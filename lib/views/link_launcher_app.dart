import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/font_size_provider.dart';
import '../services/keyboard_shortcut_service.dart';
import 'home_screen.dart';

class LinkLauncherApp extends ConsumerStatefulWidget {
  const LinkLauncherApp({super.key});

  @override
  ConsumerState<LinkLauncherApp> createState() => _LinkLauncherAppState();
}

class _LinkLauncherAppState extends ConsumerState<LinkLauncherApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // グローバルなナビゲーターキーを設定
    KeyboardShortcutService.setNavigatorKey(navigatorKey);
  }

  // 色の濃淡とコントラストを調整した色を取得
  Color _getAdjustedColor(int baseColor, double intensity, double contrast) {
    final color = Color(baseColor);
    
    // 濃淡調整
    final adjustedColor = Color.fromARGB(
      color.alpha,
      (color.red * intensity).clamp(0, 255).round(),
      (color.green * intensity).clamp(0, 255).round(),
      (color.blue * intensity).clamp(0, 255).round(),
    );
    
    // コントラスト調整
    final contrastColor = Color.fromARGB(
      adjustedColor.alpha,
      ((adjustedColor.red - 128) * contrast + 128).clamp(0, 255).round(),
      ((adjustedColor.green - 128) * contrast + 128).clamp(0, 255).round(),
      ((adjustedColor.blue - 128) * contrast + 128).clamp(0, 255).round(),
    );
    
    return contrastColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(darkModeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final colorContrast = ref.watch(colorContrastProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final textColor = ref.watch(textColorProvider);
    
    // 調整されたアクセントカラーを計算
    final adjustedAccentColor = _getAdjustedColor(accentColor, colorIntensity, colorContrast);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Link Navigator',
      debugShowCheckedModeBanner: false,
      // ちらつきを防ぐための設定
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // フォントサイズをアプリ全体に適用
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontSize),
          ),
          child: child!,
        );
      },

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: adjustedAccentColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
        ),
        // アニメーションを最小限にしてちらつきを防ぐ
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: adjustedAccentColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Color(0xFFF1F5F9),
          elevation: 0,
        ),
        // アニメーションを最小限にしてちらつきを防ぐ
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
} 