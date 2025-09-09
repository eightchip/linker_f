import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task_item.dart';
import '../utils/error_handler.dart';

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
      final credentials = json.decode(credentialsJson);
      
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
        throw Exception('OAuth2認証情報ファイルが見つかりません: $credentialsPath');
      }
      
      final credentialsJson = await credentialsFile.readAsString();
      final credentials = json.decode(credentialsJson);
      final clientId = credentials['installed']['client_id'];
      
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
      final credentialsFile = File(_credentialsFileName);
      final credentialsJson = await credentialsFile.readAsString();
      final credentials = json.decode(credentialsJson);
      final clientId = credentials['installed']['client_id'];
      final clientSecret = credentials['web']['client_secret'];
      
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
  
  /// 同期を実行
  Future<List<TaskItem>> syncEvents({
    DateTime? startTime,
    DateTime? endTime,
    int maxResults = 50,
  }) async {
    try {
      if (kDebugMode) {
        print('Google Calendar 同期開始');
      }
      
      // 有効なアクセストークンを確認
      final accessToken = await _getValidAccessToken();
      if (accessToken == null) {
        throw Exception('有効なアクセストークンがありません。OAuth2認証を実行してください。');
      }
      
      // イベントを取得
      final events = await getEvents(
        startTime: startTime,
        endTime: endTime,
        maxResults: maxResults,
      );
      
      // タスクに変換
      final tasks = convertEventsToTasks(events);
      
      if (kDebugMode) {
        print('Google Calendar 同期完了: ${tasks.length}件のタスクを取得');
      }
      
      return tasks;
    } catch (e) {
      ErrorHandler.logError('Google Calendar 同期', e);
      rethrow;
    }
  }
  
  /// リソースを解放
  void dispose() {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _isInitialized = false;
  }

  /// タスクをGoogle Calendarに送信
  Future<bool> createCalendarEvent(TaskItem task) async {
    if (!_isInitialized || _accessToken == null) {
      ErrorHandler.logError('Google Calendar送信', '認証されていません');
      return false;
    }

    try {
      // アクセストークンの有効性を確認
      if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          ErrorHandler.logError('Google Calendar送信', 'トークンの更新に失敗しました');
          return false;
        }
      }

      // イベントの開始・終了時間を設定
      DateTime startTime;
      DateTime endTime;
      
      if (task.dueDate != null) {
        startTime = task.dueDate!;
        endTime = startTime.add(const Duration(hours: 1)); // デフォルト1時間
      } else if (task.reminderTime != null) {
        startTime = task.reminderTime!;
        endTime = startTime.add(const Duration(hours: 1));
      } else {
        ErrorHandler.logError('Google Calendar送信', 'タスクに期限日またはリマインダー時間が設定されていません');
        return false;
      }

      // イベントデータを作成
      final eventData = {
        'summary': task.title,
        'description': task.description ?? '',
        'start': {
          'dateTime': startTime.toIso8601String(),
          'timeZone': 'Asia/Tokyo',
        },
        'end': {
          'dateTime': endTime.toIso8601String(),
          'timeZone': 'Asia/Tokyo',
        },
        'reminders': {
          'useDefault': false,
          'overrides': [
            {'method': 'popup', 'minutes': 15},
            {'method': 'email', 'minutes': 30},
          ],
        },
        'extendedProperties': {
          'private': {
            'taskId': task.id,
            'priority': task.priority.toString(),
            'status': task.status.toString(),
          }
        }
      };

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
        print('Google Calendarイベント作成成功: ${responseData['id']}');
        return true;
      } else {
        ErrorHandler.logError('Google Calendar送信', 'HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      ErrorHandler.logError('Google Calendar送信', e);
      return false;
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

      // イベントの開始・終了時間を設定
      DateTime startTime;
      DateTime endTime;
      
      if (task.dueDate != null) {
        startTime = task.dueDate!;
        endTime = startTime.add(const Duration(hours: 1));
      } else if (task.reminderTime != null) {
        startTime = task.reminderTime!;
        endTime = startTime.add(const Duration(hours: 1));
      } else {
        ErrorHandler.logError('Google Calendar更新', 'タスクに期限日またはリマインダー時間が設定されていません');
        return false;
      }

      // イベントデータを作成
      final eventData = {
        'summary': task.title,
        'description': task.description ?? '',
        'start': {
          'dateTime': startTime.toIso8601String(),
          'timeZone': 'Asia/Tokyo',
        },
        'end': {
          'dateTime': endTime.toIso8601String(),
          'timeZone': 'Asia/Tokyo',
        },
        'reminders': {
          'useDefault': false,
          'overrides': [
            {'method': 'popup', 'minutes': 15},
            {'method': 'email', 'minutes': 30},
          ],
        },
        'extendedProperties': {
          'private': {
            'taskId': task.id,
            'priority': task.priority.toString(),
            'status': task.status.toString(),
          }
        }
      };

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
        print('Google Calendarイベント更新成功: $eventId');
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
        print('Google Calendarイベント削除成功: $eventId');
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

  /// タスクのGoogle CalendarイベントIDを取得
  Future<String?> getCalendarEventId(TaskItem task) async {
    if (!_isInitialized || _accessToken == null) {
      return null;
    }

    try {
      // アクセストークンの有効性を確認
      if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          return null;
        }
      }

      // タスクIDでイベントを検索
      final response = await http.get(
        Uri.parse('$_calendarApiUrl/calendars/primary/events?q=${task.id}'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data['items'] as List?;
        
        if (events != null && events.isNotEmpty) {
          for (final event in events) {
            final extendedProperties = event['extendedProperties']?['private'];
            if (extendedProperties != null && extendedProperties['taskId'] == task.id) {
              return event['id'] as String;
            }
          }
        }
      }
    } catch (e) {
      ErrorHandler.logError('Google CalendarイベントID取得', e);
    }
    
    return null;
  }

  /// 包括的Google Calendar同期（全タスクを一括同期）
  Future<Map<String, dynamic>> syncAllTasksToGoogleCalendar(List<TaskItem> tasks) async {
    if (!_isInitialized || _accessToken == null) {
      return {
        'success': false,
        'error': '認証されていません',
        'created': 0,
        'updated': 0,
        'deleted': 0,
      };
    }

    try {
      // アクセストークンの有効性を確認
      if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          return {
            'success': false,
            'error': 'トークンの更新に失敗しました',
            'created': 0,
            'updated': 0,
            'deleted': 0,
          };
        }
      }

      print('=== Google Calendar包括的同期開始 ===');
      print('同期対象タスク数: ${tasks.length}');

      // 1. 現在のGoogle Calendarイベントを取得
      final existingEvents = await _getAllCalendarEvents();
      print('既存のGoogle Calendarイベント数: ${existingEvents.length}');

      // 2. 同期対象タスクをフィルタリング（期限日またはリマインダー時間があるもの）
      final syncableTasks = tasks.where((task) => 
        task.dueDate != null || task.reminderTime != null
      ).toList();
      print('同期可能タスク数: ${syncableTasks.length}');

      int created = 0;
      int updated = 0;
      int deleted = 0;

      // 3. 各タスクを同期（タスクが存在する場合のみ）
      for (final task in syncableTasks) {
        final result = await _syncSingleTask(task, existingEvents);
        switch (result) {
          case 'created':
            created++;
            break;
          case 'updated':
            updated++;
            break;
          case 'skipped':
            break;
        }
      }

      // 4. 削除されたタスクのイベントを削除
      // アプリのタスクIDセットを作成（空のリストでも動作）
      final taskIds = syncableTasks.map((task) => task.id).toSet();
      
      // 既存のGoogle Calendarイベントをチェック
      for (final event in existingEvents) {
        final taskId = event['extendedProperties']?['private']?['taskId'];
        if (taskId != null && !taskIds.contains(taskId)) {
          print('削除対象のイベント: ${event['summary']} (タスクID: $taskId)');
          final success = await deleteCalendarEvent(event['id']);
          if (success) {
            deleted++;
            print('イベント削除成功: ${event['summary']}');
          } else {
            print('イベント削除失敗: ${event['summary']}');
          }
        }
      }

      print('=== Google Calendar包括的同期完了 ===');
      print('作成: $created, 更新: $updated, 削除: $deleted');

      return {
        'success': true,
        'created': created,
        'updated': updated,
        'deleted': deleted,
      };
    } catch (e) {
      ErrorHandler.logError('Google Calendar包括的同期', e);
      return {
        'success': false,
        'error': e.toString(),
        'created': 0,
        'updated': 0,
        'deleted': 0,
      };
    }
  }

  /// 全てのGoogle Calendarイベントを取得
  Future<List<Map<String, dynamic>>> _getAllCalendarEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$_calendarApiUrl/calendars/primary/events'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data['items'] as List?;
        
        if (events != null) {
          // アプリから作成されたイベントのみをフィルタリング
          return events.where((event) {
            final extendedProperties = event['extendedProperties']?['private'];
            return extendedProperties != null && extendedProperties['taskId'] != null;
          }).cast<Map<String, dynamic>>().toList();
        }
      }
    } catch (e) {
      ErrorHandler.logError('Google Calendarイベント取得', e);
    }
    
    return [];
  }

  /// 単一タスクの同期
  Future<String> _syncSingleTask(TaskItem task, List<Map<String, dynamic>> existingEvents) async {
    try {
      // 既存のイベントを検索
      Map<String, dynamic>? existingEvent;
      for (final event in existingEvents) {
        final taskId = event['extendedProperties']?['private']?['taskId'];
        if (taskId == task.id) {
          existingEvent = event;
          break;
        }
      }

      if (existingEvent != null) {
        // 既存イベントの更新
        final success = await updateCalendarEvent(task, existingEvent['id']);
        return success ? 'updated' : 'skipped';
      } else {
        // 新規イベントの作成
        final success = await createCalendarEvent(task);
        return success ? 'created' : 'skipped';
      }
    } catch (e) {
      ErrorHandler.logError('単一タスク同期', e);
      return 'skipped';
    }
  }
}

/// Google Calendar認証情報の設定を支援するユーティリティ
class GoogleCalendarSetup {
  /// 認証情報ファイルのテンプレートを生成
  static String generateCredentialsTemplate() {
    return '''
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "your-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nYOUR_PRIVATE_KEY\\n-----END PRIVATE KEY-----\\n",
  "client_email": "your-service-account@your-project-id.iam.gserviceaccount.com",
  "client_id": "your-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/your-service-account%40your-project-id.iam.gserviceaccount.com"
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
    final file = File('google_calendar_credentials.json');
    return await file.exists();
  }
}
