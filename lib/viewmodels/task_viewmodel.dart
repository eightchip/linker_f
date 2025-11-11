import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../models/sub_task.dart';
import '../services/notification_service.dart';
import 'dart:io';
import 'dart:math' as math;
import '../services/windows_notification_service.dart';
import '../services/google_calendar_service.dart';
import '../services/settings_service.dart';
import 'link_viewmodel.dart';
import 'sub_task_viewmodel.dart';

final taskViewModelProvider = StateNotifierProvider<TaskViewModel, List<TaskItem>>((ref) {
  return TaskViewModel(ref);
});

class TaskViewModel extends StateNotifier<List<TaskItem>> {
  final Ref _ref;
  
  TaskViewModel(this._ref) : super([]) {
    print('🚨 TaskViewModel作成');
    // 非同期初期化を即座に実行
    _initializeTaskBox().catchError((error) {
      print('🚨 TaskViewModel初期化エラー: $error');
      state = [];
    });
  }

  static const String _boxName = 'tasks';
  Box<TaskItem>? _taskBox;
  Box<dynamic>? _taskDatesBox;
  final _uuid = const Uuid();

  // tasksプロパティを追加
  List<TaskItem> get tasks => state;
  
  // 手動でタスクを再読み込み
  Future<void> forceReloadTasks() async {
    print('🚨🚨🚨 手動タスク再読み込み開始 🚨🚨🚨');
    await _loadTasks();
    print('🚨🚨🚨 手動タスク再読み込み完了: ${state.length}件 🚨🚨🚨');
  }

  // _taskBoxの初期化を確実に行う
  Future<void> _initializeTaskBox() async {
    try {
      print('🚨 TaskViewModel初期化開始');
      _taskBox = await Hive.openBox<TaskItem>(_boxName);
      print('🚨 Hiveボックス初期化完了');
      
      // WindowsNotificationServiceのコールバックを設定
      WindowsNotificationService.setTaskViewModelUpdateCallback((updatedTask) {
        updateTask(updatedTask);
      });
      
      // WindowsNotificationServiceのリマインダー復元コールバックを設定
      WindowsNotificationService.setRestoreRemindersCallback((tasks) {
        _restoreRemindersFromCallback(tasks);
      });
      
      // WindowsNotificationServiceのタスク取得コールバックを設定
      WindowsNotificationService.setGetTasksCallback(() {
        return state;
      });
      
      // WindowsNotificationServiceのTaskViewModel更新コールバックを設定
      WindowsNotificationService.setTaskViewModelUpdateCallback((updatedTask) {
        updateTask(updatedTask);
      });
      
      await _loadTasks();
      print('🚨 TaskViewModel初期化完了');
    } catch (e) {
      print('TaskViewModel初期化エラー: $e');
      state = [];
    }
  }

  Future<void> _loadTasks() async {
    try {
      print('🚨 タスク読み込み開始');
      if (_taskBox == null || !_taskBox!.isOpen) {
        _taskBox = await Hive.openBox<TaskItem>(_boxName);
      }
      
      final tasks = _taskBox!.values.toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('🚨 読み込まれたタスク数: ${tasks.length}');
      
      state = tasks;
      
      // サブタスク統計を更新
      print('🚨 サブタスク統計更新開始');
      for (int i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        try {
          await updateSubTaskStatistics(task.id);
          // 更新されたタスクを取得
          final updatedTask = _taskBox?.get(task.id);
          if (updatedTask != null) {
            tasks[i] = updatedTask;
          }
        } catch (e) {
          print('❌ サブタスク統計更新エラー (${task.title}): $e');
        }
      }
      print('🚨 サブタスク統計更新完了');
      
      // 更新されたタスクリストでstateを更新
      state = tasks;
      await _cleanupInvalidLinkReferences();
      await _removeHolidayTasksOnStartup();
      print('🚨 タスク読み込み完了: ${state.length}件');
    } catch (e) {
      print('❌ _loadTasksエラー: $e');
      print('エラーの詳細: ${e.toString()}');
      print('スタックトレース: ${StackTrace.current}');
      state = [];
    }
  }

  Future<void> _updateTaskDates(
    String taskId, {
    DateTime? startedAt,
    DateTime? completedAt,
    bool clearStarted = false,
    bool clearCompleted = false,
    bool overwriteStarted = true,
    bool overwriteCompleted = true,
  }) async {
    try {
      _taskDatesBox ??= await Hive.openBox('taskDates');
      final existingRaw = _taskDatesBox!.get(taskId);
      final existing = existingRaw is Map ? Map<String, dynamic>.from(existingRaw) : <String, dynamic>{};

      if (clearStarted) {
        existing.remove('startedAt');
      } else if (startedAt != null && (overwriteStarted || !existing.containsKey('startedAt'))) {
        final normalized = DateTime(startedAt.year, startedAt.month, startedAt.day);
        existing['startedAt'] = normalized.toIso8601String();
      }

      if (clearCompleted) {
        existing.remove('completedAt');
      } else if (completedAt != null && (overwriteCompleted || !existing.containsKey('completedAt'))) {
        final normalized = DateTime(completedAt.year, completedAt.month, completedAt.day);
        existing['completedAt'] = normalized.toIso8601String();
      }

      if (existing.isEmpty) {
        await _taskDatesBox!.delete(taskId);
      } else {
        await _taskDatesBox!.put(taskId, existing);
      }
      await _taskDatesBox!.flush();
    } catch (e) {
      if (kDebugMode) {
        print('タスク日付更新エラー: $e');
      }
    }
  }

  // 起動時に祝日タスクを自動削除
  Future<void> _removeHolidayTasksOnStartup() async {
    try {
      print('=== 祝日タスク削除チェック開始 ===');
      final existingTasks = state;
      print('現在のタスク数: ${existingTasks.length}');
      
      final tasksToDelete = <TaskItem>[];
      
      // 祝日タスクを検出
      for (final task in existingTasks) {
        print('タスクをチェック: ${task.title}');
        if (_isHolidayEvent(task)) {
          print('❌ 祝日タスクとして検出: ${task.title}');
          tasksToDelete.add(task);
        } else {
          print('✅ 通常タスク: ${task.title}');
        }
      }
      
      if (tasksToDelete.isNotEmpty) {
        print('=== 起動時祝日タスク削除開始 ===');
        print('削除対象の祝日タスク数: ${tasksToDelete.length}');
        
        // 削除対象のタスクを詳細出力
        for (final taskToDelete in tasksToDelete) {
          print('削除対象: ${taskToDelete.title} (ID: ${taskToDelete.id})');
        }
        
        // 祝日タスクを直接削除
        for (final taskToDelete in tasksToDelete) {
          print('削除実行: ${taskToDelete.title}');
          await _deleteTaskDirectly(taskToDelete.id);
        }
        
        print('=== 起動時祝日タスク削除完了 ===');
        print('削除されたタスク数: ${tasksToDelete.length}件');
      } else {
        print('祝日タスクは見つかりませんでした');
      }
      
      print('=== 祝日タスク削除チェック完了 ===');
    } catch (e) {
      print('❌ 起動時祝日タスク削除エラー: $e');
      print('エラーの詳細: ${e.toString()}');
    }
  }

  Future<void> addTask(TaskItem task) async {
    try {
      if (_taskBox == null || !_taskBox!.isOpen) {
        await _loadTasks();
      }
      await _taskBox!.put(task.id, task);
      await _taskBox!.flush(); // データの永続化を確実にする
      final newTasks = [task, ...state];
      newTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = newTasks;

      // リマインダー通知をスケジュール（エラーが発生しても続行）
      try {
        if (task.reminderTime != null) {
          print('=== タスク作成時のリマインダー設定 ===');
          print('タスク: ${task.title}');
          print('リマインダー時間: ${task.reminderTime}');
          print('現在時刻: ${DateTime.now()}');
          
          if (Platform.isWindows) {
            await WindowsNotificationService.scheduleTaskReminder(task);
          } else {
            await NotificationService.scheduleTaskReminder(task);
          }
          
          print('=== タスク作成時のリマインダー設定完了 ===');
        } else {
          print('=== タスク作成時のリマインダーなし ===');
          print('タスク: ${task.title}');
          print('リマインダー時間: null');
        }
      } catch (notificationError) {
        print('通知設定エラー（無視）: $notificationError');
      }

      // リンクのタスク状態を更新
      await _updateLinkTaskStatus();
      
      // 新規タスクのサブタスク統計を初期化
      print('=== 新規タスク作成時のサブタスク統計初期化 ===');
      print('タスク: ${task.title} (ID: ${task.id})');
      await updateSubTaskStatistics(task.id);
      print('=== 新規タスク作成時のサブタスク統計初期化完了 ===');

      // Google Calendar自動同期（認証が有効な場合）
      await _autoSyncToGoogleCalendar(task);

      if (kDebugMode) {
        print('タスク追加: ${task.title}');
        if (task.reminderTime != null) {
          print('リマインダー設定: ${task.reminderTime}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスク追加エラー: $e');
      }
    }
  }

  /// Google Calendarからインポートしたタスクを追加（サブタスク統計を初期化しない）
  Future<void> _addTaskFromGoogleCalendar(TaskItem task) async {
    try {
      if (_taskBox == null || !_taskBox!.isOpen) {
        await _loadTasks();
      }
      await _taskBox!.put(task.id, task);
      await _taskBox!.flush(); // データの永続化を確実にする
      final newTasks = [task, ...state];
      newTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = newTasks;

      // リマインダー通知をスケジュール（エラーが発生しても続行）
      try {
        if (task.reminderTime != null) {
          print('=== Google Calendarインポート時のリマインダー設定 ===');
          print('タスク: ${task.title}');
          print('リマインダー時間: ${task.reminderTime}');
          print('現在時刻: ${DateTime.now()}');
          
          if (Platform.isWindows) {
            await WindowsNotificationService.scheduleTaskReminder(task);
          } else {
            await NotificationService.scheduleTaskReminder(task);
          }
          
          print('=== Google Calendarインポート時のリマインダー設定完了 ===');
        } else {
          print('=== Google Calendarインポート時のリマインダーなし ===');
          print('タスク: ${task.title}');
          print('リマインダー時間: null');
        }
      } catch (notificationError) {
        print('通知設定エラー（無視）: $notificationError');
      }

      // リンクのタスク状態を更新
      await _updateLinkTaskStatus();
      
      // サブタスク統計は初期化しない（Google Calendarから復元された値を保持）
      print('=== Google Calendarインポート時のサブタスク統計保持 ===');
      print('タスク: ${task.title} (ID: ${task.id})');
      print('サブタスク統計: ${task.totalSubTasksCount}/${task.completedSubTasksCount}');
      print('=== Google Calendarインポート時のサブタスク統計保持完了 ===');

      // Google Calendar自動同期は実行しない（既にGoogle Calendarから来たタスクのため）

      if (kDebugMode) {
        print('Google Calendarタスク追加: ${task.title}');
        print('サブタスク統計保持: ${task.totalSubTasksCount}/${task.completedSubTasksCount}');
        if (task.reminderTime != null) {
          print('リマインダー設定: ${task.reminderTime}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Google Calendarタスク追加エラー: $e');
      }
    }
  }

  /// 指定されたリンクIDを参照しているタスクからそのリンクIDを削除
  Future<void> removeLinkIdFromTasks(String linkId) async {
    try {
      print('🔗 リンクID削除開始: $linkId');
      
      if (_taskBox == null || !_taskBox!.isOpen) {
        await _loadTasks();
      }
      
      bool hasChanges = false;
      final updatedTasks = <TaskItem>[];
      
      for (final task in state) {
        bool taskUpdated = false;
        List<String> updatedLinkIds = List.from(task.relatedLinkIds);
        
        // 古い形式のリンクIDをチェック
        if (task.relatedLinkId == linkId) {
          final updatedTask = task.copyWith(relatedLinkId: null);
          updatedTasks.add(updatedTask);
          taskUpdated = true;
          hasChanges = true;
          print('🔗 古い形式のリンクIDを削除: ${task.title}');
        }
        // 新しい形式のリンクIDをチェック
        else if (updatedLinkIds.contains(linkId)) {
          updatedLinkIds.remove(linkId);
          final updatedTask = task.copyWith(relatedLinkIds: updatedLinkIds);
          updatedTasks.add(updatedTask);
          taskUpdated = true;
          hasChanges = true;
          print('🔗 新しい形式のリンクIDを削除: ${task.title}');
        }
        
        if (!taskUpdated) {
          updatedTasks.add(task);
        }
      }
      
      if (hasChanges) {
        // データベースを更新
        for (final task in updatedTasks) {
          await _taskBox!.put(task.id, task);
        }
        await _taskBox!.flush();
        
        // 状態を更新
        state = updatedTasks;
        
        print('🔗 リンクID削除完了: $linkId');
      } else {
        print('🔗 削除対象のリンクIDを持つタスクが見つかりませんでした: $linkId');
      }
    } catch (e) {
      print('🔗 リンクID削除エラー: $e');
    }
  }

  Future<void> updateTask(TaskItem task) async {
    try {
      if (_taskBox == null || !_taskBox!.isOpen) {
        await _loadTasks();
      }
      
      // 既存のタスクを取得してリマインダー時間の変更をチェック
      final existingTask = state.firstWhere((t) => t.id == task.id);
      final reminderTimeChanged = existingTask.reminderTime != task.reminderTime;
      
      print('=== タスク更新開始 ===');
      print('タスクID: ${task.id}');
      print('タスクタイトル: ${task.title}');
      print('更新前の期限日: ${existingTask.dueDate}');
      print('更新後の期限日: ${task.dueDate}');
      print('更新前のリマインダー時間: ${existingTask.reminderTime}');
      print('更新後のリマインダー時間: ${task.reminderTime}');
      print('更新前のステータス: ${existingTask.status}');
      print('更新後のステータス: ${task.status}');
      
      await _taskBox!.put(task.id, task);
      await _taskBox!.flush(); // データの永続化を確実にする
      
      print('Hiveへの保存完了');
      
      final newTasks = state.map((t) => t.id == task.id ? task : t).toList();
      newTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = newTasks;
      
      print('状態更新完了');
      print('=== タスク更新完了 ===');
      
      // Google Calendar自動同期（認証が有効な場合）
      await _autoSyncToGoogleCalendar(task);
      
      // リマインダー時間または期限日が変更された場合のみ通知を更新
      final dueDateChanged = existingTask.dueDate != task.dueDate;
      if (reminderTimeChanged || dueDateChanged) {
        try {
          if (reminderTimeChanged) {
            if (task.reminderTime != null) {
              print('=== タスク更新時のリマインダー設定 ===');
              print('タスク: ${task.title}');
              print('リマインダー時間: ${task.reminderTime}');
              print('変更前のリマインダー時間: ${existingTask.reminderTime}');
              
              if (Platform.isWindows) {
                await WindowsNotificationService.scheduleTaskReminder(task);
              } else {
                await NotificationService.scheduleTaskReminder(task);
              }
              
              print('=== タスク更新時のリマインダー設定完了 ===');
            } else {
              print('=== タスク更新時のリマインダー削除 ===');
              print('タスク: ${task.title}');
              print('変更前のリマインダー時間: ${existingTask.reminderTime}');
              
              if (Platform.isWindows) {
                await WindowsNotificationService.cancelNotification(task.id);
              } else {
                await NotificationService.cancelNotification(task.id);
              }
              
              print('=== タスク更新時のリマインダー削除完了 ===');
            }
          }
          
          if (dueDateChanged) {
            print('=== タスク更新時の期限日変更 ===');
            print('タスク: ${task.title}');
            print('新しい期限日: ${task.dueDate}');
            print('変更前の期限日: ${existingTask.dueDate}');
            print('=== タスク更新時の期限日変更完了 ===');
          }
        } catch (notificationError) {
          print('通知更新エラー（無視）: $notificationError');
        }
      } else {
        print('=== タスク更新時のリマインダー変更なし ===');
        print('タスク: ${task.title}');
        print('リマインダー時間変更なし: ${task.reminderTime}');
      }
      
      // リンクのタスク状態を更新
      await _updateLinkTaskStatus();
      
      if (kDebugMode) {
        print('タスク更新: ${task.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスク更新エラー: $e');
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      if (_taskBox == null || !_taskBox!.isOpen) {
        await _loadTasks();
      }
      await _taskBox!.delete(taskId);
      await _taskBox!.flush(); // データの永続化を確実にする
      state = state.where((task) => task.id != taskId).toList();
      
      // 通知をキャンセル（エラーが発生しても続行）
      try {
        print('=== タスク削除時のリマインダー削除 ===');
        print('タスクID: $taskId');
        
        if (Platform.isWindows) {
          await WindowsNotificationService.cancelNotification(taskId);
        } else {
          await NotificationService.cancelNotification(taskId);
        }
        
        print('=== タスク削除時のリマインダー削除完了 ===');
      } catch (notificationError) {
        print('通知キャンセルエラー（無視）: $notificationError');
      }
      
      // リンクのタスク状態を更新
      await _updateLinkTaskStatus();
      
      if (kDebugMode) {
        print('タスク削除: $taskId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスク削除エラー: $e');
      }
    }
  }

  Future<void> startTask(String taskId) async {
    try {
      final task = state.firstWhere((t) => t.id == taskId);
      final startTime = DateTime.now();
      
      final updatedTask = task.copyWith(
        status: TaskStatus.inProgress,
        completedAt: null,
        dueDate: task.dueDate, // 期限日を保持
        reminderTime: task.reminderTime, // リマインダー時間を保持
      );
      
      await updateTask(updatedTask);
      await _updateTaskDates(
        taskId,
        startedAt: startTime,
        overwriteStarted: false,
        clearCompleted: true,
      );
      
      // リンクのタスク状態を更新
      await _updateLinkTaskStatus();
      
      if (kDebugMode) {
        print('タスク開始: ${task.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスク開始エラー: $e');
      }
    }
  }

  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    switch (status) {
      case TaskStatus.inProgress:
        await startTask(taskId);
        return;
      case TaskStatus.completed:
        await completeTask(taskId);
        return;
      case TaskStatus.pending:
      case TaskStatus.cancelled:
        try {
          final task = state.firstWhere((t) => t.id == taskId);
          final shouldClearReminder = status == TaskStatus.cancelled;

          final updatedTask = task.copyWith(
            status: status,
            completedAt: status == TaskStatus.pending ? null : task.completedAt,
            reminderTime: shouldClearReminder ? null : task.reminderTime,
            isRecurringReminder: shouldClearReminder ? false : task.isRecurringReminder,
            recurringReminderPattern: shouldClearReminder ? '' : task.recurringReminderPattern,
            nextReminderTime: shouldClearReminder ? null : task.nextReminderTime,
          );

          await updateTask(updatedTask);
          await _updateTaskDates(
            taskId,
            clearStarted: true,
            clearCompleted: true,
          );
        } catch (e) {
          if (kDebugMode) {
            print('タスクステータス更新エラー: $e');
          }
        }
        return;
    }
  }

  Future<void> setTaskPriority(String taskId, TaskPriority priority) async {
    try {
      final task = state.firstWhere((t) => t.id == taskId);
      if (task.priority == priority) {
        return;
      }

      final updatedTask = task.copyWith(priority: priority);
      await updateTask(updatedTask);
    } catch (e) {
      if (kDebugMode) {
        print('タスク優先度更新エラー: $e');
      }
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      final task = state.firstWhere((t) => t.id == taskId);
      final completionTime = DateTime.now();
      
      // リマインダーをクリア
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        completedAt: completionTime,
        reminderTime: null, // リマインダーをクリア
        isRecurringReminder: false, // 繰り返しリマインダーもクリア
        recurringReminderPattern: '', // 繰り返しパターンもクリア
        nextReminderTime: null, // 次のリマインダー時間もクリア
        reminderCount: 0, // リマインダーカウントもリセット
      );
      
      await updateTask(updatedTask);
      await _updateTaskDates(
        taskId,
        completedAt: completionTime,
        overwriteCompleted: true,
      );
      
      // 通知をキャンセル
      try {
        print('=== タスク完了時のリマインダー削除 ===');
        print('タスク: ${task.title}');
        
        if (Platform.isWindows) {
          await WindowsNotificationService.cancelNotification(taskId);
        } else {
          await NotificationService.cancelNotification(taskId);
        }
        
        print('=== タスク完了時のリマインダー削除完了 ===');
      } catch (notificationError) {
        print('通知キャンセルエラー（無視）: $notificationError');
      }
      
      if (kDebugMode) {
        print('タスク完了: ${task.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスク完了エラー: $e');
      }
    }
  }

  // 今日のタスクを取得
  List<TaskItem> get todayTasks {
    return state.where((task) => task.isToday && task.status != TaskStatus.completed).toList();
  }

  // 今週のタスクを取得
  List<TaskItem> get thisWeekTasks {
    return state.where((task) => task.isThisWeek && task.status != TaskStatus.completed).toList();
  }

  // 期限切れのタスクを取得
  List<TaskItem> get overdueTasks {
    return state.where((task) => task.isOverdue).toList();
  }

  // 優先度別のタスクを取得
  List<TaskItem> getTasksByPriority(TaskPriority priority) {
    return state.where((task) => task.priority == priority && task.status != TaskStatus.completed).toList();
  }

  // ステータス別のタスクを取得
  List<TaskItem> getTasksByStatus(TaskStatus status) {
    return state.where((task) => task.status == status).toList();
  }

  // タグ別のタスクを取得
  List<TaskItem> getTasksByTag(String tag) {
    return state.where((task) => task.tags.contains(tag)).toList();
  }

  // リンクに関連するタスクを取得（後方互換性のため残す）
  List<TaskItem> getTasksByLinkId(String linkId) {
    return state.where((task) => 
      task.relatedLinkId == linkId || 
      task.relatedLinkIds.contains(linkId)
    ).toList();
  }
  
  // タスクにリンクを追加
  Future<void> addLinkToTask(String taskId, String linkId) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      final updatedRelatedLinkIds = List<String>.from(task.relatedLinkIds);
      
      if (!updatedRelatedLinkIds.contains(linkId)) {
        updatedRelatedLinkIds.add(linkId);
        
        final updatedTask = task.copyWith(
          relatedLinkIds: updatedRelatedLinkIds,
          // 最初のリンクがない場合は設定
          relatedLinkId: task.relatedLinkId ?? linkId,
        );
        
        state[taskIndex] = updatedTask;
        await _taskBox?.put(taskId, updatedTask);
        
        // データベースの整合性を確保
        await _taskBox?.flush();
        
        // リンクのタスク状態を更新
        await refreshLinkTaskStatus();
        
        if (kDebugMode) {
          print('✅ リンク追加完了: タスク「${task.title}」にリンク「$linkId」を追加');
        }
      }
    }
  }
  
  // タスクからリンクを削除
  Future<void> removeLinkFromTask(String taskId, String linkId) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      final updatedRelatedLinkIds = List<String>.from(task.relatedLinkIds);
      
      if (updatedRelatedLinkIds.contains(linkId)) {
        updatedRelatedLinkIds.remove(linkId);
        
        final updatedTask = task.copyWith(
          relatedLinkIds: updatedRelatedLinkIds,
          relatedLinkId: task.relatedLinkId == linkId
              ? (updatedRelatedLinkIds.isNotEmpty ? updatedRelatedLinkIds.first : null)
              : task.relatedLinkId,
        );
        
        state[taskIndex] = updatedTask;
        await _taskBox?.put(taskId, updatedTask);
        
        // データベースの整合性を確保
        await _taskBox?.flush();
        
        // リンクのタスク状態を更新
        await refreshLinkTaskStatus();
        
        if (kDebugMode) {
          print('✅ リンク削除完了: タスク「${task.title}」からリンク「$linkId」を削除');
        }
      }
    }
  }

  // 新しいタスクを作成
  TaskItem createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderTime,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.pending,
    List<String> tags = const [],
    String? relatedLinkId,
    List<String> relatedLinkIds = const [],
    int? estimatedMinutes,
    String? notes,
    String? assignedTo,
    bool isRecurring = false,
    String? recurringPattern,
    bool isRecurringReminder = false,
    String? recurringReminderPattern,
    DateTime? nextReminderTime,
    int reminderCount = 0,
    String? source,
    String? externalId,
  }) {
    // 後方互換性のため、relatedLinkIdがある場合はrelatedLinkIdsに追加
    List<String> finalRelatedLinkIds = List.from(relatedLinkIds);
    if (relatedLinkId != null && !finalRelatedLinkIds.contains(relatedLinkId)) {
      finalRelatedLinkIds.add(relatedLinkId);
    }
    
    return TaskItem(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      reminderTime: reminderTime,
      priority: priority,
      status: status,
      tags: tags,
      relatedLinkId: relatedLinkId,
      relatedLinkIds: finalRelatedLinkIds,
      createdAt: DateTime.now(),
      estimatedMinutes: estimatedMinutes,
      notes: notes,
      assignedTo: assignedTo,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
      isRecurringReminder: isRecurringReminder,
      recurringReminderPattern: recurringReminderPattern,
      nextReminderTime: nextReminderTime,
      reminderCount: reminderCount,
      source: source,
      externalId: externalId,
    );
  }

  // タスクをGoogle Calendarに送信（個別送信）
  Future<bool> syncTaskToGoogleCalendar(TaskItem task) async {
    try {
      final googleCalendarService = GoogleCalendarService();
      await googleCalendarService.initialize();
      
      if (task.googleCalendarEventId != null) {
        // 既存のイベントを更新
        final success = await googleCalendarService.updateCalendarEvent(task, task.googleCalendarEventId!);
        return success;
      } else {
        // 新しいイベントを作成（重複チェック付き）
        final result = await googleCalendarService.createCalendarEvent(task);
        if (result.success && result.details != null) {
          // 同期結果からイベントIDを取得してタスクを更新
          final eventId = result.details!['eventId'];
          if (eventId != null) {
            final updatedTask = task.copyWith(googleCalendarEventId: eventId);
            updateTask(updatedTask);
            if (kDebugMode) {
              print('タスクにGoogle CalendarイベントIDを設定: ${task.title} -> $eventId');
            }
          }
        }
        return result.success;
      }
    } catch (e) {
      print('Google Calendar同期エラー: $e');
      return false;
    }
  }

  // Google Calendarからアプリに同期（Google Calendarにのみ存在するイベントをアプリに追加）
  Future<Map<String, dynamic>> syncFromGoogleCalendarToApp() async {
    try {
      final googleCalendarService = GoogleCalendarService();
      await googleCalendarService.initialize();
      
      print('=== TaskViewModel: Google Calendar → アプリ同期開始 ===');
      
      // 1. Google Calendarからイベントを取得
      final startTime = DateTime.now().subtract(const Duration(days: 30));
      final endTime = DateTime.now().add(const Duration(days: 365));
      
      final calendarEvents = await googleCalendarService.getEvents(
        startTime: startTime,
        endTime: endTime,
        maxResults: 1000,
      );
      
      // 2. Google Calendarイベントをタスクに変換
      final calendarTasks = googleCalendarService.convertEventsToTasks(calendarEvents);
      
      print('Google Calendarから取得したタスク数: ${calendarTasks.length}');
      
      // 3. 実際にタスクをアプリに追加
      await syncTasksFromGoogleCalendar(calendarTasks);
      
      print('=== TaskViewModel: Google Calendar → アプリ同期完了 ===');
      
      return {
        'success': true,
        'added': calendarTasks.length,
        'skipped': 0,
      };
    } catch (e) {
      print('Google Calendar → アプリ同期エラー: $e');
      return {
        'success': false,
        'error': e.toString(),
        'added': 0,
        'skipped': 0,
      };
    }
  }

  // 全タスクをGoogle Calendarに包括的同期
  Future<Map<String, dynamic>> syncAllTasksToGoogleCalendar() async {
    try {
      final googleCalendarService = GoogleCalendarService();
      await googleCalendarService.initialize();
      
      print('=== TaskViewModel: 包括的Google Calendar同期開始 ===');
      print('現在のタスク数: ${state.length}');
      
      final result = await googleCalendarService.syncAllTasksToGoogleCalendar(state);
      
      print('=== TaskViewModel: 包括的Google Calendar同期完了 ===');
      print('結果: $result');
      
      return result;
    } catch (e) {
      print('Google Calendar包括的同期エラー: $e');
      return {
        'success': false,
        'error': e.toString(),
        'created': 0,
        'updated': 0,
        'deleted': 0,
      };
    }
  }

  // 繰り返しリマインダーの次の通知をスケジュール
  Future<void> scheduleNextRecurringReminder(TaskItem task) async {
    try {
      print('=== 繰り返しリマインダー次回設定開始 ===');
      print('タスク: ${task.title}');
      print('現在のリマインダー回数: ${task.reminderCount}');
      
      if (!task.isRecurringReminder || task.recurringReminderPattern == null) {
        print('繰り返しリマインダーが設定されていません');
        return;
      }
      
      // 次のリマインダー時間を計算
      final now = DateTime.now();
      final duration = RecurringReminderPattern.getDuration(task.recurringReminderPattern!);
      final nextReminderTime = now.add(duration);
      
      // タスクを更新
      final updatedTask = task.copyWith(
        reminderTime: nextReminderTime,
        nextReminderTime: nextReminderTime,
        reminderCount: task.reminderCount + 1,
      );
      
      // タスクを更新
      await updateTask(updatedTask);
      
      print('次のリマインダー設定完了: $nextReminderTime');
      print('=== 繰り返しリマインダー次回設定完了 ===');
    } catch (e) {
      print('繰り返しリマインダー次回設定エラー: $e');
    }
  }

  // タスクの統計情報を取得
  Map<String, int> getTaskStatistics() {
    final total = state.length;
    final completed = state.where((task) => task.status == TaskStatus.completed).length;
    final pending = state.where((task) => task.status == TaskStatus.pending).length;
    final inProgress = state.where((task) => task.status == TaskStatus.inProgress).length;
    final overdue = overdueTasks.length;
    final today = todayTasks.length;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'inProgress': inProgress,
      'overdue': overdue,
      'today': today,
    };
  }

  // データをエクスポート
  Map<String, dynamic> exportData() {
    return {
      'tasks': state.map((task) => task.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // リンクのタスク状態を更新
  Future<void> refreshLinkTaskStatus() async {
    try {
      print('=== リンクのタスク状態更新開始 ===');
      print('現在のタスク数: ${state.length}');
      for (final task in state) {
        print('タスク: ${task.title}, ステータス: ${task.status}, 関連リンクID: ${task.relatedLinkId}');
      }
      
      final linkViewModel = _ref.read(linkViewModelProvider.notifier);
      await linkViewModel.updateLinkTaskStatus(state);
      
      print('=== リンクのタスク状態更新完了 ===');
    } catch (e) {
      if (kDebugMode) {
        print('リンクのタスク状態更新エラー: $e');
        print('エラーの詳細: ${e.toString()}');
      }
    }
  }

  Future<void> clearInvalidLinkReferences(String taskId) async {
    try {
      final taskIndex = state.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) return;

      if (_taskBox == null || !_taskBox!.isOpen) {
        _taskBox = await Hive.openBox<TaskItem>(_boxName);
      }

      final task = state[taskIndex];
      final linkState = _ref.read(linkViewModelProvider);
      final validLinkIds = <String>{};
      for (final group in linkState.groups) {
        for (final link in group.items) {
          validLinkIds.add(link.id);
        }
      }

    final filteredIds = <String>{};
    for (final id in task.relatedLinkIds) {
      if (validLinkIds.contains(id)) {
        filteredIds.add(id);
      }
    }
    if (task.relatedLinkId != null &&
        task.relatedLinkId!.isNotEmpty &&
        task.relatedLinkIds.contains(task.relatedLinkId!) &&
        validLinkIds.contains(task.relatedLinkId!)) {
      filteredIds.add(task.relatedLinkId!);
    }

    final filteredList = filteredIds.toList();
    final filteredPrimary =
        filteredList.isNotEmpty ? filteredList.first : null;

      if (filteredList.length == task.relatedLinkIds.length &&
          filteredPrimary == task.relatedLinkId) {
        return;
      }

      final updatedTask = task.copyWith(
        relatedLinkIds: filteredList,
        relatedLinkId: filteredPrimary,
      );

      await _taskBox?.put(taskId, updatedTask);
      await _taskBox?.flush();

      final newState = [...state];
      newState[taskIndex] = updatedTask;
      state = newState;
      await _updateLinkTaskStatus();
    } catch (e) {
      if (kDebugMode) {
        print('リンク参照クリア中にエラー: $e');
      }
    }
  }

  Future<void> setTaskLinks(String taskId, Set<String> linkIds) async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _taskBox = await Hive.openBox<TaskItem>(_boxName);
      } else {
        _taskBox ??= Hive.box<TaskItem>(_boxName);
      }
      final box = _taskBox!;

      final taskIndex = state.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) return;

      final task = state[taskIndex];
      final linkState = _ref.read(linkViewModelProvider);
      final validLinkIds = <String>{};
      for (final group in linkState.groups) {
        for (final link in group.items) {
          validLinkIds.add(link.id);
        }
      }

      final filteredIds = linkIds.where(validLinkIds.contains).toList();
      final filteredPrimary =
          filteredIds.isNotEmpty ? filteredIds.first : null;

      final updatedTask = task.copyWith(
        relatedLinkIds: filteredIds,
        relatedLinkId: filteredPrimary,
      );

      await box.put(taskId, updatedTask);
      await box.flush();

      final newState = [...state];
      newState[taskIndex] = updatedTask;
      state = newState;

      await _updateLinkTaskStatus();
    } catch (e) {
      if (kDebugMode) {
        print('リンク更新中にエラー: $e');
      }
      rethrow;
    }
  }

  Future<void> _cleanupInvalidLinkReferences() async {
    if (_taskBox == null || !_taskBox!.isOpen) return;

    final linkState = _ref.read(linkViewModelProvider);
    final validLinkIds = <String>{};
    for (final group in linkState.groups) {
      for (final link in group.items) {
        validLinkIds.add(link.id);
      }
    }

    bool updated = false;
    final updatedTasks = [...state];

    for (var i = 0; i < updatedTasks.length; i++) {
      final task = updatedTasks[i];
      final filteredIds = <String>{};

      for (final id in task.relatedLinkIds) {
        if (validLinkIds.contains(id)) {
          filteredIds.add(id);
        }
      }
      if (task.relatedLinkId != null &&
          task.relatedLinkId!.isNotEmpty &&
          task.relatedLinkIds.contains(task.relatedLinkId!) &&
          validLinkIds.contains(task.relatedLinkId!)) {
        filteredIds.add(task.relatedLinkId!);
      }

      final filteredList = filteredIds.toList();
      final primary = filteredList.isNotEmpty ? filteredList.first : null;

      if (!listEquals(filteredList, task.relatedLinkIds) ||
          primary != task.relatedLinkId) {
        final updatedTask = task.copyWith(
          relatedLinkIds: filteredList,
          relatedLinkId: primary,
        );
        await _taskBox!.put(task.id, updatedTask);
        updatedTasks[i] = updatedTask;
        updated = true;
      }
    }

    if (updated) {
      await _taskBox!.flush();
      state = updatedTasks;
      await _updateLinkTaskStatus();
    }
  }

  // サブタスク統計を更新
  Future<void> updateSubTaskStatistics(String taskId) async {
    try {
      print('=== サブタスク統計更新開始 ===');
      print('対象タスクID: $taskId');
      print('現在のタスク数: ${state.length}');
      
      // 現在のタスク一覧をデバッグ出力
      for (int i = 0; i < state.length; i++) {
        final task = state[i];
        print('タスク[$i]: ${task.title} (ID: ${task.id})');
      }
      
      final subTaskViewModel = _ref.read(subTaskViewModelProvider.notifier);
      
      // SubTaskViewModelの初期化完了を待つ
      await subTaskViewModel.waitForInitialization();
      
      final subTasks = subTaskViewModel.getSubTasksByParentId(taskId);
      
      print('取得されたサブタスク数: ${subTasks.length}');
      for (final subTask in subTasks) {
        print('サブタスク: ${subTask.title} (ID: ${subTask.id}, 親ID: ${subTask.parentTaskId})');
      }
      
      final totalSubTasksCount = subTasks.length;
      final completedSubTasksCount = subTasks.where((subTask) => subTask.isCompleted).length;
      final hasSubTasks = totalSubTasksCount > 0;
      
      print('計算結果 - 総数: $totalSubTasksCount, 完了: $completedSubTasksCount, サブタスクあり: $hasSubTasks');
      
      // タスクが見つからない場合の詳細デバッグ
      TaskItem? task;
      try {
        task = state.firstWhere((t) => t.id == taskId);
        print('対象タスクが見つかりました: ${task.title}');
      } catch (e) {
        print('❌ 対象タスクが見つかりません！');
        print('エラー: $e');
        print('検索対象のタスクID: $taskId');
        print('現在のタスク一覧:');
        for (int i = 0; i < state.length; i++) {
          final t = state[i];
          print('  [$i] ID: ${t.id}, タイトル: ${t.title}');
        }
        return; // タスクが見つからない場合は処理を終了
      }
      
      final updatedTask = task.copyWith(
        hasSubTasks: hasSubTasks,
        totalSubTasksCount: totalSubTasksCount,
        completedSubTasksCount: completedSubTasksCount,
        // 既存のリマインダー時間を保持
        reminderTime: task.reminderTime,
      );
      
      // サブタスク統計更新時は直接データベースを更新し、updateTaskは呼ばない
      await _updateTaskDirectly(updatedTask);
      
      print('サブタスク統計更新完了: ${task.title}');
      print('更新後のタスク - サブタスクあり: ${updatedTask.hasSubTasks}, 総数: ${updatedTask.totalSubTasksCount}, 完了: ${updatedTask.completedSubTasksCount}');
    } catch (e) {
      print('サブタスク統計更新エラー: $e');
      print('エラーの詳細: ${e.toString()}');
      print('スタックトレース: ${StackTrace.current}');
    }
  }

  /// Google Calendar自動同期（認証が有効な場合のみ実行）
  Future<void> _autoSyncToGoogleCalendar(TaskItem task) async {
    try {
      final googleCalendarService = GoogleCalendarService();
      await googleCalendarService.initialize();
      
      // 認証状態をチェック
      if (!googleCalendarService.isAuthenticated) {
        if (kDebugMode) {
          print('Google Calendar認証なし - 自動同期スキップ');
        }
        return;
      }
      
      if (kDebugMode) {
        print('=== Google Calendar自動同期開始 ===');
        print('タスク: ${task.title}');
        print('ステータス: ${task.status}');
      }
      
      // 個別タスク同期を実行
      final success = await syncTaskToGoogleCalendar(task);
      
      // 完了タスクの表示/非表示を制御
      if (success && task.status == TaskStatus.completed && task.googleCalendarEventId != null) {
        await _controlCompletedTaskVisibility(task);
      }
      
      if (kDebugMode) {
        print('Google Calendar自動同期結果: $success');
        print('=== Google Calendar自動同期完了 ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Google Calendar自動同期エラー（無視）: $e');
      }
      // 自動同期のエラーは無視（ユーザーに通知しない）
    }
  }

  /// 完了タスクの表示/非表示を制御
  Future<void> _controlCompletedTaskVisibility(TaskItem task) async {
    try {
      final settingsService = SettingsService.instance;
      final showCompleted = settingsService.googleCalendarShowCompletedTasks;
      
      if (task.googleCalendarEventId != null) {
        final googleCalendarService = GoogleCalendarService();
        await googleCalendarService.initialize();
        
        // 完了タスクの表示/非表示を制御
        final success = await googleCalendarService.updateCompletedTaskVisibility(
          task.googleCalendarEventId!,
          showCompleted,
        );
        
        if (kDebugMode) {
          print('完了タスク表示制御: ${showCompleted ? "表示" : "非表示"} - 結果: $success');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('完了タスク表示制御エラー（無視）: $e');
      }
      // エラーは無視（ユーザーに通知しない）
    }
  }

  // タスクを直接更新（サブタスク統計更新用）
  Future<void> _updateTaskDirectly(TaskItem task) async {
    try {
      print('=== タスク直接更新開始 ===');
      print('更新対象タスク: ${task.title} (ID: ${task.id})');
      print('更新前の状態のタスク数: ${state.length}');
      
      if (_taskBox == null || !_taskBox!.isOpen) {
        print('_taskBoxが開いていないため、_loadTasksを実行');
        await _loadTasks();
      }
      
      print('データベースにタスクを保存中...');
      await _taskBox!.put(task.id, task);
      await _taskBox!.flush(); // データの永続化を確実にする
      print('データベースへの保存完了');
      
      // Riverpodの状態を正しく更新
      print('状態を更新中...');
      final newTasks = state.map((t) => t.id == task.id ? task : t).toList();
      newTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = newTasks;
      print('状態更新完了');
      print('更新後の状態のタスク数: ${state.length}');
      
      // 更新後のタスク一覧をデバッグ出力
      for (int i = 0; i < state.length; i++) {
        final t = state[i];
        print('更新後タスク[$i]: ${t.title} (ID: ${t.id})');
      }
      
      // リンクのタスク状態を更新
      await _updateLinkTaskStatus();
      
      if (kDebugMode) {
        print('タスク直接更新: ${task.title}');
        print('更新後のサブタスク統計 - 総数: ${task.totalSubTasksCount}, 完了: ${task.completedSubTasksCount}');
      }
      
      print('=== タスク直接更新完了 ===');
    } catch (e) {
      print('❌ タスク直接更新エラー: $e');
      print('エラーの詳細: ${e.toString()}');
      print('スタックトレース: ${StackTrace.current}');
    }
  }

  // タスクを直接削除（一括削除用）
  Future<void> _deleteTaskDirectly(String taskId) async {
    try {
      if (_taskBox == null || !_taskBox!.isOpen) {
        await _loadTasks();
      }
      await _taskBox!.delete(taskId);
      await _taskBox!.flush(); // データの永続化を確実にする
      state = state.where((task) => task.id != taskId).toList();
      
      // 通知をキャンセル（エラーが発生しても続行）
      try {
        if (Platform.isWindows) {
          await WindowsNotificationService.cancelNotification(taskId);
        } else {
          await NotificationService.cancelNotification(taskId);
        }
      } catch (notificationError) {
        print('通知キャンセルエラー（無視）: $notificationError');
      }
      
      if (kDebugMode) {
        print('タスク直接削除: $taskId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスク直接削除エラー: $e');
      }
    }
  }

  // タスクの並び替えを処理
  Future<void> updateTasks(List<TaskItem> newTasks) async {
    try {
      // 新しい順序でタスクを保存
      for (int i = 0; i < newTasks.length; i++) {
        final task = newTasks[i];
        await _taskBox!.put(task.id, task);
      }
      await _taskBox!.flush(); // データの永続化を確実にする
      
      // 状態を更新
      state = newTasks;
      
      if (kDebugMode) {
        print('タスクの並び替えが完了しました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスクの並び替えエラー: $e');
      }
    }
  }

  // 内部用のリンクのタスク状態を更新
  Future<void> _updateLinkTaskStatus() async {
    await refreshLinkTaskStatus();
  }

  // データをインポート
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      print('=== タスクインポート開始 ===');
      print('受信データのキー: ${data.keys.toList()}');
      
      if (!data.containsKey('tasks') || data['tasks'] == null) {
        print('タスクデータが見つからないか、nullです');
        return;
      }
      
      final tasksData = data['tasks'] as List<dynamic>? ?? [];
      print('タスクデータ数: ${tasksData.length}');
      
      // タスクのパースとバリデーション
      final List<TaskItem> validTasks = [];
      for (int i = 0; i < tasksData.length; i++) {
        try {
          final task = TaskItem.fromJson(tasksData[i]);
          // 基本的なバリデーション
          if (task.id.isNotEmpty && task.title.isNotEmpty) {
            validTasks.add(task);
            print('タスク追加: ${task.title} (ID: ${task.id})');
          } else {
            print('無効なタスクをスキップ: インデックス $i');
          }
        } catch (e) {
          print('タスクパースエラー (インデックス $i): $e');
          continue;
        }
      }
      
      print('有効なタスク数: ${validTasks.length}');
      
      // _taskBoxの初期化を確実に行う
      try {
        if (_taskBox == null || !_taskBox!.isOpen) {
          print('_taskBoxを初期化中...');
          _taskBox = await Hive.openBox<TaskItem>(_boxName);
          print('_taskBox初期化完了');
        }
      } catch (initError) {
        print('_taskBox初期化エラー: $initError');
        // ボックスを閉じてから再初期化
        try {
          if (_taskBox != null && _taskBox!.isOpen) {
            await _taskBox!.close();
          }
        } catch (closeError) {
          print('ボックスクローズエラー: $closeError');
        }
        _taskBox = await Hive.openBox<TaskItem>(_boxName);
        print('_taskBox新規作成完了');
      }
      
      // 既存のタスクをクリア
      await _taskBox!.clear();
      print('既存タスクをクリアしました');
      
      // 新しいタスクを追加
      for (final task in validTasks) {
        try {
          await _taskBox!.put(task.id, task);
          print('タスクを保存: ${task.title} (ID: ${task.id})');
        } catch (e) {
          print('タスク保存エラー: ${task.title} - $e');
          continue;
        }
      }
      
      await _taskBox!.flush(); // データの永続化を確実にする
      
      // 状態を更新
      state = validTasks;
      print('状態を更新しました: ${validTasks.length}件');
      
      // データの永続化を確実にするため、少し待機
      await Future.delayed(const Duration(milliseconds: 100));
      
      // リンクのタスク状態を更新
      await _updateLinkTaskStatus();
      
      print('=== タスクインポート完了: ${validTasks.length}件 ===');
    } catch (e) {
      print('=== タスクデータインポートエラー: $e ===');
      print('エラーの詳細: ${e.toString()}');
      
      // エラーが発生した場合、_taskBoxの状態を確認
      try {
        if (_taskBox != null && _taskBox!.isOpen) {
          print('_taskBoxは開いています');
        } else {
          print('_taskBoxは閉じています');
        }
      } catch (boxError) {
        print('_taskBox状態確認エラー: $boxError');
      }
    }
  }

  // リマインダーを復元するためのコールバック関数
  void _restoreRemindersFromCallback(List<TaskItem> tasks) {
    print('=== リマインダー復元コールバック開始 ===');
    print('復元するタスク数: ${tasks.length}');
    // 注意: WindowsNotificationService.restoreReminders()内で
    // 既にscheduleTaskReminder()が呼ばれているため、
    // ここで再度呼び出すと重複通知が発生します。
    // このコールバックはログ出力のみに使用します。
    for (final task in tasks) {
      if (task.reminderTime != null) {
        print('復元確認: ${task.title} (ID: ${task.id}, リマインダー: ${task.reminderTime})');
      }
    }
    print('=== リマインダー復元コールバック完了 ===');
  }

  // タスクをコピーして新しいタスクを作成
  Future<TaskItem?> copyTask(TaskItem originalTask, {
    DateTime? newDueDate,
    DateTime? newReminderTime,
    String? newTitle,
    bool keepRecurringReminder = true,
  }) async {
    try {
      print('=== タスクコピー開始 ===');
      print('元タスク: ${originalTask.title}');
      print('元タスクID: ${originalTask.id}');
      print('元タスクhasSubTasks: ${originalTask.hasSubTasks}');
      print('元タスクtotalSubTasksCount: ${originalTask.totalSubTasksCount}');
      print('元の期限日: ${originalTask.dueDate}');
      print('元のリマインダー時間: ${originalTask.reminderTime}');
      print('newDueDate: $newDueDate');
      print('newReminderTime: $newReminderTime');
      print('newTitle: $newTitle');
      print('keepRecurringReminder: $keepRecurringReminder');
      
      // 新しいタスクIDを生成
      final newTaskId = _uuid.v4();
      
      // 新しいタスクを作成（編集モーダルの全内容をコピー）
      final newTask = TaskItem(
        id: newTaskId,
        title: newTitle ?? '${originalTask.title} (コピー)',
        description: originalTask.description,
        assignedTo: originalTask.assignedTo, // 依頼先・メモをコピー
        dueDate: newDueDate ?? _calculateNextDueDate(originalTask.dueDate),
        reminderTime: newReminderTime ?? _calculateNextReminderTime(originalTask.reminderTime),
        priority: originalTask.priority,
        status: TaskStatus.pending, // ステータスは未着手にリセット
        tags: List<String>.from(originalTask.tags),
        relatedLinkId: originalTask.relatedLinkId,
        relatedLinkIds: List<String>.from(originalTask.relatedLinkIds), // 関連リンクをコピー
        createdAt: DateTime.now(),
        estimatedMinutes: originalTask.estimatedMinutes,
        recurringReminderPattern: keepRecurringReminder ? originalTask.recurringReminderPattern : null,
        reminderCount: 0,
        nextReminderTime: null,
        hasSubTasks: false,
        totalSubTasksCount: 0,
        completedSubTasksCount: 0,
      );
      
      // 新しいタスクを保存
      await _taskBox!.put(newTaskId, newTask);
      await _taskBox!.flush(); // データの永続化を確実にする
      
      // サブタスクをコピー（実際にサブタスクが存在するかチェック）
      print('=== サブタスク存在チェック開始 ===');
      print('チェック対象の元タスクID: ${originalTask.id}');
      print('元タスクタイトル: ${originalTask.title}');
      final hasActualSubTasks = await _hasSubTasks(originalTask.id);
      print('=== サブタスク存在チェック完了 ===');
      print('hasActualSubTasks結果: $hasActualSubTasks');
      print('=== サブタスクコピーデバッグ ===');
      print('originalTask.hasSubTasks: ${originalTask.hasSubTasks}');
      print('hasActualSubTasks: $hasActualSubTasks');
      print('originalTask.id: ${originalTask.id}');
      print('===============================');
      
      // 元タスクにサブタスクがある場合、または実際にサブタスクが存在する場合はコピー
      if (originalTask.hasSubTasks || hasActualSubTasks) {
        // まず新しいタスクをstateに追加
        final updatedTasks = [...state, newTask];
        updatedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = updatedTasks;
        
        // サブタスクをコピー
        await _copySubTasks(originalTask.id, newTaskId);
        
        // サブタスク統計を更新した新しいタスクを取得
        print('=== サブタスク統計更新開始 ===');
        final updatedNewTask = await _getTaskWithUpdatedSubTaskStats(newTaskId);
        print('updatedNewTask: $updatedNewTask');
        if (updatedNewTask != null) {
          print('サブタスク統計更新成功: hasSubTasks=${updatedNewTask.hasSubTasks}, totalSubTasksCount=${updatedNewTask.totalSubTasksCount}');
          // 状態を更新（サブタスク統計が更新されたタスクを使用）
          final finalTasks = [...state.where((t) => t.id != newTaskId), updatedNewTask];
          finalTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          state = finalTasks;
        } else {
          print('サブタスク統計更新失敗、元のタスクを使用');
        }
        print('=== サブタスク統計更新完了 ===');
      } else {
        // サブタスクが存在しない場合でも、元タスクのサブタスク統計をリセット
        final newTaskWithoutSubTasks = newTask.copyWith(
          hasSubTasks: false,
          totalSubTasksCount: 0,
          completedSubTasksCount: 0,
        );
        
        // 状態を更新
        final updatedTasks = [...state, newTaskWithoutSubTasks];
        updatedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = updatedTasks;
      }
      
      // リマインダーを設定
      if (newTask.reminderTime != null) {
        if (Platform.isWindows) {
          await WindowsNotificationService.scheduleTaskReminder(newTask);
        } else {
          await NotificationService.scheduleTaskReminder(newTask);
        }
      }
      
      print('=== タスクコピー完了 ===');
      print('新しいタスク: ${newTask.title}');
      print('新しい期限日: ${newTask.dueDate}');
      print('新しいリマインダー時間: ${newTask.reminderTime}');
      
      return newTask;
    } catch (e) {
      print('タスクコピーエラー: $e');
      return null;
    }
  }

  /// タスクにサブタスクが存在するかチェック
  Future<bool> _hasSubTasks(String taskId) async {
    try {
      // 複数のボックス名を試す
      final boxNames = ['sub_tasks', 'subtasks', 'SubTask'];
      Box<SubTask>? subTaskBox;
      
      for (final boxName in boxNames) {
        try {
          subTaskBox = await Hive.openBox<SubTask>(boxName);
          print('サブタスクボックス「$boxName」を開きました');
          break;
        } catch (e) {
          print('ボックス「$boxName」を開けませんでした: $e');
        }
      }
      
      if (subTaskBox == null) {
        print('サブタスクボックスを開けませんでした');
        return false;
      }
      
      final subTasks = subTaskBox.values
          .where((subTask) => subTask.parentTaskId == taskId)
          .toList();
      
      print('=== サブタスク存在チェック詳細 ===');
      print('taskId: $taskId');
      print('ボックス名: ${subTaskBox.name}');
      print('全サブタスク数: ${subTaskBox.values.length}');
      print('該当サブタスク数: ${subTasks.length}');
      for (final subTask in subTasks) {
        print('  - サブタスク: ${subTask.title} (parentTaskId: ${subTask.parentTaskId})');
      }
      print('===============================');
      
      // デバッグ: 全サブタスクのparentTaskIdを表示
      print('=== 全サブタスクのparentTaskId ===');
      for (final subTask in subTaskBox.values) {
        print('  - サブタスク: ${subTask.title} (parentTaskId: ${subTask.parentTaskId})');
      }
      print('===================================');
      
      await subTaskBox.close();
      return subTasks.isNotEmpty;
    } catch (e) {
      print('サブタスク存在チェックエラー: $e');
      return false;
    }
  }

  /// サブタスク統計を更新したタスクを取得
  Future<TaskItem?> _getTaskWithUpdatedSubTaskStats(String taskId) async {
    try {
      print('_getTaskWithUpdatedSubTaskStats開始: taskId=$taskId');
      final task = _taskBox!.get(taskId);
      if (task == null) {
        print('タスクが見つかりません: $taskId');
        return null;
      }
      print('元のタスク: ${task.title}, hasSubTasks=${task.hasSubTasks}, totalSubTasksCount=${task.totalSubTasksCount}');
      
      // サブタスク統計を更新
      await updateSubTaskStatistics(taskId);
      
      // 更新されたタスクを取得
      final updatedTask = _taskBox!.get(taskId);
      if (updatedTask != null) {
        print('更新後のタスク: ${updatedTask.title}, hasSubTasks=${updatedTask.hasSubTasks}, totalSubTasksCount=${updatedTask.totalSubTasksCount}');
      } else {
        print('更新後のタスクが見つかりません');
      }
      return updatedTask;
    } catch (e) {
      print('サブタスク統計更新エラー: $e');
      return null;
    }
  }

  /// サブタスクをコピー
  Future<void> _copySubTasks(String originalTaskId, String newTaskId) async {
    try {
      // 複数のボックス名を試す
      final boxNames = ['sub_tasks', 'subtasks', 'SubTask'];
      Box<SubTask>? subTaskBox;
      
      for (final boxName in boxNames) {
        try {
          subTaskBox = await Hive.openBox<SubTask>(boxName);
          print('サブタスクコピー用ボックス「$boxName」を開きました');
          break;
        } catch (e) {
          print('ボックス「$boxName」を開けませんでした: $e');
        }
      }
      
      if (subTaskBox == null) {
        print('サブタスクボックスを開けませんでした');
        return;
      }
      
      final originalSubTasks = subTaskBox.values
          .where((subTask) => subTask.parentTaskId == originalTaskId)
          .toList();
      
      print('=== サブタスクコピー詳細 ===');
      print('originalTaskId: $originalTaskId');
      print('newTaskId: $newTaskId');
      print('ボックス名: ${subTaskBox.name}');
      print('元サブタスク数: ${originalSubTasks.length}');
      for (final subTask in originalSubTasks) {
        print('  - 元サブタスク: ${subTask.title} (parentTaskId: ${subTask.parentTaskId})');
      }
      print('==========================');
      
      for (final originalSubTask in originalSubTasks) {
        final newSubTask = SubTask(
          id: _uuid.v4(),
          parentTaskId: newTaskId,
          title: originalSubTask.title,
          isCompleted: false, // サブタスクは未完了にリセット
          createdAt: DateTime.now(), // 作成日時を追加
          estimatedMinutes: originalSubTask.estimatedMinutes,
          completedAt: null,
          order: originalSubTask.order,
        );
        
        await subTaskBox.put(newSubTask.id, newSubTask);
        print('サブタスクをコピーしました: ${originalSubTask.title} -> ${newSubTask.title}');
      }
      
      await subTaskBox.flush();
      await subTaskBox.close();
      
      // SubTaskViewModelを更新
      final subTaskViewModel = _ref.read(subTaskViewModelProvider.notifier);
      await subTaskViewModel.waitForInitialization();
      await subTaskViewModel.refreshSubTasks();
      
      print('サブタスクをコピーしました: ${originalSubTasks.length}個');
    } catch (e) {
      print('サブタスクコピーエラー: $e');
    }
  }

  // 次の期限日を計算
  DateTime? _calculateNextDueDate(DateTime? originalDueDate) {
    if (originalDueDate == null) return null;
    
    final now = DateTime.now();
    
    // 元の期限日が現在日時より後の場合は、さらに1か月後を設定
    if (originalDueDate.isAfter(now)) {
      try {
        return DateTime(
          originalDueDate.year,
          originalDueDate.month + 1,
          originalDueDate.day,
          originalDueDate.hour,
          originalDueDate.minute,
        );
      } catch (e) {
        // 月の日数が異なる場合（例：1月31日→2月）は月末日を使用
        final nextMonth = DateTime(originalDueDate.year, originalDueDate.month + 1);
        final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final adjustedDay = originalDueDate.day > lastDayOfNextMonth 
            ? lastDayOfNextMonth 
            : originalDueDate.day;
        
        return DateTime(
          originalDueDate.year,
          originalDueDate.month + 1,
          adjustedDay,
          originalDueDate.hour,
          originalDueDate.minute,
        );
      }
    } else {
      // 元の期限日が現在日時より前の場合は、翌月の同日を設定
      try {
        return DateTime(
          now.year,
          now.month + 1,
          originalDueDate.day,
          originalDueDate.hour,
          originalDueDate.minute,
        );
      } catch (e) {
        // 月の日数が異なる場合（例：1月31日→2月）は月末日を使用
        final nextMonth = DateTime(now.year, now.month + 1);
        final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final adjustedDay = originalDueDate.day > lastDayOfNextMonth 
            ? lastDayOfNextMonth 
            : originalDueDate.day;
        
        return DateTime(
          now.year,
          now.month + 1,
          adjustedDay,
          originalDueDate.hour,
          originalDueDate.minute,
        );
      }
    }
  }

  // 次のリマインダー時間を計算
  DateTime? _calculateNextReminderTime(DateTime? originalReminderTime) {
    if (originalReminderTime == null) return null;
    
    final now = DateTime.now();
    
    // 元のリマインダー時間が現在日時より後の場合は、さらに1か月後を設定
    if (originalReminderTime.isAfter(now)) {
      try {
        return DateTime(
          originalReminderTime.year,
          originalReminderTime.month + 1,
          originalReminderTime.day,
          originalReminderTime.hour,
          originalReminderTime.minute,
        );
      } catch (e) {
        // 月の日数が異なる場合（例：1月31日→2月）は月末日を使用
        final nextMonth = DateTime(originalReminderTime.year, originalReminderTime.month + 1);
        final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final adjustedDay = originalReminderTime.day > lastDayOfNextMonth 
            ? lastDayOfNextMonth 
            : originalReminderTime.day;
        
        return DateTime(
          originalReminderTime.year,
          originalReminderTime.month + 1,
          adjustedDay,
          originalReminderTime.hour,
          originalReminderTime.minute,
        );
      }
    } else {
      // 元のリマインダー時間が現在日時より前の場合は、翌月の同日を設定
      try {
        return DateTime(
          now.year,
          now.month + 1,
          originalReminderTime.day,
          originalReminderTime.hour,
          originalReminderTime.minute,
        );
      } catch (e) {
        // 月の日数が異なる場合（例：1月31日→2月）は月末日を使用
        final nextMonth = DateTime(now.year, now.month + 1);
        final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final adjustedDay = originalReminderTime.day > lastDayOfNextMonth 
            ? lastDayOfNextMonth 
            : originalReminderTime.day;
        
        return DateTime(
          now.year,
          now.month + 1,
          adjustedDay,
          originalReminderTime.hour,
          originalReminderTime.minute,
        );
      }
    }
  }

  // Google Calendar同期関連のメソッド
  
  /// Google Calendarから同期したタスクを追加
  Future<void> syncTasksFromGoogleCalendar(List<TaskItem> calendarTasks) async {
    try {
      if (kDebugMode) {
        print('=== Google Calendar同期開始 ===');
        print('同期対象タスク数: ${calendarTasks.length}件');
        print('現在のアプリタスク数: ${state.length}件');
        
        // 最初の3件のタスク詳細を出力
        for (int i = 0; i < math.min(3, calendarTasks.length); i++) {
          final task = calendarTasks[i];
          print('タスク${i + 1}: ${task.title}');
          print('  externalId: ${task.externalId}');
          print('  優先度: ${task.priority}');
          print('  サブタスク: ${task.totalSubTasksCount}/${task.completedSubTasksCount}');
          print('  タグ: ${task.tags}');
        }
      }
      
      final existingTasks = state;
      
      int addedCount = 0;
      int updatedCount = 0;
      int skippedCount = 0;
      
      for (final calendarTask in calendarTasks) {
        if (calendarTask.externalId == null) continue;
        
        // 祝日イベントを除外
        if (_isHolidayEvent(calendarTask)) {
          if (kDebugMode) {
            print('祝日イベントをスキップ: ${calendarTask.title}');
          }
          skippedCount++;
          continue;
        }
        
        // 既存のタスクを検索（externalIdで判定）
        final existingTaskIndex = existingTasks.indexWhere(
          (task) => task.externalId == calendarTask.externalId
        );
        
        if (existingTaskIndex >= 0) {
          // 既存のタスクを更新
          if (kDebugMode) {
            print('既存タスクを更新: ${calendarTask.title}');
            print('  更新前の優先度: ${existingTasks[existingTaskIndex].priority}');
            print('  更新後の優先度: ${calendarTask.priority}');
            print('  更新前のサブタスク: ${existingTasks[existingTaskIndex].totalSubTasksCount}/${existingTasks[existingTaskIndex].completedSubTasksCount}');
            print('  更新後のサブタスク: ${calendarTask.totalSubTasksCount}/${calendarTask.completedSubTasksCount}');
          }
          // 既存タスクを更新
          final existingTask = existingTasks[existingTaskIndex];
          final updatedTask = existingTask.copyWith(
            title: calendarTask.title,
            description: calendarTask.description,
            notes: calendarTask.notes,
            dueDate: calendarTask.dueDate,
            reminderTime: calendarTask.reminderTime,
            priority: calendarTask.priority,
            status: calendarTask.status,
            tags: calendarTask.tags,
            estimatedMinutes: calendarTask.estimatedMinutes,
            assignedTo: calendarTask.assignedTo,
            hasSubTasks: calendarTask.hasSubTasks,
            completedSubTasksCount: calendarTask.completedSubTasksCount,
            totalSubTasksCount: calendarTask.totalSubTasksCount,
          );
          
          await updateTask(updatedTask);
          updatedCount++;
          
          if (kDebugMode) {
            print('Google Calendarタスク更新: ${calendarTask.title}');
          }
        } else {
          // 新しいタスクを追加（Google Calendarからインポート時はサブタスク統計を初期化しない）
          await _addTaskFromGoogleCalendar(calendarTask);
          addedCount++;
          
          if (kDebugMode) {
            print('Google Calendarタスク追加: ${calendarTask.title}');
          }
        }
      }
      
      // 削除されたイベントのタスクを削除
      final currentExternalIds = calendarTasks
          .where((task) => task.externalId != null)
          .map((task) => task.externalId!)
          .toSet();
      
      final tasksToDelete = existingTasks.where((task) =>
          task.source == 'google_calendar' &&
          task.externalId != null &&
          !currentExternalIds.contains(task.externalId)
      ).toList();
      
      for (final taskToDelete in tasksToDelete) {
        await deleteTask(taskToDelete.id);
        if (kDebugMode) {
          print('Google Calendarタスク削除: ${taskToDelete.title}');
        }
      }
      
      // 重複タスクをチェックして削除
      await _removeDuplicateTasks();
      
      if (kDebugMode) {
        print('=== Google Calendar同期完了 ===');
        print('追加: $addedCount件');
        print('更新: $updatedCount件');
        print('削除: ${tasksToDelete.length}件');
        print('スキップ: $skippedCount件');
        print('最終アプリタスク数: ${state.length}件');
      }
    } catch (e) {
      print('Google Calendar同期エラー: $e');
      rethrow;
    }
  }
  
  /// 祝日イベントかどうかを判定
  bool _isHolidayEvent(TaskItem task) {
    final title = task.title.toLowerCase();
    final description = (task.description ?? '').toLowerCase();
    
    // 祝日関連のキーワードをチェック（拡張版）
    final holidayKeywords = [
      '祝日', 'holiday', '国民の祝日', '振替休日', '敬老の日', '春分の日', '秋分の日',
      'みどりの日', '海の日', '山の日', '体育の日', 'スポーツの日', '文化の日',
      '勤労感謝の日', '天皇誕生日', '建国記念の日', '昭和の日', '憲法記念日',
      'こどもの日', '成人の日', '成人式', 'バレンタインデー', 'ホワイトデー',
      '母の日', '父の日', 'クリスマス', '大晦日', '正月', 'お盆', 'ゴールデンウィーク',
      'シルバーウィーク', '年末年始', '七夕', '七五三', '銀行休業日', '節分', '雛祭り',
      '元日', '振替', '休業', '休日', '祝祭日', '国民の休日', 'みどりの日',
      '海の日', '山の日', 'スポーツの日', '文化の日', '勤労感謝の日', '天皇誕生日',
      '建国記念の日', '昭和の日', '憲法記念日', 'こどもの日', '成人の日', '敬老の日',
      '春分の日', '秋分の日', 'みどりの日', '海の日', '山の日', 'スポーツの日',
      '文化の日', '勤労感謝の日', '天皇誕生日', '建国記念の日', '昭和の日', '憲法記念日',
      'こどもの日', '成人の日', '敬老の日', '春分の日', '秋分の日'
    ];
    
    // キーワードチェック（単独の「日」は除外）
    for (final keyword in holidayKeywords) {
      if (keyword == '日') {
        // 「日」は単独では除外しない（「今日」「明日」などは除外対象外）
        continue;
      }
      if (title.contains(keyword) || description.contains(keyword)) {
        if (kDebugMode) {
          print('祝日キーワードで除外: ${task.title} (キーワード: $keyword)');
        }
        return true;
      }
    }
    
    // 終日イベントでタイトルが短い場合は祝日の可能性が高い
    if (task.dueDate != null && task.reminderTime != null) {
      final startOfDay = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      if (task.reminderTime!.isAtSameMomentAs(startOfDay) && 
          task.dueDate!.isAtSameMomentAs(endOfDay.subtract(const Duration(seconds: 1)))) {
        // 終日イベントでタイトルが短い場合は祝日の可能性が高い
        if (title.length <= 10) {
          if (kDebugMode) {
            print('終日イベントで除外: ${task.title} (タイトル長: ${title.length})');
          }
          return true;
        }
      }
    }
    
    // タイトルが短く、日付が特定のパターンの場合は祝日の可能性が高い
    if (title.length <= 8 && task.dueDate != null) {
      // 月日が特定のパターン（祝日になりやすい日付）の場合は除外
      final month = task.dueDate!.month;
      final day = task.dueDate!.day;
      
      // 祝日になりやすい日付パターン
      final holidayDates = [
        [1, 1],   // 元日
        [1, 8],   // 成人の日（第2月曜日）
        [2, 11],  // 建国記念の日
        [2, 23],  // 天皇誕生日
        [3, 20],  // 春分の日
        [4, 29],  // 昭和の日
        [5, 3],   // 憲法記念日
        [5, 4],   // みどりの日
        [5, 5],   // こどもの日
        [7, 15],  // 海の日
        [8, 11],  // 山の日
        [9, 16],  // 敬老の日
        [9, 22],  // 秋分の日
        [10, 14], // スポーツの日
        [11, 3],  // 文化の日
        [11, 23], // 勤労感謝の日
      ];
      
      for (final holidayDate in holidayDates) {
        if (month == holidayDate[0] && day == holidayDate[1]) {
          // 祝日パターンの日付でも、タイトルが長い場合は除外しない（ビジネスイベントの可能性）
          if (title.length <= 5) {
            if (kDebugMode) {
              print('祝日日付パターンで除外: ${task.title} ($month/$day)');
            }
            return true;
          }
        }
      }
    }
    
    return false;
  }
  
  /// 重複タスクかどうかを判定
  bool _isDuplicateTask(TaskItem newTask, List<TaskItem> existingTasks) {
    for (final existingTask in existingTasks) {
      // タイトルが同じで、日付が近い場合は重複とみなす
      if (existingTask.title == newTask.title) {
        if (newTask.dueDate != null && existingTask.dueDate != null) {
          final dateDiff = newTask.dueDate!.difference(existingTask.dueDate!).abs();
          if (dateDiff.inDays <= 1) {
            return true;
          }
        }
        
        if (newTask.reminderTime != null && existingTask.reminderTime != null) {
          final timeDiff = newTask.reminderTime!.difference(existingTask.reminderTime!).abs();
          if (timeDiff.inDays <= 1) {
            return true;
          }
        }
      }
    }
    
    return false;
  }
  
  /// Google Calendarタスクを取得
  List<TaskItem> getGoogleCalendarTasks() {
    return state.where((task) => task.source == 'google_calendar').toList();
  }
  
  /// 手動でGoogle Calendarタスクを削除
  Future<void> removeGoogleCalendarTask(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    if (task.source == 'google_calendar') {
      await deleteTask(taskId);
    }
  }

  /// 選択したタスクのみをGoogle Calendarに同期
  Future<Map<String, dynamic>> syncSelectedTasksToGoogleCalendar(List<String> taskIds) async {
    try {
      if (kDebugMode) {
        print('=== 選択タスク同期開始 ===');
        print('選択されたタスク数: ${taskIds.length}');
      }
      
      final googleCalendarService = GoogleCalendarService();
      await googleCalendarService.initialize();
      
      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];
      
      for (final taskId in taskIds) {
        try {
          final task = state.firstWhere((t) => t.id == taskId);
          final result = await googleCalendarService.createCalendarEvent(task);
          
          if (result.success) {
            successCount++;
            if (kDebugMode) {
              print('タスク同期成功: ${task.title}');
            }
          } else {
            errorCount++;
            errors.add('${task.title}: ${result.errorMessage}');
            if (kDebugMode) {
              print('タスク同期失敗: ${task.title} - ${result.errorMessage}');
            }
          }
        } catch (e) {
          errorCount++;
          errors.add('タスクID $taskId: $e');
          if (kDebugMode) {
            print('タスク同期エラー: $taskId - $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('=== 選択タスク同期完了 ===');
        print('成功: $successCount件, 失敗: $errorCount件');
      }
      
      return {
        'success': errorCount == 0,
        'successCount': successCount,
        'errorCount': errorCount,
        'errors': errors,
        'total': taskIds.length,
      };
    } catch (e) {
      print('選択タスク同期エラー: $e');
      return {
        'success': false,
        'successCount': 0,
        'errorCount': taskIds.length,
        'errors': ['全体的なエラー: $e'],
        'total': taskIds.length,
      };
    }
  }

  /// 日付範囲でタスクを同期
  Future<Map<String, dynamic>> syncTasksByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      if (kDebugMode) {
        print('=== 日付範囲同期開始 ===');
        print('開始日: $startDate, 終了日: $endDate');
      }
      
      // 指定された日付範囲のタスクをフィルタリング
      final filteredTasks = state.where((task) {
        final taskDate = task.dueDate ?? task.reminderTime;
        if (taskDate == null) return false;
        
        return taskDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               taskDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      
      if (kDebugMode) {
        print('フィルタリングされたタスク数: ${filteredTasks.length}');
      }
      
      final googleCalendarService = GoogleCalendarService();
      await googleCalendarService.initialize();
      
      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];
      
      for (final task in filteredTasks) {
        try {
          final result = await googleCalendarService.createCalendarEvent(task);
          
          if (result.success) {
            successCount++;
            if (kDebugMode) {
              print('タスク同期成功: ${task.title}');
            }
          } else {
            errorCount++;
            errors.add('${task.title}: ${result.errorMessage}');
            if (kDebugMode) {
              print('タスク同期失敗: ${task.title} - ${result.errorMessage}');
            }
          }
        } catch (e) {
          errorCount++;
          errors.add('${task.title}: $e');
          if (kDebugMode) {
            print('タスク同期エラー: ${task.title} - $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('=== 日付範囲同期完了 ===');
        print('成功: $successCount件, 失敗: $errorCount件');
      }
      
      return {
        'success': errorCount == 0,
        'successCount': successCount,
        'errorCount': errorCount,
        'errors': errors,
        'total': filteredTasks.length,
      };
    } catch (e) {
      print('日付範囲同期エラー: $e');
      return {
        'success': false,
        'successCount': 0,
        'errorCount': 0,
        'errors': ['全体的なエラー: $e'],
        'total': 0,
      };
    }
  }

  /// アプリとGoogleカレンダー間の完全な相互同期
  Future<Map<String, dynamic>> performFullBidirectionalSync() async {
    try {
      if (kDebugMode) {
        print('=== 完全相互同期開始 ===');
      }
      
      final googleCalendarService = GoogleCalendarService();
      await googleCalendarService.initialize();
      
      // 1. Googleカレンダーからイベントを取得
      final startTime = DateTime.now().subtract(const Duration(days: 30));
      final endTime = DateTime.now().add(const Duration(days: 365));
      
      final calendarEvents = await googleCalendarService.getEvents(
        startTime: startTime,
        endTime: endTime,
        maxResults: 1000,
      );
      
      // 2. Googleカレンダーイベントをタスクに変換
      final calendarTasks = googleCalendarService.convertEventsToTasks(calendarEvents);
      
      if (kDebugMode) {
        print('Googleカレンダーから取得したタスク数: ${calendarTasks.length}');
        print('アプリの既存タスク数: ${state.length}');
      }
      
      // 3. アプリのタスクをGoogleカレンダーに送信
      int appToCalendarCount = 0;
      for (final appTask in state) {
        // 手動作成のタスクのみを送信（Googleカレンダーから来たタスクは除外）
        if (appTask.source != 'google_calendar' && 
            (appTask.dueDate != null || appTask.reminderTime != null)) {
          
          // Googleカレンダーに既に存在するかチェック
          final existsInCalendar = calendarTasks.any((calendarTask) => 
            _isSameTask(appTask, calendarTask));
          
          if (!existsInCalendar) {
            final result = await googleCalendarService.createCalendarEvent(appTask);
            if (result.success) {
              appToCalendarCount++;
              if (kDebugMode) {
                print('アプリタスクをGoogleカレンダーに送信: ${appTask.title}');
              }
            }
          }
        }
      }
      
      // 4. Googleカレンダーのタスクをアプリに追加
      int calendarToAppCount = 0;
      for (final calendarTask in calendarTasks) {
        // 祝日イベントを除外（二重チェック）
        if (_isHolidayEvent(calendarTask)) {
          if (kDebugMode) {
            print('祝日イベントを二重チェックで除外: ${calendarTask.title}');
          }
          continue;
        }
        
        // アプリに既に存在するかチェック
        final existsInApp = state.any((appTask) => 
          _isSameTask(appTask, calendarTask));
        
        if (!existsInApp) {
          await addTask(calendarTask);
          calendarToAppCount++;
          if (kDebugMode) {
            print('Googleカレンダータスクをアプリに追加: ${calendarTask.title}');
          }
        }
      }
      
      if (kDebugMode) {
        print('=== 完全相互同期完了 ===');
        print('アプリ→Googleカレンダー: $appToCalendarCount件');
        print('Googleカレンダー→アプリ: $calendarToAppCount件');
      }
      
      return {
        'success': true,
        'appToCalendar': appToCalendarCount,
        'calendarToApp': calendarToAppCount,
        'total': appToCalendarCount + calendarToAppCount,
      };
      
    } catch (e) {
      print('完全相互同期エラー: $e');
      return {
        'success': false,
        'error': e.toString(),
        'appToCalendar': 0,
        'calendarToApp': 0,
        'total': 0,
      };
    }
  }
  
  /// 2つのタスクが同じかどうかを判定（より厳密な判定）
  bool _isSameTask(TaskItem task1, TaskItem task2) {
    // IDが同じ場合は完全に同じタスク
    if (task1.id == task2.id) return true;
    
    // タイトルが異なる場合は別のタスク
    if (task1.title != task2.title) return false;
    
    // 作成日時が非常に近い場合（1分以内）は重複の可能性が高い
    final timeDiff = task1.createdAt.difference(task2.createdAt).abs();
    if (timeDiff.inMinutes <= 1) {
      // さらに詳細な比較
      if (task1.description == task2.description &&
          task1.priority == task2.priority &&
          task1.tags.toString() == task2.tags.toString()) {
        return true;
      }
    }
      
    // 期限日が同じ場合
    if (task1.dueDate != null && task2.dueDate != null) {
      final dateDiff = task1.dueDate!.difference(task2.dueDate!).abs();
      if (dateDiff.inDays <= 1) {
        // 説明と優先度も同じ場合は重複とみなす
        if (task1.description == task2.description &&
            task1.priority == task2.priority) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// タスク削除時にGoogle Calendarからもイベントを削除
  Future<Map<String, dynamic>> deleteTaskWithCalendarSync(String taskId) async {
    try {
      if (kDebugMode) {
        print('=== タスク削除（カレンダー同期）開始 ===');
        print('削除対象タスクID: $taskId');
      }
      
      final googleCalendarService = GoogleCalendarService();
      await googleCalendarService.initialize();
      
      // Google Calendarからイベントを削除
      final deleteResult = await googleCalendarService.deleteCalendarEventByTaskId(taskId);
      
      if (deleteResult.success) {
        if (kDebugMode) {
          print('Google Calendarイベント削除成功');
        }
        
        // アプリからタスクを削除
        await deleteTask(taskId);
        
        if (kDebugMode) {
          print('=== タスク削除（カレンダー同期）完了 ===');
        }
        
        return {
          'success': true,
          'message': 'タスクとGoogle Calendarイベントを削除しました',
        };
      } else {
        // 認証エラーの場合はタスク削除を停止
        if (deleteResult.errorCode == 'AUTH_REQUIRED' || 
            deleteResult.errorCode == 'TOKEN_REFRESH_FAILED') {
          return {
            'success': false,
            'error': deleteResult.errorMessage ?? 'Google Calendarの認証に失敗しました',
            'errorCode': deleteResult.errorCode,
          };
        }
        
        if (kDebugMode) {
          print('Google Calendarイベント削除失敗: ${deleteResult.errorMessage}');
        }
        
        // その他のエラーの場合はタスク削除は続行
        await deleteTask(taskId);
        
        return {
          'success': true,
          'message': 'タスクを削除しました（Google Calendarイベント削除に失敗）',
          'warning': deleteResult.errorMessage,
        };
      }
    } catch (e) {
      print('タスク削除（カレンダー同期）エラー: $e');
      return {
        'success': false,
        'error': 'タスク削除中にエラーが発生しました: $e',
      };
    }
  }

  /// 孤立したGoogle Calendarイベントを削除
  Future<Map<String, dynamic>> deleteOrphanedCalendarEvents() async {
    try {
      if (kDebugMode) {
        print('=== 孤立イベント削除開始 ===');
      }
      
      final googleCalendarService = GoogleCalendarService();
      await googleCalendarService.initialize();
      
      // 現在のアプリのタスクIDリストを取得
      final existingTaskIds = state.map((task) => task.id).toList();
      
      final result = await googleCalendarService.deleteOrphanedEvents(existingTaskIds);
      
      if (kDebugMode) {
        print('=== 孤立イベント削除完了 ===');
        print('結果: $result');
      }
      
      return result;
    } catch (e) {
      print('孤立イベント削除エラー: $e');
      return {
        'success': false,
        'error': e.toString(),
        'deletedCount': 0,
      };
    }
  }

  /// Google Calendarの重複イベントをクリーンアップ
  Future<Map<String, dynamic>> cleanupGoogleCalendarDuplicates() async {
    try {
      if (kDebugMode) {
        print('=== Google Calendar重複クリーンアップ開始 ===');
      }
      
      final googleCalendarService = GoogleCalendarService();
      await googleCalendarService.initialize();
      
      final result = await googleCalendarService.cleanupDuplicateEvents();
      
      if (kDebugMode) {
        print('=== Google Calendar重複クリーンアップ完了 ===');
        print('結果: $result');
      }
      
      return result;
    } catch (e) {
      print('Google Calendar重複クリーンアップエラー: $e');
      return {
        'success': false,
        'error': e.toString(),
        'duplicatesFound': 0,
        'duplicatesRemoved': 0,
      };
    }
  }

  /// 祝日タスクを一括削除
  Future<Map<String, dynamic>> removeHolidayTasks() async {
    try {
      if (kDebugMode) {
        print('=== 祝日タスク削除開始 ===');
      }
      
      final existingTasks = state;
      final tasksToDelete = <TaskItem>[];
      
      // 祝日タスクを検出
      for (final task in existingTasks) {
        if (_isHolidayEvent(task)) {
          tasksToDelete.add(task);
          if (kDebugMode) {
            print('祝日タスクを削除対象に追加: ${task.title}');
          }
        }
      }
      
      // 祝日タスクを直接削除
      int deletedCount = 0;
      for (final taskToDelete in tasksToDelete) {
        await _deleteTaskDirectly(taskToDelete.id);
        deletedCount++;
      }
      
      if (kDebugMode) {
        print('=== 祝日タスク削除完了 ===');
        print('削除されたタスク数: $deletedCount件');
      }
      
      return {
        'success': true,
        'deletedCount': deletedCount,
        'total': tasksToDelete.length,
      };
      
    } catch (e) {
      print('祝日タスク削除エラー: $e');
      return {
        'success': false,
        'error': e.toString(),
        'deletedCount': 0,
        'total': 0,
      };
    }
  }

  /// 重複タスクを削除（内部メソッド）
  Future<void> _removeDuplicateTasks() async {
    try {
      final existingTasks = state;
      final tasksToDelete = <TaskItem>[];
      
      // タイトルとexternalIdの組み合わせで重複をチェック
      final seenTasks = <String, TaskItem>{};
      
      for (final task in existingTasks) {
        final key = '${task.title}_${task.externalId ?? 'no_external'}';
        
        if (seenTasks.containsKey(key)) {
          // 重複発見：より新しいタスクを保持
          final existingTask = seenTasks[key]!;
          if (task.createdAt.isAfter(existingTask.createdAt)) {
            tasksToDelete.add(existingTask);
            seenTasks[key] = task;
          } else {
            tasksToDelete.add(task);
          }
        } else {
          seenTasks[key] = task;
        }
      }
      
      // 重複タスクを削除
      for (final taskToDelete in tasksToDelete) {
        await _deleteTaskDirectly(taskToDelete.id);
        if (kDebugMode) {
          print('重複タスクを削除: ${taskToDelete.title}');
        }
      }
      
      if (kDebugMode && tasksToDelete.isNotEmpty) {
        print('重複タスク削除完了: ${tasksToDelete.length}件');
      }
    } catch (e) {
      print('重複タスク削除エラー: $e');
    }
  }

  /// 重複タスクを一括削除
  Future<Map<String, dynamic>> removeDuplicateTasks() async {
    try {
      if (kDebugMode) {
        print('=== 重複タスク削除開始 ===');
      }
      
      final existingTasks = state;
      final tasksToDelete = <TaskItem>[];
      
      // タイトルごとにグループ化して重複を検出
      final tasksByTitle = <String, List<TaskItem>>{};
      for (final task in existingTasks) {
        tasksByTitle.putIfAbsent(task.title, () => []).add(task);
      }
      
      // 各タイトルで重複をチェック
      for (final entry in tasksByTitle.entries) {
        final tasks = entry.value;
        
        if (tasks.length > 1) {
          // 同じタイトルのタスクが複数ある場合、重複をチェック
          for (int i = 0; i < tasks.length; i++) {
            for (int j = i + 1; j < tasks.length; j++) {
              if (_isSameTask(tasks[i], tasks[j])) {
                // より古いタスクを削除対象に追加
                final olderTask = tasks[i].createdAt.isBefore(tasks[j].createdAt) 
                    ? tasks[i] : tasks[j];
                if (!tasksToDelete.contains(olderTask)) {
                  tasksToDelete.add(olderTask);
                  if (kDebugMode) {
                    print('重複タスクを削除対象に追加: ${olderTask.title}');
                  }
                }
              }
            }
          }
        }
      }
      
      // 重複タスクを直接削除
      int deletedCount = 0;
      for (final taskToDelete in tasksToDelete) {
        await _deleteTaskDirectly(taskToDelete.id);
        deletedCount++;
      }
      
      if (kDebugMode) {
        print('=== 重複タスク削除完了 ===');
        print('削除されたタスク数: $deletedCount件');
      }
      
      return {
        'success': true,
        'deletedCount': deletedCount,
        'total': tasksToDelete.length,
      };
      
    } catch (e) {
      print('重複タスク削除エラー: $e');
      return {
        'success': false,
        'error': e.toString(),
        'deletedCount': 0,
        'total': 0,
      };
    }
  }


}
