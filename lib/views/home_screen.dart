import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../viewmodels/link_viewmodel.dart';
import '../viewmodels/font_size_provider.dart';
import '../models/group.dart';
import '../models/link_item.dart';
import 'group_card.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'tutorial_dialog.dart';
import 'package:hive/hive.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfx/pdfx.dart' as pdfx;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isDragOver = false;
  String? draggingGroupId;
  Offset? draggingPosition;
  List<Group> _orderedGroups = [];
  String? _centerMessage;
  final ScrollController _scrollController = ScrollController();
  bool _showOnlyFavorites = false;
  bool _showSearchBar = false;
  String _searchQuery = '';
  bool _showRecent = false;
  bool _tutorialShown = false;
  bool _showFavoriteLinks = false;
  
  // 追加: ジャンプボタン表示制御用
  OverlayEntry? _jumpButtonOverlay;
  Offset? _lastMousePosition;
  DateTime? _lastMoveTime;
  BuildContext? _scaffoldBodyContext;
  final Map<String, bool> _showBottomSpaceMap = {};

  @override
  void initState() {
    super.initState();
    final groups = ref.read(linkViewModelProvider).groups;
    _orderedGroups = List<Group>.from(groups);
    
    // ScrollControllerの初期化を遅延させる
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
    _checkAndShowTutorial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = MediaQuery.of(context).size.width < 600 ? 18.0 : 24.0;
    final titleFontSize = MediaQuery.of(context).size.width < 600 ? 16.0 : 22.0;
    final groups = ref.watch(linkViewModelProvider).groups;
    final isLoading = ref.watch(linkViewModelProvider).isLoading;
    final error = ref.watch(linkViewModelProvider).error;
    final isDarkMode = ref.watch(darkModeProvider);
    final accentColor = ref.watch(accentColorProvider);
    
    // お気に入りグループと通常グループを分離
    final favoriteGroups = groups.where((g) => g.isFavorite).toList();
    final normalGroups = groups.where((g) => !g.isFavorite).toList();
    
    // 検索・最近使ったフィルタ適用
    List<Group> displayGroups = _showOnlyFavorites ? favoriteGroups : [...favoriteGroups, ...normalGroups];
    if (_searchQuery.isNotEmpty) {
      displayGroups = displayGroups
        .where((g) => g.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.items.any((l) => l.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            l.path.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            l.type.name.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
    }
    // 最近使ったグループ・リンク
    final recentLinks = groups.expand((g) => g.items)
      .where((l) => l.lastUsed != null)
      .toList()
      ..sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));
    final recentGroups = groups
      .where((g) => g.items.any((l) => l.lastUsed != null))
      .toList()
      ..sort((a, b) {
        final aLast = a.items.map((l) => l.lastUsed ?? DateTime.fromMillisecondsSinceEpoch(0)).reduce((a, b) => a.isAfter(b) ? a : b);
        final bLast = b.items.map((l) => l.lastUsed ?? DateTime.fromMillisecondsSinceEpoch(0)).reduce((a, b) => a.isAfter(b) ? a : b);
        return bLast.compareTo(aLast);
      });
    
    // お気に入りリンク一覧抽出
    final favoriteLinks = groups.expand((g) => g.items.map((l) => MapEntry(g, l)))
      .where((entry) => entry.value.isFavorite)
      .toList();
    
    // デバッグ情報
    print('=== デバッグ情報 ===');
    print('総リンク数: ${groups.expand((g) => g.items).length}');
    print('lastUsedが設定されているリンク数: ${recentLinks.length}');
    print('最近使ったリンク: ${recentLinks.map((l) => '${l.label} (${l.lastUsed})').toList()}');
    print('最近使ったグループ数: ${recentGroups.length}');
    print('_showRecent: $_showRecent');
    print('showRecent: ${_showRecent && (recentLinks.isNotEmpty || recentGroups.isNotEmpty)}');
    print('==================');
    
    return Listener(
      onPointerDown: (event) {
        // 右クリックや他ボタンは無視
      },
      onPointerHover: _onMouseMove,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTapDown: (details) {
          _showJumpButtons(details.globalPosition);
        },
        child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
            title: Text(
              'Link Navigator',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFontSize),
            ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 2,
        actions: [
          IconButton(icon: Icon(Icons.search, size: iconSize), tooltip: '検索', onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) _searchQuery = '';
              });
          }),
          IconButton(icon: Icon(Icons.add, size: iconSize), tooltip: 'グループを追加', onPressed: () => _showAddGroupDialog(context)),
          IconButton(icon: Icon(Icons.notes, size: iconSize), tooltip: 'メモ付きリンク一覧', onPressed: () {
              final groups = ref.read(linkViewModelProvider).groups;
              final memoLinks = groups.expand((g) => g.items.map((l) => MapEntry(g, l)))
                .where((entry) => entry.value.memo?.isNotEmpty == true)
                .toList();
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final accentColor = ref.read(accentColorProvider);
              final memoControllers = <String, TextEditingController>{};
              for (final entry in memoLinks) {
                memoControllers[entry.value.id] = TextEditingController(text: entry.value.memo ?? '');
              }
              showDialog(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    title: const Text('メモ付きリンク一覧'),
                    content: SizedBox(
                      width: 600,
                      height: 700,
                      child: Scrollbar(
                        child: ListView(
                          children: memoLinks.map((entry) {
                            final link = entry.value;
                            final group = entry.key;
                            final controller = memoControllers[link.id]!;
                            final isOverflow = (link.memo?.split('\n').length ?? 0) > 5 || (link.memo?.length ?? 0) > 100;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Color(accentColor),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.link, color: Colors.blue, size: 18),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () {
                                          ref.read(linkViewModelProvider.notifier).launchLink(link);
                                        },
                                        child: Text(
                                          link.label,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  MouseRegion(
                                    cursor: isOverflow ? SystemMouseCursors.help : SystemMouseCursors.basic,
                                    child: Tooltip(
                                      message: isOverflow ? link.memo! : '',
                                      child: TextField(
                                        controller: controller,
                                        maxLines: 3,
                                        minLines: 1,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: isDark ? Colors.black : Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: Color(accentColor).withOpacity(isDark ? 0.7 : 0.5),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.all(10),
                                        ),
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('閉じる'),
                      ),
                      ElevatedButton(
            onPressed: () {
                          for (final entry in memoLinks) {
                            final link = entry.value;
                            final group = entry.key;
                            final newMemo = memoControllers[link.id]!.text;
                            if (newMemo != link.memo) {
                              final updated = link.copyWith(memo: newMemo);
                              ref.read(linkViewModelProvider.notifier).updateLinkInGroup(
                                groupId: group.id,
                                updated: updated,
                              );
                            }
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('まとめて保存'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf, size: iconSize),
            tooltip: 'メモ付きリンク一覧をPDF出力',
            onPressed: () => _exportMemoLinksToPdf(context),
          ),
          IconButton(icon: Icon(Icons.star_outline, size: iconSize), tooltip: 'リンクのお気に入り一覧', onPressed: () async {
                  setState(() {
                    _showFavoriteLinks = !_showFavoriteLinks;
                  });
                  if (!_showFavoriteLinks) return;
              }),
          IconButton(icon: Icon(Icons.push_pin, color: _showRecent ? Colors.amber : Colors.grey, size: iconSize), tooltip: _showRecent ? '最近使った非表示' : '最近使ったを上部に表示', onPressed: () {
              setState(() {
                _showRecent = !_showRecent;
              });
            }),
          IconButton(icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, size: iconSize), tooltip: isDarkMode ? 'ライトモード' : 'ダークモード', onPressed: () {
              ref.read(darkModeProvider.notifier).state = !isDarkMode;
            }),
          IconButton(icon: Icon(Icons.palette, size: iconSize), tooltip: 'アクセントカラー変更', onPressed: () async {
                  final currentColor = ref.read(accentColorProvider);
                  final colorOptions = [
                    0xFF3B82F6, // 青（現在のデフォルト）
                    0xFFEF4444, // 赤
                    0xFF22C55E, // 緑
                    0xFFF59E42, // オレンジ
                    0xFF8B5CF6, // 紫
                    0xFFEC4899, // ピンク
                    0xFFEAB308, // 黄
                    0xFF06B6D4, // 水色
                    0xFF92400E, // 茶色
                    0xFF64748B, // グレー
                    0xFF84CC16, // ライム
                    0xFF6366F1, // インディゴ
                    0xFF14B8A6, // ティール
                    0xFFFB923C, // ディープオレンジ
                    0xFF7C3AED, // ディープパープル
                    0xFFFBBF24, // アンバー
                    0xFF0EA5E9, // シアン
                    0xFFB45309, // ブラウン
                    0xFFB91C1C, // レッドブラウン
                    0xFF166534, // ダークグリーン
                  ];
                  final colorNames = [
                    'ブルー', 'レッド', 'グリーン', 'オレンジ', 'パープル', 'ピンク', 'イエロー', 'シアン', 'ブラウン', 'グレー', 'ライム', 'インディゴ', 'ティール', 'ディープオレンジ', 'ディープパープル', 'アンバー', 'シアン', 'ブラウン', 'レッドブラウン', 'ダークグリーン'
                  ];
                  final selected = await showDialog<int>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('アクセントカラーを選択'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: colorOptions.map((color) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(color),
                                child: currentColor == color ? const Icon(Icons.check, color: Colors.white) : null,
                              ),
                              title: Text(colorNames[colorOptions.indexOf(color)]),
                              onTap: () => Navigator.pop(context, color),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                  if (selected != null && selected != currentColor) {
                    ref.read(accentColorProvider.notifier).state = selected;
                  }
                },
          ),
          IconButton(icon: Icon(Icons.upload, size: iconSize), tooltip: 'バックアップ', onPressed: () => _exportData(context)),
          IconButton(icon: Icon(Icons.download, size: iconSize), tooltip: 'データ復元', onPressed: () => _importData(context)),
          if (favoriteGroups.isNotEmpty)
            IconButton(icon: Icon(_showOnlyFavorites ? Icons.star : Icons.star_border, color: _showOnlyFavorites ? Colors.amber : Colors.grey, size: iconSize), tooltip: _showOnlyFavorites ? 'すべて表示' : 'グループのお気に入りのみ表示', onPressed: () {
                setState(() {
                  _showOnlyFavorites = !_showOnlyFavorites;
                });
                  }),
          IconButton(icon: Icon(Icons.help_outline, size: iconSize), tooltip: 'チュートリアル・ヘルプ', onPressed: _showTutorial),
        ],
        bottom: _showSearchBar
            ? PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '検索（グループ名・リンク名・パス・タイプ）',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _showSearchBar = false;
                          });
                        },
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _searchQuery = v;
                      });
                    },
                  ),
                ),
              )
            : null,
      ),
          body: Builder(
            builder: (bodyContext) {
              _scaffoldBodyContext = bodyContext;
              return Stack(
                children: [
                  _showFavoriteLinks
                    ? _buildFavoriteLinksList(favoriteLinks)
                    : isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : groups.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(displayGroups, recentLinks, recentGroups),
                  // 右下ジャンプボタン（アクセントカラー連動）
                  Positioned(
                    right: 24,
                    bottom: 32,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'jumpToTop',
                          backgroundColor: Color(accentColor).withOpacity(0.85),
                          foregroundColor: Colors.white,
                          onPressed: () {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          child: const Icon(Icons.vertical_align_top, size: 20),
                        ),
                        const SizedBox(height: 12),
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'jumpToBottom',
                          backgroundColor: Color(accentColor).withOpacity(0.85),
                          foregroundColor: Colors.white,
                              onPressed: () {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          child: const Icon(Icons.vertical_align_bottom, size: 20),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Group> displayGroups, List<LinkItem> recentLinks, List<Group> recentGroups) {
    final showRecent = _showRecent && (recentLinks.isNotEmpty || recentGroups.isNotEmpty);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        double gridSpacing;
        EdgeInsets gridPadding;
        if (width > 1400) {
          crossAxisCount = 4;
          gridSpacing = 40;
          gridPadding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
        } else if (width > 1100) {
          crossAxisCount = 3;
          gridSpacing = 32;
          gridPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        } else if (width > 700) {
          crossAxisCount = 2;
          gridSpacing = 24;
          gridPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        } else {
          crossAxisCount = 1;
          gridSpacing = 12;
          gridPadding = const EdgeInsets.symmetric(horizontal: 4, vertical: 8);
        }
        return Column(
              children: [
            if (showRecent)
                    Padding(
                padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('最近使ったリンク', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                      children: recentLinks.take(10).map((link) => ActionChip(
                              label: Text(link.label, overflow: TextOverflow.ellipsis),
                              avatar: Icon(_iconForType(link.type), size: 18),
                              onPressed: () => ref.read(linkViewModelProvider.notifier).launchLink(link),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                padding: gridPadding,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: gridSpacing,
                  mainAxisSpacing: gridSpacing,
                  childAspectRatio: 1.5,
                  ),
                  itemCount: displayGroups.length,
                  itemBuilder: (context, index) {
                    final group = displayGroups[index];
                    return Draggable<Group>(
                      data: group,
                      feedback: Material(
                        elevation: 16,
                        child: SizedBox(
                        width: 296,
                        height: 192,
                          child: GroupCard(
                            group: group,
                            onToggleCollapse: () => ref.read(linkViewModelProvider.notifier).toggleGroupCollapse(group.id),
                            onDeleteGroup: () => _deleteGroup(group.id),
                            onAddLink: () => _showAddLinkDialog(context, group.id),
                            onDeleteLink: (linkId) => ref.read(linkViewModelProvider.notifier).removeLinkFromGroup(group.id, linkId),
                            onLaunchLink: (link) => ref.read(linkViewModelProvider.notifier).launchLink(link),
                            onDropAddLink: (label, path, type) => ref.read(linkViewModelProvider.notifier).addLinkToGroup(
                              groupId: group.id,
                              label: label,
                              path: path,
                              type: type,
                            ),
                            onEditLink: (updated) => ref.read(linkViewModelProvider.notifier).updateLinkInGroup(groupId: group.id, updated: updated),
                            onReorderLinks: (newOrder) => ref.read(linkViewModelProvider.notifier).updateGroupLinksOrder(groupId: group.id, newOrder: newOrder),
                          onEditGroupTitle: (oldTitle) async {
                            final controller = TextEditingController(text: oldTitle);
                            int selectedColor = group.color ?? Colors.blue.value;
                            final result = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) => StatefulBuilder(
                                builder: (context, setState) => AlertDialog(
                                  title: const Text('グループ名を編集'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: controller,
                                          autofocus: true,
                                          decoration: const InputDecoration(labelText: '新しいグループ名'),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            const Text('色: '),
                                            Expanded(child: ColorPaletteSelector(
                                              selectedColor: selectedColor,
                                              onColorSelected: (color) => setState(() => selectedColor = color),
                                            )),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('キャンセル'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, {
                                        'title': controller.text,
                                        'color': selectedColor,
                                      }),
                                      child: const Text('保存'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (result != null && result['title'] != null && result['title'].trim().isNotEmpty && (result['title'] != oldTitle || result['color'] != group.color)) {
                              final updated = group.copyWith(title: result['title'].trim(), color: result['color']);
                              await ref.read(linkViewModelProvider.notifier).updateGroup(updated);
                            }
                            },
                            onFavoriteToggle: (g) => ref.read(linkViewModelProvider.notifier).toggleGroupFavorite(g),
                            onLinkFavoriteToggle: (g, l) => ref.read(linkViewModelProvider.notifier).toggleLinkFavorite(g, l),
                            onMoveLinkToGroup: (link, fromGroupId, toGroupId) => ref.read(linkViewModelProvider.notifier).moveLinkToGroup(link: link, fromGroupId: fromGroupId, toGroupId: toGroupId),
                          onShowMessage: _showCenterMessage,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: GroupCard(
                          group: group,
                          isDragging: true,
                          onToggleCollapse: () => ref.read(linkViewModelProvider.notifier).toggleGroupCollapse(group.id),
                          onDeleteGroup: () => _deleteGroup(group.id),
                          onAddLink: () => _showAddLinkDialog(context, group.id),
                          onDeleteLink: (linkId) => ref.read(linkViewModelProvider.notifier).removeLinkFromGroup(group.id, linkId),
                          onLaunchLink: (link) => ref.read(linkViewModelProvider.notifier).launchLink(link),
                          onDropAddLink: (label, path, type) => ref.read(linkViewModelProvider.notifier).addLinkToGroup(
                            groupId: group.id,
                            label: label,
                            path: path,
                            type: type,
                          ),
                          onEditLink: (updated) => ref.read(linkViewModelProvider.notifier).updateLinkInGroup(groupId: group.id, updated: updated),
                          onReorderLinks: (newOrder) => ref.read(linkViewModelProvider.notifier).updateGroupLinksOrder(groupId: group.id, newOrder: newOrder),
                        onEditGroupTitle: (oldTitle) async {
                          final controller = TextEditingController(text: oldTitle);
                          int selectedColor = group.color ?? Colors.blue.value;
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setState) => AlertDialog(
                                title: const Text('グループ名を編集'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: controller,
                                        autofocus: true,
                                        decoration: const InputDecoration(labelText: '新しいグループ名'),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const Text('色: '),
                                          Expanded(child: ColorPaletteSelector(
                                            selectedColor: selectedColor,
                                            onColorSelected: (color) => setState(() => selectedColor = color),
                                          )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('キャンセル'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, {
                                      'title': controller.text,
                                      'color': selectedColor,
                                    }),
                                    child: const Text('保存'),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (result != null && result['title'] != null && result['title'].trim().isNotEmpty && (result['title'] != oldTitle || result['color'] != group.color)) {
                            final updated = group.copyWith(title: result['title'].trim(), color: result['color']);
                            await ref.read(linkViewModelProvider.notifier).updateGroup(updated);
                          }
                          },
                          onFavoriteToggle: (g) => ref.read(linkViewModelProvider.notifier).toggleGroupFavorite(g),
                          onLinkFavoriteToggle: (g, l) => ref.read(linkViewModelProvider.notifier).toggleLinkFavorite(g, l),
                          onMoveLinkToGroup: (link, fromGroupId, toGroupId) => ref.read(linkViewModelProvider.notifier).moveLinkToGroup(link: link, fromGroupId: fromGroupId, toGroupId: toGroupId),
                        onShowMessage: _showCenterMessage,
                        ),
                      ),
                      child: DragTarget<Group>(
                        onWillAccept: (data) => data != null && data.id != group.id,
                        onAccept: (data) async {
                          final groups = ref.read(linkViewModelProvider).groups;
                          final fromIndex = groups.indexWhere((g) => g.id == data.id);
                          final toIndex = groups.indexWhere((g) => g.id == group.id);
                          if (fromIndex != -1 && toIndex != -1) {
                            final newOrder = List<Group>.from(groups);
                            final item = newOrder.removeAt(fromIndex);
                            newOrder.insert(toIndex, item);
                            await ref.read(linkViewModelProvider.notifier).updateGroupsOrder(newOrder);
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return GroupCard(
                            group: group,
                            onToggleCollapse: () => ref.read(linkViewModelProvider.notifier).toggleGroupCollapse(group.id),
                            onDeleteGroup: () => _deleteGroup(group.id),
                            onAddLink: () => _showAddLinkDialog(context, group.id),
                            onDeleteLink: (linkId) => ref.read(linkViewModelProvider.notifier).removeLinkFromGroup(group.id, linkId),
                            onLaunchLink: (link) => ref.read(linkViewModelProvider.notifier).launchLink(link),
                            onDropAddLink: (label, path, type) => ref.read(linkViewModelProvider.notifier).addLinkToGroup(
                              groupId: group.id,
                              label: label,
                              path: path,
                              type: type,
                            ),
                            onEditLink: (updated) => ref.read(linkViewModelProvider.notifier).updateLinkInGroup(groupId: group.id, updated: updated),
                            onReorderLinks: (newOrder) => ref.read(linkViewModelProvider.notifier).updateGroupLinksOrder(groupId: group.id, newOrder: newOrder),
                          onEditGroupTitle: (oldTitle) async {
                            final controller = TextEditingController(text: oldTitle);
                            int selectedColor = group.color ?? Colors.blue.value;
                            final result = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) => StatefulBuilder(
                                builder: (context, setState) => AlertDialog(
                                  title: const Text('グループ名を編集'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: controller,
                                          autofocus: true,
                                          decoration: const InputDecoration(labelText: '新しいグループ名'),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            const Text('色: '),
                                            Expanded(child: ColorPaletteSelector(
                                              selectedColor: selectedColor,
                                              onColorSelected: (color) => setState(() => selectedColor = color),
                                            )),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('キャンセル'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, {
                                        'title': controller.text,
                                        'color': selectedColor,
                                      }),
                                      child: const Text('保存'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (result != null && result['title'] != null && result['title'].trim().isNotEmpty && (result['title'] != oldTitle || result['color'] != group.color)) {
                              final updated = group.copyWith(title: result['title'].trim(), color: result['color']);
                              await ref.read(linkViewModelProvider.notifier).updateGroup(updated);
                            }
                            },
                            onFavoriteToggle: (g) => ref.read(linkViewModelProvider.notifier).toggleGroupFavorite(g),
                            onLinkFavoriteToggle: (g, l) => ref.read(linkViewModelProvider.notifier).toggleLinkFavorite(g, l),
                            onMoveLinkToGroup: (link, fromGroupId, toGroupId) => ref.read(linkViewModelProvider.notifier).moveLinkToGroup(link: link, fromGroupId: fromGroupId, toGroupId: toGroupId),
                          onShowMessage: _showCenterMessage,
                          );
                        },
                      ),
                    );
                  },
            ),
          ),
      ],
        );
      },
    );
  }

  Widget _buildFavoriteLinksList(List<MapEntry<Group, LinkItem>> favoriteLinks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 64),
      itemCount: favoriteLinks.length,
      itemBuilder: (context, index) {
        final entry = favoriteLinks[index];
        return FavoriteLinkTile(
          link: entry.value,
          group: entry.key,
          onUnfavorite: () => ref.read(linkViewModelProvider.notifier).toggleLinkFavorite(entry.key, entry.value),
          onLaunch: () => ref.read(linkViewModelProvider.notifier).launchLink(entry.value),
          isDark: isDark,
          onShowMessage: _showCenterMessage,
          ref: ref,
        );
      },
    );
  }

  IconData _iconForType(LinkType type) {
    switch (type) {
      case LinkType.file:
        return Icons.insert_drive_file;
      case LinkType.folder:
        return Icons.folder;
      case LinkType.url:
        return Icons.link;
    }
  }

  void _showAddGroupDialog(BuildContext context) {
    final titleController = TextEditingController();
    int selectedColor = Colors.black.value; // デフォルト黒
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
        title: const Text('Add New Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Group Title',
            hintText: 'Enter group title...',
          ),
          autofocus: true,
              ),
              const SizedBox(height: 16),
              ColorPaletteSelector(
                selectedColor: selectedColor,
                onColorSelected: (color) => setState(() => selectedColor = color),
              ),
            ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref.read(linkViewModelProvider.notifier).createGroup(
                  title: titleController.text,
                    color: selectedColor,
                    labels: null,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
        ),
      ),
    );
  }

  void _showAddLinkDialog(BuildContext context, String groupId) {
    final labelController = TextEditingController();
    final pathController = TextEditingController();
    LinkType selectedType = LinkType.file;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'Enter link label...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pathController,
                decoration: const InputDecoration(
                  labelText: 'Path/URL',
                  hintText: 'Enter file path or URL...',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LinkType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                ),
                items: LinkType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (labelController.text.isNotEmpty && 
                    pathController.text.isNotEmpty) {
                  ref.read(linkViewModelProvider.notifier).addLinkToGroup(
                    groupId: groupId,
                    label: labelController.text,
                    path: pathController.text,
                    type: selectedType,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDrop(BuildContext context, dynamic detail) async {
    if (detail.files != null && detail.files.isNotEmpty) {
      bool hasUrl = false;
      for (final file in detail.files) {
        final path = file.path;
        if (path.startsWith('http://') || path.startsWith('https://')) {
          hasUrl = true;
        }
      }
      if (hasUrl) {
        setState(() {
          _centerMessage = 'URLのドラッグ＆ドロップは未対応です\nリンク追加ボタンから直接入力してください。';
        });
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _centerMessage = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${detail.files.length}件のファイル/フォルダをドロップしました。グループにドラッグして追加できます。')),
        );
      }
    }
  }

  void _deleteGroup(String groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(linkViewModelProvider.notifier).deleteGroup(groupId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCenterMessage(String message, {IconData? icon, Color? color}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Container(
            alignment: Alignment.center,
            color: Colors.black.withOpacity(0.25),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                decoration: BoxDecoration(
                  color: color ?? Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 36),
                      const SizedBox(width: 16),
                    ],
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  void _exportData(BuildContext context) async {
    final darkMode = ref.read(darkModeProvider);
    final fontSize = ref.read(fontSizeProvider);
    final accentColor = ref.read(accentColorProvider);
    final data = ref.read(linkViewModelProvider.notifier).exportDataWithSettings(darkMode, fontSize, accentColor);
    final jsonStr = jsonEncode(data);
    final now = DateTime.now();
    final formatted = DateFormat('yyMMddHHmm').format(now);
    final file = File('linker_f_export_$formatted.json');
    await file.writeAsString(jsonStr);
    _showCenterMessage('エクスポートしました: ${file.absolute.path}', icon: Icons.check_circle, color: Colors.green[700]);
  }

  void _importData(BuildContext context) async {
    try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final jsonStr = await file.readAsString();
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        await ref.read(linkViewModelProvider.notifier).importDataWithSettings(
          data,
          (bool darkMode, double fontSize, int accentColor) {
            ref.read(darkModeProvider.notifier).state = darkMode;
            ref.read(fontSizeProvider.notifier).state = fontSize;
            ref.read(accentColorProvider.notifier).state = accentColor;
          },
        );
        _showCenterMessage('インポートしました: ${file.path}', icon: Icons.check_circle, color: Colors.blue[700]);
      }
      } catch (e) {
      _showCenterMessage('インポートエラー: $e', icon: Icons.error, color: Colors.red[700]);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first group to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndShowTutorial() async {
    final box = await Hive.openBox('settings');
    final shown = box.get('tutorial_shown', defaultValue: false);
    if (!shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TutorialDialog(
            onFinish: () async {
              await box.put('tutorial_shown', true);
              setState(() => _tutorialShown = true);
            },
          ),
        );
      });
    } else {
      setState(() => _tutorialShown = true);
    }
  }

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => TutorialDialog(),
    );
  }

  void _onMouseMove(PointerEvent event) {
    // 画面端ホバー時のジャンプボタン表示ロジックを削除
    // 何も処理しない、または他の用途だけ残す
  }

  void _showJumpButtons(Offset position, {String? edge}) {
    _jumpButtonOverlay?.remove();
    final isAtTop = _scrollController.offset <= 0;
    final isAtBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent - 1;
    List<Widget> jumpButtons = [];
    
    // ダブルクリックの場合（edge == null）
    if (edge == null) {
      if (!isAtTop) {
        jumpButtons.add(_jumpButton('前ページ', Icons.arrow_upward, _scrollToPrevPage));
      }
      if (!isAtBottom) {
        jumpButtons.add(_jumpButton('次ページ', Icons.arrow_downward, _scrollToNextPage));
      }
      if (isAtTop) {
        jumpButtons.add(_jumpButton('トップページ', Icons.vertical_align_top, _scrollToTop));
      }
      if (isAtBottom) {
        jumpButtons.add(_jumpButton('最終ページ', Icons.vertical_align_bottom, _scrollToBottom));
      }
    } else if (edge == 'top') {
      if (!isAtTop) {
        jumpButtons.add(_jumpButton('前ページ', Icons.arrow_upward, _scrollToPrevPage));
    } else {
        jumpButtons.add(_jumpButton('トップページ', Icons.vertical_align_top, _scrollToTop));
      }
    } else if (edge == 'bottom') {
      if (!isAtBottom) {
        jumpButtons.add(_jumpButton('次ページ', Icons.arrow_downward, _scrollToNextPage));
      } else {
        jumpButtons.add(_jumpButton('最終ページ', Icons.vertical_align_bottom, _scrollToBottom));
      }
    } else if (edge == 'left') {
      if (!isAtTop) {
        jumpButtons.add(_jumpButton('前ページ', Icons.arrow_upward, _scrollToPrevPage));
      } else {
        jumpButtons.add(_jumpButton('トップページ', Icons.vertical_align_top, _scrollToTop));
      }
    } else if (edge == 'right') {
      if (!isAtBottom) {
        jumpButtons.add(_jumpButton('次ページ', Icons.arrow_downward, _scrollToNextPage));
      } else {
        jumpButtons.add(_jumpButton('最終ページ', Icons.vertical_align_bottom, _scrollToBottom));
      }
    }
    _jumpButtonOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 24,
        top: position.dy - 24,
        child: Material(
          color: Colors.transparent,
      child: Column(
            mainAxisSize: MainAxisSize.min,
            children: jumpButtons,
          ),
        ),
      ),
    );
    if (_scaffoldBodyContext != null) {
      final overlay = Overlay.of(_scaffoldBodyContext!, rootOverlay: true);
      if (overlay != null) {
        overlay.insert(_jumpButtonOverlay!);
        Future.delayed(const Duration(seconds: 2), () {
          if (_jumpButtonOverlay != null) {
            _jumpButtonOverlay!.remove();
            _jumpButtonOverlay = null;
          }
        });
      }
    }
  }

  Widget _jumpButton(String label, IconData icon, VoidCallback onPressed) {
    return FloatingActionButton.extended(
      heroTag: label + icon.toString(),
      onPressed: () {
        onPressed();
        if (_jumpButtonOverlay != null) {
          _jumpButtonOverlay!.remove();
          _jumpButtonOverlay = null;
        }
      },
      icon: Icon(icon),
      label: Text(label),
    );
  }

  void _scrollToPrevPage() {
    final newOffset = (_scrollController.offset - _scrollController.position.viewportDimension).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(newOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    if (_jumpButtonOverlay != null) {
      _jumpButtonOverlay!.remove();
      _jumpButtonOverlay = null;
    }
  }
  void _scrollToNextPage() {
    final newOffset = (_scrollController.offset + _scrollController.position.viewportDimension).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(newOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    if (_jumpButtonOverlay != null) {
      _jumpButtonOverlay!.remove();
      _jumpButtonOverlay = null;
    }
  }
  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    if (_jumpButtonOverlay != null) {
      _jumpButtonOverlay!.remove();
      _jumpButtonOverlay = null;
    }
  }
  void _scrollToBottom() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    if (_jumpButtonOverlay != null) {
      _jumpButtonOverlay!.remove();
      _jumpButtonOverlay = null;
    }
  }

  double calcCardHeight(int linkCount) {
    const double perLinkHeight = 36;
    const double minHeight = 120;
    const double maxHeight = 400;
    double dynamicHeight = minHeight + (linkCount * perLinkHeight);
    return dynamicHeight.clamp(minHeight, maxHeight);
  }

  Future<void> _exportMemoLinksToPdf(BuildContext context) async {
    final groups = ref.read(linkViewModelProvider).groups;
    final memoLinks = groups.expand((g) => g.items.map((l) => MapEntry(g, l)))
      .where((entry) => entry.value.memo?.isNotEmpty == true)
      .toList();
    if (memoLinks.isEmpty) {
      _showCenterMessage('メモ付きリンクがありません', icon: Icons.info, color: Colors.blueGrey);
      return;
    }
    // 日本語フォントを読み込む
    final fontData = await rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Change to landscape orientation
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'メモ付きリンク一覧',
              style: pw.TextStyle(font: ttf, fontSize: 24),
            ),
          ),
          pw.Table.fromTextArray(
            headers: [
              'グループ',
              'リンク名',
              'メモ内容',
            ],
            data: memoLinks.map((entry) => [
              entry.key.title,
              entry.value.label,
              entry.value.memo ?? '',
            ]).toList(),
            cellStyle: pw.TextStyle(font: ttf, fontSize: 12),
            headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 14),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            border: null,
          ),
        ],
      ),
    );
    final tempDir = Directory.systemTemp;
    final tempPreviewFileName = '${tempDir.path}/memo_links_preview.pdf';
    final tempFile = File(tempPreviewFileName);
    await tempFile.writeAsBytes(await pdf.save());

    // Display PDF content on screen with error handling
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDFプレビュー'),
          content: Container(
            width: MediaQuery.of(context).size.width * 1.0, // 80% of screen width
            height: MediaQuery.of(context).size.height * 1.0, // 80% of screen height
            child: pdfx.PdfView(
              controller: pdfx.PdfController(
                document: pdfx.PdfDocument.openFile(tempPreviewFileName),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final now = DateTime.now();
                final formatted = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
                final fileName = 'memo_links_$formatted.pdf';
                final output = File(fileName);
                await output.writeAsBytes(await pdf.save());
                _showCenterMessage('PDFを保存しました: ${output.absolute.path}', icon: Icons.check_circle, color: Colors.green[700]);
              },
              child: const Text('PDF出力'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error displaying PDF: $e');
      _showCenterMessage('PDFの表示に失敗しました', icon: Icons.error, color: Colors.red[700]);
    }
  }
}

// 追加: 共通カラーパレットWidget
class ColorPaletteSelector extends StatelessWidget {
  final int selectedColor;
  final void Function(int) onColorSelected;
  static const List<Color> palette = [
    Color(0xFF3B82F6), Color(0xFFEF4444), Color(0xFF22C55E), Color(0xFFF59E42),
    Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFEAB308), Color(0xFF06B6D4),
    Color(0xFF92400E), Color(0xFF64748B), Color(0xFF84CC16), Color(0xFF6366F1),
    Color(0xFF14B8A6), Color(0xFFFB923C), Color(0xFF7C3AED), Color(0xFFFBBF24),
    Color(0xFF0EA5E9), Color(0xFFB45309), Color(0xFFB91C1C), Color(0xFF166534),
  ];
  const ColorPaletteSelector({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: palette.map((color) {
        final displayColor = isDark ? color.withOpacity(0.85) : color;
        return GestureDetector(
          onTap: () => onColorSelected(color.value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: displayColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedColor == color.value ? Colors.black : Colors.transparent,
                width: 2,
              ),
              boxShadow: isDark
                ? [BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 4)]
                : [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 2)],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 追加: お気に入りリンク用タイルWidget
class FavoriteLinkTile extends StatefulWidget {
  final LinkItem link;
  final Group group;
  final VoidCallback onUnfavorite;
  final Future<void> Function() onLaunch;
  final bool isDark;
  final void Function(String, {IconData? icon, Color? color}) onShowMessage;
  final WidgetRef ref;
  const FavoriteLinkTile({
    super.key,
    required this.link,
    required this.group,
    required this.onUnfavorite,
    required this.onLaunch,
    required this.isDark,
    required this.onShowMessage,
    required this.ref,
  });
  @override
  State<FavoriteLinkTile> createState() => _FavoriteLinkTileState();
}
class _FavoriteLinkTileState extends State<FavoriteLinkTile> {
  bool isHovered = false;
  Color _getHighlightColor() {
    final isFavorite = widget.link.isFavorite;
    final hasMemo = widget.link.memo?.isNotEmpty == true;
    if (isFavorite && hasMemo) return Colors.green.withOpacity(0.18);
    if (hasMemo) return Colors.blue.withOpacity(0.18);
    if (isFavorite) return Colors.amber.withOpacity(0.18);
    return widget.isDark ? const Color(0xFF23272F) : Colors.white;
  }
  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.link.isFavorite;
    final hasMemo = widget.link.memo?.isNotEmpty == true;
    Color indicatorColor = Colors.transparent;
    if (isFavorite && hasMemo) {
      indicatorColor = Colors.green;
    } else if (hasMemo) {
      indicatorColor = Colors.blue;
    } else if (isFavorite) {
      indicatorColor = Colors.amber;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF23272F) : Colors.white,
          border: Border.all(
            color: widget.group.color != null ? Color(widget.group.color!) : Colors.blue,
            width: isHovered ? 6 : 3,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (isHovered)
              BoxShadow(
                color: (widget.group.color != null ? Color(widget.group.color!) : Colors.amber).withOpacity(0.5),
                blurRadius: 24,
                spreadRadius: 6,
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // サイドバーインジケータ
            Container(
              width: 10,
              height: 40,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            // メインテキスト＋サブテキスト
            Expanded(
      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                  Text(
                    widget.link.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isHovered)
                    ClipRect(
                      child: Text(
                        widget.link.path,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isDark ? Colors.white70 : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
            // アイコン群
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Tooltip(
                      message: widget.link.memo?.isNotEmpty == true ? widget.link.memo! : 'メモなし',
                      child: IconButton(
                        icon: Icon(
                          Icons.note_alt_outlined,
                          color: widget.link.memo?.isNotEmpty == true ? Colors.orange : Colors.grey,
                        ),
                        tooltip: null, // Tooltipは外側で管理
                        onPressed: () async {
                          final controller = TextEditingController(text: widget.link.memo ?? '');
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('メモ編集'),
                              content: TextField(
                                controller: controller,
                                maxLines: 5,
                                decoration: const InputDecoration(hintText: 'メモを入力...'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('キャンセル'),
                                ),
          ElevatedButton(
                                  onPressed: () => Navigator.pop(context, controller.text),
                                  child: const Text('保存'),
          ),
        ],
      ),
                          );
                          if (result != null) {
                            final updated = widget.link.copyWith(memo: result);
                            widget.ref.read(linkViewModelProvider.notifier).updateLinkInGroup(
                              groupId: widget.group.id,
                              updated: updated,
                            );
                          }
                        },
                      ),
                    ),
                    if (widget.link.memo?.isNotEmpty == true)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    widget.link.isFavorite ? Icons.star : Icons.star_border,
                    color: widget.link.isFavorite ? Colors.amber : Colors.grey,
                  ),
                  tooltip: widget.link.isFavorite ? 'お気に入り解除' : 'お気に入り',
                  onPressed: () => widget.onUnfavorite(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Link',
                  onPressed: () => widget.onShowMessage('削除機能はここで実装', icon: Icons.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 追加: URLプレビューWidget
class UrlPreviewWidget extends StatefulWidget {
  final String url;
  final bool isDark;
  const UrlPreviewWidget({super.key, required this.url, required this.isDark});
  @override
  State<UrlPreviewWidget> createState() => _UrlPreviewWidgetState();
}
class _UrlPreviewWidgetState extends State<UrlPreviewWidget> {
  String? _title;
  String? _faviconUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    final url = widget.url;
    // favicon取得（Googleのサービス利用）
    final favicon = 'https://www.google.com/s2/favicons?sz=32&domain_url=$url';
    String? title;
    try {
      final uri = Uri.parse(url);
      final response = await Uri.base.resolve(url).isAbsolute
        ? await Uri.parse(url).resolve('').toString() == url ? null : null
        : null;
      // タイトル取得は簡易的に省略（本格実装はhttpパッケージでHTML取得＆<title>抽出）
      // ここではURLのホスト名をタイトル代わりに表示
      title = uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      title = url;
    }
    setState(() {
      _faviconUrl = favicon;
      _title = title;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_faviconUrl != null)
          Image.network(
            _faviconUrl!,
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => _getFallbackIconForUrl(widget.url)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            _title ?? widget.url,
            style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.white : Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _getFallbackIconForUrl(String url) {
    if (url.contains('sharepoint.com')) {
      return FaIcon(FontAwesomeIcons.microsoft, color: Colors.blue, size: 20);
    }
    if (url.contains('resonabank.co.jp')) {
      return Icon(Icons.account_balance, color: Colors.green, size: 20);
    }
    // その他はデフォルト
    return Icon(Icons.link, size: 20);
  }
}

// 追加: ファイルプレビューWidget
class FilePreviewWidget extends StatefulWidget {
  final String path;
  final bool isDark;
  const FilePreviewWidget({super.key, required this.path, required this.isDark});
  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}
class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  String? _textPreview;
  List<String>? _textFull;
  bool _isImage = false;
  bool _isPdf = false;
  bool _loading = true;
  OverlayEntry? _previewOverlay;

  @override
  void dispose() {
    _removePreviewOverlay();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _detectAndLoad();
  }

  Future<void> _detectAndLoad() async {
    final ext = widget.path.toLowerCase();
    if (ext.endsWith('.png') || ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.gif') || ext.endsWith('.bmp') || ext.endsWith('.webp')) {
      setState(() {
        _isImage = true;
        _loading = false;
      });
      return;
    }
    if (ext.endsWith('.pdf')) {
      setState(() {
        _isPdf = true;
        _loading = false;
      });
      return;
    }
    // テキストファイル判定
    if (ext.endsWith('.txt') || ext.endsWith('.md') || ext.endsWith('.csv') || ext.endsWith('.log')) {
      try {
        final file = File(widget.path);
        final lines = await file.readAsLines();
        setState(() {
          _textPreview = lines.take(3).join('\n');
          _textFull = lines;
          _loading = false;
        });
      } catch (e, st) {
        print('テキストファイル読み込みエラー: $e\n$st');
        setState(() {
          _textPreview = null;
          _textFull = null;
          _loading = false;
        });
      }
      return;
    }
    // その他
    setState(() {
      _loading = false;
    });
  }

  void _showPreviewOverlay(Widget child, {double width = 480, double height = 400}) {
    _removePreviewOverlay();
    final overlay = Overlay.of(context);
    _previewOverlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Container(
            alignment: Alignment.center,
            color: Colors.black.withOpacity(0.25),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: width,
                height: height,
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_previewOverlay!);
  }

  void _removePreviewOverlay() {
    _previewOverlay?.remove();
    _previewOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_isImage) {
      return MouseRegion(
        onEnter: (_) => _showPreviewOverlay(
          InteractiveViewer(child: Image.file(File(widget.path))),
          width: 480, height: 400,
        ),
        onExit: (_) => _removePreviewOverlay(),
        child: Image.file(File(widget.path), width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 24)),
      );
    }
    if (_isPdf) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
          IconButton(
            icon: Icon(Icons.open_in_new, size: 20, color: Colors.blue),
            tooltip: '外部アプリで開く',
            onPressed: () async {
              try {
                await Process.start('cmd', ['/c', 'start', '', widget.path]);
              } catch (e) {
                print('PDF外部起動エラー: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('外部アプリで開けませんでした')),
                  );
                }
              }
            },
          ),
        ],
      );
    }
    if (_textPreview != null) {
      final isEmpty = (_textFull == null || _textFull!.isEmpty || (_textFull!.length == 1 && _textFull![0].trim().isEmpty));
      return MouseRegion(
        onEnter: (_) => _showPreviewOverlay(
          Container(
            color: Colors.black.withOpacity(0.95),
            child: isEmpty
              ? const Center(child: Text('内容がありません', style: TextStyle(color: Colors.white, fontSize: 18)))
              : SingleChildScrollView(
                  child: SelectableText(
                    _textFull?.join('\n') ?? '',
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontFamily: 'monospace'),
                  ),
                ),
          ),
          width: 520, height: 420,
        ),
        onExit: (_) => _removePreviewOverlay(),
        child: Tooltip(
          message: isEmpty ? '内容がありません' : _textPreview!,
          child: Icon(Icons.description, color: widget.isDark ? Colors.white70 : Colors.blueGrey, size: 24),
        ),
      );
    }
    // Office系ファイルのアイコン表示（FontAwesome使用）
    final ext = widget.path.toLowerCase();
    if (ext.endsWith('.xlsx') || ext.endsWith('.xls')) {
      return FaIcon(FontAwesomeIcons.fileExcel, color: Colors.green[700], size: 24); // Excel
    }
    if (ext.endsWith('.docx') || ext.endsWith('.doc')) {
      return FaIcon(FontAwesomeIcons.fileWord, color: Colors.blue[700], size: 24); // Word
    }
    if (ext.endsWith('.pptx') || ext.endsWith('.ppt')) {
      return FaIcon(FontAwesomeIcons.filePowerpoint, color: Colors.orange[700], size: 24); // PowerPoint
    }
    if (ext.endsWith('.msg') || ext.endsWith('.eml')) {
      return FaIcon(FontAwesomeIcons.envelope, color: Colors.blue[800], size: 24);
    }
    // その他
    return Icon(Icons.insert_drive_file, color: widget.isDark ? Colors.white70 : Colors.grey, size: 24);
  }
}

// --- カスタムFABロケーション ---
class _BottomRightWithMarginFabLocation extends FloatingActionButtonLocation {
  const _BottomRightWithMarginFabLocation();
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    const double bottomMargin = 64; // タスクバー分
    final double fabX = scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width - 16;
    final double fabY = scaffoldGeometry.scaffoldSize.height - scaffoldGeometry.floatingActionButtonSize.height - bottomMargin;
    return Offset(fabX, fabY);
  }
} 