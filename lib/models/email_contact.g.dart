// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_contact.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmailContactAdapter extends TypeAdapter<EmailContact> {
  @override
  final int typeId = 11;

  @override
  EmailContact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmailContact(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      organization: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      lastUsedAt: fields[5] as DateTime,
      useCount: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, EmailContact obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.organization)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastUsedAt)
      ..writeByte(6)
      ..write(obj.useCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
