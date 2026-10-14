package com.example.kare.feature.review

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.KareDesign
import com.example.kare.core.design.KareSerif

@Composable
fun ReviewSection(
    templateId: String,
    viewModel: ReviewViewModel,
    onNavigateToSignIn: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = KareDesign.colors
    var showComposer by remember { mutableStateOf(false) }

    LaunchedEffect(templateId) {
        viewModel.loadReviews(templateId)
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column {
                Text(
                    text = stringResource(R.string.reviews_title),
                    style = MaterialTheme.typography.titleLarge,
                    fontFamily = KareSerif,
                    color = colors.textPrimary,
                )
                if (uiState.ratingCount > 0) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(top = 4.dp),
                    ) {
                        StarRating(rating = uiState.averageRating.toInt(), starSize = 14.dp)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = String.format(
                                stringResource(R.string.reviews_stars_out_of_five),
                                uiState.averageRating,
                            ),
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Medium,
                            color = colors.textPrimary,
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = String.format(stringResource(R.string.reviews_count_format), uiState.ratingCount),
                            style = MaterialTheme.typography.bodySmall,
                            color = colors.textSecondary,
                        )
                    }
                }
            }

            Button(
                onClick = { showComposer = true },
                colors = ButtonDefaults.buttonColors(
                    containerColor = colors.accent.copy(alpha = 0.12f),
                    contentColor = colors.accent,
                ),
                shape = RoundedCornerShape(10.dp),
            ) {
                Text(
                    text = stringResource(R.string.reviews_write_action),
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        if (uiState.reviews.isEmpty()) {
            Text(
                text = stringResource(R.string.reviews_empty),
                style = MaterialTheme.typography.bodyMedium,
                color = colors.textSecondary,
                modifier = Modifier.padding(vertical = 8.dp),
            )
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                uiState.reviews.forEach { review ->
                    ReviewRow(
                        review = review,
                        isCurrentUser = review.id == uiState.userReview?.id,
                        onDeleteReview = { viewModel.deleteMyReview(review.id) },
                        onReportReview = { reason -> viewModel.reportReview(review.id, reason, "") },
                        onBlockAuthor = { authorId -> viewModel.blockAuthor(authorId) },
                    )
                }
            }
        }
    }

    if (showComposer) {
        ReviewComposerSheet(
            isGuest = uiState.isGuest,
            isSubmitting = uiState.isSubmitting,
            errorMessage = uiState.errorMessage,
            onDismiss = {
                viewModel.clearError()
                showComposer = false
            },
            onSubmit = { stars, text ->
                viewModel.submitReview(stars, text) {
                    showComposer = false
                }
            },
            onNavigateToSignIn = {
                showComposer = false
                onNavigateToSignIn()
            },
        )
    }
}
