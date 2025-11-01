import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/task_item.dart';
import '../models/sub_task.dart';

class CsvExport {
  // タスクの全項目を含むヘッダー
  static const String _csvHeader = 'ID,タイトル,説明,期限,リマインダー時刻,優先度,ステータス,タグ,関連リンクID,作成日,完了日,着手日,完了日（手動入力）,推定時間(分),メモ,繰り返しタスク,繰り返しパターン,繰り返しリマインダー,繰り返しリマインダーパターン,次のリマインダー時刻,リマインダー回数,サブタスク有無,完了サブタスク数,総サブタスク数\n';
  
  // サブタスク用のヘッダー
  static const String _subTaskCsvHeader = 'サブタスクID,親タスクID,サブタスクタイトル,サブタスク説明,完了状態,作成日,完了日,順序,推定時間(分),メモ\n';
  
  static Future<File> exportTasksToCsv(List<TaskItem> tasks, List<SubTask> subTasks, String filePath) async {
    final csvContent = StringBuffer();
    
    // BOM（Byte Order Mark）を追加して文字化けを防ぐ
    csvContent.write('\uFEFF');
    
    // タスクヘッダー
    csvContent.write(_csvHeader);
    
    // 着手日・完了日を読み込むためのHive boxを開く
    Box? taskDatesBox;
    try {
      taskDatesBox = await Hive.openBox('taskDates');
    } catch (e) {
      print('taskDates boxの読み込みエラー: $e');
    }
    
    // タスクデータ
    for (final task in tasks) {
      // 着手日・完了日を読み込み
      DateTime? startedAt;
      DateTime? completedAtManual;
      
      if (taskDatesBox != null) {
        try {
          final dates = taskDatesBox.get(task.id);
          if (dates != null) {
            final datesMap = Map<String, dynamic>.from(dates);
            if (datesMap['startedAt'] != null) {
              startedAt = DateTime.parse(datesMap['startedAt']);
            }
            if (datesMap['completedAt'] != null) {
              completedAtManual = DateTime.parse(datesMap['completedAt']);
            }
          }
        } catch (e) {
          print('タスク${task.id}の着手日・完了日読み込みエラー: $e');
        }
      }
      
      final row = [
        _escapeCsvField(task.id),
        _escapeCsvField(task.title),
        _escapeCsvField(task.description ?? ''),
        task.dueDate != null ? DateFormat('yyyy/MM/dd').format(task.dueDate!) : '',
        task.reminderTime != null ? DateFormat('yyyy/MM/dd HH:mm').format(task.reminderTime!) : '',
        _getPriorityText(task.priority),
        _getStatusText(task.status),
        _escapeCsvField(task.tags.join('; ')),
        _escapeCsvField(task.relatedLinkId ?? ''),
        DateFormat('yyyy/MM/dd HH:mm').format(task.createdAt),
        task.completedAt != null ? DateFormat('yyyy/MM/dd HH:mm').format(task.completedAt!) : '',
        startedAt != null ? DateFormat('yyyy/MM/dd').format(startedAt) : '',
        completedAtManual != null ? DateFormat('yyyy/MM/dd').format(completedAtManual) : '',
        task.estimatedMinutes?.toString() ?? '',
        _escapeCsvField(task.notes ?? ''),
        task.isRecurring ? 'はい' : 'いいえ',
        _escapeCsvField(task.recurringPattern ?? ''),
        task.isRecurringReminder ? 'はい' : 'いいえ',
        _escapeCsvField(task.recurringReminderPattern ?? ''),
        task.nextReminderTime != null ? DateFormat('yyyy/MM/dd HH:mm').format(task.nextReminderTime!) : '',
        task.reminderCount.toString(),
        task.hasSubTasks ? 'はい' : 'いいえ',
        task.completedSubTasksCount.toString(),
        task.totalSubTasksCount.toString(),
      ];
      
      csvContent.write('${row.join(',')}\n');
    }
    
    // サブタスクセクション
    csvContent.write('\n'); // 空行で区切り
    csvContent.write(_subTaskCsvHeader);
    
    // サブタスクデータ
    for (final subTask in subTasks) {
      final row = [
        _escapeCsvField(subTask.id),
        _escapeCsvField(subTask.parentTaskId ?? ''),
        _escapeCsvField(subTask.title),
        _escapeCsvField(subTask.description ?? ''),
        subTask.isCompleted ? '完了' : '未完了',
        DateFormat('yyyy/MM/dd HH:mm').format(subTask.createdAt),
        subTask.completedAt != null ? DateFormat('yyyy/MM/dd HH:mm').format(subTask.completedAt!) : '',
        subTask.order.toString(),
        subTask.estimatedMinutes?.toString() ?? '',
        _escapeCsvField(subTask.notes ?? ''),
      ];
      
      csvContent.write('${row.join(',')}\n');
    }
    
    final file = File(filePath);
    // UTF-8 with BOMで保存
    await file.writeAsBytes(utf8.encode(csvContent.toString()));
    return file;
  }
  
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
  
  static String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '緊急';
    }
  }
  
  static String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '未着手';
      case TaskStatus.inProgress:
        return '進行中';
      case TaskStatus.completed:
        return '完了';
      case TaskStatus.cancelled:
        return 'キャンセル';
    }
  }
}
