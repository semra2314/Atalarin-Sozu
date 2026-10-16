package com.example.kare.feature.editor

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.*
import com.example.kare.core.localization.stringResource
import com.example.kare.core.model.WidgetContent
import com.example.kare.core.ui.*

@Composable
fun EditorRoute(viewModel: EditorViewModel, onBack: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    EditorContent(state, viewModel::edit, viewModel::discard, viewModel::reload, viewModel::save, onBack)
}

@Composable
fun EditorContent(state: EditorState, onEdit: ((EditorDraft) -> EditorDraft) -> Unit,
    onDiscard: () -> Unit, onReload: () -> Unit, onSave: (() -> Unit) -> Unit, onBack: () -> Unit) {
    val sizeLabel = stringResource(R.string.editor_size)
    var confirm by rememberSaveable { mutableStateOf(false) }
    val ready = state as? EditorState.Ready
    val back = { if (ready?.dirty == true) confirm = true else onBack() }
    BackHandler { if (ready?.saving != true) back() }
    Column(Modifier.fillMaxSize().imePadding().verticalScroll(rememberScrollState()).padding(KareSpacing.lg)
        .testTag("editor-screen"), verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
        TextButton(onClick = back, enabled = ready?.saving != true) { Text(stringResource(R.string.action_back)) }
        ScreenTitle(stringResource(R.string.editor_title))
        when(state) {
            EditorState.Loading -> LoadingContent()
            EditorState.Unsupported -> Text(stringResource(R.string.editor_unsupported))
            is EditorState.Failed -> ErrorContent(state.error, onReload)
            is EditorState.Ready -> {
                val draft = state.draft; val t = draft.primary; val enabled = !state.saving
                EditorPreview(draft, state.widget.theme?.cornerRadius ?: 22.0)
                Text(stringResource(R.string.editor_preview_note), style = MaterialTheme.typography.bodySmall)
                OutlinedTextField(t.text, { value -> onEdit { it.text(value) } }, enabled = enabled,
                    label = { Text(stringResource(R.string.editor_text)) }, modifier = Modifier.fillMaxWidth().testTag("editor-text"))
                EditorHeading(R.string.editor_font)
                EditorTypography.selectable.forEach { font ->
                    FilterChip(selected = t.fontStyle == font, enabled = enabled,
                        onClick = { onEdit { it.primary { copy(fontStyle = font) } } },
                        label = { Text(stringResource(when(font) {
                            WidgetContent.FontStyle.SERIF -> R.string.editor_serif
                            WidgetContent.FontStyle.MONOSPACED -> R.string.editor_mono
                            else -> R.string.editor_sans
                        })) }, modifier = Modifier.heightIn(min = 48.dp))
                }
                if(t.fontStyle == WidgetContent.FontStyle.ROUNDED) Text(stringResource(R.string.editor_font_fallback))
                EditorHeading(R.string.editor_size)
                Text(stringResource(R.string.editor_size_value, t.fontSize.toInt()))
                Slider(value = t.fontSize.toFloat(), onValueChange = { value -> onEdit { it.primary { copy(fontSize = value.toInt().toDouble()) } } },
                    valueRange = 8f..60f, steps = 51, enabled = enabled,
                    modifier = Modifier.heightIn(min = 48.dp).semantics { contentDescription = sizeLabel })
                EditorHeading(R.string.editor_alignment)
                WidgetContent.TextAlign.entries.forEach { alignment ->
                    FilterChip(selected = t.alignment == alignment, enabled = enabled,
                        onClick = { onEdit { it.primary { copy(alignment = alignment) } } },
                        label = { Text(stringResource(when(alignment) {
                            WidgetContent.TextAlign.LEADING -> R.string.editor_start
                            WidgetContent.TextAlign.CENTER -> R.string.editor_center
                            WidgetContent.TextAlign.TRAILING -> R.string.editor_end
                        })) }, modifier = Modifier.heightIn(min = 48.dp))
                }
                EditorHeading(R.string.editor_text_color)
                EditorPalette(t.colorHex, enabled) { hex -> onEdit { it.primary { copy(colorHex = hex) } } }
                EditorHeading(R.string.editor_background)
                EditorPalette((draft.content.background as WidgetContent.Background.Color).hexes.singleOrNull(), enabled) { hex -> onEdit { it.background(hex) } }
                state.error?.let { Text(stringResource(it.stringResource()), color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite }) }
                if(state.saved) Text(stringResource(R.string.editor_saved), Modifier.testTag("editor-saved").semantics { liveRegion = LiveRegionMode.Polite })
                Button(onClick = { onSave {} }, enabled = enabled && state.dirty, modifier = Modifier.testTag("editor-save")) { Text(stringResource(R.string.editor_save)) }
                TextButton(onClick = onDiscard, enabled = enabled && state.dirty) { Text(stringResource(R.string.editor_reset)) }
            }
        }
    }
    if(confirm && ready != null) AlertDialog(onDismissRequest = { if(!ready.saving) confirm = false },
        title = { Text(stringResource(R.string.editor_unsaved)) },
        text = { Column {
            Text(stringResource(R.string.editor_unsaved_body))
            ready.error?.let { Text(stringResource(it.stringResource()), color = MaterialTheme.colorScheme.error,
                modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite }) }
        } },
        confirmButton = { Column {
            TextButton(enabled = !ready.saving, onClick = { onSave { confirm = false; onBack() } }) { Text(stringResource(R.string.editor_save_exit)) }
            TextButton(enabled = !ready.saving, onClick = { onDiscard(); confirm = false; onBack() }) { Text(stringResource(R.string.editor_discard)) }
        } }, dismissButton = { TextButton(enabled = !ready.saving, onClick = { confirm = false }) { Text(stringResource(R.string.editor_keep)) } })
}

@Composable private fun EditorHeading(id: Int) { Text(stringResource(id), style = MaterialTheme.typography.titleMedium, modifier = Modifier.semantics { heading() }) }
@Composable private fun EditorPalette(selected: String?, enabled: Boolean, onSelect: (String) -> Unit) {
    val palette = listOf("FFFFFF" to R.string.editor_white, "1D1D1F" to R.string.editor_ink,
        "D44A33" to R.string.editor_coral, "FFD8A8" to R.string.editor_peach, "4CC9F0" to R.string.editor_blue)
    palette.forEach { (hex, label) -> FilterChip(selected = selected.equals(hex, true), enabled = enabled,
        onClick = { onSelect(hex) }, label = { Text(stringResource(label)) }, modifier = Modifier.heightIn(min = 48.dp)) }
}
