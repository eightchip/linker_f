import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';

/// グローバルメニューダイアログ
/// 共通メニューと両画面のメニュー項目をすべて表示
/// 選択されたメニュー項目の値（String）を戻り値として返す
class GlobalMenuDialog extends ConsumerStatefulWidget {
  const GlobalMenuDialog({
    super.key,
  });

  @override
  ConsumerState<GlobalMenuDialog> createState() => _GlobalMenuDialogState();
}

class _GlobalMenuDialogState extends ConsumerState<GlobalMenuDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.more_vert, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.globalMenu,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // メニューリスト
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  // 共通メニューセクション
                  _buildSectionHeader(AppLocalizations.of(context)!.common),
                  _buildMenuItem(
                    icon: Icons.settings,
                    iconColor: Colors.grey,
                    title: '${AppLocalizations.of(context)!.settings} (Ctrl+Shift+S)',
                    value: 'settings',
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    iconColor: Colors.indigo,
                    title: '${AppLocalizations.of(context)!.helpCenter} (Ctrl+H)',
                    value: 'help_center',
                  ),
                  _buildMenuItem(
                    icon: Icons.notes,
                    iconColor: Colors.teal,
                    title: '${AppLocalizations.of(context)!.memoBulkEdit} (Ctrl+E)',
                    value: 'memo_bulk_edit',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // リンク管理画面のメニューセクション
                  _buildSectionHeader(AppLocalizations.of(context)!.linkManagementEnabled),
                  _buildMenuItem(
                    icon: Icons.add,
                    iconColor: Colors.green,
                    title: '${AppLocalizations.of(context)!.addGroup} (Ctrl+N)',
                    value: 'add_group',
                  ),
                  _buildMenuItem(
                    icon: Icons.search,
                    iconColor: Colors.blue,
                    title: '${AppLocalizations.of(context)!.search} (Ctrl+F)',
                    value: 'search',
                  ),
                  _buildMenuItem(
                    icon: Icons.task_alt,
                    iconColor: Colors.orange,
                    title: '${AppLocalizations.of(context)!.taskManagement} (Ctrl+T)',
                    value: 'task',
                  ),
                  _buildMenuItem(
                    icon: Icons.sort,
                    iconColor: Colors.purple,
                    title: '${AppLocalizations.of(context)!.changeGroupOrder} (Ctrl+O)',
                    value: 'group_order',
                  ),
                  _buildMenuItem(
                    icon: Icons.keyboard,
                    iconColor: Colors.indigo,
                    title: '${AppLocalizations.of(context)!.shortcutKeys} (F1)',
                    value: 'shortcut_help',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // タスク管理画面のメニューセクション
                  _buildSectionHeader(AppLocalizations.of(context)!.taskManagementEnabled),
                  _buildMenuItem(
                    icon: Icons.add,
                    iconColor: Colors.green,
                    title: '${AppLocalizations.of(context)!.newTask} (Ctrl+N)',
                    value: 'add_task',
                  ),
                  _buildMenuItem(
                    icon: Icons.checklist,
                    iconColor: Colors.blue,
                    title: '${AppLocalizations.of(context)!.bulkSelectMode} (Ctrl+B)',
                    value: 'bulk_select',
                  ),
                  _buildMenuItem(
                    icon: Icons.download,
                    iconColor: Colors.green,
                    title: '${AppLocalizations.of(context)!.csvExport} (Ctrl+Shift+E)',
                    value: 'export',
                  ),
                  _buildMenuItem(
                    icon: Icons.calendar_month,
                    iconColor: Colors.orange,
                    title: '${AppLocalizations.of(context)!.scheduleList} (Ctrl+S)',
                    value: 'schedule',
                  ),
                  _buildMenuItem(
                    icon: Icons.group,
                    iconColor: Colors.purple,
                    title: '${AppLocalizations.of(context)!.grouping} (Ctrl+G)',
                    value: 'group_menu',
                  ),
                  _buildMenuItem(
                    icon: Icons.content_copy,
                    iconColor: Colors.teal,
                    title: '${AppLocalizations.of(context)!.createFromTemplate} (Ctrl+Shift+T)',
                    value: 'task_template',
                  ),
                  _buildMenuItem(
                    icon: Icons.visibility,
                    iconColor: Colors.grey,
                    title: '${AppLocalizations.of(context)!.toggleStatisticsSearchBar} (Ctrl+F)',
                    value: 'toggle_header',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(title),
      onTap: () {
        Navigator.pop(context, value);
      },
    );
  }
}

