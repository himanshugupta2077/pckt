package com.pckt.pckt

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * A button on a "which bucket?" question. Only queues the answer and clears
 * the notification; Dart applies it (sort_alerts.dart applyAlertAnswers) at
 * once if the app is running, else on its next start or background check.
 */
class SortActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val choice = intent.getStringExtra(EXTRA_CHOICE) ?: return
        SortAnswers.add(
            context,
            intent.getLongExtra(EXTRA_TXN, -1),
            intent.getLongExtra(EXTRA_RAW, -1),
            choice,
        )
        NotificationManagerCompat.from(context).cancel(intent.getIntExtra(EXTRA_NOTIFICATION, 0))
        MainActivity.alerts?.invokeMethod("changed", null)
    }

    companion object {
        const val EXTRA_CHOICE = "com.pckt.pckt.SORT_CHOICE"
        const val EXTRA_TXN = "com.pckt.pckt.SORT_TXN"
        const val EXTRA_RAW = "com.pckt.pckt.SORT_RAW"
        const val EXTRA_NOTIFICATION = "com.pckt.pckt.SORT_NOTIFICATION"
    }
}

/** Answers not yet applied, in the app's private prefs (ids and a bucket name only). */
object SortAnswers {
    private const val PREFS = "pckt_alerts"
    private const val KEY = "answers"

    @Synchronized
    fun add(context: Context, txnId: Long, rawId: Long, choice: String) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val list = JSONArray(prefs.getString(KEY, "[]"))
        list.put(JSONObject().put("txnId", txnId).put("rawId", rawId).put("choice", choice))
        prefs.edit().putString(KEY, list.toString()).commit()
    }

    @Synchronized
    fun take(context: Context): List<Map<String, Any>> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val list = JSONArray(prefs.getString(KEY, "[]"))
        prefs.edit().remove(KEY).commit()
        return (0 until list.length()).map { i ->
            val o = list.getJSONObject(i)
            mapOf("txnId" to o.getLong("txnId"), "rawId" to o.getLong("rawId"), "choice" to o.getString("choice"))
        }
    }
}
