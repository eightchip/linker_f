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

  /// 短いトークンを生成
  String makeShortToken() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final token = ms.toRadixString(36).toUpperCase();
    // 最後の6文字を取得（LN-プレフィックスを含めて8文字）
    return 'LN-${token.length >= 6 ? token.substring(token.length - 6) : token.padLeft(6, '0')}';
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
        body { font-family: Arial, sans-serif; line-height: 1.6; }
        .footer { margin-top: 20px; padding-top: 10px; border-top: 1px solid #ccc; font-size: 0.9em; color: #666; }
    </style>
</head>
<body>
    ${body.replaceAll('\n', '<br>')}
    <div class="footer">
        <p>このメールはタスク管理アプリから送信されました。</p>
    </div>
</body>
</html>
    ''';
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
    final token = makeShortToken();
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
  }) async {
    final token = makeShortToken();
    final finalSubject = '$subject [$token]';
    final finalBody = '$body\n\n---\n送信ID: $token';

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

  /// リソースを解放
  Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }
}
