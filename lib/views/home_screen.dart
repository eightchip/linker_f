import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../viewmodels/link_viewmodel.dart';
import '../viewmodels/font_size_provider.dart';
import '../models/group.dart';
import '../models/link_item.dart';
import 'group_card.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfx/pdfx.dart' as pdfx;

// ハイライト用のウィジェット
class HighlightedText extends StatelessWidget {
  final String text;
  final String? highlight;
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;

  const HighlightedText({
    Key? key,
    required this.text,
    this.highlight,
    this.style,
    this.overflow,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (highlight == null || highlight!.isEmpty) {
      return Text(
        text,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    final highlightLower = highlight!.toLowerCase();
    final textLower = text.toLowerCase();
    final matches = <_TextMatch>[];

    int start = 0;
    while (start < textLower.length) {
      final index = textLower.indexOf(highlightLower, start);
      if (index == -1) break;
      matches.add(_TextMatch(index, index + highlightLower.length));
      start = index + 1;
    }

    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final match in matches) {
      if (currentIndex < match.start) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: style,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style?.copyWith(
          backgroundColor: Colors.red.withValues(alpha: 0.75),
          fontWeight: FontWeight.bold,
        ),
      ));
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: overflow ?? TextOverflow.clip,
      maxLines: maxLines,
    );
  }
}

class _TextMatch {
  final int start;
  final int end;
  _TextMatch(this.start, this.end);
}

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
  bool _showSearchBar = true;
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
  
  // 追加: カスタムアイコン情報管理
  int? _pendingIconData;
  int? _pendingIconColor;

  // ショートカットキー用のFocusNode
  final FocusNode _shortcutFocusNode = FocusNode();
  // 検索バー用のFocusNode
  final FocusNode _searchFocusNode = FocusNode();

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
    _shortcutFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ショートカットキー処理
  void _handleShortcut(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      
      // Ctrl+N: 新しいグループを作成
      if (key == LogicalKeyboardKey.keyN && isControlPressed) {
        _showAddGroupDialog(context);
      }
      // Ctrl+L: 新しいリンクを追加
      else if (key == LogicalKeyboardKey.keyL && isControlPressed) {
        _showAddLinkDialogShortcut(context);
      }
      // Ctrl+F: 検索にフォーカス（検索バーを開く）
      else if (key == LogicalKeyboardKey.keyF && isControlPressed) {
        setState(() {
          _showSearchBar = true;
        });
        // 検索バーが表示された後にフォーカスを設定
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
      // Ctrl+Shift+E: データをエクスポート
      else if (key == LogicalKeyboardKey.keyE && isControlPressed && isShiftPressed) {
        _exportData(context);
      }
      // Ctrl+Shift+I: データをインポート
      else if (key == LogicalKeyboardKey.keyI && isControlPressed && isShiftPressed) {
        _importData(context);
      }
      // F1: ヘルプを表示
      else if (key == LogicalKeyboardKey.f1) {
        _showShortcutHelp(context);
      }
      // Escape: 検索を閉じる
      else if (key == LogicalKeyboardKey.escape) {
        setState(() {
          _showSearchBar = false;
          _searchQuery = '';
        });
      }
    }
  }

  // ショートカットアクション実装
  void _showAddLinkDialogShortcut(BuildContext context) {
    // 既存のリンク追加ロジックを使用
    // 最初のグループを選択してダイアログを表示
    final groups = ref.read(linkViewModelProvider).groups;
    if (groups.isNotEmpty) {
      _showAddLinkDialog(context, groups.first.id);
    }
  }



  // ショートカットヘルプダイアログ
  void _showShortcutHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('キーボードショートカット'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView(
            children: const [
              _ShortcutItem('Ctrl+N', '新しいグループを作成'),
              _ShortcutItem('Ctrl+L', '新しいリンクを追加'),
              _ShortcutItem('Ctrl+F', '検索バーを開く'),
              _ShortcutItem('Escape', '検索バーを閉じる'),
              _ShortcutItem('Ctrl+Shift+E', 'データをエクスポート'),
              _ShortcutItem('Ctrl+Shift+I', 'データをインポート'),
              _ShortcutItem('F1', 'このヘルプを表示'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
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
          g.items.any((l) {
            // ラベルでの検索
            if (l.label.toLowerCase().contains(_searchQuery.toLowerCase())) {
              return true;
            }
            // URLリンクの場合、ドメイン名でも検索
            if (l.type == LinkType.url) {
              final domain = _extractDomain(l.path);
              if (domain.toLowerCase().contains(_searchQuery.toLowerCase())) {
                return true;
              }
            }
            return false;
          }))
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
    
    return KeyboardListener(
      focusNode: _shortcutFocusNode,
      onKeyEvent: _handleShortcut,
      autofocus: true,
      child: Listener(
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
                IconButton(
                  icon: Icon(Icons.add, size: iconSize), 
                  tooltip: 'グループを追加 (Ctrl+N)', 
                  onPressed: () => _showAddGroupDialog(context)
                ),
                IconButton(
                  icon: Icon(Icons.search, size: iconSize), 
                  tooltip: '検索 (Ctrl+F)', 
                  onPressed: () {
                    setState(() {
                      _showSearchBar = !_showSearchBar;
                      if (!_showSearchBar) _searchQuery = '';
                    });
                  }
                ),
                // ショートカットヘルプボタンを追加
                IconButton(
                  icon: const Icon(Icons.keyboard),
                  tooltip: 'ショートカットキー (F1)',
                  onPressed: () => _showShortcutHelp(context),
                ),
                IconButton(icon: Icon(Icons.notes, size: iconSize), tooltip: 'メモ一括編集', onPressed: () {
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
                          title: const Text('メモ一括編集'),
                          content: SizedBox(
                            width: 1000,
                            height: 1000,
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
                                                    color: Color(accentColor).withValues(alpha: isDark ? 0.7 : 0.5),
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
                // お気に入り（★）とPDF（📄）アイコンを非表示にしました
                IconButton(icon: Icon(Icons.push_pin, color: _showRecent ? Colors.amber : Colors.grey, size: iconSize), tooltip: _showRecent ? '最近使った非表示' : '最近使ったリンクを上部に表示', onPressed: () {
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
                IconButton(icon: Icon(Icons.upload, size: iconSize), tooltip: '設定をエキスポート', onPressed: () => _exportData(context)),
                IconButton(icon: Icon(Icons.download, size: iconSize), tooltip: '設定をインポート', onPressed: () => _importData(context)),
                // お気に入りアイコンを削除
                // if (favoriteGroups.isNotEmpty)
                //   IconButton(icon: Icon(_showOnlyFavorites ? Icons.star : Icons.star_border, color: _showOnlyFavorites ? Colors.amber : Colors.grey, size: iconSize), tooltip: _showOnlyFavorites ? 'すべて表示' : 'グループのお気に入りのみ表示', onPressed: () {
                //       setState(() {
                //         _showOnlyFavorites = !_showOnlyFavorites;
                //       });
                //         }),
                // チュートリアルアイコンを削除
                // IconButton(icon: Icon(Icons.help_outline, size: iconSize), tooltip: 'チュートリアル・ヘルプ', onPressed: _showTutorial),
              ],
              bottom: _showSearchBar
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(44),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                         child: TextField(
                           focusNode: _searchFocusNode,
                           keyboardType: TextInputType.text,
                           textInputAction: TextInputAction.search,
                           decoration: InputDecoration(
                             hintText: '検索（ファイル名・フォルダ名・URL）',
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
                            backgroundColor: Color(accentColor).withValues(alpha: 0.85),
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
                            backgroundColor: Color(accentColor).withValues(alpha: 0.85),
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
                            searchQuery: _searchQuery,
                            onToggleCollapse: () => ref.read(linkViewModelProvider.notifier).toggleGroupCollapse(group.id),
                            onDeleteGroup: () => _deleteGroup(group.id),
                            onAddLink: () => _showAddLinkDialog(context, group.id),
                            onDeleteLink: (linkId) => ref.read(linkViewModelProvider.notifier).removeLinkFromGroup(group.id, linkId),
                            onLaunchLink: (link) => ref.read(linkViewModelProvider.notifier).launchLink(link),
                            onDropAddLink: (label, path, type) async {
                              // Windows APIを使ってカスタムアイコンを自動取得するため、
                              // アイコン選択ダイアログは表示しない
                              await ref.read(linkViewModelProvider.notifier).addLinkToGroup(
                                groupId: group.id,
                                label: label,
                                path: path,
                                type: type,
                              );
                            },
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
                          searchQuery: _searchQuery,
                          isDragging: true,
                          onToggleCollapse: () => ref.read(linkViewModelProvider.notifier).toggleGroupCollapse(group.id),
                          onDeleteGroup: () => _deleteGroup(group.id),
                          onAddLink: () => _showAddLinkDialog(context, group.id),
                          onDeleteLink: (linkId) => ref.read(linkViewModelProvider.notifier).removeLinkFromGroup(group.id, linkId),
                          onLaunchLink: (link) => ref.read(linkViewModelProvider.notifier).launchLink(link),
                          onDropAddLink: (label, path, type) async {
                            // Windows APIを使ってカスタムアイコンを自動取得するため、
                            // アイコン選択ダイアログは表示しない
                            await ref.read(linkViewModelProvider.notifier).addLinkToGroup(
                              groupId: group.id,
                              label: label,
                              path: path,
                              type: type,
                            );
                          },
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
                            searchQuery: _searchQuery,
                            onToggleCollapse: () => ref.read(linkViewModelProvider.notifier).toggleGroupCollapse(group.id),
                            onDeleteGroup: () => _deleteGroup(group.id),
                            onAddLink: () => _showAddLinkDialog(context, group.id),
                            onDeleteLink: (linkId) => ref.read(linkViewModelProvider.notifier).removeLinkFromGroup(group.id, linkId),
                            onLaunchLink: (link) => ref.read(linkViewModelProvider.notifier).launchLink(link),
                            onDropAddLink: (label, path, type) async {
                              // Windows APIを使ってカスタムアイコンを自動取得するため、
                              // アイコン選択ダイアログは表示しない
                              await ref.read(linkViewModelProvider.notifier).addLinkToGroup(
                                groupId: group.id,
                                label: label,
                                path: path,
                                type: type,
                              );
                            },
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
            color: Colors.black.withValues(alpha: 0.25),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                decoration: BoxDecoration(
                  color: color ?? Colors.black.withValues(alpha: 0.85),
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
    // メモを含めるかどうかの選択ダイアログ
    final includeMemos = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エクスポート設定'),
        content: const Text('メモを含めてエクスポートしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('含めない'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('含める'),
          ),
        ],
      ),
    );
    
    if (includeMemos == null) return; // キャンセルされた場合
    
    final darkMode = ref.read(darkModeProvider);
    final fontSize = ref.read(fontSizeProvider);
    final accentColor = ref.read(accentColorProvider);
    
    // メモ除外オプションを使用してエクスポート
    final data = ref.read(linkViewModelProvider.notifier).exportDataWithSettings(
      darkMode, 
      fontSize, 
      accentColor,
      excludeMemos: !includeMemos,
    );
    
    final jsonStr = jsonEncode(data);
    final now = DateTime.now();
    final formatted = DateFormat('yyMMddHHmm').format(now);
    final memoText = includeMemos ? 'メモあり' : 'メモなし';
    final file = File('linker_f_export_${memoText}_$formatted.json');
    await file.writeAsString(jsonStr);
    
    // 画面中央にエクスポート完了メッセージを表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('エクスポート完了'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('エクスポートしました:'),
            SizedBox(height: 8),
            Text(
              file.absolute.path,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                backgroundColor: Colors.grey[100],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await Process.run('explorer', ['/select,', file.absolute.path]);
              } catch (e) {
                print('フォルダを開くエラー: $e');
              }
              Navigator.pop(context);
            },
            icon: Icon(Icons.folder_open),
            label: Text('フォルダを開く'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _importData(BuildContext context) async {
    try {
      // デフォルトのエクスポートフォルダを初期位置に設定
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: Directory.current.path, // 現在のディレクトリを初期位置に
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
        
        // SnackBarで通知
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('リンクをインポートしました: ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('インポートエラー: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
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
    // チュートリアル表示を削除
    // final shown = box.get('tutorial_shown', defaultValue: false);
    // if (!shown) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     showDialog(
    //       context: context,
    //       barrierDismissible: false,
    //       builder: (context) => TutorialDialog(
    //         onFinish: () async {
    //           await box.put('tutorial_shown', true);
    //           setState(() => _tutorialShown = true);
    //         },
    //       ),
    //     );
    //   });
    // } else {
    //   setState(() => _tutorialShown = true);
    // }
    setState(() => _tutorialShown = true);
  }

  // チュートリアルメソッドを削除
  // void _showTutorial() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => TutorialDialog(),
  //   );
  // }

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
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF45B7D1), Color(0xFF96CEB4),
    Color(0xFFFFEAA7), Color(0xFFDDA0DD), Color(0xFF98D8C8), Color(0xFFF7DC6F),
    Color(0xFFBB8FCE), Color(0xFF85C1E9), Color(0xFFF8C471), Color(0xFFF1948A),
    Color(0xFF82E0AA), Color(0xFFD7BDE2), Color(0xFFA9CCE3), Color(0xFFFAD7A0),
    Color(0xFFF5B7B1), Color(0xFFA9DFBF), Color(0xFFF9E79F), Color(0xFFD2B4DE),
    Color(0xFFAED6F1),
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
        final displayColor = isDark ? color.withValues(alpha: 0.85) : color;
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
                ? [BoxShadow(color: Colors.white.withValues(alpha: 0.15), blurRadius: 4)]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 2)],
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
    if (isFavorite && hasMemo) return Colors.green.withValues(alpha: 0.18);
    if (hasMemo) return Colors.blue.withValues(alpha: 0.18);
    if (isFavorite) return Colors.amber.withValues(alpha: 0.18);
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
                color: (widget.group.color != null ? Color(widget.group.color!) : Colors.amber).withValues(alpha: 0.5),
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
                      message: widget.link.memo?.isNotEmpty == true ? widget.link.memo! : '',
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
                // お気に入りアイコンを削除
                // IconButton(
                //   icon: Icon(
                //     widget.link.isFavorite ? Icons.star : Icons.star_border,
                //     color: widget.link.isFavorite ? Colors.amber : Colors.grey,
                //   ),
                //   tooltip: widget.link.isFavorite ? 'お気に入り解除' : 'お気に入り',
                //   onPressed: () => widget.onUnfavorite(),
                // ),
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
  final String? searchQuery;
  const UrlPreviewWidget({super.key, required this.url, required this.isDark, this.searchQuery});
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
        _faviconUrl != null
          ? Image.network(
              _faviconUrl!,
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) => _getFallbackIconForUrl(widget.url))
          : _getFallbackIconForUrl(widget.url),
        const SizedBox(width: 4),
        Flexible(
          child: HighlightedText(
            text: _title ?? widget.url,
            highlight: widget.searchQuery,
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
    if (url.contains('u-next.jp') || url.contains('unext.jp')) {
      return Icon(Icons.play_circle_filled, color: Colors.red, size: 20);
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
            color: Colors.black.withValues(alpha: 0.25),
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
      return GestureDetector(
        onTap: () async {
          try {
            final file = File(widget.path);
            final absolutePath = file.absolute.path;
            await Process.run('cmd', ['/c', 'start', absolutePath], runInShell: true);
          } catch (e) {
            print('PDF外部起動エラー: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('外部アプリで開けませんでした')),
              );
            }
          }
        },
        child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
      );
    }
    if (_textPreview != null) {
      final isEmpty = (_textFull == null || _textFull!.isEmpty || (_textFull!.length == 1 && _textFull![0].trim().isEmpty));
      return MouseRegion(
        onEnter: (_) => _showPreviewOverlay(
          Container(
            color: Colors.black.withValues(alpha: 0.95),
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

// URLからドメイン名を抽出するヘルパーメソッド
String _extractDomain(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host;
  } catch (e) {
    // URLの形式が不正な場合、元のパスを返す
    return url;
  }
}

// アイコン選択ウィジェット
class IconSelector extends StatefulWidget {
  final IconData selectedIcon;
  final Color selectedIconColor;
  final Function(IconData, Color) onIconSelected;

  const IconSelector({
    Key? key,
    required this.selectedIcon,
    required this.selectedIconColor,
    required this.onIconSelected,
  }) : super(key: key);

  @override
  State<IconSelector> createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector> {
  late IconData _selectedIcon;
  late Color _selectedIconColor;

  @override
  void initState() {
    super.initState();
    print('IconSelector初期化: selectedIcon.codePoint=${widget.selectedIcon.codePoint}, selectedIcon.fontFamily=${widget.selectedIcon.fontFamily}');
    print('初期化時のアイコンが地球アイコンかチェック: ${widget.selectedIcon.codePoint == Icons.public.codePoint}');
    print('初期化時のアイコンがフォルダアイコンかチェック: ${widget.selectedIcon.codePoint == Icons.folder.codePoint}');
    _selectedIcon = widget.selectedIcon;
    _selectedIconColor = widget.selectedIconColor;
  }

  @override
  void didUpdateWidget(IconSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIcon != widget.selectedIcon) {
      _selectedIcon = widget.selectedIcon;
    }
    if (oldWidget.selectedIconColor != widget.selectedIconColor) {
      _selectedIconColor = widget.selectedIconColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 現在選択されているアイコン
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildIconWidget(_selectedIcon, _selectedIconColor, size: 32),
        ),
        const SizedBox(height: 8),
        // アイコン選択ボタン
        ElevatedButton(
          onPressed: () => _showIconPicker(),
          child: const Text('アイコンと色を選択'),
        ),
      ],
    );
  }

  void _showIconPicker() {
    bool useWindowsIcons = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('アイコンと色を選択'),
          content: SizedBox(
            width: 500,
            height: 600,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // アイコンタイプ選択タブ（Material Iconsに統一）
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.folder, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Material Icons',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // アイコン選択セクション
                  Text(
                    'フォルダアイコンを選択:',
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        childAspectRatio: 1,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: _folderIcons.length,
                      itemBuilder: (context, index) {
                        final iconData = _folderIcons[index];
                        final isSelected = iconData.codePoint == _selectedIcon.codePoint;
                        return Tooltip(
                          message: _getIconTooltip(iconData),
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                _selectedIcon = iconData;
                              });
                              setState(() {
                                _selectedIcon = iconData;
                              });
                              // Font Awesomeアイコンの場合はブランドカラーを保持
                              Color iconColor = _selectedIconColor;
                              if (iconData.fontFamily == 'FontAwesomeSolid' || 
                                  iconData.fontFamily == 'FontAwesomeRegular' || 
                                  iconData.fontFamily == 'FontAwesomeBrands') {
                                // Font Awesomeアイコンの場合は、ブランドカラーを取得
                                iconColor = _getBrandColor(iconData);
                              }
                              // 即座に親ウィジェットに反映
                              widget.onIconSelected(_selectedIcon, iconColor);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _buildIconWidget(iconData, _selectedIconColor),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 色選択セクション
                  const Text('色を選択:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ColorPaletteSelector(
                    selectedColor: _selectedIconColor.value,
                    onColorSelected: (colorValue) {
                      setDialogState(() {
                        _selectedIconColor = Color(colorValue);
                      });
                      setState(() {
                        _selectedIconColor = Color(colorValue);
                      });
                      // 即座に親ウィジェットに反映
                      widget.onIconSelected(_selectedIcon, _selectedIconColor);
                    },
                  ),
                  const SizedBox(height: 16),
                  // プレビュー
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('プレビュー:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildIconWidget(_selectedIcon, _selectedIconColor, size: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onIconSelected(_selectedIcon, _selectedIconColor);
                Navigator.pop(context);
              },
              child: const Text('決定'),
            ),
          ],
        ),
      ),
    );
  }

  // カラフルアイコンウィジェットを構築
  Widget _buildIconWidget(IconData iconData, Color color, {double size = 20}) {
    // Font Awesomeアイコンの場合はブランドカラーを適用
    if (iconData.fontFamily == 'FontAwesomeSolid' || 
        iconData.fontFamily == 'FontAwesomeRegular' || 
        iconData.fontFamily == 'FontAwesomeBrands') {
      return _buildBrandIcon(iconData, size: size);
    }
    // Material Iconsの場合は指定された色を使用
    return Icon(iconData, color: color, size: size);
  }

  // ブランドカラーを取得するメソッド
  Color _getBrandColor(IconData iconData) {
    // ブランドカラーの定義
    if (iconData.codePoint == FontAwesomeIcons.google.codePoint) {
      return const Color(0xFF4285F4); // Google Blue
    } else if (iconData.codePoint == FontAwesomeIcons.github.codePoint) {
      return const Color(0xFF181717); // GitHub Black
    } else if (iconData.codePoint == FontAwesomeIcons.youtube.codePoint) {
      return const Color(0xFFFF0000); // YouTube Red
    } else if (iconData.codePoint == FontAwesomeIcons.twitter.codePoint) {
      return const Color(0xFF1DA1F2); // Twitter Blue
    } else if (iconData.codePoint == FontAwesomeIcons.facebook.codePoint) {
      return const Color(0xFF1877F2); // Facebook Blue
    } else if (iconData.codePoint == FontAwesomeIcons.instagram.codePoint) {
      return const Color(0xFFE4405F); // Instagram Pink
    } else if (iconData.codePoint == FontAwesomeIcons.linkedin.codePoint) {
      return const Color(0xFF0A66C2); // LinkedIn Blue
    } else if (iconData.codePoint == FontAwesomeIcons.discord.codePoint) {
      return const Color(0xFF5865F2); // Discord Blue
    } else if (iconData.codePoint == FontAwesomeIcons.slack.codePoint) {
      return const Color(0xFF4A154B); // Slack Purple
    } else if (iconData.codePoint == FontAwesomeIcons.spotify.codePoint) {
      return const Color(0xFF1DB954); // Spotify Green
    } else if (iconData.codePoint == FontAwesomeIcons.amazon.codePoint) {
      return const Color(0xFFFF9900); // Amazon Orange
    } else if (iconData.codePoint == FontAwesomeIcons.apple.codePoint) {
      return const Color(0xFF000000); // Apple Black
    } else if (iconData.codePoint == FontAwesomeIcons.microsoft.codePoint) {
      return const Color(0xFF00A4EF); // Microsoft Blue
    } else if (iconData.codePoint == FontAwesomeIcons.chrome.codePoint) {
      return const Color(0xFF4285F4); // Chrome Blue
    } else if (iconData.codePoint == FontAwesomeIcons.firefox.codePoint) {
      return const Color(0xFFFF7139); // Firefox Orange
    } else if (iconData.codePoint == FontAwesomeIcons.safari.codePoint) {
      return const Color(0xFF006CFF); // Safari Blue
    } else if (iconData.codePoint == FontAwesomeIcons.edge.codePoint) {
      return const Color(0xFF0078D4); // Edge Blue
    } else if (iconData.codePoint == FontAwesomeIcons.opera.codePoint) {
      return const Color(0xFFFF1B2D); // Opera Red
    } else if (iconData.codePoint == FontAwesomeIcons.steam.codePoint) {
      return const Color(0xFF00ADE6); // Steam Blue
    } else if (iconData.codePoint == FontAwesomeIcons.reddit.codePoint) {
      return const Color(0xFFFF4500); // Reddit Orange
    } else if (iconData.codePoint == FontAwesomeIcons.stackOverflow.codePoint) {
      return const Color(0xFFF58025); // Stack Overflow Orange
    } else if (iconData.codePoint == FontAwesomeIcons.gitlab.codePoint) {
      return const Color(0xFFFCA326); // GitLab Orange
    } else if (iconData.codePoint == FontAwesomeIcons.bitbucket.codePoint) {
      return const Color(0xFF0052CC); // Bitbucket Blue
    } else if (iconData.codePoint == FontAwesomeIcons.docker.codePoint) {
      return const Color(0xFF2496ED); // Docker Blue
    } else if (iconData.codePoint == FontAwesomeIcons.aws.codePoint) {
      return const Color(0xFFFF9900); // AWS Orange
    } else if (iconData.codePoint == FontAwesomeIcons.wordpress.codePoint) {
      return const Color(0xFF21759B); // WordPress Blue
    } else if (iconData.codePoint == FontAwesomeIcons.shopify.codePoint) {
      return const Color(0xFF7AB55C); // Shopify Green
    } else if (iconData.codePoint == FontAwesomeIcons.stripe.codePoint) {
      return const Color(0xFF6772E5); // Stripe Purple
    } else if (iconData.codePoint == FontAwesomeIcons.paypal.codePoint) {
      return const Color(0xFF003087); // PayPal Blue
    } else if (iconData.codePoint == FontAwesomeIcons.bitcoin.codePoint) {
      return const Color(0xFFF7931A); // Bitcoin Orange
    } else if (iconData.codePoint == FontAwesomeIcons.ethereum.codePoint) {
      return const Color(0xFF627EEA); // Ethereum Blue
    } else if (iconData.codePoint == FontAwesomeIcons.telegram.codePoint) {
      return const Color(0xFF0088CC); // Telegram Blue
    } else if (iconData.codePoint == FontAwesomeIcons.whatsapp.codePoint) {
      return const Color(0xFF25D366); // WhatsApp Green
    } else if (iconData.codePoint == FontAwesomeIcons.skype.codePoint) {
      return const Color(0xFF00AFF0); // Skype Blue
    } else if (iconData.codePoint == FontAwesomeIcons.dropbox.codePoint) {
      return const Color(0xFF0061FF); // Dropbox Blue
    } else if (iconData.codePoint == FontAwesomeIcons.box.codePoint) {
      return const Color(0xFF0061D5); // Box Blue
    } else if (iconData.codePoint == FontAwesomeIcons.figma.codePoint) {
      return const Color(0xFFF24E1E); // Figma Orange
    } else if (iconData.codePoint == FontAwesomeIcons.blender.codePoint) {
      return const Color(0xFFF5792A); // Blender Orange
    } else if (iconData.codePoint == FontAwesomeIcons.python.codePoint) {
      return const Color(0xFF3776AB); // Python Blue
    } else if (iconData.codePoint == FontAwesomeIcons.react.codePoint) {
      return const Color(0xFF61DAFB); // React Blue
    } else if (iconData.codePoint == FontAwesomeIcons.angular.codePoint) {
      return const Color(0xFFDD0031); // Angular Red
    } else if (iconData.codePoint == FontAwesomeIcons.flutter.codePoint) {
      return const Color(0xFF02569B); // Flutter Blue
    } else if (iconData.codePoint == FontAwesomeIcons.bootstrap.codePoint) {
      return const Color(0xFF7952B3); // Bootstrap Purple
    } else if (iconData.codePoint == FontAwesomeIcons.node.codePoint) {
      return const Color(0xFF339933); // Node.js Green
    } else if (iconData.codePoint == FontAwesomeIcons.npm.codePoint) {
      return const Color(0xFFCB3837); // npm Red
    } else if (iconData.codePoint == FontAwesomeIcons.yarn.codePoint) {
      return const Color(0xFF2C8EBB); // Yarn Blue
    } else if (iconData.codePoint == FontAwesomeIcons.git.codePoint) {
      return const Color(0xFFF05032); // Git Orange
    } else if (iconData.codePoint == FontAwesomeIcons.linux.codePoint) {
      return const Color(0xFFFCC624); // Linux Yellow
    } else if (iconData.codePoint == FontAwesomeIcons.windows.codePoint) {
      return const Color(0xFF0078D4); // Windows Blue
    } else if (iconData.codePoint == FontAwesomeIcons.android.codePoint) {
      return const Color(0xFF3DDC84); // Android Green
    } else if (iconData.codePoint == FontAwesomeIcons.html5.codePoint) {
      return const Color(0xFFE34F26); // HTML5 Orange
    } else if (iconData.codePoint == FontAwesomeIcons.css3.codePoint) {
      return const Color(0xFF1572B6); // CSS3 Blue
    } else if (iconData.codePoint == FontAwesomeIcons.js.codePoint) {
      return const Color(0xFFF7DF1E); // JavaScript Yellow
    } else if (iconData.codePoint == FontAwesomeIcons.php.codePoint) {
      return const Color(0xFF777BB4); // PHP Purple
    } else if (iconData.codePoint == FontAwesomeIcons.java.codePoint) {
      return const Color(0xFFED8B00); // Java Orange
    } else if (iconData.codePoint == FontAwesomeIcons.c.codePoint) {
      return const Color(0xFFA8B9CC); // C Gray
    } else if (iconData.codePoint == FontAwesomeIcons.swift.codePoint) {
      return const Color(0xFFFA7343); // Swift Orange
    } else if (iconData.codePoint == FontAwesomeIcons.r.codePoint) {
      return const Color(0xFF276DC3); // R Blue
    } else if (iconData.codePoint == FontAwesomeIcons.salesforce.codePoint) {
      return const Color(0xFF00A1E0); // Salesforce Blue
    } else if (iconData.codePoint == FontAwesomeIcons.hubspot.codePoint) {
      return const Color(0xFFFF7A59); // HubSpot Orange
    } else if (iconData.codePoint == FontAwesomeIcons.mailchimp.codePoint) {
      return const Color(0xFFFFE01B); // Mailchimp Yellow
    } else if (iconData.codePoint == FontAwesomeIcons.trello.codePoint) {
      return const Color(0xFF0079BF); // Trello Blue
    }
    
    return Colors.grey; // デフォルト色
  }

  // ブランドアイコンを構築（カラフル）
  Widget _buildBrandIcon(IconData iconData, {double size = 20}) {
    Color brandColor = Colors.grey; // デフォルト色
    
    // ブランドカラーの定義
    if (iconData.codePoint == FontAwesomeIcons.google.codePoint) {
      brandColor = const Color(0xFF4285F4); // Google Blue
    } else if (iconData.codePoint == FontAwesomeIcons.github.codePoint) {
      brandColor = const Color(0xFF181717); // GitHub Black
    } else if (iconData.codePoint == FontAwesomeIcons.youtube.codePoint) {
      brandColor = const Color(0xFFFF0000); // YouTube Red
    } else if (iconData.codePoint == FontAwesomeIcons.twitter.codePoint) {
      brandColor = const Color(0xFF1DA1F2); // Twitter Blue
    } else if (iconData.codePoint == FontAwesomeIcons.facebook.codePoint) {
      brandColor = const Color(0xFF1877F2); // Facebook Blue
    } else if (iconData.codePoint == FontAwesomeIcons.instagram.codePoint) {
      brandColor = const Color(0xFFE4405F); // Instagram Pink
    } else if (iconData.codePoint == FontAwesomeIcons.linkedin.codePoint) {
      brandColor = const Color(0xFF0A66C2); // LinkedIn Blue
    } else if (iconData.codePoint == FontAwesomeIcons.discord.codePoint) {
      brandColor = const Color(0xFF5865F2); // Discord Blue
    } else if (iconData.codePoint == FontAwesomeIcons.slack.codePoint) {
      brandColor = const Color(0xFF4A154B); // Slack Purple
    } else if (iconData.codePoint == FontAwesomeIcons.spotify.codePoint) {
      brandColor = const Color(0xFF1DB954); // Spotify Green
    } else if (iconData.codePoint == FontAwesomeIcons.amazon.codePoint) {
      brandColor = const Color(0xFFFF9900); // Amazon Orange
    } else if (iconData.codePoint == FontAwesomeIcons.apple.codePoint) {
      brandColor = const Color(0xFF000000); // Apple Black
    } else if (iconData.codePoint == FontAwesomeIcons.microsoft.codePoint) {
      brandColor = const Color(0xFF00A4EF); // Microsoft Blue
    } else if (iconData.codePoint == FontAwesomeIcons.chrome.codePoint) {
      brandColor = const Color(0xFF4285F4); // Chrome Blue
    } else if (iconData.codePoint == FontAwesomeIcons.firefox.codePoint) {
      brandColor = const Color(0xFFFF7139); // Firefox Orange
    } else if (iconData.codePoint == FontAwesomeIcons.safari.codePoint) {
      brandColor = const Color(0xFF006CFF); // Safari Blue
    } else if (iconData.codePoint == FontAwesomeIcons.edge.codePoint) {
      brandColor = const Color(0xFF0078D4); // Edge Blue
    } else if (iconData.codePoint == FontAwesomeIcons.opera.codePoint) {
      brandColor = const Color(0xFFFF1B2D); // Opera Red
    } else if (iconData.codePoint == FontAwesomeIcons.steam.codePoint) {
      brandColor = const Color(0xFF00ADE6); // Steam Blue
    } else if (iconData.codePoint == FontAwesomeIcons.reddit.codePoint) {
      brandColor = const Color(0xFFFF4500); // Reddit Orange
    } else if (iconData.codePoint == FontAwesomeIcons.stackOverflow.codePoint) {
      brandColor = const Color(0xFFF58025); // Stack Overflow Orange
    } else if (iconData.codePoint == FontAwesomeIcons.gitlab.codePoint) {
      brandColor = const Color(0xFFFCA326); // GitLab Orange
    } else if (iconData.codePoint == FontAwesomeIcons.bitbucket.codePoint) {
      brandColor = const Color(0xFF0052CC); // Bitbucket Blue
    } else if (iconData.codePoint == FontAwesomeIcons.docker.codePoint) {
      brandColor = const Color(0xFF2496ED); // Docker Blue
    } else if (iconData.codePoint == FontAwesomeIcons.aws.codePoint) {
      brandColor = const Color(0xFFFF9900); // AWS Orange
    } else if (iconData.codePoint == FontAwesomeIcons.wordpress.codePoint) {
      brandColor = const Color(0xFF21759B); // WordPress Blue
    } else if (iconData.codePoint == FontAwesomeIcons.shopify.codePoint) {
      brandColor = const Color(0xFF7AB55C); // Shopify Green
    } else if (iconData.codePoint == FontAwesomeIcons.stripe.codePoint) {
      brandColor = const Color(0xFF6772E5); // Stripe Purple
    } else if (iconData.codePoint == FontAwesomeIcons.paypal.codePoint) {
      brandColor = const Color(0xFF003087); // PayPal Blue
    } else if (iconData.codePoint == FontAwesomeIcons.bitcoin.codePoint) {
      brandColor = const Color(0xFFF7931A); // Bitcoin Orange
    } else if (iconData.codePoint == FontAwesomeIcons.ethereum.codePoint) {
      brandColor = const Color(0xFF627EEA); // Ethereum Blue
    } else if (iconData.codePoint == FontAwesomeIcons.telegram.codePoint) {
      brandColor = const Color(0xFF0088CC); // Telegram Blue
    } else if (iconData.codePoint == FontAwesomeIcons.whatsapp.codePoint) {
      brandColor = const Color(0xFF25D366); // WhatsApp Green
    } else if (iconData.codePoint == FontAwesomeIcons.skype.codePoint) {
      brandColor = const Color(0xFF00AFF0); // Skype Blue
    } else if (iconData.codePoint == FontAwesomeIcons.dropbox.codePoint) {
      brandColor = const Color(0xFF0061FF); // Dropbox Blue
    } else if (iconData.codePoint == FontAwesomeIcons.box.codePoint) {
      brandColor = const Color(0xFF0061D5); // Box Blue
    } else if (iconData.codePoint == FontAwesomeIcons.figma.codePoint) {
      brandColor = const Color(0xFFF24E1E); // Figma Orange
    } else if (iconData.codePoint == FontAwesomeIcons.blender.codePoint) {
      brandColor = const Color(0xFFF5792A); // Blender Orange
    } else if (iconData.codePoint == FontAwesomeIcons.python.codePoint) {
      brandColor = const Color(0xFF3776AB); // Python Blue
    } else if (iconData.codePoint == FontAwesomeIcons.react.codePoint) {
      brandColor = const Color(0xFF61DAFB); // React Blue
    } else if (iconData.codePoint == FontAwesomeIcons.angular.codePoint) {
      brandColor = const Color(0xFFDD0031); // Angular Red
    } else if (iconData.codePoint == FontAwesomeIcons.flutter.codePoint) {
      brandColor = const Color(0xFF02569B); // Flutter Blue
    } else if (iconData.codePoint == FontAwesomeIcons.bootstrap.codePoint) {
      brandColor = const Color(0xFF7952B3); // Bootstrap Purple
    } else if (iconData.codePoint == FontAwesomeIcons.node.codePoint) {
      brandColor = const Color(0xFF339933); // Node.js Green
    } else if (iconData.codePoint == FontAwesomeIcons.npm.codePoint) {
      brandColor = const Color(0xFFCB3837); // npm Red
    } else if (iconData.codePoint == FontAwesomeIcons.yarn.codePoint) {
      brandColor = const Color(0xFF2C8EBB); // Yarn Blue
    } else if (iconData.codePoint == FontAwesomeIcons.git.codePoint) {
      brandColor = const Color(0xFFF05032); // Git Orange
    } else if (iconData.codePoint == FontAwesomeIcons.linux.codePoint) {
      brandColor = const Color(0xFFFCC624); // Linux Yellow
    } else if (iconData.codePoint == FontAwesomeIcons.windows.codePoint) {
      brandColor = const Color(0xFF0078D4); // Windows Blue
    } else if (iconData.codePoint == FontAwesomeIcons.android.codePoint) {
      brandColor = const Color(0xFF3DDC84); // Android Green
    } else if (iconData.codePoint == FontAwesomeIcons.html5.codePoint) {
      brandColor = const Color(0xFFE34F26); // HTML5 Orange
    } else if (iconData.codePoint == FontAwesomeIcons.css3.codePoint) {
      brandColor = const Color(0xFF1572B6); // CSS3 Blue
    } else if (iconData.codePoint == FontAwesomeIcons.js.codePoint) {
      brandColor = const Color(0xFFF7DF1E); // JavaScript Yellow
    } else if (iconData.codePoint == FontAwesomeIcons.php.codePoint) {
      brandColor = const Color(0xFF777BB4); // PHP Purple
    } else if (iconData.codePoint == FontAwesomeIcons.java.codePoint) {
      brandColor = const Color(0xFFED8B00); // Java Orange
    } else if (iconData.codePoint == FontAwesomeIcons.c.codePoint) {
      brandColor = const Color(0xFFA8B9CC); // C Gray
    } else if (iconData.codePoint == FontAwesomeIcons.swift.codePoint) {
      brandColor = const Color(0xFFFA7343); // Swift Orange
    } else if (iconData.codePoint == FontAwesomeIcons.r.codePoint) {
      brandColor = const Color(0xFF276DC3); // R Blue
    } else if (iconData.codePoint == FontAwesomeIcons.salesforce.codePoint) {
      brandColor = const Color(0xFF00A1E0); // Salesforce Blue
    } else if (iconData.codePoint == FontAwesomeIcons.hubspot.codePoint) {
      brandColor = const Color(0xFFFF7A59); // HubSpot Orange
    } else if (iconData.codePoint == FontAwesomeIcons.mailchimp.codePoint) {
      brandColor = const Color(0xFFFFE01B); // Mailchimp Yellow
    } else if (iconData.codePoint == FontAwesomeIcons.trello.codePoint) {
      brandColor = const Color(0xFF0079BF); // Trello Blue
    }
    
    return Icon(iconData, color: brandColor, size: size);
  }

  // アイコンのTooltipを取得するメソッド
  String _getIconTooltip(IconData icon) {
    // Font AwesomeアイコンのTooltipを先にチェック
    if (icon.codePoint == FontAwesomeIcons.google.codePoint) return 'Google';
    if (icon.codePoint == FontAwesomeIcons.github.codePoint) return 'GitHub';
    if (icon.codePoint == FontAwesomeIcons.youtube.codePoint) return 'YouTube';
    if (icon.codePoint == FontAwesomeIcons.twitter.codePoint) return 'Twitter';
    if (icon.codePoint == FontAwesomeIcons.facebook.codePoint) return 'Facebook';
    if (icon.codePoint == FontAwesomeIcons.instagram.codePoint) return 'Instagram';
    if (icon.codePoint == FontAwesomeIcons.linkedin.codePoint) return 'LinkedIn';
    if (icon.codePoint == FontAwesomeIcons.discord.codePoint) return 'Discord';
    if (icon.codePoint == FontAwesomeIcons.slack.codePoint) return 'Slack';
    if (icon.codePoint == FontAwesomeIcons.spotify.codePoint) return 'Spotify';
    if (icon.codePoint == FontAwesomeIcons.amazon.codePoint) return 'Amazon';
    if (icon.codePoint == FontAwesomeIcons.apple.codePoint) return 'Apple';
    if (icon.codePoint == FontAwesomeIcons.microsoft.codePoint) return 'Microsoft';
    if (icon.codePoint == FontAwesomeIcons.chrome.codePoint) return 'Chrome';
    if (icon.codePoint == FontAwesomeIcons.firefox.codePoint) return 'Firefox';
    if (icon.codePoint == FontAwesomeIcons.safari.codePoint) return 'Safari';
    if (icon.codePoint == FontAwesomeIcons.edge.codePoint) return 'Edge';
    if (icon.codePoint == FontAwesomeIcons.opera.codePoint) return 'Opera';
    if (icon.codePoint == FontAwesomeIcons.steam.codePoint) return 'Steam';
    if (icon.codePoint == FontAwesomeIcons.reddit.codePoint) return 'Reddit';
    if (icon.codePoint == FontAwesomeIcons.stackOverflow.codePoint) return 'Stack Overflow';
    if (icon.codePoint == FontAwesomeIcons.gitlab.codePoint) return 'GitLab';
    if (icon.codePoint == FontAwesomeIcons.bitbucket.codePoint) return 'Bitbucket';
    if (icon.codePoint == FontAwesomeIcons.docker.codePoint) return 'Docker';
    if (icon.codePoint == FontAwesomeIcons.aws.codePoint) return 'AWS';
    if (icon.codePoint == FontAwesomeIcons.wordpress.codePoint) return 'WordPress';
    if (icon.codePoint == FontAwesomeIcons.shopify.codePoint) return 'Shopify';
    if (icon.codePoint == FontAwesomeIcons.stripe.codePoint) return 'Stripe';
    if (icon.codePoint == FontAwesomeIcons.paypal.codePoint) return 'PayPal';
    if (icon.codePoint == FontAwesomeIcons.bitcoin.codePoint) return 'Bitcoin';
    if (icon.codePoint == FontAwesomeIcons.ethereum.codePoint) return 'Ethereum';
    if (icon.codePoint == FontAwesomeIcons.telegram.codePoint) return 'Telegram';
    if (icon.codePoint == FontAwesomeIcons.whatsapp.codePoint) return 'WhatsApp';
    if (icon.codePoint == FontAwesomeIcons.skype.codePoint) return 'Skype';
    if (icon.codePoint == FontAwesomeIcons.dropbox.codePoint) return 'Dropbox';
    if (icon.codePoint == FontAwesomeIcons.box.codePoint) return 'Box';
    if (icon.codePoint == FontAwesomeIcons.figma.codePoint) return 'Figma';
    if (icon.codePoint == FontAwesomeIcons.blender.codePoint) return 'Blender';
    if (icon.codePoint == FontAwesomeIcons.python.codePoint) return 'Python';
    if (icon.codePoint == FontAwesomeIcons.react.codePoint) return 'React';
    if (icon.codePoint == FontAwesomeIcons.angular.codePoint) return 'Angular';
    if (icon.codePoint == FontAwesomeIcons.flutter.codePoint) return 'Flutter';
    if (icon.codePoint == FontAwesomeIcons.bootstrap.codePoint) return 'Bootstrap';
    if (icon.codePoint == FontAwesomeIcons.node.codePoint) return 'Node.js';
    if (icon.codePoint == FontAwesomeIcons.npm.codePoint) return 'npm';
    if (icon.codePoint == FontAwesomeIcons.yarn.codePoint) return 'Yarn';
    if (icon.codePoint == FontAwesomeIcons.git.codePoint) return 'Git';
    if (icon.codePoint == FontAwesomeIcons.linux.codePoint) return 'Linux';
    if (icon.codePoint == FontAwesomeIcons.windows.codePoint) return 'Windows';
    if (icon.codePoint == FontAwesomeIcons.android.codePoint) return 'Android';
    if (icon.codePoint == FontAwesomeIcons.html5.codePoint) return 'HTML5';
    if (icon.codePoint == FontAwesomeIcons.css3.codePoint) return 'CSS3';
    if (icon.codePoint == FontAwesomeIcons.js.codePoint) return 'JavaScript';
    if (icon.codePoint == FontAwesomeIcons.php.codePoint) return 'PHP';
    if (icon.codePoint == FontAwesomeIcons.java.codePoint) return 'Java';
    if (icon.codePoint == FontAwesomeIcons.c.codePoint) return 'C';
    if (icon.codePoint == FontAwesomeIcons.swift.codePoint) return 'Swift';
    if (icon.codePoint == FontAwesomeIcons.r.codePoint) return 'R';
    if (icon.codePoint == FontAwesomeIcons.salesforce.codePoint) return 'Salesforce';
    if (icon.codePoint == FontAwesomeIcons.hubspot.codePoint) return 'HubSpot';
    if (icon.codePoint == FontAwesomeIcons.mailchimp.codePoint) return 'Mailchimp';
    if (icon.codePoint == FontAwesomeIcons.trello.codePoint) return 'Trello';
    
    // Material IconsのTooltip
    if (icon.codePoint == Icons.public.codePoint) return '地球アイコン';
    if (icon.codePoint == Icons.folder.codePoint) return 'フォルダ';
    if (icon.codePoint == Icons.folder_open.codePoint) return '開いたフォルダ';
    if (icon.codePoint == Icons.folder_special.codePoint) return '特別なフォルダ';
    if (icon.codePoint == Icons.folder_shared.codePoint) return '共有フォルダ';
    if (icon.codePoint == Icons.folder_zip.codePoint) return '圧縮フォルダ';
    if (icon.codePoint == Icons.folder_copy.codePoint) return 'コピーフォルダ';
    if (icon.codePoint == Icons.folder_delete.codePoint) return '削除フォルダ';
    if (icon.codePoint == Icons.folder_off.codePoint) return '無効フォルダ';
    if (icon.codePoint == Icons.folder_outlined.codePoint) return 'フォルダ（アウトライン）';
    if (icon.codePoint == Icons.folder_open_outlined.codePoint) return '開いたフォルダ（アウトライン）';
    if (icon.codePoint == Icons.folder_special_outlined.codePoint) return '特別なフォルダ（アウトライン）';
    if (icon.codePoint == Icons.folder_shared_outlined.codePoint) return '共有フォルダ（アウトライン）';
    if (icon.codePoint == Icons.folder_zip_outlined.codePoint) return '圧縮フォルダ（アウトライン）';
    if (icon.codePoint == Icons.folder_copy_outlined.codePoint) return 'コピーフォルダ（アウトライン）';
    if (icon.codePoint == Icons.folder_delete_outlined.codePoint) return '削除フォルダ（アウトライン）';
    if (icon.codePoint == Icons.folder_off_outlined.codePoint) return '無効フォルダ（アウトライン）';
    if (icon.codePoint == Icons.drive_folder_upload.codePoint) return 'アップロードフォルダ';
    if (icon.codePoint == Icons.drive_folder_upload_outlined.codePoint) return 'アップロードフォルダ（アウトライン）';
    if (icon.codePoint == Icons.drive_file_move.codePoint) return 'ファイル移動';
    if (icon.codePoint == Icons.drive_file_move_outlined.codePoint) return 'ファイル移動（アウトライン）';
    if (icon.codePoint == Icons.drive_file_rename_outline.codePoint) return 'ファイル名変更';
    if (icon.codePoint == Icons.drive_file_rename_outline_outlined.codePoint) return 'ファイル名変更（アウトライン）';
    if (icon.codePoint == Icons.book.codePoint) return '本';
    if (icon.codePoint == Icons.book_outlined.codePoint) return '本（アウトライン）';
    if (icon.codePoint == Icons.bookmark.codePoint) return 'ブックマーク';
    if (icon.codePoint == Icons.bookmark_outlined.codePoint) return 'ブックマーク（アウトライン）';
    if (icon.codePoint == Icons.favorite.codePoint) return 'お気に入り';
    if (icon.codePoint == Icons.favorite_outlined.codePoint) return 'お気に入り（アウトライン）';
    if (icon.codePoint == Icons.star.codePoint) return '星';
    if (icon.codePoint == Icons.star_outlined.codePoint) return '星（アウトライン）';
    if (icon.codePoint == Icons.home.codePoint) return 'ホーム';
    if (icon.codePoint == Icons.home_outlined.codePoint) return 'ホーム（アウトライン）';
    if (icon.codePoint == Icons.work.codePoint) return '仕事';
    if (icon.codePoint == Icons.work_outlined.codePoint) return '仕事（アウトライン）';
    if (icon.codePoint == Icons.school.codePoint) return '学校';
    if (icon.codePoint == Icons.school_outlined.codePoint) return '学校（アウトライン）';
    if (icon.codePoint == Icons.business.codePoint) return 'ビジネス';
    if (icon.codePoint == Icons.business_outlined.codePoint) return 'ビジネス（アウトライン）';
    if (icon.codePoint == Icons.store.codePoint) return '店舗';
    if (icon.codePoint == Icons.store_outlined.codePoint) return '店舗（アウトライン）';
    if (icon.codePoint == Icons.shopping_cart.codePoint) return 'ショッピングカート';
    if (icon.codePoint == Icons.shopping_cart_outlined.codePoint) return 'ショッピングカート（アウトライン）';
    if (icon.codePoint == Icons.music_note.codePoint) return '音楽';
    if (icon.codePoint == Icons.music_note_outlined.codePoint) return '音楽（アウトライン）';
    if (icon.codePoint == Icons.photo.codePoint) return '写真';
    if (icon.codePoint == Icons.photo_outlined.codePoint) return '写真（アウトライン）';
    if (icon.codePoint == Icons.video_library.codePoint) return '動画ライブラリ';
    if (icon.codePoint == Icons.video_library_outlined.codePoint) return '動画ライブラリ（アウトライン）';
    if (icon.codePoint == Icons.download.codePoint) return 'ダウンロード';
    if (icon.codePoint == Icons.download_outlined.codePoint) return 'ダウンロード（アウトライン）';
    if (icon.codePoint == Icons.upload.codePoint) return 'アップロード';
    if (icon.codePoint == Icons.upload_outlined.codePoint) return 'アップロード（アウトライン）';
    if (icon.codePoint == Icons.backup.codePoint) return 'バックアップ';
    if (icon.codePoint == Icons.backup_outlined.codePoint) return 'バックアップ（アウトライン）';
    if (icon.codePoint == Icons.archive.codePoint) return 'アーカイブ';
    if (icon.codePoint == Icons.archive_outlined.codePoint) return 'アーカイブ（アウトライン）';
    if (icon.codePoint == Icons.inbox.codePoint) return '受信トレイ';
    if (icon.codePoint == Icons.inbox_outlined.codePoint) return '受信トレイ（アウトライン）';
    if (icon.codePoint == Icons.outbox.codePoint) return '送信トレイ';
    if (icon.codePoint == Icons.outbox_outlined.codePoint) return '送信トレイ（アウトライン）';
    if (icon.codePoint == Icons.drafts.codePoint) return '下書き';
    if (icon.codePoint == Icons.drafts_outlined.codePoint) return '下書き（アウトライン）';
    if (icon.codePoint == Icons.send.codePoint) return '送信';
    if (icon.codePoint == Icons.send_outlined.codePoint) return '送信（アウトライン）';
    if (icon.codePoint == Icons.mail.codePoint) return 'メール';
    if (icon.codePoint == Icons.mail_outlined.codePoint) return 'メール（アウトライン）';
    if (icon.codePoint == Icons.contact_mail.codePoint) return '連絡先メール';
    if (icon.codePoint == Icons.contact_mail_outlined.codePoint) return '連絡先メール（アウトライン）';
    if (icon.codePoint == Icons.person.codePoint) return '人物';
    if (icon.codePoint == Icons.person_outlined.codePoint) return '人物（アウトライン）';
    if (icon.codePoint == Icons.group.codePoint) return 'グループ';
    if (icon.codePoint == Icons.group_outlined.codePoint) return 'グループ（アウトライン）';
    if (icon.codePoint == Icons.family_restroom.codePoint) return '家族';
    if (icon.codePoint == Icons.family_restroom_outlined.codePoint) return '家族（アウトライン）';
    if (icon.codePoint == Icons.pets.codePoint) return 'ペット';
    if (icon.codePoint == Icons.pets_outlined.codePoint) return 'ペット（アウトライン）';
    if (icon.codePoint == Icons.sports_soccer.codePoint) return 'サッカー';
    if (icon.codePoint == Icons.sports_soccer_outlined.codePoint) return 'サッカー（アウトライン）';
    if (icon.codePoint == Icons.sports_basketball.codePoint) return 'バスケットボール';
    if (icon.codePoint == Icons.sports_basketball_outlined.codePoint) return 'バスケットボール（アウトライン）';
    if (icon.codePoint == Icons.sports_esports.codePoint) return 'eスポーツ';
    if (icon.codePoint == Icons.sports_esports_outlined.codePoint) return 'eスポーツ（アウトライン）';
    if (icon.codePoint == Icons.games.codePoint) return 'ゲーム';
    if (icon.codePoint == Icons.games_outlined.codePoint) return 'ゲーム（アウトライン）';
    if (icon.codePoint == Icons.toys.codePoint) return 'おもちゃ';
    if (icon.codePoint == Icons.toys_outlined.codePoint) return 'おもちゃ（アウトライン）';
    if (icon.codePoint == Icons.child_care.codePoint) return '育児';
    if (icon.codePoint == Icons.child_care_outlined.codePoint) return '育児（アウトライン）';
    if (icon.codePoint == Icons.library_books.codePoint) return '図書館';
    if (icon.codePoint == Icons.library_books_outlined.codePoint) return '図書館（アウトライン）';
    if (icon.codePoint == Icons.menu_book.codePoint) return 'メニューブック';
    if (icon.codePoint == Icons.menu_book_outlined.codePoint) return 'メニューブック（アウトライン）';
    if (icon.codePoint == Icons.auto_stories.codePoint) return '自動ストーリー';
    if (icon.codePoint == Icons.auto_stories_outlined.codePoint) return '自動ストーリー（アウトライン）';
    if (icon.codePoint == Icons.emoji_emotions.codePoint) return '絵文字';
    if (icon.codePoint == Icons.emoji_emotions_outlined.codePoint) return '絵文字（アウトライン）';
    if (icon.codePoint == Icons.celebration.codePoint) return 'お祝い';
    if (icon.codePoint == Icons.celebration_outlined.codePoint) return 'お祝い（アウトライン）';
    if (icon.codePoint == Icons.cake.codePoint) return 'ケーキ';
    if (icon.codePoint == Icons.cake_outlined.codePoint) return 'ケーキ（アウトライン）';
    if (icon.codePoint == Icons.local_pizza.codePoint) return 'ピザ';
    if (icon.codePoint == Icons.local_pizza_outlined.codePoint) return 'ピザ（アウトライン）';
    if (icon.codePoint == Icons.local_cafe.codePoint) return 'カフェ';
    if (icon.codePoint == Icons.local_cafe_outlined.codePoint) return 'カフェ（アウトライン）';
    if (icon.codePoint == Icons.local_restaurant.codePoint) return 'レストラン';
    if (icon.codePoint == Icons.local_restaurant_outlined.codePoint) return 'レストラン（アウトライン）';
    if (icon.codePoint == Icons.local_bar.codePoint) return 'バー';
    if (icon.codePoint == Icons.local_bar_outlined.codePoint) return 'バー（アウトライン）';
    if (icon.codePoint == Icons.local_hotel.codePoint) return 'ホテル';
    if (icon.codePoint == Icons.local_hotel_outlined.codePoint) return 'ホテル（アウトライン）';
    if (icon.codePoint == Icons.local_gas_station.codePoint) return 'ガソリンスタンド';
    if (icon.codePoint == Icons.local_gas_station_outlined.codePoint) return 'ガソリンスタンド（アウトライン）';
    if (icon.codePoint == Icons.local_pharmacy.codePoint) return '薬局';
    if (icon.codePoint == Icons.local_pharmacy_outlined.codePoint) return '薬局（アウトライン）';
    if (icon.codePoint == Icons.local_hospital.codePoint) return '病院';
    if (icon.codePoint == Icons.local_hospital_outlined.codePoint) return '病院（アウトライン）';
    if (icon.codePoint == Icons.local_police.codePoint) return '警察';
    if (icon.codePoint == Icons.local_police_outlined.codePoint) return '警察（アウトライン）';
    if (icon.codePoint == Icons.local_fire_department.codePoint) return '消防署';
    if (icon.codePoint == Icons.local_fire_department_outlined.codePoint) return '消防署（アウトライン）';
    if (icon.codePoint == Icons.local_post_office.codePoint) return '郵便局';
    if (icon.codePoint == Icons.local_post_office_outlined.codePoint) return '郵便局（アウトライン）';
    if (icon.codePoint == Icons.local_atm.codePoint) return 'ATM';
    if (icon.codePoint == Icons.local_atm_outlined.codePoint) return 'ATM（アウトライン）';
    if (icon.codePoint == Icons.local_mall.codePoint) return 'ショッピングモール';
    if (icon.codePoint == Icons.local_mall_outlined.codePoint) return 'ショッピングモール（アウトライン）';
    if (icon.codePoint == Icons.local_movies.codePoint) return '映画館';
    if (icon.codePoint == Icons.local_movies_outlined.codePoint) return '映画館（アウトライン）';
    if (icon.codePoint == Icons.local_play.codePoint) return '遊び場';
    if (icon.codePoint == Icons.local_play_outlined.codePoint) return '遊び場（アウトライン）';
    if (icon.codePoint == Icons.local_activity.codePoint) return 'アクティビティ';
    if (icon.codePoint == Icons.local_activity_outlined.codePoint) return 'アクティビティ（アウトライン）';
    if (icon.codePoint == Icons.local_parking.codePoint) return '駐車場';
    if (icon.codePoint == Icons.local_parking_outlined.codePoint) return '駐車場（アウトライン）';
    if (icon.codePoint == Icons.local_taxi.codePoint) return 'タクシー';
    if (icon.codePoint == Icons.local_taxi_outlined.codePoint) return 'タクシー（アウトライン）';
    if (icon.codePoint == Icons.local_airport.codePoint) return '空港';
    if (icon.codePoint == Icons.local_airport_outlined.codePoint) return '空港（アウトライン）';
    if (icon.codePoint == Icons.local_shipping.codePoint) return '配送';
    if (icon.codePoint == Icons.local_shipping_outlined.codePoint) return '配送（アウトライン）';
    if (icon.codePoint == Icons.local_offer.codePoint) return 'オファー';
    if (icon.codePoint == Icons.local_offer_outlined.codePoint) return 'オファー（アウトライン）';
    if (icon.codePoint == Icons.local_florist.codePoint) return '花屋';
    if (icon.codePoint == Icons.local_florist_outlined.codePoint) return '花屋（アウトライン）';
    if (icon.codePoint == Icons.local_car_wash.codePoint) return '洗車場';
    if (icon.codePoint == Icons.local_car_wash_outlined.codePoint) return '洗車場（アウトライン）';
    if (icon.codePoint == Icons.local_laundry_service.codePoint) return 'クリーニング';
    if (icon.codePoint == Icons.local_laundry_service_outlined.codePoint) return 'クリーニング（アウトライン）';
    if (icon.codePoint == Icons.local_dining.codePoint) return '食事';
    if (icon.codePoint == Icons.local_dining_outlined.codePoint) return '食事（アウトライン）';
    if (icon.codePoint == Icons.local_drink.codePoint) return '飲み物';
    if (icon.codePoint == Icons.local_drink_outlined.codePoint) return '飲み物（アウトライン）';
    if (icon.codePoint == Icons.public_outlined.codePoint) return '地球（アウトライン）';
    if (icon.codePoint == Icons.language.codePoint) return '言語';
    if (icon.codePoint == Icons.language_outlined.codePoint) return '言語（アウトライン）';
    if (icon.codePoint == Icons.web.codePoint) return 'ウェブ';
    if (icon.codePoint == Icons.web_outlined.codePoint) return 'ウェブ（アウトライン）';
    if (icon.codePoint == Icons.computer.codePoint) return 'コンピューター';
    if (icon.codePoint == Icons.computer_outlined.codePoint) return 'コンピューター（アウトライン）';
    if (icon.codePoint == Icons.laptop.codePoint) return 'ラップトップ';
    if (icon.codePoint == Icons.laptop_outlined.codePoint) return 'ラップトップ（アウトライン）';
    if (icon.codePoint == Icons.tablet.codePoint) return 'タブレット';
    if (icon.codePoint == Icons.tablet_outlined.codePoint) return 'タブレット（アウトライン）';
    if (icon.codePoint == Icons.phone.codePoint) return '電話';
    if (icon.codePoint == Icons.phone_outlined.codePoint) return '電話（アウトライン）';
    if (icon.codePoint == Icons.smartphone.codePoint) return 'スマートフォン';
    if (icon.codePoint == Icons.smartphone_outlined.codePoint) return 'スマートフォン（アウトライン）';
    if (icon.codePoint == Icons.watch.codePoint) return '時計';
    if (icon.codePoint == Icons.watch_outlined.codePoint) return '時計（アウトライン）';
    if (icon.codePoint == Icons.headphones.codePoint) return 'ヘッドフォン';
    if (icon.codePoint == Icons.headphones_outlined.codePoint) return 'ヘッドフォン（アウトライン）';
    if (icon.codePoint == Icons.speaker.codePoint) return 'スピーカー';
    if (icon.codePoint == Icons.speaker_outlined.codePoint) return 'スピーカー（アウトライン）';
    if (icon.codePoint == Icons.tv.codePoint) return 'テレビ';
    if (icon.codePoint == Icons.tv_outlined.codePoint) return 'テレビ（アウトライン）';
    if (icon.codePoint == Icons.radio.codePoint) return 'ラジオ';
    if (icon.codePoint == Icons.radio_outlined.codePoint) return 'ラジオ（アウトライン）';
    if (icon.codePoint == Icons.camera_alt.codePoint) return 'カメラ';
    if (icon.codePoint == Icons.camera_alt_outlined.codePoint) return 'カメラ（アウトライン）';
    if (icon.codePoint == Icons.camera.codePoint) return 'カメラ';
    if (icon.codePoint == Icons.camera_outlined.codePoint) return 'カメラ（アウトライン）';
    if (icon.codePoint == Icons.videocam.codePoint) return 'ビデオカメラ';
    if (icon.codePoint == Icons.videocam_outlined.codePoint) return 'ビデオカメラ（アウトライン）';
    if (icon.codePoint == Icons.mic.codePoint) return 'マイク';
    if (icon.codePoint == Icons.mic_outlined.codePoint) return 'マイク（アウトライン）';
    if (icon.codePoint == Icons.keyboard.codePoint) return 'キーボード';
    if (icon.codePoint == Icons.keyboard_outlined.codePoint) return 'キーボード（アウトライン）';
    if (icon.codePoint == Icons.mouse.codePoint) return 'マウス';
    if (icon.codePoint == Icons.mouse_outlined.codePoint) return 'マウス（アウトライン）';
    if (icon.codePoint == Icons.print.codePoint) return 'プリンター';
    if (icon.codePoint == Icons.print_outlined.codePoint) return 'プリンター（アウトライン）';
    if (icon.codePoint == Icons.scanner.codePoint) return 'スキャナー';
    if (icon.codePoint == Icons.scanner_outlined.codePoint) return 'スキャナー（アウトライン）';
    if (icon.codePoint == Icons.fax.codePoint) return 'ファックス';
    if (icon.codePoint == Icons.fax_outlined.codePoint) return 'ファックス（アウトライン）';
    if (icon.codePoint == Icons.router.codePoint) return 'ルーター';
    if (icon.codePoint == Icons.router_outlined.codePoint) return 'ルーター（アウトライン）';
    if (icon.codePoint == Icons.wifi.codePoint) return 'Wi-Fi';
    if (icon.codePoint == Icons.wifi_outlined.codePoint) return 'Wi-Fi（アウトライン）';
    if (icon.codePoint == Icons.bluetooth.codePoint) return 'Bluetooth';
    if (icon.codePoint == Icons.bluetooth_outlined.codePoint) return 'Bluetooth（アウトライン）';
    if (icon.codePoint == Icons.nfc.codePoint) return 'NFC';
    if (icon.codePoint == Icons.nfc_outlined.codePoint) return 'NFC（アウトライン）';
    if (icon.codePoint == Icons.gps_fixed.codePoint) return 'GPS';
    if (icon.codePoint == Icons.gps_fixed_outlined.codePoint) return 'GPS（アウトライン）';
    if (icon.codePoint == Icons.location_on.codePoint) return '位置情報';
    if (icon.codePoint == Icons.location_on_outlined.codePoint) return '位置情報（アウトライン）';
    if (icon.codePoint == Icons.map.codePoint) return '地図';
    if (icon.codePoint == Icons.map_outlined.codePoint) return '地図（アウトライン）';
    if (icon.codePoint == Icons.navigation.codePoint) return 'ナビゲーション';
    if (icon.codePoint == Icons.navigation_outlined.codePoint) return 'ナビゲーション（アウトライン）';
    if (icon.codePoint == Icons.directions.codePoint) return '方向';
    if (icon.codePoint == Icons.directions_outlined.codePoint) return '方向（アウトライン）';
    if (icon.codePoint == Icons.compass_calibration.codePoint) return 'コンパス';
    if (icon.codePoint == Icons.compass_calibration_outlined.codePoint) return 'コンパス（アウトライン）';
    if (icon.codePoint == Icons.explore.codePoint) return '探索';
    if (icon.codePoint == Icons.explore_outlined.codePoint) return '探索（アウトライン）';
    if (icon.codePoint == Icons.travel_explore.codePoint) return '旅行探索';
    if (icon.codePoint == Icons.travel_explore_outlined.codePoint) return '旅行探索（アウトライン）';
    if (icon.codePoint == Icons.flight.codePoint) return '飛行機';
    if (icon.codePoint == Icons.flight_outlined.codePoint) return '飛行機（アウトライン）';
    if (icon.codePoint == Icons.train.codePoint) return '電車';
    if (icon.codePoint == Icons.train_outlined.codePoint) return '電車（アウトライン）';
    if (icon.codePoint == Icons.directions_car.codePoint) return '車';
    if (icon.codePoint == Icons.directions_car_outlined.codePoint) return '車（アウトライン）';
    if (icon.codePoint == Icons.directions_bus.codePoint) return 'バス';
    if (icon.codePoint == Icons.directions_bus_outlined.codePoint) return 'バス（アウトライン）';
    if (icon.codePoint == Icons.directions_bike.codePoint) return '自転車';
    if (icon.codePoint == Icons.directions_bike_outlined.codePoint) return '自転車（アウトライン）';
    if (icon.codePoint == Icons.directions_walk.codePoint) return '歩行';
    if (icon.codePoint == Icons.directions_walk_outlined.codePoint) return '歩行（アウトライン）';
    if (icon.codePoint == Icons.directions_boat.codePoint) return 'ボート';
    if (icon.codePoint == Icons.directions_boat_outlined.codePoint) return 'ボート（アウトライン）';
    if (icon.codePoint == Icons.directions_subway.codePoint) return '地下鉄';
    if (icon.codePoint == Icons.directions_subway_outlined.codePoint) return '地下鉄（アウトライン）';
    if (icon.codePoint == Icons.directions_transit.codePoint) return '公共交通';
    if (icon.codePoint == Icons.directions_transit_outlined.codePoint) return '公共交通（アウトライン）';
    if (icon.codePoint == Icons.directions_run.codePoint) return 'ランニング';
    if (icon.codePoint == Icons.directions_run_outlined.codePoint) return 'ランニング（アウトライン）';
    if (icon.codePoint == Icons.directions_railway.codePoint) return '鉄道';
    if (icon.codePoint == Icons.directions_railway_outlined.codePoint) return '鉄道（アウトライン）';
    if (icon.codePoint == Icons.directions_ferry.codePoint) return 'フェリー';
    if (icon.codePoint == Icons.directions_ferry_outlined.codePoint) return 'フェリー（アウトライン）';
    if (icon.codePoint == Icons.public.codePoint) return '地球';
    if (icon.codePoint == Icons.public_outlined.codePoint) return '地球（アウトライン）';
    
    // ビジネス向けアイコンのTooltip
    if (icon.codePoint == Icons.business.codePoint) return 'ビジネス';
    if (icon.codePoint == Icons.business_outlined.codePoint) return 'ビジネス（アウトライン）';
    if (icon.codePoint == Icons.account_balance.codePoint) return '銀行';
    if (icon.codePoint == Icons.account_balance_outlined.codePoint) return '銀行（アウトライン）';
    if (icon.codePoint == Icons.account_balance_wallet.codePoint) return 'ウォレット';
    if (icon.codePoint == Icons.account_balance_wallet_outlined.codePoint) return 'ウォレット（アウトライン）';
    if (icon.codePoint == Icons.attach_money.codePoint) return 'お金';
    if (icon.codePoint == Icons.attach_money_outlined.codePoint) return 'お金（アウトライン）';
    if (icon.codePoint == Icons.money.codePoint) return '現金';
    if (icon.codePoint == Icons.money_outlined.codePoint) return '現金（アウトライン）';
    if (icon.codePoint == Icons.credit_card.codePoint) return 'クレジットカード';
    if (icon.codePoint == Icons.credit_card_outlined.codePoint) return 'クレジットカード（アウトライン）';
    if (icon.codePoint == Icons.payment.codePoint) return '支払い';
    if (icon.codePoint == Icons.payment_outlined.codePoint) return '支払い（アウトライン）';
    if (icon.codePoint == Icons.receipt.codePoint) return 'レシート';
    if (icon.codePoint == Icons.receipt_outlined.codePoint) return 'レシート（アウトライン）';
    if (icon.codePoint == Icons.analytics.codePoint) return '分析';
    if (icon.codePoint == Icons.analytics_outlined.codePoint) return '分析（アウトライン）';
    if (icon.codePoint == Icons.trending_up.codePoint) return '上昇トレンド';
    if (icon.codePoint == Icons.trending_up_outlined.codePoint) return '上昇トレンド（アウトライン）';
    if (icon.codePoint == Icons.trending_down.codePoint) return '下降トレンド';
    if (icon.codePoint == Icons.trending_down_outlined.codePoint) return '下降トレンド（アウトライン）';
    if (icon.codePoint == Icons.bar_chart.codePoint) return '棒グラフ';
    if (icon.codePoint == Icons.bar_chart_outlined.codePoint) return '棒グラフ（アウトライン）';
    if (icon.codePoint == Icons.pie_chart.codePoint) return '円グラフ';
    if (icon.codePoint == Icons.show_chart.codePoint) return 'チャート';
    if (icon.codePoint == Icons.show_chart_outlined.codePoint) return 'チャート（アウトライン）';
    if (icon.codePoint == Icons.insights.codePoint) return 'インサイト';
    if (icon.codePoint == Icons.insights_outlined.codePoint) return 'インサイト（アウトライン）';
    if (icon.codePoint == Icons.query_stats.codePoint) return '統計';
    if (icon.codePoint == Icons.query_stats_outlined.codePoint) return '統計（アウトライン）';
    if (icon.codePoint == Icons.timeline.codePoint) return 'タイムライン';
    if (icon.codePoint == Icons.timeline_outlined.codePoint) return 'タイムライン（アウトライン）';
    if (icon.codePoint == Icons.schedule.codePoint) return 'スケジュール';
    if (icon.codePoint == Icons.schedule_outlined.codePoint) return 'スケジュール（アウトライン）';
    if (icon.codePoint == Icons.event.codePoint) return 'イベント';
    if (icon.codePoint == Icons.event_outlined.codePoint) return 'イベント（アウトライン）';
    if (icon.codePoint == Icons.calendar_today.codePoint) return '今日';
    if (icon.codePoint == Icons.calendar_today_outlined.codePoint) return '今日（アウトライン）';
    if (icon.codePoint == Icons.calendar_month.codePoint) return '月';
    if (icon.codePoint == Icons.calendar_month_outlined.codePoint) return '月（アウトライン）';
    if (icon.codePoint == Icons.work.codePoint) return '仕事';
    if (icon.codePoint == Icons.work_outlined.codePoint) return '仕事（アウトライン）';
    if (icon.codePoint == Icons.business_center.codePoint) return 'ビジネスセンター';
    if (icon.codePoint == Icons.business_center_outlined.codePoint) return 'ビジネスセンター（アウトライン）';
    if (icon.codePoint == Icons.meeting_room.codePoint) return '会議室';
    if (icon.codePoint == Icons.meeting_room_outlined.codePoint) return '会議室（アウトライン）';
    if (icon.codePoint == Icons.people.codePoint) return '人々';
    if (icon.codePoint == Icons.people_outlined.codePoint) return '人々（アウトライン）';
    if (icon.codePoint == Icons.people_alt.codePoint) return 'グループ';
    if (icon.codePoint == Icons.people_alt_outlined.codePoint) return 'グループ（アウトライン）';
    if (icon.codePoint == Icons.engineering.codePoint) return 'エンジニアリング';
    if (icon.codePoint == Icons.engineering_outlined.codePoint) return 'エンジニアリング（アウトライン）';
    if (icon.codePoint == Icons.architecture.codePoint) return 'アーキテクチャ';
    if (icon.codePoint == Icons.architecture_outlined.codePoint) return 'アーキテクチャ（アウトライン）';
    if (icon.codePoint == Icons.construction.codePoint) return '建設';
    if (icon.codePoint == Icons.construction_outlined.codePoint) return '建設（アウトライン）';
    if (icon.codePoint == Icons.build.codePoint) return '構築';
    if (icon.codePoint == Icons.build_outlined.codePoint) return '構築（アウトライン）';
    if (icon.codePoint == Icons.settings.codePoint) return '設定';
    if (icon.codePoint == Icons.settings_outlined.codePoint) return '設定（アウトライン）';
    if (icon.codePoint == Icons.security.codePoint) return 'セキュリティ';
    if (icon.codePoint == Icons.security_outlined.codePoint) return 'セキュリティ（アウトライン）';
    if (icon.codePoint == Icons.verified_user.codePoint) return '認証ユーザー';
    if (icon.codePoint == Icons.verified_user_outlined.codePoint) return '認証ユーザー（アウトライン）';
    if (icon.codePoint == Icons.assignment.codePoint) return '課題';
    if (icon.codePoint == Icons.assignment_outlined.codePoint) return '課題（アウトライン）';
    if (icon.codePoint == Icons.assessment.codePoint) return '評価';
    if (icon.codePoint == Icons.assessment_outlined.codePoint) return '評価（アウトライン）';
    if (icon.codePoint == Icons.quiz.codePoint) return 'クイズ';
    if (icon.codePoint == Icons.quiz_outlined.codePoint) return 'クイズ（アウトライン）';
    if (icon.codePoint == Icons.leaderboard.codePoint) return 'リーダーボード';
    if (icon.codePoint == Icons.leaderboard_outlined.codePoint) return 'リーダーボード（アウトライン）';
    if (icon.codePoint == Icons.update.codePoint) return '更新';
    if (icon.codePoint == Icons.update_outlined.codePoint) return '更新（アウトライン）';
    if (icon.codePoint == Icons.access_time.codePoint) return 'アクセス時間';
    if (icon.codePoint == Icons.access_time_outlined.codePoint) return 'アクセス時間（アウトライン）';
    if (icon.codePoint == Icons.today.codePoint) return '今日';
    if (icon.codePoint == Icons.today_outlined.codePoint) return '今日（アウトライン）';
    if (icon.codePoint == Icons.location_city.codePoint) return '都市';
    if (icon.codePoint == Icons.location_city_outlined.codePoint) return '都市（アウトライン）';
    if (icon.codePoint == Icons.location_on.codePoint) return '位置';
    if (icon.codePoint == Icons.location_on_outlined.codePoint) return '位置（アウトライン）';
    if (icon.codePoint == Icons.place.codePoint) return '場所';
    if (icon.codePoint == Icons.place_outlined.codePoint) return '場所（アウトライン）';
    if (icon.codePoint == Icons.flight.codePoint) return '飛行機';
    if (icon.codePoint == Icons.flight_outlined.codePoint) return '飛行機（アウトライン）';
    if (icon.codePoint == Icons.train.codePoint) return '電車';
    if (icon.codePoint == Icons.train_outlined.codePoint) return '電車（アウトライン）';
    if (icon.codePoint == Icons.local_shipping.codePoint) return '配送';
    if (icon.codePoint == Icons.local_shipping_outlined.codePoint) return '配送（アウトライン）';
    if (icon.codePoint == Icons.local_airport.codePoint) return '空港';
    if (icon.codePoint == Icons.local_airport_outlined.codePoint) return '空港（アウトライン）';
    if (icon.codePoint == Icons.local_hotel.codePoint) return 'ホテル';
    if (icon.codePoint == Icons.local_hotel_outlined.codePoint) return 'ホテル（アウトライン）';
    if (icon.codePoint == Icons.local_restaurant.codePoint) return 'レストラン';
    if (icon.codePoint == Icons.local_restaurant_outlined.codePoint) return 'レストラン（アウトライン）';
    if (icon.codePoint == Icons.local_cafe.codePoint) return 'カフェ';
    if (icon.codePoint == Icons.local_cafe_outlined.codePoint) return 'カフェ（アウトライン）';
    if (icon.codePoint == Icons.local_atm.codePoint) return 'ATM';
    if (icon.codePoint == Icons.local_atm_outlined.codePoint) return 'ATM（アウトライン）';
    if (icon.codePoint == Icons.local_mall.codePoint) return 'ショッピングモール';
    if (icon.codePoint == Icons.local_mall_outlined.codePoint) return 'ショッピングモール（アウトライン）';
    if (icon.codePoint == Icons.local_offer.codePoint) return 'オファー';
    if (icon.codePoint == Icons.local_offer_outlined.codePoint) return 'オファー（アウトライン）';
    
    // アイコンが見つからない場合は、アイコンの種類に応じて適切な名前を返す
    if (icon.fontFamily == 'FontAwesomeSolid' || 
        icon.fontFamily == 'FontAwesomeRegular' || 
        icon.fontFamily == 'FontAwesomeBrands') {
      return 'ブランドアイコン';
    } else if (icon.fontFamily == 'MaterialIcons') {
      return 'マテリアルアイコン';
    } else {
      return 'アイコン';
    }
  }

  // Material Iconsリスト（カラフルで多様）
  static const List<IconData> _folderIcons = [
    // デバッグ用：地球アイコンを最初に配置して確認
    Icons.public,
    Icons.folder,
    Icons.folder_open,
    Icons.folder_special,
    Icons.folder_shared,
    Icons.folder_zip,
    Icons.folder_copy,
    Icons.folder_delete,
    Icons.folder_off,
    Icons.folder_outlined,
    Icons.folder_open_outlined,
    Icons.folder_special_outlined,
    Icons.folder_shared_outlined,
    Icons.folder_zip_outlined,
    Icons.folder_copy_outlined,
    Icons.folder_delete_outlined,
    Icons.folder_off_outlined,
    Icons.drive_folder_upload,
    Icons.drive_folder_upload_outlined,
    Icons.drive_file_move,
    Icons.drive_file_move_outlined,
    Icons.drive_file_rename_outline,
    Icons.drive_file_rename_outline_outlined,
    Icons.book,
    Icons.book_outlined,
    Icons.bookmark,
    Icons.bookmark_outlined,
    Icons.favorite,
    Icons.favorite_outlined,
    Icons.star,
    Icons.star_outlined,
    Icons.home,
    Icons.home_outlined,
    Icons.work,
    Icons.work_outlined,
    Icons.school,
    Icons.school_outlined,
    Icons.business,
    Icons.business_outlined,
    Icons.store,
    Icons.store_outlined,
    Icons.shopping_cart,
    Icons.shopping_cart_outlined,
    Icons.music_note,
    Icons.music_note_outlined,
    Icons.photo,
    Icons.photo_outlined,
    Icons.video_library,
    Icons.video_library_outlined,
    Icons.download,
    Icons.download_outlined,
    Icons.upload,
    Icons.upload_outlined,
    Icons.backup,
    Icons.backup_outlined,
    Icons.archive,
    Icons.archive_outlined,
    Icons.inbox,
    Icons.inbox_outlined,
    Icons.outbox,
    Icons.outbox_outlined,
    Icons.drafts,
    Icons.drafts_outlined,
    Icons.send,
    Icons.send_outlined,
    Icons.mail,
    Icons.mail_outlined,
    Icons.contact_mail,
    Icons.contact_mail_outlined,
    Icons.person,
    Icons.person_outlined,
    Icons.group,
    Icons.group_outlined,
    Icons.family_restroom,
    Icons.family_restroom_outlined,
    Icons.pets,
    Icons.pets_outlined,
    Icons.sports_soccer,
    Icons.sports_soccer_outlined,
    Icons.sports_basketball,
    Icons.sports_basketball_outlined,
    Icons.sports_esports,
    Icons.sports_esports_outlined,
    Icons.games,
    Icons.games_outlined,
    Icons.toys,
    Icons.toys_outlined,
    Icons.child_care,
    Icons.child_care_outlined,
    Icons.library_books,
    Icons.library_books_outlined,
    Icons.menu_book,
    Icons.menu_book_outlined,
    Icons.auto_stories,
    Icons.auto_stories_outlined,
    Icons.emoji_emotions,
    Icons.emoji_emotions_outlined,
    
    // ビジネス向けアイコン
    Icons.business,
    Icons.business_outlined,
    Icons.account_balance,
    Icons.account_balance_outlined,
    Icons.account_balance_wallet,
    Icons.account_balance_wallet_outlined,
    Icons.attach_money,
    Icons.attach_money_outlined,
    Icons.money,
    Icons.money_outlined,
    Icons.money_off,
    Icons.money_off_outlined,
    Icons.credit_card,
    Icons.credit_card_outlined,
    Icons.payment,
    Icons.payment_outlined,
    Icons.receipt,
    Icons.receipt_outlined,
    Icons.receipt_long,
    Icons.receipt_long_outlined,
    Icons.account_circle,
    Icons.account_circle_outlined,
    Icons.person_add,
    Icons.person_add_outlined,
    Icons.group_add,
    Icons.group_add_outlined,
    Icons.people,
    Icons.people_outlined,
    Icons.people_alt,
    Icons.people_alt_outlined,
    Icons.engineering,
    Icons.engineering_outlined,
    Icons.architecture,
    Icons.architecture_outlined,
    Icons.construction,
    Icons.construction_outlined,
    Icons.handyman,
    Icons.handyman_outlined,
    Icons.build,
    Icons.build_outlined,
    Icons.build_circle,
    Icons.build_circle_outlined,
    Icons.settings,
    Icons.settings_outlined,
    Icons.settings_applications,
    Icons.settings_applications_outlined,
    Icons.settings_backup_restore,
    Icons.settings_backup_restore_outlined,
    Icons.settings_brightness,
    Icons.settings_brightness_outlined,
    Icons.settings_cell,
    Icons.settings_cell_outlined,
    Icons.settings_ethernet,
    Icons.settings_ethernet_outlined,
    Icons.settings_input_antenna,
    Icons.settings_input_antenna_outlined,
    Icons.settings_input_component,
    Icons.settings_input_component_outlined,
    Icons.settings_input_composite,
    Icons.settings_input_composite_outlined,
    Icons.settings_input_hdmi,
    Icons.settings_input_hdmi_outlined,
    Icons.settings_input_svideo,
    Icons.settings_input_svideo_outlined,
    Icons.settings_overscan,
    Icons.settings_overscan_outlined,
    Icons.settings_phone,
    Icons.settings_phone_outlined,
    Icons.settings_power,
    Icons.settings_power_outlined,
    Icons.settings_remote,
    Icons.settings_remote_outlined,
    Icons.settings_voice,
    Icons.settings_voice_outlined,
    Icons.manage_accounts,
    Icons.manage_accounts_outlined,
    Icons.admin_panel_settings,
    Icons.admin_panel_settings_outlined,
    Icons.security,
    Icons.security_outlined,
    Icons.verified_user,
    Icons.verified_user_outlined,
    Icons.verified,
    Icons.verified_outlined,
    Icons.assignment,
    Icons.assignment_outlined,
    Icons.assignment_ind,
    Icons.assignment_ind_outlined,
    Icons.assignment_late,
    Icons.assignment_late_outlined,
    Icons.assignment_return,
    Icons.assignment_return_outlined,
    Icons.assignment_returned,
    Icons.assignment_returned_outlined,
    Icons.assignment_turned_in,
    Icons.assignment_turned_in_outlined,
    Icons.assessment,
    Icons.assessment_outlined,
    Icons.quiz,
    Icons.quiz_outlined,
    Icons.analytics,
    Icons.analytics_outlined,
    Icons.trending_up,
    Icons.trending_up_outlined,
    Icons.trending_down,
    Icons.trending_down_outlined,
    Icons.trending_flat,
    Icons.trending_flat_outlined,
    Icons.bar_chart,
    Icons.bar_chart_outlined,
    Icons.pie_chart,
    Icons.bubble_chart,
    Icons.bubble_chart_outlined,
    Icons.show_chart,
    Icons.show_chart_outlined,
    Icons.insert_chart,
    Icons.insert_chart_outlined,
    Icons.insert_chart_outlined_outlined,
    Icons.multiline_chart,
    Icons.multiline_chart_outlined,
    Icons.scatter_plot,
    Icons.scatter_plot_outlined,
    Icons.candlestick_chart,
    Icons.candlestick_chart_outlined,
    Icons.leaderboard,
    Icons.leaderboard_outlined,
    Icons.insights,
    Icons.insights_outlined,
    Icons.query_stats,
    Icons.query_stats_outlined,
    Icons.schema,
    Icons.schema_outlined,
    Icons.timeline,
    Icons.timeline_outlined,
    Icons.update,
    Icons.update_outlined,
    Icons.update_disabled,
    Icons.update_disabled_outlined,
    Icons.access_time,
    Icons.access_time_outlined,
    Icons.access_time_filled,
    Icons.access_time_filled_outlined,
    Icons.schedule,
    Icons.schedule_outlined,
    Icons.schedule_send,
    Icons.schedule_send_outlined,
    Icons.today,
    Icons.today_outlined,
    Icons.event,
    Icons.event_outlined,
    Icons.event_available,
    Icons.event_available_outlined,
    Icons.event_busy,
    Icons.event_busy_outlined,
    Icons.event_note,
    Icons.event_note_outlined,
    Icons.event_seat,
    Icons.event_seat_outlined,
    Icons.calendar_today,
    Icons.calendar_today_outlined,
    Icons.calendar_month,
    Icons.calendar_month_outlined,
    Icons.calendar_view_day,
    Icons.calendar_view_day_outlined,
    Icons.calendar_view_week,
    Icons.calendar_view_week_outlined,
    Icons.calendar_view_month,
    Icons.calendar_view_month_outlined,
    Icons.work_off,
    Icons.work_off_outlined,
    Icons.work_outline,
    Icons.work_outline_outlined,
    Icons.work_history,
    Icons.work_history_outlined,
    Icons.work,
    Icons.work_outlined,
    Icons.business_center,
    Icons.business_center_outlined,
    Icons.corporate_fare,
    Icons.corporate_fare_outlined,
    Icons.meeting_room,
    Icons.meeting_room_outlined,
    Icons.room_service,
    Icons.room_service_outlined,
    Icons.hotel,
    Icons.hotel_outlined,
    Icons.apartment,
    Icons.apartment_outlined,
    Icons.house,
    Icons.house_outlined,
    Icons.home_work,
    Icons.home_work_outlined,
    Icons.location_city,
    Icons.location_city_outlined,
    Icons.location_on,
    Icons.location_on_outlined,
    Icons.location_off,
    Icons.location_off_outlined,
    Icons.location_searching,
    Icons.location_searching_outlined,
    Icons.location_disabled,
    Icons.location_disabled_outlined,
    Icons.my_location,
    Icons.my_location_outlined,
    Icons.place,
    Icons.place_outlined,
    Icons.navigation,
    Icons.navigation_outlined,
    Icons.directions,
    Icons.directions_outlined,
    Icons.directions_car,
    Icons.directions_car_outlined,
    Icons.directions_bus,
    Icons.directions_bus_outlined,
    Icons.directions_bike,
    Icons.directions_bike_outlined,
    Icons.directions_walk,
    Icons.directions_walk_outlined,
    Icons.directions_boat,
    Icons.directions_boat_outlined,
    Icons.directions_subway,
    Icons.directions_subway_outlined,
    Icons.directions_transit,
    Icons.directions_transit_outlined,
    Icons.directions_run,
    Icons.directions_run_outlined,
    Icons.directions_railway,
    Icons.directions_railway_outlined,
    Icons.directions_ferry,
    Icons.directions_ferry_outlined,
    Icons.flight,
    Icons.flight_outlined,
    Icons.train,
    Icons.train_outlined,
    Icons.local_taxi,
    Icons.local_taxi_outlined,
    Icons.local_shipping,
    Icons.local_shipping_outlined,
    Icons.local_airport,
    Icons.local_airport_outlined,
    Icons.local_hotel,
    Icons.local_hotel_outlined,
    Icons.local_restaurant,
    Icons.local_restaurant_outlined,
    Icons.local_cafe,
    Icons.local_cafe_outlined,
    Icons.local_bar,
    Icons.local_bar_outlined,
    Icons.local_pizza,
    Icons.local_pizza_outlined,
    Icons.local_dining,
    Icons.local_dining_outlined,
    Icons.local_drink,
    Icons.local_drink_outlined,
    Icons.local_gas_station,
    Icons.local_gas_station_outlined,
    Icons.local_pharmacy,
    Icons.local_pharmacy_outlined,
    Icons.local_hospital,
    Icons.local_hospital_outlined,
    Icons.local_police,
    Icons.local_police_outlined,
    Icons.local_fire_department,
    Icons.local_fire_department_outlined,
    Icons.local_post_office,
    Icons.local_post_office_outlined,
    Icons.local_atm,
    Icons.local_atm_outlined,
    Icons.local_mall,
    Icons.local_mall_outlined,
    Icons.local_movies,
    Icons.local_movies_outlined,
    Icons.local_play,
    Icons.local_play_outlined,
    Icons.local_activity,
    Icons.local_activity_outlined,
    Icons.local_parking,
    Icons.local_parking_outlined,
    Icons.local_offer,
    Icons.local_offer_outlined,
    Icons.local_florist,
    Icons.local_florist_outlined,
    Icons.local_car_wash,
    Icons.local_car_wash_outlined,
    Icons.local_laundry_service,
    Icons.local_laundry_service_outlined,
    Icons.celebration,
    Icons.celebration_outlined,
    Icons.cake,
    Icons.cake_outlined,
    Icons.public,
    Icons.public_outlined,
    
    // Font Awesome カラフルアイコン（実際に存在するもののみ）
    FontAwesomeIcons.google,
    FontAwesomeIcons.github,
    FontAwesomeIcons.youtube,
    FontAwesomeIcons.twitter,
    FontAwesomeIcons.facebook,
    FontAwesomeIcons.instagram,
    FontAwesomeIcons.linkedin,
    FontAwesomeIcons.discord,
    FontAwesomeIcons.slack,
    FontAwesomeIcons.spotify,
    FontAwesomeIcons.amazon,
    FontAwesomeIcons.apple,
    FontAwesomeIcons.microsoft,
    FontAwesomeIcons.chrome,
    FontAwesomeIcons.firefox,
    FontAwesomeIcons.safari,
    FontAwesomeIcons.edge,
    FontAwesomeIcons.opera,
    FontAwesomeIcons.steam,
    FontAwesomeIcons.reddit,
    FontAwesomeIcons.stackOverflow,
    FontAwesomeIcons.gitlab,
    FontAwesomeIcons.bitbucket,
    FontAwesomeIcons.docker,
    FontAwesomeIcons.aws,
    FontAwesomeIcons.wordpress,
    FontAwesomeIcons.shopify,
    FontAwesomeIcons.stripe,
    FontAwesomeIcons.paypal,
    FontAwesomeIcons.bitcoin,
    FontAwesomeIcons.ethereum,
    FontAwesomeIcons.telegram,
    FontAwesomeIcons.whatsapp,
    FontAwesomeIcons.skype,
    FontAwesomeIcons.dropbox,
    FontAwesomeIcons.box,
    FontAwesomeIcons.figma,
    FontAwesomeIcons.blender,
    FontAwesomeIcons.python,
    FontAwesomeIcons.react,
    FontAwesomeIcons.angular,
    FontAwesomeIcons.flutter,
    FontAwesomeIcons.bootstrap,
    FontAwesomeIcons.node,
    FontAwesomeIcons.npm,
    FontAwesomeIcons.yarn,
    FontAwesomeIcons.git,
    FontAwesomeIcons.linux,
    FontAwesomeIcons.windows,
    FontAwesomeIcons.android,
    FontAwesomeIcons.html5,
    FontAwesomeIcons.css3,
    FontAwesomeIcons.js,
    FontAwesomeIcons.php,
    FontAwesomeIcons.java,
    FontAwesomeIcons.c,
    FontAwesomeIcons.swift,
    FontAwesomeIcons.r,
    
    // ビジネス向けブランドアイコン（実際に存在するもののみ）
    FontAwesomeIcons.salesforce,
    FontAwesomeIcons.hubspot,
    FontAwesomeIcons.mailchimp,
    FontAwesomeIcons.skype,
    FontAwesomeIcons.slack,
    FontAwesomeIcons.trello,
    FontAwesomeIcons.dropbox,
    FontAwesomeIcons.box,
    FontAwesomeIcons.figma,
    Icons.celebration,
    Icons.celebration_outlined,
    Icons.cake,
    Icons.cake_outlined,
    Icons.local_pizza,
    Icons.local_pizza_outlined,
    Icons.local_cafe,
    Icons.local_cafe_outlined,
    Icons.local_restaurant,
    Icons.local_restaurant_outlined,
    Icons.local_bar,
    Icons.local_bar_outlined,
    Icons.local_hotel,
    Icons.local_hotel_outlined,
    Icons.local_gas_station,
    Icons.local_gas_station_outlined,
    Icons.local_pharmacy,
    Icons.local_pharmacy_outlined,
    Icons.local_hospital,
    Icons.local_hospital_outlined,
    Icons.local_police,
    Icons.local_police_outlined,
    Icons.local_fire_department,
    Icons.local_fire_department_outlined,
    Icons.local_post_office,
    Icons.local_post_office_outlined,
    Icons.local_atm,
    Icons.local_atm_outlined,
    Icons.local_mall,
    Icons.local_mall_outlined,
    Icons.local_movies,
    Icons.local_movies_outlined,
    Icons.local_play,
    Icons.local_play_outlined,
    Icons.local_activity,
    Icons.local_activity_outlined,
    Icons.local_parking,
    Icons.local_parking_outlined,
    Icons.local_taxi,
    Icons.local_taxi_outlined,
    Icons.local_airport,
    Icons.local_airport_outlined,
    Icons.local_shipping,
    Icons.local_shipping_outlined,
    Icons.local_offer,
    Icons.local_offer_outlined,
    Icons.local_florist,
    Icons.local_florist_outlined,
    Icons.local_car_wash,
    Icons.local_car_wash_outlined,
    Icons.local_laundry_service,
    Icons.local_laundry_service_outlined,
    Icons.local_dining,
    Icons.local_dining_outlined,
    Icons.local_drink,
    Icons.local_drink_outlined,
    // 地球アイコンとその他のアイコンを追加
    Icons.public_outlined,
    Icons.language,
    Icons.language_outlined,
    Icons.web,
    Icons.web_outlined,
    Icons.computer,
    Icons.computer_outlined,
    Icons.laptop,
    Icons.laptop_outlined,
    Icons.tablet,
    Icons.tablet_outlined,
    Icons.phone,
    Icons.phone_outlined,
    Icons.smartphone,
    Icons.smartphone_outlined,
    Icons.watch,
    Icons.watch_outlined,
    Icons.headphones,
    Icons.headphones_outlined,
    Icons.speaker,
    Icons.speaker_outlined,
    Icons.tv,
    Icons.tv_outlined,
    Icons.radio,
    Icons.radio_outlined,
    Icons.camera_alt,
    Icons.camera_alt_outlined,
    Icons.camera,
    Icons.camera_outlined,
    Icons.videocam,
    Icons.videocam_outlined,
    Icons.mic,
    Icons.mic_outlined,
    Icons.keyboard,
    Icons.keyboard_outlined,
    Icons.mouse,
    Icons.mouse_outlined,
    Icons.print,
    Icons.print_outlined,
    Icons.scanner,
    Icons.scanner_outlined,
    Icons.fax,
    Icons.fax_outlined,
    Icons.router,
    Icons.router_outlined,
    Icons.wifi,
    Icons.wifi_outlined,
    Icons.bluetooth,
    Icons.bluetooth_outlined,
    Icons.nfc,
    Icons.nfc_outlined,
    Icons.gps_fixed,
    Icons.gps_fixed_outlined,
    Icons.location_on,
    Icons.location_on_outlined,
    Icons.map,
    Icons.map_outlined,
    Icons.navigation,
    Icons.navigation_outlined,
    Icons.directions,
    Icons.directions_outlined,
    Icons.compass_calibration,
    Icons.compass_calibration_outlined,
    Icons.explore,
    Icons.explore_outlined,
    Icons.travel_explore,
    Icons.travel_explore_outlined,
    Icons.flight,
    Icons.flight_outlined,
    Icons.train,
    Icons.train_outlined,
    Icons.directions_car,
    Icons.directions_car_outlined,
    Icons.directions_bus,
    Icons.directions_bus_outlined,
    Icons.directions_bike,
    Icons.directions_bike_outlined,
    Icons.directions_walk,
    Icons.directions_walk_outlined,
    Icons.directions_boat,
    Icons.directions_boat_outlined,
    Icons.directions_subway,
    Icons.directions_subway_outlined,
    Icons.directions_transit,
    Icons.directions_transit_outlined,
    Icons.directions_run,
    Icons.directions_run_outlined,
    Icons.directions_railway,
    Icons.directions_railway_outlined,
    Icons.directions_ferry,
    Icons.directions_ferry_outlined,
    // 地球アイコン（Windowsシステムアイコンにも含まれる）
    Icons.public,
    Icons.public_outlined,
  ];
} 

// ショートカット項目ウィジェット
class _ShortcutItem extends StatelessWidget {
  final String shortcut;
  final String description;

  const _ShortcutItem(this.shortcut, this.description);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(description),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          shortcut,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}