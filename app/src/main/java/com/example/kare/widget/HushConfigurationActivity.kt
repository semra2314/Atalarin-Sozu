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
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
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

class HushConfigurationActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
        setResult(RESULT_CANCELED, result)
        val provider = AppWidgetManager.getInstance(this).getAppWidgetInfo(id)?.provider
        if (id <= 0 || provider != ComponentName(this, HushReceiver::class.java)) { finish(); return }
        val repository = (application as KareApplication).container.hushInstances
        val vm = ViewModelProvider(this, object : ViewModelProvider.Factory {
            override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T = modelClass.cast(
                HushConfigurationViewModel(id, repository, { HushWidget.refreshAll(applicationContext) },
                    ErrorReporter { operation, error -> Log.e("KareWidget", operation, error); Unit }, extras.createSavedStateHandle()))!!
        })[HushConfigurationViewModel::class.java]
        setContent {
            KareTheme {
                val state by vm.state.collectAsStateWithLifecycle()
                LaunchedEffect(state.saved) {
                    if (state.saved) { setResult(RESULT_OK, result); finish() }
                }
                Scaffold { padding ->
                    Column(Modifier.padding(padding).padding(KareSpacing.lg).verticalScroll(rememberScrollState()),
                        verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
                        ScreenTitle(stringResource(R.string.hush_widget_name))
                        Text(stringResource(R.string.hush_configuration_info))
                        Text(stringResource(R.string.hush_placement_guidance))
                        if (state.recovering) Text(stringResource(R.string.hush_recovery),
                            Modifier.semantics { liveRegion = LiveRegionMode.Polite })
                        when (val choice = state.selection) {
                            LoadState.Loading -> LoadingContent()
                            is LoadState.Failed -> ErrorContent(choice.error, vm::load)
                            is LoadState.Loaded -> {
                                HushLanguage.entries.forEach { option ->
                                    FilterChip(selected = choice.value == option, enabled = !state.saving,
                                        onClick = { vm.select(option) }, label = { Text(stringResource(when(option) {
                                            HushLanguage.APP -> R.string.hush_language_app
                                            HushLanguage.ENGLISH -> R.string.hush_language_english
                                            HushLanguage.TURKISH -> R.string.hush_language_turkish
                                        })) })
                                }
                                state.error?.let { Text(stringResource(it.stringResource()),
                                    Modifier.semantics { liveRegion = LiveRegionMode.Polite }) }
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
