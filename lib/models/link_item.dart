import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  @HiveField(8)
  int? iconData;

  @HiveField(9)
  int? iconColor;

  @HiveField(10)
  List<String> tags;

  @HiveField(11)
  bool hasActiveTasks;

  @HiveField(12)
  String? faviconFallbackDomain;

  @HiveField(13)
  int useCount;

  LinkItem({
    required this.id,
    required this.label,
    required this.path,
    required this.type,
    required this.createdAt,
    this.lastUsed,
    this.isFavorite = false,
    this.memo,
    this.iconData,
    this.iconColor,
    this.tags = const [],
    this.hasActiveTasks = false,
    this.faviconFallbackDomain,
    this.useCount = 0,
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
      'iconData': iconData,
      'iconColor': iconColor,
      'tags': tags,
      'hasActiveTasks': hasActiveTasks,
      'faviconFallbackDomain': faviconFallbackDomain,
      'useCount': useCount,
    };
  }

  factory LinkItem.fromJson(Map<String, dynamic> json) {
    return LinkItem(
      id: json['id'] as String,
      label: json['label'] as String,
      path: json['path'] as String,
      type: LinkType.values[json['type'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed'] as String) : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
      memo: json['memo'] as String?,
      iconData: json['iconData'] as int?,
      iconColor: json['iconColor'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      hasActiveTasks: json['hasActiveTasks'] as bool? ?? false,
      faviconFallbackDomain: json['faviconFallbackDomain'] as String?,
      useCount: json['useCount'] as int? ?? 0,
    );
  }

  // センチネル値：明示的にnullを設定することを示す
  static const String nullSentinel = '__NULL_SENTINEL__';
  
  LinkItem copyWith({
    String? id,
    String? label,
    String? path,
    LinkType? type,
    DateTime? createdAt,
    DateTime? lastUsed,
    bool? isFavorite,
    String? memo,
    int? iconData,
    int? iconColor,
    List<String>? tags,
    bool? hasActiveTasks,
    String? faviconFallbackDomain,
    int? useCount,
  }) {
    // memoの特別な処理：センチネル値が渡された場合はnullに設定
    String? finalMemo;
    if (memo == nullSentinel) {
      finalMemo = null;
    } else {
      finalMemo = memo ?? this.memo;
    }
    
    return LinkItem(
      id: id ?? this.id,
      label: label ?? this.label,
      path: path ?? this.path,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      isFavorite: isFavorite ?? this.isFavorite,
      memo: finalMemo,
      iconData: iconData ?? this.iconData,
      iconColor: iconColor ?? this.iconColor,
      tags: tags ?? this.tags,
      hasActiveTasks: hasActiveTasks ?? this.hasActiveTasks,
      faviconFallbackDomain: faviconFallbackDomain ?? this.faviconFallbackDomain,
      useCount: useCount ?? this.useCount,
    );
  }
}

