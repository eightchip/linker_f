import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/sub_task.dart';
import 'task_viewmodel.dart';

final subTaskViewModelProvider = StateNotifierProvider<SubTaskViewModel, List<SubTask>>((ref) {
  return SubTaskViewModel(ref);
});

class SubTaskViewModel extends StateNotifier<List<SubTask>> {
  SubTaskViewModel(this._ref) : super([]) {
    _initializeSubTaskBox();
  }

  static const String _boxName = 'sub_tasks';
  Box<SubTask>? _subTaskBox;
  final _uuid = const Uuid();
  bool _isInitialized = false; // 初期化完了フラグを追加
  final Ref _ref; // Riverpodのrefを追加

  // 初期化完了を待つメソッド
  Future<void> waitForInitialization() async {
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // サブタスクを再読み込みするパブリックメソッド
  Future<void> refreshSubTasks() async {
    await _loadSubTasks();
  }

  Future<void> _initializeSubTaskBox() async {
    try {
      print('=== SubTaskViewModel初期化開始 ===');
      _subTaskBox = await Hive.openBox<SubTask>(_boxName);
      print('_subTaskBox初期化完了');
      await _loadSubTasks();
      _isInitialized = true; // 初期化完了フラグを設定
      print('=== SubTaskViewModel初期化完了 ===');
    } catch (e) {
      print('SubTaskViewModel初期化エラー: $e');
      state = [];
      _isInitialized = true; // エラーでもフラグを設定
    }
  }

  Future<void> _loadSubTasks() async {
    try {
      if (_subTaskBox == null || !_subTaskBox!.isOpen) {
        _subTaskBox = await Hive.openBox<SubTask>(_boxName);
      }
      
      final subTasks = _subTaskBox!.values.toList();
      subTasks.sort((a, b) => a.order.compareTo(b.order));
      state = subTasks;
      
      if (kDebugMode) {
        print('=== サブタスク読み込み完了 ===');
        print('読み込まれたサブタスク数: ${subTasks.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('サブタスク読み込みエラー: $e');
      }
      state = [];
    }
  }

  Future<void> addSubTask(SubTask subTask) async {
    try {
      if (_subTaskBox == null || !_subTaskBox!.isOpen) {
        await _loadSubTasks();
      }
      await _subTaskBox!.put(subTask.id, subTask);
      await _subTaskBox!.flush(); // データの永続化を確実にする
      final newSubTasks = [...state, subTask];
      newSubTasks.sort((a, b) => a.order.compareTo(b.order));
      state = newSubTasks;

      if (kDebugMode) {
        print('サブタスク追加: ${subTask.title}');
        print('親タスクID: ${subTask.parentTaskId}');
        print('現在のサブタスク数: ${state.length}');
      }
      
      // 親タスクの統計更新を確実に行う
      if (subTask.parentTaskId != null) {
        print('=== サブタスク追加時の親タスク統計更新 ===');
        print('親タスクID: ${subTask.parentTaskId}');
        print('サブタスクタイトル: ${subTask.title}');
        
        // 状態変更を確実に反映させるため、少し待機
        await Future.delayed(const Duration(milliseconds: 200));
        
        // TaskViewModelの統計更新を呼び出す
        try {
          // Riverpodのrefを使用してTaskViewModelにアクセス
          final taskViewModel = _ref.read(taskViewModelProvider.notifier);
          await taskViewModel.updateSubTaskStatistics(subTask.parentTaskId!);
          print('親タスクの統計更新完了');
        } catch (e) {
          print('親タスクの統計更新エラー: $e');
        }
        
        print('=== サブタスク追加時の親タスク統計更新完了 ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('サブタスク追加エラー: $e');
      }
    }
  }

  Future<void> updateSubTask(SubTask subTask) async {
    try {
      if (_subTaskBox == null || !_subTaskBox!.isOpen) {
        await _loadSubTasks();
      }
      await _subTaskBox!.put(subTask.id, subTask);
      await _subTaskBox!.flush(); // データの永続化を確実にする
      final newSubTasks = state.map((t) => t.id == subTask.id ? subTask : t).toList();
      newSubTasks.sort((a, b) => a.order.compareTo(b.order));
      state = newSubTasks;
      
      if (kDebugMode) {
        print('サブタスク更新: ${subTask.title}');
      }
      
      // 親タスクの統計更新
      if (subTask.parentTaskId != null) {
        try {
          final taskViewModel = _ref.read(taskViewModelProvider.notifier);
          await taskViewModel.updateSubTaskStatistics(subTask.parentTaskId!);
          print('サブタスク更新後の親タスク統計更新完了');
        } catch (e) {
          print('サブタスク更新後の親タスク統計更新エラー: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('サブタスク更新エラー: $e');
      }
    }
  }

  Future<void> deleteSubTask(String subTaskId) async {
    try {
      // 削除前に親タスクIDを取得
      String? parentTaskId;
      final subTaskToDelete = state.firstWhere((task) => task.id == subTaskId, orElse: () => throw Exception('サブタスクが見つかりません'));
      parentTaskId = subTaskToDelete.parentTaskId;
      
      if (_subTaskBox == null || !_subTaskBox!.isOpen) {
        await _loadSubTasks();
      }
      await _subTaskBox!.delete(subTaskId);
      await _subTaskBox!.flush(); // データの永続化を確実にする
      state = state.where((task) => task.id != subTaskId).toList();
      
      if (kDebugMode) {
        print('サブタスク削除: $subTaskId');
      }
      
      // 親タスクの統計更新
      if (parentTaskId != null) {
        try {
          final taskViewModel = _ref.read(taskViewModelProvider.notifier);
          await taskViewModel.updateSubTaskStatistics(parentTaskId);
          print('サブタスク削除後の親タスク統計更新完了');
        } catch (e) {
          print('サブタスク削除後の親タスク統計更新エラー: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('サブタスク削除エラー: $e');
      }
    }
  }

  Future<void> completeSubTask(String subTaskId) async {
    try {
      final subTask = state.firstWhere((t) => t.id == subTaskId);
      final updatedSubTask = subTask.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await updateSubTask(updatedSubTask);
      if (kDebugMode) {
        print('サブタスク完了: ${subTask.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('サブタスク完了エラー: $e');
      }
    }
  }

  Future<void> uncompleteSubTask(String subTaskId) async {
    try {
      final subTask = state.firstWhere((t) => t.id == subTaskId);
      final updatedSubTask = subTask.copyWith(
        isCompleted: false,
        completedAt: null,
      );
      await updateSubTask(updatedSubTask);
      if (kDebugMode) {
        print('サブタスク未完了に戻す: ${subTask.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('サブタスク未完了エラー: $e');
      }
    }
  }

  // 特定のタスクのサブタスクを取得
  List<SubTask> getSubTasksByParentId(String parentTaskId) {
    return state.where((subTask) => subTask.parentTaskId == parentTaskId).toList();
  }

  // サブタスクの順序を更新
  Future<void> updateSubTaskOrder(String parentTaskId, List<String> newOrder) async {
    try {
      final subTasks = getSubTasksByParentId(parentTaskId);
      for (int i = 0; i < newOrder.length; i++) {
        final subTask = subTasks.firstWhere((t) => t.id == newOrder[i]);
        final updatedSubTask = subTask.copyWith(order: i);
        await updateSubTask(updatedSubTask);
      }
    } catch (e) {
      if (kDebugMode) {
        print('サブタスク順序更新エラー: $e');
      }
    }
  }

  // サブタスクの並び替えを処理
  Future<void> updateSubTaskOrders(List<SubTask> reorderedSubTasks) async {
    try {
      if (_subTaskBox == null || !_subTaskBox!.isOpen) {
        await _loadSubTasks();
      }
      
      // 新しい順序でサブタスクを保存
      for (int i = 0; i < reorderedSubTasks.length; i++) {
        final subTask = reorderedSubTasks[i].copyWith(order: i);
        await _subTaskBox!.put(subTask.id, subTask);
      }
      
      await _subTaskBox!.flush(); // データの永続化を確実にする
      
      // 状態を更新
      final allSubTasks = _subTaskBox!.values.toList();
      allSubTasks.sort((a, b) => a.order.compareTo(b.order));
      state = allSubTasks;
      
      if (kDebugMode) {
        print('サブタスクの並び替えが完了しました: ${reorderedSubTasks.length}件');
      }
    } catch (e) {
      if (kDebugMode) {
        print('サブタスクの並び替えエラー: $e');
      }
    }
  }

  // 新しいサブタスクを作成
  SubTask createSubTask({
    required String title,
    String? description,
    required String parentTaskId,
    int? estimatedMinutes,
    String? notes,
  }) {
    final existingSubTasks = getSubTasksByParentId(parentTaskId);
    final maxOrder = existingSubTasks.isNotEmpty 
        ? existingSubTasks.map((t) => t.order).reduce((a, b) => a > b ? a : b) 
        : -1;

    return SubTask(
      id: _uuid.v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      order: maxOrder + 1,
      parentTaskId: parentTaskId,
      estimatedMinutes: estimatedMinutes,
      notes: notes,
    );
  }

  // データをエクスポート
  Map<String, dynamic> exportData() {
    return {
      'subTasks': state.map((subTask) => subTask.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // データをインポート
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      print('=== サブタスクインポート開始 ===');
      
      if (!data.containsKey('subTasks') || data['subTasks'] == null) {
        print('サブタスクデータが見つからないか、nullです');
        return;
      }
      
      final subTasksData = data['subTasks'] as List<dynamic>? ?? [];
      print('サブタスクデータ数: ${subTasksData.length}');
      
      final subTasks = subTasksData.map((json) {
        return SubTask.fromJson(json);
      }).toList();
      
      print('パースされたサブタスク数: ${subTasks.length}');
      
      // _subTaskBoxの初期化を確実に行う
      try {
        if (_subTaskBox == null || !_subTaskBox!.isOpen) {
          print('_subTaskBoxを初期化中...');
          _subTaskBox = await Hive.openBox<SubTask>(_boxName);
          print('_subTaskBox初期化完了');
        }
      } catch (initError) {
        print('_subTaskBox初期化エラー: $initError');
        print('新しく_subTaskBoxを作成します');
        _subTaskBox = await Hive.openBox<SubTask>(_boxName);
        print('_subTaskBox新規作成完了');
      }
      
      // 既存のサブタスクをクリア
      await _subTaskBox!.clear();
      print('既存サブタスクをクリアしました');
      
      // 新しいサブタスクを追加
      for (final subTask in subTasks) {
        await _subTaskBox!.put(subTask.id, subTask);
        print('サブタスクを保存: ${subTask.title} (ID: ${subTask.id})');
      }
      
      // 状態を更新
      state = subTasks;
      print('状態を更新しました: ${subTasks.length}件');
      
      print('=== サブタスクインポート完了: ${subTasks.length}件 ===');
    } catch (e) {
      print('=== サブタスクデータインポートエラー: $e ===');
      print('エラーの詳細: ${e.toString()}');
    }
  }
}
