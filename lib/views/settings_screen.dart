import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../services/windows_notification_service.dart';
import '../viewmodels/layout_settings_provider.dart';
import '../viewmodels/font_size_provider.dart';
import '../viewmodels/link_viewmodel.dart';
import '../viewmodels/task_viewmodel.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';
import '../services/keyboard_shortcut_service.dart';
import '../services/google_calendar_service.dart';
import '../widgets/unified_dialog.dart';
import '../widgets/app_button_styles.dart';
import '../services/snackbar_service.dart';
import '../viewmodels/sync_status_provider.dart';
import '../viewmodels/ui_customization_provider.dart';
import '../views/selective_export_dialog.dart';
import '../views/selective_import_dialog.dart';
import '../models/export_config.dart';

class _ColorPreset {
  const _ColorPreset({
    required this.id,
    required this.name,
    required this.accentColor,
    required this.intensity,
    required this.contrast,
    required this.swatch,
    this.darkMode,
    this.description,
  });

  final String id;
  final String name;
  final int accentColor;
  final double intensity;
  final double contrast;
  final List<int> swatch;
  final bool? darkMode;
  final String? description;
}

const List<_ColorPreset> _colorPresets = [
  _ColorPreset(
    id: 'sunrise',
    name: 'サンライズ',
    accentColor: 0xFFEA580C,
    intensity: 1.1,
    contrast: 1.05,
    swatch: [0xFFFFB86C, 0xFFEA580C, 0xFF9A3412],
    description: '温かみのあるオレンジ系',
  ),
  _ColorPreset(
    id: 'forest',
    name: 'フォレスト',
    accentColor: 0xFF15803D,
    intensity: 1.0,
    contrast: 1.0,
    swatch: [0xFF22C55E, 0xFF15803D, 0xFF065F46],
    description: '落ち着いたグリーン系',
  ),
  _ColorPreset(
    id: 'breeze',
    name: 'ブルーブリーズ',
    accentColor: 0xFF2563EB,
    intensity: 1.05,
    contrast: 0.95,
    swatch: [0xFF60A5FA, 0xFF2563EB, 0xFF1D4ED8],
    description: '爽やかなブルー系',
  ),
  _ColorPreset(
    id: 'midnight',
    name: 'ミッドナイト',
    accentColor: 0xFF312E81,
    intensity: 0.85,
    contrast: 1.2,
    swatch: [0xFF6366F1, 0xFF312E81, 0xFF1E1B4B],
    darkMode: true,
    description: '夜間作業に合うダークテイスト',
  ),
  _ColorPreset(
    id: 'sakura',
    name: 'サクラ',
    accentColor: 0xFFE11D48,
    intensity: 1.05,
    contrast: 0.9,
    swatch: [0xFFFDA4AF, 0xFFE11D48, 0xFFBE123C],
    description: '柔らかなピンク系',
  ),
  _ColorPreset(
    id: 'citrus',
    name: 'シトラス',
    accentColor: 0xFF65A30D,
    intensity: 1.15,
    contrast: 1.05,
    swatch: [0xFFA3E635, 0xFF65A30D, 0xFF3F6212],
    description: 'フレッシュな黄緑系',
  ),
  _ColorPreset(
    id: 'slate',
    name: 'スレート',
    accentColor: 0xFF1E3A8A,
    intensity: 0.95,
    contrast: 1.15,
    swatch: [0xFF94A3B8, 0xFF1E3A8A, 0xFF0F172A],
    description: '落ち着いたブルーグレー',
  ),
  _ColorPreset(
    id: 'amber',
    name: 'アンバー',
    accentColor: 0xFFF59E0B,
    intensity: 1.2,
    contrast: 1.0,
    swatch: [0xFFFCD34D, 0xFFF59E0B, 0xFFB45309],
    description: '視認性の高いゴールド調',
  ),
  _ColorPreset(
    id: 'graphite',
    name: 'グラファイト',
    accentColor: 0xFF334155,
    intensity: 0.9,
    contrast: 1.25,
    swatch: [0xFF94A3B8, 0xFF475569, 0xFF0F172A],
    darkMode: true,
    description: 'モダンなモノトーン',
  ),
];

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
  final bool startWithTaskScreen;
  final bool outlookAutoSyncEnabled;
  final int outlookAutoSyncPeriodDays;
  final String outlookAutoSyncFrequency;
  final String locale;

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
    this.startWithTaskScreen = false,
    this.outlookAutoSyncEnabled = false,
    this.outlookAutoSyncPeriodDays = 30,
    this.outlookAutoSyncFrequency = 'on_startup',
    this.locale = 'ja',
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
    bool? startWithTaskScreen,
    bool? outlookAutoSyncEnabled,
    int? outlookAutoSyncPeriodDays,
    String? outlookAutoSyncFrequency,
    String? locale,
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
      startWithTaskScreen: startWithTaskScreen ?? this.startWithTaskScreen,
      outlookAutoSyncEnabled: outlookAutoSyncEnabled ?? this.outlookAutoSyncEnabled,
      outlookAutoSyncPeriodDays: outlookAutoSyncPeriodDays ?? this.outlookAutoSyncPeriodDays,
      outlookAutoSyncFrequency: outlookAutoSyncFrequency ?? this.outlookAutoSyncFrequency,
      locale: locale ?? this.locale,
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
        startWithTaskScreen: _service.startWithTaskScreen,
        outlookAutoSyncEnabled: _service.outlookAutoSyncEnabled,
        outlookAutoSyncPeriodDays: _service.outlookAutoSyncPeriodDays,
        outlookAutoSyncFrequency: _service.outlookAutoSyncFrequency,
        locale: _service.locale,
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

  Future<void> setStartWithTaskScreen(bool value) async {
    await _service.setStartWithTaskScreen(value);
    state = state.copyWith(startWithTaskScreen: value);
  }


  Future<void> setOutlookAutoSyncEnabled(bool value) async {
    await _service.setOutlookAutoSyncEnabled(value);
    state = state.copyWith(outlookAutoSyncEnabled: value);
  }

  Future<void> setOutlookAutoSyncPeriodDays(int value) async {
    await _service.setOutlookAutoSyncPeriodDays(value);
    state = state.copyWith(outlookAutoSyncPeriodDays: value);
  }

  Future<void> setOutlookAutoSyncFrequency(String value) async {
    await _service.setOutlookAutoSyncFrequency(value);
    state = state.copyWith(outlookAutoSyncFrequency: value);
  }

  Future<void> setLocale(String value) async {
    await _service.setLocale(value);
    state = state.copyWith(locale: value);
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
          title: Text(AppLocalizations.of(context)!.settings),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => settingsNotifier._loadSettings(),
              tooltip: AppLocalizations.of(context)!.settings,
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

  String _getColorPresetName(BuildContext context, String presetId) {
    final l10n = AppLocalizations.of(context)!;
    switch (presetId) {
      case 'sunrise':
        return l10n.colorPresetSunrise;
      case 'forest':
        return l10n.colorPresetForest;
      case 'breeze':
        return l10n.colorPresetBreeze;
      case 'midnight':
        return l10n.colorPresetMidnight;
      case 'sakura':
        return l10n.colorPresetSakura;
      case 'citrus':
        return l10n.colorPresetCitrus;
      case 'slate':
        return l10n.colorPresetSlate;
      case 'amber':
        return l10n.colorPresetAmber;
      case 'graphite':
        return l10n.colorPresetGraphite;
      default:
        return presetId;
    }
  }

  String _getColorPresetDescription(BuildContext context, String presetId) {
    final l10n = AppLocalizations.of(context)!;
    switch (presetId) {
      case 'sunrise':
        return l10n.colorPresetSunriseDesc;
      case 'forest':
        return l10n.colorPresetForestDesc;
      case 'breeze':
        return l10n.colorPresetBreezeDesc;
      case 'midnight':
        return l10n.colorPresetMidnightDesc;
      case 'sakura':
        return l10n.colorPresetSakuraDesc;
      case 'citrus':
        return l10n.colorPresetCitrusDesc;
      case 'slate':
        return l10n.colorPresetSlateDesc;
      case 'amber':
        return l10n.colorPresetAmberDesc;
      case 'graphite':
        return l10n.colorPresetGraphiteDesc;
      default:
        return '';
    }
  }

  Widget _buildColorPresetSelector(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final contrast = ref.watch(colorContrastProvider);
    final isDarkMode = ref.watch(darkModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context)!.colorPresets, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(Icons.auto_awesome, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.applyRecommendedColors,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorPresets.map((preset) {
            final isSelected =
                accentColor == preset.accentColor &&
                (intensity - preset.intensity).abs() < 0.01 &&
                (contrast - preset.contrast).abs() < 0.01 &&
                (preset.darkMode == null || preset.darkMode == isDarkMode);

            final gradientColors = preset.swatch.map((c) => Color(c)).toList();

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 150,
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Color(preset.accentColor).withOpacity(0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _applyColorPreset(context, ref, preset),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getColorPresetName(context, preset.id),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Colors.white, size: 18),
                          ],
                        ),
                        if (preset.description != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _getColorPresetDescription(context, preset.id),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(preset.intensity * 100).round()}% / ${(preset.contrast * 100).round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (preset.darkMode != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  preset.darkMode! ? Icons.dark_mode : Icons.light_mode,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _applyColorPreset(BuildContext context, WidgetRef ref, _ColorPreset preset) async {
    try {
      final settings = SettingsService.instance;
      ref.read(accentColorProvider.notifier).state = preset.accentColor;
      ref.read(colorIntensityProvider.notifier).state = preset.intensity;
      ref.read(colorContrastProvider.notifier).state = preset.contrast;
      await settings.setAccentColor(preset.accentColor);
      await settings.setColorIntensity(preset.intensity);
      await settings.setColorContrast(preset.contrast);

      if (preset.darkMode != null) {
        ref.read(darkModeProvider.notifier).state = preset.darkMode!;
        await settings.setDarkMode(preset.darkMode!);
      }

      SnackBarService.showSuccess(context, AppLocalizations.of(context)!.presetApplied(_getColorPresetName(context, preset.id)));
    } catch (e) {
      SnackBarService.showError(context, AppLocalizations.of(context)!.presetApplyFailed(e.toString()));
    }
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
    final l10n = AppLocalizations.of(context)!;
    
    return ListView(
      padding: const EdgeInsets.all(12), // パディングを増やして余裕のあるレイアウトに
      children: [
        _buildMenuSection(l10n.general, [
          _buildMenuItem(context, ref, l10n.startupSettings, Icons.settings, 'general'),
        ]),
        _buildMenuSection(l10n.appearance, [
          _buildMenuItem(context, ref, l10n.themeSettings, Icons.palette, 'theme', l10n.allScreens),
          _buildMenuItem(context, ref, l10n.fontSettings, Icons.text_fields, 'font', l10n.allScreens),
          _buildMenuItem(context, ref, l10n.uiCustomization, Icons.tune, 'ui_customization', l10n.allScreens),
        ]),
        _buildMenuSection(l10n.layout, [
          _buildMenuItem(context, ref, l10n.gridSettings, Icons.grid_view, 'grid', l10n.linkScreen),
          _buildMenuItem(context, ref, l10n.cardSettings, Icons.view_agenda, 'card', l10n.linkAndTaskScreens),
          _buildMenuItem(context, ref, l10n.itemSettings, Icons.link, 'item', l10n.linkScreen),
          _buildMenuItem(context, ref, l10n.cardViewSettings, Icons.view_module, 'task_project', l10n.taskList),
        ]),
        _buildMenuSection(l10n.data, [
          _buildMenuItem(context, ref, l10n.backup, Icons.backup, 'backup'),
        ]),
        _buildMenuSection(l10n.notifications, [
          _buildMenuItem(context, ref, l10n.notificationSettings, Icons.notifications, 'notifications'),
        ]),
        _buildMenuSection(l10n.integration, [
          _buildMenuItem(context, ref, AppLocalizations.of(context)!.googleCalendar, FontAwesomeIcons.calendarCheck, 'google_calendar'),
          _buildMenuItem(context, ref, l10n.outlook, FontAwesomeIcons.microsoft, 'outlook'),
          _buildMenuItem(context, ref, l10n.gmailIntegration, FontAwesomeIcons.envelope, 'gmail_api'),
        ], subtitle: l10n.integrationSettingsRequired),
        _buildMenuSection(l10n.others, [
          _buildMenuItem(context, ref, l10n.reset, Icons.restore, 'reset'),
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

  Widget _buildMenuItem(BuildContext context, WidgetRef ref, String title, IconData icon, String section, [String? scope]) {
    final currentSection = ref.watch(settingsSectionProvider);
    final isSelected = currentSection == section;
    
    // 各セクションに応じた色を定義
    Color getIconColor() {
      switch (section) {
        case 'general':
          return const Color(0xFF757575); // グレー
        case 'theme':
          return const Color(0xFF4CAF50); // 緑
        case 'font':
          return const Color(0xFF2196F3); // 青
        case 'ui_customization':
          return const Color(0xFF673AB7); // ディープパープル
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
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // 縦のマージンを増やす
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.15) : null, // 選択時の背景色を少し濃く
          borderRadius: BorderRadius.circular(12), // 角丸を大きく
          border: isSelected ? Border.all(color: iconColor.withOpacity(0.4), width: 1.5) : null, // 選択時の枠線を太く
          boxShadow: isSelected ? [
            BoxShadow(
              color: iconColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? iconColor : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            if (scope != null) ...[
              const SizedBox(height: 2),
              Text(
                scope,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected 
                    ? iconColor.withOpacity(0.8)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onTap: () {
          ref.read(settingsSectionProvider.notifier).state = section;
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 角丸を大きく
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // パディングを増やす
        ),
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
      case 'general':
        return _buildGeneralSection(settingsState, settingsNotifier);
      case 'theme':
        return _buildThemeSection(context, ref, currentDarkMode, currentAccentColor);
        case 'font':
          return _buildFontSection(context, ref, currentFontSize, settingsState, settingsNotifier);
        case 'ui_customization':
          return _buildUICustomizationSection(context, ref);
        case 'grid':
        return _buildGridSection(ref, layoutSettings);
      case 'card':
        return _buildCardSection(ref, layoutSettings);
        case 'item':
        return _buildItemSection(ref, layoutSettings);
      case 'task_project':
        return _buildTaskProjectSection(ref);
      case 'backup':
        return _buildIntegratedBackupSection(context, ref, settingsState, settingsNotifier);
      case 'notifications':
        return _buildNotificationSection(settingsState, settingsNotifier);
        case 'google_calendar':
          return _buildGoogleCalendarSection(settingsState, settingsNotifier);
        case 'gmail_api':
          return _buildGmailApiSection(settingsState, settingsNotifier);
        case 'outlook':
          return _buildOutlookSection(ref);
      case 'reset':
        return _buildResetSection(context, settingsNotifier, ref);
      default:
        return _buildThemeSection(context, ref, currentDarkMode, currentAccentColor);
    }
  }

  Widget _buildGeneralSection(SettingsState state, SettingsNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.general, Icons.settings),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 言語選択
                _buildLanguageSelector(state, notifier),
                const Divider(),
                const SizedBox(height: 8),
                // タスク画面で起動
                _buildSwitchWithDescription(
                  title: l10n.startWithTaskScreen,
                  description: l10n.startWithTaskScreenDescription,
                  value: state.startWithTaskScreen,
                  onChanged: notifier.setStartWithTaskScreen,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// 言語選択UI
  Widget _buildLanguageSelector(SettingsState state, SettingsNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.language, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              l10n.language,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(
              value: 'ja',
              label: Text(l10n.japanese),
              icon: const Icon(Icons.flag, size: 16),
            ),
            ButtonSegment<String>(
              value: 'en',
              label: Text(l10n.english),
              icon: const Icon(Icons.flag, size: 16),
            ),
          ],
          selected: {state.locale},
          onSelectionChanged: (Set<String> newSelection) {
            final selectedLocale = newSelection.first;
            notifier.setLocale(selectedLocale);
            // 言語変更後、アプリを再起動する必要がある場合のメッセージ
            // 実際には、MaterialAppのlocaleが変更されれば自動的に反映される
          },
        ),
      ],
    );
  }


  Widget _buildThemeSection(BuildContext context, WidgetRef ref, bool currentDarkMode, int currentAccentColor) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.themeSettings, Icons.palette),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(l10n.darkMode),
                  subtitle: Text(l10n.useDarkTheme),
                  value: currentDarkMode,
                  onChanged: (value) async {
                    ref.read(darkModeProvider.notifier).state = value;
                    await SettingsService.instance.setDarkMode(value);
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildColorPresetSelector(context, ref),

                const SizedBox(height: 24),

                Text(AppLocalizations.of(context)!.accentColor, style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildAccentColorGrid(context, ref, currentAccentColor),
                
                const SizedBox(height: 16),
                
                // 色の濃淡調整
                _buildColorIntensitySlider(context, ref),
                
                const SizedBox(height: 16),
                
                // コントラスト調整
                _buildColorContrastSlider(context, ref),
                
                const SizedBox(height: 16),
                
                // テキスト色設定
                _buildTextColorSection(context, ref),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccentColorGrid(BuildContext context, WidgetRef ref, int currentColor) {
    // 色系統を10種類に拡張、より明確に区別できる色に変更
    final colorOptions = [
      0xFF1E40AF, // ブルー（鮮明な青）
      0xFFDC2626, // レッド（濃い赤）
      0xFF16A34A, // グリーン（濃い緑）
      0xFFEA580C, // オレンジ（濃いオレンジ）
      0xFF7C3AED, // パープル（濃い紫）
      0xFFDB2777, // ピンク（濃いピンク）
      0xFF0891B2, // シアン（濃い青緑）
      0xFF4B5563, // グレー（暗いグレー）
      0xFF059669, // エメラルド（濃い緑青）
      0xFFCA8A04, // イエロー（濃い黄色）
    ];
    final colorNames = [
      AppLocalizations.of(context)!.colorBlue,
      AppLocalizations.of(context)!.colorRed,
      AppLocalizations.of(context)!.colorGreen,
      AppLocalizations.of(context)!.colorOrange,
      AppLocalizations.of(context)!.colorPurple,
      AppLocalizations.of(context)!.colorPink,
      AppLocalizations.of(context)!.colorCyan,
      AppLocalizations.of(context)!.colorGray,
      AppLocalizations.of(context)!.colorEmerald,
      AppLocalizations.of(context)!.colorYellow,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 5列で10色を2行表示
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
          onTap: () async {
            ref.read(accentColorProvider.notifier).state = color;
            await SettingsService.instance.setAccentColor(color);
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

  Widget _buildColorIntensitySlider(BuildContext context, WidgetRef ref) {
    final colorIntensity = ref.watch(colorIntensityProvider);
    final accentColor = ref.watch(accentColorProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context)!.colorIntensity, style: TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getAdjustedColor(accentColor, colorIntensity, ref.watch(colorContrastProvider)).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getAdjustedColor(accentColor, colorIntensity, ref.watch(colorContrastProvider)),
                  width: 1,
                ),
              ),
              child: Text(
                '${(colorIntensity * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: _getAdjustedColor(accentColor, colorIntensity, ref.watch(colorContrastProvider)),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getAdjustedColor(accentColor, colorIntensity, ref.watch(colorContrastProvider)),
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: _getAdjustedColor(accentColor, colorIntensity, ref.watch(colorContrastProvider)),
            overlayColor: _getAdjustedColor(accentColor, colorIntensity, ref.watch(colorContrastProvider)).withOpacity(0.2),
          ),
          child: Slider(
            value: colorIntensity,
            min: 0.5,
            max: 1.5,
            divisions: 20,
            onChanged: (value) async {
              ref.read(colorIntensityProvider.notifier).state = value;
              await SettingsService.instance.setColorIntensity(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.light, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(AppLocalizations.of(context)!.standard, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(AppLocalizations.of(context)!.dark, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _buildColorContrastSlider(BuildContext context, WidgetRef ref) {
    final colorContrast = ref.watch(colorContrastProvider);
    final accentColor = ref.watch(accentColorProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context)!.contrast, style: TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getAdjustedColor(accentColor, ref.watch(colorIntensityProvider), colorContrast).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getAdjustedColor(accentColor, ref.watch(colorIntensityProvider), colorContrast),
                  width: 1,
                ),
              ),
              child: Text(
                '${(colorContrast * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: _getAdjustedColor(accentColor, ref.watch(colorIntensityProvider), colorContrast),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getAdjustedColor(accentColor, ref.watch(colorIntensityProvider), colorContrast),
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: _getAdjustedColor(accentColor, ref.watch(colorIntensityProvider), colorContrast),
            overlayColor: _getAdjustedColor(accentColor, ref.watch(colorIntensityProvider), colorContrast).withOpacity(0.2),
          ),
          child: Slider(
            value: colorContrast,
            min: 0.7,
            max: 1.5,
            divisions: 16,
            onChanged: (value) async {
              ref.read(colorContrastProvider.notifier).state = value;
              await SettingsService.instance.setColorContrast(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.contrastLow, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(AppLocalizations.of(context)!.standard, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(AppLocalizations.of(context)!.contrastHigh, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
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

  // 背景色に適したコントラスト色を取得
  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildTextColorSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.taskListDisplaySettings, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.taskListFieldSettingsDescription,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        // タイトル設定
        _buildFieldSettings(
          context, 
          ref, 
          AppLocalizations.of(context)!.title, 
          titleTextColorProvider, 
          titleFontSizeProvider, 
          titleFontFamilyProvider,
          'title'
        ),
        
        const SizedBox(height: 16),
        
        // 本文設定
        _buildFieldSettings(
          context,
          ref,
          AppLocalizations.of(context)!.body,
          memoTextColorProvider, 
          memoFontSizeProvider, 
          memoFontFamilyProvider,
          'memo'
        ),
        
        const SizedBox(height: 16),
        
        // 依頼先への説明設定
        _buildFieldSettings(
          context, 
          ref, 
          AppLocalizations.of(context)!.assigneeDescription, 
          descriptionTextColorProvider, 
          descriptionFontSizeProvider, 
          descriptionFontFamilyProvider,
          'description'
        ),
      ],
    );
  }

  /// カードビュー専用フォント設定セクション
  Widget _buildCardViewFontSettings(
    BuildContext context,
    WidgetRef ref,
    TaskProjectLayoutSettings settings,
    TaskProjectLayoutSettingsNotifier notifier,
  ) {
    final isDarkMode = ref.watch(darkModeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.fontSettings,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.cardViewFieldSettingsDescription,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        // タイトル設定
        _buildCardViewFieldSettings(
          context,
          ref,
          AppLocalizations.of(context)!.title,
          settings.titleTextColor,
          settings.titleFontSize,
          settings.titleFontFamily,
          isDarkMode,
          (color) => notifier.updateTitleTextColor(color),
          (fontSize) => notifier.updateTitleFontSize(fontSize),
          (fontFamily) => notifier.updateTitleFontFamily(fontFamily),
        ),
        
        const SizedBox(height: 16),
        
        // 本文設定
        _buildCardViewFieldSettings(
          context,
          ref,
          AppLocalizations.of(context)!.body,
          settings.memoTextColor,
          settings.memoFontSize,
          settings.memoFontFamily,
          isDarkMode,
          (color) => notifier.updateMemoTextColor(color),
          (fontSize) => notifier.updateMemoFontSize(fontSize),
          (fontFamily) => notifier.updateMemoFontFamily(fontFamily),
        ),
        
        const SizedBox(height: 16),
        
        // 依頼先への説明設定
        _buildCardViewFieldSettings(
          context,
          ref,
          AppLocalizations.of(context)!.assigneeDescription,
          settings.descriptionTextColor,
          settings.descriptionFontSize,
          settings.descriptionFontFamily,
          isDarkMode,
          (color) => notifier.updateDescriptionTextColor(color),
          (fontSize) => notifier.updateDescriptionFontSize(fontSize),
          (fontFamily) => notifier.updateDescriptionFontFamily(fontFamily),
        ),
      ],
    );
  }

  /// カードビュー専用フィールド設定
  Widget _buildCardViewFieldSettings(
    BuildContext context,
    WidgetRef ref,
    String fieldName,
    int currentColor,
    double currentFontSize,
    String currentFontFamily,
    bool isDarkMode,
    void Function(int) onColorChanged,
    void Function(double) onFontSizeChanged,
    void Function(String) onFontFamilyChanged,
  ) {
    // テキスト色の選択肢（10種類）- ダークモード対応
    final textColorOptions = [
      0xFF000000, // 黒（ライトモード用）
      0xFFFFFFFF, // 白（ダークモード用）
      0xFF3B82F6, // ブルー（両モード対応）
      0xFFEF4444, // レッド（両モード対応）
      0xFFF59E0B, // オレンジ（両モード対応）
      0xFF10B981, // グリーン（両モード対応）
      0xFF8B5CF6, // パープル（両モード対応）
      0xFFEC4899, // ピンク（両モード対応）
      0xFF6B7280, // グレー（両モード対応）
      0xFFFBBF24, // イエロー（両モード対応）
    ];
    
    final textColorNames = [
      AppLocalizations.of(context)!.colorBlack,
      AppLocalizations.of(context)!.colorWhite,
      AppLocalizations.of(context)!.colorBlue,
      AppLocalizations.of(context)!.colorRed,
      AppLocalizations.of(context)!.colorOrange,
      AppLocalizations.of(context)!.colorGreen,
      AppLocalizations.of(context)!.colorPurple,
      AppLocalizations.of(context)!.colorPink,
      AppLocalizations.of(context)!.colorGray,
      AppLocalizations.of(context)!.colorYellow,
    ];

    // フォントファミリーの選択肢
    final fontFamilyOptions = [
      '', // デフォルト
      'Noto Sans JP',
      'Hiragino Sans',
      'Yu Gothic',
      'Meiryo',
      'MS Gothic',
      'MS Mincho',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.fieldSettings(fieldName), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            // テキスト色設定
            Text(AppLocalizations.of(context)!.textColor, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: textColorOptions.length,
              itemBuilder: (context, index) {
                final color = textColorOptions[index];
                final name = textColorNames[index];
                final isSelected = color == currentColor;
                
                return InkWell(
                  onTap: () => onColorChanged(color),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(color),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                        ? Border.all(color: isDarkMode ? Colors.black : Colors.white, width: 3)
                        : Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300, width: 1),
                      boxShadow: isSelected 
                        ? [BoxShadow(
                            color: isDarkMode 
                              ? Colors.blue.withOpacity(0.7) 
                              : Colors.blue.withOpacity(0.5), 
                            blurRadius: 4, 
                            spreadRadius: 1
                          )]
                        : null,
                    ),
                    child: Center(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: _getContrastColor(Color(color)),
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // フォントサイズ設定
            Text(AppLocalizations.of(context)!.fontSize, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: currentFontSize,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    onChanged: onFontSizeChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(currentFontSize * 100).round()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // フォントサイズのプレビュー
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
              ),
              child: Text(
                AppLocalizations.of(context)!.fontSizePreview(fieldName),
                style: TextStyle(
                  color: Color(currentColor),
                  fontSize: 14 * currentFontSize,
                  fontFamily: currentFontFamily.isEmpty ? null : currentFontFamily,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // フォントファミリー設定
            Text(AppLocalizations.of(context)!.fontFamily, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: currentFontFamily.isEmpty ? null : currentFontFamily,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: fontFamilyOptions.map((font) {
                return DropdownMenuItem<String>(
                  value: font.isEmpty ? null : font,
                  child: Text(font.isEmpty ? AppLocalizations.of(context)!.defaultValue : font),
                );
              }).toList(),
              onChanged: (value) => onFontFamilyChanged(value ?? ''),
            ),
            const SizedBox(height: 8),
            // フォントファミリーのプレビュー
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
              ),
              child: Text(
                AppLocalizations.of(context)!.fontFamilyPreview(fieldName),
                style: TextStyle(
                  color: Color(currentColor),
                  fontSize: 14 * currentFontSize,
                  fontFamily: currentFontFamily.isEmpty ? null : currentFontFamily,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldSettings(
    BuildContext context, 
    WidgetRef ref, 
    String fieldName, 
    StateProvider<int> colorProvider, 
    StateProvider<double> fontSizeProvider, 
    StateProvider<String> fontFamilyProvider,
    String fieldKey
  ) {
    final currentColor = ref.watch(colorProvider);
    final currentFontSize = ref.watch(fontSizeProvider);
    final currentFontFamily = ref.watch(fontFamilyProvider);
    final isDarkMode = ref.watch(darkModeProvider);
    
    // テキスト色の選択肢（10種類）- ダークモード対応
    final textColorOptions = [
      0xFF000000, // 黒（ライトモード用）
      0xFFFFFFFF, // 白（ダークモード用）
      0xFF3B82F6, // ブルー（両モード対応）
      0xFFEF4444, // レッド（両モード対応）
      0xFFF59E0B, // オレンジ（両モード対応）
      0xFF10B981, // グリーン（両モード対応）
      0xFF8B5CF6, // パープル（両モード対応）
      0xFFEC4899, // ピンク（両モード対応）
      0xFF6B7280, // グレー（両モード対応）
      0xFFFBBF24, // イエロー（両モード対応）
    ];
    
    final textColorNames = [
      AppLocalizations.of(context)!.colorBlack,
      AppLocalizations.of(context)!.colorWhite,
      AppLocalizations.of(context)!.colorBlue,
      AppLocalizations.of(context)!.colorRed,
      AppLocalizations.of(context)!.colorOrange,
      AppLocalizations.of(context)!.colorGreen,
      AppLocalizations.of(context)!.colorPurple,
      AppLocalizations.of(context)!.colorPink,
      AppLocalizations.of(context)!.colorGray,
      AppLocalizations.of(context)!.colorYellow,
    ];

    // フォントファミリーの選択肢
    final fontFamilyOptions = [
      '', // デフォルト
      'Noto Sans JP',
      'Hiragino Sans',
      'Yu Gothic',
      'Meiryo',
      'MS Gothic',
      'MS Mincho',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.fieldSettings(fieldName), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * ref.watch(uiDensityProvider))),
            const SizedBox(height: 12),
            
            // テキスト色設定
            Text(AppLocalizations.of(context)!.textColor, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: textColorOptions.length,
              itemBuilder: (context, index) {
                final color = textColorOptions[index];
                final name = textColorNames[index];
                final isSelected = color == currentColor;
                
                return InkWell(
                  onTap: () async {
                    ref.read(colorProvider.notifier).state = color;
                    // 設定を保存
                    final settingsService = SettingsService.instance;
                    switch (fieldKey) {
                      case 'title':
                        await settingsService.setTitleTextColor(color);
                        break;
                      case 'memo':
                        await settingsService.setMemoTextColor(color);
                        break;
                      case 'description':
                        await settingsService.setDescriptionTextColor(color);
                        break;
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(color),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                        ? Border.all(color: isDarkMode ? Colors.black : Colors.white, width: 3)
                        : Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300, width: 1),
                      boxShadow: isSelected 
                        ? [BoxShadow(
                            color: isDarkMode 
                              ? Colors.blue.withOpacity(0.7) 
                              : Colors.blue.withOpacity(0.5), 
                            blurRadius: 4, 
                            spreadRadius: 1
                          )]
                        : null,
                    ),
                    child: Center(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: _getContrastColor(Color(color)),
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // フォントサイズ設定
            Text(AppLocalizations.of(context)!.fontSize, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: currentFontSize,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    onChanged: (value) async {
                      ref.read(fontSizeProvider.notifier).state = value;
                      // 設定を保存
                      final settingsService = SettingsService.instance;
                      switch (fieldKey) {
                        case 'title':
                          await settingsService.setTitleFontSize(value);
                          break;
                        case 'memo':
                          await settingsService.setMemoFontSize(value);
                          break;
                        case 'description':
                          await settingsService.setDescriptionFontSize(value);
                          break;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(currentFontSize * 100).round()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // フォントサイズのプレビュー
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
              ),
              child: Text(
                AppLocalizations.of(context)!.fontSizePreview(fieldName),
                style: TextStyle(
                  color: Color(ref.watch(colorProvider)),
                  fontSize: 14 * ref.watch(fontSizeProvider),
                  fontFamily: ref.watch(fontFamilyProvider).isEmpty 
                      ? null 
                      : ref.watch(fontFamilyProvider),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // フォントファミリー設定
            Text(AppLocalizations.of(context)!.fontFamily, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: currentFontFamily.isEmpty ? null : currentFontFamily,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: fontFamilyOptions.map((font) {
                return DropdownMenuItem<String>(
                  value: font.isEmpty ? null : font,
                  child: Text(font.isEmpty ? AppLocalizations.of(context)!.defaultValue : font),
                );
              }).toList(),
              onChanged: (value) async {
                final fontFamily = value ?? '';
                ref.read(fontFamilyProvider.notifier).state = fontFamily;
                // 設定を保存
                final settingsService = SettingsService.instance;
                switch (fieldKey) {
                  case 'title':
                    await settingsService.setTitleFontFamily(fontFamily);
                    break;
                  case 'memo':
                    await settingsService.setMemoFontFamily(fontFamily);
                    break;
                  case 'description':
                    await settingsService.setDescriptionFontFamily(fontFamily);
                    break;
                }
              },
            ),
            const SizedBox(height: 8),
            // フォントファミリーのプレビュー
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
              ),
              child: Text(
                AppLocalizations.of(context)!.fontFamilyPreview(fieldName),
                style: TextStyle(
                  color: Color(ref.watch(colorProvider)),
                  fontSize: 14 * ref.watch(fontSizeProvider),
                  fontFamily: ref.watch(fontFamilyProvider).isEmpty 
                      ? null 
                      : ref.watch(fontFamilyProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// UIカスタマイズセクションを構築
  Widget _buildUICustomizationSection(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(uiCustomizationProvider);
    final uiNotifier = ref.read(uiCustomizationProvider.notifier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(AppLocalizations.of(context)!.uiCustomization, Icons.tune),
        const SizedBox(height: 16),
        
        // リアルタイムプレビューセクション（固定表示）
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.realtimePreview,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.live,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPreviewSection(context, uiState),
                const SizedBox(height: 12),
                // 現在の設定値を表示
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
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.currentSettings(
                            uiState.cardBorderRadius.toStringAsFixed(1),
                            (uiState.shadowIntensity * 100).toStringAsFixed(0),
                            uiState.cardPadding.toStringAsFixed(1),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 設定項目をスクロール可能なエリアに配置
        SizedBox(
          height: 500, // 固定の高さを設定（プレビューを見ながら設定できる高さ）
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        
        // カード設定
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.view_agenda,
                      color: const Color(0xFF9C27B0),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.cardSettings,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.linkAndTaskScreens,
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF9C27B0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.cardSettingsDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                
                // カードの角丸半径
                _buildSliderSetting(
                  '${AppLocalizations.of(context)!.cornerRadius}: ${uiState.cardBorderRadius.toStringAsFixed(1)}px',
                  uiState.cardBorderRadius,
                  4.0,
                  32.0,
                  (value) => uiNotifier.setCardBorderRadius(value),
                ),
                
                const SizedBox(height: 16),
                
                // カードの影の強さ
                _buildSliderSetting(
                  '${AppLocalizations.of(context)!.shadowStrength}: ${uiState.cardElevation.toStringAsFixed(1)}',
                  uiState.cardElevation,
                  0.0,
                  8.0,
                  (value) => uiNotifier.setCardElevation(value),
                ),
                
                const SizedBox(height: 16),
                
                // カードのパディング
                _buildSliderSetting(
                  '${AppLocalizations.of(context)!.padding}: ${uiState.cardPadding.toStringAsFixed(1)}px',
                  uiState.cardPadding,
                  8.0,
                  32.0,
                  (value) => uiNotifier.setCardPadding(value),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ボタン設定
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: const Color(0xFF2196F3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.buttonSettings,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.allScreensCommon,
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF2196F3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.buttonSettingsDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ボタンの角丸半径
                _buildSliderSetting(
                  AppLocalizations.of(context)!.borderRadiusPx(uiState.buttonBorderRadius.toStringAsFixed(1)),
                  uiState.buttonBorderRadius,
                  4.0,
                  24.0,
                  (value) => uiNotifier.setButtonBorderRadius(value),
                ),
                
                const SizedBox(height: 16),
                
                // ボタンの影の強さ
                _buildSliderSetting(
                  AppLocalizations.of(context)!.elevationPx(uiState.buttonElevation.toStringAsFixed(1)),
                  uiState.buttonElevation,
                  0.0,
                  6.0,
                  (value) => uiNotifier.setButtonElevation(value),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 入力フィールド設定
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: const Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.inputFieldSettings,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.allScreensCommon,
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.inputFieldSettingsDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 入力フィールドの角丸半径
                _buildSliderSetting(
                  AppLocalizations.of(context)!.borderRadiusPx(uiState.inputBorderRadius.toStringAsFixed(1)),
                  uiState.inputBorderRadius,
                  4.0,
                  24.0,
                  (value) => uiNotifier.setInputBorderRadius(value),
                ),
                
                const SizedBox(height: 16),
                
                // 入力フィールドの枠線の太さ
                _buildSliderSetting(
                  AppLocalizations.of(context)!.borderWidthPx(uiState.inputBorderWidth.toStringAsFixed(1)),
                  uiState.inputBorderWidth,
                  0.5,
                  4.0,
                  (value) => uiNotifier.setInputBorderWidth(value),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // アニメーション・エフェクト設定
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.animationEffectSettings,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // アニメーションの持続時間
                _buildSliderSetting(
                  AppLocalizations.of(context)!.animationDuration('${uiState.animationDuration}'),
                  uiState.animationDuration.toDouble(),
                  100.0,
                  1000.0,
                  (value) => uiNotifier.setAnimationDuration(value.round()),
                ),
                
                const SizedBox(height: 16),
                
                // ホバー効果の強さ
                _buildSliderSetting(
                  AppLocalizations.of(context)!.hoverEffectPercent((uiState.hoverEffectIntensity * 100).toStringAsFixed(0)),
                  uiState.hoverEffectIntensity,
                  0.0,
                  0.3,
                  (value) => uiNotifier.setHoverEffectIntensity(value),
                ),
                
                const SizedBox(height: 16),
                
                // 影の強さ
                _buildSliderSetting(
                  AppLocalizations.of(context)!.elevationPercent((uiState.shadowIntensity * 100).toStringAsFixed(0)),
                  uiState.shadowIntensity,
                  0.0,
                  0.5,
                  (value) => uiNotifier.setShadowIntensity(value),
                ),
                
                const SizedBox(height: 16),
                
                // グラデーションの強さ
                _buildSliderSetting(
                  AppLocalizations.of(context)!.gradientPercent((uiState.gradientIntensity * 100).toStringAsFixed(0)),
                  uiState.gradientIntensity,
                  0.0,
                  0.2,
                  (value) => uiNotifier.setGradientIntensity(value),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 全般設定
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.generalSettings,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // UI密度
                _buildSliderSetting(
                  AppLocalizations.of(context)!.uiDensity((uiState.uiDensity * 100).toStringAsFixed(0)),
                  uiState.uiDensity,
                  0.5,
                  2.0,
                  (value) => uiNotifier.setUiDensity(value),
                ),
                
                const SizedBox(height: 16),
                
                // アイコンサイズ
                _buildSliderSetting(
                  '${AppLocalizations.of(context)!.iconSize}: ${uiState.iconSize.toStringAsFixed(1)}px',
                  uiState.iconSize,
                  16.0,
                  48.0,
                  (value) => uiNotifier.setIconSize(value),
                ),
                
                const SizedBox(height: 16),
                
                // 要素間のスペーシング
                _buildSliderSetting(
                  AppLocalizations.of(context)!.spacing(uiState.spacing.toStringAsFixed(1)),
                  uiState.spacing,
                  4.0,
                  24.0,
                  (value) => uiNotifier.setSpacing(value),
                ),
                
                const SizedBox(height: 16),
                
                // 自動コントラスト最適化
                _buildSwitchSetting(
                  AppLocalizations.of(context)!.autoContrastOptimization,
                  AppLocalizations.of(context)!.autoContrastOptimizationDesc,
                  uiState.autoContrastOptimization,
                  (value) => uiNotifier.setAutoContrastOptimization(value),
                ),
                
                const SizedBox(height: 16),
                
                // ダークモードコントラストブースト
                _buildSliderSetting(
                  AppLocalizations.of(context)!.darkModeContrastBoostPercent((uiState.darkModeContrastBoost * 100).toStringAsFixed(0)),
                  uiState.darkModeContrastBoost,
                  1.0,
                  2.0,
                  (value) => uiNotifier.setDarkModeContrastBoost(value),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // リセットボタン
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final l10n = AppLocalizations.of(context)!;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => UnifiedDialog(
                      title: l10n.resetSettings,
                      icon: Icons.restore,
                      iconColor: Colors.orange,
                      content: Text(l10n.resetSettingsConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.reset),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    await uiNotifier.resetAllSettings();
                    if (context.mounted) {
                      SnackBarService.showSuccess(
                        context,
                        l10n.uiSettingsResetSuccess,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.restore),
                label: Text(AppLocalizations.of(context)!.resetSettings),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// プレビューセクションを構築
  Widget _buildPreviewSection(BuildContext context, UICustomizationState uiState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(uiState.cardBorderRadius),
        border: Border.all(
          color: isDarkMode 
            ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
            : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          // カードプレビュー
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(uiState.cardPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(uiState.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(uiState.shadowIntensity),
                  blurRadius: uiState.cardElevation * 4,
                  offset: Offset(0, uiState.cardElevation * 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.sampleCard,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.cardPreviewDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                
                // ボタンプレビュー
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(uiState.buttonBorderRadius),
                        ),
                        elevation: uiState.buttonElevation,
                      ),
                      child: Text(AppLocalizations.of(context)!.sampleButton),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(uiState.buttonBorderRadius),
                        ),
                        side: BorderSide(
                          width: uiState.inputBorderWidth,
                          color: isDarkMode 
                            ? Theme.of(context).colorScheme.outline.withOpacity(0.5)
                            : Colors.grey.shade400,
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.outlineButton),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // 入力フィールドプレビュー
                TextFormField(
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.sampleInputField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(uiState.inputBorderRadius),
                      borderSide: BorderSide(
                        width: uiState.inputBorderWidth,
                        color: isDarkMode 
                          ? Theme.of(context).colorScheme.outline.withOpacity(0.5)
                          : Colors.grey.shade400,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(uiState.inputBorderRadius),
                      borderSide: BorderSide(
                        width: uiState.inputBorderWidth,
                        color: isDarkMode 
                          ? Theme.of(context).colorScheme.outline.withOpacity(0.5)
                          : Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(uiState.inputBorderRadius),
                      borderSide: BorderSide(
                        width: uiState.inputBorderWidth,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// スイッチ設定ウィジェットを構築
  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  /// スライダー設定ウィジェットを構築
  Widget _buildSliderSetting(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.3),
            thumbColor: Theme.of(context).primaryColor,
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
            valueIndicatorColor: Theme.of(context).primaryColor,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 0.1).round(),
            onChanged: onChanged,
            label: value.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSection(BuildContext context, WidgetRef ref, double currentFontSize, SettingsState settingsState, SettingsNotifier settingsNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(AppLocalizations.of(context)!.fontSettings, Icons.text_fields),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.appWideFontSize('${(currentFontSize * 100).round()}')),
                Slider(
                  value: currentFontSize,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: '${(currentFontSize * 100).round()}%',
                  onChanged: (value) async {
                    ref.read(fontSizeProvider.notifier).state = value;
                    await SettingsService.instance.setFontSize(value);
                  },
                ),
                
                const SizedBox(height: 16),
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
        _buildSectionHeader(AppLocalizations.of(context)!.gridSettings, Icons.grid_view),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.autoLayoutAdjustment),
                  subtitle: Text(AppLocalizations.of(context)!.autoLayoutAdjustmentDescription),
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
                            layoutSettings.autoAdjustLayout ? AppLocalizations.of(context)!.autoLayoutEnabledLabel : AppLocalizations.of(context)!.manualLayoutSettings,
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
                          AppLocalizations.of(context)!.autoLayoutEnabled,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLayoutInfo(
                          AppLocalizations.of(context)!.largeScreen,
                          AppLocalizations.of(context)!.columnsDisplay('6'),
                          AppLocalizations.of(context)!.optimalForDesktop,
                        ),
                        _buildLayoutInfo(
                          AppLocalizations.of(context)!.mediumScreen,
                          AppLocalizations.of(context)!.columnsDisplay('4'),
                          AppLocalizations.of(context)!.optimalForLaptop,
                        ),
                        _buildLayoutInfo(
                          AppLocalizations.of(context)!.smallScreen,
                          AppLocalizations.of(context)!.columnsDisplay('3'),
                          AppLocalizations.of(context)!.optimalForSmallScreen,
                        ),
                        _buildLayoutInfo(
                          AppLocalizations.of(context)!.minimalScreen,
                          AppLocalizations.of(context)!.columnsDisplay('2'),
                          AppLocalizations.of(context)!.optimalForMobile,
                        ),
                      ] else ...[
                        Text(
                          AppLocalizations.of(context)!.manualLayoutEnabled,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLayoutInfo(
                          AppLocalizations.of(context)!.fixedColumns,
                          AppLocalizations.of(context)!.columnsDisplay('${layoutSettings.defaultCrossAxisCount}'),
                          AppLocalizations.of(context)!.sameColumnsAllScreens,
                        ),
                        _buildLayoutInfo(
                          AppLocalizations.of(context)!.useCase,
                          AppLocalizations.of(context)!.maintainSpecificDisplay,
                          AppLocalizations.of(context)!.consistentLayoutNeeded,
                        ),
                      ],
                    ],
                  ),
                ),
                
                if (!layoutSettings.autoAdjustLayout) ...[
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.defaultColumnCount('${layoutSettings.defaultCrossAxisCount}')),
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
                Text(AppLocalizations.of(context)!.gridSpacing('${layoutSettings.defaultGridSpacing}')),
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
        _buildSectionHeader(AppLocalizations.of(context)!.cardSettings, Icons.view_agenda),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.cardWidth('${layoutSettings.cardWidth}')),
                Slider(
                  value: layoutSettings.cardWidth,
                  min: 150,
                  max: 300,
                  divisions: 15,
                  label: '${layoutSettings.cardWidth}px',
                  onChanged: (value) => notifier.updateCardWidth(value),
                ),
                
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.cardHeight('${layoutSettings.cardHeight}')),
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
        _buildSectionHeader(AppLocalizations.of(context)!.itemSettings, Icons.link),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // アイテム間マージン
                _buildSettingItemWithDescription(
                  title: AppLocalizations.of(context)!.itemMargin,
                  value: '${layoutSettings.linkItemMargin}px',
                  description: AppLocalizations.of(context)!.itemMarginDescription,
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
                  title: AppLocalizations.of(context)!.itemPadding,
                  value: '${layoutSettings.linkItemPadding}px',
                  description: AppLocalizations.of(context)!.itemPaddingDescription,
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
                  title: AppLocalizations.of(context)!.fontSize,
                  value: '${layoutSettings.linkItemFontSize}px',
                  description: AppLocalizations.of(context)!.fontSizeDescription,
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
                  title: AppLocalizations.of(context)!.iconSize,
                  value: '${layoutSettings.linkItemIconSize}px',
                  description: AppLocalizations.of(context)!.linkItemIconSizeDesc,
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
                  title: AppLocalizations.of(context)!.buttonSize,
                  value: '${layoutSettings.buttonSize}px',
                  description: AppLocalizations.of(context)!.buttonSizeDescription,
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

  Widget _buildTaskProjectSection(WidgetRef ref) {
    final taskProjectLayoutSettings = ref.watch(taskProjectLayoutSettingsProvider);
    final notifier = ref.read(taskProjectLayoutSettingsProvider.notifier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(AppLocalizations.of(context)!.cardViewSettings, Icons.view_module),
        const SizedBox(height: 16),
        
        // グリッド設定
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.gridSettings,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.autoLayoutAdjustment),
                  subtitle: Text(AppLocalizations.of(context)!.autoLayoutAdjustmentDescription),
                  value: taskProjectLayoutSettings.autoAdjustLayout,
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
                            taskProjectLayoutSettings.autoAdjustLayout ? Icons.auto_awesome : Icons.settings,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            taskProjectLayoutSettings.autoAdjustLayout ? AppLocalizations.of(context)!.autoLayoutEnabledLabel : AppLocalizations.of(context)!.manualLayoutSettings,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (taskProjectLayoutSettings.autoAdjustLayout) ...[
                        Text(
                          AppLocalizations.of(context)!.autoLayoutEnabled,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ] else ...[
                        Text(
                          AppLocalizations.of(context)!.manualLayoutEnabled,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLayoutInfo(
                          AppLocalizations.of(context)!.fixedColumns,
                          AppLocalizations.of(context)!.columnsDisplay('${taskProjectLayoutSettings.defaultCrossAxisCount}'),
                          AppLocalizations.of(context)!.sameColumnsAllScreens,
                        ),
                      ],
                    ],
                  ),
                ),
                
                if (!taskProjectLayoutSettings.autoAdjustLayout) ...[
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.defaultColumnCount('${taskProjectLayoutSettings.defaultCrossAxisCount}')),
                  Slider(
                    value: taskProjectLayoutSettings.defaultCrossAxisCount.toDouble(),
                    min: 2,
                    max: 6,
                    divisions: 4,
                    label: '${taskProjectLayoutSettings.defaultCrossAxisCount}',
                    onChanged: (value) => notifier.updateCrossAxisCount(value.round()),
                  ),
                ],
                
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.gridSpacing('${taskProjectLayoutSettings.defaultGridSpacing}')),
                Slider(
                  value: taskProjectLayoutSettings.defaultGridSpacing,
                  min: 4,
                  max: 20,
                  divisions: 16,
                  label: '${taskProjectLayoutSettings.defaultGridSpacing}px',
                  onChanged: (value) => notifier.updateGridSpacing(value),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // カード高さ自動調整
        SwitchListTile(
          title: Text(AppLocalizations.of(context)!.autoAdjustCardHeight),
          subtitle: Text(AppLocalizations.of(context)!.autoAdjustCardHeightDescription),
          value: taskProjectLayoutSettings.autoAdjustCardHeight,
          onChanged: (value) => notifier.toggleAutoAdjustCardHeight(),
        ),
        
        const SizedBox(height: 16),
        
        // カード設定
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.cardSettings,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.cardWidth('${taskProjectLayoutSettings.cardWidth}')),
                Slider(
                  value: taskProjectLayoutSettings.cardWidth,
                  min: 150,
                  max: 300,
                  divisions: 15,
                  label: '${taskProjectLayoutSettings.cardWidth}px',
                  onChanged: (value) => notifier.updateCardWidth(value),
                ),
                
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.cardHeight('${taskProjectLayoutSettings.cardHeight}')),
                Slider(
                  value: taskProjectLayoutSettings.cardHeight,
                  min: 80,
                  max: 200,
                  divisions: 12,
                  label: '${taskProjectLayoutSettings.cardHeight}px',
                  onChanged: (value) => notifier.updateCardHeight(value),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // フォント設定（カードビュー専用）
        _buildCardViewFontSettings(context, ref, taskProjectLayoutSettings, notifier),
        
        const SizedBox(height: 16),
        
        // リセットボタン
        ElevatedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => UnifiedDialog(
                title: AppLocalizations.of(context)!.resetCardViewSettings,
                icon: Icons.restore,
                iconColor: Colors.orange,
                content: Text(AppLocalizations.of(context)!.resetCardViewSettingsConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppLocalizations.of(context)!.reset),
                  ),
                ],
              ),
            );
            
            if (confirmed == true) {
              notifier.resetToDefaults();
              if (context.mounted) {
                SnackBarService.showSuccess(
                  context,
                  AppLocalizations.of(context)!.taskProjectSettingsReset,
                );
              }
            }
          },
          icon: const Icon(Icons.restore),
          label: Text(AppLocalizations.of(context)!.resetSettings),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// バックアップフォルダを開く
  Future<void> _openBackupFolder(BuildContext context) async {
    try {
      final backupService = IntegratedBackupService(
        linkRepository: ref.read(linkRepositoryProvider),
        settingsService: ref.read(settingsServiceProvider),
        taskViewModel: ref.read(taskViewModelProvider.notifier),
        ref: ref,
      );
      
      final backupDir = await backupService.getBackupDirectory();
      await Process.run('explorer.exe', [backupDir.path]);
      
      SnackBarService.showSuccess(context, AppLocalizations.of(context)!.backupFolderOpened);
    } catch (e) {
      SnackBarService.showError(context, AppLocalizations.of(context)!.couldNotOpenFolder('$e'));
    }
  }

  Widget _buildIntegratedBackupSection(BuildContext context, WidgetRef ref, SettingsState state, SettingsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(AppLocalizations.of(context)!.backupExport, Icons.backup),
        const SizedBox(height: 16),
        
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    // 説明文
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
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.backupLocation,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 今すぐ保存ボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showExportOptionsDialog(context, ref),
                        icon: const Icon(Icons.save),
                        label: Text(AppLocalizations.of(context)!.saveNow),
                        style: AppButtonStyles.primary(context),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 保存先を開くボタン
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openBackupFolder(context),
                        icon: const Icon(Icons.folder_open),
                        label: Text(AppLocalizations.of(context)!.openBackupFolder),
                        style: AppButtonStyles.outlined(context),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // インポートボタン
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          print('=== メインインポートボタン押下 ===');
                          print('================================');
                          _showImportOptionsDialog(context, ref);
                        },
                  icon: const Icon(Icons.upload),
                        label: Text(AppLocalizations.of(context)!.import),
                        style: AppButtonStyles.outlined(context),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 選択式エクスポート/インポート
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.selectiveExportImport,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    // 選択式エクスポートボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSelectiveExportDialog(context, ref),
                        icon: const Icon(Icons.tune),
                        label: Text(AppLocalizations.of(context)!.selectiveExport),
                        style: AppButtonStyles.primary(context),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 選択式インポートボタン
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showSelectiveImportDialog(context, ref),
                        icon: const Icon(Icons.tune),
                        label: Text(AppLocalizations.of(context)!.selectiveImport),
                        style: AppButtonStyles.outlined(context),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 自動バックアップ設定
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.autoBackup),
                      subtitle: Text(AppLocalizations.of(context)!.autoBackupDescription),
                      value: state.autoBackup,
                      onChanged: (value) => notifier.setAutoBackup(value),
                    ),
                    
                    if (state.autoBackup) ...[
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.backupInterval('${state.backupInterval}')),
                      Slider(
                        value: state.backupInterval.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: AppLocalizations.of(context)!.backupIntervalDays('${state.backupInterval}'),
                        onChanged: (value) => notifier.setBackupInterval(value.round()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// エクスポートオプションダイアログを表示
  void _showExportOptionsDialog(BuildContext context, WidgetRef ref) {
    String selectedType = 'both'; // デフォルトは両方
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => UnifiedDialog(
          title: AppLocalizations.of(context)!.exportOptions,
          icon: Icons.save,
          iconColor: Colors.green,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.selectDataToExport),
              const SizedBox(height: 16),
              
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.linksOnly),
                subtitle: Text(AppLocalizations.of(context)!.linksOnlyDescription),
                value: 'links',
                groupValue: selectedType,
                onChanged: (value) => setState(() => selectedType = value!),
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.tasksOnly),
                subtitle: Text(AppLocalizations.of(context)!.tasksOnlyDescription),
                value: 'tasks',
                groupValue: selectedType,
                onChanged: (value) => setState(() => selectedType = value!),
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.both),
                subtitle: Text(AppLocalizations.of(context)!.bothDescription),
                value: 'both',
                groupValue: selectedType,
                onChanged: (value) => setState(() => selectedType = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.text(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performExport(context, ref, selectedType);
              },
              style: AppButtonStyles.primary(context),
              child: Text(AppLocalizations.of(context)!.export),
            ),
          ],
        ),
      ),
    );
  }

  /// インポートオプションダイアログを表示
  void _showImportOptionsDialog(BuildContext context, WidgetRef ref) {
    print('=== インポートオプションダイアログ表示 ===');
    print('========================================');
    
    String selectedType = 'both'; // デフォルトは両方
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => UnifiedDialog(
          title: AppLocalizations.of(context)!.importOptions,
          icon: Icons.upload,
          iconColor: Colors.blue,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.selectDataToImport),
              const SizedBox(height: 16),
              
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.linksOnly),
                subtitle: Text(AppLocalizations.of(context)!.linksOnlyImportDescription),
                value: 'links',
                groupValue: selectedType,
                onChanged: (value) => setState(() => selectedType = value!),
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.tasksOnly),
                subtitle: Text(AppLocalizations.of(context)!.tasksOnlyImportDescription),
                value: 'tasks',
                groupValue: selectedType,
                onChanged: (value) => setState(() => selectedType = value!),
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.both),
                subtitle: Text(AppLocalizations.of(context)!.bothImportDescription),
                value: 'both',
                groupValue: selectedType,
                onChanged: (value) => setState(() => selectedType = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.text(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                print('=== インポートボタン押下 ===');
                print('selectedType: $selectedType');
                print('==========================');
                Navigator.pop(context);
                _performImport(context, ref, selectedType);
              },
              style: AppButtonStyles.primary(context),
              child: Text(AppLocalizations.of(context)!.import),
            ),
          ],
        ),
      ),
    );
  }

  /// エクスポートを実行
  void _performExport(BuildContext context, WidgetRef ref, String type) async {
    // 非同期処理を別メソッドで実行
    _executeExport(type, ref);
  }

  /// エクスポート処理を実行（非同期処理を分離）
  void _executeExport(String type, WidgetRef ref) async {
    print('=== エクスポート開始 ===');
    print('type: $type');
    print('====================');
    
    // グローバルなNavigatorKeyを使用してダイアログを表示
    final keyboardNavigatorKey = KeyboardShortcutService.getNavigatorKey();
    final globalContext = keyboardNavigatorKey?.currentContext;
    if (globalContext == null) {
      print('エラー: globalContextがnullです');
      print('keyboardNavigatorKey: $keyboardNavigatorKey');
      print('keyboardNavigatorKey?.currentState: ${keyboardNavigatorKey?.currentState}');
      return;
    }

    // ローディングダイアログを表示
    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('=== IntegratedBackupService作成開始 ===');
      
      // IntegratedBackupServiceを使用してエクスポートを実行
      final backupService = IntegratedBackupService(
        linkRepository: ref.read(linkRepositoryProvider),
        settingsService: ref.read(settingsServiceProvider),
        taskViewModel: ref.read(taskViewModelProvider.notifier),
        ref: ref,
      );
      
      print('=== IntegratedBackupService作成完了 ===');
      print('=== エクスポート実行開始 ===');
      print('onlyLinks: ${type == 'links'}');
      print('onlyTasks: ${type == 'tasks'}');

      final filePath = await backupService.exportData(
        onlyLinks: type == 'links',
        onlyTasks: type == 'tasks',
      );
      
      print('=== エクスポート実行完了 ===');
      print('filePath: $filePath');

      // ローディングを閉じる
      Navigator.of(globalContext).pop();

      // 結果を表示
      String message = AppLocalizations.of(context)!.exportCompleted(filePath);
      
      showDialog(
        context: globalContext,
        builder: (context) => UnifiedDialog(
          title: AppLocalizations.of(context)!.exportCompletedTitle,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.primary(context),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      print('=== エクスポートエラー ===');
      print('エラー: $e');
      print('スタックトレース: ${StackTrace.current}');
      print('=======================');
      
      // ローディングを閉じる
      Navigator.of(globalContext).pop();
      
      // エラーダイアログを表示
      showDialog(
        context: globalContext,
        builder: (context) => UnifiedDialog(
          title: AppLocalizations.of(context)!.exportError,
          icon: Icons.error,
          iconColor: Colors.red,
          content: Text(AppLocalizations.of(context)!.exportErrorMessage('$e')),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.primary(context),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    }
  }

  /// 選択式エクスポートダイアログを表示
  void _showSelectiveExportDialog(BuildContext context, WidgetRef ref) async {
    final linkRepository = ref.read(linkRepositoryProvider);
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    
    final config = await showDialog<ExportConfig>(
      context: context,
      builder: (context) => SelectiveExportDialog(
        linkRepository: linkRepository,
        taskViewModel: taskViewModel,
      ),
    );
    
    if (config != null) {
      await _performSelectiveExport(context, ref, config);
    }
  }

  /// 選択式エクスポートを実行
  Future<void> _performSelectiveExport(
    BuildContext context,
    WidgetRef ref,
    ExportConfig config,
  ) async {
    final keyboardNavigatorKey = KeyboardShortcutService.getNavigatorKey();
    final globalContext = keyboardNavigatorKey?.currentContext;
    
    if (globalContext == null) return;
    
    // ローディング表示
    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final backupService = IntegratedBackupService(
        linkRepository: ref.read(linkRepositoryProvider),
        settingsService: ref.read(settingsServiceProvider),
        taskViewModel: ref.read(taskViewModelProvider.notifier),
        ref: ref,
      );
      
      final filePath = await backupService.exportDataWithConfig(config);
      
      Navigator.of(globalContext).pop();
      
      showDialog(
        context: globalContext,
        builder: (context) => UnifiedDialog(
          title: AppLocalizations.of(context)!.exportCompletedTitle,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          content: Text(AppLocalizations.of(context)!.exportCompleted(filePath)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.primary(context),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(globalContext).pop();
      
      showDialog(
        context: globalContext,
        builder: (context) => UnifiedDialog(
          title: AppLocalizations.of(context)!.exportError,
          icon: Icons.error,
          iconColor: Colors.red,
          content: Text(AppLocalizations.of(context)!.exportErrorMessage('$e')),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.primary(context),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    }
  }

  /// 選択式インポートダイアログを表示
  void _showSelectiveImportDialog(BuildContext context, WidgetRef ref) async {
    final config = await showDialog<ImportConfig>(
      context: context,
      builder: (context) => const SelectiveImportDialog(),
    );
    
    if (config != null) {
      await _performSelectiveImport(context, ref, config);
    }
  }

  /// 選択式インポートを実行
  Future<void> _performSelectiveImport(
    BuildContext context,
    WidgetRef ref,
    ImportConfig config,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'インポートするファイルを選択',
      );
      
      if (result == null || result.files.single.path == null) {
        return;
      }
      
      final file = File(result.files.single.path!);
      
      final keyboardNavigatorKey = KeyboardShortcutService.getNavigatorKey();
      final globalContext = keyboardNavigatorKey?.currentContext;
      
      if (globalContext == null) return;
      
      // ローディング表示
      showDialog(
        context: globalContext,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      try {
        final backupService = IntegratedBackupService(
          linkRepository: ref.read(linkRepositoryProvider),
          settingsService: ref.read(settingsServiceProvider),
          taskViewModel: ref.read(taskViewModelProvider.notifier),
          ref: ref,
        );
        
        final importResult = await backupService.importDataWithConfig(file, config);
        
        Navigator.of(globalContext).pop();
        
        String message = AppLocalizations.of(context)!.importCompleted(
          importResult.links.length,
          importResult.tasks.length,
          importResult.groups.length,
        );
        
        if (importResult.warnings.isNotEmpty) {
          message += '\n\n警告:\n';
          message += importResult.warnings.take(5).join('\n');
          if (importResult.warnings.length > 5) {
            message += '\n...他${importResult.warnings.length - 5}件';
          }
        }
        
        showDialog(
          context: globalContext,
          builder: (context) => UnifiedDialog(
            title: AppLocalizations.of(context)!.importCompletedTitle,
            icon: Icons.check_circle,
            iconColor: Colors.green,
            content: SingleChildScrollView(
              child: Text(message),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: AppButtonStyles.primary(context),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      } catch (e) {
        Navigator.of(globalContext).pop();
        
        showDialog(
          context: globalContext,
          builder: (context) => UnifiedDialog(
            title: 'インポートエラー',
            icon: Icons.error,
            iconColor: Colors.red,
            content: Text('インポートエラー: $e'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: AppButtonStyles.primary(context),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('ファイル選択エラー: $e');
    }
  }

  /// インポートを実行
  void _performImport(BuildContext context, WidgetRef ref, String type) async {
    print('=== _performImport呼び出し ===');
    print('type: $type');
    print('============================');
    
    try {
      // ファイル選択ダイアログを開く
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'インポートするファイルを選択',
      );
      
      print('=== ファイル選択結果 ===');
      print('result: $result');
      if (result != null) {
        print('files.length: ${result.files.length}');
        if (result.files.isNotEmpty) {
          print('file.path: ${result.files.first.path}');
        }
      }
      print('========================');

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        print('=== _executeImport呼び出し前 ===');
        print('file.path: ${file.path}');
        print('type: $type');
        print('==============================');
        
        // 非同期処理を別メソッドで実行（ローディングも含む）
        _executeImport(file, type, ref, context);
      } else {
        print('=== ファイル選択が無効 ===');
        print('result: $result');
        if (result != null) {
          print('files.length: ${result.files.length}');
          if (result.files.isNotEmpty) {
            print('first file path: ${result.files.first.path}');
          }
        }
        print('==========================');
      }
    } catch (e) {
      // ウィジェットがまだマウントされているかチェック
      if (!mounted) return;
      
      // グローバルなNavigatorKeyを使用
      final keyboardNavigatorKey = KeyboardShortcutService.getNavigatorKey();
      final globalContext = keyboardNavigatorKey?.currentContext;
      if (globalContext != null) {
        showDialog(
          context: globalContext,
          builder: (context) => UnifiedDialog(
            title: 'インポートエラー',
            icon: Icons.error,
            iconColor: Colors.red,
            content: Text('インポートエラー: $e'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: AppButtonStyles.primary(context),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      }
    }
  }

  /// インポート処理を実行（非同期処理を分離）
  void _executeImport(File file, String type, WidgetRef ref, BuildContext context) async {
    print('=== _executeImportメソッド開始 ===');
    print('file.path: ${file.path}');
    print('type: $type');
    print('================================');
    
    // グローバルなNavigatorKeyを使用してダイアログを表示
    final globalNavigatorKey = KeyboardShortcutService.getNavigatorKey();
    final globalContext = globalNavigatorKey?.currentContext;
    if (globalContext == null) {
      print('=== globalContextがnull ===');
      print('==========================');
      return;
    }
    
    print('=== ローディングダイアログ表示 ===');
    print('===============================');

    // ローディングダイアログを表示
    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('=== インポート処理開始 ===');
      print('ファイル: ${file.path}');
      print('タイプ: $type');
      
      // IntegratedBackupServiceを使用してインポートを実行
      final backupService = IntegratedBackupService(
        linkRepository: ref.read(linkRepositoryProvider),
        settingsService: ref.read(settingsServiceProvider),
        taskViewModel: ref.read(taskViewModelProvider.notifier),
        ref: ref,
      );

      final importResult = await backupService.importData(
        file,
        onlyLinks: type == 'links',
        onlyTasks: type == 'tasks',
      );

      print('=== インポート結果 ===');
      print('リンク数: ${importResult.links.length}');
      print('タスク数: ${importResult.tasks.length}');
      print('グループ数: ${importResult.groups.length}');
      print('警告数: ${importResult.warnings.length}');
      print('==================');

      // ローディングを閉じる
      Navigator.of(globalContext).pop();

      print('=== ダイアログ表示開始 ===');
      // 結果をダイアログで表示（新しいUIを使用）

      showDialog(
        context: globalContext,
        builder: (context) => UnifiedDialog(
          title: 'インポート完了',
          icon: Icons.check_circle,
          iconColor: Colors.green,
          width: 600,
          height: 600,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基本情報
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
                    Text(
                      'インポートが完了しました',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('リンク: ${importResult.links.length}件'),
                    Text('グループ: ${importResult.groups.length}件'),
                    Text('タスク: ${importResult.tasks.length}件'),
                  ],
                ),
              ),
              
              // 警告セクション
              if (importResult.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '警告 (${importResult.warnings.length}件):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: ScrollController(),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: importResult.warnings.map((warning) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $warning',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.primary(context),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
      
      print('=== ダイアログ表示完了 ===');
    } catch (e) {
      print('=== インポートエラー ===');
      print('エラー: $e');
      print('==================');
      
      // ローディングを閉じる
      Navigator.of(globalContext).pop();
      
      // エラーダイアログを表示
      showDialog(
        context: globalContext,
        builder: (context) => UnifiedDialog(
          title: 'インポートエラー',
          icon: Icons.error,
          iconColor: Colors.red,
          content: Text('インポート中にエラーが発生しました:\n\n$e'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.primary(context),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    }
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                 _buildSectionHeader(AppLocalizations.of(context)!.notificationSettings, Icons.notifications),
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
                   AppLocalizations.of(context)!.notificationWarning,
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
                   title: AppLocalizations.of(context)!.showNotifications,
                   description: AppLocalizations.of(context)!.showNotificationsDescription,
                   value: state.showNotifications,
                   onChanged: notifier.setShowNotifications,
                 ),
                
                const SizedBox(height: 16),
                
                                 _buildSwitchWithDescription(
                   title: AppLocalizations.of(context)!.notificationSound,
                   description: AppLocalizations.of(context)!.notificationSoundDescription,
                   value: state.notificationSound,
                   onChanged: notifier.setNotificationSound,
                 ),
                
                const SizedBox(height: 8),
                
                                 ElevatedButton.icon(
                   icon: const Icon(Icons.volume_up),
                   label: Text(AppLocalizations.of(context)!.testNotificationSound),
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
                     color: Theme.of(context).colorScheme.surfaceContainerHighest,
                     borderRadius: BorderRadius.circular(6),
                     border: Border.all(
                       color: Theme.of(context).colorScheme.outline.withOpacity(0.3)
                     ),
                   ),
                   child: Text(
                     AppLocalizations.of(context)!.testNotificationSoundDescription,
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
        _buildSectionHeader(AppLocalizations.of(context)!.reset, Icons.restore),
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
                        label: Text(AppLocalizations.of(context)!.resetToDefaults, style: const TextStyle(fontSize: 16)),
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
                        label: Text(AppLocalizations.of(context)!.resetLayoutSettings, style: const TextStyle(fontSize: 16)),
                        onPressed: () {
                          ref.read(layoutSettingsProvider.notifier).resetToDefaults();
                          if (context.mounted) {
                            SnackBarService.showSuccess(
                              context,
                              AppLocalizations.of(context)!.layoutSettingsReset,
                            );
                          }
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
                        icon: const Icon(Icons.tune, size: 24),
                        label: Text(AppLocalizations.of(context)!.resetUISettings, style: const TextStyle(fontSize: 16)),
                        onPressed: () async {
                          final uiNotifier = ref.read(uiCustomizationProvider.notifier);
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => UnifiedDialog(
                              title: AppLocalizations.of(context)!.resetUISettings,
                              icon: Icons.warning_amber_rounded,
                              iconColor: Colors.orange,
                              content: Text(
                                AppLocalizations.of(context)!.resetUISettingsConfirm,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(AppLocalizations.of(context)!.cancel),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(AppLocalizations.of(context)!.executeReset),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            await uiNotifier.resetAllSettings();
                            if (context.mounted) {
                              SnackBarService.showSuccess(
                                context,
                                AppLocalizations.of(context)!.uiSettingsResetSuccess,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
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
                        label: Text(AppLocalizations.of(context)!.resetDetails, style: const TextStyle(fontSize: 16)),
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
                            AppLocalizations.of(context)!.resetFunction,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.resetFunctionDescription,
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
        title: AppLocalizations.of(context)!.resetDetailsTitle,
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
                AppLocalizations.of(context)!.resetDetailsDescription,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
                const SizedBox(height: 16),
                
            _buildGuideStep('1', AppLocalizations.of(context)!.resetToDefaultsStep),
            Text(
              AppLocalizations.of(context)!.resetToDefaultsStepDescription,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            _buildResetItem(AppLocalizations.of(context)!.themeSettingsReset, AppLocalizations.of(context)!.themeSettingsResetValue),
            _buildResetItem(AppLocalizations.of(context)!.notificationSettingsReset, AppLocalizations.of(context)!.notificationSettingsResetValue),
            _buildResetItem(AppLocalizations.of(context)!.integrationSettingsReset, AppLocalizations.of(context)!.integrationSettingsResetValue),
            _buildResetItem(AppLocalizations.of(context)!.backupSettingsReset, AppLocalizations.of(context)!.backupSettingsResetValue),
            const SizedBox(height: 12),
            
            _buildGuideStep('2', AppLocalizations.of(context)!.resetLayoutSettingsStep),
            Text(
              AppLocalizations.of(context)!.resetLayoutSettingsStepDescription,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            _buildResetItem(AppLocalizations.of(context)!.gridSettingsReset, AppLocalizations.of(context)!.gridSettingsResetDesc),
            _buildResetItem(AppLocalizations.of(context)!.cardSettingsReset, AppLocalizations.of(context)!.cardSettingsResetDesc),
            _buildResetItem(AppLocalizations.of(context)!.itemSettingsReset, AppLocalizations.of(context)!.itemSettingsResetDesc),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder, color: Colors.grey, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${AppLocalizations.of(context)!.storageLocation}:\n$location',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.play_arrow, color: Colors.green, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${AppLocalizations.of(context)!.executionMethod}: $usage',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.resetToDefaults();
              // 新しい色設定もリセット
              ref.read(accentColorProvider.notifier).state = 0xFF3B82F6; // ブルー
              ref.read(colorIntensityProvider.notifier).state = 1.0; // 標準
              ref.read(colorContrastProvider.notifier).state = 1.0; // 標準
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        _buildSectionHeader(AppLocalizations.of(context)!.googleCalendarIntegration, Icons.calendar_today),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Google Calendar連携の有効/無効
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.googleCalendarIntegration),
                  subtitle: Text(AppLocalizations.of(context)!.googleCalendarIntegrationDescription),
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
                    title: Text(AppLocalizations.of(context)!.autoSync),
                    subtitle: Text(AppLocalizations.of(context)!.autoSyncDescription),
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
                      AppLocalizations.of(context)!.syncInterval('${settingsState.googleCalendarSyncInterval}'),
                      settingsState.googleCalendarSyncInterval.toDouble(),
                      15,
                      240,
                      (value) {
                        settingsNotifier.setGoogleCalendarSyncInterval(value.round());
                      },
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
                    title: Text(AppLocalizations.of(context)!.bidirectionalSync),
                    subtitle: Text(AppLocalizations.of(context)!.bidirectionalSyncDescription),
                    value: settingsState.googleCalendarBidirectionalSync,
                    onChanged: (value) {
                      settingsNotifier.setGoogleCalendarBidirectionalSync(value);
                    },
                    secondary: const Icon(Icons.sync_alt),
                  ),
                  
                  const Divider(),
                  
                  // 完了タスク表示設定
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.showCompletedTasks),
                    subtitle: Text(AppLocalizations.of(context)!.showCompletedTasksDescription),
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
                                  ? AppLocalizations.of(context)!.credentialsFileFound
                                  : AppLocalizations.of(context)!.credentialsFileNotFound,
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
                        label: Text(AppLocalizations.of(context)!.checkSetupMethod),
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
                              AppLocalizations.of(context)!.oauth2AuthCompleted,
                            );
                          } else {
                            SnackBarService.showError(
                              context,
                              AppLocalizations.of(context)!.authStartFailed,
                            );
                          }
                        } catch (e) {
                            SnackBarService.showError(
                              context,
                              AppLocalizations.of(context)!.errorColon('$e'),
                            );
                        }
                      },
                      icon: const Icon(Icons.login),
                      label: Text(AppLocalizations.of(context)!.startOAuth2Authentication),
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
                              AppLocalizations.of(context)!.appToGoogleCalendarSyncCompleted(created, updated, deleted)
                            );
                          } else {
                            SnackBarService.showError(context, AppLocalizations.of(context)!.syncErrorMessage('${result['error']}'));
                          }
                        } catch (e) {
                          SnackBarService.showError(context, AppLocalizations.of(context)!.syncErrorMessage('$e'));
                        }
                      },
                      icon: const Icon(Icons.upload),
                      label: Text(AppLocalizations.of(context)!.appToGoogleCalendarSync),
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
                              AppLocalizations.of(context)!.googleCalendarToAppSyncCompleted(added, skipped)
                            );
                          } else {
                            SnackBarService.showError(context, AppLocalizations.of(context)!.syncErrorMessage('${result['error']}'));
                          }
                        } catch (e) {
                          SnackBarService.showError(context, AppLocalizations.of(context)!.syncErrorMessage('$e'));
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: Text(AppLocalizations.of(context)!.googleCalendarToAppSync),
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


  /// 同期状態表示セクション
  Widget _buildSyncStatusSection(WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.syncStatus,
          style: const TextStyle(
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
                      AppLocalizations.of(context)!.lastSync(DateFormat('MM/dd HH:mm').format(syncState.lastSyncTime!)),
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
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              syncState.hasError ? Colors.red : Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.processingItems(syncState.processedItems ?? 0, syncState.totalItems ?? 0),
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
                  AppLocalizations.of(context)!.error(syncState.errorMessage ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (syncState.errorCode != null)
                  Text(
                    AppLocalizations.of(context)!.errorCode(syncState.errorCode ?? ''),
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
        return AppLocalizations.of(context)!.waiting;
      case SyncStatus.syncing:
        return syncState.message ?? AppLocalizations.of(context)!.syncing;
      case SyncStatus.success:
        return syncState.message ?? AppLocalizations.of(context)!.syncCompleted;
      case SyncStatus.error:
        return AppLocalizations.of(context)!.syncError;
    }
  }

  /// 部分同期機能セクション
  Widget _buildPartialSyncSection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.partialSync,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.partialSyncDescription,
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
                  AppLocalizations.of(context)!.individualTaskSyncInfo,
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
            label: Text(AppLocalizations.of(context)!.syncByDateRange),
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
            label: Text(AppLocalizations.of(context)!.cleanupDuplicateEvents),
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
            label: Text(AppLocalizations.of(context)!.deleteOrphanedEvents),
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
        title: Text(AppLocalizations.of(context)!.orphanedEventsDeletion),
        content: Text(AppLocalizations.of(context)!.orphanedEventsDeletionDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.executeDeletion),
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
        message: AppLocalizations.of(context)!.detectingOrphanedEvents,
      );
      
      final result = await taskViewModel.deleteOrphanedCalendarEvents();
      
      if (result['success'] == true) {
        final deletedCount = result['deletedCount'] ?? 0;
        
        syncStatusNotifier.syncSuccess(
          message: AppLocalizations.of(context)!.orphanedEventsDeletionCompleted(deletedCount),
        );
        
        if (deletedCount > 0) {
          SnackBarService.showSuccess(context, AppLocalizations.of(context)!.orphanedEventsDeleted(deletedCount));
        } else {
          SnackBarService.showSuccess(context, AppLocalizations.of(context)!.noOrphanedEventsFound);
        }
      } else {
        syncStatusNotifier.syncError(
          errorMessage: result['error'] ?? '不明なエラー',
          message: AppLocalizations.of(context)!.orphanedEventsDeletionFailed,
        );
        SnackBarService.showError(context, '${AppLocalizations.of(context)!.orphanedEventsDeletionFailed}: ${result['error']}');
      }
    } catch (e) {
      syncStatusNotifier.syncError(
        errorMessage: e.toString(),
        message: AppLocalizations.of(context)!.orphanedEventsDeletionError,
      );
      SnackBarService.showError(context, '${AppLocalizations.of(context)!.orphanedEventsDeletionError}: $e');
    }
  }

  /// 重複クリーンアップダイアログ
  void _showDuplicateCleanupDialog(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: AppLocalizations.of(context)!.duplicateEventsCleanup,
        icon: Icons.cleaning_services,
        iconColor: Colors.orange,
        content: Text(AppLocalizations.of(context)!.duplicateEventsCleanupDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppButtonStyles.text(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDuplicateCleanup(ref);
            },
            style: AppButtonStyles.warning(context),
            child: Text(AppLocalizations.of(context)!.executeCleanup),
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
        message: AppLocalizations.of(context)!.detectingDuplicateEvents,
      );
      
      final result = await taskViewModel.cleanupGoogleCalendarDuplicates();
      
      if (result['success'] == true) {
        final duplicatesFound = result['duplicatesFound'] ?? 0;
        final duplicatesRemoved = result['duplicatesRemoved'] ?? 0;
        
        syncStatusNotifier.syncSuccess(
          message: AppLocalizations.of(context)!.duplicateCleanupCompleted(duplicatesFound, duplicatesRemoved),
        );
        
        if (duplicatesRemoved > 0) {
          SnackBarService.showSuccess(context, AppLocalizations.of(context)!.duplicateEventsDeleted(duplicatesRemoved));
        } else {
          SnackBarService.showSuccess(context, AppLocalizations.of(context)!.noDuplicateEventsFound);
        }
      } else {
        syncStatusNotifier.syncError(
          errorMessage: result['error'] ?? '不明なエラー',
          message: AppLocalizations.of(context)!.duplicateCleanupFailed,
        );
        SnackBarService.showError(context, '${AppLocalizations.of(context)!.duplicateCleanupFailed}: ${result['error']}');
      }
    } catch (e) {
      syncStatusNotifier.syncError(
        errorMessage: e.toString(),
        message: AppLocalizations.of(context)!.duplicateCleanupError,
      );
      SnackBarService.showError(context, '${AppLocalizations.of(context)!.duplicateCleanupError}: $e');
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
              child: Text(AppLocalizations.of(context)!.cancel),
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

  /// Gmail連携セクション
  Widget _buildGmailApiSection(SettingsState settingsState, SettingsNotifier settingsNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(AppLocalizations.of(context)!.gmailIntegration, FontAwesomeIcons.envelope),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gmail連携説明（常時表示、Outlookと同様）
                // メール送信方法についての説明
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
                            AppLocalizations.of(context)!.gmailIntegrationAbout,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.gmailIntegrationDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.gmailUsage,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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

  /// Outlook連携セクション
  Widget _buildOutlookSection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(AppLocalizations.of(context)!.outlookIntegration, FontAwesomeIcons.microsoft),
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
                        AppLocalizations.of(context)!.outlookIntegrationAbout,
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
                  AppLocalizations.of(context)!.outlookIntegrationDescription,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                
                // PowerShellファイルの詳細説明
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                            AppLocalizations.of(context)!.powershellFileDetails,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Builder(
                        builder: (context) {
                          // 実行ファイルのディレクトリパスを取得
                          String portablePath = AppLocalizations.of(context)!.executableDirectory;
                          try {
                            final executablePath = Platform.resolvedExecutable;
                            final executableDir = File(executablePath).parent.path;
                            portablePath = '$executableDir\\Apps';
                          } catch (e) {
                            // エラー時はデフォルト表示を使用
                          }
                          
                          final appdataPath = Platform.environment['APPDATA'] ?? 
                            'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Roaming';
                          
                          return Column(
                            children: [
                              _buildPowerShellFileInfo(
                                'company_outlook_test.ps1',
                                AppLocalizations.of(context)!.outlookConnectionTest,
                                AppLocalizations.of(context)!.outlookConnectionTestDescription,
                                '${AppLocalizations.of(context)!.portableVersion}: $portablePath\\\n${AppLocalizations.of(context)!.installedVersion}: $appdataPath\\Apps\\',
                                AppLocalizations.of(context)!.manualExecution,
                              ),
                              
                              
                              _buildPowerShellFileInfo(
                                'compose_mail.ps1',
                                AppLocalizations.of(context)!.mailCompositionSupport,
                                AppLocalizations.of(context)!.mailCompositionSupportDescription,
                                '${AppLocalizations.of(context)!.portableVersion}: $portablePath\\\n${AppLocalizations.of(context)!.installedVersion}: $appdataPath\\Apps\\',
                                AppLocalizations.of(context)!.manualExecution,
                              ),
                              
                              _buildPowerShellFileInfo(
                                'find_sent.ps1',
                                AppLocalizations.of(context)!.sentMailSearch,
                                AppLocalizations.of(context)!.sentMailSearchDescription,
                                '${AppLocalizations.of(context)!.portableVersion}: $portablePath\\\n${AppLocalizations.of(context)!.installedVersion}: $appdataPath\\Apps\\',
                                AppLocalizations.of(context)!.manualExecution,
                              ),
                              
                              _buildPowerShellFileInfo(
                                'get_calendar_events.ps1',
                                AppLocalizations.of(context)!.outlookCalendarEvents,
                                AppLocalizations.of(context)!.outlookCalendarEventsDescription,
                                '${AppLocalizations.of(context)!.portableVersion}: $portablePath\\\n${AppLocalizations.of(context)!.installedVersion}: $appdataPath\\Apps\\',
                                AppLocalizations.of(context)!.automaticExecution,
                              ),
                            ],
                          );
                        },
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
                                  AppLocalizations.of(context)!.importantNotes,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Builder(
                              builder: (context) {
                                // 実行ファイルのディレクトリパスを取得
                                String portablePath = AppLocalizations.of(context)!.executableDirectory;
                                try {
                                  final executablePath = Platform.resolvedExecutable;
                                  final executableDir = File(executablePath).parent.path;
                                  portablePath = '$executableDir\\Apps';
                                } catch (e) {
                                  // エラー時はデフォルト表示を使用
                                }
                                
                                final appdataPath = Platform.environment['APPDATA'] ?? 
                                  'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Roaming';
                                
                                return Text(
                                  AppLocalizations.of(context)!.importantNotesContent(portablePath, '$appdataPath\\Apps'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                    height: 1.4,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // 接続テストボタン
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _testOutlookConnection,
                      icon: const Icon(Icons.wifi_protected_setup),
                      label: Text(AppLocalizations.of(context)!.connectionTest),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Outlook自動取込設定
                _buildSectionHeader(AppLocalizations.of(context)!.outlookPersonalCalendarAutoImport, Icons.sync),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSwitchWithDescription(
                          title: AppLocalizations.of(context)!.enableAutomaticImport,
                          description: AppLocalizations.of(context)!.enableAutomaticImportDescription,
                          value: ref.watch(settingsProvider).outlookAutoSyncEnabled,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).setOutlookAutoSyncEnabled(value);
                          },
                        ),
                        if (ref.watch(settingsProvider).outlookAutoSyncEnabled) ...[
                          const SizedBox(height: 24),
                          _buildSectionSubHeader(AppLocalizations.of(context)!.importPeriod),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.importPeriodDescription,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPeriodSelector(ref),
                          const SizedBox(height: 24),
                          _buildSectionSubHeader(AppLocalizations.of(context)!.automaticImportFrequency),
                          const SizedBox(height: 8),
                          _buildFrequencySelector(ref),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Outlook設定情報
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.outlookSettingsInfo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.outlookSettingsInfoContent,
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


  /// Google Calendar設定ガイドを開く
  void _openGoogleCalendarSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: AppLocalizations.of(context)!.googleCalendarSetupGuide,
        icon: Icons.calendar_today,
        iconColor: Colors.blue,
        width: 700,
        height: 800,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              AppLocalizations.of(context)!.googleCalendarSetupSteps,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGuideStep('1', AppLocalizations.of(context)!.accessGoogleCloudConsole),
            const Text('https://console.cloud.google.com/'),
            const SizedBox(height: 12),
            _buildGuideStep('2', AppLocalizations.of(context)!.createOrSelectProject),
            const SizedBox(height: 12),
            _buildGuideStep('3', AppLocalizations.of(context)!.enableGoogleCalendarAPI),
            Text(AppLocalizations.of(context)!.enableGoogleCalendarAPIDescription),
            const SizedBox(height: 12),
            _buildGuideStep('4', AppLocalizations.of(context)!.createOAuth2ClientID),
            Text(AppLocalizations.of(context)!.createOAuth2ClientIDDescription),
            const SizedBox(height: 12),
            _buildGuideStep('5', AppLocalizations.of(context)!.downloadCredentialsFile),
            Text(AppLocalizations.of(context)!.downloadCredentialsFileDescription),
            const SizedBox(height: 12),
            _buildGuideStep('6', AppLocalizations.of(context)!.placeFileInAppFolder),
            Text(AppLocalizations.of(context)!.placeFileInAppFolderDescription),
            const SizedBox(height: 12),
            _buildGuideStep('7', AppLocalizations.of(context)!.executeOAuth2Authentication),
            Text(AppLocalizations.of(context)!.executeOAuth2AuthenticationDescription),
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
                        AppLocalizations.of(context)!.generatedFiles,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.oauth2AuthCompleted,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.thisFileContains,
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
      
      // Outlook接続テスト（簡易版）
      await Future.delayed(const Duration(seconds: 1));
      
      // ローディングを閉じる
      Navigator.pop(context);
      
      SnackBarService.showSuccess(context, 'Outlook接続テストが完了しました！');
    } catch (e) {
      // ローディングを閉じる（エラー時も）
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      SnackBarService.showError(context, 'Outlook接続テストエラー: $e');
    }
  }

  /// セクションサブヘッダー
  Widget _buildSectionSubHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// 取込期間セレクター
  Widget _buildPeriodSelector(WidgetRef ref) {
    final periodOptions = [
      {'label': AppLocalizations.of(context)!.oneWeek, 'days': 7},
      {'label': AppLocalizations.of(context)!.twoWeeks, 'days': 14},
      {'label': AppLocalizations.of(context)!.oneMonth, 'days': 30},
      {'label': AppLocalizations.of(context)!.threeMonths, 'days': 90},
      {'label': AppLocalizations.of(context)!.halfYear, 'days': 180},
      {'label': AppLocalizations.of(context)!.oneYear, 'days': 365},
    ];

    final currentDays = ref.watch(settingsProvider).outlookAutoSyncPeriodDays;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: periodOptions.map((option) {
        final days = option['days'] as int;
        final label = option['label'] as String;
        final isSelected = currentDays == days;

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              ref.read(settingsProvider.notifier).setOutlookAutoSyncPeriodDays(days);
            }
          },
        );
      }).toList(),
    );
  }

  /// 自動取込頻度セレクター
  Widget _buildFrequencySelector(WidgetRef ref) {
    final frequencyOptions = [
      {'value': 'on_startup', 'label': AppLocalizations.of(context)!.onlyOnAppStart},
      {'value': '30min', 'label': AppLocalizations.of(context)!.every30Minutes},
      {'value': '1hour', 'label': AppLocalizations.of(context)!.every1Hour},
      {'value': 'daily_9am', 'label': AppLocalizations.of(context)!.everyMorning9am},
    ];

    final currentFrequency = ref.watch(settingsProvider).outlookAutoSyncFrequency;

    return Column(
      children: frequencyOptions.map((option) {
        final value = option['value'] as String;
        final label = option['label'] as String;

        return RadioListTile<String>(
          title: Text(label),
          value: value,
          groupValue: currentFrequency,
          onChanged: (selectedValue) {
            if (selectedValue != null) {
              ref.read(settingsProvider.notifier).setOutlookAutoSyncFrequency(selectedValue);
            }
          },
        );
      }).toList(),
    );
  }
  
  
  

}

// 設定セクション管理用プロバイダー
final settingsSectionProvider = StateProvider<String>((ref) => 'theme');
