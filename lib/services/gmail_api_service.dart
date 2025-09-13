import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/email_task_assignment.dart';

/// Gmail API サービス
class GmailApiService {
  static const String _gmailApiBaseUrl = 'https://gmail.googleapis.com/gmail/v1';
  String? _accessToken;
  
  /// アクセストークンを設定
  void setAccessToken(String token) {
    _accessToken = token;
  }
  
  /// アクセストークンが設定されているかチェック
  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;
  
  /// Gmailでタスク割り当てメールを検索
  Future<List<EmailTaskAssignment>> searchTaskAssignmentEmails() async {
    if (!hasAccessToken) {
      if (kDebugMode) {
        print('Gmail API: アクセストークンが設定されていません');
      }
      return [];
    }
    
    try {
      // 過去24時間のメールを検索
      final query = 'in:inbox newer_than:1d subject:(依頼 OR タスク OR お願い OR 業務 OR 作業 OR 手伝い)';
      
      // メールIDを取得
      final emailIds = await _searchEmails(query);
      if (emailIds.isEmpty) {
        return [];
      }
      
      // 各メールの詳細を取得
      final assignments = <EmailTaskAssignment>[];
      for (final emailId in emailIds) {
        final assignment = await _getEmailAssignment(emailId);
        if (assignment != null) {
          assignments.add(assignment);
        }
      }
      
      return assignments;
    } catch (e) {
      if (kDebugMode) {
        print('Gmail API 検索エラー: $e');
      }
      return [];
    }
  }
  
  /// メールIDを検索
  Future<List<String>> _searchEmails(String query) async {
    final url = Uri.parse('$_gmailApiBaseUrl/users/me/messages?q=${Uri.encodeComponent(query)}');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = data['messages'] as List? ?? [];
      return messages.map((msg) => msg['id'] as String).toList();
    } else {
      if (kDebugMode) {
        print('Gmail API 検索レスポンスエラー: ${response.statusCode} - ${response.body}');
      }
      return [];
    }
  }
  
  /// メールの詳細を取得してタスク割り当てとして解析
  Future<EmailTaskAssignment?> _getEmailAssignment(String emailId) async {
    try {
      final url = Uri.parse('$_gmailApiBaseUrl/users/me/messages/$emailId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseEmailData(data, emailId);
      } else {
        if (kDebugMode) {
          print('Gmail API メール取得エラー: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gmail API メール解析エラー: $e');
      }
      return null;
    }
  }
  
  /// メールデータを解析してタスク割り当てとして変換
  EmailTaskAssignment? _parseEmailData(Map<String, dynamic> data, String emailId) {
    try {
      final payload = data['payload'];
      if (payload == null) return null;
      
      final headers = payload['headers'] as List? ?? [];
      final headerMap = <String, String>{};
      
      for (final header in headers) {
        final name = header['name'] as String? ?? '';
        final value = header['value'] as String? ?? '';
        headerMap[name.toLowerCase()] = value;
      }
      
      final subject = headerMap['subject'] ?? '';
      final from = headerMap['from'] ?? '';
      final dateStr = headerMap['date'] ?? '';
      
      // 件名や本文にタスク関連のキーワードが含まれているかチェック
      if (!_isTaskRelatedEmail(subject)) {
        return null;
      }
      
      // 本文を取得
      final body = _extractEmailBody(payload);
      
      // 送信者情報を解析
      final senderInfo = _parseSenderInfo(from);
      
      // 期日を抽出
      final dueDate = _extractDueDate(subject, body);
      
      // 優先度を判定
      final priority = _determinePriority(subject, body);
      
      // タスクタイトルを抽出
      final taskTitle = _extractTaskTitle(subject);
      
      // タスク説明を抽出
      final taskDescription = _extractTaskDescription(body);
      
      return EmailTaskAssignment(
        emailId: emailId,
        emailSubject: subject,
        emailBody: body,
        requesterEmail: senderInfo['email'] ?? '',
        requesterName: senderInfo['name'] ?? '',
        taskTitle: taskTitle,
        taskDescription: taskDescription,
        dueDate: dueDate,
        priority: priority,
        receivedAt: _parseDate(dateStr),
        source: 'gmail',
      );
    } catch (e) {
      if (kDebugMode) {
        print('メールデータ解析エラー: $e');
      }
      return null;
    }
  }
  
  /// タスク関連のメールかどうかを判定
  bool _isTaskRelatedEmail(String subject) {
    final keywords = ['依頼', 'タスク', 'お願い', '業務', '作業', '手伝い', 'request', 'task', 'assignment'];
    final lowerSubject = subject.toLowerCase();
    return keywords.any((keyword) => lowerSubject.contains(keyword.toLowerCase()));
  }
  
  /// メール本文を抽出
  String _extractEmailBody(Map<String, dynamic> payload) {
    try {
      final parts = payload['parts'] as List? ?? [];
      if (parts.isEmpty) {
        // 単純なメールの場合
        final body = payload['body']?['data'];
        if (body != null) {
          return utf8.decode(base64Url.decode(body));
        }
        return '';
      }
      
      // マルチパートメールの場合
      for (final part in parts) {
        final mimeType = part['mimeType'] as String? ?? '';
        if (mimeType == 'text/plain' || mimeType == 'text/html') {
          final body = part['body']?['data'];
          if (body != null) {
            return utf8.decode(base64Url.decode(body));
          }
        }
      }
      
      return '';
    } catch (e) {
      if (kDebugMode) {
        print('メール本文抽出エラー: $e');
      }
      return '';
    }
  }
  
  /// 送信者情報を解析
  Map<String, String> _parseSenderInfo(String from) {
    try {
      // "名前 <email@example.com>" 形式を解析
      final match = RegExp(r'(.+?)\s*<(.+?)>').firstMatch(from);
      if (match != null) {
        return {
          'name': match.group(1)?.trim() ?? '',
          'email': match.group(2)?.trim() ?? '',
        };
      }
      
      // メールアドレスのみの場合
      if (from.contains('@')) {
        return {
          'name': '',
          'email': from.trim(),
        };
      }
      
      return {'name': from.trim(), 'email': ''};
    } catch (e) {
      return {'name': from, 'email': ''};
    }
  }
  
  /// 期日を抽出
  DateTime? _extractDueDate(String subject, String body) {
    try {
      // 件名から期日を抽出
      final datePattern = RegExp(r'(\d{1,2})[\/\-](\d{1,2})');
      final subjectMatch = datePattern.firstMatch(subject);
      
      if (subjectMatch != null) {
        final month = int.tryParse(subjectMatch.group(1) ?? '');
        final day = int.tryParse(subjectMatch.group(2) ?? '');
        
        if (month != null && day != null) {
          final currentYear = DateTime.now().year;
          return DateTime(currentYear, month, day);
        }
      }
      
      // 本文から期日を抽出
      final bodyMatch = datePattern.firstMatch(body);
      if (bodyMatch != null) {
        final month = int.tryParse(bodyMatch.group(1) ?? '');
        final day = int.tryParse(bodyMatch.group(2) ?? '');
        
        if (month != null && day != null) {
          final currentYear = DateTime.now().year;
          return DateTime(currentYear, month, day);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// 優先度を判定
  EmailTaskPriority _determinePriority(String subject, String body) {
    final urgentKeywords = ['緊急', 'urgent', '急ぎ', '高'];
    final lowKeywords = ['低', 'low', '余裕'];
    
    final text = '${subject} ${body}'.toLowerCase();
    
    if (urgentKeywords.any((keyword) => text.contains(keyword.toLowerCase()))) {
      return EmailTaskPriority.high;
    } else if (lowKeywords.any((keyword) => text.contains(keyword.toLowerCase()))) {
      return EmailTaskPriority.low;
    }
    
    return EmailTaskPriority.medium;
  }
  
  /// タスクタイトルを抽出
  String _extractTaskTitle(String subject) {
    // 【】で囲まれた部分を抽出
    final match = RegExp(r'【(.+?)】').firstMatch(subject);
    if (match != null) {
      return match.group(1) ?? subject;
    }
    
    // 件名から「Re:」や「Fwd:」を除去
    return subject.replaceAll(RegExp(r'^(Re:|Fwd:)\s*', caseSensitive: false), '').trim();
  }
  
  /// タスク説明を抽出
  String _extractTaskDescription(String body) {
    // HTMLタグを除去
    final cleanBody = body.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // 長すぎる場合は切り詰める
    if (cleanBody.length > 500) {
      return cleanBody.substring(0, 500) + '...';
    }
    
    return cleanBody.trim();
  }
  
  /// 日付文字列を解析
  DateTime _parseDate(String dateStr) {
    try {
      // RFC 2822形式の日付を解析
      final date = DateTime.parse(dateStr);
      return date;
    } catch (e) {
      return DateTime.now();
    }
  }
  
  /// 完了報告メールを送信
  Future<bool> sendCompletionReport(String recipient, String taskTitle, String notes) async {
    if (!hasAccessToken) {
      if (kDebugMode) {
        print('Gmail API: 完了報告送信にアクセストークンが必要です');
      }
      return false;
    }
    
    try {
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
      
      // Gmail APIを使用してメールを送信
      final url = Uri.parse('$_gmailApiBaseUrl/users/me/messages/send');
      
      // メールメッセージを作成
      final message = {
        'raw': base64Url.encode(utf8.encode(_createEmailMessage(recipient, subject, body))),
      };
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Gmail API: 完了報告メールを送信しました');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Gmail API: 完了報告メール送信エラー: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gmail API: 完了報告メール送信エラー: $e');
      }
      return false;
    }
  }
  
  /// メールメッセージを作成
  String _createEmailMessage(String to, String subject, String body) {
    final boundary = 'boundary_${DateTime.now().millisecondsSinceEpoch}';
    
    return '''To: $to
Subject: $subject
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="$boundary"

--$boundary
Content-Type: text/plain; charset=UTF-8

$body

--$boundary--
''';
  }
}
