// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemoItemAdapter extends TypeAdapter<MemoItem> {
  @override
  final int typeId = 32;

  @override
  MemoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemoItem(
      id: fields[0] as String,
      content: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MemoItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
