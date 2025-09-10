import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../services/windows_notification_service.dart';
import '../utils/performance_cache.dart';
import '../viewmodels/layout_settings_provider.dart';
import '../viewmodels/font_size_provider.dart';
import '../viewmodels/link_viewmodel.dart';
import '../viewmodels/task_viewmodel.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';
import '../repositories/link_repository.dart';
import '../services/google_calendar_service.dart';
import '../services/snackbar_service.dart';
import '../viewmodels/sync_status_provider.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService.instance;
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});

class SettingsState {
  final bool autoBackup;
  final int backupInterval;
  final bool showNotifications;
  final bool notificationSound;
  final int recentItemsCount;
  final bool isLoading;
  final String? error;
  final bool googleCalendarEnabled;
  final int googleCalendarSyncInterval;
  final bool googleCalendarAutoSync;
  final bool googleCalendarBidirectionalSync;

  SettingsState({
    this.autoBackup = true,
    this.backupInterval = 7,
    this.showNotifications = true,
    this.notificationSound = true,
    this.recentItemsCount = 10,
    this.isLoading = false,
    this.error,
    this.googleCalendarEnabled = false,
    this.googleCalendarSyncInterval = 60,
    this.googleCalendarAutoSync = false,
    this.googleCalendarBidirectionalSync = false,
  });

  SettingsState copyWith({
    bool? autoBackup,
    int? backupInterval,
    bool? showNotifications,
    bool? notificationSound,
    int? recentItemsCount,
    bool? isLoading,
    String? error,
    bool? googleCalendarEnabled,
    int? googleCalendarSyncInterval,
    bool? googleCalendarAutoSync,
    bool? googleCalendarBidirectionalSync,
  }) {
    return SettingsState(
      autoBackup: autoBackup ?? this.autoBackup,
      backupInterval: backupInterval ?? this.backupInterval,
      showNotifications: showNotifications ?? this.showNotifications,
      notificationSound: notificationSound ?? this.notificationSound,
      recentItemsCount: recentItemsCount ?? this.recentItemsCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      googleCalendarEnabled: googleCalendarEnabled ?? this.googleCalendarEnabled,
      googleCalendarSyncInterval: googleCalendarSyncInterval ?? this.googleCalendarSyncInterval,
      googleCalendarAutoSync: googleCalendarAutoSync ?? this.googleCalendarAutoSync,
      googleCalendarBidirectionalSync: googleCalendarBidirectionalSync ?? this.googleCalendarBidirectionalSync,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.initialize();
      
      state = state.copyWith(
        autoBackup: _service.autoBackup,
        backupInterval: _service.backupInterval,
        showNotifications: _service.showNotifications,
        notificationSound: _service.notificationSound,
        recentItemsCount: _service.recentItemsCount,
        googleCalendarEnabled: _service.googleCalendarEnabled,
        googleCalendarSyncInterval: _service.googleCalendarSyncInterval,
        googleCalendarAutoSync: _service.googleCalendarAutoSync,
        googleCalendarBidirectionalSync: _service.googleCalendarBidirectionalSync,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> setAutoBackup(bool value) async {
    await _service.setAutoBackup(value);
    state = state.copyWith(autoBackup: value);
  }

  Future<void> setBackupInterval(int value) async {
    await _service.setBackupInterval(value);
    state = state.copyWith(backupInterval: value);
  }

  Future<void> setShowNotifications(bool value) async {
    await _service.setShowNotifications(value);
    state = state.copyWith(showNotifications: value);
  }

  Future<void> setNotificationSound(bool value) async {
    await _service.setNotificationSound(value);
    state = state.copyWith(notificationSound: value);
  }

  Future<void> setRecentItemsCount(int value) async {
    await _service.setRecentItemsCount(value);
    state = state.copyWith(recentItemsCount: value);
  }

  // Google Calendar関連のメソッド
  Future<void> setGoogleCalendarEnabled(bool value) async {
    await _service.setGoogleCalendarEnabled(value);
    state = state.copyWith(googleCalendarEnabled: value);
  }

  Future<void> setGoogleCalendarSyncInterval(int value) async {
    await _service.setGoogleCalendarSyncInterval(value);
    state = state.copyWith(googleCalendarSyncInterval: value);
  }

  Future<void> setGoogleCalendarAutoSync(bool value) async {
    await _service.setGoogleCalendarAutoSync(value);
    state = state.copyWith(googleCalendarAutoSync: value);
  }

  Future<void> setGoogleCalendarBidirectionalSync(bool value) async {
    await _service.setGoogleCalendarBidirectionalSync(value);
    state = state.copyWith(googleCalendarBidirectionalSync: value);
  }

  Future<void> resetToDefaults() async {
    await _service.resetToDefaults();
    await _loadSettings();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final layoutSettings = ref.watch(layoutSettingsProvider);
    
    // 既存のテーマプロバイダーと同期
    final currentDarkMode = ref.watch(darkModeProvider);
    final currentAccentColor = ref.watch(accentColorProvider);
    final currentFontSize = ref.watch(fontSizeProvider);

    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('設定'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => settingsNotifier._loadSettings(),
              tooltip: '設定を再読み込み',
            ),
          ],
        ),
        body: settingsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  // 左側: 設定メニュー
                  Container(
                    width: 250,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: _buildSettingsMenu(context, ref),
                  ),
                  
                  // 右側: 設定内容
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildSettingsContent(
                        context, 
                        ref, 
                        settingsState, 
                        settingsNotifier, 
                        layoutSettings,
                        currentDarkMode,
                        currentAccentColor,
                        currentFontSize,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // キーボードショートカットを処理
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // 左矢印キーが押されたらリンク画面に戻る
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildSettingsMenu(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildMenuSection('外観', [
          _buildMenuItem(context, ref, 'テーマ設定', Icons.palette, 'theme'),
          _buildMenuItem(context, ref, 'フォント設定', Icons.text_fields, 'font'),
        ]),
        _buildMenuSection('レイアウト', [
          _buildMenuItem(context, ref, 'グリッド設定', Icons.grid_view, 'grid'),
          _buildMenuItem(context, ref, 'カード設定', Icons.view_agenda, 'card'),
          _buildMenuItem(context, ref, 'アイテム設定', Icons.link, 'item'),
        ]),
        _buildMenuSection('データ', [
          _buildMenuItem(context, ref, 'バックアップ', Icons.backup, 'backup'),
          _buildMenuItem(context, ref, 'エクスポート/インポート', Icons.import_export, 'export'),
        ]),
        _buildMenuSection('通知', [
          _buildMenuItem(context, ref, '通知設定', Icons.notifications, 'notifications'),
        ]),
        _buildMenuSection('連携', [
          _buildMenuItem(context, ref, 'Google Calendar', Icons.calendar_today, 'google_calendar'),
        ]),
        _buildMenuSection('パフォーマンス', [
          _buildMenuItem(context, ref, 'キャッシュ管理', Icons.memory, 'cache'),
        ]),
        _buildMenuSection('その他', [
          _buildMenuItem(context, ref, 'リセット', Icons.restore, 'reset'),
        ]),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, WidgetRef ref, String title, IconData icon, String section) {
    final currentSection = ref.watch(settingsSectionProvider);
    final isSelected = currentSection == section;
    
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        ref.read(settingsSectionProvider.notifier).state = section;
      },
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    SettingsState settingsState,
    SettingsNotifier settingsNotifier,
    LayoutSettings layoutSettings,
    bool currentDarkMode,
    int currentAccentColor,
    double currentFontSize,
  ) {
    final currentSection = ref.watch(settingsSectionProvider);
    
    switch (currentSection) {
      case 'theme':
        return _buildThemeSection(context, ref, currentDarkMode, currentAccentColor);
      case 'font':
        return _buildFontSection(context, ref, currentFontSize, settingsState, settingsNotifier);
      case 'grid':
        return _buildGridSection(ref, layoutSettings);
      case 'card':
        return _buildCardSection(ref, layoutSettings);
      case 'item':
        return _buildItemSection(ref, layoutSettings);
      case 'backup':
        return _buildBackupSection(settingsState, settingsNotifier);
      case 'export':
        return _buildExportSection(context, ref);
      case 'notifications':
        return _buildNotificationSection(settingsState, settingsNotifier);
      case 'google_calendar':
        return _buildGoogleCalendarSection(settingsState, settingsNotifier);
      case 'cache':
        return _buildCacheSection(ref);
      case 'reset':
        return _buildResetSection(context, settingsNotifier, ref);
      default:
        return _buildThemeSection(context, ref, currentDarkMode, currentAccentColor);
    }
  }

  Widget _buildThemeSection(BuildContext context, WidgetRef ref, bool currentDarkMode, int currentAccentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('テーマ設定', Icons.palette),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('ダークモード'),
                  subtitle: const Text('ダークテーマを使用'),
                  value: currentDarkMode,
                  onChanged: (value) {
                    ref.read(darkModeProvider.notifier).state = value;
                  },
                ),
                
                const SizedBox(height: 16),
                
                const Text('アクセントカラー', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildAccentColorGrid(context, ref, currentAccentColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccentColorGrid(BuildContext context, WidgetRef ref, int currentColor) {
    final colorOptions = [
      0xFF3B82F6, // 青（現在のデフォルト）
      0xFFEF4444, // 赤
      0xFF22C55E, // 緑
      0xFFF59E42, // オレンジ
      0xFF8B5CF6, // 紫
      0xFFEC4899, // ピンク
      0xFFEAB308, // 黄
      0xFF06B6D4, // 水色
      0xFF92400E, // 茶色
      0xFF64748B, // グレー
      0xFF84CC16, // ライム
      0xFF6366F1, // インディゴ
      0xFF14B8A6, // ティール
      0xFFFB923C, // ディープオレンジ
      0xFF7C3AED, // ディープパープル
      0xFFFBBF24, // アンバー
      0xFF0EA5E9, // シアン
      0xFFB45309, // ブラウン
      0xFFB91C1C, // レッドブラウン
      0xFF166534, // ダークグリーン
    ];
    final colorNames = [
      'ブルー', 'レッド', 'グリーン', 'オレンジ', 'パープル', 'ピンク', 'イエロー', 'シアン', 'ブラウン', 'グレー', 'ライム', 'インディゴ', 'ティール', 'ディープオレンジ', 'ディープパープル', 'アンバー', 'シアン', 'ブラウン', 'レッドブラウン', 'ダークグリーン'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: colorOptions.length,
      itemBuilder: (context, index) {
        final color = colorOptions[index];
        final name = colorNames[index];
        final isSelected = color == currentColor;
        
        return InkWell(
          onTap: () {
            ref.read(accentColorProvider.notifier).state = color;
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color(color),
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                ? Border.all(color: Colors.white, width: 3)
                : null,
              boxShadow: isSelected 
                ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
            ),
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFontSection(BuildContext context, WidgetRef ref, double currentFontSize, SettingsState settingsState, SettingsNotifier settingsNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('フォント設定', Icons.text_fields),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('アプリ全体のフォントサイズ: ${(currentFontSize * 100).round()}%'),
                Slider(
                  value: currentFontSize,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: '${(currentFontSize * 100).round()}%',
                  onChanged: (value) {
                    ref.read(fontSizeProvider.notifier).state = value;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildSettingItemWithDescription(
                  title: '最近使用したアイテム数',
                  value: '${settingsState.recentItemsCount}個',
                  description: 'ホーム画面に表示される「最近使ったリンク」の数を設定します。使用頻度の高いリンクが優先表示され、色分けで視認性が向上します。',
                  slider: Slider(
                    value: settingsState.recentItemsCount.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${settingsState.recentItemsCount}個',
                    onChanged: (value) => settingsNotifier.setRecentItemsCount(value.round()),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 使用頻度統計の説明
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '使用頻度統計機能',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 🔥 高頻度使用: 緑色でハイライト\n'
                        '• ⭐ 中頻度使用: オレンジ色で表示\n'
                        '• 📌 低頻度使用: 青色で表示\n'
                        '• 📌 使用頻度低: グレー色で表示\n'
                        '• 使用回数と最終使用日時を基に自動計算',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridSection(WidgetRef ref, LayoutSettings layoutSettings) {
    final notifier = ref.read(layoutSettingsProvider.notifier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('グリッド設定', Icons.grid_view),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('自動レイアウト調整'),
                  subtitle: const Text('画面サイズに応じて自動調整'),
                  value: layoutSettings.autoAdjustLayout,
                  onChanged: (value) => notifier.toggleAutoAdjustLayout(),
                ),
                
                if (!layoutSettings.autoAdjustLayout) ...[
                  const SizedBox(height: 16),
                  Text('デフォルト列数: ${layoutSettings.defaultCrossAxisCount}'),
                  Slider(
                    value: layoutSettings.defaultCrossAxisCount.toDouble(),
                    min: 2,
                    max: 6,
                    divisions: 4,
                    label: '${layoutSettings.defaultCrossAxisCount}',
                    onChanged: (value) => notifier.updateCrossAxisCount(value.round()),
                  ),
                ],
                
                const SizedBox(height: 16),
                Text('グリッド間隔: ${layoutSettings.defaultGridSpacing}px'),
                Slider(
                  value: layoutSettings.defaultGridSpacing,
                  min: 4,
                  max: 20,
                  divisions: 16,
                  label: '${layoutSettings.defaultGridSpacing}px',
                  onChanged: (value) => notifier.updateGridSpacing(value),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardSection(WidgetRef ref, LayoutSettings layoutSettings) {
    final notifier = ref.read(layoutSettingsProvider.notifier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('カード設定', Icons.view_agenda),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('カード幅: ${layoutSettings.cardWidth}px'),
                Slider(
                  value: layoutSettings.cardWidth,
                  min: 150,
                  max: 300,
                  divisions: 15,
                  label: '${layoutSettings.cardWidth}px',
                  onChanged: (value) => notifier.updateCardWidth(value),
                ),
                
                const SizedBox(height: 16),
                Text('カード高さ: ${layoutSettings.cardHeight}px'),
                Slider(
                  value: layoutSettings.cardHeight,
                  min: 80,
                  max: 200,
                  divisions: 12,
                  label: '${layoutSettings.cardHeight}px',
                  onChanged: (value) => notifier.updateCardHeight(value),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemSection(WidgetRef ref, LayoutSettings layoutSettings) {
    final notifier = ref.read(layoutSettingsProvider.notifier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('アイテム設定', Icons.link),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // アイテム間マージン
                _buildSettingItemWithDescription(
                  title: 'アイテム間マージン',
                  value: '${layoutSettings.linkItemMargin}px',
                  description: 'リンクアイテム間の空白スペースを調整します。値を大きくすると、アイテム同士の間隔が広がり、見やすくなります。',
                  slider: Slider(
                    value: layoutSettings.linkItemMargin,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: '${layoutSettings.linkItemMargin}px',
                    onChanged: (value) => notifier.updateLinkItemMargin(value),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // アイテム内パディング
                _buildSettingItemWithDescription(
                  title: 'アイテム内パディング',
                  value: '${layoutSettings.linkItemPadding}px',
                  description: 'リンクアイテム内の文字やアイコンと枠線の間の空白を調整します。値を大きくすると、アイテム内がゆとりを持って見やすくなります。',
                  slider: Slider(
                    value: layoutSettings.linkItemPadding,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    label: '${layoutSettings.linkItemPadding}px',
                    onChanged: (value) => notifier.updateLinkItemPadding(value),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // フォントサイズ
                _buildSettingItemWithDescription(
                  title: 'フォントサイズ',
                  value: '${layoutSettings.linkItemFontSize}px',
                  description: 'リンクアイテムの文字サイズを調整します。小さくすると多くのアイテムを表示できますが、読みにくくなる場合があります。',
                  slider: Slider(
                    value: layoutSettings.linkItemFontSize,
                    min: 6,
                    max: 20,
                    divisions: 28,
                    label: '${layoutSettings.linkItemFontSize}px',
                    onChanged: (value) => notifier.updateLinkItemFontSize(value),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // アイコンサイズ
                _buildSettingItemWithDescription(
                  title: 'アイコンサイズ',
                  value: '${layoutSettings.linkItemIconSize}px',
                  description: 'リンクアイテムのアイコンサイズを調整します。大きくすると視認性が向上しますが、アイテム全体のサイズも大きくなります。',
                  slider: Slider(
                    value: layoutSettings.linkItemIconSize,
                    min: 12,
                    max: 30,
                    divisions: 18,
                    label: '${layoutSettings.linkItemIconSize}px',
                    onChanged: (value) => notifier.updateLinkItemIconSize(value),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // ボタンサイズ
                _buildSettingItemWithDescription(
                  title: 'ボタンサイズ',
                  value: '${layoutSettings.buttonSize}px',
                  description: '編集・削除などのボタンのサイズを調整します。大きくすると操作しやすくなりますが、画面のスペースを多く使用します。',
                  slider: Slider(
                    value: layoutSettings.buttonSize,
                    min: 16,
                    max: 40,
                    divisions: 24,
                    label: '${layoutSettings.buttonSize}px',
                    onChanged: (value) => notifier.updateButtonSize(value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupSection(SettingsState state, SettingsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('バックアップ設定', Icons.backup),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 自動バックアップ設定
                _buildSwitchWithDescription(
                  title: '自動バックアップ',
                  description: '定期的にアプリのデータを自動的にバックアップします。データの損失を防ぎ、他のPCでも同じ設定を利用できます。',
                  value: state.autoBackup,
                  onChanged: notifier.setAutoBackup,
                ),
                
                if (state.autoBackup) ...[
                  const SizedBox(height: 16),
                  _buildSettingItemWithDescription(
                    title: 'バックアップ間隔',
                    value: '${state.backupInterval}日',
                    description: 'バックアップを実行する間隔を設定します。頻繁にバックアップすると安全性が向上しますが、ストレージ容量を多く使用します。',
                    slider: Slider(
                      value: state.backupInterval.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '${state.backupInterval}日',
                      onChanged: (value) => notifier.setBackupInterval(value.round()),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // 手動バックアップとフォルダを開くボタン
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.backup),
                        label: const Text('手動バックアップ実行'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            // 手動バックアップを実行
                            final linkRepository = LinkRepository();
                            await linkRepository.initialize(); // 初期化を追加
                            
                            final backupService = BackupService(
                              linkRepository: linkRepository,
                              settingsService: ref.read(settingsServiceProvider),
                            );
                            final backupFile = await backupService.performManualBackup();
                            
                            if (backupFile != null) {
                              SnackBarService.showSuccess(
                                context,
                                '手動バックアップが完了しました: ${backupFile.path}',
                              );
                            }
                          } catch (e) {
                            SnackBarService.showError(
                              context,
                              'バックアップエラー: $e',
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: const Text('バックアップフォルダを開く'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            final appDocDir = await getApplicationDocumentsDirectory();
                            final backupDir = Directory('${appDocDir.path}/backups');
                            
                            if (await backupDir.exists()) {
                              // Windowsでエクスプローラーを開く
                              await Process.run('explorer', [backupDir.path]);
                            } else {
                              // フォルダが存在しない場合は作成してから開く
                              await backupDir.create(recursive: true);
                              await Process.run('explorer', [backupDir.path]);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('フォルダを開けませんでした: $e'),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // バックアップの詳細説明
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'バックアップの詳細',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 自動バックアップ: アプリ起動時にチェックし、設定された間隔で実行\n'
                        '• 保存場所: %APPDATA%/linker_f/backups/\n'
                        '• ファイル形式: JSON（リンク、タスク、設定を含む）\n'
                        '• 最大保存数: 10個（古いものは自動削除）\n'
                        '• 手動バックアップ: 上記の「手動バックアップ実行」ボタンで実行可能\n'
                        '• 手動エクスポート: 設定画面から「データをエクスポート」で実行可能',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('エクスポート/インポート', Icons.import_export),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('データをエクスポート'),
                  onPressed: () => _exportData(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('データをインポート'),
                  onPressed: () => _importData(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'エクスポート/インポート機能',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• メモあり/なしを選択可能\n'
                  '• アプリの現在のディレクトリに保存\n'
                  '• 設定情報も含めてエクスポート\n'
                  '• ファイルダイアログでインポート',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    // メモを含めるかどうかの選択ダイアログ
    final includeMemos = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エクスポート設定'),
        content: const Text('メモを含めてエクスポートしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('含めない'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('含める'),
          ),
        ],
      ),
    );
    
    if (includeMemos == null) return; // キャンセルされた場合
    
    final darkMode = ref.read(darkModeProvider);
    final fontSize = ref.read(fontSizeProvider);
    final accentColor = ref.read(accentColorProvider);
    
    // リンクデータとタスクデータを取得
    final linkData = ref.read(linkViewModelProvider.notifier).exportDataWithSettings(
      darkMode, 
      fontSize, 
      accentColor,
      excludeMemos: !includeMemos,
    );
    
    final taskData = ref.read(taskViewModelProvider.notifier).exportData();
    
    // 統合データを作成
    final data = {
      ...linkData,
      'tasks': taskData['tasks'],
      'tasksExportedAt': taskData['exportedAt'],
    };
    
    final jsonStr = jsonEncode(data);
    final now = DateTime.now();
    final formatted = DateFormat('yyMMddHHmm').format(now);
    final memoText = includeMemos ? 'メモあり' : 'メモなし';
    final fileName = 'linker_f_export_${memoText}_$formatted.json';
    final currentDir = Directory.current;
    final file = File('${currentDir.path}/$fileName');
    await file.writeAsString(jsonStr);
    
    // 画面中央にエクスポート完了メッセージを表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('エクスポート完了'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('エクスポートしました:'),
            SizedBox(height: 8),
            Text(
              'ファイル名: $fileName',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                backgroundColor: Colors.grey[100],
              ),
            ),
            SizedBox(height: 4),
            Text(
              '保存場所: ${currentDir.path}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                backgroundColor: Colors.grey[100],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final directory = file.parent;
                await Process.run('explorer', [directory.path]);
              } catch (e) {
                // エラーハンドリング
              }
            },
            icon: Icon(Icons.folder_open),
            label: Text('フォルダを開く'),
          ),
        ],
      ),
    );
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      // デフォルトのエクスポートフォルダを初期位置に設定
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: Directory.current.path, // 現在のディレクトリを初期位置に
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final jsonStr = await file.readAsString();
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        // リンクデータをインポート
        await ref.read(linkViewModelProvider.notifier).importDataWithSettings(
          data,
          (bool darkMode, double fontSize, int accentColor) {
            ref.read(darkModeProvider.notifier).state = darkMode;
            ref.read(fontSizeProvider.notifier).state = fontSize;
            ref.read(accentColorProvider.notifier).state = accentColor;
          },
        );
        
        // タスクデータをインポート（存在する場合）
        if (data.containsKey('tasks')) {
          final taskData = {
            'tasks': data['tasks'],
          };
          await ref.read(taskViewModelProvider.notifier).importData(taskData);
        }
        
        // データの永続化を確実にするため、少し待機
        await Future.delayed(const Duration(milliseconds: 500));
        
        // リンクのタスク状態を更新
        await ref.read(taskViewModelProvider.notifier).refreshLinkTaskStatus();
        
        // SnackBarで通知
        final hasTasks = data.containsKey('tasks');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasTasks 
              ? 'リンクとタスクをインポートしました: ${file.path}'
              : 'リンクをインポートしました: ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('インポートエラー: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildNotificationSection(SettingsState state, SettingsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                 _buildSectionHeader('通知設定', Icons.notifications),
         const SizedBox(height: 16),
         
         // 通知の制限に関する注意事項
         Container(
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
             color: Colors.orange.shade50,
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: Colors.orange.shade200),
           ),
           child: Row(
             children: [
               Icon(
                 Icons.info_outline,
                 color: Colors.orange.shade600,
                 size: 20,
               ),
               const SizedBox(width: 8),
               Expanded(
                 child: Text(
                   '注意: 通知はアプリが起動中の場合のみ表示されます。アプリを閉じている場合は通知が表示されません。',
                   style: TextStyle(
                     color: Colors.orange.shade800,
                     fontSize: 13,
                     height: 1.4,
                   ),
                 ),
               ),
             ],
           ),
         ),
         
         const SizedBox(height: 16),
         
         Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                                 _buildSwitchWithDescription(
                   title: '通知を表示',
                   description: 'タスクの期限やリマインダーが設定されている場合、デスクトップ通知を表示します。アプリが起動中の場合のみ通知が表示されます。',
                   value: state.showNotifications,
                   onChanged: notifier.setShowNotifications,
                 ),
                
                const SizedBox(height: 16),
                
                                 _buildSwitchWithDescription(
                   title: '通知音',
                   description: '通知が表示される際に音を再生します。アプリが起動中の場合のみ音が再生されます。',
                   value: state.notificationSound,
                   onChanged: notifier.setNotificationSound,
                 ),
                
                const SizedBox(height: 8),
                
                                 ElevatedButton.icon(
                   icon: const Icon(Icons.volume_up),
                   label: const Text('通知音をテスト'),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.green,
                     foregroundColor: Colors.white,
                   ),
                   onPressed: () async {
                     try {
                       if (Platform.isWindows) {
                         await WindowsNotificationService.showTestNotification();
                       } else {
                         await NotificationService.showTestNotification();
                       }
                     } catch (e) {
                       print('通知音テストエラー: $e');
                     }
                   },
                 ),
                 
                 const SizedBox(height: 8),
                 
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: Colors.grey.shade50,
                     borderRadius: BorderRadius.circular(6),
                     border: Border.all(color: Colors.grey.shade200),
                   ),
                   child: Text(
                     'このボタンで通知音をテストできます。アプリが起動中の場合のみ音が再生されます。',
                     style: TextStyle(
                       fontSize: 11,
                       color: Colors.grey.shade600,
                       fontStyle: FontStyle.italic,
                     ),
                   ),
                 ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCacheSection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('キャッシュ管理', Icons.memory),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final stats = PerformanceCache.getStats();
                    return Column(
                      children: [
                        _buildStatRow('キャッシュサイズ', '${stats['size']}/${stats['maxSize']}'),
                        _buildStatRow('キャッシュキー数', '${stats['keys'].length}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            PerformanceCache.clear();
                            ref.invalidate(settingsProvider);
                          },
                          child: const Text('キャッシュをクリア'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetSection(BuildContext context, SettingsNotifier notifier, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('リセット', Icons.restore),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text('設定をデフォルトにリセット'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showResetConfirmationDialog(context, notifier),
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  icon: const Icon(Icons.grid_view),
                  label: const Text('レイアウト設定をリセット'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    ref.read(layoutSettingsProvider.notifier).resetToDefaults();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定をリセット'),
        content: const Text('すべての設定をデフォルト値にリセットしますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.resetToDefaults();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }

  // スイッチ付きの設定項目を説明付きで表示するウィジェット
  Widget _buildSwitchWithDescription({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 設定項目を説明付きで表示するウィジェット
  Widget _buildSettingItemWithDescription({
    required String title,
    required String value,
    required String description,
    required Widget slider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        slider,
      ],
    );
  }

  Widget _buildGoogleCalendarSection(SettingsState settingsState, SettingsNotifier settingsNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Google Calendar連携', Icons.calendar_today),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Google Calendar連携の有効/無効
                SwitchListTile(
                  title: const Text('Google Calendar連携'),
                  subtitle: const Text('Google Calendarのイベントをタスクとして同期します'),
                  value: settingsState.googleCalendarEnabled,
                  onChanged: (value) {
                    settingsNotifier.setGoogleCalendarEnabled(value);
                  },
                  secondary: const Icon(Icons.calendar_today),
                ),
                
                if (settingsState.googleCalendarEnabled) ...[
                  const Divider(),
                  
                  // 自動同期の有効/無効
                  SwitchListTile(
                    title: const Text('自動同期'),
                    subtitle: const Text('定期的にGoogle Calendarと同期します'),
                    value: settingsState.googleCalendarAutoSync,
                    onChanged: (value) {
                      settingsNotifier.setGoogleCalendarAutoSync(value);
                    },
                    secondary: const Icon(Icons.sync),
                  ),
                  
                  if (settingsState.googleCalendarAutoSync) ...[
                    const Divider(),
                    
                    // 同期間隔設定
                    _buildSliderSetting(
                      title: '同期間隔',
                      description: 'Google Calendarとの同期間隔を設定します',
                      value: settingsState.googleCalendarSyncInterval.toDouble(),
                      min: 15,
                      max: 240,
                      divisions: 15,
                      onChanged: (value) {
                        settingsNotifier.setGoogleCalendarSyncInterval(value.round());
                      },
                      formatValue: (value) => '${value.round()}分',
                    ),
                  ],
                  
                  const Divider(),
                  
                  // 同期状態表示
                  _buildSyncStatusSection(ref),
                  
                  const Divider(),
                  
                  // 部分同期機能
                  _buildPartialSyncSection(ref),
                  
                  const Divider(),
                  
                  // 双方向同期の有効/無効
                  SwitchListTile(
                    title: const Text('双方向同期'),
                    subtitle: const Text('アプリのタスクをGoogle Calendarに送信します'),
                    value: settingsState.googleCalendarBidirectionalSync,
                    onChanged: (value) {
                      settingsNotifier.setGoogleCalendarBidirectionalSync(value);
                    },
                    secondary: const Icon(Icons.sync_alt),
                  ),
                  
                  const Divider(),
                  
                  // OAuth2認証ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final googleCalendarService = GoogleCalendarService();
                          final success = await googleCalendarService.startOAuth2Auth();
                          if (success) {
                            SnackBarService.showSuccess(
                              context,
                              'OAuth2認証が完了しました',
                            );
                          } else {
                            SnackBarService.showError(
                              context,
                              '認証の開始に失敗しました',
                            );
                          }
                        } catch (e) {
                          SnackBarService.showError(
                            context,
                            'エラー: $e',
                          );
                        }
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('OAuth2認証を開始'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 完全相互同期ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final taskViewModel = ref.read(taskViewModelProvider.notifier);
                          final result = await taskViewModel.performFullBidirectionalSync();
                          
                          if (result['success']) {
                            final appToCalendar = result['appToCalendar'] ?? 0;
                            final calendarToApp = result['calendarToApp'] ?? 0;
                            final total = result['total'] ?? 0;
                            
                            SnackBarService.showSuccess(
                              context, 
                              '完全同期完了: アプリ→Googleカレンダー${appToCalendar}件, Googleカレンダー→アプリ${calendarToApp}件 (合計${total}件)'
                            );
                          } else {
                            SnackBarService.showError(context, '同期エラー: ${result['error']}');
                          }
                        } catch (e) {
                          SnackBarService.showError(context, '同期エラー: $e');
                        }
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('完全同期'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 設定情報
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '設定方法',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Google Cloud Consoleでプロジェクトを作成\n'
                          '2. Calendar APIを有効化\n'
                          '3. サービスアカウントを作成\n'
                          '4. 認証情報ファイルをダウンロード\n'
                          '5. ファイルをアプリフォルダに配置',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) formatValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          label: formatValue(value),
        ),
        Center(
          child: Text(
            formatValue(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }

  /// 同期状態表示セクション
  Widget _buildSyncStatusSection(WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '同期状態',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // 同期状態インジケーター
        Row(
          children: [
            _buildSyncStatusIndicator(syncState.status),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getSyncStatusText(syncState),
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (syncState.lastSyncTime != null)
                    Text(
                      '最終同期: ${DateFormat('MM/dd HH:mm').format(syncState.lastSyncTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        
        // 進捗バー（同期中の場合）
        if (syncState.isSyncing && syncState.totalItems != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: syncState.progressRatio,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              syncState.hasError ? Colors.red : Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${syncState.processedItems ?? 0}/${syncState.totalItems}件処理中...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        
        // エラーメッセージ（エラーの場合）
        if (syncState.hasError) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'エラー: ${syncState.errorMessage}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (syncState.errorCode != null)
                  Text(
                    'エラーコード: ${syncState.errorCode}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 同期状態インジケーター
  Widget _buildSyncStatusIndicator(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Icon(Icons.sync, color: Colors.grey[400], size: 20);
      case SyncStatus.syncing:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case SyncStatus.success:
        return Icon(Icons.check_circle, color: Colors.green, size: 20);
      case SyncStatus.error:
        return Icon(Icons.error, color: Colors.red, size: 20);
    }
  }

  /// 同期状態テキスト
  String _getSyncStatusText(SyncState syncState) {
    switch (syncState.status) {
      case SyncStatus.idle:
        return '待機中';
      case SyncStatus.syncing:
        return syncState.message ?? '同期中...';
      case SyncStatus.success:
        return syncState.message ?? '同期完了';
      case SyncStatus.error:
        return '同期エラー';
    }
  }

  /// 部分同期機能セクション
  Widget _buildPartialSyncSection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '部分同期',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '選択したタスクや日付範囲のタスクのみを同期できます',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        // 個別タスク同期の説明
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '個別タスクの同期は、タスク画面の各タスクの3点ドットメニューから「このタスクを同期」を選択してください。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // 日付範囲同期ボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDateRangeSyncDialog(ref),
            icon: const Icon(Icons.date_range),
            label: const Text('日付範囲で同期'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }


  /// 日付範囲同期ダイアログ
  void _showDateRangeSyncDialog(WidgetRef ref) {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('日付範囲同期'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('同期する日付範囲を選択してください'),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('開始日'),
                subtitle: Text(DateFormat('yyyy/MM/dd').format(startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => startDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('終了日'),
                subtitle: Text(DateFormat('yyyy/MM/dd').format(endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: startDate,
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => endDate = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performDateRangeSync(ref, startDate, endDate);
              },
              child: const Text('同期実行'),
            ),
          ],
        ),
      ),
    );
  }

  /// 日付範囲同期を実行
  Future<void> _performDateRangeSync(WidgetRef ref, DateTime startDate, DateTime endDate) async {
    final syncStatusNotifier = ref.read(syncStatusProvider.notifier);
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    
    try {
      syncStatusNotifier.startSync(
        message: '日付範囲同期中...',
      );
      
      final result = await taskViewModel.syncTasksByDateRange(startDate, endDate);
      
      if (result['success'] == true) {
        syncStatusNotifier.syncSuccess(
          message: '日付範囲同期完了: ${result['successCount']}件成功',
        );
        SnackBarService.showSuccess(context, '日付範囲同期が完了しました');
      } else {
        syncStatusNotifier.syncError(
          errorMessage: result['errors']?.join(', ') ?? '不明なエラー',
          message: '日付範囲同期に失敗しました',
        );
        SnackBarService.showError(context, '日付範囲同期に失敗しました');
      }
    } catch (e) {
      syncStatusNotifier.syncError(
        errorMessage: e.toString(),
        message: '日付範囲同期中にエラーが発生しました',
      );
      SnackBarService.showError(context, '日付範囲同期中にエラーが発生しました: $e');
    }
  }
  
}

// 設定セクション管理用プロバイダー
final settingsSectionProvider = StateProvider<String>((ref) => 'theme');
