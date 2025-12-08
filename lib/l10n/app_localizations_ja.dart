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
    return '$count個のリンク';
  }

  @override
  String get searchLinkNameMemo => '検索（リンク名・メモ内容）';

  @override
  String resultsCount(int count) {
    return '$count件の結果';
  }

  @override
  String get noSearchResults => '検索結果なし';

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
  String get noSearchHistory => '検索履歴がありません';

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
  String get memoLabel => 'メモ:';

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
    return 'サブタスク: $total\n完了: $completed';
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
  String get deleteGroupConfirm => 'このグループを削除しますか？';

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
  String get cancelledShort => 'X';

  @override
  String get dueDate => '期限日';

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
  String get tableFormat => '表形式';

  @override
  String get oneCellFormat => '1セル形式';

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
  String get oneDayOverdue => '1日超過';

  @override
  String get notSet => '未設定';

  @override
  String showOtherLinks(int count) {
    return '他$count個のリンクを表示';
  }

  @override
  String get showMore => 'もっと見る';

  @override
  String get editTask => 'タスクを編集';

  @override
  String get title => 'タイトル';

  @override
  String get body => '本文';

  @override
  String get descriptionForRequestor => '依頼先への説明';

  @override
  String get descriptionForAssignee => '担当者への説明';

  @override
  String get tags => 'タグ';

  @override
  String get startDate => '開始日';

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
  String get selectStartDate => '開始日を選択';

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
  String get newGroupName => '新しいグループ名';

  @override
  String get color => '色';

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
  String get templateNameExample => '例: 部署標準リンク集';

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
  String get createNewTask => '新規タスク作成';

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
  String get inProgressShort => 'I';

  @override
  String get completedShort => 'C';

  @override
  String get notStartedShort => 'N';

  @override
  String get inProgressShort2 => 'I';

  @override
  String get descriptionText => '説明文';

  @override
  String get requester => '依頼者';

  @override
  String get normalSearchMode => '通常検索モード';

  @override
  String get normalSearchOption => '通常検索モード';

  @override
  String get regexSearchMode => '正規表現検索モード';

  @override
  String get scheduleTitle => '予定タイトル';

  @override
  String get startDateTime => '開始日時';

  @override
  String get endDateTime => '終了日時';

  @override
  String get location => '場所';

  @override
  String get selectDateTime => '日時を選択';

  @override
  String get selectDateTimeOptional => '日時を選択（任意）';

  @override
  String get addSchedule => '予定を追加';

  @override
  String get updateSchedule => '予定を更新';

  @override
  String get scheduleAdded => '予定を追加しました';

  @override
  String get startDateTimeRequired => '開始日時は必須です';

  @override
  String get outlookDesktop => 'Outlook（デスクトップ）';

  @override
  String get gmailWeb => 'Gmail（Web）';

  @override
  String get outlookTest => 'Outlookをテスト';

  @override
  String get gmailTest => 'Gmailをテスト';

  @override
  String get sendHistory => '送信履歴';

  @override
  String get launchMailer => 'メーラーを起動';

  @override
  String get mailSentComplete => 'メール送信完了';

  @override
  String get launchMailerFirst => 'まずメーラーを起動してください';

  @override
  String get copyTask => 'タスクをコピー';

  @override
  String copyTaskConfirm(String title) {
    return '「$title」をコピーしますか？';
  }

  @override
  String get repeatPeriod => '繰り返し期間:';

  @override
  String get monthly => '月次（1か月後）';

  @override
  String get quarterly => '四半期（3か月後）';

  @override
  String get yearly => '年次（1年後）';

  @override
  String get custom => 'カスタム';

  @override
  String get copyCount => 'コピー個数:';

  @override
  String copyCountLabel(int count) {
    return '$count個';
  }

  @override
  String get maxCopiesMonthly => '最大12個まで（1か月ずつ期限をずらしてコピー）';

  @override
  String get maxCopiesQuarterly => '最大4個まで（3か月ずつ期限をずらしてコピー）';

  @override
  String get selectReminderTime => 'リマインダー時間を選択（任意）';

  @override
  String get copiedContent => 'コピーされる内容:';

  @override
  String get titleLabel => 'タイトル:';

  @override
  String get copySuffix => 'コピー';

  @override
  String get descriptionLabel => '説明:';

  @override
  String get requestorMemoLabel => '依頼先・メモ:';

  @override
  String get copyCountLabel2 => 'コピー個数:';

  @override
  String get dueDateLabel => '期限:';

  @override
  String get reminderLabel => 'リマインダー:';

  @override
  String get priorityLabel => '優先度:';

  @override
  String get statusLabel => 'ステータス:';

  @override
  String get tagsLabel => 'タグ:';

  @override
  String get estimatedTimeLabel => '推定時間:';

  @override
  String get minutes => '分';

  @override
  String get subtasksLabel => 'サブタスク:';

  @override
  String get statusResetNote => '※ ステータスは「未着手」にリセットされます';

  @override
  String get subtasksCopiedNote => '※ サブタスクもコピーされます';

  @override
  String taskCopiedSuccess(int count) {
    return 'タスクを$count個コピーしました';
  }

  @override
  String taskCopiedPartial(int success, int failed) {
    return 'タスクを$success個コピーしました（$failed個失敗）';
  }

  @override
  String get taskCopyFailed => 'タスクのコピーに失敗しました';

  @override
  String get deleteTask => 'タスクを削除';

  @override
  String deleteTaskConfirm(String title) {
    return '「$title」を削除しますか？';
  }

  @override
  String get deleteOptions => '削除オプション:';

  @override
  String get deleteAppOnly => 'アプリのみ削除';

  @override
  String get deleteAppAndCalendar => 'アプリとGoogle Calendarから削除';

  @override
  String get appOnly => 'アプリのみ';

  @override
  String get deleteBoth => '両方削除';

  @override
  String taskDeletedSuccess(String title) {
    return '「$title」を削除しました';
  }

  @override
  String get deleteFailed => '削除に失敗しました';

  @override
  String taskDeletedFromBoth(String title) {
    return '「$title」をアプリとGoogle Calendarから削除しました';
  }

  @override
  String get confirm => '確認';

  @override
  String deleteSelectedTasks(int count) {
    return '選択した$count件のタスクを削除しますか？';
  }

  @override
  String backupExecuted(int count) {
    return 'バックアップを実行しました。$count件のタスクを削除します...';
  }

  @override
  String backupFailedContinue(String error) {
    return 'バックアップに失敗しましたが、結合を続行します: $error';
  }

  @override
  String get deleteSchedule => '予定を削除';

  @override
  String deleteScheduleConfirm(String title) {
    return '「$title」を削除しますか？';
  }

  @override
  String get warning => '警告';

  @override
  String get selectAtLeastTwoTasks => '2つ以上のタスクを選択してください';

  @override
  String get noSourceTasks => '結合元のタスクがありません';

  @override
  String get backupExecutedMerge => 'バックアップを実行しました。タスク結合を実行します...';

  @override
  String get taskMergeFailed => 'タスク結合に失敗しました';

  @override
  String get linkAssignmentFailed => 'リンク割り当てに失敗しました';

  @override
  String get statusChangeFailed => 'ステータス変更に失敗しました';

  @override
  String get priorityChangeFailed => '優先度変更に失敗しました';

  @override
  String get dueDateChangeFailed => '期限日変更に失敗しました';

  @override
  String get tagChangeFailed => 'タグ変更に失敗しました';

  @override
  String taskSyncedToCalendar(String title) {
    return '「$title」をGoogle Calendarに同期しました';
  }

  @override
  String taskSyncFailed(String title, String error) {
    return '「$title」の同期に失敗しました: $error';
  }

  @override
  String taskSyncError(String title, String error) {
    return '「$title」の同期中にエラーが発生しました: $error';
  }

  @override
  String get exportFailed => 'エクスポートに失敗しました';

  @override
  String get invalidFileFormat => '無効なファイル形式です';

  @override
  String get importFailed => 'インポートに失敗しました';

  @override
  String get sendHistorySearchError => '送信済み検索エラー';

  @override
  String get mailerLaunched => 'メーラーを起動しました';

  @override
  String get replyAddressNotFound => '返信先メールアドレスが見つかりません';

  @override
  String get mailerLaunchFailed => 'メーラーの起動に失敗しました';

  @override
  String linkOpenFailed(String href) {
    return 'リンクを開けませんでした: $href';
  }

  @override
  String uncPathOpenFailed(String path) {
    return 'UNCパスを開けませんでした: $path';
  }

  @override
  String urlOpenFailed(String url) {
    return 'URLを開けませんでした: $url';
  }

  @override
  String fileOpenFailed(String path) {
    return 'ファイルを開けませんでした: $path';
  }

  @override
  String contactAddError(String error) {
    return '連絡先追加エラー: $error';
  }

  @override
  String linksAddedToTasks(int count) {
    return '$count件のタスクにリンクを追加しました';
  }

  @override
  String linksRemovedFromTasks(int count) {
    return '$count件のタスクからリンクを削除しました';
  }

  @override
  String linksReplacedInTasks(int count) {
    return '$count件のタスクのリンクを置き換えました';
  }

  @override
  String linksChangedInTasks(int count) {
    return '$count件のタスクのリンクを変更しました';
  }

  @override
  String tagsAddedToTasks(int count) {
    return '$count件のタスクにタグを追加しました';
  }

  @override
  String tagsRemovedFromTasks(int count) {
    return '$count件のタスクからタグを削除しました';
  }

  @override
  String tagsReplacedInTasks(int count) {
    return '$count件のタスクのタグを置き換えました';
  }

  @override
  String tagsChangedInTasks(int count) {
    return '$count件のタスクのタグを変更しました';
  }

  @override
  String syncingTask(String title) {
    return '「$title」を同期中...';
  }

  @override
  String get fromTodayOneWeek => '今日から1週間';

  @override
  String get fromTodayTwoWeeks => '今日から2週間';

  @override
  String get fromTodayOneMonth => '今日から1ヶ月';

  @override
  String get fromTodayThreeMonths => '今日から3ヶ月';

  @override
  String get tagsCommaSeparated => 'タグ（カンマ区切り）';

  @override
  String get tagsExample => '例: 緊急,重要,プロジェクトA';

  @override
  String get tomorrow => '明日';

  @override
  String get thisWeek => '今週';

  @override
  String get nextWeek => '来週';

  @override
  String get thisMonth => '今月';

  @override
  String get later => '来月以降';

  @override
  String get overdue => '期限切れ';

  @override
  String get noDueDate => '期限未設定';

  @override
  String get colorPresets => 'カラープリセット';

  @override
  String get applyRecommendedColors => 'ワンタップでおすすめ配色を適用';

  @override
  String get accentColor => 'アクセントカラー';

  @override
  String get colorIntensity => '色の濃淡';

  @override
  String get contrastAdjustment => 'コントラスト調整';

  @override
  String get textColorSettings => 'テキスト色設定';

  @override
  String get cardViewFieldSettingsDescription =>
      'カードビューで表示される各フィールドのテキスト色、フォントサイズ、フォントファミリーを個別に設定できます';

  @override
  String get realtimePreview => 'リアルタイムプレビュー';

  @override
  String get live => 'ライブ';

  @override
  String get cardSettingsDescription =>
      'カードの見た目と動作を調整します。角丸半径、影の強さ、パディングを変更できます。';

  @override
  String get cornerRadius => '角丸半径';

  @override
  String get shadowStrength => '影の強さ';

  @override
  String get padding => 'パディング';

  @override
  String get sampleCard => 'サンプルカード';

  @override
  String get cardPreviewDescription => 'これはカードのプレビューです。設定を変更するとリアルタイムで反映されます。';

  @override
  String get sampleButton => 'サンプルボタン';

  @override
  String get outlineButton => 'アウトラインボタン';

  @override
  String get sampleInputField => 'サンプル入力フィールド';

  @override
  String currentSettings(String radius, String shadow, String padding) {
    return '角丸: ${radius}px | 影: $shadow% | パディング: ${padding}px';
  }

  @override
  String get buttonSettings => 'ボタン設定';

  @override
  String get cardViewShort => 'C';

  @override
  String get listViewShort => 'L';

  @override
  String get taskListDisplaySettings => 'タスクリスト表示設定';

  @override
  String get taskListFieldSettingsDescription =>
      'タスクリストとタスク編集画面で表示される各フィールドのテキスト色、フォントサイズ、フォントファミリーを個別に設定できます';

  @override
  String get resetCardViewSettings => 'カードビュー設定をリセット';

  @override
  String get resetCardViewSettingsConfirm =>
      'カードビューの設定を初期値にリセットしますか？\nこの操作は取り消せません。';

  @override
  String get textColor => 'テキスト色';

  @override
  String get requestorDescription => '依頼先への説明';

  @override
  String get assigneeDescription => '担当者への説明';

  @override
  String get allScreensCommon => '全画面共通';

  @override
  String appWideFontSize(String percentage) {
    return 'アプリ全体のフォントサイズ: $percentage%';
  }

  @override
  String get autoLayoutAdjustment => '自動レイアウト調整';

  @override
  String get autoAdjustToScreenSize => '画面サイズに応じて自動調整';

  @override
  String fieldSettings(String fieldName) {
    return '$fieldName設定';
  }

  @override
  String get colorPresetSunrise => 'サンライズ';

  @override
  String get colorPresetSunriseDesc => '温かみのあるオレンジ系';

  @override
  String get colorPresetForest => 'フォレスト';

  @override
  String get colorPresetForestDesc => '落ち着いたグリーン系';

  @override
  String get colorPresetBreeze => 'ブルーブリーズ';

  @override
  String get colorPresetBreezeDesc => '爽やかなブルー系';

  @override
  String get colorPresetMidnight => 'ミッドナイト';

  @override
  String get colorPresetMidnightDesc => '夜間作業に合うダークテイスト';

  @override
  String get colorPresetSakura => 'サクラ';

  @override
  String get colorPresetSakuraDesc => '柔らかなピンク系';

  @override
  String get colorPresetCitrus => 'シトラス';

  @override
  String get colorPresetCitrusDesc => 'フレッシュな黄緑系';

  @override
  String get colorPresetSlate => 'スレート';

  @override
  String get colorPresetSlateDesc => '落ち着いたブルーグレー';

  @override
  String get colorPresetAmber => 'アンバー';

  @override
  String get colorPresetAmberDesc => '視認性の高いゴールド調';

  @override
  String get colorPresetGraphite => 'グラファイト';

  @override
  String get colorPresetGraphiteDesc => 'モダンなモノトーン';

  @override
  String presetApplied(String presetName) {
    return '$presetNameプリセットを適用しました';
  }

  @override
  String presetApplyFailed(String error) {
    return 'プリセットの適用に失敗しました: $error';
  }

  @override
  String get autoContrastOptimization => '自動コントラスト最適化';

  @override
  String get autoContrastOptimizationDesc => 'ダークモードでテキストの視認性を自動調整';

  @override
  String get iconSize => 'アイコンサイズ';

  @override
  String get linkItemIconSizeDesc =>
      'リンクアイテムのアイコンサイズを調整します。大きくすると視認性が向上しますが、アイテム全体のサイズも大きくなります。';

  @override
  String get gridSettingsReset => 'グリッド設定';

  @override
  String get gridSettingsResetDesc => 'カラム数: 4、間隔: デフォルト';

  @override
  String get cardSettingsReset => 'カード設定';

  @override
  String get cardSettingsResetDesc => 'サイズ: デフォルト、影: デフォルト';

  @override
  String get itemSettingsReset => 'アイテム設定';

  @override
  String get itemSettingsResetDesc => 'フォントサイズ: デフォルト、アイコンサイズ: デフォルト';

  @override
  String get colorBlue => 'ブルー';

  @override
  String get colorRed => 'レッド';

  @override
  String get colorGreen => 'グリーン';

  @override
  String get colorOrange => 'オレンジ';

  @override
  String get colorPurple => 'パープル';

  @override
  String get colorPink => 'ピンク';

  @override
  String get colorCyan => 'シアン';

  @override
  String get colorGray => 'グレー';

  @override
  String get colorEmerald => 'エメラルド';

  @override
  String get colorYellow => 'イエロー';

  @override
  String get colorBlack => '黒';

  @override
  String get colorWhite => '白';

  @override
  String get light => '薄い';

  @override
  String get standard => '標準';

  @override
  String get dark => '濃い';

  @override
  String get contrastLow => '低';

  @override
  String get contrastHigh => '高';

  @override
  String get contrast => 'コントラスト';

  @override
  String get fontSize => 'フォントサイズ';

  @override
  String get fontFamily => 'フォントファミリー';

  @override
  String get defaultValue => 'デフォルト';

  @override
  String fontSizePreview(String fieldName) {
    return 'プレビュー: このテキストのサイズが$fieldNameに適用されます';
  }

  @override
  String fontFamilyPreview(String fieldName) {
    return 'フォントプレビュー: このテキストのフォントが$fieldNameに適用されます';
  }

  @override
  String get buttonSettingsDescription => 'ボタンの見た目を調整します。角丸半径と影の強さを変更できます。';

  @override
  String get borderRadius => '角丸半径';

  @override
  String borderRadiusPx(String value) {
    return '角丸半径: ${value}px';
  }

  @override
  String get elevation => '影の強さ';

  @override
  String elevationPx(String value) {
    return '影の強さ: ${value}px';
  }

  @override
  String elevationPercent(String value) {
    return '影の強さ: $value%';
  }

  @override
  String get inputFieldSettings => '入力フィールド設定';

  @override
  String get inputFieldSettingsDescription =>
      'テキスト入力欄の見た目を調整します。角丸半径と枠線の太さを変更できます。';

  @override
  String get borderWidth => '枠線の太さ';

  @override
  String borderWidthPx(String value) {
    return '枠線の太さ: ${value}px';
  }

  @override
  String get hoverEffect => 'ホバー効果';

  @override
  String hoverEffectPercent(String value) {
    return 'ホバー効果: $value%';
  }

  @override
  String get gradient => 'グラデーション';

  @override
  String gradientPercent(String value) {
    return 'グラデーション: $value%';
  }

  @override
  String get generalSettings => '全般設定';

  @override
  String get darkModeContrastBoost => 'ダークモードコントラストブースト';

  @override
  String get autoLayoutEnabled => '自動レイアウトが有効です。画面サイズに応じて最適な列数が自動で決定されます。';

  @override
  String get largeScreen => '大画面（1920px以上）';

  @override
  String columnsDisplay(String count) {
    return '$count列表示';
  }

  @override
  String get optimalForDesktop => 'デスクトップモニターに最適';

  @override
  String get mediumScreen => '中画面（1200-1919px）';

  @override
  String get optimalForLaptop => 'ノートPCやタブレットに最適';

  @override
  String get smallScreen => '小画面（800-1199px）';

  @override
  String get optimalForSmallScreen => '小さな画面に最適';

  @override
  String get minimalScreen => '最小画面（800px未満）';

  @override
  String get optimalForMobile => 'モバイル表示に最適';

  @override
  String get manualLayoutEnabled => '手動レイアウト設定が有効です。固定の列数で表示されます。';

  @override
  String get fixedColumns => '固定列数';

  @override
  String get sameColumnsAllScreens => 'すべての画面サイズで同じ列数';

  @override
  String get useCase => '使用場面';

  @override
  String get maintainSpecificDisplay => '特定の表示を維持したい場合';

  @override
  String get consistentLayoutNeeded => '一貫したレイアウトが必要な場合';

  @override
  String defaultColumnCount(String count) {
    return 'デフォルト列数: $count';
  }

  @override
  String gridSpacing(String value) {
    return 'グリッド間隔: ${value}px';
  }

  @override
  String cardWidth(String value) {
    return 'カード幅: ${value}px';
  }

  @override
  String cardHeight(String value) {
    return 'カード高さ: ${value}px';
  }

  @override
  String get itemMargin => 'アイテム間マージン';

  @override
  String itemMarginPx(String value) {
    return 'アイテム間マージン: ${value}px';
  }

  @override
  String get itemMarginDescription =>
      'リンクアイテム間の空白スペースを調整します。値を大きくすると、アイテム同士の間隔が広がり、見やすくなります。';

  @override
  String get itemPadding => 'アイテム内パディング';

  @override
  String itemPaddingPx(String value) {
    return 'アイテム内パディング: ${value}px';
  }

  @override
  String get itemPaddingDescription =>
      'リンクアイテム内の文字やアイコンと枠線の間の空白を調整します。値を大きくすると、アイテム内がゆとりを持って見やすくなります。';

  @override
  String fontSizePx(String value) {
    return 'フォントサイズ: ${value}px';
  }

  @override
  String get fontSizeDescription =>
      'リンクアイテムの文字サイズを調整します。小さくすると多くのアイテムを表示できますが、読みにくくなる場合があります。';

  @override
  String get buttonSize => 'ボタンサイズ';

  @override
  String buttonSizePx(String value) {
    return 'ボタンサイズ: ${value}px';
  }

  @override
  String get buttonSizeDescription =>
      '編集・削除などのボタンのサイズを調整します。大きくすると操作しやすくなりますが、画面のスペースを多く使用します。';

  @override
  String get autoAdjustCardHeight => 'カード高さ自動調整';

  @override
  String get autoAdjustCardHeightDescription =>
      'コンテンツ量に応じてカードの高さを自動調整（手動設定の高さを最小値として使用）';

  @override
  String get backupExport => 'データのバックアップ / エクスポート';

  @override
  String get backupLocation => '保存先: ドキュメント/backups';

  @override
  String get saveNow => '今すぐ保存';

  @override
  String get openBackupFolder => '保存先を開く';

  @override
  String get selectiveExportImport => '選択式エクスポート / インポート';

  @override
  String get selectiveExport => '選択式エクスポート';

  @override
  String get selectiveImport => '選択式インポート';

  @override
  String get autoBackup => '自動バックアップ';

  @override
  String get autoBackupDescription => '定期的にデータをバックアップ';

  @override
  String backupInterval(String days) {
    return 'バックアップ間隔: $days日';
  }

  @override
  String backupIntervalDays(String days) {
    return '$days日';
  }

  @override
  String get notificationWarning =>
      '注意: 通知はアプリが起動中の場合のみ表示されます。アプリを閉じている場合は通知が表示されません。';

  @override
  String get showNotifications => '通知を表示';

  @override
  String get showNotificationsDescription =>
      'タスクの期限やリマインダーが設定されている場合、デスクトップ通知を表示します。アプリが起動中の場合のみ通知が表示されます。';

  @override
  String get notificationSound => '通知音';

  @override
  String get notificationSoundDescription =>
      '通知が表示される際に音を再生します。アプリが起動中の場合のみ音が再生されます。';

  @override
  String get testNotificationSound => '通知音をテスト';

  @override
  String get testNotificationSoundDescription =>
      'このボタンで通知音をテストできます。アプリが起動中の場合のみ音が再生されます。';

  @override
  String get resetToDefaults => '設定をデフォルトにリセット';

  @override
  String get resetLayoutSettings => 'レイアウト設定をリセット';

  @override
  String get layoutSettingsReset => 'レイアウト設定をリセットしました';

  @override
  String get resetUISettings => 'UI設定をリセット';

  @override
  String get resetUISettingsConfirm =>
      'すべてのUIカスタマイズ設定をデフォルト値にリセットします。\n\nこの操作は取り消せません。\n本当に実行しますか？';

  @override
  String get executeReset => 'リセット実行';

  @override
  String get resetDetails => 'リセット機能の詳細';

  @override
  String get resetFunction => 'リセット機能';

  @override
  String get resetFunctionDescription =>
      '• 設定リセット: テーマ、通知、連携設定など\n• レイアウトリセット: グリッドサイズ、カード設定など\n• UI設定リセット: カード、ボタン、入力フィールドのカスタマイズ設定\n• データは保持: リンク、タスク、メモは削除されません\n• 詳細は「リセット機能の詳細」ボタンで確認';

  @override
  String get resetDetailsTitle => 'リセット機能の詳細';

  @override
  String get resetDetailsDescription => 'リセット機能の詳細説明:';

  @override
  String get resetToDefaultsStep => '設定をデフォルトにリセット';

  @override
  String get resetToDefaultsStepDescription => '以下の設定が初期値に戻ります:';

  @override
  String get themeSettingsReset => 'テーマ設定';

  @override
  String get themeSettingsResetValue =>
      'ダークモード: OFF、アクセントカラー: ブルー、濃淡: 100%、コントラスト: 100%';

  @override
  String get notificationSettingsReset => '通知設定';

  @override
  String get notificationSettingsResetValue => '通知: ON、通知音: ON';

  @override
  String get integrationSettingsReset => '連携設定';

  @override
  String get integrationSettingsResetValue =>
      'Google Calendar: OFF、Gmail連携: OFF、Outlook: OFF';

  @override
  String get backupSettingsReset => 'バックアップ設定';

  @override
  String get backupSettingsResetValue => '自動バックアップ: ON、間隔: 7日';

  @override
  String get resetLayoutSettingsStep => 'レイアウト設定をリセット';

  @override
  String get resetLayoutSettingsStepDescription => '以下のレイアウト設定が初期値に戻ります:';

  @override
  String get autoSync => '自動同期';

  @override
  String get autoSyncDescription => '定期的にGoogle Calendarと同期します';

  @override
  String syncInterval(String minutes) {
    return '同期間隔: $minutes分';
  }

  @override
  String get bidirectionalSync => '双方向同期';

  @override
  String get bidirectionalSyncDescription => 'アプリのタスクをGoogle Calendarに送信します';

  @override
  String get showCompletedTasks => '完了タスクを表示';

  @override
  String get showCompletedTasksDescription => 'Google Calendarで完了したタスクを表示します';

  @override
  String get credentialsFileFound => '認証情報ファイルが見つかりました';

  @override
  String get credentialsFileNotFound => '認証情報ファイルが見つかりません';

  @override
  String get outlookSettingsInfo => 'Outlook設定情報';

  @override
  String get autoLayoutAdjustmentDescription => '画面サイズに応じて自動調整';

  @override
  String get autoLayoutEnabledLabel => '自動レイアウト有効';

  @override
  String get manualLayoutSettings => '手動レイアウト設定';

  @override
  String get animationEffectSettings => 'アニメーション・エフェクト設定';

  @override
  String animationDuration(String ms) {
    return 'アニメーション時間: ${ms}ms';
  }

  @override
  String spacing(String value) {
    return 'スペーシング: ${value}px';
  }

  @override
  String darkModeContrastBoostPercent(String value) {
    return 'ダークモードコントラストブースト: $value%';
  }

  @override
  String get taskProjectSettingsReset => 'プロジェクト一覧設定をリセットしました';

  @override
  String get backupFolderOpened => 'バックアップフォルダを開きました';

  @override
  String get googleCalendar => 'Google Calendar';

  @override
  String get googleCalendarIntegration => 'Google Calendar連携';

  @override
  String get googleCalendarIntegrationDescription =>
      'Google Calendarのイベントをタスクとして同期します';

  @override
  String get gmailIntegrationAbout => 'Gmail連携について';

  @override
  String get gmailIntegrationDescription =>
      'タスク編集モーダルからGmailのメール作成画面を起動できます。\nAPIやアクセストークンの設定は不要です。\nGoogleアカウントにログイン済みのブラウザがあれば、そのままGmailの新規作成タブが開きます。';

  @override
  String get gmailUsage =>
      '使い方：\n1. タスク編集モーダルを開く\n2. メール送信セクションでGmailを選択\n3. 宛先を入力して「メール送信」ボタンをクリック\n4. Gmailのメール作成画面が開くので、内容を確認して送信します\n（送信履歴はタスク側に記録されます）';

  @override
  String get outlookIntegration => 'Outlook連携';

  @override
  String get outlookIntegrationAbout => 'Outlook連携について';

  @override
  String get outlookIntegrationDescription =>
      'Outlook APIを使用して、メール送信機能を利用できます。';

  @override
  String get powershellFileDetails => 'PowerShellファイルの詳細';

  @override
  String get executableDirectory => '実行ファイルと同じディレクトリ\\Apps';

  @override
  String get outlookConnectionTest => 'Outlook接続テスト';

  @override
  String get outlookConnectionTestDescription => 'Outlookアプリケーションとの接続をテストします';

  @override
  String get mailCompositionSupport => 'メール作成支援';

  @override
  String get mailCompositionSupportDescription => 'タスクから返信メールを作成する際の支援機能';

  @override
  String get sentMailSearch => '送信メール検索';

  @override
  String get sentMailSearchDescription => '送信済みメールの検索・確認機能';

  @override
  String get outlookCalendarEvents => 'Outlookカレンダー予定取得';

  @override
  String get outlookCalendarEventsDescription =>
      'Outlookカレンダーから予定を取得してタスクに割り当てる機能';

  @override
  String get portableVersion => 'ポータブル版';

  @override
  String get installedVersion => 'インストール版';

  @override
  String get manualExecution => '手動実行';

  @override
  String get automaticExecution => '自動実行';

  @override
  String get importantNotes => '重要な注意事項';

  @override
  String importantNotesContent(String portablePath) {
    return '• 管理者権限は不要（ユーザーレベルで実行可能）\n• ファイル名は正確に一致させる必要があります\n• 実行ポリシーが制限されている場合は手動で許可が必要です\n• 会社PCのセキュリティポリシーにより動作しない場合があります\n\n【配置場所】\nポータブル版に同梱されています: $portablePath';
  }

  @override
  String bundledWithPortable(String portablePath) {
    return 'ポータブル版に同梱されています: $portablePath';
  }

  @override
  String get connectionTest => '接続テスト';

  @override
  String get outlookPersonalCalendarAutoImport => 'Outlook個人予定の自動取込';

  @override
  String get outlookSettingsInfoContent =>
      '• 必要な権限: Outlook送信\n• 対応機能: メール送信、予定自動取込\n• 使用方法: タスク管理からOutlookでメールを送信、または自動取込設定を有効化';

  @override
  String get googleCalendarSetupGuide => 'Google Calendar設定ガイド';

  @override
  String get googleCalendarSetupSteps => 'Google Calendar APIを使用するための設定手順:';

  @override
  String get accessGoogleCloudConsole => 'Google Cloud Consoleにアクセス';

  @override
  String get createOrSelectProject => '新しいプロジェクトを作成または既存プロジェクトを選択';

  @override
  String get enableGoogleCalendarAPI => 'Google Calendar APIを有効化';

  @override
  String get enableGoogleCalendarAPIDescription =>
      '「APIとサービス」→「ライブラリ」→「Google Calendar API」を検索して有効化';

  @override
  String get createOAuth2ClientID => 'OAuth2クライアントIDを作成';

  @override
  String get createOAuth2ClientIDDescription =>
      '「APIとサービス」→「認証情報」→「認証情報を作成」→「OAuth2クライアントID」→「デスクトップアプリケーション」';

  @override
  String get downloadCredentialsFile => '認証情報ファイルをダウンロード';

  @override
  String get downloadCredentialsFileDescription =>
      '作成したOAuth2クライアントIDの「ダウンロード」ボタンからJSONファイルをダウンロード';

  @override
  String get placeFileInAppFolder => 'ファイルをアプリフォルダに配置';

  @override
  String get placeFileInAppFolderDescription =>
      'ダウンロードしたJSONファイルを「google_calendar_credentials.json」としてアプリフォルダに配置';

  @override
  String get executeOAuth2Authentication => 'OAuth2認証を実行';

  @override
  String get executeOAuth2AuthenticationDescription =>
      'アプリの「OAuth2認証を開始」ボタンをクリックして認証を完了';

  @override
  String get generatedFiles => '生成されるファイル';

  @override
  String get exportOptions => 'エクスポートオプション';

  @override
  String get selectDataToExport => 'エクスポートするデータを選択してください:';

  @override
  String get linksOnly => 'リンクのみ';

  @override
  String get linksOnlyDescription => 'リンクデータのみをエクスポート';

  @override
  String get tasksOnly => 'タスクのみ';

  @override
  String get tasksOnlyDescription => 'タスクデータのみをエクスポート';

  @override
  String get both => '両方';

  @override
  String get bothDescription => 'リンクとタスクの両方をエクスポート';

  @override
  String get importOptions => 'インポートオプション';

  @override
  String get selectDataToImport => 'インポートするデータを選択してください:';

  @override
  String get linksOnlyImportDescription => 'リンクデータのみをインポート';

  @override
  String get tasksOnlyImportDescription => 'タスクデータのみをインポート';

  @override
  String get bothImportDescription => 'リンクとタスクの両方をインポート';

  @override
  String exportCompleted(String filePath) {
    return 'エクスポートが完了しました\n保存先: $filePath';
  }

  @override
  String get exportCompletedTitle => 'エクスポート完了';

  @override
  String get exportError => 'エクスポートエラー';

  @override
  String exportErrorMessage(String error) {
    return 'エクスポートエラー: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'フォルダを開けませんでした: $error';
  }

  @override
  String get ok => 'OK';

  @override
  String get selectFileToImport => 'インポートするファイルを選択';

  @override
  String importCompleted(int linksCount, int tasksCount, int groupsCount) {
    return 'インポートが完了しました\nリンク: $linksCount件\nタスク: $tasksCount件\nグループ: $groupsCount件';
  }

  @override
  String get importCompletedTitle => 'インポート完了';

  @override
  String get importError => 'インポートエラー';

  @override
  String importErrorMessage(String error) {
    return 'インポートエラー: $error';
  }

  @override
  String get oauth2AuthCompleted => 'OAuth2認証が完了しました';

  @override
  String get thisFileContains => 'このファイルには以下の情報が含まれます：';

  @override
  String get syncStatus => '同期状態';

  @override
  String get waiting => '待機中';

  @override
  String get syncing => '同期中...';

  @override
  String get syncCompleted => '同期が完了しました';

  @override
  String get syncError => '同期エラー';

  @override
  String lastSync(String time) {
    return '最終同期: $time';
  }

  @override
  String nextSync(String time) {
    return '次回同期予定: $time';
  }

  @override
  String get autoSyncEnabled => '自動同期が有効です';

  @override
  String get autoSyncDisabled => '自動同期が無効です';

  @override
  String tokenExpiry(String time) {
    return 'アクセストークン有効期限: $time';
  }

  @override
  String get tokenValid => '認証トークンは有効です';

  @override
  String get tokenExpired => '認証トークンが期限切れです';

  @override
  String get refreshTokenAvailable => 'リフレッシュトークンが利用可能です';

  @override
  String processingItems(int processed, int total) {
    return '$processed/$total件処理中...';
  }

  @override
  String error(String message) {
    return 'エラー: $message';
  }

  @override
  String errorCode(String code) {
    return 'エラーコード: $code';
  }

  @override
  String get partialSync => '部分同期';

  @override
  String get partialSyncDescription => '選択したタスクや日付範囲のタスクのみを同期できます';

  @override
  String get individualTaskSyncInfo =>
      '個別タスクの同期は、タスク画面の各タスクの3点ドットメニューから「このタスクを同期」を選択してください。';

  @override
  String get syncByDateRange => '日付範囲で同期';

  @override
  String get cleanupDuplicateEvents => '重複イベントをクリーンアップ';

  @override
  String get deleteOrphanedEvents => '孤立イベントを削除';

  @override
  String get orphanedEventsDeletion => '孤立イベント削除';

  @override
  String get orphanedEventsDeletionDescription =>
      'Google Calendarに残っているが、アプリに存在しないタスクのイベントを削除します。\nアプリで削除されたタスクのイベントがGoogle Calendarに残っている場合に使用してください。\n\nこの操作は取り消せません。実行しますか？';

  @override
  String get executeDeletion => '削除実行';

  @override
  String get detectingOrphanedEvents => '孤立イベントを検出中...';

  @override
  String orphanedEventsDeletionCompleted(int count) {
    return '孤立イベント削除完了: $count件削除';
  }

  @override
  String orphanedEventsDeleted(int count) {
    return '孤立イベント$count件を削除しました';
  }

  @override
  String get noOrphanedEventsFound => '孤立イベントは見つかりませんでした';

  @override
  String get orphanedEventsDeletionFailed => '孤立イベント削除に失敗しました';

  @override
  String get orphanedEventsDeletionError => '孤立イベント削除中にエラーが発生しました';

  @override
  String get duplicateEventsCleanup => '重複イベントクリーンアップ';

  @override
  String get duplicateEventsCleanupDescription =>
      'Google Calendarの重複したイベントを検出・削除します。\n同じタイトルと日付のイベントが複数ある場合、古いものを削除します。\n\nこの操作は取り消せません。実行しますか？';

  @override
  String get executeCleanup => 'クリーンアップ実行';

  @override
  String get detectingDuplicateEvents => '重複イベントを検出中...';

  @override
  String duplicateCleanupCompleted(int found, int removed) {
    return '重複クリーンアップ完了: $foundグループ検出、$removed件削除';
  }

  @override
  String duplicateEventsDeleted(int count) {
    return '重複イベント$count件を削除しました';
  }

  @override
  String get noDuplicateEventsFound => '重複イベントは見つかりませんでした';

  @override
  String get duplicateCleanupFailed => '重複クリーンアップに失敗しました';

  @override
  String get duplicateCleanupError => '重複クリーンアップ中にエラーが発生しました';

  @override
  String get checkSetupMethod => '設定方法を確認';

  @override
  String get authStartFailed => '認証の開始に失敗しました';

  @override
  String get storageLocation => '格納場所';

  @override
  String get executionMethod => '実行方法';

  @override
  String get startOAuth2Authentication => 'OAuth2認証を開始';

  @override
  String get appToGoogleCalendarSync => 'アプリ→Google Calendar同期';

  @override
  String appToGoogleCalendarSyncCompleted(
    int created,
    int updated,
    int deleted,
  ) {
    return 'アプリ→Google Calendar同期完了: 作成$created件, 更新$updated件, 削除$deleted件';
  }

  @override
  String get googleCalendarToAppSync => 'Google Calendar→アプリ同期';

  @override
  String googleCalendarToAppSyncCompleted(int added, int skipped) {
    return 'Google Calendar→アプリ同期完了: 追加$added件, スキップ$skipped件';
  }

  @override
  String syncErrorMessage(String error) {
    return '同期エラー: $error';
  }

  @override
  String errorColon(String error) {
    return 'エラー: $error';
  }

  @override
  String screenshotLoadFailed(String path) {
    return 'スクリーンショットを読み込めませんでした。\nassets/help フォルダに画像を配置してください。\n($path)';
  }

  @override
  String get bulkLinkAssignment => 'リンクを一括割り当て';

  @override
  String get addDescription => '既存のリンクに追加します';

  @override
  String get remove => '削除';

  @override
  String get removeDescription => '指定したリンクを削除します';

  @override
  String get replace => '置換';

  @override
  String get replaceDescription => '既存のリンクを全て置き換えます';

  @override
  String get noLinksAvailable => '利用可能なリンクがありません';

  @override
  String tasksMerged(int count) {
    return '$count件のタスクを結合しました';
  }

  @override
  String get mergeTask => 'タスクを結合';

  @override
  String get selectTargetTask => '結合先のタスクを選択してください：';

  @override
  String get mergeTaskConfirm => 'タスクを結合';

  @override
  String get mergeTaskConfirmDescription =>
      '結合元タスクの予定、サブタスク、メモ、リンク、タグが統合されます。\n結合元タスクは完了状態になります。';

  @override
  String mergeTaskConfirmMessage(String title, int count, String description) {
    return '「$title」に$count件のタスクを結合しますか？\n\n$description';
  }

  @override
  String get dropToAdd => 'ここにドロップして追加';

  @override
  String get noLinksDragToAdd => 'リンクなし\nここにドラッグで追加';

  @override
  String get noLinksYet => 'リンクがありません';

  @override
  String get merge => 'マージ';

  @override
  String get apply => '適用';

  @override
  String get dueDateBulkChange => '期限日を一括変更';

  @override
  String get notSelected => '未選択';

  @override
  String get bulkTagOperation => 'タグを一括操作';

  @override
  String get addTagDescription => '既存のタグに追加します';

  @override
  String get removeTagDescription => '指定したタグを削除します';

  @override
  String get someFilesNotRegistered => '一部のファイル/フォルダは登録されませんでした';

  @override
  String get folderIsEmpty => 'フォルダが空です';

  @override
  String get accessDeniedOrOtherError => 'アクセス権限がないか、その他のエラーが発生しました';

  @override
  String get doesNotExist => '存在しません';

  @override
  String get editMemo => 'メモを編集';

  @override
  String get enterMemo => 'メモを入力...';

  @override
  String get emptyMemoDeletes => '空の場合はメモを削除します';

  @override
  String currentMemo(String memo) {
    return '現在のメモ: $memo';
  }

  @override
  String get contentList => 'コンテンツ一覧';

  @override
  String get clickChapterToJump => '気になる章をクリックしてジャンプ！';

  @override
  String get searchByKeyword => 'キーワードで検索';

  @override
  String manualLoadFailed(String error) {
    return 'マニュアルの読み込みに失敗しました: $error';
  }

  @override
  String screenshotNotRegistered(String id) {
    return 'スクリーンショット「$id」は登録されていません。';
  }

  @override
  String videoNotRegistered(String id) {
    return '動画「$id」は登録されていません。assets/help/videos フォルダを確認してください。';
  }

  @override
  String get manualNotLoaded => 'マニュアルが読み込まれていません';

  @override
  String get reload => '再読み込み';

  @override
  String get retry => '再試行';

  @override
  String get unknownError => '未知のエラー';

  @override
  String get helpContentNotFound => 'ヘルプコンテンツが見つかりませんでした。';

  @override
  String get linkNavigatorManual => 'Link Navigator 取扱説明書';

  @override
  String get helpCenterGuide => 'アプリをすぐに使いこなすためのガイドです。気になる項目を左のナビから選択してください。';

  @override
  String get htmlExport => 'HTML出力・印刷';

  @override
  String htmlExportFailed(String error) {
    return 'HTML出力に失敗しました: $error';
  }

  @override
  String filesAdded(int count) {
    return 'ファイルを$count個追加しました';
  }

  @override
  String foldersAdded(int count) {
    return 'フォルダを$count個追加しました';
  }

  @override
  String linksAdded(int count) {
    return 'リンクを$count個追加しました';
  }

  @override
  String itemsAdded(String files, String folders, String links) {
    return '$files、$folders、$links';
  }

  @override
  String get label => 'ラベル';

  @override
  String get linkLabelHint => 'リンクラベルを入力...';

  @override
  String get pathUrl => 'パス/URL';

  @override
  String get pathUrlHint => 'ファイルパスまたはURLを入力...';

  @override
  String get tagsHint => 'カンマ区切りで入力（例: 仕事, 重要, プロジェクトA）';

  @override
  String get faviconUrlHint => '例: https://www.resonabank.co.jp/';

  @override
  String get icon => 'アイコン: ';

  @override
  String get noNameSet => '名称未設定';

  @override
  String get get => '取得';

  @override
  String get getSchedulesConfirm => 'スケジュールを取得しますか？';

  @override
  String schedulesRetrieved(int total, int added, int skipped) {
    return '取得: $total件\n追加: $added件\nスキップ: $skipped件';
  }

  @override
  String schedulesRetrievedNoAdd(int total, int skipped) {
    return '取得: $total件\n追加: 0件\nスキップ: $skipped件（既に取り込まれています）';
  }

  @override
  String schedulesRetrievedNoSchedule(int total) {
    return '取得: $total件\n取り込む予定はありませんでした';
  }

  @override
  String get outlookScheduleRetrieval => 'Outlookスケジュール取得';

  @override
  String get faviconFallbackDomain => 'Faviconフォールバックドメイン';

  @override
  String get faviconFallbackHelper => 'favicon取得失敗時に使用するドメインを設定';

  @override
  String get outlookAutoImportCompleted => 'Outlook自動取り込み完了';

  @override
  String uiDensity(String percent) {
    return 'UI密度: $percent%';
  }

  @override
  String get changePriorityMenu => '優先度変更';

  @override
  String get changeDueDateMenu => '期限日変更';

  @override
  String get manageTagsMenu => 'タグを操作';

  @override
  String get assignLinkMenu => 'リンクを割り当て';

  @override
  String get combineTasksMenu => 'タスクを結合';

  @override
  String get dragAndDrop => 'ドラッグ＆ドロップ';

  @override
  String get googleIntegration => 'Google連携';

  @override
  String get notificationsAlerts => '通知・アラート';

  @override
  String get colorTheme => 'カラーテーマ';

  @override
  String get shortcuts => 'ショートカット';

  @override
  String get selectColumnsToExport => 'CSV出力する列を選択';

  @override
  String get groupByDueDate => '期限日でグループ化';

  @override
  String get groupByTag => 'タグでグループ化';

  @override
  String get groupByProjectLink => 'プロジェクト（リンク）でグループ化';

  @override
  String get groupByPriority => '優先度でグループ化';

  @override
  String get assignee => '担当者';

  @override
  String get returnToLinkManagementScreen => 'リンク管理画面に戻る';

  @override
  String get templateDeleteConfirm => 'テンプレートを削除';

  @override
  String templateDeleteMessage(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get templateNameRequired => 'テンプレート名を入力してください';

  @override
  String get titleRequired => 'タイトルを入力してください';

  @override
  String get templateSaved => 'テンプレートを保存しました';

  @override
  String get csvColumnId => 'ID';

  @override
  String get csvColumnTitle => 'タイトル';

  @override
  String get csvColumnDescription => '説明';

  @override
  String get csvColumnDueDate => '期限';

  @override
  String get csvColumnReminderTime => 'リマインダー時刻';

  @override
  String get csvColumnPriority => '優先度';

  @override
  String get csvColumnStatus => 'ステータス';

  @override
  String get csvColumnTags => 'タグ';

  @override
  String get csvColumnRelatedLinkId => '関連リンクID';

  @override
  String get csvColumnCreatedAt => '作成日';

  @override
  String get csvColumnCompletedAt => '完了日';

  @override
  String get csvColumnStartedAt => '着手日';

  @override
  String get csvColumnCompletedAtManual => '完了日（手動入力）';

  @override
  String get csvColumnEstimatedMinutes => '推定時間(分)';

  @override
  String get csvColumnNotes => 'メモ';

  @override
  String get csvColumnIsRecurring => '繰り返しタスク';

  @override
  String get csvColumnRecurringPattern => '繰り返しパターン';

  @override
  String get csvColumnIsRecurringReminder => '繰り返しリマインダー';

  @override
  String get csvColumnRecurringReminderPattern => '繰り返しリマインダーパターン';

  @override
  String get csvColumnNextReminderTime => '次のリマインダー時刻';

  @override
  String get csvColumnReminderCount => 'リマインダー回数';

  @override
  String get csvColumnHasSubTasks => 'サブタスク有無';

  @override
  String get csvColumnCompletedSubTasksCount => '完了サブタスク数';

  @override
  String get csvColumnTotalSubTasksCount => '総サブタスク数';

  @override
  String get mailSending => 'メール送信';

  @override
  String get copyRequestorMemoToBody => '本文に「依頼先やメモ」をコピー';

  @override
  String get includeSubtasksInBody => '本文にサブタスクを含める';

  @override
  String get sendingApp => '送信アプリ:';

  @override
  String get recipientSelection => '送信先選択';

  @override
  String get addContact => '連絡先を追加';

  @override
  String get selectFromSendHistory => '送信履歴から選択';

  @override
  String get frequentlyUsedContacts => 'よく使われる連絡先:';

  @override
  String get emptyMailerCanLaunch => '空でもメーラーが起動します';

  @override
  String get emptyCanSpecifyAddress => '※空の場合はメーラーで直接アドレスを指定できます';

  @override
  String get mailerLaunchInstruction => '※まず「メーラーを起動」ボタンでメーラーを開いてください';

  @override
  String get mailerSendInstruction => '※メーラーでメールを送信した後、「メール送信完了」ボタンを押してください';

  @override
  String get taskRelatedMail => 'タスク関連メール';

  @override
  String mailComposeOpened(String app) {
    return '$appのメール作成画面を開きました。\nメールを送信した後、「メール送信完了」ボタンを押してください。';
  }

  @override
  String mailerLaunchError(String error) {
    return 'メーラー起動エラー: $error';
  }

  @override
  String get pleaseLaunchMailerFirst => '先に「メーラーを起動」ボタンを押してください';

  @override
  String get mailSentRecorded => 'メール送信完了を記録しました';

  @override
  String mailSentRecordError(String error) {
    return 'メール送信完了記録エラー: $error';
  }

  @override
  String get outlookConnectionTestSuccess => 'Outlook接続テスト成功';

  @override
  String get outlookConnectionTestFailed => 'Outlook接続テスト失敗: Outlookが利用できません';

  @override
  String outlookConnectionTestError(String error) {
    return 'Outlook接続テストエラー: $error';
  }

  @override
  String powershellScriptNotFound(String scriptName, String portablePath) {
    return 'PowerShellスクリプトが見つかりません: $scriptName\n\n以下の場所に配置してください:\n$portablePath';
  }

  @override
  String get name => '名前';

  @override
  String get nameRequired => '名前を入力してください';

  @override
  String get gmailLaunchFailed => 'Gmailを起動できませんでした';

  @override
  String outlookNotInstalled(String details) {
    return 'Outlookがインストールされていないか、正しく設定されていません。\n会社PCでOutlookを使用してください。\n詳細: $details';
  }

  @override
  String outlookLaunchFailed(String error) {
    return 'Outlook起動に失敗しました: $error';
  }

  @override
  String outlookSearchFailed(String error) {
    return 'Outlook検索に失敗しました: $error';
  }

  @override
  String unsupportedMailApp(String app) {
    return 'サポートされていないメールアプリ: $app';
  }

  @override
  String powershellTimeout(int seconds) {
    return 'PowerShell実行がタイムアウトしました（$seconds秒）';
  }

  @override
  String powershellScriptError(String error) {
    return 'PowerShellスクリプト実行エラー: $error';
  }

  @override
  String powershellExecutionFailed(int retries) {
    return 'PowerShell実行が失敗しました（全$retries回の試行）';
  }

  @override
  String get unexpectedJsonFormat => '予期しないJSON形式です';

  @override
  String startDateParseError(String date) {
    return '開始日時のパースエラー: $date';
  }

  @override
  String get oauth2CredentialsNotFound =>
      'OAuth2認証情報ファイルが見つかりません。設定方法を確認してください。';

  @override
  String get invalidCredentialsFormat =>
      '認証情報ファイルの形式が正しくありません。OAuth2デスクトップアプリ用の認証情報を使用してください。';

  @override
  String get clientIdNotSet => '認証情報ファイルに client_id が設定されていません。';

  @override
  String get authUrlOpenFailed => '認証URLを開けませんでした';

  @override
  String get noValidAccessToken => '有効なアクセストークンがありません。OAuth2認証を実行してください。';

  @override
  String get googleCalendarNotAuthenticated =>
      'Google Calendarが認証されていません。設定画面でOAuth2認証を実行してください。';

  @override
  String get googleCalendarMemo => 'メモ';

  @override
  String get googleCalendarTags => 'タグ';

  @override
  String get googleCalendarEstimatedTime => '推定時間';

  @override
  String get googleCalendarSubtaskProgress => 'サブタスク進捗';

  @override
  String get googleCalendarSubtaskDetails => 'サブタスク詳細';

  @override
  String get googleCalendarPriority => '優先度';

  @override
  String get googleCalendarStatus => 'ステータス';

  @override
  String get googleCalendarCreatedDate => '作成日';

  @override
  String get googleCalendarCompleted => '完了';

  @override
  String get googleCalendarHours => '時間';

  @override
  String get googleCalendarMinutes => '分';

  @override
  String googleCalendarEventFetchFailed(int statusCode) {
    return 'Google Calendar イベント取得に失敗しました: $statusCode';
  }

  @override
  String eventDeleteFailed(int statusCode) {
    return 'イベント削除に失敗しました: $statusCode';
  }

  @override
  String get backupValidationFailed => 'バックアップファイルの検証に失敗しました';

  @override
  String backupBeforeOperationFailed(String error) {
    return '操作前のバックアップに失敗しました: $error';
  }

  @override
  String get invalidBackupDataFormat => 'バックアップデータの形式が正しくありません';

  @override
  String get invalidBackupFile => '無効なバックアップファイルです';

  @override
  String emailAlreadyRegistered(String email) {
    return 'このメールアドレスは既に登録されています: $email';
  }

  @override
  String contactNotFound(String id) {
    return '連絡先が見つかりません: $id';
  }

  @override
  String outlookEventFetchFailed(String error) {
    return 'Outlookから予定を取得できませんでした。後でもう一度お試しください。\nエラー: $error';
  }

  @override
  String get outlookEventFetchFailedInfo =>
      'Outlookから予定を取得できませんでした。後でもう一度お試しください。';

  @override
  String get tokenExtractionFailed => 'トークンの抽出に失敗しました';

  @override
  String get taskNotSelected => 'タスクが選択されていません';

  @override
  String get noSendHistoryForTask => 'このタスクの送信履歴はありません';

  @override
  String get sendHistoryReused => '送信履歴を再利用しました';

  @override
  String get gmailConnectionTest => 'Gmail接続テスト';

  @override
  String get gmailConnectionTestBody => 'これはGmail接続テストです。';

  @override
  String get gmailConnectionTestSuccess => 'Gmail接続テスト成功: Gmailが開きました';

  @override
  String gmailConnectionTestError(String error) {
    return 'Gmail接続テストエラー: $error';
  }

  @override
  String get testMailSent => 'テストメール送信完了';

  @override
  String testMailSendError(String error) {
    return 'テストメール送信エラー: $error';
  }

  @override
  String get noSendHistory => '送信履歴がありません';

  @override
  String get sendHistoryAutoRegister => 'メールを送信すると、宛先が自動で連絡先に登録されます';

  @override
  String get latestMail => '🆕 最新のメール';

  @override
  String get oldestMail => '⭐ 最初のメール';

  @override
  String get sentColon => '送信:';

  @override
  String get subjectColon => '件名:';

  @override
  String get toColon => 'To:';

  @override
  String get bodyColon => '本文:';

  @override
  String get taskLabel => 'タスク:';

  @override
  String get relatedTaskInfo => '【関連タスク情報】';

  @override
  String get mailInfo => '【メール情報】';

  @override
  String get sentDateTime => '送信日時';

  @override
  String get sentId => '送信ID:';

  @override
  String get noMessage => 'メッセージがありません。';

  @override
  String get noTaskInfo => 'タスク情報がありません。';

  @override
  String get linksLabel => 'リンク:';

  @override
  String get relatedMaterials => '【関連資料】';

  @override
  String get subtaskProgress => 'サブタスク進捗:';

  @override
  String get completedLabel => '完了:';

  @override
  String get thisMailSentFromApp => 'このメールは Link Navigator アプリから送信されました。';

  @override
  String get taskInfoHeader => '📋 タスク情報';

  @override
  String get relatedMaterialsLabel => '関連資料:';

  @override
  String get gmailLinkNote =>
      '📝 注意: ネットワーク共有やローカルファイルのリンクは、Gmailでは直接クリックできません。\nリンクをコピーして、ファイルエクスプローラーやブラウザのアドレスバーに貼り付けてアクセスしてください。';

  @override
  String get outlookLinkNote =>
      '📝 注意: Outlookでは、ネットワーク共有やローカルファイルのリンクもクリック可能です。\nリンクをクリックして直接アクセスできます。';

  @override
  String get periodLabel => '期間:';

  @override
  String get startLabel => '開始:';

  @override
  String get endLabel => '終了:';

  @override
  String get getSchedules => '予定を取得';

  @override
  String get searchSchedules => '予定を検索...';

  @override
  String get sortByTitle => 'タイトル順';

  @override
  String get sortByDateTime => '日時順';

  @override
  String get processing => '処理中...';

  @override
  String assignToTasks(int count) {
    return 'タスクに割り当て ($count件)';
  }

  @override
  String linkOpened(String label) {
    return 'リンク「$label」を開きました';
  }

  @override
  String get linkNotFound => 'リンクが見つかりません';

  @override
  String get completionDateColon => '完了日:';

  @override
  String get completedColon => '完了:';

  @override
  String get copyToExcelOneCellForm => 'エクセルにコピー（1セル形式）';

  @override
  String get excelCopyOnlyInListView => 'エクセルコピーはリスト表示時のみ利用できます。';

  @override
  String schedulesCopiedToExcel(int count, String format) {
    return '$count件の予定を$formatでクリップボードにコピーしました（エクセルに貼り付け可能）';
  }

  @override
  String schedulesCopiedToExcelOneCell(int count) {
    return '$count件の予定を1セル形式でクリップボードにコピーしました（エクセルに貼り付け可能）';
  }

  @override
  String get oneCellForm => '1セル形式';

  @override
  String get tableForm => '表形式';

  @override
  String get importOutlookSchedules => 'Outlook予定を取り込む';

  @override
  String get noSchedulesToImport => '取り込む必要がある予定はありません';

  @override
  String get meeting => '会議';

  @override
  String get recurring => '定期';

  @override
  String get online => 'オンライン';

  @override
  String get noMatchingTasks => '条件に合致するタスクがありません';

  @override
  String get outlookUnavailableSkipped => 'Outlookが利用できないため、自動取り込みをスキップしました';

  @override
  String outlookAutoImportCompletedDetails(int total, int added, int skipped) {
    return 'Outlook自動取り込み完了\n取得: $total件\n追加: $added件\nスキップ: $skipped件';
  }

  @override
  String outlookAutoImportCompletedNoNew(int total) {
    return 'Outlook自動取り込み完了\n取得: $total件\n取り込む予定はありませんでした';
  }

  @override
  String outlookAutoImportCompletedSkipped(int total, int skipped) {
    return 'Outlook自動取り込み完了\n取得: $total件\n追加: 0件\nスキップ: $skipped件（既に取り込まれています）';
  }

  @override
  String outlookAutoImportCompletedAdded(int added) {
    return 'Outlook自動取り込み完了: $added件の予定を追加しました';
  }

  @override
  String outlookAutoImportCompletedSkippedOnly(int skipped) {
    return 'Outlook自動取り込み完了: $skipped件の予定は既に取り込まれています';
  }

  @override
  String outlookAutoImportError(String error) {
    return 'Outlook自動取り込み中にエラーが発生しました。\nエラー: $error';
  }

  @override
  String get selectDateToCopy => 'コピーする日付を選択してください';

  @override
  String get taskNotFound => 'タスクが見つかりません';

  @override
  String get relatedTaskNotFound => '関連タスクが見つかりませんでした';

  @override
  String get excelHeaderDate => '日付';

  @override
  String get excelHeaderStartTime => '開始時刻';

  @override
  String get excelHeaderEndTime => '終了時刻';

  @override
  String get excelHeaderTitle => 'タイトル';

  @override
  String get excelHeaderLocation => '場所';

  @override
  String get excelHeaderTaskName => 'タスク名';

  @override
  String get gettingSchedulesFromOutlook => 'Outlookから予定を取得中...';

  @override
  String get gettingSchedules => '予定を取得中...';

  @override
  String get outlookNotRunningOrUnavailable =>
      'Outlookが起動していないか、利用できません。Outlookを起動してから再度お試しください。';

  @override
  String get noSchedulesThisMonth => 'この月には予定がありません';

  @override
  String get scheduleShortcuts => '予定表ショートカット';

  @override
  String get focusSearchBar => '検索バーにフォーカス';

  @override
  String get selectIconAndColor => 'アイコンと色を選択';

  @override
  String get selectColor => '色を選択:';

  @override
  String get preview => 'プレビュー:';

  @override
  String get decide => '決定';

  @override
  String otherSubTasks(int count) {
    return '他$count個';
  }

  @override
  String get iconGlobe => '地球アイコン';

  @override
  String get iconFolder => 'フォルダ';

  @override
  String get iconFolderOpen => '開いたフォルダ';

  @override
  String get iconFolderSpecial => '特別なフォルダ';

  @override
  String get iconFolderShared => '共有フォルダ';

  @override
  String get iconFolderZip => '圧縮フォルダ';

  @override
  String get iconFolderCopy => 'コピーフォルダ';

  @override
  String get iconFolderDelete => '削除フォルダ';

  @override
  String get iconFolderOff => '無効フォルダ';

  @override
  String get iconFolderOutlined => 'フォルダ（アウトライン）';

  @override
  String get iconFolderOpenOutlined => '開いたフォルダ（アウトライン）';

  @override
  String get iconFolderSpecialOutlined => '特別なフォルダ（アウトライン）';

  @override
  String get iconFolderSharedOutlined => '共有フォルダ（アウトライン）';

  @override
  String get iconFolderZipOutlined => '圧縮フォルダ（アウトライン）';

  @override
  String get iconFolderCopyOutlined => 'コピーフォルダ（アウトライン）';

  @override
  String get iconFolderDeleteOutlined => '削除フォルダ（アウトライン）';

  @override
  String get iconFolderOffOutlined => '無効フォルダ（アウトライン）';

  @override
  String get iconFolderUpload => 'アップロードフォルダ';

  @override
  String get iconFolderUploadOutlined => 'アップロードフォルダ（アウトライン）';

  @override
  String get iconFileMove => 'ファイル移動';

  @override
  String get iconFileMoveOutlined => 'ファイル移動（アウトライン）';

  @override
  String get iconFileRename => 'ファイル名変更';

  @override
  String get iconFileRenameOutlined => 'ファイル名変更（アウトライン）';

  @override
  String associateLinksWithTask(String title) {
    return 'タスク「$title」にリンクを関連付け';
  }

  @override
  String existingRelatedLinks(int count) {
    return '既存の関連リンク（$count個）';
  }

  @override
  String get clickToExpandAndDelete => 'クリックして展開・削除';

  @override
  String get selectLinkToAssociate => '関連付けたいリンクを選択してください：';

  @override
  String get searchLinks => 'リンクを検索...';

  @override
  String selectedLinks(int selected, int existing) {
    return '選択されたリンク: $selected個（既存: $existing個）';
  }

  @override
  String linkedLinksNotFound(int count) {
    return '関連付けられたリンクが見つかりません（$count個のリンクIDが存在）';
  }

  @override
  String get linkDeleted => 'リンクを削除しました';

  @override
  String linkDeletionFailed(String error) {
    return 'リンクの削除に失敗しました: $error';
  }

  @override
  String itemsCount(int count) {
    return '$count件';
  }

  @override
  String linkList(int count) {
    return 'リンク一覧: $count個';
  }

  @override
  String get linkAssociationUpdated => 'リンクの関連付けを更新しました';

  @override
  String linkAssociationUpdateFailed(String error) {
    return 'リンクの関連付け更新に失敗しました: $error';
  }

  @override
  String get orphanedSchedules => '孤立予定';

  @override
  String get orphanedSchedulesDescription => '存在しないタスクに紐づいていた予定をまとめるためのタスクです。';

  @override
  String get systemGenerated => 'システム生成';

  @override
  String itemsCountShort(int count) {
    return '$count件';
  }

  @override
  String schedulesAssigned(int count) {
    return '$count件の予定を割り当てました';
  }

  @override
  String tasksCreatedAndSchedulesAssigned(int count) {
    return '$count件のタスクを作成し、予定を割り当てました';
  }

  @override
  String itemsDisplayed(int count) {
    return '$count件表示';
  }

  @override
  String candidateTasksFound(int count) {
    return '$count件の候補タスクが見つかりました';
  }

  @override
  String get changeAssignedTask => '割当タスクを変更';

  @override
  String get noAssignableTasks => '割り当て可能なタスクがありません';

  @override
  String get noOtherTasks => '他のタスクがありません';

  @override
  String scheduleAssignedToTask(String scheduleTitle, String taskTitle) {
    return '「$scheduleTitle」を「$taskTitle」に割り当てました';
  }

  @override
  String scheduleTaskAssignmentChangeError(String error) {
    return 'タスク割り当て変更エラー: $error';
  }

  @override
  String get scheduleTaskAssignmentChangeFailed => '予定のタスク割り当て変更に失敗しました。';

  @override
  String get edit => '編集';

  @override
  String get scheduleCopiedAndAdded => '予定をコピーして追加しました';

  @override
  String get dragOrderManual => 'ドラッグ順（手動）';

  @override
  String get memoPad => 'メモ帳';

  @override
  String get newMemo => '新しいメモ';

  @override
  String get deleteMemo => 'メモを削除';

  @override
  String get deleteMemoConfirm => 'このメモを削除しますか？';

  @override
  String get memoContentHint => 'メモの内容を入力してください...';

  @override
  String get searchMemos => 'メモを検索...';

  @override
  String get noMemos => 'メモがありません';

  @override
  String get noMemosFound => '該当するメモが見つかりません';

  @override
  String get memoAdded => 'メモを追加しました';

  @override
  String get memoUpdated => 'メモを更新しました';

  @override
  String get memoDeleted => 'メモを削除しました';

  @override
  String memoSaveError(String error) {
    return 'メモの保存に失敗しました: $error';
  }

  @override
  String memoDeleteError(String error) {
    return 'メモの削除に失敗しました: $error';
  }

  @override
  String get memoAddFailed => 'メモの追加に失敗しました';

  @override
  String get memoUpdateFailed => 'メモの更新に失敗しました';

  @override
  String get memoDeleteFailed => 'メモの削除に失敗しました';

  @override
  String get noTasks => 'タスクがありません';

  @override
  String get clickToEditAndDragToReorder => 'クリックで編集\nドラッグアイコンで順序変更';

  @override
  String get reminderDate => 'リマインダー日';

  @override
  String get reminderTime => 'リマインダー時刻';

  @override
  String get selectReminderDate => 'リマインダー日を選択';

  @override
  String get selectTime => '時間を選択';

  @override
  String get exportLinksToExcel => 'リンクをエクセル出力';

  @override
  String get exportLinksToExcelShortcut => 'リンクをエクセル出力';

  @override
  String get selectGroupsToExport => 'エクスポートするグループを選択';

  @override
  String linksExported(String filePath) {
    return 'リンクをエクセル形式でエクスポートしました: $filePath';
  }

  @override
  String linksExportFailed(String error) {
    return 'リンクのエクスポートに失敗しました: $error';
  }

  @override
  String get excelHyperlinkActivationTitle => 'ハイパーリンクを有効化する方法';

  @override
  String get excelHyperlinkActivationDescription =>
      'エクスポートしたExcelファイルで、ハイパーリンクが文字列として表示されている場合、以下の手順で一括して有効化できます：';

  @override
  String get excelHyperlinkActivationStep1 => 'リンク列（C列）を選択します';

  @override
  String get excelHyperlinkActivationStep2 =>
      'Ctrl + H キーを押して「検索と置換」ダイアログを開きます';

  @override
  String get excelHyperlinkActivationStep3 => '検索する文字列に「=HYPERLINK」と入力します';

  @override
  String get excelHyperlinkActivationStep4 =>
      '置換後の文字列にも「=HYPERLINK」と入力し、「すべて置換」をクリックします';

  @override
  String get excelHyperlinkActivationNote =>
      'これにより、Excelが数式を再評価し、ハイパーリンクが有効になります。また、Excelファイルの「ハイパーリンク有効化方法」シートにも手順が記載されています。';

  @override
  String get excelLinksSheetName => 'リンク一覧';

  @override
  String get excelHyperlinkActivationSheetName => 'ハイパーリンク有効化方法';

  @override
  String get excelColumnGroupName => 'グループ名';

  @override
  String get excelColumnLabel => 'ラベル';

  @override
  String get excelColumnLink => 'リンク';

  @override
  String get excelColumnMemo => 'メモ';

  @override
  String get excelSecurityWarningTitle => 'セキュリティ警告について';

  @override
  String get excelSecurityWarningDescription =>
      'ハイパーリンクをクリックすると、Excelのセキュリティ警告が表示される場合があります。これは、ローカルファイルやネットワークパスへのリンクに対するExcelの標準的なセキュリティ機能です。';

  @override
  String get excelSecurityWarningSolution =>
      '警告が表示された場合は、「はい」をクリックして続行してください。信頼できるファイルへのリンクであれば安全です。';

  @override
  String get officialWebsite => '公式サイト';

  @override
  String get officialWebsiteDescription =>
      '詳細な情報やスクリーンショット、デモ動画は公式サイトでご確認いただけます。';

  @override
  String get openWebsite => 'サイトを開く';

  @override
  String get noGroupsSelected => 'グループが選択されていません';

  @override
  String get completionReport => '完了報告';

  @override
  String get scheduleEditAvailableAfterTaskCreation => '※ タスク作成後に予定編集が可能になります';

  @override
  String get scheduleOverlap => '予定の重複';

  @override
  String get overlappingSchedulesMessage => '以下の予定と時間が重複しています：';

  @override
  String get time => '時間';

  @override
  String get completionNotes => '完了メモ';

  @override
  String get completionNotesHint => '完了内容や結果を記入してください';

  @override
  String get completionNotesRequired => '完了メモを入力してください';

  @override
  String get sendCompletionReport => '完了報告を送信';

  @override
  String get clearReminder => 'リマインダーをクリア';

  @override
  String get recurringReminder => '繰り返しリマインダー';

  @override
  String selectWithCount(int count) {
    return '選択 ($count)';
  }

  @override
  String get to => '宛先';

  @override
  String get app => 'アプリ';

  @override
  String get bulkAssignLinks => 'リンクを一括割り当て';

  @override
  String get replaceAllTags => '既存のタグを全て置き換えます';

  @override
  String get goToSettings => '設定画面へ';

  @override
  String get mailAction => 'メールアクション';

  @override
  String get selectMailAction => 'このタスクに関連するメールアクションを選択してください。';

  @override
  String get reply => '返信';

  @override
  String get showMoreCandidates => '候補をさらに表示';

  @override
  String get selectTask => 'タスクを選択';

  @override
  String get createTaskFirstToAddSchedule => '予定を追加するには、まずタスクを作成してください';

  @override
  String get scheduleCopied => '予定をコピーしました';

  @override
  String get scheduleDeleted => '予定を削除しました';

  @override
  String scheduleFetchFailed(String error) {
    return '予定の取得に失敗しました: $error';
  }

  @override
  String scheduleAssignmentFailed(String title, String error) {
    return '予定「$title」の割り当てに失敗しました: $error';
  }

  @override
  String taskCreationFailed(String error) {
    return 'タスクの作成に失敗しました: $error';
  }

  @override
  String get needAtLeastTwoGroups => '並び順を変更するには2つ以上のグループが必要です';

  @override
  String get createTaskFirst => '先にタスクを作成してください';

  @override
  String get subTaskTitleRequired => 'サブタスクのタイトルは必須です';

  @override
  String historyFetchError(String error) {
    return '履歴取得エラー: $error';
  }

  @override
  String get completionReportSent => '完了報告を送信しました';

  @override
  String completionReportSendError(String error) {
    return '完了報告送信エラー: $error';
  }

  @override
  String get accessTokenDescription =>
      'access_token: Google Calendar APIへのアクセス権限';

  @override
  String get refreshTokenDescription => 'refresh_token: アクセストークンの更新用';

  @override
  String get expiresAtDescription => 'expires_at: トークンの有効期限';

  @override
  String get noManualEditRequired => '※ このファイルは手動で編集する必要はありません。';

  @override
  String get openGoogleCloudConsole => 'Google Cloud Consoleを開く';

  @override
  String browserOpenFailed(String error) {
    return 'ブラウザを開けませんでした: $error';
  }

  @override
  String get resetAllSettingsTitle => '設定をリセット';

  @override
  String get resetAllSettingsConfirm => 'すべての設定をデフォルト値にリセットしますか？この操作は取り消せません。';

  @override
  String get resetButton => 'リセット';

  @override
  String get dataRetention => 'データの保持について';

  @override
  String get dataWillNotBeDeleted => '以下のデータは削除されません:';

  @override
  String get linkData => 'リンクデータ';

  @override
  String get linkDataDescription => 'すべてのリンク、グループ、メモが保持されます';

  @override
  String get taskData => 'タスクデータ';

  @override
  String get taskDataDescription => 'すべてのタスク、サブタスク、進捗が保持されます';

  @override
  String get searchHistoryRetained => '検索履歴は保持されます';

  @override
  String get resetAfterActions => 'リセット後の動作';

  @override
  String get afterResetWillBe => 'リセット後は以下のようになります:';

  @override
  String get appRestart => 'アプリ再起動';

  @override
  String get appRestartDescription => '設定変更を反映するため再起動が推奨されます';

  @override
  String get settingsConfirmation => '設定確認';

  @override
  String get settingsConfirmationDescription => '設定画面で新しい設定値を確認できます';

  @override
  String get dataRestore => 'データ復元';

  @override
  String get dataRestoreDescription => 'エクスポート/インポート機能でデータを復元可能';

  @override
  String get dateRangeSync => '日付範囲同期';

  @override
  String get selectDateRangeToSync => '同期する日付範囲を選択してください';

  @override
  String get endDate => '終了日';

  @override
  String get executeSync => '同期実行';

  @override
  String get dateRangeSyncInProgress => '日付範囲同期中...';

  @override
  String dateRangeSyncCompleted(int count) {
    return '日付範囲同期完了: $count件成功';
  }

  @override
  String get dateRangeSyncCompletedSuccess => '日付範囲同期が完了しました';

  @override
  String get dateRangeSyncFailed => '日付範囲同期に失敗しました';

  @override
  String dateRangeSyncError(String error) {
    return '日付範囲同期中にエラーが発生しました: $error';
  }

  @override
  String get syncFailed => '同期に失敗しました';

  @override
  String taskSyncCompleted(String title) {
    return '「$title」の同期が完了しました';
  }

  @override
  String taskSyncFailedMessage(String title) {
    return '「$title」の同期に失敗しました';
  }

  @override
  String taskSyncErrorMessage(String title) {
    return '「$title」の同期中にエラーが発生しました';
  }

  @override
  String get outlookConnectionTestCompleted => 'Outlook接続テストが完了しました！';

  @override
  String get saveTemplate => 'テンプレートを保存';

  @override
  String get templateDescription => '説明（任意）';

  @override
  String get templateDescriptionHint => 'このテンプレートの説明';

  @override
  String get dataSelection => 'データ選択';

  @override
  String get taskFilter => 'タスクフィルター';

  @override
  String get confirmation => '確認';

  @override
  String get searchHint => '検索...';

  @override
  String get groups => 'グループ';

  @override
  String get groupsSelectionDescription => 'グループを選択すると、そのグループ内のすべてのリンクが含まれます';

  @override
  String get tasks => 'タスク';

  @override
  String get tasksSelectionDescription => '個別にタスクを選択します';

  @override
  String get includeMemos => 'メモを含める';

  @override
  String selectedCount(int selected, int total) {
    return '選択: $selected / $total';
  }

  @override
  String get noItems => '項目がありません';

  @override
  String get noTaskData => 'タスクデータがありません';

  @override
  String get taskFilterSettings => 'タスクフィルター設定';

  @override
  String get tag => 'タグ';

  @override
  String get selectEndDate => '終了日を選択';

  @override
  String start(String date) {
    return '開始: $date';
  }

  @override
  String end(String date) {
    return '終了: $date';
  }

  @override
  String get exportSettings => '設定エクスポート';

  @override
  String get uiSettings => 'UI設定';

  @override
  String get uiSettingsDescription => 'テーマ、色、フォントサイズなど';

  @override
  String get featureSettings => '機能設定';

  @override
  String get featureSettingsDescription => '自動バックアップ、通知など';

  @override
  String get integrationSettings => '連携設定';

  @override
  String get integrationSettingsDescription => 'Google Calendar、Outlookなど';

  @override
  String get exportPreview => 'エクスポート内容の確認';

  @override
  String get partialImportSettings => '部分インポート設定';

  @override
  String get selectImportMethod => 'インポート方法を選択してください';

  @override
  String get importMethod => 'インポート方法';

  @override
  String get addToExistingData => '既存データに追加します';

  @override
  String get overwrite => '上書き';

  @override
  String get replaceExistingData => '既存データを置き換えます';

  @override
  String get mergeWithDuplicateCheck => '重複をチェックして統合します';

  @override
  String get duplicateHandling => '重複処理方法';

  @override
  String get skip => 'スキップ';

  @override
  String get skipDuplicateData => '重複データをスキップします';

  @override
  String get overwriteExistingData => '既存データを上書きします';

  @override
  String get rename => '名前を変更';

  @override
  String get renameAndAdd => '名前を変更して追加します';

  @override
  String get importData => 'インポートするデータ';

  @override
  String get links => 'リンク';

  @override
  String get next => '次へ';

  @override
  String get back => '戻る';
}
