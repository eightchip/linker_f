import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'keyboard_shortcut_service.dart';

class SnackBarService {
  static BuildContext? _globalContext() {
    final key = KeyboardShortcutService.getNavigatorKey();
    return key?.currentContext;
  }

  static void showCenteredSnackBar(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Color? iconColor,
  }) {
    try {
      // ウィジェットがマウントされているかチェック
      if (!context.mounted) return;
      
      final overlay = Overlay.of(context);
      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).size.height * 0.4, // 画面の40%の位置
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: iconColor ?? Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      overlay.insert(overlayEntry);

      // 指定された時間後に削除
      Future.delayed(duration, () {
        try {
          overlayEntry.remove();
        } catch (e) {
          // オーバーレイの削除でエラーが発生した場合は無視
          print('SnackBar overlay removal error: $e');
        }
      });
    } catch (e) {
      // オーバーレイの作成でエラーが発生した場合は無視
      print('SnackBar creation error: $e');
    }
  }

  // 成功メッセージ用
  static void showSuccess(BuildContext context, String message) {
    showCenteredSnackBar(
      context,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  // エラーメッセージ用
  static void showError(BuildContext context, String message) {
    showCenteredSnackBar(
      context,
      message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: const Duration(seconds: 4),
    );
  }

  static void showGlobalError(String message) {
    final context = _globalContext();
    if (context != null) {
      showError(context, message);
    } else {
      debugPrint('Global error notification (context unavailable): $message');
    }
  }

  // 情報メッセージ用
  static void showInfo(BuildContext context, String message) {
    showCenteredSnackBar(
      context,
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  // 警告メッセージ用
  static void showWarning(BuildContext context, String message) {
    showCenteredSnackBar(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  static void showGlobalWarning(String message) {
    final context = _globalContext();
    if (context != null) {
      showWarning(context, message);
    } else {
      debugPrint('Global warning notification (context unavailable): $message');
    }
  }

  static void showGlobalInfo(String message) {
    final context = _globalContext();
    if (context != null) {
      showInfo(context, message);
    } else {
      debugPrint('Global info notification (context unavailable): $message');
    }
  }

  static void showGlobalSuccess(String message) {
    final context = _globalContext();
    if (context != null) {
      showSuccess(context, message);
    } else {
      debugPrint('Global success notification (context unavailable): $message');
    }
  }
}
