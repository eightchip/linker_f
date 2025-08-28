import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../viewmodels/task_viewmodel.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() {
    final tasks = ref.read(taskViewModelProvider);
    _events.clear();
    
    for (final task in tasks) {
      if (task.dueDate != null) {
        final date = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        final key = DateTime(date.year, date.month, date.day);
        if (_events[key] == null) _events[key] = [];
        _events[key]!.add(task);
      }
    }
  }

  List<TaskItem> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskViewModelProvider);
    
    // イベントを再読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
        actions: [
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
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
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
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('日付を選択してください'))
                : _buildEventList(),
          ),
        ],
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
          child: ListTile(
            leading: _buildPriorityIndicator(task.priority),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.status == TaskStatus.completed 
                    ? TextDecoration.lineThrough 
                    : null,
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
                    if (task.dueDate != null)
                      Text(
                        '期限: ${DateFormat('HH:mm').format(task.dueDate!)}',
                        style: TextStyle(
                          color: task.isOverdue ? Colors.red : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    if (task.estimatedMinutes != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${task.estimatedMinutes}分',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: _buildStatusChip(task.status),
            onTap: () => _showTaskDetails(task),
          ),
        );
      },
    );
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
        ],
      ),
    );
  }
}
