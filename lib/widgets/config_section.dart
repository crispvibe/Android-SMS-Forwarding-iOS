import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ConfigSection extends StatefulWidget {
  final bool isForwardEnabled;
  final bool isAutoStartEnabled;
  final String apiUrl;
  final String groupName;
  final Function(bool) onForwardEnabledChanged;
  final Function(bool) onAutoStartChanged;
  final Function(String) onApiUrlChanged;
  final Function(String) onGroupNameChanged;
  final bool isAllPermissionsGranted;

  const ConfigSection({
    super.key,
    required this.isForwardEnabled,
    required this.isAutoStartEnabled,
    required this.apiUrl,
    required this.groupName,
    required this.onForwardEnabledChanged,
    required this.onAutoStartChanged,
    required this.onApiUrlChanged,
    required this.onGroupNameChanged,
    required this.isAllPermissionsGranted,
  });

  @override
  State<ConfigSection> createState() => _ConfigSectionState();
}

class _ConfigSectionState extends State<ConfigSection> {
  late TextEditingController _apiUrlController;
  late TextEditingController _groupNameController;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController(text: widget.apiUrl);
    _groupNameController = TextEditingController(text: widget.groupName);
  }

  @override
  void didUpdateWidget(ConfigSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiUrl != widget.apiUrl) {
      _apiUrlController.text = widget.apiUrl;
    }
    if (oldWidget.groupName != widget.groupName) {
      _groupNameController.text = widget.groupName;
    }
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _testPush() async {
    if (widget.apiUrl.isEmpty) {
      _showSnackBar('请先填写 Bark API 地址', isError: true);
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final testTitle = Uri.encodeComponent('SMS 转发测试');
      final testContent = Uri.encodeComponent('如果您收到此消息，说明配置正确！');
      final group = Uri.encodeComponent(widget.groupName);
      
      final url = '${widget.apiUrl.trimRight().replaceAll(RegExp(r'/+$'), '')}/$testTitle/$testContent?group=$group&isArchive=1';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        _showSnackBar('测试推送成功！', isError: false);
      } else {
        _showSnackBar('推送失败，状态码: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnackBar('推送失败: $e', isError: true);
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? const Color(0xFFFF453A) : const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主开关卡片
          _buildMainSwitchCard(),
          
          const SizedBox(height: 16),
          
          // API 配置
          _buildSectionTitle('Bark API 配置'),
          const SizedBox(height: 8),
          _buildApiConfigCard(),
          
          const SizedBox(height: 16),
          
          // 其他设置
          _buildSectionTitle('其他设置'),
          const SizedBox(height: 8),
          _buildOtherSettingsCard(),
          
          const SizedBox(height: 16),
          
          // 关于信息
          _buildSectionTitle('关于'),
          const SizedBox(height: 8),
          _buildAboutCard(),
          
          const SizedBox(height: 32),
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

  Widget _buildMainSwitchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isForwardEnabled && widget.isAllPermissionsGranted
              ? [const Color(0xFF1E3A2F), const Color(0xFF0F1F18)]
              : [const Color(0xFF2C1F1F), const Color(0xFF1A1212)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isForwardEnabled && widget.isAllPermissionsGranted
              ? const Color(0xFF34C759).withOpacity(0.3)
              : const Color(0xFFFF453A).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.isForwardEnabled && widget.isAllPermissionsGranted
                      ? const Color(0xFF34C759).withOpacity(0.15)
                      : const Color(0xFFFF453A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isForwardEnabled && widget.isAllPermissionsGranted
                      ? Icons.sync
                      : Icons.sync_disabled,
                  color: widget.isForwardEnabled && widget.isAllPermissionsGranted
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF453A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '短信转发',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isForwardEnabled && widget.isAllPermissionsGranted
                          ? '服务正在运行'
                          : widget.isForwardEnabled
                              ? '请先授予所有权限'
                              : '服务已停止',
                      style: TextStyle(
                        color: const Color(0xFF8E8E93),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: widget.isForwardEnabled,
                  onChanged: widget.onForwardEnabledChanged,
                ),
              ),
            ],
          ),
          if (!widget.isAllPermissionsGranted && widget.isForwardEnabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F0A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF9F0A),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '请前往权限页面授予所有必要权限',
                      style: TextStyle(
                        color: const Color(0xFFFF9F0A),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApiConfigCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // API 地址输入
          const Text(
            'API 地址',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiUrlController,
            onChanged: widget.onApiUrlChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'https://api.day.app/your_key',
              hintStyle: const TextStyle(color: Color(0xFF48484A)),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 分组名称输入
          const Text(
            '推送分组',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _groupNameController,
            onChanged: widget.onGroupNameChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'SMS',
              hintStyle: const TextStyle(color: Color(0xFF48484A)),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 测试按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTesting ? null : _testPush,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF0A84FF).withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '发送测试推送',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.rocket_launch_outlined,
            title: '开机自启',
            subtitle: '设备重启后自动启动转发服务',
            trailing: Transform.scale(
              scale: 0.85,
              child: Switch(
                value: widget.isAutoStartEnabled,
                onChanged: widget.onAutoStartChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8E8E93),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
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
          trailing,
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'sms',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMS Forwarder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2C2C2E), height: 1),
          const SizedBox(height: 16),
          _buildAboutItem(
            title: '官网',
            value: 'www.anna.tf',
            onTap: () => _launchUrl('https://www.anna.tf'),
          ),
          const SizedBox(height: 12),
          _buildAboutItem(
            title: 'GitHub',
            value: '查看源代码',
            onTap: () => _launchUrl('https://github.com/crispvibe/Android-SMS-Forwarding-iOS'),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2C2C2E), height: 1),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '免责声明：本软件仅供学习和技术研究使用，禁止用于任何非法用途。使用本软件即表示您同意自行承担所有风险和法律责任。',
              style: TextStyle(
                color: Color(0xFF636366),
                fontSize: 11,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '© 2026 anna.tf',
              style: TextStyle(
                color: Color(0xFF636366),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0A84FF),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF48484A),
                size: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
