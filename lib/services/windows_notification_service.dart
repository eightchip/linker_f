import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'dart:async';
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

  // リマインダー復元用のコールバック
  static Function(List<TaskItem>)? _restoreRemindersCallback;
  
  // タスク取得用のコールバック
  static List<TaskItem> Function()? _getTasksCallback;
  
  // 定期的なリマインダーチェック用のタイマー
  static Timer? _reminderCheckTimer;
  
  // リマインダーチェック間隔（1分）
  static const Duration _reminderCheckInterval = Duration(minutes: 1);
  
  // 復元済みリマインダーの管理
  static final Set<String> _restoredReminders = {};
  
  // 通知済みタスクの管理（重複通知防止）
  static final Set<String> _notifiedTasks = {};

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 500);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('WindowsNotificationService初期化試行 $attempt/$maxRetries');
        
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
        
        // 定期的なリマインダーチェックを開始
        _startReminderCheck();
        
        print('WindowsNotificationService初期化成功');
        return;
      } catch (e) {
        print('WindowsNotificationService初期化エラー (試行 $attempt/$maxRetries): $e');
        
        if (attempt == maxRetries) {
          print('WindowsNotificationService初期化失敗: 最大リトライ回数に達しました');
          // 通知機能を無効化してアプリケーションを継続
          _isInitialized = false;
          return;
        }
        
        // リトライ前に少し待機
        await Future.delayed(retryDelay * attempt);
      }
    }
  }

  // メッセージボックスを表示（安全性向上）
  static Future<void> _showMessageBox(String title, String message) async {
    Pointer<Utf16>? titlePtr;
    Pointer<Utf16>? messagePtr;
    
    try {
      print('メッセージボックス表示開始: $title');
      
      // 文字列をネイティブ形式に変換
      titlePtr = title.toNativeUtf16();
      messagePtr = message.toNativeUtf16();
      
      // メッセージボックスを表示
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
      } else {
        print('メッセージボックス表示結果: $result');
      }
      
    } catch (e) {
      print('メッセージボックス表示エラー: $e');
      // エラーが発生してもアプリを継続
    } finally {
      // メモリを安全に解放
      try {
        if (titlePtr != null) {
          calloc.free(titlePtr);
        }
        if (messagePtr != null) {
          calloc.free(messagePtr);
        }
        print('メッセージボックスメモリ解放完了');
      } catch (freeError) {
        print('メッセージボックスメモリ解放エラー: $freeError');
      }
    }
  }

  // システムサウンドを再生（非同期版 - UI通知をブロックしない）
  static void _playNotificationSoundAsync() {
    // 音声再生は無効化（クラッシュ防止のため）
    print('音声再生は無効化されています（安定性のため）');
  }

  // システムサウンドを再生
  static Future<void> _playNotificationSound() async {
    try {
      // 設定で通知音が有効になっているかチェック
      // SettingsServiceが初期化されていない場合はデフォルトで音を再生
      bool shouldPlaySound = true;
      try {
        final settingsService = SettingsService.instance;
        // 初期化されている場合のみ設定を取得
        if (settingsService.isInitialized) {
          shouldPlaySound = settingsService.notificationSound;
        }
      } catch (e) {
        print('設定サービスのアクセスエラー（デフォルト値を使用）: $e');
        shouldPlaySound = true; // デフォルトで音を再生
      }
      
      if (!shouldPlaySound) {
        print('通知音が無効になっているため、音を再生しません');
        return;
      }

      // システムサウンドを再生（アスタリスク音）- 安全な実行
      try {
        final result = _playSound(SND_ALIAS | SND_ASYNC, 0);
        
        if (result == 0) {
          print('通知音再生成功');
        } else {
          print('通知音再生失敗: エラーコード $result');
        }
      } catch (playError) {
        print('PlaySound API呼び出しエラー: $playError');
        // PlaySound API呼び出しに失敗しても例外を再スローしない
      }
    } catch (e) {
      print('通知音再生エラー: $e');
    }
  }

  // 通知表示（UI + 安全な音声再生）
  static Future<void> _showNotification(String title, String message) async {
    try {
      // 通知設定をチェック
      final settingsService = SettingsService.instance;
      if (!settingsService.showNotifications) {
        print('通知設定がOFFのため通知をスキップ: $title');
        return;
      }
      
      print('=== 通知表示開始 ===');
      print('タイトル: $title');
      print('メッセージ: $message');
      
      // 音声再生は無効化（クラッシュ防止のため）
      print('音声再生は無効化されています（安定性のため）');
      
      // UI通知
      await _showMessageBox(title, message);
      
      print('=== 通知表示完了 ===');
      
    } catch (e) {
      print('通知表示エラー: $e');
      // 最終フォールバック: コンソール出力のみ
      print('=== 最終フォールバック通知 ===');
      print('通知: $title - $message');
      print('=== 最終フォールバック通知完了 ===');
    }
  }

  // Windowsネイティブトースト通知を表示（シンプル版）
  static Future<void> showToastNotification(String title, String message, {String? taskId}) async {
    // 通知設定をチェック
    final settingsService = SettingsService.instance;
    if (!settingsService.showNotifications) {
      print('通知設定がOFFのためトースト通知をスキップ: $title');
      return;
    }
    
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _showNotification(title, message);
    } catch (e) {
      print('トースト通知エラー: $e');
      // エラー時も通知設定がOFFの場合は何もしない
      if (settingsService.showNotifications) {
        // フォールバック: メッセージボックス
        await _showMessageBox(title, message);
      }
    }
  }

  // タスクリマインダー通知をスケジュール（シンプルで確実な方法）
  static Future<void> scheduleTaskReminder(TaskItem task) async {
    if (task.reminderTime == null) return;
    
    // 完了済みや削除済みのタスクはリマインダーを発火しない
    if (task.status == TaskStatus.completed || task.status == TaskStatus.cancelled) {
      print('完了済み/削除済みタスクのためリマインダーをスキップ: ${task.title}');
      return;
    }

    try {
      print('=== タスクリマインダー設定開始 ===');
      print('タスク: ${task.title}');
      print('リマインダー時間: ${task.reminderTime}');
      print('ステータス: ${task.status}');
      
      final now = DateTime.now();
      final reminderTime = task.reminderTime!;
      
      // 既存のタイマーをキャンセル
      await cancelNotification(task.id);
      
      if (reminderTime.isBefore(now)) {
        // 重複通知防止: 既に通知済みのタスクはスキップ
        if (_notifiedTasks.contains(task.id)) {
          print('既に通知済みのためスキップ: ${task.title}');
          return;
        }
        
        // 期限切れの場合は即座に通知
        print('期限切れタスクのため即座に通知');
        
        // 通知済みとしてマーク
        _notifiedTasks.add(task.id);
        
        print('DEBUG: _showNotification呼び出し前');
        try {
          await _showNotification(
            '期限切れタスク',
            '${task.title}の期限が過ぎています',
          );
          print('DEBUG: _showNotification呼び出し完了');
        } catch (e) {
          print('DEBUG: _showNotification呼び出しエラー: $e');
          rethrow;
        }
        print('DEBUG: 期限切れ通知処理完了');
        return;
      }

      // 期限までの時間を計算
      final duration = reminderTime.difference(now);
      
      // すべてのリマインダーをタイマーで設定（即座に通知しない）
      print('リマインダーをタイマーで設定: ${duration.inMinutes}分後');
      
      // シンプルなタイマーを設定
      final timer = Timer(duration, () async {
        try {
          print('=== タスクリマインダー実行開始 ===');
          print('タスク: ${task.title}');
          print('実行時刻: ${DateTime.now()}');
          
          // 通知表示を安全に実行
          try {
            await _showNotification(
              'タスクリマインダー',
              '${task.title}の期限が近づいています',
            );
            print('リマインダー通知表示成功');
          } catch (notificationError) {
            print('リマインダー通知表示エラー: $notificationError');
            // エラーが発生してもアプリを継続
          }
          
          // タイマーをクリーンアップ
          _scheduledTimers.remove(task.id);
          
          print('=== タスクリマインダー実行完了 ===');
        } catch (e) {
          print('タスクリマインダー実行全体エラー: $e');
          // エラーが発生してもタイマーをクリーンアップ
          try {
            _scheduledTimers.remove(task.id);
          } catch (cleanupError) {
            print('タイマークリーンアップエラー: $cleanupError');
          }
        }
      });
      
      // タイマーを保存
      _scheduledTimers[task.id] = timer;
      
      print('リマインダー設定成功: ${task.title}');
      print('現在時刻: $now');
      print('通知予定時刻: $reminderTime');
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
      print('DEBUG: テスト通知開始');
      
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
      print('DEBUG: テストリマインダー通知開始');
      
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
          print('=== 1分後リマインダーテスト実行開始 ===');
          
          // 通知表示を安全に実行
          try {
            await _showNotification(
              '1分後リマインダーテスト',
              'この通知が表示されれば、リマインダー機能が正常に動作しています！',
            );
            print('1分後リマインダーテスト通知表示成功');
          } catch (notificationError) {
            print('1分後リマインダーテスト通知表示エラー: $notificationError');
            // エラーが発生してもアプリを継続
          }
          
          // タイマーをクリーンアップ
          _scheduledTimers.remove('test_reminder');
          print('=== 1分後リマインダーテスト実行完了 ===');
        } catch (e) {
          print('1分後リマインダーテスト実行全体エラー: $e');
          // エラーが発生してもタイマーをクリーンアップ
          try {
            _scheduledTimers.remove('test_reminder');
          } catch (cleanupError) {
            print('テストタイマークリーンアップエラー: $cleanupError');
          }
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

  // クリーンアップ（メモリリーク防止強化）
  static void dispose() {
    try {
      print('=== Windows通知サービスクリーンアップ開始 ===');
      
      // 定期的なリマインダーチェックを停止
      _stopReminderCheck();
      
      // すべてのタイマーをキャンセル
      for (final entry in _scheduledTimers.entries) {
        try {
          entry.value.cancel();
          print('タイマーキャンセル成功: ${entry.key}');
        } catch (timerError) {
          print('タイマーキャンセルエラー (${entry.key}): $timerError');
        }
      }
      _scheduledTimers.clear();
      
      // 復元済みリマインダーをクリア
      _restoredReminders.clear();
      
      // 通知済みタスクをクリア
      _notifiedTasks.clear();
      
      // コールバックをクリア
      _restoreRemindersCallback = null;
      _getTasksCallback = null;
      _taskViewModelUpdateCallback = null;
      
      // 初期化フラグをリセット
      _isInitialized = false;
      
      print('=== Windows通知サービスクリーンアップ完了 ===');
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
    
    // 元のリマインダー時間を基準にする
    if (task.reminderTime != null) {
      // 元の設定時間から次の時間を計算
      DateTime baseTime = task.reminderTime!;
      
      // 現在時刻が元の設定時間を過ぎている場合は、次の周期を計算
      while (baseTime.isBefore(now)) {
        baseTime = baseTime.add(duration);
      }
      
      return baseTime;
    }
    
    // フォールバック: 現在時刻から計算
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

  // 定期的なリマインダーチェックを開始
  static void _startReminderCheck() {
    if (_reminderCheckTimer != null) {
      _reminderCheckTimer!.cancel();
    }
    _reminderCheckTimer = Timer.periodic(_reminderCheckInterval, _checkReminders);
    print('定期的なリマインダーチェックを開始しました');
  }

  // 定期的なリマインダーチェックを停止
  static void _stopReminderCheck() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = null;
    print('定期的なリマインダーチェックを停止しました');
  }

  // リマインダーチェックのメインループ（重複通知防止）
  static void _checkReminders(Timer timer) {
    if (_getTasksCallback == null) {
      print('タスク取得コールバックが設定されていません。リマインダーチェックをスキップします。');
      return;
    }

    // 通知設定をチェック
    final settingsService = SettingsService.instance;
    if (!settingsService.showNotifications) {
      return; // 通知設定がOFFの場合はチェックをスキップ
    }

    final tasks = _getTasksCallback!();
    final now = DateTime.now();

    for (final task in tasks) {
      if (task.reminderTime == null) continue;
      
      // 完了済みや削除済みのタスクはリマインダーを発火しない
      if (task.status == TaskStatus.completed || task.status == TaskStatus.cancelled) {
        continue;
      }

      final reminderTime = task.reminderTime!;

      if (reminderTime.isBefore(now)) {
        if (task.recurringReminderPattern != null) {
          // 繰り返しリマインダーの場合、スキップせずに通知
          print('繰り返しリマインダー通知: ${task.title}');
          _showRecurringReminderNotification(task);
        } else {
          // 単発リマインダーの場合、重複通知防止
          if (_notifiedTasks.contains(task.id)) {
            print('既に通知済みのためスキップ: ${task.title}');
            continue;
          }
          
          print('期限切れタスクのため即座に通知: ${task.title}');
          
          // 通知済みとしてマーク
          _notifiedTasks.add(task.id);
          
          // 単発リマインダーの場合、即座に通知
          _showNotification(
            'タスクリマインダー',
            '${task.title}の期限が近づいています',
          );
        }
      } else if (task.recurringReminderPattern != null) {
        // 繰り返しリマインダーの場合、設定時間まで待つ
        // 既にタイマーが設定されている場合はスキップ
        if (!_scheduledTimers.containsKey(task.id)) {
          final timer = Timer(reminderTime.difference(now), () async {
            _showRecurringReminderNotification(task);
          });
          _scheduledTimers[task.id] = timer;
        }
      } else {
        // 単発リマインダーの場合
        final timer = Timer(reminderTime.difference(now), () async {
          try {
            print('=== 単発リマインダー実行 ===');
            print('タスク: ${task.title}');
            print('実行時刻: ${DateTime.now()}');
            
            // 重複通知防止: 既に通知済みのタスクはスキップ
            if (_notifiedTasks.contains(task.id)) {
              print('既に通知済みのためスキップ: ${task.title}');
              _scheduledTimers.remove(task.id);
              return;
            }
            
            // 通知済みとしてマーク
            _notifiedTasks.add(task.id);
            
            await _showNotification(
              'タスクリマインダー',
              '${task.title}の期限が近づいています',
            );
            
            // タイマーをクリーンアップ
            _scheduledTimers.remove(task.id);
            
            print('=== 単発リマインダー完了 ===');
          } catch (e) {
            print('単発リマインダー実行エラー: $e');
          }
        });
        _scheduledTimers[task.id] = timer;
      }
    }
  }

  // リマインダー復元用のコールバックを設定
  static void setRestoreRemindersCallback(Function(List<TaskItem>) callback) {
    _restoreRemindersCallback = callback;
  }

  // タスク取得用のコールバックを設定
  static void setGetTasksCallback(List<TaskItem> Function() callback) {
    _getTasksCallback = callback;
  }
  
  // リマインダー復元を実行（確実な方法）
  static Future<void> restoreReminders(List<TaskItem> tasks) async {
    try {
      print('=== Windows通知サービス: リマインダー復元開始 ===');
      print('復元対象タスク数: ${tasks.length}');
      print('現在時刻: ${DateTime.now()}');
      
      final now = DateTime.now();
      int restoredCount = 0;
      int skippedCount = 0;
      
      for (final task in tasks) {
        print('--- タスクチェック: ${task.title} ---');
        print('  ID: ${task.id}');
        print('  reminderTime: ${task.reminderTime}');
        print('  status: ${task.status}');
        print('  isRestored: ${_restoredReminders.contains(task.id)}');
        
        if (task.reminderTime == null) {
          print('  → リマインダー時間なし、スキップ');
          skippedCount++;
          continue;
        }
        
        if (task.reminderTime!.isBefore(now)) {
          print('  → 期限切れ、スキップ');
          skippedCount++;
          continue;
        }
        
        if (task.status == TaskStatus.completed) {
          print('  → 完了済み、スキップ');
          skippedCount++;
          continue;
        }
        
        if (_restoredReminders.contains(task.id)) {
          print('  → 既に復元済み、スキップ');
          skippedCount++;
          continue;
        }
        
        print('  → リマインダー復元実行');
        
        try {
          // リマインダーをスケジュール
          await scheduleTaskReminder(task);
          
          // 復元済みとしてマーク
          _restoredReminders.add(task.id);
          restoredCount++;
          
          print('  → リマインダー復元成功');
        } catch (e) {
          print('  → リマインダー復元エラー: $e');
        }
      }
      
      print('=== Windows通知サービス: リマインダー復元完了 ===');
      print('復元されたリマインダー数: $restoredCount');
      print('スキップされたタスク数: $skippedCount');
      print('復元済みリマインダーID: ${_restoredReminders.toList()}');
      
      // リマインダー復元コールバックを実行
      if (_restoreRemindersCallback != null) {
        print('リマインダー復元コールバックを実行');
        _restoreRemindersCallback!(tasks);
      } else {
        print('リマインダー復元コールバックが設定されていません');
      }
    } catch (e) {
      print('Windows通知サービス: リマインダー復元エラー: $e');
      print('エラーの詳細: ${e.toString()}');
      print('スタックトレース: ${StackTrace.current}');
    }
  }
}
