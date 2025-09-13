import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'task_item.g.dart';

@HiveType(typeId: 6)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent,
}

@HiveType(typeId: 7)
enum TaskStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  completed,
  @HiveField(3)
  cancelled,
}

// 繰り返しリマインダーパターン
class RecurringReminderPattern {
  static const String fiveMinutes = '5min';
  static const String fifteenMinutes = '15min';
  static const String thirtyMinutes = '30min';
  static const String oneHour = '1hour';
  static const String oneDay = '1day';
  static const String oneWeek = '1week';
  
  static const List<String> allPatterns = [
    fiveMinutes,
    fifteenMinutes,
    thirtyMinutes,
    oneHour,
    oneDay,
    oneWeek,
  ];
  
  static String getDisplayName(String pattern) {
    switch (pattern) {
      case fiveMinutes:
        return '5分後';
      case fifteenMinutes:
        return '15分後';
      case thirtyMinutes:
        return '30分後';
      case oneHour:
        return '1時間後';
      case oneDay:
        return '1日後';
      case oneWeek:
        return '1週間後';
      default:
        return pattern;
    }
  }
  
  static Duration getDuration(String pattern) {
    switch (pattern) {
      case fiveMinutes:
        return const Duration(minutes: 5);
      case fifteenMinutes:
        return const Duration(minutes: 15);
      case thirtyMinutes:
        return const Duration(minutes: 30);
      case oneHour:
        return const Duration(hours: 1);
      case oneDay:
        return const Duration(days: 1);
      case oneWeek:
        return const Duration(days: 7);
      default:
        return const Duration(minutes: 5);
    }
  }
}

@HiveType(typeId: 8)
class TaskItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  DateTime? reminderTime;

  @HiveField(5)
  TaskPriority priority;

  @HiveField(6)
  TaskStatus status;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  String? relatedLinkId; // リンクとの関連付け（後方互換性のため残す）

  @HiveField(26)
  List<String> relatedLinkIds; // 複数リンクとの関連付け

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime? completedAt;

  @HiveField(11)
  int? estimatedMinutes; // 推定所要時間

  @HiveField(12)
  String? notes; // 追加メモ

  @HiveField(13)
  bool isRecurring; // 繰り返しタスク

  @HiveField(14)
  String? recurringPattern; // 繰り返しパターン (daily, weekly, monthly)

  @HiveField(15)
  bool isRecurringReminder; // 繰り返しリマインダー

  @HiveField(16)
  String? recurringReminderPattern; // 繰り返しリマインダーパターン

  @HiveField(17)
  DateTime? nextReminderTime; // 次のリマインダー時刻

  @HiveField(18)
  int reminderCount; // リマインダー回数

  @HiveField(19)
  bool hasSubTasks; // サブタスクを持つかどうか

  @HiveField(20)
  int completedSubTasksCount; // 完了したサブタスクの数

  @HiveField(21)
  int totalSubTasksCount; // 総サブタスクの数

  @HiveField(22)
  String? assignedTo; // 依頼先（部下の名前）

  @HiveField(23)
  String? source; // タスクのソース（'manual', 'google_calendar'など）

  @HiveField(24)
  String? externalId; // 外部システムのID（Google CalendarのイベントIDなど）

  @HiveField(25)
  String? googleCalendarEventId; // Google CalendarイベントID（双方向同期用）

  @HiveField(27)
  bool isTeamTask; // チームタスクかどうか

  @HiveField(28)
  String? createdBy; // タスク作成者のメールアドレス

  @HiveField(29)
  String? originalEmailId; // 元のメールID

  @HiveField(30)
  String? originalEmailSubject; // 元のメール件名

  TaskItem({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.reminderTime,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.tags = const [],
    this.relatedLinkId,
    this.relatedLinkIds = const [],
    required this.createdAt,
    this.completedAt,
    this.estimatedMinutes,
    this.notes,
    this.isRecurring = false,
    this.recurringPattern,
    this.isRecurringReminder = false,
    this.recurringReminderPattern,
    this.nextReminderTime,
    this.reminderCount = 0,
    this.hasSubTasks = false,
    this.completedSubTasksCount = 0,
    this.totalSubTasksCount = 0,
    this.assignedTo,
    this.source,
    this.externalId,
    this.googleCalendarEventId,
    this.isTeamTask = false,
    this.createdBy,
    this.originalEmailId,
    this.originalEmailSubject,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'priority': priority.index,
      'status': status.index,
      'tags': tags,
      'relatedLinkId': relatedLinkId,
      'relatedLinkIds': relatedLinkIds,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'estimatedMinutes': estimatedMinutes,
      'notes': notes,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'isRecurringReminder': isRecurringReminder,
      'recurringReminderPattern': recurringReminderPattern,
      'nextReminderTime': nextReminderTime?.toIso8601String(),
      'reminderCount': reminderCount,
      'hasSubTasks': hasSubTasks,
      'completedSubTasksCount': completedSubTasksCount,
      'totalSubTasksCount': totalSubTasksCount,
      'assignedTo': assignedTo,
      'source': source,
      'externalId': externalId,
      'googleCalendarEventId': googleCalendarEventId,
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      reminderTime: json['reminderTime'] != null ? DateTime.parse(json['reminderTime']) : null,
      priority: TaskPriority.values[json['priority'] ?? 1],
      status: TaskStatus.values[json['status'] ?? 0],
      tags: List<String>.from(json['tags'] ?? []),
      relatedLinkId: json['relatedLinkId'],
      relatedLinkIds: List<String>.from(json['relatedLinkIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      estimatedMinutes: json['estimatedMinutes'],
      notes: json['notes'],
      isRecurring: json['isRecurring'] ?? false,
      recurringPattern: json['recurringPattern'],
      isRecurringReminder: json['isRecurringReminder'] ?? false,
      recurringReminderPattern: json['recurringReminderPattern'],
      nextReminderTime: json['nextReminderTime'] != null ? DateTime.parse(json['nextReminderTime']) : null,
      reminderCount: json['reminderCount'] ?? 0,
      hasSubTasks: json['hasSubTasks'] ?? false,
      completedSubTasksCount: json['completedSubTasksCount'] ?? 0,
      totalSubTasksCount: json['totalSubTasksCount'] ?? 0,
      assignedTo: json['assignedTo'],
      source: json['source'],
      externalId: json['externalId'],
      googleCalendarEventId: json['googleCalendarEventId'],
    );
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderTime,
    TaskPriority? priority,
    TaskStatus? status,
    List<String>? tags,
    String? relatedLinkId,
    List<String>? relatedLinkIds,
    DateTime? createdAt,
    DateTime? completedAt,
    int? estimatedMinutes,
    String? notes,
    bool? isRecurring,
    String? recurringPattern,
    bool? isRecurringReminder,
    String? recurringReminderPattern,
    DateTime? nextReminderTime,
    int? reminderCount,
    bool? hasSubTasks,
    int? completedSubTasksCount,
    int? totalSubTasksCount,
    String? assignedTo,
    String? source,
    String? externalId,
    String? googleCalendarEventId,
    bool clearDueDate = false,
    bool clearReminderTime = false,
    bool clearAssignedTo = false,
  }) {
    print('=== copyWith呼び出し ===');
    print('元のdueDate: ${this.dueDate}');
    print('新しいdueDate: $dueDate');
    print('dueDate == null: ${dueDate == null}');
    print('元のreminderTime: ${this.reminderTime}');
    print('新しいreminderTime: $reminderTime');
    print('reminderTime == null: ${reminderTime == null}');
    
    final result = TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate), // 期限日の適切な処理
      reminderTime: clearReminderTime ? null : (reminderTime ?? this.reminderTime), // リマインダー時間の適切な処理
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      relatedLinkId: relatedLinkId ?? this.relatedLinkId,
      relatedLinkIds: relatedLinkIds ?? this.relatedLinkIds,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      isRecurringReminder: isRecurringReminder ?? this.isRecurringReminder,
      recurringReminderPattern: recurringReminderPattern ?? this.recurringReminderPattern,
      nextReminderTime: nextReminderTime ?? this.nextReminderTime,
      reminderCount: reminderCount ?? this.reminderCount,
      hasSubTasks: hasSubTasks ?? this.hasSubTasks,
      completedSubTasksCount: completedSubTasksCount ?? this.completedSubTasksCount,
      totalSubTasksCount: totalSubTasksCount ?? this.totalSubTasksCount,
      assignedTo: clearAssignedTo ? null : (assignedTo ?? this.assignedTo),
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      googleCalendarEventId: googleCalendarEventId ?? this.googleCalendarEventId,
    );
    
    print('copyWith結果のdueDate: ${result.dueDate}');
    print('copyWith結果のreminderTime: ${result.reminderTime}');
    print('=== copyWith完了 ===');
    
    return result;
  }

  // タスクが期限切れかどうかを判定
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // 今日のタスクかどうかを判定
  bool get isToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
           dueDate!.month == now.month &&
           dueDate!.day == now.day;
  }

  // 今週のタスクかどうかを判定
  bool get isThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return dueDate!.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           dueDate!.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // 優先度の色を取得
  int get priorityColor {
    switch (priority) {
      case TaskPriority.low:
        return 0xFF4CAF50; // 緑
      case TaskPriority.medium:
        return 0xFFFF9800; // オレンジ
      case TaskPriority.high:
        return 0xFFF44336; // 赤
      case TaskPriority.urgent:
        return 0xFF9C27B0; // 紫
    }
  }

  // ステータスの色を取得
  int get statusColor {
    switch (status) {
      case TaskStatus.pending:
        return 0xFF757575; // グレー
      case TaskStatus.inProgress:
        return 0xFF2196F3; // 青
      case TaskStatus.completed:
        return 0xFF4CAF50; // 緑
      case TaskStatus.cancelled:
        return 0xFFF44336; // 赤
    }
  }
}
