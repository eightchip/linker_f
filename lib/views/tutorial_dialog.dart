import 'package:flutter/material.dart';

class TutorialDialog extends StatefulWidget {
  final VoidCallback? onFinish;
  const TutorialDialog({super.key, this.onFinish});

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int _page = 0;

  final List<_TutorialStep> steps = [
    _TutorialStep(
      title: 'Link Navigator へようこそ！',
      description: 'ファイル・フォルダ（URLは手動で入力）をグループで整理し、ドラッグ＆ドロップで直感的に管理できます。',
      imageAsset: 'assets/tutorial/welcome.png',
    ),
    _TutorialStep(
      title: 'グループの作成',
      description: '画面右上の「＋」ボタンから新しいグループを作成できます。\nグループにはタイトルと色を設定できます。',
      imageAsset: 'assets/tutorial/group_add.png',
    ),
    _TutorialStep(
      title: 'リンクの追加',
      description: 'グループの「＋」アイコンから手動追加、またはファイル/フォルダをドラッグ＆ドロップで追加できます。',
      imageAsset: 'assets/tutorial/link_add.png',
    ),
    _TutorialStep(
      title: 'リンクの起動・編集・削除',
      description: 'リンクリックで起動、ホバー時に表示されるアイコンでメモ・お気に入り登録・編集・削除・グループ内の並び替えができます。',
      imageAsset: 'assets/tutorial/link_actions.png',
    ),
    _TutorialStep(
      title: 'グループの並び替え',
      description: 'グループも、ドラッグ＆ドロップで自由に並び替えできます。',
      imageAsset: 'assets/tutorial/reorder.png',
    ),
    _TutorialStep(
      title: 'グループ間のリンク移動',
      description: 'リンクをドラッグして他のグループにドロップすると、グループ間で移動できます。\n空のグループにもドロップ可能です。',
      imageAsset: 'assets/tutorial/move_between_groups.png',
    ),
    _TutorialStep(
      title: 'データのエクスポート・インポート',
      description: '右上のダウンロード/アップロードアイコンから、データのバックアップや復元ができます。',
      imageAsset: 'assets/tutorial/export_import.png',
    ),
    _TutorialStep(
      title: 'テーマ・カスタマイズ',
      description: '画面右上の☀と🌙から、通常モードとナイトモードの切り替えが出来ます。',
      imageAsset: 'assets/tutorial/theme.png',
    ),
    _TutorialStep(
      title: 'ヘルプ・FAQ',
      description: '右上の「？」アイコンからいつでもこのチュートリアルやFAQを再表示できます。',
      imageAsset: 'assets/tutorial/help.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = steps[_page];
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 420,
        height: 520,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (step.imageAsset != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Image.asset(
                          step.imageAsset!,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    Text(
                      step.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      step.description,
                      style: const TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _page == 0
                        ? null
                        : () => setState(() => _page--),
                    child: const Text('戻る'),
                  ),
                  Row(
                    children: List.generate(
                      steps.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _page ? Colors.blue : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  _page == steps.length - 1
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onFinish?.call();
                          },
                          child: const Text('はじめる'),
                        )
                      : TextButton(
                          onPressed: () => setState(() => _page++),
                          child: const Text('次へ'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStep {
  final String title;
  final String description;
  final String? imageAsset;
  const _TutorialStep({required this.title, required this.description, this.imageAsset});
} 