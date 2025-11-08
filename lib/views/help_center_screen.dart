import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
      final slug = input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u3040-\u30ff\u3400-\u9fff -]+'), '-');
      return slug.replaceAll(RegExp('-+'), '-');
    }

    void flushSection() {
      if (currentId == null || currentTitle == null) return;
      final markdown = '#'*currentLevel + ' ' + currentTitle! + (buffer.isNotEmpty ? '\n${buffer.toString()}' : '');
      sections.add(_ManualSection(
        id: currentId!,
        title: currentTitle!,
        level: currentLevel,
        markdown: markdown,
      ));
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
      sections.add(_ManualSection(
        id: 'manual-root',
        title: 'マニュアル',
        level: 1,
        markdown: manual,
      ));
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

  Future<void> _exportManualAsHtml() async {
    try {
      if (_rawManual.isEmpty) {
        throw Exception('マニュアルが読み込まれていません');
      }

      final htmlBody = md.markdownToHtml(_rawManual);
      final fullHtml = '''<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <title>Link Navigator ヘルプセンター</title>
  <style>
    body { font-family: "Yu Gothic", "Hiragino Kaku Gothic ProN", sans-serif; margin: 32px; line-height: 1.6; background-color: #fff7f5; color: #333; }
    h1, h2, h3 { color: #d95f76; }
    table { border-collapse: collapse; width: 100%; margin: 16px 0; }
    th, td { border: 1px solid #d0b7ac; padding: 8px 12px; text-align: left; }
    th { background-color: #f4e7e2; }
    code { background: #f1f1f1; padding: 2px 4px; border-radius: 4px; }
  </style>
</head>
<body>
$htmlBody
</body>
</html>''';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/link_navigator_manual.html');
      await file.writeAsString(fullHtml);
      final uri = Uri.file(file.path);
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HTMLファイルを開けませんでした。ファイルを直接参照してください。')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('HTML出力に失敗しました: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルプセンター'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'HTML出力・印刷',
            onPressed: _isLoading ? null : _exportManualAsHtml,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: _isLoading ? null : _loadManual,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(context)
              : _sections.isEmpty
                  ? _buildEmptyState(context)
                  : _buildContent(context),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
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
          ElevatedButton(
            onPressed: _loadManual,
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWideLayout = constraints.maxWidth >= 900;
        final tocWidth = useWideLayout ? 260.0 : constraints.maxWidth;
        final content = Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections
                    .map(
                      (section) => Container(
                        key: section.key,
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: MarkdownBody(
                          data: section.markdown,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            h1: Theme.of(context).textTheme.headlineSmall,
                            h2: Theme.of(context).textTheme.titleLarge,
                            h3: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );

        final toc = SizedBox(
          width: tocWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'キーワードで検索',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: _filteredSections.length,
                      itemBuilder: (context, index) {
                        final item = _filteredSections[index];
                        final isDisabled = !_sections.contains(item);
                        final indent = ((item.level - 1).clamp(0, 4)).toDouble();
                        return ListTile(
                          dense: true,
                          enabled: !isDisabled,
                          contentPadding: EdgeInsets.only(left: indent * 12.0),
                          title: Text(
                            item.title,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _scrollToSection(item),
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
              SizedBox(height: 320, child: toc),
              const Divider(height: 1),
              Expanded(child: content),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            toc,
            const VerticalDivider(width: 1),
            content,
          ],
        );
      },
    );
  }
}
