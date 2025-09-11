// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sent_mail_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SentMailLogAdapter extends TypeAdapter<SentMailLog> {
  @override
  final int typeId = 10;

  @override
  SentMailLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SentMailLog(
      id: fields[0] as String,
      taskId: fields[1] as String,
      app: fields[2] as String,
      token: fields[3] as String,
      to: fields[4] as String,
      cc: fields[5] as String,
      bcc: fields[6] as String,
      subject: fields[7] as String,
      body: fields[8] as String,
      composedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SentMailLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.app)
      ..writeByte(3)
      ..write(obj.token)
      ..writeByte(4)
      ..write(obj.to)
      ..writeByte(5)
      ..write(obj.cc)
      ..writeByte(6)
      ..write(obj.bcc)
      ..writeByte(7)
      ..write(obj.subject)
      ..writeByte(8)
      ..write(obj.body)
      ..writeByte(9)
      ..write(obj.composedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SentMailLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
