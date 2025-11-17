import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../repositories/link_repository.dart';
import '../services/settings_service.dart';
import '../utils/error_handler.dart';
import '../models/link_item.dart';
import '../models/task_item.dart';
import '../models/group.dart';
import '../models/sub_task.dart';
import '../models/export_config.dart';
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
          print('自動バックアップを実行します（前回から$daysSinceLastBackup日経過）');
        }
        await performBackup(backupType: 'auto');
      } else {
        if (kDebugMode) {
          print('自動バックアップの時期ではありません（前回から$daysSinceLastBackup日経過、間隔: $backupInterval日）');
        }
      }
    } catch (e) {
      ErrorHandler.logError('自動バックアップチェック', e);
    }
  }

  /// バックアップを実行
  /// [backupType] バックアップの種類（'auto', 'manual', 'pre-operation'など）
  Future<File> performBackup({String backupType = 'auto'}) async {
    try {
      if (kDebugMode) {
        print('バックアップを開始します（種類: $backupType）');
      }

      final backupData = await _createBackupData();
      backupData['backupType'] = backupType;
      
      final backupFile = await _saveBackupFile(backupData);
      
      // バックアップファイルの検証
      final isValid = await validateBackupFile(backupFile);
      if (!isValid) {
        throw Exception('バックアップファイルの検証に失敗しました');
      }
      
      await _cleanupOldBackups();
      
      if (backupType != 'pre-operation') {
        // 自動バックアップの場合は最終バックアップ日時を更新
        await _settingsService.setLastBackup(DateTime.now());
      }
      
      if (kDebugMode) {
        print('バックアップが完了しました: ${backupFile.path}');
      }
      
      // バックアップ完了コールバックを呼び出し
      _onBackupCompleted?.call(backupFile.path);
      
      return backupFile;
    } catch (e) {
      ErrorHandler.logError('バックアップ実行', e);
      rethrow;
    }
  }
  
  /// 操作前の自動バックアップ（重要な操作の前に実行）
  /// [operationName] 操作名（例: 'bulk_delete', 'data_import', 'task_merge'）
  /// [itemCount] 操作対象のアイテム数（大量操作の判定に使用）
  /// [abortOnFailure] バックアップ失敗時に操作を中断するか（デフォルト: false）
  Future<bool> performPreOperationBackup({
    required String operationName,
    int itemCount = 0,
    bool abortOnFailure = false,
  }) async {
    try {
      // 大量操作の場合は必ずバックアップ（10件以上）
      final isBulkOperation = itemCount >= 10;
      
      if (!isBulkOperation && !abortOnFailure) {
        // 少量の操作でバックアップが必須でない場合はスキップ
        if (kDebugMode) {
          print('操作前バックアップをスキップします（操作: $operationName, 件数: $itemCount）');
        }
        return true;
      }
      
      if (kDebugMode) {
        print('操作前バックアップを開始します（操作: $operationName, 件数: $itemCount）');
      }
      
      try {
        await performBackup(backupType: 'pre-operation');
        if (kDebugMode) {
          print('操作前バックアップが完了しました');
        }
        return true;
      } catch (e) {
        ErrorHandler.logError('操作前バックアップ', e);
        
        if (abortOnFailure || isBulkOperation) {
          // バックアップ失敗時は警告を発行
          if (kDebugMode) {
            print('操作前バックアップが失敗しました。操作を中断するか確認が必要です。');
          }
          throw Exception('操作前のバックアップに失敗しました: $e');
        }
        
        // バックアップ失敗でも続行（警告のみ）
        if (kDebugMode) {
          print('操作前バックアップが失敗しましたが、操作を続行します');
        }
        return false;
      }
    } catch (e) {
      ErrorHandler.logError('操作前バックアップ処理', e);
      if (abortOnFailure) {
        rethrow;
      }
      return false;
    }
  }

  /// バックアップデータを作成
  Future<Map<String, dynamic>> _createBackupData() async {
    final linkData = _linkRepository.exportData();
    final settingsData = _settingsService.exportSettings();
    
    final backupData = {
      'version': '1.0',
      'createdAt': DateTime.now().toIso8601String(),
      'linkData': linkData,
      'settingsData': settingsData,
      'backupType': 'auto',
    };
    
    // タスクデータも含める（TaskViewModelが利用可能な場合、またはHiveから直接読み込む）
    try {
      List<TaskItem> tasks = [];
      
      if (_taskViewModel != null) {
        // TaskViewModelから取得（推奨）
        tasks = _taskViewModel.tasks;
      } else {
        // TaskViewModelが利用できない場合はHiveから直接読み込む
        try {
          final taskBox = await Hive.openBox<TaskItem>('tasks');
          tasks = taskBox.values.toList();
          if (kDebugMode) {
            print('Hiveからタスクデータを読み込みました: ${tasks.length}件');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Hiveからのタスクデータ読み込みエラー（無視）: $e');
          }
        }
      }
      
      if (tasks.isNotEmpty) {
        backupData['tasks'] = tasks.map((task) => task.toJson()).toList();
        
        // サブタスクデータも含める
        try {
          final subTaskBox = await Hive.openBox<SubTask>('sub_tasks');
          final allSubTasks = subTaskBox.values.toList();
          backupData['subTasks'] = allSubTasks.map((subtask) => subtask.toJson()).toList();
          
          if (kDebugMode) {
            print('バックアップにタスクデータを含めました: ${tasks.length}件のタスク、${allSubTasks.length}件のサブタスク');
          }
        } catch (e) {
          if (kDebugMode) {
            print('サブタスクデータの取得エラー（無視）: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスクデータの取得エラー（無視）: $e');
      }
    }
    
    return backupData;
  }

  /// バックアップファイルを保存（複数場所に対応）
  Future<File> _saveBackupFile(Map<String, dynamic> backupData) async {
    final backupDir = await getBackupDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'linker_backup_$timestamp.json';
    final backupFile = File('${backupDir.path}/$fileName');
    
    final jsonString = jsonEncode(backupData);
    await backupFile.writeAsString(jsonString);
    
    // 追加のバックアップ保存先にコピー（設定されている場合）
    final additionalBackupPath = _settingsService.additionalBackupPath;
    if (additionalBackupPath != null && additionalBackupPath.isNotEmpty) {
      try {
        final additionalDir = Directory(additionalBackupPath);
        if (!await additionalDir.exists()) {
          await additionalDir.create(recursive: true);
        }
        
        final additionalBackupFile = File('${additionalDir.path}/$fileName');
        await additionalBackupFile.writeAsString(jsonString);
        
        if (kDebugMode) {
          print('追加のバックアップ保存先にもコピーしました: ${additionalBackupFile.path}');
        }
      } catch (e) {
        // 追加保存先へのコピーエラーは警告のみ（メインのバックアップは成功している）
        if (kDebugMode) {
          print('追加のバックアップ保存先へのコピーエラー（無視）: $e');
        }
      }
    }
    
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
      final backupDataRaw = jsonDecode(jsonString);
      if (backupDataRaw is! Map) {
        throw Exception('バックアップデータの形式が正しくありません');
      }
      final backupData = Map<String, dynamic>.from(backupDataRaw);
      
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

  /// バックアップファイルの整合性を検証
  Future<bool> validateBackupFile(File backupFile) async {
    try {
      if (!await backupFile.exists()) {
        if (kDebugMode) {
          print('バックアップファイルが存在しません: ${backupFile.path}');
        }
        return false;
      }
      
      // ファイルサイズチェック（空ファイルでないか）
      final fileSize = await backupFile.length();
      if (fileSize == 0) {
        if (kDebugMode) {
          print('バックアップファイルが空です: ${backupFile.path}');
        }
        return false;
      }
      
      // JSON形式の検証
      final jsonString = await backupFile.readAsString();
      try {
        final backupDataRaw = jsonDecode(jsonString);
        if (backupDataRaw is! Map) {
          if (kDebugMode) {
            print('バックアップファイルの形式が不正です: ${backupFile.path}');
          }
          return false;
        }
        
        final backupData = Map<String, dynamic>.from(backupDataRaw);
        
        // 基本的な検証
        if (!_validateBackupData(backupData)) {
          if (kDebugMode) {
            print('バックアップデータの検証に失敗しました: ${backupFile.path}');
          }
          return false;
        }
        
        if (kDebugMode) {
          print('バックアップファイルの検証に成功しました: ${backupFile.path}');
        }
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('バックアップファイルのJSON解析エラー: $e');
        }
        return false;
      }
    } catch (e) {
      ErrorHandler.logError('バックアップファイル検証', e);
      return false;
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
          final backupDataRaw = jsonDecode(jsonString);
          if (backupDataRaw is! Map) {
            continue; // 無効なファイルはスキップ
          }
          final backupData = Map<String, dynamic>.from(backupDataRaw);
          
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
          final backupDataRaw = jsonDecode(jsonString);
          if (backupDataRaw is! Map) {
            continue; // 無効なファイルはスキップ
          }
          final backupData = Map<String, dynamic>.from(backupDataRaw);
          
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

  /// 選択式エクスポート（v2形式）
  Future<String> exportDataWithConfig(ExportConfig config) async {
    try {
      final backupDir = await getBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final templateSuffix = config.templateName != null ? '_${config.templateName}' : '';
      final fileName = 'linker_export${templateSuffix}_$timestamp.json';
      final filePath = '${backupDir.path}/$fileName';
      
      final exportData = <String, dynamic>{
        'version': '2.0',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'exportType': 'selective',
        'exportConfig': config.toJson(),
        'description': '選択式エクスポート',
      };
      
      // リンクデータ（選択されたグループとリンクのみ）
      final allLinks = _linkRepository.getAllLinks();
      final allGroups = _linkRepository.getAllGroups();
      
      // 選択されたグループをフィルター
      List<Group> selectedGroups = [];
      if (config.selectedGroupIds.isEmpty) {
        // 全グループを選択
        selectedGroups = allGroups;
      } else {
        selectedGroups = allGroups
            .where((group) => config.selectedGroupIds.contains(group.id))
            .toList();
      }
      
      // グループ内のリンクIDを収集
      final groupLinkIds = <String>{};
      for (final group in selectedGroups) {
        for (final item in group.items) {
          groupLinkIds.add(item.id);
        }
      }
      
      // 選択されたリンクをフィルター
      List<LinkItem> selectedLinks = [];
      if (config.selectedLinkIds.isEmpty) {
        // 全リンクを選択（グループ外のリンク）
        selectedLinks = allLinks
            .where((link) => !groupLinkIds.contains(link.id))
            .toList();
      } else {
        // 指定されたリンクのみ
        selectedLinks = allLinks
            .where((link) => config.selectedLinkIds.contains(link.id))
            .toList();
      }
      
      // メモを含める/含めないの処理
      if (!config.includeMemos) {
        selectedLinks = selectedLinks.map((link) {
          return LinkItem(
            id: link.id,
            label: link.label,
            path: link.path,
            type: link.type,
            createdAt: link.createdAt,
            lastUsed: link.lastUsed,
            isFavorite: link.isFavorite,
            memo: null,
            iconData: link.iconData,
            iconColor: link.iconColor,
            tags: link.tags,
            hasActiveTasks: link.hasActiveTasks,
            faviconFallbackDomain: link.faviconFallbackDomain,
          );
        }).toList();
        
        selectedGroups = selectedGroups.map((group) {
          final itemsWithoutMemos = group.items.map((item) {
            return LinkItem(
              id: item.id,
              label: item.label,
              path: item.path,
              type: item.type,
              createdAt: item.createdAt,
              lastUsed: item.lastUsed,
              isFavorite: item.isFavorite,
              memo: null,
              iconData: item.iconData,
              iconColor: item.iconColor,
              tags: item.tags,
              hasActiveTasks: item.hasActiveTasks,
              faviconFallbackDomain: item.faviconFallbackDomain,
            );
          }).toList();
          return group.copyWith(items: itemsWithoutMemos);
        }).toList();
      }
      
      exportData['links'] = selectedLinks.map((link) => link.toJson()).toList();
      exportData['groups'] = selectedGroups.map((group) => group.toJson()).toList();
      
      // グループ順序（選択されたグループのみ）
      final allGroupsOrder = _linkRepository.getGroupsOrder();
      final selectedGroupsOrder = allGroupsOrder
          .where((id) => config.selectedGroupIds.isEmpty || config.selectedGroupIds.contains(id))
          .toList();
      exportData['groupsOrder'] = selectedGroupsOrder;
      
      // タスクデータ（フィルター適用）
      if (_taskViewModel != null) {
        List<TaskItem> filteredTasks = _taskViewModel.tasks;
        
        // タスクIDでフィルター
        if (config.selectedTaskIds.isNotEmpty) {
          filteredTasks = filteredTasks
              .where((task) => config.selectedTaskIds.contains(task.id))
              .toList();
        }
        
        // タスクフィルターを適用
        if (config.taskFilter != null) {
          filteredTasks = _applyTaskFilter(filteredTasks, config.taskFilter!);
        }
        
        exportData['tasks'] = filteredTasks.map((task) => task.toJson()).toList();
        
        // サブタスクデータ（選択されたタスクのもののみ）
        final subTaskBox = Hive.box<SubTask>('sub_tasks');
        final selectedTaskIds = filteredTasks.map((t) => t.id).toSet();
        final selectedSubTasks = subTaskBox.values
            .where((subtask) => selectedTaskIds.contains(subtask.parentTaskId))
            .toList();
        exportData['subTasks'] = selectedSubTasks.map((subtask) => subtask.toJson()).toList();
      }
      
      // 設定データ（選択された項目のみ）
      if (config.settingsConfig != null) {
        final settingsData = <String, dynamic>{};
        final allSettings = _settingsService.exportSettings();
        
        if (config.settingsConfig!.includeUISettings) {
          settingsData['darkMode'] = allSettings['darkMode'];
          settingsData['accentColor'] = allSettings['accentColor'];
          settingsData['fontSize'] = allSettings['fontSize'];
          settingsData['textColor'] = allSettings['textColor'];
          settingsData['colorIntensity'] = allSettings['colorIntensity'];
          settingsData['colorContrast'] = allSettings['colorContrast'];
          settingsData['uiSettings'] = allSettings['uiSettings'];
        }
        
        if (config.settingsConfig!.includeFeatureSettings) {
          settingsData['autoBackup'] = allSettings['autoBackup'];
          settingsData['backupInterval'] = allSettings['backupInterval'];
          settingsData['showNotifications'] = allSettings['showNotifications'];
          settingsData['notificationSound'] = allSettings['notificationSound'];
        }
        
        if (config.settingsConfig!.includeIntegrationSettings) {
          settingsData['googleCalendarEnabled'] = allSettings['googleCalendarEnabled'];
          settingsData['googleCalendarSyncInterval'] = allSettings['googleCalendarSyncInterval'];
          settingsData['googleCalendarAutoSync'] = allSettings['googleCalendarAutoSync'];
          settingsData['gmailApiEnabled'] = allSettings['gmailApiEnabled'];
          settingsData['outlookAutoSyncEnabled'] = allSettings['outlookAutoSyncEnabled'];
          settingsData['outlookAutoSyncPeriodDays'] = allSettings['outlookAutoSyncPeriodDays'];
          settingsData['outlookAutoSyncFrequency'] = allSettings['outlookAutoSyncFrequency'];
        }
        
        if (settingsData.isNotEmpty) {
          exportData['settings'] = settingsData;
        }
      }
      
      final file = File(filePath);
      await file.writeAsString(json.encode(exportData));
      
      if (kDebugMode) {
        print('選択式エクスポート完了: $filePath');
        print('グループ: ${selectedGroups.length}件');
        print('リンク: ${selectedLinks.length}件');
        print('タスク: ${exportData['tasks']?.length ?? 0}件');
      }
      
      return filePath;
    } catch (e) {
      ErrorHandler.logError('選択式エクスポート', e);
      rethrow;
    }
  }

  /// タスクフィルターを適用
  List<TaskItem> _applyTaskFilter(List<TaskItem> tasks, TaskFilterConfig filter) {
    return tasks.where((task) {
      // タグフィルター
      if (filter.tags.isNotEmpty) {
        final taskTags = task.tags.toSet();
        if (!filter.tags.any((tag) => taskTags.contains(tag))) {
          return false;
        }
      }
      
      // ステータスフィルター
      if (filter.statuses.isNotEmpty) {
        final statusStr = task.status.toString().split('.').last;
        if (!filter.statuses.contains(statusStr)) {
          return false;
        }
      }
      
      // 作成日フィルター
      if (filter.createdAtStart != null) {
        if (task.createdAt.isBefore(filter.createdAtStart!)) {
          return false;
        }
      }
      if (filter.createdAtEnd != null) {
        if (task.createdAt.isAfter(filter.createdAtEnd!)) {
          return false;
        }
      }
      
      // 期限日フィルター
      if (task.dueDate != null) {
        if (filter.dueDateStart != null && task.dueDate!.isBefore(filter.dueDateStart!)) {
          return false;
        }
        if (filter.dueDateEnd != null && task.dueDate!.isAfter(filter.dueDateEnd!)) {
          return false;
        }
      } else {
        // 期限日が設定されていないタスクを除外する場合
        if (filter.dueDateStart != null || filter.dueDateEnd != null) {
          return false;
        }
      }
      
      // 関連リンクIDフィルター
      if (filter.relatedLinkIds.isNotEmpty) {
        if (!task.relatedLinkIds.any((linkId) => filter.relatedLinkIds.contains(linkId))) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

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
        
        // グループデータも含める（グループ内のリンクも含む）
        exportData['groups'] = groups.map((group) => group.toJson()).toList();
        
        // グループ順序も含める
        final groupsOrder = _linkRepository.getGroupsOrder();
        exportData['groupsOrder'] = groupsOrder;
        
        if (kDebugMode) {
          print('=== エクスポートデータ ===');
          print('全リンク数: ${links.length}');
          print('グループ内リンク数: ${groupLinkIds.length}');
          print('グループ外リンク数: ${standaloneLinks.length}');
          print('グループ数: ${groups.length}');
          print('グループ順序: $groupsOrder');
          if (standaloneLinks.isNotEmpty) {
            print('🔗 エクスポートされるグループ外リンク:');
            for (final link in standaloneLinks) {
              print('  - リンクID: ${link.id}, ラベル: ${link.label}');
            }
          }
          print('====================');
        }
      }
      
      // タスクデータ
      if (!onlyLinks && _taskViewModel != null) {
        final tasks = _taskViewModel.tasks;
        exportData['tasks'] = tasks.map((task) => task.toJson()).toList();
        
        // サブタスクデータもエクスポート
        final subTaskBox = Hive.box<SubTask>('sub_tasks');
        final allSubTasks = subTaskBox.values.toList();
        exportData['subTasks'] = allSubTasks.map((subtask) => subtask.toJson()).toList();
        
        if (kDebugMode) {
          print('=== サブタスクエクスポート ===');
          print('エクスポートされたサブタスク数: ${allSubTasks.length}');
          for (final subtask in allSubTasks) {
            print('サブタスク: ${subtask.title} (親タスク: ${subtask.parentTaskId}, 完了: ${subtask.isCompleted})');
          }
          print('========================');
        }
      }
      
      // 設定データ（UI設定を含む）
      exportData['settings'] = {
        'autoBackup': _settingsService.autoBackup,
        'backupInterval': _settingsService.backupInterval,
        'darkMode': _settingsService.darkMode,
        'accentColor': _settingsService.accentColor,
        // UI設定を追加
        'uiSettings': _settingsService.exportUISettings(),
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
  /// 部分インポート（設定付き）
  Future<ImportResult> importDataWithConfig(
    File file,
    ImportConfig config,
  ) async {
    try {
      final content = await file.readAsString();
      final jsonData = json.decode(content);
      
      final version = (jsonData['version'] ?? '1.0').toString();
      final warnings = <String>[];
      
      Map<String, dynamic> v2Data = {};
      
      // バージョン判定
      if (version.startsWith('2.') || jsonData.containsKey('groups')) {
        v2Data = Map<String, dynamic>.from(jsonData);
      } else {
        // v1 → v2 変換
        Map<String, dynamic> data = {};
        if (jsonData.containsKey('linkData')) {
          data = jsonData['linkData'] as Map<String, dynamic>? ?? {};
        } else if (jsonData.containsKey('data')) {
          data = jsonData['data'] as Map<String, dynamic>? ?? {};
        } else {
          data = jsonData;
        }
        
        v2Data = {
          'version': '2.0',
          'exportedAt': jsonData['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
          'links': data['links'] ?? [],
          'tasks': jsonData['tasks'] ?? data['tasks'] ?? [],
          'subTasks': jsonData['subTasks'] ?? [],
          'groups': data['groups'] ?? [],
          'groupsOrder': data['groupsOrder'] ?? [],
          'settings': jsonData['prefs'] ?? jsonData['settingsData'] ?? {},
        };
      }
      
      // バリデーションとモデル化
      List<LinkItem> links = [];
      List<Group> groups = [];
      List<TaskItem> tasks = [];
      
      if (config.importLinks && !config.importTasks) {
        for (final linkJson in (v2Data['links'] as List? ?? [])) {
          try {
            links.add(LinkItem.fromJson(linkJson));
          } catch (e) {
            warnings.add('link 変換失敗: $e');
          }
        }
        
        if (config.importGroups) {
          for (final groupJson in (v2Data['groups'] as List? ?? [])) {
            try {
              groups.add(Group.fromJson(groupJson));
            } catch (e) {
              warnings.add('group 変換失敗: $e');
            }
          }
        }
      }
      
      if (config.importTasks && !config.importLinks) {
        for (final taskJson in (v2Data['tasks'] as List? ?? [])) {
          try {
            tasks.add(TaskItem.fromJson(taskJson));
          } catch (e) {
            warnings.add('task 変換失敗: $e');
          }
        }
      }
      
      if (config.importLinks && config.importTasks) {
        for (final linkJson in (v2Data['links'] as List? ?? [])) {
          try {
            links.add(LinkItem.fromJson(linkJson));
          } catch (e) {
            warnings.add('link 変換失敗: $e');
          }
        }
        
        if (config.importGroups) {
          for (final groupJson in (v2Data['groups'] as List? ?? [])) {
            try {
              groups.add(Group.fromJson(groupJson));
            } catch (e) {
              warnings.add('group 変換失敗: $e');
            }
          }
        }
        
        for (final taskJson in (v2Data['tasks'] as List? ?? [])) {
          try {
            tasks.add(TaskItem.fromJson(taskJson));
          } catch (e) {
            warnings.add('task 変換失敗: $e');
          }
        }
      }
      
      // インポート処理
      if (config.importMode == ImportMode.overwrite) {
        // 上書きモード：既存データを削除してからインポート
        if (config.importLinks) {
          final allLinks = _linkRepository.getAllLinks();
          for (final link in allLinks) {
            _linkRepository.deleteLink(link.id);
          }
        }
        if (config.importTasks && _taskViewModel != null) {
          final allTasks = _taskViewModel.tasks;
          for (final task in allTasks) {
            _taskViewModel.deleteTask(task.id);
          }
        }
      }
      
      // リンクのインポート（グループ外のリンク）
      if (config.importLinks && links.isNotEmpty) {
        if (kDebugMode) {
          print('🔗 グループ外リンクのインポート開始: ${links.length}件');
          for (final link in links) {
            print('  - リンクID: ${link.id}, ラベル: ${link.label}');
          }
        }
        await _importLinksWithConfig(links, config, warnings);
        if (kDebugMode) {
          print('🔗 グループ外リンクのインポート完了');
        }
      } else if (links.isNotEmpty) {
        if (kDebugMode) {
          print('⚠️ 警告: グループ外リンクが${links.length}件ありますが、インポート設定で「リンク」が無効のためスキップされます');
          for (final link in links) {
            print('  - スキップされたリンクID: ${link.id}, ラベル: ${link.label}');
          }
        }
        warnings.add('グループ外リンク${links.length}件がスキップされました（インポート設定で「リンク」が無効）');
      }
      
      // グループのインポート（グループ内のリンクも含む）
      if (config.importGroups && groups.isNotEmpty) {
        if (kDebugMode) {
          print('📁 グループのインポート開始: ${groups.length}件');
          int totalGroupLinks = 0;
          for (final group in groups) {
            print('  - グループ: ${group.title}, リンク数: ${group.items.length}');
            totalGroupLinks += group.items.length;
          }
          print('📁 グループ内リンク合計: $totalGroupLinks件');
        }
        await _importGroupsWithConfig(groups, config, warnings);
        if (kDebugMode) {
          print('📁 グループのインポート完了');
        }
      }
      
      // タスクのインポート
      if (config.importTasks && tasks.isNotEmpty) {
        await _importTasksWithConfig(tasks, v2Data['subTasks'], config, warnings);
      }
      
      // 設定のインポート
      if (config.importSettings && v2Data['settings'] != null) {
        await _importSettings(v2Data['settings'], warnings);
      }
      
      return ImportResult(
        links: links,
        tasks: tasks,
        groups: groups,
        warnings: warnings,
      );
    } catch (e) {
      ErrorHandler.logError('部分インポート', e);
      rethrow;
    }
  }

  /// リンクをインポート（設定付き）
  Future<void> _importLinksWithConfig(
    List<LinkItem> links,
    ImportConfig config,
    List<String> warnings,
  ) async {
    final existingLinkIds = _linkRepository.getAllLinks().map((link) => link.id).toSet();
    
    for (final link in links) {
      if (existingLinkIds.contains(link.id)) {
        // 重複処理
        switch (config.duplicateHandling) {
          case DuplicateHandling.skip:
            warnings.add('リンク「${link.label}」は既に存在するためスキップしました');
            continue;
          case DuplicateHandling.overwrite:
            _linkRepository.deleteLink(link.id);
            await _linkRepository.saveLink(link);
            break;
          case DuplicateHandling.rename:
            int counter = 1;
            String newLabel = '${link.label}_${counter}';
            while (existingLinkIds.contains(link.id) || 
                   _linkRepository.getAllLinks().any((l) => l.label == newLabel)) {
              counter++;
              newLabel = '${link.label}_$counter';
            }
            final renamedLink = LinkItem(
              id: link.id,
              label: newLabel,
              path: link.path,
              type: link.type,
              createdAt: link.createdAt,
              lastUsed: link.lastUsed,
              isFavorite: link.isFavorite,
              memo: link.memo,
              iconData: link.iconData,
              iconColor: link.iconColor,
              tags: link.tags,
              hasActiveTasks: link.hasActiveTasks,
              faviconFallbackDomain: link.faviconFallbackDomain,
            );
            await _linkRepository.saveLink(renamedLink);
            break;
        }
      } else {
        await _linkRepository.saveLink(link);
      }
    }
  }

  /// グループをインポート（設定付き）
  Future<void> _importGroupsWithConfig(
    List<Group> groups,
    ImportConfig config,
    List<String> warnings,
  ) async {
    final existingGroupIds = _linkRepository.getAllGroups().map((g) => g.id).toSet();
    
    for (final group in groups) {
      if (existingGroupIds.contains(group.id)) {
        switch (config.duplicateHandling) {
          case DuplicateHandling.skip:
            warnings.add('グループ「${group.title}」は既に存在するためスキップしました');
            continue;
          case DuplicateHandling.overwrite:
            _linkRepository.deleteGroup(group.id);
            await _linkRepository.saveGroup(group);
            break;
          case DuplicateHandling.rename:
            int counter = 1;
            String newTitle = '${group.title}_$counter';
            while (existingGroupIds.contains(group.id) ||
                   _linkRepository.getAllGroups().any((g) => g.title == newTitle)) {
              counter++;
              newTitle = '${group.title}_$counter';
            }
            final renamedGroup = group.copyWith(title: newTitle);
            await _linkRepository.saveGroup(renamedGroup);
            break;
        }
      } else {
        await _linkRepository.saveGroup(group);
      }
    }
  }

  /// タスクをインポート（設定付き）
  Future<void> _importTasksWithConfig(
    List<TaskItem> tasks,
    dynamic subTasksData,
    ImportConfig config,
    List<String> warnings,
  ) async {
    if (_taskViewModel == null) return;
    
    final existingTaskIds = _taskViewModel.tasks.map((t) => t.id).toSet();
    
    for (final task in tasks) {
      if (existingTaskIds.contains(task.id)) {
        switch (config.duplicateHandling) {
          case DuplicateHandling.skip:
            warnings.add('タスク「${task.title}」は既に存在するためスキップしました');
            continue;
          case DuplicateHandling.overwrite:
            _taskViewModel.deleteTask(task.id);
            _taskViewModel.addTask(task);
            break;
          case DuplicateHandling.rename:
            int counter = 1;
            String newTitle = '${task.title}_$counter';
            while (existingTaskIds.contains(task.id) ||
                   _taskViewModel.tasks.any((t) => t.title == newTitle)) {
              counter++;
              newTitle = '${task.title}_$counter';
            }
            final renamedTask = TaskItem(
              id: task.id,
              title: newTitle,
              description: task.description,
              status: task.status,
              priority: task.priority,
              createdAt: task.createdAt,
              dueDate: task.dueDate,
              reminderTime: task.reminderTime,
              relatedLinkIds: task.relatedLinkIds,
              tags: task.tags,
              notes: task.notes,
              assignedTo: task.assignedTo,
            );
            _taskViewModel.addTask(renamedTask);
            break;
        }
      } else {
        _taskViewModel.addTask(task);
      }
    }
    
    // サブタスクのインポート
    if (subTasksData != null && subTasksData is List) {
      final subTaskBox = await Hive.openBox<SubTask>('sub_tasks');
      final importedTaskIds = tasks.map((t) => t.id).toSet();
      
      for (final subtaskJson in subTasksData) {
        try {
          final subtask = SubTask.fromJson(subtaskJson);
          if (importedTaskIds.contains(subtask.parentTaskId)) {
            await subTaskBox.put(subtask.id, subtask);
          }
        } catch (e) {
          warnings.add('サブタスク変換失敗: $e');
        }
      }
    }
  }

  /// 設定をインポート
  Future<void> _importSettings(
    Map<String, dynamic> settings,
    List<String> warnings,
  ) async {
    try {
      await _settingsService.importSettings(settings);
    } catch (e) {
      warnings.add('設定インポートエラー: $e');
    }
  }

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
          // バックアップファイル形式（linkDataキー）と旧形式（dataキー）の両方に対応
          Map<String, dynamic> data = {};
          
          if (jsonData.containsKey('linkData')) {
            // 新しいバックアップ形式（linkDataキー）
            data = jsonData['linkData'] as Map<String, dynamic>? ?? {};
            if (kDebugMode) {
              print('バックアップ形式（linkData）を検出');
            }
          } else if (jsonData.containsKey('data')) {
            // 旧形式（dataキー）
            data = jsonData['data'] as Map<String, dynamic>? ?? {};
            if (kDebugMode) {
              print('旧形式（data）を検出');
            }
          } else {
            // 直接links/tasks/groupsがルートにある場合
            data = jsonData;
            if (kDebugMode) {
              print('ルートレベル形式を検出');
            }
          }
          
          v2Data = {
            'version': '2.0',
            'exportedAt': jsonData['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
            'links': data['links'] ?? [],
            'tasks': jsonData['tasks'] ?? data['tasks'] ?? [], // タスクはルートレベルまたはlinkData内にある可能性
            'subTasks': jsonData['subTasks'] ?? [], // サブタスクも含める
            'groups': data['groups'] ?? [],
            'groupsOrder': data['groupsOrder'] ?? [],
            'settings': jsonData['prefs'] ?? jsonData['settingsData'] ?? {},
          };
          
          if (kDebugMode) {
            print('v1→v2変換: groups=${v2Data['groups']?.length ?? 0}件, groupsOrder=${v2Data['groupsOrder']?.length ?? 0}件');
            print('links: ${(v2Data['links'] as List?)?.length ?? 0}件');
            print('tasks: ${(v2Data['tasks'] as List?)?.length ?? 0}件');
          }
          
          // 警告は、データが存在しない場合のみ表示（空のリストは正常）
          if (!jsonData.containsKey('linkData') && !jsonData.containsKey('data') && !jsonData.containsKey('links')) {
            if ((v2Data['links'] as List?)?.isEmpty ?? true) {
              warnings.add('v1: links が見つかりません。空で取り込みました。');
            }
          }
          if (!jsonData.containsKey('tasks') && !data.containsKey('tasks')) {
            if ((v2Data['tasks'] as List?)?.isEmpty ?? true) {
              warnings.add('v1: tasks が見つかりません。空で取り込みました。');
            }
          }
        } catch (e) {
          warnings.add('v1→v2 変換で例外: $e');
          v2Data = {
            'version': '2.0',
            'links': [],
            'tasks': [],
            'groups': [],
            'groupsOrder': [],
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
        final existingTaskIds = _taskViewModel.tasks.map((task) => task.id).toSet();
        
        // 利用可能なリンクIDを取得（関連リンクIDの整合性チェック用）
        final availableLinkIds = _linkRepository.getAllLinks().map((link) => link.id).toSet();
        
        for (final task in tasks) {
          // 重複チェック：同じIDのタスクが既に存在する場合はスキップ
          if (existingTaskIds.contains(task.id)) {
            warnings.add('タスク「${task.title}」は既に存在するためスキップしました');
            continue;
          }
          
          // タイトルベースの重複チェック（過去24時間以内）
          final now = DateTime.now();
          final recentTasks = _taskViewModel.tasks.where((existingTask) {
            final timeDiff = now.difference(existingTask.createdAt);
            return timeDiff.inHours <= 24 && existingTask.title == task.title;
          }).toList();
          
          if (recentTasks.isNotEmpty) {
            warnings.add('タスク「${task.title}」は過去24時間以内に作成されているためスキップしました');
            continue;
          }
          
          // 関連リンクIDの整合性チェック
          final validRelatedLinkIds = task.relatedLinkIds.where((linkId) => availableLinkIds.contains(linkId)).toList();
          if (validRelatedLinkIds.length != task.relatedLinkIds.length) {
            final invalidCount = task.relatedLinkIds.length - validRelatedLinkIds.length;
            warnings.add('タスク「${task.title}」の関連リンク$invalidCount件が見つからないため除外しました');
          }
          
          // 有効な関連リンクIDのみでタスクを作成
          final cleanedTask = task.copyWith(relatedLinkIds: validRelatedLinkIds);
          await _taskViewModel.addTask(cleanedTask);
          
          // サブタスクの復元処理を追加（実際のデータから復元）
          await _restoreSubTasksFromBackup(task.id, task, v2Data['subTasks']);
        }
      }
      
      // 実際に保存されたグループのみを返す
      final savedGroups = groups.take(savedGroupsCount).toList();
      
      // 設定データの復元（UI設定を含む）
      if (v2Data['settings'] != null) {
        try {
          final settingsDataRaw = v2Data['settings'];
          if (settingsDataRaw is! Map) {
            warnings.add('設定データの形式が正しくありません');
            if (kDebugMode) {
              print('設定データの形式エラー: ${settingsDataRaw.runtimeType}');
            }
            return ImportResult(links: links, tasks: tasks, groups: savedGroups, warnings: warnings);
          }
          final settingsData = Map<String, dynamic>.from(settingsDataRaw);
          
          // 基本設定の復元
          if (settingsData.containsKey('autoBackup')) {
            await _settingsService.setAutoBackup(settingsData['autoBackup']);
          }
          if (settingsData.containsKey('backupInterval')) {
            await _settingsService.setBackupInterval(settingsData['backupInterval']);
          }
          if (settingsData.containsKey('darkMode')) {
            await _settingsService.setDarkMode(settingsData['darkMode']);
          }
          if (settingsData.containsKey('accentColor')) {
            await _settingsService.setAccentColor(settingsData['accentColor']);
          }
          
          // UI設定の復元
          if (settingsData.containsKey('uiSettings')) {
            final uiSettingsData = settingsData['uiSettings'];
            if (uiSettingsData is Map) {
              // Map<dynamic, dynamic> を Map<String, dynamic> に安全に変換
              final uiSettings = Map<String, dynamic>.from(uiSettingsData);
              await _settingsService.importUISettings(uiSettings);
              if (kDebugMode) {
                print('UI設定を復元しました');
              }
            } else {
              warnings.add('UI設定の形式が正しくありません');
              if (kDebugMode) {
                print('UI設定の形式エラー: ${uiSettingsData.runtimeType}');
              }
            }
          }
          
          if (kDebugMode) {
            print('設定データを復元しました');
          }
        } catch (e) {
          warnings.add('設定データの復元でエラーが発生しました: $e');
          if (kDebugMode) {
            print('設定復元エラー: $e');
          }
        }
      }
      
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
          final linkViewModel = _ref.read(linkViewModelProvider.notifier);
          await linkViewModel.refreshGroups();
          if (kDebugMode) {
            print('=== LinkViewModel状態更新完了 ===');
            final currentState = _ref.read(linkViewModelProvider);
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
      
      print('=== IntegratedBackupService インポート完了 ===');
      print('リンク数: ${links.length}');
      print('タスク数: ${tasks.length}');
      print('グループ数: ${savedGroups.length}');
      print('警告数: ${warnings.length}');
      print('==========================================');
      
      return ImportResult(
        links: links,
        tasks: tasks,
        groups: savedGroups,
        warnings: warnings,
      );
    } catch (e) {
      print('=== IntegratedBackupService インポートエラー ===');
      print('エラー: $e');
      print('==========================================');
      
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

  /// バックアップからサブタスクを復元
  Future<void> _restoreSubTasksFromBackup(String taskId, TaskItem task, List<dynamic>? exportedSubTasks) async {
    try {
      final subTaskBox = Hive.box<SubTask>('sub_tasks');
      
      if (exportedSubTasks != null && exportedSubTasks.isNotEmpty) {
        // 実際のサブタスクデータから復元
        final taskSubTasks = exportedSubTasks
            .where((subtaskData) => subtaskData['parentTaskId'] == taskId)
            .toList();
        
        for (final subtaskData in taskSubTasks) {
          final subtask = SubTask(
            id: subtaskData['id'] ?? '${taskId}_${DateTime.now().millisecondsSinceEpoch}',
            parentTaskId: taskId,
            title: subtaskData['title'] ?? 'サブタスク',
            description: subtaskData['description'],
            isCompleted: subtaskData['isCompleted'] ?? false,
            order: subtaskData['order'] ?? 0,
            createdAt: subtaskData['createdAt'] != null 
                ? DateTime.parse(subtaskData['createdAt']) 
                : DateTime.now(),
            completedAt: subtaskData['completedAt'] != null 
                ? DateTime.parse(subtaskData['completedAt']) 
                : null,
          );
          subTaskBox.put(subtask.id, subtask);
        }
        
        subTaskBox.flush();
        if (kDebugMode) {
          print('サブタスク復元完了（実際のデータ）: タスク「${task.title}」- ${taskSubTasks.length}件');
        }
      } else if (task.hasSubTasks && task.totalSubTasksCount > 0) {
        // フォールバック: タスクのメタデータから復元（後方互換性）
        for (int i = 0; i < task.completedSubTasksCount; i++) {
          final subtask = SubTask(
            id: '${taskId}_completed_$i',
            parentTaskId: taskId,
            title: '完了済みサブタスク ${i + 1}',
            isCompleted: true,
            order: i,
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          );
          subTaskBox.put(subtask.id, subtask);
        }
        
        for (int i = task.completedSubTasksCount; i < task.totalSubTasksCount; i++) {
          final subtask = SubTask(
            id: '${taskId}_pending_$i',
            parentTaskId: taskId,
            title: '未完了サブタスク ${i + 1}',
            isCompleted: false,
            order: i,
            createdAt: DateTime.now(),
          );
          subTaskBox.put(subtask.id, subtask);
        }
        
        subTaskBox.flush();
        if (kDebugMode) {
          print('サブタスク復元完了（メタデータ）: タスク「${task.title}」- 完了:${task.completedSubTasksCount}, 総数:${task.totalSubTasksCount}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('サブタスク復元エラー: $e');
      }
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
