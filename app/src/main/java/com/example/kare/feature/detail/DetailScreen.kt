package com.example.kare.feature.detail

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.*
import com.example.kare.core.localization.*
import com.example.kare.core.model.WidgetSize
import com.example.kare.core.presentation.*
import com.example.kare.core.ui.*

@Composable
fun DetailRoute(viewModel: DetailViewModel, onBack: () -> Unit, onLibrary: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    DetailContent(viewModel.templateId, state, onBack, onLibrary, viewModel::reload,
        viewModel::retryLibrary, viewModel::selectSize, viewModel::install)
}

@Composable
fun DetailContent(templateId: String, state: DetailUiState, onBack: () -> Unit, onLibrary: () -> Unit,
    onRetry: () -> Unit, onRetryLibrary: () -> Unit, onSize: (WidgetSize) -> Unit, onInstall: () -> Unit) {
    LazyColumn(Modifier.fillMaxSize().wrapContentWidth().widthIn(max = KareLayout.readableWidth)
        .fillMaxWidth().testTag("detail-$templateId"), contentPadding = PaddingValues(KareSpacing.lg),
        verticalArrangement = Arrangement.spacedBy(KareSpacing.lg)) {
        item { TextButton(onClick = onBack) { Text(stringResource(R.string.action_back)) } }
        when (val loaded = state.template) {
            LoadState.Loading -> item { LoadingContent() }
            is LoadState.Failed -> item { ErrorContent(loaded.error, onRetry) }
            is LoadState.Loaded -> {
                val template = loaded.value
                val copy = catalogCopy(template.id)
                val installed = (state.installed as? LoadState.Loaded)?.value
                val busy = state.action == InstallState.Installing
                item { ScreenTitle(copy?.let { stringResource(it.name) } ?: template.name) }
                item {
                    catalogArtwork(template.id)?.let { artwork ->
                        Card(shape = KareShapes.card) {
                            Image(painterResource(artwork), contentDescription = null, contentScale = ContentScale.Fit,
                                modifier = Modifier.fillMaxWidth().aspectRatio(1.5f))
                        }
                    } ?: Surface(color = MaterialTheme.colorScheme.primaryContainer, shape = KareShapes.card) {
                        Text(stringResource(R.string.detail_preview_unavailable), Modifier.padding(KareSpacing.xl))
                    }
                }
                item { Text(stringResource(R.string.author_by, template.author.displayName)) }
                item { Text(stringResource(template.category.stringResource()), color = MaterialTheme.colorScheme.onSurfaceVariant) }
                if (template.ratingCount > 0) item {
                    Text(stringResource(R.string.detail_rating, template.rating, template.ratingCount),
                        modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
                }
                item { Text(copy?.let { stringResource(it.summary) } ?: template.summary) }
                item { Text(stringResource(R.string.detail_sizes), style = MaterialTheme.typography.headlineSmall,
                    modifier = Modifier.semantics { heading() }) }
                if (installed == null && template.supportedSizes.size > 1) item { Text(stringResource(R.string.detail_choose_size)) }
                item {
                    Column {
                        template.supportedSizes.forEach { size ->
                            FilterChip(selected = (installed?.size ?: state.selectedSize) == size,
                                enabled = !busy && installed == null, onClick = { onSize(size) },
                                label = { Text(stringResource(size.detailLabel())) },
                                modifier = Modifier.heightIn(min = 48.dp).testTag("size-${size.rawValue}"))
                        }
                    }
                }
                item { Text(stringResource(R.string.detail_size_note), style = MaterialTheme.typography.bodySmall) }
                item { Text(stringResource(if (template.price.isFree) R.string.price_free else R.string.detail_locked)) }
                when (val membership = state.installed) {
                    LoadState.Loading -> item { LoadingContent() }
                    is LoadState.Failed -> item { ErrorContent(membership.error, onRetryLibrary) }
                    is LoadState.Loaded -> if (membership.value != null) item {
                        Column(verticalArrangement = Arrangement.spacedBy(KareSpacing.sm)) {
                            Text(stringResource(R.string.detail_installed), Modifier.testTag("detail-installed")
                                .semantics { liveRegion = LiveRegionMode.Polite })
                            Text(stringResource(R.string.detail_local_only))
                            Button(onClick = onLibrary, modifier = Modifier.testTag("open-library")) {
                                Text(stringResource(R.string.detail_open_library))
                            }
                        }
                    }
                }
                if (!template.price.isFree) item {
                    Button(onClick = {}, enabled = false, modifier = Modifier.testTag("purchase-unavailable")) {
                        Text(stringResource(R.string.detail_purchase_unavailable))
                    }
                } else if (installed == null) item {
                    Button(onClick = onInstall, enabled = state.canInstall, modifier = Modifier.testTag("detail-install")) {
                        Text(stringResource(if (busy) R.string.detail_installing else R.string.action_install))
                    }
                }
                (state.action as? InstallState.Failed)?.let { failure -> item {
                    Column {
                        Text(stringResource(R.string.detail_install_failed), Modifier.semantics { liveRegion = LiveRegionMode.Polite })
                        Text(stringResource(failure.error.stringResource()))
                        if (state.canInstall) TextButton(onClick = onInstall) { Text(stringResource(R.string.action_retry)) }
                    }
                } }
            }
        }
    }
}

internal fun WidgetSize.detailLabel(): Int = when (this) {
    WidgetSize.SMALL -> R.string.detail_size_small
    WidgetSize.MEDIUM -> R.string.detail_size_medium
    WidgetSize.LARGE -> R.string.detail_size_large
    WidgetSize.ACCESSORY_CIRCULAR -> R.string.detail_size_circular
    WidgetSize.ACCESSORY_RECTANGULAR -> R.string.detail_size_rectangular
}
