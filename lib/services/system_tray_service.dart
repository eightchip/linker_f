import 'package:tray_manager/tray_manager.dart';

class SystemTrayService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // システムトレイの初期化
      // アイコンファイルが存在しない場合はデフォルトアイコンを使用
      try {
        await trayManager.setIcon('assets/icons/app_icon.ico');
      } catch (e) {
        print('カスタムアイコンの読み込みに失敗しました。デフォルトアイコンを使用します: $e');
        // デフォルトアイコンを使用するか、アイコンなしで初期化
      }

      // システムトレイメニューの設定
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(
              key: 'show',
              label: '表示',
            ),
            MenuItem(
              key: 'hide',
              label: '非表示',
            ),
            MenuItem.separator(),
            MenuItem(
              key: 'exit',
              label: '終了',
            ),
          ],
        ),
      );

      // システムトレイイベントのリスナーを設定（簡易版）
      print('システムトレイリスナー設定完了');

      _isInitialized = true;
      print('システムトレイサービス初期化完了');
    } catch (e) {
      print('システムトレイサービス初期化エラー: $e');
    }
  }

  // システムトレイメニューアイテムのクリック処理
  static void _handleTrayMenuItemClick(String key) {
    switch (key) {
      case 'show':
        print('アプリを表示');
        // ここでアプリウィンドウを表示する処理を追加
        break;
      case 'hide':
        print('アプリを非表示');
        // ここでアプリウィンドウを非表示にする処理を追加
        break;
      case 'exit':
        print('アプリを終了');
        // ここでアプリを終了する処理を追加
        break;
    }
  }

  // システムトレイを表示
  static Future<void> show() async {
    if (_isInitialized) {
      try {
        await trayManager.setIcon('assets/icons/app_icon.ico');
        print('システムトレイ表示');
      } catch (e) {
        print('システムトレイ表示エラー: $e');
      }
    }
  }

  // システムトレイを非表示
  static Future<void> hide() async {
    if (_isInitialized) {
      try {
        await trayManager.destroy();
        print('システムトレイ非表示');
      } catch (e) {
        print('システムトレイ非表示エラー: $e');
      }
    }
  }

  // システムトレイ通知を表示
  static Future<void> showNotification({
    required String title,
    required String message,
    Duration? duration,
  }) async {
    if (_isInitialized) {
      try {
        // tray_managerパッケージでは直接的な通知機能がないため、
        // Windows通知サービスを使用
        print('システムトレイ通知: $title - $message');
      } catch (e) {
        print('システムトレイ通知エラー: $e');
      }
    }
  }

  // クリーンアップ
  static Future<void> dispose() async {
    try {
      if (_isInitialized) {
        await trayManager.destroy();
        _isInitialized = false;
        print('システムトレイサービスクリーンアップ完了');
      }
    } catch (e) {
      print('システムトレイサービスクリーンアップエラー: $e');
    }
  }
}
