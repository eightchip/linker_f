import 'package:flutter/material.dart';
import '../models/export_config.dart';
import '../widgets/app_button_styles.dart';

/// 部分インポートダイアログ
class SelectiveImportDialog extends StatefulWidget {
  const SelectiveImportDialog({Key? key}) : super(key: key);

  @override
  State<SelectiveImportDialog> createState() => _SelectiveImportDialogState();
}

class _SelectiveImportDialogState extends State<SelectiveImportDialog> {
  ImportConfig _config = ImportConfig();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ヘッダー
            Row(
              children: [
                const Icon(Icons.upload, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '部分インポート設定',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // コンテンツ
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              const Text(
                'インポート方法を選択してください',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // インポート方法
              _buildSectionHeader('インポート方法'),
              RadioListTile<ImportMode>(
                title: const Text('追加'),
                subtitle: const Text('既存データに追加します'),
                value: ImportMode.add,
                groupValue: _config.importMode,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importMode: value);
                  });
                },
              ),
              RadioListTile<ImportMode>(
                title: const Text('上書き'),
                subtitle: const Text('既存データを置き換えます'),
                value: ImportMode.overwrite,
                groupValue: _config.importMode,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importMode: value);
                  });
                },
              ),
              RadioListTile<ImportMode>(
                title: const Text('マージ'),
                subtitle: const Text('重複をチェックして統合します'),
                value: ImportMode.merge,
                groupValue: _config.importMode,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importMode: value);
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // 重複処理方法
              _buildSectionHeader('重複処理方法'),
              RadioListTile<DuplicateHandling>(
                title: const Text('スキップ'),
                subtitle: const Text('重複データをスキップします'),
                value: DuplicateHandling.skip,
                groupValue: _config.duplicateHandling,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(duplicateHandling: value);
                  });
                },
              ),
              RadioListTile<DuplicateHandling>(
                title: const Text('上書き'),
                subtitle: const Text('既存データを上書きします'),
                value: DuplicateHandling.overwrite,
                groupValue: _config.duplicateHandling,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(duplicateHandling: value);
                  });
                },
              ),
              RadioListTile<DuplicateHandling>(
                title: const Text('名前を変更'),
                subtitle: const Text('名前を変更して追加します'),
                value: DuplicateHandling.rename,
                groupValue: _config.duplicateHandling,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(duplicateHandling: value);
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // インポートするデータ
              _buildSectionHeader('インポートするデータ'),
              CheckboxListTile(
                title: const Text('リンク'),
                value: _config.importLinks,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importLinks: value ?? true);
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('グループ'),
                value: _config.importGroups,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importGroups: value ?? true);
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('タスク'),
                value: _config.importTasks,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importTasks: value ?? true);
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('設定'),
                value: _config.importSettings,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importSettings: value ?? false);
                  });
                },
              ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // フッター
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: AppButtonStyles.text(context),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _config);
                  },
                  style: AppButtonStyles.primary(context),
                  child: const Text('インポート'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}

