import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../services/notification_service.dart';
import 'link_viewmodel.dart';

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
      await _loadTasks();
    } catch (e) {
      print('TaskViewModel初期化エラー: $e');
      state = [];
    }
  }

  Future<void> _loadTasks() async {
    try {
      print('=== タスク読み込み開始 ===');
      
      if (_taskBox == null || !_taskBox!.isOpen) {
        print('_taskBoxが初期化されていないため、初期化します');
        _taskBox = await Hive.openBox<TaskItem>(_boxName);
        print('_taskBox初期化完了');
      }
      
      final tasks = _taskBox!.values.toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = tasks;
      
      if (kDebugMode) {
        print('=== タスク読み込み完了 ===');
        print('読み込まれたタスク数: ${tasks.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスク読み込みエラー: $e');
        print('エラーの詳細: ${e.toString()}');
      }
      state = [];
    }
  }

  Future<void> addTask(TaskItem task) async {
    try {
      if (_taskBox == null || !_taskBox!.isOpen) {
        await _loadTasks();
      }
      await _taskBox!.put(task.id, task);
      final newTasks = [...state, task];
      newTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = newTasks;
      
      // リマインダー通知をスケジュール（エラーが発生しても続行）
      try {
        if (task.reminderTime != null) {
          await NotificationService.scheduleTaskReminder(task);
        }
      } catch (notificationError) {
        if (kDebugMode) {
          print('通知設定エラー（無視）: $notificationError');
        }
      }
      
      // リンクのタスク状態を更新
      await _updateLinkTaskStatus();
      
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
      await _taskBox!.put(task.id, task);
      final newTasks = state.map((t) => t.id == task.id ? task : t).toList();
      newTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = newTasks;
      
      // リマインダー通知を更新（エラーが発生しても続行）
      try {
        if (task.reminderTime != null) {
          await NotificationService.scheduleTaskReminder(task);
        } else {
          await NotificationService.cancelNotification(task.id);
        }
      } catch (notificationError) {
        if (kDebugMode) {
          print('通知更新エラー（無視）: $notificationError');
        }
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
      state = state.where((task) => task.id != taskId).toList();
      
      // 通知をキャンセル（エラーが発生しても続行）
      try {
        await NotificationService.cancelNotification(taskId);
      } catch (notificationError) {
        if (kDebugMode) {
          print('通知キャンセルエラー（無視）: $notificationError');
        }
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

  Future<void> completeTask(String taskId) async {
    try {
      final task = state.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
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
    bool isRecurring = false,
    String? recurringPattern,
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
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
    );
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

  // 内部用のリンクのタスク状態を更新
  Future<void> _updateLinkTaskStatus() async {
    await refreshLinkTaskStatus();
  }

  // データをインポート
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      print('=== タスクインポート開始 ===');
      print('受信データのキー: ${data.keys.toList()}');
      
      if (!data.containsKey('tasks')) {
        print('タスクデータが見つかりません');
        return;
      }
      
      final tasksData = data['tasks'] as List<dynamic>;
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
}
