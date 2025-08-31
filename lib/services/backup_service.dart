import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../repositories/link_repository.dart';
import '../services/settings_service.dart';
import '../utils/error_handler.dart';

/// 自動バックアップサービス
class BackupService {
  static const String _backupFolderName = 'backups';
  static const int _maxBackupFiles = 10;
  
  final LinkRepository _linkRepository;
  final SettingsService _settingsService;
  
  BackupService({
    required LinkRepository linkRepository,
    required SettingsService settingsService,
  }) : _linkRepository = linkRepository,
       _settingsService = settingsService;

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
    final backupDir = await _getBackupDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'linker_backup_$timestamp.json';
    final backupFile = File('${backupDir.path}/$fileName');
    
    final jsonString = jsonEncode(backupData);
    await backupFile.writeAsString(jsonString);
    
    return backupFile;
  }

  /// バックアップディレクトリを取得または作成
  Future<Directory> _getBackupDirectory() async {
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
      final backupDir = await _getBackupDirectory();
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
      final backupDir = await _getBackupDirectory();
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
      final backupDir = await _getBackupDirectory();
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
          
          totalSize += await file.length();
          
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
      final backupDir = await _getBackupDirectory();
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
