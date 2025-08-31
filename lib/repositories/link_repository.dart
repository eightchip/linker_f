import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/link_item.dart';
import '../models/group.dart';

class LinkRepository {
  static const String _groupsBoxName = 'groups';
  static const String _linksBoxName = 'links';
  static const String _groupsOrderBoxName = 'groups_order';
  
  late Box<Group> _groupsBox;
  late Box<LinkItem> _linksBox;
  late Box _groupsOrderBox;

  Future<void> initialize() async {
    // Open boxes (Hive is already initialized in main.dart)
    _groupsBox = await Hive.openBox<Group>(_groupsBoxName);
    _linksBox = await Hive.openBox<LinkItem>(_linksBoxName);
    _groupsOrderBox = await Hive.openBox(_groupsOrderBoxName);
  }

  // Group operations
  List<Group> getAllGroups() {
    return _groupsBox.values.toList();
  }

  Future<void> saveGroup(Group group) async {
    await _groupsBox.put(group.id, group);
  }

  Future<void> updateGroup(Group group) async {
    await _groupsBox.put(group.id, group);
  }

  Future<void> deleteGroup(String groupId) async {
    await _groupsBox.delete(groupId);
  }

  // Link operations
  List<LinkItem> getAllLinks() {
    return _linksBox.values.toList();
  }

  Future<void> saveLink(LinkItem link) async {
    await _linksBox.put(link.id, link);
  }

  Future<void> deleteLink(String linkId) async {
    await _linksBox.delete(linkId);
  }

  Future<void> updateLinkLastUsed(String linkId) async {
    final link = _linksBox.get(linkId);
    if (link != null) {
      link.lastUsed = DateTime.now();
      await _linksBox.put(linkId, link);
    }
  }

      // Export/Import
  Map<String, dynamic> exportData({Map<String, dynamic>? settings, bool excludeMemos = false}) {
    if (kDebugMode) {
      print('=== exportData 呼び出し ===');
      print('excludeMemos: $excludeMemos');
    }
    
    if (excludeMemos) {
      if (kDebugMode) {
        print('=== メモ除外エクスポート開始 ===');
      }
      
      // メモを除外したデータを作成
      final groupsWithoutMemos = _groupsBox.values.map((group) {
        final itemsWithoutMemos = group.items.map((item) {
          // 新しいLinkItemオブジェクトを作成してメモを確実にnullにする
          final itemWithoutMemo = LinkItem(
            id: item.id,
            label: item.label,
            path: item.path,
            type: item.type,
            createdAt: item.createdAt,
            lastUsed: item.lastUsed,
            isFavorite: item.isFavorite,
            memo: null, // 確実にnullに設定
            iconData: item.iconData,
            iconColor: item.iconColor,
            tags: item.tags,
            hasActiveTasks: item.hasActiveTasks,
            faviconFallbackDomain: item.faviconFallbackDomain,
          );
          return itemWithoutMemo;
        }).toList();
        return group.copyWith(items: itemsWithoutMemos);
      }).toList();
      
      final linksWithoutMemos = _linksBox.values.map((link) {
        // 新しいLinkItemオブジェクトを作成してメモを確実にnullに設定
        final linkWithoutMemo = LinkItem(
          id: link.id,
          label: link.label,
          path: link.path,
          type: link.type,
          createdAt: link.createdAt,
          lastUsed: link.lastUsed,
          isFavorite: link.isFavorite,
          memo: null, // 確実にnullに設定
          iconData: link.iconData,
          iconColor: link.iconColor,
          tags: link.tags,
          hasActiveTasks: link.hasActiveTasks,
          faviconFallbackDomain: link.faviconFallbackDomain,
        );
        return linkWithoutMemo;
      }).toList();
      
      if (kDebugMode) {
        print('=== メモ除外エクスポート完了 ===');
      }
      
      return {
        'groups': groupsWithoutMemos.map((g) => g.toJson()).toList(),
        'links': linksWithoutMemos.map((l) => l.toJson()).toList(),
        'groupsOrder': getGroupsOrder(),
        if (settings != null) 'settings': settings,
      };
    } else {
      if (kDebugMode) {
        print('=== メモを含むエクスポート ===');
      }
      return {
        'groups': _groupsBox.values.map((g) => g.toJson()).toList(),
        'links': _linksBox.values.map((l) => l.toJson()).toList(),
        'groupsOrder': getGroupsOrder(),
        if (settings != null) 'settings': settings,
      };
    }
  }

  Future<void> importData(Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        print('=== LinkRepository インポート開始 ===');
        print('受信データのキー: ${data.keys.toList()}');
      }
      
      // 既存データをクリア
      await _groupsBox.clear();
      await _linksBox.clear();
      
      // グループデータをインポート
      final groupsData = data['groups'] ?? [];
      if (kDebugMode) {
        print('グループデータ数: ${groupsData.length}');
      }
      for (final groupData in groupsData) {
        final group = Group.fromJson(groupData);
        final fixedGroup = group.color == null
          ? group.copyWith(color: 0xFF3B82F6) // デフォルト青
          : group;
        await _groupsBox.put(fixedGroup.id, fixedGroup);
        if (kDebugMode) {
          print('グループ保存: ${fixedGroup.title} (ID: ${fixedGroup.id})');
          // グループ内のリンクのフォールバックドメインを確認
          for (final item in fixedGroup.items) {
            if (item.faviconFallbackDomain != null) {
              print('  - リンク "${item.label}": フォールバックドメイン = ${item.faviconFallbackDomain}');
            }
          }
        }
      }
      
      // リンクデータをインポート
      final linksData = data['links'] ?? [];
      if (kDebugMode) {
        print('リンクデータ数: ${linksData.length}');
      }
      for (final linkData in linksData) {
        final link = LinkItem.fromJson(linkData);
        await _linksBox.put(link.id, link);
        if (kDebugMode) {
          print('リンク保存: ${link.label} (ID: ${link.id})');
          if (link.faviconFallbackDomain != null) {
            print('  - フォールバックドメイン: ${link.faviconFallbackDomain}');
          }
        }
      }
      
      // グループ順序も復元
      if (data['groupsOrder'] is List) {
        final order = List<String>.from(data['groupsOrder']);
        await saveGroupsOrder(order);
        if (kDebugMode) {
          print('グループ順序を復元: $order');
        }
      }
      
      // データの永続化を確実にするため、少し待機
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (kDebugMode) {
        print('=== LinkRepository インポート完了 ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LinkRepository インポートエラー: $e');
      }
      rethrow;
    }
  }

  // 並び順の保存
  Future<void> saveGroupsOrder(List<String> groupIds) async {
    await _groupsOrderBox.put('order', groupIds);
  }

  // 並び順の取得
  List<String> getGroupsOrder() {
    final order = _groupsOrderBox.get('order');
    if (order is List<String>) {
      return order;
    } else if (order is List) {
      // 型安全でない場合のため
      return order.map((e) => e.toString()).toList();
    }
    return [];
  }

  void dispose() {
    _groupsBox.close();
    _linksBox.close();
    _groupsOrderBox.close();
  }
} 