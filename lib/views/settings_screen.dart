import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
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

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
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

  SettingsState({
    this.autoBackup = true,
    this.backupInterval = 7,
    this.showNotifications = true,
    this.notificationSound = true,
    this.recentItemsCount = 10,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    bool? autoBackup,
    int? backupInterval,
    bool? showNotifications,
    bool? notificationSound,
    int? recentItemsCount,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      autoBackup: autoBackup ?? this.autoBackup,
      backupInterval: backupInterval ?? this.backupInterval,
      showNotifications: showNotifications ?? this.showNotifications,
      notificationSound: notificationSound ?? this.notificationSound,
      recentItemsCount: recentItemsCount ?? this.recentItemsCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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

  Future<void> resetToDefaults() async {
    await _service.resetToDefaults();
    await _loadSettings();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final layoutSettings = ref.watch(layoutSettingsProvider);
    
    // 既存のテーマプロバイダーと同期
    final currentDarkMode = ref.watch(darkModeProvider);
    final currentAccentColor = ref.watch(accentColorProvider);
    final currentFontSize = ref.watch(fontSizeProvider);

    return Scaffold(
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
    );
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
                  description: 'ホーム画面に表示される「最近使ったリンク」の数を設定します。多くすると便利ですが、画面が混雑する可能性があります。',
                  slider: Slider(
                    value: settingsState.recentItemsCount.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${settingsState.recentItemsCount}個',
                    onChanged: (value) => settingsNotifier.setRecentItemsCount(value.round()),
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
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSwitchWithDescription(
                  title: '通知を表示',
                  description: 'タスクの期限やリマインダーが設定されている場合、デスクトップ通知を表示します。重要なタスクを見逃すことを防げます。',
                  value: state.showNotifications,
                  onChanged: notifier.setShowNotifications,
                ),
                
                const SizedBox(height: 16),
                
                _buildSwitchWithDescription(
                  title: '通知音',
                  description: '通知が表示される際に音を再生します。作業中でも通知を見逃すことがありません。',
                  value: state.notificationSound,
                  onChanged: notifier.setNotificationSound,
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
}

// 設定セクション管理用プロバイダー
final settingsSectionProvider = StateProvider<String>((ref) => 'theme');
