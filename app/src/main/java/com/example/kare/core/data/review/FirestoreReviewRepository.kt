package com.example.kare.core.data.review

import com.example.kare.core.model.AuthState
import com.example.kare.core.model.ReportReason
import com.example.kare.core.model.Review
import com.example.kare.core.moderation.ReviewFilter
import com.example.kare.core.repository.AuthRepository
import com.example.kare.core.repository.ReviewRepository
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import java.time.Instant
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.tasks.await

/**
 * Production [ReviewRepository] implementation backed by Cloud Firestore.
 *
 * Implements the iOS Firestore schema:
 * - Reviews collection: `reviews/{templateID}_{uid}`
 * - Reports collection: `reports/{reportID}`
 * - Blocked authors: `users/{uid}/blocks/{authorId}`, private to the blocking user
 * - Enforces 1 review per user per template, content moderation via [ReviewFilter],
 *   real-time query observation, and persistent per-account user blocking.
 */
class FirestoreReviewRepository(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance(),
    private val authRepository: AuthRepository,
    private val reviewFilter: ReviewFilter = ReviewFilter,
) : ReviewRepository {

    private val reportedReviewIds = MutableStateFlow<Set<String>>(emptySet())

    /** Blocked author ids of the signed-in account; empty for guests. Follows sign-in and sign-out. */
    @OptIn(ExperimentalCoroutinesApi::class)
    private fun observeBlockedAuthors(): Flow<Set<String>> =
        authRepository.authState.flatMapLatest { state ->
            val uid = (state as? AuthState.Authenticated)?.user?.id
            if (uid == null) flowOf(emptySet()) else observeBlocksOf(uid)
        }

    private fun observeBlocksOf(uid: String): Flow<Set<String>> = callbackFlow {
        val registration = blocksCollection(uid).addSnapshotListener { snapshot, error ->
            if (error != null) {
                // Blocking is a convenience filter; keep showing reviews if the list cannot be read.
                trySend(emptySet())
                return@addSnapshotListener
            }
            trySend(snapshot?.documents?.mapTo(HashSet()) { it.id } ?: emptySet())
        }
        awaitClose { registration.remove() }
    }

    override fun observeReviews(templateId: String): Flow<List<Review>> {
        val reviews = callbackFlow {
            val registration = firestore.collection(REVIEWS_COLLECTION)
                .whereEqualTo("templateId", templateId)
                .addSnapshotListener { snapshot, error ->
                    if (error != null) {
                        close(error)
                        return@addSnapshotListener
                    }
                    if (snapshot != null) {
                        trySend(snapshot.documents.mapNotNull { it.toReview() })
                    }
                }
            awaitClose { registration.remove() }
        }
        return combine(reviews, observeBlockedAuthors(), reportedReviewIds) { all, blocked, reported ->
            all.visible(blocked, reported)
        }
    }

    override suspend fun getReviews(templateId: String): List<Review> {
        return try {
            val snapshot = firestore.collection(REVIEWS_COLLECTION)
                .whereEqualTo("templateId", templateId)
                .get()
                .await()

            snapshot.documents.mapNotNull { it.toReview() }
                .visible(loadBlockedAuthors(), reportedReviewIds.value)
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
        reportedReviewIds.value = reportedReviewIds.value + reviewId

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
        val user = authRepository.currentUser
            ?: throw IllegalStateException("Must be signed in to block a user")
        require(authorId.isNotBlank() && authorId != user.id) { "Invalid author to block" }

        blocksCollection(user.id)
            .document(authorId)
            .set(mapOf("blockedAt" to FieldValue.serverTimestamp()))
            .await()
    }

    override suspend fun isBlocked(authorId: String): Boolean = authorId in loadBlockedAuthors()

    private suspend fun loadBlockedAuthors(): Set<String> {
        val uid = authRepository.currentUser?.id ?: return emptySet()
        return try {
            blocksCollection(uid).get().await().documents.mapTo(HashSet()) { it.id }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            emptySet()
        }
    }

    private fun blocksCollection(uid: String) =
        firestore.collection(USERS_COLLECTION).document(uid).collection(BLOCKS_COLLECTION)

    private fun List<Review>.visible(blocked: Set<String>, reported: Set<String>): List<Review> =
        filter { it.id !in reported }
            .filter { it.authorId == null || it.authorId !in blocked }
            .sortedByDescending { it.createdAt }

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
        const val USERS_COLLECTION = "users"
        const val BLOCKS_COLLECTION = "blocks"
    }
}
