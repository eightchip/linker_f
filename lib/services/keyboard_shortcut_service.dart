import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../views/task_screen.dart';
import '../views/calendar_screen.dart';

/// キーボードショートカットサービス
class KeyboardShortcutService {
  static GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  // ナビゲーターキーを設定
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }
  
  /// キーボードショートカットを処理
  static bool handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final logicalKey = event.logicalKey;
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      final isAltPressed = HardwareKeyboard.instance.isAltPressed;
      
      // Ctrl+Shift+L: グローバルタスク作成
      if (isCtrlPressed && isShiftPressed && logicalKey == LogicalKeyboardKey.keyL) {
        _handleGlobalTaskCreation();
        return true;
      }
      
      // Ctrl+N: 新規タスク作成
      if (isCtrlPressed && !isShiftPressed && logicalKey == LogicalKeyboardKey.keyN) {
        _handleNewTask();
        return true;
      }
      
      // Ctrl+E: タスク編集
      if (isCtrlPressed && !isShiftPressed && logicalKey == LogicalKeyboardKey.keyE) {
        _handleEditTask();
        return true;
      }
      
      // Ctrl+D: タスク削除
      if (isCtrlPressed && !isShiftPressed && logicalKey == LogicalKeyboardKey.keyD) {
        _handleDeleteTask();
        return true;
      }
      
      // Ctrl+Enter: タスク完了
      if (isCtrlPressed && !isShiftPressed && logicalKey == LogicalKeyboardKey.enter) {
        _handleCompleteTask();
        return true;
      }
      
      // Ctrl+1: リンク画面
      if (isCtrlPressed && !isShiftPressed && logicalKey == LogicalKeyboardKey.digit1) {
        _handleNavigateToScreen(0);
        return true;
      }
      
      // Ctrl+2: タスク画面
      if (isCtrlPressed && !isShiftPressed && logicalKey == LogicalKeyboardKey.digit2) {
        _handleNavigateToScreen(1);
        return true;
      }
      
      // Ctrl+3: カレンダー画面
      if (isCtrlPressed && !isShiftPressed && logicalKey == LogicalKeyboardKey.digit3) {
        _handleNavigateToScreen(2);
        return true;
      }
      
      // Ctrl+F: 検索
      if (isCtrlPressed && !isShiftPressed && logicalKey == LogicalKeyboardKey.keyF) {
        _handleSearch();
        return true;
      }
      
      // Ctrl+G: 次の検索結果
      if (isCtrlPressed && !isShiftPressed && logicalKey == LogicalKeyboardKey.keyG) {
        _handleNextSearchResult();
        return true;
      }
    }
    
    return false;
  }
  
  /// グローバルタスク作成
  static void _handleGlobalTaskCreation() {
    if (kDebugMode) {
      print('グローバルタスク作成ショートカットが押されました');
    }
    
    // アプリを前面に表示
    _bringAppToFront();
    
    // タスク作成ダイアログを表示
    final context = _navigatorKey.currentContext;
    if (context != null) {
      // タスク画面に移動してからタスク作成ダイアログを表示
      _showTaskCreationDialog(context);
    }
  }
  
  /// 新規タスク作成
  static void _handleNewTask() {
    if (kDebugMode) {
      print('新規タスク作成ショートカットが押されました');
    }
    
    final context = _navigatorKey.currentContext;
    if (context != null) {
      _showTaskCreationDialog(context);
    }
  }
  
  /// タスク編集
  static void _handleEditTask() {
    if (kDebugMode) {
      print('タスク編集ショートカットが押されました');
    }
    
    final context = _navigatorKey.currentContext;
    if (context != null) {
      // 現在選択されているタスクを編集
      _showTaskEditDialog(context);
    }
  }
  
  /// タスク削除
  static void _handleDeleteTask() {
    if (kDebugMode) {
      print('タスク削除ショートカットが押されました');
    }
    
    final context = _navigatorKey.currentContext;
    if (context != null) {
      // 現在選択されているタスクを削除
      _showTaskDeleteConfirmation(context);
    }
  }
  
  /// タスク完了
  static void _handleCompleteTask() {
    if (kDebugMode) {
      print('タスク完了ショートカットが押されました');
    }
    
    final context = _navigatorKey.currentContext;
    if (context != null) {
      // 現在選択されているタスクを完了
      _completeSelectedTask(context);
    }
  }
  
  /// 画面切り替え
  static void _handleNavigateToScreen(int screenIndex) {
    if (kDebugMode) {
      print('画面切り替えショートカットが押されました: $screenIndex');
    }
    
    final context = _navigatorKey.currentContext;
    if (context != null) {
      // 画面切り替えのロジックは各画面で実装
      _navigateToScreen(context, screenIndex);
    }
  }
  
  /// 検索
  static void _handleSearch() {
    if (kDebugMode) {
      print('検索ショートカットが押されました');
    }
    
    final context = _navigatorKey.currentContext;
    if (context != null) {
      _showSearchDialog(context);
    }
  }
  
  /// 次の検索結果
  static void _handleNextSearchResult() {
    if (kDebugMode) {
      print('次の検索結果ショートカットが押されました');
    }
    
    final context = _navigatorKey.currentContext;
    if (context != null) {
      _navigateToNextSearchResult(context);
    }
  }
  
  /// アプリを前面に表示
  static void _bringAppToFront() {
    try {
      // Windowsの場合の実装
      if (Platform.isWindows) {
        // ウィンドウマネージャーを使用してアプリを前面に表示
        // この実装は後で詳細化
      }
    } catch (e) {
      if (kDebugMode) {
        print('アプリを前面に表示する際のエラー: $e');
      }
    }
  }
  
  /// タスク作成ダイアログを表示
  static void _showTaskCreationDialog(BuildContext context) {
    // タスク作成ダイアログの実装
    // これは後で詳細化
    if (kDebugMode) {
      print('タスク作成ダイアログを表示');
    }
  }
  
  /// タスク編集ダイアログを表示
  static void _showTaskEditDialog(BuildContext context) {
    // タスク編集ダイアログの実装
    if (kDebugMode) {
      print('タスク編集ダイアログを表示');
    }
  }
  
  /// タスク削除確認ダイアログを表示
  static void _showTaskDeleteConfirmation(BuildContext context) {
    // タスク削除確認ダイアログの実装
    if (kDebugMode) {
      print('タスク削除確認ダイアログを表示');
    }
  }
  
  /// 選択されたタスクを完了
  static void _completeSelectedTask(BuildContext context) {
    // タスク完了の実装
    if (kDebugMode) {
      print('選択されたタスクを完了');
    }
  }
  
  /// 画面に移動
  static void _navigateToScreen(BuildContext context, int screenIndex) {
    if (kDebugMode) {
      print('画面 $screenIndex に移動');
    }
    
    // HomeScreenのメソッドを使用して画面遷移
    switch (screenIndex) {
      case 0: // リンク画面（ホーム）
        // ホーム画面に戻る
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case 1: // タスク画面
        // TaskScreenに移動
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskScreen(),
          ),
        );
        break;
      case 2: // カレンダー画面
        // CalendarScreenに移動
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CalendarScreen(),
          ),
        );
        break;
    }
  }
  
  /// 検索ダイアログを表示
  static void _showSearchDialog(BuildContext context) {
    // 検索ダイアログの実装
    if (kDebugMode) {
      print('検索ダイアログを表示');
    }
  }
  
  /// 次の検索結果に移動
  static void _navigateToNextSearchResult(BuildContext context) {
    // 次の検索結果に移動の実装
    if (kDebugMode) {
      print('次の検索結果に移動');
    }
  }
}

/// キーボードショートカット用のウィジェット
class KeyboardShortcutWidget extends StatefulWidget {
  final Widget child;
  
  const KeyboardShortcutWidget({
    super.key,
    required this.child,
  });
  
  @override
  State<KeyboardShortcutWidget> createState() => _KeyboardShortcutWidgetState();
}

class _KeyboardShortcutWidgetState extends State<KeyboardShortcutWidget> {
  final FocusNode _node = FocusNode(); // ← 再利用
  
  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _node,
      autofocus: false, // ← 重要: 奪わない
      onKeyEvent: (event) {
        // TextField にフォーカスがある時はグローバルショートカット無効化
        final focused = FocusManager.instance.primaryFocus;
        final isEditing = focused?.context?.widget is EditableText;
        if (isEditing) return; // ← 入力中はショートカット処理しない
        
        if (KeyboardShortcutService.handleKeyEvent(event)) {
          // ショートカットが処理された場合は、イベントを消費
          return;
        }
      },
      child: widget.child,
    );
  }
}
