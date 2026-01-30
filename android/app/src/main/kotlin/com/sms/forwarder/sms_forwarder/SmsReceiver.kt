package com.sms.forwarder.sms_forwarder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import kotlin.concurrent.thread
import android.content.SharedPreferences
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class SmsReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "SmsReceiver"
        private const val PREFS_NAME = "FlutterSharedPreferences"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("flutter.forward_enabled", false)
            val apiUrl = prefs.getString("flutter.api_url", "") ?: ""
            val groupName = prefs.getString("flutter.group_name", "SMS") ?: "SMS"
            
            if (!isEnabled || apiUrl.isEmpty()) {
                Log.d(TAG, "转发未启用或 API 地址为空")
                return
            }
            
            // 合并同一条短信的所有部分
            val smsMap = mutableMapOf<String, StringBuilder>()
            val senderMap = mutableMapOf<String, String>()
            val timeMap = mutableMapOf<String, Long>()
            
            for (message in messages) {
                val sender = message.displayOriginatingAddress ?: "未知号码"
                val body = message.messageBody ?: ""
                val timestamp = message.timestampMillis
                
                val key = "${sender}_${timestamp / 60000}" // 按分钟分组
                
                if (!smsMap.containsKey(key)) {
                    smsMap[key] = StringBuilder()
                    senderMap[key] = sender
                    timeMap[key] = timestamp
                }
                smsMap[key]?.append(body)
            }
            
            // 发送每条合并后的短信
            for ((key, bodyBuilder) in smsMap) {
                val sender = senderMap[key] ?: "未知号码"
                val body = bodyBuilder.toString()
                val timestamp = timeMap[key] ?: System.currentTimeMillis()
                
                Log.d(TAG, "收到短信: 发送者=$sender, 内容=$body")
                
                // 保存日志
                saveLog(context, sender, body, timestamp)
                
                // 转发短信
                forwardSms(context, apiUrl, sender, body, groupName)
            }
        }
    }
    
    private fun saveLog(context: Context, sender: String, body: String, timestamp: Long) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val logsJson = prefs.getString("flutter.sms_logs", "[]") ?: "[]"
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
            val timeStr = dateFormat.format(Date(timestamp))
            
            val logEntry = JSONObject().apply {
                put("sender", sender)
                put("body", body)
                put("time", timeStr)
                put("timestamp", timestamp)
                put("status", "pending")
            }
            
            // 解析现有日志并添加新日志
            val logsArray = org.json.JSONArray(logsJson)
            logsArray.put(logEntry)
            
            // 只保留最近 100 条日志
            while (logsArray.length() > 100) {
                logsArray.remove(0)
            }
            
            prefs.edit().putString("flutter.sms_logs", logsArray.toString()).apply()
            
        } catch (e: Exception) {
            Log.e(TAG, "保存日志失败: ${e.message}")
        }
    }
    
    private fun updateLogStatus(context: Context, timestamp: Long, status: String) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val logsJson = prefs.getString("flutter.sms_logs", "[]") ?: "[]"
            val logsArray = org.json.JSONArray(logsJson)
            
            for (i in 0 until logsArray.length()) {
                val log = logsArray.getJSONObject(i)
                if (log.getLong("timestamp") == timestamp) {
                    log.put("status", status)
                    break
                }
            }
            
            prefs.edit().putString("flutter.sms_logs", logsArray.toString()).apply()
            
        } catch (e: Exception) {
            Log.e(TAG, "更新日志状态失败: ${e.message}")
        }
    }
    
    private fun forwardSms(context: Context, apiUrl: String, sender: String, body: String, groupName: String) {
        thread {
            try {
                // 构建 Bark API URL
                val title = URLEncoder.encode("短信来自: $sender", "UTF-8")
                val content = URLEncoder.encode(body, "UTF-8")
                val group = URLEncoder.encode(groupName, "UTF-8")
                
                val fullUrl = "${apiUrl.trimEnd('/')}/$title/$content?group=$group&isArchive=1"
                
                Log.d(TAG, "转发 URL: $fullUrl")
                
                val url = URL(fullUrl)
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 10000
                connection.readTimeout = 10000
                
                val responseCode = connection.responseCode
                
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    Log.d(TAG, "短信转发成功")
                    updateLogStatus(context, System.currentTimeMillis(), "success")
                } else {
                    Log.e(TAG, "短信转发失败, 响应码: $responseCode")
                    updateLogStatus(context, System.currentTimeMillis(), "failed")
                }
                
                connection.disconnect()
                
            } catch (e: Exception) {
                Log.e(TAG, "短信转发异常: ${e.message}")
                updateLogStatus(context, System.currentTimeMillis(), "failed")
            }
        }
    }
}
