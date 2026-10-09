package com.example.kare.feature.search

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.*
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.*
import com.example.kare.core.model.WidgetCategory
import com.example.kare.core.presentation.LoadState
import com.example.kare.core.ui.*

@Composable
fun SearchRoute(viewModel: SearchViewModel, onTemplateClick: (String) -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    SearchContent(state, viewModel::setQuery, viewModel::setCategory, viewModel::retry, onTemplateClick)
}

@Composable
fun SearchContent(state: SearchUiState, onQueryChange: (String) -> Unit, onCategorySelect: (WidgetCategory?) -> Unit,
    onRetry: () -> Unit, onTemplateClick: (String) -> Unit) {
    val keyboard = LocalSoftwareKeyboardController.current
    LazyColumn(Modifier.fillMaxSize().wrapContentWidth().widthIn(max = KareLayout.readableWidth).fillMaxWidth(), contentPadding = PaddingValues(KareSpacing.lg),
        verticalArrangement = Arrangement.spacedBy(KareSpacing.lg)) {
        item { ScreenTitle(stringResource(R.string.search_title)) }
        item {
            OutlinedTextField(state.query, onQueryChange, modifier = Modifier.fillMaxWidth().testTag("search-query"),
                label = { Text(stringResource(R.string.search_hint)) }, singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { keyboard?.hide() }),
                trailingIcon = { if (state.query.isNotEmpty()) TextButton(onClick = { onQueryChange("") }) { Text(stringResource(R.string.search_clear)) } })
        }
        item { CategoryChips(state.category, onCategorySelect) }
        when (val results = state.results) {
            LoadState.Loading -> item { LoadingContent() }
            is LoadState.Failed -> item { ErrorContent(results.error, onRetry) }
            is LoadState.Loaded -> {
                if (results.value.isEmpty()) item { EmptyContent(stringResource(R.string.search_empty_title), stringResource(R.string.search_empty_message)) }
                items(results.value, key = { it.id }) { template ->
                    TemplateCard(template, { onTemplateClick(template.id) }, Modifier.fillMaxWidth())
                }
            }
        }
    }
}
