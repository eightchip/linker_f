// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Link Navigator';

  @override
  String get settings => '設定';

  @override
  String get general => '一般';

  @override
  String get theme => 'テーマ';

  @override
  String get font => 'フォント';

  @override
  String get backup => 'バックアップ';

  @override
  String get notifications => '通知';

  @override
  String get outlook => 'Outlook連携';

  @override
  String get language => '言語';

  @override
  String get japanese => '日本語';

  @override
  String get english => 'English';

  @override
  String get enableAutomaticImport => '自動取込を有効にする';

  @override
  String get enableAutomaticImportDescription =>
      'Outlookの個人カレンダーから予定を自動的に取り込みます。取り込んだ予定は「Outlook連携（自動取込）」タスクに紐づけられます。\n\n⚠️ 注意: 自動取込実行時に起動しているOutlookが落ちる場合があります。';

  @override
  String get importPeriod => '取込期間';

  @override
  String get importPeriodDescription => '明日を起点に、どこまで未来の予定を取り込むか設定します。';

  @override
  String get automaticImportFrequency => '自動取込の頻度';

  @override
  String get onlyOnAppStart => 'アプリ起動時のみ';

  @override
  String get every30Minutes => '30分ごと';

  @override
  String get every1Hour => '1時間ごと';

  @override
  String get everyMorning9am => '毎朝9:00';

  @override
  String get oneWeek => '1週間';

  @override
  String get twoWeeks => '2週間';

  @override
  String get oneMonth => '1ヶ月';

  @override
  String get threeMonths => '3ヶ月';

  @override
  String get halfYear => '半年';

  @override
  String get oneYear => '1年';

  @override
  String get taskManagement => 'タスク管理';

  @override
  String get linkManagement => 'リンク管理';

  @override
  String itemsSelected(int count) {
    return '$count件選択中';
  }

  @override
  String get startWithTaskScreen => 'タスク画面で起動';

  @override
  String get startWithTaskScreenDescription =>
      'アプリ起動時にタスク画面をデフォルトで表示します。オフにすると、リンク管理画面で起動します。';

  @override
  String get appearance => '外観';

  @override
  String get layout => 'レイアウト';

  @override
  String get data => 'データ';

  @override
  String get integration => '連携';

  @override
  String get others => 'その他';

  @override
  String get startupSettings => '起動設定';

  @override
  String get themeSettings => 'テーマ設定';

  @override
  String get fontSettings => 'フォント設定';

  @override
  String get uiCustomization => 'UIカスタマイズ';

  @override
  String get gridSettings => 'グリッド設定';

  @override
  String get cardSettings => 'カード設定';

  @override
  String get itemSettings => 'アイテム設定';

  @override
  String get cardViewSettings => 'カードビュー設定';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get gmailIntegration => 'Gmail連携';

  @override
  String get reset => 'リセット';

  @override
  String get allScreens => '全画面共通';

  @override
  String get linkScreen => 'リンク画面';

  @override
  String get linkAndTaskScreens => 'リンク・タスク画面';

  @override
  String get taskList => 'タスク一覧';

  @override
  String get integrationSettingsRequired => '各連携機能には個別の設定が必要です';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get useDarkTheme => 'ダークテーマを使用';

  @override
  String get cancel => 'キャンセル';

  @override
  String get resetSettings => '設定をリセット';

  @override
  String get resetSettingsConfirm => 'すべてのUI設定をデフォルト値にリセットしますか？\nこの操作は取り消せません。';

  @override
  String get resetExecuted => 'リセット実行';

  @override
  String get uiSettingsReset => 'UI設定をリセット';

  @override
  String get uiSettingsResetConfirm =>
      'すべてのUIカスタマイズ設定をデフォルト値にリセットします。\n\nこの操作は取り消せません。\n本当に実行しますか？';

  @override
  String get uiSettingsResetSuccess => 'UI設定をリセットしました';

  @override
  String get save => '保存';

  @override
  String get close => '閉じる';

  @override
  String get addGroup => 'グループを追加';

  @override
  String get search => '検索';

  @override
  String get memoBulkEdit => 'メモ一括編集';

  @override
  String get shortcutKeys => 'ショートカットキー';

  @override
  String get linkManagementShortcuts => 'リンク管理ショートカット';

  @override
  String get addGroupShortcut => 'グループを追加';

  @override
  String get openSearchBar => '検索バーを開く';

  @override
  String get openTaskManagement => 'タスク管理画面を開く';

  @override
  String get openMemoBulkEdit => 'メモ一括編集を開く';

  @override
  String get changeGroupOrder => 'グループの並び順を変更';

  @override
  String get openSettings => '設定を開く';

  @override
  String get showThreeDotMenu => '3点メニューを表示';

  @override
  String get focusThreeDotMenu => '3点メニューにフォーカス';

  @override
  String get closeSearchBar => '検索バーを閉じる';

  @override
  String get switchLinkTypeFilter => 'リンクタイプフィルターを切り替え';

  @override
  String get showShortcutList => 'ショートカット一覧を表示';

  @override
  String linksCount(int count) {
    return '$count件のリンク';
  }

  @override
  String get searchLinkNameMemo => '検索（リンク名・メモ内容）';

  @override
  String resultsCount(int count) {
    return '$count件の結果';
  }

  @override
  String get noSearchResults => '検索結果がありません';

  @override
  String get noMemoLinks => 'メモが登録されているリンクがありません';

  @override
  String get saveAll => 'まとめて保存';

  @override
  String get searchPlaceholder => '検索（ファイル名・フォルダ名・URL・タグ）';

  @override
  String get type => 'タイプ';

  @override
  String get all => 'すべて';

  @override
  String get url => 'URL';

  @override
  String get folder => 'フォルダ';

  @override
  String get file => 'ファイル';

  @override
  String get globalMenu => 'グローバルメニュー';

  @override
  String get common => '共通';

  @override
  String get linkManagementEnabled => 'リンク管理（リンク管理画面で有効）';

  @override
  String get taskManagementEnabled => 'タスク管理（タスク管理画面で有効）';

  @override
  String get newTask => '新しいタスク';

  @override
  String get bulkSelectMode => '一括選択モード';

  @override
  String get csvExport => 'CSV出力';

  @override
  String get scheduleList => 'スケジュール一覧';

  @override
  String get grouping => 'グループ化';

  @override
  String get createFromTemplate => 'テンプレートから作成';

  @override
  String get toggleStatisticsSearchBar => '統計・検索バー表示/非表示';

  @override
  String get helpCenter => 'ヘルプセンター';

  @override
  String get pathOrUrl => 'パス/URL';

  @override
  String get enterPathOrUrl => 'ファイルパスまたはURLを入力...';

  @override
  String get selectFolderIcon => 'フォルダアイコンを選択:';

  @override
  String get homeScreen => 'ホーム画面に戻る';

  @override
  String get exitSelectionMode => '選択モードを終了';

  @override
  String get searchTasks => 'タスクを検索（タイトル・説明・タグ・依頼先）';

  @override
  String get searchWithRegex => '正規表現で検索（例: ^プロジェクト.*完了\\\$）';

  @override
  String get searchHistory => '検索履歴';

  @override
  String get clear => 'クリア';

  @override
  String get switchToNormalSearch => '通常検索に切り替え';

  @override
  String get switchToRegexSearch => '正規表現検索に切り替え';

  @override
  String get searchOptions => '検索オプション';

  @override
  String get addMemo => 'メモ追加';

  @override
  String get memoCanBeAddedFromLinkManagement => 'メモはリンク管理画面から追加可能';

  @override
  String get unpin => 'ピンを外す';

  @override
  String get pinToTop => '上部にピン留め';

  @override
  String get changeStatus => 'ステータスを変更';

  @override
  String get changePriority => '優先度を変更';

  @override
  String get hideFilters => 'フィルターを隠す';

  @override
  String get showFilters => 'フィルターを表示';

  @override
  String get changeGridColumns => 'グリッド列数を変更';

  @override
  String get saveLoadFilters => 'フィルター保存・読み込み';

  @override
  String get bulkOperations => '一括操作';

  @override
  String get memoLabel => 'メモ';

  @override
  String get selectAll => '全選択';

  @override
  String get deselectAll => '全解除';

  @override
  String get cardView => 'カードビュー';

  @override
  String get listView => 'リスト表示';

  @override
  String get status => 'ステータス';

  @override
  String get notStarted => '未着手';

  @override
  String get inProgress => '進行中';

  @override
  String get completed => '完了';

  @override
  String get sortOrder => '並び替え順序';

  @override
  String get firstPriority => '第1順位';

  @override
  String get secondPriority => '第2順位';

  @override
  String get thirdPriority => '第3順位';

  @override
  String get dueDateOrder => '期限順';

  @override
  String get statusOrder => 'ステータス順';

  @override
  String get ascending => '昇順';

  @override
  String get descending => '降順';

  @override
  String get priorityOrder => '優先度順';

  @override
  String get titleOrder => 'タイトル順';

  @override
  String get createdOrder => '作成日順';

  @override
  String get none => 'なし';

  @override
  String get details => '詳細';

  @override
  String get collapseLinks => 'リンクを折りたたむ';

  @override
  String get expandLinks => 'リンクを展開';

  @override
  String get subtask => 'サブタスク';

  @override
  String subtaskTooltip(int total, int completed) {
    return 'サブタスク: $total個\n完了: $completed個';
  }

  @override
  String get showAllDetails => 'すべて詳細表示';

  @override
  String get hideAllDetails => 'すべて詳細非表示';

  @override
  String get toggleDetails => '詳細表示/非表示切り替え';

  @override
  String get columns => '列';

  @override
  String get notStartedTasks => '未着手タスク';

  @override
  String get inProgressTasks => '進行中タスク';

  @override
  String get statusChange => 'ステータス変更';

  @override
  String get clearDueDate => '期限日をクリア';

  @override
  String get clearHistory => '履歴クリア';

  @override
  String get clearHistoryConfirm => '履歴をクリア';

  @override
  String get noGrouping => 'グループ化なし';

  @override
  String get groupByStatus => 'ステータスでグループ化';

  @override
  String get noTags => 'タグなし';

  @override
  String get noLinks => 'リンクなし';

  @override
  String countItems(String label, int count) {
    return '$label: $count件';
  }

  @override
  String get tapForDetails => 'タップで詳細表示';

  @override
  String get deleteGroup => 'グループを削除';

  @override
  String get addLink => 'リンクを追加';

  @override
  String get editLink => 'リンクを編集';

  @override
  String get deleteLink => 'リンクを削除';

  @override
  String get addTaskFromLink => 'リンクからタスクを追加';

  @override
  String get copy => 'コピー';

  @override
  String get syncTask => 'このタスクを同期';

  @override
  String get delete => '削除';

  @override
  String get high => '高';

  @override
  String get medium => '中';

  @override
  String get low => '低';

  @override
  String get urgent => '緊急';

  @override
  String get lowShort => '低';

  @override
  String get mediumShort => '中';

  @override
  String get highShort => '高';

  @override
  String get urgentShort => '緊';

  @override
  String get cancelled => 'キャンセル';

  @override
  String get cancelledShort => '止';

  @override
  String get dueDate => '期限';

  @override
  String get started => '着手';

  @override
  String get taskManagementShortcuts => 'タスク管理ショートカット';

  @override
  String get minimize => '最小化';

  @override
  String get maximize => '最大化';

  @override
  String get restoreWindow => '元のサイズに戻す';

  @override
  String get shortcutList => 'ショートカット一覧';

  @override
  String get scheduleScreen => '予定表';

  @override
  String get searchSchedule => '予定タイトル、タスク名、場所で検索';

  @override
  String get switchView => '表示切り替え';

  @override
  String get monthlyView => '月次表示';

  @override
  String get showPast => '過去を表示';

  @override
  String get importFromOutlook => 'Outlookから予定を取り込む';

  @override
  String get copyToExcel => 'エクセルにコピー';

  @override
  String copyToExcelSelected(int count) {
    return 'エクセルにコピー（選択された$count日分の予定をクリップボードにコピー）';
  }

  @override
  String get copyToExcelSelectDate => 'エクセルにコピー（日付を選択してください）';

  @override
  String get tableFormat => '表形式（複数列）';

  @override
  String get oneCellFormat => '1セル形式（列挙）';

  @override
  String get action => 'アクション';

  @override
  String get today => '今日';

  @override
  String daysRemaining(int count) {
    return 'あと$count日';
  }

  @override
  String get oneDayRemaining => 'あと1日';

  @override
  String daysOverdue(int count) {
    return '$count日超過';
  }

  @override
  String get notSet => '未設定';

  @override
  String showOtherLinks(int count) {
    return '他$count個のリンクを表示';
  }

  @override
  String get editTask => 'タスクを編集';

  @override
  String get title => 'タイトル';

  @override
  String get body => '本文';

  @override
  String get descriptionForRequestor => '依頼先への説明';

  @override
  String get tags => 'タグ';

  @override
  String get startDate => '着手日';

  @override
  String get completionDate => '完了日';

  @override
  String get reminderFunction => 'リマインダー機能';

  @override
  String get linkAssociation => 'リンク関連付け';

  @override
  String get relatedLinks => '関連リンク';

  @override
  String get pinning => 'ピン留め';

  @override
  String get schedule => '予定';

  @override
  String get emailSendingFunction => 'メール送信機能';

  @override
  String get openEmailSendingFunction => 'メール送信機能を開く';

  @override
  String get collapseMailFunction => 'メール機能を折りたたむ';

  @override
  String get update => '更新';

  @override
  String get selectStartDate => '着手日を選択';

  @override
  String get subtaskTitle => 'サブタスクタイトル';

  @override
  String get estimatedTime => '推定時間 (分)';

  @override
  String get description => '説明';

  @override
  String get add => '追加';

  @override
  String get creationDate => '作成日';

  @override
  String get subtaskName => 'サブタスク名';

  @override
  String get enterTitle => 'タイトルを入力してください';

  @override
  String get bodyTextCanDisplayUpTo8Lines => '本文は8行まで表示できます。';

  @override
  String get noSubtasks => 'サブタスクがありません';

  @override
  String estimatedTimeMinutes(int minutes) {
    return '推定時間: $minutes分';
  }

  @override
  String get create => '作成';

  @override
  String get selectDueDate => '期限日を選択';

  @override
  String get priority => '優先度';

  @override
  String get clearStartDate => '着手日をクリア';

  @override
  String get selectCompletionDate => '完了日を選択';

  @override
  String get clearCompletionDate => '完了日をクリア';

  @override
  String get pinnedToTop => '上部にピン留め中';

  @override
  String get howToUseRegex => '正規表現の使い方';

  @override
  String get commonPatterns => 'よく使うパターン:';

  @override
  String get copyPattern => 'パターンをコピー';

  @override
  String patternCopied(String pattern) {
    return '「$pattern」をコピーしました';
  }

  @override
  String get regexInvalidWarning => '正規表現が無効な場合は自動的に通常検索に切り替わります';

  @override
  String get regexExample1 => '「プロジェクト」で始まるタスク';

  @override
  String get regexExample2 => '「完了」で終わるタスク';

  @override
  String get regexExample3 => '「プロジェクト」で始まり「完了」で終わるタスク';

  @override
  String get regexExample4 => '「緊急」または「重要」を含むタスク';

  @override
  String get regexExample5 => '日付形式（YYYY-MM-DD）を含むタスク';

  @override
  String get regexExample6 => '2文字以上の大文字を含むタスク';

  @override
  String get regexExample7 => '1〜10文字のタスクタイトル';

  @override
  String get saveFilter => 'フィルターを保存';

  @override
  String get filterName => 'フィルター名';

  @override
  String get filterNameExample => '例: 今週の緊急タスク';

  @override
  String filterSaved(String name) {
    return 'フィルター「$name」を保存しました';
  }

  @override
  String get noSavedFilters => '保存されたフィルターがありません';

  @override
  String filterLoaded(String name) {
    return 'フィルター「$name」を読み込みました';
  }

  @override
  String get exportFilterPresets => 'フィルタープリセットをエクスポート';

  @override
  String get filterPresetsExported => 'フィルタープリセットをエクスポートしました';

  @override
  String get importFilterPresets => 'フィルタープリセットをインポート';

  @override
  String filterPresetsImported(int count) {
    return '$count件のフィルタープリセットをインポートしました';
  }

  @override
  String get export => 'エクスポート';

  @override
  String get import => 'インポート';

  @override
  String get quickFilterApplied => 'クイックフィルターを適用しました';

  @override
  String get filterReset => 'フィルターをリセットしました';

  @override
  String get editGroupName => 'グループ名を編集';

  @override
  String get createTaskFromLink => 'このリンクからタスクを作成';

  @override
  String get activeTaskExists => 'アクティブなタスクがあります';

  @override
  String get selectCopyDestination => 'コピー先を選択';

  @override
  String get selectMoveDestination => '移動先を選択';

  @override
  String linkCopied(String linkName, String groupName) {
    return '「$linkName」を「$groupName」にコピーしました';
  }

  @override
  String linkMoved(String linkName, String groupName) {
    return '「$linkName」を「$groupName」に移動しました';
  }

  @override
  String copyFailed(String error) {
    return 'コピーに失敗しました: $error';
  }

  @override
  String get copyNotAvailable => 'コピー機能が利用できません';

  @override
  String get moveNotAvailable => '移動機能が利用できません';

  @override
  String get noCopyDestinationGroups => 'コピー先のグループがありません';

  @override
  String get noMoveDestinationGroups => '移動先のグループがありません';

  @override
  String get dragToReorder => 'ドラッグ&ドロップで並び順を変更できます';

  @override
  String get groupOrderChanged => 'グループの並び順を変更しました';

  @override
  String get taskTemplate => 'タスクテンプレート';

  @override
  String get selectTemplate => 'テンプレートを選択';

  @override
  String get taskDetails => 'タスク詳細';

  @override
  String get templateName => 'テンプレート名';

  @override
  String get templateNameExample => '例: 会議準備、定期報告など';

  @override
  String get createTask => 'タスクを作成';

  @override
  String get editTemplate => 'テンプレート編集';

  @override
  String get editComplete => '編集完了';

  @override
  String get addNewTemplate => '新しいテンプレートを追加';

  @override
  String get syncThisTask => 'このタスクを同期';

  @override
  String get taskCreated => 'タスクを作成しました';

  @override
  String get reminder => 'リマインダー';

  @override
  String get selectPlease => '選択してください';

  @override
  String get createNewTask => '新しいタスクを作成';

  @override
  String get toggleBatchSelectionMode => '一括選択モードを切り替え';

  @override
  String get exportToCsv => 'CSVにエクスポート';

  @override
  String get openSettingsScreen => '設定画面を開く';

  @override
  String get openSchedule => '予定表を開く';

  @override
  String get groupingMenu => 'グループ化メニュー';

  @override
  String get toggleCompactStandardDisplay => 'コンパクト⇔標準表示切り替え';

  @override
  String get goHomeOrOpenThreeDotMenu => 'ホームへ戻る / 3点メニューを開く';

  @override
  String get history => '履歴';

  @override
  String get task => 'タスク';

  @override
  String get saveCurrentFilter => '現在のフィルターを保存';

  @override
  String get filterManagement => 'フィルター管理';

  @override
  String get urgentTasks => '緊急タスク';

  @override
  String get todayTasks => '今日のタスク';

  @override
  String get total => '総';

  @override
  String get totalTasks => '総タスク';

  @override
  String get inProgressShort => '進';

  @override
  String get completedShort => '完';

  @override
  String get notStartedShort => '未';

  @override
  String get inProgressShort2 => '中';

  @override
  String get descriptionText => '説明文';

  @override
  String get requester => '依頼先';

  @override
  String get normalSearchMode => '通常検索モード';

  @override
  String get regexSearchMode => '正規表現検索モード';
}
