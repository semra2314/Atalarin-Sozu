package com.example.kare.feature.review

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.kare.R
import com.example.kare.core.design.KareDesign
import com.example.kare.core.model.ReportReason
import com.example.kare.core.model.Review
import java.time.Duration
import java.time.Instant

@Composable
fun ReviewRow(
    review: Review,
    isCurrentUser: Boolean,
    onDeleteReview: () -> Unit,
    onReportReview: (ReportReason) -> Unit,
    onBlockAuthor: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = KareDesign.colors
    var menuExpanded by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(colors.surfaceMuted.copy(alpha = 0.7f))
            .padding(14.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // Author initial avatar
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(colors.accent.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center,
            ) {
                val initial = review.authorName.trim().firstOrNull()?.uppercase() ?: "K"
                Text(
                    text = initial,
                    color = colors.accent,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                )
            }

            Spacer(modifier = Modifier.width(10.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = review.authorName,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = colors.textPrimary,
                )
                Text(
                    text = formatRelativeTime(review.createdAt),
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.textSecondary,
                )
            }

            IconButton(onClick = { menuExpanded = true }) {
                Icon(
                    imageVector = Icons.Default.MoreVert,
                    contentDescription = "Options",
                    tint = colors.textSecondary,
                )
            }

            DropdownMenu(
                expanded = menuExpanded,
                onDismissRequest = { menuExpanded = false },
            ) {
                if (isCurrentUser) {
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.reviews_action_delete)) },
                        onClick = {
                            menuExpanded = false
                            onDeleteReview()
                        },
                    )
                } else {
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.reviews_action_report)) },
                        onClick = {
                            menuExpanded = false
                            onReportReview(ReportReason.OFFENSIVE)
                        },
                    )
                    review.authorId?.let { authorId ->
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.reviews_action_block)) },
                            onClick = {
                                menuExpanded = false
                                onBlockAuthor(authorId)
                            },
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        StarRating(rating = review.stars, starSize = 14.dp)

        Spacer(modifier = Modifier.height(6.dp))

        Text(
            text = review.text,
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textPrimary,
        )
    }
}

private fun formatRelativeTime(createdAt: Instant): String {
    val duration = Duration.between(createdAt, Instant.now())
    val minutes = duration.toMinutes()
    val hours = duration.toHours()
    val days = duration.toDays()

    return when {
        minutes < 1 -> "Just now"
        minutes < 60 -> "${minutes}m ago"
        hours < 24 -> "${hours}h ago"
        days < 30 -> "${days}d ago"
        else -> "${days / 30}mo ago"
    }
}
