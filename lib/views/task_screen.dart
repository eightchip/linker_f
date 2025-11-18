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
import 'dart:convert';
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
import '../services/backup_service.dart';
import '../repositories/link_repository.dart';
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
import '../widgets/shortcut_help_dialog.dart';
import 'help_center_screen.dart';

// 検索候補の種類
enum _SuggestionType {
  history,
  title,
  tag,
  description,
}

// 検索候補データクラス
class _SearchSuggestion {
  final String text;
  final _SuggestionType type;
  final String? subtitle;

  _SearchSuggestion({
    required this.text,
    required this.type,
    this.subtitle,
  });
}

// ショートカットキー用のIntentクラス
class _ToggleHeaderIntent extends Intent {
  const _ToggleHeaderIntent();
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

class _ToggleDetailIntent extends Intent {
  const _ToggleDetailIntent();
}

class _ToggleListViewModeIntent extends Intent {
  const _ToggleListViewModeIntent();
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

// リストビュー表示モード
enum ListViewMode {
  compact,   // コンパクトモード（一覧性重視）
  standard,  // 標準モード（現在の実装）
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
  ListViewMode _listViewMode = ListViewMode.standard; // リストビュー表示モード（デフォルトは標準）
  int _compactGridColumns = 4; // コンパクトモードのグリッド列数（デフォルト4列）
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
  List<_SearchSuggestion> _searchSuggestions = [];
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
    _settingsService = SettingsService.instance;
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();

    _searchQuery = '';
    
    // 検索履歴を読み込み
    _loadSearchHistory();
    // ピン留めを読み込み
    _loadPinnedTasks();
    // 保存されたフィルターを読み込み
    _loadSavedFilterPresets();
    // カスタム順序を読み込み
    _loadCustomTaskOrder();
    // リストビュー表示モードを読み込み
    _loadListViewMode();
    
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

    final deletedCount = _selectedTaskIds.length;

    // 大量削除の場合は操作前バックアップを実行（10件以上）
    if (deletedCount >= 10) {
      try {
        final settingsService = SettingsService.instance;
        final linkRepository = LinkRepository.instance;
        final backupService = BackupService(
          linkRepository: linkRepository,
          settingsService: settingsService,
        );
        
        await backupService.performPreOperationBackup(
          operationName: 'bulk_delete',
          itemCount: deletedCount,
          abortOnFailure: false, // バックアップ失敗でも続行
        );
        
        if (mounted) {
          SnackBarService.showInfo(
            context,
            'バックアップを実行しました。${deletedCount}件のタスクを削除します...',
          );
        }
      } catch (e) {
        // バックアップエラーは警告のみ表示して続行
        if (mounted) {
          SnackBarService.showWarning(
            context,
            'バックアップに失敗しましたが、削除を続行します: $e',
          );
        }
      }
    }

    final confirmed = await UnifiedDialogHelper.showDeleteConfirmDialog(
      context,
      title: '確認',
      message: '選択した${deletedCount}件のタスクを削除しますか？',
      confirmText: '削除',
      cancelText: 'キャンセル',
    );

    if (confirmed == true) {
      try {
        final taskViewModel = ref.read(taskViewModelProvider.notifier);
      
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

  /// 選択されたタスクを結合
  Future<void> _mergeSelectedTasks(BuildContext context) async {
    if (_selectedTaskIds.length < 2) {
      SnackBarService.showWarning(context, '2つ以上のタスクを選択してください');
      return;
    }

    try {
      final tasks = ref.read(taskViewModelProvider);
      final selectedTasks = _selectedTaskIds
          .map((id) => tasks.firstWhere((t) => t.id == id))
          .toList();

      // 結合先タスクを選択するダイアログを表示
      final targetTask = await showDialog<TaskItem>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('タスクを結合'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '結合先のタスクを選択してください：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      return ListTile(
                        title: Text(task.title),
                        subtitle: task.description != null && task.description!.isNotEmpty
                            ? Text(
                                task.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        leading: Radio<TaskItem>(
                          value: task,
                          groupValue: null,
                          onChanged: (value) => Navigator.pop(context, task),
                        ),
                        onTap: () => Navigator.pop(context, task),
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
          ],
        ),
      );

      if (targetTask == null) return;

      // 結合元タスクIDを取得（結合先を除く）
      final sourceTaskIds = selectedTasks
          .where((t) => t.id != targetTask.id)
          .map((t) => t.id)
          .toList();

      if (sourceTaskIds.isEmpty) {
        SnackBarService.showWarning(context, '結合元のタスクがありません');
        return;
      }

      // 操作前バックアップを実行（タスク結合は重要な操作）
      try {
        final settingsService = SettingsService.instance;
        final linkRepository = LinkRepository.instance;
        final backupService = BackupService(
          linkRepository: linkRepository,
          settingsService: settingsService,
        );
        
        await backupService.performPreOperationBackup(
          operationName: 'task_merge',
          itemCount: sourceTaskIds.length + 1,
          abortOnFailure: false, // バックアップ失敗でも続行
        );
        
        if (mounted) {
          SnackBarService.showInfo(
            context,
            'バックアップを実行しました。タスク結合を実行します...',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarService.showWarning(
            context,
            'バックアップに失敗しましたが、結合を続行します: $e',
          );
        }
      }

      // 確認ダイアログ
      final confirmed = await UnifiedDialogHelper.showDeleteConfirmDialog(
        context,
        title: 'タスクを結合',
        message: '「${targetTask.title}」に${sourceTaskIds.length}件のタスクを結合しますか？\n\n'
            '結合元タスクの予定、サブタスク、メモ、リンク、タグが統合されます。\n'
            '結合元タスクは完了状態になります。',
        confirmText: '結合',
        cancelText: 'キャンセル',
      );

      if (confirmed != true) return;

      // マージを実行
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      await taskViewModel.mergeTasks(
        targetTaskId: targetTask.id,
        sourceTaskIds: sourceTaskIds,
        deleteSourceTasks: false, // 完了状態にする
      );

      // 選択モードを解除
      setState(() {
        _selectedTaskIds.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        SnackBarService.showSuccess(
          context,
          '${sourceTaskIds.length + 1}件のタスクを結合しました',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'タスク結合に失敗しました: $e');
      }
    }
  }

  /// 一括リンク割り当てダイアログを表示
  void _showBulkLinkDialog(BuildContext context) {
    String? selectedLinkId;
    String operationMode = 'add'; // 'add', 'remove', 'replace'
    
    // 利用可能なリンクを取得
    final linkViewModel = ref.read(linkViewModelProvider);
    final allLinks = <LinkItem>[];
    for (final group in linkViewModel.groups) {
      allLinks.addAll(group.items);
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('リンクを一括割り当て'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 操作モード選択
                RadioListTile<String>(
                  title: const Text('追加'),
                  subtitle: const Text('既存のリンクに追加します'),
                  value: 'add',
                  groupValue: operationMode,
                  onChanged: (value) {
                    setDialogState(() {
                      operationMode = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('削除'),
                  subtitle: const Text('指定したリンクを削除します'),
                  value: 'remove',
                  groupValue: operationMode,
                  onChanged: (value) {
                    setDialogState(() {
                      operationMode = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('置換'),
                  subtitle: const Text('既存のリンクを全て置き換えます'),
                  value: 'replace',
                  groupValue: operationMode,
                  onChanged: (value) {
                    setDialogState(() {
                      operationMode = value!;
                    });
                  },
                ),
                const Divider(),
                // リンク選択
                if (allLinks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('利用可能なリンクがありません'),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allLinks.length,
                      itemBuilder: (context, index) {
                        final link = allLinks[index];
                        return RadioListTile<String>(
                          title: Text(link.label),
                          subtitle: Text(
                            link.path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: link.id,
                          groupValue: selectedLinkId,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedLinkId = value;
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: selectedLinkId != null
                  ? () async {
                      Navigator.of(context).pop();
                      await _bulkChangeLink(selectedLinkId!, operation: operationMode);
                    }
                  : null,
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }

  /// 選択されたタスクのリンクを一括変更
  Future<void> _bulkChangeLink(String linkId, {String operation = 'add'}) async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final tasks = ref.read(taskViewModelProvider);
      final selectedTasks = tasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
      final updatedCount = selectedTasks.length;

      for (final task in selectedTasks) {
        List<String> updatedLinkIds;
        final currentLinkIds = task.relatedLinkIds.isNotEmpty
            ? List<String>.from(task.relatedLinkIds)
            : (task.relatedLinkId != null && task.relatedLinkId!.isNotEmpty
                ? [task.relatedLinkId!]
                : []);
        
        switch (operation) {
          case 'add':
            // 追加：既存のリンクに追加
            if (!currentLinkIds.contains(linkId)) {
              updatedLinkIds = <String>[...currentLinkIds, linkId];
            } else {
              updatedLinkIds = List<String>.from(currentLinkIds);
            }
            break;
          case 'remove':
            // 削除：指定したリンクを削除
            updatedLinkIds = List<String>.from(currentLinkIds.where((id) => id != linkId));
            break;
          case 'replace':
            // 置換：既存のリンクを全て置き換え
            updatedLinkIds = [linkId];
            break;
          default:
            updatedLinkIds = List<String>.from(currentLinkIds);
        }
        
        final updatedTask = task.copyWith(
          relatedLinkIds: updatedLinkIds,
          relatedLinkId: updatedLinkIds.isNotEmpty ? updatedLinkIds[0] : null,
        );
        await taskViewModel.updateTask(updatedTask);
      }

      // 選択をクリア
      setState(() {
        _selectedTaskIds.clear();
      });

      if (mounted) {
        String message;
        switch (operation) {
          case 'add':
            message = '$updatedCount件のタスクにリンクを追加しました';
            break;
          case 'remove':
            message = '$updatedCount件のタスクからリンクを削除しました';
            break;
          case 'replace':
            message = '$updatedCount件のタスクのリンクを置き換えました';
            break;
          default:
            message = '$updatedCount件のタスクのリンクを変更しました';
        }
        SnackBarService.showSuccess(context, message);
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'リンク割り当てに失敗しました: $e');
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
  /// 一括タグ変更ダイアログを表示（拡張版）
  void _showBulkTagsDialog(BuildContext context) {
    final tagController = TextEditingController();
    String operationMode = 'add'; // 'add', 'remove', 'replace'
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('タグを一括操作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 操作モード選択
              RadioListTile<String>(
                title: const Text('追加'),
                subtitle: const Text('既存のタグに追加します'),
                value: 'add',
                groupValue: operationMode,
                onChanged: (value) {
                  setDialogState(() {
                    operationMode = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('削除'),
                subtitle: const Text('指定したタグを削除します'),
                value: 'remove',
                groupValue: operationMode,
                onChanged: (value) {
                  setDialogState(() {
                    operationMode = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('置換'),
                subtitle: const Text('既存のタグを全て置き換えます'),
                value: 'replace',
                groupValue: operationMode,
                onChanged: (value) {
                  setDialogState(() {
                    operationMode = value!;
                  });
                },
              ),
              const Divider(),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(
                  labelText: 'タグ（カンマ区切り）',
                  hintText: '例: 緊急,重要,プロジェクトA',
                ),
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
                await _bulkChangeTags(tags, operation: operationMode);
              },
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }
  /// 選択されたタスクのタグを一括変更（拡張版）
  Future<void> _bulkChangeTags(List<String> tags, {String operation = 'add'}) async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final tasks = ref.read(taskViewModelProvider);
      final selectedTasks = tasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
      final updatedCount = selectedTasks.length;

      for (final task in selectedTasks) {
        List<String> updatedTags;
        final currentTags = task.tags ?? [];
        
        switch (operation) {
          case 'add':
            // 追加：既存のタグに追加
            updatedTags = [...currentTags, ...tags].toSet().toList();
            break;
          case 'remove':
            // 削除：指定したタグを削除
            updatedTags = currentTags.where((tag) => !tags.contains(tag)).toList();
            break;
          case 'replace':
            // 置換：既存のタグを全て置き換え
            updatedTags = tags;
            break;
          default:
            updatedTags = currentTags;
        }
        
        final updatedTask = task.copyWith(tags: updatedTags);
        await taskViewModel.updateTask(updatedTask);
      }

      // 選択をクリア
      setState(() {
        _selectedTaskIds.clear();
      });

      if (mounted) {
        String message;
        switch (operation) {
          case 'add':
            message = '$updatedCount件のタスクにタグを追加しました';
            break;
          case 'remove':
            message = '$updatedCount件のタスクからタグを削除しました';
            break;
          case 'replace':
            message = '$updatedCount件のタスクのタグを置き換えました';
            break;
          default:
            message = '$updatedCount件のタスクのタグを変更しました';
        }
        SnackBarService.showSuccess(context, message);
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
    // TaskViewModelの作成を強制
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    final tasks = ref.watch(taskViewModelProvider);
    final statistics = taskViewModel.getTaskStatistics();
    
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

    // 画面が表示されたときに確実にフォーカスを復元
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreFocusIfNeeded();
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final titleScale = ref.watch(titleFontSizeProvider);
    final appBarTitleFontSize = (screenWidth < 600 ? 16.0 : 22.0) * titleScale;

    return KeyboardShortcutWidget(
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          // ショートカットキーを定義（フォーカスに依存しない）
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH): const _ToggleHeaderIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _ShowTaskDialogIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): const _ToggleSelectionModeIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyE): const _ExportCsvIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS): const _ShowSettingsIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG): const _ShowGroupMenuIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyT): const _ShowTaskTemplateIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const _ShowScheduleIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _NavigateHomeIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowRight): const _ShowPopupMenuIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): const _FocusMenuIntent(),
          LogicalKeySet(LogicalKeyboardKey.f1): const _ShowShortcutHelpIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): const _ToggleDetailIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX): const _ToggleListViewModeIntent(),
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
            _ToggleDetailIntent: CallbackAction<_ToggleDetailIntent>(
              onInvoke: (_) {
                // Ctrl+Z: 詳細トグル（すべて詳細表示/非表示）
                final focused = FocusManager.instance.primaryFocus;
                if (focused?.context?.widget is! EditableText) {
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
                }
                _restoreFocusIfNeeded();
                return null;
              },
            ),
            _ToggleListViewModeIntent: CallbackAction<_ToggleListViewModeIntent>(
              onInvoke: (_) {
                // Ctrl+X: コンパクト⇔標準の切り替え
                final focused = FocusManager.instance.primaryFocus;
                if (focused?.context?.widget is! EditableText) {
                  setState(() {
                    _listViewMode = _listViewMode == ListViewMode.compact 
                        ? ListViewMode.standard 
                        : ListViewMode.compact;
                    _saveListViewMode();
                  });
                }
                _restoreFocusIfNeeded();
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
                    Text(
                      'タスク管理',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: appBarTitleFontSize,
                      ),
                    ),
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
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'ショートカットキー (F1)',
                onPressed: () => _showShortcutHelp(context),
                color: Theme.of(context).colorScheme.primary,
              ),
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
                case 'link':
                  _showBulkLinkDialog(context);
                  break;
                case 'merge':
                  await _mergeSelectedTasks(context);
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
                    Text('タグを操作'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'link',
                child: Row(
                  children: [
                    Icon(Icons.link, size: 20),
                    SizedBox(width: 8),
                    Text('リンクを割り当て'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'merge',
                enabled: _selectedTaskIds.length >= 2,
                child: Row(
                  children: [
                    Icon(
                      Icons.merge_type,
                      size: 20,
                      color: _selectedTaskIds.length >= 2 ? null : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'タスクを結合',
                      style: TextStyle(
                        color: _selectedTaskIds.length >= 2 ? null : Colors.grey,
                      ),
                    ),
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
            IconButton(
              icon: const Icon(Icons.help_outline),
              color: Theme.of(context).colorScheme.primary,
              tooltip: 'ショートカットキー (F1)',
              onPressed: () => _showShortcutHelp(context),
            ),
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
            // スケジュール一覧
              PopupMenuItem(
              value: 'schedule',
                child: Row(
                  children: [
                  Icon(Icons.calendar_month, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                const Text('スケジュール一覧 (Ctrl+S)'),
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
    final total = statistics['total'] ?? 0;
    final pending = statistics['pending'] ?? 0;
    final inProgress = statistics['inProgress'] ?? 0;
    final completed = statistics['completed'] ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // 左側: 統計情報（コンパクト・狭く）
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildStatItem('総', total, Icons.list),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildStatItem(
                  '未',
                  pending,
                  Icons.radio_button_unchecked,
                  Colors.grey,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildStatItem(
                  '進',
                  inProgress,
                  Icons.pending,
                  Colors.blue,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildStatItem(
                  '完',
                  completed,
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          // 一括詳細トグルボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
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
          
          // 右側: 検索とフィルター（余白を削減）
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 8),
                // 強化された検索バー（幅を広く）
                Expanded(
                  child: Builder(
                    builder: (context) {
                      print('TextField構築時: _searchFocusNode.hasFocus=${_searchFocusNode.hasFocus}');
                      return Focus(
                        focusNode: _searchFocusNode,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                            setState(() {
                              _showSearchSuggestions = false;
                            });
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                        key: const ValueKey('task_search_field'),
                        controller: _searchController,                 // ← controller を使う
                        textInputAction: TextInputAction.search,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
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
                                      _showSearchSuggestions = false;
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
                      ),
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
                    switch (value) {
                      case 'save':
                        _showSaveFilterDialog();
                        break;
                      case 'load':
                        _showLoadFilterDialog();
                        break;
                      case 'quick_urgent':
                        _applyQuickFilter('urgent');
                        break;
                      case 'quick_today':
                        _applyQuickFilter('today');
                        break;
                      case 'quick_pending':
                        _applyQuickFilter('pending');
                        break;
                      case 'quick_in_progress':
                        _applyQuickFilter('in_progress');
                        break;
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
                          Text('フィルター管理'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'quick_urgent',
                      child: Row(
                        children: [
                          Icon(Icons.priority_high, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('緊急タスク'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'quick_today',
                      child: Row(
                        children: [
                          Icon(Icons.today, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('今日のタスク'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'quick_pending',
                      child: Row(
                        children: [
                          Icon(Icons.pending, size: 20, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('未着手タスク'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'quick_in_progress',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, size: 20, color: Colors.green),
                          SizedBox(width: 8),
                          Text('進行中タスク'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: AppSpacing.sm),
                
                // リストビュー表示モード切り替えボタン
                ToggleButtons(
                  isSelected: [
                    _listViewMode == ListViewMode.compact,
                    _listViewMode == ListViewMode.standard,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _listViewMode = index == 0 ? ListViewMode.compact : ListViewMode.standard;
                      _saveListViewMode();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 70,
                  ),
                  children: [
                    Tooltip(
                      message: 'カードビュー',
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_headline, size: 16),
                            SizedBox(width: 4),
                            Text('カ', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'リストビュー',
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_list, size: 16),
                            SizedBox(width: 4),
                            Text('リ', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // コンパクトモードの列数選択（コンパクトモード時のみ表示）
                if (_listViewMode == ListViewMode.compact) ...[
                  const SizedBox(width: AppSpacing.sm),
                  PopupMenuButton<int>(
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_view, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_compactGridColumns}列',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    tooltip: 'グリッド列数を変更',
                    onSelected: (value) {
                      setState(() {
                        _compactGridColumns = value;
                        _saveListViewMode();
                      });
                    },
                    itemBuilder: (context) => [
                      for (int i = 2; i <= 8; i++)
                        PopupMenuItem<int>(
                          value: i,
                          child: Row(
                            children: [
                              if (_compactGridColumns == i)
                                const Icon(Icons.check, size: 16, color: Colors.green),
                              if (_compactGridColumns == i) const SizedBox(width: 8),
                              Text('$i列'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                
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
    // ラベルを展開（「完」→「完了」など）
    String fullLabel = label;
    if (label == '総') fullLabel = '総タスク';
    else if (label == '未') fullLabel = '未着手';
    else if (label == '進') fullLabel = '進行中';
    else if (label == '完') fullLabel = '完了';
    
    return Tooltip(
      message: count == 0 ? '$fullLabel: 0件' : '$fullLabel: $count件（タップで詳細表示）',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => _showStatisticsDetail(fullLabel, count),
        borderRadius: BorderRadius.circular(8),
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
            Icon(icon, color: count == 0 ? Colors.grey : color, size: 16), // アイコンサイズを小さく
        const SizedBox(height: 2),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: count == 0 ? Colors.grey : color,
            fontWeight: FontWeight.bold,
            fontSize: 13, // フォントサイズを小さく
          ),
        ),
        Text(
          label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 9, // フォントサイズを小さく
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
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final accentColor = colorScheme.primary;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 64),
          backgroundColor: colorScheme.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    color: accentColor.withOpacity(0.08),
                  ),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$label',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count件のタスク',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filteredTasks.isEmpty
                      ? const Center(child: Text('該当するタスクがありません'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: filteredTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final dueDate = task.dueDate;
                            final isOverdue = dueDate != null &&
                                dueDate.isBefore(DateTime.now()) &&
                                task.status != TaskStatus.completed;
                            final dueText = dueDate != null
                                ? DateFormat('yyyy/MM/dd').format(dueDate)
                                : '未設定';
                            final dueColor = dueDate == null
                                ? Colors.grey
                                : isOverdue
                                    ? Colors.red.shade600
                                    : Colors.blue.shade600;

                            return Material(
                              color: colorScheme.surface,
                              elevation: 0,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              task.title,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: dueColor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: dueColor.withOpacity(0.3)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.event,
                                                        size: 14,
                                                        color: dueColor,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '期限: $dueText',
                                                        style: TextStyle(
                                                          color: dueColor,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                _buildStatusChip(task.status),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: colorScheme.outline),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('閉じる'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    // フィルターが適用されているかチェック
    final hasActiveFilters = !_filterStatuses.contains('all') || 
                             _filterStatuses.length > 1 ||
                             _filterPriority != 'all' ||
                             _searchQuery.isNotEmpty;
    
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
        // クリアボタン（フィルターが適用されている場合のみ表示）
        if (hasActiveFilters) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('クリア', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
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
    // 表示モードによって切り替え
    if (_listViewMode == ListViewMode.compact) {
      return _buildCompactTaskTile(task, isSelected, reorderIndex: reorderIndex);
    } else {
      return _buildStandardTaskTile(task, isSelected, reorderIndex: reorderIndex);
    }
  }

  /// コンパクトモード用のタスクListTileを構築（一覧性重視）
  Widget _buildCompactTaskTile(TaskItem task, bool isSelected, {int? reorderIndex}) {
    final bool hasSubTaskBadge = task.hasSubTasks || task.totalSubTasksCount > 0;
    final relatedLinks = _getRelatedLinks(task);
    final hasValidLinks = _hasValidLinks(task);
    final expandedLinksKey = 'compact_links_${task.id}';
    final isLinksExpanded = _expandedTaskIds.contains(expandedLinksKey);
    
    // UIカスタマイズ設定を取得
    final uiState = ref.watch(uiCustomizationProvider);
    
    return ListTile(
      onTap: null, // ListTileのデフォルトのタップ動作を無効化
      dense: true, // コンパクト表示
      minVerticalPadding: 0,
      contentPadding: EdgeInsets.symmetric(
        horizontal: uiState.cardPadding * 0.5, 
        vertical: uiState.cardPadding * 0.25
      ), // パディングを最小限に
      leading: _isSelectionMode 
        ? Checkbox(
            value: isSelected,
            onChanged: (_) => _toggleTaskSelection(task.id),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ドラッグハンドル（並び替え可能な場合のみ表示）
              if (reorderIndex != null && (_sortOrders.isEmpty || _sortOrders[0]['field'] == 'custom'))
                ReorderableDragStartListener(
                  index: reorderIndex!,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              // ピン留めアイコン（小さめ）
              IconButton(
                icon: Icon(
                  _pinnedTaskIds.contains(task.id)
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                  size: 16,
                  color: _pinnedTaskIds.contains(task.id)
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                ),
                tooltip: _pinnedTaskIds.contains(task.id) ? 'ピンを外す' : '上部にピン留め',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => _togglePinTask(task.id),
              ),
              const SizedBox(width: 4),
              // 期限日バッジ（小さめ）
              _buildCompactDeadlineIndicator(task),
            ],
          ),
      title: Row(
        children: [
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
                      fontSize: 14 * ref.watch(titleFontSizeProvider) * 0.9, // フォントサイズを0.9倍に
                      fontWeight: FontWeight.w500,
                      fontFamily: ref.watch(titleFontFamilyProvider).isEmpty 
                          ? null 
                          : ref.watch(titleFontFamilyProvider),
                    ),
                  )
                : Tooltip(
                    message: _buildCompactTooltipContent(task), // ホバー時ツールチップ
                    child: Text(
                      task.title,
                      style: TextStyle(
                        color: _getTaskTitleColor(),
                        decoration: task.status == TaskStatus.completed 
                            ? TextDecoration.lineThrough 
                            : null,
                        fontSize: 14 * ref.watch(titleFontSizeProvider) * 0.9, // フォントサイズを0.9倍に
                        fontWeight: FontWeight.w500,
                        fontFamily: ref.watch(titleFontFamilyProvider).isEmpty 
                            ? null 
                            : ref.watch(titleFontFamilyProvider),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          if (task.isTeamTask) ...[
            const SizedBox(width: 4),
            Icon(Icons.group, size: 14, color: Colors.blue[700]),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // リンク表示（アコーディオン）
          if (hasValidLinks && relatedLinks.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildCompactLinksDisplay(task, relatedLinks, isLinksExpanded, expandedLinksKey),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 予定バッジ（ツールチップ付き）
          _buildScheduleBadgeCompact(task.id),
          const SizedBox(width: 4),
          // リマインダーアイコン（小さめ）
          if (task.reminderTime != null)
            Icon(Icons.notifications_active, color: Colors.orange, size: 16),
          if (task.reminderTime != null) const SizedBox(width: 4),
          // ステータスバッジ（コンパクト版）
          _buildCompactStatusBadge(task),
          const SizedBox(width: 4),
          // 優先度インジケーター（小さめのアイコンのみ）
          _buildCompactPriorityIndicator(task),
          const SizedBox(width: 4),
          // サブタスクバッジ（小さめ・クリック可能）
          if (hasSubTaskBadge)
            GestureDetector(
              onTap: () {
                // サブタスクダイアログを開く
                showDialog(
                  context: context,
                  builder: (context) => SubTaskDialog(
                    parentTaskId: task.id,
                    parentTaskTitle: task.title,
                  ),
                ).then((_) {
                  setState(() {});
                });
              },
              child: Tooltip(
                message: _buildSubTaskTooltipContent(task),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.completedSubTasksCount == task.totalSubTasksCount 
                      ? Colors.green.shade600 
                      : Colors.red.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${task.completedSubTasksCount}/${task.totalSubTasksCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// コンパクトモード用の期限日バッジ（小さめ）
  Widget _buildCompactDeadlineIndicator(TaskItem task) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData icon;
    
    if (task.dueDate == null) {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade900;
      borderColor = Colors.green.shade300;
      icon = Icons.schedule;
    } else {
      final now = DateTime.now();
      final dueDate = task.dueDate!;
      final difference = dueDate.difference(now).inDays;
      
      if (difference < 0) {
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        borderColor = Colors.red.shade300;
        icon = Icons.warning;
      } else if (difference == 0) {
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        borderColor = Colors.orange.shade300;
        icon = Icons.today;
      } else if (difference <= 3) {
        backgroundColor = Colors.amber.shade50;
        textColor = Colors.amber.shade900;
        borderColor = Colors.amber.shade300;
        icon = Icons.calendar_today;
      } else {
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade900;
        borderColor = Colors.blue.shade300;
        icon = Icons.calendar_today;
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 12),
          const SizedBox(width: 3),
          Text(
            task.dueDate != null 
              ? _getRemainingDaysText(task.dueDate!)
              : '未',
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// コンパクトモード用のステータスバッジ（クリック可能）
  Widget _buildCompactStatusBadge(TaskItem task) {
    Map<String, dynamic> statusBadge;
    switch (task.status) {
      case TaskStatus.pending:
        statusBadge = {
          'icon': Icons.schedule,
          'text': '未',
          'color': Colors.green.shade800,
        };
        break;
      case TaskStatus.inProgress:
        statusBadge = {
          'icon': Icons.play_arrow,
          'text': '中',
          'color': Colors.blue.shade800,
        };
        break;
      case TaskStatus.completed:
        statusBadge = {
          'icon': Icons.check,
          'text': '完',
          'color': Colors.grey.shade800,
        };
        break;
      case TaskStatus.cancelled:
        statusBadge = {
          'icon': Icons.cancel,
          'text': '止',
          'color': Colors.red.shade800,
        };
        break;
    }
    return PopupMenuButton<TaskStatus>(
      tooltip: 'ステータスを変更',
      initialValue: task.status,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 8),
      onSelected: (status) {
        ref.read(taskViewModelProvider.notifier).setTaskStatus(task.id, status);
      },
      itemBuilder: (context) {
        return TaskStatus.values.map((status) {
          final info = _getStatusMenuInfo(status);
          final isSelected = status == task.status;
          return PopupMenuItem<TaskStatus>(
            value: status,
            child: Row(
              children: [
                Icon(
                  info['icon'] as IconData,
                  color: info['color'] as Color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info['text'] as String,
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: statusBadge['color'] as Color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusBadge['icon'] as IconData, size: 12, color: Colors.white),
            const SizedBox(width: 2),
            Text(
              statusBadge['text'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// コンパクトモード用の優先度インジケーター（漢字一文字、クリックで変更可能）
  Widget _buildCompactPriorityIndicator(TaskItem task) {
    return PopupMenuButton<TaskPriority>(
      tooltip: '優先度を変更',
      initialValue: task.priority,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 8),
      onSelected: (priority) {
        ref.read(taskViewModelProvider.notifier).setTaskPriority(task.id, priority);
      },
      itemBuilder: (context) {
        return TaskPriority.values.map((priority) {
          final info = _getPriorityInfoForList(priority);
          final isSelected = priority == task.priority;
          return PopupMenuItem<TaskPriority>(
            value: priority,
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: info['color'] as Color,
                  size: 14,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    info['text'] as String,
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Builder(
        builder: (context) {
          final priorityInfo = _getPriorityInfoForList(task.priority);
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
        },
      ),
    );
  }

  /// コンパクトモード用のツールチップコンテンツ（ホバー時に詳細情報を表示）
  String _buildCompactTooltipContent(TaskItem task) {
    final buffer = StringBuffer();
    buffer.writeln('タスク: ${task.title}');
    
    if (task.assignedTo != null && task.assignedTo!.isNotEmpty) {
      buffer.writeln('依頼先: ${task.assignedTo}');
    }
    
    if (task.description != null && task.description!.isNotEmpty) {
      final desc = task.description!.length > 100 
          ? '${task.description!.substring(0, 100)}...'
          : task.description!;
      buffer.writeln('説明: $desc');
    }
    
    if (task.tags.isNotEmpty) {
      buffer.writeln('タグ: ${task.tags.join(", ")}');
    }
    
    return buffer.toString();
  }

  /// コンパクトモード用のリンク表示（アコーディオン）
  Widget _buildCompactLinksDisplay(TaskItem task, List<LinkItem> links, bool isExpanded, String expandedKey) {
    // リンクが空の場合は何も表示しない
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }
    
    const maxVisibleLinks = 3; // 最初に表示するリンク数
    final visibleLinks = isExpanded ? links : links.take(maxVisibleLinks).toList();
    final hasMoreLinks = links.length > maxVisibleLinks;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: visibleLinks.map((link) {
            return Tooltip(
              message: link.memo != null && link.memo!.isNotEmpty 
                  ? link.memo! 
                  : 'メモはリンク管理画面から追加可能',
              waitDuration: const Duration(milliseconds: 500),
              child: InkWell(
                onTap: () => _openRelatedLink(link),
                borderRadius: BorderRadius.circular(4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 200, // 最大幅を制限（はみ出し防止）
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: _buildFaviconOrIcon(link, Theme.of(context)),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          link.label,
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (hasMoreLinks)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedTaskIds.remove(expandedKey);
                } else {
                  _expandedTaskIds.add(expandedKey);
                }
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: Colors.blue[700],
                ),
                Text(
                  isExpanded 
                    ? 'リンクを折りたたむ'
                    : '他${links.length - maxVisibleLinks}個のリンクを表示',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// コンパクトモード用の予定バッジ（ツールチップ付き）
  Widget _buildScheduleBadgeCompact(String taskId) {
    final schedules = ref.watch(scheduleViewModelProvider);
    final taskSchedules = schedules.where((s) => s.taskId == taskId).toList();
    
    if (taskSchedules.isEmpty) {
      return const SizedBox(width: 16);
    }
    
    // 日時昇順でソート
    taskSchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    
    // ツールチップコンテンツを生成
    final tooltipContent = _buildScheduleTooltipContent(taskSchedules);
    
    return SizedBox(
      width: 16,
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
          child: Icon(
            Icons.calendar_today,
            size: 16,
            color: Colors.orange.shade700,
          ),
        ),
      ),
    );
  }

  /// 標準モード用のタスクListTileを構築（現在の実装）
  Widget _buildStandardTaskTile(TaskItem task, bool isSelected, {int? reorderIndex}) {
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
              // ドラッグハンドル（並び替え可能な場合のみ表示）
              if (reorderIndex != null && (_sortOrders.isEmpty || _sortOrders[0]['field'] == 'custom'))
                ReorderableDragStartListener(
                  index: reorderIndex!,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.drag_handle,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
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
                                    : Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (task.completedSubTasksCount == task.totalSubTasksCount 
                                        ? Colors.green.shade600 
                                        : Colors.red.shade600).withValues(alpha: 0.4),
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
          _buildStatusSelector(task),
          const SizedBox(width: 4),
          _buildPrioritySelector(task),
          const SizedBox(width: 8),
          // アクションメニュー
          PopupMenuButton<String>(
            onSelected: (value) => _handleTaskAction(value, task),
            itemBuilder: (context) => [
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
        text = '未';
        icon = Icons.schedule;
        break;
      case TaskStatus.inProgress:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        borderColor = Colors.blue.shade300;
        text = '中';
        icon = Icons.play_arrow;
        break;
      case TaskStatus.completed:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade800;
        borderColor = Colors.grey.shade300;
        text = '完';
        icon = Icons.check;
        break;
      case TaskStatus.cancelled:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        borderColor = Colors.red.shade300;
        text = '止';
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

  Map<String, dynamic> _getStatusMenuInfo(TaskStatus status) {
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

  Widget _buildStatusSelector(TaskItem task) {
    return PopupMenuButton<TaskStatus>(
      tooltip: 'ステータスを変更',
      initialValue: task.status,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 8),
      onSelected: (status) {
        ref.read(taskViewModelProvider.notifier).setTaskStatus(task.id, status);
      },
      itemBuilder: (context) {
        return TaskStatus.values.map((status) {
          final info = _getStatusMenuInfo(status);
          final isSelected = status == task.status;
          return PopupMenuItem<TaskStatus>(
            value: status,
            child: Row(
              children: [
                Icon(
                  info['icon'] as IconData,
                  color: info['color'] as Color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info['text'] as String,
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: _buildStatusChip(task.status),
    );
  }

  Widget _buildPrioritySelector(TaskItem task) {
    return PopupMenuButton<TaskPriority>(
      tooltip: '優先度を変更',
      initialValue: task.priority,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 8),
      onSelected: (priority) {
        ref.read(taskViewModelProvider.notifier).setTaskPriority(task.id, priority);
      },
      itemBuilder: (context) {
        return TaskPriority.values.map((priority) {
          final info = _getPriorityInfoForList(priority);
          final isSelected = priority == task.priority;
          return PopupMenuItem<TaskPriority>(
            value: priority,
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: info['color'] as Color,
                  size: 14,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    info['text'] as String,
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: _buildPriorityIndicatorForList(task.priority),
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
    SnackBarService.showSuccess(
      context,
      'フィルターをリセットしました',
    );
    
    print('🔄 フィルターリセット完了');
  }

  void _handleTaskAction(String action, TaskItem task) {
    final taskViewModel = ref.read(taskViewModelProvider.notifier);

    switch (action) {
      case 'copy':
        _showCopyTaskDialog(task);
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
    final validLinkCount = _getValidLinkCount(task);
    
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
    
    return _getValidLinkCount(task) > 0;
  }

  int _getValidLinkCount(TaskItem task) {
    if ((task.relatedLinkIds.isEmpty) &&
        (task.relatedLinkId == null || task.relatedLinkId!.isEmpty)) {
      return 0;
    }

    final groups = ref.read(linkViewModelProvider);
    final existingIds = <String>{};

    for (final group in groups.groups) {
      for (final link in group.items) {
        existingIds.add(link.id);
      }
    }

    final validNewIds =
        task.relatedLinkIds.where((id) => existingIds.contains(id)).toSet();
    int total = validNewIds.length;

    if (task.relatedLinkId != null &&
        task.relatedLinkId!.isNotEmpty &&
        existingIds.contains(task.relatedLinkId!) &&
        !validNewIds.contains(task.relatedLinkId!)) {
      total += 1;
    }

    return total;
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
  // CSV出力処理（フィルター適用済みタスク+完了タスクも出力）
  void _exportTasksToCsv() async {
    try {
      final tasks = ref.read(taskViewModelProvider);
      // フィルター適用済みのタスクリストを取得
      final filteredTasks = _getFilteredTasks(tasks);
      // 完了タスクを追加（重複を避ける）
      final completedTasks = tasks.where((task) => 
        task.status == TaskStatus.completed && 
        !filteredTasks.any((t) => t.id == task.id)
      ).toList();
      // フィルター済みタスクと完了タスクを結合してソート
      final allTasksForExport = _sortTasks([...filteredTasks, ...completedTasks]);
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
        // 一時ファイルにCSVを出力（フィルター適用済みタスク+完了タスク、選択された列のみ）
        await CsvExport.exportTasksToCsv(
          allTasksForExport,
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
          SnackBarService.showSuccess(
            context,
            'CSV出力が完了しました: ${targetFile.path.split(Platform.pathSeparator).last}',
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
        SnackBarService.showError(
          context,
          'CSV出力エラー: ${e.toString()}',
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
    } else if (event.logicalKey == LogicalKeyboardKey.keyT && isControlPressed && isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+Shift+T 検出: テンプレートから作成');
      _showTaskTemplate();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyS && isControlPressed && !isShiftPressed) {
      if (isEditing) return false;
      print('✅ Ctrl+S 検出: 予定表');
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
    } else if (event.logicalKey == LogicalKeyboardKey.keyZ && isControlPressed && !isShiftPressed) {
      // Ctrl+Z: 詳細トグル（すべて詳細表示/非表示）
      if (isEditing) return false;
      print('✅ Ctrl+Z 検出: 詳細表示/非表示切り替え');
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
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyX && isControlPressed && !isShiftPressed) {
      // Ctrl+X: コンパクト⇔標準の切り替え
      if (isEditing) return false;
      print('✅ Ctrl+X 検出: コンパクト⇔標準表示切り替え');
      setState(() {
        _listViewMode = _listViewMode == ListViewMode.compact 
            ? ListViewMode.standard 
            : ListViewMode.compact;
        _saveListViewMode();
      });
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
    showShortcutHelpDialog(
      context,
      title: 'タスク管理ショートカット',
      entries: const [
        ShortcutHelpEntry('Ctrl + N', '新しいタスクを作成'),
        ShortcutHelpEntry('Ctrl + B', '一括選択モードを切り替え'),
        ShortcutHelpEntry('Ctrl + Shift + E', 'CSVにエクスポート'),
        ShortcutHelpEntry('Ctrl + Shift + S', '設定画面を開く'),
        ShortcutHelpEntry('Ctrl + S', '予定表を開く'),
        ShortcutHelpEntry('Ctrl + G', 'グループ化メニュー'),
        ShortcutHelpEntry('Ctrl + Shift + T', 'テンプレートから作成'),
        ShortcutHelpEntry('Ctrl + H', '統計・検索バー表示/非表示'),
        ShortcutHelpEntry('Ctrl + Z', '詳細表示/非表示切り替え'),
        ShortcutHelpEntry('Ctrl + X', 'コンパクト⇔標準表示切り替え'),
        ShortcutHelpEntry('← / →', 'ホームへ戻る / 3点メニューを開く'),
        ShortcutHelpEntry('↓', '3点メニューにフォーカス'),
        ShortcutHelpEntry('F1', 'ショートカット一覧を表示'),
            ],
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
        // スケジュール一覧
        PopupMenuItem(
          value: 'schedule',
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
                const Text('スケジュール一覧 (Ctrl+S)'),
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

  /// 検索候補を更新（タグ・説明文からの候補も含む）
  void _updateSearchSuggestions(String query) {
    if (query.trim().isEmpty) {
      _searchSuggestions = [];
      return;
    }
    
    final queryLower = query.toLowerCase();
    final suggestions = <_SearchSuggestion>[];
    final addedTexts = <String>{}; // 重複チェック用
    
    // 検索履歴から候補を取得
    for (final history in _searchHistory) {
      if (history.toLowerCase().contains(queryLower) && !addedTexts.contains(history)) {
        suggestions.add(_SearchSuggestion(
          text: history,
          type: _SuggestionType.history,
        ));
        addedTexts.add(history);
      }
    }
    
    // タスクタイトルから候補を取得
    final tasks = ref.read(taskViewModelProvider);
    for (final task in tasks) {
      // タイトル
      if (task.title.toLowerCase().contains(queryLower) && !addedTexts.contains(task.title)) {
        suggestions.add(_SearchSuggestion(
          text: task.title,
          type: _SuggestionType.title,
        ));
        addedTexts.add(task.title);
      }
      
      // タグから候補を取得
      for (final tag in task.tags) {
        if (tag.toLowerCase().contains(queryLower) && !addedTexts.contains(tag)) {
          suggestions.add(_SearchSuggestion(
            text: tag,
            type: _SuggestionType.tag,
            subtitle: 'タグ: ${task.title}',
          ));
          addedTexts.add(tag);
        }
      }
      
      // 説明文から候補を取得（短いサマリー）
      if (task.description != null && task.description!.isNotEmpty) {
        final descLower = task.description!.toLowerCase();
        if (descLower.contains(queryLower)) {
          // マッチした部分の前後を含む短いテキストを抽出（最大50文字）
          final matchIndex = descLower.indexOf(queryLower);
          final start = (matchIndex - 20).clamp(0, descLower.length);
          final end = (matchIndex + queryLower.length + 30).clamp(0, task.description!.length);
          var summary = task.description!.substring(start, end);
          if (start > 0) summary = '...$summary';
          if (end < task.description!.length) summary = '$summary...';
          
          final suggestionText = summary.trim();
          if (!addedTexts.contains(suggestionText)) {
            suggestions.add(_SearchSuggestion(
              text: suggestionText,
              type: _SuggestionType.description,
              subtitle: '説明: ${task.title}',
            ));
            addedTexts.add(suggestionText);
          }
        }
      }
    }
    
    // 最大10件まで（種類の多様性を考慮）
    _searchSuggestions = suggestions.take(10).toList();
  }

  /// 検索候補リストを構築（ハイライト表示対応）
  Widget _buildSearchSuggestions() {
    if (_searchSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
          IconData icon;
          Color iconColor;
          
          switch (suggestion.type) {
            case _SuggestionType.history:
              icon = Icons.history;
              iconColor = Colors.grey;
              break;
            case _SuggestionType.title:
              icon = Icons.title;
              iconColor = Theme.of(context).primaryColor;
              break;
            case _SuggestionType.tag:
              icon = Icons.label;
              iconColor = Colors.orange.shade700;
              break;
            case _SuggestionType.description:
              icon = Icons.description;
              iconColor = Colors.blue.shade700;
              break;
          }
          
          return InkWell(
            onTap: () {
              setState(() {
                _searchController.text = suggestion.text;
                _searchQuery = suggestion.text;
                _userTypedSearch = true;
                _showSearchSuggestions = false;
              });
              _searchFocusNode.unfocus();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HighlightedText(
                          text: suggestion.text,
                          highlight: _searchQuery,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (suggestion.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            suggestion.subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
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

  /// リストビュー表示モードを読み込み
  void _loadListViewMode() {
    try {
      final box = Hive.box('filterPresets');
      final modeString = box.get('listViewMode') as String?;
      final columns = box.get('compactGridColumns', defaultValue: 4) as int;
      
      if (modeString != null) {
        setState(() {
          _listViewMode = modeString == 'compact' ? ListViewMode.compact : ListViewMode.standard;
          _compactGridColumns = columns;
        });
      } else {
        setState(() {
          _compactGridColumns = columns;
        });
      }
    } catch (e) {
      _listViewMode = ListViewMode.standard;
      _compactGridColumns = 4;
    }
  }


  /// リストビュー表示モードを保存
  void _saveListViewMode() {
    try {
      final box = Hive.box('filterPresets');
      final modeString = _listViewMode == ListViewMode.compact ? 'compact' : 'standard';
      box.put('listViewMode', modeString);
      box.put('compactGridColumns', _compactGridColumns);
    } catch (e) {
      // エラーは無視
    }
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

  /// フィルター読み込みダイアログを表示（エクスポート/インポート機能付き）
  void _showLoadFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルター管理'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // エクスポート/インポートボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _exportFilterPresets();
                    },
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('エクスポート'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _importFilterPresets();
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('インポート'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // 保存されたフィルター一覧
              if (_savedFilterPresets.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('保存されたフィルターがありません'),
                )
              else
                Flexible(
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
            ],
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

  /// フィルタープリセットをエクスポート
  Future<void> _exportFilterPresets() async {
    try {
      final exportData = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'presets': _savedFilterPresets,
      };
      
      final jsonString = jsonEncode(exportData);
      
      // ファイル保存ダイアログを表示
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'フィルタープリセットをエクスポート',
        fileName: 'task_filter_presets_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        
        if (mounted) {
          SnackBarService.showSuccess(context, 'フィルタープリセットをエクスポートしました');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'エクスポートに失敗しました: $e');
      }
    }
  }

  /// フィルタープリセットをインポート
  Future<void> _importFilterPresets() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'フィルタープリセットをインポート',
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final importData = jsonDecode(jsonString) as Map<String, dynamic>;
        
        if (importData['presets'] != null) {
          final importedPresets = Map<String, Map<String, dynamic>>.from(
            (importData['presets'] as Map).map((key, value) => 
              MapEntry(key.toString(), Map<String, dynamic>.from(value))
            )
          );
          
          // 既存のプリセットとマージ（同名の場合は上書き）
          _savedFilterPresets.addAll(importedPresets);
          _saveFilterPresets();
          _loadSavedFilterPresets();
          
          if (mounted) {
            SnackBarService.showSuccess(
              context, 
              '${importedPresets.length}件のフィルタープリセットをインポートしました'
            );
          }
        } else {
          if (mounted) {
            SnackBarService.showError(context, '無効なファイル形式です');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'インポートに失敗しました: $e');
      }
    }
  }

  /// クイックフィルターを適用
  void _applyQuickFilter(String filterType) {
    setState(() {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      switch (filterType) {
        case 'urgent':
          // 緊急タスク: 優先度が高または緊急、かつ未完了
          _filterStatuses = {'pending', 'in_progress'};
          _filterPriority = 'high';
          _searchQuery = '';
          _searchController.text = '';
          break;
        case 'today':
          // 今日のタスク: 期限日が今日、かつ未完了
          _filterStatuses = {'pending', 'in_progress'};
          _filterPriority = 'all';
          _searchQuery = '';
          _searchController.text = '';
          // 期限日フィルターは別途実装が必要（現在の実装では期限日フィルターがないため、検索で代替）
          break;
        case 'pending':
          // 未着手タスク
          _filterStatuses = {'pending'};
          _filterPriority = 'all';
          _searchQuery = '';
          _searchController.text = '';
          break;
        case 'in_progress':
          // 進行中タスク
          _filterStatuses = {'in_progress'};
          _filterPriority = 'all';
          _searchQuery = '';
          _searchController.text = '';
          break;
      }
      
      _saveFilterSettings();
    });
    
    SnackBarService.showInfo(context, 'クイックフィルターを適用しました');
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
                  SnackBarService.showSuccess(
                    context,
                    '「${example['pattern']}」をコピーしました',
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
                    title: Text(
                      query,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
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
    // コンパクトモードの場合はグリッド表示（カード型）
    if (_listViewMode == ListViewMode.compact) {
      return _buildCompactGridView(sortedTasks);
    }
    
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

  /// コンパクトモード用のグリッドビューを構築（カード型）
  Widget _buildCompactGridView(List<TaskItem> tasks) {
    // ピン留めタスクと通常タスクを分離
    final pinnedTasks = tasks.where((task) => _pinnedTaskIds.contains(task.id)).toList();
    final unpinnedTasks = tasks.where((task) => !_pinnedTaskIds.contains(task.id)).toList();
    
    // レイアウト設定を取得
    final layoutSettings = ref.watch(taskProjectLayoutSettingsProvider);
    final fontSize = ref.watch(uiDensityProvider);
    // カードビュー専用のフォント設定を使用
    final titleFontSize = layoutSettings.titleFontSize;
    final titleFontFamily = layoutSettings.titleFontFamily;
    final titleTextColor = layoutSettings.titleTextColor;
    final memoFontSize = layoutSettings.memoFontSize;
    final memoFontFamily = layoutSettings.memoFontFamily;
    final memoTextColor = layoutSettings.memoTextColor;
    final descriptionFontSize = layoutSettings.descriptionFontSize;
    final descriptionFontFamily = layoutSettings.descriptionFontFamily;
    final descriptionTextColor = layoutSettings.descriptionTextColor;
    
    // 列数を計算（自動調整または手動設定）
    final crossAxisCount = layoutSettings.autoAdjustLayout
        ? (MediaQuery.of(context).size.width > 1400 ? _compactGridColumns
            : MediaQuery.of(context).size.width > 1100 ? _compactGridColumns
            : MediaQuery.of(context).size.width > 700 ? (_compactGridColumns - 1).clamp(2, 4)
            : 2)
        : _compactGridColumns.clamp(2, 8);
    
    final spacing = layoutSettings.defaultGridSpacing;
    final cardWidth = layoutSettings.cardWidth;
    final cardHeight = layoutSettings.cardHeight;
    
    // ピン留めタスクを上部に固定表示
    Widget buildGridSection(List<TaskItem> taskList) {
      if (taskList.isEmpty) return const SizedBox.shrink();
      
      if (layoutSettings.autoAdjustCardHeight) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final padding = spacing * 0.75;
            final effectiveWidth = availableWidth - (padding * 2);
            final crossAxisSpacing = spacing;
            final itemWidth = (effectiveWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
            
            return Padding(
              padding: EdgeInsets.all(padding),
              child: Wrap(
                spacing: crossAxisSpacing,
                runSpacing: spacing,
                alignment: WrapAlignment.start,
                children: taskList.map((task) {
                  return SizedBox(
                    width: itemWidth,
                    child: _buildCompactTaskCard(
                      task,
                      isSelected: _selectedTaskIds.contains(task.id),
                      cardWidth: itemWidth,
                      minCardHeight: cardHeight,
                      layoutSettings: layoutSettings,
                      fontSize: fontSize,
                      titleFontSize: titleFontSize,
                      titleFontFamily: titleFontFamily,
                      titleTextColor: titleTextColor,
                      memoFontSize: memoFontSize,
                      memoFontFamily: memoFontFamily,
                      memoTextColor: memoTextColor,
                      descriptionFontSize: descriptionFontSize,
                      descriptionFontFamily: descriptionFontFamily,
                      descriptionTextColor: descriptionTextColor,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      }
      
      // 固定アスペクト比のグリッドビュー
      final childAspectRatio = cardWidth / cardHeight;
      
      return GridView.builder(
        padding: EdgeInsets.all(spacing * 0.75),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: taskList.length,
        itemBuilder: (context, index) {
          final task = taskList[index];
          return _buildCompactTaskCard(
            task,
            isSelected: _selectedTaskIds.contains(task.id),
            cardWidth: null,
            minCardHeight: null,
            layoutSettings: layoutSettings,
            fontSize: fontSize,
            titleFontSize: titleFontSize,
            titleFontFamily: titleFontFamily,
            titleTextColor: titleTextColor,
            memoFontSize: memoFontSize,
            memoFontFamily: memoFontFamily,
            memoTextColor: memoTextColor,
            descriptionFontSize: descriptionFontSize,
            descriptionFontFamily: descriptionFontFamily,
            descriptionTextColor: descriptionTextColor,
          );
        },
      );
    }
    
    // ピン留めタスクがある場合は固定表示
    if (pinnedTasks.isNotEmpty) {
      return SingleChildScrollView(
        child: Column(
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
              child: buildGridSection(pinnedTasks),
            ),
            // 通常タスク（スクロール可能）
            if (unpinnedTasks.isNotEmpty) buildGridSection(unpinnedTasks),
          ],
        ),
      );
    }
    
    // ピン留めタスクがない場合は通常表示
    return buildGridSection(unpinnedTasks);
  }

  /// コンパクトモード用のタスクカード（カード形式）
  Widget _buildCompactTaskCard(
    TaskItem task, {
    required bool isSelected,
    double? cardWidth,
    double? minCardHeight,
    required TaskProjectLayoutSettings layoutSettings,
    required double fontSize,
    required double titleFontSize,
    required String titleFontFamily,
    required int titleTextColor,
    required double memoFontSize,
    required String memoFontFamily,
    required int memoTextColor,
    required double descriptionFontSize,
    required String descriptionFontFamily,
    required int descriptionTextColor,
  }) {
    final bool hasSubTaskBadge = task.hasSubTasks || task.totalSubTasksCount > 0;
    final isHovered = _hoveredTaskIds.contains(task.id);
    final relatedLinks = _getRelatedLinks(task);
    final hasValidLinks = _hasValidLinks(task);
    final expandedLinksKey = 'compact_links_${task.id}';
    final isLinksExpanded = _expandedTaskIds.contains(expandedLinksKey);
    final isExpanded = _expandedTaskIds.contains(task.id);
    
    // 詳細があるかチェック
    final bool hasDetails =
        (task.description != null && task.description!.isNotEmpty) ||
        (task.assignedTo != null && task.assignedTo!.isNotEmpty) ||
        hasValidLinks;
    
    // 期限日に基づく背景色（ナイトモード対応）
    final now = DateTime.now();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    Color cardBg;
    Color borderColor;
    
    if (task.dueDate == null) {
      cardBg = isDarkMode 
          ? colorScheme.surfaceContainerHighest 
          : colorScheme.surface;
      borderColor = isDarkMode 
          ? Colors.green.shade400 
          : Colors.green.shade300;
    } else {
      final difference = task.dueDate!.difference(now).inDays;
      if (difference < 0) {
        // 期限切れ
        cardBg = isDarkMode 
            ? Colors.red.shade900.withValues(alpha: 0.4)
            : Colors.red.shade50;
        borderColor = isDarkMode 
            ? Colors.red.shade400 
            : Colors.red.shade300;
      } else if (difference == 0) {
        // 今日が期限
        cardBg = isDarkMode 
            ? Colors.orange.shade900.withValues(alpha: 0.4)
            : Colors.orange.shade50;
        borderColor = isDarkMode 
            ? Colors.orange.shade400 
            : Colors.orange.shade300;
      } else if (difference <= 3) {
        // 3日以内
        cardBg = isDarkMode 
            ? Colors.amber.shade900.withValues(alpha: 0.4)
            : Colors.amber.shade50;
        borderColor = isDarkMode 
            ? Colors.amber.shade400 
            : Colors.amber.shade300;
      } else {
        // それ以外
        cardBg = isDarkMode 
            ? colorScheme.surfaceContainerHighest 
            : Colors.blue.shade50;
        borderColor = isDarkMode 
            ? Colors.blue.shade400 
            : Colors.blue.shade300;
      }
    }
    
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredTaskIds.add(task.id)),
      onExit: (_) => setState(() => _hoveredTaskIds.remove(task.id)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_isSelectionMode) {
            _toggleTaskSelection(task.id);
          } else {
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
          }
        },
        child: Transform.scale(
          scale: isHovered && !_isSelectionMode ? 1.02 : 1.0,
          child: Card(
            elevation: isHovered ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 2),
            ),
            color: cardBg,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minCardHeight ?? layoutSettings.cardHeight,
                maxWidth: cardWidth ?? double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // ヘッダー: ピン留めボタン + 期限日バッジ + チェックボックス
                  Row(
                    children: [
                      // ピン留めボタン
                      IconButton(
                        icon: Icon(
                          _pinnedTaskIds.contains(task.id)
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: 14,
                          color: _pinnedTaskIds.contains(task.id)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        tooltip: _pinnedTaskIds.contains(task.id) ? 'ピンを外す' : '上部にピン留め',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () {
                          _togglePinTask(task.id);
                          setState(() {});
                        },
                      ),
                      // 期限日バッジ（コンパクト）
                      _buildCompactDeadlineIndicator(task),
                      const Spacer(),
                      // 選択モードの場合はチェックボックス
                      if (_isSelectionMode)
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleTaskSelection(task.id),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // タイトル + 詳細トグル
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _searchQuery.isNotEmpty
                            ? HighlightedText(
                                text: task.title,
                                highlight: _searchQuery,
                                style: TextStyle(
                                  color: task.status == TaskStatus.completed 
                                      ? Color(titleTextColor).withOpacity(0.5)
                                      : Color(titleTextColor),
                                  decoration: task.status == TaskStatus.completed 
                                      ? TextDecoration.lineThrough 
                                      : null,
                                  fontSize: 13 * titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: titleFontFamily.isEmpty ? null : titleFontFamily,
                                ),
                              )
                            : Text(
                                task.title,
                                style: TextStyle(
                                  color: task.status == TaskStatus.completed 
                                      ? Color(titleTextColor).withOpacity(0.5)
                                      : Color(titleTextColor),
                                  decoration: task.status == TaskStatus.completed 
                                      ? TextDecoration.lineThrough 
                                      : null,
                                  fontSize: 13 * titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: titleFontFamily.isEmpty ? null : titleFontFamily,
                                ),
                                maxLines: isExpanded ? null : 2,
                                overflow: isExpanded ? null : TextOverflow.ellipsis,
                              ),
                      ),
                      // 詳細トグルボタン
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
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              Text(
                                isExpanded ? '閉じる' : '詳細',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // 依頼先/メモ（1行表示または展開時は全表示）
                  if (task.assignedTo != null && task.assignedTo!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${task.assignedTo}',
                      style: TextStyle(
                        fontSize: 10 * memoFontSize,
                        color: Color(memoTextColor),
                        fontFamily: memoFontFamily.isEmpty ? null : memoFontFamily,
                      ),
                      maxLines: isExpanded ? null : 1,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ],
                  // 説明（1行表示または展開時は全表示）
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 10 * descriptionFontSize,
                        color: Color(descriptionTextColor),
                        fontFamily: descriptionFontFamily.isEmpty ? null : descriptionFontFamily,
                      ),
                      maxLines: isExpanded ? null : 1,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ],
                  // リンク表示（展開時のみまたはアコーディオン）
                  if (hasValidLinks && relatedLinks.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildCompactLinksDisplay(task, relatedLinks, isLinksExpanded || isExpanded, expandedLinksKey),
                  ],
                  const SizedBox(height: 6),
                  // フッター: ステータス + 優先度 + その他
                  Row(
                    children: [
                      // 予定バッジ（ツールチップ付き）
                      _buildScheduleBadgeCompact(task.id),
                      const SizedBox(width: 4),
                      // リマインダーアイコン
                      if (task.reminderTime != null)
                        Icon(Icons.notifications_active, size: 12, color: Colors.orange),
                      if (task.reminderTime != null) const SizedBox(width: 4),
                      // ステータスバッジ（クリック可能）
                      _buildCompactStatusBadge(task),
                      const SizedBox(width: 6),
                      // 優先度インジケーター（漢字一文字）
                      _buildCompactPriorityIndicator(task),
                      const Spacer(),
                      // チームタスクアイコン
                      if (task.isTeamTask)
                        Icon(Icons.group, size: 12, color: Colors.blue[700]),
                      if (task.isTeamTask) const SizedBox(width: 4),
                      // サブタスクバッジ（クリック可能・ツールチップ付き）
                      if (hasSubTaskBadge)
                        GestureDetector(
                          onTap: () {
                            // サブタスクダイアログを開く
                            showDialog(
                              context: context,
                              builder: (context) => SubTaskDialog(
                                parentTaskId: task.id,
                                parentTaskTitle: task.title,
                              ),
                            ).then((_) {
                              setState(() {});
                            });
                          },
                          child: Tooltip(
                            message: _buildSubTaskTooltipContent(task),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: task.completedSubTasksCount == task.totalSubTasksCount 
                                  ? Colors.green.shade600 
                                  : Colors.red.shade600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${task.completedSubTasksCount}/${task.totalSubTasksCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // アクションメニュー（コピー・同期・削除）
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 14, color: Colors.grey.shade600),
                        tooltip: 'アクション',
                        onSelected: (value) => _handleTaskAction(value, task),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'copy',
                            child: Row(
                              children: [
                                Icon(Icons.copy, color: Colors.blue, size: 16),
                                const SizedBox(width: 8),
                                Text('コピー', style: TextStyle(color: Colors.blue, fontSize: 12)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'sync_to_calendar',
                            child: Row(
                              children: [
                                Icon(Icons.sync, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Text('このタスクを同期', style: TextStyle(color: Colors.green, fontSize: 12)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Text('削除', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
    try {
      final groups = ref.read(linkViewModelProvider);
      final relatedLinks = <LinkItem>[];
      
      // デバッグログ（本番環境では削除可能）
      if (task.relatedLinkIds.isNotEmpty) {
        print('🔗 _getRelatedLinks: タスク「${task.title}」のリンクID数: ${task.relatedLinkIds.length}');
        print('🔗 リンクID一覧: ${task.relatedLinkIds}');
        print('🔗 利用可能なグループ数: ${groups.groups.length}');
      }
      
      for (final linkId in task.relatedLinkIds) {
        bool found = false;
        for (final group in groups.groups) {
          for (final link in group.items) {
            if (link.id == linkId) {
              relatedLinks.add(link);
              found = true;
              break;
            }
          }
          if (found) break;
        }
        if (!found) {
          print('⚠️ リンクID「$linkId」が見つかりませんでした（タスク: ${task.title}）');
        }
      }
      
      if (task.relatedLinkIds.isNotEmpty && relatedLinks.isEmpty) {
        print('⚠️ 警告: タスク「${task.title}」に${task.relatedLinkIds.length}個のリンクIDがありますが、実際のリンクが見つかりませんでした');
      }
      
      return relatedLinks;
    } catch (e, stackTrace) {
      print('❌ _getRelatedLinks エラー: $e');
      print('❌ スタックトレース: $stackTrace');
      return [];
    }
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