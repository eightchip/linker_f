import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_item.dart';
import '../models/link_item.dart';
import '../viewmodels/link_viewmodel.dart';
import '../viewmodels/task_viewmodel.dart';
import '../services/snackbar_service.dart';

/// リンク関連付けダイアログ（共有ウィジェット）
class LinkAssociationDialog extends ConsumerStatefulWidget {
  final TaskItem task;
  final VoidCallback onLinksUpdated;

  const LinkAssociationDialog({
    super.key,
    required this.task,
    required this.onLinksUpdated,
  });

  @override
  ConsumerState<LinkAssociationDialog> createState() => _LinkAssociationDialogState();
}

class _LinkAssociationDialogState extends ConsumerState<LinkAssociationDialog> {
  Set<String> _selectedLinkIds = {};
  late int _initialExistingLinkCount;
  Set<String> _removedLinkIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedLinkIds = Set.from(widget.task.relatedLinkIds);
    _initialExistingLinkCount = widget.task.relatedLinkIds.length;
  }

  @override
  Widget build(BuildContext context) {
    final linkGroups = ref.watch(linkViewModelProvider);
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.95,
        constraints: const BoxConstraints(
          minWidth: 800,
          minHeight: 600,
          maxWidth: 1400,
          maxHeight: 1000,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.link,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'リンク関連付け',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'タスク「${widget.task.title}」に関連するリンクを選択してください',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '閉じる',
                  ),
                ],
              ),
            ),
            
            // 検索バー
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'リンクを検索...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
            ),
            
            // リンクリスト
            Expanded(
              child: linkGroups.groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.link_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'リンクがありません',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: linkGroups.groups.length,
                      itemBuilder: (context, index) {
                        final group = linkGroups.groups[index];
                        final filteredItems = _filterLinks(group.items);
                        
                        if (filteredItems.isEmpty) return const SizedBox.shrink();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 8),
                              child: Text(
                                group.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            ...filteredItems.map((link) {
                              final isSelected = _selectedLinkIds.contains(link.id);
                              final isExisting = widget.task.relatedLinkIds.contains(link.id);
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: isSelected ? 4 : 1,
                                color: isSelected
                                    ? theme.colorScheme.primary.withOpacity(0.1)
                                    : theme.colorScheme.surface,
                                child: CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked ?? false) {
                                        _selectedLinkIds.add(link.id);
                                        _removedLinkIds.remove(link.id);
                                      } else {
                                        _selectedLinkIds.remove(link.id);
                                        if (isExisting) {
                                          _removedLinkIds.add(link.id);
                                        }
                                      }
                                    });
                                  },
                                  title: Text(
                                    link.label,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    link.path,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  secondary: Icon(
                                    _getLinkIcon(link.type),
                                    color: _getLinkColor(link.type),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
            
            // フッター
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '選択中: ${_selectedLinkIds.length}個',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('キャンセル'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveLinkAssociations,
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LinkItem> _filterLinks(List<LinkItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((link) =>
            link.label.toLowerCase().contains(_searchQuery) ||
            link.path.toLowerCase().contains(_searchQuery))
        .toList();
  }

  IconData _getLinkIcon(LinkType type) {
    switch (type) {
      case LinkType.file:
        return Icons.insert_drive_file;
      case LinkType.url:
        return Icons.link;
      case LinkType.folder:
        return Icons.folder;
    }
  }

  Color _getLinkColor(LinkType type) {
    switch (type) {
      case LinkType.file:
        return Colors.blue;
      case LinkType.url:
        return Colors.green;
      case LinkType.folder:
        return Colors.orange;
    }
  }

  Future<void> _saveLinkAssociations() async {
    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      
      final currentLinkIds = Set.from(widget.task.relatedLinkIds);
      final linksToAdd = _selectedLinkIds.difference(currentLinkIds);
      final linksToRemove = currentLinkIds.difference(_selectedLinkIds);
      
      for (final linkId in linksToAdd) {
        await taskViewModel.addLinkToTask(widget.task.id, linkId);
      }
      
      for (final linkId in linksToRemove) {
        await taskViewModel.removeLinkFromTask(widget.task.id, linkId);
      }
      
      SnackBarService.showSuccess(
        context,
        'リンクの関連付けを更新しました',
      );
      
      widget.onLinksUpdated();
      Navigator.of(context).pop();
      
    } catch (e) {
      SnackBarService.showError(
        context,
        'リンクの関連付け更新に失敗しました: $e',
      );
    }
  }
}

