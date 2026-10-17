package com.example.kare.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import androidx.lifecycle.*
import androidx.lifecycle.viewmodel.CreationExtras
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.KareApplication
import com.example.kare.MainActivity
import com.example.kare.R
import com.example.kare.core.design.KareSpacing
import com.example.kare.core.localization.stringResource
import com.example.kare.core.presentation.*
import com.example.kare.core.ui.*
import com.example.kare.feature.settings.PreferencesHost

class EditableConfigurationActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
        setResult(RESULT_CANCELED, result)
        if(id <= 0 || AppWidgetManager.getInstance(this).getAppWidgetInfo(id)?.provider != ComponentName(this, EditableReceiver::class.java)) { finish(); return }
        val container = (application as KareApplication).container
        val vm = ViewModelProvider(this, object : ViewModelProvider.Factory {
            override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T = modelClass.cast(
                EditableConfigurationViewModel(id, intent.getStringExtra(INSTALLED_ID), container.editableInstances,
                    { EditableWidget.refresh(applicationContext, id) }, ErrorReporter { operation, error -> Log.e("KareWidget", operation, error); Unit }, extras.createSavedStateHandle()))!!
        })[EditableConfigurationViewModel::class.java]
        setContent {
            PreferencesHost(viewModel(factory = container.viewModelFactory)) {
                val state by vm.state.collectAsStateWithLifecycle()
                LaunchedEffect(state.saved) { if(state.saved) { setResult(RESULT_OK, result); finish() } }
                Scaffold { padding ->
                    Column(Modifier.padding(padding).padding(KareSpacing.lg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
                        ScreenTitle(stringResource(R.string.editable_widget_name))
                        Text(stringResource(R.string.editable_configuration_info))
                        when(val choices = state.choices) {
                            LoadState.Loading -> LoadingContent()
                            is LoadState.Failed -> ErrorContent(choices.error, vm::load)
                            is LoadState.Loaded -> {
                                if(choices.value.isEmpty()) Text(stringResource(R.string.editable_no_designs))
                                choices.value.forEach { widget ->
                                    FilterChip(selected = state.selected == widget.templateId, enabled = !state.saving,
                                        onClick = { vm.select(widget.templateId) }, label = { Text(widget.name) }, modifier = Modifier.heightIn(min = 48.dp))
                                }
                                Button(onClick = vm::save, enabled = state.selected != null && !state.saving) { Text(stringResource(R.string.action_save)) }
                            }
                        }
                        state.error?.let { Text(stringResource(it.stringResource()), Modifier.semantics { liveRegion = LiveRegionMode.Polite }) }
                        TextButton(onClick = { startActivity(Intent(this@EditableConfigurationActivity, MainActivity::class.java)) }) { Text(stringResource(R.string.proverb_open_app)) }
                        TextButton(onClick = { finish() }, enabled = !state.saving) { Text(stringResource(R.string.action_cancel)) }
                    }
                }
            }
        }
    }
    companion object { const val INSTALLED_ID = "installedWidgetId" }
}
