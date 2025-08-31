// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LinkItemAdapter extends TypeAdapter<LinkItem> {
  @override
  final int typeId = 1;

  @override
  LinkItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LinkItem(
      id: fields[0] as String,
      label: fields[1] as String,
      path: fields[2] as String,
      type: fields[3] as LinkType,
      createdAt: fields[4] as DateTime,
      lastUsed: fields[5] as DateTime?,
      isFavorite: fields[6] as bool,
      memo: fields[7] as String?,
      iconData: fields[8] as int?,
      iconColor: fields[9] as int?,
      tags: (fields[10] as List).cast<String>(),
      hasActiveTasks: fields[11] as bool,
      faviconFallbackDomain: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LinkItem obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastUsed)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.memo)
      ..writeByte(8)
      ..write(obj.iconData)
      ..writeByte(9)
      ..write(obj.iconColor)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.hasActiveTasks)
      ..writeByte(12)
      ..write(obj.faviconFallbackDomain);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LinkTypeAdapter extends TypeAdapter<LinkType> {
  @override
  final int typeId = 0;

  @override
  LinkType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LinkType.file;
      case 1:
        return LinkType.folder;
      case 2:
        return LinkType.url;
      default:
        return LinkType.file;
    }
  }

  @override
  void write(BinaryWriter writer, LinkType obj) {
    switch (obj) {
      case LinkType.file:
        writer.writeByte(0);
        break;
      case LinkType.folder:
        writer.writeByte(1);
        break;
      case LinkType.url:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
