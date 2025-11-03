import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/task_item.dart';
import '../models/sub_task.dart';

class CsvExport {
  // サブタスク用のヘッダー
  static const String _subTaskCsvHeader = 'サブタスクID,親タスクID,サブタスクタイトル,サブタスク説明,完了状態,作成日,完了日,順序,推定時間(分),メモ\n';
  
  // 列の定義
  static const List<Map<String, String>> _columns = [
    {'id': 'id', 'label': 'ID'},
    {'id': 'title', 'label': 'タイトル'},
    {'id': 'description', 'label': '説明'},
    {'id': 'dueDate', 'label': '期限'},
    {'id': 'reminderTime', 'label': 'リマインダー時刻'},
    {'id': 'priority', 'label': '優先度'},
    {'id': 'status', 'label': 'ステータス'},
    {'id': 'tags', 'label': 'タグ'},
    {'id': 'relatedLinkId', 'label': '関連リンクID'},
    {'id': 'createdAt', 'label': '作成日'},
    {'id': 'completedAt', 'label': '完了日'},
    {'id': 'startedAt', 'label': '着手日'},
    {'id': 'completedAtManual', 'label': '完了日（手動入力）'},
    {'id': 'estimatedMinutes', 'label': '推定時間(分)'},
    {'id': 'notes', 'label': 'メモ'},
    {'id': 'isRecurring', 'label': '繰り返しタスク'},
    {'id': 'recurringPattern', 'label': '繰り返しパターン'},
    {'id': 'isRecurringReminder', 'label': '繰り返しリマインダー'},
    {'id': 'recurringReminderPattern', 'label': '繰り返しリマインダーパターン'},
    {'id': 'nextReminderTime', 'label': '次のリマインダー時刻'},
    {'id': 'reminderCount', 'label': 'リマインダー回数'},
    {'id': 'hasSubTasks', 'label': 'サブタスク有無'},
    {'id': 'completedSubTasksCount', 'label': '完了サブタスク数'},
    {'id': 'totalSubTasksCount', 'label': '総サブタスク数'},
  ];

  static List<Map<String, String>> getColumns() => _columns;

  static Future<File> exportTasksToCsv(
    List<TaskItem> tasks,
    List<SubTask> subTasks,
    String filePath, {
    Set<String>? selectedColumns,
  }) async {
    final csvContent = StringBuffer();
    
    // BOM（Byte Order Mark）を追加して文字化けを防ぐ
    csvContent.write('\uFEFF');
    
    // 列選択が指定されている場合は、選択された列のみを使用
    final columnsToUse = selectedColumns ?? _columns.map((c) => c['id']!).toSet();
    
    // タスクヘッダーを構築
    final headerParts = _columns
        .where((col) => columnsToUse.contains(col['id']))
        .map((col) => col['label']!)
        .toList();
    csvContent.write('${headerParts.join(',')}\n');
    
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
      
      // 選択された列の値を構築
      final row = <String>[];
      for (final col in _columns) {
        if (!columnsToUse.contains(col['id'])) continue;
        
        final columnId = col['id']!;
        String value = '';
        
        switch (columnId) {
          case 'id':
            value = _escapeCsvField(task.id);
            break;
          case 'title':
            value = _escapeCsvField(task.title);
            break;
          case 'description':
            value = _escapeCsvField(task.description ?? '');
            break;
          case 'dueDate':
            value = task.dueDate != null ? DateFormat('yyyy/MM/dd').format(task.dueDate!) : '';
            break;
          case 'reminderTime':
            value = task.reminderTime != null ? DateFormat('yyyy/MM/dd HH:mm').format(task.reminderTime!) : '';
            break;
          case 'priority':
            value = _getPriorityText(task.priority);
            break;
          case 'status':
            value = _getStatusText(task.status);
            break;
          case 'tags':
            value = _escapeCsvField(task.tags.join('; '));
            break;
          case 'relatedLinkId':
            value = _escapeCsvField(task.relatedLinkId ?? '');
            break;
          case 'createdAt':
            value = DateFormat('yyyy/MM/dd HH:mm').format(task.createdAt);
            break;
          case 'completedAt':
            value = task.completedAt != null ? DateFormat('yyyy/MM/dd HH:mm').format(task.completedAt!) : '';
            break;
          case 'startedAt':
            value = startedAt != null ? DateFormat('yyyy/MM/dd').format(startedAt) : '';
            break;
          case 'completedAtManual':
            value = completedAtManual != null ? DateFormat('yyyy/MM/dd').format(completedAtManual) : '';
            break;
          case 'estimatedMinutes':
            value = task.estimatedMinutes?.toString() ?? '';
            break;
          case 'notes':
            value = _escapeCsvField(task.notes ?? '');
            break;
          case 'isRecurring':
            value = task.isRecurring ? 'はい' : 'いいえ';
            break;
          case 'recurringPattern':
            value = _escapeCsvField(task.recurringPattern ?? '');
            break;
          case 'isRecurringReminder':
            value = task.isRecurringReminder ? 'はい' : 'いいえ';
            break;
          case 'recurringReminderPattern':
            value = _escapeCsvField(task.recurringReminderPattern ?? '');
            break;
          case 'nextReminderTime':
            value = task.nextReminderTime != null ? DateFormat('yyyy/MM/dd HH:mm').format(task.nextReminderTime!) : '';
            break;
          case 'reminderCount':
            value = task.reminderCount.toString();
            break;
          case 'hasSubTasks':
            value = task.hasSubTasks ? 'はい' : 'いいえ';
            break;
          case 'completedSubTasksCount':
            value = task.completedSubTasksCount.toString();
            break;
          case 'totalSubTasksCount':
            value = task.totalSubTasksCount.toString();
            break;
        }
        
        row.add(value);
      }
      
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
