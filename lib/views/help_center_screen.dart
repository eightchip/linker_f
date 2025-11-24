import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../services/snackbar_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _ManualSection {
  _ManualSection({
    required this.id,
    required this.title,
    required this.level,
    required this.markdown,
  }) : key = GlobalKey();

  final String id;
  final String title;
  final int level;
  final String markdown;
  final GlobalKey key;
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const Map<String, String> _screenshotMap = {
    'link-menu': 'assets/help/link_menu.png',
    'task-menu': 'assets/help/task_menu.png',
    'task-grid': 'assets/help/task_grid.png',
    'schedule-list': 'assets/help/schedule_list.png',
  };

  static const Map<String, String> _videoMap = {
    'add_new_group': 'assets/help/videos/add_new_group.mp4',
    'new_memo_task_add': 'assets/help/videos/new_memo_task_add.mp4',
    'task_screen': 'assets/help/videos/task_screen.mp4',
  };

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<_ManualSection> _sections = [];
  List<_ManualSection> _filteredSections = [];
  bool _isLoading = true;
  String? _error;
  String _rawManual = '';

  @override
  void initState() {
    super.initState();
    _loadManual();
    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadManual() async {
    try {
      final manual = await rootBundle.loadString('Link_Navigator_取扱説明書.md');
      final parsed = _parseManual(manual);
      setState(() {
        _rawManual = manual;
        _sections = parsed;
        _filteredSections = parsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'マニュアルの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  List<_ManualSection> _parseManual(String manual) {
    final lines = manual.split('\n');
    final sections = <_ManualSection>[];
    final buffer = StringBuffer();
    String? currentId;
    String? currentTitle;
    int currentLevel = 1;

    String slugify(String input) {
      final slug = input.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9\u3040-\u30ff\u3400-\u9fff -]+'),
        '-',
      );
      return slug.replaceAll(RegExp('-+'), '-');
    }

    void flushSection() {
      final id = currentId;
      final title = currentTitle;
      if (id == null || title == null) return;
      final markdown =
          '#' * currentLevel +
          ' ' +
          title +
          (buffer.isNotEmpty ? '\n${buffer.toString()}' : '');
      sections.add(
        _ManualSection(
          id: id,
          title: title,
          level: currentLevel,
          markdown: markdown,
        ),
      );
      buffer.clear();
    }

    final headingReg = RegExp(r'^(#{1,4})\s+(.+)$');

    for (final rawLine in lines) {
      final line = rawLine.replaceAll('\r', '');
      final match = headingReg.firstMatch(line);
      if (match != null) {
        if (currentId != null) {
          flushSection();
        }
        final hashes = match.group(1)!;
        final title = match.group(2)!.trim();
        currentLevel = hashes.length;
        currentId = '${slugify(title)}-${sections.length}';
        currentTitle = title;
      } else {
        buffer.writeln(line);
      }
    }
    // flush last
    if (currentId != null) {
      flushSection();
    }

    // fallback entire manual if no headings parsed
    if (sections.isEmpty) {
      sections.add(
        _ManualSection(
          id: 'manual-root',
          title: 'マニュアル',
          level: 1,
          markdown: manual,
        ),
      );
    }

    return sections;
  }

  void _handleSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSections = _sections;
      } else {
        _filteredSections = _sections
            .where((section) => section.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _showScreenshot(String screenshotId) async {
    final assetPath = _screenshotMap[screenshotId];
    if (assetPath == null) {
      if (mounted) {
        SnackBarService.showWarning(
          context,
          'スクリーンショット「$screenshotId」は登録されていません。',
        );
      }
      return;
    }

    try {
      final data = await rootBundle.load(assetPath);
      if (!mounted) return;
      final bytes = data.buffer.asUint8List();
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: Colors.black.withOpacity(0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                width: MediaQuery.of(context).size.width * 0.8,
                child: InteractiveViewer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                assetPath.split('/').last,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarService.showWarning(
        context,
        'スクリーンショットを読み込めませんでした。\nassets/help フォルダに画像を配置してください。\n($assetPath)',
      );
    }
  }

  Future<void> _showVideo(String videoId) async {
    final source = _videoMap[videoId];
    if (source == null) {
      if (mounted) {
        SnackBarService.showWarning(
          context,
          '動画「$videoId」は登録されていません。assets/help/videos フォルダを確認してください。',
        );
      }
      return;
    }

    VideoPlayerController? videoController;
    ChewieController? chewieController;
    File? tempVideoFile;
    bool launchedExternally = false;
    try {
      if (source.startsWith('http')) {
        videoController = VideoPlayerController.networkUrl(Uri.parse(source));
      } else {
        tempVideoFile = await _copyAssetToTemp(source);
        if (tempVideoFile == null) {
          throw Exception('アセット動画を一時ファイルへ展開できませんでした。');
        }
        videoController = VideoPlayerController.file(tempVideoFile);
      }
      await videoController.initialize();
      chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: false,
        allowMuting: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          final aspectRatio =
              videoController!.value.aspectRatio > 0 ? videoController.value.aspectRatio : 16 / 9;
          return Dialog(
            insetPadding: const EdgeInsets.all(24),
            backgroundColor: Colors.black.withOpacity(0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Chewie(controller: chewieController!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  source.startsWith('http') ? source : source.split('/').last,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    } catch (e, stack) {
      debugPrint('HelpCenter: video load error for $source -> $e');
      debugPrintStack(stackTrace: stack);

      if (!source.startsWith('http')) {
        tempVideoFile ??= await _copyAssetToTemp(source);
        if (tempVideoFile != null && await tempVideoFile.exists()) {
          try {
            await Process.start(
              tempVideoFile.path,
              const [],
              mode: ProcessStartMode.normal,
            );
            launchedExternally = true;
            if (mounted) {
              SnackBarService.showInfo(
                context,
                '内蔵プレーヤーで再生できなかったため、既定のアプリで動画を開きました。',
              );
            }
          } catch (launchError, launchStack) {
            debugPrint('HelpCenter: fallback launch error -> $launchError');
            debugPrintStack(stackTrace: launchStack);
            try {
              await Process.run(
                'cmd',
                ['/c', 'start', '', tempVideoFile.path],
                runInShell: true,
              );
              launchedExternally = true;
              if (mounted) {
                SnackBarService.showInfo(
                  context,
                  '既定のアプリで動画を開きました。',
                );
              }
            } catch (fallbackError, fallbackStack) {
              debugPrint('HelpCenter: secondary fallback error -> $fallbackError');
              debugPrintStack(stackTrace: fallbackStack);
            }
          }
        }
      }

      if (!launchedExternally && mounted) {
        SnackBarService.showWarning(
          context,
          '動画を再生できませんでした。\n$e\n($source)',
        );
      }
    } finally {
      chewieController?.dispose();
      videoController?.dispose();
      if (!launchedExternally &&
          tempVideoFile != null &&
          await tempVideoFile.exists()) {
        try {
          await tempVideoFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<File?> _copyAssetToTemp(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final file = File('${tempDir.path}/$fileName');
      final Uint8List bytes =
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e, stack) {
      debugPrint('HelpCenter: asset copy error for $assetPath -> $e');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  Future<void> _handleLinkTap(String text, String? href, String? title) async {
    if (href == null) {
      return;
    }

    if (href.startsWith('screenshot:')) {
      final screenshotId = href.substring('screenshot:'.length);
      await _showScreenshot(screenshotId);
      return;
    }

    if (href.startsWith('video:')) {
      final videoId = href.substring('video:'.length);
      await _showVideo(videoId);
      return;
    }

    final uri = Uri.tryParse(href);
    if (uri == null) {
      if (mounted) {
        SnackBarService.showWarning(context, 'リンクを開けませんでした: $href');
      }
      return;
    }

    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        SnackBarService.showWarning(context, 'リンクを開けませんでした: $href');
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showWarning(context, 'リンクを開けませんでした: $href');
      }
    }
  }

  Future<void> _exportManualAsHtml() async {
    try {
      if (_rawManual.isEmpty) {
        throw Exception('マニュアルが読み込まれていません');
      }

      final htmlBody = md.markdownToHtml(
        _rawManual,
        extensionSet: md.ExtensionSet.gitHubWeb,
        inlineSyntaxes: [
          md.AutolinkExtensionSyntax(),
        ],
      );
      final fullHtml =
          '''<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <title>Link Navigator ヘルプセンター</title>
  <style>
    :root {
      color-scheme: light;
    }
    body {
      font-family: "Yu Gothic", "Hiragino Kaku Gothic ProN", sans-serif;
      margin: 0;
      padding: 48px 32px;
      line-height: 1.7;
      background: linear-gradient(135deg, #e0f2fe 0%, #d1fae5 100%);
      color: #1e293b;
      display: flex;
      justify-content: center;
    }
    .manual {
      max-width: 960px;
      width: 100%;
      background: #ffffff;
      border-radius: 28px;
      padding: 56px 64px;
      box-shadow: 0 18px 45px rgba(37, 99, 235, 0.12), 0 12px 26px rgba(14, 184, 166, 0.14);
    }
    h1 {
      font-size: 2.2em;
      color: #2563eb;
      margin-bottom: 0.6em;
      border-bottom: 4px solid rgba(37, 99, 235, 0.25);
      padding-bottom: 0.35em;
    }
    h2 {
      font-size: 1.6em;
      color: #0d9488;
      margin-top: 2.4em;
      margin-bottom: 0.8em;
      position: relative;
      padding-left: 16px;
    }
    h2::before {
      content: "";
      position: absolute;
      left: 0;
      top: 8px;
      width: 6px;
      height: calc(100% - 16px);
      border-radius: 3px;
      background: linear-gradient(180deg, rgba(37, 99, 235, 0.8), rgba(14, 184, 166, 0.8));
    }
    h3 {
      font-size: 1.3em;
      color: #059669;
      margin-top: 1.8em;
      margin-bottom: 0.6em;
    }
    p, ul, ol {
      margin: 0 0 1.2em;
    }
    ul, ol {
      padding-left: 1.4em;
    }
    li {
      margin-bottom: 0.4em;
    }
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 20px 0;
      background: rgba(255, 255, 255, 0.96);
      border-radius: 18px;
      overflow: hidden;
      box-shadow: inset 0 0 0 1px rgba(37, 99, 235, 0.1);
    }
    th, td {
      border: 1px solid rgba(37, 99, 235, 0.18);
      padding: 12px 16px;
      text-align: left;
    }
    th {
      background: rgba(37, 99, 235, 0.1);
      color: #1e40af;
      font-weight: 600;
    }
    blockquote {
      margin: 1.4em 0;
      padding: 18px 24px;
      background: rgba(14, 184, 166, 0.1);
      border-left: 6px solid rgba(14, 184, 166, 0.7);
      border-radius: 18px;
      color: #0f766e;
    }
    pre {
      background: rgba(42, 45, 54, 0.08);
      padding: 14px 18px;
      border-radius: 16px;
      overflow-x: auto;
    }
    code {
      background: rgba(37, 99, 235, 0.1);
      padding: 2px 6px;
      border-radius: 6px;
      font-size: 0.95em;
      color: #1e40af;
    }
    img {
      max-width: 100%;
      border-radius: 16px;
      box-shadow: 0 12px 30px rgba(0, 0, 0, 0.12);
      margin: 24px 0;
    }
    a {
      color: #2563eb;
      font-weight: 600;
      text-decoration: none;
      border-bottom: 1px dashed rgba(37, 99, 235, 0.5);
    }
    a:hover {
      border-bottom-style: solid;
    }
    @media print {
      body {
        background: #ffffff;
        padding: 0;
      }
      .manual {
        box-shadow: none;
        border-radius: 0;
        padding: 32px 28px;
        margin: 0;
      }
      a {
        color: inherit;
        border-bottom: none;
      }
    }
  </style>
</head>
<body>
  <main class="manual">
    $htmlBody
  </main>
</body>
</html>''';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/link_navigator_manual.html');
      await file.writeAsString(fullHtml);
      final uri = Uri.file(file.path);
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        SnackBarService.showError(
          context,
          'HTMLファイルを開けませんでした。ファイルを直接参照してください。',
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarService.showError(
        context,
        'HTML出力に失敗しました: $e',
      );
    }
  }

  Future<void> _scrollToSection(_ManualSection section) async {
    final context = section.key.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        alignment: 0.05,
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildHeroCard(
    ThemeData theme, {
    required Color accentColor,
    required Color secondaryColor,
    required Color tertiaryColor,
    required ColorScheme colorScheme,
  }) {
    final highlightTags = [
      'ドラッグ＆ドロップ',
      'Google連携',
      '通知・アラート',
      'カラーテーマ',
      'ショートカット',
    ];

    final cardColor = Color.alphaBlend(
      secondaryColor.withOpacity(0.12),
      colorScheme.surface,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withOpacity(0.18)),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Link Navigator 取扱説明書',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'アプリをすぐに使いこなすためのガイドです。気になる項目を左のナビから選択してください。',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.78),
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: highlightTags
                .map(
                  (tag) => Chip(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    backgroundColor: Color.alphaBlend(
                      tertiaryColor.withOpacity(0.18),
                      colorScheme.surface,
                    ),
                    avatar: CircleAvatar(
                      backgroundColor: tertiaryColor.withOpacity(0.8),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: colorScheme.onTertiary,
                      ),
                    ),
                    label: Text(
                      tag,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required Color accentColor,
    required Color secondaryColor,
    required Color tertiaryColor,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffe0f2fe), Color(0xffd1fae5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final useWideLayout = constraints.maxWidth >= 900;
          final tocWidth = useWideLayout ? 260.0 : constraints.maxWidth;
          final baseTextColor = theme.brightness == Brightness.dark
              ? colorScheme.onSurface.withOpacity(0.94)
              : Colors.grey.shade900;
          final secondaryTextColor = theme.brightness == Brightness.dark
              ? colorScheme.onSurfaceVariant.withOpacity(0.88)
              : Colors.grey.shade700;
          final sectionColors = <Color>[
            colorScheme.surface,
            Color.alphaBlend(
              (theme.brightness == Brightness.dark
                      ? accentColor.withOpacity(0.08)
                      : accentColor.withOpacity(0.04)),
              colorScheme.surface,
            ),
            Color.alphaBlend(
              (theme.brightness == Brightness.dark
                      ? secondaryColor.withOpacity(0.09)
                      : secondaryColor.withOpacity(0.04)),
              colorScheme.surface,
            ),
            Color.alphaBlend(
              (theme.brightness == Brightness.dark
                      ? tertiaryColor.withOpacity(0.09)
                      : tertiaryColor.withOpacity(0.04)),
              colorScheme.surface,
            ),
          ];
          final textTheme = theme.textTheme;
          final heroCard = _buildHeroCard(
            theme,
            accentColor: accentColor,
            secondaryColor: secondaryColor,
            tertiaryColor: tertiaryColor,
            colorScheme: colorScheme,
          );

          final content = Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heroCard,
                    const SizedBox(height: 24),
                    ..._sections.map(
                        (section) => Container(
                          key: section.key,
                          margin: const EdgeInsets.only(bottom: 28),
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          decoration: BoxDecoration(
                            color:
                                sectionColors[(section.level - 1)
                                    .clamp(0, sectionColors.length - 1)
                                    .toInt()],
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withOpacity(0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: MarkdownBody(
                            data: section.markdown,
                            onTapLink: (text, href, title) =>
                                _handleLinkTap(text, href, title),
                            styleSheet: MarkdownStyleSheet.fromTheme(theme)
                                .copyWith(
                                  h1: textTheme.headlineSmall?.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  h2: textTheme.titleLarge?.copyWith(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  h3: textTheme.titleMedium?.copyWith(
                                    color: theme.brightness == Brightness.dark
                                        ? accentColor.withOpacity(0.9)
                                        : accentColor.withOpacity(0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  p: textTheme.bodyLarge?.copyWith(
                                    height: 1.8,
                                    color: baseTextColor,
                                  ),
                                  listBullet: textTheme.bodyLarge?.copyWith(
                                    color: baseTextColor,
                                  ),
                                  em: textTheme.bodyLarge?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: secondaryTextColor,
                                  ),
                                  strong: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: baseTextColor,
                                  ),
                                  tableBorder: TableBorder.all(
                                    color: accentColor.withOpacity(0.18),
                                  ),
                                  tableHeadAlign: TextAlign.left,
                                  tableHead: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: baseTextColor,
                                  ),
                                  tableBody: textTheme.bodyMedium?.copyWith(
                                    color: baseTextColor,
                                  ),
                                  tableCellsPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  blockquoteDecoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme.primary.withOpacity(0.12)
                                        : Colors.white.withOpacity(0.58),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border(
                                      left: BorderSide(
                                        color: secondaryColor.withOpacity(0.8),
                                        width: 6,
                                      ),
                                    ),
                                  ),
                                  blockquotePadding: const EdgeInsets.fromLTRB(
                                    18,
                                    14,
                                    18,
                                    14,
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme.surfaceContainerHighest
                                            .withOpacity(0.4)
                                        : Colors.black.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  codeblockPadding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    12,
                                  ),
                                  horizontalRuleDecoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: accentColor.withOpacity(0.2),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );

          final toc = SizedBox(
             width: tocWidth,
             child: Container(
               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
               decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.45)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      color: Color.alphaBlend(
                        accentColor.withOpacity(0.07),
                        colorScheme.surface,
                      ),
                      border: Border(
                        bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'コンテンツ一覧',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '気になる章をクリックしてジャンプ！',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                   Padding(
                     padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                     child: TextField(
                       controller: _searchController,
                       decoration: InputDecoration(
                         prefixIcon: Icon(Icons.search, color: secondaryColor),
                         labelText: 'キーワードで検索',
                         filled: true,
                         fillColor: colorScheme.surface,
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(16),
                           borderSide: BorderSide(
                             color: accentColor.withOpacity(0.2),
                           ),
                         ),
                         enabledBorder: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(16),
                           borderSide: BorderSide(
                             color: accentColor.withOpacity(0.2),
                           ),
                         ),
                         focusedBorder: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(16),
                           borderSide: BorderSide(
                             color: secondaryColor.withOpacity(0.8),
                             width: 2,
                           ),
                         ),
                       ),
                     ),
                   ),
                   const SizedBox(height: 18),
                   Expanded(
                     child: Scrollbar(
                       radius: const Radius.circular(16),
                       scrollbarOrientation: ScrollbarOrientation.right,
                       child: ListView.builder(
                         padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                         itemCount: _filteredSections.length,
                         itemBuilder: (context, index) {
                           final item = _filteredSections[index];
                           final isDisabled = !_sections.contains(item);
                           final indent = ((item.level - 1).clamp(
                             0,
                             4,
                           )).toDouble();
                          final baseOpacity = 0.05 + (item.level * 0.05);
                          final clampedOpacity =
                              (baseOpacity.clamp(0.08, 0.22)).toDouble();
                          final highlightColor =
                              (item.level == 1 ? accentColor : secondaryColor)
                                  .withOpacity(clampedOpacity);
                          final tileColor = Color.alphaBlend(
                            highlightColor,
                            colorScheme.surface,
                          );
 
                           return Container(
                             margin: const EdgeInsets.only(bottom: 10),
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(16),
                               color: colorScheme.surface,
                               boxShadow: [
                                 BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 6),
                                ),
                               ],
                             ),
                             child: ListTile(
                               dense: true,
                               enabled: !isDisabled,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               leading: Icon(
                                 Icons.bookmark_rounded,
                                 color:
                                     (item.level == 1
                                             ? accentColor
                                             : secondaryColor)
                                         .withOpacity(0.85),
                                 size: 20,
                               ),
                               tileColor: tileColor,
                               contentPadding: EdgeInsets.only(
                                 left: 16 + indent * 12.0,
                                 right: 16,
                               ),
                               title: Text(
                                 item.title,
                                 style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                   fontWeight: item.level == 1
                                       ? FontWeight.w600
                                       : FontWeight.w500,
                                 ),
                                 maxLines: 2,
                                 overflow: TextOverflow.ellipsis,
                               ),
                               trailing: Icon(
                                 Icons.arrow_forward_ios_rounded,
                                 color: (item.level == 1
                                         ? accentColor
                                         : secondaryColor)
                                     .withOpacity(0.8),
                                 size: 14,
                               ),
                               onTap: () => _scrollToSection(item),
                             ),
                           );
                         },
                       ),
                    ),
                  ),
                ],
              ),
            ),
          );

          if (!useWideLayout) {
            return Column(
              children: [
                SizedBox(height: 360, child: toc),
                const SizedBox(height: 4),
                Expanded(child: content),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              toc,
              const VerticalDivider(width: 1, thickness: 0.6),
              content,
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;
    final secondaryColor = colorScheme.secondary;
    final tertiaryColor = colorScheme.tertiary;
    final backgroundTone = Color.alphaBlend(
      colorScheme.primary.withOpacity(0.02),
      colorScheme.surface,
    );
    final appBarColor = colorScheme.surface;
 
    return Scaffold(
      backgroundColor: backgroundTone,
      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withOpacity(0.18)),
              ),
              child: Icon(Icons.auto_awesome, color: accentColor),
            ),
            const SizedBox(width: 12),
            Text(
              'ヘルプセンター',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.print_outlined, color: accentColor),
            tooltip: 'HTML出力・印刷',
            onPressed: _isLoading ? null : _exportManualAsHtml,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: secondaryColor),
            tooltip: '再読み込み',
            onPressed: _isLoading ? null : _loadManual,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(16),
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError(context)
          : _sections.isEmpty
          ? _buildEmptyState(context)
          : _buildContent(
              context,
              accentColor: accentColor,
              secondaryColor: secondaryColor,
              tertiaryColor: tertiaryColor,
            ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? '未知のエラー',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadManual,
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 48),
          const SizedBox(height: 16),
          const Text('ヘルプコンテンツが見つかりませんでした。'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadManual, child: const Text('再読み込み')),
        ],
      ),
    );
  }
}
