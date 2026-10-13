package com.example.kare.core.data.review

import com.example.kare.core.data.auth.InMemoryAuthRepository
import com.example.kare.core.model.ReportReason
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class ReviewRepositoryTest {

    private lateinit var authRepository: InMemoryAuthRepository
    private lateinit var reviewRepository: InMemoryReviewRepository

    @Before
    fun setUp() {
        authRepository = InMemoryAuthRepository()
        reviewRepository = InMemoryReviewRepository(authRepository)
    }

    @Test
    fun submitReview_requiresAuthentication() = runTest {
        val result = reviewRepository.submitReview("template-1", 5, "Great widget!")
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is IllegalStateException)
    }

    @Test
    fun submitReview_successAndAppearsInList() = runTest {
        authRepository.register("Test User", "user@example.com", "validPass1")

        val result = reviewRepository.submitReview("template-1", 5, "Beautiful minimal widget")
        assertTrue(result.isSuccess)

        val reviews = reviewRepository.getReviews("template-1")
        assertEquals(1, reviews.size)
        assertEquals(5, reviews[0].stars)
        assertEquals("Beautiful minimal widget", reviews[0].text)
    }

    @Test
    fun submitReview_rejectsObjectionableContent() = runTest {
        authRepository.register("Test User", "user@example.com", "validPass1")

        val result = reviewRepository.submitReview("template-1", 1, "tam bir amk tasarımı")
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is IllegalArgumentException)
    }

    @Test
    fun submitReview_updatesExistingReviewForSameUserAndTemplate() = runTest {
        authRepository.register("Test User", "user@example.com", "validPass1")

        reviewRepository.submitReview("template-1", 4, "Initial review")
        assertEquals(1, reviewRepository.getReviews("template-1").size)

        reviewRepository.submitReview("template-1", 5, "Updated review text")
        val reviews = reviewRepository.getReviews("template-1")
        assertEquals(1, reviews.size)
        assertEquals(5, reviews[0].stars)
        assertEquals("Updated review text", reviews[0].text)
    }

    @Test
    fun deleteMyReview_removesFromTemplateReviews() = runTest {
        authRepository.register("Test User", "user@example.com", "validPass1")
        reviewRepository.submitReview("template-1", 5, "To be deleted")

        val reviewId = reviewRepository.getReviews("template-1").first().id
        val deleteResult = reviewRepository.deleteMyReview("template-1", reviewId)
        assertTrue(deleteResult.isSuccess)

        val reviews = reviewRepository.getReviews("template-1")
        assertTrue(reviews.isEmpty())
    }

    @Test
    fun reportReview_hidesReviewFromList() = runTest {
        authRepository.register("Test User", "user@example.com", "validPass1")
        reviewRepository.submitReview("template-1", 5, "Public review")

        val reviewId = reviewRepository.getReviews("template-1").first().id
        reviewRepository.reportReview(reviewId, "template-1", ReportReason.SPAM, "Spam review")

        val reviews = reviewRepository.observeReviews("template-1").first()
        assertTrue(reviews.isEmpty())
    }

    @Test
    fun blockUser_hidesAllReviewsFromThatUser() = runTest {
        authRepository.register("Author", "author@example.com", "validPass1")
        val authorId = authRepository.currentUser!!.id
        reviewRepository.submitReview("template-1", 5, "Author review")

        reviewRepository.blockUser(authorId)

        val reviews = reviewRepository.getReviews("template-1")
        assertTrue(reviews.isEmpty())
        assertTrue(reviewRepository.isBlocked(authorId))
    }
}
