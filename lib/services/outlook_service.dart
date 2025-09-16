import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/email_task_assignment.dart';

/// Outlook サービス
class OutlookService {
  static const String _scriptPath = r'C:\Apps\company_task_search.ps1';
  
  /// PowerShellスクリプトを実行してOutlookからタスク割り当てメールを検索
  Future<List<EmailTaskAssignment>> searchTaskAssignmentEmails() async {
    try {
      if (kDebugMode) {
        print('Outlook Service: PowerShellスクリプトを実行中...');
      }
      
      // スクリプトファイルの存在確認
      final scriptFile = File(_scriptPath);
      if (!await scriptFile.exists()) {
        if (kDebugMode) {
          print('Outlook Service: スクリプトファイルが見つかりません: $_scriptPath');
        }
        throw Exception('スクリプトファイルが見つかりません: $_scriptPath');
      }
      
      // PowerShellスクリプトを実行
      final result = await Process.run(
        'powershell.exe',
        [
          '-ExecutionPolicy', 'Bypass',
          '-File', _scriptPath,
        ],
        workingDirectory: Directory.current.path,
      );
      
      if (result.exitCode != 0) {
        if (kDebugMode) {
          print('Outlook Service: PowerShellスクリプト実行エラー: ${result.stderr}');
        }
        throw Exception('PowerShellスクリプト実行エラー: ${result.stderr}');
      }
      
      // PowerShellの出力を直接解析（JSONファイルではなく標準出力から）
      final output = result.stdout.toString().trim();
      if (kDebugMode) {
        print('Outlook Service: PowerShell出力: $output');
      }
      
      // JSON形式の出力を探す
      final jsonMatch = RegExp(r'\{.*\}', multiLine: true, dotAll: true).firstMatch(output);
      if (jsonMatch == null) {
        if (kDebugMode) {
          print('Outlook Service: JSON出力が見つかりません');
        }
        return [];
      }
      
      final jsonString = jsonMatch.group(0)!;
      final jsonData = jsonDecode(jsonString);
      
      // 成功フラグを確認
      if (jsonData['success'] != true) {
        if (kDebugMode) {
          print('Outlook Service: スクリプトが失敗を報告: ${jsonData['error']}');
        }
        throw Exception('スクリプト実行失敗: ${jsonData['error']}');
      }
      
      final List<dynamic> tasks = jsonData['tasks'] ?? [];
      final assignments = <EmailTaskAssignment>[];
      
      for (final taskJson in tasks) {
        try {
          final assignment = EmailTaskAssignment.fromJson(taskJson);
          assignments.add(assignment);
        } catch (e) {
          if (kDebugMode) {
            print('Outlook Service: タスク割り当ての解析エラー: $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('Outlook Service: ${assignments.length}件のタスク割り当てメールを発見');
      }
      
      return assignments;
    } catch (e) {
      if (kDebugMode) {
        print('Outlook Service エラー: $e');
      }
      rethrow; // エラーを上位に伝播
    }
  }
  
  /// Outlook接続をテスト
  Future<bool> testConnection() async {
    try {
      if (kDebugMode) {
        print('Outlook Service: 接続テスト開始');
      }
      
      // 専用の接続テストスクリプトを使用
      final result = await Process.run(
        'powershell.exe',
        [
          '-ExecutionPolicy', 'Bypass',
          '-File', r'C:\Apps\company_outlook_test.ps1',
        ],
        workingDirectory: Directory.current.path,
      );
      
      final success = result.exitCode == 0;
      
      if (kDebugMode) {
        print('Outlook Service: 接続テスト結果: ${success ? "成功" : "失敗"}');
        print('Outlook Service: 標準出力: ${result.stdout}');
        if (!success) {
          print('Outlook Service: エラー詳細: ${result.stderr}');
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Outlook Service 接続テストエラー: $e');
      }
      return false;
    }
  }
  
  /// Gmailで検索したメールから自動的にタスクを生成
  Future<List<EmailTaskAssignment>> generateTasksFromEmails() async {
    try {
      if (kDebugMode) {
        print('Outlook Service: メールからタスクを自動生成開始');
      }
      
      // タスク割り当てメールを検索
      final assignments = await searchTaskAssignmentEmails();
      
      if (kDebugMode) {
        print('Outlook Service: ${assignments.length}件のタスク割り当てメールを発見');
      }
      
      return assignments;
    } catch (e) {
      if (kDebugMode) {
        print('Outlook Service 自動タスク生成エラー: $e');
      }
      return [];
    }
  }
}
