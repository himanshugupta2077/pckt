package com.pckt.pckt

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * After the plain alert for a bank SMS: runs Dart's sortAlertMain in a
 * headless engine to store the message and, if the payment is unclear,
 * turn the alert into a question (SmsAlertReceiver.ask). A WorkManager job
 * rather than the receiver itself, which must finish within ~10 s.
 */
class SortAlertWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        // One engine (one extra DB connection) at a time.
        synchronized(lock) { runEngine() }
        return Result.success()
    }

    private fun runEngine() {
        val ctx = applicationContext
        val main = Handler(Looper.getMainLooper())
        val done = CountDownLatch(1)
        var engine: FlutterEngine? = null
        val started = System.currentTimeMillis()
        main.post {
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(ctx)
                loader.ensureInitializationComplete(ctx, null)
                val e = FlutterEngine(ctx)
                engine = e
                MethodChannel(e.dartExecutor.binaryMessenger, "pckt/sms").setMethodCallHandler { call, result ->
                    when (call.method) {
                        "hasPermission" -> result.success(
                            ctx.checkSelfPermission(Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
                        )
                        "readInbox" -> {
                            val since = call.argument<Number>("sinceMillis")?.toLong() ?: 0L
                            val limit = call.argument<Int>("limit") ?: 5000
                            Thread {
                                try {
                                    val rows = readSmsInbox(ctx, since, limit)
                                    main.post { result.success(rows) }
                                } catch (e: Exception) {
                                    main.post { result.error("READ_FAILED", e.message, null) }
                                }
                            }.start()
                        }
                        else -> result.notImplemented()
                    }
                }
                MethodChannel(e.dartExecutor.binaryMessenger, "pckt/alerts").setMethodCallHandler { call, result ->
                    when (call.method) {
                        "job" -> result.success(
                            mapOf(
                                "id" to inputData.getInt(KEY_ID, 0),
                                "body" to inputData.getString(KEY_BODY),
                                "at" to inputData.getLong(KEY_AT, System.currentTimeMillis()),
                            )
                        )
                        "takeAnswers" -> result.success(SortAnswers.take(ctx))
                        "ask" -> {
                            SmsAlertReceiver.ask(
                                ctx,
                                call.argument<Int>("id") ?: 0,
                                call.argument<String>("title") ?: "",
                                call.argument<String>("text") ?: "",
                                call.argument<Boolean>("credit") == true,
                                call.argument<Number>("txnId")?.toLong() ?: -1,
                                call.argument<Number>("rawId")?.toLong() ?: -1,
                            )
                            result.success(null)
                        }
                        "done" -> {
                            result.success(null)
                            done.countDown()
                        }
                        else -> result.notImplemented()
                    }
                }
                e.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "sortAlertMain")
                )
            } catch (t: Throwable) {
                Log.w(TAG, "engine start failed", t)
                done.countDown()
            }
        }
        val finished = done.await(90, TimeUnit.SECONDS)
        Log.i(TAG, "check ${if (finished) "done" else "timed out"} in ${System.currentTimeMillis() - started} ms")
        main.post {
            engine?.destroy()
            // The open app's lists don't see the other connection's writes.
            MainActivity.alerts?.invokeMethod("changed", null)
        }
    }

    companion object {
        private const val TAG = "pckt-alerts"
        private val lock = Any()
        private const val KEY_ID = "id"
        private const val KEY_BODY = "body"
        private const val KEY_AT = "at"

        fun enqueue(context: Context, id: Int, body: String, at: Long) {
            val request = OneTimeWorkRequestBuilder<SortAlertWorker>()
                .setInputData(workDataOf(KEY_ID to id, KEY_BODY to body, KEY_AT to at))
                .apply {
                    // Expedited on 12+; older versions would need a foreground notification.
                    if (Build.VERSION.SDK_INT >= 31) setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                }
                .build()
            WorkManager.getInstance(context).enqueue(request)
        }
    }
}
