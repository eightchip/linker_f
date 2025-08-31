import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// 設定管理サービス
class SettingsService {
  static const String _settingsBoxName = 'settings';
  static const String _defaultSettingsBoxName = 'default_settings';
  
  late Box _settingsBox;
  late Box _defaultSettingsBox;
  
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
  static const String _showNotificationsKey = 'showNotifications';
  static const String _notificationSoundKey = 'notificationSound';
  static const String _recentItemsCountKey = 'recentItemsCount';
  static const String _searchHistoryKey = 'searchHistory';
  static const String _favoriteGroupsKey = 'favoriteGroups';
  static const String _lastBackupKey = 'lastBackup';
  static const String _versionKey = 'version';

  // デフォルト値
  static const bool _defaultDarkMode = false;
  static const double _defaultFontSize = 1.0;
  static const int _defaultAccentColor = 0xFF3B82F6;
  static const double _defaultWindowWidth = 800.0;
  static const double _defaultWindowHeight = 600.0;
  static const double _defaultWindowX = 100.0;
  static const double _defaultWindowY = 100.0;
  static const bool _defaultAutoBackup = true;
  static const int _defaultBackupInterval = 7; // 日数
  static const bool _defaultShowNotifications = true;
  static const bool _defaultNotificationSound = true;
  static const int _defaultRecentItemsCount = 10;
  static const int _currentVersion = 1;

  /// 初期化
  Future<void> initialize() async {
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _defaultSettingsBox = await Hive.openBox(_defaultSettingsBoxName);
    
    // 初回起動時のデフォルト設定を保存
    await _initializeDefaultSettings();
    
    // バージョン管理
    await _handleVersionMigration();
  }

  /// デフォルト設定の初期化
  Future<void> _initializeDefaultSettings() async {
    if (!_defaultSettingsBox.containsKey(_versionKey)) {
      await _defaultSettingsBox.put(_darkModeKey, _defaultDarkMode);
      await _defaultSettingsBox.put(_fontSizeKey, _defaultFontSize);
      await _defaultSettingsBox.put(_accentColorKey, _defaultAccentColor);
      await _defaultSettingsBox.put(_windowWidthKey, _defaultWindowWidth);
      await _defaultSettingsBox.put(_windowHeightKey, _defaultWindowHeight);
      await _defaultSettingsBox.put(_windowXKey, _defaultWindowX);
      await _defaultSettingsBox.put(_windowYKey, _defaultWindowY);
      await _defaultSettingsBox.put(_autoBackupKey, _defaultAutoBackup);
      await _defaultSettingsBox.put(_backupIntervalKey, _defaultBackupInterval);
      await _defaultSettingsBox.put(_showNotificationsKey, _defaultShowNotifications);
      await _defaultSettingsBox.put(_notificationSoundKey, _defaultNotificationSound);
      await _defaultSettingsBox.put(_recentItemsCountKey, _defaultRecentItemsCount);
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
    if (!_settingsBox.containsKey(_recentItemsCountKey)) {
      await _settingsBox.put(_recentItemsCountKey, _defaultRecentItemsCount);
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
  
  /// 最近使用したアイテム数
  int get recentItemsCount => _settingsBox.get(_recentItemsCountKey, defaultValue: _defaultRecentItemsCount) as int;
  Future<void> setRecentItemsCount(int value) async {
    await _settingsBox.put(_recentItemsCountKey, value);
  }

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

  /// お気に入りグループ
  List<String> get favoriteGroups {
    final groups = _settingsBox.get(_favoriteGroupsKey);
    return groups != null ? List<String>.from(groups as List) : [];
  }
  Future<void> setFavoriteGroups(List<String> value) async {
    await _settingsBox.put(_favoriteGroupsKey, value);
  }

  /// お気に入りグループに追加
  Future<void> addFavoriteGroup(String groupId) async {
    final groups = favoriteGroups;
    if (!groups.contains(groupId)) {
      groups.add(groupId);
      await setFavoriteGroups(groups);
    }
  }

  /// お気に入りグループから削除
  Future<void> removeFavoriteGroup(String groupId) async {
    final groups = favoriteGroups;
    groups.remove(groupId);
    await setFavoriteGroups(groups);
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
      
      return darkMode is bool && 
             fontSize is double && 
             fontSize > 0 && 
             accentColor is int;
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
}
