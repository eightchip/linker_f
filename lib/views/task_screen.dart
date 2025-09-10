import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/task_item.dart';
import '../models/link_item.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/link_viewmodel.dart';
import '../viewmodels/sub_task_viewmodel.dart';
import '../services/notification_service.dart';
import '../services/windows_notification_service.dart';
import '../services/settings_service.dart';
import '../services/snackbar_service.dart';
import '../utils/csv_export.dart';
import 'task_dialog.dart';
import 'calendar_screen.dart';
import 'sub_task_dialog.dart';

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
  late TextEditingController _searchController;
  
  // 一括選択機能の状態変数
  bool _isSelectionMode = false; // 選択モードのオン/オフ
  Set<String> _selectedTaskIds = {}; // 選択されたタスクのIDセット

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService.instance;
    _searchController = TextEditingController(text: _searchQuery);
    // 非同期で初期化を実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSettings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: Text('選択した${_selectedTaskIds.length}件のタスクを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
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
        // 検索コントローラーのテキストも更新
        _searchController.text = _searchQuery;
      }
    } catch (e) {
      print('フィルター設定の読み込みエラー: $e');
      // エラーの場合はデフォルト値を使用
      _filterStatuses = {'all'};
      _filterPriority = 'all';
      _sortOrders = [{'field': 'dueDate', 'order': 'asc'}];
      _searchQuery = '';
      _searchController.text = _searchQuery;
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
    final tasks = ref.watch(taskViewModelProvider);
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    final statistics = taskViewModel.getTaskStatistics();

    // フィルタリング
    final filteredTasks = _getFilteredTasks(tasks);

    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: _handleKeyEvent,
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
            PopupMenuButton<String>(
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
                value: 'calendar',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('カレンダー表示'),
                  ],
                ),
              ),
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
            ],
          ),
          ],
        ],
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
          ),
        ],
      ),
      ),
    );
  }

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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('総タスク', statistics['total'] ?? 0, Icons.list),
                _buildStatItem('未着手', statistics['pending'] ?? 0, Icons.radio_button_unchecked, Colors.grey),
                _buildStatItem('完了', statistics['completed'] ?? 0, Icons.check_circle, Colors.green),
                _buildStatItem('進行中', statistics['inProgress'] ?? 0, Icons.pending, Colors.blue),
                _buildStatItem('期限切れ', statistics['overdue'] ?? 0, Icons.warning, Colors.red),
                _buildStatItem('今日', statistics['today'] ?? 0, Icons.today, Colors.orange),
              ],
            ),
          ),
          
          // 右半分: 検索とフィルター
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const SizedBox(width: 16),
                // 検索バー
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'タスクを検索...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _saveFilterSettings();
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // 優先度フィルター
                Expanded(
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
                
                const SizedBox(width: 8),
                
                // フィルター表示/非表示ボタン
                IconButton(
                  icon: Icon(_showFilters ? Icons.expand_less : Icons.expand_more, size: 20),
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
        Icon(icon, color: color, size: 18),
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
                      const SizedBox(width: 4),
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
                      const SizedBox(width: 4),
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
                      const SizedBox(width: 4),
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
    
    return Card(
      key: ValueKey(task.id), // キーを追加
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: _isSelectionMode && isSelected 
        ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
        : null,
      child: ListTile(
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
                  // 1段目: タイトル
                  Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.status == TaskStatus.completed 
                          ? TextDecoration.lineThrough 
                          : null,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
                          const SizedBox(width: 8),
                          Text(
                            '${task.assignedTo}',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ],
                      ],
                    )
                  else if (task.assignedTo != null)
                    // リマインドがない場合はタイトルの真下に依頼先・メモを表示
                    Text(
                      'メモ: ${task.assignedTo}',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                        child: Text(
                          '${task.completedSubTasksCount}/${task.totalSubTasksCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _showSubTaskDialog(task),
              tooltip: 'サブタスク管理',
            ),
            // 関連リンクへのアクセスボタン
            if (task.relatedLinkId != null)
              IconButton(
                icon: const Icon(Icons.link, size: 16),
                onPressed: () => _openRelatedLink(task),
                tooltip: '関連リンクを開く',
              ),
            _buildStatusChip(task.status),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handleTaskAction(value, task),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('編集'),
                    ],
                  ),
                ),
                const PopupMenuItem(
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
                  const PopupMenuItem(
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
                  const PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check),
                        SizedBox(width: 8),
                        Text('完了'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
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
      builder: (context) => TaskDialog(task: task),
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
      case 'calendar':
        _showCalendarScreen();
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
      case 'delete':
        _showDeleteConfirmation(task);
        break;
    }
  }

  void _showDeleteConfirmation(TaskItem task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを削除'),
        content: Text('「${task.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // カレンダー画面を表示
  void _showCalendarScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalendarScreen(),
      ),
    );
  }

  // 関連リンクを開くメソッド
  void _openRelatedLink(TaskItem task) {
    if (task.relatedLinkId == null) return;

    final linkViewModel = ref.read(linkViewModelProvider.notifier);
    final groups = ref.read(linkViewModelProvider);
    
    // 関連リンクを検索
    LinkItem? relatedLink;
    for (final group in groups.groups) {
      relatedLink = group.items.firstWhere(
        (link) => link.id == task.relatedLinkId,
        orElse: () => LinkItem(
          id: '',
          label: '',
          path: '',
          type: LinkType.url,
          createdAt: DateTime.now(),
        ),
      );
      if (relatedLink.id.isNotEmpty) break;
    }

    if (relatedLink != null && relatedLink.id.isNotEmpty) {
      // リンクを開く
      linkViewModel.launchLink(relatedLink);
      
      // 成功メッセージを表示
      SnackBarService.showSuccess(
        context,
        'リンク「${relatedLink.label}」を開きました',
      );
    } else {
      // エラーメッセージを表示
      SnackBarService.showError(
        context,
        '関連リンクが見つかりません',
      );
    }
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
        final tags = task.tags.map((tag) => tag.toLowerCase()).join(' ');
        
        if (!title.contains(query) && 
            !description.contains(query) && 
            !tags.contains(query)) {
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
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // モーダルが開いている場合はショートカットを無効化
      if (ModalRoute.of(context)?.isFirst != true) {
        return;
      }
      
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // 左矢印キーが押されたらホーム画面に戻る
        Navigator.of(context).pop();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // 右矢印キーで3点ドットメニューを表示
        _showPopupMenu(context);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // 下矢印キーで3点ドットメニューを表示
        _showPopupMenu(context);
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
        // カレンダー表示
        const PopupMenuItem(
          value: 'calendar',
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('カレンダー表示'),
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
      builder: (context) => AlertDialog(
        title: const Text('タスクをコピー'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${task.title}」をコピーしますか？'),
            const SizedBox(height: 16),
            const Text('コピーされる内容:'),
            const SizedBox(height: 8),
            Text('• タイトル: ${task.title} (コピー)'),
            if (task.dueDate != null)
              Text('• 期限日: ${DateFormat('yyyy/MM/dd').format(task.dueDate!)}'),
            if (task.reminderTime != null)
              Text('• リマインダー: ${DateFormat('yyyy/MM/dd HH:mm').format(task.reminderTime!)}'),
            Text('• 優先度: ${_getPriorityText(task.priority)}'),
            if (task.tags.isNotEmpty)
              Text('• タグ: ${task.tags.join(', ')}'),
            if (task.estimatedMinutes != null)
              Text('• 推定時間: ${task.estimatedMinutes}分'),
            const SizedBox(height: 8),
            const Text('※ 期限日とリマインダー時間は翌月の同日に自動調整されます'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('コピー', style: TextStyle(color: Colors.white)),
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
}
