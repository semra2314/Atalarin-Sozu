package com.example.kare.core.data.review

import com.example.kare.core.model.ReportReason
import com.example.kare.core.model.Review
import com.example.kare.core.moderation.ReviewFilter
import com.example.kare.core.repository.AuthRepository
import com.example.kare.core.repository.ReviewRepository
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

/**
 * Production [ReviewRepository] implementation backed by Cloud Firestore.
 *
 * Implements the iOS Firestore schema:
 * - Reviews collection: `reviews/{templateID}_{uid}`
 * - Reports collection: `reports/{reportID}`
 * - Enforces 1 review per user per template, content moderation via [ReviewFilter],
 *   real-time query observation, and user blocking.
 */
class FirestoreReviewRepository(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance(),
    private val authRepository: AuthRepository,
    private val reviewFilter: ReviewFilter = ReviewFilter,
) : ReviewRepository {

    private val blockedUserIds = ConcurrentHashMap.newKeySet<String>()
    private val reportedReviewIds = ConcurrentHashMap.newKeySet<String>()

    override fun observeReviews(templateId: String): Flow<List<Review>> = callbackFlow {
        val collection = firestore.collection(REVIEWS_COLLECTION)
            .whereEqualTo("templateId", templateId)

        val registration = collection.addSnapshotListener { snapshot, error ->
            if (error != null) {
                close(error)
                return@addSnapshotListener
            }

            if (snapshot != null) {
                val reviews = snapshot.documents.mapNotNull { doc ->
                    doc.toReview()
                }
                .filter { it.id !in reportedReviewIds }
                .filter { it.authorId == null || it.authorId !in blockedUserIds }
                .sortedByDescending { it.createdAt }

                trySend(reviews)
            }
        }

        awaitClose { registration.remove() }
    }

    override suspend fun getReviews(templateId: String): List<Review> {
        return try {
            val snapshot = firestore.collection(REVIEWS_COLLECTION)
                .whereEqualTo("templateId", templateId)
                .get()
                .await()

            snapshot.documents.mapNotNull { it.toReview() }
                .filter { it.id !in reportedReviewIds }
                .filter { it.authorId == null || it.authorId !in blockedUserIds }
                .sortedByDescending { it.createdAt }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun submitReview(
        templateId: String,
        stars: Int,
        text: String,
    ): Result<Unit> = runCatching {
        val user = authRepository.currentUser
            ?: throw IllegalStateException("Must be signed in to submit a review")

        require(stars in 1..5) { "Stars must be between 1 and 5" }
        require(text.isNotBlank()) { "Review text cannot be empty" }
        require(!reviewFilter.isObjectionable(text)) { "Review contains objectionable content" }

        val docId = "${templateId}_${user.id}"
        val data = hashMapOf(
            "templateId" to templateId,
            "authorId" to user.id,
            "authorName" to (user.displayName?.ifBlank { "Kare User" } ?: "Kare User"),
            "stars" to stars,
            "text" to text.trim(),
            "createdAt" to FieldValue.serverTimestamp(),
        )

        firestore.collection(REVIEWS_COLLECTION)
            .document(docId)
            .set(data)
            .await()
    }

    override suspend fun deleteMyReview(
        templateId: String,
        reviewId: String,
    ): Result<Unit> = runCatching {
        val user = authRepository.currentUser
            ?: throw IllegalStateException("Must be signed in to delete a review")

        val docId = "${templateId}_${user.id}"
        firestore.collection(REVIEWS_COLLECTION)
            .document(docId)
            .delete()
            .await()
    }

    override suspend fun reportReview(
        reviewId: String,
        templateId: String,
        reason: ReportReason,
        text: String,
    ): Result<Unit> = runCatching {
        val reporter = authRepository.currentUser
            ?: throw IllegalStateException("Must be signed in to report a review")
        reportedReviewIds.add(reviewId)

        val reportData = hashMapOf(
            "reviewId" to reviewId,
            "templateId" to templateId,
            "reason" to reason.name,
            "text" to text.trim(),
            "reporterId" to reporter.id,
            "reportedAt" to FieldValue.serverTimestamp(),
        )

        firestore.collection(REPORTS_COLLECTION)
            .add(reportData)
            .await()
    }

    override suspend fun blockUser(authorId: String): Result<Unit> = runCatching {
        blockedUserIds.add(authorId)
    }

    override suspend fun isBlocked(authorId: String): Boolean {
        return blockedUserIds.contains(authorId)
    }

    private fun com.google.firebase.firestore.DocumentSnapshot.toReview(): Review? {
        val templateId = getString("templateId") ?: return null
        val authorName = getString("authorName") ?: "Kare User"
        val stars = getLong("stars")?.toInt() ?: 5
        val text = getString("text") ?: ""
        val authorId = getString("authorId")
        val timestamp = getTimestamp("createdAt")

        val createdAt = if (timestamp != null) {
            Instant.ofEpochSecond(timestamp.seconds, timestamp.nanoseconds.toLong())
        } else {
            Instant.now()
        }

        return Review(
            id = id,
            templateId = templateId,
            authorName = authorName,
            stars = stars.coerceIn(1, 5),
            text = text,
            authorId = authorId,
            createdAt = createdAt,
        )
    }

    private companion object {
        const val REVIEWS_COLLECTION = "reviews"
        const val REPORTS_COLLECTION = "reports"
    }
}
