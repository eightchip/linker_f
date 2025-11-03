import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

// レイアウト設定のデータクラス
class LayoutSettings {
  final int defaultCrossAxisCount;
  final double defaultGridSpacing;
  final double cardWidth;  // カードの幅（px）
  final double cardHeight; // カードの高さ（px）
  final double linkItemMargin;
  final double linkItemPadding;
  final double linkItemFontSize;
  final double linkItemIconSize;
  final double buttonSize;
  final bool autoAdjustLayout;


  LayoutSettings({
    this.defaultCrossAxisCount = 4,
    this.defaultGridSpacing = 8.0,
    this.cardWidth = 200.0,  // デフォルト幅
    this.cardHeight = 120.0, // デフォルト高さ
    this.linkItemMargin = 1.0,
    this.linkItemPadding = 2.0,
    this.linkItemFontSize = 9.0,
    this.linkItemIconSize = 18.0,
    this.buttonSize = 24.0,
    this.autoAdjustLayout = true,

  });

  LayoutSettings copyWith({
    int? defaultCrossAxisCount,
    double? defaultGridSpacing,
    double? cardWidth,
    double? cardHeight,
    double? linkItemMargin,
    double? linkItemPadding,
    double? linkItemFontSize,
    double? linkItemIconSize,
    double? buttonSize,
    bool? autoAdjustLayout,
  }) {
    return LayoutSettings(
      defaultCrossAxisCount: defaultCrossAxisCount ?? this.defaultCrossAxisCount,
      defaultGridSpacing: defaultGridSpacing ?? this.defaultGridSpacing,
      cardWidth: cardWidth ?? this.cardWidth,
      cardHeight: cardHeight ?? this.cardHeight,
      linkItemMargin: linkItemMargin ?? this.linkItemMargin,
      linkItemPadding: linkItemPadding ?? this.linkItemPadding,
      linkItemFontSize: linkItemFontSize ?? this.linkItemFontSize,
      linkItemIconSize: linkItemIconSize ?? this.linkItemIconSize,
      buttonSize: buttonSize ?? this.buttonSize,
      autoAdjustLayout: autoAdjustLayout ?? this.autoAdjustLayout,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultCrossAxisCount': defaultCrossAxisCount,
      'defaultGridSpacing': defaultGridSpacing,
      'cardWidth': cardWidth,
      'cardHeight': cardHeight,
      'linkItemMargin': linkItemMargin,
      'linkItemPadding': linkItemPadding,
      'linkItemFontSize': linkItemFontSize,
      'linkItemIconSize': linkItemIconSize,
      'buttonSize': buttonSize,
      'autoAdjustLayout': autoAdjustLayout,
    };
  }

  factory LayoutSettings.fromJson(Map<String, dynamic> json) {
    return LayoutSettings(
      defaultCrossAxisCount: json['defaultCrossAxisCount'] ?? 4,
      defaultGridSpacing: json['defaultGridSpacing']?.toDouble() ?? 8.0,
      cardWidth: json['cardWidth']?.toDouble() ?? 200.0,
      cardHeight: json['cardHeight']?.toDouble() ?? 120.0,
      linkItemMargin: json['linkItemMargin']?.toDouble() ?? 1.0,
      linkItemPadding: json['linkItemPadding']?.toDouble() ?? 2.0,
      linkItemFontSize: json['linkItemFontSize']?.toDouble() ?? 9.0,
      linkItemIconSize: json['linkItemIconSize']?.toDouble() ?? 18.0,
      buttonSize: json['buttonSize']?.toDouble() ?? 24.0,
      autoAdjustLayout: json['autoAdjustLayout'] ?? true,
    );
  }
}

// レイアウト設定のプロバイダー
class LayoutSettingsNotifier extends StateNotifier<LayoutSettings> {
  LayoutSettingsNotifier() : super(LayoutSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox('layoutSettings');
      final settingsJson = box.get('settings');
      if (settingsJson != null) {
        state = LayoutSettings.fromJson(Map<String, dynamic>.from(settingsJson));
      }
    } catch (e) {
      // デフォルト設定を使用
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = await Hive.openBox('layoutSettings');
      await box.put('settings', state.toJson());
    } catch (e) {
      // エラーハンドリング
    }
  }

  void updateSettings(LayoutSettings newSettings) {
    state = newSettings;
    _saveSettings();
  }

  void updateCrossAxisCount(int count) {
    state = state.copyWith(defaultCrossAxisCount: count);
    _saveSettings();
  }

  void updateGridSpacing(double spacing) {
    state = state.copyWith(defaultGridSpacing: spacing);
    _saveSettings();
  }

  void updateCardWidth(double width) {
    state = state.copyWith(cardWidth: width);
    _saveSettings();
  }

  void updateCardHeight(double height) {
    state = state.copyWith(cardHeight: height);
    _saveSettings();
  }

  void updateLinkItemMargin(double margin) {
    state = state.copyWith(linkItemMargin: margin);
    _saveSettings();
  }

  void updateLinkItemPadding(double padding) {
    state = state.copyWith(linkItemPadding: padding);
    _saveSettings();
  }

  void updateLinkItemFontSize(double fontSize) {
    state = state.copyWith(linkItemFontSize: fontSize);
    _saveSettings();
  }

  void updateLinkItemIconSize(double iconSize) {
    state = state.copyWith(linkItemIconSize: iconSize);
    _saveSettings();
  }

  void updateButtonSize(double buttonSize) {
    state = state.copyWith(buttonSize: buttonSize);
    _saveSettings();
  }

  void toggleAutoAdjustLayout() {
    state = state.copyWith(autoAdjustLayout: !state.autoAdjustLayout);
    _saveSettings();
  }

  void resetToDefaults() {
    state = LayoutSettings();
    _saveSettings();
  }

  // カスタムプリセットの保存
  Future<void> saveCustomPreset(String presetName, LayoutSettings preset) async {
    try {
      final box = await Hive.openBox('layoutSettings');
      final customPresets = Map<String, dynamic>.from(box.get('customPresets') ?? {});
      customPresets[presetName] = preset.toJson();
      await box.put('customPresets', customPresets);
    } catch (e) {
      // エラーハンドリング
    }
  }

  // カスタムプリセットの取得
  Future<Map<String, LayoutSettings>> getCustomPresets() async {
    try {
      final box = await Hive.openBox('layoutSettings');
      final customPresetsJson = box.get('customPresets');
      if (customPresetsJson != null) {
        final Map<String, dynamic> customPresets = Map<String, dynamic>.from(customPresetsJson);
        return customPresets.map((key, value) => MapEntry(key, LayoutSettings.fromJson(Map<String, dynamic>.from(value))));
      }
    } catch (e) {
      // エラーハンドリング
    }
    return {};
  }

  // カスタムプリセットの削除
  Future<void> deleteCustomPreset(String presetName) async {
    try {
      final box = await Hive.openBox('layoutSettings');
      final customPresets = Map<String, dynamic>.from(box.get('customPresets') ?? {});
      customPresets.remove(presetName);
      await box.put('customPresets', customPresets);
    } catch (e) {
      // エラーハンドリング
    }
  }
}

final layoutSettingsProvider = StateNotifierProvider<LayoutSettingsNotifier, LayoutSettings>(
  (ref) => LayoutSettingsNotifier(),
);

// タスクグリッドビュー用レイアウト設定のデータクラス
class TaskProjectLayoutSettings {
  final int defaultCrossAxisCount;
  final double defaultGridSpacing;
  final double cardWidth;  // カードの幅（px）
  final double cardHeight; // カードの高さ（px）
  final bool autoAdjustLayout;
  final bool autoAdjustCardHeight; // カード高さをコンテンツに応じて自動調整
  final double titleFontSize; // タイトルフォントサイズ（倍率）
  final double memoFontSize; // メモフォントサイズ（倍率）
  final double descriptionFontSize; // 説明フォントサイズ（倍率）

  TaskProjectLayoutSettings({
    this.defaultCrossAxisCount = 4,
    this.defaultGridSpacing = 8.0,
    this.cardWidth = 180.0,  // デフォルト幅（タスクグリッドビュー用）
    this.cardHeight = 160.0, // デフォルト高さ（タスクグリッドビュー用）
    this.autoAdjustLayout = true,
    this.autoAdjustCardHeight = false, // デフォルトはオフ
    this.titleFontSize = 1.0,
    this.memoFontSize = 1.0,
    this.descriptionFontSize = 1.0,
  });

  TaskProjectLayoutSettings copyWith({
    int? defaultCrossAxisCount,
    double? defaultGridSpacing,
    double? cardWidth,
    double? cardHeight,
    bool? autoAdjustLayout,
    bool? autoAdjustCardHeight,
    double? titleFontSize,
    double? memoFontSize,
    double? descriptionFontSize,
  }) {
    return TaskProjectLayoutSettings(
      defaultCrossAxisCount: defaultCrossAxisCount ?? this.defaultCrossAxisCount,
      defaultGridSpacing: defaultGridSpacing ?? this.defaultGridSpacing,
      cardWidth: cardWidth ?? this.cardWidth,
      cardHeight: cardHeight ?? this.cardHeight,
      autoAdjustLayout: autoAdjustLayout ?? this.autoAdjustLayout,
      autoAdjustCardHeight: autoAdjustCardHeight ?? this.autoAdjustCardHeight,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      memoFontSize: memoFontSize ?? this.memoFontSize,
      descriptionFontSize: descriptionFontSize ?? this.descriptionFontSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultCrossAxisCount': defaultCrossAxisCount,
      'defaultGridSpacing': defaultGridSpacing,
      'cardWidth': cardWidth,
      'cardHeight': cardHeight,
      'autoAdjustLayout': autoAdjustLayout,
      'autoAdjustCardHeight': autoAdjustCardHeight,
      'titleFontSize': titleFontSize,
      'memoFontSize': memoFontSize,
      'descriptionFontSize': descriptionFontSize,
    };
  }

  factory TaskProjectLayoutSettings.fromJson(Map<String, dynamic> json) {
    return TaskProjectLayoutSettings(
      defaultCrossAxisCount: json['defaultCrossAxisCount'] ?? 4,
      defaultGridSpacing: json['defaultGridSpacing']?.toDouble() ?? 8.0,
      cardWidth: json['cardWidth']?.toDouble() ?? 180.0,
      cardHeight: json['cardHeight']?.toDouble() ?? 160.0,
      autoAdjustLayout: json['autoAdjustLayout'] ?? true,
      autoAdjustCardHeight: json['autoAdjustCardHeight'] ?? false,
      titleFontSize: json['titleFontSize']?.toDouble() ?? 1.0,
      memoFontSize: json['memoFontSize']?.toDouble() ?? 1.0,
      descriptionFontSize: json['descriptionFontSize']?.toDouble() ?? 1.0,
    );
  }
}

// プロジェクト一覧用レイアウト設定のプロバイダー
class TaskProjectLayoutSettingsNotifier extends StateNotifier<TaskProjectLayoutSettings> {
  TaskProjectLayoutSettingsNotifier() : super(TaskProjectLayoutSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox('taskProjectLayoutSettings');
      final settingsJson = box.get('settings');
      if (settingsJson != null) {
        state = TaskProjectLayoutSettings.fromJson(Map<String, dynamic>.from(settingsJson));
      }
    } catch (e) {
      // デフォルト設定を使用
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = await Hive.openBox('taskProjectLayoutSettings');
      await box.put('settings', state.toJson());
    } catch (e) {
      // エラーハンドリング
    }
  }

  void updateSettings(TaskProjectLayoutSettings newSettings) {
    state = newSettings;
    _saveSettings();
  }

  void updateCrossAxisCount(int count) {
    state = state.copyWith(defaultCrossAxisCount: count);
    _saveSettings();
  }

  void updateGridSpacing(double spacing) {
    state = state.copyWith(defaultGridSpacing: spacing);
    _saveSettings();
  }

  void updateCardWidth(double width) {
    state = state.copyWith(cardWidth: width);
    _saveSettings();
  }

  void updateCardHeight(double height) {
    state = state.copyWith(cardHeight: height);
    _saveSettings();
  }

  void toggleAutoAdjustLayout() {
    state = state.copyWith(autoAdjustLayout: !state.autoAdjustLayout);
    _saveSettings();
  }

  void toggleAutoAdjustCardHeight() {
    state = state.copyWith(autoAdjustCardHeight: !state.autoAdjustCardHeight);
    _saveSettings();
  }

  void updateTitleFontSize(double fontSize) {
    state = state.copyWith(titleFontSize: fontSize);
    _saveSettings();
  }

  void updateMemoFontSize(double fontSize) {
    state = state.copyWith(memoFontSize: fontSize);
    _saveSettings();
  }

  void updateDescriptionFontSize(double fontSize) {
    state = state.copyWith(descriptionFontSize: fontSize);
    _saveSettings();
  }

  void resetToDefaults() {
    state = TaskProjectLayoutSettings();
    _saveSettings();
  }
}

final taskProjectLayoutSettingsProvider = StateNotifierProvider<TaskProjectLayoutSettingsNotifier, TaskProjectLayoutSettings>(
  (ref) => TaskProjectLayoutSettingsNotifier(),
);