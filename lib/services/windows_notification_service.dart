import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import '../models/task_item.dart';

class WindowsNotificationService {
  static bool _isInitialized = false;
  static late final DynamicLibrary _user32;
  static late final int Function(int, Pointer<Utf16>, Pointer<Utf16>, int, Pointer<Utf16>, int, int) _messageBoxW;
  
  // バックグラウンド通知用のタイマー
  static final Map<String, Timer> _scheduledTimers = {};
  static final Map<String, TaskItem> _scheduledTasks = {};

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 基本的なWindows APIを初期化
      _user32 = DynamicLibrary.open('user32.dll');
      _messageBoxW = _user32.lookupFunction<
          Int32 Function(IntPtr, Pointer<Utf16>, Pointer<Utf16>, Uint32, Pointer<Utf16>, IntPtr, IntPtr),
          int Function(int, Pointer<Utf16>, Pointer<Utf16>, int, Pointer<Utf16>, int, int)>('MessageBoxW');

      _isInitialized = true;
      print('Windows通知サービス初期化完了');
    } catch (e) {
      print('Windows通知サービス初期化エラー: $e');
    }
  }

  // Windowsネイティブトースト通知を表示
  static Future<void> showToastNotification(String title, String message, {String? taskId}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 非ブロッキングのトースト通知を表示
      await _showNonBlockingToastNotification(title, message, taskId);
    } catch (e) {
      print('トースト通知エラー: $e');
      // フォールバック: メッセージボックス
      await _showMessageBox(title, message);
    }
  }

  // 非ブロッキングのトースト通知を表示
  static Future<void> _showNonBlockingToastNotification(String title, String message, String? taskId) async {
    try {
      // バックグラウンドでトースト通知を表示
      // アプリが閉じられていても通知が表示されるようにする
      print('非ブロッキングトースト通知: $title - $message');
      
      // PowerShellを使用してWindows 10/11のトースト通知を表示
      await _showPowerShellToastNotification(title, message);
      
    } catch (e) {
      print('非ブロッキングトースト通知エラー: $e');
      rethrow;
    }
  }

  // PowerShellを使用してWindows 10/11のトースト通知を表示
  static Future<void> _showPowerShellToastNotification(String title, String message) async {
    try {
      // PowerShellスクリプトを作成
      final powershellScript = '''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

\$template = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$title</text>
            <text>$message</text>
        </binding>
    </visual>
</toast>
"@

\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml(\$template)
\$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
\$toast.Tag = "TaskReminder"
\$toast.Group = "TaskReminders"

\$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("LinkerF")
\$notifier.Show(\$toast)
''';

      // 一時的なPowerShellスクリプトファイルを作成
      final tempDir = Directory.systemTemp;
      final scriptFile = File('${tempDir.path}\\show_toast_${DateTime.now().millisecondsSinceEpoch}.ps1');
      await scriptFile.writeAsString(powershellScript);
      
      // PowerShellスクリプトを実行
      final result = await Process.run('powershell', [
        '-ExecutionPolicy', 'Bypass',
        '-File', scriptFile.path
      ]);
      
      if (result.exitCode == 0) {
        print('PowerShellトースト通知成功: $title');
      } else {
        print('PowerShellトースト通知失敗: ${result.stderr}');
        // フォールバック: メッセージボックス
        await _showMessageBox(title, message);
      }
      
      // 一時ファイルを削除
      await scriptFile.delete();
      
    } catch (e) {
      print('PowerShellトースト通知エラー: $e');
      // フォールバック: メッセージボックス
      await _showMessageBox(title, message);
    }
  }

  // メッセージボックスを表示（フォールバック）
  static Future<void> _showMessageBox(String title, String message) async {
    try {
      final titlePtr = title.toNativeUtf16();
      final messagePtr = message.toNativeUtf16();
      
      final result = _messageBoxW(
        0, // hWnd
        messagePtr, // lpText
        titlePtr, // lpCaption
        MB_OK | MB_ICONINFORMATION, // uType
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

  // タスクリマインダー通知をスケジュール
  static Future<void> scheduleTaskReminder(TaskItem task) async {
    if (task.reminderTime == null) return;

    try {
      final now = DateTime.now();
      final reminderTime = task.reminderTime!;
      
      // 既存のタイマーをキャンセル
      await cancelNotification(task.id);
      
      if (reminderTime.isBefore(now)) {
        // 期限切れの場合は即座に通知
        await showToastNotification(
          '期限切れタスク',
          '${task.title}の期限が過ぎています',
          taskId: task.id,
        );
        return;
      }

      // 期限までの時間を計算
      final duration = reminderTime.difference(now);
      
      // 5分以内の場合は即座に通知
      if (duration.inMinutes <= 5) {
        await showToastNotification(
          'リマインダー',
          '${task.title}の期限が近づいています',
          taskId: task.id,
        );
        return;
      }

      // バックグラウンドでタイマーを設定
      final timer = Timer(duration, () async {
        try {
          // リマインダー時間になったら通知を表示
          await showToastNotification(
            'タスクリマインダー',
            '${task.title}の期限が近づいています',
            taskId: task.id,
          );
          
          // タイマーをクリーンアップ
          _scheduledTimers.remove(task.id);
          _scheduledTasks.remove(task.id);
          
          print('スケジュール通知実行: ${task.title}');
        } catch (e) {
          print('スケジュール通知エラー: $e');
        }
      });
      
      // タイマーとタスクを保存
      _scheduledTimers[task.id] = timer;
      _scheduledTasks[task.id] = task;
      
      // PowerShellを使用して永続的な通知を設定
      await _schedulePersistentNotification(task, reminderTime);
      
      print('Windows環境でのスケジュール通知設定: ${task.title} - ${reminderTime}');
      print('通知予定時間: ${duration.inMinutes}分後');
      
    } catch (e) {
      print('Windowsリマインダー設定エラー: $e');
    }
  }

  // PowerShellを使用して永続的な通知を設定
  static Future<void> _schedulePersistentNotification(TaskItem task, DateTime reminderTime) async {
    try {
      // PowerShellスクリプトを作成（トースト通知付き）
      final powershellScript = '''
param(
    [string]\$TaskTitle = "${task.title}",
    [string]\$TaskDescription = "${task.description}",
    [string]\$ReminderTime = "${reminderTime.toString()}"
)

# トースト通知を表示する関数
function Show-ToastNotification {
    param([string]\$Title, [string]\$Message)
    
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        \$template = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>\$Title</text>
            <text>\$Message</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default"/>
</toast>
"@

        \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        \$xml.LoadXml(\$template)
        \$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
        \$toast.Tag = "TaskReminder_\$TaskTitle"
        \$toast.Group = "TaskReminders"

        \$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("LinkerF")
        \$notifier.Show(\$toast)
        
        Write-Host "トースト通知を表示しました: \$Title"
    }
    catch {
        Write-Host "トースト通知エラー: \$_"
        # フォールバック: メッセージボックス
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show("\$Message", "\$Title", "OK", "Information")
    }
}

# メイン処理
Write-Host "タスクリマインダー実行: \$TaskTitle"
Write-Host "期限: \$ReminderTime"

# トースト通知を表示
Show-ToastNotification -Title "タスクリマインダー" -Message "\$TaskTitle`n期限: \$ReminderTime"

# ログファイルに記録
\$logPath = "\$env:TEMP\\task_reminder_log.txt"
\$logEntry = "\$(Get-Date): タスクリマインダー実行 - \$TaskTitle"
Add-Content -Path \$logPath -Value \$logEntry
''';

      // 一時的なPowerShellスクリプトファイルを作成
      final tempDir = Directory.systemTemp;
      final scriptFile = File('${tempDir.path}\\task_reminder_${task.id}.ps1');
      await scriptFile.writeAsString(powershellScript);
      
      // Windows Task Schedulerでタスクを登録
      final taskName = 'TaskReminder_${task.id}';
      final scheduledTime = reminderTime.toUtc();
      
      // schtasksコマンドでタスクをスケジュール（PowerShellスクリプトを実行）
      final result = await Process.run('schtasks', [
        '/create',
        '/tn', taskName,
        '/tr', 'powershell.exe -ExecutionPolicy Bypass -File "${scriptFile.path}"',
        '/sc', 'once',
        '/st', '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
        '/sd', '${scheduledTime.year}-${scheduledTime.month.toString().padLeft(2, '0')}-${scheduledTime.day.toString().padLeft(2, '0')}',
        '/ru', 'SYSTEM', // システム権限で実行
        '/f' // 既存のタスクを上書き
      ]);
      
      if (result.exitCode == 0) {
        print('永続的タスクスケジュール成功: ${task.title}');
        print('スクリプトパス: ${scriptFile.path}');
      } else {
        print('永続的タスクスケジュール失敗: ${result.stderr}');
        // フォールバック: 通常のタイマーのみ使用
        print('フォールバック: アプリ内タイマーのみ使用');
      }
      
    } catch (e) {
      print('永続的通知設定エラー: $e');
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
        _scheduledTasks.remove(taskId);
      }
      
      // Windows Task Schedulerからタスクを削除
      final taskName = 'TaskReminder_$taskId';
      final result = await Process.run('schtasks', [
        '/delete',
        '/tn', taskName,
        '/f' // 確認なしで削除
      ]);
      
      if (result.exitCode == 0) {
        print('永続的タスク削除成功: $taskId');
      } else {
        print('永続的タスク削除失敗: ${result.stderr}');
      }
      
      // 一時的なPowerShellスクリプトファイルも削除
      try {
        final tempDir = Directory.systemTemp;
        final scriptFile = File('${tempDir.path}\\task_reminder_${taskId}.ps1');
        if (await scriptFile.exists()) {
          await scriptFile.delete();
        }
      } catch (e) {
        print('スクリプトファイル削除エラー: $e');
      }
      
      print('Windows通知キャンセル: $taskId');
    } catch (e) {
      print('Windows通知キャンセルエラー: $e');
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
      _scheduledTasks.clear();
      
      // すべての永続的タスクを削除
      final result = await Process.run('schtasks', [
        '/query',
        '/tn', 'TaskReminder_*',
        '/fo', 'csv'
      ]);
      
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.contains('TaskReminder_')) {
            final taskName = line.split(',')[0].replaceAll('"', '');
            await Process.run('schtasks', ['/delete', '/tn', taskName, '/f']);
          }
        }
      }
      
      // 一時的なPowerShellスクリプトファイルを削除
      try {
        final tempDir = Directory.systemTemp;
        final files = tempDir.listSync();
        for (final file in files) {
          if (file is File && file.path.contains('task_reminder_')) {
            await file.delete();
          }
        }
      } catch (e) {
        print('スクリプトファイル一括削除エラー: $e');
      }
      
      print('Windows通知全キャンセル');
    } catch (e) {
      print('Windows通知全キャンセルエラー: $e');
    }
  }

  // テスト通知
  static Future<void> showTestNotification() async {
    await showToastNotification(
      'テスト通知',
      'Windowsネイティブ通知機能が正常に動作しています',
    );
  }

  // リマインダーテスト通知
  static Future<void> showTestReminderNotification() async {
    await showToastNotification(
      'リマインダーテスト',
      'Windowsネイティブリマインダー機能が正常に動作しています',
    );
  }

  // 1分後のテストリマインダー
  static Future<void> showTestReminderInOneMinute() async {
    try {
      // 1分後のテストタスクを作成
      final testTask = TaskItem(
        id: 'test_reminder_${DateTime.now().millisecondsSinceEpoch}',
        title: '1分後リマインダーテスト',
        description: 'アプリが閉じられていても通知が表示されるテスト',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
        reminderTime: DateTime.now().add(const Duration(minutes: 1)),
        tags: ['テスト'],
      );
      
      // 永続的な通知をスケジュール
      await scheduleTaskReminder(testTask);
      
      print('1分後のテストリマインダーを設定しました');
    } catch (e) {
      print('1分後リマインダーテストエラー: $e');
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
      _scheduledTasks.clear();
      
      print('Windows通知サービスクリーンアップ');
    } catch (e) {
      print('Windows通知サービスクリーンアップエラー: $e');
    }
  }
}
