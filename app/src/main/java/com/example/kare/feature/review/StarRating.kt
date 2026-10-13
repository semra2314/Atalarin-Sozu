package com.example.kare.feature.review

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.example.kare.core.design.KareDesign

/**
 * Reusable 5-star rating component for display or interactive selection.
 */
@Composable
fun StarRating(
    rating: Int,
    modifier: Modifier = Modifier,
    maxStars: Int = 5,
    starSize: Dp = 16.dp,
    activeColor: Color = Color(0xFFFFB800),
    inactiveColor: Color = Color(0x40888888),
    onRatingChanged: ((Int) -> Unit)? = null,
) {
    Row(modifier = modifier) {
        for (i in 1..maxStars) {
            val isSelected = i <= rating
            val starModifier = if (onRatingChanged != null) {
                Modifier
                    .size(starSize)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { onRatingChanged(i) }
            } else {
                Modifier.size(starSize)
            }

            Icon(
                imageVector = Icons.Default.Star,
                contentDescription = "$i stars",
                tint = if (isSelected) activeColor else inactiveColor,
                modifier = starModifier,
            )
        }
    }
}
