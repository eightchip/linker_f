import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/link_item.dart';
import '../models/group.dart';
import '../models/task_item.dart';
import '../models/sub_task.dart';
import '../models/schedule_item.dart';
import 'settings_service.dart';

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
      // OneDriveのファイルロックエラーの場合は警告のみ表示
      if (e.toString().contains('lock failed') || e.toString().contains('別のプロセスがファイル')) {
        print('OneDriveの同期によるファイルロックエラーが発生しました。アプリケーションは正常に動作します。');
      } else {
        print('マイグレーションエラーが発生しましたが、アプリケーションは続行します。');
      }
      // マイグレーションエラーは致命的ではないため、続行（rethrowしない）
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

  /// データの整合性チェック（予定の整合性チェックを含む）
  static Future<Map<String, dynamic>> validateDataIntegrity() async {
    final issues = <String>[];
    
    try {
      final groupsBox = await Hive.openBox<Group>('groups');
      final linksBox = await Hive.openBox<LinkItem>('links');
      final tasksBox = await Hive.openBox<TaskItem>('tasks');
      final subTasksBox = await Hive.openBox<SubTask>('sub_tasks');
      Box<ScheduleItem>? schedulesBox;
      try {
        schedulesBox = await Hive.openBox<ScheduleItem>('taskSchedules');
      } catch (e) {
        schedulesBox = null;
        print('予定ボックスのオープンエラー（チェック時、スキップ）: $e');
      }
      
      final taskIds = tasksBox.values.map((t) => t.id).toSet();
      
      // グループ内のリンクIDが個別リンクボックスに存在するかチェック
      for (final group in groupsBox.values) {
        for (final item in group.items) {
          if (!linksBox.containsKey(item.id)) {
            final issue = 'グループ "${group.title}" のリンク "${item.label}" が個別リンクボックスに存在しません';
            print('整合性エラー: $issue');
            issues.add(issue);
          }
        }
      }
      
      // タスクの関連リンクIDが存在するかチェック
      for (final task in tasksBox.values) {
        if (task.relatedLinkId != null && !linksBox.containsKey(task.relatedLinkId)) {
          final issue = 'タスク "${task.title}" の関連リンクID "${task.relatedLinkId}" が存在しません';
          print('整合性エラー: $issue');
          issues.add(issue);
        }
        
        // タスクのrelatedLinkIdsをチェック
        for (final linkId in task.relatedLinkIds) {
          if (!linksBox.containsKey(linkId)) {
            final issue = 'タスク "${task.title}" の関連リンクID "$linkId" が存在しません';
            print('整合性エラー: $issue');
            issues.add(issue);
          }
        }
      }
      
      // サブタスクの親タスクIDが存在するかチェック
      for (final subTask in subTasksBox.values) {
        if (subTask.parentTaskId != null && !taskIds.contains(subTask.parentTaskId)) {
          final issue = 'サブタスク "${subTask.title}" の親タスクID "${subTask.parentTaskId}" が存在しません';
          print('整合性エラー: $issue');
          issues.add(issue);
        }
      }
      
      // 予定のタスクIDが存在するかチェック
      if (schedulesBox != null) {
        for (final schedule in schedulesBox.values) {
          if (!taskIds.contains(schedule.taskId)) {
            final issue = '予定 "${schedule.title}" のタスクID "${schedule.taskId}" が存在しません';
            print('整合性エラー: $issue');
            issues.add(issue);
          }
        }
      }
      
      if (issues.isEmpty) {
        print('データ整合性チェック完了: 正常');
        return {'valid': true, 'issues': []};
      } else {
        print('データ整合性チェック完了: ${issues.length}件の問題を検出');
        return {'valid': false, 'issues': issues};
      }
    } catch (e) {
      print('データ整合性チェックエラー: $e');
      return {'valid': false, 'issues': ['整合性チェック実行エラー: $e']};
    }
  }

  /// 破損データの修復（予定の修復を含む）
  static Future<Map<String, int>> repairCorruptedData() async {
    final repairCounts = <String, int>{
      'groups': 0,
      'tasks': 0,
      'subTasks': 0,
      'schedules': 0,
    };
    
    try {
      print('破損データ修復開始');
      
      final groupsBox = await Hive.openBox<Group>('groups');
      final linksBox = await Hive.openBox<LinkItem>('links');
      final tasksBox = await Hive.openBox<TaskItem>('tasks');
      final subTasksBox = await Hive.openBox<SubTask>('sub_tasks');
      final schedulesBox = await Hive.openBox<ScheduleItem>('taskSchedules').catchError((e) => null);
      
      final taskIds = tasksBox.values.map((t) => t.id).toSet();
      final linkIds = linksBox.values.map((l) => l.id).toSet();
      
      // 存在しないリンクをグループから削除
      for (final group in groupsBox.values) {
        final validItems = group.items.where((item) => linkIds.contains(item.id)).toList();
        if (validItems.length != group.items.length) {
          final updatedGroup = group.copyWith(items: validItems);
          await groupsBox.put(group.id, updatedGroup);
          print('グループ "${group.title}" から無効なリンクを削除しました');
          repairCounts['groups'] = repairCounts['groups']! + 1;
        }
      }
      
      // 存在しないリンクを参照するタスクの関連リンクIDをクリア
      for (final task in tasksBox.values) {
        bool updated = false;
        TaskItem? updatedTask = task;
        
        // relatedLinkIdをクリア
        if (task.relatedLinkId != null && !linkIds.contains(task.relatedLinkId)) {
          updatedTask = task.copyWith(relatedLinkId: null);
          updated = true;
        }
        
        // relatedLinkIdsから無効なリンクIDを削除
        final validLinkIds = task.relatedLinkIds.where((id) => linkIds.contains(id)).toList();
        if (validLinkIds.length != task.relatedLinkIds.length) {
          updatedTask = updatedTask.copyWith(relatedLinkIds: validLinkIds);
          updated = true;
        }
        
        if (updated) {
          await tasksBox.put(updatedTask.id, updatedTask);
          print('タスク "${updatedTask.title}" の無効な関連リンクIDをクリアしました');
          repairCounts['tasks'] = repairCounts['tasks']! + 1;
        }
      }
      
      // 存在しないタスクを参照するサブタスクの親タスクIDをクリア
      for (final subTask in subTasksBox.values) {
        if (subTask.parentTaskId != null && !taskIds.contains(subTask.parentTaskId)) {
          final updatedSubTask = subTask.copyWith(parentTaskId: null);
          await subTasksBox.put(subTask.id, updatedSubTask);
          print('サブタスク "${subTask.title}" の無効な親タスクIDをクリアしました');
          repairCounts['subTasks'] = repairCounts['subTasks']! + 1;
        }
      }
      
      // 孤立した予定の修復（存在しないタスクIDに紐づく予定）
      if (schedulesBox != null) {
        TaskItem? orphanTask;
        
        // 言語設定を取得
        final settingsService = SettingsService.instance;
        final locale = settingsService.locale;
        final isEnglish = locale == 'en';
        
        // 孤立予定タスクのタイトル（日本語と英語の両方をチェック）
        final orphanedTitleJa = '孤立予定';
        final orphanedTitleEn = 'Orphaned Schedules';
        final orphanedDescriptionJa = '存在しないタスクに紐づいていた予定をまとめるためのタスクです。';
        final orphanedDescriptionEn = 'Task to collect schedules that were linked to non-existent tasks.';
        final systemGeneratedTagJa = 'システム生成';
        final systemGeneratedTagEn = 'System Generated';
        final orphanedTagJa = '孤立予定';
        final orphanedTagEn = 'Orphaned Schedules';
        
        final orphanedTitle = isEnglish ? orphanedTitleEn : orphanedTitleJa;
        final orphanedDescription = isEnglish ? orphanedDescriptionEn : orphanedDescriptionJa;
        final systemGeneratedTag = isEnglish ? systemGeneratedTagEn : systemGeneratedTagJa;
        final orphanedTag = isEnglish ? orphanedTagEn : orphanedTagJa;
        
        for (final schedule in schedulesBox.values) {
          if (!taskIds.contains(schedule.taskId)) {
            // 孤立予定タスクを作成または取得（日本語と英語の両方をチェック）
            if (orphanTask == null) {
              final orphanTasks = tasksBox.values.where((t) => 
                t.title == orphanedTitleJa || 
                t.title == orphanedTitleEn ||
                t.title.contains('孤立した予定') ||
                t.title.contains('Orphaned')
              ).toList();
              
              if (orphanTasks.isNotEmpty) {
                orphanTask = orphanTasks.first;
                // 既存のタスクのタイトル、説明、タグを現在の言語設定に応じて更新
                final needsUpdate = 
                    (isEnglish && orphanTask!.title == orphanedTitleJa) ||
                    (!isEnglish && orphanTask!.title == orphanedTitleEn) ||
                    (isEnglish && orphanTask!.description == orphanedDescriptionJa) ||
                    (!isEnglish && orphanTask!.description == orphanedDescriptionEn) ||
                    (isEnglish && orphanTask!.tags.contains(systemGeneratedTagJa)) ||
                    (!isEnglish && orphanTask!.tags.contains(systemGeneratedTagEn)) ||
                    (isEnglish && orphanTask!.tags.contains(orphanedTagJa)) ||
                    (!isEnglish && orphanTask!.tags.contains(orphanedTagEn));
                
                if (needsUpdate) {
                  // タグを更新
                  final updatedTags = orphanTask!.tags.map((tag) {
                    if (tag == systemGeneratedTagJa || tag == systemGeneratedTagEn) {
                      return systemGeneratedTag;
                    } else if (tag == orphanedTagJa || tag == orphanedTagEn) {
                      return orphanedTag;
                    }
                    return tag;
                  }).toList();
                  
                  orphanTask = orphanTask!.copyWith(
                    title: orphanedTitle,
                    description: orphanedDescription,
                    tags: updatedTags,
                  );
                  await tasksBox.put(orphanTask!.id, orphanTask!);
                  print('孤立予定タスクを現在の言語設定に更新しました: ${orphanTask!.id}');
                }
              } else {
                // 孤立予定タスクを作成
                final uuid = Uuid();
                orphanTask = TaskItem(
                  id: uuid.v4(),
                  title: orphanedTitle,
                  description: orphanedDescription,
                  priority: TaskPriority.low,
                  status: TaskStatus.inProgress,
                  createdAt: DateTime.now(),
                  tags: [systemGeneratedTag, orphanedTag],
                );
                await tasksBox.put(orphanTask.id, orphanTask);
                taskIds.add(orphanTask.id);
                print('孤立予定タスクを作成しました: ${orphanTask.id}');
              }
            }
            
            // 予定のタスクIDを更新
            final updatedSchedule = schedule.copyWith(
              taskId: orphanTask.id,
              updatedAt: DateTime.now(),
            );
            await schedulesBox.put(schedule.id, updatedSchedule);
            print('予定 "${schedule.title}" を孤立予定タスクに移動しました');
            repairCounts['schedules'] = repairCounts['schedules']! + 1;
          }
        }
      }
      
      print('破損データ修復完了: ${repairCounts.values.reduce((a, b) => a + b)}件修復');
      return repairCounts;
    } catch (e) {
      print('破損データ修復エラー: $e');
      rethrow;
    }
  }
}
