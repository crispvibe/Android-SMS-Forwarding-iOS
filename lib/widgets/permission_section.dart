import 'package:flutter/material.dart';
import '../services/permission_service.dart';

class PermissionSection extends StatefulWidget {
  final bool hasSmsPermission;
  final bool hasNotificationPermission;
  final bool isBatteryOptimizationIgnored;
  final PermissionService permissionService;
  final VoidCallback onPermissionChanged;

  const PermissionSection({
    super.key,
    required this.hasSmsPermission,
    required this.hasNotificationPermission,
    required this.isBatteryOptimizationIgnored,
    required this.permissionService,
    required this.onPermissionChanged,
  });

  @override
  State<PermissionSection> createState() => _PermissionSectionState();
}

class _PermissionSectionState extends State<PermissionSection> {
  String _manufacturer = '';

  @override
  void initState() {
    super.initState();
    _loadManufacturer();
  }

  Future<void> _loadManufacturer() async {
    final manufacturer = await widget.permissionService.getDeviceManufacturer();
    setState(() {
      _manufacturer = manufacturer;
    });
  }

  String _getManufacturerDisplayName() {
    if (_manufacturer.contains('xiaomi') || _manufacturer.contains('redmi')) {
      return '小米 / Redmi (HyperOS/MIUI)';
    } else if (_manufacturer.contains('huawei')) {
      return '华为';
    } else if (_manufacturer.contains('honor')) {
      return '荣耀';
    } else if (_manufacturer.contains('oppo')) {
      return 'OPPO';
    } else if (_manufacturer.contains('vivo')) {
      return 'vivo';
    } else if (_manufacturer.contains('oneplus')) {
      return '一加';
    } else if (_manufacturer.contains('samsung')) {
      return '三星';
    } else if (_manufacturer.contains('meizu')) {
      return '魅族';
    }
    return _manufacturer.isNotEmpty 
        ? _manufacturer[0].toUpperCase() + _manufacturer.substring(1) 
        : '未知';
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = widget.hasSmsPermission && 
                       widget.hasNotificationPermission && 
                       widget.isBatteryOptimizationIgnored;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态卡片
          _buildStatusCard(allGranted),
          
          const SizedBox(height: 20),
          
          // 设备信息
          _buildSectionTitle('设备信息'),
          const SizedBox(height: 8),
          _buildDeviceInfoCard(),
          
          const SizedBox(height: 20),
          
          // 必要权限
          _buildSectionTitle('必要权限'),
          const SizedBox(height: 8),
          _buildPermissionCard(
            icon: Icons.message_outlined,
            title: '短信权限',
            subtitle: '读取新短信并进行转发',
            isGranted: widget.hasSmsPermission,
            onTap: () async {
              await widget.permissionService.requestSmsPermission();
              widget.onPermissionChanged();
            },
          ),
          const SizedBox(height: 10),
          _buildPermissionCard(
            icon: Icons.notifications_outlined,
            title: '通知权限',
            subtitle: '显示前台服务通知',
            isGranted: widget.hasNotificationPermission,
            onTap: () async {
              await widget.permissionService.requestNotificationPermission();
              widget.onPermissionChanged();
            },
          ),
          const SizedBox(height: 10),
          _buildPermissionCard(
            icon: Icons.battery_saver_outlined,
            title: '忽略电池优化',
            subtitle: '保持后台服务持续运行',
            isGranted: widget.isBatteryOptimizationIgnored,
            onTap: () async {
              await widget.permissionService.openBatteryOptimizationSettings();
            },
          ),
          
          // 小米特殊权限提示
          if (_manufacturer.contains('xiaomi') || _manufacturer.contains('redmi')) ...[
            const SizedBox(height: 20),
            _buildSectionTitle('小米/HyperOS 专属'),
            const SizedBox(height: 8),
            _buildXiaomiSmsPermissionCard(),
          ],
          
          const SizedBox(height: 20),
          
          // 厂商设置
          _buildSectionTitle('厂商设置（推荐）'),
          const SizedBox(height: 8),
          _buildManufacturerSettingCard(),
          
          const SizedBox(height: 24),
          
          // 声明
          _buildDisclaimer(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF453A).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFFF453A).withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                '法律声明',
                style: TextStyle(
                  color: Color(0xFFFF453A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '本软件仅供学习和技术研究使用\n严禁用于任何非法用途\n使用本软件即表示您同意自行承担所有风险和法律责任',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 11,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '© 2026 anna.tf',
            style: TextStyle(
              color: Color(0xFF48484A),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF8E8E93),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool allGranted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: allGranted
              ? [const Color(0xFF1E3A2F), const Color(0xFF0F1F18)]
              : [const Color(0xFF3A2A1E), const Color(0xFF1F170F)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allGranted
              ? const Color(0xFF34C759).withOpacity(0.3)
              : const Color(0xFFFF9F0A).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: allGranted
                  ? const Color(0xFF34C759).withOpacity(0.15)
                  : const Color(0xFFFF9F0A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              allGranted ? Icons.verified_user : Icons.security,
              color: allGranted ? const Color(0xFF34C759) : const Color(0xFFFF9F0A),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allGranted ? '权限已就绪' : '需要授予权限',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allGranted
                      ? '所有必要权限已授予，服务可以正常运行'
                      : '请授予以下权限以确保短信转发功能正常工作',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_android,
              color: Color(0xFF8E8E93),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '设备厂商',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getManufacturerDisplayName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isGranted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isGranted
                    ? const Color(0xFF34C759).withOpacity(0.12)
                    : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isGranted ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isGranted)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF34C759),
                size: 22,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '授权',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildXiaomiSmsPermissionCard() {
    return GestureDetector(
      onTap: () async {
        // 打开应用权限设置页面
        await widget.permissionService.openAppPermissionSettings();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF9F0A).withOpacity(0.15),
              const Color(0xFFFF6B00).withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF9F0A).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F0A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    color: Color(0xFFFF9F0A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '通知类短信权限',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '小米/HyperOS 必须开启此权限',
                        style: TextStyle(
                          color: Color(0xFFFF9F0A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFFF9F0A),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '请手动开启：',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '设置 → 应用设置 → 应用管理 → SMS → 权限管理 → 通知类短信 → 允许',
                    style: TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManufacturerSettingCard() {
    return GestureDetector(
      onTap: () async {
        await widget.permissionService.openAutoStartSettings();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E5CE6).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.settings_suggest_outlined,
                    color: Color(0xFF5E5CE6),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '自启动管理',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '打开 ${_getManufacturerDisplayName()} 自启动设置',
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF48484A),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF8E8E93),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '请在系统设置中允许 SMS 自启动并关闭后台限制，以确保服务稳定运行',
                      style: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
