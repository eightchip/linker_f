import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/link_item.dart';
import '../models/group.dart';

class LinkRepository {
  static const String _groupsBoxName = 'groups';
  static const String _linksBoxName = 'links';
  static const String _groupsOrderBoxName = 'groups_order';
  
  // シングルトンインスタンス
  static LinkRepository? _instance;
  static LinkRepository get instance {
    _instance ??= LinkRepository._internal();
    return _instance!;
  }
  
  // プライベートコンストラクタ
  LinkRepository._internal();
  
  Box<Group>? _groupsBox;
  Box<LinkItem>? _linksBox;
  Box? _groupsOrderBox;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('LinkRepository: Hiveボックスを初期化中...');
      // Open boxes (Hive is already initialized in main.dart)
      _groupsBox = await Hive.openBox<Group>(_groupsBoxName);
      _linksBox = await Hive.openBox<LinkItem>(_linksBoxName);
      _groupsOrderBox = await Hive.openBox(_groupsOrderBoxName);
      _isInitialized = true;
      print('LinkRepository: Hiveボックスの初期化が完了しました');
    } catch (e) {
      print('LinkRepository: Hiveボックスの初期化エラー: $e');
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized || _groupsBox == null || _linksBox == null || _groupsOrderBox == null) {
      throw StateError('LinkRepository is not initialized. Call initialize() first.');
    }
  }

  // Group operations
  List<Group> getAllGroups() {
    _ensureInitialized();
    final groups = _groupsBox!.values.toList();
    
    if (kDebugMode) {
      print('LinkRepository: グループ読み込み - 総数: ${groups.length}');
      for (final group in groups) {
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
    
    return groups;
  }

  Future<void> saveGroup(Group group) async {
    _ensureInitialized();
    try {
      if (kDebugMode) {
        print('LinkRepository: グループ保存開始 - ${group.title} (ID: ${group.id})');
        print('  - リンク数: ${group.items.length}');
        for (final item in group.items) {
          print('    - リンク: ${item.label} (ID: ${item.id})');
        }
      }
      
      await _groupsBox!.put(group.id, group);
      
      // データの永続化を確実にするため、少し待機
      await Future.delayed(const Duration(milliseconds: 50));
      
      // 保存されたデータを検証
      final savedGroup = _groupsBox!.get(group.id);
      if (savedGroup != null) {
        if (kDebugMode) {
          print('LinkRepository: グループ保存完了 - ${savedGroup.title}');
          print('  - 保存されたリンク数: ${savedGroup.items.length}');
        }
      } else {
        print('LinkRepository: 警告 - グループの保存に失敗しました: ${group.title}');
      }
    } catch (e) {
      print('LinkRepository: グループ保存エラー - ${group.title}: $e');
      rethrow;
    }
  }

  Future<void> updateGroup(Group group) async {
    _ensureInitialized();
    try {
      if (kDebugMode) {
        print('LinkRepository: グループ更新開始 - ${group.title} (ID: ${group.id})');
        print('  - リンク数: ${group.items.length}');
        for (final item in group.items) {
          print('    - リンク: ${item.label} (ID: ${item.id})');
        }
      }
      
      await _groupsBox!.put(group.id, group);
      
      // データの永続化を確実にするため、少し待機
      await Future.delayed(const Duration(milliseconds: 50));
      
      // 保存されたデータを検証
      final savedGroup = _groupsBox!.get(group.id);
      if (savedGroup != null) {
        if (kDebugMode) {
          print('LinkRepository: グループ更新完了 - ${savedGroup.title}');
          print('  - 保存されたリンク数: ${savedGroup.items.length}');
        }
      } else {
        print('LinkRepository: 警告 - グループの更新に失敗しました: ${group.title}');
      }
    } catch (e) {
      print('LinkRepository: グループ更新エラー - ${group.title}: $e');
      rethrow;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    _ensureInitialized();
    await _groupsBox!.delete(groupId);
  }

  // Link operations
  List<LinkItem> getAllLinks() {
    _ensureInitialized();
    return _linksBox!.values.toList();
  }

  Future<void> saveLink(LinkItem link) async {
    _ensureInitialized();
    await _linksBox!.put(link.id, link);
  }

  Future<void> deleteLink(String linkId) async {
    _ensureInitialized();
    await _linksBox!.delete(linkId);
  }

  Future<void> updateLinkLastUsed(String linkId) async {
    _ensureInitialized();
    final link = _linksBox!.get(linkId);
    if (link != null) {
      link.lastUsed = DateTime.now();
      await _linksBox!.put(linkId, link);
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
      
      _ensureInitialized();
      // 元のデータを確認
      if (kDebugMode) {
        print('=== 元のデータ確認 ===');
        for (final group in _groupsBox!.values) {
          for (final item in group.items) {
            if (item.memo != null) {
              print('元データ: グループ "${group.title}" のリンク "${item.label}": memo="${item.memo}"');
            }
          }
        }
        for (final link in _linksBox!.values) {
          if (link.memo != null) {
            print('元データ: 個別リンク "${link.label}": memo="${link.memo}"');
          }
        }
      }
      
      // メモを除外したデータを作成（より確実な方法）
      final groupsWithoutMemos = _groupsBox!.values.map((group) {
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
      
      final linksWithoutMemos = _linksBox!.values.map((link) {
        // メモがnullでない場合（空文字列も含む）のみ除外処理をログ出力
        if (kDebugMode) {
          if (link.memo != null && link.memo!.isNotEmpty) {
            print('個別リンク "${link.label}": メモを除外 (元: "${link.memo}" -> null)');
          } else if (link.memo != null) {
            print('個別リンク "${link.label}": 空メモを除外 (元: "" -> null)');
          }
        }
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
      _ensureInitialized();
      if (kDebugMode) {
        print('=== メモを含むエクスポート ===');
      }
      return {
        'groups': _groupsBox!.values.map((g) => g.toJson()).toList(),
        'links': _linksBox!.values.map((l) => l.toJson()).toList(),
        'groupsOrder': getGroupsOrder(),
        if (settings != null) 'settings': settings,
      };
    }
  }

  Future<void> importData(Map<String, dynamic> data) async {
    _ensureInitialized();
    try {
      if (kDebugMode) {
        print('=== LinkRepository インポート開始 ===');
        print('受信データのキー: ${data.keys.toList()}');
      }
      
      // 既存データをクリア
      await _groupsBox!.clear();
      await _linksBox!.clear();
      if (kDebugMode) {
        print('既存データのクリア完了');
      }
      
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
        await _groupsBox!.put(fixedGroup.id, fixedGroup);
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
        await _linksBox!.put(link.id, link);
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
    _ensureInitialized();
    await _groupsOrderBox!.put('order', groupIds);
  }

  // 並び順の取得
  List<String> getGroupsOrder() {
    _ensureInitialized();
    final order = _groupsOrderBox!.get('order');
    if (order is List<String>) {
      return order;
    } else if (order is List) {
      // 型安全でない場合のため
      return order.map((e) => e.toString()).toList();
    }
    return [];
  }

  // データ整合性チェック
  Future<bool> validateDataIntegrity() async {
    _ensureInitialized();
    try {
      if (kDebugMode) {
        print('LinkRepository: データ整合性チェック開始');
      }
      
      final groups = _groupsBox!.values.toList();
      final links = _linksBox!.values.toList();
      
      // グループ内のリンクが個別リンクボックスにも存在するかチェック
      final groupLinkIds = <String>{};
      for (final group in groups) {
        for (final item in group.items) {
          groupLinkIds.add(item.id);
        }
      }
      
      final individualLinkIds = links.map((link) => link.id).toSet();
      
      // グループ内のリンクで個別リンクボックスに存在しないものがあるかチェック
      final missingLinks = groupLinkIds.difference(individualLinkIds);
      if (missingLinks.isNotEmpty) {
        print('LinkRepository: データ整合性エラー - グループ内のリンクが個別リンクボックスに存在しません: $missingLinks');
        return false;
      }
      
      if (kDebugMode) {
        print('LinkRepository: データ整合性チェック完了 - 正常');
        print('  - グループ数: ${groups.length}');
        print('  - 個別リンク数: ${links.length}');
        print('  - グループ内リンク数: ${groupLinkIds.length}');
      }
      
      return true;
    } catch (e) {
      print('LinkRepository: データ整合性チェックエラー: $e');
      return false;
    }
  }

  void dispose() {
    if (_isInitialized) {
      _groupsBox?.close();
      _linksBox?.close();
      _groupsOrderBox?.close();
    }
  }
} 