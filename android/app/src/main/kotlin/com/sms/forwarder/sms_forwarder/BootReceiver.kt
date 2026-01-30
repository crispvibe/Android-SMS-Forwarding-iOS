package com.sms.forwarder.sms_forwarder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON" ||
            intent.action == Intent.ACTION_REBOOT) {
            
            Log.d(TAG, "系统启动完成，启动短信转发服务")
            
            // 检查是否启用了开机自启
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val autoStartEnabled = prefs.getBoolean("flutter.auto_start_enabled", false)
            
            if (autoStartEnabled) {
                // 启动前台服务
                val serviceIntent = Intent(context, SmsForwarderService::class.java)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                
                Log.d(TAG, "短信转发服务已启动")
            } else {
                Log.d(TAG, "开机自启未启用")
            }
        }
    }
}
