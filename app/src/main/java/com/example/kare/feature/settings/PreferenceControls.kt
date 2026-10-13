package com.example.kare.feature.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import com.example.kare.R
import com.example.kare.core.design.KareSpacing
import com.example.kare.core.model.AppLanguage

@Composable
fun PreferenceHeading(text: String) { Text(text, style = MaterialTheme.typography.titleLarge, modifier = Modifier.semantics { heading() }) }

@Composable
fun PreferenceErrorText(error: PreferenceError) {
    Text(stringResource(if (error == PreferenceError.READ) R.string.preferences_read_error else R.string.preferences_write_error),
        color = MaterialTheme.colorScheme.error, modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
}

@Composable
fun PreferenceChoice(label: String, selected: Boolean, enabled: Boolean, tag: String, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().heightIn(min = 48.dp).testTag(tag)
        .selectable(selected = selected, enabled = enabled, role = Role.RadioButton, onClick = onClick)
        .padding(vertical = KareSpacing.sm), verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KareSpacing.sm)) {
        RadioButton(selected = selected, onClick = null, enabled = enabled)
        Text(label, Modifier.weight(1f))
    }
}

@Composable
fun LanguageChoices(language: AppLanguage, enabled: Boolean, onLanguage: (AppLanguage) -> Unit) {
    Column(Modifier.selectableGroup()) {
        AppLanguage.entries.forEach { option -> PreferenceChoice(stringResource(when(option) {
            AppLanguage.SYSTEM -> R.string.language_system
            AppLanguage.ENGLISH -> R.string.language_english
            AppLanguage.TURKISH -> R.string.language_turkish
        }), language == option, enabled, "language-${option.name}", { onLanguage(option) }) }
    }
}
