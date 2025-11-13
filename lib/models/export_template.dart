import 'export_config.dart';

/// エクスポートテンプレート
class ExportTemplate {
  final String id;
  final String name;
  final String? description;
  final ExportConfig config;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExportTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.config,
    required this.createdAt,
    required this.updatedAt,
  });

  ExportTemplate copyWith({
    String? id,
    String? name,
    String? description,
    ExportConfig? config,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExportTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'config': config.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ExportTemplate.fromJson(Map<String, dynamic> json) {
    return ExportTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      config: ExportConfig.fromJson(json['config'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

