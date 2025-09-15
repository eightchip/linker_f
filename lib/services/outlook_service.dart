import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/email_task_assignment.dart';

/// Outlook サービス
class OutlookService {
  static const String _scriptPath = r'C:\Apps\find_task_assignments_company_safe.ps1';
  
  /// PowerShellスクリプトを実行してOutlookからタスク割り当てメールを検索
  Future<List<EmailTaskAssignment>> searchTaskAssignmentEmails() async {
    try {
      if (kDebugMode) {
        print('Outlook Service: PowerShellスクリプトを実行中...');
      }
      
      // PowerShellスクリプトを実行
      final result = await Process.run(
        'powershell.exe',
        [
          '-ExecutionPolicy', 'Bypass',
          '-File', _scriptPath,
          '-OutputFile', 'task_assignments.json'
        ],
        workingDirectory: Directory.current.path,
      );
      
      if (result.exitCode != 0) {
        if (kDebugMode) {
          print('Outlook Service: PowerShellスクリプト実行エラー: ${result.stderr}');
        }
        return [];
      }
      
      // 結果ファイルを読み込み
      final outputFile = File('task_assignments.json');
      if (!await outputFile.exists()) {
        if (kDebugMode) {
          print('Outlook Service: 出力ファイルが見つかりません');
        }
        return [];
      }
      
      final jsonString = await outputFile.readAsString(encoding: utf8);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      final assignments = <EmailTaskAssignment>[];
      for (final json in jsonList) {
        try {
          final assignment = EmailTaskAssignment.fromJson(json);
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
      return [];
    }
  }
  
  /// Outlook接続をテスト
  Future<bool> testConnection() async {
    try {
      if (kDebugMode) {
        print('Outlook Service: 接続テスト開始');
      }
      
      // PowerShellスクリプトを実行してテスト
      final result = await Process.run(
        'powershell.exe',
        [
          '-ExecutionPolicy', 'Bypass',
          '-Command',
          '''
          try {
            \$outlook = New-Object -ComObject Outlook.Application
            \$namespace = \$outlook.GetNamespace("MAPI")
            \$inbox = \$namespace.GetDefaultFolder(6)
            Write-Host "Outlook接続成功"
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$outlook) | Out-Null
            exit 0
          } catch {
            Write-Host "Outlook接続失敗: \$(\$_.Exception.Message)"
            exit 1
          }
          '''
        ],
        workingDirectory: Directory.current.path,
      );
      
      final success = result.exitCode == 0;
      
      if (kDebugMode) {
        print('Outlook Service: 接続テスト結果: ${success ? "成功" : "失敗"}');
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
