package com.example.kare.feature.profile

import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.kare.core.design.KareDesign
import com.example.kare.core.design.KareSerif
import java.io.File

/**
 * Avatar displaying user's selected image, or fallback serif initial letter.
 */
@Composable
fun ProfileAvatar(
    name: String,
    avatarPath: String?,
    modifier: Modifier = Modifier,
    size: Dp = 80.dp,
) {
    val colors = KareDesign.colors
    val bitmap = remember(avatarPath) {
        if (!avatarPath.isNullOrBlank()) {
            val file = File(avatarPath)
            if (file.exists() && file.length() > 0) {
                BitmapFactory.decodeFile(file.absolutePath)
            } else null
        } else null
    }

    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(colors.accent.copy(alpha = 0.12f)),
        contentAlignment = Alignment.Center,
    ) {
        if (bitmap != null) {
            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = "Profile Avatar",
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(size)
                    .clip(CircleShape),
            )
        } else {
            val initial = name.trim().firstOrNull()?.uppercase() ?: "K"
            Text(
                text = initial,
                fontFamily = KareSerif,
                fontWeight = FontWeight.Bold,
                fontSize = (size.value * 0.45f).sp,
                color = colors.accent,
            )
        }
    }
}
