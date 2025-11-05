import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/schedule_item.dart';
import '../models/task_item.dart';
import '../viewmodels/schedule_viewmodel.dart';
import '../viewmodels/task_viewmodel.dart';
import 'task_dialog.dart';

class ScheduleCalendarScreen extends ConsumerStatefulWidget {
  const ScheduleCalendarScreen({super.key});

  @override
  ConsumerState<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends ConsumerState<ScheduleCalendarScreen> {
  bool _localeInitialized = false;
  final ScrollController _scrollController = ScrollController();
  
  // 日付範囲フィルター: 'all', 'future', 'past'
  String _dateFilter = 'all';
  
  // 今日の日付の位置を保持
  GlobalKey? _todayKey;

  @override
  void initState() {
    super.initState();
    // 日本語ロケールを初期化
    _initializeLocale();
    // 画面表示時にデータを再読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = ref.read(scheduleViewModelProvider.notifier);
      await vm.waitForInitialization();
      // 初期化完了後にデータを再読み込み
      if (mounted) {
        // データベースから最新のデータを読み込む
        await vm.loadSchedules();
        // Riverpodの状態を強制的に更新
        if (mounted) {
          ref.invalidate(scheduleViewModelProvider);
          // 今日の位置にジャンプ
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToToday();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocale() async {
    if (!_localeInitialized) {
      await initializeDateFormatting('ja_JP', null);
      _localeInitialized = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(scheduleViewModelProvider);
    final tasks = ref.watch(taskViewModelProvider);
    final now = DateTime.now();
    
    // 日付範囲フィルターを適用
    final filteredSchedules = schedules.where((schedule) {
      if (_dateFilter == 'future') {
        return schedule.startDateTime.isAfter(now);
      } else if (_dateFilter == 'past') {
        return schedule.startDateTime.isBefore(now);
      }
      return true; // 'all'
    }).toList();
    
    // 日付ごとにグループ化
    final schedulesByDate = <DateTime, List<ScheduleItem>>{};
    for (final schedule in filteredSchedules) {
      final dateKey = DateTime(
        schedule.startDateTime.year,
        schedule.startDateTime.month,
        schedule.startDateTime.day,
      );
      if (!schedulesByDate.containsKey(dateKey)) {
        schedulesByDate[dateKey] = [];
      }
      schedulesByDate[dateKey]!.add(schedule);
    }

    // 日付順にソート
    final sortedDates = schedulesByDate.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('予定表'),
        actions: [
          // 今日へのジャンプボタン
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '今日にジャンプ',
            onPressed: _scrollToToday,
          ),
          // フィルターメニュー
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'フィルター',
            onSelected: (value) {
              setState(() {
                _dateFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('すべて'),
              ),
              const PopupMenuItem(
                value: 'future',
                child: Text('未来のみ'),
              ),
              const PopupMenuItem(
                value: 'past',
                child: Text('過去のみ'),
              ),
            ],
          ),
        ],
      ),
      body: filteredSchedules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _dateFilter == 'future' ? '未来の予定がありません'
                        : _dateFilter == 'past' ? '過去の予定がありません'
                        : '予定がありません',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final dateSchedules = schedulesByDate[date]!;
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
                
                // 今日の日付のキーを保持
                if (isToday && _todayKey == null) {
                  _todayKey = GlobalKey();
                }
                
                return _buildDateSection(
                  date,
                  dateSchedules,
                  tasks,
                  isToday ? _todayKey : null,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        tooltip: '予定を追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _scrollToToday() {
    if (_todayKey?.currentContext != null) {
      Scrollable.ensureVisible(
        _todayKey!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _showAddScheduleDialog() async {
    final tasks = ref.read(taskViewModelProvider);
    if (tasks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予定を追加するには、まずタスクを作成してください')),
        );
      }
      return;
    }

    // タスク選択ダイアログ
    final selectedTask = await showDialog<TaskItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.title),
                onTap: () => Navigator.pop(context, task),
              );
            },
          ),
        ),
      ),
    );

    if (selectedTask != null && mounted) {
      // タスク編集モーダルを開く（予定セクションを展開）
      showDialog(
        context: context,
        builder: (context) => TaskDialog(task: selectedTask),
      );
    }
  }

  Widget _buildDateSection(
    DateTime date,
    List<ScheduleItem> schedules,
    List<TaskItem> tasks,
    GlobalKey? dateKey,
  ) {
    // ロケールが初期化されていない場合はデフォルト形式を使用
    final dateFormat = _localeInitialized
        ? DateFormat('yyyy年MM月dd日(E)', 'ja_JP')
        : DateFormat('yyyy/MM/dd (E)');
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: dateKey,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isToday ? Colors.blue.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                dateFormat.format(date),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.blue.shade900 : Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue.shade300 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${schedules.length}件',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...schedules.map((schedule) {
          TaskItem task;
          try {
            task = tasks.firstWhere((t) => t.id == schedule.taskId);
          } catch (e) {
            task = TaskItem(
              id: schedule.taskId,
              title: 'タスクが見つかりません',
              createdAt: DateTime.now(),
            );
          }
          
          return _buildScheduleCard(schedule, task);
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildScheduleCard(ScheduleItem schedule, TaskItem task) {
    final timeFormat = DateFormat('HH:mm');
    final hasEndTime = schedule.endDateTime != null;
    final timeText = hasEndTime
        ? '${timeFormat.format(schedule.startDateTime)} - ${timeFormat.format(schedule.endDateTime!)}'
        : timeFormat.format(schedule.startDateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // タスク編集モーダルを開く
          final tasks = ref.read(taskViewModelProvider);
          try {
            final task = tasks.firstWhere((t) => t.id == schedule.taskId);
            showDialog(
              context: context,
              builder: (context) => TaskDialog(task: task),
            );
          } catch (e) {
            // タスクが見つからない場合は何もしない
          }
        },
        onLongPress: () {
          _showScheduleMenu(schedule, task);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (schedule.location != null && schedule.location!.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        schedule.location!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                schedule.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  // タスク編集モーダルを開く
                  final tasks = ref.read(taskViewModelProvider);
                  try {
                    final task = tasks.firstWhere((t) => t.id == schedule.taskId);
                    showDialog(
                      context: context,
                      builder: (context) => TaskDialog(task: task),
                    );
                  } catch (e) {
                    // タスクが見つからない場合は何もしない
                  }
                },
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  schedule.notes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleMenu(ScheduleItem schedule, TaskItem task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('編集'),
              onTap: () {
                Navigator.pop(context);
                _editSchedule(schedule, task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('コピー'),
              onTap: () {
                Navigator.pop(context);
                _copySchedule(schedule, task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('削除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteSchedule(schedule);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSchedule(ScheduleItem schedule, TaskItem task) async {
    // タスク編集モーダルを開く（予定セクションを展開）
    await showDialog(
      context: context,
      builder: (context) => TaskDialog(task: task),
    );
    
    // モーダルが閉じた後にデータを再読み込み
    if (mounted) {
      final vm = ref.read(scheduleViewModelProvider.notifier);
      await vm.loadSchedules();
    }
  }

  Future<void> _copySchedule(ScheduleItem schedule, TaskItem task) async {
    // 日時選択ダイアログ
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: schedule.startDateTime.add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate == null || !mounted) return;
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(schedule.startDateTime),
    );
    
    if (pickedTime == null || !mounted) return;
    
    // 終了日時の計算
    DateTime? newEndDateTime;
    if (schedule.endDateTime != null) {
      final duration = schedule.endDateTime!.difference(schedule.startDateTime);
      newEndDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ).add(duration);
    }
    
    // 新しい予定を作成
    final vm = ref.read(scheduleViewModelProvider.notifier);
    final newSchedule = vm.createSchedule(
      taskId: schedule.taskId,
      title: schedule.title,
      startDateTime: DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
      endDateTime: newEndDateTime,
      location: schedule.location,
      notes: schedule.notes,
    );
    
    await vm.addSchedule(newSchedule);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予定をコピーしました')),
      );
    }
  }

  Future<void> _deleteSchedule(ScheduleItem schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予定を削除'),
        content: Text('「${schedule.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      final vm = ref.read(scheduleViewModelProvider.notifier);
      await vm.deleteSchedule(schedule.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予定を削除しました')),
        );
      }
    }
  }
}

