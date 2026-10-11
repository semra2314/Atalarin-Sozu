package com.example.kare.widget

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.example.kare.R

/** Route-level platform composition; stateless feature content receives only a UI slot. */
@Composable
fun WidgetPlacementRoute(templateId: String) {
    val context = LocalContext.current.applicationContext
    val coordinator = remember(context) { WidgetPlacementCoordinator(AndroidWidgetPlacementManager(context)) }
    var result by rememberSaveable(templateId) { mutableStateOf<PlacementResult?>(null) }
    WidgetPlacementContent(coordinator.hasWidget(templateId), result,
        onPlace = { result = coordinator.request(templateId) }, onDismiss = { result = null })
}

@Composable
fun WidgetPlacementContent(available: Boolean, result: PlacementResult?, onPlace: () -> Unit, onDismiss: () -> Unit) {
    if (!available) return
    TextButton(onClick = onPlace, modifier = Modifier.heightIn(min = 48.dp).testTag("place-widget")) {
        Text(stringResource(R.string.widget_add_home))
    }
    if (result != null) AlertDialog(onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.widget_add_home)) },
        text = {
            Column {
                Text(stringResource(when (result) {
                    PlacementResult.REQUESTED -> R.string.widget_placement_requested
                    PlacementResult.UNSUPPORTED -> R.string.widget_placement_unsupported
                    PlacementResult.UNAVAILABLE -> R.string.widget_placement_unavailable
                }))
                Text(stringResource(R.string.widget_placement_manual))
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.action_dismiss)) } })
}
