import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import '../models/task_item.dart';
import '../models/link_item.dart';
import '../models/group.dart';
import '../views/home_screen.dart'; // HighlightedText用
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/link_viewmodel.dart';
import '../viewmodels/sub_task_viewmodel.dart';
import '../services/notification_service.dart';
import '../services/windows_notification_service.dart';
import '../services/settings_service.dart';
import '../services/snackbar_service.dart';
import '../viewmodels/sync_status_provider.dart';
import 'settings_screen.dart';
import '../utils/csv_export.dart';
import 'task_dialog.dart';
import 'sub_task_dialog.dart';
import '../widgets/mail_badge.dart';
import '../services/mail_service.dart';
import '../models/sent_mail_log.dart';
import '../models/sub_task.dart';
import '../services/keyboard_shortcut_service.dart';
import '../viewmodels/font_size_provider.dart';
import '../viewmodels/ui_customization_provider.dart';
import '../viewmodels/layout_settings_provider.dart';
import '../widgets/unified_dialog.dart';
import '../widgets/copy_task_dialog.dart';
import '../widgets/task_template_dialog.dart';
import '../widgets/app_button_styles.dart';
import '../widgets/app_spacing.dart';
import '../widgets/link_association_dialog.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  late SettingsService _settingsService;
  Set<String> _filterStatuses = {'all'}; // 複数選択可能
  String _filterPriority = 'all'; // all, low, medium, high, urgent
  String _searchQuery = '';
  List<Map<String, String>> _sortOrders = [{'field': 'dueDate', 'order': 'asc'}]; // 第3順位まで設定可能
  bool _showFilters = false; // フィルター表示/非表示の切り替え
  bool _showHeaderSection = true; // 統計情報と検索バーの表示/非表示の切り替え
  final FocusNode _appBarMenuFocusNode = FocusNode();
  late FocusNode _searchFocusNode;

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
  
  // フォーカス
  final FocusNode _rootKeyFocus = FocusNode(debugLabel: 'rootKeys');
  // 検索欄
  late final TextEditingController _searchController;
  // ユーザーが検索操作を始めたか（ハイライト制御用）
  bool _userTypedSearch = false;
  
  // 一括選択機能の状態変数
  bool _isSelectionMode = false; // 選択モードのオン/オフ
  Set<String> _selectedTaskIds = {}; // 選択されたタスクのIDセット
  // タスクごとの詳細展開状態
  Set<String> _expandedTaskIds = {};
  // タスクごとのホバー状態
  final Set<String> _hoveredTaskIds = {};
  
  // 並び替え機能
  String _sortBy = 'dueDate'; // dueDate, priority, created, title, status
  bool _sortAscending = true;
  // ピン留めされたタスクID
  Set<String> _pinnedTaskIds = <String>{};
  
  // 検索機能強化
  bool _useRegex = false;
  bool _searchInDescription = true;
  bool _searchInTags = true;
  bool _searchInRequester = true;
  List<String> _searchHistory = [];
  bool _showSearchOptions = false;

  @override
  void initState() {
    super.initState();
    print('=== TaskScreen initState 開始 ===');
    _settingsService = SettingsService.instance;
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();

    _searchQuery = '';
    print('初期化時の_searchQuery: "$_searchQuery"');
    
    // 検索履歴を読み込み
    _loadSearchHistory();
    // ピン留めを読み込み
    _loadPinnedTasks();
    
    // 検索コントローラーのリスナーを追加（初期化直後）
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
          _userTypedSearch = _searchQuery.isNotEmpty;
        });
      }
    });

    _initializeSettings().then((_) {
      if (!mounted) return;

      // 初期表示は必ず空にする（復元値を使わない仕様）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _searchQuery = '';
          _searchController.clear();
        });
        _saveFilterSettings();        // 空で保存して以後は空スタート
        _searchFocusNode.requestFocus(); // カーソルも置く
      });
    });

    // 検索クエリの同期はonChangedで処理
    print('=== TaskScreen initState 終了 ===');
  }

  void _loadPinnedTasks() {
    try {
      final box = Hive.box('pinnedTasks');
      final ids = box.get('ids', defaultValue: <String>[]) as List;
      _pinnedTaskIds = ids.map((e) => e.toString()).toSet();
    } catch (_) {}
  }

  void _savePinnedTasks() {
    try {
      Hive.box('pinnedTasks').put('ids', _pinnedTaskIds.toList());
    } catch (_) {}
  }

  void _togglePinTask(String taskId) {
    setState(() {
      if (_pinnedTaskIds.contains(taskId)) {
        _pinnedTaskIds.remove(taskId);
      } else {
        _pinnedTaskIds.add(taskId);
      }
      _savePinnedTasks();
    });
  }

  @override
  void dispose() {
    _rootKeyFocus.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _appBarMenuFocusNode.dispose();
    super.dispose();
  }

  /// 選択モードの切り替え
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTaskIds.clear();
      }
    });
  }

  /// ホーム画面に遷移（タスク管理デフォルトトグル対応）
  void _navigateToHome(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      // 通常のナビゲーション（ホーム画面から来た場合）
      Navigator.of(context).pop();
    } else {
      // タスク管理デフォルトトグルがオンの場合（ルート画面の場合）
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  /// タスクの選択状態を切り替え
  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  /// 全選択/全解除
  void _toggleSelectAll(List<TaskItem> sortedTasks) {
    setState(() {
      if (_selectedTaskIds.length == sortedTasks.length) {
        // 全選択されている場合は全解除
        _selectedTaskIds.clear();
      } else {
        // 一部または未選択の場合は全選択
        _selectedTaskIds = sortedTasks.map((task) => task.id).toSet();
      }
    });
  }

  /// 選択されたタスクを一括削除
  Future<void> _deleteSelectedTasks() async {
    if (_selectedTaskIds.isEmpty) return;

    final confirmed = await UnifiedDialogHelper.showDeleteConfirmDialog(
      context,
      title: '確認',
      message: '選択した${_selectedTaskIds.length}件のタスクを削除しますか？',
      confirmText: '削除',
      cancelText: 'キャンセル',
    );

    if (confirmed == true) {
      try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
        final deletedCount = _selectedTaskIds.length;
      
      // 選択されたタスクを削除
      for (final taskId in _selectedTaskIds) {
          await taskViewModel.deleteTask(taskId);
      }

      // 選択モードを解除
      setState(() {
        _selectedTaskIds.clear();
        _isSelectionMode = false;
      });

      // 削除完了のメッセージを表示
      if (mounted) {
        SnackBarService.showSuccess(
          context,
            '$deletedCount件のタスクを削除しました',
        );
        }
      } catch (e) {
        if (mounted) {
          SnackBarService.showError(context, '削除に失敗しました: $e');
        }
      }
    }
  }

  /// 設定サービスを初期化してからフィルター設定を読み込み
  Future<void> _initializeSettings() async {
    try {
      if (!_settingsService.isInitialized) {
        await _settingsService.initialize();
      }
      if (mounted) {
        setState(() {
          _loadFilterSettings();
        });
      }
    } catch (e) {
      print('設定サービスの初期化エラー: $e');
      // 初期化に失敗した場合はデフォルト値を使用
      if (mounted) {
        setState(() {
          _filterStatuses = {'all'};
          _filterPriority = 'all';
          _sortOrders = [{'field': 'dueDate', 'order': 'asc'}];
          _searchQuery = '';
        });
      }
    }
  }

  /// フィルター設定を読み込み
  void _loadFilterSettings() {
    try {
      if (_settingsService.isInitialized) {
        _filterStatuses = _settingsService.taskFilterStatuses.toSet();
        _filterPriority = _settingsService.taskFilterPriority;
        _sortOrders = _settingsService.taskSortOrders.map((item) => Map<String, String>.from(item)).toList();
        _searchQuery = _settingsService.taskSearchQuery;
      } else {
        // 設定サービスが初期化されていない場合はデフォルト値を使用
        _filterStatuses = {'all'};
        _filterPriority = 'all';
        _sortOrders = [{'field': 'dueDate', 'order': 'asc'}];
        _searchQuery = '';
      }
    } catch (e) {
      print('フィルター設定の読み込みエラー: $e');
      // エラーの場合はデフォルト値を使用
      _filterStatuses = {'all'};
      _filterPriority = 'all';
      _sortOrders = [{'field': 'dueDate', 'order': 'asc'}];
      _searchQuery = '';
    }
  }

  /// フィルター設定を保存
  Future<void> _saveFilterSettings() async {
    try {
      if (_settingsService.isInitialized) {
        await _settingsService.setTaskFilterStatuses(_filterStatuses.toList());
        await _settingsService.setTaskFilterPriority(_filterPriority);
        await _settingsService.setTaskSortOrders(_sortOrders);
        await _settingsService.setTaskSearchQuery(_searchQuery);
      }
    } catch (e) {
      print('フィルター設定の保存エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🚨 TaskScreen build開始');
    
    // TaskViewModelの作成を強制
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    final tasks = ref.watch(taskViewModelProvider);
    final statistics = taskViewModel.getTaskStatistics();
    
    // 重要な情報のみ出力
    print('🚨 タスク数: ${tasks.length}');
    
    // アクセントカラーの調整色を取得
    final accentColor = ref.watch(accentColorProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final colorContrast = ref.watch(colorContrastProvider);
    final adjustedAccentColor = _getAdjustedColor(accentColor, colorIntensity, colorContrast);

    // フィルタリング
    final filteredTasks = _getFilteredTasks(tasks);
    
    // 並び替え
    final sortedTasks = _sortTasks(filteredTasks);
    
    // 重要な情報のみ出力
    if (tasks.isNotEmpty) {
      print('🚨 フィルタリング後: ${filteredTasks.length}件表示');
      print('🚨 並び替え後: ${sortedTasks.length}件表示');
    } else {
      print('🚨 タスクが存在しません！');
    }

    return KeyboardShortcutWidget(
      child: FocusScope(
        autofocus: false,
        child: Focus(
          autofocus: false,
          canRequestFocus: true,
          skipTraversal: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              print('🔑 キーイベント受信: ${event.logicalKey.keyLabel}, Ctrl=${HardwareKeyboard.instance.isControlPressed}, Shift=${HardwareKeyboard.instance.isShiftPressed}');
              
              final isControlPressed = HardwareKeyboard.instance.isControlPressed;
              final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
              
              // Ctrl+H: 統計・検索バーの表示/非表示（常に有効）
              if (event.logicalKey == LogicalKeyboardKey.keyH && isControlPressed && !isShiftPressed) {
                print('✅ Ctrl+H 検出: 統計・検索バー切り替え');
                setState(() {
                  _showHeaderSection = !_showHeaderSection;
                });
                return KeyEventResult.handled;
              }
              
              // F1: ショートカットヘルプ（常に有効）
              if (event.logicalKey == LogicalKeyboardKey.f1) {
                print('✅ F1 検出: ショートカットヘルプ表示');
                _showShortcutHelp(context);
                return KeyEventResult.handled;
              }
              
              // その他のショートカット処理
              final result = _handleKeyEventShortcut(event, isControlPressed, isShiftPressed);
              if (result) {
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: KeyboardListener(
            focusNode: _rootKeyFocus,
            autofocus: false,
            onKeyEvent: (e) {
              // フォールバック: KeyboardListenerでも処理
              if (e is KeyDownEvent) {
                final isControlPressed = HardwareKeyboard.instance.isControlPressed;
                final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
                _handleKeyEventShortcut(e, isControlPressed, isShiftPressed);
              }
            },
            child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.98),
          appBar: AppBar(
            title: _isSelectionMode 
              ? Text('${_selectedTaskIds.length}件選択中')
              : Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8 * ref.watch(uiDensityProvider)),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('タスク管理'),
                  ],
                ),
            leading: _isSelectionMode 
              ? IconButton(
                  onPressed: _toggleSelectionMode,
                  icon: const Icon(Icons.close),
                  tooltip: '選択モードを終了',
                )
              : IconButton(
                  onPressed: () => _navigateToHome(context),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'ホーム画面に戻る',
                ),
            actions: [
              if (_isSelectionMode) ...[
                // 全選択/全解除ボタン
                IconButton(
              onPressed: () => _toggleSelectAll(filteredTasks),
              icon: Icon(_selectedTaskIds.length == filteredTasks.length 
                ? Icons.deselect 
                : Icons.select_all),
              tooltip: _selectedTaskIds.length == filteredTasks.length 
                ? '全解除' 
                : '全選択',
            ),
            // 削除ボタン
            IconButton(
              onPressed: _selectedTaskIds.isEmpty ? null : _deleteSelectedTasks,
              icon: const Icon(Icons.delete),
              tooltip: '選択したタスクを削除',
            ),
             ] else ...[
            // 3点ドットメニューに統合
            Focus(
              focusNode: _appBarMenuFocusNode,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    // 左矢印キーでホーム画面に戻る
                    _navigateToHome(context);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    // エンターキーでメニューを開く
                    _showPopupMenu(context);
                    return KeyEventResult.handled;
                  }
                }//if (event is KeyDownEvent)
                return KeyEventResult.ignored;
              },
              child: PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              // 新しいタスク作成
              PopupMenuItem(
                value: 'add_task',
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('新しいタスク (Ctrl+N)'),
                  ],
                ),
              ),
              // 一括選択モード
              PopupMenuItem(
                value: 'bulk_select',
                child: Row(
                  children: [
                    Icon(Icons.checklist, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('一括選択モード (Ctrl+B)'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('CSV出力 (Ctrl+Shift+E)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text('設定 (Ctrl+Shift+S)'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // プロジェクト一覧
              PopupMenuItem(
                value: 'project_overview',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('プロジェクト一覧 (Ctrl+P)'),
                  ],
                ),
              ),
              // 並び替え
              PopupMenuItem(
                value: 'sort_menu',
                child: Row(
                  children: [
                    Icon(Icons.sort, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('並び替え (Ctrl+O)'),
                  ],
                ),
              ),
              // テンプレートから作成
              PopupMenuItem(
                value: 'task_template',
                child: Row(
                  children: [
                    Icon(Icons.content_copy, color: Colors.teal, size: 20),
                    SizedBox(width: 8),
                    Text('テンプレートから作成 (Ctrl+Shift+T)'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'toggle_header',
                child: Row(
                  children: [
                    Icon(
                      _showHeaderSection ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(_showHeaderSection ? '統計・検索バーを非表示 (Ctrl+H)' : '統計・検索バーを表示 (Ctrl+H)'),
                  ],
                ),
              ),
            ],//itemBuilder
          ),
          ),
         ],//else
         ],//actions
       ),
        body: Column(
          children: [
          // 統計情報と検索・フィルターを1行に配置
          if (_showHeaderSection) _buildCompactHeaderSection(statistics),
          
          // 検索オプション（折りたたみ可能）
          if (_showSearchOptions && _showHeaderSection) _buildSearchOptionsSection(),
          
          // ステータスフィルター（折りたたみ可能）
          if (_showFilters) _buildStatusFilterSection(),
          
          // タスク一覧（ピン留めタスク固定 + 通常タスクスクロール）
          Expanded(
            child: sortedTasks.isEmpty
                ? const Center(
                    child: Text('タスクがありません'),
                  )
                : _buildPinnedAndScrollableTaskList(sortedTasks),
          ),//Expanded
          ],//children
        ),//Column
          ),//Scaffold
          ),//KeyboardListener
        ),//Focus
      ),//FocusScope
    );//KeyboardShortcutWidget
  }//build

  Widget _buildCompactHeaderSection(Map<String, int> statistics) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // 左半分: 統計情報（コンパクト）
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('総タスク', statistics['total'] ?? 0, Icons.list),
                const SizedBox(width: 4),
                _buildStatItem('未着手', statistics['pending'] ?? 0, Icons.radio_button_unchecked, Colors.grey),
                const SizedBox(width: 4),
                _buildStatItem('完了', statistics['completed'] ?? 0, Icons.check_circle, Colors.green),
                const SizedBox(width: 4),
                _buildStatItem('進行中', statistics['inProgress'] ?? 0, Icons.pending, Colors.blue),
                const SizedBox(width: 4),
                _buildStatItem('期限切れ', statistics['overdue'] ?? 0, Icons.warning, Colors.red),
                const SizedBox(width: 4),
                _buildStatItem('今日', statistics['today'] ?? 0, Icons.today, Colors.orange),
              ],
            ),
          ),
          
          // 一括詳細トグルボタン
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Tooltip(
              message: _expandedTaskIds.isEmpty ? 'すべて詳細表示' : 'すべて詳細非表示',
              child: IconButton(
                onPressed: () {
                  setState(() {
                    if (_expandedTaskIds.isEmpty) {
                      // すべて詳細表示
                      final tasks = ref.read(taskViewModelProvider);
                      _expandedTaskIds = tasks.map((task) => task.id).toSet();
                    } else {
                      // すべて詳細非表示
                      _expandedTaskIds.clear();
                    }
                  });
                },
                icon: Icon(
                  _expandedTaskIds.isEmpty ? Icons.expand_more : Icons.expand_less,
                  color: _expandedTaskIds.isEmpty ? Colors.grey : Colors.blue,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _expandedTaskIds.isEmpty 
                      ? Colors.grey.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  foregroundColor: _expandedTaskIds.isEmpty ? Colors.grey : Colors.blue,
                  padding: EdgeInsets.all(8 * ref.watch(uiDensityProvider)),
                  minimumSize: const Size(32, 32),
                  maximumSize: const Size(32, 32),
                ),
              ),
            ),
          ),
          
          // 右半分: 検索とフィルター
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.lg),
                // 強化された検索バー
                Expanded(
                  flex: 3, // 検索バーを広く
                  child: Builder(
                    builder: (context) {
                      print('TextField構築時: _searchFocusNode.hasFocus=${_searchFocusNode.hasFocus}');
                      return TextField(
                        key: const ValueKey('task_search_field'),
                        controller: _searchController,                 // ← controller を使う
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: _useRegex 
                            ? '正規表現で検索（例: ^プロジェクト.*完了\$）...'
                            : 'タスクを検索（タイトル・説明・タグ・依頼先）...',
                          prefixIcon: Icon(Icons.search, size: AppIconSizes.medium),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 入力前から履歴アイコンを表示
                              IconButton(
                                icon: const Icon(Icons.history, size: 20),
                                onPressed: _showSearchHistory,
                                tooltip: '検索履歴',
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _userTypedSearch = false;
                                    });
                                  },
                                  tooltip: 'クリア',
                                ),
                              ],
                              IconButton(
                                icon: Icon(
                                  _useRegex ? Icons.code : Icons.text_fields,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _useRegex = !_useRegex;
                                  });
                                },
                                tooltip: _useRegex ? '通常検索に切り替え' : '正規表現検索に切り替え',
                              ),
                              IconButton(
                                icon: const Icon(Icons.tune, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _showSearchOptions = !_showSearchOptions;
                                  });
                                },
                                tooltip: '検索オプション',
                              ),
                            ],
                          ),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          isDense: true,
                        ),
                        onTap: () {
                          print('=== 検索フィールドタップ ===');
                          print('現在の_userTypedSearch: $_userTypedSearch');
                          print('現在の_searchQuery: "$_searchQuery"');
                          print('========================');
                        },
                        onChanged: (value) {
                          // 設定を保存
                          _saveFilterSettings();
                          // フォーカスを再主張（親に奪われた直後でも戻す）
                          if (!_searchFocusNode.hasFocus) {
                            _searchFocusNode.requestFocus();
                          }
                        },
                        onSubmitted: (value) {
                          // Enter で確定した際の処理
                          _saveFilterSettings();
                          // 検索実行時に履歴に追加
                          if (value.trim().isNotEmpty) {
                            _addToSearchHistory(value.trim());
                          }
                        },
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: AppSpacing.sm),
                
                // 優先度フィルター
                Expanded(
                  flex: 1, // 優先度ドロップダウンを狭く
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      labelText: '優先度',
                      isDense: true,
                    ),
                    value: _filterPriority,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('すべて')),
                      DropdownMenuItem(value: 'low', child: Text('低')),
                      DropdownMenuItem(value: 'medium', child: Text('中')),
                      DropdownMenuItem(value: 'high', child: Text('高')),
                      DropdownMenuItem(value: 'urgent', child: Text('緊急')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filterPriority = value;
                        });
                        _saveFilterSettings();
                      }
                    },
                  ),
                ),
                
                const SizedBox(width: AppSpacing.sm),
                
                // フィルター表示/非表示ボタン
                IconButton(
                  icon: Icon(_showFilters ? Icons.expand_less : Icons.expand_more, size: AppIconSizes.medium),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  tooltip: _showFilters ? 'フィルターを隠す' : 'フィルターを表示',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, [Color? color]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: AppIconSizes.medium),
        const SizedBox(height: 2),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildStatusFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // ステータスフィルター
          _buildStatusFilterChips(),
          
          // 折りたたみ可能な並び替えセクション
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSortingSection(),
          ),
        ],
      ),
    );
  }

  // ステータスフィルター（複数選択）
  Widget _buildStatusFilterChips() {
    return Row(
      children: [
        const Text('ステータス:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('すべて', style: TextStyle(fontSize: 11)),
                selected: _filterStatuses.contains('all'),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _filterStatuses = {'all'};
                    } else {
                      _filterStatuses.remove('all');
                    }
                  });
                  _saveFilterSettings();
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
              FilterChip(
                label: const Text('未着手', style: TextStyle(fontSize: 11)),
                selected: _filterStatuses.contains('pending'),
                onSelected: (selected) {
                  setState(() {
                    _filterStatuses.remove('all');
                    if (selected) {
                      _filterStatuses.add('pending');
                    } else {
                      _filterStatuses.remove('pending');
                    }
                  });
                  _saveFilterSettings();
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
              FilterChip(
                label: const Text('進行中', style: TextStyle(fontSize: 11)),
                selected: _filterStatuses.contains('inProgress'),
                onSelected: (selected) {
                  setState(() {
                    _filterStatuses.remove('all');
                    if (selected) {
                      _filterStatuses.add('inProgress');
                    } else {
                      _filterStatuses.remove('inProgress');
                    }
                  });
                  _saveFilterSettings();
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
              FilterChip(
                label: const Text('完了', style: TextStyle(fontSize: 11)),
                selected: _filterStatuses.contains('completed'),
                onSelected: (selected) {
                  setState(() {
                    _filterStatuses.remove('all');
                    if (selected) {
                      _filterStatuses.add('completed');
                    } else {
                      _filterStatuses.remove('completed');
                    }
                  });
                  _saveFilterSettings();
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 並び替えセクション（第3順位まで）
  Widget _buildSortingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('並び替え順序:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // 3つの並び替え順位を横並びに
        Row(
          children: [
            // 第1順位
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('第1順位', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            isDense: true,
                          ),
                          value: _sortOrders.isNotEmpty ? _sortOrders[0]['field'] : 'dueDate',
                          items: [
                            const DropdownMenuItem(value: 'dueDate', child: Text('期限順')),
                            const DropdownMenuItem(value: 'priority', child: Text('優先度順')),
                            const DropdownMenuItem(value: 'title', child: Text('タイトル順')),
                            const DropdownMenuItem(value: 'createdAt', child: Text('作成日順')),
                            const DropdownMenuItem(value: 'status', child: Text('ステータス順')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (_sortOrders.isEmpty) {
                                _sortOrders = [{'field': value!, 'order': 'asc'}];
                              } else {
                                _sortOrders[0] = {'field': value!, 'order': _sortOrders[0]['order']!};
                              }
                            });
                            _saveFilterSettings();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            isDense: true,
                          ),
                          value: _sortOrders.isNotEmpty ? _sortOrders[0]['order'] : 'asc',
                  items: const [
                            DropdownMenuItem(value: 'asc', child: Text('昇順')),
                            DropdownMenuItem(value: 'desc', child: Text('降順')),
                  ],
                  onChanged: (value) {
                      setState(() {
                              if (_sortOrders.isNotEmpty) {
                                _sortOrders[0] = {'field': _sortOrders[0]['field']!, 'order': value!};
                              }
                            });
                            _saveFilterSettings();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 第2順位
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('第2順位', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            isDense: true,
                          ),
                          value: _sortOrders.length > 1 ? _sortOrders[1]['field'] : null,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('なし')),
                            const DropdownMenuItem(value: 'dueDate', child: Text('期限順')),
                            const DropdownMenuItem(value: 'priority', child: Text('優先度順')),
                            const DropdownMenuItem(value: 'title', child: Text('タイトル順')),
                            const DropdownMenuItem(value: 'createdAt', child: Text('作成日順')),
                            const DropdownMenuItem(value: 'status', child: Text('ステータス順')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (value == null) {
                                if (_sortOrders.length > 1) {
                                  _sortOrders.removeAt(1);
                                }
                              } else {
                                if (_sortOrders.length > 1) {
                                  _sortOrders[1] = {'field': value, 'order': _sortOrders[1]['order']!};
                                } else {
                                  _sortOrders.add({'field': value, 'order': 'asc'});
                                }
                              }
                            });
                            _saveFilterSettings();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            isDense: true,
                          ),
                          value: _sortOrders.length > 1 ? _sortOrders[1]['order'] : 'asc',
                          items: const [
                            DropdownMenuItem(value: 'asc', child: Text('昇順')),
                            DropdownMenuItem(value: 'desc', child: Text('降順')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (_sortOrders.length > 1) {
                                _sortOrders[1] = {'field': _sortOrders[1]['field']!, 'order': value!};
                              }
                            });
                            _saveFilterSettings();
                          },
                        ),
            ),
          ],
        ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 第3順位
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('第3順位', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            isDense: true,
                          ),
                          value: _sortOrders.length > 2 ? _sortOrders[2]['field'] : null,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('なし')),
                            const DropdownMenuItem(value: 'dueDate', child: Text('期限順')),
                            const DropdownMenuItem(value: 'priority', child: Text('優先度順')),
                            const DropdownMenuItem(value: 'title', child: Text('タイトル順')),
                            const DropdownMenuItem(value: 'createdAt', child: Text('作成日順')),
                            const DropdownMenuItem(value: 'status', child: Text('ステータス順')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (value == null) {
                                if (_sortOrders.length > 2) {
                                  _sortOrders.removeAt(2);
                                }
                              } else {
                                if (_sortOrders.length > 2) {
                                  _sortOrders[2] = {'field': value, 'order': _sortOrders[2]['order']!};
                                } else {
                                  _sortOrders.add({'field': value, 'order': 'asc'});
                                }
                              }
                            });
                            _saveFilterSettings();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            isDense: true,
                          ),
                          value: _sortOrders.length > 2 ? _sortOrders[2]['order'] : 'asc',
                          items: const [
                            DropdownMenuItem(value: 'asc', child: Text('昇順')),
                            DropdownMenuItem(value: 'desc', child: Text('降順')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (_sortOrders.length > 2) {
                                _sortOrders[2] = {'field': _sortOrders[2]['field']!, 'order': value!};
                              }
                            });
                            _saveFilterSettings();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    print('=== _buildTaskCard呼び出し ===');
    print('task.title: "${task.title}"');
    print('_userTypedSearch: $_userTypedSearch');
    print('_searchQuery: "$_searchQuery"');
    print('============================');
    final isSelected = _selectedTaskIds.contains(task.id);
    final isAutoGenerated = _isAutoGeneratedTask(task);
    
    final isHovered = _hoveredTaskIds.contains(task.id);
    
    // UIカスタマイズ設定を取得
    final uiState = ref.watch(uiCustomizationProvider);
    
    // アクセントカラーの調整色を取得
    final accentColor = ref.watch(accentColorProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final colorContrast = ref.watch(colorContrastProvider);
    final adjustedAccentColor = _getAdjustedColor(accentColor, colorIntensity, colorContrast);
    
    return Tooltip(
      message: 'タスクをクリックして編集',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredTaskIds.add(task.id)),
        onExit: (_) => setState(() => _hoveredTaskIds.remove(task.id)),
        child: AnimatedContainer(
        key: ValueKey(task.id),
        duration: Duration(milliseconds: uiState.animationDuration), // UIカスタマイズのアニメーション時間
        curve: Curves.easeOutCubic, // より滑らかなカーブ
        margin: EdgeInsets.symmetric(
          horizontal: uiState.spacing * 1.5, 
          vertical: uiState.spacing
        ), // UIカスタマイズのスペーシング
        decoration: BoxDecoration(
          color: _isSelectionMode && isSelected 
            ? Theme.of(context).primaryColor.withValues(alpha: 0.15) 
            : isHovered
              ? Theme.of(context).primaryColor.withValues(alpha: uiState.hoverEffectIntensity) // UIカスタマイズのホバー効果
              : _getTaskCardColor(task), // 期限日に応じた色
          borderRadius: BorderRadius.circular(uiState.cardBorderRadius), // UIカスタマイズの角丸半径
          border: Border.all(
            color: _isSelectionMode && isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.6)
              : isHovered
                ? Theme.of(context).primaryColor.withValues(alpha: 0.8)
                : _getTaskBorderColor(task), // 期限日に応じたボーダー色
            width: _isSelectionMode && isSelected ? 3 : isHovered ? 4 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: uiState.shadowIntensity), // UIカスタマイズの影の強さ
              blurRadius: isHovered ? uiState.cardElevation * 8 : uiState.cardElevation * 4, // UIカスタマイズの影の強さ
              offset: Offset(0, isHovered ? uiState.cardElevation * 4 : uiState.cardElevation * 2),
            ),
            if (_isSelectionMode && isSelected)
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            if (isHovered && !_isSelectionMode)
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: uiState.shadowIntensity * 1.5),
                blurRadius: uiState.cardElevation * 12,
                offset: Offset(0, uiState.cardElevation * 5),
              ),
            // 追加のグロー効果
            if (isHovered && !_isSelectionMode)
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: uiState.gradientIntensity),
                blurRadius: uiState.cardElevation * 16,
                offset: Offset(0, uiState.cardElevation * 6),
              ),
          ],
        ),
        child: Stack(
          children: [
            _buildImprovedTaskListTile(task, isSelected),
            if (isAutoGenerated) _buildEmailBadge(task),
          ],
        ),
      ),
     ),
    );
  }
  
  /// 改善されたタスクのListTileを構築（指示書に基づく）
  Widget _buildImprovedTaskListTile(TaskItem task, bool isSelected) {
    bool isExpanded = _expandedTaskIds.contains(task.id);
    final bool hasDetails =
        (task.description != null && task.description!.isNotEmpty) ||
        _hasValidLinks(task);
    
    // UIカスタマイズ設定を取得
    final uiState = ref.watch(uiCustomizationProvider);
    
    // アクセントカラーの調整色を取得
    final accentColor = ref.watch(accentColorProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final colorContrast = ref.watch(colorContrastProvider);
    final adjustedAccentColor = _getAdjustedColor(accentColor, colorIntensity, colorContrast);
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: uiState.cardPadding, 
        vertical: uiState.cardPadding * 0.75
      ), // UIカスタマイズのパディング
      leading: _isSelectionMode 
        ? Checkbox(
            value: isSelected,
            onChanged: (_) => _toggleTaskSelection(task.id),
          )
        : _buildDeadlineIndicator(task),
      title: Row(
        children: [
          // 詳細ボタン（左寄せ）: 表示内容がある場合のみ
          if (hasDetails)
            TextButton(
              onPressed: () => setState(() {
                if (isExpanded) {
                  _expandedTaskIds.remove(task.id);
                } else {
                  _expandedTaskIds.add(task.id);
                }
              }),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                children: [
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 2),
                  Text(
                    isExpanded ? '閉じる' : '詳細',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: _searchQuery.isNotEmpty
                ? HighlightedText(
                    text: task.title,
                    highlight: _searchQuery,
                    style: TextStyle(
                      color: _getTaskTitleColor(),
                      decoration: task.status == TaskStatus.completed 
                          ? TextDecoration.lineThrough 
                          : null,
                      fontSize: 16 * ref.watch(titleFontSizeProvider),
                      fontWeight: FontWeight.w500,
                      fontFamily: ref.watch(titleFontFamilyProvider).isEmpty 
                          ? null 
                          : ref.watch(titleFontFamilyProvider),
                    ),
                  )
                : Text(
                    task.title,
                    style: TextStyle(
                      color: _getTaskTitleColor(),
                      decoration: task.status == TaskStatus.completed 
                          ? TextDecoration.lineThrough 
                          : null,
                      fontSize: 16 * ref.watch(titleFontSizeProvider),
                      fontWeight: FontWeight.w500,
                      fontFamily: ref.watch(titleFontFamilyProvider).isEmpty 
                          ? null 
                          : ref.watch(titleFontFamilyProvider),
                    ),
                  ),
          ),
          const SizedBox(width: 4),
          // ピン留めトグル
          IconButton(
            icon: Icon(
              _pinnedTaskIds.contains(task.id)
                ? Icons.push_pin
                : Icons.push_pin_outlined,
              size: 18,
              color: _pinnedTaskIds.contains(task.id)
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            ),
            tooltip: _pinnedTaskIds.contains(task.id) ? 'ピンを外す' : '上部にピン留め',
            visualDensity: VisualDensity.compact,
            onPressed: () => _togglePinTask(task.id),
          ),
          if (task.isTeamTask) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'チーム',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 依頼先/メモ（テキストのみ）
          if (task.assignedTo != null) ...[
            const SizedBox(height: 4),
            _buildClickableMemoText(task.assignedTo!, task, showRelatedLinks: false),
          ],
          // 説明文を常時表示（緑色の文字部分）
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // 展開時のみ表示される詳細情報（関連資料）
          if (isExpanded) ...[
            const SizedBox(height: 8),
            if (_hasValidLinks(task)) ...[
              const SizedBox(height: 6),
              _buildRelatedLinksDisplay(_getRelatedLinks(task), onAnyLinkTap: () {
                // 詳細折りたたみ中の誤タップ防止はしない。ここは展開中のみ表示
              }),
            ],
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // リマインダーアイコン
          if (task.reminderTime != null)
            Icon(
              Icons.notifications_active,
              color: Colors.orange,
              size: 20,
            ),
          const SizedBox(width: 4),
          // サブタスク: あるときだけバッジ表示し、クリックで編集ダイアログ
          Builder(
            builder: (context) {
              print('=== 全タスクのサブタスクバッジチェック ===');
              print('タスク: ${task.title}');
              print('hasSubTasks: ${task.hasSubTasks}');
              print('totalSubTasksCount: ${task.totalSubTasksCount}');
              print('completedSubTasksCount: ${task.completedSubTasksCount}');
              print('表示条件: ${task.hasSubTasks || task.totalSubTasksCount > 0}');
              print('===============================');
              
              if (task.hasSubTasks || task.totalSubTasksCount > 0) {
                return Tooltip(
                  message: _buildSubTaskTooltipContent(task),
                  preferBelow: false,
                  verticalOffset: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  child: Container(
                    width: 65,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showSubTaskDialog(task),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: task.completedSubTasksCount == task.totalSubTasksCount 
                                    ? Colors.green.shade600 
                                    : Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (task.completedSubTasksCount == task.totalSubTasksCount 
                                        ? Colors.green.shade600 
                                        : Colors.blue.shade600).withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 60,
                                  minHeight: 32,
                                ),
                                child: Center(
                                  child: Text(
                                    '${task.completedSubTasksCount}/${task.totalSubTasksCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          // メールバッジ
          _buildMailBadges(task.id),
          const SizedBox(width: 4),
          // 関連リンクボタン
          _buildRelatedLinksButton(task),
          const SizedBox(width: 4),
          // ステータスチップ
          _buildStatusChip(task.status),
          const SizedBox(width: 8),
          // アクションメニュー
          PopupMenuButton<String>(
            onSelected: (value) => _handleTaskAction(value, task),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('編集'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('コピー', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
              if (task.status == TaskStatus.pending)
                PopupMenuItem(
                  value: 'start',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('進行中', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
              if (task.status == TaskStatus.inProgress)
                PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check),
                      SizedBox(width: 8),
                      Text('完了'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'sync_to_calendar',
                child: Row(
                  children: [
                    Icon(Icons.sync, color: Colors.green),
                    SizedBox(width: 8),
                    Text('このタスクを同期', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('削除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        // タップで編集画面を開く
        _showTaskDialog(task: task);
      },
    );
  }

  /// 期限日インジケーター（指示書に基づく改善）
  Widget _buildDeadlineIndicator(TaskItem task) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData icon;
    
    if (task.dueDate == null) {
      backgroundColor = Colors.amber.shade50;
      textColor = Colors.amber.shade900;
      borderColor = Colors.amber.shade300;
      icon = Icons.schedule;
    } else if (task.isOverdue) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade900;
      borderColor = Colors.red.shade300;
      icon = Icons.warning;
    } else if (task.isToday) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      borderColor = Colors.orange.shade300;
      icon = Icons.today;
    } else {
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade900;
      borderColor = Colors.blue.shade300;
      icon = Icons.calendar_today;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            task.dueDate != null 
              ? DateFormat('MM/dd').format(task.dueDate!)
              : '未設定',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPriorityIndicator(TaskPriority priority) {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: Color(_getPriorityColor(priority)),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  int _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 0xFF4CAF50;
      case TaskPriority.medium:
        return 0xFFFF9800;
      case TaskPriority.high:
        return 0xFFF44336;
      case TaskPriority.urgent:
        return 0xFF9C27B0;
    }
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    String text;
    IconData icon;

    switch (status) {
      case TaskStatus.pending:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        borderColor = Colors.green.shade300;
        text = '未着手';
        icon = Icons.schedule;
        break;
      case TaskStatus.inProgress:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        borderColor = Colors.blue.shade300;
        text = '進行中';
        icon = Icons.play_arrow;
        break;
      case TaskStatus.completed:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade800;
        borderColor = Colors.grey.shade300;
        text = '完了';
        icon = Icons.check;
        break;
      case TaskStatus.cancelled:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        borderColor = Colors.red.shade300;
        text = 'キャンセル';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text, 
            style: TextStyle(
              color: textColor, 
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog({TaskItem? task}) async {
    await showDialog(
      context: context,
      builder: (context) => TaskDialog(
        task: task,
        onMailSent: () {
          // メール送信後にタスクリストを更新
          setState(() {});
        },
      ),
    );
    // ダイアログを閉じた後にピン留め状態を再読み込み
    _loadPinnedTasks();
    setState(() {});
  }

  void _showSubTaskDialog(TaskItem task) {
    showDialog(
      context: context,
      builder: (context) => SubTaskDialog(
        parentTaskId: task.id,
        parentTaskTitle: task.title,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_task':
        _showTaskDialog();
        break;
      case 'bulk_select':
        _toggleSelectionMode();
        break;
      case 'export':
        _exportTasksToCsv();
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
        break;
      case 'project_overview':
        _showProjectOverview();
        break;
      case 'sort_menu':
        _showSortMenu(context);
        break;
      case 'task_template':
        _showTaskTemplate();
        break;
      case 'toggle_header':
        setState(() {
          _showHeaderSection = !_showHeaderSection;
        });
        break;
      case 'reload_tasks':
        _reloadTasks();
        break;
    }
  }

  /// タスクを再読み込み
  void _reloadTasks() async {
    print('🚨 手動タスク再読み込み開始');
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    await taskViewModel.forceReloadTasks();
    setState(() {});
    print('🚨 手動タスク再読み込み完了');
  }

  /// フィルターをリセット
  void _resetFilters() {
    print('🔄 フィルターリセット開始');
    print('リセット前: _filterStatuses=$_filterStatuses, _filterPriority=$_filterPriority, _searchQuery="$_searchQuery"');
    
    setState(() {
      _filterStatuses = {'all'};
      _filterPriority = 'all';
      _searchQuery = '';
      _searchController.clear();
    });
    
    print('リセット後: _filterStatuses=$_filterStatuses, _filterPriority=$_filterPriority, _searchQuery="$_searchQuery"');
    
    _saveFilterSettings();
    
    // スナックバーで通知
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('フィルターをリセットしました'),
        duration: Duration(seconds: 2),
      ),
    );
    
    print('🔄 フィルターリセット完了');
  }

  void _handleTaskAction(String action, TaskItem task) {
    final taskViewModel = ref.read(taskViewModelProvider.notifier);

    switch (action) {
      case 'edit':
        _showTaskDialog(task: task);
        break;
      case 'copy':
        _showCopyTaskDialog(task);
        break;
      case 'start':
        taskViewModel.startTask(task.id);
        break;
      case 'complete':
        taskViewModel.completeTask(task.id);
        break;
      case 'sync_to_calendar':
        _syncTaskToCalendar(task);
        break;
      case 'delete':
        _showDeleteConfirmation(task);
        break;
    }
  }

  /// 個別タスクをGoogle Calendarに同期
  Future<void> _syncTaskToCalendar(TaskItem task) async {
    final syncStatusNotifier = ref.read(syncStatusProvider.notifier);
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    
    try {
      syncStatusNotifier.startSync(
        message: '「${task.title}」を同期中...',
        totalItems: 1,
      );
      
      final result = await taskViewModel.syncSelectedTasksToGoogleCalendar([task.id]);
      
      if (result['success'] == true) {
        syncStatusNotifier.syncSuccess(
          message: '「${task.title}」の同期が完了しました',
        );
        SnackBarService.showSuccess(context, '「${task.title}」をGoogle Calendarに同期しました');
      } else {
        final errors = result['errors'] as List<String>?;
        final errorMessage = errors?.isNotEmpty == true ? errors!.first : '不明なエラー';
        syncStatusNotifier.syncError(
          errorMessage: errorMessage,
          message: '「${task.title}」の同期に失敗しました',
        );
        SnackBarService.showError(context, '「${task.title}」の同期に失敗しました: $errorMessage');
      }
    } catch (e) {
      syncStatusNotifier.syncError(
        errorMessage: e.toString(),
        message: '「${task.title}」の同期中にエラーが発生しました',
      );
      SnackBarService.showError(context, '「${task.title}」の同期中にエラーが発生しました: $e');
    }
  }

  void _showDeleteConfirmation(TaskItem task) {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: 'タスクを削除',
        icon: Icons.delete_outline,
        iconColor: Colors.red,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${task.title}」を削除しますか？'),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              '削除オプション:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('• アプリのみ削除'),
            const Text('• アプリとGoogle Calendarから削除'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppButtonStyles.text(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(taskViewModelProvider.notifier).deleteTask(task.id);
              Navigator.of(context).pop();
                if (mounted) {
                  SnackBarService.showSuccess(context, '「${task.title}」を削除しました');
                }
              } catch (e) {
                if (mounted) {
                  SnackBarService.showError(context, '削除に失敗しました: $e');
                }
              }
            },
            style: AppButtonStyles.warning(context),
            child: const Text('アプリのみ'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await ref.read(taskViewModelProvider.notifier).deleteTaskWithCalendarSync(task.id);
                Navigator.of(context).pop();
                if (mounted) {
                  if (result['success'] == true) {
                    final message = result['message'] ?? '「${task.title}」をアプリとGoogle Calendarから削除しました';
                    SnackBarService.showSuccess(context, message);
                    
                    // 警告メッセージがある場合は表示
                    if (result['warning'] != null) {
                      SnackBarService.showError(context, '警告: ${result['warning']}');
                    }
                  } else {
                    final error = result['error'] ?? '削除に失敗しました';
                    final errorCode = result['errorCode'];
                    
                    // 認証エラーの場合は設定画面への案内を表示
                    if (errorCode == 'AUTH_REQUIRED' || errorCode == 'TOKEN_REFRESH_FAILED') {
                      _showAuthErrorDialog(context, error);
                    } else {
                      SnackBarService.showError(context, error);
                    }
                  }
                }
              } catch (e) {
                if (mounted) {
                  SnackBarService.showError(context, '削除に失敗しました: $e');
                }
              }
            },
            style: AppButtonStyles.danger(context),
            child: const Text('両方削除'),
          ),
        ],
      ),
    );
  }


  /// 関連リンクボタンを構築
  Widget _buildRelatedLinksButton(TaskItem task) {
    // 実際に存在するリンクがあるかチェック
    final hasValidLinks = _hasValidLinks(task);
    
    print('🔗 リンクボタン表示チェック: ${task.title}');
    print('🔗 タスクID: ${task.id}');
    print('🔗 リンクID数: ${task.relatedLinkIds.length}');
    print('🔗 有効なリンク: $hasValidLinks');
    
    
    if (!hasValidLinks) {
      print('🔗 無効なリンクのため、link_offアイコンを表示');
      return IconButton(
        icon: const Icon(Icons.link_off, size: 16, color: Colors.grey),
        onPressed: () => _showLinkAssociationDialog(task),
        tooltip: 'リンクを関連付け',
      );
    }
    
    // 有効なリンク数を正確に計算（根本修正）
    int validLinkCount = 0;
    
    // 新しい形式のリンクIDをチェック（実際に存在するリンクのみ）
    for (final linkId in task.relatedLinkIds) {
      final label = _getLinkLabel(linkId);
      if (label != null) {
        validLinkCount++;
      }
    }
    
    // 古い形式のリンクもチェック（重複しないように）
    if (task.relatedLinkId != null && task.relatedLinkId!.isNotEmpty) {
      final label = _getLinkLabel(task.relatedLinkId!);
      if (label != null && !task.relatedLinkIds.contains(task.relatedLinkId)) {
        validLinkCount++;
      }
    }
    
    // リンクバッジがある場合はバッジのみ表示、ない場合はlink_offアイコン表示
    if (validLinkCount > 0) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showLinkAssociationDialog(task),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.shade600.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 24,
                    ),
                    child: Text(
                      '$validLinkCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // リンクがない場合はlink_offアイコンを表示
      return IconButton(
        icon: const Icon(Icons.link_off, size: 16, color: Colors.grey),
        onPressed: () => _showLinkAssociationDialog(task),
        tooltip: 'リンクを関連付け',
      );
    }
  }
  
  /// リンクのラベルを取得
  String? _getLinkLabel(String linkId) {
    final groups = ref.read(linkViewModelProvider);
    print('🔗 _getLinkLabel 検索開始: $linkId');
    print('🔗 利用可能なグループ数: ${groups.groups.length}');
    
    for (final group in groups.groups) {
      print('🔗 グループ "${group.title}" のアイテム数: ${group.items.length}');
      for (final link in group.items) {
        if (link.id == linkId) {
          print('🔗 リンクが見つかりました: ${link.label}');
          return link.label;
        }
      }
    }
    print('🔗 リンクが見つかりませんでした: $linkId');
    return null;
  }

  /// タスクに有効なリンクがあるかチェック
  bool _hasValidLinks(TaskItem task) {
    print('🔗 _hasValidLinks チェック: ${task.title}');
    print('🔗 古い形式のリンクID: ${task.relatedLinkId}');
    print('🔗 新しい形式のリンクID: ${task.relatedLinkIds}');
    
    // 新しい形式のリンクIDをチェック（優先）
    for (final linkId in task.relatedLinkIds) {
      final label = _getLinkLabel(linkId);
      print('🔗 リンクID $linkId のラベル: $label');
      if (label != null) {
        print('🔗 有効なリンクが見つかりました');
        return true;
      }
    }
    
    // 古い形式のリンクIDをチェック（フォールバック）
    if (task.relatedLinkId != null && task.relatedLinkId!.isNotEmpty) {
      final label = _getLinkLabel(task.relatedLinkId!);
      print('🔗 古い形式のリンクラベル: $label');
      if (label != null) {
        print('🔗 古い形式で有効なリンクが見つかりました');
        return true;
      }
    }
    
    print('🔗 有効なリンクが見つかりませんでした');
    return false;
  }
  
  /// リンクアクションを処理
  void _handleLinkAction(String action, TaskItem task) {
    if (action.startsWith('open_')) {
      final linkId = action.substring(5); // 'open_' を除去
      _openSpecificLink(task, linkId);
    } else if (action == 'manage_links') {
      _showLinkAssociationDialog(task);
    }
  }
  
  /// 特定のリンクを開く
  void _openSpecificLink(TaskItem task, String linkId) {
    final linkViewModel = ref.read(linkViewModelProvider.notifier);
    final groups = ref.read(linkViewModelProvider);
    
    // リンクを検索
    LinkItem? targetLink;
    for (final group in groups.groups) {
      targetLink = group.items.firstWhere(
        (link) => link.id == linkId,
        orElse: () => LinkItem(
          id: '',
          label: '',
          path: '',
          type: LinkType.url,
          createdAt: DateTime.now(),
        ),
      );
      if (targetLink.id.isNotEmpty) break;
    }

    if (targetLink != null && targetLink.id.isNotEmpty) {
      // リンクを開く
      linkViewModel.launchLink(targetLink);
      
      // 成功メッセージを表示
      SnackBarService.showSuccess(
        context,
        'リンク「${targetLink.label}」を開きました',
      );
    } else {
      // エラーメッセージを表示
      SnackBarService.showError(
        context,
        'リンクが見つかりません',
      );
    }
  }

  /// リンク関連付けダイアログを表示
  void _showLinkAssociationDialog(TaskItem task) {
    // 最新のタスクデータを取得
    final tasks = ref.read(taskViewModelProvider);
    final currentTask = tasks.firstWhere(
      (t) => t.id == task.id,
      orElse: () => task,
    );
    
    showDialog(
      context: context,
      builder: (context) => LinkAssociationDialog(
        task: currentTask,
        onLinksUpdated: () {
          // ref.watch(taskViewModelProvider)で監視しているため、自動的に再ビルドされる
          // ただし、念のため明示的にsetStateを呼ぶ
          setState(() {});
        },
      ),
    );
  }

  // 通知テストメソッド
  void _showTestNotification() async {
    try {
      // Windows環境ではWindows固有の通知サービスを使用
      if (Platform.isWindows) {
        await WindowsNotificationService.showTestNotification();
      } else {
        // その他のプラットフォームではアプリ内通知を使用
        NotificationService.showInAppNotification(
          context,
          'テスト通知',
          '通知機能が正常に動作しています',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      NotificationService.showInAppNotification(
        context,
        '通知エラー',
        '通知の送信に失敗しました: $e',
        backgroundColor: Colors.orange,
      );
    }
  }

  // リマインダーテストメソッド
  void _showTestReminderNotification() async {
    try {
      // Windows環境ではWindows固有の通知サービスを使用
      if (Platform.isWindows) {
        await WindowsNotificationService.showTestReminderNotification();
      } else {
        // その他のプラットフォームではアプリ内通知を使用
        NotificationService.showInAppNotification(
          context,
          'リマインダーテスト',
          'リマインダー通知が正常に動作しています',
          backgroundColor: Colors.blue,
        );
      }
    } catch (e) {
      NotificationService.showInAppNotification(
        context,
        'リマインダーテストエラー',
        'リマインダーテストに失敗しました: $e',
        backgroundColor: Colors.orange,
      );
    }
  }

  // 1分後リマインダーテストメソッド
  void _showTestReminderInOneMinute() async {
    try {
      // Windows環境ではWindows固有の通知サービスを使用
      if (Platform.isWindows) {
        await WindowsNotificationService.showTestReminderInOneMinute();
        
        // 成功メッセージを表示
        NotificationService.showInAppNotification(
          context,
          '1分後リマインダー設定',
          '1分後にリマインダーが表示されます。アプリを閉じている場合は通知が表示されません。',
          backgroundColor: Colors.green,
        );
      } else {
        // その他のプラットフォームではアプリ内通知を使用
        NotificationService.showInAppNotification(
          context,
          '1分後リマインダーテスト',
          '1分後にリマインダーが表示されます',
          backgroundColor: Colors.blue,
        );
      }
    } catch (e) {
      NotificationService.showInAppNotification(
        context,
        '1分後リマインダーテストエラー',
        '1分後リマインダーテストに失敗しました: $e',
        backgroundColor: Colors.orange,
      );
    }
  }


  
  // フィルタリング処理を別メソッドに分離
  List<TaskItem> _getFilteredTasks(List<TaskItem> tasks) {
    print('=== フィルタリング開始 ===');
    print('全タスク数: ${tasks.length}');
    print('フィルター状態: $_filterStatuses');
    print('優先度フィルター: $_filterPriority');
    print('検索クエリ: "$_searchQuery"');
    
    final filteredTasks = tasks.where((task) {
      // ステータスフィルター（複数選択対応）
      if (!_filterStatuses.contains('all')) {
        bool statusMatch = false;
        if (_filterStatuses.contains('pending') && task.status == TaskStatus.pending) {
          statusMatch = true;
        }
        if (_filterStatuses.contains('inProgress') && task.status == TaskStatus.inProgress) {
          statusMatch = true;
        }
        if (_filterStatuses.contains('completed') && task.status == TaskStatus.completed) {
          statusMatch = true;
        }
        if (_filterStatuses.contains('cancelled') && task.status == TaskStatus.cancelled) {
          statusMatch = true;
        }
        if (!statusMatch) return false;
      }

      // 優先度フィルター
      if (_filterPriority != 'all') {
        TaskPriority? priority;
        switch (_filterPriority) {
          case 'low':
            priority = TaskPriority.low;
            break;
          case 'medium':
            priority = TaskPriority.medium;
            break;
          case 'high':
            priority = TaskPriority.high;
            break;
          case 'urgent':
            priority = TaskPriority.urgent;
            break;
        }
        if (task.priority != priority) return false;
      }

      // 強化された検索フィルター
      if (_searchQuery.isNotEmpty) {
        if (!_matchesSearchQuery(task, _searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();

    print('フィルタリング後タスク数: ${filteredTasks.length}');
    print('=== フィルタリング完了 ===');

                    // 選択された並び替え方法に基づいてソート（第3順位まで対応）
          filteredTasks.sort((a, b) {
            for (int i = 0; i < _sortOrders.length; i++) {
              final sortConfig = _sortOrders[i];
              final sortField = sortConfig['field']!;
              final sortOrder = sortConfig['order']!;
              int comparison = 0;
              
              switch (sortField) {
                case 'dueDate':
                  comparison = _compareDueDate(a.dueDate, b.dueDate);
                  break;
                case 'priority':
                  comparison = _comparePriority(a.priority, b.priority);
                  break;
                case 'title':
                  comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
                  break;
                case 'createdAt':
                  comparison = b.createdAt.compareTo(a.createdAt);
                  break;
                case 'status':
                  final statusOrder = {
                    TaskStatus.pending: 1,
                    TaskStatus.inProgress: 2,
                    TaskStatus.completed: 3,
                  };
                  comparison = (statusOrder[a.status] ?? 0).compareTo(statusOrder[b.status] ?? 0);
                  break;
                default:
                  comparison = 0;
              }
              
              // 降順の場合は比較結果を反転
              if (sortOrder == 'desc') {
                comparison = -comparison;
              }
              
              if (comparison != 0) {
                return comparison;
              }
            }
            
            // すべての並び替え条件が同じ場合は期限順で決定
            return _compareDueDate(a.dueDate, b.dueDate);
          });

      return filteredTasks;
  }

  // 優先度の比較（緊急度高い順）
  int _comparePriority(TaskPriority a, TaskPriority b) {
    final priorityOrder = {
      TaskPriority.urgent: 4,
      TaskPriority.high: 3,
      TaskPriority.medium: 2,
      TaskPriority.low: 1,
    };
    
    return (priorityOrder[b] ?? 0).compareTo(priorityOrder[a] ?? 0);
  }

  // 期限の比較（期限なしは最後）
  int _compareDueDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return 0;
    } else if (a == null) {
      return 1; // aの期限なしは後ろ
    } else if (b == null) {
      return -1; // bの期限なしは後ろ
    } else {
      return a.compareTo(b); // 期限昇順
    }
  }

  // CSV出力処理
  void _exportTasksToCsv() async {
    try {
      final tasks = ref.read(taskViewModelProvider);
      final subTasks = ref.read(subTaskViewModelProvider);
      
      // ファイルダイアログで保存場所を選択
      final now = DateTime.now();
      final formatted = DateFormat('yyMMdd_HHmm').format(now);
      final defaultFileName = 'tasks_export_$formatted.csv';
      
      // デスクトップをデフォルトの保存場所に設定
      final desktopPath = '${Platform.environment['USERPROFILE']}\\Desktop';
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'CSVファイルの保存場所を選択',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        initialDirectory: desktopPath,
      );
      
      if (outputFile == null) {
        // ユーザーがキャンセルした場合
        return;
      }
      
      // OneDriveの問題を回避するため、一時ディレクトリで作成してから移動
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_$defaultFileName');
      
      try {
        // 一時ファイルにCSVを出力
        await CsvExport.exportTasksToCsv(tasks, subTasks, tempFile.path);
        
        // 一時ファイルを目的の場所に移動
        final targetFile = File(outputFile);
        await tempFile.copy(targetFile.path);
        
        // 一時ファイルを削除
        await tempFile.delete();
        
        // 成功メッセージを表示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CSV出力が完了しました: ${targetFile.path.split(Platform.pathSeparator).last}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (copyError) {
        // コピーに失敗した場合、一時ファイルを削除
        try {
          await tempFile.delete();
        } catch (_) {}
        rethrow;
      }
    } catch (e) {
      print('CSV出力エラーの詳細: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV出力エラー: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // キーボードショートカット処理（ショートカット専用）
  bool _handleKeyEventShortcut(KeyDownEvent event, bool isControlPressed, bool isShiftPressed) {
    // モーダルが開いている場合はショートカットを無効化
    final isModalOpen = ModalRoute.of(context)?.isFirst != true;
    if (isModalOpen) {
      print('⏸️ モーダルが開いているため、ショートカットをスキップ');
      return false;
    }
    
    // TextField編集中は一部のショートカットのみ有効
    final focused = FocusManager.instance.primaryFocus;
    final isEditing = focused?.context?.widget is EditableText;
    
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      print('✅ ← 検出: ホーム画面に戻る');
      _navigateToHome(context);
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      print('✅ → 検出: 3点ドットメニューにフォーカス');
      _appBarMenuFocusNode.requestFocus();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      print('✅ ↓ 検出: 3点ドットメニューにフォーカス');
      _appBarMenuFocusNode.requestFocus();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyN && isControlPressed && !isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+N 検出: 新しいタスク作成');
      _showTaskDialog();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyB && isControlPressed && !isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+B 検出: 一括選択モード');
      _toggleSelectionMode();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyE && isControlPressed && isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+Shift+E 検出: CSV出力');
      _exportTasksToCsv();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyS && isControlPressed && isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+Shift+S 検出: 設定画面');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyP && isControlPressed && !isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+P 検出: プロジェクト一覧');
      _showProjectOverview();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyO && isControlPressed && !isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+O 検出: 並び替え');
      _showSortMenu(context);
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyT && isControlPressed && isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+Shift+T 検出: テンプレートから作成');
      _showTaskTemplate();
      return true;
    }
    return false;
  }

  // キーボードショートカット処理（後方互換性のため残す）
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      _handleKeyEventShortcut(event, isControlPressed, isShiftPressed);
    }
  }

  /// ショートカットヘルプダイアログを表示
  void _showShortcutHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: 'キーボードショートカット',
        icon: Icons.keyboard,
        iconColor: Colors.blue,
        width: 400,
        height: 500,
        content: SizedBox(
          width: 400,
          height: 400,
          child: ListView(
            children: [
              _TaskShortcutItem('Ctrl+N', '新しいタスク'),
              _TaskShortcutItem('Ctrl+B', '一括選択モード'),
              _TaskShortcutItem('Ctrl+Shift+E', 'CSV出力'),
              _TaskShortcutItem('Ctrl+Shift+S', '設定'),
              const Divider(),
              _TaskShortcutItem('Ctrl+P', 'プロジェクト一覧'),
              _TaskShortcutItem('Ctrl+O', '並び替え'),
              _TaskShortcutItem('Ctrl+Shift+T', 'テンプレートから作成'),
              const Divider(),
              _TaskShortcutItem('←', 'ホーム画面に戻る'),
              _TaskShortcutItem('→', '3点ドットメニュー'),
              _TaskShortcutItem('Ctrl+H', '統計・検索バー表示/非表示'),
              _TaskShortcutItem('F1', 'ショートカットキー'),
              const Divider(),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: AppButtonStyles.primary(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  // 3点ドットメニューを表示
  void _showPopupMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        // 新しいタスク作成
        const PopupMenuItem(
          value: 'add_task',
          child: Row(
            children: [
              Icon(Icons.add, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('新しいタスク'),
            ],
          ),
        ),
        // 一括選択モード
        const PopupMenuItem(
          value: 'bulk_select',
          child: Row(
            children: [
              Icon(Icons.checklist, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('一括選択モード'),
            ],
          ),
        ),
        // CSVエクスポート
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.download, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text('CSVエクスポート'),
            ],
          ),
        ),
        // テスト通知
        const PopupMenuItem(
          value: 'test_notification',
          child: Row(
            children: [
              Icon(Icons.notifications, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('テスト通知'),
            ],
          ),
        ),
        // テストリマインダー
        const PopupMenuItem(
          value: 'test_reminder',
          child: Row(
            children: [
              Icon(Icons.alarm, color: Colors.teal, size: 20),
              SizedBox(width: 8),
              Text('テストリマインダー'),
            ],
          ),
        ),
        // 1分後リマインダー
        const PopupMenuItem(
          value: 'test_reminder_1min',
          child: Row(
            children: [
              Icon(Icons.timer, color: Colors.indigo, size: 20),
              SizedBox(width: 8),
              Text('1分後リマインダー'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleMenuAction(value);
      }
    });
  }

  // タスクコピーダイアログを表示
  void _showCopyTaskDialog(TaskItem task) {
    showDialog(
      context: context,
      builder: (context) => CopyTaskDialog(task: task),
    );
  }

  /// サブタスクのツールチップ内容を構築
  String _buildSubTaskTooltipContent(TaskItem task) {
    if (!task.hasSubTasks && task.totalSubTasksCount == 0) {
      return '';
    }

    // サブタスクの詳細を取得
    final subTasks = _getSubTasksForTask(task.id);
    if (subTasks.isEmpty) {
      return 'サブタスク: ${task.totalSubTasksCount}個\n完了: ${task.completedSubTasksCount}個';
    }

    final buffer = StringBuffer();
    buffer.writeln('サブタスク: ${task.totalSubTasksCount}個');
    buffer.writeln('完了: ${task.completedSubTasksCount}個');
    buffer.writeln('');
    
    for (int i = 0; i < subTasks.length && i < 10; i++) {
      final subTask = subTasks[i];
      final status = subTask.isCompleted ? '✓' : '×';
      final title = subTask.title.length > 20 
        ? '${subTask.title.substring(0, 20)}...' 
        : subTask.title;
      buffer.writeln('$status $title');
    }
    
    if (subTasks.length > 10) {
      buffer.writeln('... 他${subTasks.length - 10}個');
    }
    
    return buffer.toString().trim();
  }

  /// タスクのサブタスクを取得
  List<SubTask> _getSubTasksForTask(String taskId) {
    try {
      // SubTaskViewModelから取得
      final subTaskViewModel = ref.read(subTaskViewModelProvider.notifier);
      final subTasks = subTaskViewModel.getSubTasksByParentId(taskId);
      
      // 並び順でソート
      subTasks.sort((a, b) => a.order.compareTo(b.order));
      
      return subTasks;
    } catch (e) {
      print('サブタスク取得エラー: $e');
      return [];
    }
  }

  /// プロジェクト一覧を表示
  void _showProjectOverview() {
    showDialog(
      context: context,
      builder: (context) => _ProjectOverviewDialog(),
    );
  }

  /// タスクテンプレートダイアログを表示
  void _showTaskTemplate() {
    showDialog(
      context: context,
      builder: (context) => const TaskTemplateDialog(),
    );
  }

  /// 並び替えメニューを表示
  void _showSortMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        PopupMenuItem(
          value: 'dueDate',
          child: Row(
            children: [
              Icon(Icons.schedule, size: 16),
              const SizedBox(width: 8),
              const Text('期限日'),
              if (_sortBy == 'dueDate') ...[
                const Spacer(),
                Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'priority',
          child: Row(
            children: [
              Icon(Icons.priority_high, size: 16),
              const SizedBox(width: 8),
              const Text('優先度'),
              if (_sortBy == 'priority') ...[
                const Spacer(),
                Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'created',
          child: Row(
            children: [
              Icon(Icons.access_time, size: 16),
              const SizedBox(width: 8),
              const Text('作成日'),
              if (_sortBy == 'created') ...[
                const Spacer(),
                Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'title',
          child: Row(
            children: [
              Icon(Icons.title, size: 16),
              const SizedBox(width: 8),
              const Text('タイトル'),
              if (_sortBy == 'title') ...[
                const Spacer(),
                Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 16),
              const SizedBox(width: 8),
              const Text('ステータス'),
              if (_sortBy == 'status') ...[
                const Spacer(),
                Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
              ],
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          if (value == _sortBy) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = true;
          }
        });
      }
    });
  }

  /// タスクの期限日に応じたカード色を取得
  Color _getTaskCardColor(TaskItem task) {
    if (task.dueDate == null) {
      return Theme.of(context).colorScheme.surface;
    }

    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      // 期限切れ
      return Colors.red.shade50;
    } else if (difference == 0) {
      // 今日が期限
      return Colors.orange.shade50;
    } else if (difference <= 3) {
      // 3日以内
      return Colors.amber.shade50;
    } else if (difference <= 7) {
      // 1週間以内
      return Colors.yellow.shade50;
    } else {
      // それ以外
      return Theme.of(context).colorScheme.surface;
    }
  }

  /// タスクの期限日に応じたボーダー色を取得
  Color _getTaskBorderColor(TaskItem task) {
    if (task.dueDate == null) {
      return Theme.of(context).colorScheme.outline.withValues(alpha: 0.4);
    }

    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      // 期限切れ
      return Colors.red.shade300;
    } else if (difference == 0) {
      // 今日が期限
      return Colors.orange.shade300;
    } else if (difference <= 3) {
      // 3日以内
      return Colors.amber.shade300;
    } else if (difference <= 7) {
      // 1週間以内
      return Colors.yellow.shade300;
    } else {
      // それ以外
      return Theme.of(context).colorScheme.outline.withValues(alpha: 0.4);
    }
  }

  /// 検索履歴を読み込み
  void _loadSearchHistory() async {
    try {
      final box = Hive.box('searchHistory');
      final history = box.get('taskSearchHistory', defaultValue: <String>[]);
      _searchHistory = List<String>.from(history);
    } catch (e) {
      print('検索履歴読み込みエラー: $e');
      _searchHistory = [];
    }
  }

  /// 検索履歴を保存
  void _saveSearchHistory() async {
    try {
      final box = Hive.box('searchHistory');
      box.put('taskSearchHistory', _searchHistory);
    } catch (e) {
      print('検索履歴保存エラー: $e');
    }
  }

  /// 検索履歴に追加
  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;
    
    // 既存の履歴から同じクエリを削除
    _searchHistory.remove(query.trim());
    
    // 先頭に追加
    _searchHistory.insert(0, query.trim());
    
    // 最大20件まで保持
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.take(20).toList();
    }
    
    _saveSearchHistory();
  }

  /// 検索履歴をクリア
  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
    _saveSearchHistory();
  }

  /// 強化された検索クエリマッチング
  bool _matchesSearchQuery(TaskItem task, String query) {
    if (query.trim().isEmpty) return true;
    
    try {
      if (_useRegex) {
        // 正規表現検索
        final regex = RegExp(query, caseSensitive: false);
        return _matchesRegexInTask(task, regex);
      } else {
        // 通常の検索
        final queryLower = query.toLowerCase();
        return _matchesTextInTask(task, queryLower);
      }
    } catch (e) {
      // 正規表現エラーの場合は通常検索にフォールバック
      print('正規表現エラー: $e');
      final queryLower = query.toLowerCase();
      return _matchesTextInTask(task, queryLower);
    }
  }

  /// 正規表現での検索
  bool _matchesRegexInTask(TaskItem task, RegExp regex) {
    // タイトル検索（常に有効）
    if (regex.hasMatch(task.title)) return true;
    
    // 説明文検索
    if (_searchInDescription && task.description != null && regex.hasMatch(task.description!)) {
      return true;
    }
    
    // タグ検索
    if (_searchInTags && task.tags.isNotEmpty) {
      for (final tag in task.tags) {
        if (regex.hasMatch(tag)) return true;
      }
    }
    
    // 依頼先検索
    if (_searchInRequester && task.assignedTo != null && regex.hasMatch(task.assignedTo!)) {
      return true;
    }
    
    // メモ検索
    if (task.notes != null && regex.hasMatch(task.notes!)) {
      return true;
    }
    
    return false;
  }

  /// 通常のテキスト検索
  bool _matchesTextInTask(TaskItem task, String queryLower) {
    // タイトル検索（常に有効）
    if (task.title.toLowerCase().contains(queryLower)) return true;
    
    // 説明文検索
    if (_searchInDescription && task.description != null && 
        task.description!.toLowerCase().contains(queryLower)) {
      return true;
    }
    
    // タグ検索
    if (_searchInTags && task.tags.isNotEmpty) {
      for (final tag in task.tags) {
        if (tag.toLowerCase().contains(queryLower)) return true;
      }
    }
    
    // 依頼先検索
    if (_searchInRequester && task.assignedTo != null && 
        task.assignedTo!.toLowerCase().contains(queryLower)) {
      return true;
    }
    
    // メモ検索
    if (task.notes != null && task.notes!.toLowerCase().contains(queryLower)) {
      return true;
    }
    
    return false;
  }

  /// 検索オプションセクションを構築
  Widget _buildSearchOptionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              Icon(
                Icons.tune,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '検索オプション',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _showSearchOptions = false;
                  });
                },
                tooltip: '閉じる',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('説明文', style: TextStyle(fontSize: 14)),
                  value: _searchInDescription,
                  onChanged: (value) {
                    setState(() {
                      _searchInDescription = value ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('タグ', style: TextStyle(fontSize: 14)),
                  value: _searchInTags,
                  onChanged: (value) {
                    setState(() {
                      _searchInTags = value ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('依頼先', style: TextStyle(fontSize: 14)),
                  value: _searchInRequester,
                  onChanged: (value) {
                    setState(() {
                      _searchInRequester = value ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _useRegex ? Icons.code : Icons.text_fields,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _useRegex ? '正規表現検索モード' : '通常検索モード',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_searchHistory.isNotEmpty) ...[
                TextButton.icon(
                  onPressed: _showSearchHistory,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('履歴'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clearSearchHistory,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('履歴クリア'),
                ),
              ],
            ],
          ),
          if (_useRegex) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '正規表現の使い方',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRegexExamples(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 正規表現の例を表示
  Widget _buildRegexExamples() {
    final examples = [
      {'pattern': r'^プロジェクト', 'description': '「プロジェクト」で始まるタスク'},
      {'pattern': r'完了$', 'description': '「完了」で終わるタスク'},
      {'pattern': r'^プロジェクト.*完了$', 'description': '「プロジェクト」で始まり「完了」で終わるタスク'},
      {'pattern': r'緊急|重要', 'description': '「緊急」または「重要」を含むタスク'},
      {'pattern': r'\d{4}-\d{2}-\d{2}', 'description': '日付形式（YYYY-MM-DD）を含むタスク'},
      {'pattern': r'[A-Z]{2,}', 'description': '2文字以上の大文字を含むタスク'},
      {'pattern': r'^.{1,10}$', 'description': '1〜10文字のタスクタイトル'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'よく使うパターン:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        ...examples.map((example) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    example['pattern']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: example['pattern']!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('「${example['pattern']}」をコピーしました'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'パターンをコピー',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  example['description']!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber,
                size: 14,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '正規表現が無効な場合は自動的に通常検索に切り替わります',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 検索履歴を表示
  void _showSearchHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history),
            SizedBox(width: 8),
            Text('検索履歴'),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: _searchHistory.isEmpty
            ? const Center(
                child: Text('検索履歴がありません'),
              )
            : ListView.builder(
                itemCount: _searchHistory.length,
                itemBuilder: (context, index) {
                  final query = _searchHistory[index];
                  return ListTile(
                    leading: const Icon(Icons.search, size: 20),
                    title: Text(query),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchHistory.removeAt(index);
                        });
                        _saveSearchHistory();
                      },
                    ),
                    onTap: () {
                      _searchController.text = query;
                      setState(() {
                        _searchQuery = query;
                        _userTypedSearch = true;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          if (_searchHistory.isNotEmpty)
            TextButton(
              onPressed: () {
                _clearSearchHistory();
                Navigator.of(context).pop();
              },
              child: const Text('履歴をクリア'),
            ),
        ],
      ),
    );
  }

  /// タスクを並び替える
  List<TaskItem> _sortTasks(List<TaskItem> tasks) {
    final sortedTasks = List<TaskItem>.from(tasks);
    
    sortedTasks.sort((a, b) {
      // ピン留めは最優先で上に
      final aPinned = _pinnedTaskIds.contains(a.id);
      final bPinned = _pinnedTaskIds.contains(b.id);
      if (aPinned != bPinned) {
        return aPinned ? -1 : 1;
      }
      int comparison = 0;
      
      switch (_sortBy) {
        case 'dueDate':
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          comparison = a.dueDate!.compareTo(b.dueDate!);
          break;
        case 'priority':
          comparison = a.priority.index.compareTo(b.priority.index);
          break;
        case 'created':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'status':
          comparison = a.status.index.compareTo(b.status.index);
          break;
        default:
          return 0;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return sortedTasks;
  }

  /// ピン留めタスク固定 + 通常タスクスクロール表示を構築
  Widget _buildPinnedAndScrollableTaskList(List<TaskItem> sortedTasks) {
    // ピン留めタスクと通常タスクを分離
    final pinnedTasks = sortedTasks.where((task) => _pinnedTaskIds.contains(task.id)).toList();
    final unpinnedTasks = sortedTasks.where((task) => !_pinnedTaskIds.contains(task.id)).toList();
    
    // ピン留めタスクがある場合は固定 + スクロール表示
    if (pinnedTasks.isNotEmpty) {
      return Column(
        children: [
          // ピン留めタスク（固定表示）
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: pinnedTasks.map((task) => _buildTaskCard(task)).toList(),
            ),
          ),
          // 通常タスク（スクロール可能）
          Expanded(
            child: unpinnedTasks.isEmpty
                ? const Center(child: Text('その他のタスクはありません'))
                : ListView.builder(
                    itemCount: unpinnedTasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(unpinnedTasks[index]);
                    },
                  ),
          ),
        ],
      );
    }
    
    // ピン留めタスクがない場合は通常のリスト表示
    return ListView.builder(
      itemCount: unpinnedTasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(unpinnedTasks[index]);
      },
    );
  }

  /// メールバッジを構築
  Widget _buildMailBadges(String taskId) {
    print('=== _buildMailBadges呼び出し ===');
    print('taskId: $taskId');
    print('===============================');
    
    return Consumer(
      builder: (context, ref, child) {
        print('=== メールバッジConsumer開始 ===');
        print('taskId: $taskId');
        
        try {
          // タスクの状態が変更されたときに強制的に再構築するためのキー
          final taskState = ref.watch(taskViewModelProvider);
          print('taskState.length: ${taskState.length}');
          
          final task = taskState.firstWhere((t) => t.id == taskId);
          print('タスクが見つかりました: ${task.title}');
          
          return FutureBuilder<List<SentMailLog>>(
            key: ValueKey('mail_badges_${taskId}_${task.createdAt.millisecondsSinceEpoch}'), // より動的なキー
            future: _getMailLogsForTask(taskId),
            builder: (context, snapshot) {
              print('=== メールバッジFutureBuilder ===');
              print('taskId: $taskId');
              print('snapshot.hasData: ${snapshot.hasData}');
              print('snapshot.data?.length: ${snapshot.data?.length}');
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                print('メールログ詳細:');
                for (final log in snapshot.data!) {
                  print('  - ${log.subject} (${log.composedAt})');
                }
              }
              print('===============================');
              
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: MailBadgeList(
                    logs: snapshot.data!,
                    onLogTap: _openSentSearch,
                  ),
                );
              }
              // メールログがない場合は何も表示しない
              return const SizedBox.shrink();
            },
          );
        } catch (e) {
          print('メールバッジエラー: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  /// タスクのメールログを取得
  Future<List<SentMailLog>> _getMailLogsForTask(String taskId) async {
    try {
      final mailService = MailService();
      await mailService.initialize();
      final logs = mailService.getMailLogsForTask(taskId);
      
      if (kDebugMode) {
        print('タスクID $taskId のメールログ取得: ${logs.length}件');
        for (final log in logs) {
          print('  - ${log.app}: ${log.token} (${log.composedAt})');
        }
      }
      
      return logs;
    } catch (e) {
      if (kDebugMode) {
        print('メールログ取得エラー: $e');
      }
      return [];
    }
  }

  /// 送信済み検索を開く
  Future<void> _openSentSearch(SentMailLog log) async {
    try {
      final mailService = MailService();
      await mailService.initialize();
      await mailService.openSentSearch(log);
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, '送信済み検索エラー: $e');
      }
    }
  }

  /// 認証エラーダイアログを表示
  void _showAuthErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: 'Google Calendar認証エラー',
        icon: Icons.error_outline,
        iconColor: Colors.red,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Google Calendarとの同期を行うには、設定画面でGoogle Calendarの認証を行う必要があります。',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppButtonStyles.text(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 設定画面に遷移
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            style: AppButtonStyles.primary(context),
            child: const Text('設定画面へ'),
          ),
        ],
      ),
    );
  }

  // 優先度のテキストを取得
  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '緊急';
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '未着手';
      case TaskStatus.inProgress:
        return '進行中';
      case TaskStatus.completed:
        return '完了';
      case TaskStatus.cancelled:
        return 'キャンセル';
    }
  }
  
  /// 自動生成タスクかどうかを判定
  bool _isAutoGeneratedTask(TaskItem task) {
    return task.tags.contains('Gmail自動生成') || 
           task.tags.contains('Outlook自動生成') ||
           task.id.startsWith('gmail_') ||
           task.id.startsWith('outlook_');
  }
  
  /// メールバッジを構築
  Widget _buildEmailBadge(TaskItem task) {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: () => _showEmailActions(task),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.email,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                'メール',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// メールアクションダイアログを表示
  void _showEmailActions(TaskItem task) {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: 'メールアクション',
        icon: Icons.email,
        iconColor: Colors.blue,
        content: const Text('このタスクに関連するメールアクションを選択してください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppButtonStyles.text(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _replyToEmail(task);
            },
            style: AppButtonStyles.primary(context),
            child: const Text('返信'),
          ),
        ],
      ),
    );
  }
  
  /// メールに返信
  void _replyToEmail(TaskItem task) {
    try {
      // タスクの説明から返信先メールアドレスを抽出
      final description = task.description ?? '';
      
      // 複数のパターンで返信先を検索
      String? replyToEmail;
      
      // パターン1: 💬 返信先: email@example.com
      final replyRegex = RegExp(r'💬 返信先: ([^\s\n]+)');
      final replyMatch = replyRegex.firstMatch(description);
      if (replyMatch != null && replyMatch.group(1) != null) {
        replyToEmail = replyMatch.group(1)!;
      }
      
      // パターン2: 送信者情報から抽出 (📧 送信者: Name (email@example.com))
      if (replyToEmail == null) {
        final senderRegex = RegExp(r'📧 送信者: [^(]+ \(([^)]+)\)');
        final senderMatch = senderRegex.firstMatch(description);
        if (senderMatch != null && senderMatch.group(1) != null) {
          replyToEmail = senderMatch.group(1)!;
        }
      }
      
      // パターン3: 一般的なメールアドレスパターン
      if (replyToEmail == null) {
        final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
        final emailMatch = emailRegex.firstMatch(description);
        if (emailMatch != null) {
          replyToEmail = emailMatch.group(0);
        }
      }
      
      if (replyToEmail != null && replyToEmail.isNotEmpty) {
        final subject = 'Re: ${task.title}';
        final body = 'タスク「${task.title}」について返信します。\n\n';
        
        // デフォルトメーラーを起動
        final mailtoUrl = 'mailto:$replyToEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
        Process.run('cmd', ['/c', 'start', mailtoUrl]);
        
        SnackBarService.showSuccess(context, 'メーラーを起動しました');
      } else {
        SnackBarService.showError(context, '返信先メールアドレスが見つかりません');
      }
    } catch (e) {
      SnackBarService.showError(context, 'メーラーの起動に失敗しました: $e');
    }
  }

  /// クリック可能なメモテキストを構築
  Widget _buildClickableMemoText(String memoText, TaskItem task, {bool showRelatedLinks = true}) {
    // タスクの関連リンクを取得
    final relatedLinks = _getRelatedLinks(task);
    
    // メモテキスト内のリンクパターンを検出
    final linkPattern = RegExp(r'(\\\\[^\s]+|https?://[^\s]+|file://[^\s]+|C:\\[^\s]+)');
    final matches = linkPattern.allMatches(memoText);
    
    // メモテキストと関連リンクの両方にリンクがある場合
    if (matches.isNotEmpty || (showRelatedLinks && relatedLinks.isNotEmpty)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // メモテキストの表示
          if (memoText.isNotEmpty)
            RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: matches.isNotEmpty 
                    ? _buildTextSpans(memoText, matches)
                    : [TextSpan(text: memoText)],
                style: TextStyle(
                  color: Color(ref.watch(memoTextColorProvider)),
                  fontSize: 13 * ref.watch(memoFontSizeProvider),
                  fontWeight: FontWeight.w700,
                  fontFamily: ref.watch(memoFontFamilyProvider).isEmpty 
                      ? null 
                      : ref.watch(memoFontFamilyProvider),
                ),
              ),
            ),
          
          // 関連リンクの表示
          if (showRelatedLinks && relatedLinks.isNotEmpty) ...[
            if (memoText.isNotEmpty) const SizedBox(height: 4),
            _buildRelatedLinksDisplay(relatedLinks),
          ],
        ],
      );
    }
    
    // リンクがない場合は通常のテキスト表示
    return HighlightedText(
      text: memoText,
      highlight: (_userTypedSearch && _searchQuery.isNotEmpty) ? _searchQuery : null,
      style: TextStyle(
        color: Color(ref.watch(memoTextColorProvider)),
        fontSize: 13 * ref.watch(memoFontSizeProvider),
        fontWeight: FontWeight.w700,
        fontFamily: ref.watch(memoFontFamilyProvider).isEmpty 
            ? null 
            : ref.watch(memoFontFamilyProvider),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// テキストスパンを構築（リンク部分をクリック可能にする）
  List<TextSpan> _buildTextSpans(String text, Iterable<RegExpMatch> matches) {
    final spans = <TextSpan>[];
    int lastEnd = 0;
    
    for (final match in matches) {
      // リンク前のテキスト
      if (match.start > lastEnd) {
        final beforeText = text.substring(lastEnd, match.start);
        spans.add(TextSpan(text: beforeText));
      }
      
      // リンク部分
      final linkText = match.group(0)!;
      spans.add(TextSpan(
        text: linkText,
        style: TextStyle(
          color: Colors.blue[800],
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue[800],
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _handleLinkTap(linkText),
      ));
      
      lastEnd = match.end;
    }
    
    // 最後のテキスト
    if (lastEnd < text.length) {
      final afterText = text.substring(lastEnd);
      spans.add(TextSpan(text: afterText));
    }
    
    return spans;
  }

  /// リンクタップを処理
  void _handleLinkTap(String linkText) {
    try {
      if (linkText.startsWith('\\\\')) {
        // UNCパスの場合
        _openUncPath(linkText);
      } else if (linkText.startsWith('http')) {
        // URLの場合
        _openUrl(linkText);
      } else if (linkText.startsWith('file://')) {
        // ファイルURLの場合
        _openFileUrl(linkText);
      } else if (linkText.contains(':\\')) {
        // ローカルファイルパスの場合
        _openLocalPath(linkText);
      }
    } catch (e) {
      if (kDebugMode) {
        print('リンクオープンエラー: $e');
      }
      SnackBarService.showError(context, 'リンクを開けませんでした: $linkText');
    }
  }

  /// UNCパスを開く
  void _openUncPath(String uncPath) {
    try {
      // UNCパスをfile://形式に変換
      final fileUrl = 'file:///${uncPath.replaceAll('\\', '/')}';
      _openFileUrl(fileUrl);
    } catch (e) {
      SnackBarService.showError(context, 'UNCパスを開けませんでした: $uncPath');
    }
  }

  /// URLを開く
  void _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        SnackBarService.showError(context, 'URLを開けませんでした: $url');
      }
    } catch (e) {
      SnackBarService.showError(context, 'URLを開けませんでした: $url');
    }
  }

  /// ファイルURLを開く
  void _openFileUrl(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        SnackBarService.showError(context, 'ファイルを開けませんでした: $fileUrl');
      }
    } catch (e) {
      SnackBarService.showError(context, 'ファイルを開けませんでした: $fileUrl');
    }
  }

  /// ローカルパスを開く
  void _openLocalPath(String path) async {
    try {
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        SnackBarService.showError(context, 'ファイルを開けませんでした: $path');
      }
    } catch (e) {
      SnackBarService.showError(context, 'ファイルを開けませんでした: $path');
    }
  }

  /// タスクの関連リンクを取得
  List<LinkItem> _getRelatedLinks(TaskItem task) {
    final groups = ref.read(linkViewModelProvider);
    final relatedLinks = <LinkItem>[];
    
    for (final linkId in task.relatedLinkIds) {
      for (final group in groups.groups) {
        for (final link in group.items) {
          if (link.id == linkId) {
            relatedLinks.add(link);
            break;
          }
        }
      }
    }
    
    return relatedLinks;
  }

  /// 画像ファイルかどうかを判定
  bool _isImageFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.png') || 
           ext.endsWith('.jpg') || 
           ext.endsWith('.jpeg') || 
           ext.endsWith('.gif') || 
           ext.endsWith('.bmp') || 
           ext.endsWith('.webp');
  }

  /// 全画面画像表示
  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // 背景をクリックで閉じる
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // 画像を中央に配置
              Center(
                child: GestureDetector(
                  onTap: () {
                    // 画像をクリックしても閉じない（ズームやパンの操作ができるように）
                  },
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                '画像を読み込めませんでした',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // 閉じるボタン
              Positioned(
                top: 40,
                right: 40,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 関連リンクの表示を構築
  Widget _buildRelatedLinksDisplay(List<LinkItem> links, {VoidCallback? onAnyLinkTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // リンク一覧（アイコン付きで表示）
        ...links.map((link) {
          final isImage = link.type == LinkType.file && _isImageFile(link.path);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                // リンクアイコン（画像の場合は大きく表示してクリック可能）
                if (isImage)
                  GestureDetector(
                    onTap: () {
                      _showFullScreenImage(context, link.path);
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(link.path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 32),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 16,
                    height: 16,
                    child: _buildFaviconOrIcon(link, Theme.of(context)),
                  ),
                const SizedBox(width: 8),
                // リンクラベル（クリック可能）
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (onAnyLinkTap != null) onAnyLinkTap();
                      _openRelatedLink(link);
                    },
                    child: Text(
                      link.label,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue[800],
                      ),
                      maxLines: isImage ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 関連リンクを開く
  void _openRelatedLink(LinkItem link) {
    try {
      final linkViewModel = ref.read(linkViewModelProvider.notifier);
      linkViewModel.launchLink(link);
      
      SnackBarService.showSuccess(
        context,
        'リンク「${link.label}」を開きました',
      );
    } catch (e) {
      SnackBarService.showError(
        context,
        'リンクを開けませんでした: ${link.label}',
      );
    }
  }

  /// タスクタイトルの文字色を取得（ダークモード対応）
  Color _getTaskTitleColor() {
    final isDarkMode = ref.watch(darkModeProvider);
    final customColor = Color(ref.watch(titleTextColorProvider));
    
    // ダークモードの場合は自動的に白、ライトモードの場合はカスタム色または黒
    if (isDarkMode) {
      return Colors.white;
    } else {
      // カスタム色が設定されている場合はそれを使用、デフォルトは黒
      return customColor.value == 0xFF000000 ? Colors.black : customColor;
    }
  }

  Widget _buildFaviconOrIcon(LinkItem link, ThemeData theme) {
    // リンク管理画面と同じアイコン表示ロジックを使用
    if (link.type == LinkType.url) {
      return UrlPreviewWidget(
        url: link.path, 
        isDark: theme.brightness == Brightness.dark,
        fallbackDomain: link.faviconFallbackDomain,
      );
    } else if (link.type == LinkType.file) {
      return FilePreviewWidget(
        path: link.path,
        isDark: theme.brightness == Brightness.dark,
      );
    } else {
      // フォルダの場合 - リンク管理画面と同じロジック
      if (link.iconData != null) {
        return Icon(
          IconData(link.iconData!, fontFamily: 'MaterialIcons'),
          color: link.iconColor != null ? Color(link.iconColor!) : Colors.orange,
          size: 16,
        );
      } else {
        return Icon(
          Icons.folder,
          color: Colors.orange,
          size: 16,
        );
      }
    }
  }

  Color _getLinkIconColor(LinkItem link) {
    if (link.iconColor != null) {
      return Color(link.iconColor!);
    } else {
      switch (link.type) {
        case LinkType.url:
          return Colors.blue;
        case LinkType.file:
          return Colors.green;
        case LinkType.folder:
          return Colors.orange;
      }
    }
  }

  Widget _buildLinkIcon(LinkItem link, {double size = 20}) {
    if (link.type == LinkType.folder) {
      if (link.iconData != null) {
        return Icon(
          IconData(link.iconData!, fontFamily: 'MaterialIcons'),
          color: _getLinkIconColor(link),
          size: size,
        );
      } else {
        return Icon(
          Icons.folder,
          color: _getLinkIconColor(link),
          size: size,
        );
      }
    } else {
      switch (link.type) {
        case LinkType.file:
          return Icon(
            Icons.insert_drive_file,
            color: _getLinkIconColor(link),
            size: size,
          );
        case LinkType.url:
          return Icon(
            Icons.link,
            color: _getLinkIconColor(link),
            size: size,
          );
        case LinkType.folder:
          return Icon(
            Icons.folder,
            color: _getLinkIconColor(link),
            size: size,
          );
      }
    }
  }
  
}

/// プロジェクト一覧ダイアログ
class _ProjectOverviewDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ProjectOverviewDialog> createState() => _ProjectOverviewDialogState();
}

class _ProjectOverviewDialogState extends ConsumerState<_ProjectOverviewDialog> {
  bool _hideCompleted = true; // デフォルトで完了タスクを非表示
  late FocusNode _dialogFocusNode;

  @override
  void initState() {
    super.initState();
    _dialogFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _dialogFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WidgetRef ref = this.ref;
    final tasks = ref.watch(taskViewModelProvider);
    final now = DateTime.now();
    
    // フォント設定を取得
    final fontSize = ref.watch(fontSizeProvider);
    final titleFontSize = ref.watch(titleFontSizeProvider);
    final memoFontSize = ref.watch(memoFontSizeProvider);
    final descriptionFontSize = ref.watch(descriptionFontSizeProvider);
    final titleFontFamily = ref.watch(titleFontFamilyProvider);
    final memoFontFamily = ref.watch(memoFontFamilyProvider);
    final descriptionFontFamily = ref.watch(descriptionFontFamilyProvider);
    
    // プロジェクト一覧用のレイアウト設定を取得
    final layoutSettings = ref.watch(taskProjectLayoutSettingsProvider);
    
    // タスクをフィルタリング（完了タスクを除外）
    final filteredTasks = tasks.where((task) {
      if (_hideCompleted && task.status == TaskStatus.completed) {
        return false;
      }
      return true;
    }).toList();
    
    // 期限日順でソート（期限なしは最後）
    final sortedTasks = filteredTasks..sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    
    // グリッド設定を計算
    final crossAxisCount = layoutSettings.autoAdjustLayout
        ? (MediaQuery.of(context).size.width > 1400 ? layoutSettings.defaultCrossAxisCount
            : MediaQuery.of(context).size.width > 1100 ? layoutSettings.defaultCrossAxisCount
            : MediaQuery.of(context).size.width > 700 ? (layoutSettings.defaultCrossAxisCount - 1).clamp(2, 4)
            : 2)
        : layoutSettings.defaultCrossAxisCount;
    
    // カードサイズからアスペクト比を計算
    final cardWidth = layoutSettings.cardWidth;
    final cardHeight = layoutSettings.cardHeight;
    final childAspectRatio = cardWidth / cardHeight;

    return PopScope(
      canPop: true,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: FocusScope(
          autofocus: true,
          child: Focus(
            autofocus: true,
            canRequestFocus: true,
            skipTraversal: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                final isControlPressed = HardwareKeyboard.instance.isControlPressed;
                final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
                
                print('🔑 ダイアログ内キーイベント受信: ${event.logicalKey.keyLabel}, Ctrl=$isControlPressed, Shift=$isShiftPressed');
                
                // Escape: ダイアログを閉じる
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  print('✅ Escape 検出: ダイアログを閉じる');
                  Navigator.of(context).pop();
                  return KeyEventResult.handled;
                }
                
                // Ctrl+P: ダイアログを閉じる（プロジェクト一覧を閉じる）
                if (event.logicalKey == LogicalKeyboardKey.keyP && isControlPressed && !isShiftPressed) {
                  print('✅ Ctrl+P 検出: ダイアログを閉じる');
                  Navigator.of(context).pop();
                  return KeyEventResult.handled;
                }
                
                // Ctrl+H: 親画面のヘッダーセクション切り替え（ダイアログを閉じて処理）
                if (event.logicalKey == LogicalKeyboardKey.keyH && isControlPressed && !isShiftPressed) {
                  print('✅ Ctrl+H 検出: ダイアログを閉じてヘッダーセクション切り替え');
                  Navigator.of(context).pop();
                  // 親画面の状態更新は親画面で処理される
                  return KeyEventResult.handled;
                }
                
                // F1: ショートカットヘルプ（ダイアログを閉じて表示）
                if (event.logicalKey == LogicalKeyboardKey.f1) {
                  print('✅ F1 検出: ダイアログを閉じてショートカットヘルプ表示');
                  Navigator.of(context).pop();
                  // 親画面でヘルプが表示される
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: KeyboardListener(
              focusNode: _dialogFocusNode,
              autofocus: true,
              onKeyEvent: (event) {
                // 追加のキーイベント処理が必要な場合
              },
              child: Container(
            width: MediaQuery.of(context).size.width * 0.98,
            height: MediaQuery.of(context).size.height * 0.95,
            constraints: const BoxConstraints(
              minWidth: 1000,
              minHeight: 700,
              maxWidth: 1600,
              maxHeight: 1200,
            ),
            child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'タスク一覧',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 20) * fontSize,
                      fontFamily: titleFontFamily.isEmpty ? null : titleFontFamily,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Checkbox(
                        value: _hideCompleted,
                        onChanged: (v) => setState(() => _hideCompleted = v ?? true),
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                      Text(
                        '完了タスクを非表示',
                        style: TextStyle(fontSize: 12 * fontSize),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '閉じる',
                  ),
                ],
              ),
            ),
            // タスク一覧
            Expanded(
              child: sortedTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'タスクがありません',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(layoutSettings.defaultGridSpacing * 0.75),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: layoutSettings.defaultGridSpacing,
                      mainAxisSpacing: layoutSettings.defaultGridSpacing,
                    ),
                    itemCount: sortedTasks.length,
                    itemBuilder: (context, index) {
                      final task = sortedTasks[index];
                      
                      // カードカラー（期限に応じた色味）
                      final Color? dueColor = task.dueDate != null
                          ? _getDueDateColor(task.dueDate!, now)
                          : null;
                      final Color cardBg = dueColor != null
                          ? dueColor.withOpacity(0.08)
                          : Theme.of(context).colorScheme.surface;
                      final Color borderColor = dueColor != null
                          ? dueColor.withOpacity(0.5)
                          : Theme.of(context).dividerColor;

                      // ステータスバッジの色とテキスト
                      final statusBadge = _getTaskStatusBadge(task.status);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: borderColor, width: 1),
                        ),
                        color: cardBg,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          focusColor: Colors.transparent,
                          canRequestFocus: false,
                          onTap: () {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (context) => TaskDialog(task: task),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(8 * fontSize),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // タイトル
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14 * fontSize * titleFontSize,
                                          fontFamily: titleFontFamily.isEmpty ? null : titleFontFamily,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // ステータスバッジ
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6 * fontSize, vertical: 2 * fontSize),
                                      decoration: BoxDecoration(
                                        color: statusBadge['color'].withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: statusBadge['color'].withOpacity(0.4), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            statusBadge['icon'] as IconData,
                                            size: 10 * fontSize,
                                            color: statusBadge['color'],
                                          ),
                                          SizedBox(width: 2 * fontSize),
                                          Text(
                                            statusBadge['text'] as String,
                                            style: TextStyle(
                                              color: statusBadge['color'],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9 * fontSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // 期限
                                if (task.dueDate != null && dueColor != null) ...[
                                  SizedBox(height: 4 * fontSize),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6 * fontSize, vertical: 4 * fontSize),
                                    decoration: BoxDecoration(
                                      color: dueColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: dueColor.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 12 * fontSize,
                                          color: dueColor,
                                        ),
                                        SizedBox(width: 4 * fontSize),
                                        Text(
                                          '期限: ${DateFormat('MM/dd').format(task.dueDate!)}',
                                          style: TextStyle(
                                            color: dueColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11 * fontSize,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                // メモまたは依頼先
                                if (task.assignedTo != null && task.assignedTo!.isNotEmpty) ...[
                                  SizedBox(height: 4 * fontSize),
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 10 * fontSize, color: Colors.grey[600]),
                                      SizedBox(width: 2 * fontSize),
                                      Expanded(
                                        child: Text(
                                          task.assignedTo!,
                                          style: TextStyle(
                                            color: Color(ref.watch(memoTextColorProvider)),
                                            fontSize: 10 * fontSize * memoFontSize,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: memoFontFamily.isEmpty ? null : memoFontFamily,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (task.notes != null && task.notes!.isNotEmpty) ...[
                                  SizedBox(height: 4 * fontSize),
                                  Row(
                                    children: [
                                      Icon(Icons.note, size: 10 * fontSize, color: Colors.grey[600]),
                                      SizedBox(width: 2 * fontSize),
                                      Expanded(
                                        child: Text(
                                          task.notes!,
                                          style: TextStyle(
                                            color: Color(ref.watch(memoTextColorProvider)),
                                            fontSize: 10 * fontSize * memoFontSize,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: memoFontFamily.isEmpty ? null : memoFontFamily,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                // 説明
                                if (task.description != null && task.description!.isNotEmpty) ...[
                                  SizedBox(height: 4 * fontSize),
                                  Text(
                                    task.description!,
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 10 * fontSize * descriptionFontSize,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: descriptionFontFamily.isEmpty ? null : descriptionFontFamily,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                // サブタスク進捗
                                if (task.hasSubTasks && task.totalSubTasksCount > 0) ...[
                                  SizedBox(height: 4 * fontSize),
                                  Row(
                                    children: [
                                      Icon(Icons.list, size: 10 * fontSize, color: Colors.blue),
                                      SizedBox(width: 2 * fontSize),
                                      Text(
                                        '${task.completedSubTasksCount}/${task.totalSubTasksCount}',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 10 * fontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                // タグ
                                if (task.tags.isNotEmpty) ...[
                                  SizedBox(height: 4 * fontSize),
                                  Wrap(
                                    spacing: 2 * fontSize,
                                    runSpacing: 2 * fontSize,
                                    children: task.tags.take(2).map((tag) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(horizontal: 4 * fontSize, vertical: 2 * fontSize),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 8 * fontSize,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                // 推定時間
                                if (task.estimatedMinutes != null && task.estimatedMinutes! > 0) ...[
                                  SizedBox(height: 4 * fontSize),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 10 * fontSize, color: Colors.grey[600]),
                                      SizedBox(width: 2 * fontSize),
                                      Text(
                                        task.estimatedMinutes! >= 60
                                            ? '${task.estimatedMinutes! ~/ 60}時間${task.estimatedMinutes! % 60 > 0 ? '${task.estimatedMinutes! % 60}分' : ''}'
                                            : '${task.estimatedMinutes}分',
                                        style: TextStyle(
                                          fontSize: 9 * fontSize,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }

  Color _getProjectColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  Color _getDueDateColor(DateTime dueDate, DateTime now) {
    final difference = dueDate.difference(now).inDays;
    if (difference < 0) {
      return Colors.red; // 期限切れ
    } else if (difference == 0) {
      return Colors.orange; // 今日が期限
    } else if (difference <= 3) {
      return Colors.amber; // 3日以内
    } else {
      return Colors.grey; // それ以外
    }
  }

  /// ステータスバッジ情報を取得
  Map<String, dynamic> _getStatusBadge(int completedCount, int totalCount) {
    if (totalCount == 0) {
      return {
        'icon': Icons.hourglass_empty,
        'text': '未着手',
        'color': Colors.green,
      };
    } else if (completedCount == totalCount) {
      return {
        'icon': Icons.check_circle,
        'text': '完了',
        'color': Colors.grey,
      };
    } else if (completedCount > 0) {
      return {
        'icon': Icons.play_circle,
        'text': '進行中',
        'color': Colors.blue,
      };
    } else {
      return {
        'icon': Icons.hourglass_empty,
        'text': '未着手',
        'color': Colors.green,
      };
    }
  }

  /// 期限日表示テキストを取得
  String _getDueDateDisplayText(List<TaskItem> projectTasks, DateTime nearestDueDate) {
    if (projectTasks.length == 1) {
      // 単一タスクの場合
      return '期限: ${DateFormat('MM/dd').format(nearestDueDate)}';
    } else {
      // 複数タスクの場合（コピーしたタスクなど）
      final dueDates = projectTasks
          .map((t) => t.dueDate)
          .where((d) => d != null)
          .cast<DateTime>()
          .toList();
      
      if (dueDates.length <= 1) {
        return '期限: ${DateFormat('MM/dd').format(nearestDueDate)}';
      } else {
        // 最も近い期限日と最も遠い期限日を表示
        dueDates.sort();
        final earliest = dueDates.first;
        final latest = dueDates.last;
        
        if (earliest == latest) {
          return '期限: ${DateFormat('MM/dd').format(earliest)}';
        } else {
          return '期限: ${DateFormat('MM/dd').format(earliest)}-${DateFormat('MM/dd').format(latest)}';
        }
      }
    }
  }

  /// タスクのステータスバッジ情報を取得
  Map<String, dynamic> _getTaskStatusBadge(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return {
          'icon': Icons.hourglass_empty,
          'text': '未着手',
          'color': Colors.green,
        };
      case TaskStatus.inProgress:
        return {
          'icon': Icons.play_circle,
          'text': '進行中',
          'color': Colors.blue,
        };
      case TaskStatus.completed:
        return {
          'icon': Icons.check_circle,
          'text': '完了',
          'color': Colors.grey,
        };
      case TaskStatus.cancelled:
        return {
          'icon': Icons.cancel,
          'text': 'キャンセル',
          'color': Colors.red,
        };
    }
  }
}

/// ショートカット項目ウィジェット（タスク画面用）
class _TaskShortcutItem extends StatelessWidget {
  final String shortcut;
  final String description;

  const _TaskShortcutItem(this.shortcut, this.description);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(description),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          shortcut,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
