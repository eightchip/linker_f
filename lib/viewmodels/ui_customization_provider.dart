import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// UIカスタマイズ設定のProvider
class UICustomizationNotifier extends StateNotifier<UICustomizationState> {
  final SettingsService _settingsService;

  UICustomizationNotifier(this._settingsService) : super(UICustomizationState.initial()) {
    _loadSettings();
  }

  /// 設定を読み込み
  void _loadSettings() {
    state = state.copyWith(
      cardBorderRadius: _settingsService.cardBorderRadius,
      cardElevation: _settingsService.cardElevation,
      cardPadding: _settingsService.cardPadding,
      buttonBorderRadius: _settingsService.buttonBorderRadius,
      buttonElevation: _settingsService.buttonElevation,
      inputBorderRadius: _settingsService.inputBorderRadius,
      inputBorderWidth: _settingsService.inputBorderWidth,
      animationDuration: _settingsService.animationDuration,
      hoverEffectIntensity: _settingsService.hoverEffectIntensity,
      shadowIntensity: _settingsService.shadowIntensity,
      gradientIntensity: _settingsService.gradientIntensity,
      uiDensity: _settingsService.uiDensity,
      iconSize: _settingsService.iconSize,
      spacing: _settingsService.spacing,
      autoContrastOptimization: _settingsService.autoContrastOptimization,
      darkModeContrastBoost: _settingsService.darkModeContrastBoost,
    );
  }

  /// カードの角丸半径を設定
  Future<void> setCardBorderRadius(double value) async {
    await _settingsService.setCardBorderRadius(value);
    state = state.copyWith(cardBorderRadius: value);
  }

  /// カードの影の強さを設定
  Future<void> setCardElevation(double value) async {
    await _settingsService.setCardElevation(value);
    state = state.copyWith(cardElevation: value);
  }

  /// カードのパディングを設定
  Future<void> setCardPadding(double value) async {
    await _settingsService.setCardPadding(value);
    state = state.copyWith(cardPadding: value);
  }

  /// ボタンの角丸半径を設定
  Future<void> setButtonBorderRadius(double value) async {
    await _settingsService.setButtonBorderRadius(value);
    state = state.copyWith(buttonBorderRadius: value);
  }

  /// ボタンの影の強さを設定
  Future<void> setButtonElevation(double value) async {
    await _settingsService.setButtonElevation(value);
    state = state.copyWith(buttonElevation: value);
  }

  /// 入力フィールドの角丸半径を設定
  Future<void> setInputBorderRadius(double value) async {
    await _settingsService.setInputBorderRadius(value);
    state = state.copyWith(inputBorderRadius: value);
  }

  /// 入力フィールドの枠線の太さを設定
  Future<void> setInputBorderWidth(double value) async {
    await _settingsService.setInputBorderWidth(value);
    state = state.copyWith(inputBorderWidth: value);
  }

  /// アニメーションの持続時間を設定
  Future<void> setAnimationDuration(int value) async {
    await _settingsService.setAnimationDuration(value);
    state = state.copyWith(animationDuration: value);
  }

  /// ホバー効果の強さを設定
  Future<void> setHoverEffectIntensity(double value) async {
    await _settingsService.setHoverEffectIntensity(value);
    state = state.copyWith(hoverEffectIntensity: value);
  }

  /// 影の強さを設定
  Future<void> setShadowIntensity(double value) async {
    await _settingsService.setShadowIntensity(value);
    state = state.copyWith(shadowIntensity: value);
  }

  /// グラデーションの強さを設定
  Future<void> setGradientIntensity(double value) async {
    await _settingsService.setGradientIntensity(value);
    state = state.copyWith(gradientIntensity: value);
  }

  /// UI密度を設定
  Future<void> setUiDensity(double value) async {
    await _settingsService.setUiDensity(value);
    state = state.copyWith(uiDensity: value);
  }

  /// アイコンサイズを設定
  Future<void> setIconSize(double value) async {
    await _settingsService.setIconSize(value);
    state = state.copyWith(iconSize: value);
  }

  /// 要素間のスペーシングを設定
  Future<void> setSpacing(double value) async {
    await _settingsService.setSpacing(value);
    state = state.copyWith(spacing: value);
  }

  /// 自動コントラスト最適化を設定
  Future<void> setAutoContrastOptimization(bool value) async {
    await _settingsService.setAutoContrastOptimization(value);
    state = state.copyWith(autoContrastOptimization: value);
  }

  /// ダークモードコントラストブーストを設定
  Future<void> setDarkModeContrastBoost(double value) async {
    await _settingsService.setDarkModeContrastBoost(value);
    state = state.copyWith(darkModeContrastBoost: value);
  }

  /// 全UI設定をリセット
  Future<void> resetAllSettings() async {
    await _settingsService.resetAllUISettings();
    _loadSettings();
  }

  /// 設定を再読み込み
  void refreshSettings() {
    _loadSettings();
  }
}

/// UIカスタマイズ設定の状態
class UICustomizationState {
  final double cardBorderRadius;
  final double cardElevation;
  final double cardPadding;
  final double buttonBorderRadius;
  final double buttonElevation;
  final double inputBorderRadius;
  final double inputBorderWidth;
  final int animationDuration;
  final double hoverEffectIntensity;
  final double shadowIntensity;
  final double gradientIntensity;
  final double uiDensity;
  final double iconSize;
  final double spacing;
  final bool autoContrastOptimization;
  final double darkModeContrastBoost;

  const UICustomizationState({
    required this.cardBorderRadius,
    required this.cardElevation,
    required this.cardPadding,
    required this.buttonBorderRadius,
    required this.buttonElevation,
    required this.inputBorderRadius,
    required this.inputBorderWidth,
    required this.animationDuration,
    required this.hoverEffectIntensity,
    required this.shadowIntensity,
    required this.gradientIntensity,
    required this.uiDensity,
    required this.iconSize,
    required this.spacing,
    required this.autoContrastOptimization,
    required this.darkModeContrastBoost,
  });

  factory UICustomizationState.initial() {
    return const UICustomizationState(
      cardBorderRadius: 16.0,
      cardElevation: 2.0,
      cardPadding: 16.0,
      buttonBorderRadius: 12.0,
      buttonElevation: 1.0,
      inputBorderRadius: 12.0,
      inputBorderWidth: 1.5,
      animationDuration: 300,
      hoverEffectIntensity: 0.1,
      shadowIntensity: 0.15,
      gradientIntensity: 0.05,
      uiDensity: 1.0,
      iconSize: 24.0,
      spacing: 8.0,
      autoContrastOptimization: true,
      darkModeContrastBoost: 1.2,
    );
  }

  UICustomizationState copyWith({
    double? cardBorderRadius,
    double? cardElevation,
    double? cardPadding,
    double? buttonBorderRadius,
    double? buttonElevation,
    double? inputBorderRadius,
    double? inputBorderWidth,
    int? animationDuration,
    double? hoverEffectIntensity,
    double? shadowIntensity,
    double? gradientIntensity,
    double? uiDensity,
    double? iconSize,
    double? spacing,
    bool? autoContrastOptimization,
    double? darkModeContrastBoost,
  }) {
    return UICustomizationState(
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      cardElevation: cardElevation ?? this.cardElevation,
      cardPadding: cardPadding ?? this.cardPadding,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      buttonElevation: buttonElevation ?? this.buttonElevation,
      inputBorderRadius: inputBorderRadius ?? this.inputBorderRadius,
      inputBorderWidth: inputBorderWidth ?? this.inputBorderWidth,
      animationDuration: animationDuration ?? this.animationDuration,
      hoverEffectIntensity: hoverEffectIntensity ?? this.hoverEffectIntensity,
      shadowIntensity: shadowIntensity ?? this.shadowIntensity,
      gradientIntensity: gradientIntensity ?? this.gradientIntensity,
      uiDensity: uiDensity ?? this.uiDensity,
      iconSize: iconSize ?? this.iconSize,
      spacing: spacing ?? this.spacing,
      autoContrastOptimization: autoContrastOptimization ?? this.autoContrastOptimization,
      darkModeContrastBoost: darkModeContrastBoost ?? this.darkModeContrastBoost,
    );
  }
}

/// UIカスタマイズ設定のProvider
final uiCustomizationProvider = StateNotifierProvider<UICustomizationNotifier, UICustomizationState>((ref) {
  return UICustomizationNotifier(SettingsService.instance);
});

/// 個別のUI設定Provider（便利なアクセス用）
final cardBorderRadiusProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).cardBorderRadius);
final cardElevationProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).cardElevation);
final cardPaddingProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).cardPadding);
final buttonBorderRadiusProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).buttonBorderRadius);
final buttonElevationProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).buttonElevation);
final inputBorderRadiusProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).inputBorderRadius);
final inputBorderWidthProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).inputBorderWidth);
final animationDurationProvider = Provider<int>((ref) => ref.watch(uiCustomizationProvider).animationDuration);
final hoverEffectIntensityProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).hoverEffectIntensity);
final shadowIntensityProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).shadowIntensity);
final gradientIntensityProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).gradientIntensity);
final uiDensityProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).uiDensity);
final iconSizeProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).iconSize);
final spacingProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).spacing);
final autoContrastOptimizationProvider = Provider<bool>((ref) => ref.watch(uiCustomizationProvider).autoContrastOptimization);
final darkModeContrastBoostProvider = Provider<double>((ref) => ref.watch(uiCustomizationProvider).darkModeContrastBoost);

/// ダークモードでの自動コントラスト最適化された色を取得
Color getOptimizedColorForDarkMode(
  Color baseColor,
  Color backgroundColor,
  bool isDarkMode,
  bool autoOptimization,
  double contrastBoost,
) {
  if (!isDarkMode || !autoOptimization) {
    return baseColor;
  }

  // 背景色の明度を計算
  final bgLuminance = backgroundColor.computeLuminance();
  
  // ベース色の明度を計算
  final baseLuminance = baseColor.computeLuminance();
  
  // コントラスト比を計算
  final contrastRatio = (baseLuminance + 0.05) / (bgLuminance + 0.05);
  
  // 最小コントラスト比（WCAG AA準拠）
  const minContrastRatio = 4.5;
  
  if (contrastRatio >= minContrastRatio) {
    return baseColor;
  }
  
  // HSL色空間に変換
  final hsl = HSLColor.fromColor(baseColor);
  
  // 明度を調整してコントラストを向上
  double adjustedLightness = hsl.lightness;
  
  if (bgLuminance < 0.5) {
    // ダーク背景の場合、テキストを明るくする
    adjustedLightness = (adjustedLightness * contrastBoost).clamp(0.0, 1.0);
  } else {
    // ライト背景の場合、テキストを暗くする
    adjustedLightness = (adjustedLightness / contrastBoost).clamp(0.0, 1.0);
  }
  
  // 彩度も微調整（色の鮮やかさを保持しつつ視認性を向上）
  double adjustedSaturation = hsl.saturation;
  if (adjustedLightness > 0.8 || adjustedLightness < 0.2) {
    adjustedSaturation = (adjustedSaturation * 0.9).clamp(0.0, 1.0);
  }
  
  return HSLColor.fromAHSL(
    hsl.alpha,
    hsl.hue,
    adjustedSaturation,
    adjustedLightness,
  ).toColor();
}

/// テキスト色の自動最適化
Color getOptimizedTextColor(
  Color baseColor,
  Color backgroundColor,
  bool isDarkMode,
  bool autoOptimization,
  double contrastBoost,
) {
  return getOptimizedColorForDarkMode(
    baseColor,
    backgroundColor,
    isDarkMode,
    autoOptimization,
    contrastBoost,
  );
}

/// アクセント色の自動最適化
Color getOptimizedAccentColor(
  Color baseColor,
  Color backgroundColor,
  bool isDarkMode,
  bool autoOptimization,
  double contrastBoost,
) {
  if (!isDarkMode || !autoOptimization) {
    return baseColor;
  }
  
  // アクセント色は少し控えめに調整
  final adjustedBoost = contrastBoost * 0.8;
  
  return getOptimizedColorForDarkMode(
    baseColor,
    backgroundColor,
    isDarkMode,
    autoOptimization,
    adjustedBoost,
  );
}
