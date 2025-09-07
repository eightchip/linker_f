import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../services/notification_service.dart';
import 'dart:io';
import '../services/windows_notification_service.dart';
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
      state = tasks;
      
      // 全タスクのサブタスク統計を更新
      await _updateAllSubTaskStatistics();
      
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

  // 全タスクのサブタスク統計を更新
  Future<void> _updateAllSubTaskStatistics() async {
    try {
      for (final task in state) {
        await updateSubTaskStatistics(task.id);
      }
      if (kDebugMode) {
        print('全タスクのサブタスク統計を更新しました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('全タスクのサブタスク統計更新エラー: $e');
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
      
      await _taskBox!.put(task.id, task);
      await _taskBox!.flush(); // データの永続化を確実にする
      final newTasks = state.map((t) => t.id == task.id ? task : t).toList();
      newTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = newTasks;
      
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
  }) {
    return TaskItem(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      reminderTime: reminderTime,
      priority: priority,
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
    );
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
      
      await updateTask(updatedTask);
      
      print('サブタスク統計更新完了: ${task.title}');
      print('更新後のタスク - サブタスクあり: ${updatedTask.hasSubTasks}, 総数: ${updatedTask.totalSubTasksCount}, 完了: ${updatedTask.completedSubTasksCount}');
    } catch (e) {
      print('サブタスク統計更新エラー: $e');
      print('エラーの詳細: ${e.toString()}');
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


}
