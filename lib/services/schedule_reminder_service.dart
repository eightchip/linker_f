import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:intl/intl.dart';
import '../models/schedule_item.dart';
import '../services/settings_service.dart';

/// 予定リマインダーサービス
/// 予定時刻15分前にOutlook風のポップアップモーダルを表示
class ScheduleReminderService {
  static final Map<String, Timer> _scheduledTimers = {};
  static final Set<String> _notifiedSchedules = {};
  static BuildContext? _context;
  static OverlayEntry? _currentReminderOverlay;

  /// アプリのコンテキストを設定（main.dartやapp.dartで呼び出し）
  static void setContext(BuildContext context) {
    _context = context;
  }

  /// 予定のリマインダーをスケジュール
  static Future<void> scheduleReminder(ScheduleItem schedule) async {
    // 既存のタイマーをキャンセル
    await cancelReminder(schedule.id);

    final now = DateTime.now();
    final reminderTime = schedule.startDateTime.subtract(const Duration(minutes: 15));

    // 既に15分前を過ぎている場合はスキップ
    if (reminderTime.isBefore(now)) {
      return;
    }

    // 通知設定をチェック
    final settingsService = SettingsService.instance;
    if (!settingsService.showNotifications) {
      return;
    }

    final duration = reminderTime.difference(now);

    final timer = Timer(duration, () {
      _showReminderDialog(schedule);
      _scheduledTimers.remove(schedule.id);
    });

    _scheduledTimers[schedule.id] = timer;

    if (kDebugMode) {
      print('予定リマインダー設定: ${schedule.title} (${duration.inMinutes}分後)');
    }
  }

  /// リマインダーをキャンセル
  static Future<void> cancelReminder(String scheduleId) async {
    final timer = _scheduledTimers.remove(scheduleId);
    timer?.cancel();

    if (kDebugMode) {
      print('予定リマインダーキャンセル: $scheduleId');
    }
  }

  /// すべてのリマインダーを復元
  static Future<void> restoreReminders(List<ScheduleItem> schedules) async {
    final now = DateTime.now();

    for (final schedule in schedules) {
      final reminderTime = schedule.startDateTime.subtract(const Duration(minutes: 15));

      // 既に15分前を過ぎている場合はスキップ
      if (reminderTime.isBefore(now)) {
        continue;
      }

      // 既に通知済みの場合はスキップ
      if (_notifiedSchedules.contains(schedule.id)) {
        continue;
      }

      await scheduleReminder(schedule);
    }
  }

  /// Outlook風のリマインダーダイアログを表示
  static void _showReminderDialog(ScheduleItem schedule) {
    if (_context == null || !_context!.mounted) {
      print('コンテキストが利用できません。リマインダーをスキップします。');
      return;
    }

    // 通知済みとしてマーク
    _notifiedSchedules.add(schedule.id);

    // 既存のオーバーレイを削除
    _removeCurrentOverlay();

    // 新しいオーバーレイを作成
    _currentReminderOverlay = OverlayEntry(
      builder: (context) => _ReminderOverlay(
        schedule: schedule,
        onDismiss: () {
          _removeCurrentOverlay();
        },
      ),
    );

    // オーバーレイを表示
    Overlay.of(_context!, rootOverlay: true).insert(_currentReminderOverlay!);
  }

  /// 現在のオーバーレイを削除
  static void _removeCurrentOverlay() {
    _currentReminderOverlay?.remove();
    _currentReminderOverlay = null;
  }

  /// すべてのリマインダーをクリア
  static void clearAllReminders() {
    for (final timer in _scheduledTimers.values) {
      timer.cancel();
    }
    _scheduledTimers.clear();
    _notifiedSchedules.clear();
    _removeCurrentOverlay();
  }
}

/// Outlook風のリマインダーオーバーレイ
class _ReminderOverlay extends StatefulWidget {
  final ScheduleItem schedule;
  final VoidCallback onDismiss;

  const _ReminderOverlay({
    required this.schedule,
    required this.onDismiss,
  });

  @override
  State<_ReminderOverlay> createState() => _ReminderOverlayState();
}

class _ReminderOverlayState extends State<_ReminderOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('yyyy/MM/dd HH:mm');
    final hasEndTime = widget.schedule.endDateTime != null;
    final timeText = hasEndTime
        ? '${timeFormat.format(widget.schedule.startDateTime)} - ${timeFormat.format(widget.schedule.endDateTime!)}'
        : timeFormat.format(widget.schedule.startDateTime);

    return Material(
      color: Colors.black54,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '予定のリマインダー',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onDismiss,
                      ),
                    ],
                  ),
                ),
                // コンテンツ
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトル
                      Text(
                        widget.schedule.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 日時
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      // 場所
                      if (widget.schedule.location != null && widget.schedule.location!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.schedule.location!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // メモ
                      if (widget.schedule.notes != null && widget.schedule.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.schedule.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // ボタン
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: widget.onDismiss,
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

