import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/schedule_item.dart';
import '../services/schedule_reminder_service.dart';
import '../services/google_calendar_service.dart';

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
      
      // リマインダーを復元
      await ScheduleReminderService.restoreReminders(schedules);
      
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

  /// 予定を追加（重複チェック付き）
  Future<void> addSchedule(ScheduleItem schedule) async {
    try {
      if (_scheduleBox == null || !_scheduleBox!.isOpen) {
        _scheduleBox = await Hive.openBox<ScheduleItem>(_boxName);
      }
      
      // Outlook EntryIDで既存予定を検索
      ScheduleItem? existingSchedule;
      if (schedule.outlookEntryId != null && schedule.outlookEntryId!.isNotEmpty) {
        for (final s in state) {
          if (s.outlookEntryId == schedule.outlookEntryId) {
            existingSchedule = s;
            if (kDebugMode) {
              print('既存予定を発見（EntryID）: ${s.title} (ID: ${s.id})');
            }
            break;
          }
        }
      }
      
      // 既存予定が見つかった場合は更新
      if (existingSchedule != null) {
        if (kDebugMode) {
          print('既存予定を更新: ${existingSchedule.title} -> ${schedule.title}');
        }
        // 既存予定の情報を保持しつつ、新しい情報で更新
        final updatedSchedule = existingSchedule.copyWith(
          title: schedule.title,
          startDateTime: schedule.startDateTime,
          endDateTime: schedule.endDateTime,
          location: schedule.location,
          notes: schedule.notes,
          updatedAt: DateTime.now(),
          outlookEntryId: schedule.outlookEntryId, // EntryIDを確実に保存
          // Google CalendarイベントIDは既存のものを保持
          googleCalendarEventId: existingSchedule.googleCalendarEventId,
        );
        await updateSchedule(updatedSchedule);
        return;
      }
      
      // 新規予定として追加
      // Google Calendarに同期（認証済みの場合）
      String? googleCalendarEventId;
      try {
        final googleCalendarService = GoogleCalendarService();
        await googleCalendarService.initialize();
        if (googleCalendarService.isAuthenticated) {
          final result = await googleCalendarService.createCalendarEventFromSchedule(schedule);
          if (result.success && result.details != null) {
            googleCalendarEventId = result.details!['eventId'] as String?;
            if (kDebugMode) {
              print('予定をGoogle Calendarに同期: ${schedule.title} -> $googleCalendarEventId');
            }
          } else {
            if (kDebugMode) {
              print('予定のGoogle Calendar同期失敗: ${result.errorMessage}');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('予定のGoogle Calendar同期エラー（無視）: $e');
        }
      }
      
      // Google CalendarイベントIDを設定して保存
      final scheduleWithEventId = schedule.copyWith(
        googleCalendarEventId: googleCalendarEventId,
      );
      await _scheduleBox!.put(scheduleWithEventId.id, scheduleWithEventId);
      await _scheduleBox!.flush();
      // データベースから最新のデータを読み込む
      await _loadSchedules();
      
      // リマインダーを設定
      await ScheduleReminderService.scheduleReminder(scheduleWithEventId);

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
      // 既存のリマインダーをキャンセル
      await ScheduleReminderService.cancelReminder(schedule.id);
      
      // Google Calendarに同期（認証済みの場合）
      String? googleCalendarEventId = schedule.googleCalendarEventId;
      try {
        final googleCalendarService = GoogleCalendarService();
        await googleCalendarService.initialize();
        if (googleCalendarService.isAuthenticated) {
          if (googleCalendarEventId != null) {
            // 既存イベントを更新
            final success = await googleCalendarService.updateCalendarEventFromSchedule(
              schedule,
              googleCalendarEventId,
            );
            if (!success && kDebugMode) {
              print('予定のGoogle Calendar更新失敗: ${schedule.title}');
            }
          } else {
            // 新規作成（既存イベントが見つからなかった場合）
            final result = await googleCalendarService.createCalendarEventFromSchedule(schedule);
            if (result.success && result.details != null) {
              googleCalendarEventId = result.details!['eventId'] as String?;
              if (kDebugMode) {
                print('予定をGoogle Calendarに新規作成: ${schedule.title} -> $googleCalendarEventId');
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('予定のGoogle Calendar同期エラー（無視）: $e');
        }
      }
      
      final updatedSchedule = schedule.copyWith(
        updatedAt: DateTime.now(),
        googleCalendarEventId: googleCalendarEventId,
      );
      await _scheduleBox!.put(updatedSchedule.id, updatedSchedule);
      await _scheduleBox!.flush();
      await _loadSchedules();
      
      // 新しいリマインダーを設定
      await ScheduleReminderService.scheduleReminder(updatedSchedule);

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
      
      // 削除前にGoogle CalendarイベントIDを取得
      final schedule = _scheduleBox!.get(scheduleId);
      String? googleCalendarEventId = schedule?.googleCalendarEventId;
      
      // リマインダーをキャンセル
      await ScheduleReminderService.cancelReminder(scheduleId);
      
      // Google Calendarから削除（認証済みの場合）
      if (googleCalendarEventId != null) {
        try {
          final googleCalendarService = GoogleCalendarService();
          await googleCalendarService.initialize();
          if (googleCalendarService.isAuthenticated) {
            final success = await googleCalendarService.deleteCalendarEvent(googleCalendarEventId);
            if (kDebugMode) {
              if (success) {
                print('予定をGoogle Calendarから削除: $googleCalendarEventId');
              } else {
                print('予定のGoogle Calendar削除失敗: $googleCalendarEventId');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('予定のGoogle Calendar削除エラー（無視）: $e');
          }
        }
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

