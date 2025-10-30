import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_item.dart';
import '../models/link_item.dart';
import '../models/group.dart';
import '../viewmodels/link_viewmodel.dart';
import '../viewmodels/task_viewmodel.dart';
import '../services/snackbar_service.dart';
import '../viewmodels/ui_customization_provider.dart';
import '../widgets/app_spacing.dart';
import '../views/home_screen.dart'; // FilePreviewWidget, UrlPreviewWidget用

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
            // ヘッダー部分
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
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'リンク管理',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'タスク「${widget.task.title}」にリンクを関連付け',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // コンテンツ部分
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 既存の関連リンクセクション（折りたたみ可能）
                    if (_currentExistingLinkCount > 0) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          leading: Icon(
                            Icons.link_off,
                            color: theme.colorScheme.error,
                            size: 16,
                          ),
                          title: Text(
                            '既存の関連リンク（${_currentExistingLinkCount}個）',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error,
                            ),
                          ),
                          subtitle: Text(
                            'クリックして展開・削除',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error.withValues(alpha: 0.7),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: _buildExistingLinksGrid(linkGroups, theme),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    
                    Text(
                      '関連付けたいリンクを選択してください：',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // 検索フィールド
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'リンクを検索...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _getFilteredGroups(linkGroups).length,
                        itemBuilder: (context, groupIndex) {
                          final group = _getFilteredGroups(linkGroups)[groupIndex];
                          return _buildGroupCard(group, theme);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // フッター部分
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Row(
                children: [
                  // 選択情報
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedLinkIds.isNotEmpty 
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.colorScheme.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedLinkIds.isNotEmpty 
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedLinkIds.isNotEmpty ? Icons.check_circle : Icons.info_outline,
                          color: _selectedLinkIds.isNotEmpty 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '選択されたリンク: ${_getValidSelectedLinkCount()}個（既存: ${_currentExistingLinkCount}個）',
                          style: TextStyle(
                            color: _getValidSelectedLinkCount() > 0 
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // ボタン
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.outline,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('キャンセル'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: (_getValidSelectedLinkCount() > 0 || _hasExistingLinksChanged()) ? _saveLinkAssociations : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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

  /// 既存の関連リンクリストを構築（カード形式）
  Widget _buildExistingLinksGrid(LinkState linkGroups, ThemeData theme) {
    final existingLinks = <LinkItem>[];
    
    for (final linkId in widget.task.relatedLinkIds) {
      if (_removedLinkIds.contains(linkId)) {
        continue;
      }
      
      LinkItem? link;
      for (final group in linkGroups.groups) {
        for (final item in group.items) {
          if (item.id == linkId) {
            link = item;
            break;
          }
        }
        if (link != null) break;
      }
      
      if (link != null) {
        existingLinks.add(link);
      }
    }
    
    if (existingLinks.isEmpty) {
      if (widget.task.relatedLinkIds.isNotEmpty && _removedLinkIds.length < widget.task.relatedLinkIds.length) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            '関連付けられたリンクが見つかりません（${_currentExistingLinkCount}個のリンクIDが存在）',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        );
      }
      return const SizedBox.shrink();
    }
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 2.5,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        padding: const EdgeInsets.all(12),
        itemCount: existingLinks.length,
        itemBuilder: (context, index) {
          final link = existingLinks[index];
          final linkId = link.id;
          return Stack(
            children: [
              _buildGridLinkItem(link, theme),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _removeLinkFromTask(linkId),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: theme.colorScheme.onError,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 検索クエリに基づいてグループをフィルタリング
  List<Group> _getFilteredGroups(LinkState linkGroups) {
    if (_searchQuery.isEmpty) {
      return linkGroups.groups;
    }
    
    final query = _searchQuery.toLowerCase();
    return linkGroups.groups.where((group) {
      if (group.title.toLowerCase().contains(query)) {
        return true;
      }
      return group.items.any((link) =>
          link.label.toLowerCase().contains(query) ||
          link.path.toLowerCase().contains(query));
    }).toList();
  }

  /// 有効な選択されたリンク数を取得
  int _getValidSelectedLinkCount() {
    final linkGroups = ref.read(linkViewModelProvider);
    int validCount = 0;
    
    for (final linkId in _selectedLinkIds) {
      if (_removedLinkIds.contains(linkId)) {
        continue;
      }
      
      bool linkExists = false;
      for (final group in linkGroups.groups) {
        for (final link in group.items) {
          if (link.id == linkId) {
            linkExists = true;
            break;
          }
        }
        if (linkExists) break;
      }
      
      if (linkExists) {
        validCount++;
      }
    }
    
    return validCount;
  }

  /// 現在の既存リンク数を取得
  int get _currentExistingLinkCount {
    final linkGroups = ref.read(linkViewModelProvider);
    int validLinkCount = 0;
    
    for (final linkId in widget.task.relatedLinkIds) {
      if (!_removedLinkIds.contains(linkId)) {
        bool linkExists = false;
        for (final group in linkGroups.groups) {
          for (final link in group.items) {
            if (link.id == linkId) {
              linkExists = true;
              break;
            }
          }
          if (linkExists) break;
        }
        if (linkExists) {
          validLinkCount++;
        }
      }
    }
    
    return validLinkCount;
  }

  /// 既存リンクに変更があったかチェック
  bool _hasExistingLinksChanged() {
    return _currentExistingLinkCount != _initialExistingLinkCount;
  }

  /// タスクからリンクを削除
  void _removeLinkFromTask(String linkId) async {
    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final updatedLinkIds = List<String>.from(widget.task.relatedLinkIds);
      updatedLinkIds.remove(linkId);
      
      final updatedTask = widget.task.copyWith(relatedLinkIds: updatedLinkIds);
      await taskViewModel.updateTask(updatedTask);
      
      setState(() {
        _selectedLinkIds.remove(linkId);
        _removedLinkIds.add(linkId);
      });
      
      widget.onLinksUpdated();
      
      if (mounted) {
        SnackBarService.showSuccess(
          context,
          'リンクを削除しました',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(
          context,
          'リンクの削除に失敗しました: $e',
        );
      }
    }
  }

  Widget _buildGroupCard(Group group, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8 * ref.watch(uiDensityProvider)),
              decoration: BoxDecoration(
                color: _getGroupColor(group).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder,
                color: _getGroupColor(group),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                group.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getGroupColor(group).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${group.items.length}個',
                style: TextStyle(
                  color: _getGroupColor(group),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getGroupColor(group).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.list,
                  color: _getGroupColor(group),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'リンク一覧: ${group.items.length}個',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getGroupColor(group),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 500),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2.5,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              padding: const EdgeInsets.all(12),
              itemCount: group.items.length,
              itemBuilder: (context, index) {
                final link = group.items[index];
                return _buildGridLinkItem(link, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLinkItem(LinkItem link, ThemeData theme) {
    final isSelected = _selectedLinkIds.contains(link.id);
    
    final linkGroups = ref.read(linkViewModelProvider);
    Group? parentGroup;
    for (final group in linkGroups.groups) {
      if (group.items.any((item) => item.id == link.id)) {
        parentGroup = group;
        break;
      }
    }
    
    final groupColor = parentGroup != null ? _getGroupColor(parentGroup) : Colors.grey;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedLinkIds.remove(link.id);
              } else {
                _selectedLinkIds.add(link.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 2,
                      height: 16,
                      decoration: BoxDecoration(
                        color: groupColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildFaviconOrIcon(link, theme),
                    const Spacer(),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          width: 1.5,
                        ),
                        color: isSelected 
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: theme.colorScheme.onPrimary,
                              size: 8,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    link.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaviconOrIcon(LinkItem link, ThemeData theme) {
    if (link.type == LinkType.url) {
      return UrlPreviewWidget(
        url: link.path, 
        isDark: theme.brightness == Brightness.dark,
        fallbackDomain: link.faviconFallbackDomain,
      );
    } else if (link.type == LinkType.file) {
      return FilePreviewWidget(
        path: link.path,
        isDark: theme.brightness == Brightness.dark,
      );
    } else {
      if (link.iconData != null) {
        return Icon(
          IconData(link.iconData!, fontFamily: 'MaterialIcons'),
          color: link.iconColor != null ? Color(link.iconColor!) : Colors.orange,
          size: 16,
        );
      } else {
        return Icon(
          Icons.folder,
          color: Colors.orange,
          size: 16,
        );
      }
    }
  }

  Color _getGroupColor(Group group) {
    switch (group.title.toLowerCase()) {
      case 'favorites':
        return Colors.blue;
      case 'favorites2':
        return Colors.green;
      case 'favorites3':
        return Colors.red;
      case 'programming':
        return Colors.purple;
      default:
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
