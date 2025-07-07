import 'package:hive_flutter/hive_flutter.dart';
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
  Map<String, dynamic> exportData({Map<String, dynamic>? settings}) {
    return {
      'groups': _groupsBox.values.map((g) => g.toJson()).toList(),
      'links': _linksBox.values.map((l) => l.toJson()).toList(),
      'groupsOrder': getGroupsOrder(),
      if (settings != null) 'settings': settings,
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    await _groupsBox.clear();
    await _linksBox.clear();
    
    for (final groupData in data['groups'] ?? []) {
      final group = Group.fromJson(groupData);
      await _groupsBox.put(group.id, group);
    }
    
    for (final linkData in data['links'] ?? []) {
      final link = LinkItem.fromJson(linkData);
      await _linksBox.put(link.id, link);
    }
    // グループ順序も復元
    if (data['groupsOrder'] is List) {
      await saveGroupsOrder(List<String>.from(data['groupsOrder']));
    }
    // settingsフィールドは今後の拡張用にそのまま返す（ViewModelで反映）
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