import 'package:hive/hive.dart';
import '../models/export_template.dart';
import 'package:flutter/foundation.dart';

/// エクスポートテンプレートサービス
class ExportTemplateService {
  static const String _boxName = 'export_templates';
  
  /// テンプレートを保存
  Future<void> saveTemplate(ExportTemplate template) async {
    try {
      final box = await Hive.openBox(_boxName);
      final templates = _getTemplates(box);
      
      // 既存のテンプレートを更新または新規追加
      final index = templates.indexWhere((t) => t.id == template.id);
      if (index >= 0) {
        templates[index] = template.copyWith(updatedAt: DateTime.now());
      } else {
        templates.add(template);
      }
      
      await box.put('templates', templates.map((t) => t.toJson()).toList());
      
      if (kDebugMode) {
        print('テンプレートを保存しました: ${template.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('テンプレート保存エラー: $e');
      }
      rethrow;
    }
  }
  
  /// テンプレートを取得
  Future<ExportTemplate?> getTemplate(String id) async {
    try {
      final box = await Hive.openBox(_boxName);
      final templates = _getTemplates(box);
      return templates.firstWhere((t) => t.id == id, orElse: () => throw Exception('Template not found'));
    } catch (e) {
      if (kDebugMode) {
        print('テンプレート取得エラー: $e');
      }
      return null;
    }
  }
  
  /// 全テンプレートを取得
  Future<List<ExportTemplate>> getAllTemplates() async {
    try {
      final box = await Hive.openBox(_boxName);
      return _getTemplates(box);
    } catch (e) {
      if (kDebugMode) {
        print('テンプレート一覧取得エラー: $e');
      }
      return [];
    }
  }
  
  /// テンプレートを削除
  Future<void> deleteTemplate(String id) async {
    try {
      final box = await Hive.openBox(_boxName);
      final templates = _getTemplates(box);
      templates.removeWhere((t) => t.id == id);
      await box.put('templates', templates.map((t) => t.toJson()).toList());
      
      if (kDebugMode) {
        print('テンプレートを削除しました: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('テンプレート削除エラー: $e');
      }
      rethrow;
    }
  }
  
  List<ExportTemplate> _getTemplates(Box box) {
    try {
      final templatesData = box.get('templates');
      if (templatesData == null) {
        return [];
      }
      
      final List<dynamic> templatesList = templatesData is List ? templatesData : [];
      return templatesList
          .map((json) => ExportTemplate.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('テンプレート読み込みエラー: $e');
      }
      return [];
    }
  }
}

