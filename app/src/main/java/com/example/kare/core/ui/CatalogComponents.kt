package com.example.kare.core.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.example.kare.R
import com.example.kare.core.design.*
import com.example.kare.core.localization.*
import com.example.kare.core.model.*
import com.example.kare.core.presentation.UiError

@Composable
fun ScreenTitle(title: String, modifier: Modifier = Modifier) {
    Text(title, modifier.semantics { heading() }, style = KareTextStyles.display)
}

@Composable
fun LoadingContent() {
    Column(Modifier.fillMaxWidth().padding(KareSpacing.xl), verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
        CircularProgressIndicator()
        Text(stringResource(R.string.loading_widgets))
    }
}

@Composable
fun ErrorContent(error: UiError, onRetry: () -> Unit) {
    Column(Modifier.fillMaxWidth().padding(KareSpacing.lg), verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
        Text(stringResource(R.string.error_title), style = MaterialTheme.typography.titleLarge)
        Text(stringResource(error.stringResource()))
        Button(onClick = onRetry) { Text(stringResource(R.string.action_retry)) }
    }
}

@Composable
fun EmptyContent(title: String, message: String? = null) {
    Column(Modifier.fillMaxWidth().padding(KareSpacing.lg), verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
        Text(title, style = MaterialTheme.typography.headlineSmall)
        message?.let { Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant) }
    }
}

@Composable
fun CategoryChips(selected: WidgetCategory?, onSelect: (WidgetCategory?) -> Unit) {
    LazyRow(horizontalArrangement = Arrangement.spacedBy(KareSpacing.sm)) {
        item { FilterChip(selected = selected == null, onClick = { onSelect(null) },
            label = { Text(stringResource(R.string.all_categories)) }, modifier = Modifier.heightIn(min = 48.dp)) }
        items(WidgetCategory.entries, key = { it.rawValue }) { category ->
            FilterChip(selected = selected == category, onClick = { onSelect(if (selected == category) null else category) },
                label = { Text(stringResource(category.stringResource())) },
                modifier = Modifier.heightIn(min = 48.dp).testTag("category-${category.rawValue}"))
        }
    }
}

@Composable
fun TemplateCard(template: WidgetTemplate, onClick: () -> Unit, modifier: Modifier = Modifier, showArtwork: Boolean = true) {
    val copy = catalogCopy(template.id)
    Card(onClick = onClick, modifier = modifier.testTag("template-${template.id}"), shape = KareShapes.card,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        if (showArtwork) {
            val artwork = catalogArtwork(template.id)
            if (artwork != null) Image(painterResource(artwork), contentDescription = null,
                contentScale = ContentScale.Crop, modifier = Modifier.fillMaxWidth().aspectRatio(1.5f))
            else Surface(color = MaterialTheme.colorScheme.primaryContainer, modifier = Modifier.fillMaxWidth().height(96.dp)) {}
        }
        Column(Modifier.padding(KareSpacing.md), verticalArrangement = Arrangement.spacedBy(KareSpacing.sm)) {
            Text(copy?.let { stringResource(it.name) } ?: template.name, style = MaterialTheme.typography.headlineSmall)
            Text(stringResource(R.string.author_by, template.author.displayName), style = MaterialTheme.typography.bodySmall)
            Text(copy?.let { stringResource(it.summary) } ?: template.summary, style = MaterialTheme.typography.bodyMedium)
            Text(stringResource(template.category.stringResource()), color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(stringResource(if (template.price.isFree) R.string.price_free else R.string.catalog_paid),
                style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
        }
    }
}

@Composable
fun SectionHeader(section: CatalogSection) {
    val copy = catalogSectionStrings(section.id)
    Column(verticalArrangement = Arrangement.spacedBy(KareSpacing.xs)) {
        Text(copy?.let { stringResource(it.title) } ?: section.title,
            style = MaterialTheme.typography.headlineSmall, modifier = Modifier.semantics { heading() })
        val subtitle = if (copy != null) copy.subtitle?.let { stringResource(it) } else section.subtitle
        subtitle?.let { Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant) }
    }
}
