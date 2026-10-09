package com.example.kare.feature.discover

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.*
import com.example.kare.core.model.CatalogSection
import com.example.kare.core.presentation.LoadState
import com.example.kare.core.ui.*

@Composable
fun DiscoverRoute(viewModel: DiscoverViewModel, onTemplateClick: (String) -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    DiscoverContent(state, viewModel::reload, onTemplateClick)
}

@Composable
fun DiscoverContent(state: LoadState<List<CatalogSection>>, onRetry: () -> Unit, onTemplateClick: (String) -> Unit) {
    LazyColumn(Modifier.fillMaxSize().wrapContentWidth().widthIn(max = KareLayout.wideWidth).fillMaxWidth(),
        contentPadding = PaddingValues(KareSpacing.lg), verticalArrangement = Arrangement.spacedBy(KareSpacing.xl)) {
        item { ScreenTitle(stringResource(R.string.discover_title)) }
        when (state) {
            LoadState.Loading -> item { LoadingContent() }
            is LoadState.Failed -> item { ErrorContent(state.error, onRetry) }
            is LoadState.Loaded -> {
                item { TextButton(onClick = onRetry) { Text(stringResource(R.string.action_refresh)) } }
                if (state.value.all { it.templates.isEmpty() }) item { EmptyContent(stringResource(R.string.catalog_empty)) }
                state.value.filter { it.templates.isNotEmpty() }.forEach { section ->
                    item(key = "heading-${section.id}") { SectionHeader(section) }
                    if (section.style == CatalogSection.Style.COMPACT_LIST) {
                        items(section.templates, key = { "${section.id}-${it.id}" }) { template ->
                            TemplateCard(template, { onTemplateClick(template.id) }, Modifier.fillMaxWidth(), showArtwork = false)
                        }
                    } else item(key = "shelf-${section.id}") {
                        LazyRow(horizontalArrangement = Arrangement.spacedBy(KareSpacing.lg)) {
                            items(section.templates, key = { it.id }) { template ->
                                TemplateCard(template, { onTemplateClick(template.id) }, Modifier.width(if (section.style == CatalogSection.Style.SPOTLIGHT) 280.dp else 220.dp))
                            }
                        }
                    }
                }
            }
        }
    }
}
