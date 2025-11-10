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
import '../models/schedule_item.dart';
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
  static const String _scheduleEventColorId = '5'; // Banana (yellow)
  
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
        
        // タスクの作成（詳細情報を含む）
        final task = _convertEventToTask(event);
        if (task != null) {
          tasks.add(task);
          
          if (kDebugMode) {
            print('Google Calendar イベントをタスクに変換: $title');
          }
        }
      } catch (e) {
        ErrorHandler.logError('イベント変換エラー: ${event['summary']}', e);
      }
    }
    
    return tasks;
  }
  
  /// ビジネスイベントかどうかを判定
  bool _isBusinessEvent(String title, String description) {
    final titleLower = title.toLowerCase();
    final descriptionLower = description.toLowerCase();
    
    // ビジネス関連のキーワード
    final businessKeywords = [
      '会議', 'meeting', '打ち合わせ', '商談', '営業', 'sales', 'business',
      'プロジェクト', 'project', 'ミーティング', 'mtg', 'mtg', 'm&a',
      'レビュー', 'review', '報告', 'report', 'プレゼン', 'presentation',
      '研修', 'training', 'セミナー', 'seminar', '講習', 'workshop',
      '面談', 'interview', '評価', 'evaluation', '1on1', 'one-on-one',
      '定例', 'regular', '週次', 'weekly', '月次', 'monthly', '四半期', 'quarterly',
      '顧客', 'customer', 'クライアント', 'client', '取引先', 'partner',
      '契約', 'contract', '提案', 'proposal', '企画', 'planning',
      '開発', 'development', 'デザイン', 'design', 'テスト', 'test',
      'リリース', 'release', 'デプロイ', 'deploy', '運用', 'operation',
      'サポート', 'support', '保守', 'maintenance', '障害', 'incident',
      '電話', 'call', 'テレビ会議', 'zoom', 'teams', 'webex', 'skype',
      '出張', 'business trip', '訪問', 'visit', '移動', 'travel',
      '資料', 'document', '資料作成', '資料準備', '資料確認', '資料レビュー',
      '予算', 'budget', 'コスト', 'cost', '経費', 'expense',
      'スケジュール', 'schedule', '調整', 'coordination', '調整会議',
      '承認', 'approval', '決裁', 'decision', '確認', 'confirmation',
      'フォロー', 'follow-up', 'follow up', 'アフター', 'after',
      'キックオフ', 'kickoff', 'kick-off', '開始', 'start', 'スタート',
      '完了', 'completion', '終了', 'finish', 'close', 'クローズ',
      '振り返り', 'retrospective', 'レトロ', 'retro', '反省会',
      '歓送迎会', '送別会', '歓迎会', '飲み会', '懇親会', '忘年会', '新年会',
      'イベント', 'event', '展示会', 'exhibition', '見本市', 'trade show',
      'マーケティング', 'marketing', 'キャンペーン', 'campaign', 'プロモーション',
      '人事', 'hr', '採用', 'recruitment', '面接', 'interview',
      '法務', 'legal', 'コンプライアンス', 'compliance', '契約書',
      '財務', 'finance', '経理', 'accounting', '会計', 'audit',
      'システム', 'system', 'it', 'インフラ', 'infrastructure',
      'セキュリティ', 'security', 'プライバシー', 'privacy', 'gdpr',
      '品質', 'quality', 'qa', 'テスト', 'test', '検証', 'verification',
      'パフォーマンス', 'performance', '最適化', 'optimization',
      '分析', 'analysis', 'データ', 'data', 'レポート', 'report',
      'kpi', '指標', 'metric', '測定', 'measurement', '評価', 'evaluation'
    ];
    
    // ビジネスキーワードが含まれているかチェック
    for (final keyword in businessKeywords) {
      if (titleLower.contains(keyword) || descriptionLower.contains(keyword)) {
        return true;
      }
    }
    
    // 時刻指定のイベントはビジネスイベントの可能性が高い
    return false;
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
      '元日', '振替', '休業', '休日', '祝祭日', '国民の休日',
      // 追加の祝日キーワード
      'japanese holiday', 'national holiday', 'public holiday', 'calendar holiday',
      '祝', '祭', '日', '誕生日', '記念日', 'イベント', 'event', 'カレンダー', 'calendar',
      // 日本の祝日名（詳細）
      '元日', '成人の日', '建国記念の日', '天皇誕生日', '春分の日', '昭和の日',
      '憲法記念日', 'みどりの日', 'こどもの日', '海の日', '山の日', '敬老の日',
      '秋分の日', 'スポーツの日', '文化の日', '勤労感謝の日',
      // その他の休日
      '土日', 'weekend', '土曜', '日曜', 'saturday', 'sunday'
    ];
    
    // キーワードチェック（より慎重に）
    for (final keyword in holidayKeywords) {
      if (titleLower.contains(keyword) || descriptionLower.contains(keyword)) {
        // ただし、明らかにビジネス関連のイベントは除外しない
        if (_isBusinessEvent(title, description)) {
          if (kDebugMode) {
            print('ビジネスイベントのため祝日除外をスキップ: "$title" (キーワード: "$keyword")');
          }
          continue;
        }
        
        if (kDebugMode) {
          print('祝日キーワードで除外: "$title" (キーワード: "$keyword")');
        }
        return true;
      }
    }
    
    // Google Calendarの祝日カレンダーを除外
    final calendarId = event['organizer']?['email'] ?? '';
    if (calendarId.contains('holiday') || calendarId.contains('祝日')) {
      if (kDebugMode) {
        print('祝日カレンダーで除外: "$title" (カレンダー: "$calendarId")');
      }
      return true;
    }
    
    // イベントの作成者をチェック
    final creator = event['creator']?['email'] ?? '';
    if (creator.contains('holiday') || creator.contains('祝日') || creator.contains('calendar')) {
      if (kDebugMode) {
        print('祝日作成者で除外: "$title" (作成者: "$creator")');
      }
      return true;
    }
    
    // 終日イベントの判定を緩和
    final start = event['start'];
    final end = event['end'];
    
    if (start != null && end != null) {
      // 終日イベントかどうかをチェック
      final isAllDay = start['date'] != null && end['date'] != null;
      
      if (isAllDay) {
        // ビジネスイベントの場合は除外しない
        if (_isBusinessEvent(title, description)) {
          if (kDebugMode) {
            print('終日ビジネスイベントのため除外をスキップ: "$title"');
          }
          return false;
        }
        
        // タイトルが非常に短い場合のみ除外（5文字以下に緩和）
        if (titleLower.length <= 5) {
          if (kDebugMode) {
            print('終日イベント（極短タイトル）で除外: "$title"');
          }
          return true;
        }
        
        // 説明が空で、かつタイトルが短い場合のみ除外
        if (description.isEmpty && titleLower.length <= 8) {
          if (kDebugMode) {
            print('終日イベント（説明なし・短タイトル）で除外: "$title"');
          }
          return true;
        }
      }
    }
    
    // タイトルが短く、日付が特定のパターンの場合は祝日の可能性が高い
    if (titleLower.length <= 8) {
      DateTime? eventDate;
      
      final start = event['start'];
      if (start != null) {
        if (start['dateTime'] != null) {
          eventDate = DateTime.parse(start['dateTime']).toLocal();
        } else if (start['date'] != null) {
          eventDate = DateTime.parse(start['date']);
        }
      }
      
      if (eventDate != null) {
        final month = eventDate.month;
        final day = eventDate.day;
        
        // 祝日になりやすい日付パターン
        final holidayDates = [
          [1, 1],   // 元日
          [1, 8],   // 成人の日（第2月曜日）
          [2, 11],  // 建国記念の日
          [2, 23],  // 天皇誕生日
          [3, 20],  // 春分の日
          [4, 29],  // 昭和の日
          [5, 3],   // 憲法記念日
          [5, 4],   // みどりの日
          [5, 5],   // こどもの日
          [7, 15],  // 海の日
          [8, 11],  // 山の日
          [9, 16],  // 敬老の日
          [9, 22],  // 秋分の日
          [10, 14], // スポーツの日
          [11, 3],  // 文化の日
          [11, 23], // 勤労感謝の日
        ];
        
        for (final holidayDate in holidayDates) {
          if (month == holidayDate[0] && day == holidayDate[1]) {
            return true;
          }
        }
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
  
  /// エラーメッセージを生成
  String _getErrorMessage(int statusCode, Map<String, dynamic> errorBody) {
    switch (statusCode) {
      case 400:
        final error = errorBody['error'];
        if (error != null) {
          final errors = error['errors'] as List?;
          if (errors != null && errors.isNotEmpty) {
            final firstError = errors[0] as Map<String, dynamic>;
            final reason = firstError['reason'] as String?;
            final message = firstError['message'] as String?;
            if (reason == 'required') {
              return '必須フィールドが不足しています: ${message ?? '詳細不明'}';
            }
            return 'リクエストが無効です: ${message ?? reason ?? '詳細不明'}';
          }
        }
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

  /// 重複イベントを検出・削除
  Future<Map<String, dynamic>> cleanupDuplicateEvents() async {
    try {
      if (!_isInitialized || _accessToken == null) {
        return {
          'success': false,
          'error': '認証されていません',
          'duplicatesFound': 0,
          'duplicatesRemoved': 0,
        };
      }

      print('=== 重複イベントクリーンアップ開始 ===');
      
      // 現在のイベントを取得
      final events = await getEvents(
        startTime: DateTime.now().subtract(const Duration(days: 365)),
        endTime: DateTime.now().add(const Duration(days: 365)),
        maxResults: 1000,
      );
      
      print('取得したイベント数: ${events.length}');
      
      // 重複を検出
      final duplicates = _findDuplicateEvents(events);
      print('重複イベント数: ${duplicates.length}');
      
      int removedCount = 0;
      List<String> errors = [];
      
      // 重複イベントを削除（古い方を削除）
      for (final duplicateGroup in duplicates) {
        if (duplicateGroup.length > 1) {
          // 作成日時でソート（古い順）
          duplicateGroup.sort((a, b) {
            final aCreated = DateTime.parse(a['created'] ?? a['updated'] ?? '1970-01-01');
            final bCreated = DateTime.parse(b['created'] ?? b['updated'] ?? '1970-01-01');
            return aCreated.compareTo(bCreated);
          });
          
          // 最初の1つ以外を削除
          for (int i = 1; i < duplicateGroup.length; i++) {
            try {
              final eventId = duplicateGroup[i]['id'];
              if (eventId != null) {
                await _deleteEvent(eventId);
                removedCount++;
                print('重複イベント削除: ${duplicateGroup[i]['summary']} (ID: $eventId)');
              }
            } catch (e) {
              errors.add('イベント削除エラー: $e');
              print('イベント削除エラー: $e');
            }
          }
        }
      }
      
      print('=== 重複イベントクリーンアップ完了 ===');
      print('削除されたイベント数: $removedCount');
      
      return {
        'success': true,
        'duplicatesFound': duplicates.length,
        'duplicatesRemoved': removedCount,
        'errors': errors,
      };
    } catch (e) {
      print('重複イベントクリーンアップエラー: $e');
      return {
        'success': false,
        'error': e.toString(),
        'duplicatesFound': 0,
        'duplicatesRemoved': 0,
      };
    }
  }

  /// 重複イベントを検出
  List<List<Map<String, dynamic>>> _findDuplicateEvents(List<Map<String, dynamic>> events) {
    final Map<String, List<Map<String, dynamic>>> eventGroups = {};
    
    for (final event in events) {
      final title = event['summary'] ?? '';
      final start = event['start'];
      DateTime? startTime;
      
      if (start != null) {
        if (start['dateTime'] != null) {
          startTime = DateTime.parse(start['dateTime']).toLocal();
        } else if (start['date'] != null) {
          startTime = DateTime.parse(start['date']);
        }
      }
      
      if (title.isNotEmpty && startTime != null) {
        // タイトルと日付の組み合わせでキーを作成
        final key = '${title}_${startTime.toIso8601String().split('T')[0]}';
        
        if (!eventGroups.containsKey(key)) {
          eventGroups[key] = [];
        }
        eventGroups[key]!.add(event);
      }
    }
    
    // 重複があるグループのみを返す
    return eventGroups.values.where((group) => group.length > 1).toList();
  }

  /// イベントを削除
  Future<void> _deleteEvent(String eventId) async {
    final response = await http.delete(
      Uri.parse('$_calendarApiUrl/calendars/primary/events/$eventId'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode != 204) {
      throw Exception('イベント削除に失敗しました: ${response.statusCode}');
    }
  }

  /// タスクIDでイベントを削除
  Future<SyncResult> deleteCalendarEventByTaskId(String taskId) async {
    try {
      if (!_isInitialized || _accessToken == null) {
        return SyncResult(
          success: false,
          errorMessage: 'Google Calendarが認証されていません。',
          errorCode: 'AUTH_REQUIRED',
        );
      }

      // アクセストークンの有効性を確認
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

      // タスクIDでイベントを検索
      final events = await getEvents(
        startTime: DateTime.now().subtract(const Duration(days: 365)),
        endTime: DateTime.now().add(const Duration(days: 365)),
        maxResults: 1000,
      );

      String? eventIdToDelete;
      for (final event in events) {
        final eventTaskId = event['extendedProperties']?['private']?['taskId'];
        if (eventTaskId == taskId) {
          eventIdToDelete = event['id'];
          break;
        }
      }

      if (eventIdToDelete == null) {
        return SyncResult(
          success: false,
          errorMessage: 'タスクIDに対応するイベントが見つかりませんでした。',
          errorCode: 'EVENT_NOT_FOUND',
        );
      }

      // イベントを削除
      await _deleteEvent(eventIdToDelete);
      
      return SyncResult(
        success: true,
        details: {'deletedEventId': eventIdToDelete},
      );
    } catch (e) {
      return SyncResult(
        success: false,
        errorMessage: 'イベント削除中にエラーが発生しました: ${e.toString()}',
        errorCode: 'DELETE_ERROR',
      );
    }
  }

  /// アプリで削除されたタスクのイベントを一括削除
  Future<Map<String, dynamic>> deleteOrphanedEvents(List<String> existingTaskIds) async {
    try {
      if (!_isInitialized || _accessToken == null) {
        return {
          'success': false,
          'error': '認証されていません',
          'deletedCount': 0,
        };
      }

      print('=== 孤立イベント削除開始 ===');
      print('既存タスクID数: ${existingTaskIds.length}');
      
      // 現在のイベントを取得
      final events = await getEvents(
        startTime: DateTime.now().subtract(const Duration(days: 365)),
        endTime: DateTime.now().add(const Duration(days: 365)),
        maxResults: 1000,
      );
      
      print('取得したイベント数: ${events.length}');
      
      int deletedCount = 0;
      List<String> errors = [];
      
      // アプリのタスクIDに対応しないイベントを削除
      for (final event in events) {
        final eventTaskId = event['extendedProperties']?['private']?['taskId'];
        if (eventTaskId != null && !existingTaskIds.contains(eventTaskId)) {
          try {
            final eventId = event['id'];
            if (eventId != null) {
              await _deleteEvent(eventId);
              deletedCount++;
              print('孤立イベント削除: ${event['summary']} (タスクID: $eventTaskId)');
            }
          } catch (e) {
            errors.add('イベント削除エラー: $e');
            print('イベント削除エラー: $e');
          }
        }
      }
      
      print('=== 孤立イベント削除完了 ===');
      print('削除されたイベント数: $deletedCount');
      
      return {
        'success': true,
        'deletedCount': deletedCount,
        'errors': errors,
      };
    } catch (e) {
      print('孤立イベント削除エラー: $e');
      return {
        'success': false,
        'error': e.toString(),
        'deletedCount': 0,
      };
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

      // より広範囲で既存イベントを検索（日付変更に対応）
      final existingEvents = await getEvents(
        startTime: startTime.subtract(const Duration(days: 30)), // 過去30日から
        endTime: startTime.add(const Duration(days: 30)), // 未来30日まで
        maxResults: 200,
      );
      
      // 1. まずタスクIDで既存イベントを検索
      Map<String, dynamic>? existingEvent;
      for (final event in existingEvents) {
        final taskId = event['extendedProperties']?['private']?['taskId'];
        if (taskId == task.id) {
          existingEvent = event;
          print('タスクIDで既存イベントを発見: ${event['summary']} (ID: $taskId)');
          break;
        }
      }
      
      // 2. タスクIDで見つからない場合は、タイトルのみで検索
      if (existingEvent == null) {
        for (final event in existingEvents) {
          final eventTitle = event['summary'] ?? '';
          if (eventTitle == task.title) {
            // 同じタイトルのイベントが見つかった場合
            existingEvent = event;
            print('タイトルで既存イベントを発見: $eventTitle');
            break;
          }
        }
      }
      
      // 3. 既存イベントが見つかった場合は更新
      if (existingEvent != null) {
        print('既存イベントを更新: ${existingEvent['summary']}');
        final success = await updateCalendarEvent(task, existingEvent['id']);
        
        if (success) {
          // タスクにGoogle CalendarイベントIDを設定
          await _updateTaskWithEventId(task, existingEvent['id']);
          return SyncResult(
            success: true,
            details: {'eventId': existingEvent['id'], 'action': 'updated'},
          );
        } else {
          return SyncResult(
            success: false,
            errorMessage: '既存イベントの更新に失敗しました: ${existingEvent['summary']}',
            errorCode: 'UPDATE_FAILED',
          );
        }
      }

      // 詳細説明を構築（複数の情報を含める）
      final description = _buildEnhancedDescription(task);
      
      // 参加者リストを構築
      final attendees = _buildAttendeesList(task);
      
      // 繰り返しルールを構築
      final recurrence = _buildRecurrenceRule(task);
      
      // 必須フィールドの検証
      if (task.title.trim().isEmpty) {
        ErrorHandler.logError('Google Calendar送信', 'タスクのタイトルが空です');
        return SyncResult(
          success: false,
          errorMessage: 'タスクのタイトルが空です。',
          errorCode: 'EMPTY_TITLE',
        );
      }

      // 日付の検証
      final startDateStr = startTime.toIso8601String().split('T')[0];
      final endDateStr = startTime.add(const Duration(days: 1)).toIso8601String().split('T')[0];
      
      print('日付検証: 開始日=$startDateStr, 終了日=$endDateStr');

      // 基本データ（成功確認済み）
      final eventData = {
        'summary': task.title.trim(),
        'start': {
          'date': startDateStr,
        },
        'end': {
          'date': endDateStr,
        },
      };
      
      // 説明文がある場合のみ追加
      if (description.isNotEmpty) {
        eventData['description'] = description;
      }
      
      // colorIdを追加（段階的復元）
      eventData['colorId'] = _getStatusColorId(task.status);
      
      // extendedPropertiesを段階的に追加（サブタスク関連フィールドを追加）
      final createExtendedProps = {
        'taskId': task.id,
        'status': task.status.toString(),
        'priority': task.priority.toString(),
        'hasSubTasks': task.hasSubTasks.toString(),
        'subTasksProgress': '${task.completedSubTasksCount}/${task.totalSubTasksCount}',
        'completedSubTasksCount': task.completedSubTasksCount.toString(),
        'totalSubTasksCount': task.totalSubTasksCount.toString(),
      };
      
      // サブタスクの詳細データを保存（実際のデータで判断）
      final subtaskDetails = _getSubTaskDetails(task.id);
      print('=== エクスポート時サブタスク詳細取得 ===');
      print('タスク: ${task.title}');
      print('hasSubTasks: ${task.hasSubTasks}');
      print('totalSubTasksCount: ${task.totalSubTasksCount}');
      print('取得されたサブタスク数: ${subtaskDetails.length}');
      
      if (subtaskDetails.isNotEmpty) {
        final subtasksJson = subtaskDetails.map((subtask) => {
          'id': subtask.id,
          'title': subtask.title,
          'description': subtask.description ?? '',
          'isCompleted': subtask.isCompleted,
          'order': subtask.order,
          'estimatedMinutes': subtask.estimatedMinutes,
        }).toList();
        createExtendedProps['subtasks'] = jsonEncode(subtasksJson);
        print('サブタスク詳細をextendedPropertiesに保存: ${subtasksJson.length}件');
        print('保存されたサブタスクJSON: ${jsonEncode(subtasksJson)}');
      } else {
        print('サブタスク詳細が空です');
      }
      print('=== エクスポート時サブタスク詳細取得完了 ===');
      
      eventData['extendedProperties'] = {
        'private': createExtendedProps
      };

      // 場所情報がある場合のみ追加（有効な場所情報のみ）
      if (task.assignedTo != null && task.assignedTo!.isNotEmpty) {
        if (_isValidLocation(task.assignedTo!)) {
          eventData['location'] = task.assignedTo!;
          print('場所情報を追加: ${task.assignedTo}');
        } else {
          print('場所情報をスキップ（無効）: ${task.assignedTo}');
        }
      }

      // 参加者リストがある場合のみ追加
      if (attendees.isNotEmpty) {
        eventData['attendees'] = attendees;
      }

      // 繰り返しルールがある場合は追加
      if (recurrence.isNotEmpty) {
        eventData['recurrence'] = recurrence;
      }

      // 送信前の最終検証
      print('=== 送信前検証 ===');
      final summary = eventData['summary']?.toString() ?? '';
      final startData = eventData['start'] as Map<String, dynamic>?;
      final endData = eventData['end'] as Map<String, dynamic>?;
      final startDate = startData?['date']?.toString() ?? '';
      final endDate = endData?['date']?.toString() ?? '';
      final extendedProps = eventData['extendedProperties'] as Map<String, dynamic>?;
      
      print('summary: "$summary" (長さ: ${summary.length})');
      print('start.date: $startDate');
      print('end.date: $endDate');
      print('colorId: ${eventData['colorId']}');
      print('description長さ: ${description.length}');
      print('extendedProperties長さ: ${jsonEncode(extendedProps).length}');
      print('extendedPropertiesサブタスク関連フィールド追加テスト実行中...');
      
      // 必須フィールドの最終チェック
      if (summary.trim().isEmpty) {
        print('❌ summaryが空です');
        return SyncResult(
          success: false,
          errorMessage: 'イベントのタイトルが空です。',
          errorCode: 'EMPTY_SUMMARY',
        );
      }
      
      if (startDate.isEmpty || endDate.isEmpty) {
        print('❌ 日付が空です');
        return SyncResult(
          success: false,
          errorMessage: 'イベントの日付が設定されていません。',
          errorCode: 'EMPTY_DATE',
        );
      }
      
      print('✅ extendedPropertiesサブタスク関連フィールド追加検証完了');

      // デバッグ用: 送信データをログ出力
      if (kDebugMode) {
        print('=== Google Calendar API送信データ ===');
        print('タスク: ${task.title}');
        print('依頼先: ${task.assignedTo}');
        print('参加者数: ${attendees.length}');
        print('参加者詳細: $attendees');
        print('説明文の長さ: ${description.length}文字');
        print('説明文プレビュー: ${description.length > 200 ? "${description.substring(0, 200)}..." : description}');
        print('送信データ: ${jsonEncode(eventData)}');
        print('===============================');
      }

      // Google Calendar APIに送信
      print('=== API送信詳細 ===');
      print('URL: $_calendarApiUrl/calendars/primary/events');
      print('Authorization: Bearer ${_accessToken?.substring(0, 20)}...');
      print('Content-Type: application/json');
      print('送信データサイズ: ${jsonEncode(eventData).length}文字');
      
      final response = await http.post(
        Uri.parse('$_calendarApiUrl/calendars/primary/events'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(eventData),
      );
      
      print('レスポンスステータス: ${response.statusCode}');
      print('レスポンスボディ: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Google Calendarイベント作成成功: ${responseData['id']}');
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

      // 詳細説明を構築（複数の情報を含める）
      final description = _buildEnhancedDescription(task);
      
      // 参加者リストを構築
      final attendees = _buildAttendeesList(task);
      
      // 繰り返しルールを構築
      final recurrence = _buildRecurrenceRule(task);
      
      // 最小限のデータでテスト（更新処理の問題を特定するため）
      final eventData = {
        'summary': task.title.trim(),
        'start': {
          'date': startTime.toIso8601String().split('T')[0],
        },
        'end': {
          'date': startTime.add(const Duration(days: 1)).toIso8601String().split('T')[0],
        },
      };
      
      // 説明文がある場合のみ追加
      if (description.isNotEmpty) {
        eventData['description'] = description;
      }
      
      // colorIdを復元（段階的テスト）
      eventData['colorId'] = _getStatusColorId(task.status);
      
      // extendedPropertiesを段階的に追加（サブタスク関連フィールドを追加）
      final updateExtendedProps = {
        'taskId': task.id,
        'status': task.status.toString(),
        'priority': task.priority.toString(),
        'hasSubTasks': task.hasSubTasks.toString(),
        'subTasksProgress': '${task.completedSubTasksCount}/${task.totalSubTasksCount}',
        'completedSubTasksCount': task.completedSubTasksCount.toString(),
        'totalSubTasksCount': task.totalSubTasksCount.toString(),
      };
      
      // サブタスクの詳細データを保存（実際のデータで判断）
      final subtaskDetails = _getSubTaskDetails(task.id);
      print('=== 更新時サブタスク詳細取得 ===');
      print('タスク: ${task.title}');
      print('hasSubTasks: ${task.hasSubTasks}');
      print('totalSubTasksCount: ${task.totalSubTasksCount}');
      print('取得されたサブタスク数: ${subtaskDetails.length}');
      
      if (subtaskDetails.isNotEmpty) {
        final subtasksJson = subtaskDetails.map((subtask) => {
          'id': subtask.id,
          'title': subtask.title,
          'description': subtask.description ?? '',
          'isCompleted': subtask.isCompleted,
          'order': subtask.order,
          'estimatedMinutes': subtask.estimatedMinutes,
        }).toList();
        updateExtendedProps['subtasks'] = jsonEncode(subtasksJson);
        print('サブタスク詳細をextendedPropertiesに保存（更新）: ${subtasksJson.length}件');
        print('保存されたサブタスクJSON: ${jsonEncode(subtasksJson)}');
      } else {
        print('サブタスク詳細が空です');
      }
      print('=== 更新時サブタスク詳細取得完了 ===');
      
      eventData['extendedProperties'] = {
        'private': updateExtendedProps
      };

      // 場所情報がある場合のみ追加（有効な場所情報のみ）
      if (task.assignedTo != null && task.assignedTo!.isNotEmpty) {
        if (_isValidLocation(task.assignedTo!)) {
          eventData['location'] = task.assignedTo!;
          print('場所情報を追加: ${task.assignedTo}');
        } else {
          print('場所情報をスキップ（無効）: ${task.assignedTo}');
        }
      }

      // 参加者リストがある場合のみ追加
      if (attendees.isNotEmpty) {
        eventData['attendees'] = attendees;
      }

      // 繰り返しルールがある場合は追加
      if (recurrence.isNotEmpty) {
        eventData['recurrence'] = recurrence;
      }

      // 送信前検証（完全復元テスト）
      print('=== 更新前検証 ===');
      final summary = eventData['summary']?.toString() ?? '';
      final startData = eventData['start'] as Map<String, dynamic>?;
      final endData = eventData['end'] as Map<String, dynamic>?;
      final startDate = startData?['date']?.toString() ?? '';
      final endDate = endData?['date']?.toString() ?? '';
      final extendedProps = eventData['extendedProperties'] as Map<String, dynamic>?;
      
      print('summary: "$summary" (長さ: ${summary.length})');
      print('start.date: $startDate');
      print('end.date: $endDate');
      print('colorId: ${eventData['colorId']}');
      print('description長さ: ${description.length}');
      print('extendedProperties長さ: ${jsonEncode(extendedProps).length}');
      print('extendedPropertiesサブタスク関連フィールド追加テスト実行中...');
      
      // 必須フィールドの最終チェック
      if (summary.trim().isEmpty) {
        print('❌ summaryが空です');
        return false;
      }
      
      if (startDate.isEmpty || endDate.isEmpty) {
        print('❌ 日付が設定されていません');
        return false;
      }
      
      print('✅ 更新処理extendedPropertiesサブタスク関連フィールド追加検証完了');

      // デバッグ用: 送信データをログ出力
      if (kDebugMode) {
        print('=== Google Calendar API更新データ ===');
        print('タスク: ${task.title}');
        print('イベントID: $eventId');
        print('依頼先: ${task.assignedTo}');
        print('参加者数: ${attendees.length}');
        print('参加者詳細: $attendees');
        print('送信データ: ${jsonEncode(eventData)}');
        print('===============================');
      }

      // API送信詳細ログ
      print('=== 更新API送信詳細 ===');
      print('URL: $_calendarApiUrl/calendars/primary/events/$eventId');
      print('Authorization: Bearer ${_accessToken?.substring(0, 20)}...');
      print('Content-Type: application/json');
      print('送信データサイズ: ${jsonEncode(eventData).length}文字');

      // Google Calendar APIに送信
      final response = await http.put(
        Uri.parse('$_calendarApiUrl/calendars/primary/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(eventData),
      );

      print('レスポンスステータス: ${response.statusCode}');
      print('レスポンスボディ: ${response.body}');

      if (response.statusCode == 200) {
        print('Google Calendarイベント更新成功: $eventId');
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = _getErrorMessage(response.statusCode, errorBody);
        ErrorHandler.logError('Google Calendar更新', 'HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      ErrorHandler.logError('Google Calendar更新', e);
      return false;
    }
  }

  /// 予定のGoogle Calendarイベントを作成
  Future<SyncResult> createCalendarEventFromSchedule(ScheduleItem schedule) async {
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

      // 既存イベントを検索（ScheduleIDで検索）
      final startTime = schedule.startDateTime;
      final existingEvents = await getEvents(
        startTime: startTime.subtract(const Duration(days: 30)),
        endTime: startTime.add(const Duration(days: 30)),
        maxResults: 200,
      );

      // ScheduleIDで既存イベントを検索
      Map<String, dynamic>? existingEvent;
      for (final event in existingEvents) {
        final scheduleId = event['extendedProperties']?['private']?['scheduleId'];
        if (scheduleId == schedule.id) {
          existingEvent = event;
          if (kDebugMode) {
            print('予定IDで既存イベントを発見: ${event['summary']} (ID: $scheduleId)');
          }
          break;
        }
      }

      // 既存イベントが見つかった場合は更新
      if (existingEvent != null) {
        if (kDebugMode) {
          print('既存イベントを更新: ${existingEvent['summary']}');
        }
        final success = await updateCalendarEventFromSchedule(schedule, existingEvent['id']);
        
        if (success) {
          return SyncResult(
            success: true,
            details: {'eventId': existingEvent['id'], 'action': 'updated'},
          );
        } else {
          return SyncResult(
            success: false,
            errorMessage: '既存イベントの更新に失敗しました: ${existingEvent['summary']}',
            errorCode: 'UPDATE_FAILED',
          );
        }
      }

      // イベントデータを構築
      final eventData = <String, dynamic>{
        'summary': schedule.title.trim(),
        'colorId': _scheduleEventColorId,
      };

      // 日時を設定（終日イベントではなく、日時指定）
      final startDateTime = schedule.startDateTime;
      final endDateTime = schedule.endDateTime ?? startDateTime.add(const Duration(hours: 1));

      eventData['start'] = {
        'dateTime': startDateTime.toUtc().toIso8601String(),
        'timeZone': 'Asia/Tokyo',
      };
      eventData['end'] = {
        'dateTime': endDateTime.toUtc().toIso8601String(),
        'timeZone': 'Asia/Tokyo',
      };

      // 説明文を構築
      final descriptionParts = <String>[];
      if (schedule.notes != null && schedule.notes!.isNotEmpty) {
        descriptionParts.add('メモ: ${schedule.notes}');
      }
      if (descriptionParts.isNotEmpty) {
        eventData['description'] = descriptionParts.join('\n');
      }

      // extendedPropertiesにScheduleIDを保存
      eventData['extendedProperties'] = {
        'private': {
          'scheduleId': schedule.id,
          'taskId': schedule.taskId,
        }
      };

      // 場所情報がある場合のみ追加
      if (schedule.location != null && schedule.location!.isNotEmpty) {
        eventData['location'] = schedule.location;
      }

      // デバッグ用: 送信データをログ出力
      if (kDebugMode) {
        print('=== Google Calendar API送信データ（予定） ===');
        print('予定: ${schedule.title}');
        print('開始: ${startDateTime}');
        print('終了: ${endDateTime}');
        print('場所: ${schedule.location}');
        print('送信データ: ${jsonEncode(eventData)}');
        print('===============================');
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

      if (kDebugMode) {
        print('レスポンスステータス: ${response.statusCode}');
        print('レスポンスボディ: ${response.body}');
      }

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

  /// 予定のGoogle Calendarイベントを更新
  Future<bool> updateCalendarEventFromSchedule(ScheduleItem schedule, String eventId) async {
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

      // イベントデータを構築
      final eventData = <String, dynamic>{
        'summary': schedule.title.trim(),
        'colorId': _scheduleEventColorId,
      };

      // 日時を設定
      final startDateTime = schedule.startDateTime;
      final endDateTime = schedule.endDateTime ?? startDateTime.add(const Duration(hours: 1));

      eventData['start'] = {
        'dateTime': startDateTime.toUtc().toIso8601String(),
        'timeZone': 'Asia/Tokyo',
      };
      eventData['end'] = {
        'dateTime': endDateTime.toUtc().toIso8601String(),
        'timeZone': 'Asia/Tokyo',
      };

      // 説明文を構築
      final descriptionParts = <String>[];
      if (schedule.notes != null && schedule.notes!.isNotEmpty) {
        descriptionParts.add('メモ: ${schedule.notes}');
      }
      if (descriptionParts.isNotEmpty) {
        eventData['description'] = descriptionParts.join('\n');
      }

      // extendedPropertiesにScheduleIDを保存
      eventData['extendedProperties'] = {
        'private': {
          'scheduleId': schedule.id,
          'taskId': schedule.taskId,
        }
      };

      // 場所情報がある場合のみ追加
      if (schedule.location != null && schedule.location!.isNotEmpty) {
        eventData['location'] = schedule.location;
      }

      // デバッグ用: 送信データをログ出力
      if (kDebugMode) {
        print('=== Google Calendar API更新データ（予定） ===');
        print('予定: ${schedule.title}');
        print('イベントID: $eventId');
        print('開始: ${startDateTime}');
        print('終了: ${endDateTime}');
        print('場所: ${schedule.location}');
        print('送信データ: ${jsonEncode(eventData)}');
        print('===============================');
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

      if (kDebugMode) {
        print('レスポンスステータス: ${response.statusCode}');
        print('レスポンスボディ: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Google Calendarイベント更新成功: $eventId');
        }
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = _getErrorMessage(response.statusCode, errorBody);
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

  /// 認証状態を確認
  bool get isAuthenticated {
    return _isInitialized && _accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!);
  }

  /// タスクステータスに応じたGoogle Calendar色IDを取得
  String _getStatusColorId(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '10'; // バジル（緑）- 未着手（目に留まりやすく）
      case TaskStatus.inProgress:
        return '7'; // ピーコック（青）- 進行中（画像のような鮮やかな青い色）
      case TaskStatus.completed:
        return '8'; // グラファイト（グレー）- 完了済み（目立たない）
      case TaskStatus.cancelled:
        return '11'; // トマト（赤）- キャンセル
    }
  }

  /// タスクにGoogle CalendarイベントIDを設定
  Future<void> _updateTaskWithEventId(TaskItem task, String eventId) async {
    try {
      // TaskViewModelを通じてタスクを更新
      final updatedTask = task.copyWith(googleCalendarEventId: eventId);
      
      // TaskViewModelのインスタンスを取得して更新
      // 注意: この方法は直接的な参照が必要ですが、依存関係を避けるため
      // タスクの更新は呼び出し元で行うことを前提とします
      if (kDebugMode) {
        print('タスクにGoogle CalendarイベントIDを設定: ${task.title} -> $eventId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスクイベントID設定エラー: $e');
      }
    }
  }

  /// 説明文からサブタスク関連の情報を削除
  String _removeSubtaskInfoFromDescription(String description) {
    final lines = description.split('\n');
    final cleanedLines = <String>[];
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // サブタスク関連の行をスキップ
      if (trimmedLine.startsWith('📋 サブタスク進捗:') ||
          trimmedLine.startsWith('📝 サブタスク詳細:') ||
          trimmedLine.startsWith('  ✖') ||
          trimmedLine.startsWith('  ✅') ||
          trimmedLine.startsWith('✖') ||
          trimmedLine.startsWith('✅') ||
          trimmedLine.startsWith('⭐ 優先度:') ||
          trimmedLine.startsWith('📊 ステータス:') ||
          trimmedLine.startsWith('📅 作成日:') ||
          trimmedLine.startsWith('📝 メモ:')) {
        continue;
      }
      
      // 空行でない場合は追加
      if (trimmedLine.isNotEmpty) {
        cleanedLines.add(line);
      }
    }
    
    return cleanedLines.join('\n').trim();
  }

  /// 拡張された詳細説明を構築
  String _buildEnhancedDescription(TaskItem task) {
    final parts = <String>[];
    
    // 基本説明（重複チェック）
    if (task.description != null && task.description!.isNotEmpty) {
      final cleanDescription = task.description!.trim();
      if (cleanDescription.isNotEmpty) {
        // 既存の説明文からサブタスク関連の情報を削除
        final cleanedDescription = _removeSubtaskInfoFromDescription(cleanDescription);
        print('=== 説明文クリーンアップ ===');
        print('元の説明文: $cleanDescription');
        print('クリーンアップ後: $cleanedDescription');
        print('=== 説明文クリーンアップ完了 ===');
        
        if (cleanedDescription.isNotEmpty && !parts.contains(cleanedDescription)) {
          parts.add(cleanedDescription);
        }
      }
    }
    
    // 追加メモ（重複チェック）
    if (task.notes != null && task.notes!.isNotEmpty) {
      final memoText = '📝 メモ: ${task.notes!}';
      if (!parts.any((part) => part.contains('📝 メモ:'))) {
        parts.add(memoText);
      }
    }
    
    // タグ情報（重複チェック）
    if (task.tags.isNotEmpty) {
      final tagText = '🏷️ タグ: ${task.tags.join(', ')}';
      if (!parts.any((part) => part.contains('🏷️ タグ:'))) {
        parts.add(tagText);
      }
    }
    
    // 推定時間（重複チェック）
    if (task.estimatedMinutes != null && task.estimatedMinutes! > 0) {
      final hours = task.estimatedMinutes! ~/ 60;
      final minutes = task.estimatedMinutes! % 60;
      final timeText = hours > 0 
          ? '⏱️ 推定時間: $hours時間${minutes > 0 ? '$minutes分' : ''}'
          : '⏱️ 推定時間: $minutes分';
      
      if (!parts.any((part) => part.contains('⏱️ 推定時間:'))) {
        parts.add(timeText);
      }
    }
    
    // サブタスク詳細情報（重複チェック）
    print('=== サブタスク詳細情報構築開始 ===');
    print('task.hasSubTasks: ${task.hasSubTasks}');
    print('task.totalSubTasksCount: ${task.totalSubTasksCount}');
    print('task.completedSubTasksCount: ${task.completedSubTasksCount}');
    
    // サブタスクの詳細を取得して表示（実際のデータで判断）
    final subtaskDetails = _getSubTaskDetails(task.id);
    print('=== サブタスク詳細構築 ===');
    print('取得されたサブタスク数: ${subtaskDetails.length}');
    for (final subtask in subtaskDetails) {
      print('サブタスク: ${subtask.title} (完了: ${subtask.isCompleted})');
    }
    
    if (subtaskDetails.isNotEmpty) {
      // サブタスク進捗を計算（実際のデータから）
      final completedCount = subtaskDetails.where((s) => s.isCompleted).length;
      final totalCount = subtaskDetails.length;
      final subtaskProgressText = '📋 サブタスク進捗: $completedCount/$totalCount 完了';
      print('サブタスク進捗テキスト: $subtaskProgressText');
      
      // 古いサブタスク進捗を削除
      parts.removeWhere((part) => part.contains('📋 サブタスク進捗:'));
      print('古いサブタスク進捗を削除しました');
      
      // 新しいサブタスク進捗を追加
      parts.add(subtaskProgressText);
      print('新しいサブタスク進捗を追加しました');
      
      // 古いサブタスク詳細を削除
      parts.removeWhere((part) => part.contains('📝 サブタスク詳細:'));
      parts.removeWhere((part) => part.startsWith('  ✖') || part.startsWith('  ✅'));
      print('古いサブタスク詳細を削除しました');
      
      // 新しいサブタスク詳細を追加
      parts.add('');
      parts.add('📝 サブタスク詳細:');
      for (final subtask in subtaskDetails) {
        final statusIcon = subtask.isCompleted ? '✅' : '✖';
        parts.add('  $statusIcon ${subtask.title}');
        if (subtask.description != null && subtask.description!.isNotEmpty) {
          parts.add('     ${subtask.description!}');
        }
        if (subtask.estimatedMinutes != null && subtask.estimatedMinutes! > 0) {
          parts.add('     ⏱️ 推定時間: ${subtask.estimatedMinutes}分');
        }
      }
      print('新しいサブタスク詳細を追加しました');
    } else {
      print('サブタスクが存在しません');
    }
    print('=== サブタスク詳細構築完了 ===');
    print('=== サブタスク詳細情報構築完了 ===');
    
    // 優先度情報（古いものを削除してから新しいものを追加）
    final priorityText = _getPriorityText(task.priority);
    final priorityLine = '⭐ 優先度: $priorityText';
    parts.removeWhere((part) => part.contains('⭐ 優先度:'));
    parts.add(priorityLine);
    print('優先度を更新しました: $priorityText');
    
    // ステータス情報（古いものを削除してから新しいものを追加）
    final statusText = _getStatusText(task.status);
    final statusLine = '📊 ステータス: $statusText';
    parts.removeWhere((part) => part.contains('📊 ステータス:'));
    parts.add(statusLine);
    print('ステータスを更新しました: $statusText');
    
    // 作成日時（古いものを削除してから新しいものを追加）
    final createdAtLine = '📅 作成日: ${task.createdAt.toIso8601String().split('T')[0]}';
    parts.removeWhere((part) => part.contains('📅 作成日:'));
    parts.add(createdAtLine);
    print('作成日を更新しました: ${task.createdAt.toIso8601String().split('T')[0]}');
    
    final fullDescription = parts.join('\n');
    print('=== 最終説明文構築結果 ===');
    print('構築された説明文: $fullDescription');
    print('=== 最終説明文構築結果完了 ===');
    
    // Google Calendar APIの説明文の長さ制限（約8000文字）を考慮
    if (fullDescription.length > 8000) {
      // 重要な情報のみ残す
      final essentialParts = <String>[];
      
      // 基本説明
      if (task.description != null && task.description!.isNotEmpty) {
        final cleanDescription = task.description!.trim();
        if (cleanDescription.isNotEmpty && !essentialParts.contains(cleanDescription)) {
          essentialParts.add(cleanDescription);
        }
      }
      
      // 追加メモ（短縮）
      if (task.notes != null && task.notes!.isNotEmpty) {
        final shortNotes = task.notes!.length > 100 
            ? '${task.notes!.substring(0, 100)}...' 
            : task.notes!;
        final memoText = '📝 メモ: $shortNotes';
        if (!essentialParts.any((part) => part.contains('📝 メモ:'))) {
          essentialParts.add(memoText);
        }
      }
      
      // 推定時間
      if (task.estimatedMinutes != null && task.estimatedMinutes! > 0) {
        final hours = task.estimatedMinutes! ~/ 60;
        final minutes = task.estimatedMinutes! % 60;
        final timeText = hours > 0 
            ? '⏱️ 推定時間: $hours時間${minutes > 0 ? '$minutes分' : ''}'
            : '⏱️ 推定時間: $minutes分';
        if (!essentialParts.any((part) => part.contains('⏱️ 推定時間:'))) {
          essentialParts.add(timeText);
        }
      }
      
      // サブタスク情報（短縮版）
      // サブタスクの詳細を取得して表示（実際のデータで判断）
      final subtaskDetails = _getSubTaskDetails(task.id);
      if (subtaskDetails.isNotEmpty) {
        final completedCount = subtaskDetails.where((s) => s.isCompleted).length;
        final totalCount = subtaskDetails.length;
        final subtaskProgressText = '📋 サブタスク: $completedCount/$totalCount 完了';
        if (!essentialParts.any((part) => part.contains('📋 サブタスク:'))) {
          essentialParts.add(subtaskProgressText);
          
          // 最初の3つのサブタスクのみ表示
          essentialParts.add('');
          essentialParts.add('📝 サブタスク詳細:');
          final maxSubTasks = subtaskDetails.length > 3 ? 3 : subtaskDetails.length;
          for (int i = 0; i < maxSubTasks; i++) {
            final subtask = subtaskDetails[i];
            final statusIcon = subtask.isCompleted ? '✅' : '✖';
            essentialParts.add('  $statusIcon ${subtask.title}');
          }
          if (subtaskDetails.length > 3) {
            essentialParts.add('  ...他${subtaskDetails.length - 3}件');
          }
        }
      }
      
      // 優先度とステータス
      final priorityText = '⭐ 優先度: ${_getPriorityText(task.priority)}';
      final statusText = '📊 ステータス: ${_getStatusText(task.status)}';
      
      if (!essentialParts.any((part) => part.contains('⭐ 優先度:'))) {
        essentialParts.add(priorityText);
      }
      if (!essentialParts.any((part) => part.contains('📊 ステータス:'))) {
        essentialParts.add(statusText);
      }
      
      return essentialParts.join('\n');
    }
    
    return fullDescription;
  }
  
  /// タスクのサブタスク詳細を取得
  List<SubTask> _getSubTaskDetails(String taskId) {
    try {
      // 簡易実装: Hiveボックスから直接取得
      final subTaskBox = Hive.box<SubTask>('sub_tasks');
      final subTasks = subTaskBox.values
          .where((subtask) => subtask.parentTaskId == taskId)
          .toList();
      
      // 並び順でソート
      subTasks.sort((a, b) => a.order.compareTo(b.order));
      
      return subTasks;
    } catch (e) {
      if (kDebugMode) {
        print('サブタスク詳細取得エラー: $e');
      }
      return [];
    }
  }

  /// サブタスクを復元（Google Calendarからインポート時）
  void _restoreSubTasks(String parentTaskId, List<dynamic> subtasksJson) {
    try {
      final subTaskBox = Hive.box<SubTask>('sub_tasks');
      
      for (final subtaskData in subtasksJson) {
        final subtask = SubTask(
          id: subtaskData['id'] ?? const Uuid().v4(),
          parentTaskId: parentTaskId,
          title: subtaskData['title'] ?? '',
          description: subtaskData['description']?.isNotEmpty == true ? subtaskData['description'] : null,
          isCompleted: subtaskData['isCompleted'] ?? false,
          order: subtaskData['order'] ?? 0,
          createdAt: DateTime.now(),
        );
        
        subTaskBox.put(subtask.id, subtask);
        print('サブタスク復元: ${subtask.title} (完了: ${subtask.isCompleted})');
      }
      
      subTaskBox.flush();
      print('サブタスク復元完了: ${subtasksJson.length}件');
    } catch (e) {
      print('サブタスク復元エラー: $e');
    }
  }

  /// 参加者リストを構築
  List<Map<String, dynamic>> _buildAttendeesList(TaskItem task) {
    final attendees = <Map<String, dynamic>>[];
    
    // 依頼先が設定されている場合、参加者として追加
    if (task.assignedTo != null && task.assignedTo!.isNotEmpty) {
      // 有効なメールアドレスかどうかをチェック
      if (_isValidEmail(task.assignedTo!)) {
        // メールアドレスが有効な場合のみ参加者として追加
        attendees.add({
          'email': task.assignedTo!,
          'displayName': task.assignedTo!.split('@')[0], // メールアドレスの@より前を表示名として使用
          'responseStatus': 'needsAction',
        });
      }
      // メールアドレスが無効な場合は参加者として追加しない
      // （Google Calendar APIではemailフィールドが必須のため）
    }
    
    return attendees;
  }

  /// 有効なメールアドレスかどうかをチェック
  bool _isValidEmail(String email) {
    // 基本的なメールアドレス形式のチェック
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// 有効な場所情報かどうかをチェック
  bool _isValidLocation(String location) {
    // 場所情報として有効な文字列かどうかをチェック
    // 基本的な文字列の長さと内容をチェック
    if (location.length < 2 || location.length > 200) {
      return false;
    }
    
    // 単純な文字列や疑問符を含む文字列は場所情報として不適切
    final invalidLocations = [
      'test', 'テスト', 'sample', 'サンプル', 'example', '例',
      'なんで？', 'なぜ？', 'どうして？', 'what', 'why', 'how',
      'どこ？', 'when', 'where', 'who'
    ];
    if (invalidLocations.contains(location.toLowerCase())) {
      return false;
    }
    
    // 疑問符のみまたは疑問符で終わる短い文字列は不適切
    if (location.endsWith('？') || location.endsWith('?')) {
      if (location.length <= 10) {
        return false;
      }
    }
    
    // メールアドレス形式は場所情報として不適切
    if (_isValidEmail(location)) {
      return false;
    }
    
    // 数字のみの文字列は不適切
    if (RegExp(r'^\d+$').hasMatch(location)) {
      return false;
    }
    
    return true;
  }

  /// 繰り返しルールを構築
  List<String> _buildRecurrenceRule(TaskItem task) {
    if (!task.isRecurring || task.recurringPattern == null) {
      return [];
    }
    
    final rules = <String>[];
    
    switch (task.recurringPattern) {
      case 'daily':
        rules.add('RRULE:FREQ=DAILY');
        break;
      case 'weekly':
        rules.add('RRULE:FREQ=WEEKLY');
        break;
      case 'monthly':
        rules.add('RRULE:FREQ=MONTHLY');
        break;
      case 'yearly':
        rules.add('RRULE:FREQ=YEARLY');
        break;
      default:
        // その他のパターンは無視
        break;
    }
    
    return rules;
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

  /// 完了タスクの表示/非表示を制御
  Future<bool> updateCompletedTaskVisibility(String eventId, bool showCompleted) async {
    try {
      if (!_isInitialized || _accessToken == null) {
        return false;
      }

      // イベントの詳細を取得
      final response = await http.get(
        Uri.parse('$_calendarApiUrl/calendars/primary/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode != 200) {
        return false;
      }

      final eventData = json.decode(response.body);
      
      // 表示/非表示を制御
      if (showCompleted) {
        // 完了タスクを表示（透明度を100%に戻す）
        eventData['transparency'] = 'opaque';
      } else {
        // 完了タスクを非表示（透明度を50%に設定）
        eventData['transparency'] = 'transparent';
      }

      // イベントを更新
      final updateResponse = await http.put(
        Uri.parse('$_calendarApiUrl/calendars/primary/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(eventData),
      );

      return updateResponse.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('完了タスク表示制御エラー: $e');
      }
      return false;
    }
  }

  /// アプリ側を優先したGoogle Calendar同期（Google Calendarにのみ存在するイベントをアプリに同期）
  Future<Map<String, dynamic>> syncFromGoogleCalendarToApp(List<TaskItem> existingAppTasks) async {
    if (!_isInitialized || _accessToken == null) {
      return {
        'success': false,
        'error': '認証されていません',
        'added': 0,
        'skipped': 0,
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
            'added': 0,
            'skipped': 0,
          };
        }
      }

      print('=== Google Calendar → アプリ同期開始 ===');
      
      // 1. Google Calendarの全イベントを取得
      final allEvents = await _getAllCalendarEvents();
      print('Google Calendarイベント数: ${allEvents.length}');
      
      // 2. アプリの既存タスクIDセットを作成
      final appTaskIds = existingAppTasks.map((task) => task.id).toSet();
      print('アプリの既存タスク数: ${appTaskIds.length}');
      
      int added = 0;
      int skipped = 0;
      
      // 3. Google Calendarのイベントをチェック
      for (final event in allEvents) {
        final eventTaskId = event['extendedProperties']?['private']?['taskId'];
        
        // アプリから作成されたイベントはスキップ
        if (eventTaskId != null && appTaskIds.contains(eventTaskId)) {
          skipped++;
          continue;
        }
        
        // 祝日イベントをスキップ
        final summary = event['summary'] ?? '';
        if (_isHolidayEvent(summary, event['description'] ?? '', event)) {
          skipped++;
          continue;
        }
        
        // Google Calendarにのみ存在するイベントをアプリに追加
        print('=== イベント変換開始 ===');
        print('イベントID: ${event['id']}');
        print('イベントタイトル: ${event['summary']}');
        print('extendedProperties: ${event['extendedProperties']}');
        
        final task = _convertEventToTask(event);
        if (task != null) {
          // UUIDベースの重複チェック（厳密）
          final isDuplicate = existingAppTasks.any((existingTask) => 
            existingTask.id == task.id);
          
          if (!isDuplicate) {
            added++;
            print('Google Calendar → アプリ同期対象: ${task.title} (UUID: ${task.id})');
          } else {
            skipped++;
            print('UUID重複のためスキップ: ${task.title} (UUID: ${task.id})');
          }
        }
      }
      
      print('=== Google Calendar → アプリ同期完了 ===');
      print('追加: $added, スキップ: $skipped');
      
      return {
        'success': true,
        'added': added,
        'skipped': skipped,
      };
    } catch (e) {
      ErrorHandler.logError('Google Calendar → アプリ同期', e);
      return {
        'success': false,
        'error': e.toString(),
        'added': 0,
        'skipped': 0,
      };
    }
  }

  /// イベントをタスクに変換（詳細情報を含む）
  TaskItem? _convertEventToTask(Map<String, dynamic> event) {
    try {
      print('=== _convertEventToTask開始 ===');
      final summary = event['summary'] ?? '';
      final description = event['description'] ?? '';
      final start = event['start'];
      
      print('summary: "$summary"');
      print('description: "$description"');
      print('start: $start');
      
      if (summary.isEmpty) {
        print('summaryが空のためnullを返す');
        return null;
      }
      
      DateTime? dueDate;
      DateTime? reminderTime;
      
      if (start != null) {
        if (start['dateTime'] != null) {
          // 時刻指定イベント
          final dateTime = DateTime.parse(start['dateTime']).toLocal();
          reminderTime = dateTime;
          dueDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
        } else if (start['date'] != null) {
          // 終日イベント
          dueDate = DateTime.parse(start['date']);
        }
      }
      
      // 拡張プロパティから詳細情報を取得
      final extendedProps = event['extendedProperties']?['private'] ?? {};
      
      // デバッグ: 拡張プロパティの内容を出力
      print('=== Google Calendarイベント変換デバッグ ===');
      print('イベントタイトル: $summary');
      print('拡張プロパティ: $extendedProps');
      print('extendedProperties全体: ${event['extendedProperties']}');
      
      // ステータス（拡張プロパティから直接取得、なければ色IDから推定）
      TaskStatus status;
      final statusStr = extendedProps['status'] ?? '';
      if (statusStr.isNotEmpty) {
        status = _parseStatus(statusStr);
      } else {
        // フォールバック：色IDから推定
        final colorId = event['colorId'] ?? '1';
        status = _getStatusFromColorId(colorId);
      }
      
      // 見積もり時間
      final estimatedMinutesStr = extendedProps['estimatedMinutes'] ?? '';
      int? estimatedMinutes = estimatedMinutesStr.isNotEmpty ? int.tryParse(estimatedMinutesStr) : null;
      
      // 優先度
      final priorityStr = extendedProps['priority'] ?? '';
      TaskPriority priority = _parsePriority(priorityStr);
      
      // タグ（List<dynamic>型とString型の両方に対応）
      List<String> tags = [];
      final tagsData = extendedProps['tags'];
      if (tagsData != null) {
        if (tagsData is List) {
          // List<dynamic>型の場合
          tags = tagsData.map((tag) => tag.toString().trim()).where((tag) => tag.isNotEmpty).toList();
        } else if (tagsData is String) {
          // String型の場合
          final tagsStr = tagsData.trim();
          if (tagsStr.isNotEmpty) {
            tags = tagsStr.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
          }
        }
      }
      
      // サブタスク情報（拡張プロパティから直接取得）
      bool hasSubTasks = false;
      int completedSubTasksCount = 0;
      int totalSubTasksCount = 0;
      
      // 新しい形式のサブタスク情報を取得
      final hasSubTasksStr = extendedProps['hasSubTasks'] ?? '';
      final completedSubTasksStr = extendedProps['completedSubTasksCount'] ?? '';
      final totalSubTasksStr = extendedProps['totalSubTasksCount'] ?? '';
      
      print('サブタスク情報取得:');
      print('  hasSubTasksStr: "$hasSubTasksStr"');
      print('  completedSubTasksStr: "$completedSubTasksStr"');
      print('  totalSubTasksStr: "$totalSubTasksStr"');
      
      if (hasSubTasksStr.isNotEmpty) {
        hasSubTasks = hasSubTasksStr.toLowerCase() == 'true';
        completedSubTasksCount = int.tryParse(completedSubTasksStr) ?? 0;
        totalSubTasksCount = int.tryParse(totalSubTasksStr) ?? 0;
        print('新形式サブタスク情報: hasSubTasks=$hasSubTasks, 完了=$completedSubTasksCount, 総数=$totalSubTasksCount');
      } else {
        // 旧形式のサブタスク情報を取得
        final subtasksStr = extendedProps['subtasks'] ?? '';
        print('旧形式サブタスク情報: "$subtasksStr"');
        if (subtasksStr.isNotEmpty) {
          try {
            final List<dynamic> subtasksJson = json.decode(subtasksStr);
            totalSubTasksCount = subtasksJson.length;
            completedSubTasksCount = subtasksJson.where((subtask) => subtask['isCompleted'] == true).length;
            hasSubTasks = totalSubTasksCount > 0;
            print('旧形式サブタスク解析成功: hasSubTasks=$hasSubTasks, 完了=$completedSubTasksCount, 総数=$totalSubTasksCount');
          } catch (e) {
            // JSON解析に失敗した場合はデフォルト値を使用
            hasSubTasks = false;
            completedSubTasksCount = 0;
            totalSubTasksCount = 0;
            print('旧形式サブタスク解析失敗: $e');
          }
        } else {
          print('サブタスク情報なし');
        }
      }
      
      // 元のタスクIDを復元（UUIDベースのマッチングのため）
      final originalTaskId = extendedProps['taskId'] ?? const Uuid().v4();
      
      // サブタスクの詳細データを復元
      if (hasSubTasks && totalSubTasksCount > 0) {
        final subtasksStr = extendedProps['subtasks'] ?? '';
        if (subtasksStr.isNotEmpty) {
          try {
            final List<dynamic> subtasksJson = json.decode(subtasksStr);
            print('サブタスク詳細を復元: ${subtasksJson.length}件');
            // サブタスクをHiveに保存
            _restoreSubTasks(originalTaskId, subtasksJson);
          } catch (e) {
            print('サブタスク詳細復元エラー: $e');
          }
        }
      }
      
      // メモ（拡張プロパティまたは説明から取得）
      String notes = extendedProps['notes'] ?? '';
      
      // 説明フィールドからもメモ情報を抽出
      if (notes.isEmpty && description.isNotEmpty) {
        // 説明にメモ情報が含まれている場合
        final lines = description.split('\n');
        final memoLines = <String>[];
        
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.startsWith('メモ:') || 
              trimmedLine.startsWith('Memo:') ||
              trimmedLine.startsWith('Notes:') ||
              trimmedLine.startsWith('備考:')) {
            memoLines.add(trimmedLine.substring(trimmedLine.indexOf(':') + 1).trim());
          } else if (trimmedLine.startsWith('- ') || 
                     trimmedLine.startsWith('• ') ||
                     trimmedLine.startsWith('・')) {
            // 箇条書きの場合はメモとして扱う
            memoLines.add(trimmedLine.substring(2).trim());
          }
        }
        
        if (memoLines.isNotEmpty) {
          notes = memoLines.join('\n');
        } else {
          // 説明が短い場合はメモとして扱う
          notes = description;
        }
      }
      
      // 説明フィールドからサブタスク情報を抽出（拡張プロパティにない場合）
      if (!hasSubTasks && description.isNotEmpty) {
        final lines = description.split('\n');
        int subtaskCount = 0;
        int completedCount = 0;
        
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.contains('[x]') || trimmedLine.contains('[✓]') || trimmedLine.contains('✅')) {
            // 完了したサブタスク
            subtaskCount++;
            completedCount++;
          } else if (trimmedLine.contains('[]') || trimmedLine.contains('[ ]') || 
                     trimmedLine.startsWith('- ') || trimmedLine.startsWith('• ') || 
                     trimmedLine.startsWith('・')) {
            // 未完了のサブタスク
            subtaskCount++;
          }
        }
        
        if (subtaskCount > 0) {
          hasSubTasks = true;
          totalSubTasksCount = subtaskCount;
          completedSubTasksCount = completedCount;
        }
      }
      
      // 説明フィールドから優先度を抽出（拡張プロパティにない場合）
      if (priority == TaskPriority.medium && description.isNotEmpty) {
        final descLower = description.toLowerCase();
        if (descLower.contains('緊急') || descLower.contains('urgent')) {
          priority = TaskPriority.urgent;
        } else if (descLower.contains('高') || descLower.contains('high')) {
          priority = TaskPriority.high;
        } else if (descLower.contains('低') || descLower.contains('low')) {
          priority = TaskPriority.low;
        }
      }
      
      // 説明フィールドから見積もり時間を抽出（拡張プロパティにない場合）
      if (estimatedMinutes == null && description.isNotEmpty) {
        final timeMatch = RegExp(r'(\d+)\s*分|(\d+)\s*min|(\d+)\s*時間|(\d+)\s*hour').firstMatch(description);
        if (timeMatch != null) {
          final minutes = int.tryParse(timeMatch.group(1) ?? timeMatch.group(2) ?? '');
          final hours = int.tryParse(timeMatch.group(3) ?? timeMatch.group(4) ?? '');
          if (minutes != null) {
            estimatedMinutes = minutes;
          } else if (hours != null) {
            estimatedMinutes = hours * 60;
          }
        }
      }
      
      // 場所情報を依頼先として設定
      final location = event['location'] ?? '';
      final assignedTo = location.isNotEmpty ? location : null;
      
      // 参加者情報を取得
      final attendees = event['attendees'] as List? ?? [];
      String? attendeeEmail;
      if (attendees.isNotEmpty) {
        final firstAttendee = attendees[0] as Map<String, dynamic>?;
        attendeeEmail = firstAttendee?['email'] ?? assignedTo;
      }
      
      // 繰り返し情報を取得
      final recurrence = event['recurrence'] as List? ?? [];
      bool isRecurring = recurrence.isNotEmpty;
      String? recurringPattern;
      if (isRecurring) {
        final rrule = recurrence[0] as String? ?? '';
        if (rrule.contains('FREQ=DAILY')) {
          recurringPattern = 'daily';
        } else if (rrule.contains('FREQ=WEEKLY')) {
          recurringPattern = 'weekly';
        } else if (rrule.contains('FREQ=MONTHLY')) {
          recurringPattern = 'monthly';
        } else if (rrule.contains('FREQ=YEARLY')) {
          recurringPattern = 'yearly';
        }
      }
      
      // 作成日時を取得（可能であれば）
      DateTime? createdAt;
      if (event['created'] != null) {
        try {
          createdAt = DateTime.parse(event['created']).toLocal();
        } catch (e) {
          createdAt = DateTime.now();
        }
      } else {
        createdAt = DateTime.now();
      }
      
      final task = TaskItem(
        id: originalTaskId,
        title: summary,
        description: description.isNotEmpty ? description : null,
        notes: notes.isNotEmpty ? notes : null,
        dueDate: dueDate,
        reminderTime: reminderTime,
        priority: priority,
        status: status,
        tags: tags,
        createdAt: createdAt,
        estimatedMinutes: estimatedMinutes,
        assignedTo: attendeeEmail ?? assignedTo,
        isRecurring: isRecurring,
        recurringPattern: recurringPattern,
        source: 'google_calendar',
        externalId: event['id'],
        hasSubTasks: hasSubTasks,
        completedSubTasksCount: completedSubTasksCount,
        totalSubTasksCount: totalSubTasksCount,
      );
      
      // デバッグ情報を出力
      if (kDebugMode) {
        print('=== タスク変換完了 ===');
        print('タイトル: ${task.title}');
        print('UUID復元: $originalTaskId (元のID: ${extendedProps['taskId']})');
        print('優先度: ${task.priority}');
        print('ステータス: ${task.status}');
        print('タグ: ${task.tags}');
        print('サブタスク: ${task.totalSubTasksCount}/${task.completedSubTasksCount}');
        print('サブタスク詳細: hasSubTasks=${task.hasSubTasks}, 完了=${task.completedSubTasksCount}, 総数=${task.totalSubTasksCount}');
        print('見積もり時間: ${task.estimatedMinutes}分');
        print('メモ: ${task.notes}');
        print('依頼先: ${task.assignedTo}');
        print('ソース: ${task.source}');
        print('外部ID: ${task.externalId}');
        print('拡張プロパティ情報:');
        extendedProps.forEach((key, value) {
          print('  $key: $value');
        });
        print('ステータス解析: statusStr="$statusStr" → ${task.status}');
        print('==================');
      }
      
      return task;
    } catch (e) {
      ErrorHandler.logError('イベント→タスク変換', e);
      return null;
    }
  }
  
  /// 優先度を文字列から解析
  TaskPriority _parsePriority(String priorityStr) {
    switch (priorityStr.toLowerCase()) {
      case 'urgent':
      case '緊急':
        return TaskPriority.urgent;
      case 'high':
      case '高':
        return TaskPriority.high;
      case 'medium':
      case '中':
        return TaskPriority.medium;
      case 'low':
      case '低':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  /// ステータスを文字列から解析
  TaskStatus _parseStatus(String statusStr) {
    // TaskStatus.enumValue 形式の文字列を処理
    if (statusStr.contains('TaskStatus.')) {
      final statusPart = statusStr.split('TaskStatus.')[1];
      switch (statusPart.toLowerCase()) {
        case 'pending':
        case '未着手':
          return TaskStatus.pending;
        case 'inprogress':
        case '進行中':
          return TaskStatus.inProgress;
        case 'completed':
        case '完了':
          return TaskStatus.completed;
        case 'cancelled':
        case 'キャンセル':
          return TaskStatus.cancelled;
        default:
          return TaskStatus.pending;
      }
    }
    
    // 直接的な文字列を処理
    switch (statusStr.toLowerCase()) {
      case 'pending':
      case '未着手':
        return TaskStatus.pending;
      case 'inprogress':
      case '進行中':
        return TaskStatus.inProgress;
      case 'completed':
      case '完了':
        return TaskStatus.completed;
      case 'cancelled':
      case 'キャンセル':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }
  

  /// 色IDからステータスを推定
  TaskStatus _getStatusFromColorId(String colorId) {
    switch (colorId) {
      case '8': // グラファイト（グレー）
        return TaskStatus.completed;
      case '7': // ピーコック（青）- 進行中
        return TaskStatus.inProgress;
      case '9': // ブルーベリー（青）- 進行中（旧設定との互換性）
        return TaskStatus.inProgress;
      case '10': // バジル（グリーン）
        return TaskStatus.pending;
      case '11': // トマト（レッド）
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
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
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 30));
      final endTime = now.add(const Duration(days: 365));
      
      final url = Uri.parse('$_calendarApiUrl/calendars/primary/events').replace(
        queryParameters: {
          'timeMin': startTime.toUtc().toIso8601String(),
          'timeMax': endTime.toUtc().toIso8601String(),
          'maxResults': '2500', // 最大取得数を増加
          'singleEvents': 'true',
          'orderBy': 'startTime',
        },
      );
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data['items'] as List?;
        
        if (events != null) {
          // 全てのイベントを取得（アプリから作成されたものも、Google Calendarに元々あったものも含む）
          print('Google Calendarから取得した全イベント数: ${events.length}');
          
          // デバッグ情報を出力
          int holidayCount = 0;
          int validEventCount = 0;
          int businessEventCount = 0;
          
          print('=== イベント詳細分析 ===');
          for (int i = 0; i < events.length && i < 30; i++) {
            final event = events[i] as Map<String, dynamic>;
            final summary = event['summary'] ?? '無題';
            final description = event['description'] ?? '';
            final start = event['start'];
            String dateStr = '日付なし';
            bool isAllDay = false;
            
            if (start != null) {
              if (start['dateTime'] != null) {
                dateStr = DateTime.parse(start['dateTime']).toLocal().toString();
                isAllDay = false;
              } else if (start['date'] != null) {
                dateStr = DateTime.parse(start['date']).toString();
                isAllDay = true;
              }
            }
            
            final extendedProps = event['extendedProperties']?['private'];
            final isAppCreated = extendedProps?['taskId'] != null;
            
            // ビジネスイベントチェック
            final isBusiness = _isBusinessEvent(summary, description);
            if (isBusiness) businessEventCount++;
            
            // 祝日チェック
            final isHoliday = _isHolidayEvent(summary, description, event);
            if (isHoliday) {
              holidayCount++;
            } else {
              validEventCount++;
            }
            
            print('  イベント${i + 1}: "$summary"');
            print('    日付: $dateStr (終日: $isAllDay)');
            print('    説明: ${description.length > 50 ? description.substring(0, 50) + "..." : description}');
            print('    アプリ作成: $isAppCreated, ビジネス: $isBusiness, 祝日: $isHoliday');
            
            // 拡張プロパティの詳細を出力
            final eventExtendedProps = event['extendedProperties']?['private'] ?? {};
            if (eventExtendedProps.isNotEmpty) {
              print('    拡張プロパティ:');
              eventExtendedProps.forEach((key, value) {
                print('      $key: $value');
              });
            } else {
              print('    拡張プロパティ: なし');
            }
            
            // 色IDとステータス情報
            final colorId = event['colorId'] ?? '1';
            print('    色ID: $colorId');
            
            print('');
          }
          
          print('=== 統計サマリー ===');
          print('総イベント数: ${events.length}件');
          print('祝日除外: $holidayCount件');
          print('ビジネスイベント: $businessEventCount件');
          print('有効イベント: $validEventCount件');
          print('==================');
          
          return events.cast<Map<String, dynamic>>().toList();
        }
      } else {
        print('Google Calendar イベント取得エラー: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      ErrorHandler.logError('Google Calendarイベント取得', e);
    }
    
    return [];
  }

  /// 単一タスクの同期（UUIDベースの厳密なマッチング）
  Future<String> _syncSingleTask(TaskItem task, List<Map<String, dynamic>> existingEvents) async {
    try {
      // 既存のイベントを検索（UUIDベースの厳密なマッチング）
      Map<String, dynamic>? existingEvent;
      
      // 1. タスクID（UUID）で厳密に検索
      for (final event in existingEvents) {
        final taskId = event['extendedProperties']?['private']?['taskId'];
        if (taskId == task.id) {
          existingEvent = event;
          print('UUID一致で既存イベント発見: ${task.title} (ID: $taskId)');
          break;
        }
      }
      
      // 2. UUIDが見つからない場合のみ、タイトルベースのフォールバック検索
      if (existingEvent == null) {
        for (final event in existingEvents) {
          final eventTitle = event['summary'] ?? '';
          final eventStart = event['start'];
          DateTime? eventStartTime;
          
          if (eventStart != null) {
            if (eventStart['dateTime'] != null) {
              eventStartTime = DateTime.parse(eventStart['dateTime']).toLocal();
            } else if (eventStart['date'] != null) {
              eventStartTime = DateTime.parse(eventStart['date']);
            }
          }
          
          // タイトルが完全一致し、日付が同じ場合のみ重複とみなす
          if (eventTitle == task.title && eventStartTime != null && task.dueDate != null) {
            final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
            final eventDate = DateTime(eventStartTime.year, eventStartTime.month, eventStartTime.day);
            
            if (taskDate.isAtSameMomentAs(eventDate)) {
              existingEvent = event;
              print('タイトル・日付一致で既存イベント発見: $eventTitle');
              break;
            }
          }
        }
      }

      if (existingEvent != null) {
        // 既存イベントの更新（UUIDを確実に保持）
        final success = await updateCalendarEvent(task, existingEvent['id']);
        if (success) {
          print('既存イベント更新成功: ${task.title}');
          return 'updated';
        } else {
          print('既存イベント更新失敗: ${task.title}');
          return 'skipped';
        }
      } else {
        // 新規イベントの作成
        final result = await createCalendarEvent(task);
        if (result.success) {
          print('新規イベント作成成功: ${task.title}');
          return 'created';
        } else {
          print('新規イベント作成失敗: ${task.title}');
          return 'skipped';
        }
      }
    } catch (e) {
      ErrorHandler.logError('単一タスク同期', e);
      return 'skipped';
    }
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
