import 'package:hive/hive.dart';

part 'email_contact.g.dart';

@HiveType(typeId: 11)
class EmailContact {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String email;
  @HiveField(3)
  final String? organization;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final DateTime lastUsedAt;
  @HiveField(6)
  final int useCount;

  EmailContact({
    required this.id,
    required this.name,
    required this.email,
    this.organization,
    required this.createdAt,
    required this.lastUsedAt,
    required this.useCount,
  });

  EmailContact copyWith({
    String? id,
    String? name,
    String? email,
    String? organization,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? useCount,
  }) {
    return EmailContact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      organization: organization ?? this.organization,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'organization': organization,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'useCount': useCount,
    };
  }

  factory EmailContact.fromJson(Map<String, dynamic> json) {
    return EmailContact(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      organization: json['organization'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUsedAt: DateTime.parse(json['lastUsedAt']),
      useCount: json['useCount'],
    );
  }

  @override
  String toString() {
    return 'EmailContact(id: $id, name: $name, email: $email, organization: $organization, createdAt: $createdAt, lastUsedAt: $lastUsedAt, useCount: $useCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailContact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// 表示用の名前（名前 + メールアドレス）
  String get displayName {
    if (organization != null && organization!.isNotEmpty) {
      return '$name ($email) - $organization';
    }
    return '$name ($email)';
  }

  /// 短縮表示名
  String get shortDisplayName {
    return '$name <$email>';
  }
}
