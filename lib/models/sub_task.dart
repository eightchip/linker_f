import 'package:hive/hive.dart';

part 'sub_task.g.dart';

@HiveType(typeId: 9)
class SubTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? completedAt;

  @HiveField(6)
  int order;

  @HiveField(7)
  String? parentTaskId;

  @HiveField(8)
  int? estimatedMinutes;

  @HiveField(9)
  String? notes;

  SubTask({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    required this.order,
    this.parentTaskId,
    this.estimatedMinutes,
    this.notes,
  });

  SubTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    int? order,
    String? parentTaskId,
    int? estimatedMinutes,
    String? notes,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'order': order,
      'parentTaskId': parentTaskId,
      'estimatedMinutes': estimatedMinutes,
      'notes': notes,
    };
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      order: json['order'] as int? ?? 0,
      parentTaskId: json['parentTaskId'] as String?,
      estimatedMinutes: json['estimatedMinutes'] as int?,
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SubTask{id: $id, title: $title, isCompleted: $isCompleted}';
  }
}
