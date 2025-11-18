import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import '../models/link_item.dart';
import '../models/group.dart';
import '../repositories/link_repository.dart';
import 'package:collection/collection.dart';
import '../utils/windows_icon_extractor.dart';
import 'dart:ffi' as ffi;
import 'package:win32/win32.dart';
import 'package:flutter/foundation.dart';
import '../models/task_item.dart';
import 'task_viewmodel.dart';

final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  return LinkRepository.instance;
});

final linkViewModelProvider = StateNotifierProvider<LinkViewModel, LinkState>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return LinkViewModel(repository, ref);
});

class LinkState {
  final List<Group> groups;
  final bool isLoading;
  final String? error;

  LinkState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  LinkState copyWith({
    List<Group>? groups,
    bool? isLoading,
    String? error,
  }) {
    return LinkState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LinkViewModel extends StateNotifier<LinkState> {
  final LinkRepository _repository;
  final _uuid = Uuid();
  final Ref _ref;

  LinkViewModel(this._repository, this._ref) : super(LinkState()) {
    _initialize();
  }

  /// Windowsで特殊文字を含むファイルを安全に開く
  Future<void> _openFileWithShellExecute(String filePath) async {
    try {
      final file = File(filePath);
      final absolutePath = file.absolute.path;
      
      // ShellExecuteを使用してファイルを開く（特殊文字対応）
      final result = ShellExecute(
        0, // hwnd
        TEXT('open'), // lpOperation
        TEXT(absolutePath), // lpFile
        ffi.nullptr, // lpParameters
        ffi.nullptr, // lpDirectory
        SW_SHOWNORMAL, // nShowCmd
      );
      
      if (result <= 32) {
        // ShellExecuteが失敗した場合、フォールバックとしてcmdを使用
        await Process.run('cmd', ['/c', 'start', '', '"$absolutePath"'], runInShell: true);
      }
    } catch (e) {
      print('ShellExecute failed: $e');
      // 最終的なフォールバック
      final file = File(filePath);
      final absolutePath = file.absolute.path;
      await Process.run('cmd', ['/c', 'start', '', '"$absolutePath"'], runInShell: true);
    }
  }

  /// PDFファイルを安全に開く（公開メソッド）
  Future<void> openPdfFile(String filePath) async {
    await _openFileWithShellExecute(filePath);
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.initialize();
      
      // データ整合性チェックを無効化（既存データを保持）
      if (kDebugMode) {
        print('LinkViewModel: データ整合性チェックをスキップします（既存データを保持）');
      }
      
      // 自動復元機能：最新のバックアップファイルからデータを復元
      await _autoRestoreFromBackup();
      
      await _loadGroups();
      // 既存のリンクにデフォルトタグを追加
      await addDefaultTagsToExistingLinks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 外部からグループを強制更新するための公開メソッド
  Future<void> refreshGroups() async {
    await _loadGroups(forceUpdate: true);
  }

  Future<void> _loadGroups({bool forceUpdate = false}) async {
    final groups = _repository.getAllGroups();
    final order = _repository.getGroupsOrder();
    List<Group> sortedGroups;
    if (order.isNotEmpty) {
      // 順序リストに従って並べる
      sortedGroups = [
        ...order.map((id) => groups.firstWhereOrNull((g) => g.id == id)).whereType<Group>(),
        ...groups.where((g) => !order.contains(g.id)), // 新規追加分
      ];
    } else {
      sortedGroups = groups;
    }
    
    // デバッグ用: 読み込まれたデータの詳細を確認
    if (kDebugMode) {
      print('LinkViewModel: _loadGroups - 読み込まれたデータの詳細');
      for (final group in sortedGroups) {
        print('  - グループ: ${group.title} (ID: ${group.id}) - リンク数: ${group.items.length}');
        if (group.items.isNotEmpty) {
          for (final item in group.items) {
            print('    - リンク: ${item.label} (ID: ${item.id})');
          }
        } else {
          print('    - リンクなし');
        }
      }
    }
    
    // デバッグ情報（開発時のみ）
    if (kDebugMode) {
      print('=== _loadGroups ===');
      print('読み込まれたグループ数: ${sortedGroups.length}');
      print('現在の状態のグループ数: ${state.groups.length}');
      print('強制更新: $forceUpdate');
      print('状態が等しいかチェック中...');
      
      final areEqual = _areGroupsEqual(state.groups, sortedGroups);
      print('状態が等しい: $areEqual');
      
      if (!areEqual || forceUpdate) {
        print('状態が変更されたため、更新を実行します');
        for (final group in sortedGroups) {
          print('グループ "${group.title}": ${group.items.length}個のリンク');
          for (final link in group.items) {
            if (link.lastUsed != null) {
              print('  - ${link.label}: lastUsed = ${link.lastUsed}');
            }
          }
        }
      } else {
        print('状態が変更されていないため、更新をスキップします');
      }
      print('==================');
    }
    
    // 常に状態を更新する（状態比較の問題を回避）
    if (kDebugMode) {
      print('LinkViewModel: 状態を更新します - グループ数: ${sortedGroups.length}');
      for (final group in sortedGroups) {
        print('  - 更新されるグループ: ${group.title} - リンク数: ${group.items.length}');
      }
    }
    state = state.copyWith(groups: sortedGroups);
  }

  // グループの等価性をチェックするヘルパーメソッド
  bool _areGroupsEqual(List<Group> groups1, List<Group> groups2) {
    if (groups1.length != groups2.length) return false;
    
    for (int i = 0; i < groups1.length; i++) {
      final group1 = groups1[i];
      final group2 = groups2[i];
      
      if (group1.id != group2.id ||
          group1.title != group2.title ||
          group1.isFavorite != group2.isFavorite ||
          group1.collapsed != group2.collapsed ||
          group1.color != group2.color ||
          group1.order != group2.order) {
        return false;
      }
      
      if (group1.items.length != group2.items.length) return false;
      
      for (int j = 0; j < group1.items.length; j++) {
        final item1 = group1.items[j];
        final item2 = group2.items[j];
        
        if (item1.id != item2.id ||
            item1.label != item2.label ||
            item1.path != item2.path ||
            item1.type != item2.type ||
            item1.isFavorite != item2.isFavorite ||
            item1.lastUsed != item2.lastUsed ||
            item1.hasActiveTasks != item2.hasActiveTasks ||
            item1.memo != item2.memo ||
            !_areTagsEqual(item1.tags, item2.tags)) {
          return false;
        }
      }
    }
    
    return true;
  }

  // タグの等価性をチェックするヘルパーメソッド
  bool _areTagsEqual(List<String> tags1, List<String> tags2) {
    if (tags1.length != tags2.length) return false;
    for (int i = 0; i < tags1.length; i++) {
      if (tags1[i] != tags2[i]) return false;
    }
    return true;
  }

  // Group operations
  Future<void> createGroup({
    required String title,
    int? color,
    List<String>? labels,
  }) async {
    final groups = state.groups;
    final maxOrder = groups.isNotEmpty ? groups.map((g) => g.order).reduce((a, b) => a > b ? a : b) : 0;
    final group = Group(
      id: _uuid.v4(),
      title: title,
      items: [],
      order: maxOrder + 1,
      color: color,
      labels: labels,
    );
    await _repository.saveGroup(group);
    // 並び順リストにも追加
    final newOrder = [...groups.map((g) => g.id), group.id];
    await _repository.saveGroupsOrder(newOrder);
    await _loadGroups();
  }

  Future<void> updateGroup(Group group) async {
    await _repository.saveGroup(group);
    await _loadGroups();
  }

  Future<void> deleteGroup(String groupId) async {
    await _repository.deleteGroup(groupId);
    // 並び順リストからも削除
    final newOrder = state.groups.where((g) => g.id != groupId).map((g) => g.id).toList();
    await _repository.saveGroupsOrder(newOrder);
    await _loadGroups();
  }

  Future<void> toggleGroupCollapse(String groupId) async {
    final groups = state.groups;
    final groupIndex = groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = groups[groupIndex];
      final updatedGroup = group.copyWith(collapsed: !group.collapsed);
      await _repository.saveGroup(updatedGroup);
      await _loadGroups();
    }
  }

  Future<void> toggleGroupFavorite(Group group) async {
    print('Toggle group favorite: ${group.title}, current: ${group.isFavorite}');
    final updated = group.copyWith(isFavorite: !group.isFavorite);
    print('New favorite state: ${updated.isFavorite}');
    await _repository.updateGroup(updated);
    await _loadGroups();
  }

  // Link operations
  Future<void> addLinkToGroup({
    required String groupId,
    required String label,
    required String path,
    required LinkType type,
    int? iconData,
    int? iconColor,
    List<String>? tags,
    String? faviconFallbackDomain,
  }) async {
    // フォルダの場合、Windows APIを使ってカスタムアイコンを自動取得
    if (type == LinkType.folder) {
      if (iconData == null || iconColor == null) {
        try {
          final directory = Directory(path);
          if (await directory.exists()) {
            print('フォルダ登録: ${directory.path}');
            print('Windows APIを使用してカスタムアイコンを検出中...');
            
            // Windows APIを使ってフォルダのカスタムアイコンを取得
            final iconInfo = await WindowsIconExtractor.getFolderIcon(path);
            
            if (iconInfo != null && iconInfo['isCustom'] == true) {
              // カスタムアイコンが見つかった場合
              print('カスタムアイコンを検出しました');
              iconData = iconInfo['iconHandle'] as int;
              iconColor = iconInfo['color'] as int;
              
              print('設定されたカスタムアイコン: iconData=$iconData, iconColor=$iconColor');
            } else {
              // カスタムアイコンがない場合はデフォルトアイコンを設定
              print('カスタムアイコンが見つかりませんでした。デフォルトアイコンを設定');
              iconData = Icons.folder.codePoint;
              iconColor = Colors.orange.value;
              
              print('設定されたデフォルトアイコン: iconData=$iconData, iconColor=$iconColor');
            }
          }
        } catch (e) {
          print('フォルダアイコン検出エラー: $e');
          // エラーの場合もデフォルトアイコンを設定
          iconData = Icons.folder.codePoint;
          iconColor = Colors.orange.value;
        }
      } else {
        print('フォルダ登録: $path');
        print('カスタムアイコンが指定されました: iconData=$iconData, iconColor=$iconColor');
        print('地球アイコンのcodePoint: ${Icons.public.codePoint}');
        print('指定されたアイコンが地球アイコンかチェック: ${iconData == Icons.public.codePoint}');
      }
    }

    final link = LinkItem(
      id: _uuid.v4(),
      label: label,
      path: path,
      type: type,
      createdAt: DateTime.now(),
      iconData: iconData,
      iconColor: iconColor,
      tags: tags ?? [],
      faviconFallbackDomain: faviconFallbackDomain,
    );
    
    // フォールバックドメインのデバッグログ
    if (kDebugMode && faviconFallbackDomain != null && faviconFallbackDomain.isNotEmpty) {
      print('リンク追加: フォールバックドメイン設定 = $faviconFallbackDomain');
    }

    await _repository.saveLink(link);
    
    final groups = state.groups;
    final groupIndex = groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = groups[groupIndex];
      final updatedItems = [...group.items, link];
      final updatedGroup = group.copyWith(items: updatedItems);
      
      if (kDebugMode) {
        print('LinkViewModel: グループにリンクを追加 - ${group.title}');
        print('  - 追加前のリンク数: ${group.items.length}');
        print('  - 追加後のリンク数: ${updatedItems.length}');
        print('  - 追加されたリンク: ${link.label} (ID: ${link.id})');
      }
      
      await _repository.saveGroup(updatedGroup);
      await _loadGroups();
    } else {
      print('LinkViewModel: エラー - グループが見つかりません: $groupId');
    }
  }

  Future<void> removeLinkFromGroup(String groupId, String linkId) async {
    print('🔗 リンク削除開始: $linkId (グループ: $groupId)');
    
    // リンクを削除
    await _repository.deleteLink(linkId);
    
    // タスクからもリンクIDを削除
    try {
      final taskViewModel = _ref.read(taskViewModelProvider.notifier);
      await taskViewModel.removeLinkIdFromTasks(linkId);
      print('🔗 タスクからのリンクID削除完了: $linkId');
    } catch (e) {
      print('🔗 タスクからのリンクID削除エラー: $e');
    }
    
    final groups = state.groups;
    final groupIndex = groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = groups[groupIndex];
      final updatedItems = group.items.where((item) => item.id != linkId).toList();
      final updatedGroup = group.copyWith(items: updatedItems);
      await _repository.saveGroup(updatedGroup);
      await _loadGroups();
      print('🔗 リンク削除完了: $linkId');
    }
  }

  Future<void> updateLinkLastUsed(String linkId) async {
    await _repository.updateLinkLastUsed(linkId);
  }

  Future<void> launchLink(LinkItem link) async {
    print('=== launchLink 開始 ===');
    print('リンク: ${link.label} (${link.path})');
    print('現在のlastUsed: ${link.lastUsed}');
    print('現在の使用回数: ${link.useCount}');
    
    // リンクのlastUsedとuseCountを更新
    final updatedLink = link.copyWith(
      lastUsed: DateTime.now(),
      useCount: link.useCount + 1,
    );
    print('更新後のlastUsed: ${updatedLink.lastUsed}');
    print('更新後の使用回数: ${updatedLink.useCount}');
    
    // グループ内のリンクも更新
    final groups = state.groups;
    bool hasChanges = false;
    for (final group in groups) {
      final linkIndex = group.items.indexWhere((item) => item.id == link.id);
      if (linkIndex != -1) {
        print('グループ "${group.title}" 内のリンクを更新');
        final updatedItems = List<LinkItem>.from(group.items);
        updatedItems[linkIndex] = updatedLink;
        final updatedGroup = group.copyWith(items: updatedItems);
        await _repository.saveGroup(updatedGroup);
        hasChanges = true;
        break;
      }
    }
    
    // 個別のリンクボックスも更新
    await _repository.updateLinkLastUsed(link.id);
    
    // 変更があった場合のみ状態を再読み込み
    if (hasChanges) {
      await _loadGroups();
    }
    print('=== launchLink 完了 ===');
    
    // 実際にリンクを起動
    try {
      switch (link.type) {
        case LinkType.file:
          if (await File(link.path).exists()) {
            // Windowsで特殊文字を含むファイルパスを正しく開く方法
            await _openFileWithShellExecute(link.path);
          } else {
            throw Exception('File not found: ${link.path}');
          }
          break;
        case LinkType.folder:
          if (await Directory(link.path).exists()) {
            await Process.run('explorer', [link.path]);
          } else {
            throw Exception('Folder not found: ${link.path}');
          }
          break;
        case LinkType.url:
          final uri = Uri.parse(link.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Cannot launch URL: ${link.path}');
          }
          break;
      }
      print('Successfully launched: ${link.path}');
    } catch (e) {
      print('Error launching link: $e');
      // エラーが発生した場合はlastUsedを元に戻す
      final revertedLink = link.copyWith(lastUsed: link.lastUsed);
      for (final group in groups) {
        final linkIndex = group.items.indexWhere((item) => item.id == link.id);
        if (linkIndex != -1) {
          final updatedItems = List<LinkItem>.from(group.items);
          updatedItems[linkIndex] = revertedLink;
          final updatedGroup = group.copyWith(items: updatedItems);
          await _repository.saveGroup(updatedGroup);
          break;
        }
      }
      await _loadGroups();
      rethrow;
    }
  }

  Future<void> updateLinkInGroup({required String groupId, required LinkItem updated}) async {
    final groups = state.groups;
    final groupIndex = groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = groups[groupIndex];
      final updatedItems = group.items.map((e) => e.id == updated.id ? updated : e).toList();
      final updatedGroup = group.copyWith(items: updatedItems);
      
      await _repository.saveGroup(updatedGroup);
      await _loadGroups(forceUpdate: true);
    }
  }

  // 既存のリンクにデフォルトタグを追加
  Future<void> addDefaultTagsToExistingLinks() async {
    final groups = state.groups;
    bool hasChanges = false;
    
    for (final group in groups) {
      final updatedItems = group.items.map((link) {
        // 既にタグがある場合はスキップ
        if (link.tags.isNotEmpty) return link;
        
        // リンクタイプに基づいてデフォルトタグを追加
        String defaultTag = '';
        switch (link.type) {
          case LinkType.file:
            defaultTag = 'ファイル';
            break;
          case LinkType.folder:
            defaultTag = 'フォルダ';
            break;
          case LinkType.url:
            defaultTag = 'URL';
            break;
        }
        
        if (defaultTag.isNotEmpty) {
          hasChanges = true;
          return link.copyWith(tags: [defaultTag]);
        }
        return link;
      }).toList();
      
      if (hasChanges) {
        final updatedGroup = group.copyWith(items: updatedItems);
        await _repository.saveGroup(updatedGroup);
      }
    }
    
    if (hasChanges) {
      await _loadGroups();
    }
  }

  Future<void> updateGroupLinksOrder({required String groupId, required List<LinkItem> newOrder}) async {
    final groups = state.groups;
    final groupIndex = groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = groups[groupIndex];
      final updatedGroup = group.copyWith(items: newOrder);
      await _repository.saveGroup(updatedGroup);
      await _loadGroups();
    }
  }

  Future<void> updateGroupsOrder(List<Group> newOrder) async {
    for (int i = 0; i < newOrder.length; i++) {
      final updated = newOrder[i].copyWith(order: i);
      await _repository.saveGroup(updated);
    }
    // 並び順リストを保存
    await _repository.saveGroupsOrder(newOrder.map((g) => g.id).toList());
    await _loadGroups();
  }

  Future<void> toggleLinkFavorite(Group group, LinkItem link) async {
    if (kDebugMode) {
      print('Toggle link favorite: ${link.label}, current: ${link.isFavorite}');
    }
    final updatedLink = link.copyWith(isFavorite: !link.isFavorite);
    if (kDebugMode) {
      print('New link favorite state: ${updatedLink.isFavorite}');
    }
    final updatedItems = group.items.map((item) => item.id == link.id ? updatedLink : item).toList();
    // グループのお気に入り状態を自動制御
    bool newGroupFavorite;
    if (updatedLink.isFavorite) {
      newGroupFavorite = true;
    } else {
      newGroupFavorite = updatedItems.any((item) => item.isFavorite);
    }
    final updatedGroup = group.copyWith(
      items: updatedItems,
      isFavorite: newGroupFavorite,
    );
    await _repository.updateGroup(updatedGroup);
    await _loadGroups();
  }

  Future<void> moveLinkToGroup({required LinkItem link, required String fromGroupId, required String toGroupId}) async {
    if (fromGroupId == toGroupId) return;
    final groups = state.groups;
    final fromIndex = groups.indexWhere((g) => g.id == fromGroupId);
    final toIndex = groups.indexWhere((g) => g.id == toGroupId);
    if (fromIndex == -1 || toIndex == -1) return;
    final fromGroup = groups[fromIndex];
    final toGroup = groups[toIndex];
    final newFromItems = fromGroup.items.where((item) => item.id != link.id).toList();
    final newToItems = [...toGroup.items, link];
    // お気に入りリンクが0件ならisFavorite=false
    final updatedFromGroup = fromGroup.copyWith(
      items: newFromItems,
      isFavorite: newFromItems.any((item) => item.isFavorite),
    );
    final updatedToGroup = toGroup.copyWith(items: newToItems);
    await _repository.saveGroup(updatedFromGroup);
    await _repository.saveGroup(updatedToGroup);
    await _loadGroups();
  }

  Future<void> copyLinkToGroup({required LinkItem link, required String fromGroupId, required String toGroupId}) async {
    if (fromGroupId == toGroupId) return;
    final groups = state.groups;
    final toIndex = groups.indexWhere((g) => g.id == toGroupId);
    if (toIndex == -1) return;
    final toGroup = groups[toIndex];
    // リンクをコピー（新しいIDを生成）
    final copiedLink = link.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    final newToItems = [...toGroup.items, copiedLink];
    final updatedToGroup = toGroup.copyWith(items: newToItems);
    await _repository.saveGroup(updatedToGroup);
    await _loadGroups();
  }

  // Export/Import
  Map<String, dynamic> exportDataWithSettings(bool darkMode, double fontSize, int accentColor, {Map<String, dynamic>? customSettings, bool excludeMemos = false}) {
    final settings = {
      'darkMode': darkMode,
      'fontSize': fontSize,
      'accentColor': accentColor,
      if (customSettings != null) ...customSettings,
    };
    return _repository.exportData(settings: settings, excludeMemos: excludeMemos);
  }

  Future<Map<String, dynamic>?> importDataWithSettings(Map<String, dynamic> data, void Function(bool, double, int) onSettings) async {
    try {
      print('=== LinkViewModel インポート開始 ===');
      print('受信データのキー: ${data.keys.toList()}');
      
      // リンクデータをインポート
      await _repository.importData(data);
      print('リポジトリへのインポート完了');
      
      // グループデータを再読み込み
      await _loadGroups();
      print('グループデータの再読み込み完了');
      
      // 設定データを処理
      if (data['settings'] is Map) {
        final settings = data['settings'] as Map;
        final darkMode = settings['darkMode'] is bool ? settings['darkMode'] as bool : false;
        final fontSize = settings['fontSize'] is num ? (settings['fontSize'] as num).toDouble() : 1.0;
        final accentColor = settings['accentColor'] is int ? settings['accentColor'] as int : 0xFF3B82F6;
        onSettings(darkMode, fontSize, accentColor);
        print('設定データの適用完了');
        return Map<String, dynamic>.from(settings);
      }
      
      print('=== LinkViewModel インポート完了 ===');
      return null;
    } catch (e) {
      print('LinkViewModel インポートエラー: $e');
      rethrow;
    }
  }

  // タスク状態に基づいてリンクのhasActiveTasksを更新
  Future<void> updateLinkTaskStatus(List<TaskItem> tasks) async {
    try {
      print('=== updateLinkTaskStatus開始 ===');
      print('受信タスク数: ${tasks.length}');
      print('現在のグループ数: ${state.groups.length}');
      
      final groups = state.groups;
      bool hasChanges = false;
      
      for (final group in groups) {
        print('グループ "${group.title}" を処理中...');
        final updatedItems = <LinkItem>[];
        
        for (final link in group.items) {
          // このリンクに関連する完了していないタスクがあるかチェック
          final hasActiveTasks = tasks.any((task) => 
            task.relatedLinkId == link.id && 
            task.status != TaskStatus.completed
          );
          
          print('リンク "${link.label}": 現在のhasActiveTasks=${link.hasActiveTasks}, 計算結果=$hasActiveTasks');
          
          if (link.hasActiveTasks != hasActiveTasks) {
            final updatedLink = link.copyWith(hasActiveTasks: hasActiveTasks);
            updatedItems.add(updatedLink);
            hasChanges = true;
            print('リンク "${link.label}" のhasActiveTasksを更新: ${link.hasActiveTasks} -> $hasActiveTasks');
          } else {
            updatedItems.add(link);
          }
        }
        
        if (hasChanges) {
          final updatedGroup = group.copyWith(items: updatedItems);
          await _repository.updateGroup(updatedGroup);
          print('グループ "${group.title}" を更新しました');
        }
      }
      
      if (hasChanges) {
        await _loadGroups();
        if (kDebugMode) {
          print('リンクのタスク状態を更新しました');
        }
      } else {
        print('変更はありませんでした');
      }
      
      print('=== updateLinkTaskStatus完了 ===');
    } catch (e) {
      if (kDebugMode) {
        print('リンクのタスク状態更新エラー: $e');
      }
    }
  }

  // リンクに関連するタスクを取得
  List<TaskItem> getTasksByLinkId(String linkId) {
    // 現在のタスクリストを取得する方法を実装
    // このメソッドは現在使用されていないため、空のリストを返す
    return [];
  }

  // 指定されたIDのリンクを取得
  LinkItem? getLinkById(String linkId) {
    for (final group in state.groups) {
      for (final link in group.items) {
        if (link.id == linkId) {
          return link;
        }
      }
    }
    return null;
  }

  // 自動復元機能：最新のバックアップファイルからデータを復元
  Future<void> _autoRestoreFromBackup() async {
    try {
      if (kDebugMode) {
        print('LinkViewModel: 自動復元機能を開始します');
      }
      
      // 現在のデータをチェック
      final currentGroups = _repository.getAllGroups();
      final totalLinks = currentGroups.fold<int>(0, (sum, group) => sum + group.items.length);
      
      if (kDebugMode) {
        print('LinkViewModel: 現在のデータ - グループ数: ${currentGroups.length}, 総リンク数: $totalLinks');
      }
      
      // リンクが少ない場合（データが失われている可能性）のみ復元を実行
      if (totalLinks < 50) {
        if (kDebugMode) {
          print('LinkViewModel: データが少ないため、バックアップからの復元を実行します');
        }
        
        // 最新のバックアップファイルを探す
        final backupFile = await _findLatestBackupFile();
        if (backupFile != null) {
          if (kDebugMode) {
            print('LinkViewModel: バックアップファイルを発見: $backupFile');
          }
          
          // バックアップファイルからデータを復元
          await _restoreFromBackupFile(backupFile);
        } else {
          if (kDebugMode) {
            print('LinkViewModel: バックアップファイルが見つかりませんでした');
          }
        }
      } else {
        if (kDebugMode) {
          print('LinkViewModel: データが十分にあるため、復元をスキップします');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('LinkViewModel: 自動復元エラー: $e');
      }
      // エラーが発生してもアプリケーションは継続
    }
  }
  
  // 最新のバックアップファイルを探す
  Future<String?> _findLatestBackupFile() async {
    try {
      final directory = Directory.current;
      final files = directory.listSync()
          .where((file) => file is File && file.path.contains('linker_f_export_メモあり_') && file.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      if (files.isEmpty) return null;
      
      // ファイル名から日時を抽出して最新のものを選択
      files.sort((a, b) => b.path.compareTo(a.path));
      return files.first.path;
    } catch (e) {
      if (kDebugMode) {
        print('LinkViewModel: バックアップファイル検索エラー: $e');
      }
      return null;
    }
  }
  
  // バックアップファイルからデータを復元
  Future<void> _restoreFromBackupFile(String filePath) async {
    try {
      if (kDebugMode) {
        print('LinkViewModel: バックアップファイルから復元開始: $filePath');
      }
      
      final file = File(filePath);
      final content = await file.readAsString();
      final data = json.decode(content);
      
      // グループデータを復元
      if (data['groups'] != null) {
        final groups = (data['groups'] as List)
            .map((groupData) => Group.fromJson(groupData))
            .toList();
        
        for (final group in groups) {
          await _repository.saveGroup(group);
        }
        
        if (kDebugMode) {
          print('LinkViewModel: グループ復元完了 - ${groups.length}個のグループ');
        }
      }
      
      // 個別リンクデータを復元
      if (data['links'] != null) {
        final links = (data['links'] as List)
            .map((linkData) => LinkItem.fromJson(linkData))
            .toList();
        
        for (final link in links) {
          await _repository.saveLink(link);
        }
        
        if (kDebugMode) {
          print('LinkViewModel: リンク復元完了 - ${links.length}個のリンク');
        }
      }
      
      // グループ順序を復元
      if (data['groupsOrder'] != null) {
        final order = List<String>.from(data['groupsOrder']);
        await _repository.saveGroupsOrder(order);
        
        if (kDebugMode) {
          print('LinkViewModel: グループ順序復元完了');
        }
      }
      
      if (kDebugMode) {
        print('LinkViewModel: バックアップからの復元が完了しました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LinkViewModel: バックアップ復元エラー: $e');
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
} 