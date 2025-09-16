import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
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
import 'package:url_launcher/url_launcher.dart';
import '../models/sent_mail_log.dart';
import '../services/keyboard_shortcut_service.dart';
import '../widgets/unified_dialog.dart';
import '../widgets/app_button_styles.dart';
import '../widgets/app_spacing.dart';

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
  final FocusNode _appBarMenuFocusNode = FocusNode();
  late FocusNode _searchFocusNode;
  
  // フォーカス
  final FocusNode _rootKeyFocus = FocusNode(debugLabel: 'rootKeys');
  // 検索欄
  late final TextEditingController _searchController;
  // ユーザーが検索操作を始めたか（ハイライト制御用）
  bool _userTypedSearch = false;
  
  // 一括選択機能の状態変数
  bool _isSelectionMode = false; // 選択モードのオン/オフ
  Set<String> _selectedTaskIds = {}; // 選択されたタスクのIDセット

  @override
  void initState() {
    super.initState();
    print('=== TaskScreen initState 開始 ===');
    _settingsService = SettingsService.instance;
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();

    _searchQuery = '';
    print('初期化時の_searchQuery: "$_searchQuery"');
    _initializeSettings().then((_) {
      if (!mounted) return;

      // いったん復元（必要なら一瞬だけ内部状態に取り込む）
      _searchController.text = _searchQuery;

      // 初期表示は必ず空にする（復元値を使わない仕様）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _userTypedSearch = false;
          _searchQuery = '';
          _searchController.clear();
        });
        _saveFilterSettings();        // 空で保存して以後は空スタート
        _searchFocusNode.requestFocus(); // カーソルも置く
      });
    });

    // 入力のたびに _searchQuery を同期
    _searchController.addListener(() {
      final v = _searchController.text;
      if (v != _searchQuery) {
        setState(() {
          _searchQuery = v;
        });
        _saveFilterSettings();
      }
    });
    print('=== TaskScreen initState 終了 ===');
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
  void _toggleSelectAll(List<TaskItem> filteredTasks) {
    setState(() {
      if (_selectedTaskIds.length == filteredTasks.length) {
        // 全選択されている場合は全解除
        _selectedTaskIds.clear();
      } else {
        // 一部または未選択の場合は全選択
        _selectedTaskIds = filteredTasks.map((task) => task.id).toSet();
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
            '${deletedCount}件のタスクを削除しました',
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
    print('build呼び出し: _searchQuery="$_searchQuery"');
    final tasks = ref.watch(taskViewModelProvider);
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    final statistics = taskViewModel.getTaskStatistics();

    // フィルタリング
    final filteredTasks = _getFilteredTasks(tasks);

    return KeyboardShortcutWidget(
      child: KeyboardListener(
        focusNode: _rootKeyFocus, // 再生成しない
        autofocus: false,         // ← これが超重要。TextField のフォーカスを奪わない
        onKeyEvent: (e) {
          // TextField にフォーカスがある時はグローバルショートカット無効化
          final focused = FocusManager.instance.primaryFocus;
          final isEditing = focused?.context?.widget is EditableText;
          if (isEditing) return;
          _handleKeyEvent(e);
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSelectionMode 
              ? Text('${_selectedTaskIds.length}件選択中')
              : const Text('タスク管理'),
            leading: _isSelectionMode 
              ? IconButton(
                  onPressed: _toggleSelectionMode,
                  icon: const Icon(Icons.close),
                  tooltip: '選択モードを終了',
                )
              : null,
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
                    Navigator.of(context).pop();
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
                    Text('新しいタスク'),
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
                    Text('一括選択モード'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.green),
                    SizedBox(width: 8),
                    Text('CSV出力'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'test_notification',
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('通知テスト'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_reminder',
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('リマインダーテスト'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_reminder_1min',
                child: Row(
                  children: [
                    Icon(Icons.timer, color: Colors.red),
                    SizedBox(width: 8),
                    Text('1分後リマインダーテスト'),
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
          _buildCompactHeaderSection(statistics),
          
          // ステータスフィルター（折りたたみ可能）
          if (_showFilters) _buildStatusFilterSection(),
          
          // タスク一覧（全画面表示）
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
                    child: Text('タスクがありません'),
                  )
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(filteredTasks[index]);
                    },
                  ),
          ),//Expanded
          ],//children
        ),//Column
        ),
      ),
    );
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
                const SizedBox(width: AppSpacing.xs),
                _buildStatItem('未着手', statistics['pending'] ?? 0, Icons.radio_button_unchecked, Colors.grey),
                const SizedBox(width: AppSpacing.xs),
                _buildStatItem('完了', statistics['completed'] ?? 0, Icons.check_circle, Colors.green),
                const SizedBox(width: AppSpacing.xs),
                _buildStatItem('進行中', statistics['inProgress'] ?? 0, Icons.pending, Colors.blue),
                const SizedBox(width: AppSpacing.xs),
                _buildStatItem('期限切れ', statistics['overdue'] ?? 0, Icons.warning, Colors.red),
                const SizedBox(width: AppSpacing.xs),
                _buildStatItem('今日', statistics['today'] ?? 0, Icons.today, Colors.orange),
              ],
            ),
          ),
          
          // 右半分: 検索とフィルター
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.lg),
                // 検索バー
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
                        decoration: const InputDecoration(
                          hintText: 'タスクを検索（タイトル・説明・メモ・タグ）...',
                          prefixIcon: Icon(Icons.search, size: AppIconSizes.medium),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          isDense: true,
                        ),
                        onChanged: (_) {
                          // 入力が始まったらハイライト有効化
                          if (!_userTypedSearch) {
                            setState(() => _userTypedSearch = true);
                          }
                          // フォーカスを再主張（親に奪われた直後でも戻す）
                          if (!_searchFocusNode.hasFocus) {
                            _searchFocusNode.requestFocus();
                          }
                        },
                        onSubmitted: (_) {
                          // Enter で確定した際もハイライト有効化
                          if (!_userTypedSearch) {
                            setState(() => _userTypedSearch = true);
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
    final isSelected = _selectedTaskIds.contains(task.id);
    final isAutoGenerated = _isAutoGeneratedTask(task);
    
    return Card(
      key: ValueKey(task.id), // キーを追加
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: _isSelectionMode && isSelected 
        ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
        : null,
      elevation: 3, // 影を強化
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          _buildTaskListTile(task, isSelected),
          if (isAutoGenerated) _buildEmailBadge(task),
        ],
      ),
    );
  }
  
  /// タスクのListTileを構築
  Widget _buildTaskListTile(TaskItem task, bool isSelected) {
    return ListTile(
        leading: _isSelectionMode 
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleTaskSelection(task.id),
            )
          : _buildPriorityIndicator(task.priority),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 期限日を左側に配置
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: task.dueDate != null 
                  ? (task.isOverdue ? Colors.red.shade50 : Colors.blue.shade50)
                  : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: task.dueDate != null 
                    ? (task.isOverdue ? Colors.red.shade400 : Colors.blue.shade400)
                    : Colors.amber.shade400,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    task.dueDate != null 
                      ? DateFormat('MM/dd').format(task.dueDate!)
                      : '未設定',
                    style: TextStyle(
                      color: task.dueDate != null 
                        ? (task.isOverdue ? Colors.red.shade800 : Colors.blue.shade800)
                        : Colors.amber.shade800,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (task.isOverdue || task.isToday) ...[
                    const SizedBox(height: 2),
                    Icon(
                      task.isOverdue ? Icons.warning : Icons.today,
                      color: task.isOverdue ? Colors.red : Colors.orange,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 右側にタイトル・リマインダー・依頼先を3段で配置
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1段目: タイトル（チームタスクの場合はバッジ付き）
                  Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final highlightText = (_userTypedSearch && _searchQuery.isNotEmpty) ? _searchQuery : null;
                            print('HighlightedText タイトル: text="${task.title}", highlight="$highlightText", _searchQuery="$_searchQuery"');
                            return HighlightedText(
                              text: task.title,
                              highlight: highlightText,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface, // 文字色を明示的に指定
                                decoration: task.status == TaskStatus.completed 
                                    ? TextDecoration.lineThrough 
                                    : null,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      if (task.isTeamTask) ...[
                        const SizedBox(width: AppSpacing.sm),
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
                                size: 12,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: AppSpacing.xs),
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
                  const SizedBox(height: 4),
                  // 2段目: リマインダーと依頼先・メモの組み合わせ
                  if (task.reminderTime != null)
                    Row(
                      children: [
                        Text(
                          'リマインド: ${DateFormat('MM/dd HH:mm').format(task.reminderTime!)}',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 102, 0),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (task.assignedTo != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          HighlightedText(
                            text: '${task.assignedTo}',
                            highlight: (_userTypedSearch && _searchQuery.isNotEmpty) ? _searchQuery : null,
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    )
                  else if (task.assignedTo != null)
                    // リマインドがない場合はタイトルの真下に依頼先・メモを表示
                    HighlightedText(
                      text: 'メモ: ${task.assignedTo}',
                      highlight: (_userTypedSearch && _searchQuery.isNotEmpty) ? _searchQuery : null,
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // メールバッジ
            _buildMailBadges(task.id),
            // サブタスクボタン
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.subdirectory_arrow_right, size: 20),
                  if (task.hasSubTasks)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Builder(
                          builder: (context) {
                            // デバッグ情報を出力
                            if (kDebugMode) {
                              print('サブタスクバッジ表示 - タスク: ${task.title}, 完了: ${task.completedSubTasksCount}, 総数: ${task.totalSubTasksCount}');
                            }
                            return Text(
                          '${task.completedSubTasksCount}/${task.totalSubTasksCount}',
                          style: const TextStyle(
                            color: Colors.white,
                                fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _showSubTaskDialog(task),
              tooltip: 'サブタスク管理',
            ),
            // 関連リンクへのアクセスボタン
            _buildRelatedLinksButton(task),
            _buildStatusChip(task.status),
            const SizedBox(width: 8),
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
        onTap: _isSelectionMode 
          ? () => _toggleTaskSelection(task.id)
          : () => _showTaskDialog(task: task),
        onLongPress: _isSelectionMode 
          ? null 
          : () {
              _toggleSelectionMode();
              _toggleTaskSelection(task.id);
            },
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
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case TaskStatus.pending:
        color = Colors.grey;
        text = '未着手';
        icon = Icons.schedule;
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        text = '進行中';
        icon = Icons.play_arrow;
        break;
      case TaskStatus.completed:
        color = Colors.green;
        text = '完了';
        icon = Icons.check;
        break;
      case TaskStatus.cancelled:
        color = Colors.red;
        text = 'キャンセル';
        icon = Icons.cancel;
        break;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showTaskDialog({TaskItem? task}) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        task: task,
        onMailSent: () {
          // メール送信後にタスクリストを更新
          setState(() {});
        },
      ),
    );
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
      case 'test_notification':
        _showTestNotification();
        break;
      case 'test_reminder':
        _showTestReminderNotification();
        break;
      case 'test_reminder_1min':
        _showTestReminderInOneMinute();
        break;
    }
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
    final hasLinks = task.relatedLinkId != null || task.relatedLinkIds.isNotEmpty;
    
    if (!hasLinks) {
      return IconButton(
        icon: const Icon(Icons.link_off, size: 16, color: Colors.grey),
        onPressed: () => _showLinkAssociationDialog(task),
        tooltip: 'リンクを関連付け',
      );
    }
    
    return PopupMenuButton<String>(
      icon: Stack(
        children: [
          const Icon(Icons.link, size: 16),
          if (task.relatedLinkIds.length > 1)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  '${task.relatedLinkIds.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: '関連リンクを開く',
      onSelected: (value) => _handleLinkAction(value, task),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        
        // 各リンクを開くオプション
        for (int i = 0; i < task.relatedLinkIds.length; i++) {
          final linkId = task.relatedLinkIds[i];
          items.add(PopupMenuItem(
            value: 'open_$linkId',
            child: Row(
              children: [
                const Icon(Icons.open_in_new, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _getLinkLabel(linkId) ?? 'リンク $i',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ));
        }
        
        // 区切り線
        items.add(const PopupMenuDivider());
        
        // リンク管理オプション
        items.addAll([
          const PopupMenuItem(
            value: 'manage_links',
            child: Row(
              children: [
                Icon(Icons.link, color: Colors.blue),
                SizedBox(width: 8),
                Text('リンク管理', style: TextStyle(color: Colors.blue)),
              ],
            ),
          ),
        ]);
        
        return items;
      },
    );
  }
  
  /// リンクのラベルを取得
  String? _getLinkLabel(String linkId) {
    final groups = ref.read(linkViewModelProvider);
    
    for (final group in groups.groups) {
      for (final link in group.items) {
        if (link.id == linkId) {
          return link.label;
        }
      }
    }
    return null;
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
    showDialog(
      context: context,
      builder: (context) => _LinkAssociationDialog(
        task: task,
        onLinksUpdated: () {
          setState(() {}); // UIを更新
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

      // 検索フィルター
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = task.title.toLowerCase();
        final description = task.description?.toLowerCase() ?? '';
        final notes = task.notes?.toLowerCase() ?? '';
        final assignedTo = task.assignedTo?.toLowerCase() ?? '';
        final tags = task.tags.map((tag) => tag.toLowerCase()).join(' ');
        
        final titleMatch = title.contains(query);
        final descriptionMatch = description.contains(query);
        final notesMatch = notes.contains(query);
        final assignedToMatch = assignedTo.contains(query);
        final tagsMatch = tags.contains(query);
        
        if (!titleMatch && !descriptionMatch && !notesMatch && !assignedToMatch && !tagsMatch) {
          return false;
        }
      }

      return true;
    }).toList();

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

  // キーボードショートカット処理
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // モーダルが開いている場合はショートカットを無効化
      if (ModalRoute.of(context)?.isFirst != true) {
        return;
      }
      
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).maybePop();
        }
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // 右矢印キーでAppBarの3点ドットメニューにフォーカスを移す
        _appBarMenuFocusNode.requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // 下矢印キーでAppBarの3点ドットメニューにフォーカスを移す
        _appBarMenuFocusNode.requestFocus();
      }
    }
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
      builder: (context) => UnifiedDialog(
        title: 'タスクをコピー',
        icon: Icons.copy,
        iconColor: Colors.blue,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${task.title}」をコピーしますか？'),
            const SizedBox(height: AppSpacing.lg),
            const Text('コピーされる内容:'),
            const SizedBox(height: AppSpacing.sm),
            Text('• タイトル: ${task.title} (コピー)'),
            if (task.dueDate != null)
              Text('• 期限日: ${DateFormat('yyyy/MM/dd').format(task.dueDate!)}'),
            if (task.reminderTime != null)
              Text('• リマインダー: ${DateFormat('yyyy/MM/dd HH:mm').format(task.reminderTime!)}'),
            Text('• 優先度: ${_getPriorityText(task.priority)}'),
            if (task.tags.isNotEmpty)
              HighlightedText(
                text: '• タグ: ${task.tags.join(', ')}',
                highlight: (_userTypedSearch && _searchQuery.isNotEmpty) ? _searchQuery : null,
              ),
            const SizedBox(height: AppSpacing.sm),
            const Text('※ 期限日とリマインダー時間は翌月の同日に自動調整されます'),
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
              Navigator.of(context).pop();
              
              // タスクをコピー
              final copiedTask = await ref.read(taskViewModelProvider.notifier).copyTask(task);
              
              if (copiedTask != null) {
                // 成功メッセージを表示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('タスク「${copiedTask.title}」をコピーしました'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                // エラーメッセージを表示
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('タスクのコピーに失敗しました'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: AppButtonStyles.primary(context),
            child: const Text('コピー'),
          ),
        ],
      ),
    );
  }

  /// メールバッジを構築
  Widget _buildMailBadges(String taskId) {
    return FutureBuilder<List<SentMailLog>>(
      future: _getMailLogsForTask(taskId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MailBadgeList(
              logs: snapshot.data!,
              onLogTap: _openSentSearch,
            ),
          );
        }
        return const SizedBox.shrink();
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
  
}

/// リンク関連付けダイアログ
class _LinkAssociationDialog extends ConsumerStatefulWidget {
  final TaskItem task;
  final VoidCallback onLinksUpdated;

  const _LinkAssociationDialog({
    required this.task,
    required this.onLinksUpdated,
  });

  @override
  ConsumerState<_LinkAssociationDialog> createState() => _LinkAssociationDialogState();
}

class _LinkAssociationDialogState extends ConsumerState<_LinkAssociationDialog> {
  Set<String> _selectedLinkIds = {};

  @override
  void initState() {
    super.initState();
    // 現在の関連リンクを選択状態に設定
    _selectedLinkIds = Set.from(widget.task.relatedLinkIds);
  }

  @override
  Widget build(BuildContext context) {
    final linkGroups = ref.watch(linkViewModelProvider);
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // ヘッダー部分
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.link,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'リンク管理',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'タスク「${widget.task.title}」にリンクを関連付け',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // コンテンツ部分
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '関連付けたいリンクを選択してください：',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: ListView.builder(
                        itemCount: linkGroups.groups.length,
                        itemBuilder: (context, groupIndex) {
                          final group = linkGroups.groups[groupIndex];
                          return _buildGroupCard(group, theme);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // フッター部分
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
              ),
              child: Row(
                children: [
                  // 選択情報
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedLinkIds.isNotEmpty 
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.colorScheme.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedLinkIds.isNotEmpty 
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedLinkIds.isNotEmpty ? Icons.check_circle : Icons.info_outline,
                          color: _selectedLinkIds.isNotEmpty 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '選択されたリンク: ${_selectedLinkIds.length}個',
                          style: TextStyle(
                            color: _selectedLinkIds.isNotEmpty 
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // ボタン
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.outline,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('キャンセル'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _selectedLinkIds.isNotEmpty ? _saveLinkAssociations : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Group group, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getGroupColor(group).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder,
                color: _getGroupColor(group),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                group.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getGroupColor(group).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${group.items.length}個',
                style: TextStyle(
                  color: _getGroupColor(group),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: group.items.map((link) => _buildLinkItem(link, theme)).toList(),
      ),
    );
  }

  Widget _buildLinkItem(LinkItem link, ThemeData theme) {
    final isSelected = _selectedLinkIds.contains(link.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedLinkIds.remove(link.id);
              } else {
                _selectedLinkIds.add(link.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // アイコン
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getLinkTypeColor(link.type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getLinkTypeIcon(link.type),
                    color: _getLinkTypeColor(link.type),
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // リンク情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        link.path,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // 選択状態インジケーター
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.add,
                    color: isSelected 
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.outline.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getGroupColor(Group group) {
    // グループ名に基づいて色を決定
    switch (group.title.toLowerCase()) {
      case 'favorites':
        return Colors.blue;
      case 'favorites2':
        return Colors.green;
      case 'favorites3':
        return Colors.red;
      case 'programming':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  Color _getLinkTypeColor(LinkType type) {
    switch (type) {
      case LinkType.url:
        return Colors.blue;
      case LinkType.file:
        return Colors.green;
      case LinkType.folder:
        return Colors.orange;
    }
  }

  IconData _getLinkTypeIcon(LinkType type) {
    switch (type) {
      case LinkType.url:
        return Icons.language;
      case LinkType.file:
        return Icons.description;
      case LinkType.folder:
        return Icons.folder;
    }
  }

  Future<void> _saveLinkAssociations() async {
    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      
      // 現在のリンクを取得
      final currentLinkIds = Set.from(widget.task.relatedLinkIds);
      
      // 追加するリンク
      final linksToAdd = _selectedLinkIds.difference(currentLinkIds);
      
      // 削除するリンク
      final linksToRemove = currentLinkIds.difference(_selectedLinkIds);
      
      // リンクを追加
      for (final linkId in linksToAdd) {
        await taskViewModel.addLinkToTask(widget.task.id, linkId);
      }
      
      // リンクを削除
      for (final linkId in linksToRemove) {
        await taskViewModel.removeLinkFromTask(widget.task.id, linkId);
      }
      
      // 成功メッセージを表示
      SnackBarService.showSuccess(
        context,
        'リンクの関連付けを更新しました',
      );
      
      // コールバックを実行
      widget.onLinksUpdated();
      
      // ダイアログを閉じる
      Navigator.of(context).pop();
      
    } catch (e) {
      SnackBarService.showError(
        context,
        'リンクの関連付け更新に失敗しました: $e',
      );
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
  
  /// メールアクションを表示
  void _showEmailActions(TaskItem task) {
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: 'メールアクション',
        icon: Icons.email,
        iconColor: Colors.blue,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'タスク: ${task.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('このタスクに関連するメールアクション:'),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('メールに返信'),
              onTap: () {
                Navigator.pop(context);
                _replyToEmail(task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('関連メールを検索'),
              onTap: () {
                Navigator.pop(context);
                _searchRelatedEmails(task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('メール詳細を表示'),
              onTap: () {
                Navigator.pop(context);
                _showEmailDetails(task);
              },
            ),
          ],
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
  
  /// メールに返信
  void _replyToEmail(TaskItem task) {
    // 説明から返信先メールアドレスを抽出
    final description = task.description ?? '';
    final emailMatch = RegExp(r'💬 返信先: (.+)').firstMatch(description);
    
    if (emailMatch != null) {
      final replyEmail = emailMatch.group(1)?.trim();
      if (replyEmail != null && replyEmail.isNotEmpty) {
        // メーラー選択ダイアログを表示
        _showMailerSelectionDialog(task, replyEmail);
      } else {
        SnackBarService.showError(context, '返信先メールアドレスが無効です');
      }
    } else {
      SnackBarService.showError(context, '返信先メールアドレスが見つかりません');
    }
  }

  /// メーラー選択ダイアログを表示
  void _showMailerSelectionDialog(TaskItem task, String replyEmail) {
    String selectedMailer = 'outlook'; // デフォルトは必ずOutlook
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          
          return UnifiedDialog(
            title: 'メーラー選択',
            icon: Icons.email,
            iconColor: Colors.blue,
            width: 450,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('送信アプリ:'),
                const SizedBox(height: 12),
                
                // メーラー選択（Outlook左デフォルト／Gmail右）
                Row(
                  children: [
                    // Outlook選択（左、デフォルト）
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedMailer == 'outlook' ? Colors.blue : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: selectedMailer == 'outlook' ? Colors.blue.shade50 : Colors.white,
                        ),
                        child: RadioListTile<String>(
                          title: const Text('Outlook'),
                          subtitle: const Text('デスクトップ'),
                          value: 'outlook',
                          groupValue: selectedMailer,
                          onChanged: (value) => setState(() => selectedMailer = value!),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          activeColor: Colors.blue,
                          dense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Gmail選択（右）
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedMailer == 'gmail' ? Colors.red : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: selectedMailer == 'gmail' ? Colors.red.shade50 : Colors.white,
                        ),
                        child: RadioListTile<String>(
                          title: const Text('Gmail'),
                          subtitle: const Text('Web'),
                          value: 'gmail',
                          groupValue: selectedMailer,
                          onChanged: (value) => setState(() => selectedMailer = value!),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          activeColor: Colors.red,
                          dense: true,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 各メーラー個別テストボタン
              Row(
                children: [
                  // Outlookテストボタン
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedMailer == 'outlook' ? Colors.blue : Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: selectedMailer == 'outlook' ? Colors.blue.shade50 : Colors.grey.shade50,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _testOutlookConnection(),
                        icon: const Icon(Icons.business, size: 16),
                        label: const Text('Outlookテスト'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: selectedMailer == 'outlook' ? Colors.blue : Colors.grey.shade600,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Gmailテストボタン
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedMailer == 'gmail' ? Colors.red : Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: selectedMailer == 'gmail' ? Colors.red.shade50 : Colors.grey.shade50,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _testGmailConnection(),
                        icon: const Icon(Icons.mail, size: 16),
                        label: const Text('Gmailテスト'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: selectedMailer == 'gmail' ? Colors.red : Colors.grey.shade600,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.text(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendReplyEmail(task, replyEmail, selectedMailer);
              },
              style: AppButtonStyles.primary(context),
              child: const Text('送信'),
            ),
          ],
        );
        },
      ),
    );
  }

  /// 返信メールを送信
  void _sendReplyEmail(TaskItem task, String replyEmail, String mailer) async {
    try {
      final subject = 'Re: ${task.title}';
      final mailService = MailService();
      
      await mailService.sendMail(
        taskId: task.id,
        app: mailer,
        to: replyEmail,
        cc: '',
        bcc: '',
        subject: subject,
        body: '', // HTMLテンプレートを使用
        title: task.title,
        due: task.dueDate?.toString(),
        status: task.status.toString(),
        memo: task.description,
        links: [], // 必要に応じてリンクを追加
      );
      
      SnackBarService.showSuccess(context, '${mailer == 'outlook' ? 'Outlook' : 'Gmail'}で返信メールを作成しました');
    } catch (e) {
      SnackBarService.showError(context, 'メール送信エラー: $e');
    }
  }

  /// Outlook接続テスト
  void _testOutlookConnection() async {
    try {
      final mailService = MailService();
      final isAvailable = await mailService.isOutlookAvailable();
      
      if (isAvailable) {
        SnackBarService.showSuccess(context, 'Outlook接続テスト成功');
      } else {
        SnackBarService.showError(context, 'Outlook接続テスト失敗');
      }
    } catch (e) {
      SnackBarService.showError(context, 'Outlook接続テストエラー: $e');
    }
  }

  /// Gmail接続テスト
  void _testGmailConnection() async {
    try {
      const gmailUrl = 'https://mail.google.com/mail/?view=cm&fs=1&to=';
      final uri = Uri.parse(gmailUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        SnackBarService.showSuccess(context, 'Gmail接続テスト成功');
      } else {
        SnackBarService.showError(context, 'Gmail接続テスト失敗');
      }
    } catch (e) {
      SnackBarService.showError(context, 'Gmail接続テストエラー: $e');
    }
  }
  
  /// 関連メールを検索
  void _searchRelatedEmails(TaskItem task) async {
    try {
      // 説明からメールIDを抽出
      final description = task.description ?? '';
      final emailIdMatch = RegExp(r'🔍 メールID: (.+)').firstMatch(description);
      
      if (emailIdMatch != null) {
        final emailId = emailIdMatch.group(1)?.trim();
        if (emailId != null && emailId.isNotEmpty) {
          // タスクのソースに応じて検索方法を選択
          if (task.id.startsWith('gmail_')) {
            // Gmailの場合はGmailで検索
            final gmailUrl = 'https://mail.google.com/mail/u/0/#search/$emailId';
            if (await canLaunchUrl(Uri.parse(gmailUrl))) {
              await launchUrl(Uri.parse(gmailUrl));
              SnackBarService.showSuccess(context, 'Gmailでメールを検索中...');
            } else {
              SnackBarService.showError(context, 'Gmailを開けませんでした');
            }
          } else if (task.id.startsWith('outlook_')) {
            // Outlookの場合はPowerShellスクリプトで検索
            await _searchOutlookEmail(emailId);
          } else {
            SnackBarService.showInfo(context, 'メールID: $emailId\n手動でメールを検索してください');
          }
        } else {
          SnackBarService.showError(context, 'メールIDが見つかりません');
        }
      } else {
        SnackBarService.showError(context, 'メールIDが見つかりません');
      }
    } catch (e) {
      SnackBarService.showError(context, 'メール検索エラー: $e');
    }
  }

  /// Outlookでメールを検索
  Future<void> _searchOutlookEmail(String emailId) async {
    try {
      final mailService = MailService();
      await mailService.initialize();
      
      final result = await mailService.searchSentMail(emailId);
      if (result) {
        SnackBarService.showSuccess(context, 'Outlookでメールを検索中...');
      } else {
        SnackBarService.showError(context, 'メールが見つかりませんでした');
      }
    } catch (e) {
      SnackBarService.showError(context, 'Outlook検索エラー: $e');
    }
  }
  
  /// メール詳細を表示
  void _showEmailDetails(TaskItem task) {
    final description = task.description ?? '';
    
    showDialog(
      context: context,
      builder: (context) => UnifiedDialog(
        title: 'メール詳細',
        icon: Icons.info_outline,
        iconColor: Colors.blue,
        width: 600,
        height: 500,
        content: SingleChildScrollView(
          child: Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppButtonStyles.text(context),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _replyToEmail(task);
            },
            style: AppButtonStyles.primary(context),
            child: const Text('返信'),
          ),
        ],
      ),
    );
  }
  
}
