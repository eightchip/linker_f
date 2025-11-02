# タスクのグループ化表示 - 具体的な実装提案

## 概要
タスク一覧画面で、タスクを様々な基準でグループ化して表示する機能。スキーマ変更なしで、既存の`TaskItem`フィールドを活用します。

## グループ化の基準（選択可能）

### 1. **期限日でグループ化**
既存フィールド: `dueDate` (DateTime?)

**グループ例:**
- **今日** - `dueDate`が今日のタスク
- **明日** - `dueDate`が明日のタスク
- **今週** - `dueDate`が今週（月曜～日曜）のタスク
- **来週** - `dueDate`が来週のタスク
- **今月** - `dueDate`が今月のタスク
- **来月以降** - `dueDate`が来月以降のタスク
- **期限切れ** - `dueDate`が過去のタスク
- **期限未設定** - `dueDate`がnullのタスク

**実装方法:**
```dart
Map<String, List<TaskItem>> _groupByDueDate(List<TaskItem> tasks) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  final nextWeekStart = weekEnd.add(const Duration(days: 1));
  final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonthStart = DateTime(now.year, now.month + 1, 1);

  final groups = <String, List<TaskItem>>{
    '今日': [],
    '明日': [],
    '今週': [],
    '来週': [],
    '今月': [],
    '来月以降': [],
    '期限切れ': [],
    '期限未設定': [],
  };

  for (final task in tasks) {
    if (task.dueDate == null) {
      groups['期限未設定']!.add(task);
      continue;
    }

    final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    
    if (taskDate == today) {
      groups['今日']!.add(task);
    } else if (taskDate == tomorrow) {
      groups['明日']!.add(task);
    } else if (taskDate.isBefore(today)) {
      groups['期限切れ']!.add(task);
    } else if (taskDate.isAfter(nextWeekEnd)) {
      if (taskDate.isBefore(nextMonthStart)) {
        groups['今月']!.add(task);
      } else {
        groups['来月以降']!.add(task);
      }
    } else if (taskDate.isAfter(weekEnd)) {
      groups['来週']!.add(task);
    } else {
      groups['今週']!.add(task);
    }
  }

  // 空のグループを削除
  groups.removeWhere((key, value) => value.isEmpty);
  return groups;
}
```

---

### 2. **タグでグループ化**
既存フィールド: `tags` (List<String>)

**グループ例:**
- **タグごと** - 各タグ名がグループ名
- **タグなし** - `tags.isEmpty`のタスク
- **複数タグ** - 複数のタグを持つタスクは各タググループに表示（重複あり）

**実装方法:**
```dart
Map<String, List<TaskItem>> _groupByTags(List<TaskItem> tasks) {
  final groups = <String, List<TaskItem>>{};
  
  for (final task in tasks) {
    if (task.tags.isEmpty) {
      if (!groups.containsKey('タグなし')) {
        groups['タグなし'] = [];
      }
      groups['タグなし']!.add(task);
    } else {
      for (final tag in task.tags) {
        if (!groups.containsKey(tag)) {
          groups[tag] = [];
        }
        groups[tag]!.add(task);
      }
    }
  }
  
  return groups;
}
```

---

### 3. **関連リンクIDでグループ化（プロジェクト的な使い方）**
既存フィールド: `relatedLinkId` (String?)

**グループ例:**
- **リンクIDごと** - 同じ`relatedLinkId`を持つタスクをグループ化
- **リンクなし** - `relatedLinkId`がnullのタスク

**実装方法:**
```dart
Map<String, List<TaskItem>> _groupByLinkId(List<TaskItem> tasks) {
  final groups = <String, List<TaskItem>>{};
  final linkLabels = <String, String>{}; // linkId -> label のマッピング
  
  for (final task in tasks) {
    final linkId = task.relatedLinkId;
    if (linkId == null || linkId.isEmpty) {
      if (!groups.containsKey('リンクなし')) {
        groups['リンクなし'] = [];
      }
      groups['リンクなし']!.add(task);
    } else {
      // リンクラベルを取得（既存の_getLinkLabelメソッドを使用）
      final label = _getLinkLabel(linkId) ?? linkId;
      linkLabels[linkId] = label;
      
      if (!groups.containsKey(label)) {
        groups[label] = [];
      }
      groups[label]!.add(task);
    }
  }
  
  return groups;
}
```

---

### 4. **ステータスでグループ化**
既存フィールド: `status` (TaskStatus)

**グループ例:**
- **未着手** - `TaskStatus.pending`
- **進行中** - `TaskStatus.inProgress`
- **完了** - `TaskStatus.completed`
- **キャンセル** - `TaskStatus.cancelled`

**実装方法:**
```dart
Map<String, List<TaskItem>> _groupByStatus(List<TaskItem> tasks) {
  final groups = <String, List<TaskItem>>{
    '未着手': [],
    '進行中': [],
    '完了': [],
    'キャンセル': [],
  };

  for (final task in tasks) {
    switch (task.status) {
      case TaskStatus.pending:
        groups['未着手']!.add(task);
        break;
      case TaskStatus.inProgress:
        groups['進行中']!.add(task);
        break;
      case TaskStatus.completed:
        groups['完了']!.add(task);
        break;
      case TaskStatus.cancelled:
        groups['キャンセル']!.add(task);
        break;
    }
  }

  groups.removeWhere((key, value) => value.isEmpty);
  return groups;
}
```

---

### 5. **優先度でグループ化**
既存フィールド: `priority` (TaskPriority)

**グループ例:**
- **緊急** - `TaskPriority.urgent`
- **高** - `TaskPriority.high`
- **中** - `TaskPriority.medium`
- **低** - `TaskPriority.low`

**実装方法:**
```dart
Map<String, List<TaskItem>> _groupByPriority(List<TaskItem> tasks) {
  final groups = <String, List<TaskItem>>{
    '緊急': [],
    '高': [],
    '中': [],
    '低': [],
  };

  for (final task in tasks) {
    switch (task.priority) {
      case TaskPriority.urgent:
        groups['緊急']!.add(task);
        break;
      case TaskPriority.high:
        groups['高']!.add(task);
        break;
      case TaskPriority.medium:
        groups['中']!.add(task);
        break;
      case TaskPriority.low:
        groups['低']!.add(task);
        break;
    }
  }

  groups.removeWhere((key, value) => value.isEmpty);
  return groups;
}
```

---

## UI実装方法

### グループ化表示の切り替え
```dart
enum GroupByOption {
  none,      // グループ化なし（通常表示）
  dueDate,   // 期限日でグループ化
  tags,      // タグでグループ化
  linkId,    // リンクIDでグループ化
  status,    // ステータスでグループ化
  priority,  // 優先度でグループ化
}

// 状態変数
GroupByOption _groupByOption = GroupByOption.none;
```

### ExpansionTileを使ったUI
```dart
Widget _buildGroupedTaskList(Map<String, List<TaskItem>> groups) {
  final sortedKeys = groups.keys.toList();
  // グループの表示順序を調整（例：期限日の場合は時系列順）
  
  return ListView.builder(
    itemCount: sortedKeys.length,
    itemBuilder: (context, index) {
      final groupName = sortedKeys[index];
      final tasks = groups[groupName]!;
      
      return ExpansionTile(
        leading: Icon(_getGroupIcon(groupName)),
        title: Text('$groupName (${tasks.length}件)'),
        initiallyExpanded: true, // または最後に開いていたグループを記憶
        children: tasks.map((task) => _buildTaskItem(task)).toList(),
      );
    },
  );
}
```

### メニューでの選択
タスク一覧のヘッダーまたはフィルターメニューに、グループ化の選択UIを追加：
```dart
PopupMenuButton<GroupByOption>(
  icon: Icon(Icons.group),
  tooltip: 'グループ化',
  itemBuilder: (context) => [
    PopupMenuItem(
      value: GroupByOption.none,
      child: Row(
        children: [
          Icon(Icons.list, size: 20),
          SizedBox(width: 8),
          Text('グループ化なし'),
        ],
      ),
    ),
    PopupMenuItem(
      value: GroupByOption.dueDate,
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 20),
          SizedBox(width: 8),
          Text('期限日でグループ化'),
        ],
      ),
    ),
    PopupMenuItem(
      value: GroupByOption.tags,
      child: Row(
        children: [
          Icon(Icons.label, size: 20),
          SizedBox(width: 8),
          Text('タグでグループ化'),
        ],
      ),
    ),
    PopupMenuItem(
      value: GroupByOption.linkId,
      child: Row(
        children: [
          Icon(Icons.link, size: 20),
          SizedBox(width: 8),
          Text('プロジェクト（リンク）でグループ化'),
        ],
      ),
    ),
    PopupMenuItem(
      value: GroupByOption.status,
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20),
          SizedBox(width: 8),
          Text('ステータスでグループ化'),
        ],
      ),
    ),
    PopupMenuItem(
      value: GroupByOption.priority,
      child: Row(
        children: [
          Icon(Icons.flag, size: 20),
          SizedBox(width: 8),
          Text('優先度でグループ化'),
        ],
      ),
    ),
  ],
  onSelected: (value) {
    setState(() {
      _groupByOption = value;
    });
  },
)
```

---

## 実装時の考慮事項

### 1. **フィルターとの併用**
- グループ化は、既存のフィルター（ステータス、優先度、検索）適用後のタスクに対して適用
- グループ化後も、各グループ内でタスクのソートは維持

### 2. **パフォーマンス**
- 大量のタスクでも動作するよう、グループ化処理は効率的に実装
- `ExpansionTile`の`initiallyExpanded`はデフォルトで`true`、または最後の状態を記憶

### 3. **UI表示**
- 各グループのヘッダーにタスク数を表示
- グループ名のアイコンを適切に設定（期限日=カレンダー、タグ=ラベルなど）
- グループの展開/折りたたみ状態を記憶（オプション）

### 4. **空のグループ**
- タスクが0件のグループは非表示

### 5. **複数基準の組み合わせ**
- 将来的に、2つの基準を組み合わせたグループ化も可能（例：期限日×ステータス）
- 初回実装では単一基準に限定

---

## 実装難易度
- **低〜中**: 既存のデータ構造を活用するため、スキーマ変更なし
- グループ化ロジック: 低
- UI実装: 中（ExpansionTileの統合）

---

## メリット
1. **大量タスクの管理**: 関連タスクをまとめて表示
2. **視認性向上**: 重要度や期限で整理
3. **プロジェクト管理**: リンクIDによるグループ化でプロジェクト単位の管理が可能
4. **柔軟性**: 用途に応じてグループ化基準を切り替え可能

