import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../l10n/app_localizations.dart';

class WindowControlButtons extends StatefulWidget {
  final double iconSize;
  final EdgeInsetsGeometry? padding;

  const WindowControlButtons({super.key, this.iconSize = 18, this.padding});

  @override
  State<WindowControlButtons> createState() => _WindowControlButtonsState();
}

class _WindowControlButtonsState extends State<WindowControlButtons>
    with WindowListener {
  bool _isMaximized = false;

  bool get _isDesktopPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    if (_isDesktopPlatform) {
      windowManager.addListener(this);
      windowManager.isMaximized().then((value) {
        if (mounted) {
          setState(() => _isMaximized = value);
        }
      });
    }
  }

  @override
  void dispose() {
    if (_isDesktopPlatform) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) {
      setState(() => _isMaximized = true);
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) {
      setState(() => _isMaximized = false);
    }
  }

  @override
  void onWindowRestore() {
    if (mounted) {
      setState(() => _isMaximized = false);
    }
  }

  Future<void> _toggleWindowSize() async {
    if (!_isDesktopPlatform) return;
    final isMax = await windowManager.isMaximized();
    if (isMax) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopPlatform) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      IconButton(
        padding: widget.padding ?? EdgeInsets.zero,
        iconSize: widget.iconSize,
        tooltip: AppLocalizations.of(context)!.minimize,
        icon: const Icon(Icons.remove),
        onPressed: () async => windowManager.minimize(),
      ),
      IconButton(
        padding: widget.padding ?? EdgeInsets.zero,
        iconSize: widget.iconSize,
        tooltip: _isMaximized ? AppLocalizations.of(context)!.restoreWindow : AppLocalizations.of(context)!.maximize,
        icon: Icon(_isMaximized ? Icons.filter_none : Icons.crop_square),
        onPressed: _toggleWindowSize,
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
