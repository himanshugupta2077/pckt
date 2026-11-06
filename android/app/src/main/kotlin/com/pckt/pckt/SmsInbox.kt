package com.pckt.pckt

import android.content.Context
import android.provider.Telephony

/** Inbox messages newer than [since], oldest first (MainActivity and SortAlertWorker). */
fun readSmsInbox(context: Context, since: Long, limit: Int): List<Map<String, Any?>> {
    val out = ArrayList<Map<String, Any?>>()
    context.contentResolver.query(
        Telephony.Sms.Inbox.CONTENT_URI,
        arrayOf(Telephony.Sms._ID, Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE),
        "${Telephony.Sms.DATE} > ?",
        arrayOf(since.toString()),
        "${Telephony.Sms.DATE} ASC",
    )?.use { c ->
        val id = c.getColumnIndexOrThrow(Telephony.Sms._ID)
        val addr = c.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
        val body = c.getColumnIndexOrThrow(Telephony.Sms.BODY)
        val date = c.getColumnIndexOrThrow(Telephony.Sms.DATE)
        while (c.moveToNext() && out.size < limit) {
            out.add(
                mapOf(
                    "id" to c.getLong(id).toString(),
                    "address" to (c.getString(addr) ?: ""),
                    "body" to (c.getString(body) ?: ""),
                    "date" to c.getLong(date),
                )
            )
        }
    }
    return out
}
