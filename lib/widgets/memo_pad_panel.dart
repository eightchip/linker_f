import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/memo_item.dart';
import '../viewmodels/memo_viewmodel.dart';
import '../services/snackbar_service.dart';
import '../l10n/app_localizations.dart';
import 'memo_editor_dialog.dart';

/// メモ帳パネルウィジェット
class MemoPadPanel extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const MemoPadPanel({
    super.key,
    this.onClose,
  });

  @override
  ConsumerState<MemoPadPanel> createState() => _MemoPadPanelState();
}

class _MemoPadPanelState extends ConsumerState<MemoPadPanel> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memos = ref.watch(memoViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    // 検索フィルタリング
    final filteredMemos = _searchQuery.isEmpty
        ? memos
        : memos.where((memo) =>
            memo.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.note,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.memoPad,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClose,
                  tooltip: l10n.close,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // 検索バーと新規メモボタン
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 検索バー
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchMemos,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                // 新規メモボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showMemoEditor(context, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.newMemo),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // メモ一覧
          Expanded(
            child: filteredMemos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 64,
                          color: theme.colorScheme.outline.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? l10n.noMemos
                              : l10n.noMemosFound,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredMemos.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final memo = filteredMemos[index];
                      return _buildMemoItem(context, memo, dateFormat, theme, l10n);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoItem(
    BuildContext context,
    MemoItem memo,
    DateFormat dateFormat,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    // プレビューテキスト（最初の50文字）
    final preview = memo.content.length > 50
        ? '${memo.content.substring(0, 50)}...'
        : memo.content;

    return InkWell(
      onTap: () => _showMemoEditor(context, memo),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    preview,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showMemoEditor(context, memo);
                    } else if (value == 'delete') {
                      _deleteMemo(context, memo, l10n);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            l10n.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(memo.updatedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMemoEditor(BuildContext context, MemoItem? memo) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => MemoEditorDialog(memo: memo),
    );

    if (result != null && mounted) {
      final memoViewModel = ref.read(memoViewModelProvider.notifier);
      final l10n = AppLocalizations.of(context)!;

      try {
        if (memo == null) {
          // 新規作成
          await memoViewModel.addMemo(result['content']!);
          SnackBarService.showSuccess(context, l10n.memoAdded);
        } else {
          // 更新
          await memoViewModel.updateMemo(memo.id, result['content']!);
          SnackBarService.showSuccess(context, l10n.memoUpdated);
        }
      } catch (e) {
        SnackBarService.showError(
          context,
          memo == null ? l10n.memoAddFailed : l10n.memoUpdateFailed,
        );
      }
    }
  }

  Future<void> _deleteMemo(
    BuildContext context,
    MemoItem memo,
    AppLocalizations l10n,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMemo),
        content: Text(l10n.deleteMemoConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(memoViewModelProvider.notifier).deleteMemo(memo.id);
        SnackBarService.showSuccess(context, l10n.memoDeleted);
      } catch (e) {
        SnackBarService.showError(context, l10n.memoDeleteFailed);
      }
    }
  }
}
