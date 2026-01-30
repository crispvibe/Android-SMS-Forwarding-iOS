package com.sms.forwarder.sms_forwarder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Telephony
import android.util.Log
import androidx.core.app.NotificationCompat
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import kotlin.concurrent.thread
import org.json.JSONObject
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.*

class SmsForwarderService : Service() {
    
    companion object {
        private const val TAG = "SmsForwarderService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "sms_forwarder_channel"
        private const val PREFS_NAME = "FlutterSharedPreferences"
    }
    
    private var smsReceiver: BroadcastReceiver? = null
    private var smsObserver: ContentObserver? = null
    private var lastSmsId: Long = 0
    private val processedSms = mutableSetOf<String>()
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "服务创建")
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        // 获取最新短信ID，避免处理旧短信
        lastSmsId = getLastSmsId()
        
        // 方案1: 动态注册广播接收器
        registerSmsReceiver()
        
        // 方案2: ContentObserver 监听短信数据库（备用方案）
        registerSmsObserver()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "服务启动命令")
        
        // 确保接收器已注册
        if (smsReceiver == null) {
            registerSmsReceiver()
        }
        if (smsObserver == null) {
            registerSmsObserver()
        }
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        Log.d(TAG, "服务销毁")
        unregisterSmsReceiver()
        unregisterSmsObserver()
        super.onDestroy()
        
        // 尝试重启服务
        sendBroadcast(Intent(this, RestartReceiver::class.java))
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d(TAG, "任务被移除")
        super.onTaskRemoved(rootIntent)
        restartService()
    }
    
    private fun restartService() {
        val intent = Intent(applicationContext, SmsForwarderService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(intent)
        } else {
            applicationContext.startService(intent)
        }
    }
    
    private fun registerSmsReceiver() {
        if (smsReceiver != null) return
        
        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                Log.d(TAG, "广播接收器触发: ${intent.action}")
                when (intent.action) {
                    Telephony.Sms.Intents.SMS_RECEIVED_ACTION,
                    "android.provider.Telephony.SMS_DELIVER" -> {
                        handleSmsIntent(context, intent)
                    }
                }
            }
        }
        
        val filter = IntentFilter().apply {
            addAction(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
            addAction("android.provider.Telephony.SMS_DELIVER")
            priority = IntentFilter.SYSTEM_HIGH_PRIORITY
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(smsReceiver, filter, RECEIVER_EXPORTED)
        } else {
            registerReceiver(smsReceiver, filter)
        }
        
        Log.d(TAG, "短信广播接收器已注册")
    }
    
    private fun unregisterSmsReceiver() {
        smsReceiver?.let {
            try {
                unregisterReceiver(it)
                Log.d(TAG, "广播接收器已注销")
            } catch (e: Exception) {
                Log.e(TAG, "注销广播接收器失败: ${e.message}")
            }
        }
        smsReceiver = null
    }
    
    private fun registerSmsObserver() {
        if (smsObserver != null) return
        
        smsObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                Log.d(TAG, "ContentObserver 检测到短信变化: $uri")
                checkNewSms()
            }
        }
        
        try {
            contentResolver.registerContentObserver(
                Telephony.Sms.CONTENT_URI,
                true,
                smsObserver!!
            )
            Log.d(TAG, "短信 ContentObserver 已注册")
        } catch (e: Exception) {
            Log.e(TAG, "注册 ContentObserver 失败: ${e.message}")
        }
    }
    
    private fun unregisterSmsObserver() {
        smsObserver?.let {
            try {
                contentResolver.unregisterContentObserver(it)
                Log.d(TAG, "ContentObserver 已注销")
            } catch (e: Exception) {
                Log.e(TAG, "注销 ContentObserver 失败: ${e.message}")
            }
        }
        smsObserver = null
    }
    
    private fun getLastSmsId(): Long {
        try {
            val cursor = contentResolver.query(
                Telephony.Sms.Inbox.CONTENT_URI,
                arrayOf(Telephony.Sms._ID),
                null, null,
                "${Telephony.Sms._ID} DESC LIMIT 1"
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    return it.getLong(0)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "获取最新短信ID失败: ${e.message}")
        }
        return 0
    }
    
    private fun checkNewSms() {
        thread {
            try {
                val cursor = contentResolver.query(
                    Telephony.Sms.Inbox.CONTENT_URI,
                    arrayOf(
                        Telephony.Sms._ID,
                        Telephony.Sms.ADDRESS,
                        Telephony.Sms.BODY,
                        Telephony.Sms.DATE
                    ),
                    "${Telephony.Sms._ID} > ?",
                    arrayOf(lastSmsId.toString()),
                    "${Telephony.Sms._ID} ASC"
                )
                
                cursor?.use {
                    while (it.moveToNext()) {
                        val id = it.getLong(0)
                        val sender = it.getString(1) ?: "未知号码"
                        val body = it.getString(2) ?: ""
                        val timestamp = it.getLong(3)
                        
                        val smsKey = "${sender}_${timestamp}"
                        
                        if (!processedSms.contains(smsKey)) {
                            processedSms.add(smsKey)
                            lastSmsId = id
                            
                            Log.d(TAG, "ContentObserver 发现新短信: $sender")
                            processSms(sender, body, timestamp)
                            
                            // 限制缓存大小
                            if (processedSms.size > 100) {
                                processedSms.clear()
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "检查新短信失败: ${e.message}")
            }
        }
    }
    
    private fun handleSmsIntent(context: Context, intent: Intent) {
        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isEmpty()) return
            
            val smsMap = mutableMapOf<String, StringBuilder>()
            val senderMap = mutableMapOf<String, String>()
            val timeMap = mutableMapOf<String, Long>()
            
            for (message in messages) {
                val sender = message.displayOriginatingAddress ?: "未知号码"
                val body = message.messageBody ?: ""
                val timestamp = message.timestampMillis
                
                val key = "${sender}_${timestamp / 60000}"
                
                if (!smsMap.containsKey(key)) {
                    smsMap[key] = StringBuilder()
                    senderMap[key] = sender
                    timeMap[key] = timestamp
                }
                smsMap[key]?.append(body)
            }
            
            for ((key, bodyBuilder) in smsMap) {
                val sender = senderMap[key] ?: "未知号码"
                val body = bodyBuilder.toString()
                val timestamp = timeMap[key] ?: System.currentTimeMillis()
                
                val smsKey = "${sender}_${timestamp}"
                if (!processedSms.contains(smsKey)) {
                    processedSms.add(smsKey)
                    Log.d(TAG, "广播接收器处理短信: $sender")
                    processSms(sender, body, timestamp)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "处理短信Intent失败: ${e.message}")
        }
    }
    
    private fun processSms(sender: String, body: String, timestamp: Long) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean("flutter.forward_enabled", false)
        val apiUrl = prefs.getString("flutter.api_url", "") ?: ""
        val groupName = prefs.getString("flutter.group_name", "SMS") ?: "SMS"
        
        Log.d(TAG, "处理短信 - 启用: $isEnabled, API: ${apiUrl.take(30)}...")
        
        if (!isEnabled || apiUrl.isEmpty()) {
            Log.d(TAG, "转发未启用或API为空，跳过")
            return
        }
        
        saveLog(sender, body, timestamp)
        forwardSms(apiUrl, sender, body, groupName, timestamp)
    }
    
    private fun saveLog(sender: String, body: String, timestamp: Long) {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
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
            
            val logsArray = JSONArray(logsJson)
            logsArray.put(logEntry)
            
            while (logsArray.length() > 100) {
                logsArray.remove(0)
            }
            
            prefs.edit().putString("flutter.sms_logs", logsArray.toString()).apply()
            Log.d(TAG, "日志已保存")
        } catch (e: Exception) {
            Log.e(TAG, "保存日志失败: ${e.message}")
        }
    }
    
    private fun updateLogStatus(timestamp: Long, status: String) {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val logsJson = prefs.getString("flutter.sms_logs", "[]") ?: "[]"
            val logsArray = JSONArray(logsJson)
            
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
    
    private fun forwardSms(apiUrl: String, sender: String, body: String, groupName: String, timestamp: Long) {
        thread {
            try {
                val title = URLEncoder.encode("短信来自: $sender", "UTF-8")
                val content = URLEncoder.encode(body, "UTF-8")
                val group = URLEncoder.encode(groupName, "UTF-8")
                
                val fullUrl = "${apiUrl.trimEnd('/')}/$title/$content?group=$group&isArchive=1"
                
                Log.d(TAG, "转发 URL: ${fullUrl.take(80)}...")
                
                val url = URL(fullUrl)
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                
                val responseCode = connection.responseCode
                
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    Log.d(TAG, "转发成功")
                    updateLogStatus(timestamp, "success")
                } else {
                    Log.e(TAG, "转发失败: $responseCode")
                    updateLogStatus(timestamp, "failed")
                }
                
                connection.disconnect()
            } catch (e: Exception) {
                Log.e(TAG, "转发异常: ${e.message}")
                updateLogStatus(timestamp, "failed")
            }
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "短信转发服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "保持短信转发服务运行"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SMS 转发服务运行中")
            .setContentText("正在监听新短信")
            .setSmallIcon(android.R.drawable.ic_dialog_email)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}

// 重启接收器
class RestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val serviceIntent = Intent(context, SmsForwarderService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
