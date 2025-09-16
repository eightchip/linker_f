import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../repositories/link_repository.dart';
import '../services/settings_service.dart';
import '../utils/error_handler.dart';
import '../models/link_item.dart';
import '../models/task_item.dart';
import '../models/group.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/link_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// インポート結果クラス
class ImportResult {
  final List<LinkItem> links;
  final List<TaskItem> tasks;
  final List<Group> groups;
  final List<String> warnings;

  ImportResult({
    required this.links,
    required this.tasks,
    required this.groups,
    required this.warnings,
  });
}

/// 自動バックアップサービス
class BackupService {
  static const String _backupFolderName = 'backups';
  static const int _maxBackupFiles = 10;
  
  final LinkRepository _linkRepository;
  final SettingsService _settingsService;
  final TaskViewModel? _taskViewModel;
  
  // バックアップ完了時のコールバック
  static Function(String backupPath)? _onBackupCompleted;
  
  BackupService({
    required LinkRepository linkRepository,
    required SettingsService settingsService,
    TaskViewModel? taskViewModel,
  }) : _linkRepository = linkRepository,
       _settingsService = settingsService,
       _taskViewModel = taskViewModel;
  
  /// バックアップ完了コールバックを設定
  static void setOnBackupCompleted(Function(String backupPath) callback) {
    _onBackupCompleted = callback;
  }

  /// 自動バックアップをチェックして実行
  Future<void> checkAndPerformAutoBackup() async {
    try {
      if (!_settingsService.autoBackup) {
        if (kDebugMode) {
          print('自動バックアップが無効です');
        }
        return;
      }

      final lastBackup = _settingsService.lastBackup;
      final backupInterval = _settingsService.backupInterval;
      
      if (lastBackup == null) {
        // 初回バックアップ
        await performBackup();
        return;
      }

      final daysSinceLastBackup = DateTime.now().difference(lastBackup).inDays;
      
      if (daysSinceLastBackup >= backupInterval) {
        if (kDebugMode) {
          print('自動バックアップを実行します（前回から${daysSinceLastBackup}日経過）');
        }
        await performBackup();
      } else {
        if (kDebugMode) {
          print('自動バックアップの時期ではありません（前回から${daysSinceLastBackup}日経過、間隔: ${backupInterval}日）');
        }
      }
    } catch (e) {
      ErrorHandler.logError('自動バックアップチェック', e);
    }
  }

  /// バックアップを実行
  Future<void> performBackup() async {
    try {
      if (kDebugMode) {
        print('バックアップを開始します');
      }

      final backupData = await _createBackupData();
      final backupFile = await _saveBackupFile(backupData);
      
      await _cleanupOldBackups();
      await _settingsService.setLastBackup(DateTime.now());
      
      if (kDebugMode) {
        print('バックアップが完了しました: ${backupFile.path}');
      }
      
      // バックアップ完了コールバックを呼び出し
      _onBackupCompleted?.call(backupFile.path);
    } catch (e) {
      ErrorHandler.logError('バックアップ実行', e);
      rethrow;
    }
  }

  /// バックアップデータを作成
  Future<Map<String, dynamic>> _createBackupData() async {
    final linkData = _linkRepository.exportData();
    final settingsData = _settingsService.exportSettings();
    
    return {
      'version': '1.0',
      'createdAt': DateTime.now().toIso8601String(),
      'linkData': linkData,
      'settingsData': settingsData,
      'backupType': 'auto',
    };
  }

  /// バックアップファイルを保存
  Future<File> _saveBackupFile(Map<String, dynamic> backupData) async {
    final backupDir = await getBackupDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'linker_backup_$timestamp.json';
    final backupFile = File('${backupDir.path}/$fileName');
    
    final jsonString = jsonEncode(backupData);
    await backupFile.writeAsString(jsonString);
    
    return backupFile;
  }

  /// バックアップディレクトリを取得または作成
  Future<Directory> getBackupDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDocDir.path}/$_backupFolderName');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }

  /// 古いバックアップファイルを削除
  Future<void> _cleanupOldBackups() async {
    try {
      final backupDir = await getBackupDirectory();
      final files = backupDir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      
      if (files.length > _maxBackupFiles) {
        // 作成日時でソート（古い順）
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        
        // 古いファイルを削除
        final filesToDelete = files.take(files.length - _maxBackupFiles);
        for (final file in filesToDelete) {
          await file.delete();
          if (kDebugMode) {
            print('古いバックアップファイルを削除: ${file.path}');
          }
        }
      }
    } catch (e) {
      ErrorHandler.logError('古いバックアップファイルの削除', e);
    }
  }

  /// 手動バックアップを実行
  Future<File?> performManualBackup() async {
    try {
      if (kDebugMode) {
        print('手動バックアップを開始します');
      }

      final backupData = await _createBackupData();
      final backupFile = await _saveBackupFile(backupData);
      
      if (kDebugMode) {
        print('手動バックアップが完了しました: ${backupFile.path}');
      }
      
      return backupFile;
    } catch (e) {
      ErrorHandler.logError('手動バックアップ実行', e);
      rethrow;
    }
  }

  /// バックアップから復元
  Future<void> restoreFromBackup(File backupFile) async {
    try {
      if (kDebugMode) {
        print('バックアップから復元を開始します: ${backupFile.path}');
      }

      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // バックアップデータの検証
      if (!_validateBackupData(backupData)) {
        throw Exception('無効なバックアップファイルです');
      }
      
      // リンクデータの復元
      if (backupData['linkData'] != null) {
        await _linkRepository.importData(backupData['linkData']);
      }
      
      // 設定データの復元
      if (backupData['settingsData'] != null) {
        await _settingsService.importSettings(backupData['settingsData']);
      }
      
      if (kDebugMode) {
        print('バックアップからの復元が完了しました');
      }
    } catch (e) {
      ErrorHandler.logError('バックアップ復元', e);
      rethrow;
    }
  }

  /// バックアップデータの検証
  bool _validateBackupData(Map<String, dynamic> backupData) {
    try {
      // 必須フィールドのチェック
      if (!backupData.containsKey('version') ||
          !backupData.containsKey('createdAt') ||
          !backupData.containsKey('linkData')) {
        return false;
      }
      
      // バージョンチェック
      final version = backupData['version'] as String;
      if (!version.startsWith('1.')) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 利用可能なバックアップファイルの一覧を取得
  Future<List<BackupFileInfo>> getAvailableBackups() async {
    try {
      final backupDir = await getBackupDirectory();
      final files = backupDir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      
      final backupInfos = <BackupFileInfo>[];
      
      for (final file in files) {
        try {
          final jsonString = await file.readAsString();
          final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
          
          final createdAt = DateTime.parse(backupData['createdAt'] as String);
          final backupType = backupData['backupType'] as String? ?? 'unknown';
          final fileSize = await file.length();
          
          backupInfos.add(BackupFileInfo(
            file: file,
            createdAt: createdAt,
            backupType: backupType,
            fileSize: fileSize,
          ));
        } catch (e) {
          if (kDebugMode) {
            print('バックアップファイルの読み込みエラー: ${file.path} - $e');
          }
        }
      }
      
      // 作成日時でソート（新しい順）
      backupInfos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return backupInfos;
    } catch (e) {
      ErrorHandler.logError('バックアップ一覧取得', e);
      return [];
    }
  }

  /// バックアップの統計情報を取得
  Future<BackupStats> getBackupStats() async {
    try {
      final backupDir = await getBackupDirectory();
      final files = backupDir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      
      int totalSize = 0;
      int autoBackupCount = 0;
      int manualBackupCount = 0;
      
      for (final file in files) {
        try {
          final jsonString = await file.readAsString();
          final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
          
          totalSize += (await file.length()).toInt();
          
          final backupType = backupData['backupType'] as String? ?? 'unknown';
          if (backupType == 'auto') {
            autoBackupCount++;
          } else if (backupType == 'manual') {
            manualBackupCount++;
          }
        } catch (e) {
          // エラーは無視
        }
      }
      
      return BackupStats(
        totalFiles: files.length,
        totalSize: totalSize,
        autoBackupCount: autoBackupCount,
        manualBackupCount: manualBackupCount,
        lastBackup: _settingsService.lastBackup,
        nextBackup: _getNextBackupDate(),
      );
    } catch (e) {
      ErrorHandler.logError('バックアップ統計取得', e);
      return BackupStats.empty();
    }
  }

  /// 次回バックアップ予定日を取得
  DateTime? _getNextBackupDate() {
    final lastBackup = _settingsService.lastBackup;
    if (lastBackup == null) return null;
    
    final backupInterval = _settingsService.backupInterval;
    return lastBackup.add(Duration(days: backupInterval));
  }

  /// 特定のバックアップファイルを削除
  Future<void> deleteBackup(File backupFile) async {
    try {
      await backupFile.delete();
      if (kDebugMode) {
        print('バックアップファイルを削除しました: ${backupFile.path}');
      }
    } catch (e) {
      ErrorHandler.logError('バックアップファイル削除', e);
      rethrow;
    }
  }

  /// すべてのバックアップファイルを削除
  Future<void> deleteAllBackups() async {
    try {
      final backupDir = await getBackupDirectory();
      final files = backupDir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      
      for (final file in files) {
        await file.delete();
      }
      
      if (kDebugMode) {
        print('すべてのバックアップファイルを削除しました');
      }
    } catch (e) {
      ErrorHandler.logError('全バックアップファイル削除', e);
      rethrow;
    }
  }
}

/// バックアップファイル情報
class BackupFileInfo {
  final File file;
  final DateTime createdAt;
  final String backupType;
  final int fileSize;

  BackupFileInfo({
    required this.file,
    required this.createdAt,
    required this.backupType,
    required this.fileSize,
  });

  String get fileName => file.path.split('/').last;
  String get formattedSize => _formatFileSize(fileSize);
  String get formattedDate => '${createdAt.year}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// バックアップ統計情報
class BackupStats {
  final int totalFiles;
  final int totalSize;
  final int autoBackupCount;
  final int manualBackupCount;
  final DateTime? lastBackup;
  final DateTime? nextBackup;

  BackupStats({
    required this.totalFiles,
    required this.totalSize,
    required this.autoBackupCount,
    required this.manualBackupCount,
    this.lastBackup,
    this.nextBackup,
  });

  factory BackupStats.empty() {
    return BackupStats(
      totalFiles: 0,
      totalSize: 0,
      autoBackupCount: 0,
      manualBackupCount: 0,
    );
  }

  String get formattedTotalSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedLastBackup {
    if (lastBackup == null) return 'なし';
    return '${lastBackup!.year}/${lastBackup!.month.toString().padLeft(2, '0')}/${lastBackup!.day.toString().padLeft(2, '0')}';
  }

  String get formattedNextBackup {
    if (nextBackup == null) return 'なし';
    return '${nextBackup!.year}/${nextBackup!.month.toString().padLeft(2, '0')}/${nextBackup!.day.toString().padLeft(2, '0')}';
  }
}

/// 統合バックアップ/エクスポートサービス
class IntegratedBackupService {
  static const String _backupFolderName = 'backups';
  static const int _maxBackupFiles = 10;
  
  final LinkRepository _linkRepository;
  final SettingsService _settingsService;
  final TaskViewModel? _taskViewModel;
  final WidgetRef? _ref;
  
  IntegratedBackupService({
    required LinkRepository linkRepository,
    required SettingsService settingsService,
    TaskViewModel? taskViewModel,
    WidgetRef? ref,
  }) : _linkRepository = linkRepository,
       _settingsService = settingsService,
       _taskViewModel = taskViewModel,
       _ref = ref;

  /// 統合エクスポート（v2形式）
  Future<String> exportData({
    bool onlyLinks = false,
    bool onlyTasks = false,
  }) async {
    try {
      final backupDir = await getBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // エクスポートタイプを決定
      String exportType;
      if (onlyLinks) {
        exportType = 'links_only';
      } else if (onlyTasks) {
        exportType = 'tasks_only';
      } else {
        exportType = 'both';
      }
      
      final fileName = 'linker_backup_${exportType}_$timestamp.json';
      final filePath = '${backupDir.path}/$fileName';
      
      final exportData = <String, dynamic>{
        'version': '2.0',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'exportType': exportType,
        'description': _getExportDescription(exportType),
      };
      
      // リンクデータ
      if (!onlyTasks) {
        final links = _linkRepository.getAllLinks();
        final groups = _linkRepository.getAllGroups();
        
        // グループ内のリンクIDを収集
        final groupLinkIds = <String>{};
        for (final group in groups) {
          for (final item in group.items) {
            groupLinkIds.add(item.id);
          }
        }
        
        // グループに含まれていないリンクのみをエクスポート
        final standaloneLinks = links.where((link) => !groupLinkIds.contains(link.id)).toList();
        exportData['links'] = standaloneLinks.map((link) => link.toJson()).toList();
        
        // グループデータも含める
        exportData['groups'] = groups.map((group) => group.toJson()).toList();
        
        // グループ順序も含める
        final groupsOrder = _linkRepository.getGroupsOrder();
        exportData['groupsOrder'] = groupsOrder;
        
        if (kDebugMode) {
          print('=== エクスポートデータ ===');
          print('全リンク数: ${links.length}');
          print('グループ外リンク数: ${standaloneLinks.length}');
          print('グループ数: ${groups.length}');
          print('グループ順序: $groupsOrder');
          print('====================');
        }
      }
      
      // タスクデータ
      if (!onlyLinks && _taskViewModel != null) {
        final tasks = _taskViewModel!.tasks;
        exportData['tasks'] = tasks.map((task) => task.toJson()).toList();
      }
      
      // 設定データ
      exportData['settings'] = {
        'autoBackup': _settingsService.autoBackup,
        'backupInterval': _settingsService.backupInterval,
        'darkMode': _settingsService.darkMode,
        'accentColor': _settingsService.accentColor,
      };
      
      final file = File(filePath);
      await file.writeAsString(json.encode(exportData));
      
      // 古いファイルを削除
      await _cleanupOldBackups(backupDir);
      
      if (kDebugMode) {
        print('統合エクスポート完了: $filePath');
      }
      
      return filePath;
    } catch (e) {
      ErrorHandler.logError('統合エクスポート', e);
      rethrow;
    }
  }

  /// 統合インポート（自動変換対応）
  Future<ImportResult> importData(
    File file, {
    bool onlyLinks = false,
    bool onlyTasks = false,
  }) async {
    try {
      final content = await file.readAsString();
      final jsonData = json.decode(content);
      
      if (kDebugMode) {
        print('=== JSON読み込みデバッグ ===');
        print('JSON keys: ${jsonData.keys.toList()}');
        print('groups key exists: ${jsonData.containsKey('groups')}');
        print('groups data: ${jsonData['groups']}');
        print('========================');
      }
      
      final version = (jsonData['version'] ?? '1.0').toString();
      final warnings = <String>[];
      
      Map<String, dynamic> v2Data = {};
      
      // バージョン判定を改善：versionフィールドがない場合は直接v2として扱う
      if (version.startsWith('2.') || jsonData.containsKey('groups')) {
        v2Data = Map<String, dynamic>.from(jsonData);
        if (kDebugMode) {
          print('v2データを直接使用: groups=${v2Data['groups']?.length ?? 0}件');
          print('v2Data keys: ${v2Data.keys.toList()}');
          print('groups data: ${v2Data['groups']}');
        }
      } else {
        // v1 → v2 変換
        try {
          final data = jsonData['data'] ?? {};
          v2Data = {
            'version': '2.0',
            'exportedAt': DateTime.now().toUtc().toIso8601String(),
            'links': data['links'] ?? [],
            'tasks': data['tasks'] ?? [],
            'groups': data['groups'] ?? [], // グループ情報を追加
            'groupsOrder': data['groupsOrder'] ?? [], // グループ順序も追加
            'settings': jsonData['prefs'] ?? {},
          };
          
          if (kDebugMode) {
            print('v1→v2変換: groups=${v2Data['groups']?.length ?? 0}件, groupsOrder=${v2Data['groupsOrder']?.length ?? 0}件');
          }
          
          if (data['links'] == null) {
            warnings.add('v1: links が見つかりません。空で取り込みました。');
          }
          if (data['tasks'] == null) {
            warnings.add('v1: tasks が見つかりません。空で取り込みました。');
          }
        } catch (e) {
          warnings.add('v1→v2 変換で例外: $e');
          v2Data = {
            'version': '2.0',
            'links': [],
            'tasks': [],
            'settings': {},
          };
        }
      }
      
      // バリデーションとモデル化
      List<LinkItem> links = [];
      List<Group> groups = [];
      
      if (!onlyTasks) {
        for (final linkJson in (v2Data['links'] as List? ?? [])) {
          try {
            links.add(LinkItem.fromJson(linkJson));
          } catch (e) {
            warnings.add('link 変換失敗: $e');
          }
        }
        
        // グループ情報も収集
        for (final groupJson in (v2Data['groups'] as List? ?? [])) {
          try {
            final group = Group.fromJson(groupJson);
            groups.add(group);
            if (kDebugMode) {
              print('グループ解析: ${group.title} (ID: ${group.id})');
            }
          } catch (e) {
            warnings.add('group 変換失敗: $e');
          }
        }
        
        if (kDebugMode) {
          print('解析されたグループ数: ${groups.length}');
        }
      }
      
      List<TaskItem> tasks = [];
      if (!onlyLinks) {
        for (final taskJson in (v2Data['tasks'] as List? ?? [])) {
          try {
            tasks.add(TaskItem.fromJson(taskJson));
          } catch (e) {
            warnings.add('task 変換失敗: $e');
          }
        }
      }
      
      // データを実際に保存
      if (!onlyTasks && links.isNotEmpty) {
        // 既存のリンクIDを取得
        final existingLinkIds = _linkRepository.getAllLinks().map((link) => link.id).toSet();
        
        // グループ内のリンクIDも収集（重複チェック用）
        final groupLinkIds = <String>{};
        if (v2Data['groups'] != null) {
          final groupsData = v2Data['groups'] as List;
          for (final groupData in groupsData) {
            try {
              final group = Group.fromJson(groupData);
              for (final item in group.items) {
                groupLinkIds.add(item.id);
              }
            } catch (e) {
              // グループ解析エラーは無視
            }
          }
        }
        
        for (final link in links) {
          // 重複チェック：同じIDのリンクが既に存在する場合はスキップ
          if (existingLinkIds.contains(link.id)) {
            warnings.add('リンク「${link.label}」は既に存在するためスキップしました');
            continue;
          }
          
          // グループ内にも同じリンクが含まれている場合はスキップ（グループ保存時に処理される）
          if (groupLinkIds.contains(link.id)) {
            warnings.add('リンク「${link.label}」はグループ内に含まれているためスキップしました');
            if (kDebugMode) {
              print('リンク「${link.label}」はグループ内に含まれているためスキップ');
            }
            continue;
          }
          
          await _linkRepository.saveLink(link);
        }
      }
      
      // グループ情報も復帰（v2データに含まれている場合）
      int savedGroupsCount = 0;
      if (!onlyTasks && v2Data['groups'] != null) {
        final groupsData = v2Data['groups'] as List;
        if (kDebugMode) {
          print('=== グループ解析開始 ===');
          print('v2Data[\'groups\']: ${v2Data['groups']}');
          print('groupsData.length: ${groupsData.length}');
          print('groupsData.isNotEmpty: ${groupsData.isNotEmpty}');
        }
        if (groupsData.isNotEmpty) {
          // 既存のグループIDを取得
          final existingGroupIds = _linkRepository.getAllGroups().map((group) => group.id).toSet();
          
          for (final groupData in groupsData) {
            try {
              if (kDebugMode) {
                print('グループデータを解析中: $groupData');
              }
              final group = Group.fromJson(groupData);
              
              if (kDebugMode) {
                print('解析されたグループ: ${group.title} (ID: ${group.id})');
              }
              
              // 既存のグループが存在する場合は上書き保存（復帰のため）
              if (existingGroupIds.contains(group.id)) {
                warnings.add('グループ「${group.title}」を上書き保存しました');
                if (kDebugMode) {
                  print('既存グループを上書き: ${group.title}');
                }
              }
              
              await _linkRepository.saveGroup(group);
              savedGroupsCount++;
              if (kDebugMode) {
                print('グループ保存完了: ${group.title} (保存済み: $savedGroupsCount)');
              }
            } catch (e) {
              warnings.add('グループ変換失敗: $e');
              if (kDebugMode) {
                print('グループ変換エラー: $e');
                print('問題のグループデータ: $groupData');
              }
            }
          }
          
          // グループ順序も復帰
          if (v2Data['groupsOrder'] != null) {
            final groupsOrder = List<String>.from(v2Data['groupsOrder']);
            await _linkRepository.saveGroupsOrder(groupsOrder);
            if (kDebugMode) {
              print('グループ順序を復元: $groupsOrder');
            }
          }
        }
      }
      
      if (!onlyLinks && tasks.isNotEmpty && _taskViewModel != null) {
        // 既存のタスクIDを取得
        final existingTaskIds = _taskViewModel!.tasks.map((task) => task.id).toSet();
        
        for (final task in tasks) {
          // 重複チェック：同じIDのタスクが既に存在する場合はスキップ
          if (existingTaskIds.contains(task.id)) {
            warnings.add('タスク「${task.title}」は既に存在するためスキップしました');
            continue;
          }
          
          // タイトルベースの重複チェック（過去24時間以内）
          final now = DateTime.now();
          final recentTasks = _taskViewModel!.tasks.where((existingTask) {
            if (existingTask.createdAt == null) return false;
            final timeDiff = now.difference(existingTask.createdAt!);
            return timeDiff.inHours <= 24 && existingTask.title == task.title;
          }).toList();
          
          if (recentTasks.isNotEmpty) {
            warnings.add('タスク「${task.title}」は過去24時間以内に作成されているためスキップしました');
            continue;
          }
          
          await _taskViewModel!.addTask(task);
        }
      }
      
      // 実際に保存されたグループのみを返す
      final savedGroups = groups.take(savedGroupsCount).toList();
      
      if (kDebugMode) {
        print('=== インポート結果サマリー ===');
        print('保存されたリンク数: ${links.length}');
        print('保存されたグループ数: $savedGroupsCount');
        print('保存されたタスク数: ${tasks.length}');
        print('警告数: ${warnings.length}');
        print('========================');
      }
      
      // LinkViewModelの状態を強制更新
      if (_ref != null) {
        try {
          final linkViewModel = _ref!.read(linkViewModelProvider.notifier);
          await linkViewModel.refreshGroups();
          if (kDebugMode) {
            print('=== LinkViewModel状態更新完了 ===');
            final currentState = _ref!.read(linkViewModelProvider);
            print('更新後のグループ数: ${currentState.groups.length}');
            for (final group in currentState.groups) {
              print('グループ: ${group.title} (ID: ${group.id})');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('LinkViewModel状態更新エラー: $e');
          }
        }
      }
      
      return ImportResult(
        links: links,
        tasks: tasks,
        groups: savedGroups,
        warnings: warnings,
      );
    } catch (e) {
      ErrorHandler.logError('統合インポート', e);
      // エラーの詳細を含むImportResultを返す
      return ImportResult(
        links: [],
        tasks: [],
        groups: [],
        warnings: ['インポートエラー: $e'],
      );
    }
  }

  /// エクスポートタイプの説明を取得
  String _getExportDescription(String exportType) {
    switch (exportType) {
      case 'links_only':
        return 'リンクデータのみのエクスポート';
      case 'tasks_only':
        return 'タスクデータのみのエクスポート';
      case 'both':
        return 'リンクとタスクの両方のエクスポート';
      default:
        return '不明なエクスポートタイプ';
    }
  }

  /// バックアップディレクトリを取得
  Future<Directory> getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${documentsDir.path}/$_backupFolderName');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }

  /// 古いバックアップファイルを削除
  Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.contains('linker_backup_'))
          .toList();
      
      if (files.length > _maxBackupFiles) {
        // 作成日時でソート（古い順）
        files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        
        // 古いファイルを削除
        final filesToDelete = files.take(files.length - _maxBackupFiles);
        for (final file in filesToDelete) {
          await file.delete();
          if (kDebugMode) {
            print('古いバックアップファイルを削除: ${file.path}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('バックアップクリーンアップエラー: $e');
      }
    }
  }
}
