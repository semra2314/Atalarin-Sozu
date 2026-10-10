package com.example.kare.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.*
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.CreationExtras
import com.example.kare.KareApplication
import com.example.kare.R
import com.example.kare.core.design.*
import com.example.kare.core.localization.stringResource
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.core.ui.*

class ProverbConfigurationActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
        setResult(RESULT_CANCELED, result)
        val provider = AppWidgetManager.getInstance(this).getAppWidgetInfo(id)?.provider
        if (id <= 0 || provider != ComponentName(this, ProverbReceiver::class.java)) { finish(); return }
        val repository = (application as KareApplication).container.widgetInstances
        val vm = ViewModelProvider(this, object : ViewModelProvider.Factory {
            override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T = modelClass.cast(
                WidgetConfigurationViewModel(id, repository, { ProverbWidget.refreshAll(applicationContext) },
                    ErrorReporter { operation, error -> Log.e("KareWidget", operation, error); Unit }, extras.createSavedStateHandle()))!!
        })[WidgetConfigurationViewModel::class.java]
        setContent {
            KareTheme {
                val state by vm.state.collectAsStateWithLifecycle()
                LaunchedEffect(state.saved) {
                    if (state.saved) { setResult(RESULT_OK, result); finish() }
                }
                Scaffold { padding ->
                    Column(Modifier.padding(padding).padding(KareSpacing.lg).verticalScroll(rememberScrollState()),
                        verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
                        ScreenTitle(stringResource(R.string.proverb_widget_name))
                        Text(stringResource(R.string.proverb_configuration_info))
                        when (val choice = state.selection) {
                            LoadState.Loading -> LoadingContent()
                            is LoadState.Failed -> ErrorContent(choice.error, vm::load)
                            is LoadState.Loaded -> {
                                ProverbSelection.entries.forEach { option ->
                                    FilterChip(selected = choice.value == option, enabled = !state.saving,
                                        onClick = { vm.select(option) }, label = { Text(stringResource(when(option) {
                                            ProverbSelection.ALL -> R.string.proverb_all
                                            ProverbSelection.PROVERBS -> R.string.proverb_proverbs
                                            ProverbSelection.IDIOMS -> R.string.proverb_idioms
                                        })) })
                                }
                                state.error?.let { Text(stringResource(it.stringResource())) }
                                Button(onClick = vm::save, enabled = !state.saving) { Text(stringResource(R.string.action_save)) }
                            }
                        }
                        TextButton(onClick = { finish() }, enabled = !state.saving) { Text(stringResource(R.string.action_cancel)) }
                    }
                }
            }
        }
    }
}
