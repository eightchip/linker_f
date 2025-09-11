import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../services/notification_service.dart';
import 'dart:io';
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
    _initializeTaskBox();
  }

  static const String _boxName = 'tasks';
  Box<TaskItem>? _taskBox;
  final _uuid = const Uuid();

  // _taskBoxの初期化を確実に行う
  Future<void> _initializeTaskBox() async {
    try {
      print('=== TaskViewModel初期化開始 ===');
      _taskBox = await Hive.openBox<TaskItem>(_boxName);
      print('_taskBox初期化完了');
      
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
    } catch (e) {
      print('TaskViewModel初期化エラー: $e');
      state = [];
    }
  }

  Future<void> _loadTasks() async {
    try {
      if (_taskBox == null || !_taskBox!.isOpen) {
        _taskBox = await Hive.openBox<TaskItem>(_boxName);
      }
      
      final tasks = _taskBox!.values.toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // 期限日のデバッグログ
      print('=== タスク読み込み時の期限日確認 ===');
      for (final task in tasks) {
        print('タスク: ${task.title}');
        print('期限日: ${task.dueDate}');
        print('リマインダー時間: ${task.reminderTime}');
        print('---');
      }
      
      state = tasks;
      
      // 起動時に祝日タスクを自動削除
      await _removeHolidayTasksOnStartup();
      
      if (kDebugMode) {
        print('=== タスク読み込み完了 ===');
        print('読み込まれたタスク数: ${tasks.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスク読み込みエラー: $e');
      }
      state = [];
    }
  }

  // 起動時に祝日タスクを自動削除
  Future<void> _removeHolidayTasksOnStartup() async {
    try {
      final existingTasks = state;
      final tasksToDelete = <TaskItem>[];
      
      // 祝日タスクを検出
      for (final task in existingTasks) {
        if (_isHolidayEvent(task)) {
          tasksToDelete.add(task);
        }
      }
      
      if (tasksToDelete.isNotEmpty) {
        if (kDebugMode) {
          print('=== 起動時祝日タスク削除開始 ===');
          print('削除対象の祝日タスク数: ${tasksToDelete.length}');
        }
        
        // 祝日タスクを直接削除
        for (final taskToDelete in tasksToDelete) {
          await _deleteTaskDirectly(taskToDelete.id);
        }
        
        if (kDebugMode) {
          print('=== 起動時祝日タスク削除完了 ===');
          print('削除されたタスク数: ${tasksToDelete.length}件');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('起動時祝日タスク削除エラー: $e');
      }
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
      
      final updatedTask = task.copyWith(
        status: TaskStatus.inProgress,
        dueDate: task.dueDate, // 期限日を保持
        reminderTime: task.reminderTime, // リマインダー時間を保持
      );
      
      await updateTask(updatedTask);
      
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

  Future<void> completeTask(String taskId) async {
    try {
      final task = state.firstWhere((t) => t.id == taskId);
      
      // リマインダーをクリア
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        reminderTime: null, // リマインダーをクリア
        isRecurringReminder: false, // 繰り返しリマインダーもクリア
        recurringReminderPattern: '', // 繰り返しパターンもクリア
        nextReminderTime: null, // 次のリマインダー時間もクリア
        reminderCount: 0, // リマインダーカウントもリセット
      );
      
      await updateTask(updatedTask);
      
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

  // リンクに関連するタスクを取得
  List<TaskItem> getTasksByLinkId(String linkId) {
    return state.where((task) => task.relatedLinkId == linkId).toList();
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
      
      final result = await googleCalendarService.syncFromGoogleCalendarToApp(state);
      
      // 実際にタスクを追加する処理は、Google Calendarサービスから返されたタスクリストを使用
      // ここでは同期結果のみを返す
      
      print('=== TaskViewModel: Google Calendar → アプリ同期完了 ===');
      print('結果: $result');
      
      return result;
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
      
      print('次のリマインダー設定完了: ${nextReminderTime}');
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

  // サブタスク統計を更新
  Future<void> updateSubTaskStatistics(String taskId) async {
    try {
      print('=== サブタスク統計更新開始 ===');
      print('対象タスクID: $taskId');
      
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
      
      final task = state.firstWhere((t) => t.id == taskId);
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
      if (_taskBox == null || !_taskBox!.isOpen) {
        await _loadTasks();
      }
      
      await _taskBox!.put(task.id, task);
      await _taskBox!.flush(); // データの永続化を確実にする
      
      // Riverpodの状態を正しく更新
      final newTasks = state.map((t) => t.id == task.id ? task : t).toList();
      newTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = newTasks;
      
      // リンクのタスク状態を更新
      await _updateLinkTaskStatus();
      
      if (kDebugMode) {
        print('タスク直接更新: ${task.title}');
        print('更新後のサブタスク統計 - 総数: ${task.totalSubTasksCount}, 完了: ${task.completedSubTasksCount}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスク直接更新エラー: $e');
      }
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
      
      final tasks = tasksData.map((json) {
        print('タスクJSON: $json');
        return TaskItem.fromJson(json);
      }).toList();
      
      print('パースされたタスク数: ${tasks.length}');
      
      // _taskBoxの初期化を確実に行う
      try {
        if (_taskBox == null || !_taskBox!.isOpen) {
          print('_taskBoxを初期化中...');
          _taskBox = await Hive.openBox<TaskItem>(_boxName);
          print('_taskBox初期化完了');
        }
      } catch (initError) {
        print('_taskBox初期化エラー: $initError');
        print('新しく_taskBoxを作成します');
        _taskBox = await Hive.openBox<TaskItem>(_boxName);
        print('_taskBox新規作成完了');
      }
      
      // 既存のタスクをクリア
      await _taskBox!.clear();
      print('既存タスクをクリアしました');
      
      // 新しいタスクを追加
      for (final task in tasks) {
        await _taskBox!.put(task.id, task);
        print('タスクを保存: ${task.title} (ID: ${task.id})');
      }
      await _taskBox!.flush(); // データの永続化を確実にする
      
      // 状態を更新
      state = tasks;
      print('状態を更新しました: ${tasks.length}件');
      
      // データの永続化を確実にするため、少し待機
      await Future.delayed(const Duration(milliseconds: 100));
      
      // リンクのタスク状態を更新
      await _updateLinkTaskStatus();
      
      print('=== タスクインポート完了: ${tasks.length}件 ===');
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
    for (final task in tasks) {
      print('復元タスク: ${task.title} (ID: ${task.id})');
      // リマインダーを再スケジュール
      if (task.reminderTime != null) {
        print('リマインダー時間: ${task.reminderTime}');
        if (Platform.isWindows) {
          WindowsNotificationService.scheduleTaskReminder(task);
        } else {
          NotificationService.scheduleTaskReminder(task);
        }
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
      print('元の期限日: ${originalTask.dueDate}');
      print('元のリマインダー時間: ${originalTask.reminderTime}');
      
      // 新しいタスクIDを生成
      final newTaskId = _uuid.v4();
      
      // 新しいタスクを作成
      final newTask = TaskItem(
        id: newTaskId,
        title: newTitle ?? '${originalTask.title} (コピー)',
        description: originalTask.description,
        dueDate: newDueDate ?? _calculateNextDueDate(originalTask.dueDate),
        reminderTime: newReminderTime ?? _calculateNextReminderTime(originalTask.reminderTime),
        priority: originalTask.priority,
        status: TaskStatus.pending,
        tags: List<String>.from(originalTask.tags),
        relatedLinkId: originalTask.relatedLinkId,
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
      
      // 状態を更新
      final updatedTasks = [...state, newTask];
      updatedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = updatedTasks;
      
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

  // 次の期限日を計算
  DateTime? _calculateNextDueDate(DateTime? originalDueDate) {
    if (originalDueDate == null) return null;
    
    // 現在時刻が元の期限日を過ぎている場合は、翌月の同日を設定
    final now = DateTime.now();
    if (originalDueDate.isBefore(now)) {
      return DateTime(
        now.year,
        now.month + 1,
        originalDueDate.day,
        originalDueDate.hour,
        originalDueDate.minute,
      );
    }
    
    return originalDueDate;
  }

  // 次のリマインダー時間を計算
  DateTime? _calculateNextReminderTime(DateTime? originalReminderTime) {
    if (originalReminderTime == null) return null;
    
    // 現在時刻が元のリマインダー時間を過ぎている場合は、翌月の同日を設定
    final now = DateTime.now();
    if (originalReminderTime.isBefore(now)) {
      return DateTime(
        now.year,
        now.month + 1,
        originalReminderTime.day,
        originalReminderTime.hour,
        originalReminderTime.minute,
      );
    }
    
    return originalReminderTime;
  }

  // Google Calendar同期関連のメソッド
  
  /// Google Calendarから同期したタスクを追加
  Future<void> syncTasksFromGoogleCalendar(List<TaskItem> calendarTasks) async {
    try {
      if (kDebugMode) {
        print('Google Calendar同期開始: ${calendarTasks.length}件のタスク');
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
        
        // 重複チェック（タイトルと日付で判定）
        final isDuplicate = _isDuplicateTask(calendarTask, existingTasks);
        if (isDuplicate) {
          if (kDebugMode) {
            print('重複タスクをスキップ: ${calendarTask.title}');
          }
          skippedCount++;
          continue;
        }
        
        // 既存のタスクを検索
        final existingTaskIndex = existingTasks.indexWhere(
          (task) => task.source == 'google_calendar' && task.externalId == calendarTask.externalId
        );
        
        if (existingTaskIndex >= 0) {
          // 既存タスクを更新
          final existingTask = existingTasks[existingTaskIndex];
          final updatedTask = existingTask.copyWith(
            title: calendarTask.title,
            description: calendarTask.description,
            dueDate: calendarTask.dueDate,
            reminderTime: calendarTask.reminderTime,
            priority: calendarTask.priority,
            estimatedMinutes: calendarTask.estimatedMinutes,
            assignedTo: calendarTask.assignedTo,
          );
          
          await updateTask(updatedTask);
          updatedCount++;
          
          if (kDebugMode) {
            print('Google Calendarタスク更新: ${calendarTask.title}');
          }
        } else {
          // 新しいタスクを追加
          await addTask(calendarTask);
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
      
      if (kDebugMode) {
        print('Google Calendar同期完了: 追加${addedCount}件, 更新${updatedCount}件, 削除${tasksToDelete.length}件, スキップ${skippedCount}件');
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
    
    // キーワードチェック
    for (final keyword in holidayKeywords) {
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
          if (kDebugMode) {
            print('祝日日付パターンで除外: ${task.title} (${month}/${day})');
          }
          return true;
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
        print('アプリ→Googleカレンダー: ${appToCalendarCount}件');
        print('Googleカレンダー→アプリ: ${calendarToAppCount}件');
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
  
  /// 2つのタスクが同じかどうかを判定（タイトルと日付で比較）
  bool _isSameTask(TaskItem task1, TaskItem task2) {
    // タイトルが同じ
    if (task1.title != task2.title) return false;
    
    // 日付が同じ（期限日またはリマインダー時間）
    if (task1.dueDate != null && task2.dueDate != null) {
      final dateDiff = task1.dueDate!.difference(task2.dueDate!).abs();
      if (dateDiff.inDays <= 1) return true;
    }
    
    if (task1.reminderTime != null && task2.reminderTime != null) {
      final timeDiff = task1.reminderTime!.difference(task2.reminderTime!).abs();
      if (timeDiff.inDays <= 1) return true;
    }
    
    // 期限日とリマインダー時間の組み合わせ
    if (task1.dueDate != null && task2.reminderTime != null) {
      final dateDiff = task1.dueDate!.difference(task2.reminderTime!).abs();
      if (dateDiff.inDays <= 1) return true;
    }
    
    if (task1.reminderTime != null && task2.dueDate != null) {
      final dateDiff = task1.reminderTime!.difference(task2.dueDate!).abs();
      if (dateDiff.inDays <= 1) return true;
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
