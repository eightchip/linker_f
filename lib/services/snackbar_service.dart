import 'package:flutter/material.dart';

class SnackBarService {
  static void showCenteredSnackBar(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Color? iconColor,
  }) {
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
      overlayEntry.remove();
    });
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
}
