package com.example.varipath

import android.app.NotificationManager
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.varipath/critical_alarm"

    private var savedAlarmVolume: Int? = null
    private var savedMusicVolume: Int? = null
    private var savedInterruptionFilter: Int? = null
    private var savedSpeakerphone: Boolean? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepareCriticalAlarm" -> {
                        prepareCriticalAlarm()
                        result.success(true)
                    }
                    "restoreAudio" -> {
                        restoreAudio()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun audioManager(): AudioManager =
        getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private fun notificationManager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun vibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private fun hasDndAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            notificationManager().isNotificationPolicyAccessGranted
        } else {
            true
        }
    }

    private fun prepareCriticalAlarm() {
        val am = audioManager()

        if (savedAlarmVolume == null) {
            savedAlarmVolume = am.getStreamVolume(AudioManager.STREAM_ALARM)
        }
        if (savedMusicVolume == null) {
            savedMusicVolume = am.getStreamVolume(AudioManager.STREAM_MUSIC)
        }
        if (savedSpeakerphone == null) {
            savedSpeakerphone = am.isSpeakerphoneOn
        }

        am.mode = AudioManager.MODE_NORMAL
        am.isSpeakerphoneOn = true
        am.setStreamVolume(
            AudioManager.STREAM_ALARM,
            am.getStreamMaxVolume(AudioManager.STREAM_ALARM),
            0,
        )
        am.setStreamVolume(
            AudioManager.STREAM_MUSIC,
            am.getStreamMaxVolume(AudioManager.STREAM_MUSIC),
            0,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasDndAccess()) {
            val nm = notificationManager()
            if (savedInterruptionFilter == null) {
                savedInterruptionFilter = nm.currentInterruptionFilter
            }
            if (nm.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_NONE) {
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
            }
        }

        startCriticalVibration()
    }

    private fun startCriticalVibration() {
        val pattern = longArrayOf(0, 500, 250, 500, 250, 700)
        val vibrator = vibrator()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, 0)
        }
    }

    private fun restoreAudio() {
        vibrator().cancel()

        val am = audioManager()
        savedAlarmVolume?.let { am.setStreamVolume(AudioManager.STREAM_ALARM, it, 0) }
        savedMusicVolume?.let { am.setStreamVolume(AudioManager.STREAM_MUSIC, it, 0) }
        savedSpeakerphone?.let { am.isSpeakerphoneOn = it }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasDndAccess()) {
            savedInterruptionFilter?.let { notificationManager().setInterruptionFilter(it) }
        }

        savedAlarmVolume = null
        savedMusicVolume = null
        savedInterruptionFilter = null
        savedSpeakerphone = null
    }
}
