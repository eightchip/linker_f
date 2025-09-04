import '../models/task_item.dart';
import '../viewmodels/task_viewmodel.dart';
import 'package:uuid/uuid.dart';

class RecurringTaskService {
  static const _uuid = Uuid();
  
  /// 繰り返しタスクの次の実行日を計算
  static DateTime? calculateNextDueDate(TaskItem task) {
    if (!task.isRecurring || task.dueDate == null) return null;
    
    final now = DateTime.now();
    final lastDueDate = task.dueDate!;
    
    switch (task.recurringPattern) {
      case 'daily':
        return DateTime(lastDueDate.year, lastDueDate.month, lastDueDate.day + 1);
      case 'weekly':
        return DateTime(lastDueDate.year, lastDueDate.month, lastDueDate.day + 7);
      case 'monthly':
        // 翌月の同日（月末の場合は月末日）
        final nextMonth = DateTime(lastDueDate.year, lastDueDate.month + 1, 1);
        final daysInNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final nextDay = lastDueDate.day > daysInNextMonth ? daysInNextMonth : lastDueDate.day;
        return DateTime(nextMonth.year, nextMonth.month, nextDay);
      default:
        return null;
    }
  }
  
  /// 繰り返しタスクの次のリマインダー時刻を計算
  static DateTime? calculateNextReminderTime(TaskItem task) {
    if (!task.isRecurringReminder || task.reminderTime == null) return null;
    
    final now = DateTime.now();
    final lastReminderTime = task.reminderTime!;
    
    // 繰り返しリマインダーパターンに基づいて次の時刻を計算
    switch (task.recurringReminderPattern) {
      case RecurringReminderPattern.fiveMinutes:
        return lastReminderTime.add(const Duration(minutes: 5));
      case RecurringReminderPattern.fifteenMinutes:
        return lastReminderTime.add(const Duration(minutes: 15));
      case RecurringReminderPattern.thirtyMinutes:
        return lastReminderTime.add(const Duration(minutes: 30));
      case RecurringReminderPattern.oneHour:
        return lastReminderTime.add(const Duration(hours: 1));
      case RecurringReminderPattern.oneDay:
        return lastReminderTime.add(const Duration(days: 1));
      case RecurringReminderPattern.oneWeek:
        return lastReminderTime.add(const Duration(days: 7));
      default:
        return null;
    }
  }
  
  /// 完了した繰り返しタスクの次のタスクを生成
  static Future<void> generateNextRecurringTask(TaskItem completedTask, TaskViewModel taskViewModel) async {
    if (!completedTask.isRecurring) return;
    
    final nextDueDate = calculateNextDueDate(completedTask);
    if (nextDueDate == null) return;
    
    // 次のタスクを作成
    final nextTask = TaskItem(
      id: _uuid.v4(),
      title: completedTask.title,
      description: completedTask.description,
      dueDate: nextDueDate,
      reminderTime: completedTask.isRecurringReminder 
          ? calculateNextReminderTime(completedTask)
          : null,
      priority: completedTask.priority,
      status: TaskStatus.pending,
      tags: List.from(completedTask.tags),
      relatedLinkId: completedTask.relatedLinkId,
      createdAt: DateTime.now(),
      estimatedMinutes: completedTask.estimatedMinutes,
      notes: completedTask.notes,
      isRecurring: completedTask.isRecurring,
      recurringPattern: completedTask.recurringPattern,
      isRecurringReminder: completedTask.isRecurringReminder,
      recurringReminderPattern: completedTask.recurringReminderPattern,
      hasSubTasks: completedTask.hasSubTasks,
      completedSubTasksCount: 0,
      totalSubTasksCount: completedTask.totalSubTasksCount,
    );
    
    // 新しいタスクを追加
    await taskViewModel.addTask(nextTask);
  }
  
  /// 期限切れの繰り返しタスクの次のタスクを生成
  static Future<void> generateNextOverdueRecurringTask(TaskItem overdueTask, TaskViewModel taskViewModel) async {
    if (!overdueTask.isRecurring) return;
    
    final nextDueDate = calculateNextDueDate(overdueTask);
    if (nextDueDate == null) return;
    
    // 現在時刻が次の期限を過ぎている場合は、さらに次の期限を計算
    final now = DateTime.now();
    DateTime finalNextDueDate = nextDueDate;
    
    while (finalNextDueDate.isBefore(now)) {
      final tempDate = calculateNextDueDate(TaskItem(
        id: '',
        title: '',
        dueDate: finalNextDueDate,
        createdAt: DateTime.now(),
        isRecurring: true,
        recurringPattern: overdueTask.recurringPattern,
      ));
      
      if (tempDate == null) break;
      finalNextDueDate = tempDate;
    }
    
    // 次のタスクを作成
    final nextTask = TaskItem(
      id: _uuid.v4(),
      title: overdueTask.title,
      description: overdueTask.description,
      dueDate: finalNextDueDate,
      reminderTime: overdueTask.isRecurringReminder 
          ? calculateNextReminderTime(overdueTask)
          : null,
      priority: overdueTask.priority,
      status: TaskStatus.pending,
      tags: List.from(overdueTask.tags),
      relatedLinkId: overdueTask.relatedLinkId,
      createdAt: DateTime.now(),
      estimatedMinutes: overdueTask.estimatedMinutes,
      notes: overdueTask.notes,
      isRecurring: overdueTask.isRecurring,
      recurringPattern: overdueTask.recurringPattern,
      isRecurringReminder: overdueTask.isRecurringReminder,
      recurringReminderPattern: overdueTask.recurringReminderPattern,
      hasSubTasks: overdueTask.hasSubTasks,
      completedSubTasksCount: 0,
      totalSubTasksCount: overdueTask.totalSubTasksCount,
    );
    
    // 新しいタスクを追加
    await taskViewModel.addTask(nextTask);
  }
}
