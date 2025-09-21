import 'package:flutter_riverpod/flutter_riverpod.dart';
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
