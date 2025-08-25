import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/link_item.dart';
import '../models/group.dart';
import '../repositories/link_repository.dart';
import 'package:collection/collection.dart';
import '../utils/windows_icon_extractor.dart';

final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  return LinkRepository();
});

final linkViewModelProvider = StateNotifierProvider<LinkViewModel, LinkState>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return LinkViewModel(repository);
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

  LinkViewModel(this._repository) : super(LinkState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.initialize();
      await _loadGroups();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadGroups() async {
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
    // デバッグ情報
    print('=== _loadGroups ===');
    print('読み込まれたグループ数: ${sortedGroups.length}');
    for (final group in sortedGroups) {
      print('グループ "${group.title}": ${group.items.length}個のリンク');
      for (final link in group.items) {
        if (link.lastUsed != null) {
          print('  - ${link.label}: lastUsed = ${link.lastUsed}');
        }
      }
    }
    print('==================');
    state = state.copyWith(groups: sortedGroups);
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
        print('フォルダ登録: ${path}');
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
    );

    await _repository.saveLink(link);
    
    final groups = state.groups;
    final groupIndex = groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = groups[groupIndex];
      final updatedItems = [...group.items, link];
      final updatedGroup = group.copyWith(items: updatedItems);
      await _repository.saveGroup(updatedGroup);
      await _loadGroups();
    }
  }

  Future<void> removeLinkFromGroup(String groupId, String linkId) async {
    await _repository.deleteLink(linkId);
    
    final groups = state.groups;
    final groupIndex = groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = groups[groupIndex];
      final updatedItems = group.items.where((item) => item.id != linkId).toList();
      final updatedGroup = group.copyWith(items: updatedItems);
      await _repository.saveGroup(updatedGroup);
      await _loadGroups();
    }
  }

  Future<void> updateLinkLastUsed(String linkId) async {
    await _repository.updateLinkLastUsed(linkId);
  }

  Future<void> launchLink(LinkItem link) async {
    print('=== launchLink 開始 ===');
    print('リンク: ${link.label} (${link.path})');
    print('現在のlastUsed: ${link.lastUsed}');
    
    // リンクのlastUsedを更新
    final updatedLink = link.copyWith(lastUsed: DateTime.now());
    print('更新後のlastUsed: ${updatedLink.lastUsed}');
    
    // グループ内のリンクも更新
    final groups = state.groups;
    for (final group in groups) {
      final linkIndex = group.items.indexWhere((item) => item.id == link.id);
      if (linkIndex != -1) {
        print('グループ "${group.title}" 内のリンクを更新');
        final updatedItems = List<LinkItem>.from(group.items);
        updatedItems[linkIndex] = updatedLink;
        final updatedGroup = group.copyWith(items: updatedItems);
        await _repository.saveGroup(updatedGroup);
        break;
      }
    }
    
    // 個別のリンクボックスも更新
    await _repository.updateLinkLastUsed(link.id);
    
    // 状態を再読み込み
    await _loadGroups();
    print('=== launchLink 完了 ===');
    
    // 実際にリンクを起動
    try {
      switch (link.type) {
        case LinkType.file:
          if (await File(link.path).exists()) {
            // Windowsの正しい起動方法
            await Process.run('cmd', ['/c', 'start', '', link.path], runInShell: true);
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
    print('Toggle link favorite: ${link.label}, current: ${link.isFavorite}');
    final updatedLink = link.copyWith(isFavorite: !link.isFavorite);
    print('New link favorite state: ${updatedLink.isFavorite}');
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

  // Export/Import
  Map<String, dynamic> exportDataWithSettings(bool darkMode, double fontSize, int accentColor, {Map<String, dynamic>? customSettings}) {
    final settings = {
      'darkMode': darkMode,
      'fontSize': fontSize,
      'accentColor': accentColor,
      if (customSettings != null) ...customSettings,
    };
    return _repository.exportData(settings: settings);
  }

  Future<Map<String, dynamic>?> importDataWithSettings(Map<String, dynamic> data, void Function(bool, double, int) onSettings) async {
    await _repository.importData(data);
    await _loadGroups();
    if (data['settings'] is Map) {
      final settings = data['settings'] as Map;
      final darkMode = settings['darkMode'] is bool ? settings['darkMode'] as bool : false;
      final fontSize = settings['fontSize'] is num ? (settings['fontSize'] as num).toDouble() : 1.0;
      final accentColor = settings['accentColor'] is int ? settings['accentColor'] as int : 0xFF3B82F6;
      onSettings(darkMode, fontSize, accentColor);
      return Map<String, dynamic>.from(settings);
    }
    return null;
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
} 