import 'package:hive/hive.dart';

part 'memo_item.g.dart';

@HiveType(typeId: 32)
class MemoItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String content; // メモの内容

  @HiveField(2)
  DateTime createdAt; // 作成日時

  @HiveField(3)
  DateTime updatedAt; // 更新日時

  MemoItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  MemoItem copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemoItem(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


