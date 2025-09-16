import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../models/sent_mail_log.dart';
import '../services/email_contact_service.dart';

class MailService {
  static final MailService _instance = MailService._internal();
  factory MailService() => _instance;
  MailService._internal();

  static const String _boxName = 'sent_mail_logs';
  Box<SentMailLog>? _box;

  /// サービスを初期化
  Future<void> initialize() async {
    if (_box == null) {
      _box = await Hive.openBox<SentMailLog>(_boxName);
      if (kDebugMode) {
        print('MailService初期化完了: ${_box?.length}件のログを読み込み');
      }
    }
  }

  /// Outlookが利用可能かチェック
  Future<bool> isOutlookAvailable() async {
    try {
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        r'try { $ol = New-Object -ComObject Outlook.Application; $ol.Quit(); Write-Output "true" } catch { Write-Output "false" }',
      ]);

      return result.stdout.toString().trim() == 'true';
    } catch (e) {
      if (kDebugMode) {
        print('Outlook可用性チェックエラー: $e');
      }
      return false;
    }
  }

  /// 短いトークンを生成（LN-XXXXXX形式）
  String makeToken() {
    final n = DateTime.now().millisecondsSinceEpoch;
    return 'LN-${n.toRadixString(36).toUpperCase().substring(2, 8)}';
  }

  /// メール本文HTMLテンプレートを生成
  String buildMailHtml({
    required String title,
    String? due,
    String? status,
    String? memo,
    List<String>? links,
    required String token,
  }) {
    String linkItem(String raw) {
      final isUnc = raw.startsWith(r'\\');
      final href = isUnc ? 'file://${raw.replaceAll(r'\', '/')}' : raw;
      return '<li><a href="$href">$raw</a></li>';
    }

    final linksHtml = (links ?? []).isEmpty
        ? ''
        : '<p><b>関連資料:</b></p><ul>${(links!).map(linkItem).join()}</ul>';

    final memoHtml = (memo ?? '').isEmpty
        ? ''
        : '<p><b>メモ:</b><br>${(memo!).replaceAll('\n', '<br>')}</p>';

    return '''
    <html><body style="font-family:Segoe UI,Meiryo;font-size:14px;">
      <p><b>タスク:</b> $title</p>
      ${due == null || due.isEmpty ? '' : '<p><b>期限:</b> $due</p>'}
      ${status == null || status.isEmpty ? '' : '<p><b>ステータス:</b> $status</p>'}
      $memoHtml
      $linksHtml
      <hr style="margin-top:16px;">
      <p style="color:#6b7280;font-size:12px;">
        送信ID: $token<br>
        （このIDで送信済み検索ができます）
      </p>
    </body></html>
    ''';
  }

  /// タスクIDに関連する送信ログを取得
  List<SentMailLog> getMailLogsForTask(String taskId) {
    if (_box == null) return [];
    return _box!.values.where((log) => log.taskId == taskId).toList();
  }

  /// 送信ログを保存
  Future<void> saveMailLog(SentMailLog log) async {
    if (_box == null) {
      await initialize();
    }
    await _box!.put(log.id, log);
    if (kDebugMode) {
      print('メールログ保存: ${log.token} (タスクID: ${log.taskId})');
      print('保存後のログ数: ${_box!.length}');
    }
  }

  /// 送信ログを削除
  Future<void> deleteMailLog(String logId) async {
    if (_box == null) return;
    await _box!.delete(logId);
    if (kDebugMode) {
      print('メールログ削除: $logId');
    }
  }

  /// Gmail Webでメール作成画面を起動
  Future<void> launchGmail({
    required String to,
    required String cc,
    required String bcc,
    required String subject,
    required String body,
  }) async {
    try {
      final url = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1'
        '&to=${Uri.encodeComponent(to)}'
        '&cc=${Uri.encodeComponent(cc)}'
        '&bcc=${Uri.encodeComponent(bcc)}'
        '&su=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Gmailを起動できませんでした');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gmail起動エラー: $e');
      }
      rethrow;
    }
  }

  /// Outlook デスクトップでメール作成画面を起動
  Future<void> launchOutlookDesktop({
    required String to,
    required String cc,
    required String bcc,
    required String subject,
    required String body,
  }) async {
    try {
      final tmp = Directory.systemTemp;
      final htmlPath = '${tmp.path}\\task_mail_${DateTime.now().millisecondsSinceEpoch}.html';
      
      // HTMLボディを作成
      final htmlBody = _createHtmlBody(body);
      await File(htmlPath).writeAsString(htmlBody, encoding: utf8);

      const scriptPath = r'C:\Apps\compose_mail.ps1';
      
      // PowerShellスクリプトを実行
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptPath,
        '-To', to,
        '-Cc', cc,
        '-Bcc', bcc,
        '-Subject', subject,
        '-HtmlPath', htmlPath,
      ]);

      if (result.exitCode != 0) {
        final errorMessage = result.stderr.toString();
        if (errorMessage.contains('COM') || errorMessage.contains('Outlook')) {
          throw Exception('Outlookがインストールされていないか、正しく設定されていません。\n会社PCでOutlookを使用してください。\n詳細: $errorMessage');
        } else {
          throw Exception('Outlook起動に失敗しました: $errorMessage');
        }
      }

      // 一時ファイルを削除
      try {
        await File(htmlPath).delete();
      } catch (e) {
        if (kDebugMode) {
          print('一時ファイル削除エラー: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Outlook起動エラー: $e');
      }
      rethrow;
    }
  }

  /// HTMLボディを作成
  String _createHtmlBody(String body) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { 
            font-family: 'Segoe UI', 'Hiragino Sans', 'ヒラギノ角ゴシック', 'Yu Gothic', 'メイリオ', sans-serif; 
            line-height: 1.8; 
            color: #333; 
            max-width: 600px; 
            margin: 0 auto; 
            padding: 20px;
            background-color: #f8f9fa;
        }
        .container {
            background-color: white;
            border-radius: 12px;
            padding: 30px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            border: 1px solid #e9ecef;
        }
        .header {
            border-bottom: 3px solid #007bff;
            padding-bottom: 15px;
            margin-bottom: 25px;
        }
        .header h1 {
            color: #007bff;
            margin: 0;
            font-size: 24px;
            font-weight: 600;
        }
        .content {
            font-size: 16px;
            margin-bottom: 25px;
        }
        .task-info {
            background-color: #f8f9fa;
            border-left: 4px solid #007bff;
            padding: 15px;
            margin: 20px 0;
            border-radius: 0 8px 8px 0;
        }
        .footer { 
            margin-top: 30px; 
            padding-top: 20px; 
            border-top: 2px solid #e9ecef; 
            font-size: 14px; 
            color: #6c757d;
            text-align: center;
        }
        .footer p {
            margin: 5px 0;
        }
        .app-badge {
            display: inline-block;
            background: linear-gradient(135deg, #007bff, #0056b3);
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin: 10px 0;
        }
        .timestamp {
            color: #6c757d;
            font-size: 12px;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📧 タスク管理アプリからのメール</h1>
        </div>
        
        <div class="content">
            ${_formatBodyContent(body)}
        </div>
        
        <div class="task-info">
            <strong>📋 タスク情報</strong><br>
            このメールはタスク管理システムから自動生成されました。
        </div>
        
        <div class="footer">
            <div class="app-badge">Link Navigator</div>
            <p>このメールはタスク管理アプリから送信されました。</p>
            <p>送信日時: ${DateTime.now().toString().split('.')[0]}</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// 本文コンテンツをフォーマット
  String _formatBodyContent(String body) {
    if (body.trim().isEmpty) {
      return '<p style="color: #6c757d; font-style: italic;">メッセージがありません。</p>';
    }
    
    // 改行を適切に処理し、HTMLエスケープ
    final escapedBody = body
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
    
    // 改行を段落に変換
    final paragraphs = escapedBody.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => '<p style="margin: 10px 0;">${line.trim()}</p>')
        .join('');
    
    return paragraphs.isNotEmpty ? paragraphs : '<p>${escapedBody}</p>';
  }

  /// 強化されたメール本文を作成
  String _createEnhancedBody(String originalBody, String token) {
    final currentTime = DateTime.now();
    final formattedTime = '${currentTime.year}年${currentTime.month}月${currentTime.day}日 ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
    
    final enhancedBody = '''
${originalBody.isNotEmpty ? originalBody : 'メッセージがありません。'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📧 メール情報
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 送信日時: $formattedTime
🆔 送信ID: $token
📱 送信元: Link Navigator (タスク管理アプリ)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

このメールは Link Navigator タスク管理アプリから自動送信されました。
返信や質問がございましたら、お気軽にお声かけください。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    
    return enhancedBody;
  }

  /// 送信済み検索（Gmail）
  Future<void> openGmailSentSearch(String token) async {
    try {
      final url = Uri.parse('https://mail.google.com/mail/u/0/#search/'
          '${Uri.encodeComponent('in:sent "' + token + '"')}');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Gmailを起動できませんでした');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gmail検索エラー: $e');
      }
      rethrow;
    }
  }

  /// 送信済み検索（Outlook デスクトップ）
  Future<void> openOutlookSentSearch(String token) async {
    try {
      const scriptPath = r'C:\Apps\find_sent.ps1';
      
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptPath,
        '-Token', token,
      ]);

      if (result.exitCode != 0) {
        final errorMessage = result.stderr.toString();
        if (errorMessage.contains('COM') || errorMessage.contains('Outlook')) {
          throw Exception('Outlookがインストールされていないか、正しく設定されていません。\n会社PCでOutlookを使用してください。\n詳細: $errorMessage');
        } else {
          throw Exception('Outlook検索に失敗しました: $errorMessage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Outlook検索エラー: $e');
      }
      rethrow;
    }
  }

  /// 送信済み検索を開く
  Future<void> openSentSearch(SentMailLog log) async {
    if (log.app == 'outlook') {
      await openOutlookSentSearch(log.token);
    } else {
      await openGmailSentSearch(log.token);
    }
  }

  /// 送信ログのみを保存（メーラーは起動しない）
  Future<void> saveMailLogOnly({
    required String taskId,
    required String app, // 'gmail' | 'outlook'
    required String to,
    required String cc,
    required String bcc,
    required String subject,
    required String body,
  }) async {
    final token = makeToken();
    final finalSubject = '$subject [$token]';
    final finalBody = '$body\n\n---\n送信ID: $token';

    // 送信ログのみを保存（メーラーは起動しない）
    final log = SentMailLog(
      id: const Uuid().v4(),
      taskId: taskId,
      app: app,
      token: token,
      to: to,
      cc: cc,
      bcc: bcc,
      subject: finalSubject,
      body: finalBody,
      composedAt: DateTime.now(),
    );

    await saveMailLog(log);

    // 送信後、宛先から連絡先を自動抽出・登録
    await _extractAndSaveContacts(log);

    if (kDebugMode) {
      print('メール送信ログのみ保存: ${log.token}');
      print('保存されたログ数: ${_box?.length ?? 0}');
      print('タスクID $taskId のログ数: ${getMailLogsForTask(taskId).length}');
    }
  }

  /// 既存のトークンで送信ログのみを保存（メーラーは起動しない）
  Future<void> saveMailLogWithToken({
    required String taskId,
    required String app, // 'gmail' | 'outlook'
    required String to,
    required String cc,
    required String bcc,
    required String subject,
    required String body,
    required String token,
  }) async {
    // 送信ログのみを保存（メーラーは起動しない）
    final log = SentMailLog(
      id: const Uuid().v4(),
      taskId: taskId,
      app: app,
      token: token,
      to: to,
      cc: cc,
      bcc: bcc,
      subject: subject,
      body: body,
      composedAt: DateTime.now(),
    );

    await saveMailLog(log);

    // 送信後、宛先から連絡先を自動抽出・登録
    await _extractAndSaveContacts(log);

    if (kDebugMode) {
      print('メール送信ログ保存（既存トークン）: ${log.token}');
      print('保存されたログ数: ${_box?.length ?? 0}');
      print('タスクID $taskId のログ数: ${getMailLogsForTask(taskId).length}');
    }
  }

  /// メール送信を実行
  Future<void> sendMail({
    required String taskId,
    required String app, // 'gmail' | 'outlook'
    required String to,
    required String cc,
    required String bcc,
    required String subject,
    required String body,
    String? title,
    String? due,
    String? status,
    String? memo,
    List<String>? links,
  }) async {
    final token = makeToken();
    final finalSubject = '$subject [$token]';
    
    // HTMLテンプレートを使用する場合は、タスク情報から生成
    String finalBody;
    if (title != null) {
      finalBody = buildMailHtml(
        title: title,
        due: due,
        status: status,
        memo: memo,
        links: links,
        token: token,
      );
    } else {
      finalBody = _createEnhancedBody(body, token);
    }

    try {
      if (app == 'gmail') {
        await launchGmail(
          to: to,
          cc: cc,
          bcc: bcc,
          subject: finalSubject,
          body: finalBody,
        );
      } else if (app == 'outlook') {
        await launchOutlookDesktop(
          to: to,
          cc: cc,
          bcc: bcc,
          subject: finalSubject,
          body: finalBody,
        );
      } else {
        throw Exception('サポートされていないメールアプリ: $app');
      }

      // 送信ログを保存
      final log = SentMailLog(
        id: const Uuid().v4(),
        taskId: taskId,
        app: app,
        token: token,
        to: to,
        cc: cc,
        bcc: bcc,
        subject: finalSubject,
        body: finalBody,
        composedAt: DateTime.now(),
      );

      await saveMailLog(log);

      // 送信後、宛先から連絡先を自動抽出・登録
      await _extractAndSaveContacts(log);

      if (kDebugMode) {
        print('メール送信ログを保存: ${log.token}');
        print('保存されたログ数: ${_box?.length ?? 0}');
        print('タスクID $taskId のログ数: ${getMailLogsForTask(taskId).length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('メール送信エラー: $e');
      }
      rethrow;
    }
  }

  /// 送信ログから連絡先を自動抽出・登録
  Future<void> _extractAndSaveContacts(SentMailLog log) async {
    try {
      final contactService = EmailContactService();
      await contactService.initialize();
      
      // To, Cc, Bccから連絡先を抽出
      final emails = [
        log.to,
        log.cc,
        log.bcc,
      ].where((email) => email.isNotEmpty && email.trim().isNotEmpty).toList();

      for (final email in emails) {
        final cleanEmail = email.trim();
        if (cleanEmail.isNotEmpty) {
          // 既存の連絡先をチェック
          final existingContact = contactService.getContactByEmail(cleanEmail);
          
          if (existingContact == null) {
            // 新しい連絡先を作成
            try {
              // メールアドレスから名前を推定
              String name = cleanEmail;
              if (cleanEmail.contains('@')) {
                final localPart = cleanEmail.split('@')[0];
                name = localPart
                    .replaceAll('.', ' ')
                    .replaceAll('_', ' ')
                    .replaceAll('-', ' ')
                    .split(' ')
                    .map((word) => word.isNotEmpty 
                        ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
                        : '')
                    .join(' ')
                    .trim();
                
                // 名前が空の場合はメールアドレスのローカル部分を使用
                if (name.isEmpty) {
                  name = localPart;
                }
              }

              await contactService.addContact(
                name: name,
                email: cleanEmail,
                organization: null,
              );
              
              if (kDebugMode) {
                print('新しい連絡先を自動登録: $name <$cleanEmail>');
              }
            } catch (e) {
              if (kDebugMode) {
                print('連絡先自動登録エラー: $e');
              }
            }
          } else {
            // 既存の連絡先の使用回数を更新
            await contactService.updateContactUsage(cleanEmail);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('連絡先抽出エラー: $e');
      }
    }
  }

  /// Outlook送信済み検索
  Future<bool> searchSentMail(String token) async {
    try {
      const scriptPath = r'C:\Apps\find_sent.ps1';
      
      final result = await Process.run('powershell.exe', [
        '-ExecutionPolicy', 'Bypass',
        '-File', scriptPath,
        '-Token', token,
      ]);

      if (kDebugMode) {
        print('Outlook送信済み検索結果: ${result.exitCode}');
        print('Stdout: ${result.stdout}');
        print('Stderr: ${result.stderr}');
      }

      return result.exitCode == 0;
    } catch (e) {
      if (kDebugMode) {
        print('Outlook送信済み検索エラー: $e');
      }
      return false;
    }
  }

  /// リソースを解放
  Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }
}
