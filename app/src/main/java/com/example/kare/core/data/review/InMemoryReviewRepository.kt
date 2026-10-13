package com.example.kare.core.data.review

import com.example.kare.core.model.AuthState
import com.example.kare.core.model.ReportReason
import com.example.kare.core.model.Review
import com.example.kare.core.moderation.ReviewFilter
import com.example.kare.core.repository.AuthRepository
import com.example.kare.core.repository.ReviewRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.util.UUID

/**
 * In-memory thread-safe implementation of [ReviewRepository].
 * Enforces 1-review-per-user-per-template, objectionable content filtering,
 * author blocking, and review reporting.
 */
class InMemoryReviewRepository(
    private val authRepository: AuthRepository,
    initialReviews: List<Review> = emptyList(),
) : ReviewRepository {

    private val reviewsState = MutableStateFlow(initialReviews)
    private val reportedReviewIds = MutableStateFlow<Set<String>>(emptySet())
    private val blockedUserIds = MutableStateFlow<Set<String>>(emptySet())

    override fun observeReviews(templateId: String): Flow<List<Review>> {
        return reviewsState.map { allReviews ->
            val blocked = blockedUserIds.value
            val reported = reportedReviewIds.value
            allReviews
                .filter { it.templateId == templateId }
                .filter { it.id !in reported }
                .filter { it.authorId == null || it.authorId !in blocked }
                .sortedByDescending { it.createdAt }
        }
    }

    override suspend fun getReviews(templateId: String): List<Review> {
        val blocked = blockedUserIds.value
        val reported = reportedReviewIds.value
        return reviewsState.value
            .filter { it.templateId == templateId }
            .filter { it.id !in reported }
            .filter { it.authorId == null || it.authorId !in blocked }
            .sortedByDescending { it.createdAt }
    }

    override suspend fun submitReview(
        templateId: String,
        stars: Int,
        text: String,
    ): Result<Unit> = runCatching {
        // Use currentUser snapshot — avoids needing a StateFlow.value on the authState Flow.
        val user = authRepository.currentUser
            ?: throw IllegalStateException("Must be signed in to submit a review")

        if (stars !in 1..5) {
            throw IllegalArgumentException("Stars must be between 1 and 5")
        }

        if (text.isBlank()) {
            throw IllegalArgumentException("Review text cannot be empty")
        }

        if (ReviewFilter.isObjectionable(text)) {
            throw IllegalArgumentException("Review contains objectionable content")
        }

        val currentList = reviewsState.value
        val existingIndex = currentList.indexOfFirst {
            it.templateId == templateId && it.authorId == user.id
        }

        val newReview = Review(
            id = UUID.randomUUID().toString(),
            templateId = templateId,
            authorId = user.id,
            authorName = user.displayName?.ifBlank { "Kare User" } ?: "Kare User",
            stars = stars,
            text = text.trim(),
            createdAt = Instant.now(),
        )

        val updated = currentList.toMutableList()
        if (existingIndex >= 0) {
            updated[existingIndex] = newReview
        } else {
            updated.add(newReview)
        }
        reviewsState.value = updated
    }

    override suspend fun deleteMyReview(
        templateId: String,
        reviewId: String,
    ): Result<Unit> = runCatching {
        val user = authRepository.currentUser
            ?: throw IllegalStateException("Must be signed in to delete a review")

        val currentList = reviewsState.value
        val review = currentList.firstOrNull { it.id == reviewId && it.templateId == templateId }
            ?: throw NoSuchElementException("Review not found")

        if (review.authorId != user.id) {
            throw IllegalAccessException("Cannot delete a review that does not belong to you")
        }

        reviewsState.value = currentList.filter { it.id != reviewId }
    }

    override suspend fun reportReview(
        reviewId: String,
        templateId: String,
        reason: ReportReason,
        text: String,
    ): Result<Unit> = runCatching {
        reportedReviewIds.value = reportedReviewIds.value + reviewId
    }

    override suspend fun blockUser(authorId: String): Result<Unit> = runCatching {
        blockedUserIds.value = blockedUserIds.value + authorId
    }

    override suspend fun isBlocked(authorId: String): Boolean {
        return authorId in blockedUserIds.value
    }
}
