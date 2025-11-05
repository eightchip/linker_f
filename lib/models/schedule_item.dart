import 'package:hive/hive.dart';

part 'schedule_item.g.dart';

@HiveType(typeId: 31)
class ScheduleItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String taskId; // 関連するタスクID

  @HiveField(2)
  String title; // 予定タイトル

  @HiveField(3)
  DateTime startDateTime; // 開始日時

  @HiveField(4)
  DateTime? endDateTime; // 終了日時（オプション）

  @HiveField(5)
  String? location; // 場所（オプション）

  @HiveField(6)
  String? notes; // メモ（オプション）

  @HiveField(7)
  DateTime createdAt; // 作成日時

  @HiveField(8)
  DateTime? updatedAt; // 更新日時

  ScheduleItem({
    required this.id,
    required this.taskId,
    required this.title,
    required this.startDateTime,
    this.endDateTime,
    this.location,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  ScheduleItem copyWith({
    String? id,
    String? taskId,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? location,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'location': location,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'],
      taskId: json['taskId'],
      title: json['title'],
      startDateTime: DateTime.parse(json['startDateTime']),
      endDateTime: json['endDateTime'] != null ? DateTime.parse(json['endDateTime']) : null,
      location: json['location'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

