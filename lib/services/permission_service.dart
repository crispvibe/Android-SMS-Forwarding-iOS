import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const _channel = MethodChannel('com.sms.forwarder/settings');

  /// 检查短信权限
  Future<bool> checkSmsPermission() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  /// 请求短信权限
  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// 检查通知权限
  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// 检查是否已忽略电池优化
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 打开电池优化设置
  Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimization');
    } catch (e) {
      // 忽略错误
    }
  }

  /// 打开自启动设置
  Future<void> openAutoStartSettings() async {
    try {
      await _channel.invokeMethod('openAutoStartSettings');
    } catch (e) {
      // 忽略错误
    }
  }

  /// 打开应用权限设置页面
  Future<void> openAppPermissionSettings() async {
    try {
      await _channel.invokeMethod('openAppPermissionSettings');
    } catch (e) {
      // 回退到通用应用设置
      await openAppSettings();
    }
  }

  /// 获取设备厂商
  Future<String> getDeviceManufacturer() async {
    try {
      final result = await _channel.invokeMethod<String>('getDeviceManufacturer');
      return result ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// 启动前台服务
  Future<void> startForegroundService() async {
    try {
      await _channel.invokeMethod('startForegroundService');
    } catch (e) {
      // 忽略错误
    }
  }

  /// 请求所有必要权限
  Future<Map<String, bool>> requestAllPermissions() async {
    final smsGranted = await requestSmsPermission();
    final notificationGranted = await requestNotificationPermission();
    final batteryIgnored = await isIgnoringBatteryOptimizations();

    return {
      'sms': smsGranted,
      'notification': notificationGranted,
      'battery': batteryIgnored,
    };
  }
}
