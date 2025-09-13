import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_item.dart';
import '../models/sub_task.dart';
import '../utils/error_handler.dart';

/// 同期結果クラス
class SyncResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? details;
  
  SyncResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.details,
  });
}

/// Google Calendar連携サービス
class GoogleCalendarService {
  static const String _credentialsFileName = 'oauth2_credentials.json';
  static const String _tokensFileName = 'google_calendar_tokens.json';
  static const String _calendarApiUrl = 'https://www.googleapis.com/calendar/v3';
  static const String _redirectUri = 'http://127.0.0.1:8080/callback';
  static const String _scope = 'https://www.googleapis.com/auth/calendar';
  
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  bool _isInitialized = false;

  /// コンストラクタ
  GoogleCalendarService();
  
  /// 認証ファイルのパスを取得（ユーザーディレクトリ優先）
  Future<String> _getCredentialsPath() async {
    try {
      // まずユーザーディレクトリを確認
      final userDir = await getApplicationDocumentsDirectory();
      final userCredentialsPath = '${userDir.path}/$_credentialsFileName';
      final userCredentialsFile = File(userCredentialsPath);
      
      if (await userCredentialsFile.exists()) {
        return userCredentialsPath;
      }
      
      // ユーザーディレクトリにない場合は実行ディレクトリを確認
      final currentDirCredentialsFile = File(_credentialsFileName);
      if (await currentDirCredentialsFile.exists()) {
        return _credentialsFileName;
      }
      
      // どちらにもない場合はユーザーディレクトリのパスを返す
      return userCredentialsPath;
    } catch (e) {
      // エラーの場合は実行ディレクトリを返す
      return _credentialsFileName;
    }
  }
  
  /// トークンファイルのパスを取得（ユーザーディレクトリ優先）
  Future<String> _getTokensPath() async {
    try {
      // まずユーザーディレクトリを確認
      final userDir = await getApplicationDocumentsDirectory();
      return '${userDir.path}/$_tokensFileName';
    } catch (e) {
      // エラーの場合は実行ディレクトリを返す
      return _tokensFileName;
    }
  }
  
  /// 初期化
  Future<bool> initialize() async {
    try {
      if (kDebugMode) {
        print('Google Calendar サービス初期化開始（OAuth2認証）');
      }
      
      // 認証情報ファイルの存在確認
      final credentialsPath = await _getCredentialsPath();
      final credentialsFile = File(credentialsPath);
      if (!await credentialsFile.exists()) {
        if (kDebugMode) {
          print('OAuth2認証情報ファイルが見つかりません: $credentialsPath');
        }
        return false;
      }
      
      // 認証情報を読み込み
      final credentialsJson = await credentialsFile.readAsString();
      json.decode(credentialsJson); // 認証情報の検証
      
      // 保存されたトークンを確認
      if (await _loadStoredTokens()) {
        _isInitialized = true;
        if (kDebugMode) {
          print('Google Calendar サービス初期化完了（保存されたトークン使用）');
        }
        return true;
      }
      
      // 新しい認証が必要
      if (kDebugMode) {
        print('新しいOAuth2認証が必要です');
      }
      _isInitialized = false;
      return false;
    } catch (e) {
      ErrorHandler.logError('Google Calendar初期化', e);
      if (kDebugMode) {
        print('Google Calendar初期化エラー: $e');
      }
      return false;
    }
  }
  
  /// 初期化状態を確認
  bool get isInitialized => _isInitialized;
  
  /// 保存されたトークンを読み込み
  Future<bool> _loadStoredTokens() async {
    try {
      // トークンファイルの存在確認
      final tokensPath = await _getTokensPath();
      final tokenFile = File(tokensPath);
      if (!await tokenFile.exists()) {
        return false;
      }
      
      // トークンを読み込み
      final tokenJson = await tokenFile.readAsString();
      final tokens = json.decode(tokenJson);
      
      _accessToken = tokens['access_token'];
      _refreshToken = tokens['refresh_token'];
      if (tokens['expires_at'] != null) {
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(tokens['expires_at']);
      }
      
      // トークンの有効性を確認
      if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
        return true;
      }
      
      // リフレッシュトークンで更新を試行
      if (_refreshToken != null) {
        return await _refreshAccessToken();
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('保存されたトークンの読み込みエラー: $e');
      }
      return false;
    }
  }
  
  /// トークンを保存
  Future<void> _saveTokens() async {
    try {
      final tokens = {
        'access_token': _accessToken,
        'refresh_token': _refreshToken,
        'expires_at': _tokenExpiry?.millisecondsSinceEpoch,
      };
      
      final tokensPath = await _getTokensPath();
      final tokenFile = File(tokensPath);
      await tokenFile.writeAsString(json.encode(tokens));
    } catch (e) {
      if (kDebugMode) {
        print('トークン保存エラー: $e');
      }
    }
  }
  
  /// OAuth2認証を開始
  Future<bool> startOAuth2Auth() async {
    try {
      if (kDebugMode) {
        print('OAuth2認証を開始します');
      }
      
      // 認証情報を読み込み
      final credentialsPath = await _getCredentialsPath();
      final credentialsFile = File(credentialsPath);
      if (!await credentialsFile.exists()) {
        if (kDebugMode) {
          print('OAuth2認証情報ファイルが見つかりません: $credentialsPath');
        }
        throw Exception('OAuth2認証情報ファイルが見つかりません。設定方法を確認してください。');
      }
      
      final credentialsJson = await credentialsFile.readAsString();
      final credentials = json.decode(credentialsJson);
      
      // 認証情報の形式をチェック
      if (!credentials.containsKey('installed')) {
        if (kDebugMode) {
          print('認証情報ファイルの形式が正しくありません。installed セクションが見つかりません。');
        }
        throw Exception('認証情報ファイルの形式が正しくありません。OAuth2デスクトップアプリ用の認証情報を使用してください。');
      }
      
      final installed = credentials['installed'];
      final clientId = installed['client_id'];
      
      if (clientId == null || clientId.isEmpty) {
        if (kDebugMode) {
          print('client_id が見つかりません');
        }
        throw Exception('認証情報ファイルに client_id が設定されていません。');
      }
      
      // 認証URLを生成
      final authUrl = Uri.parse('https://accounts.google.com/o/oauth2/auth').replace(
        queryParameters: {
          'client_id': clientId,
          'redirect_uri': _redirectUri,
          'response_type': 'code',
          'scope': _scope,
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
      
      // ローカルサーバーを起動して認証コードを受信
      final authCode = await _startLocalServerAndGetAuthCode(authUrl);
      
      if (authCode != null) {
        if (kDebugMode) {
          print('認証コードを取得しました、トークン交換を開始します');
        }
        // 認証コードからトークンを取得
        final success = await exchangeCodeForTokens(authCode);
        if (success) {
          if (kDebugMode) {
            print('OAuth2認証が完了しました');
          }
          return true;
        } else {
          if (kDebugMode) {
            print('トークン交換に失敗しました');
          }
        }
      } else {
        if (kDebugMode) {
          print('認証コードの取得に失敗しました');
        }
      }
      
      return false;
    } catch (e) {
      ErrorHandler.logError('OAuth2認証開始', e);
      if (kDebugMode) {
        print('OAuth2認証開始エラー: $e');
      }
      return false;
    }
  }
  
  /// ローカルサーバーを起動して認証コードを受信
  Future<String?> _startLocalServerAndGetAuthCode(Uri authUrl) async {
    HttpServer? server;
    
    try {
      // ローカルサーバーを起動
      server = await HttpServer.bind('127.0.0.1', 8080);
      if (kDebugMode) {
        print('ローカルサーバーを起動しました: http://127.0.0.1:8080');
      }
      
      // ブラウザで認証URLを開く
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        if (kDebugMode) {
          print('ブラウザで認証URLを開きました: $authUrl');
        }
      } else {
        throw Exception('認証URLを開けませんでした');
      }
      
      // 認証コードを受信するまで待機（タイムアウト: 5分）
      final completer = Completer<String?>();
      Timer(const Duration(minutes: 5), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      server.listen((HttpRequest request) async {
        if (request.uri.path == '/callback') {
          final authCode = request.uri.queryParameters['code'];
          final error = request.uri.queryParameters['error'];
          
          if (authCode != null) {
            if (kDebugMode) {
              print('認証コードを受信しました: ${authCode.substring(0, 20)}...');
            }
            
            // 成功ページを表示
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.html
              ..write('''
                <html>
                  <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
                    <h1 style="color: green;">認証が完了しました！</h1>
                    <p>このウィンドウを閉じてアプリに戻ってください。</p>
                  </body>
                </html>
              ''');
            await request.response.close();
            
            if (!completer.isCompleted) {
              completer.complete(authCode);
            }
          } else if (error != null) {
            // エラーページを表示
            request.response
              ..statusCode = 400
              ..headers.contentType = ContentType.html
              ..write('''
                <html>
                  <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
                    <h1 style="color: red;">認証エラー</h1>
                    <p>エラー: $error</p>
                    <p>このウィンドウを閉じてアプリに戻ってください。</p>
                  </body>
                </html>
              ''');
            await request.response.close();
            
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        } else {
          // その他のリクエストは404を返す
          request.response
            ..statusCode = 404
            ..write('Not Found');
          await request.response.close();
        }
      });
      
      return await completer.future;
    } finally {
      // サーバーを停止
      await server?.close();
      if (kDebugMode) {
        print('ローカルサーバーを停止しました');
      }
    }
  }
  
  /// 認証コードを入力してトークンを取得
  Future<bool> authenticateWithCode(String authCode) async {
    try {
      if (kDebugMode) {
        print('認証コードで認証を開始します');
      }
      
      final success = await exchangeCodeForTokens(authCode);
      if (success) {
        if (kDebugMode) {
          print('OAuth2認証が完了しました');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('認証コードの交換に失敗しました');
        }
        return false;
      }
    } catch (e) {
      ErrorHandler.logError('認証コード認証', e);
      if (kDebugMode) {
        print('認証コード認証エラー: $e');
      }
      return false;
    }
  }
  
  /// 認証コードからトークンを取得
  Future<bool> exchangeCodeForTokens(String authCode) async {
    try {
      if (kDebugMode) {
        print('認証コードをトークンに交換します');
      }
      
      // 認証情報を読み込み
      final credentialsPath = await _getCredentialsPath();
      final credentialsFile = File(credentialsPath);
      final credentialsJson = await credentialsFile.readAsString();
      final credentials = json.decode(credentialsJson);
      final clientId = credentials['installed']['client_id'];
      final clientSecret = credentials['installed']['client_secret'];
      
      // トークンリクエスト（デスクトップアプリ用）
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': authCode,
          'grant_type': 'authorization_code',
          'redirect_uri': _redirectUri,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        
        // トークンを保存
        await _saveTokens();
        
        _isInitialized = true;
        
        if (kDebugMode) {
          print('OAuth2認証が完了しました');
          print('アクセストークン: ${_accessToken?.substring(0, 20)}...');
          print('リフレッシュトークン: ${_refreshToken?.substring(0, 20)}...');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('トークン取得エラー: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      ErrorHandler.logError('認証コード交換', e);
      if (kDebugMode) {
        print('認証コード交換エラー: $e');
      }
      return false;
    }
  }
  
  /// アクセストークンをリフレッシュ
  Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) {
        return false;
      }
      
      // 認証情報を読み込み
      final credentialsPath = await _getCredentialsPath();
      final credentialsFile = File(credentialsPath);
      final credentialsJson = await credentialsFile.readAsString();
      final credentials = json.decode(credentialsJson);
      final clientId = credentials['installed']['client_id'];
      final clientSecret = credentials['installed']['client_secret'];
      
      // リフレッシュトークンリクエスト
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'refresh_token': _refreshToken,
          'grant_type': 'refresh_token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        
        // トークンを保存
        await _saveTokens();
        
        if (kDebugMode) {
          print('アクセストークンをリフレッシュしました');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('トークンリフレッシュエラー: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      ErrorHandler.logError('トークンリフレッシュ', e);
      if (kDebugMode) {
        print('トークンリフレッシュエラー: $e');
      }
      return false;
    }
  }
  
  /// 有効なアクセストークンを取得
  Future<String?> _getValidAccessToken() async {
    try {
      // トークンが有効かチェック
      if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
        return _accessToken;
      }
      
      // リフレッシュトークンで更新を試行
      if (_refreshToken != null) {
        if (await _refreshAccessToken()) {
          return _accessToken;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('有効なアクセストークン取得エラー: $e');
      }
      return null;
    }
  }
  
  /// カレンダーイベントを取得
  Future<List<Map<String, dynamic>>> getEvents({
    DateTime? startTime,
    DateTime? endTime,
    int maxResults = 50,
  }) async {
    try {
      // 有効なアクセストークンを取得
      final accessToken = await _getValidAccessToken();
      if (accessToken == null) {
        throw Exception('有効なアクセストークンがありません。OAuth2認証を実行してください。');
      }
      
      final now = DateTime.now();
      final start = startTime ?? now;
      final end = endTime ?? now.add(const Duration(days: 30));
      
      final url = Uri.parse('$_calendarApiUrl/calendars/primary/events').replace(
        queryParameters: {
          'timeMin': start.toUtc().toIso8601String(),
          'timeMax': end.toUtc().toIso8601String(),
          'maxResults': maxResults.toString(),
          'singleEvents': 'true',
          'orderBy': 'startTime',
        },
      );
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        if (kDebugMode) {
          print('Google Calendar イベント取得エラー: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Google Calendar イベント取得に失敗しました: ${response.statusCode}');
      }
    } catch (e) {
      ErrorHandler.logError('Google Calendar イベント取得', e);
      rethrow;
    }
  }
  
  /// Google Calendarイベントをタスクに変換
  List<TaskItem> convertEventsToTasks(List<Map<String, dynamic>> events) {
    final tasks = <TaskItem>[];
    
    for (final event in events) {
      try {
        // イベントの基本情報
        final title = event['summary'] ?? '無題のイベント';
        final description = event['description'] ?? '';
        
        // 祝日イベントかどうかをチェック
        if (_isHolidayEvent(title, description, event)) {
          if (kDebugMode) {
            print('祝日イベントをスキップ: $title');
          }
          continue;
        }
        
        // 開始時間と終了時間
        DateTime? startTime;
        DateTime? endTime;
        
        final start = event['start'];
        if (start != null) {
          if (start['dateTime'] != null) {
            startTime = DateTime.parse(start['dateTime']).toLocal();
          } else if (start['date'] != null) {
            startTime = DateTime.parse(start['date']);
          }
        }
        
        final end = event['end'];
        if (end != null) {
          if (end['dateTime'] != null) {
            endTime = DateTime.parse(end['dateTime']).toLocal();
          } else if (end['date'] != null) {
            endTime = DateTime.parse(end['date']);
          }
        }
        
        // タスクの作成
        final task = TaskItem(
          id: 'google_cal_${event['id']}',
          title: title,
          description: description.isNotEmpty ? description : null,
          status: TaskStatus.pending,
          priority: _determinePriority(event),
          createdAt: DateTime.now(),
          dueDate: endTime,
          reminderTime: startTime,
          estimatedMinutes: _calculateEstimatedMinutes(startTime, endTime),
          assignedTo: _extractAttendees(event),
          source: 'google_calendar',
          externalId: event['id'],
        );
        
        tasks.add(task);
        
        if (kDebugMode) {
          print('Google Calendar イベントをタスクに変換: $title');
        }
      } catch (e) {
        ErrorHandler.logError('イベント変換エラー: ${event['summary']}', e);
      }
    }
    
    return tasks;
  }
  
  /// 祝日イベントかどうかを判定
  bool _isHolidayEvent(String title, String description, Map<String, dynamic> event) {
    final titleLower = title.toLowerCase();
    final descriptionLower = description.toLowerCase();
    
    // 祝日関連のキーワードをチェック（拡張版）
    final holidayKeywords = [
      '祝日', 'holiday', '国民の祝日', '振替休日', '敬老の日', '春分の日', '秋分の日',
      'みどりの日', '海の日', '山の日', '体育の日', 'スポーツの日', '文化の日',
      '勤労感謝の日', '天皇誕生日', '建国記念の日', '昭和の日', '憲法記念日',
      'こどもの日', '成人の日', '成人式', 'バレンタインデー', 'ホワイトデー',
      '母の日', '父の日', 'クリスマス', '大晦日', '正月', 'お盆', 'ゴールデンウィーク',
      'シルバーウィーク', '年末年始', '七夕', '七五三', '銀行休業日', '節分', '雛祭り',
      '元日', '振替', '休業', '休日', '祝祭日', '国民の休日'
    ];
    
    // キーワードチェック
    for (final keyword in holidayKeywords) {
      if (titleLower.contains(keyword) || descriptionLower.contains(keyword)) {
        return true;
      }
    }
    
    // 終日イベントでタイトルが短い場合は祝日の可能性が高い
    final start = event['start'];
    final end = event['end'];
    
    if (start != null && end != null) {
      // 終日イベントかどうかをチェック
      final isAllDay = start['date'] != null && end['date'] != null;
      
      if (isAllDay && titleLower.length <= 10) {
        return true;
      }
    }
    
    return false;
  }

  /// イベントから優先度を決定
  TaskPriority _determinePriority(Map<String, dynamic> event) {
    // 重要度や参加者数に基づいて優先度を決定
    final attendees = event['attendees'] as List?;
    if (attendees != null && attendees.length > 5) {
      return TaskPriority.high;
    }
    
    final summary = (event['summary'] ?? '').toString().toLowerCase();
    if (summary.contains('緊急') || summary.contains('urgent')) {
      return TaskPriority.urgent;
    }
    
    if (summary.contains('重要') || summary.contains('important')) {
      return TaskPriority.high;
    }
    
    return TaskPriority.medium;
  }
  
  /// 推定時間を計算
  int? _calculateEstimatedMinutes(DateTime? startTime, DateTime? endTime) {
    if (startTime == null || endTime == null) {
      return null;
    }
    
    final duration = endTime.difference(startTime);
    return duration.inMinutes;
  }
  
  /// 参加者を抽出
  String? _extractAttendees(Map<String, dynamic> event) {
    final attendees = event['attendees'] as List?;
    if (attendees == null || attendees.isEmpty) {
      return null;
    }
    
    final attendeeNames = attendees
        .where((attendee) => attendee['displayName'] != null)
        .map((attendee) => attendee['displayName'])
        .take(3) // 最大3名まで
        .join(', ');
    
    return attendeeNames.isNotEmpty ? attendeeNames : null;
  }
  
  /// タスクをGoogle Calendarに送信
  Future<SyncResult> createCalendarEvent(TaskItem task) async {
    if (!_isInitialized || _accessToken == null) {
      ErrorHandler.logError('Google Calendar送信', '認証されていません');
      return SyncResult(
        success: false,
        errorMessage: 'Google Calendarが認証されていません。設定画面でOAuth2認証を実行してください。',
        errorCode: 'AUTH_REQUIRED',
      );
    }

    try {
      // アクセストークンの有効性を確認
      if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          ErrorHandler.logError('Google Calendar送信', 'トークンの更新に失敗しました');
          return SyncResult(
            success: false,
            errorMessage: 'アクセストークンの更新に失敗しました。再認証が必要です。',
            errorCode: 'TOKEN_REFRESH_FAILED',
          );
        }
      }

      // イベントの開始時間を設定（終日イベント用）
      DateTime startTime;
      
      if (task.dueDate != null) {
        startTime = task.dueDate!;
      } else if (task.reminderTime != null) {
        startTime = task.reminderTime!;
      } else {
        ErrorHandler.logError('Google Calendar送信', 'タスクに期限日またはリマインダー時間が設定されていません');
        return SyncResult(
          success: false,
          errorMessage: 'タスクに期限日またはリマインダー時間が設定されていません。',
          errorCode: 'NO_DATE_SET',
        );
      }

      // 詳細説明を構築
      final description = _buildEnhancedDescription(task);
      
      // 日付のみの終日イベントとして作成
      final eventData = {
        'summary': task.title,
        'description': description,
        'start': {
          'date': startTime.toIso8601String().split('T')[0], // 日付のみ
        },
        'end': {
          'date': startTime.add(const Duration(days: 1)).toIso8601String().split('T')[0], // 翌日
        },
        'colorId': _getStatusColorId(task.status), // ステータスに応じた色ID
        'reminders': {
          'useDefault': false,
          'overrides': [
            {'method': 'popup', 'minutes': 0}, // 当日の0分前（開始時刻）
          ],
        },
        'extendedProperties': {
          'private': {
            'taskId': task.id,
            'priority': task.priority.toString(),
            'status': task.status.toString(),
            'estimatedMinutes': task.estimatedMinutes?.toString() ?? '',
          }
        }
      };

      // 場所情報がある場合のみ追加
      if (task.assignedTo != null && task.assignedTo!.isNotEmpty) {
        eventData['location'] = task.assignedTo!;
      }

      // Google Calendar APIに送信
      final response = await http.post(
        Uri.parse('$_calendarApiUrl/calendars/primary/events'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(eventData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (kDebugMode) {
          print('Google Calendarイベント作成成功: ${responseData['id']}');
        }
        return SyncResult(
          success: true,
          details: {'eventId': responseData['id']},
        );
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = _getErrorMessage(response.statusCode, errorBody);
        ErrorHandler.logError('Google Calendar送信', 'HTTP ${response.statusCode}: ${response.body}');
        return SyncResult(
          success: false,
          errorMessage: errorMessage,
          errorCode: 'HTTP_${response.statusCode}',
          details: errorBody,
        );
      }
    } catch (e) {
      ErrorHandler.logError('Google Calendar送信', e);
      return SyncResult(
        success: false,
        errorMessage: 'ネットワークエラーまたは予期しないエラーが発生しました: ${e.toString()}',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  /// タスクのGoogle Calendarイベントを更新
  Future<bool> updateCalendarEvent(TaskItem task, String eventId) async {
    if (!_isInitialized || _accessToken == null) {
      ErrorHandler.logError('Google Calendar更新', '認証されていません');
      return false;
    }

    try {
      // アクセストークンの有効性を確認
      if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          ErrorHandler.logError('Google Calendar更新', 'トークンの更新に失敗しました');
          return false;
        }
      }

      // イベントの開始時間を設定（終日イベント用）
      DateTime startTime;
      
      if (task.dueDate != null) {
        startTime = task.dueDate!;
      } else if (task.reminderTime != null) {
        startTime = task.reminderTime!;
      } else {
        ErrorHandler.logError('Google Calendar更新', 'タスクに期限日またはリマインダー時間が設定されていません');
        return false;
      }

      // 詳細説明を構築
      final description = _buildEnhancedDescription(task);
      
      // 日付のみの終日イベントとして更新
      final eventData = {
        'summary': task.title,
        'description': description,
        'start': {
          'date': startTime.toIso8601String().split('T')[0], // 日付のみ
        },
        'end': {
          'date': startTime.add(const Duration(days: 1)).toIso8601String().split('T')[0], // 翌日
        },
        'colorId': _getStatusColorId(task.status), // ステータスに応じた色ID
        'reminders': {
          'useDefault': false,
          'overrides': [
            {'method': 'popup', 'minutes': 0}, // 当日の0分前（開始時刻）
          ],
        },
        'extendedProperties': {
          'private': {
            'taskId': task.id,
            'priority': task.priority.toString(),
            'status': task.status.toString(),
            'estimatedMinutes': task.estimatedMinutes?.toString() ?? '',
          }
        }
      };

      // 場所情報がある場合のみ追加
      if (task.assignedTo != null && task.assignedTo!.isNotEmpty) {
        eventData['location'] = task.assignedTo!;
      }

      // Google Calendar APIに送信
      final response = await http.put(
        Uri.parse('$_calendarApiUrl/calendars/primary/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(eventData),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Google Calendarイベント更新成功: $eventId');
        }
        return true;
      } else {
        ErrorHandler.logError('Google Calendar更新', 'HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      ErrorHandler.logError('Google Calendar更新', e);
      return false;
    }
  }

  /// タスクのGoogle Calendarイベントを削除
  Future<bool> deleteCalendarEvent(String eventId) async {
    if (!_isInitialized || _accessToken == null) {
      ErrorHandler.logError('Google Calendar削除', '認証されていません');
      return false;
    }

    try {
      // アクセストークンの有効性を確認
      if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          ErrorHandler.logError('Google Calendar削除', 'トークンの更新に失敗しました');
          return false;
        }
      }

      // Google Calendar APIに送信
      final response = await http.delete(
        Uri.parse('$_calendarApiUrl/calendars/primary/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 204) {
        if (kDebugMode) {
          print('Google Calendarイベント削除成功: $eventId');
        }
        return true;
      } else {
        ErrorHandler.logError('Google Calendar削除', 'HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      ErrorHandler.logError('Google Calendar削除', e);
      return false;
    }
  }

  /// 認証状態を確認
  bool get isAuthenticated {
    return _isInitialized && _accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!);
  }

  /// タスクステータスに応じたGoogle Calendar色IDを取得
  String _getStatusColorId(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '8'; // グラファイト（グレー）- 未着手
      case TaskStatus.inProgress:
        return '7'; // ピーコック（青）- 進行中
      case TaskStatus.completed:
        return '10'; // バジル（緑）- 完了済み
      case TaskStatus.cancelled:
        return '11'; // トマト（赤）- キャンセル
    }
  }

  /// 拡張された詳細説明を構築
  String _buildEnhancedDescription(TaskItem task) {
    final parts = <String>[];
    
    // 基本説明
    if (task.description != null && task.description!.isNotEmpty) {
      parts.add(task.description!);
    }
    
    // 追加メモ
    if (task.notes != null && task.notes!.isNotEmpty) {
      parts.add('📝 メモ: ${task.notes!}');
    }
    
    // タグ情報
    if (task.tags.isNotEmpty) {
      parts.add('🏷️ タグ: ${task.tags.join(', ')}');
    }
    
    // 推定時間
    if (task.estimatedMinutes != null && task.estimatedMinutes! > 0) {
      final hours = task.estimatedMinutes! ~/ 60;
      final minutes = task.estimatedMinutes! % 60;
      if (hours > 0) {
        parts.add('⏱️ 推定時間: ${hours}時間${minutes > 0 ? '${minutes}分' : ''}');
      } else {
        parts.add('⏱️ 推定時間: ${minutes}分');
      }
    }
    
    // 優先度情報
    final priorityText = _getPriorityText(task.priority);
    parts.add('⭐ 優先度: $priorityText');
    
    // ステータス情報
    final statusText = _getStatusText(task.status);
    parts.add('📊 ステータス: $statusText');
    
    // 作成日時
    parts.add('📅 作成日: ${task.createdAt.toIso8601String().split('T')[0]}');
    
    return parts.join('\n');
  }

  /// 優先度のテキストを取得
  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '緊急';
    }
  }

  /// ステータスのテキストを取得
  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '未着手';
      case TaskStatus.inProgress:
        return '進行中';
      case TaskStatus.completed:
        return '完了';
      case TaskStatus.cancelled:
        return 'キャンセル';
    }
  }

  /// エラーメッセージを生成
  String _getErrorMessage(int statusCode, Map<String, dynamic> errorBody) {
    switch (statusCode) {
      case 400:
        return 'リクエストが無効です。タスクの情報を確認してください。';
      case 401:
        return '認証に失敗しました。Google Calendarの認証を再実行してください。';
      case 403:
        return 'アクセスが拒否されました。Google Calendarの権限を確認してください。';
      case 404:
        return 'カレンダーが見つかりません。';
      case 429:
        return 'リクエスト制限に達しました。しばらく待ってから再試行してください。';
      case 500:
        return 'Google Calendarサーバーでエラーが発生しました。';
      case 503:
        return 'Google Calendarサービスが一時的に利用できません。';
      default:
        final error = errorBody['error'];
        if (error != null && error['message'] != null) {
          return 'Google Calendarエラー: ${error['message']}';
        }
        return '予期しないエラーが発生しました (HTTP $statusCode)';
    }
  }

  /// リソースを解放
  void dispose() {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _isInitialized = false;
  }
}

/// Google Calendar認証情報の設定を支援するユーティリティ
class GoogleCalendarSetup {
  /// 認証情報ファイルのテンプレートを生成（OAuth2デスクトップアプリ用）
  static String generateCredentialsTemplate() {
    return '''
{
  "installed": {
    "client_id": "your-client-id.apps.googleusercontent.com",
    "project_id": "your-project-id",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_secret": "your-client-secret",
    "redirect_uris": ["http://localhost:8080"]
  }
}
''';
  }
  
  /// 認証情報ファイルを作成
  static Future<bool> createCredentialsFile(String credentialsJson) async {
    try {
      final file = File('google_calendar_credentials.json');
      await file.writeAsString(credentialsJson);
      return true;
    } catch (e) {
      ErrorHandler.logError('認証情報ファイル作成', e);
      return false;
    }
  }
  
  /// 認証情報ファイルの存在確認
  static Future<bool> hasCredentialsFile() async {
    try {
      // ユーザーディレクトリを確認
      final userDir = await getApplicationDocumentsDirectory();
      final userCredentialsPath = '${userDir.path}/google_calendar_credentials.json';
      final userCredentialsFile = File(userCredentialsPath);
      
      if (await userCredentialsFile.exists()) {
        return true;
      }
      
      // 実行ディレクトリを確認
      final currentDirCredentialsFile = File('google_calendar_credentials.json');
      return await currentDirCredentialsFile.exists();
    } catch (e) {
      // エラーの場合は実行ディレクトリのみ確認
      final file = File('google_calendar_credentials.json');
      return await file.exists();
    }
  }
  
  /// 認証情報ファイルのパスを取得
  static Future<String> getCredentialsFilePath() async {
    try {
      // ユーザーディレクトリを確認
      final userDir = await getApplicationDocumentsDirectory();
      final userCredentialsPath = '${userDir.path}/google_calendar_credentials.json';
      final userCredentialsFile = File(userCredentialsPath);
      
      if (await userCredentialsFile.exists()) {
        return userCredentialsPath;
      }
      
      // 実行ディレクトリを確認
      final currentDirCredentialsFile = File('google_calendar_credentials.json');
      if (await currentDirCredentialsFile.exists()) {
        return 'google_calendar_credentials.json';
      }
      
      // どちらにもない場合はユーザーディレクトリのパスを返す
      return userCredentialsPath;
    } catch (e) {
      // エラーの場合は実行ディレクトリを返す
      return 'google_calendar_credentials.json';
    }
  }
}