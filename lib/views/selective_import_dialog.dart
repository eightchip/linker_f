import 'package:flutter/material.dart';
import '../models/export_config.dart';
import '../widgets/app_button_styles.dart';
import '../l10n/app_localizations.dart';

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
                Text(
                  AppLocalizations.of(context)!.partialImportSettings,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              Text(
                AppLocalizations.of(context)!.selectImportMethod,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // インポート方法
              _buildSectionHeader(AppLocalizations.of(context)!.importMethod),
              RadioListTile<ImportMode>(
                title: Text(AppLocalizations.of(context)!.add),
                subtitle: Text(AppLocalizations.of(context)!.addToExistingData),
                value: ImportMode.add,
                groupValue: _config.importMode,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importMode: value);
                  });
                },
              ),
              RadioListTile<ImportMode>(
                title: Text(AppLocalizations.of(context)!.overwrite),
                subtitle: Text(AppLocalizations.of(context)!.replaceExistingData),
                value: ImportMode.overwrite,
                groupValue: _config.importMode,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importMode: value);
                  });
                },
              ),
              RadioListTile<ImportMode>(
                title: Text(AppLocalizations.of(context)!.merge),
                subtitle: Text(AppLocalizations.of(context)!.mergeWithDuplicateCheck),
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
              _buildSectionHeader(AppLocalizations.of(context)!.duplicateHandling),
              RadioListTile<DuplicateHandling>(
                title: Text(AppLocalizations.of(context)!.skip),
                subtitle: Text(AppLocalizations.of(context)!.skipDuplicateData),
                value: DuplicateHandling.skip,
                groupValue: _config.duplicateHandling,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(duplicateHandling: value);
                  });
                },
              ),
              RadioListTile<DuplicateHandling>(
                title: Text(AppLocalizations.of(context)!.overwrite),
                subtitle: Text(AppLocalizations.of(context)!.overwriteExistingData),
                value: DuplicateHandling.overwrite,
                groupValue: _config.duplicateHandling,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(duplicateHandling: value);
                  });
                },
              ),
              RadioListTile<DuplicateHandling>(
                title: Text(AppLocalizations.of(context)!.rename),
                subtitle: Text(AppLocalizations.of(context)!.renameAndAdd),
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
              _buildSectionHeader(AppLocalizations.of(context)!.importData),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context)!.links),
                value: _config.importLinks,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importLinks: value ?? true);
                  });
                },
              ),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context)!.groups),
                value: _config.importGroups,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importGroups: value ?? true);
                  });
                },
              ),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context)!.tasks),
                value: _config.importTasks,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(importTasks: value ?? true);
                  });
                },
              ),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context)!.settings),
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
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _config);
                  },
                  style: AppButtonStyles.primary(context),
                  child: Text(AppLocalizations.of(context)!.import),
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

