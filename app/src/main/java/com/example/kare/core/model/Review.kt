package com.example.kare.core.model

import java.time.Instant
import java.util.UUID

/** Review value. Submission implementations must derive the author from the authenticated session. */
data class Review(
    val templateId: String,
    val authorName: String,
    val stars: Int,
    val text: String,
    val id: String = UUID.randomUUID().toString(),
    val authorId: String? = null,
    val createdAt: Instant = Instant.now(),
) {
    init {
        require(stars in 1..5) { "Review stars must be between 1 and 5" }
    }
}
