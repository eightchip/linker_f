import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// 設定管理サービス
class SettingsService {
  static const String _settingsBoxName = 'settings';
  static const String _defaultSettingsBoxName = 'default_settings';
  
  late Box _settingsBox;
  late Box _defaultSettingsBox;
  
  // シングルトンインスタンス
  static SettingsService? _instance;
  
  // プライベートコンストラクタ
  SettingsService._();
  
  // シングルトンインスタンスを取得
  static SettingsService get instance {
    _instance ??= SettingsService._();
    return _instance!;
  }
  
  // 設定キー
  static const String _darkModeKey = 'darkMode';
  static const String _fontSizeKey = 'fontSize';
  static const String _accentColorKey = 'accentColor';
  static const String _windowWidthKey = 'windowWidth';
  static const String _windowHeightKey = 'windowHeight';
  static const String _windowXKey = 'windowX';
  static const String _windowYKey = 'windowY';
  static const String _autoBackupKey = 'autoBackup';
  static const String _backupIntervalKey = 'backupInterval';
  static const String _additionalBackupPathKey = 'additionalBackupPath';
  static const String _showNotificationsKey = 'showNotifications';
  static const String _notificationSoundKey = 'notificationSound';
  static const String _searchHistoryKey = 'searchHistory';
  static const String _lastBackupKey = 'lastBackup';
  static const String _versionKey = 'version';
  static const String _taskFilterStatusesKey = 'taskFilterStatuses';
  static const String _taskFilterPriorityKey = 'taskFilterPriority';
  static const String _taskSortOrdersKey = 'taskSortOrders';
  static const String _taskSearchQueryKey = 'taskSearchQuery';
  static const String _googleCalendarEnabledKey = 'googleCalendarEnabled';
  static const String _googleCalendarSyncIntervalKey = 'googleCalendarSyncInterval';
  static const String _googleCalendarLastSyncKey = 'googleCalendarLastSync';
  static const String _googleCalendarAutoSyncKey = 'googleCalendarAutoSync';
  static const String _googleCalendarBidirectionalSyncKey = 'googleCalendarBidirectionalSync';
  static const String _googleCalendarShowCompletedTasksKey = 'googleCalendarShowCompletedTasks';
  static const String _gmailApiEnabledKey = 'gmailApiEnabled';
  static const String _outlookAutoSyncEnabledKey = 'outlookAutoSyncEnabled';
  static const String _outlookAutoSyncPeriodDaysKey = 'outlookAutoSyncPeriodDays';
  static const String _outlookAutoSyncFrequencyKey = 'outlookAutoSyncFrequency';
  static const String _textColorKey = 'textColor';
  static const String _colorIntensityKey = 'colorIntensity';
  static const String _colorContrastKey = 'colorContrast';
  static const String _titleTextColorKey = 'titleTextColor';
  static const String _titleFontSizeKey = 'titleFontSize';
  static const String _titleFontFamilyKey = 'titleFontFamily';
  static const String _memoTextColorKey = 'memoTextColor';
  static const String _memoFontSizeKey = 'memoFontSize';
  static const String _memoFontFamilyKey = 'memoFontFamily';
  static const String _descriptionTextColorKey = 'descriptionTextColor';
  static const String _descriptionFontSizeKey = 'descriptionFontSize';
  static const String _descriptionFontFamilyKey = 'descriptionFontFamily';
  static const String _startWithTaskScreenKey = 'startWithTaskScreen';
  
  // UIカスタマイズ設定キー
  static const String _cardBorderRadiusKey = 'cardBorderRadius';
  static const String _cardElevationKey = 'cardElevation';
  static const String _cardPaddingKey = 'cardPadding';
  static const String _buttonBorderRadiusKey = 'buttonBorderRadius';
  static const String _buttonElevationKey = 'buttonElevation';
  static const String _inputBorderRadiusKey = 'inputBorderRadius';
  static const String _inputBorderWidthKey = 'inputBorderWidth';
  static const String _animationDurationKey = 'animationDuration';
  static const String _hoverEffectIntensityKey = 'hoverEffectIntensity';
  static const String _shadowIntensityKey = 'shadowIntensity';
  static const String _gradientIntensityKey = 'gradientIntensity';
  static const String _uiDensityKey = 'uiDensity';
  static const String _iconSizeKey = 'iconSize';
  static const String _spacingKey = 'spacing';
  static const String _autoContrastOptimizationKey = 'autoContrastOptimization';
  static const String _darkModeContrastBoostKey = 'darkModeContrastBoost';

  // デフォルト値
  static const bool _defaultDarkMode = false;
  static const double _defaultFontSize = 1.0;
  static const int _defaultAccentColor = 0xFF1E40AF; // 鮮明なブルー色
  static const int _defaultTextColor = 0xFF000000;
  static const double _defaultColorIntensity = 1.0;
  static const double _defaultColorContrast = 1.0;
  static const int _defaultTitleTextColor = 0xFF000000;
  static const double _defaultTitleFontSize = 1.0;
  static const String _defaultTitleFontFamily = '';
  static const int _defaultMemoTextColor = 0xFF000000;
  static const double _defaultMemoFontSize = 1.0;
  static const String _defaultMemoFontFamily = '';
  static const int _defaultDescriptionTextColor = 0xFF000000;
  static const double _defaultDescriptionFontSize = 1.0;
  static const String _defaultDescriptionFontFamily = '';
  static const bool _defaultStartWithTaskScreen = false;
  
  // UIカスタマイズデフォルト値
  static const double _defaultCardBorderRadius = 16.0;
  static const double _defaultCardElevation = 2.0;
  static const double _defaultCardPadding = 16.0;
  static const double _defaultButtonBorderRadius = 12.0;
  static const double _defaultButtonElevation = 1.0;
  static const double _defaultInputBorderRadius = 12.0;
  static const double _defaultInputBorderWidth = 1.5;
  static const int _defaultAnimationDuration = 300; // ミリ秒
  static const double _defaultHoverEffectIntensity = 0.1;
  static const double _defaultShadowIntensity = 0.15;
  static const double _defaultGradientIntensity = 0.05;
  static const double _defaultUiDensity = 1.0;
  static const double _defaultIconSize = 24.0;
  static const double _defaultSpacing = 8.0;
  static const bool _defaultAutoContrastOptimization = true;
  static const double _defaultDarkModeContrastBoost = 1.2;
  
  static const double _defaultWindowWidth = 800.0;
  static const double _defaultWindowHeight = 600.0;
  static const double _defaultWindowX = 100.0;
  static const double _defaultWindowY = 100.0;
  static const bool _defaultAutoBackup = true;
  static const int _defaultBackupInterval = 7; // 日数
  static const bool _defaultShowNotifications = true;
  static const bool _defaultNotificationSound = true;
  static const int _currentVersion = 1;
  static const List<String> _defaultTaskFilterStatuses = ['all'];
  static const String _defaultTaskFilterPriority = 'all';
  static const List<Map<String, String>> _defaultTaskSortOrders = [{'field': 'dueDate', 'order': 'asc'}];
  static const bool _defaultGoogleCalendarEnabled = false;
  static const int _defaultGoogleCalendarSyncInterval = 60; // 分
  static const bool _defaultGoogleCalendarAutoSync = false;
  static const bool _defaultGoogleCalendarBidirectionalSync = false;
  static const bool _defaultGoogleCalendarShowCompletedTasks = true;
  static const bool _defaultGmailApiEnabled = false;
  static const bool _defaultOutlookAutoSyncEnabled = false;
  static const int _defaultOutlookAutoSyncPeriodDays = 30; // 1ヶ月
  static const String _defaultOutlookAutoSyncFrequency = 'on_startup'; // 'on_startup', '30min', '1hour', 'daily_9am'

  /// 初期化（リトライ機能付き）
  Future<void> initialize() async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 500);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('SettingsService初期化試行 $attempt/$maxRetries');
        
        _settingsBox = await Hive.openBox(_settingsBoxName);
        _defaultSettingsBox = await Hive.openBox(_defaultSettingsBoxName);
        
        // 初回起動時のデフォルト設定を保存
        await _initializeDefaultSettings();
        
        // バージョン管理
        await _handleVersionMigration();
        
        print('SettingsService初期化成功');
        return;
      } catch (e) {
        print('SettingsService初期化エラー (試行 $attempt/$maxRetries): $e');
        
        if (attempt == maxRetries) {
          print('SettingsService初期化失敗: 最大リトライ回数に達しました');
          // 最後の試行でも失敗した場合は、デフォルト値で継続
          _initializeWithDefaults();
          return;
        }
        
        // リトライ前に少し待機
        await Future.delayed(retryDelay * attempt);
      }
    }
  }
  
  /// デフォルト値で初期化（フォールバック）
  void _initializeWithDefaults() {
    print('SettingsService: デフォルト値で初期化');
    // デフォルト値を使用してアプリケーションを継続
    // 実際のBoxは後で再試行される
  }

  /// 初期化状態をチェック
  bool get isInitialized {
    try {
      return _settingsBox.isOpen && _defaultSettingsBox.isOpen;
    } catch (e) {
      print('SettingsService初期化状態チェックエラー: $e');
      return false;
    }
  }
  
  /// 安全な設定値取得
  T _getSetting<T>(String key, T defaultValue) {
    try {
      if (!isInitialized) {
        print('SettingsService未初期化: デフォルト値を使用 ($key)');
        return defaultValue;
      }
      return _settingsBox.get(key, defaultValue: defaultValue) as T;
    } catch (e) {
      print('設定値取得エラー ($key): $e');
      return defaultValue;
    }
  }
  
  /// 安全な設定値保存
  Future<void> _setSetting<T>(String key, T value) async {
    try {
      if (!isInitialized) {
        print('SettingsService未初期化: 設定保存をスキップ ($key)');
        return;
      }
      await _settingsBox.put(key, value);
    } catch (e) {
      print('設定値保存エラー ($key): $e');
    }
  }

  /// デフォルト設定の初期化
  Future<void> _initializeDefaultSettings() async {
    if (!_defaultSettingsBox.containsKey(_versionKey)) {
      await _defaultSettingsBox.put(_darkModeKey, _defaultDarkMode);
      await _defaultSettingsBox.put(_fontSizeKey, _defaultFontSize);
      await _defaultSettingsBox.put(_accentColorKey, _defaultAccentColor);
      await _defaultSettingsBox.put(_textColorKey, _defaultTextColor);
      await _defaultSettingsBox.put(_colorIntensityKey, _defaultColorIntensity);
      await _defaultSettingsBox.put(_colorContrastKey, _defaultColorContrast);
      await _defaultSettingsBox.put(_windowWidthKey, _defaultWindowWidth);
      await _defaultSettingsBox.put(_windowHeightKey, _defaultWindowHeight);
      await _defaultSettingsBox.put(_windowXKey, _defaultWindowX);
      await _defaultSettingsBox.put(_windowYKey, _defaultWindowY);
      await _defaultSettingsBox.put(_autoBackupKey, _defaultAutoBackup);
      await _defaultSettingsBox.put(_backupIntervalKey, _defaultBackupInterval);
      await _defaultSettingsBox.put(_showNotificationsKey, _defaultShowNotifications);
      await _defaultSettingsBox.put(_notificationSoundKey, _defaultNotificationSound);
      await _defaultSettingsBox.put(_taskFilterStatusesKey, _defaultTaskFilterStatuses);
      await _defaultSettingsBox.put(_taskFilterPriorityKey, _defaultTaskFilterPriority);
      await _defaultSettingsBox.put(_taskSortOrdersKey, _defaultTaskSortOrders);
      await _defaultSettingsBox.put(_startWithTaskScreenKey, _defaultStartWithTaskScreen);
      await _defaultSettingsBox.put(_versionKey, _currentVersion);
    }
  }

  /// バージョン管理とマイグレーション
  Future<void> _handleVersionMigration() async {
    final currentVersion = _settingsBox.get(_versionKey, defaultValue: 0) as int;
    
    if (currentVersion < _currentVersion) {
      if (kDebugMode) {
        print('設定のバージョンアップデート: $currentVersion → $_currentVersion');
      }
      
      // バージョン1へのマイグレーション
      if (currentVersion < 1) {
        await _migrateToVersion1();
      }
      
      await _settingsBox.put(_versionKey, _currentVersion);
    }
  }

  /// バージョン1へのマイグレーション
  Future<void> _migrateToVersion1() async {
    // 新しい設定項目の追加
    if (!_settingsBox.containsKey(_autoBackupKey)) {
      await _settingsBox.put(_autoBackupKey, _defaultAutoBackup);
    }
    if (!_settingsBox.containsKey(_backupIntervalKey)) {
      await _settingsBox.put(_backupIntervalKey, _defaultBackupInterval);
    }
    if (!_settingsBox.containsKey(_showNotificationsKey)) {
      await _settingsBox.put(_showNotificationsKey, _defaultShowNotifications);
    }
    if (!_settingsBox.containsKey(_notificationSoundKey)) {
      await _settingsBox.put(_notificationSoundKey, _defaultNotificationSound);
    }
    if (!_settingsBox.containsKey(_textColorKey)) {
      await _settingsBox.put(_textColorKey, _defaultTextColor);
    }
    if (!_settingsBox.containsKey(_titleTextColorKey)) {
      await _settingsBox.put(_titleTextColorKey, _defaultTitleTextColor);
    }
    if (!_settingsBox.containsKey(_titleFontSizeKey)) {
      await _settingsBox.put(_titleFontSizeKey, _defaultTitleFontSize);
    }
    if (!_settingsBox.containsKey(_titleFontFamilyKey)) {
      await _settingsBox.put(_titleFontFamilyKey, _defaultTitleFontFamily);
    }
    if (!_settingsBox.containsKey(_memoTextColorKey)) {
      await _settingsBox.put(_memoTextColorKey, _defaultMemoTextColor);
    }
    if (!_settingsBox.containsKey(_memoFontSizeKey)) {
      await _settingsBox.put(_memoFontSizeKey, _defaultMemoFontSize);
    }
    if (!_settingsBox.containsKey(_memoFontFamilyKey)) {
      await _settingsBox.put(_memoFontFamilyKey, _defaultMemoFontFamily);
    }
    if (!_settingsBox.containsKey(_descriptionTextColorKey)) {
      await _settingsBox.put(_descriptionTextColorKey, _defaultDescriptionTextColor);
    }
    if (!_settingsBox.containsKey(_descriptionFontSizeKey)) {
      await _settingsBox.put(_descriptionFontSizeKey, _defaultDescriptionFontSize);
    }
    if (!_settingsBox.containsKey(_descriptionFontFamilyKey)) {
      await _settingsBox.put(_descriptionFontFamilyKey, _defaultDescriptionFontFamily);
    }
    if (!_settingsBox.containsKey(_startWithTaskScreenKey)) {
      await _settingsBox.put(_startWithTaskScreenKey, _defaultStartWithTaskScreen);
    }
  }

  // ==================== 基本設定 ====================
  
  /// ダークモード設定
  bool get darkMode => _settingsBox.get(_darkModeKey, defaultValue: _defaultDarkMode) as bool;
  Future<void> setDarkMode(bool value) async {
    await _settingsBox.put(_darkModeKey, value);
  }

  /// フォントサイズ設定
  double get fontSize => _settingsBox.get(_fontSizeKey, defaultValue: _defaultFontSize) as double;
  Future<void> setFontSize(double value) async {
    await _settingsBox.put(_fontSizeKey, value);
  }

  /// アクセントカラー設定
  int get accentColor => _settingsBox.get(_accentColorKey, defaultValue: _defaultAccentColor) as int;
  Future<void> setAccentColor(int value) async {
    await _settingsBox.put(_accentColorKey, value);
  }

  /// テキスト色設定
  int get textColor => _settingsBox.get(_textColorKey, defaultValue: _defaultTextColor) as int;
  Future<void> setTextColor(int value) async {
    await _settingsBox.put(_textColorKey, value);
  }

  /// 色の濃淡設定
  double get colorIntensity => _settingsBox.get(_colorIntensityKey, defaultValue: _defaultColorIntensity) as double;
  Future<void> setColorIntensity(double value) async {
    await _settingsBox.put(_colorIntensityKey, value);
  }

  /// コントラスト設定
  double get colorContrast => _settingsBox.get(_colorContrastKey, defaultValue: _defaultColorContrast) as double;
  Future<void> setColorContrast(double value) async {
    await _settingsBox.put(_colorContrastKey, value);
  }

  /// タイトルテキスト色設定
  int get titleTextColor => _settingsBox.get(_titleTextColorKey, defaultValue: _defaultTitleTextColor) as int;
  Future<void> setTitleTextColor(int value) async {
    await _settingsBox.put(_titleTextColorKey, value);
  }

  /// タイトルフォントサイズ設定
  double get titleFontSize => _settingsBox.get(_titleFontSizeKey, defaultValue: _defaultTitleFontSize) as double;
  Future<void> setTitleFontSize(double value) async {
    await _settingsBox.put(_titleFontSizeKey, value);
  }

  /// タイトルフォントファミリー設定
  String get titleFontFamily => _settingsBox.get(_titleFontFamilyKey, defaultValue: _defaultTitleFontFamily) as String;
  Future<void> setTitleFontFamily(String value) async {
    await _settingsBox.put(_titleFontFamilyKey, value);
  }

  /// メモテキスト色設定
  int get memoTextColor => _settingsBox.get(_memoTextColorKey, defaultValue: _defaultMemoTextColor) as int;
  Future<void> setMemoTextColor(int value) async {
    await _settingsBox.put(_memoTextColorKey, value);
  }

  /// メモフォントサイズ設定
  double get memoFontSize => _settingsBox.get(_memoFontSizeKey, defaultValue: _defaultMemoFontSize) as double;
  Future<void> setMemoFontSize(double value) async {
    await _settingsBox.put(_memoFontSizeKey, value);
  }

  /// メモフォントファミリー設定
  String get memoFontFamily => _settingsBox.get(_memoFontFamilyKey, defaultValue: _defaultMemoFontFamily) as String;
  Future<void> setMemoFontFamily(String value) async {
    await _settingsBox.put(_memoFontFamilyKey, value);
  }

  /// 説明テキスト色設定
  int get descriptionTextColor => _settingsBox.get(_descriptionTextColorKey, defaultValue: _defaultDescriptionTextColor) as int;
  Future<void> setDescriptionTextColor(int value) async {
    await _settingsBox.put(_descriptionTextColorKey, value);
  }

  /// 説明フォントサイズ設定
  double get descriptionFontSize => _settingsBox.get(_descriptionFontSizeKey, defaultValue: _defaultDescriptionFontSize) as double;
  Future<void> setDescriptionFontSize(double value) async {
    await _settingsBox.put(_descriptionFontSizeKey, value);
  }

  /// 説明フォントファミリー設定
  String get descriptionFontFamily => _settingsBox.get(_descriptionFontFamilyKey, defaultValue: _defaultDescriptionFontFamily) as String;
  Future<void> setDescriptionFontFamily(String value) async {
    await _settingsBox.put(_descriptionFontFamilyKey, value);
  }

  /// タスク画面で起動する設定
  bool get startWithTaskScreen => _settingsBox.get(_startWithTaskScreenKey, defaultValue: _defaultStartWithTaskScreen) as bool;
  Future<void> setStartWithTaskScreen(bool value) async {
    await _settingsBox.put(_startWithTaskScreenKey, value);
  }

  // ==================== ウィンドウ設定 ====================
  
  /// ウィンドウ幅
  double get windowWidth => _settingsBox.get(_windowWidthKey, defaultValue: _defaultWindowWidth) as double;
  Future<void> setWindowWidth(double value) async {
    await _settingsBox.put(_windowWidthKey, value);
  }

  /// ウィンドウ高さ
  double get windowHeight => _settingsBox.get(_windowHeightKey, defaultValue: _defaultWindowHeight) as double;
  Future<void> setWindowHeight(double value) async {
    await _settingsBox.put(_windowHeightKey, value);
  }

  /// ウィンドウX座標
  double get windowX => _settingsBox.get(_windowXKey, defaultValue: _defaultWindowX) as double;
  Future<void> setWindowX(double value) async {
    await _settingsBox.put(_windowXKey, value);
  }

  /// ウィンドウY座標
  double get windowY => _settingsBox.get(_windowYKey, defaultValue: _defaultWindowY) as double;
  Future<void> setWindowY(double value) async {
    await _settingsBox.put(_windowYKey, value);
  }

  // ==================== バックアップ設定 ====================
  
  /// 自動バックアップ設定
  bool get autoBackup => _settingsBox.get(_autoBackupKey, defaultValue: _defaultAutoBackup) as bool;
  Future<void> setAutoBackup(bool value) async {
    await _settingsBox.put(_autoBackupKey, value);
  }

  /// バックアップ間隔（日数）
  int get backupInterval => _settingsBox.get(_backupIntervalKey, defaultValue: _defaultBackupInterval) as int;
  Future<void> setBackupInterval(int value) async {
    await _settingsBox.put(_backupIntervalKey, value);
  }

  /// 最後のバックアップ日時
  DateTime? get lastBackup {
    final timestamp = _settingsBox.get(_lastBackupKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp as int) : null;
  }
  Future<void> setLastBackup(DateTime value) async {
    await _settingsBox.put(_lastBackupKey, value.millisecondsSinceEpoch);
  }

  /// 追加のバックアップ保存先パス（複数場所への保存用）
  String? get additionalBackupPath {
    final path = _settingsBox.get(_additionalBackupPathKey);
    return path != null ? path as String : null;
  }
  Future<void> setAdditionalBackupPath(String? value) async {
    if (value == null || value.isEmpty) {
      await _settingsBox.delete(_additionalBackupPathKey);
    } else {
      await _settingsBox.put(_additionalBackupPathKey, value);
    }
  }

  // ==================== 通知設定 ====================
  
  /// 通知表示設定
  bool get showNotifications => _settingsBox.get(_showNotificationsKey, defaultValue: _defaultShowNotifications) as bool;
  Future<void> setShowNotifications(bool value) async {
    await _settingsBox.put(_showNotificationsKey, value);
  }

  /// 通知音設定
  bool get notificationSound => _settingsBox.get(_notificationSoundKey, defaultValue: _defaultNotificationSound) as bool;
  Future<void> setNotificationSound(bool value) async {
    await _settingsBox.put(_notificationSoundKey, value);
  }

  // ==================== UI設定 ====================
  

  /// 検索履歴
  List<String> get searchHistory {
    final history = _settingsBox.get(_searchHistoryKey);
    return history != null ? List<String>.from(history as List) : [];
  }
  Future<void> setSearchHistory(List<String> value) async {
    await _settingsBox.put(_searchHistoryKey, value);
  }

  /// 検索履歴に追加
  Future<void> addSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final history = searchHistory;
    history.remove(query); // 重複を削除
    history.insert(0, query); // 先頭に追加
    
    // 最大20件まで保持
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    
    await setSearchHistory(history);
  }

  /// 検索履歴をクリア
  Future<void> clearSearchHistory() async {
    await _settingsBox.delete(_searchHistoryKey);
  }


  // ==================== タスクフィルター設定 ====================
  
  /// タスクフィルターステータス
  List<String> get taskFilterStatuses {
    final statuses = _settingsBox.get(_taskFilterStatusesKey);
    return statuses != null ? List<String>.from(statuses as List) : _defaultTaskFilterStatuses;
  }
  Future<void> setTaskFilterStatuses(List<String> value) async {
    await _settingsBox.put(_taskFilterStatusesKey, value);
  }

  String get taskSearchQuery {
    return _settingsBox.get(_taskSearchQueryKey, defaultValue: '');
  }
  Future<void> setTaskSearchQuery(String value) async {
    await _settingsBox.put(_taskSearchQueryKey, value);
  }

  /// タスクフィルタープライオリティ
  String get taskFilterPriority => _settingsBox.get(_taskFilterPriorityKey, defaultValue: _defaultTaskFilterPriority) as String;
  Future<void> setTaskFilterPriority(String value) async {
    await _settingsBox.put(_taskFilterPriorityKey, value);
  }

  /// タスクソート順序
  List<Map<String, String>> get taskSortOrders {
    final orders = _settingsBox.get(_taskSortOrdersKey);
    if (orders != null) {
      return List<Map<String, String>>.from(
        (orders as List).map((item) => Map<String, String>.from(item as Map))
      );
    }
    return List<Map<String, String>>.from(
      _defaultTaskSortOrders.map((item) => Map<String, String>.from(item))
    );
  }
  Future<void> setTaskSortOrders(List<Map<String, String>> value) async {
    await _settingsBox.put(_taskSortOrdersKey, value);
  }

  // ==================== ユーティリティ ====================
  
  /// 設定をリセット
  Future<void> resetToDefaults() async {
    await _settingsBox.clear();
    await _initializeDefaultSettings();
  }

  /// 特定の設定をリセット
  Future<void> resetSetting(String key) async {
    final defaultValue = _defaultSettingsBox.get(key);
    if (defaultValue != null) {
      await _settingsBox.put(key, defaultValue);
    }
  }

  /// すべての設定を取得
  Map<String, dynamic> getAllSettings() {
    final settings = <String, dynamic>{};
    for (final key in _settingsBox.keys) {
      settings[key] = _settingsBox.get(key);
    }
    return settings;
  }

  /// 設定を一括更新
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      await _settingsBox.put(entry.key, entry.value);
    }
  }

  /// 設定のエクスポート
  Map<String, dynamic> exportSettings() {
    return {
      'settings': getAllSettings(),
      'defaults': _getAllDefaultSettings(),
      'version': _currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// 設定のインポート
  Future<void> importSettings(Map<String, dynamic> data) async {
    if (data['settings'] is Map) {
      final settings = data['settings'] as Map;
      await updateSettings(Map<String, dynamic>.from(settings));
    }
  }

  /// デフォルト設定をすべて取得
  Map<String, dynamic> _getAllDefaultSettings() {
    final defaults = <String, dynamic>{};
    for (final key in _defaultSettingsBox.keys) {
      defaults[key] = _defaultSettingsBox.get(key);
    }
    return defaults;
  }

  /// 設定の検証
  bool validateSettings() {
    try {
      // 基本的な型チェック
      final darkMode = this.darkMode;
      final fontSize = this.fontSize;
      final accentColor = this.accentColor;
      
      return fontSize is double && 
             fontSize > 0;
    } catch (e) {
      if (kDebugMode) {
        print('設定の検証エラー: $e');
      }
      return false;
    }
  }

  /// リソースを解放
  Future<void> dispose() async {
    await _settingsBox.close();
    await _defaultSettingsBox.close();
  }

  // Google Calendar関連の設定
  
  /// Google Calendar連携が有効かどうか
  bool get googleCalendarEnabled {
    return _settingsBox.get(_googleCalendarEnabledKey, defaultValue: _defaultGoogleCalendarEnabled);
  }
  
  /// Google Calendar連携の有効/無効を設定
  Future<void> setGoogleCalendarEnabled(bool value) async {
    await _settingsBox.put(_googleCalendarEnabledKey, value);
  }
  
  /// Google Calendar同期間隔（分）
  int get googleCalendarSyncInterval {
    return _settingsBox.get(_googleCalendarSyncIntervalKey, defaultValue: _defaultGoogleCalendarSyncInterval);
  }
  
  /// Google Calendar同期間隔を設定
  Future<void> setGoogleCalendarSyncInterval(int value) async {
    await _settingsBox.put(_googleCalendarSyncIntervalKey, value);
  }
  
  /// Google Calendar自動同期が有効かどうか
  bool get googleCalendarAutoSync {
    return _settingsBox.get(_googleCalendarAutoSyncKey, defaultValue: _defaultGoogleCalendarAutoSync);
  }
  
  /// Google Calendar自動同期の有効/無効を設定
  Future<void> setGoogleCalendarAutoSync(bool value) async {
    await _settingsBox.put(_googleCalendarAutoSyncKey, value);
  }

  /// Google Calendar双方向同期の有効/無効を取得
  bool get googleCalendarBidirectionalSync {
    return _settingsBox.get(_googleCalendarBidirectionalSyncKey, defaultValue: _defaultGoogleCalendarBidirectionalSync);
  }
  
  /// Google Calendar双方向同期の有効/無効を設定
  Future<void> setGoogleCalendarBidirectionalSync(bool value) async {
    await _settingsBox.put(_googleCalendarBidirectionalSyncKey, value);
  }
  
  /// Google Calendar最終同期時刻
  DateTime? get googleCalendarLastSync {
    final timestamp = _settingsBox.get(_googleCalendarLastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  /// Google Calendar最終同期時刻を設定
  Future<void> setGoogleCalendarLastSync(DateTime value) async {
    await _settingsBox.put(_googleCalendarLastSyncKey, value.millisecondsSinceEpoch);
  }

  /// Google Calendar完了タスク表示設定を取得
  bool get googleCalendarShowCompletedTasks {
    return _settingsBox.get(_googleCalendarShowCompletedTasksKey, defaultValue: _defaultGoogleCalendarShowCompletedTasks);
  }
  
  /// Google Calendar完了タスク表示設定を設定
  Future<void> setGoogleCalendarShowCompletedTasks(bool value) async {
    await _settingsBox.put(_googleCalendarShowCompletedTasksKey, value);
  }

  /// Gmail連携が有効かどうか
  bool get gmailApiEnabled {
    return _settingsBox.get(_gmailApiEnabledKey, defaultValue: _defaultGmailApiEnabled);
  }
  
  /// Gmail連携の有効/無効を設定
  Future<void> setGmailApiEnabled(bool value) async {
    await _settingsBox.put(_gmailApiEnabledKey, value);
  }

  // ==================== Outlook自動取込設定 ====================
  
  /// Outlook自動取込が有効かどうか
  bool get outlookAutoSyncEnabled {
    return _settingsBox.get(_outlookAutoSyncEnabledKey, defaultValue: _defaultOutlookAutoSyncEnabled);
  }
  
  /// Outlook自動取込の有効/無効を設定
  Future<void> setOutlookAutoSyncEnabled(bool value) async {
    await _settingsBox.put(_outlookAutoSyncEnabledKey, value);
  }
  
  /// Outlook自動取込期間（日数）
  int get outlookAutoSyncPeriodDays {
    return _settingsBox.get(_outlookAutoSyncPeriodDaysKey, defaultValue: _defaultOutlookAutoSyncPeriodDays);
  }
  
  /// Outlook自動取込期間を設定
  Future<void> setOutlookAutoSyncPeriodDays(int value) async {
    await _settingsBox.put(_outlookAutoSyncPeriodDaysKey, value);
  }
  
  /// Outlook自動取込頻度
  /// 'on_startup': アプリ起動時のみ
  /// '30min': 30分ごと
  /// '1hour': 1時間ごと
  /// 'daily_9am': 毎朝9:00
  String get outlookAutoSyncFrequency {
    return _settingsBox.get(_outlookAutoSyncFrequencyKey, defaultValue: _defaultOutlookAutoSyncFrequency);
  }
  
  /// Outlook自動取込頻度を設定
  Future<void> setOutlookAutoSyncFrequency(String value) async {
    await _settingsBox.put(_outlookAutoSyncFrequencyKey, value);
  }

  // UIカスタマイズ設定のgetterとsetter
  
  /// カードの角丸半径
  double get cardBorderRadius {
    return _settingsBox.get(_cardBorderRadiusKey, defaultValue: _defaultCardBorderRadius);
  }
  
  /// カードの角丸半径を設定
  Future<void> setCardBorderRadius(double value) async {
    await _settingsBox.put(_cardBorderRadiusKey, value);
  }
  
  /// カードの影の強さ
  double get cardElevation {
    return _settingsBox.get(_cardElevationKey, defaultValue: _defaultCardElevation);
  }
  
  /// カードの影の強さを設定
  Future<void> setCardElevation(double value) async {
    await _settingsBox.put(_cardElevationKey, value);
  }
  
  /// カードのパディング
  double get cardPadding {
    return _settingsBox.get(_cardPaddingKey, defaultValue: _defaultCardPadding);
  }
  
  /// カードのパディングを設定
  Future<void> setCardPadding(double value) async {
    await _settingsBox.put(_cardPaddingKey, value);
  }
  
  /// ボタンの角丸半径
  double get buttonBorderRadius {
    return _settingsBox.get(_buttonBorderRadiusKey, defaultValue: _defaultButtonBorderRadius);
  }
  
  /// ボタンの角丸半径を設定
  Future<void> setButtonBorderRadius(double value) async {
    await _settingsBox.put(_buttonBorderRadiusKey, value);
  }
  
  /// ボタンの影の強さ
  double get buttonElevation {
    return _settingsBox.get(_buttonElevationKey, defaultValue: _defaultButtonElevation);
  }
  
  /// ボタンの影の強さを設定
  Future<void> setButtonElevation(double value) async {
    await _settingsBox.put(_buttonElevationKey, value);
  }
  
  /// 入力フィールドの角丸半径
  double get inputBorderRadius {
    return _settingsBox.get(_inputBorderRadiusKey, defaultValue: _defaultInputBorderRadius);
  }
  
  /// 入力フィールドの角丸半径を設定
  Future<void> setInputBorderRadius(double value) async {
    await _settingsBox.put(_inputBorderRadiusKey, value);
  }
  
  /// 入力フィールドの枠線の太さ
  double get inputBorderWidth {
    return _settingsBox.get(_inputBorderWidthKey, defaultValue: _defaultInputBorderWidth);
  }
  
  /// 入力フィールドの枠線の太さを設定
  Future<void> setInputBorderWidth(double value) async {
    await _settingsBox.put(_inputBorderWidthKey, value);
  }
  
  /// アニメーションの持続時間（ミリ秒）
  int get animationDuration {
    return _settingsBox.get(_animationDurationKey, defaultValue: _defaultAnimationDuration);
  }
  
  /// アニメーションの持続時間を設定
  Future<void> setAnimationDuration(int value) async {
    await _settingsBox.put(_animationDurationKey, value);
  }
  
  /// ホバー効果の強さ
  double get hoverEffectIntensity {
    return _settingsBox.get(_hoverEffectIntensityKey, defaultValue: _defaultHoverEffectIntensity);
  }
  
  /// ホバー効果の強さを設定
  Future<void> setHoverEffectIntensity(double value) async {
    await _settingsBox.put(_hoverEffectIntensityKey, value);
  }
  
  /// 影の強さ
  double get shadowIntensity {
    return _settingsBox.get(_shadowIntensityKey, defaultValue: _defaultShadowIntensity);
  }
  
  /// 影の強さを設定
  Future<void> setShadowIntensity(double value) async {
    await _settingsBox.put(_shadowIntensityKey, value);
  }
  
  /// グラデーションの強さ
  double get gradientIntensity {
    return _settingsBox.get(_gradientIntensityKey, defaultValue: _defaultGradientIntensity);
  }
  
  /// グラデーションの強さを設定
  Future<void> setGradientIntensity(double value) async {
    await _settingsBox.put(_gradientIntensityKey, value);
  }
  
  /// UI密度
  double get uiDensity {
    return _settingsBox.get(_uiDensityKey, defaultValue: _defaultUiDensity);
  }
  
  /// UI密度を設定
  Future<void> setUiDensity(double value) async {
    await _settingsBox.put(_uiDensityKey, value);
  }
  
  /// アイコンサイズ
  double get iconSize {
    return _settingsBox.get(_iconSizeKey, defaultValue: _defaultIconSize);
  }
  
  /// アイコンサイズを設定
  Future<void> setIconSize(double value) async {
    await _settingsBox.put(_iconSizeKey, value);
  }
  
  /// 要素間のスペーシング
  double get spacing {
    return _settingsBox.get(_spacingKey, defaultValue: _defaultSpacing);
  }
  
  /// 要素間のスペーシングを設定
  Future<void> setSpacing(double value) async {
    await _settingsBox.put(_spacingKey, value);
  }

  /// 自動コントラスト最適化
  bool get autoContrastOptimization {
    return _settingsBox.get(_autoContrastOptimizationKey, defaultValue: _defaultAutoContrastOptimization);
  }

  /// 自動コントラスト最適化を設定
  Future<void> setAutoContrastOptimization(bool value) async {
    await _settingsBox.put(_autoContrastOptimizationKey, value);
  }

  /// ダークモードコントラストブースト
  double get darkModeContrastBoost {
    return _settingsBox.get(_darkModeContrastBoostKey, defaultValue: _defaultDarkModeContrastBoost);
  }

  /// ダークモードコントラストブーストを設定
  Future<void> setDarkModeContrastBoost(double value) async {
    await _settingsBox.put(_darkModeContrastBoostKey, value);
  }
  
  /// 全UI設定をリセット（デフォルト値に戻す）
  Future<void> resetAllUISettings() async {
    await _settingsBox.put(_cardBorderRadiusKey, _defaultCardBorderRadius);
    await _settingsBox.put(_cardElevationKey, _defaultCardElevation);
    await _settingsBox.put(_cardPaddingKey, _defaultCardPadding);
    await _settingsBox.put(_buttonBorderRadiusKey, _defaultButtonBorderRadius);
    await _settingsBox.put(_buttonElevationKey, _defaultButtonElevation);
    await _settingsBox.put(_inputBorderRadiusKey, _defaultInputBorderRadius);
    await _settingsBox.put(_inputBorderWidthKey, _defaultInputBorderWidth);
    await _settingsBox.put(_animationDurationKey, _defaultAnimationDuration);
    await _settingsBox.put(_hoverEffectIntensityKey, _defaultHoverEffectIntensity);
    await _settingsBox.put(_shadowIntensityKey, _defaultShadowIntensity);
    await _settingsBox.put(_gradientIntensityKey, _defaultGradientIntensity);
    await _settingsBox.put(_uiDensityKey, _defaultUiDensity);
    await _settingsBox.put(_iconSizeKey, _defaultIconSize);
    await _settingsBox.put(_spacingKey, _defaultSpacing);
    await _settingsBox.put(_autoContrastOptimizationKey, _defaultAutoContrastOptimization);
    await _settingsBox.put(_darkModeContrastBoostKey, _defaultDarkModeContrastBoost);
  }
  
  /// UI設定をエクスポート（JSON形式）
  Map<String, dynamic> exportUISettings() {
    return {
      // 基本UI設定
      'darkMode': darkMode,
      'accentColor': accentColor,
      'fontSize': fontSize,
      'textColor': textColor,
      'colorIntensity': colorIntensity,
      'colorContrast': colorContrast,
      
      // 個別テキスト設定
      'titleTextColor': titleTextColor,
      'titleFontSize': titleFontSize,
      'titleFontFamily': titleFontFamily,
      'memoTextColor': memoTextColor,
      'memoFontSize': memoFontSize,
      'memoFontFamily': memoFontFamily,
      'descriptionTextColor': descriptionTextColor,
      'descriptionFontSize': descriptionFontSize,
      'descriptionFontFamily': descriptionFontFamily,
      
      // カスタマイズUI設定
      'cardBorderRadius': cardBorderRadius,
      'cardElevation': cardElevation,
      'cardPadding': cardPadding,
      'buttonBorderRadius': buttonBorderRadius,
      'buttonElevation': buttonElevation,
      'inputBorderRadius': inputBorderRadius,
      'inputBorderWidth': inputBorderWidth,
      'animationDuration': animationDuration,
      'hoverEffectIntensity': hoverEffectIntensity,
      'shadowIntensity': shadowIntensity,
      'gradientIntensity': gradientIntensity,
      'uiDensity': uiDensity,
      'iconSize': iconSize,
      'spacing': spacing,
      'autoContrastOptimization': autoContrastOptimization,
      'darkModeContrastBoost': darkModeContrastBoost,
    };
  }
  
  /// UI設定をインポート（JSON形式）
  Future<void> importUISettings(Map<String, dynamic> settings) async {
    // 基本UI設定
    if (settings.containsKey('darkMode')) await setDarkMode(settings['darkMode']);
    if (settings.containsKey('accentColor')) await setAccentColor(settings['accentColor']);
    if (settings.containsKey('fontSize')) await setFontSize(settings['fontSize']);
    if (settings.containsKey('textColor')) await setTextColor(settings['textColor']);
    if (settings.containsKey('colorIntensity')) await setColorIntensity(settings['colorIntensity']);
    if (settings.containsKey('colorContrast')) await setColorContrast(settings['colorContrast']);
    
    // 個別テキスト設定
    if (settings.containsKey('titleTextColor')) await setTitleTextColor(settings['titleTextColor']);
    if (settings.containsKey('titleFontSize')) await setTitleFontSize(settings['titleFontSize']);
    if (settings.containsKey('titleFontFamily')) await setTitleFontFamily(settings['titleFontFamily']);
    if (settings.containsKey('memoTextColor')) await setMemoTextColor(settings['memoTextColor']);
    if (settings.containsKey('memoFontSize')) await setMemoFontSize(settings['memoFontSize']);
    if (settings.containsKey('memoFontFamily')) await setMemoFontFamily(settings['memoFontFamily']);
    if (settings.containsKey('descriptionTextColor')) await setDescriptionTextColor(settings['descriptionTextColor']);
    if (settings.containsKey('descriptionFontSize')) await setDescriptionFontSize(settings['descriptionFontSize']);
    if (settings.containsKey('descriptionFontFamily')) await setDescriptionFontFamily(settings['descriptionFontFamily']);
    
    // カスタマイズUI設定
    if (settings.containsKey('cardBorderRadius')) await setCardBorderRadius(settings['cardBorderRadius']);
    if (settings.containsKey('cardElevation')) await setCardElevation(settings['cardElevation']);
    if (settings.containsKey('cardPadding')) await setCardPadding(settings['cardPadding']);
    if (settings.containsKey('buttonBorderRadius')) await setButtonBorderRadius(settings['buttonBorderRadius']);
    if (settings.containsKey('buttonElevation')) await setButtonElevation(settings['buttonElevation']);
    if (settings.containsKey('inputBorderRadius')) await setInputBorderRadius(settings['inputBorderRadius']);
    if (settings.containsKey('inputBorderWidth')) await setInputBorderWidth(settings['inputBorderWidth']);
    if (settings.containsKey('animationDuration')) await setAnimationDuration(settings['animationDuration']);
    if (settings.containsKey('hoverEffectIntensity')) await setHoverEffectIntensity(settings['hoverEffectIntensity']);
    if (settings.containsKey('shadowIntensity')) await setShadowIntensity(settings['shadowIntensity']);
    if (settings.containsKey('gradientIntensity')) await setGradientIntensity(settings['gradientIntensity']);
    if (settings.containsKey('uiDensity')) await setUiDensity(settings['uiDensity']);
    if (settings.containsKey('iconSize')) await setIconSize(settings['iconSize']);
    if (settings.containsKey('spacing')) await setSpacing(settings['spacing']);
    if (settings.containsKey('autoContrastOptimization')) await setAutoContrastOptimization(settings['autoContrastOptimization']);
    if (settings.containsKey('darkModeContrastBoost')) await setDarkModeContrastBoost(settings['darkModeContrastBoost']);
  }
}
