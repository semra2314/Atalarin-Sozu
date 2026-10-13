package com.example.kare.core.repository

import com.example.kare.core.model.ReportReason
import com.example.kare.core.model.Review
import kotlinx.coroutines.flow.Flow

/**
 * Repository for managing template reviews, ratings, user reporting, and content moderation.
 */
interface ReviewRepository {
    fun observeReviews(templateId: String): Flow<List<Review>>
    suspend fun getReviews(templateId: String): List<Review>
    suspend fun submitReview(templateId: String, stars: Int, text: String): Result<Unit>
    suspend fun deleteMyReview(templateId: String, reviewId: String): Result<Unit>
    suspend fun reportReview(reviewId: String, templateId: String, reason: ReportReason, text: String): Result<Unit>
    suspend fun blockUser(authorId: String): Result<Unit>
    suspend fun isBlocked(authorId: String): Boolean
}
