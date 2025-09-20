import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task_item.dart';
import 'dart:io';
import 'windows_notification_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // タイムゾーンデータを初期化
      tz.initializeTimeZones();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            linux: initializationSettingsLinux,
          );

      final bool? initialized = await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // 通知タップ時の処理
          print('通知がタップされました: ${response.payload}');
        },
      );
      
      print('通知サービス初期化結果: $initialized');
    } catch (e) {
      print('通知サービス初期化エラー: $e');
    }
  }

  // タスクのリマインダー通知をスケジュール
  static Future<void> scheduleTaskReminder(TaskItem task) async {
    if (task.reminderTime == null) return;

    try {
      // WindowsではzonedScheduleが実装されていないため、
      // 期限が過ぎている場合や5分以内の場合は即座に通知を表示
      final now = DateTime.now();
      final reminderTime = task.reminderTime!;
      
      if (reminderTime.isBefore(now)) {
        // 既に期限が過ぎている場合は即座に通知
        print('期限切れタスクの通知: ${task.title}');
        await showOverdueNotification(task);
        return;
      }

      // 期限までの時間を計算
      final duration = reminderTime.difference(now);
      
      // 5分以内の場合は即座に通知
      if (duration.inMinutes <= 5) {
        print('5分以内のリマインダー通知: ${task.title}');
        await showOverdueNotification(task);
        return;
      }

      // WindowsではzonedScheduleが実装されていないため、
      // スケジュール通知は使用しない
      print('Windows環境ではスケジュール通知が使用できません: ${task.title}');
      print('リマインダー時間: $reminderTime');
      
    } catch (e) {
      print('リマインダー設定エラー: $e');
    }
  }

  // 期限切れタスクの通知
  static Future<void> showOverdueNotification(TaskItem task) async {
    try {
      // Windows環境ではWindows固有の通知サービスを使用
      if (Platform.isWindows) {
        await WindowsNotificationService.showToastNotification(
          '期限切れタスク',
          '${task.title}の期限が過ぎています',
          taskId: task.id,
        );
        return;
      }

      // その他のプラットフォームではflutter_local_notificationsを使用
      const NotificationDetails notificationDetails = NotificationDetails();

      await _notifications.show(
        task.id.hashCode,
        '期限切れタスク',
        '${task.title}の期限が過ぎています',
        notificationDetails,
        payload: task.id,
      );
      
      print('期限切れ通知を送信: ${task.title}');
    } catch (e) {
      print('期限切れ通知エラー: $e');
      // Windowsでは通知が表示されない場合があるため、ログのみ出力
      print('Windows環境では通知が表示されない場合があります');
    }
  }

  // 通知をキャンセル
  static Future<void> cancelNotification(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  // すべての通知をキャンセル
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // テスト用の即座通知
  static Future<void> showTestNotification() async {
    try {
      // Windows環境ではWindows固有の通知サービスを使用
      if (Platform.isWindows) {
        await WindowsNotificationService.showTestNotification();
        return;
      }

      // その他のプラットフォームではflutter_local_notificationsを使用
      const NotificationDetails notificationDetails = NotificationDetails();

      await _notifications.show(
        999,
        'テスト通知',
        '通知機能が正常に動作しています',
        notificationDetails,
      );
      
      print('テスト通知を送信しました');
    } catch (e) {
      print('テスト通知エラー: $e');
      // Windowsでは通知が表示されない場合があるため、エラーをスローしない
      print('Windows環境では通知が表示されない場合があります');
    }
  }

  // リマインダー通知のテスト
  static Future<void> showTestReminderNotification() async {
    try {
      // Windows環境ではWindows固有の通知サービスを使用
      if (Platform.isWindows) {
        await WindowsNotificationService.showTestReminderNotification();
        return;
      }

      // その他のプラットフォームではflutter_local_notificationsを使用
      const NotificationDetails notificationDetails = NotificationDetails();

      await _notifications.show(
        998,
        'リマインダーテスト',
        'リマインダー通知が正常に動作しています',
        notificationDetails,
      );
      
      print('リマインダーテスト通知を送信しました');
    } catch (e) {
      print('リマインダーテスト通知エラー: $e');
    }
  }

  // アプリ内トースト通知を表示（画面中央）
  static void showInAppNotification(BuildContext context, String title, String message, {Color? backgroundColor}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4, // 画面の40%の位置
        left: MediaQuery.of(context).size.width * 0.1, // 画面の10%の位置
        right: MediaQuery.of(context).size.width * 0.1, // 画面の10%の位置
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: backgroundColor ?? Colors.blue,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 3秒後に自動的に消す
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
