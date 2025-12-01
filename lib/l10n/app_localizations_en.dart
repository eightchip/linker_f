// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Link Navigator';

  @override
  String get settings => 'Settings';

  @override
  String get general => 'General';

  @override
  String get theme => 'Theme';

  @override
  String get font => 'Font';

  @override
  String get backup => 'Backup';

  @override
  String get notifications => 'Notifications';

  @override
  String get outlook => 'Outlook Integration';

  @override
  String get language => 'Language';

  @override
  String get japanese => 'Japanese';

  @override
  String get english => 'English';

  @override
  String get enableAutomaticImport => 'Enable Automatic Import';

  @override
  String get enableAutomaticImportDescription =>
      'Automatically import schedules from your Outlook personal calendar. Imported schedules are linked to the \"Outlook Integration (Auto Import)\" task.\n\n⚠️ Warning: Outlook may crash when automatic import is executed while Outlook is running.';

  @override
  String get importPeriod => 'Import Period';

  @override
  String get importPeriodDescription =>
      'Set how far into the future schedules will be imported, starting from tomorrow.';

  @override
  String get automaticImportFrequency => 'Automatic Import Frequency';

  @override
  String get onlyOnAppStart => 'Only when app starts';

  @override
  String get every30Minutes => 'Every 30 minutes';

  @override
  String get every1Hour => 'Every 1 hour';

  @override
  String get everyMorning9am => 'Every morning at 9:00';

  @override
  String get oneWeek => '1 Week';

  @override
  String get twoWeeks => '2 Weeks';

  @override
  String get oneMonth => '1 Month';

  @override
  String get threeMonths => '3 Months';

  @override
  String get halfYear => 'Half Year';

  @override
  String get oneYear => '1 Year';

  @override
  String get taskManagement => 'Task Management';

  @override
  String get linkManagement => 'Link Management';

  @override
  String itemsSelected(int count) {
    return '$count items selected';
  }

  @override
  String get startWithTaskScreen => 'Start with Task Screen';

  @override
  String get startWithTaskScreenDescription =>
      'Display the task screen by default when the app starts. When turned off, the app starts with the link management screen.';

  @override
  String get appearance => 'Appearance';

  @override
  String get layout => 'Layout';

  @override
  String get data => 'Data';

  @override
  String get integration => 'Integration';

  @override
  String get others => 'Others';

  @override
  String get startupSettings => 'Startup Settings';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get fontSettings => 'Font Settings';

  @override
  String get uiCustomization => 'UI Customization';

  @override
  String get gridSettings => 'Grid Settings';

  @override
  String get cardSettings => 'Card Settings';

  @override
  String get itemSettings => 'Item Settings';

  @override
  String get cardViewSettings => 'Card View Settings';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get gmailIntegration => 'Gmail Integration';

  @override
  String get reset => 'Reset';

  @override
  String get allScreens => 'All Screens';

  @override
  String get linkScreen => 'Link Screen';

  @override
  String get linkAndTaskScreens => 'Link & Task Screens';

  @override
  String get taskList => 'Task List';

  @override
  String get integrationSettingsRequired =>
      'Each integration feature requires individual settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get useDarkTheme => 'Use dark theme';

  @override
  String get cancel => 'Cancel';

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get resetSettingsConfirm =>
      'Reset all UI settings to default values?\nThis action cannot be undone.';

  @override
  String get resetExecuted => 'Reset';

  @override
  String get uiSettingsReset => 'Reset UI Settings';

  @override
  String get uiSettingsResetConfirm =>
      'Reset all UI customization settings to default values.\n\nThis action cannot be undone.\nAre you sure you want to proceed?';

  @override
  String get uiSettingsResetSuccess => 'UI settings have been reset';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get addGroup => 'Add Group';

  @override
  String get search => 'Search';

  @override
  String get memoBulkEdit => 'Bulk Edit Memos';

  @override
  String get shortcutKeys => 'Shortcut Keys';

  @override
  String get linkManagementShortcuts => 'Link Management Shortcuts';

  @override
  String get addGroupShortcut => 'Add Group';

  @override
  String get openSearchBar => 'Open Search Bar';

  @override
  String get openTaskManagement => 'Open Task Management';

  @override
  String get openMemoBulkEdit => 'Open Bulk Edit Memos';

  @override
  String get changeGroupOrder => 'Change Group Order';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get showThreeDotMenu => 'Show 3-dot Menu';

  @override
  String get focusThreeDotMenu => 'Focus on 3-dot menu';

  @override
  String get closeSearchBar => 'Close Search Bar';

  @override
  String get switchLinkTypeFilter => 'Switch Link Type Filter';

  @override
  String get showShortcutList => 'Display shortcut list';

  @override
  String linksCount(int count) {
    return '$count links';
  }

  @override
  String get searchLinkNameMemo => 'Search (Link Name / Memo)';

  @override
  String resultsCount(int count) {
    return '$count results';
  }

  @override
  String get noSearchResults => 'No search results';

  @override
  String get noMemoLinks => 'No links with memos';

  @override
  String get saveAll => 'Save All';

  @override
  String get searchPlaceholder =>
      'Search (File name / Folder name / URL / Tag)';

  @override
  String get type => 'Type';

  @override
  String get all => 'All';

  @override
  String get url => 'URL';

  @override
  String get folder => 'Folder';

  @override
  String get file => 'File';

  @override
  String get globalMenu => 'Global Menu';

  @override
  String get common => 'Common';

  @override
  String get linkManagementEnabled =>
      'Link Management (Enabled on Link Management Screen)';

  @override
  String get taskManagementEnabled =>
      'Task Management (Enabled on Task Management Screen)';

  @override
  String get newTask => 'New Task';

  @override
  String get bulkSelectMode => 'Bulk Select Mode';

  @override
  String get csvExport => 'CSV Export';

  @override
  String get scheduleList => 'Schedule List';

  @override
  String get grouping => 'Grouping';

  @override
  String get createFromTemplate => 'Create from template';

  @override
  String get toggleStatisticsSearchBar => 'Show/hide statistics/search bar';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get pathOrUrl => 'Path/URL';

  @override
  String get enterPathOrUrl => 'Enter file path or URL...';

  @override
  String get selectFolderIcon => 'Select Folder Icon:';

  @override
  String get homeScreen => 'Return to Home Screen';

  @override
  String get exitSelectionMode => 'Exit Selection Mode';

  @override
  String get searchTasks =>
      'Search Tasks (Title / Description / Tags / Assignee)';

  @override
  String get searchWithRegex =>
      'Search with Regex (e.g., ^Project.*Complete\\\$)';

  @override
  String get searchHistory => 'Search History';

  @override
  String get clear => 'Clear';

  @override
  String get switchToNormalSearch => 'Switch to Normal Search';

  @override
  String get switchToRegexSearch => 'Switch to Regex Search';

  @override
  String get searchOptions => 'Search Options';

  @override
  String get addMemo => 'Add Memo';

  @override
  String get memoCanBeAddedFromLinkManagement =>
      'Memos can be added from the Link Management screen';

  @override
  String get unpin => 'Unpin';

  @override
  String get pinToTop => 'Pin to Top';

  @override
  String get changeStatus => 'Change Status';

  @override
  String get changePriority => 'Change Priority';

  @override
  String get hideFilters => 'Hide Filters';

  @override
  String get showFilters => 'Show Filters';

  @override
  String get changeGridColumns => 'Change Grid Columns';

  @override
  String get saveLoadFilters => 'Save / Load Filters';

  @override
  String get bulkOperations => 'Bulk Operations';

  @override
  String get memoLabel => 'Memo';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get cardView => 'Card View';

  @override
  String get listView => 'List View';

  @override
  String get status => 'Status';

  @override
  String get notStarted => 'Not Started';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get sortOrder => 'Sort Order';

  @override
  String get firstPriority => '1st Priority';

  @override
  String get secondPriority => '2nd Priority';

  @override
  String get thirdPriority => '3rd Priority';

  @override
  String get dueDateOrder => 'Due Date Order';

  @override
  String get statusOrder => 'Status Order';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get priorityOrder => 'Priority Order';

  @override
  String get titleOrder => 'Title Order';

  @override
  String get createdOrder => 'Created Date Order';

  @override
  String get none => 'None';

  @override
  String get details => 'Details';

  @override
  String get collapseLinks => 'Collapse Links';

  @override
  String get expandLinks => 'Expand Links';

  @override
  String get subtask => 'Subtask';

  @override
  String subtaskTooltip(int total, int completed) {
    return 'Subtasks: $total\nCompleted: $completed';
  }

  @override
  String get showAllDetails => 'Show All Details';

  @override
  String get hideAllDetails => 'Hide All Details';

  @override
  String get toggleDetails => 'Toggle Details';

  @override
  String get columns => 'Columns';

  @override
  String get notStartedTasks => 'Not Started Tasks';

  @override
  String get inProgressTasks => 'In Progress Tasks';

  @override
  String get statusChange => 'Change Status';

  @override
  String get clearDueDate => 'Clear Due Date';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirm => 'Clear History';

  @override
  String get noGrouping => 'No Grouping';

  @override
  String get groupByStatus => 'Group by Status';

  @override
  String get noTags => 'No Tags';

  @override
  String get noLinks => 'No Links';

  @override
  String countItems(String label, int count) {
    return '$label: $count items';
  }

  @override
  String get tapForDetails => 'Tap for details';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get addLink => 'Add Link';

  @override
  String get editLink => 'Edit Link';

  @override
  String get deleteLink => 'Delete Link';

  @override
  String get addTaskFromLink => 'Add Task from Link';

  @override
  String get copy => 'Copy';

  @override
  String get syncTask => 'Sync This Task';

  @override
  String get delete => 'Delete';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get low => 'Low';

  @override
  String get urgent => 'Urgent';

  @override
  String get lowShort => 'L';

  @override
  String get mediumShort => 'M';

  @override
  String get highShort => 'H';

  @override
  String get urgentShort => 'U';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get cancelledShort => 'C';

  @override
  String get dueDate => 'Due Date';

  @override
  String get started => 'Started';

  @override
  String get taskManagementShortcuts => 'Task Management Shortcuts';

  @override
  String get minimize => 'Minimize';

  @override
  String get maximize => 'Maximize';

  @override
  String get restoreWindow => 'Restore Window';

  @override
  String get shortcutList => 'Shortcut List';

  @override
  String get scheduleScreen => 'Schedule';

  @override
  String get searchSchedule => 'Search by schedule title, task name, location';

  @override
  String get switchView => 'Switch View';

  @override
  String get monthlyView => 'Monthly View';

  @override
  String get showPast => 'Show Past';

  @override
  String get importFromOutlook => 'Import from Outlook';

  @override
  String get copyToExcel => 'Copy to Excel';

  @override
  String copyToExcelSelected(int count) {
    return 'Copy to Excel (Copy $count days of schedules to clipboard)';
  }

  @override
  String get copyToExcelSelectDate => 'Copy to Excel (Please select dates)';

  @override
  String get tableFormat => 'Table Format (Multiple Columns)';

  @override
  String get oneCellFormat => 'One Cell Format (List)';

  @override
  String get action => 'Action';

  @override
  String get today => 'Today';

  @override
  String daysRemaining(int count) {
    return '$count days left';
  }

  @override
  String get oneDayRemaining => '1 day left';

  @override
  String daysOverdue(int count) {
    return '$count days overdue';
  }

  @override
  String get notSet => 'Not Set';

  @override
  String showOtherLinks(int count) {
    return 'Show $count other links';
  }

  @override
  String get editTask => 'Edit Task';

  @override
  String get title => 'Title';

  @override
  String get body => 'Body';

  @override
  String get descriptionForRequestor => 'Description for Requestor';

  @override
  String get tags => 'Tags';

  @override
  String get startDate => 'Start Date';

  @override
  String get completionDate => 'Completion Date';

  @override
  String get reminderFunction => 'Reminder Function';

  @override
  String get linkAssociation => 'Link Association';

  @override
  String get relatedLinks => 'Related Links';

  @override
  String get pinning => 'Pinning';

  @override
  String get schedule => 'Schedule';

  @override
  String get emailSendingFunction => 'Email Sending Function';

  @override
  String get openEmailSendingFunction => 'Open Email Sending Function';

  @override
  String get collapseMailFunction => 'Collapse Mail Function';

  @override
  String get update => 'Update';

  @override
  String get selectStartDate => 'Select Start Date';

  @override
  String get subtaskTitle => 'Subtask Title';

  @override
  String get estimatedTime => 'Estimated Time (minutes)';

  @override
  String get description => 'Description';

  @override
  String get add => 'Add';

  @override
  String get creationDate => 'Creation Date';

  @override
  String get subtaskName => 'Subtask Name';

  @override
  String get enterTitle => 'Please enter a title';

  @override
  String get bodyTextCanDisplayUpTo8Lines =>
      'Body text can be displayed up to 8 lines.';

  @override
  String get noSubtasks => 'No Subtasks';

  @override
  String estimatedTimeMinutes(int minutes) {
    return 'Estimated Time: $minutes minutes';
  }

  @override
  String get create => 'Create';

  @override
  String get selectDueDate => 'Select Due Date';

  @override
  String get priority => 'Priority';

  @override
  String get clearStartDate => 'Clear Start Date';

  @override
  String get selectCompletionDate => 'Select Completion Date';

  @override
  String get clearCompletionDate => 'Clear Completion Date';

  @override
  String get pinnedToTop => 'Pinned to Top';

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
  String get editGroupName => 'Edit Group Name';

  @override
  String get createTaskFromLink => 'Create task from this link';

  @override
  String get activeTaskExists => 'Active task exists';

  @override
  String get selectCopyDestination => 'Select Copy Destination';

  @override
  String get selectMoveDestination => 'Select Move Destination';

  @override
  String linkCopied(String linkName, String groupName) {
    return 'Copied \"$linkName\" to \"$groupName\"';
  }

  @override
  String linkMoved(String linkName, String groupName) {
    return 'Moved \"$linkName\" to \"$groupName\"';
  }

  @override
  String copyFailed(String error) {
    return 'Copy failed: $error';
  }

  @override
  String get copyNotAvailable => 'Copy function not available';

  @override
  String get moveNotAvailable => 'Move function not available';

  @override
  String get noCopyDestinationGroups => 'No destination groups for copy';

  @override
  String get noMoveDestinationGroups => 'No destination groups for move';

  @override
  String get dragToReorder => 'You can change the order by drag & drop';

  @override
  String get groupOrderChanged => 'Group order changed';

  @override
  String get taskTemplate => 'Task Template';

  @override
  String get selectTemplate => 'Select Template';

  @override
  String get taskDetails => 'Task Details';

  @override
  String get templateName => 'Template Name';

  @override
  String get templateNameExample =>
      'Example: Meeting preparation, regular reports, etc.';

  @override
  String get createTask => 'Create Task';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get editComplete => 'Edit Complete';

  @override
  String get addNewTemplate => 'Add New Template';

  @override
  String get syncThisTask => 'Sync this task';

  @override
  String get taskCreated => 'Task created';

  @override
  String get reminder => 'Reminder';

  @override
  String get selectPlease => 'Please select';

  @override
  String get createNewTask => 'Create a new task';

  @override
  String get toggleBatchSelectionMode => 'Toggle batch selection mode';

  @override
  String get exportToCsv => 'Export to CSV';

  @override
  String get openSettingsScreen => 'Open settings screen';

  @override
  String get openSchedule => 'Open schedule';

  @override
  String get groupingMenu => 'Grouping menu';

  @override
  String get toggleCompactStandardDisplay =>
      'Toggle compact ⇔ standard display';

  @override
  String get goHomeOrOpenThreeDotMenu => 'Go back to home / Open 3-dot menu';

  @override
  String get history => 'History';

  @override
  String get task => 'Task';

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
