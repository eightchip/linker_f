import 'package:flutter/material.dart';

/// 統一されたダイアログコンポーネント
class UnifiedDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final IconData? icon;
  final Color? iconColor;
  final double? width;
  final double? height;

  const UnifiedDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
    this.iconColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: iconColor ?? Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // コンテンツ
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
            // アクションボタン
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 統一されたボタンスタイル
class AppButtonStyles {
  static ButtonStyle primary(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static ButtonStyle danger(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade600,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static ButtonStyle warning(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.orange.shade600,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static ButtonStyle secondary(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static ButtonStyle text(BuildContext context) {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

/// 便利なダイアログ表示メソッド
class UnifiedDialogHelper {
  /// 確認ダイアログを表示
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '確認',
    String cancelText = 'キャンセル',
    IconData? icon,
    Color? iconColor,
    ButtonStyle? confirmButtonStyle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => UnifiedDialog(
        title: title,
        icon: icon,
        iconColor: iconColor,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: AppButtonStyles.text(context),
            child: Text(cancelText),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: confirmButtonStyle ?? AppButtonStyles.primary(context),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 削除確認ダイアログを表示
  static Future<bool?> showDeleteConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '削除',
    String cancelText = 'キャンセル',
  }) {
    return showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: Icons.delete_outline,
      iconColor: Colors.red,
      confirmButtonStyle: AppButtonStyles.danger(context),
    );
  }

  /// 警告ダイアログを表示
  static Future<bool?> showWarningDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '確認',
    String cancelText = 'キャンセル',
  }) {
    return showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: Icons.warning_outlined,
      iconColor: Colors.orange,
      confirmButtonStyle: AppButtonStyles.warning(context),
    );
  }

  /// 情報ダイアログを表示
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'OK',
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: title,
        icon: icon ?? Icons.info_outline,
        iconColor: iconColor ?? Colors.blue,
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppButtonStyles.primary(context),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
