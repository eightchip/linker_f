import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../viewmodels/task_viewmodel.dart';
import '../services/snackbar_service.dart';
import 'settings_screen.dart';
import 'task_dialog.dart';
import '../services/keyboard_shortcut_service.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TaskItem>> _events = {};
  
  // フィルタリング用の状態
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  bool _showCompletedTasks = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _loadEvents() {
    final tasks = ref.read(taskViewModelProvider);
    _events.clear();
    
    // フィルタリングを適用
    final filteredTasks = tasks.where((task) {
      // 完了タスクの表示/非表示
      if (!_showCompletedTasks && task.status == TaskStatus.completed) {
        return false;
      }
      
      // ステータスフィルタ
      if (_statusFilter != null && task.status != _statusFilter) {
        return false;
      }
      
      // 優先度フィルタ
      if (_priorityFilter != null && task.priority != _priorityFilter) {
        return false;
      }
      
      return true;
    }).toList();
    
    print('=== カレンダーイベント読み込み開始 ===');
    print('読み込まれたタスク数: ${tasks.length}');
    print('フィルタ後タスク数: ${filteredTasks.length}');
    
    for (final task in filteredTasks) {
      print('タスク: ${task.title}');
      print('  期限日: ${task.dueDate}');
      print('  リマインダー時間: ${task.reminderTime}');
      
      // 期限日がある場合
      if (task.dueDate != null) {
        final date = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        final key = DateTime(date.year, date.month, date.day);
        if (_events[key] == null) _events[key] = [];
        _events[key]!.add(task);
        print('  期限日イベント追加: ${key}');
      }
      
      // リマインダー時間がある場合（期限日と異なる日の場合のみ）
      if (task.reminderTime != null) {
        final reminderDate = DateTime(task.reminderTime!.year, task.reminderTime!.month, task.reminderTime!.day);
        final dueDate = task.dueDate != null 
          ? DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day)
          : null;
        
        // リマインダー日が期限日と異なる場合のみ追加
        if (dueDate == null || !isSameDay(reminderDate, dueDate)) {
          final key = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
          if (_events[key] == null) _events[key] = [];
          _events[key]!.add(task);
          print('  リマインダーイベント追加: ${key}');
        } else {
          print('  リマインダー日が期限日と同じためスキップ');
        }
      }
    }
    
    print('イベントマップの内容:');
    _events.forEach((date, eventList) {
      print('  ${date}: ${eventList.length}件のイベント');
      for (final event in eventList) {
        print('    - ${event.title}');
      }
    });
    print('=== カレンダーイベント読み込み完了 ===');
  }

  List<TaskItem> _getEventsForDay(DateTime day) {
    // 日付を正規化してキーとして使用
    final normalizedDay = DateTime(day.year, day.month, day.day);
    
    // イベントマップのキーと一致するかチェック
    final matchingKey = _events.keys.firstWhere(
      (key) => key.year == normalizedDay.year && 
               key.month == normalizedDay.month && 
               key.day == normalizedDay.day,
      orElse: () => normalizedDay,
    );
    
    final events = _events[matchingKey] ?? [];
    if (events.isNotEmpty) {
      print('日付 ${day} のイベント: ${events.length}件');
      for (final event in events) {
        print('  - ${event.title}');
      }
    }
    return events;
  }

  Widget _buildStatisticsSection() {
    final tasks = ref.watch(taskViewModelProvider);
    final now = DateTime.now();
    
    // 今週のタスク統計
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekTasks = tasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return taskDate.isAfter(weekStart.subtract(const Duration(days: 1))) && 
             taskDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
    
    // 今月のタスク統計
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final monthTasks = tasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return taskDate.isAfter(monthStart.subtract(const Duration(days: 1))) && 
             taskDate.isBefore(monthEnd.add(const Duration(days: 1)));
    }).toList();
    
    final weekCompleted = weekTasks.where((task) => task.status == TaskStatus.completed).length;
    final monthCompleted = monthTasks.where((task) => task.status == TaskStatus.completed).length;
    
    final weekCompletionRate = weekTasks.isEmpty ? 0.0 : (weekCompleted / weekTasks.length * 100);
    final monthCompletionRate = monthTasks.isEmpty ? 0.0 : (monthCompleted / monthTasks.length * 100);

    // 期限切れタスクの統計
    final overdueTasks = tasks.where((task) => task.isOverdue).length;
    
    // 緊急タスクの統計
    final urgentTasks = tasks.where((task) => 
        task.priority == TaskPriority.urgent && 
        task.status != TaskStatus.completed
    ).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '今週',
                  '${weekCompleted}/${weekTasks.length}',
                  weekCompletionRate,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '今月',
                  '${monthCompleted}/${monthTasks.length}',
                  monthCompletionRate,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '期限切れ',
                  '$overdueTasks件',
                  0.0,
                  Colors.red,
                  showProgress: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '緊急',
                  '$urgentTasks件',
                  0.0,
                  Colors.purple,
                  showProgress: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String period, String count, double rate, Color color, {bool showProgress = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (showProgress) ...[
          const SizedBox(height: 2),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(taskViewModelProvider);
    
    // タスクが変更されたときにイベントを再読み込み
    _loadEvents();

    return KeyboardShortcutWidget(
      child: Scaffold(
        appBar: AppBar(
        title: const Text('カレンダー'),
        actions: [
          // フィルターメニュー
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case 'show_completed':
                    _showCompletedTasks = !_showCompletedTasks;
                    break;
                  case 'status_pending':
                    _statusFilter = _statusFilter == TaskStatus.pending ? null : TaskStatus.pending;
                    break;
                  case 'status_in_progress':
                    _statusFilter = _statusFilter == TaskStatus.inProgress ? null : TaskStatus.inProgress;
                    break;
                  case 'status_completed':
                    _statusFilter = _statusFilter == TaskStatus.completed ? null : TaskStatus.completed;
                    break;
                  case 'priority_urgent':
                    _priorityFilter = _priorityFilter == TaskPriority.urgent ? null : TaskPriority.urgent;
                    break;
                  case 'priority_high':
                    _priorityFilter = _priorityFilter == TaskPriority.high ? null : TaskPriority.high;
                    break;
                  case 'clear_filters':
                    _statusFilter = null;
                    _priorityFilter = null;
                    _showCompletedTasks = true;
                    break;
                }
                _loadEvents();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'show_completed',
                child: Row(
                  children: [
                    Icon(
                      _showCompletedTasks ? Icons.check_box : Icons.check_box_outline_blank,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    const Text('完了タスクを表示'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'status_pending',
                child: Row(
                  children: [
                    Icon(
                      _statusFilter == TaskStatus.pending ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text('未着手のみ'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'status_in_progress',
                child: Row(
                  children: [
                    Icon(
                      _statusFilter == TaskStatus.inProgress ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    const Text('進行中のみ'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'status_completed',
                child: Row(
                  children: [
                    Icon(
                      _statusFilter == TaskStatus.completed ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    const Text('完了のみ'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'priority_urgent',
                child: Row(
                  children: [
                    Icon(
                      _priorityFilter == TaskPriority.urgent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    const Text('緊急のみ'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'priority_high',
                child: Row(
                  children: [
                    Icon(
                      _priorityFilter == TaskPriority.high ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Text('高優先度のみ'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('フィルターをクリア'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.filter_list),
            ),
          ),
          // カレンダー形式メニュー
          PopupMenuButton<CalendarFormat>(
            onSelected: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarFormat.month,
                child: Text('月間'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.week,
                child: Text('週間'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Text('2週間'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.view_week),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<TaskItem>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onDayLongPressed: (selectedDay, focusedDay) {
              // 日付を長押しでタスク作成
              _showCreateTaskDialog(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.red),
              holidayTextStyle: TextStyle(color: Colors.red),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                print('markerBuilder呼び出し: ${date}, イベント数: ${events.length}');
                if (events.isNotEmpty) {
                  print('イベント詳細:');
                  for (final event in events) {
                    print('  - ${event.title} (優先度: ${event.priority}, ステータス: ${event.status})');
                  }
                  
                  // 優先度とステータスに基づいて色を決定
                  final hasUrgent = events.any((task) => task.priority == TaskPriority.urgent);
                  final hasOverdue = events.any((task) => task.isOverdue);
                  final hasCompleted = events.any((task) => task.status == TaskStatus.completed);
                  
                  Color markerColor;
                  if (hasUrgent) {
                    markerColor = Colors.purple;
                  } else if (hasOverdue) {
                    markerColor = Colors.red;
                  } else if (hasCompleted) {
                    markerColor = Colors.green;
                  } else {
                    markerColor = Colors.blue;
                  }
                  
                  print('マーカー色: ${markerColor}');
                  
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: markerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${events.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),
          // 統計情報を表示
          _buildStatisticsSection(),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('日付を選択してください'))
                : _buildEventList(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return const Center(
        child: Text('この日のタスクはありません'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final task = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: _getTaskCardColor(task),
          child: ListTile(
            leading: _buildPriorityIndicator(task.priority),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.status == TaskStatus.completed 
                    ? TextDecoration.lineThrough 
                    : null,
                color: task.status == TaskStatus.completed 
                    ? Colors.grey[600] 
                    : null,
                fontWeight: task.priority == TaskPriority.urgent 
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null)
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // リマインダー時間の表示
                    if (task.reminderTime != null && isSameDay(task.reminderTime!, _selectedDay!))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'リマインド: ${DateFormat('HH:mm').format(task.reminderTime!)}',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // 期限日の表示
                    if (task.dueDate != null && isSameDay(task.dueDate!, _selectedDay!))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: task.isOverdue ? Colors.red.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '期限: ${DateFormat('HH:mm').format(task.dueDate!)}',
                          style: TextStyle(
                            color: task.isOverdue ? Colors.red.shade800 : Colors.blue.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(task.status),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(task),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: '削除',
                ),
              ],
            ),
            onTap: () => _showTaskDetails(task),
          ),
        );
      },
    );
  }

  Color? _getTaskCardColor(TaskItem task) {
    if (task.status == TaskStatus.completed) {
      return Colors.green.shade50;
    } else if (task.isOverdue) {
      return Colors.red.shade50;
    } else if (task.priority == TaskPriority.urgent) {
      return Colors.purple.shade50;
    } else if (task.priority == TaskPriority.high) {
      return Colors.orange.shade50;
    }
    return null; // デフォルトの色
  }

  Widget _buildPriorityIndicator(TaskPriority priority) {
    Color color;
    IconData icon;

    switch (priority) {
      case TaskPriority.low:
        color = Colors.green;
        icon = Icons.flag;
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        icon = Icons.flag;
        break;
      case TaskPriority.high:
        color = Colors.red;
        icon = Icons.flag;
        break;
      case TaskPriority.urgent:
        color = Colors.purple;
        icon = Icons.flag;
        break;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
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

  void _showCreateTaskDialog(DateTime selectedDay) {
    // 新規タスク作成の場合はnullを渡す
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        task: null, // 新規作成
        initialDueDate: selectedDay, // 初期期限日を設定
      ),
    ).then((_) {
      // ダイアログが閉じられた後にイベントを再読み込み
      setState(() {
        _loadEvents();
      });
    });
  }

  void _showTaskDetails(TaskItem task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) ...[
              const Text('説明:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(task.description!),
              const SizedBox(height: 16),
            ],
            if (task.dueDate != null) ...[
              const Text('期限:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('yyyy/MM/dd HH:mm').format(task.dueDate!)),
              const SizedBox(height: 16),
            ],
            if (task.reminderTime != null) ...[
              const Text('リマインダー:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('yyyy/MM/dd HH:mm').format(task.reminderTime!)),
              const SizedBox(height: 16),
            ],
            if (task.tags.isNotEmpty) ...[
              const Text('タグ:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 4,
                children: task.tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showTaskDialog(task);
            },
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog(TaskItem task) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(task: task),
    ).then((_) {
      // ダイアログが閉じられた後にイベントを再読み込み
      setState(() {
        _loadEvents();
      });
    });
  }

  void _showDeleteConfirmation(TaskItem task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを削除'),
        content: Text('「${task.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCalendarDeleteConfirmation(task);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showCalendarDeleteConfirmation(TaskItem task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを削除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${task.title}」を削除しますか？'),
            const SizedBox(height: 16),
            const Text(
              '削除オプション:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• アプリのみ削除'),
            const Text('• アプリとGoogle Calendarから削除'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final taskViewModel = ref.read(taskViewModelProvider.notifier);
                await taskViewModel.deleteTask(task.id);
                Navigator.of(context).pop();
                
                // イベントを再読み込み
                setState(() {
                  _loadEvents();
                });
                
                if (mounted) {
                  SnackBarService.showSuccess(context, '「${task.title}」を削除しました');
                }
              } catch (e) {
                if (mounted) {
                  SnackBarService.showError(context, '削除に失敗しました: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('アプリのみ', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final taskViewModel = ref.read(taskViewModelProvider.notifier);
                final result = await taskViewModel.deleteTaskWithCalendarSync(task.id);
                Navigator.of(context).pop();
                
                // イベントを再読み込み
                setState(() {
                  _loadEvents();
                });
                
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('両方削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 認証エラーダイアログを表示
  void _showAuthErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Calendar認証エラー'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            const SizedBox(height: 16),
            const Text(
              'Google Calendarとの同期を行うには、設定画面でGoogle Calendarの認証を行う必要があります。',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('設定画面へ'),
          ),
        ],
      ),
    );
  }
}
