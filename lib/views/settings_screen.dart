import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../services/windows_notification_service.dart';
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
import '../widgets/unified_dialog.dart';
import '../services/snackbar_service.dart';
import '../services/gmail_api_service.dart';
import '../services/outlook_service.dart';
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
  final bool isLoading;
  final String? error;
  final bool googleCalendarEnabled;
  final int googleCalendarSyncInterval;
  final bool googleCalendarAutoSync;
  final bool googleCalendarBidirectionalSync;
  final bool googleCalendarShowCompletedTasks;
  final bool gmailApiEnabled;

  SettingsState({
    this.autoBackup = true,
    this.backupInterval = 7,
    this.showNotifications = true,
    this.notificationSound = true,
    this.isLoading = false,
    this.error,
    this.googleCalendarEnabled = false,
    this.googleCalendarSyncInterval = 60,
    this.googleCalendarAutoSync = false,
    this.googleCalendarBidirectionalSync = false,
    this.googleCalendarShowCompletedTasks = true,
    this.gmailApiEnabled = false,
  });

  SettingsState copyWith({
    bool? autoBackup,
    int? backupInterval,
    bool? showNotifications,
    bool? notificationSound,
    bool? isLoading,
    String? error,
    bool? googleCalendarEnabled,
    int? googleCalendarSyncInterval,
    bool? googleCalendarAutoSync,
    bool? googleCalendarBidirectionalSync,
    bool? googleCalendarShowCompletedTasks,
    bool? gmailApiEnabled,
  }) {
    return SettingsState(
      autoBackup: autoBackup ?? this.autoBackup,
      backupInterval: backupInterval ?? this.backupInterval,
      showNotifications: showNotifications ?? this.showNotifications,
      notificationSound: notificationSound ?? this.notificationSound,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      googleCalendarEnabled: googleCalendarEnabled ?? this.googleCalendarEnabled,
      googleCalendarSyncInterval: googleCalendarSyncInterval ?? this.googleCalendarSyncInterval,
      googleCalendarAutoSync: googleCalendarAutoSync ?? this.googleCalendarAutoSync,
      googleCalendarBidirectionalSync: googleCalendarBidirectionalSync ?? this.googleCalendarBidirectionalSync,
      googleCalendarShowCompletedTasks: googleCalendarShowCompletedTasks ?? this.googleCalendarShowCompletedTasks,
      gmailApiEnabled: gmailApiEnabled ?? this.gmailApiEnabled,
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
        googleCalendarEnabled: _service.googleCalendarEnabled,
        googleCalendarSyncInterval: _service.googleCalendarSyncInterval,
        googleCalendarAutoSync: _service.googleCalendarAutoSync,
        googleCalendarBidirectionalSync: _service.googleCalendarBidirectionalSync,
        googleCalendarShowCompletedTasks: _service.googleCalendarShowCompletedTasks,
        gmailApiEnabled: _service.gmailApiEnabled,
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

  Future<void> setGoogleCalendarShowCompletedTasks(bool value) async {
    await _service.setGoogleCalendarShowCompletedTasks(value);
    state = state.copyWith(googleCalendarShowCompletedTasks: value);
  }

  Future<void> updateGmailApiEnabled(bool value) async {
    await _service.setGmailApiEnabled(value);
    state = state.copyWith(gmailApiEnabled: value);
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
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: _buildSettingsMenu(context, ref),
                  ),
                  
                  // 右側: 設定内容
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
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
          _buildMenuItem(context, ref, 'Gmail API', FontAwesomeIcons.envelope, 'gmail_api'),
          _buildMenuItem(context, ref, 'Outlook', FontAwesomeIcons.microsoft, 'outlook'),
        ], subtitle: '各連携機能には個別の設定が必要です'),
        _buildMenuSection('その他', [
          _buildMenuItem(context, ref, 'リセット', Icons.restore, 'reset'),
        ]),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Widget> children, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
            title,
                style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ],
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
    
    // 各セクションに応じた色を定義
    Color getIconColor() {
      switch (section) {
        case 'theme':
          return const Color(0xFF4CAF50); // 緑
        case 'font':
          return const Color(0xFF2196F3); // 青
        case 'grid':
          return const Color(0xFFFF9800); // オレンジ
        case 'card':
          return const Color(0xFF9C27B0); // 紫
        case 'item':
          return const Color(0xFF009688); // ティール
        case 'backup':
          return const Color(0xFF607D8B); // ブルーグレー
        case 'export':
          return const Color(0xFF4CAF50); // 緑
        case 'notifications':
          return const Color(0xFFFF5722); // ディープオレンジ
        case 'google_calendar':
          return const Color(0xFF3F51B5); // インディゴ
        case 'gmail_api':
          return const Color(0xFFEA4335); // Gmail赤
        case 'outlook':
          return const Color(0xFF0078D4); // Outlook青
        case 'reset':
          return const Color(0xFFF44336); // 赤
        default:
          return Colors.grey;
      }
    }
    
    final iconColor = getIconColor();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? iconColor.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: iconColor.withOpacity(0.3), width: 1) : null,
      ),
      child: ListTile(
        leading: icon.fontFamily == 'FontAwesome'
          ? FaIcon(
              icon,
              color: isSelected ? iconColor : iconColor.withOpacity(0.7),
              size: 20,
            )
          : Icon(
          icon, 
          color: isSelected ? iconColor : iconColor.withOpacity(0.7),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? iconColor : Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        onTap: () {
          ref.read(settingsSectionProvider.notifier).state = section;
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
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
        case 'gmail_api':
          return _buildGmailApiSection(settingsState, settingsNotifier);
        case 'outlook':
          return _buildOutlookSection();
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
                ? Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black, 
                    width: 3
                  )
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
                
                const SizedBox(height: 16),
                
                // 自動レイアウトの説明
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            layoutSettings.autoAdjustLayout ? Icons.auto_awesome : Icons.settings,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            layoutSettings.autoAdjustLayout ? '自動レイアウト有効' : '手動レイアウト設定',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (layoutSettings.autoAdjustLayout) ...[
                        Text(
                          '自動レイアウトが有効です。画面サイズに応じて最適な列数が自動で決定されます。',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLayoutInfo(
                          '大画面（1920px以上）',
                          '6列表示',
                          'デスクトップモニターに最適',
                        ),
                        _buildLayoutInfo(
                          '中画面（1200-1919px）',
                          '4列表示',
                          'ノートPCやタブレットに最適',
                        ),
                        _buildLayoutInfo(
                          '小画面（800-1199px）',
                          '3列表示',
                          '小さな画面に最適',
                        ),
                        _buildLayoutInfo(
                          '最小画面（800px未満）',
                          '2列表示',
                          'モバイル表示に最適',
                        ),
                      ] else ...[
                        Text(
                          '手動レイアウト設定が有効です。固定の列数で表示されます。',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLayoutInfo(
                          '固定列数',
                          '${layoutSettings.defaultCrossAxisCount}列表示',
                          'すべての画面サイズで同じ列数',
                        ),
                        _buildLayoutInfo(
                          '使用場面',
                          '特定の表示を維持したい場合',
                          '一貫したレイアウトが必要な場合',
                        ),
                      ],
                    ],
                  ),
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
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ElevatedButton.icon(
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
                    
                    ElevatedButton.icon(
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
        
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
          child: Padding(
                padding: const EdgeInsets.all(24),
            child: Column(
                  mainAxisSize: MainAxisSize.min,
              children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload, size: 24),
                        label: const Text('データをエクスポート', style: TextStyle(fontSize: 16)),
                  onPressed: () => _exportData(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download, size: 24),
                        label: const Text('データをインポート', style: TextStyle(fontSize: 16)),
                  onPressed: () => _importData(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                  'エクスポート/インポート機能',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                  '• メモあり/なしを選択可能\n'
                  '• アプリの現在のディレクトリに保存\n'
                  '• 設定情報も含めてエクスポート\n'
                  '• ファイルダイアログでインポート',
                            style: TextStyle(
                              fontSize: 14, 
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    // メモを含めるかどうかの選択ダイアログ
    final includeMemos = await UnifiedDialogHelper.showConfirmDialog(
      context,
      title: 'エクスポート設定',
      message: 'メモを含めてエクスポートしますか？',
      confirmText: '含める',
      cancelText: '含めない',
      icon: Icons.upload,
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
      builder: (context) => UnifiedDialog(
        title: 'エクスポート完了',
        icon: Icons.check_circle,
        iconColor: Colors.green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('エクスポートしました:'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
              'ファイル名: $fileName',
                style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
              '保存場所: ${currentDir.path}',
                style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppButtonStyles.text(context),
            child: const Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final directory = file.parent;
                await Process.run('explorer', [directory.path]);
                Navigator.pop(context);
              } catch (e) {
                // エラーハンドリング
              }
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('フォルダを開く'),
            style: AppButtonStyles.primary(context),
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
        
        // 成功通知
        final hasTasks = data.containsKey('tasks');
        SnackBarService.showSuccess(
          context,
          hasTasks 
              ? 'リンクとタスクをインポートしました: ${file.path}'
            : 'リンクをインポートしました: ${file.path}',
        );
      }
    } catch (e) {
      SnackBarService.showError(context, 'インポートエラー: $e');
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
                     color: Theme.of(context).colorScheme.surfaceVariant,
                     borderRadius: BorderRadius.circular(6),
                     border: Border.all(
                       color: Theme.of(context).colorScheme.outline.withOpacity(0.3)
                     ),
                   ),
                   child: Text(
                     'このボタンで通知音をテストできます。アプリが起動中の場合のみ音が再生されます。',
                     style: TextStyle(
                       fontSize: 11,
                       color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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


  Widget _buildResetSection(BuildContext context, SettingsNotifier notifier, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('リセット', Icons.restore),
        const SizedBox(height: 16),
        
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
          child: Padding(
                padding: const EdgeInsets.all(24),
            child: Column(
                  mainAxisSize: MainAxisSize.min,
              children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.restore, size: 24),
                        label: const Text('設定をデフォルトにリセット', style: TextStyle(fontSize: 16)),
                        onPressed: () => _showResetConfirmationDialog(context, notifier),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.grid_view, size: 24),
                        label: const Text('レイアウト設定をリセット', style: TextStyle(fontSize: 16)),
                          onPressed: () {
                          ref.read(layoutSettingsProvider.notifier).resetToDefaults();
                        },
                  style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.help_outline, size: 24),
                        label: const Text('リセット機能の詳細', style: TextStyle(fontSize: 16)),
                        onPressed: () => _openResetDetailsGuide(context),
                  style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 説明
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'リセット機能',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 設定リセット: テーマ、通知、連携設定など\n'
                            '• レイアウトリセット: グリッドサイズ、カード設定など\n'
                            '• データは保持: リンク、タスク、メモは削除されません\n'
                            '• 詳細は「リセット機能の詳細」ボタンで確認',
                            style: TextStyle(
                              fontSize: 14, 
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    // FontAwesomeアイコンの場合はFaIconを使用
    Widget iconWidget;
    if (icon.fontFamily == 'FontAwesome') {
      iconWidget = FaIcon(icon, size: 24);
    } else {
      iconWidget = Icon(icon, size: 24);
    }
    
    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }


  void _openResetDetailsGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: 'リセット機能の詳細',
        icon: Icons.help_outline,
        iconColor: Colors.grey,
        width: 700,
        height: 800,
        content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'リセット機能の詳細説明:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
                const SizedBox(height: 16),
                
            _buildGuideStep('1', '設定をデフォルトにリセット'),
            Text(
              '以下の設定が初期値に戻ります:',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            _buildResetItem('テーマ設定', 'ダークモード: OFF、アクセントカラー: デフォルト'),
            _buildResetItem('通知設定', '通知: ON、通知音: ON'),
            _buildResetItem('連携設定', 'Google Calendar: OFF、Gmail API: OFF、Outlook: OFF'),
            _buildResetItem('バックアップ設定', '自動バックアップ: ON、間隔: 7日'),
            const SizedBox(height: 12),
            
            _buildGuideStep('2', 'レイアウト設定をリセット'),
            Text(
              '以下のレイアウト設定が初期値に戻ります:',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            _buildResetItem('グリッド設定', 'カラム数: 4、間隔: デフォルト'),
            _buildResetItem('カード設定', 'サイズ: デフォルト、影: デフォルト'),
            _buildResetItem('アイテム設定', 'フォントサイズ: デフォルト、アイコンサイズ: デフォルト'),
            const SizedBox(height: 12),
            
            _buildGuideStep('3', 'データの保持について'),
            Text(
              '以下のデータは削除されません:',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            _buildResetItem('リンクデータ', 'すべてのリンク、グループ、メモが保持されます'),
            _buildResetItem('タスクデータ', 'すべてのタスク、サブタスク、進捗が保持されます'),
            _buildResetItem('検索履歴', '検索履歴は保持されます'),
            const SizedBox(height: 12),
            
            _buildGuideStep('4', 'リセット後の動作'),
            Text(
              'リセット後は以下のようになります:',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            _buildResetItem('アプリ再起動', '設定変更を反映するため再起動が推奨されます'),
            _buildResetItem('設定確認', '設定画面で新しい設定値を確認できます'),
            _buildResetItem('データ復元', 'エクスポート/インポート機能でデータを復元可能'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppButtonStyles.text(context),
            child: const Text('閉じる'),
                ),
              ],
            ),
    );
  }

  Widget _buildResetItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerShellFileInfo(String fileName, String title, String description, String location, String usage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Icon(Icons.code, color: Colors.blue, size: 16),
              const SizedBox(width: 6),
              Text(
                fileName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blue.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        Text(
          title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.folder, color: Colors.grey, size: 12),
              const SizedBox(width: 4),
              Text(
                '格納場所: $location',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.play_arrow, color: Colors.green, size: 12),
              const SizedBox(width: 4),
              Text(
                '実行方法: $usage',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutInfo(String title, String value, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
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
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3)
            ),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3)
            ),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                  
                  // 完了タスク表示設定
                  SwitchListTile(
                    title: const Text('完了タスクを表示'),
                    subtitle: const Text('Google Calendarで完了したタスクを表示します'),
                    value: settingsState.googleCalendarShowCompletedTasks,
                    onChanged: (value) {
                      settingsNotifier.setGoogleCalendarShowCompletedTasks(value);
                    },
                    secondary: const Icon(Icons.visibility),
                  ),
                  
                  const Divider(),
                  
                  // 認証情報ファイルの状態表示
                  FutureBuilder<bool>(
                    future: GoogleCalendarSetup.hasCredentialsFile(),
                    builder: (context, snapshot) {
                      final hasCredentials = snapshot.data ?? false;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: hasCredentials ? Colors.green.shade50 : Colors.red.shade50,
                          border: Border.all(
                            color: hasCredentials ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasCredentials ? Icons.check_circle : Icons.error,
                              color: hasCredentials ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasCredentials 
                                  ? '認証情報ファイルが見つかりました'
                                  : '認証情報ファイルが見つかりません',
                                style: TextStyle(
                                  color: hasCredentials ? Colors.green.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // 設定方法とOAuth2認証ボタン
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openGoogleCalendarSetupGuide,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('設定方法を確認'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
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
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // アプリ→Google Calendar同期ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final taskViewModel = ref.read(taskViewModelProvider.notifier);
                          final result = await taskViewModel.syncAllTasksToGoogleCalendar();
                          
                          if (result['success']) {
                            final created = result['created'] ?? 0;
                            final updated = result['updated'] ?? 0;
                            final deleted = result['deleted'] ?? 0;
                            
                            SnackBarService.showSuccess(
                              context, 
                              'アプリ→Google Calendar同期完了: 作成${created}件, 更新${updated}件, 削除${deleted}件'
                            );
                          } else {
                            SnackBarService.showError(context, '同期エラー: ${result['error']}');
                          }
                        } catch (e) {
                          SnackBarService.showError(context, '同期エラー: $e');
                        }
                      },
                      icon: const Icon(Icons.upload),
                      label: const Text('アプリ→Google Calendar同期'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Google Calendar→アプリ同期ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final taskViewModel = ref.read(taskViewModelProvider.notifier);
                          final result = await taskViewModel.syncFromGoogleCalendarToApp();
                          
                          if (result['success']) {
                            final added = result['added'] ?? 0;
                            final skipped = result['skipped'] ?? 0;
                            
                            SnackBarService.showSuccess(
                              context, 
                              'Google Calendar→アプリ同期完了: 追加${added}件, スキップ${skipped}件'
                            );
                          } else {
                            SnackBarService.showError(context, '同期エラー: ${result['error']}');
                          }
                        } catch (e) {
                          SnackBarService.showError(context, '同期エラー: $e');
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Google Calendar→アプリ同期'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 設定情報
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
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3)
            ),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
        return Icon(
          Icons.sync, 
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), 
          size: 20
        );
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
        const SizedBox(height: 8),
        
        // 重複クリーンアップボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDuplicateCleanupDialog(ref),
            icon: const Icon(Icons.cleaning_services),
            label: const Text('重複イベントをクリーンアップ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // 孤立イベント削除ボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showOrphanedEventsCleanupDialog(ref),
            icon: const Icon(Icons.delete_forever),
            label: const Text('孤立イベントを削除'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }


  /// 孤立イベント削除ダイアログ
  void _showOrphanedEventsCleanupDialog(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('孤立イベント削除'),
        content: const Text(
          'Google Calendarに残っているが、アプリに存在しないタスクのイベントを削除します。\n'
          'アプリで削除されたタスクのイベントがGoogle Calendarに残っている場合に使用してください。\n\n'
          'この操作は取り消せません。実行しますか？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performOrphanedEventsCleanup(ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除実行'),
          ),
        ],
      ),
    );
  }

  /// 孤立イベント削除を実行
  Future<void> _performOrphanedEventsCleanup(WidgetRef ref) async {
    final syncStatusNotifier = ref.read(syncStatusProvider.notifier);
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    
    try {
      syncStatusNotifier.startSync(
        message: '孤立イベントを検出中...',
      );
      
      final result = await taskViewModel.deleteOrphanedCalendarEvents();
      
      if (result['success'] == true) {
        final deletedCount = result['deletedCount'] ?? 0;
        
        syncStatusNotifier.syncSuccess(
          message: '孤立イベント削除完了: ${deletedCount}件削除',
        );
        
        if (deletedCount > 0) {
          SnackBarService.showSuccess(context, '孤立イベント${deletedCount}件を削除しました');
        } else {
          SnackBarService.showSuccess(context, '孤立イベントは見つかりませんでした');
        }
      } else {
        syncStatusNotifier.syncError(
          errorMessage: result['error'] ?? '不明なエラー',
          message: '孤立イベント削除に失敗しました',
        );
        SnackBarService.showError(context, '孤立イベント削除に失敗しました: ${result['error']}');
      }
    } catch (e) {
      syncStatusNotifier.syncError(
        errorMessage: e.toString(),
        message: '孤立イベント削除中にエラーが発生しました',
      );
      SnackBarService.showError(context, '孤立イベント削除中にエラーが発生しました: $e');
    }
  }

  /// 重複クリーンアップダイアログ
  void _showDuplicateCleanupDialog(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: '重複イベントクリーンアップ',
        icon: Icons.cleaning_services,
        iconColor: Colors.orange,
        content: const Text(
          'Google Calendarの重複したイベントを検出・削除します。\n'
          '同じタイトルと日付のイベントが複数ある場合、古いものを削除します。\n\n'
          'この操作は取り消せません。実行しますか？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppButtonStyles.text(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDuplicateCleanup(ref);
            },
            style: AppButtonStyles.warning(context),
            child: const Text('クリーンアップ実行'),
          ),
        ],
      ),
    );
  }

  /// 重複クリーンアップを実行
  Future<void> _performDuplicateCleanup(WidgetRef ref) async {
    final syncStatusNotifier = ref.read(syncStatusProvider.notifier);
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    
    try {
      syncStatusNotifier.startSync(
        message: '重複イベントを検出中...',
      );
      
      final result = await taskViewModel.cleanupGoogleCalendarDuplicates();
      
      if (result['success'] == true) {
        final duplicatesFound = result['duplicatesFound'] ?? 0;
        final duplicatesRemoved = result['duplicatesRemoved'] ?? 0;
        
        syncStatusNotifier.syncSuccess(
          message: '重複クリーンアップ完了: ${duplicatesFound}グループ検出、${duplicatesRemoved}件削除',
        );
        
        if (duplicatesRemoved > 0) {
          SnackBarService.showSuccess(context, '重複イベント${duplicatesRemoved}件を削除しました');
        } else {
          SnackBarService.showSuccess(context, '重複イベントは見つかりませんでした');
        }
      } else {
        syncStatusNotifier.syncError(
          errorMessage: result['error'] ?? '不明なエラー',
          message: '重複クリーンアップに失敗しました',
        );
        SnackBarService.showError(context, '重複クリーンアップに失敗しました: ${result['error']}');
      }
    } catch (e) {
      syncStatusNotifier.syncError(
        errorMessage: e.toString(),
        message: '重複クリーンアップ中にエラーが発生しました',
      );
      SnackBarService.showError(context, '重複クリーンアップ中にエラーが発生しました: $e');
    }
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

  /// Gmail API設定セクション
  Widget _buildGmailApiSection(SettingsState settingsState, SettingsNotifier settingsNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Gmail API連携', FontAwesomeIcons.envelope),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gmail API連携トグル
                SwitchListTile(
                  title: const Text('Gmail API連携'),
                  subtitle: const Text('Gmail APIを使用してメール受信時の自動タスク生成と完了報告機能を利用します'),
                  value: settingsState.gmailApiEnabled,
                  onChanged: (value) {
                    settingsNotifier.updateGmailApiEnabled(value);
                  },
                  secondary: const Icon(Icons.email),
                ),
                const SizedBox(height: 16),
                
                // Gmail API説明（トグルがオンの時のみ表示）
                if (settingsState.gmailApiEnabled) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                            Icon(Icons.info, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Gmail API連携について',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gmail APIを使用して、メール受信時の自動タスク生成と完了報告機能を利用できます。\n'
                        '自分宛てのメールで「依頼」「タスク」「お願い」などのキーワードが含まれている場合、自動でタスクとして登録されます。',
                        style: TextStyle(
                          fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ],
                
                // アクセストークン設定（トグルがオンの時のみ表示）
                if (settingsState.gmailApiEnabled) ...[
                _buildAccessTokenSection(),
                
                const SizedBox(height: 16),
                
                // テスト機能
                _buildTestSection(),
                
                const SizedBox(height: 16),
                
                // 設定情報
                _buildGmailApiInfo(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// アクセストークン設定セクション
  Widget _buildAccessTokenSection() {
    return Consumer(
      builder: (context, ref, child) {
        final settingsService = ref.watch(settingsServiceProvider);
        final currentToken = settingsService.gmailApiAccessToken ?? '';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'アクセストークン設定',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gmail APIのアクセストークンを設定してください。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            
            // アクセストークン入力フィールド
            TextFormField(
              initialValue: currentToken,
              decoration: const InputDecoration(
                labelText: 'アクセストークン',
                hintText: 'Gmail APIのアクセストークンを入力',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              maxLines: 1,
              onChanged: (value) {
                // アクセストークンを保存
                _saveGmailAccessToken(value);
              },
            ),
        
            const SizedBox(height: 8),
            
            // アクセストークン取得ボタン
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                    onPressed: _openGmailApiSetupGuide,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('設定方法を確認'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ElevatedButton.icon(
                    onPressed: _testGmailConnection,
                    icon: const Icon(Icons.wifi_protected_setup),
                    label: const Text('接続テスト'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Outlook連携セクション
  Widget _buildOutlookSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Outlook連携', FontAwesomeIcons.microsoft),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 説明
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Outlook連携について',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Outlook APIを使用して、メール受信時の自動タスク生成機能を利用できます。\n会社PCでのみ利用可能です。',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                
                // PowerShellファイルの詳細説明
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'PowerShellファイルの詳細',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      _buildPowerShellFileInfo(
                        'company_outlook_test.ps1',
                        'Outlook接続テスト',
                        'Outlookアプリケーションとの接続をテストします',
                        'C:\\Apps\\',
                        '手動実行',
                      ),
                      
                      _buildPowerShellFileInfo(
                        'company_task_search.ps1',
                        'タスク関連メール検索',
                        '件名・本文からタスク関連メールを検索し、タスク情報を抽出します',
                        'C:\\Apps\\',
                        '手動実行',
                      ),
                      
                      _buildPowerShellFileInfo(
                        'compose_mail.ps1',
                        'メール作成支援',
                        'タスクから返信メールを作成する際の支援機能',
                        'C:\\Apps\\',
                        '手動実行',
                      ),
                      
                      _buildPowerShellFileInfo(
                        'find_sent.ps1',
                        '送信メール検索',
                        '送信済みメールの検索・確認機能',
                        'C:\\Apps\\',
                        '手動実行',
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '重要な注意事項',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '• 管理者権限は不要（ユーザーレベルで実行可能）\n'
                              '• すべてのファイルは C:\\Apps\\ に配置してください\n'
                              '• ファイル名は正確に一致させる必要があります\n'
                              '• 実行ポリシーが制限されている場合は手動で許可が必要です\n'
                              '• 会社PCのセキュリティポリシーにより動作しない場合があります',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // 接続テストとタスク自動生成ボタン
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _testOutlookConnection,
                      icon: const Icon(Icons.wifi_protected_setup),
                      label: const Text('接続テスト'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _testOutlookSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('メール検索テスト'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _generateTasksFromOutlook,
                      icon: const Icon(Icons.add_task),
                      label: const Text('タスク自動生成'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Outlook設定情報
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outlook設定情報',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 必要な権限: Outlook読み取り\n• 対応機能: メール受信監視、タスク自動生成\n• 検索対象: 件名に「依頼」「タスク」「お願い」等のキーワード\n• 監視間隔: 手動実行',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  /// テスト機能セクション
  Widget _buildTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'テスト機能',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
                onPressed: _testGmailSearch,
                icon: const Icon(Icons.search),
                label: const Text('メール検索テスト'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ElevatedButton.icon(
              onPressed: _generateTasksFromGmail,
              icon: const Icon(Icons.add_task),
              label: const Text('タスク自動生成'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
                onPressed: _sendTestCompletionReport,
                icon: const Icon(Icons.send),
                label: const Text('完了報告テスト'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Gmail API情報セクション
  Widget _buildGmailApiInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gmail API設定情報',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• 必要な権限: Gmail読み取り、Gmail送信\n'
            '• 対応機能: メール受信監視、タスク自動生成、完了報告\n'
            '• 検索対象: 件名に「依頼」「タスク」「お願い」等のキーワード\n'
            '• 監視間隔: 5分ごと',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Gmail API設定ガイドを開く
  void _openGmailApiSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: 'Gmail API設定ガイド',
        icon: Icons.help_outline,
        iconColor: Colors.orange,
        width: 700,
        height: 700,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gmail APIを使用するための設定手順:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGuideStep('1', 'Google Cloud Consoleにアクセス'),
            const Text('https://console.cloud.google.com/'),
            const SizedBox(height: 12),
            _buildGuideStep('2', '新しいプロジェクトを作成または既存プロジェクトを選択'),
            const SizedBox(height: 12),
            _buildGuideStep('3', 'Gmail APIを有効化'),
            const Text('「APIとサービス」→「ライブラリ」→「Gmail API」を検索して有効化'),
            const SizedBox(height: 12),
            _buildGuideStep('4', '認証情報を作成'),
            const Text('「APIとサービス」→「認証情報」→「認証情報を作成」→「OAuth 2.0 クライアント ID」'),
            const SizedBox(height: 12),
            _buildGuideStep('5', 'アクセストークンを取得'),
            const Text('OAuth 2.0 Playground (https://developers.google.com/oauthplayground/) を使用'),
            const Text('1. 左側で「Gmail API v1」→「https://www.googleapis.com/auth/gmail.readonly」を選択'),
            const Text('2. 「Authorize APIs」をクリックしてGoogleアカウントで認証'),
            const Text('3. 右側の「Exchange authorization code for tokens」をクリック'),
            const Text('4. 生成された「Access token」をコピー'),
            const SizedBox(height: 12),
            _buildGuideStep('6', 'アクセストークンを入力'),
            const Text('上記の「アクセストークン」フィールドに取得したトークンを入力'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppButtonStyles.text(context),
            child: const Text('閉じる'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await Process.run('cmd', ['/c', 'start', 'https://console.cloud.google.com/']);
                Navigator.pop(context);
              } catch (e) {
                SnackBarService.showError(context, 'ブラウザを開けませんでした: $e');
              }
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Google Cloud Consoleを開く'),
            style: AppButtonStyles.primary(context),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await Process.run('cmd', ['/c', 'start', 'https://developers.google.com/oauthplayground/']);
                Navigator.pop(context);
              } catch (e) {
                SnackBarService.showError(context, 'ブラウザを開けませんでした: $e');
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('OAuth 2.0 Playgroundを開く'),
            style: AppButtonStyles.secondary(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Google Calendar設定ガイドを開く
  void _openGoogleCalendarSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: 'Google Calendar設定ガイド',
        icon: Icons.calendar_today,
        iconColor: Colors.blue,
        width: 700,
        height: 800,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Calendar APIを使用するための設定手順:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGuideStep('1', 'Google Cloud Consoleにアクセス'),
            const Text('https://console.cloud.google.com/'),
            const SizedBox(height: 12),
            _buildGuideStep('2', '新しいプロジェクトを作成または既存プロジェクトを選択'),
            const SizedBox(height: 12),
            _buildGuideStep('3', 'Google Calendar APIを有効化'),
            const Text('「APIとサービス」→「ライブラリ」→「Google Calendar API」を検索して有効化'),
            const SizedBox(height: 12),
            _buildGuideStep('4', 'OAuth2クライアントIDを作成'),
            const Text('「APIとサービス」→「認証情報」→「認証情報を作成」→「OAuth2クライアントID」→「デスクトップアプリケーション」'),
            const SizedBox(height: 12),
            _buildGuideStep('5', '認証情報ファイルをダウンロード'),
            const Text('作成したOAuth2クライアントIDの「ダウンロード」ボタンからJSONファイルをダウンロード'),
            const SizedBox(height: 12),
            _buildGuideStep('6', 'ファイルをアプリフォルダに配置'),
            const Text('ダウンロードしたJSONファイルを「oauth2_credentials.json」としてアプリフォルダに配置'),
            const SizedBox(height: 12),
            _buildGuideStep('7', 'OAuth2認証を実行'),
            const Text('アプリの「OAuth2認証を開始」ボタンをクリックして認証を完了'),
            const SizedBox(height: 12),
            
            // トークンファイルの説明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '自動生成されるファイル',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OAuth2認証完了後、アプリが自動的に「google_calendar_tokens.json」ファイルを生成します。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'このファイルには以下の情報が含まれます：',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• access_token: Google Calendar APIへのアクセス権限',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                        ),
                        Text(
                          '• refresh_token: アクセストークンの更新用',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                        ),
                        Text(
                          '• expires_at: トークンの有効期限',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '※ このファイルは手動で編集する必要はありません。',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppButtonStyles.text(context),
            child: const Text('閉じる'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await Process.run('cmd', ['/c', 'start', 'https://console.cloud.google.com/']);
                Navigator.pop(context);
              } catch (e) {
                SnackBarService.showError(context, 'ブラウザを開けませんでした: $e');
              }
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Google Cloud Consoleを開く'),
            style: AppButtonStyles.primary(context),
          ),
        ],
      ),
    );
  }

  /// Gmail接続をテスト
  Future<void> _testGmailConnection() async {
    try {
      final settingsService = ref.read(settingsServiceProvider);
      final accessToken = settingsService.gmailApiAccessToken;
      
      if (accessToken == null || accessToken.isEmpty) {
        SnackBarService.showError(context, 'アクセストークンが設定されていません。先にアクセストークンを入力してください。');
        return;
      }
      
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Gmail API接続テスト
      final gmailApiService = GmailApiService();
      final isConnected = await gmailApiService.testConnection(accessToken);
      
      // 接続テスト成功時にアクセストークンを設定
      if (isConnected) {
        gmailApiService.setAccessToken(accessToken);
      }
      
      // ローディングを閉じる
      Navigator.pop(context);
      
      if (isConnected) {
        SnackBarService.showSuccess(context, 'Gmail API接続テストが成功しました！');
      } else {
        SnackBarService.showError(context, 'Gmail API接続テストが失敗しました。アクセストークンを確認してください。');
      }
    } catch (e) {
      // ローディングを閉じる（エラー時）
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      SnackBarService.showError(context, 'Gmail接続テストエラー: $e');
    }
  }

  /// Gmail検索をテスト
  Future<void> _testGmailSearch() async {
    try {
      final gmailApiService = GmailApiService();
      final assignments = await gmailApiService.searchTaskAssignmentEmails();
      
      SnackBarService.showSuccess(
        context, 
        'Gmail検索テスト完了: ${assignments.length}件のタスク割り当てメールを発見'
      );
    } catch (e) {
      SnackBarService.showError(context, 'Gmail検索テストエラー: $e');
    }
  }

  /// Gmail APIからタスクを自動生成
  Future<void> _generateTasksFromGmail() async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // タスクビューモデルからGmail APIでタスクを生成
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final result = await taskViewModel.generateTasksFromGmail();
      
      // ローディングを閉じる
      Navigator.pop(context);
      
      if (result['success']) {
        final addedCount = result['addedCount'] as int;
        final total = result['total'] as int;
        
        if (addedCount > 0) {
          SnackBarService.showSuccess(
            context, 
            '${addedCount}件のタスクを自動生成しました（検索結果: ${total}件）'
          );
        } else {
          SnackBarService.showInfo(
            context, 
            'タスク割り当てメールが見つかりませんでした'
          );
        }
      } else {
        SnackBarService.showError(
          context, 
          'タスク生成エラー: ${result['message']}'
        );
      }
    } catch (e) {
      // ローディングを閉じる（エラー時も）
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      SnackBarService.showError(context, 'タスク生成エラー: $e');
    }
  }

  /// Outlook接続をテスト
  Future<void> _testOutlookConnection() async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Outlook接続テスト
      final outlookService = OutlookService();
      final isConnected = await outlookService.testConnection();
      
      // ローディングを閉じる
      Navigator.pop(context);
      
      if (isConnected) {
        SnackBarService.showSuccess(context, 'Outlook接続テストが成功しました！');
      } else {
        SnackBarService.showError(context, 'Outlook接続テストが失敗しました。Outlookが起動しているか確認してください。');
      }
    } catch (e) {
      // ローディングを閉じる（エラー時も）
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      SnackBarService.showError(context, 'Outlook接続テストエラー: $e');
    }
  }
  
  /// Outlookメール検索をテスト
  Future<void> _testOutlookSearch() async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Outlookメール検索テスト
      final outlookService = OutlookService();
      final assignments = await outlookService.searchTaskAssignmentEmails();
      
      // ローディングを閉じる
      Navigator.pop(context);
      
      SnackBarService.showSuccess(
        context, 
        'Outlook検索テスト完了: ${assignments.length}件のタスク割り当てメールを発見'
      );
    } catch (e) {
      // ローディングを閉じる（エラー時も）
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      SnackBarService.showError(context, 'Outlook検索テストエラー: $e');
    }
  }
  
  /// Outlookからタスクを自動生成
  Future<void> _generateTasksFromOutlook() async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // タスクビューモデルからOutlookでタスクを生成
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final result = await taskViewModel.generateTasksFromOutlook();
      
      // ローディングを閉じる
      Navigator.pop(context);
      
      if (result['success']) {
        final addedCount = result['addedCount'] as int;
        final total = result['total'] as int;
        
        if (addedCount > 0) {
          SnackBarService.showSuccess(
            context, 
            '${addedCount}件のタスクを自動生成しました（検索結果: ${total}件）'
          );
        } else {
          SnackBarService.showInfo(
            context, 
            'タスク割り当てメールが見つかりませんでした'
          );
        }
      } else {
        SnackBarService.showError(
          context, 
          'タスク生成エラー: ${result['message']}'
        );
      }
    } catch (e) {
      // ローディングを閉じる（エラー時も）
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      SnackBarService.showError(context, 'タスク生成エラー: $e');
    }
  }

  /// 完了報告テストを送信
  Future<void> _sendTestCompletionReport() async {
    try {
      final gmailApiService = GmailApiService();
      final success = await gmailApiService.sendCompletionReport(
        'test@example.com',
        'テストタスク',
        'これはテスト完了報告です。',
      );
      
      if (success) {
        SnackBarService.showSuccess(context, '完了報告テスト送信完了');
      } else {
        SnackBarService.showError(context, '完了報告テスト送信失敗');
      }
    } catch (e) {
      SnackBarService.showError(context, '完了報告テストエラー: $e');
    }
  }

  /// Gmailアクセストークンを保存
  void _saveGmailAccessToken(String token) async {
    try {
      final settingsService = SettingsService.instance;
      await settingsService.setGmailApiAccessToken(token.isEmpty ? null : token);
      
      if (kDebugMode) {
        print('Gmailアクセストークンを保存: ${token.isNotEmpty ? token.substring(0, 10) + '...' : '削除'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gmailアクセストークン保存エラー: $e');
      }
    }
  }
  
}

// 設定セクション管理用プロバイダー
final settingsSectionProvider = StateProvider<String>((ref) => 'theme');
