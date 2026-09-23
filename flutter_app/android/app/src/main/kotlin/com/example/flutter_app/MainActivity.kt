package com.example.flutter_app

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.elderlycare/phone_call"
    private val VOICE_SETUP_CHANNEL = "com.elderlycare/voice_setup"
    private val MEDIA_SAVE_CHANNEL = "com.elderlycare/media_save"
    private val CALL_PERMISSION_REQUEST_CODE = 1001
    private var pendingPhoneNumber: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configureVoiceSetupChannel(flutterEngine)
        configureMediaSaveChannel(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "makeDirectCall") {
                val phoneNumber = call.argument<String>("phoneNumber")
                if (phoneNumber.isNullOrEmpty()) {
                    result.error("INVALID_NUMBER", "Phone number is empty", null)
                    return@setMethodCallHandler
                }
                directCall(phoneNumber)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun configureMediaSaveChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_SAVE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveMedia") {
                    val bytes = call.argument<ByteArray>("bytes")
                    val displayName = call.argument<String>("displayName")
                    val mimeType = call.argument<String>("mimeType")
                    val type = call.argument<String>("type")
                    if (bytes == null || bytes.isEmpty()) {
                        result.error("NO_DATA", "Media data is empty", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val saved = saveToMediaStore(
                            bytes,
                            displayName ?: "cognitivecare_media",
                            mimeType ?: "application/octet-stream",
                            type ?: "image"
                        )
                        result.success(saved)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message ?: "Failed to save media", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveToMediaStore(data: ByteArray, displayName: String, mimeType: String, type: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH,
                    if (type == "audio") Environment.DIRECTORY_MUSIC else Environment.DIRECTORY_PICTURES)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val collection = if (type == "audio")
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            else
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("Could not create media entry")
            contentResolver.openOutputStream(uri)?.use {
                it.write(data)
            } ?: throw IllegalStateException("Could not open output stream")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            return uri.toString()
        } else {
            val subDir = if (type == "audio") Environment.DIRECTORY_MUSIC else Environment.DIRECTORY_PICTURES
            val dir = getExternalFilesDir(subDir) ?: this.filesDir
            if (!dir.exists()) dir.mkdirs()
            val target = File(dir, displayName)
            target.writeBytes(data)
            return target.absolutePath
        }
    }

    private fun configureVoiceSetupChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_SETUP_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openSettings") {
                    val setting = call.argument<String>("setting")
                    openVoiceSettings(setting)
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun openVoiceSettings(setting: String?) {
        val intent = when (setting) {
            "recognition" -> Intent("android.settings.VOICE_INPUT_SETTINGS")
            else -> Intent("com.android.settings.TTS_SETTINGS")
        }
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun directCall(phoneNumber: String) {
        val cleanNumber = phoneNumber.replace(Regex("[^0-9+]"), "")
        val uri = Uri.parse("tel:$cleanNumber")
        
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
            val callIntent = Intent(Intent.ACTION_CALL, uri)
            callIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(callIntent)
        } else {
            pendingPhoneNumber = cleanNumber
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CALL_PHONE),
                CALL_PERMISSION_REQUEST_CODE
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CALL_PERMISSION_REQUEST_CODE) {
            val phone = pendingPhoneNumber
            pendingPhoneNumber = null
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                if (!phone.isNullOrEmpty()) {
                    val callIntent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$phone"))
                    callIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(callIntent)
                }
            } else {
                if (!phone.isNullOrEmpty()) {
                    val dialIntent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phone"))
                    dialIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(dialIntent)
                }
            }
        }
    }
}

