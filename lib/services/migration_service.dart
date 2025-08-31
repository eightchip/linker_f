import 'package:hive_flutter/hive_flutter.dart';
import '../models/link_item.dart';
import '../models/group.dart';
import '../models/task_item.dart';
import '../models/sub_task.dart';

class MigrationService {
  static const String _migrationVersionKey = 'migration_version';
  static const int _currentVersion = 2; // 現在のスキーマバージョン

  /// データマイグレーションを実行
  static Future<void> migrateData() async {
    try {
      final versionBox = await Hive.openBox('migration_version');
      final currentVersion = versionBox.get(_migrationVersionKey, defaultValue: 0) as int;
      
      if (currentVersion < _currentVersion) {
        print('データマイグレーション開始: バージョン $currentVersion → $_currentVersion');
        
        // バージョン1から2へのマイグレーション
        if (currentVersion < 2) {
          await _migrateToVersion2();
        }
        
        // バージョンを更新
        await versionBox.put(_migrationVersionKey, _currentVersion);
        print('データマイグレーション完了: バージョン $_currentVersion');
      }
    } catch (e) {
      print('データマイグレーションエラー: $e');
      rethrow;
    }
  }

  /// バージョン1から2へのマイグレーション（faviconFallbackDomain追加）
  static Future<void> _migrateToVersion2() async {
    try {
      print('バージョン2へのマイグレーション開始');
      
      // グループボックスのマイグレーション
      final groupsBox = await Hive.openBox<Group>('groups');
      final updatedGroups = <Group>[];
      
      for (final group in groupsBox.values) {
        final updatedItems = group.items.map((item) {
          // faviconFallbackDomainフィールドが存在しない場合、nullで初期化
          if (item.faviconFallbackDomain == null) {
            return item.copyWith(faviconFallbackDomain: null);
          }
          return item;
        }).toList();
        
        final updatedGroup = group.copyWith(items: updatedItems);
        updatedGroups.add(updatedGroup);
      }
      
      // 更新されたグループを保存
      for (final group in updatedGroups) {
        await groupsBox.put(group.id, group);
      }
      
      // 個別リンクボックスのマイグレーション
      final linksBox = await Hive.openBox<LinkItem>('links');
      final updatedLinks = <LinkItem>[];
      
      for (final link in linksBox.values) {
        // faviconFallbackDomainフィールドが存在しない場合、nullで初期化
        if (link.faviconFallbackDomain == null) {
          final updatedLink = link.copyWith(faviconFallbackDomain: null);
          updatedLinks.add(updatedLink);
        } else {
          updatedLinks.add(link);
        }
      }
      
      // 更新されたリンクを保存
      for (final link in updatedLinks) {
        await linksBox.put(link.id, link);
      }
      
      print('バージョン2へのマイグレーション完了');
    } catch (e) {
      print('バージョン2へのマイグレーションエラー: $e');
      rethrow;
    }
  }

  /// データの整合性チェック
  static Future<bool> validateDataIntegrity() async {
    try {
      final groupsBox = await Hive.openBox<Group>('groups');
      final linksBox = await Hive.openBox<LinkItem>('links');
      final tasksBox = await Hive.openBox<TaskItem>('tasks');
      final subTasksBox = await Hive.openBox<SubTask>('sub_tasks');
      
      // グループ内のリンクIDが個別リンクボックスに存在するかチェック
      for (final group in groupsBox.values) {
        for (final item in group.items) {
          if (!linksBox.containsKey(item.id)) {
            print('整合性エラー: グループ "${group.title}" のリンク "${item.label}" が個別リンクボックスに存在しません');
            return false;
          }
        }
      }
      
      // タスクの関連リンクIDが存在するかチェック
      for (final task in tasksBox.values) {
        if (task.relatedLinkId != null && !linksBox.containsKey(task.relatedLinkId)) {
          print('整合性エラー: タスク "${task.title}" の関連リンクID "${task.relatedLinkId}" が存在しません');
          return false;
        }
      }
      
      // サブタスクの親タスクIDが存在するかチェック
      for (final subTask in subTasksBox.values) {
        if (subTask.parentTaskId != null && !tasksBox.containsKey(subTask.parentTaskId)) {
          print('整合性エラー: サブタスク "${subTask.title}" の親タスクID "${subTask.parentTaskId}" が存在しません');
          return false;
        }
      }
      
      print('データ整合性チェック完了: 正常');
      return true;
    } catch (e) {
      print('データ整合性チェックエラー: $e');
      return false;
    }
  }

  /// 破損データの修復
  static Future<void> repairCorruptedData() async {
    try {
      print('破損データ修復開始');
      
      final groupsBox = await Hive.openBox<Group>('groups');
      final linksBox = await Hive.openBox<LinkItem>('links');
      final tasksBox = await Hive.openBox<TaskItem>('tasks');
      final subTasksBox = await Hive.openBox<SubTask>('sub_tasks');
      
      // 存在しないリンクをグループから削除
      for (final group in groupsBox.values) {
        final validItems = group.items.where((item) => linksBox.containsKey(item.id)).toList();
        if (validItems.length != group.items.length) {
          final updatedGroup = group.copyWith(items: validItems);
          await groupsBox.put(group.id, updatedGroup);
          print('グループ "${group.title}" から無効なリンクを削除しました');
        }
      }
      
      // 存在しないリンクを参照するタスクの関連リンクIDをクリア
      for (final task in tasksBox.values) {
        if (task.relatedLinkId != null && !linksBox.containsKey(task.relatedLinkId)) {
          final updatedTask = task.copyWith(relatedLinkId: null);
          await tasksBox.put(task.id, updatedTask);
          print('タスク "${task.title}" の無効な関連リンクIDをクリアしました');
        }
      }
      
      // 存在しないタスクを参照するサブタスクの親タスクIDをクリア
      for (final subTask in subTasksBox.values) {
        if (subTask.parentTaskId != null && !tasksBox.containsKey(subTask.parentTaskId)) {
          final updatedSubTask = subTask.copyWith(parentTaskId: null);
          await subTasksBox.put(subTask.id, updatedSubTask);
          print('サブタスク "${subTask.title}" の無効な親タスクIDをクリアしました');
        }
      }
      
      print('破損データ修復完了');
    } catch (e) {
      print('破損データ修復エラー: $e');
      rethrow;
    }
  }
}
