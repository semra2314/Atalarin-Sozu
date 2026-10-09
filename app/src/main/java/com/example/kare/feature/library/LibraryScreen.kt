package com.example.kare.feature.library

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.*
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
import com.example.kare.core.presentation.LoadState
import com.example.kare.core.ui.*

@Composable
fun LibraryRoute(viewModel: LibraryViewModel, onTemplateClick: (String) -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    LibraryContent(state, viewModel::retryObservation, viewModel::setFavoritesOnly,
        { viewModel.toggleFavorite(it) }, { viewModel.remove(it) }, { viewModel.reorder(it) }, viewModel::clearAction, onTemplateClick)
}

@Composable
fun LibraryContent(state: LibraryUiState, onRetry: () -> Unit, onFavoritesOnly: (Boolean) -> Unit,
    onFavoriteToggle: (String) -> Unit, onRemove: (String) -> Unit, onReorder: (List<String>) -> Unit,
    onDismissAction: () -> Unit, onTemplateClick: (String) -> Unit) {
    var pendingRemoval by rememberSaveable { mutableStateOf<String?>(null) }
    val all = (state.widgets as? LoadState.Loaded)?.value.orEmpty()
    val busy = state.action is LibraryActionState.Running
    val target = all.find { it.templateId == pendingRemoval }
    if (target != null) AlertDialog(onDismissRequest = { pendingRemoval = null },
        title = { Text(stringResource(R.string.action_remove)) },
        text = { Text(stringResource(R.string.library_remove_confirm, target.name)) },
        confirmButton = { TextButton(enabled = !busy, onClick = { onRemove(target.templateId); pendingRemoval = null },
            modifier = Modifier.testTag("confirm-remove")) { Text(stringResource(R.string.action_remove)) } },
        dismissButton = { TextButton(onClick = { pendingRemoval = null }) { Text(stringResource(R.string.action_cancel)) } })
    LazyColumn(Modifier.fillMaxSize().wrapContentWidth().widthIn(max = KareLayout.readableWidth).fillMaxWidth(), contentPadding = PaddingValues(KareSpacing.lg),
        verticalArrangement = Arrangement.spacedBy(KareSpacing.lg)) {
        item { ScreenTitle(stringResource(R.string.library_title)) }
        item {
            FilterChip(selected = state.favoritesOnly, onClick = { onFavoritesOnly(!state.favoritesOnly) },
                label = { Text(stringResource(R.string.favorites_show_only)) }, modifier = Modifier.heightIn(min = 48.dp))
        }
        when (val action = state.action) {
            is LibraryActionState.Running -> item { Text(stringResource(R.string.library_working), modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite }) }
            is LibraryActionState.Failed -> item {
                Column {
                    Text(stringResource(action.error.stringResource()), modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
                    TextButton(onClick = onDismissAction) { Text(stringResource(R.string.action_dismiss)) }
                }
            }
            else -> Unit
        }
        when (val widgets = state.widgets) {
            LoadState.Loading -> item { LoadingContent() }
            is LoadState.Failed -> item { ErrorContent(widgets.error, onRetry) }
            is LoadState.Loaded -> {
                if (state.visibleWidgets.isEmpty()) item { EmptyContent(
                    stringResource(if (state.favoritesOnly) R.string.favorites_empty_title else R.string.library_empty_title),
                    stringResource(if (state.favoritesOnly) R.string.favorites_empty_message else R.string.library_empty_message)) }
                if (state.favoritesOnly && state.visibleWidgets.isNotEmpty()) item { Text(stringResource(R.string.library_reorder_hint)) }
                items(state.visibleWidgets, key = { it.templateId }) { widget ->
                    val index = all.indexOfFirst { it.templateId == widget.templateId }
                    Card(shape = KareShapes.card, colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
                        TextButton(onClick = { onTemplateClick(widget.templateId) }, modifier = Modifier.fillMaxWidth().testTag("installed-${widget.templateId}")) {
                            Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(KareSpacing.xs)) {
                                Text(widget.name, style = MaterialTheme.typography.headlineSmall, color = MaterialTheme.colorScheme.onSurface)
                                Text(stringResource(R.string.author_by, widget.authorName), color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                        Column(Modifier.padding(horizontal = KareSpacing.md)) {
                            TextButton(enabled = !busy, onClick = { onFavoriteToggle(widget.templateId) },
                                modifier = Modifier.testTag("favorite-${widget.templateId}")) {
                                Text(stringResource(if (widget.isFavorite) R.string.favorite_remove else R.string.favorite_add))
                            }
                            TextButton(enabled = !busy, onClick = { pendingRemoval = widget.templateId },
                                modifier = Modifier.testTag("remove-${widget.templateId}")) { Text(stringResource(R.string.action_remove)) }
                            Column {
                                TextButton(enabled = !busy && !state.favoritesOnly && index > 0, onClick = {
                                    val ids = all.map { it.templateId }.toMutableList()
                                    java.util.Collections.swap(ids, index, index - 1); onReorder(ids)
                                }) { Text(stringResource(R.string.action_move_up)) }
                                TextButton(enabled = !busy && !state.favoritesOnly && index < all.lastIndex, onClick = {
                                    val ids = all.map { it.templateId }.toMutableList()
                                    java.util.Collections.swap(ids, index, index + 1); onReorder(ids)
                                }) { Text(stringResource(R.string.action_move_down)) }
                            }
                        }
                    }
                }
            }
        }
    }
}
