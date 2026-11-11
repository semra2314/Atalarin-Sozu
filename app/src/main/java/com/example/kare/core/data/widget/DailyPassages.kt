package com.example.kare.core.data.widget

import com.example.kare.core.model.DailyPassage
import com.example.kare.core.model.DailySource
import java.time.LocalDate

/**
 * Starter public-domain corpus: King James Version (1611) and poetry by authors who died before 1900.
 * Wording needs a proofreading pass against the cited editions before release, and the corpus needs
 * to grow; selection tolerates any non-empty list.
 */
internal object DailyPassages {
    private val bible = listOf(
        "The Lord is my shepherd; I shall not want." to "Psalm 23:1",
        "Be still, and know that I am God." to "Psalm 46:10",
        "This is the day which the Lord hath made; we will rejoice and be glad in it." to "Psalm 118:24",
        "Trust in the Lord with all thine heart; and lean not unto thine own understanding." to "Proverbs 3:5",
        "A soft answer turneth away wrath: but grievous words stir up anger." to "Proverbs 15:1",
        "To every thing there is a season, and a time to every purpose under the heaven." to "Ecclesiastes 3:1",
        "Ask, and it shall be given you; seek, and ye shall find; knock, and it shall be opened unto you." to "Matthew 7:7",
        "Thou shalt love thy neighbour as thyself." to "Mark 12:31",
    ).map { (text, reference) -> DailyPassage(text, "$reference (KJV)", DailySource.BIBLE) }

    private val poetry = listOf(
        "To see a world in a grain of sand, and a heaven in a wild flower." to "William Blake, Auguries of Innocence",
        "Hope is the thing with feathers that perches in the soul." to "Emily Dickinson",
        "A thing of beauty is a joy for ever." to "John Keats, Endymion",
        "If Winter comes, can Spring be far behind?" to "Percy Bysshe Shelley, Ode to the West Wind",
        "'Tis better to have loved and lost than never to have loved at all." to "Alfred Tennyson, In Memoriam A.H.H.",
    ).map { (text, author) -> DailyPassage(text, author, DailySource.POETRY) }

    fun forSource(source: DailySource): List<DailyPassage> = when (source) {
        DailySource.BIBLE -> bible
        DailySource.POETRY -> poetry
    }
}

/**
 * Deterministic per-day pick from the device's local calendar date: every instance with the same source
 * shows the same passage all day and changes at local midnight. This is an Android definition of the
 * day index (epoch day), not a verified parity with the iOS day counter.
 */
fun dailyPassage(date: LocalDate, source: DailySource): DailyPassage {
    val passages = DailyPassages.forSource(source)
    return passages[Math.floorMod(date.toEpochDay(), passages.size.toLong()).toInt()]
}
