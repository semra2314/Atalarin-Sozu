package com.example.kare.feature.review

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.AuthState
import com.example.kare.core.model.ReportReason
import com.example.kare.core.model.Review
import com.example.kare.core.repository.AuthRepository
import com.example.kare.core.repository.ReviewRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

data class ReviewUiState(
    val templateId: String = "",
    val reviews: List<Review> = emptyList(),
    val userReview: Review? = null,
    val averageRating: Double = 0.0,
    val ratingCount: Int = 0,
    val isLoading: Boolean = false,
    val isSubmitting: Boolean = false,
    val isGuest: Boolean = true,
    val errorMessage: String? = null,
)

class ReviewViewModel(
    private val reviewRepository: ReviewRepository,
    private val authRepository: AuthRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(ReviewUiState())
    val uiState: StateFlow<ReviewUiState> = _uiState.asStateFlow()

    private var observeJob: Job? = null

    init {
        viewModelScope.launch {
            authRepository.authState.collectLatest { authState ->
                val isGuest = authState !is AuthState.Authenticated
                val current = _uiState.value
                val currentUserId = (authState as? AuthState.Authenticated)?.user?.id
                _uiState.value = current.copy(
                    isGuest = isGuest,
                    userReview = current.reviews.firstOrNull { it.authorId == currentUserId },
                )
            }
        }
    }

    fun loadReviews(templateId: String) {
        observeJob?.cancel()
        _uiState.value = _uiState.value.copy(templateId = templateId, isLoading = true)

        observeJob = viewModelScope.launch {
            reviewRepository.observeReviews(templateId).collectLatest { reviewList ->
                val currentUserId = authRepository.currentUser?.id
                val avg = if (reviewList.isNotEmpty()) {
                    reviewList.map { it.stars }.average()
                } else 0.0

                _uiState.value = _uiState.value.copy(
                    reviews = reviewList,
                    userReview = reviewList.firstOrNull { it.authorId == currentUserId },
                    averageRating = avg,
                    ratingCount = reviewList.size,
                    isLoading = false,
                )
            }
        }
    }

    fun submitReview(stars: Int, text: String, onSuccess: () -> Unit = {}) {
        val templateId = _uiState.value.templateId
        if (templateId.isBlank()) return

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSubmitting = true, errorMessage = null)
            val result = reviewRepository.submitReview(templateId, stars, text)
            _uiState.value = _uiState.value.copy(isSubmitting = false)
            result.onSuccess {
                onSuccess()
            }.onFailure { th ->
                _uiState.value = _uiState.value.copy(
                    errorMessage = th.localizedMessage ?: "Failed to submit review"
                )
            }
        }
    }

    fun deleteMyReview(reviewId: String) {
        val templateId = _uiState.value.templateId
        viewModelScope.launch {
            reviewRepository.deleteMyReview(templateId, reviewId)
        }
    }

    fun reportReview(reviewId: String, reason: ReportReason, text: String) {
        val templateId = _uiState.value.templateId
        viewModelScope.launch {
            reviewRepository.reportReview(reviewId, templateId, reason, text)
        }
    }

    fun blockAuthor(authorId: String) {
        viewModelScope.launch {
            reviewRepository.blockUser(authorId)
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }
}
