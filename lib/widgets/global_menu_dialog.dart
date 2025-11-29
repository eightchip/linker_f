import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                  const Text(
                    'グローバルメニュー',
                    style: TextStyle(
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
                  _buildSectionHeader('共通'),
                  _buildMenuItem(
                    icon: Icons.settings,
                    iconColor: Colors.grey,
                    title: '設定 (Ctrl+Shift+S)',
                    value: 'settings',
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    iconColor: Colors.indigo,
                    title: 'ヘルプセンター (Ctrl+H)',
                    value: 'help_center',
                  ),
                  _buildMenuItem(
                    icon: Icons.notes,
                    iconColor: Colors.teal,
                    title: 'メモ一括編集 (Ctrl+E)',
                    value: 'memo_bulk_edit',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // リンク管理画面のメニューセクション
                  _buildSectionHeader('リンク管理（リンク管理画面で有効）'),
                  _buildMenuItem(
                    icon: Icons.add,
                    iconColor: Colors.green,
                    title: 'グループを追加 (Ctrl+N)',
                    value: 'add_group',
                  ),
                  _buildMenuItem(
                    icon: Icons.search,
                    iconColor: Colors.blue,
                    title: '検索 (Ctrl+F)',
                    value: 'search',
                  ),
                  _buildMenuItem(
                    icon: Icons.task_alt,
                    iconColor: Colors.orange,
                    title: 'タスク管理 (Ctrl+T)',
                    value: 'task',
                  ),
                  _buildMenuItem(
                    icon: Icons.sort,
                    iconColor: Colors.purple,
                    title: 'グループの並び順を変更 (Ctrl+O)',
                    value: 'group_order',
                  ),
                  _buildMenuItem(
                    icon: Icons.keyboard,
                    iconColor: Colors.indigo,
                    title: 'ショートカットキー (F1)',
                    value: 'shortcut_help',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // タスク管理画面のメニューセクション
                  _buildSectionHeader('タスク管理（タスク管理画面で有効）'),
                  _buildMenuItem(
                    icon: Icons.add,
                    iconColor: Colors.green,
                    title: '新しいタスク (Ctrl+N)',
                    value: 'add_task',
                  ),
                  _buildMenuItem(
                    icon: Icons.checklist,
                    iconColor: Colors.blue,
                    title: '一括選択モード (Ctrl+B)',
                    value: 'bulk_select',
                  ),
                  _buildMenuItem(
                    icon: Icons.download,
                    iconColor: Colors.green,
                    title: 'CSV出力 (Ctrl+Shift+E)',
                    value: 'export',
                  ),
                  _buildMenuItem(
                    icon: Icons.calendar_month,
                    iconColor: Colors.orange,
                    title: 'スケジュール一覧 (Ctrl+S)',
                    value: 'schedule',
                  ),
                  _buildMenuItem(
                    icon: Icons.group,
                    iconColor: Colors.purple,
                    title: 'グループ化 (Ctrl+G)',
                    value: 'group_menu',
                  ),
                  _buildMenuItem(
                    icon: Icons.content_copy,
                    iconColor: Colors.teal,
                    title: 'テンプレートから作成 (Ctrl+Shift+T)',
                    value: 'task_template',
                  ),
                  _buildMenuItem(
                    icon: Icons.visibility,
                    iconColor: Colors.grey,
                    title: '統計・検索バー表示/非表示 (Ctrl+F)',
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

