import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../models/email_task_assignment.dart';
import '../viewmodels/task_viewmodel.dart';
import '../services/settings_service.dart';
import '../services/gmail_api_service.dart';

/// メール監視サービス
class EmailMonitorService {
  static final EmailMonitorService _instance = EmailMonitorService._internal();
  factory EmailMonitorService() => _instance;
  EmailMonitorService._internal();

  final SettingsService _settingsService = SettingsService.instance;
  final GmailApiService _gmailApiService = GmailApiService();
  final Uuid _uuid = const Uuid();
  
  Timer? _monitorTimer;
  bool _isMonitoring = false;
  
  /// メール監視を開始
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    try {
      _isMonitoring = true;
      if (kDebugMode) {
        print('メール監視を開始しました');
      }
      
      // Gmail APIアクセストークンを設定
      await _initializeGmailApi();
      
      // 5分ごとにメールをチェック
      _monitorTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _checkForNewEmails();
      });
      
      // 初回チェック（エラーが発生しても監視は継続）
      try {
        await _checkForNewEmails();
      } catch (e) {
        if (kDebugMode) {
          print('初回メールチェックでエラー: $e');
        }
      }
    } catch (e) {
      _isMonitoring = false;
      if (kDebugMode) {
        print('メール監視開始エラー: $e');
      }
      rethrow;
    }
  }

  /// Gmail APIを初期化
  Future<void> _initializeGmailApi() async {
    try {
      final accessToken = _settingsService.gmailApiAccessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        _gmailApiService.setAccessToken(accessToken);
        if (kDebugMode) {
          print('Gmail APIアクセストークンを設定しました');
        }
      } else {
        if (kDebugMode) {
          print('Gmail APIアクセストークンが設定されていません');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gmail API初期化エラー: $e');
      }
    }
  }
  
  /// メール監視を停止
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    if (kDebugMode) {
      print('メール監視を停止しました');
    }
  }
  
  /// 新しいメールをチェック
  Future<void> _checkForNewEmails() async {
    try {
      // Gmailの検索クエリを実行
      try {
        await _checkGmailForTaskAssignments();
      } catch (e) {
        if (kDebugMode) {
          print('Gmailチェック中にエラー: $e');
        }
      }
      
      // Outlookの検索クエリを実行
      try {
        await _checkOutlookForTaskAssignments();
      } catch (e) {
        if (kDebugMode) {
          print('Outlookチェック中にエラー: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('メールチェック中に予期しないエラーが発生: $e');
      }
    }
  }
  
  /// Gmailでタスク割り当てメールをチェック
  Future<void> _checkGmailForTaskAssignments() async {
    try {
      if (kDebugMode) {
        print('Gmailでタスク割り当てメールをチェック中...');
      }
      
      // Gmail APIを使用してタスク割り当てメールを検索
      final assignments = await _gmailApiService.searchTaskAssignmentEmails();
      
      for (final assignment in assignments) {
        await _processEmailAssignment(assignment.toJson());
      }
      
      if (kDebugMode) {
        print('Gmailから ${assignments.length} 件のタスク割り当てメールを処理しました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gmailチェック中にエラー: $e');
      }
    }
  }
  
  /// Outlookでタスク割り当てメールをチェック
  Future<void> _checkOutlookForTaskAssignments() async {
    try {
      // PowerShellを使用してOutlookのメールを検索
      final result = await Process.run(
        'powershell',
        [
          '-ExecutionPolicy', 'Bypass',
          '-File', 'C:\\Apps\\find_task_assignments.ps1'
        ],
        workingDirectory: Directory.current.path,
      );
      
      if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
        final emails = jsonDecode(result.stdout.toString()) as List;
        for (final emailData in emails) {
          await _processEmailAssignment(emailData);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Outlookチェック中にエラー: $e');
      }
    }
  }
  
  /// メール割り当てを処理してタスクを作成
  Future<void> _processEmailAssignment(Map<String, dynamic> emailData) async {
    try {
      final assignment = EmailTaskAssignment.fromJson(emailData);
      
      // 新しいタスクを作成
      final newTask = TaskItem(
        id: _uuid.v4(),
        title: assignment.taskTitle,
        description: assignment.taskDescription,
        dueDate: assignment.dueDate,
        priority: _convertPriority(assignment.priority),
        status: TaskStatus.pending,
        assignedTo: assignment.requesterEmail,
        createdBy: assignment.requesterEmail,
        createdAt: DateTime.now(),
        isTeamTask: true, // チームタスクとしてマーク
        originalEmailId: assignment.emailId,
        originalEmailSubject: assignment.emailSubject,
      );
      
      // TODO: TaskViewModelを使用してタスクを追加
      // 現在は直接データベースに保存する実装が必要
      
      if (kDebugMode) {
        print('チームタスクを作成しました: ${assignment.taskTitle}');
      }
      
      // 通知を表示
      _showTaskAssignmentNotification(assignment);
      
    } catch (e) {
      if (kDebugMode) {
        print('メール割り当て処理中にエラー: $e');
      }
    }
  }
  
  /// タスク割り当て通知を表示
  void _showTaskAssignmentNotification(EmailTaskAssignment assignment) {
    // 通知サービスの実装が必要
    if (kDebugMode) {
      print('新しいタスクが割り当てられました: ${assignment.taskTitle}');
    }
  }
  
  /// 優先度を変換
  TaskPriority _convertPriority(EmailTaskPriority priority) {
    switch (priority) {
      case EmailTaskPriority.low:
        return TaskPriority.low;
      case EmailTaskPriority.medium:
        return TaskPriority.medium;
      case EmailTaskPriority.high:
        return TaskPriority.high;
    }
  }

  /// 完了報告メールを送信
  Future<void> sendCompletionReport(TaskItem task, String completionNotes) async {
    try {
      if (task.isTeamTask && task.createdBy != null) {
        // 完了報告メールを送信
        await _sendCompletionEmail(task.createdBy!, task.title, completionNotes);
        
        if (kDebugMode) {
          print('完了報告を送信しました: ${task.title}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('完了報告送信中にエラー: $e');
      }
    }
  }
  
  /// 完了報告メールを送信
  Future<void> _sendCompletionEmail(String recipient, String taskTitle, String notes) async {
    try {
      // Gmail APIが利用可能な場合はGmailを使用
      if (_gmailApiService.hasAccessToken) {
        final success = await _gmailApiService.sendCompletionReport(recipient, taskTitle, notes);
        if (success) {
          if (kDebugMode) {
            print('Gmail API経由で完了報告メールを送信しました');
          }
          return;
        }
      }
      
      // フォールバック: 通常のメール送信
      final subject = '【完了報告】$taskTitle';
      final body = '''
タスクが完了しました。

タスク: $taskTitle
完了日時: ${DateTime.now().toLocal().toString()}
完了者: ${Platform.environment['USERNAME'] ?? 'Unknown'}

完了メモ:
$notes

---
このメールは自動生成されました。
      ''';
      
      // メール送信サービスを使用
      // MailService().sendEmail() の実装が必要
      if (kDebugMode) {
        print('完了報告メールを送信: $recipient');
        print('件名: $subject');
        print('本文: $body');
      }
    } catch (e) {
      if (kDebugMode) {
        print('完了報告メール送信中にエラー: $e');
      }
    }
  }
}
