import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_item.dart';

final scheduleViewModelProvider = StateNotifierProvider<ScheduleViewModel, List<ScheduleItem>>((ref) {
  return ScheduleViewModel();
});

class ScheduleViewModel extends StateNotifier<List<ScheduleItem>> {
  ScheduleViewModel() : super([]) {
    _initializeScheduleBox();
  }

  static const String _boxName = 'taskSchedules';
  Box<ScheduleItem>? _scheduleBox;
  final _uuid = const Uuid();
  bool _isInitialized = false;

  Future<void> waitForInitialization() async {
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _initializeScheduleBox() async {
    try {
      print('=== ScheduleViewModel初期化開始 ===');
      _scheduleBox = await Hive.openBox<ScheduleItem>(_boxName);
      await _loadSchedules();
      _isInitialized = true;
      print('=== ScheduleViewModel初期化完了 ===');
    } catch (e) {
      print('ScheduleViewModel初期化エラー: $e');
      state = [];
      _isInitialized = true;
    }
  }

  Future<void> loadSchedules() async {
    await _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      if (_scheduleBox == null || !_scheduleBox!.isOpen) {
        _scheduleBox = await Hive.openBox<ScheduleItem>(_boxName);
      }
      
      final schedules = _scheduleBox!.values.toList();
      schedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      state = schedules;
      
      if (kDebugMode) {
        print('予定読み込み完了: ${schedules.length}件');
      }
    } catch (e) {
      if (kDebugMode) {
        print('予定読み込みエラー: $e');
      }
      state = [];
    }
  }

  /// 予定を追加
  Future<void> addSchedule(ScheduleItem schedule) async {
    try {
      if (_scheduleBox == null || !_scheduleBox!.isOpen) {
        _scheduleBox = await Hive.openBox<ScheduleItem>(_boxName);
      }
      await _scheduleBox!.put(schedule.id, schedule);
      await _scheduleBox!.flush();
      // データベースから最新のデータを読み込む
      await _loadSchedules();

      if (kDebugMode) {
        print('予定追加: ${schedule.title}');
      }
    } catch (e) {
      print('予定追加エラー: $e');
    }
  }

  /// 予定を更新
  Future<void> updateSchedule(ScheduleItem schedule) async {
    try {
      if (_scheduleBox == null || !_scheduleBox!.isOpen) {
        await _loadSchedules();
      }
      final updatedSchedule = schedule.copyWith(updatedAt: DateTime.now());
      await _scheduleBox!.put(updatedSchedule.id, updatedSchedule);
      await _scheduleBox!.flush();
      await _loadSchedules();

      if (kDebugMode) {
        print('予定更新: ${schedule.title}');
      }
    } catch (e) {
      print('予定更新エラー: $e');
    }
  }

  /// 予定を削除
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      if (_scheduleBox == null || !_scheduleBox!.isOpen) {
        await _loadSchedules();
      }
      await _scheduleBox!.delete(scheduleId);
      await _scheduleBox!.flush();
      await _loadSchedules();

      if (kDebugMode) {
        print('予定削除: $scheduleId');
      }
    } catch (e) {
      print('予定削除エラー: $e');
    }
  }

  /// タスクIDに関連する予定を取得
  List<ScheduleItem> getSchedulesByTaskId(String taskId) {
    return state.where((s) => s.taskId == taskId).toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  /// 日付範囲の予定を取得
  List<ScheduleItem> getSchedulesByDateRange(DateTime start, DateTime end) {
    return state.where((s) {
      return s.startDateTime.isAfter(start.subtract(const Duration(days: 1))) &&
          s.startDateTime.isBefore(end.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  /// 予定を作成
  ScheduleItem createSchedule({
    required String taskId,
    required String title,
    required DateTime startDateTime,
    DateTime? endDateTime,
    String? location,
    String? notes,
  }) {
    return ScheduleItem(
      id: _uuid.v4(),
      taskId: taskId,
      title: title,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: location,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}

