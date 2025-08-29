import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'models/link_item.dart';
import 'models/group.dart';
import 'models/task_item.dart';
import 'views/link_launcher_app.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'services/notification_service.dart';
import 'services/windows_notification_service.dart';
import 'services/system_tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive with persistent directory
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);
  
  // Register adapters
  try {
    Hive.registerAdapter(LinkTypeAdapter());
  } catch (e) {
    // Already registered
  }
  try {
    Hive.registerAdapter(LinkItemAdapter());
  } catch (e) {
    // Already registered
  }
  try {
    Hive.registerAdapter(GroupAdapter());
  } catch (e) {
    // Already registered
  }
  try {
    Hive.registerAdapter(OffsetAdapter());
  } catch (e) {
    // Already registered
  }
  try {
    Hive.registerAdapter(TaskPriorityAdapter());
  } catch (e) {
    // Already registered
  }
  try {
    Hive.registerAdapter(TaskStatusAdapter());
  } catch (e) {
    // Already registered
  }
  try {
    Hive.registerAdapter(TaskItemAdapter());
  } catch (e) {
    // Already registered
  }
  
  // データベースファイルの永続化を確実にする
  // 注意: スキーマ変更時のみ以下の行を有効にする
  // await Hive.deleteBoxFromDisk('groups');
  // await Hive.deleteBoxFromDisk('links');
  // await Hive.deleteBoxFromDisk('tasks');
  
  // 通知機能の初期化
  await NotificationService.initialize();
  
  // Windows固有の通知機能の初期化
  await WindowsNotificationService.initialize();
  
  // システムトレイ機能の初期化
  await SystemTrayService.initialize();
  
  // Desktop window configuration
  await windowManager.ensureInitialized();

  // ディスプレイの取得と設定
  final displays = await ScreenRetriever.instance.getAllDisplays();
  
  // 複数ディスプレイがある場合は小さいディスプレイを選択
  // 単一ディスプレイの場合はそのディスプレイを使用
  final targetDisplay = displays.length > 1 
      ? displays.reduce((a, b) => (a.size.width * a.size.height) < (b.size.width * b.size.height) ? a : b)
      : displays[0];
  
  // 選択したディスプレイの半分のサイズでウィンドウを設定
  final displaySize = targetDisplay.size;
  final windowWidth = (displaySize.width / 2).round();
  final windowHeight = displaySize.height.round();
  
  // ウィンドウの位置を設定（選択したディスプレイの右半分に配置）
  // 複数ディスプレイの場合は2番目のディスプレイ（サブディスプレイ）の右半分に配置
  final windowX = displays.length > 1 
      ? displays[0].size.width + (displaySize.width - windowWidth)  // メインディスプレイの幅 + サブディスプレイの右半分
      : (displaySize.width - windowWidth);  // 単一ディスプレイの場合は右半分
  final windowY = 0;

  print('ディスプレイ数: ${displays.length}');
  print('選択したディスプレイサイズ: ${targetDisplay.size}');
  print('ウィンドウサイズ: ${windowWidth}x${windowHeight}');
  print('ウィンドウ位置: ($windowX, $windowY)');

  WindowOptions windowOptions = WindowOptions(
    size: Size(windowWidth.toDouble(), windowHeight.toDouble()),
    center: false,
    backgroundColor: const Color(0xFFF4F5F7),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Link Navigator',
    // ちらつきを防ぐための設定
    alwaysOnTop: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPosition(Offset(windowX.toDouble(), windowY.toDouble()));
    await windowManager.setTitle('Link Navigator');
  });

  runApp(const ProviderScope(child: LinkLauncherApp()));
}

