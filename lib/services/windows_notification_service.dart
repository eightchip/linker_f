import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import '../models/task_item.dart';
import '../services/settings_service.dart';

class WindowsNotificationService {
  static bool _isInitialized = false;
  static late final DynamicLibrary _user32;
  static late final DynamicLibrary _winmm;
  static late final int Function(int, Pointer<Utf16>, Pointer<Utf16>, int, Pointer<Utf16>, int, int) _messageBoxW;
  static late final int Function(int, int) _playSound;
  
  // シンプルなタイマー管理
  static final Map<String, Timer> _scheduledTimers = {};

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 基本的なWindows APIを初期化
      _user32 = DynamicLibrary.open('user32.dll');
      _messageBoxW = _user32.lookupFunction<
          Int32 Function(IntPtr, Pointer<Utf16>, Pointer<Utf16>, Uint32, Pointer<Utf16>, IntPtr, IntPtr),
          int Function(int, Pointer<Utf16>, Pointer<Utf16>, int, Pointer<Utf16>, int, int)>('MessageBoxW');

      // 音声再生用のAPIを初期化
      _winmm = DynamicLibrary.open('winmm.dll');
      _playSound = _winmm.lookupFunction<
          Int32 Function(Uint32, IntPtr),
          int Function(int, int)>('PlaySoundW');

      _isInitialized = true;
      print('Windows通知サービス初期化完了');
    } catch (e) {
      print('Windows通知サービス初期化エラー: $e');
    }
  }

  // メッセージボックスを表示（最も確実な方法）
  static Future<void> _showMessageBox(String title, String message) async {
    try {
      final titlePtr = title.toNativeUtf16();
      final messagePtr = message.toNativeUtf16();
      
      final result = _messageBoxW(
        0, // hWnd
        messagePtr, // lpText
        titlePtr, // lpCaption
        MB_OK | MB_ICONINFORMATION | MB_TOPMOST, // uType (最前面表示)
        nullptr, // lpHelpInfo
        0, // dwLanguageId
        0, // dwContextHelpId
      );

      if (result == IDOK) {
        print('メッセージボックス表示成功: $title');
      }

      // メモリを解放
      calloc.free(titlePtr);
      calloc.free(messagePtr);
    } catch (e) {
      print('メッセージボックス表示エラー: $e');
    }
  }

  // システムサウンドを再生
  static Future<void> _playNotificationSound() async {
    try {
      // 設定で通知音が有効になっているかチェック
      final settingsService = SettingsService();
      final shouldPlaySound = settingsService.notificationSound;
      
      if (!shouldPlaySound) {
        print('通知音が無効になっているため、音を再生しません');
        return;
      }

      // システムサウンドを再生（アスタリスク音）
      final result = _playSound(SND_ALIAS | SND_ASYNC, 0);
      
      if (result == 0) {
        print('通知音再生成功');
      } else {
        print('通知音再生失敗: エラーコード $result');
      }
    } catch (e) {
      print('通知音再生エラー: $e');
    }
  }

  // シンプルな通知表示
  static Future<void> _showNotification(String title, String message) async {
    try {
      // 通知音を再生
      await _playNotificationSound();
      
      await _showMessageBox(title, message);
    } catch (e) {
      print('通知表示エラー: $e');
      // 最終手段: コンソール出力
      print('=== 通知 ===');
      print('タイトル: $title');
      print('メッセージ: $message');
      print('==========');
    }
  }

  // Windowsネイティブトースト通知を表示（シンプル版）
  static Future<void> showToastNotification(String title, String message, {String? taskId}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _showNotification(title, message);
    } catch (e) {
      print('トースト通知エラー: $e');
      // フォールバック: メッセージボックス
      await _showMessageBox(title, message);
    }
  }

  // タスクリマインダー通知をスケジュール（シンプルで確実な方法）
  static Future<void> scheduleTaskReminder(TaskItem task) async {
    if (task.reminderTime == null) return;

    try {
      print('=== タスクリマインダー設定開始 ===');
      print('タスク: ${task.title}');
      print('リマインダー時間: ${task.reminderTime}');
      
      final now = DateTime.now();
      final reminderTime = task.reminderTime!;
      
      // 既存のタイマーをキャンセル
      await cancelNotification(task.id);
      
      if (reminderTime.isBefore(now)) {
        // 期限切れの場合は即座に通知
        print('期限切れタスクのため即座に通知');
        await _showNotification(
          '期限切れタスク',
          '${task.title}の期限が過ぎています',
        );
        return;
      }

      // 期限までの時間を計算
      final duration = reminderTime.difference(now);
      
      // すべてのリマインダーをタイマーで設定（即座に通知しない）
      print('リマインダーをタイマーで設定: ${duration.inMinutes}分後');
      
      // シンプルなタイマーを設定
      final timer = Timer(duration, () async {
        try {
          print('=== タスクリマインダー実行 ===');
          print('タスク: ${task.title}');
          print('実行時刻: ${DateTime.now()}');
          
          await _showNotification(
            'タスクリマインダー',
            '${task.title}の期限が近づいています',
          );
          
          // タイマーをクリーンアップ
          _scheduledTimers.remove(task.id);
          
          print('=== タスクリマインダー完了 ===');
        } catch (e) {
          print('タスクリマインダー実行エラー: $e');
        }
      });
      
      // タイマーを保存
      _scheduledTimers[task.id] = timer;
      
      print('リマインダー設定成功: ${task.title}');
      print('現在時刻: ${now}');
      print('通知予定時刻: ${reminderTime}');
      print('通知予定時間: ${duration.inMinutes}分後');
      print('=== タスクリマインダー設定完了 ===');
      
    } catch (e) {
      print('タスクリマインダー設定エラー: $e');
    }
  }

  // 通知をキャンセル
  static Future<void> cancelNotification(String taskId) async {
    try {
      // タイマーをキャンセル
      final timer = _scheduledTimers[taskId];
      if (timer != null) {
        timer.cancel();
        _scheduledTimers.remove(taskId);
      }
      
      print('通知キャンセル成功: $taskId');
    } catch (e) {
      print('通知キャンセルエラー: $e');
    }
  }

  // すべての通知をキャンセル
  static Future<void> cancelAllNotifications() async {
    try {
      // すべてのタイマーをキャンセル
      for (final timer in _scheduledTimers.values) {
        timer.cancel();
      }
      _scheduledTimers.clear();
      
      print('すべての通知をキャンセルしました');
    } catch (e) {
      print('通知全キャンセルエラー: $e');
    }
  }

  // テスト通知
  static Future<void> showTestNotification() async {
    try {
      // 通知音を再生
      await _playNotificationSound();
      
      await _showNotification(
        'テスト通知',
        'Windows通知機能が正常に動作しています',
      );
    } catch (e) {
      print('テスト通知エラー: $e');
    }
  }

  // リマインダーテスト通知
  static Future<void> showTestReminderNotification() async {
    try {
      // 通知音を再生
      await _playNotificationSound();
      
      await _showNotification(
        'リマインダーテスト',
        'Windowsリマインダー機能が正常に動作しています',
        );
    } catch (e) {
      print('リマインダーテスト通知エラー: $e');
    }
  }

  // 1分後のテストリマインダー（確実に動作するテスト）
  static Future<void> showTestReminderInOneMinute() async {
    try {
      print('=== 1分後リマインダーテスト開始 ===');
      
      // 既存のテストタイマーをキャンセル
      final existingTimer = _scheduledTimers['test_reminder'];
      if (existingTimer != null) {
        existingTimer.cancel();
        _scheduledTimers.remove('test_reminder');
      }
      
      // 1分後のタイマーを設定
      final timer = Timer(const Duration(minutes: 1), () async {
        try {
          print('=== 1分後リマインダーテスト実行 ===');
          await _showNotification(
            '1分後リマインダーテスト',
            'この通知が表示されれば、リマインダー機能が正常に動作しています！',
          );
          _scheduledTimers.remove('test_reminder');
          print('=== 1分後リマインダーテスト完了 ===');
        } catch (e) {
          print('1分後リマインダーテスト実行エラー: $e');
        }
      });
      
      // タイマーを保存
      _scheduledTimers['test_reminder'] = timer;
      
      print('1分後のテストリマインダーを設定しました');
      print('1分後にメッセージボックスが表示されます');
      print('現在時刻: ${DateTime.now()}');
      print('通知予定時刻: ${DateTime.now().add(const Duration(minutes: 1))}');
      print('=== 1分後リマインダーテスト設定完了 ===');
      
    } catch (e) {
      print('1分後リマインダーテスト設定エラー: $e');
    }
  }

  // クリーンアップ
  static void dispose() {
    try {
      // すべてのタイマーをキャンセル
      for (final timer in _scheduledTimers.values) {
        timer.cancel();
      }
      _scheduledTimers.clear();
      
      print('Windows通知サービスクリーンアップ');
    } catch (e) {
      print('Windows通知サービスクリーンアップエラー: $e');
    }
  }

  // 繰り返しリマインダー通知を表示
  static Future<void> _showRecurringReminderNotification(TaskItem task) async {
    try {
      print('=== 繰り返しリマインダー通知表示 ===');
      
      // 次の通知時間を計算
      final nextReminderTime = _calculateNextReminderTime(task);
      
      // 通知を表示
      await _showNotification(
        'タスクリマインダー',
        '${task.title}の期限が近づいています\n\n次の通知: ${_formatDateTime(nextReminderTime)}',
      );
      
      // 次のリマインダーをスケジュール
      await _scheduleNextRecurringReminder(task, nextReminderTime);
      
      print('=== 繰り返しリマインダー通知完了 ===');
    } catch (e) {
      print('繰り返しリマインダー通知エラー: $e');
    }
  }

  // 次のリマインダー時間を計算
  static DateTime _calculateNextReminderTime(TaskItem task) {
    final now = DateTime.now();
    final pattern = task.recurringReminderPattern ?? RecurringReminderPattern.fiveMinutes;
    final duration = RecurringReminderPattern.getDuration(pattern);
    return now.add(duration);
  }

  // 日時をフォーマット
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 次の繰り返しリマインダーをスケジュール
  static Future<void> _scheduleNextRecurringReminder(TaskItem task, DateTime nextTime) async {
    try {
      print('=== 次の繰り返しリマインダー設定 ===');
      print('タスク: ${task.title}');
      print('次の通知時間: $nextTime');
      
      // タスクを更新（次のリマインダー時間とカウントを更新）
      final updatedTask = task.copyWith(
        reminderTime: nextTime,
        nextReminderTime: nextTime,
        reminderCount: task.reminderCount + 1,
      );
      
      // TaskViewModelの更新コールバックを呼び出し
      if (_taskViewModelUpdateCallback != null) {
        _taskViewModelUpdateCallback!(updatedTask);
        print('TaskViewModel更新コールバック実行完了');
      } else {
        print('TaskViewModel更新コールバックが設定されていません');
      }
      
      print('=== 次の繰り返しリマインダー設定完了 ===');
    } catch (e) {
      print('次の繰り返しリマインダー設定エラー: $e');
    }
  }

  // TaskViewModelの参照を保持
  static Function(TaskItem)? _taskViewModelUpdateCallback;

  // TaskViewModelの更新コールバックを設定
  static void setTaskViewModelUpdateCallback(Function(TaskItem) callback) {
    _taskViewModelUpdateCallback = callback;
  }
}
