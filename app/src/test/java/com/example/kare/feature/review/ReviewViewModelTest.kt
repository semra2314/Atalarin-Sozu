package com.example.kare.feature.review

import com.example.kare.core.data.auth.InMemoryAuthRepository
import com.example.kare.core.data.review.InMemoryReviewRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ReviewViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var authRepository: InMemoryAuthRepository
    private lateinit var reviewRepository: InMemoryReviewRepository
    private lateinit var viewModel: ReviewViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        authRepository = InMemoryAuthRepository()
        reviewRepository = InMemoryReviewRepository(authRepository)
        viewModel = ReviewViewModel(reviewRepository, authRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun loadReviews_observesAndUpdatesList() = runTest {
        authRepository.register("Reviewer", "reviewer@example.com", "validPass1")
        reviewRepository.submitReview("template-10", 5, "Best widget ever")

        viewModel.loadReviews("template-10")
        testDispatcher.scheduler.advanceUntilIdle()

        assertEquals(1, viewModel.uiState.value.reviews.size)
        assertEquals(5.0, viewModel.uiState.value.averageRating, 0.01)
        assertEquals(1, viewModel.uiState.value.ratingCount)
        assertNotNull(viewModel.uiState.value.userReview)
    }

    @Test
    fun submitReview_asGuest_setsErrorMessage() = runTest {
        viewModel.loadReviews("template-10")
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.submitReview(5, "Guest review should fail")
        testDispatcher.scheduler.advanceUntilIdle()

        assertNotNull(viewModel.uiState.value.errorMessage)
    }

    @Test
    fun deleteMyReview_removesFromState() = runTest {
        authRepository.register("Reviewer", "reviewer@example.com", "validPass1")
        reviewRepository.submitReview("template-10", 4, "Good design")

        viewModel.loadReviews("template-10")
        testDispatcher.scheduler.advanceUntilIdle()

        val reviewId = viewModel.uiState.value.userReview!!.id
        viewModel.deleteMyReview(reviewId)
        testDispatcher.scheduler.advanceUntilIdle()

        assertTrue(viewModel.uiState.value.reviews.isEmpty())
        assertNull(viewModel.uiState.value.userReview)
    }
}
