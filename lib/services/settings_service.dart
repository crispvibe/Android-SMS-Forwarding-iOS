import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  /// 获取日志列表
  Future<List<Map<String, dynamic>>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 重新加载以获取原生代码写入的最新数据
      await prefs.reload();
      final logsJson = prefs.getString('sms_logs') ?? '[]';
      final List<dynamic> logsList = json.decode(logsJson);
      
      // 倒序排列，最新的在前面
      final logs = logsList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
          .reversed
          .toList();
      
      return logs;
    } catch (e) {
      return [];
    }
  }

  /// 清空日志
  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sms_logs', '[]');
  }

  /// 添加日志
  Future<void> addLog({
    required String sender,
    required String body,
    required String status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString('sms_logs') ?? '[]';
      final List<dynamic> logsList = json.decode(logsJson);
      
      final now = DateTime.now();
      final timeStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      logsList.add({
        'sender': sender,
        'body': body,
        'time': timeStr,
        'timestamp': now.millisecondsSinceEpoch,
        'status': status,
      });
      
      // 只保留最近 100 条日志
      while (logsList.length > 100) {
        logsList.removeAt(0);
      }
      
      await prefs.setString('sms_logs', json.encode(logsList));
    } catch (e) {
      // 忽略错误
    }
  }

  /// 获取设置
  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'forward_enabled': prefs.getBool('forward_enabled') ?? false,
      'auto_start_enabled': prefs.getBool('auto_start_enabled') ?? false,
      'api_url': prefs.getString('api_url') ?? '',
      'group_name': prefs.getString('group_name') ?? 'SMS',
    };
  }

  /// 保存设置
  Future<void> saveSettings({
    bool? forwardEnabled,
    bool? autoStartEnabled,
    String? apiUrl,
    String? groupName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (forwardEnabled != null) {
      await prefs.setBool('forward_enabled', forwardEnabled);
    }
    if (autoStartEnabled != null) {
      await prefs.setBool('auto_start_enabled', autoStartEnabled);
    }
    if (apiUrl != null) {
      await prefs.setString('api_url', apiUrl);
    }
    if (groupName != null) {
      await prefs.setString('group_name', groupName);
    }
  }
}
