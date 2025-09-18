# 📋 タスク管理UI改善 指示書（Cursor用）

## 1️⃣ タスク画面（個別タスクごとの表示）

### 改善ポイント
- **期限日を最重要要素として強調**（背景色＋太字、大きめフォント）  
- **ステータス＋リマインダー＋進捗**をまとめて右端に揃え、一覧性UP  
- **説明・リンクは折りたたみ**で表示量を調整  
- **行間の詰め方改善**でカードをより多く表示可能に  

### コード例
```dart
// TaskCard レイアウト
Card(
  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
  child: ListTile(
    leading: Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: deadlineColor(task.deadline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        formatDate(task.deadline),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ),
    title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w600)),
    subtitle: _expanded ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.description.isNotEmpty) Text(task.description, style: TextStyle(color: Colors.grey[700])),
        ...task.links.map((l) => InkWell(onTap: ()=>openLink(l), child: Text(l, style: TextStyle(color: Colors.blue)))),
      ],
    ) : null,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.reminderAt != null) Icon(Icons.notifications_active, color: Colors.orange),
        Chip(label: Text(task.status), backgroundColor: statusColor(task.status)),
        Text("${task.subtasksDone}/${task.subtasksTotal}"),
      ],
    ),
    onTap: ()=> setState(()=> _expanded = !_expanded),
  ),
);
```

---

## 2️⃣ タスク編集モーダル

### 改善ポイント
- **色の明暗差を強化**（背景=明、入力欄=濃い枠線＋Hover時の強調）  
- **メモ欄入力不具合**（カーソルがスキップする現象）は `TextField` のIME/フォーカス制御を修正  
- **入力欄の余白と行間を広めに**してストレスなく編集可能に  

### コード例
```dart
// TextField (メモ欄)
TextField(
  controller: _memoController,
  decoration: InputDecoration(
    hintText: "依頼先やメモ",
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue, width: 2),
    ),
  ),
  keyboardType: TextInputType.multiline,
  maxLines: null,
  textInputAction: TextInputAction.newline,
  enableInteractiveSelection: true, // ← カーソル移動改善
)
```

---

## 3️⃣ メール送信機能改善

### 改善ポイント
- **サブタスクも本文に含める**（✅/⬜️マーク＋推定時間＋完了日時をリスト化）  
- **CC/BCC入力欄は削除**しシンプル化（To のみ）  
- **本文レイアウトはHTMLで美しく**、リンクは `<a>` 形式で直接クリック可能に  

### コード例
```dart
// メール本文生成（サブタスク込み）
String buildMailHtml(Task t) {
  final subs = t.subtasks.map((s) =>
    "<li>${s.done ? '✅' : '⬜️'} ${s.title} "
    "${s.estimatedMinutes != null ? '(${s.estimatedMinutes}分)' : ''}"
    "${s.doneAt != null ? '｜完了: ${s.doneAt}' : ''}</li>"
  ).join();

  return '''
  <h2>${t.title}</h2>
  <p><b>期限:</b> ${t.deadline ?? "未設定"} ｜ <b>ステータス:</b> ${t.status}</p>
  ${t.description != null ? "<p>${t.description}</p>" : ""}
  <h3>サブタスク</h3>
  <ul>$subs</ul>
  <h3>関連資料</h3>
  <ul>${t.links.map((l) => "<li><a href='$l'>$l</a></li>").join()}</ul>
  <hr><small>このメールはタスク管理アプリから送信されました。</small>
  ''';
}
```

---

## 🚀 提案まとめ
- **タスク画面** → 期限日最優先・説明折りたたみ・右端に集約  
- **編集モーダル** → 入力しやすさUP・色コントラスト改善・カーソル不具合修正  
- **メール送信** → サブタスク込み・リンククリック可能・UI最小限化（Toのみ）  
