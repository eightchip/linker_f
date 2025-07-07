import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../models/group.dart';
import '../models/link_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';

class GroupCard extends StatefulWidget {
  final Group group;
  final VoidCallback onToggleCollapse;
  final VoidCallback onDeleteGroup;
  final VoidCallback onAddLink;
  final Function(String) onDeleteLink;
  final Function(LinkItem) onLaunchLink;
  final Future<void> Function(String label, String path, LinkType type)? onDropAddLink;
  final Future<void> Function(LinkItem updated) onEditLink;
  final Future<void> Function(List<LinkItem> newOrder) onReorderLinks;
  final void Function(Offset newPosition)? onMove;
  final bool isDragging;
  final void Function(String newTitle)? onEditGroupTitle;
  final void Function(Group) onFavoriteToggle;
  final void Function(Group, LinkItem) onLinkFavoriteToggle;
  final void Function(LinkItem link, String fromGroupId, String toGroupId)? onMoveLinkToGroup;
  final void Function(String, {IconData? icon, Color? color}) onShowMessage;

  const GroupCard({
    Key? key,
    required this.group,
    required this.onToggleCollapse,
    required this.onDeleteGroup,
    required this.onAddLink,
    required this.onDeleteLink,
    required this.onLaunchLink,
    this.onDropAddLink,
    required this.onEditLink,
    required this.onReorderLinks,
    this.onMove,
    this.isDragging = false,
    this.onEditGroupTitle,
    required this.onFavoriteToggle,
    required this.onLinkFavoriteToggle,
    this.onMoveLinkToGroup,
    required this.onShowMessage,
  }) : super(key: key);

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  bool _isDropTarget = false;

  @override
  Widget build(BuildContext context) {
    final isDropOrHover = _isDropTarget || widget.isDragging;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: isDropOrHover ? Colors.amber : widget.group.color != null ? Color(widget.group.color!) : Colors.grey.shade300,
          width: isDropOrHover ? 8 : 4,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isDropOrHover)
            BoxShadow(
              color: (widget.group.color != null ? Color(widget.group.color!) : Colors.amber).withOpacity(0.5),
              blurRadius: 32,
              spreadRadius: 8,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(isDropOrHover ? 0.18 : 0.08),
            blurRadius: isDropOrHover ? 24 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropTarget(
        onDragEntered: (detail) => setState(() => _isDropTarget = true),
        onDragExited: (detail) => setState(() => _isDropTarget = false),
        onDragDone: (detail) {
          setState(() => _isDropTarget = false);
          _handleDrop(context, detail);
        },
        child: Card(
          elevation: isDropOrHover ? 24 : 6,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.transparent, width: 0),
          ),
          child: _GroupCardContent(
            group: widget.group,
            isDragging: widget.isDragging,
            onToggleCollapse: widget.onToggleCollapse,
            onDeleteGroup: widget.onDeleteGroup,
            onAddLink: widget.onAddLink,
            onDeleteLink: widget.onDeleteLink,
            onLaunchLink: widget.onLaunchLink,
            onDropAddLink: widget.onDropAddLink,
            onEditLink: widget.onEditLink,
            onReorderLinks: widget.onReorderLinks,
            onMove: widget.onMove,
            onEditGroupTitle: widget.onEditGroupTitle,
            onFavoriteToggle: widget.onFavoriteToggle,
            onLinkFavoriteToggle: widget.onLinkFavoriteToggle,
            onMoveLinkToGroup: widget.onMoveLinkToGroup,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms);
  }

  void _handleDrop(BuildContext context, dynamic detail) async {
    bool added = false;
    List<String> failed = [];
    if (detail.files != null && detail.files.isNotEmpty) {
      for (final file in detail.files) {
        final path = file.path;
        final ext = p.extension(path).toLowerCase();
        LinkType type;
        if (path.startsWith('http://') || path.startsWith('https://')) {
          type = LinkType.url;
          if (widget.onDropAddLink != null) {
            await widget.onDropAddLink!(p.basename(path), path, type);
            added = true;
          }
        } else if (await FileSystemEntity.isDirectory(path)) {
          type = LinkType.folder;
          try {
            final dir = Directory(path);
            if (await dir.exists()) {
              await dir.list().first;
              if (widget.onDropAddLink != null) {
                await widget.onDropAddLink!(p.basename(path), path, type);
                added = true;
              }
            } else {
              failed.add(path);
            }
          } catch (_) {
            failed.add(path);
          }
        } else {
          type = LinkType.file;
          try {
            final fileObj = File(path);
            if (await fileObj.exists()) {
              await fileObj.open();
              if (widget.onDropAddLink != null) {
                await widget.onDropAddLink!(p.basename(path), path, type);
          added = true;
              }
            } else {
              failed.add(path);
            }
          } catch (_) {
            failed.add(path);
          }
        }
      }
    }
    if (added) {
      widget.onShowMessage(
        'リンクを追加しました',
        icon: Icons.check_circle,
        color: Colors.green[700],
      );
    }
    if (failed.isNotEmpty) {
      widget.onShowMessage(
        '一部のファイル/フォルダはアクセスできなかったため登録されませんでした',
        icon: Icons.error,
        color: Colors.red[700],
      );
    }
  }
}

class _HoverAnimatedCard extends StatefulWidget {
  final Widget child;
  final Color borderColor;
  final Color hoverBorderColor;
  final double borderWidth;
  const _HoverAnimatedCard({
    required this.child,
    required this.borderColor,
    required this.hoverBorderColor,
    required this.borderWidth,
  });
  @override
  State<_HoverAnimatedCard> createState() => _HoverAnimatedCardState();
}

class _HoverAnimatedCardState extends State<_HoverAnimatedCard> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        border: Border.all(
          color: _hovering ? widget.hoverBorderColor : widget.borderColor,
          width: widget.borderWidth,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _hovering
            ? [BoxShadow(color: widget.hoverBorderColor.withOpacity(0.3), blurRadius: 16, offset: Offset(0, 4))]
            : [],
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: widget.child,
      ),
    );
  }
}

class _GroupCardContent extends StatefulWidget {
  final Group group;
  final VoidCallback onToggleCollapse;
  final VoidCallback onDeleteGroup;
  final VoidCallback onAddLink;
  final Function(String) onDeleteLink;
  final Function(LinkItem) onLaunchLink;
  final Future<void> Function(String label, String path, LinkType type)? onDropAddLink;
  final Future<void> Function(LinkItem updated) onEditLink;
  final Future<void> Function(List<LinkItem> newOrder) onReorderLinks;
  final void Function(Offset newPosition)? onMove;
  final bool isDragging;
  final void Function(String newTitle)? onEditGroupTitle;
  final void Function(Group) onFavoriteToggle;
  final void Function(Group, LinkItem) onLinkFavoriteToggle;
  final void Function(LinkItem link, String fromGroupId, String toGroupId)? onMoveLinkToGroup;

  const _GroupCardContent({
    required this.group,
    required this.onToggleCollapse,
    required this.onDeleteGroup,
    required this.onAddLink,
    required this.onDeleteLink,
    required this.onLaunchLink,
    this.onDropAddLink,
    required this.onEditLink,
    required this.onReorderLinks,
    this.onMove,
    this.isDragging = false,
    this.onEditGroupTitle,
    required this.onFavoriteToggle,
    required this.onLinkFavoriteToggle,
    this.onMoveLinkToGroup,
  });

  @override
  State<_GroupCardContent> createState() => _GroupCardContentState();
}

class _GroupCardContentState extends State<_GroupCardContent> {
  bool showOnlyFavorites = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final items = group.items;
    final scale = (MediaQuery.of(context).size.width / 1200.0).clamp(1.0, 1.15);
    final canAddLink = items.length < 5;
    final isGroupFavorite = group.isFavorite;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(14 * scale),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                    group.title ?? '名称未設定',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
                Visibility(
                  visible: _hovering,
                  maintainState: false,
                  maintainAnimation: false,
                  maintainSize: false,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
              IconButton(
                icon: Icon(
                  isGroupFavorite ? Icons.star : Icons.star_border,
                  color: isGroupFavorite ? Colors.amber : Colors.grey,
                ),
                tooltip: isGroupFavorite ? 'お気に入り解除' : 'お気に入り',
                onPressed: () => widget.onFavoriteToggle(group),
                        iconSize: 18,
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 28, minHeight: 28),
              ),
                      SizedBox(width: 8),
              IconButton(
                        icon: Icon(Icons.edit, size: 16),
                tooltip: 'Edit Group Name',
                onPressed: () => widget.onEditGroupTitle?.call(group.title),
                        iconSize: 18,
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 28, minHeight: 28),
              ),
                      SizedBox(width: 8),
              IconButton(
                        icon: Icon(Icons.delete, color: Colors.red, size: 16),
                        onPressed: widget.onDeleteGroup,
                        tooltip: 'Delete Group',
                        iconSize: 18,
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 28, minHeight: 28),
              ),
                      if (canAddLink) ...[
                        SizedBox(width: 8),
                IconButton(
                          icon: Icon(Icons.add, size: 16),
                  onPressed: widget.onAddLink,
                  tooltip: 'Add Link',
                          iconSize: 18,
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ],
                  ),
              ),
            ],
          ),
        ),
        ),
          const Divider(height: 1),
          Expanded(
          child: items.isEmpty
              ? DragTarget<Map<String, dynamic>>(
                  onWillAccept: (data) {
                    if (data == null) return false;
                    final fromGroupId = data['fromGroupId'] as String?;
                    return fromGroupId != widget.group.id;
                  },
                  onAccept: (data) {
                    final link = data['link'] as LinkItem;
                    final fromGroupId = data['fromGroupId'] as String;
                    if (widget.onMoveLinkToGroup != null) {
                      widget.onMoveLinkToGroup!(link, fromGroupId, widget.group.id);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Center(
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: candidateData.isNotEmpty ? Colors.blueAccent : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: candidateData.isNotEmpty ? Colors.blue.withOpacity(0.08) : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          candidateData.isNotEmpty ? 'ここにドロップして追加' : 'リンクなし\nここにドラッグで追加',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13 * scale),
          ),
                      ),
                    );
                  },
                )
              : _buildContent(context, scale, items),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, double scale, List<LinkItem> items) {
    if (items.isEmpty) {
      return SizedBox(
        height: 119 * scale,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link_off, size: 55 * scale, color: Colors.grey),
              SizedBox(height: 11 * scale),
              Text(
                'No links yet',
                style: TextStyle(color: Colors.grey, fontSize: 19 * scale, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }
    // お気に入り→通常の順で並べる
    final filtered = showOnlyFavorites ? items.where((l) => l.isFavorite).toList() : items;
    final sortedItems = [
      ...filtered.where((l) => l.isFavorite),
      ...filtered.where((l) => !l.isFavorite),
    ];
    return DragTarget<Map<String, dynamic>>(
        onWillAccept: (data) {
          if (data == null) return false;
          final fromGroupId = data['fromGroupId'] as String?;
          return fromGroupId != widget.group.id;
        },
        onAccept: (data) {
          final link = data['link'] as LinkItem;
          final fromGroupId = data['fromGroupId'] as String;
          if (widget.onMoveLinkToGroup != null) {
            widget.onMoveLinkToGroup!(link, fromGroupId, widget.group.id);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return ReorderableListView(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) async {
              if (oldIndex < newIndex) newIndex--;
              final newItems = List<LinkItem>.from(sortedItems);
              final item = newItems.removeAt(oldIndex);
              newItems.insert(newIndex, item);
              await widget.onReorderLinks(newItems);
            },
            children: [
              for (int i = 0; i < sortedItems.length; i++)
                _buildLinkItem(context, sortedItems[i], sortedItems, scale: scale, key: ValueKey(sortedItems[i].id)),
            ],
          );
        },
    );
  }

  Widget _buildLinkItem(BuildContext context, LinkItem item, List<LinkItem> items, {double scale = 1.0, Key? key}) {
    IconData iconData;
    Color iconColor;
    switch (item.type) {
      case LinkType.file:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.blue;
        break;
      case LinkType.folder:
        iconData = Icons.folder;
        iconColor = Colors.orange;
        break;
      case LinkType.url:
        iconData = Icons.link;
        iconColor = Colors.green;
        break;
    }
    final isLinkFavorite = item.isFavorite;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowColor = isLinkFavorite
        ? (isDark
            ? Colors.amber.withOpacity(0.22)
            : Colors.amber.withOpacity(0.16))
        : Colors.transparent;
    bool _hovering = false;
    return KeyedSubtree(
      key: key,
      child: Draggable<Map<String, dynamic>>(
        data: {'link': item, 'fromGroupId': widget.group.id},
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            child: Row(
              children: [
                item.type == LinkType.url
                  ? UrlPreviewWidget(url: item.path, isDark: isDark)
                  : item.type == LinkType.file
                    ? FilePreviewWidget(path: item.path, isDark: isDark)
                    : Icon(iconData, color: iconColor, size: 25 * scale),
                SizedBox(width: 8),
                if (item.type != LinkType.url)
                  Expanded(
                    child: Text(item.label, style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w500, color: Colors.white), overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: GestureDetector(
              onTap: () => _launchLink(item),
              child: Container(
                color: rowColor,
                padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 0),
                child: Row(
                  children: [
                    item.type == LinkType.url
                      ? UrlPreviewWidget(url: item.path, isDark: isDark)
                      : item.type == LinkType.file
                        ? FilePreviewWidget(path: item.path, isDark: isDark)
                        : Icon(iconData, color: iconColor, size: 25 * scale),
                    SizedBox(width: 8),
                    if (item.type != LinkType.url)
                      Expanded(
                        child: Tooltip(
        message: item.path,
        child: Text(
          item.label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
                      ),
                    Visibility(
                      visible: _hovering,
                      maintainState: false,
                      maintainAnimation: false,
                      maintainSize: false,
                      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: item.memo?.isNotEmpty == true ? item.memo! : 'メモなし',
            child: IconButton(
              icon: const Icon(Icons.note_alt_outlined),
              tooltip: '',
              onPressed: () async {
                final controller = TextEditingController(text: item.memo ?? '');
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
                  final updated = item.copyWith(memo: result);
                  widget.onEditLink(updated);
                  setState(() {});
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(
              isLinkFavorite ? Icons.star : Icons.star_border,
              color: isLinkFavorite ? Colors.amber : Colors.grey,
            ),
            tooltip: isLinkFavorite ? 'お気に入り解除' : 'お気に入り',
            onPressed: () => widget.onLinkFavoriteToggle(widget.group, item),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 14 * scale),
            onPressed: () => _showEditLinkDialog(context, item),
            tooltip: 'Edit Link',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.delete, size: 14 * scale),
            onPressed: () => widget.onDeleteLink(item.id),
            tooltip: 'Delete Link',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          SizedBox(width: 8),
          ReorderableDragStartListener(
            index: key is ValueKey ? items.indexWhere((e) => e.id == (key as ValueKey).value) : 0,
            child: Icon(Icons.drag_handle, size: 18 * scale, color: Colors.grey[700]),
          ),
        ],
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
  }

  void _showEditLinkDialog(BuildContext context, LinkItem item) {
    final labelController = TextEditingController(text: item.label);
    final pathController = TextEditingController(text: item.path);
    LinkType selectedType = item.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Link'),
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
              onPressed: () async {
                if (labelController.text.isNotEmpty && pathController.text.isNotEmpty) {
                  final updated = LinkItem(
                    id: item.id,
                    label: labelController.text,
                    path: pathController.text,
                    type: selectedType,
                    createdAt: item.createdAt,
                    lastUsed: item.lastUsed,
                  );
                  await widget.onEditLink(updated);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkDetails(BuildContext context, LinkItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Label: ${item.label}'),
            const SizedBox(height: 8),
            Text('Path: ${item.path}'),
            const SizedBox(height: 8),
            Text('Type: ${item.type.name.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Created: ${item.createdAt.toString()}'),
            if (item.lastUsed != null) ...[
              const SizedBox(height: 8),
              Text('Last Used: ${item.lastUsed.toString()}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchLink(LinkItem item) async {
    // LinkViewModelのlaunchLinkメソッドを呼び出して、lastUsedを更新する
    widget.onLaunchLink(item);
  }
} 