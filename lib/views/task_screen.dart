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
import 'schedule_calendar_screen.dart';
import '../widgets/mail_badge.dart';
import '../viewmodels/schedule_viewmodel.dart';
import '../models/schedule_item.dart';
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
import '../widgets/window_control_buttons.dart';
import 'help_center_screen.dart';

// ショートカットキー用のIntentクラス
class _ToggleHeaderIntent extends Intent {
  const _ToggleHeaderIntent();
}

class _ShowProjectOverviewIntent extends Intent {
  const _ShowProjectOverviewIntent();
}

class _ShowTaskDialogIntent extends Intent {
  const _ShowTaskDialogIntent();
}

class _ToggleSelectionModeIntent extends Intent {
  const _ToggleSelectionModeIntent();
}

class _ExportCsvIntent extends Intent {
  const _ExportCsvIntent();
}

class _ShowSettingsIntent extends Intent {
  const _ShowSettingsIntent();
}

class _ShowGroupMenuIntent extends Intent {
  const _ShowGroupMenuIntent();
}

class _ShowTaskTemplateIntent extends Intent {
  const _ShowTaskTemplateIntent();
}

class _ShowScheduleIntent extends Intent {
  const _ShowScheduleIntent();
}

class _NavigateHomeIntent extends Intent {
  const _NavigateHomeIntent();
}

class _ShowPopupMenuIntent extends Intent {
  const _ShowPopupMenuIntent();
}

class _FocusMenuIntent extends Intent {
  const _FocusMenuIntent();
}

class _ShowShortcutHelpIntent extends Intent {
  const _ShowShortcutHelpIntent();
}

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

// グループ化オプション
enum GroupByOption {
  none,      // グループ化なし
  dueDate,   // 期限日でグループ化
  tags,      // タグでグループ化
  linkId,    // リンクIDでグループ化
  status,    // ステータスでグループ化
  priority,  // 優先度でグループ化
}

class _TaskScreenState extends ConsumerState<TaskScreen>
    with WidgetsBindingObserver {
  late SettingsService _settingsService;
  Set<String> _filterStatuses = {'all'}; // 複数選択可能
  String _filterPriority = 'all'; // all, low, medium, high, urgent
  String _searchQuery = '';
  List<Map<String, String>> _sortOrders = [{'field': 'dueDate', 'order': 'asc'}]; // 第3順位まで設定可能
  bool _showFilters = false; // フィルター表示/非表示の切り替え
  bool _showHeaderSection = true; // 統計情報と検索バーの表示/非表示の切り替え
  final FocusNode _appBarMenuFocusNode = FocusNode();
  late FocusNode _searchFocusNode;
  final GlobalKey _menuButtonKey = GlobalKey(); // 3点ドットメニューボタンの位置を取得するためのキー

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
  // ピン留めされたタスクID
  Set<String> _pinnedTaskIds = <String>{};
  
  bool get _isDesktopPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  
  // 検索機能強化
  bool _useRegex = false;
  bool _searchInDescription = true;
  bool _searchInTags = true;
  bool _searchInRequester = true;
  List<String> _searchHistory = [];
  List<String> _searchSuggestions = [];
  bool _showSearchSuggestions = false;
  bool _showSearchOptions = false;
  
  // 名前付きフィルター
  Map<String, Map<String, dynamic>> _savedFilterPresets = {};
  
  // カスタム順序（ドラッグ&ドロップ用）
  List<String> _customTaskOrder = [];
  bool _suppressNextTap = false;

  // グループ化機能
  GroupByOption _groupByOption = GroupByOption.none;

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
    // 保存されたフィルターを読み込み
    _loadSavedFilterPresets();
    // カスタム順序を読み込み
    _loadCustomTaskOrder();
    
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
    
    // WidgetsBindingObserverを追加
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面が再表示されたときにフォーカスを復元（複数回試行で確実に）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreFocusIfNeeded();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _restoreFocusIfNeeded();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _restoreFocusIfNeeded();
    });
  }
  
  /// フォーカスを復元する必要がある場合に復元
  void _restoreFocusIfNeeded() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) return; // この画面が表示されていない場合はスキップ
    
    final primaryFocus = FocusManager.instance.primaryFocus;
    final focusWidget = primaryFocus?.context?.widget;
    
    // TextField、Dialog、PopupMenuButton以外の場合、フォーカスを復元
    final shouldRestore = focusWidget is! EditableText && 
        focusWidget is! Dialog &&
        primaryFocus?.context?.findAncestorWidgetOfExactType<Dialog>() == null &&
        primaryFocus?.context?.findAncestorWidgetOfExactType<PopupMenuButton>() == null;
    
    if (shouldRestore && !_rootKeyFocus.hasFocus) {
      print('🔄 フォーカス復元: _rootKeyFocusにフォーカスを戻す');
      _rootKeyFocus.requestFocus();
    }
  }

  List<Widget> _buildWindowControlButtons() {
    if (!_isDesktopPlatform) {
      return const [];
    }
    return const [WindowControlButtons()];
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
    WidgetsBinding.instance.removeObserver(this);
    _rootKeyFocus.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _appBarMenuFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // アプリがフォアグラウンドに戻ったときにフォーカスを復元
    if (state == AppLifecycleState.resumed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final primaryFocus = FocusManager.instance.primaryFocus;
        // TextFieldにフォーカスがない場合のみ復元
        if (primaryFocus?.context?.widget is! EditableText && !_rootKeyFocus.hasFocus) {
          _rootKeyFocus.requestFocus();
        }
      });
    }
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

  /// 一括ステータス変更メニューを表示
  void _showBulkStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBulkStatusMenuItem(
              context,
              TaskStatus.pending,
              '未着手',
              Colors.green,
              Icons.pending,
            ),
            _buildBulkStatusMenuItem(
              context,
              TaskStatus.inProgress,
              '進行中',
              Colors.blue,
              Icons.play_circle_outline,
            ),
            _buildBulkStatusMenuItem(
              context,
              TaskStatus.completed,
              '完了',
              Colors.grey,
              Icons.check_circle,
            ),
            _buildBulkStatusMenuItem(
              context,
              TaskStatus.cancelled,
              '取消',
              Colors.red,
              Icons.cancel,
            ),
          ],
        ),
      ),
    );
  }

  /// 一括ステータスメニューアイテムを構築
  Widget _buildBulkStatusMenuItem(
    BuildContext context,
    TaskStatus status,
    String label,
    Color color,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        await _bulkChangeStatus(status);
      },
    );
  }

  /// 選択されたタスクのステータスを一括変更
  Future<void> _bulkChangeStatus(TaskStatus status) async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final tasks = ref.read(taskViewModelProvider);
      final selectedTasks = tasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
      final updatedCount = selectedTasks.length;

      for (final task in selectedTasks) {
        if (status == TaskStatus.completed) {
          await taskViewModel.completeTask(task.id);
        } else if (status == TaskStatus.inProgress && task.status == TaskStatus.pending) {
          await taskViewModel.startTask(task.id);
        } else {
          final updatedTask = task.copyWith(
            status: status,
            completedAt: status == TaskStatus.completed ? DateTime.now() : null,
          );
          await taskViewModel.updateTask(updatedTask);
        }
      }

      // 選択をクリア
      setState(() {
        _selectedTaskIds.clear();
      });

      if (mounted) {
        SnackBarService.showSuccess(
          context,
          '$updatedCount件のタスクのステータスを変更しました',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'ステータス変更に失敗しました: $e');
      }
    }
  }

  /// 一括優先度変更メニューを表示
  void _showBulkPriorityMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBulkPriorityMenuItem(
              context,
              TaskPriority.low,
              '低',
              Colors.grey,
            ),
            _buildBulkPriorityMenuItem(
              context,
              TaskPriority.medium,
              '中',
              Colors.orange,
            ),
            _buildBulkPriorityMenuItem(
              context,
              TaskPriority.high,
              '高',
              Colors.red,
            ),
            _buildBulkPriorityMenuItem(
              context,
              TaskPriority.urgent,
              '緊急',
              Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }

  /// 一括優先度メニューアイテムを構築
  Widget _buildBulkPriorityMenuItem(
    BuildContext context,
    TaskPriority priority,
    String label,
    Color color,
  ) {
    IconData icon;
    switch (priority) {
      case TaskPriority.low:
        icon = Icons.arrow_downward;
        break;
      case TaskPriority.medium:
        icon = Icons.remove;
        break;
      case TaskPriority.high:
        icon = Icons.arrow_upward;
        break;
      case TaskPriority.urgent:
        icon = Icons.priority_high;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        await _bulkChangePriority(priority);
      },
    );
  }

  /// 選択されたタスクの優先度を一括変更
  Future<void> _bulkChangePriority(TaskPriority priority) async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final tasks = ref.read(taskViewModelProvider);
      final selectedTasks = tasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
      final updatedCount = selectedTasks.length;

      for (final task in selectedTasks) {
        final updatedTask = task.copyWith(priority: priority);
        await taskViewModel.updateTask(updatedTask);
      }

      // 選択をクリア
      setState(() {
        _selectedTaskIds.clear();
      });

      if (mounted) {
        SnackBarService.showSuccess(
          context,
          '$updatedCount件のタスクの優先度を変更しました',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, '優先度変更に失敗しました: $e');
      }
    }
  }

  /// 一括期限日変更ダイアログを表示
  void _showBulkDueDateDialog(BuildContext context) {
    DateTime? selectedDate;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('期限日を一括変更'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('期限日を選択'),
                subtitle: Text(
                  selectedDate != null
                      ? DateFormat('yyyy/MM/dd').format(selectedDate!)
                      : '未選択',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
              ),
              CheckboxListTile(
                title: const Text('期限日をクリア'),
                value: selectedDate == null,
                onChanged: (value) {
                  setDialogState(() {
                    selectedDate = value == true ? null : (selectedDate ?? DateTime.now());
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _bulkChangeDueDate(selectedDate);
              },
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }
  /// 選択されたタスクの期限日を一括変更
  Future<void> _bulkChangeDueDate(DateTime? dueDate) async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final tasks = ref.read(taskViewModelProvider);
      final selectedTasks = tasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
      final updatedCount = selectedTasks.length;

      for (final task in selectedTasks) {
        final updatedTask = task.copyWith(dueDate: dueDate);
        await taskViewModel.updateTask(updatedTask);
      }

      // 選択をクリア
      setState(() {
        _selectedTaskIds.clear();
      });

      if (mounted) {
        SnackBarService.showSuccess(
          context,
          '$updatedCount件のタスクの期限日を変更しました',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, '期限日変更に失敗しました: $e');
      }
    }
  }
  /// 一括タグ変更ダイアログを表示
  void _showBulkTagsDialog(BuildContext context) {
    final tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タグを一括変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tagController,
              decoration: const InputDecoration(
                labelText: 'タグ（カンマ区切り）',
                hintText: '例: 緊急,重要,プロジェクトA',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '既存のタグに追加されます',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              final tags = tagController.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
              Navigator.of(context).pop();
              await _bulkChangeTags(tags);
            },
            child: const Text('適用'),
          ),
        ],
      ),
    );
  }
  /// 選択されたタスクのタグを一括変更
  Future<void> _bulkChangeTags(List<String> tags) async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final tasks = ref.read(taskViewModelProvider);
      final selectedTasks = tasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
      final updatedCount = selectedTasks.length;

      for (final task in selectedTasks) {
        final currentTags = task.tags ?? [];
        final updatedTags = [...currentTags, ...tags].toSet().toList();
        final updatedTask = task.copyWith(tags: updatedTags);
        await taskViewModel.updateTask(updatedTask);
      }

      // 選択をクリア
      setState(() {
        _selectedTaskIds.clear();
      });

      if (mounted) {
        SnackBarService.showSuccess(
          context,
          '$updatedCount件のタスクにタグを追加しました',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'タグ変更に失敗しました: $e');
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

    _normalizeSortOrders();
  }
  void _normalizeSortOrders() {
    final validFields = {'custom', 'dueDate', 'priority', 'title', 'created', 'status'};
    final normalized = <Map<String, String>>[];

    for (final entry in _sortOrders) {
      var field = entry['field'];
      var order = entry['order'];

      if (field == 'createdAt') {
        field = 'created';
      }
      if (field == null || !validFields.contains(field)) {
        continue;
      }
      if (order != 'desc') {
        order = 'asc';
      }

      normalized.add({'field': field, 'order': order!});
    }

    if (normalized.isEmpty) {
      normalized.add({'field': 'dueDate', 'order': 'asc'});
    }

    _sortOrders = normalized;
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
    
    // グループ化（グループ化が有効な場合）
    Map<String, List<TaskItem>>? groupedTasks;
    if (_groupByOption != GroupByOption.none) {
      groupedTasks = _groupTasks(sortedTasks, _groupByOption);
    }
    
    // 重要な情報のみ出力
    if (tasks.isNotEmpty) {
      print('🚨 フィルタリング後: ${filteredTasks.length}件表示');
      print('🚨 並び替え後: ${sortedTasks.length}件表示');
      if (groupedTasks != null) {
        print('🚨 グループ化: ${groupedTasks.length}グループ');
      }
    } else {
      print('🚨 タスクが存在しません！');
    }

    // 画面が表示されたときに確実にフォーカスを復元
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreFocusIfNeeded();
    });

    return KeyboardShortcutWidget(
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          // ショートカットキーを定義（フォーカスに依存しない）
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH): const _ToggleHeaderIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP): const _ShowProjectOverviewIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _ShowTaskDialogIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): const _ToggleSelectionModeIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyE): const _ExportCsvIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS): const _ShowSettingsIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG): const _ShowGroupMenuIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyT): const _ShowTaskTemplateIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyC): const _ShowScheduleIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _NavigateHomeIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowRight): const _ShowPopupMenuIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): const _FocusMenuIntent(),
          LogicalKeySet(LogicalKeyboardKey.f1): const _ShowShortcutHelpIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _ToggleHeaderIntent: CallbackAction<_ToggleHeaderIntent>(
              onInvoke: (_) {
                setState(() {
                  _showHeaderSection = !_showHeaderSection;
                });
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _ShowProjectOverviewIntent: CallbackAction<_ShowProjectOverviewIntent>(
              onInvoke: (_) {
                _showProjectOverview();
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _ShowTaskDialogIntent: CallbackAction<_ShowTaskDialogIntent>(
              onInvoke: (_) {
                final focused = FocusManager.instance.primaryFocus;
                if (focused?.context?.widget is! EditableText) {
                  _showTaskDialog();
                }
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _ToggleSelectionModeIntent: CallbackAction<_ToggleSelectionModeIntent>(
              onInvoke: (_) {
                final focused = FocusManager.instance.primaryFocus;
                if (focused?.context?.widget is! EditableText) {
                  _toggleSelectionMode();
                }
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _ExportCsvIntent: CallbackAction<_ExportCsvIntent>(
              onInvoke: (_) {
                final focused = FocusManager.instance.primaryFocus;
                if (focused?.context?.widget is! EditableText) {
                  _exportTasksToCsv();
                }
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _ShowSettingsIntent: CallbackAction<_ShowSettingsIntent>(
              onInvoke: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _ShowGroupMenuIntent: CallbackAction<_ShowGroupMenuIntent>(
              onInvoke: (_) {
                final focused = FocusManager.instance.primaryFocus;
                if (focused?.context?.widget is! EditableText) {
                  _showGroupMenu(context);
                }
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _ShowTaskTemplateIntent: CallbackAction<_ShowTaskTemplateIntent>(
              onInvoke: (_) {
                final focused = FocusManager.instance.primaryFocus;
                if (focused?.context?.widget is! EditableText) {
                  _showTaskTemplate();
                }
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _ShowScheduleIntent: CallbackAction<_ShowScheduleIntent>(
              onInvoke: (_) {
                final focused = FocusManager.instance.primaryFocus;
                if (focused?.context?.widget is! EditableText) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScheduleCalendarScreen()),
                  );
                }
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _NavigateHomeIntent: CallbackAction<_NavigateHomeIntent>(
              onInvoke: (_) {
                _navigateToHome(context);
                return null;
              },
            ),
            _ShowPopupMenuIntent: CallbackAction<_ShowPopupMenuIntent>(
              onInvoke: (_) {
                final focused = FocusManager.instance.primaryFocus;
                if (focused?.context?.widget is! EditableText) {
                  _showPopupMenu(context);
                }
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _FocusMenuIntent: CallbackAction<_FocusMenuIntent>(
              onInvoke: (_) {
                _appBarMenuFocusNode.requestFocus();
                return null;
              },
            ),
            _ShowShortcutHelpIntent: CallbackAction<_ShowShortcutHelpIntent>(
              onInvoke: (_) {
                _showShortcutHelp(context);
                return null;
              },
            ),
          },
      child: FocusScope(
        autofocus: true,
        canRequestFocus: true,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_rootKeyFocus.hasFocus) {
                _rootKeyFocus.requestFocus();
              }
            });
          }
        },
    child: Focus(
      focusNode: _rootKeyFocus,
      autofocus: true,
      canRequestFocus: true,
      skipTraversal: true,
      onKeyEvent: (node, event) {
            // フォールバック処理（Shortcutsで処理されなかった場合）
        if (event is KeyDownEvent) {
          final isControlPressed = HardwareKeyboard.instance.isControlPressed;
          final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
          final result = _handleKeyEventShortcut(event, isControlPressed, isShiftPressed);
          if (result) {
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
          // フォーカスが失われた場合に自動的に復元
          onFocusChange: (hasFocus) {
            if (!hasFocus) {
              // フォーカスが失われた場合、少し待ってから復元を試みる
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _restoreFocusIfNeeded();
              });
              // より確実に復元するため、複数回試行
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted) _restoreFocusIfNeeded();
              });
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) _restoreFocusIfNeeded();
              });
            } else {
              print('✅ フォーカス取得: _rootKeyFocusにフォーカスが当たった');
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
          // 一括操作メニューボタン
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: '一括操作',
            enabled: !_selectedTaskIds.isEmpty,
            onSelected: (value) async {
              switch (value) {
                case 'status':
                  _showBulkStatusMenu(context);
                  break;
                case 'priority':
                  _showBulkPriorityMenu(context);
                  break;
                case 'dueDate':
                  _showBulkDueDateDialog(context);
                  break;
                case 'tags':
                  _showBulkTagsDialog(context);
                  break;
                case 'delete':
                  await _deleteSelectedTasks();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text('ステータス変更'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20),
                    SizedBox(width: 8),
                    Text('優先度変更'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dueDate',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 8),
                    Text('期限日変更'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tags',
                child: Row(
                  children: [
                    Icon(Icons.label, size: 20),
                    SizedBox(width: 8),
                    Text('タグ変更'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('削除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          ..._buildWindowControlButtons(),
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
            child: Builder(
              key: _menuButtonKey,
              builder: (context) => PopupMenuButton<String>(
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
            // タスクグリッドビュー
            PopupMenuItem(
              value: 'project_overview',
              child: Row(
                children: [
                  Icon(Icons.calendar_view_month, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('タスクグリッドビュー (Ctrl+P)'),
                ],
              ),
            ),
            // スケジュール一覧
            PopupMenuItem(
              value: 'schedule',
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Text('スケジュール一覧 (Ctrl+Shift+C)'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'help_center',
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.indigo, size: 20),
                  const SizedBox(width: 8),
                  const Text('ヘルプセンター'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // グループ化
            PopupMenuItem(
              value: 'group_menu',
              child: Row(
                children: [
                  Icon(Icons.group, color: Colors.purple, size: 20),
                  SizedBox(width: 8),
                  Text('グループ化 (Ctrl+G)'),
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
        ),
        ..._buildWindowControlButtons(),
       ],//else
       ],//actions
     ),
      body: Column(
        children: [
        // 統計情報と検索・フィルターを1行に配置
        if (_showHeaderSection) _buildCompactHeaderSection(statistics),
        
        // 検索候補リスト
        if (_showSearchSuggestions && _showHeaderSection) _buildSearchSuggestions(),
        
        // 検索オプション（折りたたみ可能）
        if (_showSearchOptions && _showHeaderSection) _buildSearchOptionsSection(),
        
        // ステータスフィルター（折りたたみ可能）
        if (_showFilters) _buildStatusFilterSection(),
        
        // タスク一覧（グループ化 or ピン留めタスク固定 + 通常タスクスクロール）
        Expanded(
          child: sortedTasks.isEmpty
              ? const Center(
                  child: Text('タスクがありません'),
                )
              : (groupedTasks != null && groupedTasks.isNotEmpty)
                  ? _buildGroupedTaskList(groupedTasks)
              : _buildPinnedAndScrollableTaskList(sortedTasks),
        ),//Expanded
        ],//children
      ),//Column
        ),//Scaffold
      ),//Focus
    ),//FocusScope
      ),//Actions
    ),//Shortcuts
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
            flex: 2,
            child: LayoutBuilder(
              builder: (context, statsConstraints) {
                final availableWidth = statsConstraints.maxWidth;
                final statTiles = <Widget>[
                  _buildStatItem('総タスク', statistics['total'] ?? 0, Icons.list),
                  _buildStatItem('未着手', statistics['pending'] ?? 0, Icons.radio_button_unchecked, Colors.grey),
                  _buildStatItem('完了', statistics['completed'] ?? 0, Icons.check_circle, Colors.green),
                  _buildStatItem('進行中', statistics['inProgress'] ?? 0, Icons.pending, Colors.blue),
                  _buildStatItem('期限切れ', statistics['overdue'] ?? 0, Icons.warning, Colors.red),
                  _buildStatItem('今日', statistics['today'] ?? 0, Icons.today, Colors.orange),
                ];

                if (availableWidth < 760) {
                  return SizedBox(
                    height: 86,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.horizontal,
                      itemCount: statTiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => SizedBox(width: 170, child: statTiles[index]),
                    ),
                  );
                }

                if (availableWidth < 1280) {
                  final columns = availableWidth < 1040 ? 2 : 3;
                  const spacing = 12.0;
                  final availableForTiles = availableWidth - (columns - 1) * spacing;
                  final tileWidth = (availableForTiles / columns).clamp(180.0, 260.0).toDouble();

                  return Align(
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: statTiles
                          .map(
                            (tile) => SizedBox(
                              width: tileWidth,
                              child: tile,
                            ),
                          )
                          .toList(),
                    ),
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: statTiles
                      .map(
                        (tile) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: tile,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
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
            flex: 3,
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
                            ? '正規表現で検索（例: ^プロジェクト.*完了\$）'
                            : 'タスクを検索（タイトル・説明・タグ・依頼先）',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).hintColor,
                          ),
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
                          setState(() {
                            _searchQuery = value;
                            _userTypedSearch = value.isNotEmpty;
                            // 検索候補を更新
                            _updateSearchSuggestions(value);
                            _showSearchSuggestions = value.isNotEmpty && _searchSuggestions.isNotEmpty;
                          });
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
                
                // 優先度フィルター（幅を狭く）
                SizedBox(
                  width: 120, // 固定幅で狭く
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      labelText: '優先度',
                      isDense: true,
                    ),
                    value: _filterPriority,
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('すべて'),
                      ),
                      DropdownMenuItem(
                        value: 'low',
                        child: _buildPriorityDropdownItem('低', Colors.green),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: _buildPriorityDropdownItem('中', Colors.orange),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: _buildPriorityDropdownItem('高', Colors.red),
                      ),
                      DropdownMenuItem(
                        value: 'urgent',
                        child: _buildPriorityDropdownItem('緊急', Colors.purple),
                      ),
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
                
                // フィルター保存・読み込みボタン
                PopupMenuButton<String>(
                  icon: const Icon(Icons.bookmark, size: AppIconSizes.medium),
                  tooltip: 'フィルターの保存・読み込み',
                  onSelected: (value) {
                    if (value == 'save') {
                      _showSaveFilterDialog();
                    } else if (value == 'load') {
                      _showLoadFilterDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'save',
                      child: Row(
                        children: [
                          Icon(Icons.save, size: 20),
                          SizedBox(width: 8),
                          Text('現在のフィルターを保存'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'load',
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, size: 20),
                          SizedBox(width: 8),
                          Text('保存したフィルターを読み込み'),
                        ],
                      ),
                    ),
                  ],
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
    return Tooltip(
      message: count == 0 ? '$label: 0件' : '$label: $count件（タップで詳細表示）',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => _showStatisticsDetail(label, count),
        borderRadius: BorderRadius.circular(8),
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
            Icon(icon, color: count == 0 ? Colors.grey : color, size: AppIconSizes.medium),
        const SizedBox(height: 2),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: count == 0 ? Colors.grey : color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: count == 0 ? Colors.grey : null,
              ),
        ),
      ],
        ),
      ),
    );
  }

  /// 統計詳細モーダルを表示
  void _showStatisticsDetail(String label, int count) {
    final tasks = ref.read(taskViewModelProvider);
    List<TaskItem> filteredTasks = [];
    
    switch (label) {
      case '総タスク':
        filteredTasks = tasks;
        break;
      case '未着手':
        filteredTasks = tasks.where((t) => t.status == TaskStatus.pending).toList();
        break;
      case '完了':
        filteredTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
        break;
      case '進行中':
        filteredTasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
        break;
      case '期限切れ':
        final now = DateTime.now();
        filteredTasks = tasks.where((t) => 
          t.dueDate != null && t.dueDate!.isBefore(now) && t.status != TaskStatus.completed
        ).toList();
        break;
      case '今日':
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = todayStart.add(const Duration(days: 1));
        filteredTasks = tasks.where((t) => 
          t.dueDate != null && 
          t.dueDate!.isAfter(todayStart) && 
          t.dueDate!.isBefore(todayEnd)
        ).toList();
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label: $count件'),
        content: SizedBox(
          width: double.maxFinite,
          child: filteredTasks.isEmpty
              ? const Text('該当するタスクがありません')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return ListTile(
                      title: Text(task.title),
                      subtitle: task.dueDate != null
                          ? Text('期限: ${DateFormat('yyyy/MM/dd').format(task.dueDate!)}')
                          : const Text('期限: 未設定'),
                      trailing: _buildStatusChip(task.status),
                      onTap: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) => TaskDialog(
                            task: task,
                            onPinChanged: () {
                              _loadPinnedTasks();
                              setState(() {});
                            },
                            onLinkReordered: () {
                              ref.read(taskViewModelProvider.notifier).forceReloadTasks();
                              setState(() {});
                            },
                          ),
                        );
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
        ],
      ),
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
                            const DropdownMenuItem(value: 'custom', child: Text('ドラッグ順（手動）')),
                            const DropdownMenuItem(value: 'dueDate', child: Text('期限順')),
                            const DropdownMenuItem(value: 'priority', child: Text('優先度順')),
                            const DropdownMenuItem(value: 'title', child: Text('タイトル順')),
                            const DropdownMenuItem(value: 'created', child: Text('作成日順')),
                            const DropdownMenuItem(value: 'status', child: Text('ステータス順')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              if (value == 'custom') {
                                _sortOrders = [
                                  {'field': 'custom', 'order': 'asc'},
                                ];
                              } else if (_sortOrders.isEmpty) {
                                _sortOrders = [
                                  {'field': value, 'order': 'asc'},
                                ];
                              } else {
                                _sortOrders[0] = {'field': value, 'order': _sortOrders[0]['order'] ?? 'asc'};
                              }
                              if (_sortOrders.isNotEmpty && _sortOrders[0]['field'] == 'custom') {
                                // カスタム順のときは第2・第3順位をリセット
                                if (_sortOrders.length > 1) {
                                  _sortOrders = _sortOrders.sublist(0, 1);
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
                          value: _sortOrders.isNotEmpty ? _sortOrders[0]['order'] : 'asc',
                          items: const [
                            DropdownMenuItem(value: 'asc', child: Text('昇順')),
                            DropdownMenuItem(value: 'desc', child: Text('降順')),
                          ],
                          onChanged: (_sortOrders.isNotEmpty && _sortOrders[0]['field'] == 'custom')
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    if (_sortOrders.isNotEmpty) {
                                      _sortOrders[0] = {
                                        'field': _sortOrders[0]['field'] ?? 'dueDate',
                                        'order': value,
                                      };
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
                            const DropdownMenuItem(value: 'created', child: Text('作成日順')),
                            const DropdownMenuItem(value: 'status', child: Text('ステータス順')),
                          ],
                          onChanged: (_sortOrders.isNotEmpty && _sortOrders[0]['field'] == 'custom')
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == null) {
                                      if (_sortOrders.length > 1) {
                                        _sortOrders.removeAt(1);
                                      }
                                    } else {
                                      if (_sortOrders.length > 1) {
                                        _sortOrders[1] = {'field': value, 'order': _sortOrders[1]['order'] ?? 'asc'};
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
                          onChanged: (_sortOrders.isNotEmpty && _sortOrders[0]['field'] == 'custom')
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    if (_sortOrders.length > 1) {
                                      _sortOrders[1] = {'field': _sortOrders[1]['field'] ?? 'dueDate', 'order': value};
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
                            const DropdownMenuItem(value: 'created', child: Text('作成日順')),
                            const DropdownMenuItem(value: 'status', child: Text('ステータス順')),
                          ],
                          onChanged: (_sortOrders.isNotEmpty && _sortOrders[0]['field'] == 'custom')
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == null) {
                                      if (_sortOrders.length > 2) {
                                        _sortOrders.removeAt(2);
                                      }
                                    } else {
                                      if (_sortOrders.length > 2) {
                                        _sortOrders[2] = {'field': value, 'order': _sortOrders[2]['order'] ?? 'asc'};
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
                          onChanged: (_sortOrders.isNotEmpty && _sortOrders[0]['field'] == 'custom')
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    if (_sortOrders.length > 2) {
                                      _sortOrders[2] = {'field': _sortOrders[2]['field'] ?? 'dueDate', 'order': value};
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
  Widget _buildTaskCard(TaskItem task, {int? reorderIndex}) {
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
    
    Widget cardContent = AnimatedContainer(
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
                  : _getTaskBorderColorEnhanced(task), // 期限日に応じたボーダー色（ダークモード対応）
          width: _isSelectionMode && isSelected ? 3 : isHovered ? 4 : 2.5, // 通常時も少し太く
          ),
          boxShadow: [
            BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.6) // ダークモードではより濃い影
                : Theme.of(context).colorScheme.shadow.withValues(alpha: uiState.shadowIntensity),
            blurRadius: isHovered ? uiState.cardElevation * 8 : uiState.cardElevation * 5, // 少し大きめに
            offset: Offset(0, isHovered ? uiState.cardElevation * 4 : uiState.cardElevation * 2.5),
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
          _buildImprovedTaskListTile(task, isSelected, reorderIndex: reorderIndex),
            if (isAutoGenerated) _buildEmailBadge(task),
          ],
        ),
    );

    if (reorderIndex != null) {
      cardContent = Tooltip(
        message: 'クリックで編集\nドラッグアイコンで順序変更',
        waitDuration: const Duration(milliseconds: 500),
        child: cardContent,
      );
    }

    return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredTaskIds.add(task.id)),
        onExit: (_) => setState(() => _hoveredTaskIds.remove(task.id)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_suppressNextTap) {
            _suppressNextTap = false;
            return;
          }
          _suppressNextTap = false;
          // タスクをタップした時にタスクダイアログを開く
          showDialog(
            context: context,
            builder: (context) => TaskDialog(
              task: task,
              onPinChanged: () {
                _loadPinnedTasks();
                setState(() {});
              },
              onLinkReordered: () {
                // リンク並び替え後にタスク管理画面をリフレッシュ
                ref.read(taskViewModelProvider.notifier).forceReloadTasks();
                setState(() {});
              },
            ),
          );
        },
        onTapCancel: () => _suppressNextTap = false,
        child: Transform.scale(
          scale: isHovered && !_isSelectionMode ? 1.02 : 1.0,
          child: cardContent,
      ),
     ),
    );
  }
  /// 改善されたタスクのListTileを構築（指示書に基づく）
  Widget _buildImprovedTaskListTile(TaskItem task, bool isSelected, {int? reorderIndex}) {
    bool isExpanded = _expandedTaskIds.contains(task.id);
    // リンクがなくても、説明や依頼先があれば詳細トグルを表示
    final bool hasDetails =
        (task.description != null && task.description!.isNotEmpty) ||
        (task.assignedTo != null && task.assignedTo!.isNotEmpty) ||
        _hasValidLinks(task);
    final bool hasSubTaskBadge = task.hasSubTasks || task.totalSubTasksCount > 0;
    
    // UIカスタマイズ設定を取得
    final uiState = ref.watch(uiCustomizationProvider);
    
    // アクセントカラーの調整色を取得
    final accentColor = ref.watch(accentColorProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final colorContrast = ref.watch(colorContrastProvider);
    final adjustedAccentColor = _getAdjustedColor(accentColor, colorIntensity, colorContrast);
    
    return ListTile(
      onTap: null, // ListTileのデフォルトのタップ動作を無効化
      isThreeLine: false, // subtitleの高さを制限しない
      dense: false,
      minVerticalPadding: 0,
      contentPadding: EdgeInsets.symmetric(
        horizontal: uiState.cardPadding, 
        vertical: uiState.cardPadding * 0.75
      ), // UIカスタマイズのパディング
      leading: _isSelectionMode 
        ? Checkbox(
            value: isSelected,
            onChanged: (_) => _toggleTaskSelection(task.id),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ピン留めトグル（期限日バッジの近くに配置）
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _togglePinTask(task.id),
              ),
              const SizedBox(width: 4),
              _buildDeadlineIndicator(task),
            ],
          ),
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
      subtitle: IntrinsicHeight(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
        children: [
            // 依頼先/メモ（テキストのみ）：展開時は完全表示、折りたたみ時は省略表示
            if (task.assignedTo != null && task.assignedTo!.isNotEmpty) ...[
            const SizedBox(height: 4),
              if (isExpanded)
                // 展開時：完全表示（UI設定の色を維持）
                Text(
                  task.assignedTo!,
                  style: TextStyle(
                    color: Color(ref.watch(memoTextColorProvider)), // 緑色（UI設定から取得）
                    fontSize: 13 * ref.watch(memoFontSizeProvider),
                    fontWeight: FontWeight.w700,
                    fontFamily: ref.watch(memoFontFamilyProvider).isEmpty 
                        ? null 
                        : ref.watch(memoFontFamilyProvider),
                  ),
                  maxLines: null, // 行数制限なし
                  overflow: TextOverflow.visible,
                  softWrap: true,
                )
              else
                // 折りたたみ時：省略表示（従来通り）
            _buildClickableMemoText(task.assignedTo!, task, showRelatedLinks: false),
          ],
            // 依頼先への説明：展開時のみ完全表示、折りたたみ時は省略表示
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
              if (isExpanded)
                // 展開時：完全表示（UI設定の色を維持）
            Text(
              task.description!,
              style: TextStyle(
                    color: Color(ref.watch(descriptionTextColorProvider)), // UI設定から取得
                    fontSize: 13 * ref.watch(descriptionFontSizeProvider),
                fontWeight: FontWeight.w500,
                    fontFamily: ref.watch(descriptionFontFamilyProvider).isEmpty 
                        ? null 
                        : ref.watch(descriptionFontFamilyProvider),
              ),
                  maxLines: null, // 行数制限なし
                  overflow: TextOverflow.visible,
                  softWrap: true,
                )
              else
                // 折りたたみ時：省略表示（従来通り）
                _buildDescriptionWithTooltip(task.description!),
            ],
            // タグ表示（タスクグリッドビューと同様のスタイル）
            if (task.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: task.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
              overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
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
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // リマインダーアイコン（常に幅を確保）
          Visibility(
            visible: task.reminderTime != null,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
            Icon(
              Icons.notifications_active,
              color: Colors.orange,
              size: 20,
            ),
                SizedBox(width: 4),
              ],
            ),
          ),
          // サブタスク: あるときだけバッジ表示し、クリックで編集ダイアログ
          Builder(
            builder: (context) {
              print('=== 全タスクのサブタスクバッジチェック ===');
              print('タスク: ${task.title}');
              print('hasSubTasks: ${task.hasSubTasks}');
              print('totalSubTasksCount: ${task.totalSubTasksCount}');
              print('completedSubTasksCount: ${task.completedSubTasksCount}');
              print('表示条件: $hasSubTaskBadge');
              print('===============================');
              
              return Visibility(
                visible: hasSubTaskBadge,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
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
                    ),
                    const SizedBox(width: 4),
                  ],
                  ),
                );
            },
          ),
          // 予定バッジ（カレンダーアイコン）
          _buildScheduleBadge(task.id),
          const SizedBox(width: 4),
          // メールバッジ
          _buildMailBadges(task.id),
          const SizedBox(width: 4),
          // 関連リンクボタン
          _buildRelatedLinksButton(task),
          const SizedBox(width: 4),
          // ステータスチップと優先度（必須バッジ）
          _buildStatusChip(task.status),
          const SizedBox(width: 4),
          _buildPriorityIndicatorForList(task.priority),
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
          if (reorderIndex != null) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: 'ドラッグで順序変更',
              waitDuration: const Duration(milliseconds: 400),
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: GestureDetector(
                  onTapDown: (_) => _suppressNextTap = true,
                  onTapUp: (_) => _suppressNextTap = false,
                  onTapCancel: () => _suppressNextTap = false,
                  child: ReorderableDragStartListener(
                    index: reorderIndex!,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        Icons.drag_indicator,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 期限日インジケーター（指示書に基づく改善）
  /// タスクグリッドビューと同じ色分けロジックを使用
  Widget _buildDeadlineIndicator(TaskItem task) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData icon;
    
    if (task.dueDate == null) {
      // 期限未設定は未着手と同じ緑色
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade900;
      borderColor = Colors.green.shade300;
      icon = Icons.schedule;
    } else {
      final now = DateTime.now();
      final dueDate = task.dueDate!;
      final difference = dueDate.difference(now).inDays;
      
      if (difference < 0) {
        // 期限切れ
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade900;
      borderColor = Colors.red.shade300;
      icon = Icons.warning;
      } else if (difference == 0) {
        // 今日が期限
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      borderColor = Colors.orange.shade300;
      icon = Icons.today;
      } else if (difference <= 3) {
        // 3日以内（黄色/アンバー）
        backgroundColor = Colors.amber.shade50;
        textColor = Colors.amber.shade900;
        borderColor = Colors.amber.shade300;
        icon = Icons.calendar_today;
    } else {
        // それ以外（グレー/青）
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade900;
      borderColor = Colors.blue.shade300;
      icon = Icons.calendar_today;
      }
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
              ? _getRemainingDaysText(task.dueDate!)
              : '未設定',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 期限日までの残り日数をテキストで返す
  String _getRemainingDaysText(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = due.difference(today).inDays;
    
    if (difference < 0) {
      return '${-difference}日超過';
    } else if (difference == 0) {
      return '今日';
    } else if (difference == 1) {
      return 'あと1日';
    } else if (difference <= 3) {
      return 'あと$difference日';
    } else {
      return DateFormat('MM/dd').format(dueDate);
    }
  }

  Widget _buildPriorityIndicator(TaskPriority priority, [double? fontSize]) {
    // グリッドビュー用（色と文字1文字）
    if (fontSize != null) {
      final priorityInfo = _getPriorityInfo(priority);
      return Container(
        width: 16 * fontSize,
        height: 16 * fontSize,
        decoration: BoxDecoration(
          color: priorityInfo['color'] as Color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            priorityInfo['text'] as String,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10 * fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    // タスク管理画面用（縦のバー）
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: Color(_getPriorityColor(priority)),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Map<String, dynamic> _getPriorityInfo(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return {'color': Colors.green, 'text': '低'};
      case TaskPriority.medium:
        return {'color': Colors.orange, 'text': '中'};
      case TaskPriority.high:
        return {'color': Colors.red, 'text': '高'};
      case TaskPriority.urgent:
        return {'color': Colors.purple, 'text': '緊'};
    }
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

  /// タスク管理画面用の優先度表示（色と文字1文字）
  Widget _buildPriorityIndicatorForList(TaskPriority priority) {
    final priorityInfo = _getPriorityInfoForList(priority);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: priorityInfo['color'] as Color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          priorityInfo['text'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 優先度フィルター用のドロップダウンアイテム（色アイコン＋文字、コンパクト版）
  Widget _buildPriorityDropdownItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              text.length > 1 ? text[0] : text, // 1文字のみ表示（「緊急」→「緊」）
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// タスク管理画面用の優先度情報を取得
  Map<String, dynamic> _getPriorityInfoForList(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return {'color': Colors.green, 'text': '低'};
      case TaskPriority.medium:
        return {'color': Colors.orange, 'text': '中'};
      case TaskPriority.high:
        return {'color': Colors.red, 'text': '高'};
      case TaskPriority.urgent:
        return {'color': Colors.purple, 'text': '緊'};
    }
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
        onPinChanged: () {
          // ピン止め状態変更後にタスクリストを更新
          _loadPinnedTasks();
          setState(() {});
        },
        onLinkReordered: () {
          // リンク並び替え後にタスク管理画面をリフレッシュ
          ref.read(taskViewModelProvider.notifier).forceReloadTasks();
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
      case 'schedule':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ScheduleCalendarScreen(),
          ),
        );
        break;
      case 'group_menu':
        _showGroupMenu(context);
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
      case 'help_center':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HelpCenterScreen(),
          ),
        );
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
      // リンクのメモ情報を取得してTooltipに表示
      final relatedLinks = _getRelatedLinks(task);
      final tooltipMessage = relatedLinks.map((link) {
        if (link.memo != null && link.memo!.isNotEmpty) {
          return '${link.label}\nメモ: ${link.memo}';
        }
        return link.label;
      }).join('\n\n');
      
      return Tooltip(
        message: tooltipMessage,
        waitDuration: const Duration(milliseconds: 500),
        child: Container(
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

    return filteredTasks;
  }

  // 優先度の比較（緊急度高い順）
  // CSV出力処理（フィルター適用済みタスクのみ出力）
  void _exportTasksToCsv() async {
    try {
      final tasks = ref.read(taskViewModelProvider);
      // フィルター適用済みのタスクリストを取得
      final filteredTasks = _sortTasks(_getFilteredTasks(tasks));
      final subTasks = ref.read(subTaskViewModelProvider);
      
      // 列選択ダイアログを表示
      final columns = CsvExport.getColumns();
      final selectedColumns = await _showColumnSelectionDialog(columns);
      
      if (selectedColumns == null) {
        // ユーザーがキャンセルした場合
        return;
      }
      
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
        // 一時ファイルにCSVを出力（フィルター適用済みタスクのみ、選択された列のみ）
        await CsvExport.exportTasksToCsv(
          filteredTasks,
          subTasks,
          tempFile.path,
          selectedColumns: selectedColumns,
        );
        
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
  /// CSV出力の列選択ダイアログを表示
  Future<Set<String>?> _showColumnSelectionDialog(List<Map<String, String>> columns) async {
    // デフォルトで全列を選択
    final selectedColumnIds = columns.map((c) => c['id']!).toSet();
    
    return await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('CSV出力する列を選択'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 全選択/全解除ボタン
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedColumnIds.clear();
                          selectedColumnIds.addAll(columns.map((c) => c['id']!));
                        });
                      },
                      child: const Text('すべて選択'),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedColumnIds.clear();
                        });
                      },
                      child: const Text('すべて解除'),
                    ),
                  ],
                ),
                const Divider(),
                // 列のチェックボックス
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: columns.length,
                    itemBuilder: (context, index) {
                      final column = columns[index];
                      final columnId = column['id']!;
                      final columnLabel = column['label']!;
                      final isSelected = selectedColumnIds.contains(columnId);
                      
                      return CheckboxListTile(
                        title: Text(columnLabel),
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedColumnIds.add(columnId);
                            } else {
                              selectedColumnIds.remove(columnId);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: selectedColumnIds.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context, Set<String>.from(selectedColumnIds));
                    },
              child: const Text('出力'),
            ),
          ],
        ),
      ),
    );
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
    
    // フォーカスが失われている場合は復元を試みる
    if (!_rootKeyFocus.hasFocus && !isEditing && focused?.context?.findAncestorWidgetOfExactType<Dialog>() == null) {
      print('🔍 ショートカット処理前にフォーカスを復元');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_rootKeyFocus.hasFocus) {
          _rootKeyFocus.requestFocus();
        }
      });
    }
    
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      print('✅ ← 検出: ホーム画面に戻る');
      _navigateToHome(context);
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (isEditing) return false;
      print('✅ → 検出: 3点ドットメニューを表示');
      _showPopupMenu(context);
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
      print('✅ Ctrl+P 検出: タスクグリッドビュー');
      _showProjectOverview();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyT && isControlPressed && isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+Shift+T 検出: テンプレートから作成');
      _showTaskTemplate();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyC && isControlPressed && isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+Shift+C 検出: 予定表');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ScheduleCalendarScreen(),
        ),
      );
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyG && isControlPressed && !isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+G 検出: グループ化メニュー');
      _showGroupMenu(context);
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
              _TaskShortcutItem('ヘルプメニュー', 'ヘルプセンター（3点メニュー）'),
              const Divider(),
              _TaskShortcutItem('Ctrl+P', 'タスクグリッドビュー'),
              _TaskShortcutItem('Ctrl+Shift+C', 'スケジュール一覧'),
              _TaskShortcutItem('Ctrl+G', 'グループ化'),
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
    // 3点ドットメニューボタンの位置を取得
    final RenderBox? button = _menuButtonKey.currentContext?.findRenderObject() as RenderBox?;
    RelativeRect position;
    
    if (button != null) {
      final Offset offset = button.localToGlobal(Offset.zero);
      position = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height,
        offset.dx + button.size.width,
        offset.dy + button.size.height,
      );
    } else {
      // フォールバック: ボタンの位置が取得できない場合は固定位置
      final screenSize = MediaQuery.of(context).size;
      position = RelativeRect.fromLTRB(
        screenSize.width - 200,
        100,
        screenSize.width - 50,
        100,
      );
    }
    
    showMenu<String>(
      context: context,
      position: position,
      items: [
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
        // タスクグリッドビュー
        PopupMenuItem(
          value: 'project_overview',
          child: Row(
            children: [
              Icon(Icons.calendar_view_month, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('タスクグリッドビュー (Ctrl+P)'),
            ],
          ),
        ),
        // スケジュール一覧
        PopupMenuItem(
          value: 'schedule',
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text('スケジュール一覧 (Ctrl+Shift+C)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'help_center',
          child: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              const Text('ヘルプセンター'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // 並び替え
        // グループ化
        PopupMenuItem(
          value: 'group_menu',
          child: Row(
            children: [
              Icon(Icons.group, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text('グループ化 (Ctrl+G)'),
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
    
    // 最大20個まで表示
    final displayCount = subTasks.length < 20 ? subTasks.length : 20;
    for (int i = 0; i < displayCount; i++) {
      final subTask = subTasks[i];
      final status = subTask.isCompleted ? '✓' : '×';
      final title = subTask.title.length > 30 
        ? '${subTask.title.substring(0, 30)}...' 
        : subTask.title;
      buffer.writeln('$status $title');
      
      // 説明がある場合は表示
      if (subTask.description != null && subTask.description!.isNotEmpty) {
        final desc = subTask.description!.length > 40 
          ? '  ${subTask.description!.substring(0, 40)}...' 
          : '  ${subTask.description!}';
        buffer.writeln(desc);
      }
    }
    
    if (subTasks.length > 20) {
      buffer.writeln('... 他${subTasks.length - 20}個');
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

  /// タスクグリッドビューを表示
  void _showProjectOverview() {
    showDialog(
      context: context,
      builder: (context) => _ProjectOverviewDialog(
        onPinChanged: () {
          // ピン状態が変更されたら、親の状態も再読み込み
          setState(() {
            _loadPinnedTasks();
          });
        },
      ),
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
  /// タスクの期限日に応じたカード色を取得
  /// カード背景色は常にUI設定の色を使用（期限日による色分けは期限バッジのみに適用）
  Color _getTaskCardColor(TaskItem task) {
      return Theme.of(context).colorScheme.surface;
  }
  /// タスクの期限日に応じたボーダー色を取得
  /// ボーダー色は常にUI設定の色を使用（期限日による色分けは期限バッジのみに適用）
  Color _getTaskBorderColor(TaskItem task) {
      return Theme.of(context).colorScheme.outline.withValues(alpha: 0.4);
    }

  /// タスクの期限日に応じたボーダー色を取得（ダークモード対応強化版）
  Color _getTaskBorderColorEnhanced(TaskItem task) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      // ダークモードではより明るいボーダーで視認性を向上
      return Theme.of(context).colorScheme.outline.withValues(alpha: 0.6);
    } else {
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

  /// 検索候補を更新
  void _updateSearchSuggestions(String query) {
    if (query.trim().isEmpty) {
      _searchSuggestions = [];
      return;
    }
    
    final queryLower = query.toLowerCase();
    final suggestions = <String>[];
    
    // 検索履歴から候補を取得
    for (final history in _searchHistory) {
      if (history.toLowerCase().contains(queryLower) && !suggestions.contains(history)) {
        suggestions.add(history);
      }
    }
    
    // タスクタイトルから候補を取得
    final tasks = ref.read(taskViewModelProvider);
    for (final task in tasks) {
      if (task.title.toLowerCase().contains(queryLower) && !suggestions.contains(task.title)) {
        suggestions.add(task.title);
      }
    }
    
    // 最大5件まで
    _searchSuggestions = suggestions.take(5).toList();
  }

  /// 検索候補リストを構築
  Widget _buildSearchSuggestions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _searchSuggestions.map((suggestion) {
          return InkWell(
            onTap: () {
              setState(() {
                _searchController.text = suggestion;
                _searchQuery = suggestion;
                _userTypedSearch = true;
                _showSearchSuggestions = false;
              });
              _searchFocusNode.unfocus();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 保存されたフィルタープリセットを読み込み
  void _loadSavedFilterPresets() {
    try {
      final box = Hive.box('filterPresets');
      final presets = box.get('taskFilterPresets', defaultValue: <String, Map>{});
      _savedFilterPresets = Map<String, Map<String, dynamic>>.from(
        presets.map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value)))
      );
    } catch (e) {
      print('フィルタープリセット読み込みエラー: $e');
      _savedFilterPresets = {};
    }
  }

  /// 保存されたフィルタープリセットを保存
  void _saveFilterPresets() {
    try {
      final box = Hive.box('filterPresets');
      box.put('taskFilterPresets', _savedFilterPresets);
    } catch (e) {
      print('フィルタープリセット保存エラー: $e');
    }
  }

  /// フィルター保存ダイアログを表示
  void _showSaveFilterDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルターを保存'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'フィルター名',
            hintText: '例: 今週の緊急タスク',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                _savedFilterPresets[name] = {
                  'statuses': _filterStatuses.toList(),
                  'priority': _filterPriority,
                  'sortOrders': _sortOrders,
                  'searchQuery': _searchQuery,
                };
                _saveFilterPresets();
                Navigator.of(context).pop();
                SnackBarService.showSuccess(context, 'フィルター「$name」を保存しました');
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// フィルター読み込みダイアログを表示
  void _showLoadFilterDialog() {
    if (_savedFilterPresets.isEmpty) {
      SnackBarService.showInfo(context, '保存されたフィルターがありません');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルターを読み込み'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _savedFilterPresets.length,
            itemBuilder: (context, index) {
              final presetName = _savedFilterPresets.keys.elementAt(index);
              final preset = _savedFilterPresets[presetName]!;
              return ListTile(
                title: Text(presetName),
                subtitle: Text(
                  'ステータス: ${preset['statuses']?.length ?? 0}件, '
                  '優先度: ${preset['priority'] ?? 'すべて'}, '
                  '検索: ${preset['searchQuery']?.toString().isEmpty ?? true ? 'なし' : 'あり'}'
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        _savedFilterPresets.remove(presetName);
                        _saveFilterPresets();
                        Navigator.of(context).pop();
                        _showLoadFilterDialog();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, size: 20),
                      onPressed: () {
                        setState(() {
                          final statusList = (preset['statuses'] as List?);
                          _filterStatuses = statusList != null 
                              ? statusList.map((e) => e.toString()).toSet() 
                              : {'all'};
                          _filterPriority = preset['priority']?.toString() ?? 'all';
                          _sortOrders = (preset['sortOrders'] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? [{'field': 'dueDate', 'order': 'asc'}];
                          _searchQuery = preset['searchQuery']?.toString() ?? '';
                          _searchController.text = _searchQuery;
                        });
                        _saveFilterSettings();
                        Navigator.of(context).pop();
                        SnackBarService.showSuccess(context, 'フィルター「$presetName」を読み込みました');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
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

  List<TaskItem> _applyCustomOrder(List<TaskItem> tasks) {
    if (_customTaskOrder.isEmpty) {
      return tasks;
    }

    final idToTask = {for (final task in tasks) task.id: task};
    final ordered = <TaskItem>[];

    for (final id in _customTaskOrder) {
      final task = idToTask.remove(id);
      if (task != null) {
        ordered.add(task);
      }
    }

    if (idToTask.isNotEmpty) {
      ordered.addAll(idToTask.values);
    }
    return ordered;
  }

  /// タスクを並び替える
  List<TaskItem> _sortTasks(List<TaskItem> tasks) {
    if (_sortOrders.isNotEmpty && _sortOrders[0]['field'] == 'custom') {
      return _applyCustomOrder(List<TaskItem>.from(tasks));
    }

    final sortedTasks = List<TaskItem>.from(tasks);
    
    sortedTasks.sort((a, b) {
      // ピン留めは最優先で上に
      final aPinned = _pinnedTaskIds.contains(a.id);
      final bPinned = _pinnedTaskIds.contains(b.id);
      if (aPinned != bPinned) {
        return aPinned ? -1 : 1;
      }
      int comparison = 0;
      
      for (final order in _sortOrders.where((o) => o['field'] != null)) {
        final sortField = order['field']!;
        final sortOrder = order['order'] == 'desc' ? -1 : 1;
        switch (sortField) {
          case 'dueDate':
            if (a.dueDate == null && b.dueDate == null) {
              comparison = 0;
            } else if (a.dueDate == null) {
              comparison = 1;
            } else if (b.dueDate == null) {
              comparison = -1;
            } else {
              comparison = a.dueDate!.compareTo(b.dueDate!);
            }
            break;
          case 'priority':
            comparison = a.priority.index.compareTo(b.priority.index);
            break;
          case 'created':
          case 'createdAt':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'title':
            comparison = a.title.compareTo(b.title);
            break;
          case 'status':
            comparison = a.status.index.compareTo(b.status.index);
            break;
          default:
            comparison = 0;
            break;
        }
        if (comparison != 0) {
          return comparison * sortOrder;
        }
      }
      
      return 0;
    });
    
    return sortedTasks;
  }
  /// グループ化メニューを表示
  void _showGroupMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループ化'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('グループ化なし'),
                trailing: _groupByOption == GroupByOption.none
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _groupByOption = GroupByOption.none;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('期限日でグループ化'),
                trailing: _groupByOption == GroupByOption.dueDate
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _groupByOption = GroupByOption.dueDate;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.label),
                title: const Text('タグでグループ化'),
                trailing: _groupByOption == GroupByOption.tags
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _groupByOption = GroupByOption.tags;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('プロジェクト（リンク）でグループ化'),
                trailing: _groupByOption == GroupByOption.linkId
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _groupByOption = GroupByOption.linkId;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('ステータスでグループ化'),
                trailing: _groupByOption == GroupByOption.status
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _groupByOption = GroupByOption.status;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('優先度でグループ化'),
                trailing: _groupByOption == GroupByOption.priority
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _groupByOption = GroupByOption.priority;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// タスクをグループ化
  Map<String, List<TaskItem>> _groupTasks(List<TaskItem> tasks, GroupByOption option) {
    switch (option) {
      case GroupByOption.none:
        return {};
      case GroupByOption.dueDate:
        return _groupByDueDate(tasks);
      case GroupByOption.tags:
        return _groupByTags(tasks);
      case GroupByOption.linkId:
        return _groupByLinkId(tasks);
      case GroupByOption.status:
        return _groupByStatus(tasks);
      case GroupByOption.priority:
        return _groupByPriority(tasks);
    }
  }

  /// 期限日でグループ化
  Map<String, List<TaskItem>> _groupByDueDate(List<TaskItem> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final nextWeekStart = weekEnd.add(const Duration(days: 1));
    final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    final groups = <String, List<TaskItem>>{
      '今日': [],
      '明日': [],
      '今週': [],
      '来週': [],
      '今月': [],
      '来月以降': [],
      '期限切れ': [],
      '期限未設定': [],
    };

    for (final task in tasks) {
      if (task.dueDate == null) {
        groups['期限未設定']!.add(task);
        continue;
      }

      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      
      if (taskDate == today) {
        groups['今日']!.add(task);
      } else if (taskDate == tomorrow) {
        groups['明日']!.add(task);
      } else if (taskDate.isBefore(today)) {
        groups['期限切れ']!.add(task);
      } else if (taskDate.isAfter(nextWeekEnd)) {
        if (taskDate.isBefore(nextMonthStart)) {
          groups['今月']!.add(task);
        } else {
          groups['来月以降']!.add(task);
        }
      } else if (taskDate.isAfter(weekEnd)) {
        groups['来週']!.add(task);
      } else {
        groups['今週']!.add(task);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  /// タグでグループ化
  Map<String, List<TaskItem>> _groupByTags(List<TaskItem> tasks) {
    final groups = <String, List<TaskItem>>{};
    
    for (final task in tasks) {
      if (task.tags.isEmpty) {
        if (!groups.containsKey('タグなし')) {
          groups['タグなし'] = [];
        }
        groups['タグなし']!.add(task);
      } else {
        for (final tag in task.tags) {
          if (!groups.containsKey(tag)) {
            groups[tag] = [];
          }
          groups[tag]!.add(task);
        }
      }
    }
    
    return groups;
  }

  /// リンクIDでグループ化
  Map<String, List<TaskItem>> _groupByLinkId(List<TaskItem> tasks) {
    final groups = <String, List<TaskItem>>{};
    
    for (final task in tasks) {
      final linkId = task.relatedLinkId;
      if (linkId == null || linkId.isEmpty) {
        if (!groups.containsKey('リンクなし')) {
          groups['リンクなし'] = [];
        }
        groups['リンクなし']!.add(task);
      } else {
        // リンクラベルを取得（簡易実装、必要に応じて_getLinkLabelを使用）
        final label = linkId; // 本来は_getLinkLabel(linkId)を使用
        if (!groups.containsKey(label)) {
          groups[label] = [];
        }
        groups[label]!.add(task);
      }
    }
    
    return groups;
  }

  /// ステータスでグループ化
  Map<String, List<TaskItem>> _groupByStatus(List<TaskItem> tasks) {
    final groups = <String, List<TaskItem>>{
      '未着手': [],
      '進行中': [],
      '完了': [],
      'キャンセル': [],
    };

    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.pending:
          groups['未着手']!.add(task);
          break;
        case TaskStatus.inProgress:
          groups['進行中']!.add(task);
          break;
        case TaskStatus.completed:
          groups['完了']!.add(task);
          break;
        case TaskStatus.cancelled:
          groups['キャンセル']!.add(task);
          break;
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  /// 優先度でグループ化
  Map<String, List<TaskItem>> _groupByPriority(List<TaskItem> tasks) {
    final groups = <String, List<TaskItem>>{
      '緊急': [],
      '高': [],
      '中': [],
      '低': [],
    };

    for (final task in tasks) {
      switch (task.priority) {
        case TaskPriority.urgent:
          groups['緊急']!.add(task);
          break;
        case TaskPriority.high:
          groups['高']!.add(task);
          break;
        case TaskPriority.medium:
          groups['中']!.add(task);
          break;
        case TaskPriority.low:
          groups['低']!.add(task);
          break;
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }
  /// グループ化されたタスクリストを構築
  Widget _buildGroupedTaskList(Map<String, List<TaskItem>> groups) {
    final sortedKeys = groups.keys.toList();
    
    // グループの表示順序を調整
    if (_groupByOption == GroupByOption.dueDate) {
      // 期限日の場合は時系列順
      final order = ['今日', '明日', '今週', '来週', '今月', '来月以降', '期限切れ', '期限未設定'];
      sortedKeys.sort((a, b) {
        final indexA = order.indexOf(a);
        final indexB = order.indexOf(b);
        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    } else if (_groupByOption == GroupByOption.priority) {
      // 優先度の場合は緊急度順
      final order = ['緊急', '高', '中', '低'];
      sortedKeys.sort((a, b) {
        final indexA = order.indexOf(a);
        final indexB = order.indexOf(b);
        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    } else {
      // その他の場合はアルファベット順
      sortedKeys.sort();
    }

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final groupName = sortedKeys[index];
        final tasks = groups[groupName]!;
        
        // ピン留めタスクと通常タスクを分離
        final pinnedTasks = tasks.where((task) => _pinnedTaskIds.contains(task.id)).toList();
        final unpinnedTasks = tasks.where((task) => !_pinnedTaskIds.contains(task.id)).toList();
        
        return ExpansionTile(
          leading: Icon(_getGroupIcon(groupName)),
          title: Text('$groupName (${tasks.length}件)'),
          initiallyExpanded: true,
          children: [
            // ピン留めタスク
            if (pinnedTasks.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
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
            // 通常タスク
            ...unpinnedTasks.map((task) => _buildTaskCard(task)),
          ],
        );
      },
    );
  }
  /// グループ名に応じたアイコンを取得
  IconData _getGroupIcon(String groupName) {
    if (_groupByOption == GroupByOption.dueDate) {
      if (groupName == '今日' || groupName == '明日') {
        return Icons.today;
      } else if (groupName == '期限切れ') {
        return Icons.warning;
      } else if (groupName == '期限未設定') {
        return Icons.event_busy;
      } else {
        return Icons.calendar_month;
      }
    } else if (_groupByOption == GroupByOption.tags) {
      return Icons.label;
    } else if (_groupByOption == GroupByOption.linkId) {
      return Icons.link;
    } else if (_groupByOption == GroupByOption.status) {
      switch (groupName) {
        case '未着手':
          return Icons.radio_button_unchecked;
        case '進行中':
          return Icons.refresh;
        case '完了':
          return Icons.check_circle;
        case 'キャンセル':
          return Icons.cancel;
        default:
          return Icons.category;
      }
    } else if (_groupByOption == GroupByOption.priority) {
      return Icons.flag;
    }
    return Icons.folder;
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
          // 通常タスク（スクロール可能、ドラッグ&ドロップ対応）
          Expanded(
            child: unpinnedTasks.isEmpty
                ? const Center(child: Text('その他のタスクはありません'))
                : _buildReorderableTaskList(unpinnedTasks),
          ),
        ],
      );
    }
    
    // ピン留めタスクがない場合はドラッグ&ドロップ対応リストを表示
    return _buildReorderableTaskList(unpinnedTasks);
  }

  /// カスタム順序を読み込み
  void _loadCustomTaskOrder() {
    try {
      final box = Hive.box('taskOrder');
      final order = box.get('customOrder', defaultValue: <String>[]);
      _customTaskOrder = List<String>.from(order);
    } catch (e) {
      print('カスタム順序読み込みエラー: $e');
      _customTaskOrder = [];
    }
  }

  /// カスタム順序を保存
  void _saveCustomTaskOrder() {
    try {
      final box = Hive.box('taskOrder');
      box.put('customOrder', _customTaskOrder);
    } catch (e) {
      print('カスタム順序保存エラー: $e');
    }
  }

  /// 並び替え可能なタスクリストを構築
  Widget _buildReorderableTaskList(List<TaskItem> tasks) {
    final usingCustomOrder = _sortOrders.isNotEmpty && _sortOrders[0]['field'] == 'custom';
    final orderedTasks = usingCustomOrder
        ? _applyCustomOrder(List<TaskItem>.from(tasks))
        : List<TaskItem>.from(tasks);

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      buildDefaultDragHandles: false,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, animatedChild) {
            final t = Curves.easeOut.transform(animation.value);
            return Transform.scale(
              scale: 1.0 + t * 0.04,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: animatedChild,
              ),
            );
          },
          child: child,
        );
      },
      itemCount: orderedTasks.length,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        setState(() {
          final movedTask = orderedTasks.removeAt(oldIndex);
          orderedTasks.insert(newIndex, movedTask);
          _customTaskOrder = orderedTasks.map((task) => task.id).toList();
          _sortOrders = [
            {'field': 'custom', 'order': 'asc'},
          ];
          _saveCustomTaskOrder();
          _saveFilterSettings();
          _suppressNextTap = false;
        });
      },
      itemBuilder: (context, index) {
        return _buildTaskCardWithKey(
          orderedTasks[index],
          key: ValueKey(orderedTasks[index].id),
          index: index,
        );
      },
    );
  }

  /// キー付きタスクカードを構築（ReorderableListView用）
  Widget _buildTaskCardWithKey(TaskItem task, {required Key key, required int index}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _buildTaskCard(task, reorderIndex: index),
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
  /// 予定バッジ（カレンダーアイコン、ホバーで予定リスト表示）
  Widget _buildScheduleBadge(String taskId) {
    final schedules = ref.watch(scheduleViewModelProvider);
    final taskSchedules = schedules.where((s) => s.taskId == taskId).toList();
    
    if (taskSchedules.isEmpty) {
      return const SizedBox(width: 28);
    }
    
    // 日時昇順でソート
    taskSchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    
    // ツールチップコンテンツを生成
    final tooltipContent = _buildScheduleTooltipContent(taskSchedules);
    
    return SizedBox(
      width: 28,
      child: MouseRegion(
        cursor: SystemMouseCursors.help,
        child: Tooltip(
          message: tooltipContent,
          waitDuration: const Duration(milliseconds: 500),
          preferBelow: false,
          verticalOffset: 10,
          textStyle: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.calendar_today,
              size: 20,
              color: Colors.orange.shade700,
            ),
          ),
        ),
      ),
    );
  }

  /// 予定ツールチップのコンテンツを生成
  String _buildScheduleTooltipContent(List<ScheduleItem> schedules) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('MM/dd');
    final timeFormat = DateFormat('HH:mm');
    
    for (final schedule in schedules) {
      final date = dateFormat.format(schedule.startDateTime);
      final time = timeFormat.format(schedule.startDateTime);
      final endTime = schedule.endDateTime != null
          ? ' - ${timeFormat.format(schedule.endDateTime!)}'
          : '';
      final location = schedule.location != null && schedule.location!.isNotEmpty
          ? ' @ ${schedule.location}'
          : '';
      
      buffer.writeln('$date $time$endTime$location');
      buffer.writeln('  ${schedule.title}');
      if (buffer.length > 0) {
        buffer.writeln('');
      }
    }
    
    return buffer.toString().trim();
  }
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

  /// 関連リンクの表示を構築（タスク一覧用：ツールチップ・長押しなし、10個以上は2列表示）
  Widget _buildRelatedLinksDisplay(List<LinkItem> links, {VoidCallback? onAnyLinkTap}) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: links.map((link) {
          final isImage = link.type == LinkType.file && _isImageFile(link.path);
          
        // 画像の場合は大きく表示
        if (isImage) {
          return GestureDetector(
                    onTap: () {
              if (onAnyLinkTap != null) onAnyLinkTap();
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
          );
        }
        
        // 通常のリンク表示（ツールチップでメモを表示）
        return Tooltip(
          message: link.memo != null && link.memo!.isNotEmpty 
              ? link.memo! 
              : 'メモはリンク管理画面から追加可能',
          waitDuration: const Duration(milliseconds: 500),
                  child: GestureDetector(
                    onTap: () {
                      if (onAnyLinkTap != null) onAnyLinkTap();
                      _openRelatedLink(link);
                    },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Faviconまたはアイコンを表示
                SizedBox(
                  width: 16,
                  height: 16,
                  child: _buildFaviconOrIcon(link, Theme.of(context)),
                ),
                const SizedBox(width: 6),
                Text(
                      link.label,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue[800],
                      ),
                  maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            ),
          );
      }).toList(),
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

  /// タスクグリッドビュー用の関連リンク表示を構築
  Widget _buildRelatedLinksForGrid(TaskItem task, double fontSize) {
    final relatedLinks = _getRelatedLinks(task);
    if (relatedLinks.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 4 * fontSize,
      runSpacing: 2 * fontSize,
      children: relatedLinks.map((link) {
        return Tooltip(
          message: link.memo != null && link.memo!.isNotEmpty 
              ? '${link.label}\n\nメモ: ${link.memo}' 
              : link.label,
          waitDuration: const Duration(milliseconds: 500),
          child: InkWell(
            onTap: () => _openRelatedLink(link),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link,
                  size: 10 * fontSize,
                  color: Colors.blue[700],
                ),
                SizedBox(width: 2 * fontSize),
                Text(
                  link.label,
                  style: TextStyle(
                    fontSize: 8 * fontSize,
                    color: Colors.blue[800],
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
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
  
  /// 展開時の本文表示（タスクグリッドビューと同じスタイル）
  Widget _buildDescriptionExpanded(String description) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        description,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        maxLines: null, // 行数制限なし
        overflow: TextOverflow.visible,
        softWrap: true,
        textAlign: TextAlign.left,
      ),
    );
}
  /// リストビュー用の本文表示（ツールチップ付き）
  Widget _buildDescriptionWithTooltip(String description) {
    return GestureDetector(
      onTap: () {
        // タップで全文を表示するダイアログ
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('本文'),
            content: SingleChildScrollView(
              child: Text(description),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      },
      child: Tooltip(
        message: description,
        waitDuration: const Duration(milliseconds: 400),
        preferBelow: false,
        showDuration: const Duration(seconds: 5),
        textStyle: const TextStyle(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.95),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(8),
        excludeFromSemantics: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.text,
          child: Text(
            description,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
/// タスクグリッドビューダイアログ
class _ProjectOverviewDialog extends ConsumerStatefulWidget {
  final VoidCallback? onPinChanged; // ピン状態変更時のコールバック
  
  const _ProjectOverviewDialog({this.onPinChanged});
  
  @override
  ConsumerState<_ProjectOverviewDialog> createState() => _ProjectOverviewDialogState();
}
class _ProjectOverviewDialogState extends ConsumerState<_ProjectOverviewDialog> {
  Set<String> _filterDueDateColors = {}; // 期限日の色でフィルター（複数選択対応）
  Set<TaskStatus> _filterStatuses = {TaskStatus.pending, TaskStatus.inProgress}; // ステータスフィルター（複数選択対応、デフォルト: 未着手と進行中）
  TaskPriority? _filterPriority; // 優先度フィルター
  late FocusNode _dialogFocusNode;
  // 一括選択機能の状態変数
  bool _isSelectionMode = false; // 選択モードのオン/オフ
  Set<String> _selectedTaskIds = {}; // 選択されたタスクのIDセット
  // ピン留めされたタスクID（タスク管理画面と同期）
  Set<String> _pinnedTaskIds = <String>{};
  // 検索機能
  String _searchQuery = '';
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _dialogFocusNode = FocusNode();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _loadPinnedTasks();
    
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
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
      widget.onPinChanged?.call();
    });
  }

  @override
  void dispose() {
    _dialogFocusNode.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  /// タスクに有効なリンクがあるかチェック
  bool _hasValidLinks(TaskItem task) {
    for (final linkId in task.relatedLinkIds) {
      final groups = ref.read(linkViewModelProvider);
      for (final group in groups.groups) {
        for (final link in group.items) {
          if (link.id == linkId) {
            return true;
          }
        }
      }
    }
    if (task.relatedLinkId != null && task.relatedLinkId!.isNotEmpty) {
      final groups = ref.read(linkViewModelProvider);
      for (final group in groups.groups) {
        for (final link in group.items) {
          if (link.id == task.relatedLinkId) {
            return true;
          }
        }
      }
    }
    return false;
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

  /// タスクグリッドビュー用の関連リンク表示を構築
  Widget _buildRelatedLinksForGrid(TaskItem task, double fontSize, {String searchQuery = ''}) {
    final relatedLinks = _getRelatedLinks(task);
    if (relatedLinks.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 6 * fontSize,
      runSpacing: 4 * fontSize,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: relatedLinks.map((link) {
        return Tooltip(
          message: link.memo != null && link.memo!.isNotEmpty 
              ? link.memo! 
              : 'メモはリンク管理画面から追加可能',
          waitDuration: const Duration(milliseconds: 500),
          child: GestureDetector(
            onTap: () => _openRelatedLink(link),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Faviconまたはアイコンを表示
                SizedBox(
                  width: 14 * fontSize,
                  height: 14 * fontSize,
                  child: _buildFaviconOrIconForGrid(link, Theme.of(context), fontSize),
                ),
                SizedBox(width: 4 * fontSize),
                Flexible(
                  child: searchQuery.isNotEmpty
                      ? HighlightedText(
                          text: link.label,
                          highlight: searchQuery,
                          style: TextStyle(
                            fontSize: 9 * fontSize,
                            color: Colors.blue[800],
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          link.label,
                          style: TextStyle(
                            fontSize: 9 * fontSize,
                            color: Colors.blue[800],
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Faviconまたはアイコンを構築（タスクグリッドビュー用）
  Widget _buildFaviconOrIconForGrid(LinkItem link, ThemeData theme, double fontSize) {
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
      // フォルダの場合
      if (link.iconData != null) {
        return Icon(
          IconData(link.iconData!, fontFamily: 'MaterialIcons'),
          color: link.iconColor != null ? Color(link.iconColor!) : Colors.orange,
          size: 12 * fontSize,
        );
      } else {
        return Icon(
          Icons.folder,
          color: Colors.orange,
          size: 12 * fontSize,
        );
      }
    }
  }

  /// フィルターダイアログを表示（タスクグリッドビュー用）
  Future<void> _showFilterDialogForGrid(BuildContext context, DateTime now) async {
    Set<String> selectedDueDateColors = Set<String>.from(_filterDueDateColors);
    Set<TaskStatus> selectedStatuses = Set<TaskStatus>.from(_filterStatuses);
    TaskPriority? selectedPriority = _filterPriority;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('フィルター'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '期限日の色（複数選択可）',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChipForGrid<bool>(
                      'すべて',
                      true,
                      selectedDueDateColors.isEmpty,
                      (value) {
                        setDialogState(() {
                          selectedDueDateColors.clear();
                        });
                      },
                    ),
                    _buildFilterChipForGrid<String>(
                      '期限切れ',
                      'red',
                      selectedDueDateColors.contains('red'),
                      (value) {
                        setDialogState(() {
                          if (selectedDueDateColors.contains(value)) {
                            selectedDueDateColors.remove(value);
                          } else {
                            selectedDueDateColors.add(value);
                          }
                        });
                      },
                    ),
                    _buildFilterChipForGrid<String>(
                      '今日が期限',
                      'orange',
                      selectedDueDateColors.contains('orange'),
                      (value) {
                        setDialogState(() {
                          if (selectedDueDateColors.contains(value)) {
                            selectedDueDateColors.remove(value);
                          } else {
                            selectedDueDateColors.add(value);
                          }
                        });
                      },
                    ),
                    _buildFilterChipForGrid<String>(
                      '3日以内',
                      'amber',
                      selectedDueDateColors.contains('amber'),
                      (value) {
                        setDialogState(() {
                          if (selectedDueDateColors.contains(value)) {
                            selectedDueDateColors.remove(value);
                          } else {
                            selectedDueDateColors.add(value);
                          }
                        });
                      },
                    ),
                    _buildFilterChipForGrid<String>(
                      '余裕あり',
                      'blue',
                      selectedDueDateColors.contains('blue'),
                      (value) {
                        setDialogState(() {
                          if (selectedDueDateColors.contains(value)) {
                            selectedDueDateColors.remove(value);
                          } else {
                            selectedDueDateColors.add(value);
                          }
                        });
                      },
                    ),
                    _buildFilterChipForGrid<String>(
                      '期限未設定',
                      'green',
                      selectedDueDateColors.contains('green'),
                      (value) {
                        setDialogState(() {
                          if (selectedDueDateColors.contains(value)) {
                            selectedDueDateColors.remove(value);
                          } else {
                            selectedDueDateColors.add(value);
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'ステータス（複数選択可）',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChipForGrid<bool>(
                      'すべて',
                      true,
                      selectedStatuses.isEmpty,
                      (value) {
                        setDialogState(() {
                          selectedStatuses.clear();
                        });
                      },
                    ),
                    _buildFilterChipForGrid<TaskStatus>(
                      '未着手',
                      TaskStatus.pending,
                      selectedStatuses.contains(TaskStatus.pending),
                      (value) {
                        setDialogState(() {
                          if (selectedStatuses.contains(value)) {
                            selectedStatuses.remove(value);
                          } else {
                            selectedStatuses.add(value);
                          }
                        });
                      },
                    ),
                    _buildFilterChipForGrid<TaskStatus>(
                      '進行中',
                      TaskStatus.inProgress,
                      selectedStatuses.contains(TaskStatus.inProgress),
                      (value) {
                        setDialogState(() {
                          if (selectedStatuses.contains(value)) {
                            selectedStatuses.remove(value);
                          } else {
                            selectedStatuses.add(value);
                          }
                        });
                      },
                    ),
                    _buildFilterChipForGrid<TaskStatus>(
                      '完了',
                      TaskStatus.completed,
                      selectedStatuses.contains(TaskStatus.completed),
                      (value) {
                        setDialogState(() {
                          if (selectedStatuses.contains(value)) {
                            selectedStatuses.remove(value);
                          } else {
                            selectedStatuses.add(value);
                          }
                        });
                      },
                    ),
                    _buildFilterChipForGrid<TaskStatus>(
                      '取消',
                      TaskStatus.cancelled,
                      selectedStatuses.contains(TaskStatus.cancelled),
                      (value) {
                        setDialogState(() {
                          if (selectedStatuses.contains(value)) {
                            selectedStatuses.remove(value);
                          } else {
                            selectedStatuses.add(value);
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  '優先度',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChipForGrid<TaskPriority?>(
                      'すべて',
                      null,
                      selectedPriority == null,
                      (value) {
                        setDialogState(() {
                          selectedPriority = null;
                        });
                      },
                    ),
                    _buildFilterChipForGrid<TaskPriority>(
                      '低',
                      TaskPriority.low,
                      selectedPriority == TaskPriority.low,
                      (value) {
                        setDialogState(() {
                          selectedPriority = value;
                        });
                      },
                    ),
                    _buildFilterChipForGrid<TaskPriority>(
                      '中',
                      TaskPriority.medium,
                      selectedPriority == TaskPriority.medium,
                      (value) {
                        setDialogState(() {
                          selectedPriority = value;
                        });
                      },
                    ),
                    _buildFilterChipForGrid<TaskPriority>(
                      '高',
                      TaskPriority.high,
                      selectedPriority == TaskPriority.high,
                      (value) {
                        setDialogState(() {
                          selectedPriority = value;
                        });
                      },
                    ),
                    _buildFilterChipForGrid<TaskPriority>(
                      '緊急',
                      TaskPriority.urgent,
                      selectedPriority == TaskPriority.urgent,
                      (value) {
                        setDialogState(() {
                          selectedPriority = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterDueDateColors.clear();
                  _filterStatuses.clear();
                  _filterPriority = null;
                });
                Navigator.pop(context);
              },
              child: const Text('リセット'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterDueDateColors = selectedDueDateColors;
                  _filterStatuses = selectedStatuses;
                  _filterPriority = selectedPriority;
                });
                Navigator.pop(context);
              },
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipForGrid<T>(
    String label,
    T value,
    bool isSelected,
    ValueChanged<T> onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }
  @override
  Widget build(BuildContext context) {
    final WidgetRef ref = this.ref;
    final tasks = ref.watch(taskViewModelProvider);
    final now = DateTime.now();
    
    // フォント設定を取得（タスクグリッドビュー専用の設定）
    final fontSize = ref.watch(fontSizeProvider);
    final layoutSettings = ref.watch(taskProjectLayoutSettingsProvider);
    // タスクグリッドビュー専用のフォントサイズ設定を使用
    final titleFontSize = layoutSettings.titleFontSize;
    final memoFontSize = layoutSettings.memoFontSize;
    final descriptionFontSize = layoutSettings.descriptionFontSize;
    // フォントファミリーは全画面共通の設定を使用
    final titleFontFamily = ref.watch(titleFontFamilyProvider);
    final memoFontFamily = ref.watch(memoFontFamilyProvider);
    final descriptionFontFamily = ref.watch(descriptionFontFamilyProvider);
    
    // タスクをフィルタリング（複数フィルター適用）
    print('🔍 タスクグリッドビュー フィルター状態: _filterDueDateColors=$_filterDueDateColors, _filterStatuses=$_filterStatuses, _filterPriority=$_filterPriority');
    print('🔍 全タスク数: ${tasks.length}');
    final filteredTasks = tasks.where((task) {
      // 期限日の色分けフィルター（複数選択対応）
      if (_filterDueDateColors.isNotEmpty) {
        final taskDueDateColor = _getDueDateColorForFilter(task, now);
        if (!_filterDueDateColors.contains(taskDueDateColor)) {
        return false;
      }
      }
      
      // ステータスフィルター（複数選択対応）
      if (_filterStatuses.isNotEmpty) {
        if (!_filterStatuses.contains(task.status)) {
          return false;
        }
      }
      
      // 優先度フィルター
      if (_filterPriority != null) {
        if (task.priority != _filterPriority) {
          return false;
        }
      }
      
      // 検索フィルター
      if (_searchQuery.isNotEmpty) {
        final queryLower = _searchQuery.toLowerCase();
        if (!task.title.toLowerCase().contains(queryLower) &&
            (task.description == null || !task.description!.toLowerCase().contains(queryLower)) &&
            (task.assignedTo == null || !task.assignedTo!.toLowerCase().contains(queryLower)) &&
            (task.notes == null || !task.notes!.toLowerCase().contains(queryLower)) &&
            !task.tags.any((tag) => tag.toLowerCase().contains(queryLower))) {
          return false;
        }
      }
      
      return true;
    }).toList();
    print('🔍 フィルター後タスク数: ${filteredTasks.length}');
    
    // ピン留めタスクを先頭に、その後期限日順でソート（期限なしは最後）
    final sortedTasks = filteredTasks..sort((a, b) {
      // ピン留めの優先度を比較
      final aIsPinned = _pinnedTaskIds.contains(a.id);
      final bIsPinned = _pinnedTaskIds.contains(b.id);
      if (aIsPinned && !bIsPinned) return -1;
      if (!aIsPinned && bIsPinned) return 1;
      
      // 両方ピン留めまたは両方ピン留めでない場合、期限日でソート
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
          autofocus: false,
          child: FocusScope(
            autofocus: false,
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
                  // 選択モード時は選択数を表示
                  if (_isSelectionMode)
                    Text(
                      '${_selectedTaskIds.length}件選択中',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                  Text(
                    'タスク一覧',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                        fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 20) * fontSize,
                        fontFamily: titleFontFamily.isEmpty ? null : titleFontFamily,
                    ),
                  ),
                  const Spacer(),
                  if (_isSelectionMode) ...[
                    // 選択モード時のアクション
                    IconButton(
                      icon: Icon(_selectedTaskIds.length == sortedTasks.length 
                        ? Icons.deselect 
                        : Icons.select_all),
                      tooltip: _selectedTaskIds.length == sortedTasks.length 
                        ? '全解除' 
                        : '全選択',
                      onPressed: () => _toggleSelectAllForGrid(sortedTasks),
                    ),
                    // 一括操作メニューボタン
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: '一括操作',
                      enabled: !_selectedTaskIds.isEmpty,
                      onSelected: (value) async {
                        switch (value) {
                          case 'status':
                            _showBulkStatusMenuForGrid(context);
                            break;
                          case 'priority':
                            _showBulkPriorityMenuForGrid(context);
                            break;
                          case 'delete':
                            await _deleteSelectedTasksForGrid(context);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'status',
                          child: Row(
                    children: [
                              Icon(Icons.play_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text('ステータス変更'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'priority',
                          child: Row(
                            children: [
                              Icon(Icons.flag, size: 20),
                              SizedBox(width: 8),
                              Text('優先度変更'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('削除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: '選択モードを終了',
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedTaskIds.clear();
                        });
                      },
                      ),
                  ] else ...[
                    // 通常モード時のアクション
                    IconButton(
                      icon: const Icon(Icons.check_box_outline_blank),
                      tooltip: '一括選択モード',
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                        });
                      },
                      ),
                      const SizedBox(width: 8),
                    // フィルターダイアログボタン
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.filter_alt, size: 20),
                          if (_filterDueDateColors.isNotEmpty || _filterStatuses.isNotEmpty || _filterPriority != null)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 6,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                    ],
                  ),
                      tooltip: 'フィルター',
                      onPressed: () => _showFilterDialogForGrid(context, now),
                    ),
                  ],
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '閉じる',
                  ),
                ],
              ),
            ),
            // 検索バー（シンプルな実装）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'タスクを検索（タイトル・説明・タグ・依頼先）...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
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
                : layoutSettings.autoAdjustCardHeight
                    ? _buildAutoHeightGrid(
                        sortedTasks,
                        crossAxisCount,
                        cardWidth,
                        cardHeight,
                        layoutSettings.defaultGridSpacing,
                        now,
                        fontSize,
                        titleFontSize,
                        titleFontFamily,
                        memoFontSize,
                        memoFontFamily,
                        descriptionFontSize,
                        descriptionFontFamily,
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
                      
                      // カード背景色は期限日に基づいて色分け
                      final Color cardBg = _getCardBackgroundColor(task, now);
                      // ボーダー色も期限日に基づいて設定
                      final Color borderColor = _getCardBorderColor(task, now);

                      // ステータスバッジの色とテキスト
                      final statusBadge = _getTaskStatusBadgeForGrid(task.status);

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
                            if (_isSelectionMode) {
                              // 選択モード時はタップで選択切り替え
                              setState(() {
                                if (_selectedTaskIds.contains(task.id)) {
                                  _selectedTaskIds.remove(task.id);
                                } else {
                                  _selectedTaskIds.add(task.id);
                                }
                              });
                            } else {
                              // 通常モード時はタスクダイアログを開く
                            showDialog(
                              context: context,
                              builder: (context) => TaskDialog(task: task),
                              ).then((_) {
                                // タスクダイアログを閉じた時にタスクグリッドビューに戻る
                                // ダイアログが既に閉じられているため、何もしない
                              });
                            }
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
                                    // 選択モード時はチェックボックス、通常時はピン留めボタン
                                    if (_isSelectionMode)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4, top: 2),
                                        child: Checkbox(
                                          value: _selectedTaskIds.contains(task.id),
                                          onChanged: (_) {
                                            setState(() {
                                              if (_selectedTaskIds.contains(task.id)) {
                                                _selectedTaskIds.remove(task.id);
                                              } else {
                                                _selectedTaskIds.add(task.id);
                                              }
                                            });
                                          },
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      )
                                    else
                                      // ピン留めボタン
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4, top: 2),
                                        child: IconButton(
                                          icon: Icon(
                                            _pinnedTaskIds.contains(task.id)
                                                ? Icons.push_pin
                                                : Icons.push_pin_outlined,
                                            size: 16 * fontSize,
                                            color: _pinnedTaskIds.contains(task.id)
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.grey,
                                          ),
                                          tooltip: _pinnedTaskIds.contains(task.id) ? 'ピンを外す' : '上部にピン留め',
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                          onPressed: () => _togglePinTask(task.id),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14 * fontSize * titleFontSize,
                                          fontFamily: titleFontFamily.isEmpty ? null : titleFontFamily,
                                          color: _getTextColorForCardBackground(cardBg),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // 優先度表示（色と文字1文字）
                                    _buildPriorityIndicator(task.priority, fontSize),
                                    const SizedBox(width: 4),
                                    // 予定バッジ（カレンダーアイコン）
                                    _buildScheduleBadgeForGrid(task.id, fontSize),
                                    const SizedBox(width: 4),
                                    // ステータスバッジ（タスク管理画面と統一）
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6 * fontSize, vertical: 2 * fontSize),
                                      decoration: BoxDecoration(
                                        color: _getStatusBadgeBackgroundColor(statusBadge['color'] as Color),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _getStatusBadgeBorderColor(statusBadge['color'] as Color), width: 1.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            statusBadge['icon'] as IconData,
                                            size: 10 * fontSize,
                                            color: statusBadge['color'] as Color,
                                          ),
                                          SizedBox(width: 2 * fontSize),
                                          Text(
                                            statusBadge['text'] as String,
                                            style: TextStyle(
                                              color: statusBadge['color'] as Color,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 9 * fontSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // 期限（視認性を最大限確保: 白色背景 + 濃い色のテキスト）
                                if (task.dueDate != null) ...[
                                  SizedBox(height: 4 * fontSize),
                                  Builder(
                                    builder: (context) {
                                      // 期限日に応じた濃い色を決定（背景色に関係なく視認性を確保）
                                      final Color badgeColor;
                                      // 期限日の差を計算
                                      final difference = task.dueDate!.difference(now).inDays;
                                      if (difference < 0) {
                                        badgeColor = Colors.red.shade700; // 期限切れ
                                      } else if (difference == 0) {
                                        badgeColor = Colors.orange.shade700; // 今日が期限
                                      } else if (difference <= 3) {
                                        badgeColor = Colors.amber.shade700; // 3日以内
                                      } else {
                                        badgeColor = Colors.blue.shade700; // それ以外
                                      }
                                      
                                      return Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8 * fontSize, vertical: 5 * fontSize),
                                    decoration: BoxDecoration(
                                          color: Colors.white, // 常に白色背景で視認性を確保
                                      borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: badgeColor,
                                            width: 2, // 太いボーダーで強調
                                          ),
                                          boxShadow: [
                                            // 強い影でカード背景から視覚的に分離
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                            // 内側の影も追加して立体感を向上
                                            BoxShadow(
                                              color: badgeColor.withOpacity(0.1),
                                              blurRadius: 2,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                    ),
                                    child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                              size: 13 * fontSize,
                                              color: badgeColor, // 濃い色で視認性を確保
                                            ),
                                            SizedBox(width: 4 * fontSize),
                                            Text(
                                              DateFormat('MM/dd').format(task.dueDate!),
                                              style: TextStyle(
                                                color: badgeColor, // 濃い色で視認性を確保
                                                fontWeight: FontWeight.w800, // 太字
                                                fontSize: 12 * fontSize,
                                                // テキストシャドウは不要（白背景なので）
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ] else ...[
                                  // 期限未設定の場合はタスクリストビューと同じスタイルのバッジを表示
                                  SizedBox(height: 4 * fontSize),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8 * fontSize, vertical: 6 * fontSize),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50, // タスクリストビューと同じ背景色
                                      borderRadius: BorderRadius.circular(12 * fontSize), // タスクリストビューと同じ角丸
                                      border: Border.all(
                                        color: Colors.green.shade300, // タスクリストビューと同じボーダー色
                                        width: 2, // タスクリストビューと同じボーダー幅
                                      ),
                                        ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 13 * fontSize,
                                          color: Colors.green.shade900, // タスクリストビューと同じテキスト色
                                        ),
                                        SizedBox(width: 4 * fontSize),
                                        Text(
                                          '未設定',
                                          style: TextStyle(
                                            color: Colors.green.shade900, // タスクリストビューと同じテキスト色
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
                                // 本文（説明）
                                if (task.description != null && task.description!.isNotEmpty) ...[
                                  SizedBox(height: 4 * fontSize),
                                  _buildDescriptionWithTooltipGrid(
                                    task.description!,
                                    fontSize,
                                    descriptionFontSize,
                                    descriptionFontFamily,
                                    searchQuery: _searchQuery,
                                  ),
                                ],
                                // サブタスク進捗
                                if (task.hasSubTasks && task.totalSubTasksCount > 0) ...[
                                  SizedBox(height: 4 * fontSize),
                                  _buildSubTaskProgressWithTooltip(task, fontSize),
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
    );
  }

  /// 自動高さ調整対応のグリッドビューを構築
  Widget _buildAutoHeightGrid(
    List<TaskItem> tasks,
    int crossAxisCount,
    double cardWidth,
    double minCardHeight,
    double gridSpacing,
    DateTime now,
    double fontSize,
    double titleFontSize,
    String titleFontFamily,
    double memoFontSize,
    String memoFontFamily,
    double descriptionFontSize,
    String descriptionFontFamily,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 利用可能な幅を計算
        final availableWidth = constraints.maxWidth;
        final padding = gridSpacing * 0.75;
        final effectiveWidth = availableWidth - (padding * 2);
        final crossAxisSpacing = gridSpacing;
        final itemWidth = (effectiveWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Wrap(
            spacing: crossAxisSpacing,
            runSpacing: gridSpacing,
            alignment: WrapAlignment.start,
            children: tasks.map((task) {
              return SizedBox(
                width: itemWidth,
                child: _buildAutoHeightCard(
                  task,
                  itemWidth,
                  minCardHeight,
                  now,
                  fontSize,
                  titleFontSize,
                  titleFontFamily,
                  memoFontSize,
                  memoFontFamily,
                  descriptionFontSize,
                  descriptionFontFamily,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
  /// 自動高さ調整対応のカードを構築
  Widget _buildAutoHeightCard(
    TaskItem task,
    double cardWidth,
    double minCardHeight,
    DateTime now,
    double fontSize,
    double titleFontSize,
    String titleFontFamily,
    double memoFontSize,
    String memoFontFamily,
    double descriptionFontSize,
    String descriptionFontFamily,
  ) {
    // カードカラー（期限日に基づいた色分け）
    final Color cardBg = _getCardBackgroundColor(task, now);
    final Color borderColor = _getCardBorderColor(task, now);
    final statusBadge = _getTaskStatusBadgeForGrid(task.status);

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
          if (_isSelectionMode) {
            setState(() {
              if (_selectedTaskIds.contains(task.id)) {
                _selectedTaskIds.remove(task.id);
              } else {
                _selectedTaskIds.add(task.id);
              }
            });
          } else {
            showDialog(
              context: context,
              builder: (context) => TaskDialog(task: task),
            );
          }
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
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 4, top: 2),
                      child: Checkbox(
                        value: _selectedTaskIds.contains(task.id),
                        onChanged: (_) {
                          setState(() {
                            if (_selectedTaskIds.contains(task.id)) {
                              _selectedTaskIds.remove(task.id);
                            } else {
                              _selectedTaskIds.add(task.id);
                            }
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  else
                    // ピン留めボタン
                    Padding(
                      padding: const EdgeInsets.only(right: 4, top: 2),
                      child: IconButton(
                        icon: Icon(
                          _pinnedTaskIds.contains(task.id)
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: 16 * fontSize,
                          color: _pinnedTaskIds.contains(task.id)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        tooltip: _pinnedTaskIds.contains(task.id) ? 'ピンを外す' : '上部にピン留め',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () => _togglePinTask(task.id),
                      ),
                    ),
                  Expanded(
                    child: _searchQuery.isNotEmpty
                        ? HighlightedText(
                            text: task.title,
                            highlight: _searchQuery,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * fontSize * titleFontSize,
                              fontFamily: titleFontFamily.isEmpty ? null : titleFontFamily,
                              color: _getTextColorForCardBackground(cardBg),
                            ),
                            maxLines: null,
                            overflow: TextOverflow.visible,
                          )
                        : Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * fontSize * titleFontSize,
                              fontFamily: titleFontFamily.isEmpty ? null : titleFontFamily,
                              color: _getTextColorForCardBackground(cardBg),
                            ),
                            maxLines: null, // 自動高さ調整時は行数制限を緩和
                            overflow: TextOverflow.visible,
                          ),
                  ),
                  const SizedBox(width: 4),
                  // 優先度表示（色と文字1文字）
                  _buildPriorityIndicator(task.priority, fontSize),
                  const SizedBox(width: 4),
                  // 予定バッジ（カレンダーアイコン）
                  _buildScheduleBadgeForGrid(task.id, fontSize),
                  const SizedBox(width: 4),
                  // ステータスバッジ（タスク管理画面と統一）
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6 * fontSize, vertical: 2 * fontSize),
                    decoration: BoxDecoration(
                      color: _getStatusBadgeBackgroundColor(statusBadge['color'] as Color),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusBadgeBorderColor(statusBadge['color'] as Color), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusBadge['icon'] as IconData,
                          size: 10 * fontSize,
                          color: statusBadge['color'] as Color,
                        ),
                        SizedBox(width: 2 * fontSize),
                        Text(
                          statusBadge['text'] as String,
                          style: TextStyle(
                            color: statusBadge['color'] as Color,
                            fontWeight: FontWeight.w600,
                            fontSize: 9 * fontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 期限
              if (task.dueDate != null) ...[
                SizedBox(height: 4 * fontSize),
                Builder(
                  builder: (context) {
                    final Color badgeColor;
                    final difference = task.dueDate!.difference(now).inDays;
                    if (difference < 0) {
                      badgeColor = Colors.red.shade700;
                    } else if (difference == 0) {
                      badgeColor = Colors.orange.shade700;
                    } else if (difference <= 3) {
                      badgeColor = Colors.amber.shade700;
                    } else {
                      badgeColor = Colors.blue.shade700;
                    }
                    
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * fontSize, vertical: 5 * fontSize),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: badgeColor.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 13 * fontSize, color: badgeColor),
                          SizedBox(width: 4 * fontSize),
                          Text(
                            DateFormat('MM/dd').format(task.dueDate!),
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12 * fontSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else ...[
                SizedBox(height: 4 * fontSize),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8 * fontSize, vertical: 6 * fontSize),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12 * fontSize),
                    border: Border.all(color: Colors.green.shade300, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 13 * fontSize, color: Colors.green.shade900),
                      SizedBox(width: 4 * fontSize),
                      Text(
                        '未設定',
                        style: TextStyle(
                          color: Colors.green.shade900,
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
                        maxLines: null, // 自動高さ調整時は行数制限を緩和
                        overflow: TextOverflow.visible,
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
                        maxLines: null, // 自動高さ調整時は行数制限を緩和
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ],
              // 本文（説明）
              if (task.description != null && task.description!.isNotEmpty) ...[
                SizedBox(height: 4 * fontSize),
                _buildDescriptionWithTooltipGrid(
                  task.description!,
                  fontSize,
                  descriptionFontSize,
                  descriptionFontFamily,
                  searchQuery: _searchQuery,
                ),
              ],
              // サブタスク進捗
              if (task.hasSubTasks && task.totalSubTasksCount > 0) ...[
                SizedBox(height: 4 * fontSize),
                _buildSubTaskProgressWithTooltip(task, fontSize),
              ],
              // タグ
              if (task.tags.isNotEmpty) ...[
                SizedBox(height: 4 * fontSize),
                Wrap(
                  spacing: 2 * fontSize,
                  runSpacing: 2 * fontSize,
                  children: task.tags.map((tag) {
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
              // 関連リンク
              if (_hasValidLinks(task)) ...[
                SizedBox(height: 4 * fontSize),
                _buildRelatedLinksForGrid(task, fontSize, searchQuery: _searchQuery),
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

  /// カードの背景色を期限日に基づいて取得
  Color _getCardBackgroundColor(TaskItem task, DateTime now) {
    if (task.dueDate == null) {
      return Colors.green.shade50; // 期限未設定は緑
    }
    final difference = task.dueDate!.difference(now).inDays;
    if (difference < 0) {
      return Colors.red.shade50; // 期限切れ
    } else if (difference == 0) {
      return Colors.orange.shade50; // 今日が期限
    } else if (difference <= 3) {
      return Colors.amber.shade50; // 3日以内
    } else {
      return Colors.blue.shade50; // それ以外（青）
    }
  }

  /// カードのボーダー色を期限日に基づいて取得
  Color _getCardBorderColor(TaskItem task, DateTime now) {
    if (task.dueDate == null) {
      return Colors.green.shade300; // 期限未設定は緑
    }
    final difference = task.dueDate!.difference(now).inDays;
    if (difference < 0) {
      return Colors.red.shade300; // 期限切れ
    } else if (difference == 0) {
      return Colors.orange.shade300; // 今日が期限
    } else if (difference <= 3) {
      return Colors.amber.shade300; // 3日以内
    } else {
      return Colors.blue.shade300; // それ以外（青）
    }
  }

  /// フィルター用の期限日色を取得
  String? _getDueDateColorForFilter(TaskItem task, DateTime now) {
    if (task.dueDate == null) {
      return 'green'; // 期限未設定は緑
    }
    final difference = task.dueDate!.difference(now).inDays;
    if (difference < 0) {
      return 'red'; // 期限切れ
    } else if (difference == 0) {
      return 'orange'; // 今日が期限
    } else if (difference <= 3) {
      return 'amber'; // 3日以内
    } else {
      return 'blue'; // それ以外（青）
    }
  }

  /// バッジ背景色に対してコントラストの高いテキスト色を取得
  Color _getContrastTextColor(Color backgroundColor, Color borderColor) {
    // バッジの背景色は薄い色なので、常に濃い色や白色を使用してコントラストを確保
    // ボーダー色に基づいて適切なテキスト色を決定
    if (borderColor.value == Colors.red.value) {
      return Colors.red.shade900; // 濃い赤
    } else if (borderColor.value == Colors.orange.value) {
      return Colors.orange.shade900; // 濃いオレンジ
    } else if (borderColor.value == Colors.amber.value) {
      return Colors.amber.shade900; // 濃いアンバー
    } else if (borderColor.value == Colors.green.value) {
      return Colors.green.shade900; // 濃い緑
    } else if (borderColor.value == Colors.blue.value) {
      return Colors.blue.shade900; // 濃い青
    } else if (borderColor.value == Colors.grey.value) {
      return Colors.grey.shade900; // 濃いグレー
    } else {
      // その他の場合は黒を使用
      return Colors.black87;
    }
  }

  /// カード背景色に対して適切なコントラストのテキスト色を取得
  Color _getTextColorForCardBackground(Color backgroundColor) {
    // 背景色の明度を計算
    final luminance = backgroundColor.computeLuminance();
    
    // ダークモードかどうかを確認
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 背景が薄い色（明度が高い）の場合、濃いテキストを使用
    // 背景が濃い色（明度が低い）の場合、明るいテキストを使用
    if (isDarkMode) {
      // ダークモードの場合、背景が薄くても濃いテキストを使用
      // ただし、背景が非常に薄い場合は少し濃めにする
      if (luminance > 0.5) {
        return Colors.black87; // 薄い背景に対して濃いテキスト
      } else {
        return Colors.white; // 濃い背景に対して白テキスト
      }
    } else {
      // ライトモードの場合
      if (luminance > 0.5) {
        return Colors.black87; // 薄い背景に対して濃いテキスト
      } else {
        return Colors.white; // 濃い背景に対して白テキスト
      }
    }
  }

  /// ステータスバッジの背景色を取得（タスク管理画面と統一）
  Color _getStatusBadgeBackgroundColor(Color textColor) {
    // テキスト色に基づいて背景色を決定
    if (textColor == Colors.green.shade800) {
      return Colors.green.shade50;
    } else if (textColor == Colors.blue.shade800) {
      return Colors.blue.shade50;
    } else if (textColor == Colors.grey.shade800) {
      return Colors.grey.shade50;
    } else if (textColor == Colors.red.shade800) {
      return Colors.red.shade50;
    }
    return Colors.grey.shade50;
  }

  /// ステータスバッジのボーダー色を取得（タスク管理画面と統一）
  Color _getStatusBadgeBorderColor(Color textColor) {
    // テキスト色に基づいてボーダー色を決定
    if (textColor == Colors.green.shade800) {
      return Colors.green.shade300;
    } else if (textColor == Colors.blue.shade800) {
      return Colors.blue.shade300;
    } else if (textColor == Colors.grey.shade800) {
      return Colors.grey.shade300;
    } else if (textColor == Colors.red.shade800) {
      return Colors.red.shade300;
    }
    return Colors.grey.shade300;
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

  /// タスクのステータスバッジ情報を取得（グリッドビュー用）
  Map<String, dynamic> _getTaskStatusBadgeForGrid(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return {
          'icon': Icons.schedule,
          'text': '未着手',
          'color': Colors.green.shade800,
        };
      case TaskStatus.inProgress:
        return {
          'icon': Icons.play_arrow,
          'text': '進行中',
          'color': Colors.blue.shade800,
        };
      case TaskStatus.completed:
        return {
          'icon': Icons.check,
          'text': '完了',
          'color': Colors.grey.shade800,
        };
      case TaskStatus.cancelled:
        return {
          'icon': Icons.cancel,
          'text': 'キャンセル',
          'color': Colors.red.shade800,
        };
    }
  }

  /// タスクグリッドビュー用のサブタスク進捗表示（ツールチップ付き）
  Widget _buildSubTaskProgressWithTooltip(TaskItem task, double fontSize) {
    final tooltipContent = _buildSubTaskTooltipContent(task);

    return MouseRegion(
      cursor: SystemMouseCursors.help,
      child: Tooltip(
        message: tooltipContent,
        waitDuration: const Duration(milliseconds: 500),
        preferBelow: false,
        verticalOffset: 10,
        textStyle: const TextStyle(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
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
      ),
    );
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

  /// サブタスクのツールチップコンテンツを構築
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
    
    // 最大20個まで表示
    final displayCount = subTasks.length < 20 ? subTasks.length : 20;
    for (int i = 0; i < displayCount; i++) {
      final subTask = subTasks[i];
      final status = subTask.isCompleted ? '✓' : '×';
      final title = subTask.title.length > 30 
        ? '${subTask.title.substring(0, 30)}...' 
        : subTask.title;
      buffer.writeln('$status $title');
      
      // 説明がある場合は表示
      if (subTask.description != null && subTask.description!.isNotEmpty) {
        final desc = subTask.description!.length > 40 
          ? '  ${subTask.description!.substring(0, 40)}...' 
          : '  ${subTask.description!}';
        buffer.writeln(desc);
      }
    }
    
    if (subTasks.length > 20) {
      buffer.writeln('... 他${subTasks.length - 20}個');
    }
    
    return buffer.toString().trim();
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

  /// グリッドビュー用の本文表示（ツールチップなし）
  Widget _buildDescriptionWithTooltipGrid(String description, double fontSize, double descriptionFontSize, String descriptionFontFamily, {String searchQuery = ''}) {
    // UI設定から色を取得
    final descriptionColor = Color(ref.watch(descriptionTextColorProvider));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // タップで全文を表示するダイアログ（親のInkWellのonTapを呼ばない）
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('本文'),
            content: SingleChildScrollView(
              child: searchQuery.isNotEmpty
                  ? HighlightedText(
                      text: description,
                      highlight: searchQuery,
                    )
                  : Text(description),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: searchQuery.isNotEmpty
            ? HighlightedText(
                text: description,
                highlight: searchQuery,
                style: TextStyle(
                  color: descriptionColor, // UI設定から取得
                  fontSize: 10 * fontSize * descriptionFontSize,
                  fontWeight: FontWeight.w500,
                  fontFamily: descriptionFontFamily.isEmpty ? null : descriptionFontFamily,
                ),
                maxLines: null,
                overflow: TextOverflow.visible,
              )
            : Text(
                description,
                style: TextStyle(
                  color: descriptionColor, // UI設定から取得
                  fontSize: 10 * fontSize * descriptionFontSize,
                  fontWeight: FontWeight.w500,
                  fontFamily: descriptionFontFamily.isEmpty ? null : descriptionFontFamily,
                ),
                maxLines: null,
                overflow: TextOverflow.visible,
              ),
      ),
    );
  }

  /// 全選択/全解除（タスクグリッドビュー）
  void _toggleSelectAllForGrid(List<TaskItem> tasks) {
    setState(() {
      if (_selectedTaskIds.length == tasks.length) {
        _selectedTaskIds.clear();
      } else {
        _selectedTaskIds = tasks.map((task) => task.id).toSet();
      }
    });
  }
  /// 一括ステータス変更メニューを表示（タスクグリッドビュー）
  void _showBulkStatusMenuForGrid(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBulkStatusMenuItemForGrid(
              context,
              TaskStatus.pending,
              '未着手',
              Colors.green,
              Icons.pending,
            ),
            _buildBulkStatusMenuItemForGrid(
              context,
              TaskStatus.inProgress,
              '進行中',
              Colors.blue,
              Icons.play_circle_outline,
            ),
            _buildBulkStatusMenuItemForGrid(
              context,
              TaskStatus.completed,
              '完了',
              Colors.grey,
              Icons.check_circle,
            ),
            _buildBulkStatusMenuItemForGrid(
              context,
              TaskStatus.cancelled,
              '取消',
              Colors.red,
              Icons.cancel,
            ),
          ],
        ),
      ),
    );
  }

  /// 一括ステータスメニューアイテムを構築（タスクグリッドビュー）
  Widget _buildBulkStatusMenuItemForGrid(
    BuildContext context,
    TaskStatus status,
    String label,
    Color color,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        await _bulkChangeStatusForGrid(status);
      },
    );
  }

  /// 一括優先度変更メニューを表示（タスクグリッドビュー）
  void _showBulkPriorityMenuForGrid(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBulkPriorityMenuItemForGrid(
              context,
              TaskPriority.low,
              '低',
              Colors.grey,
            ),
            _buildBulkPriorityMenuItemForGrid(
              context,
              TaskPriority.medium,
              '中',
              Colors.orange,
            ),
            _buildBulkPriorityMenuItemForGrid(
              context,
              TaskPriority.high,
              '高',
              Colors.red,
            ),
            _buildBulkPriorityMenuItemForGrid(
              context,
              TaskPriority.urgent,
              '緊急',
              Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }

  /// 一括優先度メニューアイテムを構築（タスクグリッドビュー）
  Widget _buildBulkPriorityMenuItemForGrid(
    BuildContext context,
    TaskPriority priority,
    String label,
    Color color,
  ) {
    IconData icon;
    switch (priority) {
      case TaskPriority.low:
        icon = Icons.arrow_downward;
        break;
      case TaskPriority.medium:
        icon = Icons.remove;
        break;
      case TaskPriority.high:
        icon = Icons.arrow_upward;
        break;
      case TaskPriority.urgent:
        icon = Icons.priority_high;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        await _bulkChangePriorityForGrid(priority);
      },
    );
  }

  /// 選択されたタスクのステータスを一括変更（タスクグリッドビュー）
  Future<void> _bulkChangeStatusForGrid(TaskStatus status) async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final tasks = ref.read(taskViewModelProvider);
      final selectedTasks = tasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
      final updatedCount = selectedTasks.length;

      for (final task in selectedTasks) {
        if (status == TaskStatus.completed) {
          await taskViewModel.completeTask(task.id);
        } else if (status == TaskStatus.inProgress && task.status == TaskStatus.pending) {
          await taskViewModel.startTask(task.id);
        } else {
          final updatedTask = task.copyWith(
            status: status,
            completedAt: status == TaskStatus.completed ? DateTime.now() : null,
          );
          await taskViewModel.updateTask(updatedTask);
        }
      }

      // 選択をクリア
      setState(() {
        _selectedTaskIds.clear();
      });

      if (mounted) {
        SnackBarService.showSuccess(
          context,
          '$updatedCount件のタスクのステータスを変更しました',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'ステータス変更に失敗しました: $e');
      }
    }
  }

  /// 選択されたタスクの優先度を一括変更（タスクグリッドビュー）
  Future<void> _bulkChangePriorityForGrid(TaskPriority priority) async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final tasks = ref.read(taskViewModelProvider);
      final selectedTasks = tasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
      final updatedCount = selectedTasks.length;

      for (final task in selectedTasks) {
        final updatedTask = task.copyWith(priority: priority);
        await taskViewModel.updateTask(updatedTask);
      }

      // 選択をクリア
      setState(() {
        _selectedTaskIds.clear();
      });

      if (mounted) {
        SnackBarService.showSuccess(
          context,
          '$updatedCount件のタスクの優先度を変更しました',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, '優先度変更に失敗しました: $e');
      }
    }
  }

  /// 選択されたタスクを一括削除（タスクグリッドビュー）
  Future<void> _deleteSelectedTasksForGrid(BuildContext context) async {
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

  /// 優先度表示（色と文字1文字）を構築
  Widget _buildPriorityIndicator(TaskPriority priority, double fontSize) {
    final priorityInfo = _getPriorityInfo(priority);
    return Container(
      width: 16 * fontSize,
      height: 16 * fontSize,
      decoration: BoxDecoration(
        color: priorityInfo['color'] as Color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          priorityInfo['text'] as String,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10 * fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 優先度情報を取得
  Map<String, dynamic> _getPriorityInfo(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return {'color': Colors.green, 'text': '低'};
      case TaskPriority.medium:
        return {'color': Colors.orange, 'text': '中'};
      case TaskPriority.high:
        return {'color': Colors.red, 'text': '高'};
      case TaskPriority.urgent:
        return {'color': Colors.purple, 'text': '緊'};
    }
  }

  /// グリッドビュー用の予定バッジ（カレンダーアイコン、ホバーで予定リスト表示）
  Widget _buildScheduleBadgeForGrid(String taskId, double fontSize) {
    final schedules = ref.watch(scheduleViewModelProvider);
    final taskSchedules = schedules.where((s) => s.taskId == taskId).toList();
    
    if (taskSchedules.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 日時昇順でソート
    taskSchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    
    // ツールチップコンテンツを生成
    final tooltipContent = _buildScheduleTooltipContent(taskSchedules);
    
    return MouseRegion(
      cursor: SystemMouseCursors.help,
      child: Tooltip(
        message: tooltipContent,
        waitDuration: const Duration(milliseconds: 500),
        preferBelow: false,
        verticalOffset: 10,
        textStyle: const TextStyle(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.calendar_today,
          size: 16 * fontSize,
          color: Colors.orange.shade700,
        ),
      ),
    );
  }

  /// 予定ツールチップのコンテンツを生成
  String _buildScheduleTooltipContent(List<ScheduleItem> schedules) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('MM/dd');
    final timeFormat = DateFormat('HH:mm');
    
    for (final schedule in schedules) {
      final date = dateFormat.format(schedule.startDateTime);
      final time = timeFormat.format(schedule.startDateTime);
      final endTime = schedule.endDateTime != null
          ? ' - ${timeFormat.format(schedule.endDateTime!)}'
          : '';
      final location = schedule.location != null && schedule.location!.isNotEmpty
          ? ' @ ${schedule.location}'
          : '';
      
      buffer.writeln('$date $time$endTime$location');
      buffer.writeln('  ${schedule.title}');
      if (buffer.length > 0) {
        buffer.writeln('');
      }
    }
    
    return buffer.toString().trim();
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