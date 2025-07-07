import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/widgets.dart';

part 'link_item.g.dart';

@HiveType(typeId: 0)
enum LinkType {
  @HiveField(0)
  file,
  @HiveField(1)
  folder,
  @HiveField(2)
  url,
}

@HiveType(typeId: 1)
class LinkItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String label;

  @HiveField(2)
  String path;

  @HiveField(3)
  LinkType type;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? lastUsed;

  @HiveField(6)
  bool isFavorite;

  @HiveField(7)
  String? memo;

  LinkItem({
    required this.id,
    required this.label,
    required this.path,
    required this.type,
    required this.createdAt,
    this.lastUsed,
    this.isFavorite = false,
    this.memo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'path': path,
      'type': type.index,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'isFavorite': isFavorite,
      'memo': memo,
    };
  }

  factory LinkItem.fromJson(Map<String, dynamic> json) {
    return LinkItem(
      id: json['id'],
      label: json['label'],
      path: json['path'],
      type: LinkType.values[json['type']],
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      isFavorite: json['isFavorite'] ?? false,
      memo: json['memo'],
    );
  }

  LinkItem copyWith({
    String? id,
    String? label,
    String? path,
    LinkType? type,
    DateTime? createdAt,
    DateTime? lastUsed,
    bool? isFavorite,
    String? memo,
  }) {
    return LinkItem(
      id: id ?? this.id,
      label: label ?? this.label,
      path: path ?? this.path,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      isFavorite: isFavorite ?? this.isFavorite,
      memo: memo ?? this.memo,
    );
  }
}

