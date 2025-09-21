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
    
    // HSL色空間に変換
    final hsl = HSLColor.fromColor(color);
    
    // 濃淡調整: 明度を調整（0.5〜1.5の範囲で0.2〜0.8の明度にマッピング）
    final adjustedLightness = (0.2 + (intensity - 0.5) * 0.6).clamp(0.1, 0.9);
    
    // コントラスト調整: 彩度を調整（0.7〜1.5の範囲で0.3〜1.0の彩度にマッピング）
    final adjustedSaturation = (0.3 + (contrast - 0.7) * 0.875).clamp(0.1, 1.0);
    
    // 調整された色を返す
    return HSLColor.fromAHSL(
      color.alpha / 255.0,
      hsl.hue,
      adjustedSaturation,
      adjustedLightness,
    ).toColor();
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(darkModeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final textColor = ref.watch(textColorProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final colorContrast = ref.watch(colorContrastProvider);
    
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
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // 元の白い背景色に固定
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
        scaffoldBackgroundColor: const Color(0xFF0F172A), // 元の黒い背景色に固定
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