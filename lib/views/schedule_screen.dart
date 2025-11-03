import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/task_item.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/font_size_provider.dart';
import 'task_dialog.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  final Map<String, Map<String, DateTime?>> _taskDatesCache = {};
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  bool _showPeriodBarLegend = true; // 期間バーの凡例を表示

  @override
  void initState() {
    super.initState();
    _initializeDateRange();
  }

  void _initializeDateRange() {
    final tasks = ref.read(taskViewModelProvider);
    if (tasks.isEmpty) return;

    DateTime? minDate;
    DateTime? maxDate;
    final now = DateTime.now();

    for (final task in tasks) {
      if (task.dueDate != null) {
        if (minDate == null || task.dueDate!.isBefore(minDate)) {
          minDate = task.dueDate;
        }
        if (maxDate == null || task.dueDate!.isAfter(maxDate)) {
          maxDate = task.dueDate;
        }
      }
    }

    if (minDate != null && maxDate != null) {
      // 少し余裕を持たせる
      setState(() {
        _startDate = minDate!.subtract(const Duration(days: 7));
        _endDate = maxDate!.add(const Duration(days: 14));
        if (_startDate.isAfter(now)) {
          _startDate = DateTime(now.year, now.month, now.day);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskViewModelProvider);
    final fontSize = ref.watch(fontSizeProvider);

    // 期限日があるタスクのみをフィルタリング
    var filteredTasks = tasks.where((task) => task.dueDate != null).toList();
    
    // ステータスフィルター適用
    if (_filterStatus != null) {
      filteredTasks = filteredTasks.where((task) => task.status == _filterStatus).toList();
    }
    
    // 優先度フィルター適用
    if (_filterPriority != null) {
      filteredTasks = filteredTasks.where((task) => task.priority == _filterPriority).toList();
    }

    // 日付範囲でフィルタリング（期限日が範囲内のタスクのみ表示）
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    
    filteredTasks = filteredTasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      // 期限日が開始日以降、終了日以前の範囲内かどうか（厳密に判定）
      // taskDate >= start && taskDate <= end
      return !taskDate.isBefore(start) && !taskDate.isAfter(end);
    }).toList();

    // 期限日順にソート
    filteredTasks.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    // 日付ごとにグループ化（順序情報を読み込んでソート）
    // FutureBuilderで非同期処理を扱うため、ここでは変数に保存しない

    // 表示期間を計算
    final duration = _endDate.difference(_startDate).inDays + 1;
    final dateRangeText =
        '${DateFormat('yyyy/MM/dd').format(_startDate)} ～ ${DateFormat('yyyy/MM/dd').format(_endDate)} ($duration日間)';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('スケジュール一覧'),
            Text(
              dateRangeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_filterStatus != null || _filterPriority != null)
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
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'フィルター',
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: '日付範囲を選択',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: filteredTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '表示できるタスクがありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '期限日が設定されているタスクのみ表示されます',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
             )
           : Focus(
               autofocus: true,
               onKeyEvent: (node, event) {
                 if (event is KeyDownEvent) {
                   final isControlPressed = HardwareKeyboard.instance.isControlPressed;
                   
                   // Ctrl+L: 期間バー凡例の表示/非表示
                   if (event.logicalKey == LogicalKeyboardKey.keyL && isControlPressed) {
                     setState(() {
                       _showPeriodBarLegend = !_showPeriodBarLegend;
                     });
                     return KeyEventResult.handled;
                   }
                   
                   // F1: ショートカットヘルプ
                   if (event.logicalKey == LogicalKeyboardKey.f1) {
                     _showShortcutHelp(context);
                     return KeyEventResult.handled;
                   }
                 }
                 return KeyEventResult.ignored;
               },
               child: Column(
                 children: [
                   // 期間バーの凡例
                   if (_showPeriodBarLegend)
                     _buildPeriodBarLegend(fontSize),
                  // タスクリスト
                  Expanded(
                    child: FutureBuilder<Map<String, List<TaskItem>>>(
                      future: _groupTasksByDate(filteredTasks),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final groupedTasks = snapshot.data!;
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: groupedTasks.length,
                          itemBuilder: (context, index) {
                            final dateKey = groupedTasks.keys.elementAt(index);
                            final tasksForDate = groupedTasks[dateKey]!;
                            final date = DateTime.parse(dateKey);

                            return _buildDateGroup(date, tasksForDate, filteredTasks, fontSize);
                          },
                        );
                      },
                    ),
                  ),
                 ],
               ),
             ),
     );
   }

  Future<Map<String, List<TaskItem>>> _groupTasksByDate(List<TaskItem> tasks) async {
    final Map<String, List<TaskItem>> grouped = {};

    for (final task in tasks) {
      if (task.dueDate == null) continue;

      // 期限日を基準にグループ化
      final dateKey = DateFormat('yyyy-MM-dd').format(task.dueDate!);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(task);
    }

    // 日付ごとに順序を適用してソート
    final sorted = <String, List<TaskItem>>{};
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    for (final key in sortedKeys) {
      final tasksForDate = grouped[key]!;
      // 順序情報を読み込んでソート
      sorted[key] = await _loadAndSortTasksByOrder(key, tasksForDate);
    }

    return sorted;
  }

  /// 日付ごとのタスク順序を読み込んでソート
  Future<List<TaskItem>> _loadAndSortTasksByOrder(String dateKey, List<TaskItem> tasks) async {
    try {
      final box = await Hive.openBox('taskDates');
      final orderKey = 'schedule_order_$dateKey';
      final orderData = box.get(orderKey);
      
      if (orderData != null && orderData is List) {
        // 保存されている順序に従ってソート
        final orderMap = <String, int>{};
        for (int i = 0; i < orderData.length; i++) {
          if (orderData[i] is String) {
            orderMap[orderData[i]] = i;
          }
        }
        
        tasks.sort((a, b) {
          final aOrder = orderMap[a.id];
          final bOrder = orderMap[b.id];
          if (aOrder == null && bOrder == null) return 0;
          if (aOrder == null) return 1; // 順序が設定されていないタスクは最後
          if (bOrder == null) return -1;
          return aOrder.compareTo(bOrder);
        });
      }
    } catch (e) {
      print('タスク順序読み込みエラー ($dateKey): $e');
    }
    
    return tasks;
  }

  /// タスクの順序を保存
  Future<void> _saveTaskOrder(String dateKey, List<TaskItem> tasks) async {
    try {
      final box = await Hive.openBox('taskDates');
      final orderKey = 'schedule_order_$dateKey';
      final taskIds = tasks.map((t) => t.id).toList();
      await box.put(orderKey, taskIds);
    } catch (e) {
      print('タスク順序保存エラー ($dateKey): $e');
    }
  }

  Widget _buildDateGroup(DateTime date, List<TaskItem> tasks, List<TaskItem> allFilteredTasks, double fontSize) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isPast = date.isBefore(now) && !isToday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付ヘッダー
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isToday
                ? Theme.of(context).colorScheme.primaryContainer
                : isPast
                    ? Colors.grey[200]
                    : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToday
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                DateFormat('yyyy年MM月dd日').format(date),
                style: TextStyle(
                  fontSize: 14 * fontSize,
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_getDayOfWeek(date)})',
                style: TextStyle(
                  fontSize: 12 * fontSize,
                  color: isToday
                      ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                      : Colors.grey[600],
                ),
              ),
              const Spacer(),
              // 統計情報
              Builder(
                builder: (context) {
                  // 週/月の集計を計算
                  final weekTasks = _getWeekTasks(date, allFilteredTasks);
                  final monthTasks = _getMonthTasks(date, allFilteredTasks);
                  final weekCount = weekTasks.length;
                  final monthCount = monthTasks.length;
                  
                  return Row(
                    children: [
                      // 週の集計（月曜日または週の最初の日の場合のみ表示）
                      if (date.weekday == 1 || _isWeekStart(date, allFilteredTasks))
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '週:$weekCount',
                            style: TextStyle(
                              fontSize: 9 * fontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // 月の集計（月初の場合のみ表示）
                      if (date.day == 1)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.purple[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '月:$monthCount',
                            style: TextStyle(
                              fontSize: 9 * fontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // 完了タスク数
                      if (tasks.any((t) => t.status == TaskStatus.completed))
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${tasks.where((t) => t.status == TaskStatus.completed).length}完了',
                            style: TextStyle(
                              fontSize: 9 * fontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // 期限切れタスク数
                      Builder(
                        builder: (context) {
                          final now = DateTime.now();
                          final overdueCount = tasks.where((t) {
                            if (t.dueDate == null) return false;
                            return t.dueDate!.isBefore(now) && t.status != TaskStatus.completed;
                          }).length;
                          
                          if (overdueCount > 0) {
                            return Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$overdueCount期限切れ',
                                style: TextStyle(
                                  fontSize: 9 * fontSize,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      // 総タスク数
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tasks.length}件',
                          style: TextStyle(
                            fontSize: 11 * fontSize,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // タスクリスト（ReorderableListViewで並び替え可能）
        _buildReorderableTaskList(tasks, date, fontSize),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 並び替え可能なタスクリストを構築
  Widget _buildReorderableTaskList(List<TaskItem> tasks, DateTime date, double fontSize) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    
    // タスクリストのコピーを作成（状態を変更するため）
    final tasksCopy = List<TaskItem>.from(tasks);
    
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasksCopy.length,
      onReorder: (oldIndex, newIndex) async {
        // インデックス調整（ReorderableListViewの仕様）
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        
        // タスクの順序を更新
        final movedTask = tasksCopy.removeAt(oldIndex);
        tasksCopy.insert(newIndex, movedTask);
        
        // 順序を保存
        await _saveTaskOrder(dateKey, tasksCopy);
        
        // 状態を更新（再ビルドをトリガー）
        setState(() {});
      },
      itemBuilder: (context, index) {
        final task = tasksCopy[index];
        return _buildTaskItemWithKey(task, date, fontSize, index, key: ValueKey(task.id));
      },
    );
  }

  /// キー付きタスクアイテムを構築（ReorderableListView用）
  Widget _buildTaskItemWithKey(TaskItem task, DateTime dueDate, double fontSize, int index, {required Key key}) {
    return Container(
      key: key,
      child: _buildTaskItem(task, dueDate, fontSize),
    );
  }

  Widget _buildTaskItem(TaskItem task, DateTime dueDate, double fontSize) {
    return FutureBuilder<Map<String, DateTime?>>(
      future: _loadTaskDates(task),
      builder: (context, snapshot) {
        final startedAt = snapshot.data?['startedAt'];
        final completedAt = snapshot.data?['completedAt'];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => TaskDialog(task: task),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトルとステータス
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14 * fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _buildStatusBadge(task.status, fontSize),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 期間バー（着手日がある場合のみ表示）
                  if (startedAt != null) ...[
                    _buildPeriodBar(startedAt, completedAt, dueDate, fontSize),
                    const SizedBox(height: 8),
                  ],
                  // 遅延警告（着手日が期限日より遅い場合）
                  if (startedAt != null) ...[
                    Builder(
                      builder: (context) {
                        final startDate = DateTime(startedAt.year, startedAt.month, startedAt.day);
                        final dueDateNormalized = DateTime(dueDate.year, dueDate.month, dueDate.day);
                        if (startDate.isAfter(dueDateNormalized)) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade300, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16 * fontSize,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '遅延開始: 着手日が期限日より遅れています',
                                  style: TextStyle(
                                    fontSize: 11 * fontSize,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                  // 日付情報
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (startedAt != null)
                        _buildDateBadge(
                          '着手',
                          startedAt,
                          Colors.blue,
                          dueDate,
                          fontSize,
                        ),
                      if (completedAt != null)
                        _buildDateBadge(
                          '完了',
                          completedAt,
                          Colors.grey,
                          dueDate,
                          fontSize,
                        ),
                      _buildDateBadge(
                        '期限',
                        dueDate,
                        _getDueDateColor(dueDate),
                        dueDate,
                        fontSize,
                      ),
                    ],
                  ),
                  // 優先度
                  if (task.priority != TaskPriority.medium) ...[
                    const SizedBox(height: 8),
                    _buildPriorityBadge(task.priority, fontSize),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(TaskStatus status, double fontSize) {
    Color color;
    String text;

    switch (status) {
      case TaskStatus.pending:
        color = Colors.green;
        text = '未着手';
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        text = '進行中';
        break;
      case TaskStatus.completed:
        color = Colors.grey;
        text = '完了';
        break;
      case TaskStatus.cancelled:
        color = Colors.red;
        text = '取消';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10 * fontSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateBadge(
    String label,
    DateTime date,
    Color color,
    DateTime dueDate,
    double fontSize,
  ) {
    final isDifferent = date.year != dueDate.year ||
        date.month != dueDate.month ||
        date.day != dueDate.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10 * fontSize,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('MM/dd').format(date),
            style: TextStyle(
              fontSize: 10 * fontSize,
              color: isDifferent ? color : Colors.grey[700],
              fontWeight: isDifferent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority, double fontSize) {
    Color color;
    String text;

    switch (priority) {
      case TaskPriority.low:
        color = Colors.grey;
        text = '低';
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        text = '中';
        break;
      case TaskPriority.high:
        color = Colors.red;
        text = '高';
        break;
      case TaskPriority.urgent:
        color = Colors.deepPurple;
        text = '緊急';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10 * fontSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red; // 期限超過
    } else if (difference == 0) {
      return Colors.orange; // 今日が期限
    } else if (difference <= 3) {
      return Colors.orange; // 3日以内
    } else {
      return Colors.green; // 余裕あり
    }
  }

  /// 指定日付を含む週のタスクを取得
  List<TaskItem> _getWeekTasks(DateTime date, List<TaskItem> allTasks) {
    // 週の開始日（月曜日）を計算
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return !taskDate.isBefore(weekStart) && !taskDate.isAfter(weekEnd);
    }).toList();
  }

  /// 指定日付を含む月のタスクを取得
  List<TaskItem> _getMonthTasks(DateTime date, List<TaskItem> allTasks) {
    final monthStart = DateTime(date.year, date.month, 1);
    final nextMonthStart = DateTime(date.year, date.month + 1, 1);
    
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return !taskDate.isBefore(monthStart) && taskDate.isBefore(nextMonthStart);
    }).toList();
  }

  /// 指定日付が週の最初の日（表示範囲内）かどうかを判定
  bool _isWeekStart(DateTime date, List<TaskItem> allTasks) {
    // 週の開始日（月曜日）を計算
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    
    // 同じ週にタスクがあるかチェック
    final weekTasks = _getWeekTasks(date, allTasks);
    if (weekTasks.isEmpty) return false;
    
    // 週の最初のタスクの日付を取得
    final firstTaskDate = weekTasks.map((t) => t.dueDate!).reduce((a, b) => a.isBefore(b) ? a : b);
    final firstTaskDateNormalized = DateTime(firstTaskDate.year, firstTaskDate.month, firstTaskDate.day);
    
    return firstTaskDateNormalized.year == weekStart.year &&
           firstTaskDateNormalized.month == weekStart.month &&
           firstTaskDateNormalized.day == weekStart.day;
  }

  String _getDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case 1:
        return '月';
      case 2:
        return '火';
      case 3:
        return '水';
      case 4:
        return '木';
      case 5:
        return '金';
      case 6:
        return '土';
      case 7:
        return '日';
      default:
        return '';
    }
  }

  Future<Map<String, DateTime?>> _loadTaskDates(TaskItem task) async {
    // キャッシュを確認
    if (_taskDatesCache.containsKey(task.id)) {
      return _taskDatesCache[task.id]!;
    }

    DateTime? startedAt;
    DateTime? completedAt;

    try {
      final box = await Hive.openBox('taskDates');
      final dates = box.get(task.id);
      if (dates != null) {
        final datesMap = Map<String, dynamic>.from(dates);
        if (datesMap['startedAt'] != null) {
          final parsed = DateTime.parse(datesMap['startedAt']);
          startedAt = DateTime(parsed.year, parsed.month, parsed.day);
        }
        if (datesMap['completedAt'] != null) {
          final parsed = DateTime.parse(datesMap['completedAt']);
          completedAt = DateTime(parsed.year, parsed.month, parsed.day);
        }
      }
    } catch (e) {
      print('タスク${task.id}の着手日・完了日読み込みエラー: $e');
    }

    final result = {
      'startedAt': startedAt,
      'completedAt': completedAt,
    };

    // キャッシュに保存
    _taskDatesCache[task.id] = result;

    return result;
  }

  Future<void> _selectDateRange() async {
    DateTime? selectedStartDate = _startDate;
    DateTime? selectedEndDate = _endDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('表示期間を選択'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // クイック選択
                const Text(
                  '期間で選択',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickRangeButton(
                      context,
                      '今日から1週間',
                      () {
                        final now = DateTime.now();
                        setDialogState(() {
                          selectedStartDate = DateTime(now.year, now.month, now.day);
                          selectedEndDate = selectedStartDate!.add(const Duration(days: 6));
                        });
                      },
                    ),
                    _buildQuickRangeButton(
                      context,
                      '今日から2週間',
                      () {
                        final now = DateTime.now();
                        setDialogState(() {
                          selectedStartDate = DateTime(now.year, now.month, now.day);
                          selectedEndDate = selectedStartDate!.add(const Duration(days: 13));
                        });
                      },
                    ),
                    _buildQuickRangeButton(
                      context,
                      '今日から1ヶ月',
                      () {
                        final now = DateTime.now();
                        setDialogState(() {
                          selectedStartDate = DateTime(now.year, now.month, now.day);
                          selectedEndDate = selectedStartDate!.add(const Duration(days: 29));
                        });
                      },
                    ),
                    _buildQuickRangeButton(
                      context,
                      '今日から3ヶ月',
                      () {
                        final now = DateTime.now();
                        setDialogState(() {
                          selectedStartDate = DateTime(now.year, now.month, now.day);
                          selectedEndDate = selectedStartDate!.add(const Duration(days: 89));
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                // 日付を直接選択
                const Text(
                  '日付を直接選択',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('開始日'),
                  subtitle: Text(
                    selectedStartDate != null
                        ? '${DateFormat('yyyy年MM月dd日').format(selectedStartDate!)} (${_getDayOfWeek(selectedStartDate!)})'
                        : '開始日を選択',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate ?? DateTime.now(),
                      firstDate: DateTime(2000, 1, 1),
                      lastDate: DateTime(2100, 12, 31),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedStartDate = date;
                        if (selectedEndDate != null &&
                            selectedEndDate!.isBefore(selectedStartDate!)) {
                          selectedEndDate = selectedStartDate!.add(const Duration(days: 13));
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('終了日'),
                  subtitle: Text(
                    selectedEndDate != null
                        ? '${DateFormat('yyyy年MM月dd日').format(selectedEndDate!)} (${_getDayOfWeek(selectedEndDate!)})'
                        : '終了日を選択',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedEndDate ??
                          selectedStartDate?.add(const Duration(days: 13)) ??
                          DateTime.now(),
                      firstDate: selectedStartDate ?? DateTime(2000, 1, 1),
                      lastDate: DateTime(2100, 12, 31),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedEndDate = date;
                      });
                    }
                  },
                ),
                if (selectedStartDate != null && selectedEndDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '期間: ${selectedEndDate!.difference(selectedStartDate!).inDays + 1}日間',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: selectedStartDate != null && selectedEndDate != null
                  ? () {
                      Navigator.pop(
                        context,
                        {
                          'startDate': selectedStartDate,
                          'endDate': selectedEndDate,
                        },
                      );
                    }
                  : null,
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['startDate'] != null && result['endDate'] != null) {
      setState(() {
        _startDate = result['startDate'] as DateTime;
        _endDate = result['endDate'] as DateTime;
      });
      // キャッシュをクリアして再読み込み
      _taskDatesCache.clear();
    }
  }

  Widget _buildQuickRangeButton(
    BuildContext context,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// 期間バーを構築（着手日～期限日を視覚化）
  Widget _buildPeriodBar(
    DateTime startedAt,
    DateTime? completedAt,
    DateTime dueDate,
    double fontSize,
  ) {
    final now = DateTime.now();
    final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
    final end = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final completed = completedAt != null
        ? DateTime(completedAt.year, completedAt.month, completedAt.day)
        : null;
    
    // 期間の長さを計算
    final totalDays = end.difference(start).inDays + 1;
    final elapsedDays = completed != null
        ? completed.difference(start).inDays + 1
        : (now.isAfter(start) ? now.difference(start).inDays + 1 : 0);
    
    final isOverdue = completed == null && now.isAfter(end);
    final isCompleted = completed != null;
    final isEarlyCompletion = completed != null && completed.isBefore(end);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final elapsedWidth = elapsedDays > 0
            ? (elapsedDays / totalDays).clamp(0.0, 1.0) * barWidth
            : 0.0;
        
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              // 経過期間のバー（着手日～現在または完了日）
              if (elapsedDays > 0)
                Positioned(
                  left: 0,
                  width: elapsedWidth,
                  height: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? (isEarlyCompletion ? Colors.green : Colors.grey[500])
                          : (isOverdue ? Colors.red[400] : Colors.blue[400]),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              // 完了マーカー
              if (completed != null && elapsedWidth > 0)
                Positioned(
                  left: elapsedWidth.clamp(0.0, barWidth - 4),
                  child: Container(
                    width: 4,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// フィルターダイアログを表示
  Future<void> _showFilterDialog() async {
    TaskStatus? selectedStatus = _filterStatus;
    TaskPriority? selectedPriority = _filterPriority;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('フィルター'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ステータス',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip<TaskStatus?>(
                    'すべて',
                    null,
                    selectedStatus == null,
                    (value) {
                      setDialogState(() {
                        selectedStatus = null;
                      });
                    },
                  ),
                  _buildFilterChip<TaskStatus>(
                    '未着手',
                    TaskStatus.pending,
                    selectedStatus == TaskStatus.pending,
                    (value) {
                      setDialogState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  _buildFilterChip<TaskStatus>(
                    '進行中',
                    TaskStatus.inProgress,
                    selectedStatus == TaskStatus.inProgress,
                    (value) {
                      setDialogState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  _buildFilterChip<TaskStatus>(
                    '完了',
                    TaskStatus.completed,
                    selectedStatus == TaskStatus.completed,
                    (value) {
                      setDialogState(() {
                        selectedStatus = value;
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
                  _buildFilterChip<TaskPriority?>(
                    'すべて',
                    null,
                    selectedPriority == null,
                    (value) {
                      setDialogState(() {
                        selectedPriority = null;
                      });
                    },
                  ),
                  _buildFilterChip<TaskPriority>(
                    '低',
                    TaskPriority.low,
                    selectedPriority == TaskPriority.low,
                    (value) {
                      setDialogState(() {
                        selectedPriority = value;
                      });
                    },
                  ),
                  _buildFilterChip<TaskPriority>(
                    '中',
                    TaskPriority.medium,
                    selectedPriority == TaskPriority.medium,
                    (value) {
                      setDialogState(() {
                        selectedPriority = value;
                      });
                    },
                  ),
                  _buildFilterChip<TaskPriority>(
                    '高',
                    TaskPriority.high,
                    selectedPriority == TaskPriority.high,
                    (value) {
                      setDialogState(() {
                        selectedPriority = value;
                      });
                    },
                  ),
                  _buildFilterChip<TaskPriority>(
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
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterStatus = null;
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
                  _filterStatus = selectedStatus;
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

  Widget _buildFilterChip<T>(
    String label,
    T value,
    bool isSelected,
    ValueChanged<T> onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(value);
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  /// 期間バーの凡例を構築
  Widget _buildPeriodBarLegend(double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            '期間バー:',
            style: TextStyle(
              fontSize: 11 * fontSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          // 進行中
          _buildLegendItem(
            Colors.blue[400]!,
            '進行中',
            fontSize,
          ),
          const SizedBox(width: 12),
          // 期限切れ
          _buildLegendItem(
            Colors.red[400]!,
            '期限切れ',
            fontSize,
          ),
          const SizedBox(width: 12),
          // 早期完了
          _buildLegendItem(
            Colors.green[400]!,
            '早期完了',
            fontSize,
          ),
          const SizedBox(width: 12),
          // 期限日完了
          _buildLegendItem(
            Colors.grey[500]!,
            '期限日完了',
            fontSize,
          ),
          const Spacer(),
          // ショートカットキー表示
          Text(
            'Ctrl+L で表示切替',
            style: TextStyle(
              fontSize: 10 * fontSize,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10 * fontSize,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// ショートカットヘルプダイアログを表示
  void _showShortcutHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ショートカットキー'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShortcutItem('Ctrl+L', '期間バー凡例の表示/非表示'),
              _buildShortcutItem('F1', 'このヘルプを表示'),
              _buildShortcutItem('フィルターアイコン', 'ステータス・優先度でフィルター'),
              _buildShortcutItem('日付範囲アイコン', '表示期間を変更'),
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

  Widget _buildShortcutItem(String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

