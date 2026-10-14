package com.example.kare.feature.profile

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.kare.R
import com.example.kare.core.data.profile.ProfileAvatarStore
import com.example.kare.core.design.KareDesign
import com.example.kare.core.design.KareSerif
import com.example.kare.core.model.UserProfile
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditProfileSheet(
    userProfile: UserProfile,
    onDismiss: () -> Unit,
    onSave: (displayName: String, username: String, avatarPath: String?) -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val avatarStore = remember { ProfileAvatarStore(context) }
    val colors = KareDesign.colors

    var displayName by remember { mutableStateOf(userProfile.displayName) }
    var username by remember { mutableStateOf(userProfile.username) }
    var currentAvatarPath by remember { mutableStateOf(userProfile.avatarPath) }

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent(),
    ) { uri: Uri? ->
        uri?.let {
            coroutineScope.launch {
                context.contentResolver.openInputStream(it)?.use { stream ->
                    avatarStore.saveAvatar(stream).onSuccess { path ->
                        currentAvatarPath = path
                    }
                }
            }
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = colors.surface,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 36.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = stringResource(R.string.profile_edit_title),
                style = MaterialTheme.typography.headlineSmall,
                fontFamily = KareSerif,
                color = colors.textPrimary,
            )

            Spacer(modifier = Modifier.height(20.dp))

            ProfileAvatar(
                name = displayName.ifBlank { "User" },
                avatarPath = currentAvatarPath,
                size = 90.dp,
                modifier = Modifier.clickable { photoPickerLauncher.launch("image/*") },
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row {
                Button(
                    onClick = { photoPickerLauncher.launch("image/*") },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = colors.accent.copy(alpha = 0.12f),
                        contentColor = colors.accent,
                    ),
                    shape = RoundedCornerShape(8.dp),
                ) {
                    Text(
                        text = stringResource(R.string.profile_edit_change_photo),
                        style = MaterialTheme.typography.labelMedium,
                    )
                }

                if (!currentAvatarPath.isNullOrBlank()) {
                    Spacer(modifier = Modifier.width(8.dp))
                    OutlinedButton(
                        onClick = {
                            coroutineScope.launch {
                                avatarStore.deleteAvatar()
                                currentAvatarPath = null
                            }
                        },
                        shape = RoundedCornerShape(8.dp),
                    ) {
                        Text(
                            text = stringResource(R.string.profile_edit_remove_photo),
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.error,
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            OutlinedTextField(
                value = displayName,
                onValueChange = { displayName = it },
                label = { Text(stringResource(R.string.profile_edit_name_label)) },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = colors.accent,
                    unfocusedBorderColor = colors.border,
                ),
            )

            Spacer(modifier = Modifier.height(14.dp))

            OutlinedTextField(
                value = username,
                onValueChange = { username = it.removePrefix("@").filter { char -> char.isLetterOrDigit() || char == '_' } },
                label = { Text(stringResource(R.string.profile_edit_username_label)) },
                prefix = { Text("@") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = colors.accent,
                    unfocusedBorderColor = colors.border,
                ),
            )

            Spacer(modifier = Modifier.height(24.dp))

            Row(modifier = Modifier.fillMaxWidth()) {
                OutlinedButton(
                    onClick = onDismiss,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                ) {
                    Text(stringResource(R.string.profile_edit_cancel))
                }

                Spacer(modifier = Modifier.width(12.dp))

                Button(
                    onClick = {
                        onSave(displayName, username, currentAvatarPath)
                        onDismiss()
                    },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = colors.accent,
                        contentColor = colors.onInk,
                    ),
                ) {
                    Text(stringResource(R.string.profile_edit_save))
                }
            }
        }
    }
}
