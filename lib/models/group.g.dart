// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupAdapter extends TypeAdapter<Group> {
  @override
  final int typeId = 2;

  @override
  Group read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Group(
      id: fields[0] as String,
      title: fields[1] as String,
      items: (fields[2] as List?)?.cast<LinkItem>() ?? [],
      collapsed: fields[3] as bool? ?? false,
      isRecentFiles: fields[4] as bool? ?? false,
      order: fields[5] as int? ?? 0,
      isFavorite: fields[6] as bool? ?? false,
      color: fields[7] as int?,
      labels: (fields[8] as List?)?.cast<String>() ?? [],
      iconData: fields[9] as int?,
      iconColor: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.collapsed)
      ..writeByte(4)
      ..write(obj.isRecentFiles)
      ..writeByte(5)
      ..write(obj.order)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.labels)
      ..writeByte(9)
      ..write(obj.iconData)
      ..writeByte(10)
      ..write(obj.iconColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
