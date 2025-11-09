import 'package:flutter/material.dart';

class ShortcutHelpEntry {
  final String keys;
  final String description;

  const ShortcutHelpEntry(this.keys, this.description);
}

Future<void> showShortcutHelpDialog(
  BuildContext context, {
  required String title,
  required List<ShortcutHelpEntry> entries,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 96),
                child: Text(
                  entry.keys,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              title: Text(entry.description),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}

