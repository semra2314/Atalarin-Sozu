package com.example.kare.core.data.profile

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import kotlin.math.max

/**
 * Manages local user profile avatar persistence and downscaling.
 * Matches iOS ImageDownscaler constraint: max 400px JPEG output.
 */
class ProfileAvatarStore(private val context: Context) {

    private val avatarFile: File
        get() = File(context.filesDir, AVATAR_FILE_NAME)

    suspend fun saveAvatar(inputStream: InputStream): Result<String> = withContext(Dispatchers.IO) {
        runCatching {
            val originalBitmap = BitmapFactory.decodeStream(inputStream)
                ?: error("Failed to decode image from input stream")

            val downscaledBitmap = downscaleIfNeeded(originalBitmap, MAX_DIMENSION)
            val outputStream = ByteArrayOutputStream()
            downscaledBitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, outputStream)

            FileOutputStream(avatarFile).use { fos ->
                fos.write(outputStream.toByteArray())
                fos.flush()
            }

            if (downscaledBitmap != originalBitmap) {
                downscaledBitmap.recycle()
            }
            originalBitmap.recycle()

            avatarFile.absolutePath
        }
    }

    suspend fun getAvatarFile(): File? = withContext(Dispatchers.IO) {
        if (avatarFile.exists() && avatarFile.length() > 0) avatarFile else null
    }

    suspend fun deleteAvatar(): Boolean = withContext(Dispatchers.IO) {
        if (avatarFile.exists()) {
            avatarFile.delete()
        } else {
            true
        }
    }

    private fun downscaleIfNeeded(bitmap: Bitmap, maxDimension: Int): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        val longestEdge = max(width, height)

        if (longestEdge <= maxDimension) {
            return bitmap
        }

        val scale = maxDimension.toFloat() / longestEdge
        val targetWidth = (width * scale).toInt().coerceAtLeast(1)
        val targetHeight = (height * scale).toInt().coerceAtLeast(1)

        return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
    }

    companion object {
        const val AVATAR_FILE_NAME = "profile-avatar.jpg"
        const val MAX_DIMENSION = 400
        const val JPEG_QUALITY = 85
    }
}
