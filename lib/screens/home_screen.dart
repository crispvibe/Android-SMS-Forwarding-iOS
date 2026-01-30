import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/permission_service.dart';
import '../services/settings_service.dart';
import '../widgets/config_section.dart';
import '../widgets/log_section.dart';
import '../widgets/permission_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.sms.forwarder/settings');
  final PermissionService _permissionService = PermissionService();
  final SettingsService _settingsService = SettingsService();
  
  bool _isForwardEnabled = false;
  bool _isAutoStartEnabled = false;
  String _apiUrl = '';
  String _groupName = 'SMS';
  List<Map<String, dynamic>> _logs = [];
  
  bool _hasSmsPermission = false;
  bool _hasNotificationPermission = false;
  bool _isBatteryOptimizationIgnored = false;
  
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      _loadLogs();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isForwardEnabled = prefs.getBool('forward_enabled') ?? false;
      _isAutoStartEnabled = prefs.getBool('auto_start_enabled') ?? false;
      _apiUrl = prefs.getString('api_url') ?? '';
      _groupName = prefs.getString('group_name') ?? 'SMS';
    });
    _loadLogs();
    // 启动前台服务（无论开关状态，服务会根据设置决定是否转发）
    _startForegroundService();
  }

  Future<void> _loadLogs() async {
    final logs = await _settingsService.getLogs();
    setState(() {
      _logs = logs;
    });
  }

  Future<void> _checkPermissions() async {
    final smsPermission = await _permissionService.checkSmsPermission();
    final notificationPermission = await _permissionService.checkNotificationPermission();
    final batteryOptimization = await _permissionService.isIgnoringBatteryOptimizations();
    
    setState(() {
      _hasSmsPermission = smsPermission;
      _hasNotificationPermission = notificationPermission;
      _isBatteryOptimizationIgnored = batteryOptimization;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('forward_enabled', _isForwardEnabled);
    await prefs.setBool('auto_start_enabled', _isAutoStartEnabled);
    await prefs.setString('api_url', _apiUrl);
    await prefs.setString('group_name', _groupName);
  }

  void _onForwardEnabledChanged(bool value) {
    setState(() {
      _isForwardEnabled = value;
    });
    _saveSettings();
    if (value) {
      _startForegroundService();
    }
  }

  Future<void> _startForegroundService() async {
    try {
      await _channel.invokeMethod('startForegroundService');
    } catch (e) {
      debugPrint('启动前台服务失败: $e');
    }
  }

  void _onAutoStartChanged(bool value) {
    setState(() {
      _isAutoStartEnabled = value;
    });
    _saveSettings();
  }

  void _onApiUrlChanged(String value) {
    setState(() {
      _apiUrl = value;
    });
    _saveSettings();
  }

  void _onGroupNameChanged(String value) {
    setState(() {
      _groupName = value;
    });
    _saveSettings();
  }

  Future<void> _clearLogs() async {
    await _settingsService.clearLogs();
    _loadLogs();
  }

  bool get _isAllPermissionsGranted =>
      _hasSmsPermission && _hasNotificationPermission && _isBatteryOptimizationIgnored;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'sms',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  // 状态指示器
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isForwardEnabled && _isAllPermissionsGranted
                          ? const Color(0xFF34C759).withOpacity(0.15)
                          : const Color(0xFFFF453A).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isForwardEnabled && _isAllPermissionsGranted
                                ? const Color(0xFF34C759)
                                : const Color(0xFFFF453A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isForwardEnabled && _isAllPermissionsGranted ? '运行中' : '已停止',
                          style: TextStyle(
                            color: _isForwardEnabled && _isAllPermissionsGranted
                                ? const Color(0xFF34C759)
                                : const Color(0xFFFF453A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab 切换
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab('配置', 0),
                    _buildTab('日志', 1),
                    _buildTab('权限', 2),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 内容区域
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  // 配置页面
                  ConfigSection(
                    isForwardEnabled: _isForwardEnabled,
                    isAutoStartEnabled: _isAutoStartEnabled,
                    apiUrl: _apiUrl,
                    groupName: _groupName,
                    onForwardEnabledChanged: _onForwardEnabledChanged,
                    onAutoStartChanged: _onAutoStartChanged,
                    onApiUrlChanged: _onApiUrlChanged,
                    onGroupNameChanged: _onGroupNameChanged,
                    isAllPermissionsGranted: _isAllPermissionsGranted,
                  ),
                  
                  // 日志页面
                  LogSection(
                    logs: _logs,
                    onClearLogs: _clearLogs,
                    onRefresh: _loadLogs,
                  ),
                  
                  // 权限页面
                  PermissionSection(
                    hasSmsPermission: _hasSmsPermission,
                    hasNotificationPermission: _hasNotificationPermission,
                    isBatteryOptimizationIgnored: _isBatteryOptimizationIgnored,
                    permissionService: _permissionService,
                    onPermissionChanged: _checkPermissions,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
          if (index == 1) {
            _loadLogs();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C2C2E) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
