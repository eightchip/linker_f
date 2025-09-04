import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/task_item.dart';
import '../models/link_item.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/link_viewmodel.dart';
import '../viewmodels/sub_task_viewmodel.dart';
import '../services/notification_service.dart';
import '../services/windows_notification_service.dart';
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
  Set<String> _filterStatuses = {'all'}; // 複数選択可能
  String _filterPriority = 'all'; // all, low, medium, high, urgent
  String _searchQuery = '';
  List<String> _sortOrders = ['dueDate']; // 第3順位まで設定可能
  bool _showFilters = false; // フィルター表示/非表示の切り替え

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
        title: const Text('タスク管理'),
        actions: [
          IconButton(
            onPressed: () => _showCalendarScreen(),
            icon: const Icon(Icons.calendar_month),
            tooltip: 'カレンダー表示',
          ),
          IconButton(
            onPressed: () => _showTestNotification(),
            icon: const Icon(Icons.notifications),
            tooltip: '通知テスト',
          ),
          IconButton(
            onPressed: () => _showTestReminderNotification(),
            icon: const Icon(Icons.schedule),
            tooltip: 'リマインダーテスト',
          ),
          IconButton(
            onPressed: () => _showTestReminderInOneMinute(),
            icon: const Icon(Icons.timer),
            tooltip: '1分後リマインダーテスト',
          ),
          IconButton(
            onPressed: () => _showTaskDialog(),
            icon: const Icon(Icons.add),
            tooltip: '新しいタスク',
          ),
          IconButton(
            onPressed: () => _exportTasksToCsv(),
            icon: const Icon(Icons.download),
            tooltip: 'CSV出力',
          ),
        ],
      ),
      body: Column(
        children: [
          // 統計情報
          _buildStatisticsCard(statistics),
          
          // フィルターと検索（折りたたみ可能）
          _buildCollapsibleFilterSection(),
          
          // タスク一覧（全画面表示）
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
                    child: Text('タスクがありません'),
                  )
                : ReorderableListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(filteredTasks[index]);
                    },
                    onReorder: (oldIndex, newIndex) {
                      _handleTaskReorder(oldIndex, newIndex);
                    },
                    buildDefaultDragHandles: true,
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, int> statistics) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('総タスク', statistics['total'] ?? 0, Icons.list),
            _buildStatItem('完了', statistics['completed'] ?? 0, Icons.check_circle, Colors.green),
            _buildStatItem('進行中', statistics['inProgress'] ?? 0, Icons.pending, Colors.blue),
            _buildStatItem('期限切れ', statistics['overdue'] ?? 0, Icons.warning, Colors.red),
            _buildStatItem('今日', statistics['today'] ?? 0, Icons.today, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCollapsibleFilterSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // フィルター表示/非表示の切り替えボタン
          ListTile(
            leading: Icon(_showFilters ? Icons.expand_less : Icons.expand_more),
            title: Text(_showFilters ? 'フィルターを隠す' : 'フィルターを表示'),
            trailing: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
            ),
            onTap: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          
          // 折りたたみ可能なフィルター内容
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 検索バー
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'タスクを検索...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      // ステータスフィルター（複数選択）
                      Expanded(
                        child: _buildStatusFilterChips(),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // 優先度フィルター
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('優先度:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 並び替え（第3順位まで）
                  _buildSortingSection(),
                  
                  const SizedBox(height: 16),
                  
                  // 並び替えの説明
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '並び替え順序: 最大3段階まで設定可能（ドラッグ&ドロップで手動調整可能）',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ステータスフィルター（複数選択）
  Widget _buildStatusFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ステータス:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('すべて'),
              selected: _filterStatuses.contains('all'),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filterStatuses = {'all'};
                  } else {
                    _filterStatuses.remove('all');
                  }
                });
              },
            ),
            FilterChip(
              label: const Text('未着手'),
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
              },
            ),
            FilterChip(
              label: const Text('進行中'),
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
              },
            ),
            FilterChip(
              label: const Text('完了'),
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
              },
            ),
          ],
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
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '第1順位',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                value: _sortOrders.isNotEmpty ? _sortOrders[0] : 'dueDate',
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
                      _sortOrders = [value!];
                    } else {
                      _sortOrders[0] = value!;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '第2順位',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                value: _sortOrders.length > 1 ? _sortOrders[1] : null,
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
                        _sortOrders[1] = value;
                      } else {
                        _sortOrders.add(value);
                      }
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '第3順位',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                value: _sortOrders.length > 2 ? _sortOrders[2] : null,
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
                        _sortOrders.add(value);
                      } else {
                        _sortOrders[2] = value;
                      }
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    return Card(
      key: ValueKey(task.id), // キーを追加
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildPriorityIndicator(task.priority),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  decoration: task.status == TaskStatus.completed 
                      ? TextDecoration.lineThrough 
                      : null,
                ),
              ),
            ),
            if (task.isOverdue)
              const Icon(Icons.warning, color: Colors.red, size: 16),
            if (task.isToday)
              const Icon(Icons.today, color: Colors.orange, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            // 期限とリマインダー情報を1行に表示
            Row(
              children: [
                if (task.dueDate != null)
                  Text(
                    '期限: ${DateFormat('MM/dd').format(task.dueDate!)}',
                    style: TextStyle(
                      color: task.isOverdue ? Colors.red : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                if (task.reminderTime != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'リマ: ${DateFormat('MM/dd HH:mm').format(task.reminderTime!)}',
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontSize: 11,
                    ),
                  ),
                ],
                if (task.estimatedMinutes != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${task.estimatedMinutes}分',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
            // タグを1行に表示（空白を削減）
            if (task.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  spacing: 2,
                  runSpacing: 0,
                  children: task.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  )).toList(),
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
                  const Icon(Icons.subdirectory_arrow_right, size: 16),
                  if (task.hasSubTasks)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${task.completedSubTasksCount}/${task.totalSubTasksCount}',
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
        onTap: () => _showTaskDialog(task: task),
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
            onPressed: () {
              ref.read(taskViewModelProvider.notifier).deleteTask(task.id);
              Navigator.of(context).pop();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('リンク「${relatedLink.label}」を開きました'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // エラーメッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('関連リンクが見つかりません'),
          backgroundColor: Colors.red,
        ),
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

  // 複数キーワードがすべて含まれているかチェックするヘルパーメソッド
  bool _matchesKeywords(String text, List<String> keywords) {
    if (keywords.isEmpty) return true;
    return keywords.every((keyword) => text.contains(keyword));
  }

  // ReorderableListViewの並び替えを処理するメソッド
  void _handleTaskReorder(int oldIndex, int newIndex) {
    final taskViewModel = ref.read(taskViewModelProvider.notifier);
    final List<TaskItem> allTasks = List.from(ref.read(taskViewModelProvider));
    
    // フィルタリングされたタスクのインデックスを元のタスクリストのインデックスに変換
    final filteredTasks = _getFilteredTasks(allTasks);
    final oldTask = filteredTasks[oldIndex];
    final newTask = filteredTasks[newIndex];
    
    final oldOriginalIndex = allTasks.indexWhere((task) => task.id == oldTask.id);
    final newOriginalIndex = allTasks.indexWhere((task) => task.id == newTask.id);
    
    if (oldOriginalIndex != -1 && newOriginalIndex != -1) {
      // 元のリストで並び替えを実行
      final task = allTasks.removeAt(oldOriginalIndex);
      allTasks.insert(newOriginalIndex, task);
      
      // 並び替えを保存
      taskViewModel.updateTasks(allTasks);
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
              final sortOrder = _sortOrders[i];
              int comparison = 0;
              
              switch (sortOrder) {
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
      
      // 現在のディレクトリにCSVファイルを保存
      final now = DateTime.now();
      final formatted = DateFormat('yyMMdd_HHmm').format(now);
      final fileName = 'tasks_export_$formatted.csv';
      final currentDir = Directory.current;
      final filePath = '${currentDir.path}/$fileName';
      
      await CsvExport.exportTasksToCsv(tasks, subTasks, filePath);
      
      // 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV出力が完了しました: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV出力エラー: $e'),
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
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // 左矢印キーが押されたらホーム画面に戻る
        Navigator.of(context).pop();
      }
    }
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
      default:
        return '中';
    }
  }
}
