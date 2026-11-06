package com.pckt.pckt

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * The daily upload of the backup to the user's server: runs Dart's dailySyncMain in a
 * headless engine at 12:00. On failure WorkManager tries again with a growing wait (30 min,
 * 1 h, 1.5 h…: about 12:30, 13:30, 15:00, 17:00, 19:30) until 22:00. Each day is its own one-time job named for its date, so the next
 * day's job can be queued while this one is still running and a fixed 12:00 never drifts.
 */
class DailySyncWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val outcome = synchronized(SortAlertWorker.lock) { runEngine() }
        Log.i(TAG, "daily sync: $outcome (try ${runAttemptCount + 1})")
        return when (outcome) {
            "off" -> Result.success()
            "ok", "stop" -> {
                ensure(applicationContext)
                Result.success()
            }
            // A try before noon can only be a retry that slept past midnight.
            else -> if (LocalTime.now().hour !in 12 until LAST_HOUR) {
                ensure(applicationContext)
                Result.success()
            } else {
                Result.retry()
            }
        }
    }

    private fun runEngine(): String {
        val ctx = applicationContext
        val main = Handler(Looper.getMainLooper())
        val done = CountDownLatch(1)
        var outcome = "retry"
        var engine: FlutterEngine? = null
        main.post {
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(ctx)
                loader.ensureInitializationComplete(ctx, null)
                val e = FlutterEngine(ctx)
                engine = e
                MethodChannel(e.dartExecutor.binaryMessenger, "pckt/sync").setMethodCallHandler { call, result ->
                    if (call.method == "result") {
                        outcome = call.arguments as? String ?: "retry"
                        result.success(null)
                        done.countDown()
                    } else {
                        result.notImplemented()
                    }
                }
                e.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "dailySyncMain")
                )
            } catch (t: Throwable) {
                Log.w(TAG, "engine start failed", t)
                done.countDown()
            }
        }
        // Building the backup plus a 60 s upload.
        if (!done.await(180, TimeUnit.SECONDS)) Log.w(TAG, "daily sync timed out")
        main.post {
            engine?.destroy()
            // The open app's lists don't see the other connection's writes.
            MainActivity.alerts?.invokeMethod("changed", null)
        }
        return outcome
    }

    companion object {
        private const val TAG = "pckt-sync"
        private const val TAG_ALL = "daily-sync"
        private const val LAST_HOUR = 22

        /** Queues the job for the next 12:00 unless it is already queued. */
        fun ensure(context: Context) {
            val now = LocalDateTime.now()
            val today = now.toLocalDate()
            val day: LocalDate = if (now.toLocalTime().isBefore(LocalTime.NOON)) today else today.plusDays(1)
            val at = day.atTime(LocalTime.NOON).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
            val request = OneTimeWorkRequestBuilder<DailySyncWorker>()
                .setInitialDelay((at - System.currentTimeMillis()).coerceAtLeast(0), TimeUnit.MILLISECONDS)
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .setBackoffCriteria(BackoffPolicy.LINEAR, 30, TimeUnit.MINUTES)
                .addTag(TAG_ALL)
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork("$TAG_ALL-$day", ExistingWorkPolicy.KEEP, request)
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelAllWorkByTag(TAG_ALL)
        }
    }
}
