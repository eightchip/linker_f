import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
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
  
  /// 初期化
  Future<bool> initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('Google Calendar サービス初期化開始');
      }
      
      // 認証情報ファイルの存在確認
      final credentialsPath = await _getCredentialsPath();
      final credentialsFile = File(credentialsPath);
      if (!await credentialsFile.exists()) {
        if (kDebugMode) {
          debugPrint('OAuth2認証情報ファイルが見つかりません: $credentialsPath');
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
          debugPrint('Google Calendar サービス初期化完了');
        }
        return true;
      }
      
      // 新しい認証が必要
      if (kDebugMode) {
        debugPrint('新しいOAuth2認証が必要です');
      }
      _isInitialized = false;
      return false;
    } catch (e) {
      ErrorHandler.logError('Google Calendar初期化', e);
      if (kDebugMode) {
        debugPrint('Google Calendar初期化エラー: $e');
      }
      return false;
    }
  }
  
  /// 初期化状態を確認
  bool get isInitialized => _isInitialized;
  
  /// 認証状態を確認
  bool get isAuthenticated {
    return _isInitialized && 
           _accessToken != null && 
           _tokenExpiry != null && 
           DateTime.now().isBefore(_tokenExpiry!);
  }
  
  /// 認証ファイルのパスを取得
  Future<String> _getCredentialsPath() async {
    try {
      final userDir = await getApplicationDocumentsDirectory();
      final userCredentialsPath = '${userDir.path}/$_credentialsFileName';
      final userCredentialsFile = File(userCredentialsPath);
      
      if (await userCredentialsFile.exists()) {
        return userCredentialsPath;
      }
      
      final currentDirCredentialsFile = File(_credentialsFileName);
      if (await currentDirCredentialsFile.exists()) {
        return _credentialsFileName;
      }
      
      return userCredentialsPath;
    } catch (e) {
      return _credentialsFileName;
    }
  }
  
  /// トークンファイルのパスを取得
  Future<String> _getTokensPath() async {
    try {
      final userDir = await getApplicationDocumentsDirectory();
      return '${userDir.path}/$_tokensFileName';
    } catch (e) {
      return _tokensFileName;
    }
  }
  
  /// 保存されたトークンを読み込み
  Future<bool> _loadStoredTokens() async {
    try {
      final tokensPath = await _getTokensPath();
      final tokenFile = File(tokensPath);
      if (!await tokenFile.exists()) {
        return false;
      }
      
      final tokenJson = await tokenFile.readAsString();
      final tokens = json.decode(tokenJson);
      
      _accessToken = tokens['access_token'];
      _refreshToken = tokens['refresh_token'];
      if (tokens['expires_at'] != null) {
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(tokens['expires_at']);
      }
      
      if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
        return true;
      }
      
      if (_refreshToken != null) {
        return await _refreshAccessToken();
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('保存されたトークンの読み込みエラー: $e');
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
        debugPrint('トークン保存エラー: $e');
      }
    }
  }
  
  /// OAuth2認証を開始
  Future<bool> startOAuth2Auth() async {
    try {
      if (kDebugMode) {
        debugPrint('OAuth2認証を開始します');
      }
      
      final credentialsPath = await _getCredentialsPath();
      final credentialsFile = File(credentialsPath);
      if (!await credentialsFile.exists()) {
        throw Exception('OAuth2認証情報ファイルが見つかりません。');
      }
      
      final credentialsJson = await credentialsFile.readAsString();
      final credentials = json.decode(credentialsJson);
      
      if (!credentials.containsKey('installed')) {
        throw Exception('認証情報ファイルの形式が正しくありません。');
      }
      
      final installed = credentials['installed'];
      final clientId = installed['client_id'];
      
      if (clientId == null || clientId.isEmpty) {
        throw Exception('client_id が設定されていません。');
      }
      
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
      
      final authCode = await _startLocalServerAndGetAuthCode(authUrl);
      
      if (authCode != null) {
        final success = await exchangeCodeForTokens(authCode);
        if (success) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      ErrorHandler.logError('OAuth2認証開始', e);
      return false;
    }
  }
  
  /// ローカルサーバーを起動して認証コードを受信
  Future<String?> _startLocalServerAndGetAuthCode(Uri authUrl) async {
    HttpServer? server;
    
    try {
      server = await HttpServer.bind('127.0.0.1', 8080);
      
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('認証URLを開けませんでした');
      }
      
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
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.html
              ..write('<html><body><h1>認証が完了しました！</h1><p>このウィンドウを閉じてください。</p></body></html>');
            await request.response.close();
            
            if (!completer.isCompleted) {
              completer.complete(authCode);
            }
          } else if (error != null) {
            request.response
              ..statusCode = 400
              ..headers.contentType = ContentType.html
              ..write('<html><body><h1>認証エラー</h1><p>エラー: $error</p></body></html>');
            await request.response.close();
            
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        } else {
          request.response
            ..statusCode = 404
            ..write('Not Found');
          await request.response.close();
        }
      });
      
      return await completer.future;
    } finally {
      await server?.close();
    }
  }
  
  /// 認証コードからトークンを取得
  Future<bool> exchangeCodeForTokens(String authCode) async {
    try {
      final credentialsPath = await _getCredentialsPath();
      final credentialsFile = File(credentialsPath);
      final credentialsJson = await credentialsFile.readAsString();
      final credentials = json.decode(credentialsJson);
      final clientId = credentials['installed']['client_id'];
      final clientSecret = credentials['installed']['client_secret'];
      
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
        
        await _saveTokens();
        _isInitialized = true;
        return true;
      }
      
      return false;
    } catch (e) {
      ErrorHandler.logError('認証コード交換', e);
      return false;
    }
  }
  
  /// アクセストークンをリフレッシュ
  Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) {
        return false;
      }
      
      final credentialsPath = await _getCredentialsPath();
      final credentialsFile = File(credentialsPath);
      final credentialsJson = await credentialsFile.readAsString();
      final credentials = json.decode(credentialsJson);
      final clientId = credentials['installed']['client_id'];
      final clientSecret = credentials['installed']['client_secret'];
      
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
        
        await _saveTokens();
        return true;
      }
      
      return false;
    } catch (e) {
      ErrorHandler.logError('トークンリフレッシュ', e);
      return false;
    }
  }
  
  /// 有効なアクセストークンを取得
  Future<String?> _getValidAccessToken() async {
    try {
      if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
        return _accessToken;
      }
      
      if (_refreshToken != null) {
        if (await _refreshAccessToken()) {
          return _accessToken;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// タスクをGoogle Calendarに送信
  Future<SyncResult> createCalendarEvent(TaskItem task) async {
    if (!_isInitialized || _accessToken == null) {
      return SyncResult(
        success: false,
        errorMessage: 'Google Calendarが認証されていません。',
        errorCode: 'AUTH_REQUIRED',
      );
    }

    try {
      if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          return SyncResult(
            success: false,
            errorMessage: 'アクセストークンの更新に失敗しました。',
            errorCode: 'TOKEN_REFRESH_FAILED',
          );
        }
      }

      DateTime startTime;
      if (task.dueDate != null) {
        startTime = task.dueDate!;
      } else if (task.reminderTime != null) {
        startTime = task.reminderTime!;
      } else {
        return SyncResult(
          success: false,
          errorMessage: 'タスクに期限日またはリマインダー時間が設定されていません。',
          errorCode: 'NO_DATE_SET',
        );
      }

      final eventData = {
        'summary': task.title,
        'description': task.description ?? '',
        'start': {
          'date': startTime.toIso8601String().split('T')[0],
        },
        'end': {
          'date': startTime.add(const Duration(days: 1)).toIso8601String().split('T')[0],
        },
        'colorId': _getStatusColorId(task.status),
        'extendedProperties': {
          'private': {
            'taskId': task.id,
            'priority': task.priority.toString(),
            'status': task.status.toString(),
          }
        }
      };

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
        return SyncResult(
          success: true,
          details: {'eventId': responseData['id']},
        );
      } else {
        return SyncResult(
          success: false,
          errorMessage: 'Google Calendarイベント作成に失敗しました。',
          errorCode: 'HTTP_${response.statusCode}',
        );
      }
    } catch (e) {
      ErrorHandler.logError('Google Calendar送信', e);
      return SyncResult(
        success: false,
        errorMessage: 'ネットワークエラーが発生しました: ${e.toString()}',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  /// タスクのGoogle Calendarイベントを更新
  Future<bool> updateCalendarEvent(TaskItem task, String eventId) async {
    if (!_isInitialized || _accessToken == null) {
      return false;
    }

    try {
      if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          return false;
        }
      }

      DateTime startTime;
      if (task.dueDate != null) {
        startTime = task.dueDate!;
      } else if (task.reminderTime != null) {
        startTime = task.reminderTime!;
      } else {
        return false;
      }

      final eventData = {
        'summary': task.title,
        'description': task.description ?? '',
        'start': {
          'date': startTime.toIso8601String().split('T')[0],
        },
        'end': {
          'date': startTime.add(const Duration(days: 1)).toIso8601String().split('T')[0],
        },
        'colorId': _getStatusColorId(task.status),
        'extendedProperties': {
          'private': {
            'taskId': task.id,
            'priority': task.priority.toString(),
            'status': task.status.toString(),
          }
        }
      };

      final response = await http.put(
        Uri.parse('$_calendarApiUrl/calendars/primary/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(eventData),
      );

      return response.statusCode == 200;
    } catch (e) {
      ErrorHandler.logError('Google Calendar更新', e);
      return false;
    }
  }

  /// タスクのGoogle Calendarイベントを削除
  Future<bool> deleteCalendarEvent(String eventId) async {
    if (!_isInitialized || _accessToken == null) {
      return false;
    }

    try {
      if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          return false;
        }
      }

      final response = await http.delete(
        Uri.parse('$_calendarApiUrl/calendars/primary/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      ErrorHandler.logError('Google Calendar削除', e);
      return false;
    }
  }

  /// タスクステータスに応じたGoogle Calendar色IDを取得
  String _getStatusColorId(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '8'; // グラファイト（グレー）
      case TaskStatus.inProgress:
        return '7'; // ピーコック（青）
      case TaskStatus.completed:
        return '10'; // バジル（緑）
      case TaskStatus.cancelled:
        return '11'; // トマト（赤）
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