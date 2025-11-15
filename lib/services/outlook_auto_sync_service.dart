import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/outlook_calendar_service.dart';
import '../services/settings_service.dart';
import '../services/snackbar_service.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/schedule_viewmodel.dart';
import '../utils/error_handler.dart';

/// Outlook自動取込サービス
/// 個人Outlookカレンダーから予定を自動的に取り込む
class OutlookAutoSyncService {
  static final OutlookAutoSyncService _instance = OutlookAutoSyncService._internal();
  factory OutlookAutoSyncService() => _instance;
  OutlookAutoSyncService._internal();

  final OutlookCalendarService _outlookService = OutlookCalendarService();
  final SettingsService _settingsService = SettingsService.instance;
  
  /// 自動取込を実行
  /// [ref] RiverpodのRef（TaskViewModelとScheduleViewModelにアクセスするため）
  Future<void> syncOutlookCalendar(WidgetRef ref) async {
    try {
      // 設定を確認
      final isEnabled = _settingsService.outlookAutoSyncEnabled;
      if (!isEnabled) {
        if (kDebugMode) {
          print('Outlook自動取込は無効です');
        }
        return;
      }

      // Outlookが利用可能かチェック（プロセス監視付き）
      if (kDebugMode) {
        print('Outlook可用性チェック開始...');
      }
      final isAvailable = await _outlookService.isOutlookAvailable();
      if (!isAvailable) {
        if (kDebugMode) {
          print('Outlookが利用できないため、自動取込をスキップします');
        }
        SnackBarService.showGlobalInfo(
          'Outlookが利用できないため、自動取り込みをスキップしました',
        );
        return;
      }
      if (kDebugMode) {
        print('Outlook可用性確認完了');
      }

      // 専用タスクを取得または作成
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final syncTask = await taskViewModel.getOrCreateAutoOutlookSyncTask();

      // 取込期間を計算（明日から指定日数後まで）
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final periodDays = _settingsService.outlookAutoSyncPeriodDays;
      final endDate = tomorrow.add(Duration(days: periodDays));

      if (kDebugMode) {
        print('=== Outlook自動取込開始 ===');
        print('開始日: $tomorrow');
        print('終了日: $endDate');
        print('期間: $periodDays日');
      }

      // Outlookから予定を取得（タイムアウト・再試行付き）
      List<Map<String, dynamic>> events = [];
      try {
        events = await _outlookService.getCalendarEvents(
          startDate: tomorrow,
          endDate: endDate,
        );
      } catch (e) {
        ErrorHandler.logError('Outlook自動取込: 予定取得', e);
        if (kDebugMode) {
          print('予定取得エラー: $e');
        }
        SnackBarService.showGlobalInfo(
          'Outlookから予定を取得できませんでした。後でもう一度お試しください。',
        );
        rethrow;
      }

      if (kDebugMode) {
        print('取得した予定数: ${events.length}件');
      }

      // 既存の予定を取得（重複チェック用）
      final scheduleViewModel = ref.read(scheduleViewModelProvider.notifier);
      await scheduleViewModel.waitForInitialization();
      await scheduleViewModel.loadSchedules();
      final existingSchedules = ref.read(scheduleViewModelProvider);

      // 予定を変換して保存
      int addedCount = 0;
      int skippedCount = 0;

      for (final event in events) {
        try {
          final entryId = event['EntryID'] as String? ?? '';
          
          // EntryIDで重複チェック
          if (entryId.isNotEmpty) {
            final isDuplicate = existingSchedules.any(
              (schedule) => schedule.outlookEntryId == entryId,
            );
            
            if (isDuplicate) {
              skippedCount++;
              continue;
            }
          }

          // ScheduleItemに変換
          final schedule = _outlookService.convertEventToScheduleItem(
            taskId: syncTask.id,
            outlookEvent: event,
          );

          // 予定を保存
          await scheduleViewModel.addSchedule(schedule);
          addedCount++;

          if (kDebugMode && addedCount % 10 == 0) {
            print('予定を追加中... ($addedCount件)');
          }
        } catch (e) {
          if (kDebugMode) {
            print('予定の追加エラー: $e');
          }
          ErrorHandler.logError('Outlook自動取込', e);
        }
      }

      if (kDebugMode) {
        print('=== Outlook自動取込完了 ===');
        print('追加: $addedCount件');
        print('スキップ: $skippedCount件');
      }

      // メッセージを表示（追加があった場合のみ）
      if (addedCount > 0 || skippedCount > 0) {
        if (addedCount > 0) {
          SnackBarService.showGlobalSuccess(
            'Outlook自動取り込み完了: ${addedCount}件の予定を追加しました',
          );
        } else if (skippedCount > 0) {
          SnackBarService.showGlobalInfo(
            'Outlook自動取り込み完了: ${skippedCount}件の予定は既に取り込まれています',
          );
        }
      }
    } catch (e) {
      ErrorHandler.logError('Outlook自動取込', e);
      if (kDebugMode) {
        print('Outlook自動取込エラー: $e');
      }
    }
  }
}

