# ガントチャート機能の提案

## 概要
タスク管理アプリにガントチャートのようなスケジュール管理画面を追加し、視覚的にタスクの進行状況と期間を把握できるようにします。

## 主な機能

### 1. ガントチャートビュー
- **タイムライン表示**: 横軸に日付、縦軸にタスクを表示
- **タスクバー**: 着手日から完了日（または期限日）までの期間をバーで表示
- **進捗表示**: タスクの進捗状況に応じてバーの色や塗りつぶしを変更
- **ズーム機能**: 日/週/月単位での表示切り替え

### 2. インタラクティブな操作
- **ドラッグ&ドロップ**: タスクバーをドラッグして期間を変更
- **クリック編集**: タスクバーをクリックしてタスク詳細を表示・編集
- **期間の視覚的な調整**: バーの端をドラッグして着手日・完了日を変更

### 3. フィルタリングとグループ化
- **ステータスフィルタ**: 未着手/進行中/完了でフィルタリング
- **優先度フィルタ**: 優先度別に表示
- **リンク別グループ化**: 関連リンクごとにグループ化して表示
- **期間フィルタ**: 特定の期間のタスクのみ表示

### 4. 依存関係の表示
- **先行タスク**: タスク間の依存関係を矢印で表示
- **クリティカルパス**: 重要なタスクを強調表示

### 5. 統計情報
- **期間の可視化**: 着手日から完了日までの実働期間を視覚的に確認
- **遅延タスクのハイライト**: 期限を過ぎたタスクを赤色で表示
- **進捗率の表示**: 各タスクの進捗率をバーの上に表示

## 実装の詳細

### UIコンポーネント
```
lib/views/gantt_screen.dart
  - GanttChartView: メインのガントチャートウィジェット
  - TaskBar: 個々のタスクバー
  - TimelineHeader: 日付ヘッダー
  - TaskList: 左側のタスクリスト
```

### データ構造
- 既存のTaskItemモデルを使用
- 着手日・完了日は既に実装済みのHive box（'taskDates'）から読み込み
- 期限日（dueDate）をフォールバックとして使用

### 実装の優先順位

#### Phase 1: 基本機能（必須）
1. タスクリストとタイムラインの基本表示
2. 着手日・完了日（または期限日）に基づくタスクバーの表示
3. ズーム機能（日/週/月表示）
4. タスクバーのクリックでタスク詳細ダイアログを表示

#### Phase 2: インタラクティブ機能
1. タスクバーのドラッグ&ドロップで期間変更
2. バーの端をドラッグして着手日・完了日を調整
3. フィルタリング機能

#### Phase 3: 高度な機能
1. 依存関係の表示
2. グループ化機能
3. 統計情報の表示
4. クリティカルパスの強調表示

## 技術的な考慮事項

### パフォーマンス
- 大量のタスクがある場合のパフォーマンス最適化が必要
- 仮想スクロールの実装を検討

### データ同期
- タスクの期間変更時に、Hive boxの'taskDates'を更新
- TaskItemのdueDateとの整合性を保つ

### UI/UX
- レスポンシブデザインに対応
- マウスホイールでのスクロール
- キーボードショートカットのサポート

## 実装例

### 基本構造
```dart
class GanttChartView extends StatelessWidget {
  final List<TaskItem> tasks;
  final DateTime startDate;
  final DateTime endDate;
  final GanttViewMode viewMode; // day, week, month
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左側: タスクリスト
        Expanded(
          flex: 2,
          child: TaskList(tasks: tasks),
        ),
        // 右側: タイムライン
        Expanded(
          flex: 8,
          child: TimelineView(
            tasks: tasks,
            startDate: startDate,
            endDate: endDate,
            viewMode: viewMode,
          ),
        ),
      ],
    );
  }
}
```

### タスクバーの表示
```dart
class TaskBar extends StatelessWidget {
  final TaskItem task;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime startDate;
  final double dayWidth;
  
  @override
  Widget build(BuildContext context) {
    final barStart = _calculateBarStart(startedAt ?? task.dueDate);
    final barEnd = _calculateBarEnd(completedAt ?? task.dueDate);
    final barWidth = (barEnd.difference(barStart).inDays + 1) * dayWidth;
    
    return Positioned(
      left: barStart,
      width: barWidth,
      child: Container(
        decoration: BoxDecoration(
          color: _getTaskColor(task.status),
          borderRadius: BorderRadius.circular(4),
        ),
        child: GestureDetector(
          onTap: () => _showTaskDialog(context, task),
          onPanUpdate: (details) => _updateTaskDate(details),
        ),
      ),
    );
  }
}
```

## 追加の検討事項

### エクスポート機能
- PDF形式でのガントチャート出力
- 画像形式（PNG/JPG）での保存
- 印刷機能

### インポート機能
- Microsoft Project形式（.mpp）からのインポート
- 他のプロジェクト管理ツールからの移行

### カスタマイズ
- 色テーマのカスタマイズ
- 表示期間のカスタマイズ
- タスクバーのスタイルカスタマイズ

## 今後の拡張
- リソース管理機能（担当者別の表示）
- コスト管理機能
- マイルストーンの表示
- 複数プロジェクトの統合表示

