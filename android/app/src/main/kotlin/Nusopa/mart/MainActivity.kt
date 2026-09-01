package Nusopa.mart

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

/** Main Android activity using Flutter embedding v2. */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "incoming_calls",
                "Panggilan masuk",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi panggilan suara dan video Nusopa.Mart"
                enableVibration(true)
                setSound(
                    android.provider.Settings.System.DEFAULT_NOTIFICATION_URI,
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .build()
                )
            }
            getSystemService(Context.NOTIFICATION_SERVICE)
                ?.let { (it as NotificationManager).createNotificationChannel(channel) }
        }
    }
}
