import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'dart:async';
import 'models/link_item.dart';
import 'models/group.dart';
import 'models/task_item.dart';
import 'models/sub_task.dart';
import 'views/link_launcher_app.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'services/notification_service.dart';
import 'services/windows_notification_service.dart';
import 'services/system_tray_service.dart';
import 'services/migration_service.dart';
import 'services/settings_service.dart';
import 'services/backup_service.dart';
import 'services/google_calendar_service.dart';
import 'repositories/link_repository.dart';
import 'viewmodels/task_viewmodel.dart';


void main() async {
  try {
    // 重複起動チェック
    if (!await _checkSingleInstance()) {
      print('アプリケーションが既に起動しています。終了します。');
      return;
    }
    
    // 段階的初期化でアプリケーションの安定性を向上
    await _initializeApp();
    await _initializeWindow();
    
    // 通知サービス初期化（既存サービスを直接使用）
    try {
      print('通知サービス初期化開始');
      await NotificationService.initialize();
      await WindowsNotificationService.initialize();
      print('通知サービス初期化完了');
    } catch (e) {
      print('通知サービス初期化エラー: $e');
    }
    
    runApp(const ProviderScope(child: LinkLauncherApp()));
  } catch (e) {
    print('アプリケーション初期化エラー: $e');
    // エラーが発生してもアプリケーションを起動
    runApp(const ProviderScope(child: LinkLauncherApp()));
  }
}

// アプリケーションの基本初期化
Future<void> _initializeApp() async {
  print('アプリケーション初期化開始');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // 段階1: Hive初期化
  await _initializeHive();
  
  // 段階2: データマイグレーション
  await _initializeDataMigration();
  
  // 段階3: 基本サービスの初期化
  await _initializeBasicServices();
  
  // 段階4: 高度な機能の初期化（非同期）
  _initializeAdvancedFeatures();
  
  print('アプリケーション初期化完了');
}

// Hive初期化
Future<void> _initializeHive() async {
  try {
    print('Hive初期化開始');
    
    // Initialize Hive with local directory (OneDrive問題を完全回避)
    // アプリのローカルデータディレクトリを使用（OneDriveの影響を受けない）
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? 'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Local';
    final localDataDir = Directory('$localAppData\\linker_f_data');
    if (!await localDataDir.exists()) {
      await localDataDir.create(recursive: true);
    }
    await Hive.initFlutter(localDataDir.path);
    print('Hive初期化完了: ${localDataDir.path}');
    
    // 既存のOneDriveデータを新しい場所に移動
    await _migrateFromOneDrive(localDataDir);
    
    // アダプター登録
    try {
      Hive.registerAdapter(LinkTypeAdapter());
    } catch (e) {
      print('LinkTypeAdapter登録エラー: $e');
    }
    try {
      Hive.registerAdapter(LinkItemAdapter());
    } catch (e) {
      print('LinkItemAdapter登録エラー: $e');
    }
    try {
      Hive.registerAdapter(GroupAdapter());
    } catch (e) {
      print('GroupAdapter登録エラー: $e');
    }
    try {
      Hive.registerAdapter(OffsetAdapter());
    } catch (e) {
      print('OffsetAdapter登録エラー: $e');
    }
    try {
      Hive.registerAdapter(TaskPriorityAdapter());
    } catch (e) {
      print('TaskPriorityAdapter登録エラー: $e');
    }
    try {
      Hive.registerAdapter(TaskStatusAdapter());
    } catch (e) {
      print('TaskStatusAdapter登録エラー: $e');
    }
    try {
      Hive.registerAdapter(TaskItemAdapter());
    } catch (e) {
      print('TaskItemAdapter登録エラー: $e');
    }
    try {
      Hive.registerAdapter(SubTaskAdapter());
    } catch (e) {
      print('SubTaskAdapter登録エラー: $e');
    }
    
    print('Hive初期化完了');
  } catch (e) {
    print('Hive初期化エラー: $e');
    rethrow;
  }
}

// データマイグレーション初期化
Future<void> _initializeDataMigration() async {
  try {
    print('データマイグレーション開始');
    
    await MigrationService.migrateData();
    
    final isDataValid = await MigrationService.validateDataIntegrity();
    if (!isDataValid) {
      print('データ整合性エラーを検出しました。修復を開始します...');
      await MigrationService.repairCorruptedData();
    }
    
    print('データマイグレーション完了');
  } catch (e) {
    print('データマイグレーションエラー: $e');
    // データマイグレーションエラーは致命的でないため、継続
  }
}

// 基本サービスの初期化
Future<void> _initializeBasicServices() async {
  try {
    print('基本サービス初期化開始');
    
    // 設定サービスの初期化（最優先）
    final settingsService = SettingsService.instance;
    await settingsService.initialize();
    
    // 通知サービス初期化はmain()で実行済み
    
    print('基本サービス初期化完了');
  } catch (e) {
    print('基本サービス初期化エラー: $e');
    // 通知機能のエラーは致命的でないため、継続
  }
}

// 高度な機能の初期化（非同期実行）
void _initializeAdvancedFeatures() {
  // 非同期で実行してUIの起動をブロックしない
  Future.microtask(() async {
    try {
      print('高度な機能初期化開始');
      
      // システムトレイ機能の初期化
      await SystemTrayService.initialize();
      
      // 自動バックアップのチェックと実行
      try {
        final settingsService = SettingsService.instance;
        final linkRepository = LinkRepository();
        await linkRepository.initialize();
        
        // バックアップ完了時のコールバックを設定
        BackupService.setOnBackupCompleted((backupPath) {
          _showBackupCompletedNotification(backupPath);
        });
        
        final backupService = BackupService(
          linkRepository: linkRepository,
          settingsService: settingsService,
        );
        await backupService.checkAndPerformAutoBackup();
        print('自動バックアップチェック完了');
      } catch (e) {
        print('自動バックアップチェックエラー: $e');
        // バックアップエラーは致命的でないため、継続
      }
      
      // リマインダー復元
      final taskBox = await Hive.openBox<TaskItem>('tasks');
      final tasks = taskBox.values.toList();
      if (tasks.isNotEmpty) {
        print('既存タスク数: ${tasks.length}');
        await WindowsNotificationService.restoreReminders(tasks);
      }
      
      // Google Calendar自動同期の初期化
      await _initializeGoogleCalendarSync();
      
      print('高度な機能初期化完了');
    } catch (e) {
      print('高度な機能初期化エラー: $e');
      // 高度な機能のエラーは致命的でないため、継続
    }
  });
}

// ウィンドウ初期化
Future<void> _initializeWindow() async {
  try {
    print('ウィンドウ初期化開始');
    
    await windowManager.ensureInitialized();

    // ディスプレイの取得と設定
    final displays = await ScreenRetriever.instance.getAllDisplays();
    
    // 複数ディスプレイがある場合は小さいディスプレイを選択
    final targetDisplay = displays.length > 1 
        ? displays.reduce((a, b) => (a.size.width * a.size.height) < (b.size.width * b.size.height) ? a : b)
        : displays[0];
    
    // 選択したディスプレイの半分のサイズでウィンドウを設定
    final displaySize = targetDisplay.size;
    final windowWidth = (displaySize.width / 2).round();
    final windowHeight = displaySize.height.round();
    
    // ウィンドウの位置を設定
    final windowX = displays.length > 1 
        ? displays[0].size.width + (displaySize.width - windowWidth)
        : (displaySize.width - windowWidth);
    final windowY = 0;

    if (kDebugMode) {
      print('ディスプレイ数: ${displays.length}');
      print('選択したディスプレイサイズ: ${targetDisplay.size}');
      print('ウィンドウサイズ: ${windowWidth}x${windowHeight}');
      print('ウィンドウ位置: ($windowX, $windowY)');
    }

    WindowOptions windowOptions = WindowOptions(
      size: Size(windowWidth.toDouble(), windowHeight.toDouble()),
      center: false,
      backgroundColor: const Color(0xFFF4F5F7),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Link Navigator',
      alwaysOnTop: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPosition(Offset(windowX.toDouble(), windowY.toDouble()));
      await windowManager.setTitle('Link Navigator');
    });
    
    print('ウィンドウ初期化完了');
  } catch (e) {
    print('ウィンドウ初期化エラー: $e');
    // ウィンドウ初期化エラーは致命的でないため、継続
  }
}

// OneDriveからのデータ移行
Future<void> _migrateFromOneDrive(Directory newDataDir) async {
  try {
    print('OneDriveデータ移行チェック開始');
    
    // OneDriveのDocumentsディレクトリをチェック
    final appDocDir = await getApplicationDocumentsDirectory();
    final oneDriveDataDir = Directory('${appDocDir.path}/linker_f_data');
    
    if (await oneDriveDataDir.exists()) {
      print('OneDriveデータが見つかりました: ${oneDriveDataDir.path}');
      
      // 新しいディレクトリにファイルをコピー
      final files = await oneDriveDataDir.list().toList();
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          final newFile = File('${newDataDir.path}/$fileName');
          
          try {
            await file.copy(newFile.path);
            print('ファイル移行完了: $fileName');
          } catch (e) {
            print('ファイル移行エラー ($fileName): $e');
          }
        }
      }
      
      print('OneDriveデータ移行完了');
    } else {
      print('OneDriveデータは見つかりませんでした');
    }
  } catch (e) {
    print('OneDriveデータ移行エラー: $e');
  }
}

// 重複起動チェック
Future<bool> _checkSingleInstance() async {
  try {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? 'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Local';
    final lockFile = File('$localAppData\\linker_f_data\\app.lock');
    
    if (await lockFile.exists()) {
      // ロックファイルが存在する場合、プロセスが生きているかチェック
      try {
        final content = await lockFile.readAsString();
        final pid = int.tryParse(content.trim());
        if (pid != null) {
          // Windowsでプロセスが存在するかチェック
          final result = await Process.run('tasklist', ['/FI', 'PID eq $pid', '/FO', 'CSV']);
          if (result.stdout.toString().contains('$pid')) {
            print('既存のプロセスが実行中です (PID: $pid)');
            return false;
          }
        }
      } catch (e) {
        print('ロックファイルチェックエラー: $e');
      }
    }
    
    // ロックファイルを作成
    await lockFile.parent.create(recursive: true);
    await lockFile.writeAsString(pid.toString());
    
    // アプリ終了時にロックファイルを削除
    ProcessSignal.sigint.watch().listen((_) async {
      try {
        await lockFile.delete();
      } catch (e) {
        print('ロックファイル削除エラー: $e');
      }
    });
    
    return true;
  } catch (e) {
    print('重複起動チェックエラー: $e');
    return true; // エラーの場合は起動を許可
  }
}

/// バックアップ完了通知を表示
void _showBackupCompletedNotification(String backupPath) {
  try {
    // Windows通知を表示
    WindowsNotificationService.showToastNotification(
      '自動バックアップ完了',
      'データのバックアップが完了しました。\n保存場所: ${backupPath.split('\\').last}',
    );
    
    // バックアップフォルダを開く
    final backupDir = File(backupPath).parent.path;
    Process.run('explorer', [backupDir]);
    
    print('バックアップ完了通知を表示: $backupPath');
  } catch (e) {
    print('バックアップ完了通知エラー: $e');
  }
}

/// Google Calendar自動同期の初期化
Future<void> _initializeGoogleCalendarSync() async {
  try {
    final settingsService = SettingsService.instance;
    
    // Google Calendar連携が有効でない場合はスキップ
    if (!settingsService.googleCalendarEnabled) {
      print('Google Calendar連携が無効のため、同期をスキップします');
      return;
    }
    
    // Google Calendarサービスの初期化
    final googleCalendarService = GoogleCalendarService();
    final initialized = await googleCalendarService.initialize();
    
    if (!initialized) {
      print('Google Calendarサービスの初期化に失敗しました');
      return;
    }
    
    print('Google Calendar自動同期を開始します');
    
    // 初回同期を実行
    await _performGoogleCalendarSync(googleCalendarService);
    
    // 自動同期が有効な場合は、定期的な同期を開始
    if (settingsService.googleCalendarAutoSync) {
      _startGoogleCalendarAutoSync(googleCalendarService);
    }
    
  } catch (e) {
    print('Google Calendar自動同期初期化エラー: $e');
  }
}

/// Google Calendar同期を実行
Future<void> _performGoogleCalendarSync(GoogleCalendarService googleCalendarService) async {
  try {
    print('Google Calendar同期を実行中...');
    
    // 過去30日から未来30日までのイベントを取得
    final startTime = DateTime.now().subtract(const Duration(days: 30));
    final endTime = DateTime.now().add(const Duration(days: 30));
    
    final calendarTasks = await googleCalendarService.syncEvents(
      startTime: startTime,
      endTime: endTime,
      maxResults: 100,
    );
    
    // TaskViewModelに同期
    // 注意: ここでは直接TaskViewModelにアクセスできないため、
    // 実際の実装ではProviderコンテキストが必要です
    
    print('Google Calendar同期完了: ${calendarTasks.length}件のタスクを取得');
    
    // TODO: 自動同期でもタスクを保存する必要があります
    // 現在は手動同期でのみタスクが保存されます
    
    // 最終同期時刻を更新
    final settingsService = SettingsService.instance;
    await settingsService.setGoogleCalendarLastSync(DateTime.now());
    
  } catch (e) {
    print('Google Calendar同期エラー: $e');
  }
}

/// Google Calendar自動同期を開始
void _startGoogleCalendarAutoSync(GoogleCalendarService googleCalendarService) {
  final settingsService = SettingsService.instance;
  final syncInterval = settingsService.googleCalendarSyncInterval;
  
  print('Google Calendar自動同期を開始: ${syncInterval}分間隔');
  
  Timer.periodic(Duration(minutes: syncInterval), (timer) async {
    try {
      await _performGoogleCalendarSync(googleCalendarService);
    } catch (e) {
      print('Google Calendar自動同期エラー: $e');
    }
  });
}

