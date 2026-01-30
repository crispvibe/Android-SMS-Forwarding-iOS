import 'package:flutter/material.dart';

class LogSection extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final VoidCallback onClearLogs;
  final VoidCallback onRefresh;

  const LogSection({
    super.key,
    required this.logs,
    required this.onClearLogs,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部操作栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '共 ${logs.length} 条记录',
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onRefresh,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            color: Color(0xFF0A84FF),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '刷新',
                            style: TextStyle(
                              color: Color(0xFF0A84FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: logs.isEmpty ? null : () => _showClearConfirmDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: logs.isEmpty ? const Color(0xFF48484A) : const Color(0xFFFF453A),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '清空',
                            style: TextStyle(
                              color: logs.isEmpty ? const Color(0xFF48484A) : const Color(0xFFFF453A),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 日志列表
        Expanded(
          child: logs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: logs.length + 1, // +1 for disclaimer
                  itemBuilder: (context, index) {
                    if (index == logs.length) {
                      return _buildDisclaimer();
                    }
                    return _buildLogItem(logs[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2C2C2E),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          Text(
            '本软件仅供学习和技术研究使用',
            style: TextStyle(
              color: Color(0xFF636366),
              fontSize: 11,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '禁止用于任何非法用途',
            style: TextStyle(
              color: Color(0xFFFF453A),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
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

  void _showClearConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '确认清空',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          '确定要清空所有日志记录吗？此操作不可恢复。',
          style: TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(
                color: Color(0xFF0A84FF),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClearLogs();
            },
            child: const Text(
              '清空',
              style: TextStyle(
                color: Color(0xFFFF453A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.history,
              color: Color(0xFF48484A),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无转发记录',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '收到短信后会在这里显示转发记录',
            style: TextStyle(
              color: Color(0xFF48484A),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final sender = log['sender'] ?? '未知号码';
    final body = log['body'] ?? '';
    final time = log['time'] ?? '';
    final status = log['status'] ?? 'pending';
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'success':
        statusColor = const Color(0xFF34C759);
        statusIcon = Icons.check_circle;
        statusText = '已推送';
        break;
      case 'failed':
        statusColor = const Color(0xFFFF453A);
        statusIcon = Icons.error;
        statusText = '失败';
        break;
      default:
        statusColor = const Color(0xFFFF9F0A);
        statusIcon = Icons.schedule;
        statusText = '等待中';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：发送者和状态
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF8E8E93),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sender,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF636366),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 短信内容
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              body,
              style: const TextStyle(
                color: Color(0xFFAEAEB2),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
