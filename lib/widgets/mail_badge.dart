import 'package:flutter/material.dart';
import '../models/sent_mail_log.dart';

class MailBadge extends StatelessWidget {
  final SentMailLog log;
  final VoidCallback? onTap;

  const MailBadge({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _buildTooltipMessage(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getBadgeColor(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
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
    
    return '送信: $dateFormat\n'
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

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: logs.map((log) => MailBadge(
        log: log,
        onTap: () => onLogTap?.call(log),
      )).toList(),
    );
  }
}
