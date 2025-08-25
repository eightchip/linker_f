import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'link_item.dart';

part 'group.g.dart';

@HiveType(typeId: 2)
class Group extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  List<LinkItem> items;

  @HiveField(3)
  bool collapsed;

  @HiveField(4)
  bool isRecentFiles;

  @HiveField(5)
  int order;

  @HiveField(6)
  bool isFavorite;

  @HiveField(7)
  int? color;

  @HiveField(8)
  List<String>? labels;

  @HiveField(9)
  int? iconData;

  @HiveField(10)
  int? iconColor;

  Group({
    required this.id,
    required this.title,
    required this.items,
    this.collapsed = false,
    this.isRecentFiles = false,
    this.order = 0,
    this.isFavorite = false,
    this.color,
    this.labels,
    this.iconData,
    this.iconColor,
  });

  Group copyWith({
    String? id,
    String? title,
    List<LinkItem>? items,
    bool? collapsed,
    bool? isRecentFiles,
    int? order,
    bool? isFavorite,
    int? color,
    List<String>? labels,
    int? iconData,
    int? iconColor,
  }) {
    return Group(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
      collapsed: collapsed ?? this.collapsed,
      isRecentFiles: isRecentFiles ?? this.isRecentFiles,
      order: order ?? this.order,
      isFavorite: isFavorite ?? this.isFavorite,
      color: color ?? this.color,
      labels: labels ?? this.labels,
      iconData: iconData ?? this.iconData,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
      'collapsed': collapsed,
      'isRecentFiles': isRecentFiles,
      'order': order,
      'isFavorite': isFavorite,
      'color': color,
      'labels': labels,
      'iconData': iconData,
      'iconColor': iconColor,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      title: json['title'],
      items: (json['items'] as List).map((item) => LinkItem.fromJson(item)).toList(),
      collapsed: json['collapsed'] ?? false,
      isRecentFiles: json['isRecentFiles'] ?? false,
      order: json['order'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      color: json['color'],
      labels: (json['labels'] as List?)?.map((e) => e.toString()).toList(),
      iconData: json['iconData'],
      iconColor: json['iconColor'],
    );
  }
}

class OffsetAdapter extends TypeAdapter<Offset> {
  @override
  final int typeId = 3;

  @override
  Offset read(BinaryReader reader) {
    final dx = reader.readDouble();
    final dy = reader.readDouble();
    return Offset(dx, dy);
  }

  @override
  void write(BinaryWriter writer, Offset obj) {
    writer.writeDouble(obj.dx);
    writer.writeDouble(obj.dy);
  }
} 