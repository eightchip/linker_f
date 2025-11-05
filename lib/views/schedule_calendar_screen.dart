import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
        }
      }
    });
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
    
    // デバッグ用: 予定の数を表示
    if (kDebugMode) {
      print('予定表画面: 予定数 = ${schedules.length}');
      for (final schedule in schedules) {
        print('  予定: ${schedule.title} (${schedule.startDateTime})');
      }
    }
    
    // 日付ごとにグループ化
    final schedulesByDate = <DateTime, List<ScheduleItem>>{};
    for (final schedule in schedules) {
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
        actions: const [],
      ),
      body: schedules.isEmpty
          ? const Center(
              child: Text('予定がありません'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final dateSchedules = schedulesByDate[date]!;
                
                return _buildDateSection(date, dateSchedules, tasks);
              },
            ),
    );
  }

  Widget _buildDateSection(
    DateTime date,
    List<ScheduleItem> schedules,
    List<TaskItem> tasks,
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
}

