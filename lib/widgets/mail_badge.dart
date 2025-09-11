import 'package:flutter/material.dart';
import '../models/sent_mail_log.dart';

class MailBadge extends StatelessWidget {
  final SentMailLog log;
  final VoidCallback? onTap;
  final bool isLatest;
  final bool isOldest;

  const MailBadge({
    super.key,
    required this.log,
    this.onTap,
    this.isLatest = false,
    this.isOldest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _buildTooltipMessage(),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getBadgeColor(),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
                // 最新バッジに特別な効果を追加
                boxShadow: isLatest ? [
                  BoxShadow(
                    color: _getBadgeColor().withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIcon(),
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getDisplayText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // 最新バッジにNEWチャーム
            if (isLatest)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // 最古バッジに☆チャーム
            if (isOldest)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade700,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor() {
    switch (log.app) {
      case 'gmail':
        return Colors.red;
      case 'outlook':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (log.app) {
      case 'gmail':
        return Icons.mail;
      case 'outlook':
        return Icons.email;
      default:
        return Icons.mail_outline;
    }
  }

  String _getDisplayText() {
    switch (log.app) {
      case 'gmail':
        return 'Gmail';
      case 'outlook':
        return 'Outlook';
      default:
        return 'Mail';
    }
  }

  String _buildTooltipMessage() {
    final dateFormat = '${log.composedAt.month}/${log.composedAt.day} ${log.composedAt.hour.toString().padLeft(2, '0')}:${log.composedAt.minute.toString().padLeft(2, '0')}';
    final bodyPreview = log.body.length > 120 
        ? '${log.body.substring(0, 120)}...'
        : log.body;
    
    String prefix = '';
    if (isLatest) {
      prefix = '🆕 最新のメール\n';
    } else if (isOldest) {
      prefix = '⭐ 最初のメール\n';
    }
    
    return '$prefix'
           '送信: $dateFormat\n'
           '件名: ${log.subject}\n'
           'To: ${log.to}\n'
           '本文: $bodyPreview';
  }
}

class MailBadgeList extends StatelessWidget {
  final List<SentMailLog> logs;
  final Function(SentMailLog)? onLogTap;

  const MailBadgeList({
    super.key,
    required this.logs,
    this.onLogTap,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }

    // 最新順でソート（最新が左に来るように）
    final sortedLogs = List<SentMailLog>.from(logs);
    sortedLogs.sort((a, b) => b.composedAt.compareTo(a.composedAt));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: sortedLogs.asMap().entries.map((entry) {
        final index = entry.key;
        final log = entry.value;
        final isLatest = index == 0; // 最新
        final isOldest = index == sortedLogs.length - 1; // 最初（最古）
        
        return Padding(
          padding: EdgeInsets.only(
            right: index < sortedLogs.length - 1 ? 4 : 0, // 最後の要素以外は右マージン
          ),
          child: MailBadge(
            log: log,
            isLatest: isLatest,
            isOldest: isOldest,
            onTap: () => onLogTap?.call(log),
          ),
        );
      }).toList(),
    );
  }
}
