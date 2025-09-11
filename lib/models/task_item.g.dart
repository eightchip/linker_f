// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskItemAdapter extends TypeAdapter<TaskItem> {
  @override
  final int typeId = 8;

  @override
  TaskItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      dueDate: fields[3] as DateTime?,
      reminderTime: fields[4] as DateTime?,
      priority: fields[5] as TaskPriority,
      status: fields[6] as TaskStatus,
      tags: (fields[7] as List).cast<String>(),
      relatedLinkId: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      completedAt: fields[10] as DateTime?,
      estimatedMinutes: fields[11] as int?,
      notes: fields[12] as String?,
      isRecurring: fields[13] as bool,
      recurringPattern: fields[14] as String?,
      isRecurringReminder: fields[15] as bool,
      recurringReminderPattern: fields[16] as String?,
      nextReminderTime: fields[17] as DateTime?,
      reminderCount: fields[18] as int,
      hasSubTasks: fields[19] as bool,
      completedSubTasksCount: fields[20] as int,
      totalSubTasksCount: fields[21] as int,
      assignedTo: fields[22] as String?,
      source: fields[23] as String?,
      externalId: fields[24] as String?,
      googleCalendarEventId: fields[25] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskItem obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.reminderTime)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.relatedLinkId)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.completedAt)
      ..writeByte(11)
      ..write(obj.estimatedMinutes)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.isRecurring)
      ..writeByte(14)
      ..write(obj.recurringPattern)
      ..writeByte(15)
      ..write(obj.isRecurringReminder)
      ..writeByte(16)
      ..write(obj.recurringReminderPattern)
      ..writeByte(17)
      ..write(obj.nextReminderTime)
      ..writeByte(18)
      ..write(obj.reminderCount)
      ..writeByte(19)
      ..write(obj.hasSubTasks)
      ..writeByte(20)
      ..write(obj.completedSubTasksCount)
      ..writeByte(21)
      ..write(obj.totalSubTasksCount)
      ..writeByte(22)
      ..write(obj.assignedTo)
      ..writeByte(23)
      ..write(obj.source)
      ..writeByte(24)
      ..write(obj.externalId)
      ..writeByte(25)
      ..write(obj.googleCalendarEventId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 6;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.high;
      case 3:
        return TaskPriority.urgent;
      default:
        return TaskPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.low:
        writer.writeByte(0);
        break;
      case TaskPriority.medium:
        writer.writeByte(1);
        break;
      case TaskPriority.high:
        writer.writeByte(2);
        break;
      case TaskPriority.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 7;

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.pending;
      case 1:
        return TaskStatus.inProgress;
      case 2:
        return TaskStatus.completed;
      case 3:
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    switch (obj) {
      case TaskStatus.pending:
        writer.writeByte(0);
        break;
      case TaskStatus.inProgress:
        writer.writeByte(1);
        break;
      case TaskStatus.completed:
        writer.writeByte(2);
        break;
      case TaskStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
