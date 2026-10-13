package com.example.kare.core.moderation

/**
 * Moderation utility for checking objectionable, offensive, or inappropriate review text
 * across English and Turkish languages, matching the iOS moderation filter.
 */
object ReviewFilter {

    private val BANNED_PATTERNS = listOf(
        // English profanity / offensive tokens
        "fuck", "shit", "bitch", "asshole", "bastard", "cunt", "dick", "pussy",
        "nigger", "nigga", "faggot", "whore", "slut", "retard", "scam",
        // Turkish profanity / offensive tokens
        "amk", "aq", "orospu", "piç", "pic", "siktir", "sikik", "sikim", "yarak",
        "yarrak", "göt", "gotveren", "ibne", "kahpe", "pezevenk", "amcık", "amcik",
        "ananı", "anani", "sikeyim", "sikerim"
    )

    /**
     * Checks if the provided [text] contains any objectionable or offensive words.
     * Normalized by removing non-alphanumeric punctuation and lowercasing.
     */
    fun isObjectionable(text: String): Boolean {
        if (text.isBlank()) return false
        val normalized = text.lowercase()
            .replace(Regex("[^a-z0-9ğüşıöç\\s]"), "")

        val words = normalized.split(Regex("\\s+")).filter { it.isNotBlank() }
        for (word in words) {
            for (pattern in BANNED_PATTERNS) {
                if (word == pattern || word.contains(pattern)) {
                    return true
                }
            }
        }
        return false
    }
}
