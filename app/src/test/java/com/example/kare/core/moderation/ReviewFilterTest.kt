package com.example.kare.core.moderation

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReviewFilterTest {

    @Test
    fun allowsCleanEnglishAndTurkishTexts() {
        assertFalse(ReviewFilter.isObjectionable("This is an amazing and beautiful widget design!"))
        assertFalse(ReviewFilter.isObjectionable("Harika bir widget, ana ekranımda çok güzel durdu."))
        assertFalse(ReviewFilter.isObjectionable(""))
        assertFalse(ReviewFilter.isObjectionable("   "))
    }

    @Test
    fun detectsEnglishProfanity() {
        assertTrue(ReviewFilter.isObjectionable("This app is complete shit!"))
        assertTrue(ReviewFilter.isObjectionable("What a scam app"))
        assertTrue(ReviewFilter.isObjectionable("You are a bitch"))
    }

    @Test
    fun detectsTurkishProfanity() {
        assertTrue(ReviewFilter.isObjectionable("Bu ne biçim widget amk"))
        assertTrue(ReviewFilter.isObjectionable("Siktir git buradan"))
        assertTrue(ReviewFilter.isObjectionable("Kahpece bir tasarım"))
    }

    @Test
    fun handlesPunctuationAndMixedCase() {
        assertTrue(ReviewFilter.isObjectionable("S.I.K.T.I.R"))
        assertTrue(ReviewFilter.isObjectionable("SHIT!!!"))
        assertTrue(ReviewFilter.isObjectionable("bu tam bir amk."))
    }
}
