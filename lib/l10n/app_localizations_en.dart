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
  String get createFromTemplate => 'Create from Template';

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
  String get noSearchHistory => 'No search history';

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
  String get memoLabel => 'Memo:';

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
  String get deleteGroupConfirm => 'Do you want to delete this group?';

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
  String get cancelledShort => 'X';

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
  String get tableFormat => 'Table Format';

  @override
  String get oneCellFormat => 'One Cell Format';

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
  String get oneDayOverdue => '1 day overdue';

  @override
  String get notSet => 'Not Set';

  @override
  String showOtherLinks(int count) {
    return 'Show $count more links';
  }

  @override
  String get showMore => 'Show more';

  @override
  String get editTask => 'Edit Task';

  @override
  String get title => 'Title';

  @override
  String get body => 'Body';

  @override
  String get descriptionForRequestor => 'Description for Requestor';

  @override
  String get descriptionForAssignee => 'Description for Assignee';

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
  String get howToUseRegex => 'How to use Regular Expressions';

  @override
  String get commonPatterns => 'Common patterns:';

  @override
  String get copyPattern => 'Copy Pattern';

  @override
  String patternCopied(String pattern) {
    return 'Copied \"$pattern\"';
  }

  @override
  String get regexInvalidWarning =>
      'If the regular expression is invalid, it will automatically switch to normal search';

  @override
  String get regexExample1 => 'Tasks starting with \"project\"';

  @override
  String get regexExample2 => 'Tasks ending with \"completed\"';

  @override
  String get regexExample3 =>
      'Tasks starting with \"project\" and ending with \"completed\"';

  @override
  String get regexExample4 => 'Tasks containing \"urgent\" or \"important\"';

  @override
  String get regexExample5 => 'Tasks containing date format (YYYY-MM-DD)';

  @override
  String get regexExample6 => 'Tasks containing 2 or more uppercase letters';

  @override
  String get regexExample7 => 'Task titles of 1 to 10 characters';

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
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get quickFilterApplied => 'クイックフィルターを適用しました';

  @override
  String get filterReset => 'フィルターをリセットしました';

  @override
  String get editGroupName => 'Edit Group Name';

  @override
  String get newGroupName => 'New Group Name';

  @override
  String get color => 'Color';

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
  String get createNewTask => 'Create New Task';

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
  String get urgentTasks => 'Urgent Tasks';

  @override
  String get todayTasks => 'Today\'s Tasks';

  @override
  String get total => 'Total';

  @override
  String get totalTasks => 'Total';

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
  String get requester => 'Requester';

  @override
  String get normalSearchMode => 'Normal Search Mode';

  @override
  String get normalSearchOption => 'Normal Search Mode';

  @override
  String get regexSearchMode => 'Regular Expression Search Mode';

  @override
  String get scheduleTitle => 'Schedule Title';

  @override
  String get startDateTime => 'Start Date/Time';

  @override
  String get endDateTime => 'End Date/Time';

  @override
  String get location => 'Location';

  @override
  String get selectDateTime => 'Select Date/Time';

  @override
  String get selectDateTimeOptional => 'Select Date/Time (Optional)';

  @override
  String get addSchedule => 'Add Schedule';

  @override
  String get updateSchedule => 'Update Schedule';

  @override
  String get scheduleAdded => 'Schedule added';

  @override
  String get startDateTimeRequired => 'Start date/time is required';

  @override
  String get outlookDesktop => 'Outlook (Desktop)';

  @override
  String get gmailWeb => 'Gmail (Web)';

  @override
  String get outlookTest => 'Test Outlook';

  @override
  String get gmailTest => 'Test Gmail';

  @override
  String get sendHistory => 'Send History';

  @override
  String get launchMailer => 'Launch Mailer';

  @override
  String get mailSentComplete => 'Mail Sent';

  @override
  String get launchMailerFirst => 'Please launch mailer first';

  @override
  String get copyTask => 'Copy Task';

  @override
  String copyTaskConfirm(String title) {
    return 'Do you want to copy \"$title\"?';
  }

  @override
  String get repeatPeriod => 'Repeat Period:';

  @override
  String get monthly => 'Monthly (1 month later)';

  @override
  String get quarterly => 'Quarterly (3 months later)';

  @override
  String get yearly => 'Yearly (1 year later)';

  @override
  String get custom => 'Custom';

  @override
  String get copyCount => 'Number of Copies:';

  @override
  String copyCountLabel(int count) {
    return '$count items';
  }

  @override
  String get maxCopiesMonthly =>
      'Up to 12 items (copy with due dates shifted by 1 month each)';

  @override
  String get maxCopiesQuarterly =>
      'Up to 4 items (copy with due dates shifted by 3 months each)';

  @override
  String get selectReminderTime => 'Select Reminder Time (Optional)';

  @override
  String get copiedContent => 'Content to be copied:';

  @override
  String get titleLabel => 'Title:';

  @override
  String get copySuffix => 'Copy';

  @override
  String get descriptionLabel => 'Description:';

  @override
  String get requestorMemoLabel => 'Requestor/Memo:';

  @override
  String get copyCountLabel2 => 'Number of Copies:';

  @override
  String get dueDateLabel => 'Due Date:';

  @override
  String get reminderLabel => 'Reminder:';

  @override
  String get priorityLabel => 'Priority:';

  @override
  String get statusLabel => 'Status:';

  @override
  String get tagsLabel => 'Tags:';

  @override
  String get estimatedTimeLabel => 'Estimated Time:';

  @override
  String get minutes => 'minutes';

  @override
  String get subtasksLabel => 'Subtasks:';

  @override
  String get statusResetNote => '※ Status will be reset to \"Not Started\"';

  @override
  String get subtasksCopiedNote => '※ Subtasks will also be copied';

  @override
  String taskCopiedSuccess(int count) {
    return 'Copied $count task(s)';
  }

  @override
  String taskCopiedPartial(int success, int failed) {
    return 'Copied $success task(s) ($failed failed)';
  }

  @override
  String get taskCopyFailed => 'Failed to copy task';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String deleteTaskConfirm(String title) {
    return 'Do you want to delete \"$title\"?';
  }

  @override
  String get deleteOptions => 'Deletion Options:';

  @override
  String get deleteAppOnly => 'Delete from app only';

  @override
  String get deleteAppAndCalendar => 'Delete from app and Google Calendar';

  @override
  String get appOnly => 'App only';

  @override
  String get deleteBoth => 'Delete both';

  @override
  String taskDeletedSuccess(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String taskDeletedFromBoth(String title) {
    return 'Deleted \"$title\" from app and Google Calendar';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String deleteSelectedTasks(int count) {
    return 'Do you want to delete $count selected task(s)?';
  }

  @override
  String backupExecuted(int count) {
    return 'Backup executed. Deleting $count task(s)...';
  }

  @override
  String backupFailedContinue(String error) {
    return 'Backup failed, but continuing with merge: $error';
  }

  @override
  String get deleteSchedule => 'Delete Schedule';

  @override
  String deleteScheduleConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get warning => 'Warning';

  @override
  String get selectAtLeastTwoTasks => 'Please select at least 2 tasks';

  @override
  String get noSourceTasks => 'No source tasks to merge';

  @override
  String get backupExecutedMerge => 'Backup executed. Merging tasks...';

  @override
  String get taskMergeFailed => 'Failed to merge tasks';

  @override
  String get linkAssignmentFailed => 'Failed to assign link';

  @override
  String get statusChangeFailed => 'Failed to change status';

  @override
  String get priorityChangeFailed => 'Failed to change priority';

  @override
  String get dueDateChangeFailed => 'Failed to change due date';

  @override
  String get tagChangeFailed => 'Failed to change tags';

  @override
  String taskSyncedToCalendar(String title) {
    return 'Synced \"$title\" to Google Calendar';
  }

  @override
  String taskSyncFailed(String title, String error) {
    return 'Failed to sync \"$title\": $error';
  }

  @override
  String taskSyncError(String title, String error) {
    return 'Error occurred while syncing \"$title\": $error';
  }

  @override
  String get exportFailed => 'Export failed';

  @override
  String get invalidFileFormat => 'Invalid file format';

  @override
  String get importFailed => 'Import failed';

  @override
  String get sendHistorySearchError => 'Send history search error';

  @override
  String get mailerLaunched => 'Mailer launched';

  @override
  String get replyAddressNotFound => 'Reply address not found';

  @override
  String get mailerLaunchFailed => 'Failed to launch mailer';

  @override
  String linkOpenFailed(String href) {
    return 'Failed to open link: $href';
  }

  @override
  String uncPathOpenFailed(String path) {
    return 'Failed to open UNC path: $path';
  }

  @override
  String urlOpenFailed(String url) {
    return 'Failed to open URL: $url';
  }

  @override
  String fileOpenFailed(String path) {
    return 'Failed to open file: $path';
  }

  @override
  String contactAddError(String error) {
    return 'Contact add error: $error';
  }

  @override
  String linksAddedToTasks(int count) {
    return 'Added links to $count tasks';
  }

  @override
  String linksRemovedFromTasks(int count) {
    return 'Removed links from $count tasks';
  }

  @override
  String linksReplacedInTasks(int count) {
    return 'Replaced links in $count tasks';
  }

  @override
  String linksChangedInTasks(int count) {
    return 'Changed links in $count tasks';
  }

  @override
  String tagsAddedToTasks(int count) {
    return 'Added tags to $count tasks';
  }

  @override
  String tagsRemovedFromTasks(int count) {
    return 'Removed tags from $count tasks';
  }

  @override
  String tagsReplacedInTasks(int count) {
    return 'Replaced tags in $count tasks';
  }

  @override
  String tagsChangedInTasks(int count) {
    return 'Changed tags in $count tasks';
  }

  @override
  String syncingTask(String title) {
    return 'Syncing \"$title\"...';
  }

  @override
  String get fromTodayOneWeek => '1 Week from Today';

  @override
  String get fromTodayTwoWeeks => '2 Weeks from Today';

  @override
  String get fromTodayOneMonth => '1 Month from Today';

  @override
  String get fromTodayThreeMonths => '3 Months from Today';

  @override
  String get tagsCommaSeparated => 'Tags (comma-separated)';

  @override
  String get tagsExample => 'Example: Urgent, Important, Project A';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeek => 'This Week';

  @override
  String get nextWeek => 'Next Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get later => 'Later';

  @override
  String get overdue => 'Overdue';

  @override
  String get noDueDate => 'No Due Date';

  @override
  String get colorPresets => 'Color Presets';

  @override
  String get applyRecommendedColors =>
      'Apply recommended color scheme with one tap';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get colorIntensity => 'Color Intensity';

  @override
  String get contrastAdjustment => 'Contrast Adjustment';

  @override
  String get textColorSettings => 'Text Color Settings';

  @override
  String get cardViewFieldSettingsDescription =>
      'You can individually set the text color, font size, and font family for each field displayed in the card view';

  @override
  String get realtimePreview => 'Real-time Preview';

  @override
  String get live => 'Live';

  @override
  String get cardSettingsDescription =>
      'Adjust the card\'s appearance and behavior. You can change the corner radius, shadow strength, and padding.';

  @override
  String get cornerRadius => 'Corner Radius';

  @override
  String get shadowStrength => 'Shadow Strength';

  @override
  String get padding => 'Padding';

  @override
  String get sampleCard => 'Sample Card';

  @override
  String get cardPreviewDescription =>
      'This is a card preview. Changes to settings will be reflected in real-time.';

  @override
  String get sampleButton => 'Sample Button';

  @override
  String get outlineButton => 'Outline Button';

  @override
  String get sampleInputField => 'Sample Input Field';

  @override
  String currentSettings(String radius, String shadow, String padding) {
    return 'Corner Radius: ${radius}px | Shadow: $shadow% | Padding: ${padding}px';
  }

  @override
  String get buttonSettings => 'Button Settings';

  @override
  String get cardViewShort => 'C';

  @override
  String get listViewShort => 'L';

  @override
  String get taskListDisplaySettings => 'Task List Display Settings';

  @override
  String get taskListFieldSettingsDescription =>
      'You can individually set the text color, font size, and font family for each field displayed in the task list and task edit screens';

  @override
  String get resetCardViewSettings => 'Reset Card View Settings';

  @override
  String get resetCardViewSettingsConfirm =>
      'Do you want to reset the card view settings to default values?\nThis action cannot be undone.';

  @override
  String get textColor => 'Text Color';

  @override
  String get requestorDescription => 'Requestor Description';

  @override
  String get assigneeDescription => 'Assignee Description';

  @override
  String get allScreensCommon => 'All Screens';

  @override
  String appWideFontSize(String percentage) {
    return 'App-wide Font Size: $percentage%';
  }

  @override
  String get autoLayoutAdjustment => 'Auto Layout Adjustment';

  @override
  String get autoAdjustToScreenSize => 'Auto-adjust to screen size';

  @override
  String fieldSettings(String fieldName) {
    return '$fieldName Settings';
  }

  @override
  String get colorPresetSunrise => 'Sunrise';

  @override
  String get colorPresetSunriseDesc => 'Warm orange tones';

  @override
  String get colorPresetForest => 'Forest';

  @override
  String get colorPresetForestDesc => 'Calm green tones';

  @override
  String get colorPresetBreeze => 'Blue Breeze';

  @override
  String get colorPresetBreezeDesc => 'Refreshing blue tones';

  @override
  String get colorPresetMidnight => 'Midnight';

  @override
  String get colorPresetMidnightDesc => 'Dark theme suitable for night work';

  @override
  String get colorPresetSakura => 'Sakura';

  @override
  String get colorPresetSakuraDesc => 'Soft pink tones';

  @override
  String get colorPresetCitrus => 'Citrus';

  @override
  String get colorPresetCitrusDesc => 'Fresh yellow-green tones';

  @override
  String get colorPresetSlate => 'Slate';

  @override
  String get colorPresetSlateDesc => 'Calm blue-grey';

  @override
  String get colorPresetAmber => 'Amber';

  @override
  String get colorPresetAmberDesc => 'High visibility gold tone';

  @override
  String get colorPresetGraphite => 'Graphite';

  @override
  String get colorPresetGraphiteDesc => 'Modern monotone';

  @override
  String presetApplied(String presetName) {
    return 'Applied \"$presetName\" preset';
  }

  @override
  String presetApplyFailed(String error) {
    return 'Failed to apply preset: $error';
  }

  @override
  String get autoContrastOptimization => 'Auto Contrast Optimization';

  @override
  String get autoContrastOptimizationDesc =>
      'Automatically adjust text visibility in dark mode';

  @override
  String get iconSize => 'Icon Size';

  @override
  String get linkItemIconSizeDesc =>
      'Adjust the icon size of link items. Increasing the size improves visibility but also increases the overall item size.';

  @override
  String get gridSettingsReset => 'Grid Settings';

  @override
  String get gridSettingsResetDesc => 'Columns: 4, Spacing: Default';

  @override
  String get cardSettingsReset => 'Card Settings';

  @override
  String get cardSettingsResetDesc => 'Size: Default, Shadow: Default';

  @override
  String get itemSettingsReset => 'Item Settings';

  @override
  String get itemSettingsResetDesc => 'Font Size: Default, Icon Size: Default';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorRed => 'Red';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorGray => 'Gray';

  @override
  String get colorEmerald => 'Emerald';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorWhite => 'White';

  @override
  String get light => 'Light';

  @override
  String get standard => 'Standard';

  @override
  String get dark => 'Dark';

  @override
  String get contrastLow => 'Low';

  @override
  String get contrastHigh => 'High';

  @override
  String get contrast => 'Contrast';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontFamily => 'Font Family';

  @override
  String get defaultValue => 'Default';

  @override
  String fontSizePreview(String fieldName) {
    return 'Preview: The size of this text will be applied to $fieldName';
  }

  @override
  String fontFamilyPreview(String fieldName) {
    return 'Font Preview: The font of this text will be applied to $fieldName';
  }

  @override
  String get buttonSettingsDescription =>
      'Adjust the appearance of buttons. You can change the border radius and shadow intensity.';

  @override
  String get borderRadius => 'Border Radius';

  @override
  String borderRadiusPx(String value) {
    return 'Border Radius: ${value}px';
  }

  @override
  String get elevation => 'Shadow Intensity';

  @override
  String elevationPx(String value) {
    return 'Shadow Intensity: ${value}px';
  }

  @override
  String elevationPercent(String value) {
    return 'Shadow Intensity: $value%';
  }

  @override
  String get inputFieldSettings => 'Input Field Settings';

  @override
  String get inputFieldSettingsDescription =>
      'Adjust the appearance of text input fields. You can change the border radius and border width.';

  @override
  String get borderWidth => 'Border Width';

  @override
  String borderWidthPx(String value) {
    return 'Border Width: ${value}px';
  }

  @override
  String get hoverEffect => 'Hover Effect';

  @override
  String hoverEffectPercent(String value) {
    return 'Hover Effect: $value%';
  }

  @override
  String get gradient => 'Gradient';

  @override
  String gradientPercent(String value) {
    return 'Gradient: $value%';
  }

  @override
  String get generalSettings => 'General Settings';

  @override
  String get darkModeContrastBoost => 'Dark Mode Contrast Boost';

  @override
  String get autoLayoutEnabled =>
      'Auto layout is enabled. The optimal number of columns is automatically determined based on screen size.';

  @override
  String get largeScreen => 'Large Screen (1920px or more)';

  @override
  String columnsDisplay(String count) {
    return '$count columns';
  }

  @override
  String get optimalForDesktop => 'Optimal for desktop monitors';

  @override
  String get mediumScreen => 'Medium Screen (1200-1919px)';

  @override
  String get optimalForLaptop => 'Optimal for laptops and tablets';

  @override
  String get smallScreen => 'Small Screen (800-1199px)';

  @override
  String get optimalForSmallScreen => 'Optimal for small screens';

  @override
  String get minimalScreen => 'Minimal Screen (less than 800px)';

  @override
  String get optimalForMobile => 'Optimal for mobile display';

  @override
  String get manualLayoutEnabled =>
      'Manual layout settings are enabled. Display will use a fixed number of columns.';

  @override
  String get fixedColumns => 'Fixed Columns';

  @override
  String get sameColumnsAllScreens =>
      'Same number of columns for all screen sizes';

  @override
  String get useCase => 'Use Case';

  @override
  String get maintainSpecificDisplay =>
      'When you want to maintain a specific display';

  @override
  String get consistentLayoutNeeded => 'When a consistent layout is needed';

  @override
  String defaultColumnCount(String count) {
    return 'Default Column Count: $count';
  }

  @override
  String gridSpacing(String value) {
    return 'Grid Spacing: ${value}px';
  }

  @override
  String cardWidth(String value) {
    return 'Card Width: ${value}px';
  }

  @override
  String cardHeight(String value) {
    return 'Card Height: ${value}px';
  }

  @override
  String get itemMargin => 'Item Margin';

  @override
  String itemMarginPx(String value) {
    return 'Item Margin: ${value}px';
  }

  @override
  String get itemMarginDescription =>
      'Adjust the blank space between link items. Increasing the value widens the spacing between items, making them easier to see.';

  @override
  String get itemPadding => 'Item Padding';

  @override
  String itemPaddingPx(String value) {
    return 'Item Padding: ${value}px';
  }

  @override
  String get itemPaddingDescription =>
      'Adjust the blank space between text/icons and the border inside link items. Increasing the value makes the item content more spacious and easier to read.';

  @override
  String fontSizePx(String value) {
    return 'Font Size: ${value}px';
  }

  @override
  String get fontSizeDescription =>
      'Adjust the text size of link items. Making it smaller allows more items to be displayed, but may make them harder to read.';

  @override
  String get buttonSize => 'Button Size';

  @override
  String buttonSizePx(String value) {
    return 'Button Size: ${value}px';
  }

  @override
  String get buttonSizeDescription =>
      'Adjust the size of buttons such as edit and delete. Making them larger makes them easier to operate, but uses more screen space.';

  @override
  String get autoAdjustCardHeight => 'Auto Adjust Card Height';

  @override
  String get autoAdjustCardHeightDescription =>
      'Automatically adjust card height based on content amount (uses manually set height as minimum)';

  @override
  String get backupExport => 'Data Backup / Export';

  @override
  String get backupLocation => 'Save Location: Documents/backups';

  @override
  String get saveNow => 'Save Now';

  @override
  String get openBackupFolder => 'Open Backup Folder';

  @override
  String get selectiveExportImport => 'Selective Export / Import';

  @override
  String get selectiveExport => 'Selective Export';

  @override
  String get selectiveImport => 'Selective Import';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get autoBackupDescription => 'Backup data periodically';

  @override
  String backupInterval(String days) {
    return 'Backup Interval: $days days';
  }

  @override
  String backupIntervalDays(String days) {
    return '$days days';
  }

  @override
  String get notificationWarning =>
      'Note: Notifications are only displayed when the app is running. Notifications will not be displayed when the app is closed.';

  @override
  String get showNotifications => 'Show Notifications';

  @override
  String get showNotificationsDescription =>
      'Display desktop notifications when task deadlines or reminders are set. Notifications are only displayed when the app is running.';

  @override
  String get notificationSound => 'Notification Sound';

  @override
  String get notificationSoundDescription =>
      'Play a sound when notifications are displayed. Sound is only played when the app is running.';

  @override
  String get testNotificationSound => 'Test Notification Sound';

  @override
  String get testNotificationSoundDescription =>
      'You can test the notification sound with this button. Sound is only played when the app is running.';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get resetLayoutSettings => 'Reset Layout Settings';

  @override
  String get layoutSettingsReset => 'Layout settings have been reset';

  @override
  String get resetUISettings => 'Reset UI Settings';

  @override
  String get resetUISettingsConfirm =>
      'Reset all UI customization settings to default values.\n\nThis operation cannot be undone.\nAre you sure you want to proceed?';

  @override
  String get executeReset => 'Execute Reset';

  @override
  String get resetDetails => 'Reset Details';

  @override
  String get resetFunction => 'Reset Function';

  @override
  String get resetFunctionDescription =>
      '• Settings Reset: Theme, notifications, integration settings, etc.\n• Layout Reset: Grid size, card settings, etc.\n• UI Settings Reset: Card, button, input field customization settings\n• Data is Preserved: Links, tasks, and memos are not deleted\n• Details can be confirmed with the \"Reset Details\" button';

  @override
  String get resetDetailsTitle => 'Reset Details';

  @override
  String get resetDetailsDescription => 'Reset function detailed explanation:';

  @override
  String get resetToDefaultsStep => 'Reset to Defaults';

  @override
  String get resetToDefaultsStepDescription =>
      'The following settings will be reset to initial values:';

  @override
  String get themeSettingsReset => 'Theme Settings';

  @override
  String get themeSettingsResetValue =>
      'Dark Mode: OFF, Accent Color: Blue, Intensity: 100%, Contrast: 100%';

  @override
  String get notificationSettingsReset => 'Notification Settings';

  @override
  String get notificationSettingsResetValue =>
      'Notifications: ON, Notification Sound: ON';

  @override
  String get integrationSettingsReset => 'Integration Settings';

  @override
  String get integrationSettingsResetValue =>
      'Google Calendar: OFF, Gmail Integration: OFF, Outlook: OFF';

  @override
  String get backupSettingsReset => 'Backup Settings';

  @override
  String get backupSettingsResetValue => 'Auto Backup: ON, Interval: 7 days';

  @override
  String get resetLayoutSettingsStep => 'Reset Layout Settings';

  @override
  String get resetLayoutSettingsStepDescription =>
      'The following layout settings will be reset to initial values:';

  @override
  String get autoSync => 'Auto Sync';

  @override
  String get autoSyncDescription => 'Sync with Google Calendar periodically';

  @override
  String syncInterval(String minutes) {
    return 'Sync Interval: $minutes minutes';
  }

  @override
  String get bidirectionalSync => 'Bidirectional Sync';

  @override
  String get bidirectionalSyncDescription =>
      'Send app tasks to Google Calendar';

  @override
  String get showCompletedTasks => 'Show Completed Tasks';

  @override
  String get showCompletedTasksDescription =>
      'Display completed tasks from Google Calendar';

  @override
  String get credentialsFileFound => 'Credentials file found';

  @override
  String get credentialsFileNotFound => 'Credentials file not found';

  @override
  String get outlookSettingsInfo => 'Outlook Settings Info';

  @override
  String get autoLayoutAdjustmentDescription =>
      'Automatically adjust based on screen size';

  @override
  String get autoLayoutEnabledLabel => 'Auto Layout Enabled';

  @override
  String get manualLayoutSettings => 'Manual Layout Settings';

  @override
  String get animationEffectSettings => 'Animation & Effect Settings';

  @override
  String animationDuration(String ms) {
    return 'Animation Duration: ${ms}ms';
  }

  @override
  String spacing(String value) {
    return 'Spacing: ${value}px';
  }

  @override
  String darkModeContrastBoostPercent(String value) {
    return 'Dark Mode Contrast Boost: $value%';
  }

  @override
  String get taskProjectSettingsReset =>
      'Task project settings have been reset';

  @override
  String get backupFolderOpened => 'Backup folder opened';

  @override
  String get googleCalendar => 'Google Calendar';

  @override
  String get googleCalendarIntegration => 'Google Calendar Integration';

  @override
  String get googleCalendarIntegrationDescription =>
      'Sync Google Calendar events as tasks';

  @override
  String get gmailIntegrationAbout => 'About Gmail Integration';

  @override
  String get gmailIntegrationDescription =>
      'You can launch Gmail\'s compose screen from the task edit modal.\nNo API or access token configuration is required.\nIf you have a browser logged into your Google account, a new Gmail compose tab will open directly.';

  @override
  String get gmailUsage =>
      'Usage:\n1. Open the task edit modal\n2. Select Gmail in the email sending section\n3. Enter the recipient and click the \"Send Email\" button\n4. Gmail\'s compose screen will open, so check the content and send\n(Sending history is recorded on the task side)';

  @override
  String get outlookIntegration => 'Outlook Integration';

  @override
  String get outlookIntegrationAbout => 'About Outlook Integration';

  @override
  String get outlookIntegrationDescription =>
      'You can use email sending functionality using the Outlook API.';

  @override
  String get powershellFileDetails => 'PowerShell File Details';

  @override
  String get executableDirectory => 'Same directory as executable\\Apps';

  @override
  String get outlookConnectionTest => 'Outlook Connection Test';

  @override
  String get outlookConnectionTestDescription =>
      'Test connection with Outlook application';

  @override
  String get mailCompositionSupport => 'Mail Composition Support';

  @override
  String get mailCompositionSupportDescription =>
      'Support function for creating reply emails from tasks';

  @override
  String get sentMailSearch => 'Sent Mail Search';

  @override
  String get sentMailSearchDescription =>
      'Function to search and confirm sent emails';

  @override
  String get outlookCalendarEvents => 'Outlook Calendar Events';

  @override
  String get outlookCalendarEventsDescription =>
      'Function to retrieve events from Outlook calendar and assign them to tasks';

  @override
  String get portableVersion => 'Portable Version';

  @override
  String get installedVersion => 'Installed Version';

  @override
  String get manualExecution => 'Manual Execution';

  @override
  String get automaticExecution => 'Automatic Execution';

  @override
  String get importantNotes => 'Important Notes';

  @override
  String importantNotesContent(String portablePath, String installedPath) {
    return '• Administrator privileges are not required (can be executed at user level)\n• File names must match exactly\n• Manual permission is required if execution policy is restricted\n• May not work due to company PC security policies\n\n【Installation Location】Please place in one of the following:\n1. Portable Version: $portablePath\n2. Installed Version: $installedPath';
  }

  @override
  String get connectionTest => 'Connection Test';

  @override
  String get outlookPersonalCalendarAutoImport =>
      'Outlook Personal Calendar Auto Import';

  @override
  String get outlookSettingsInfoContent =>
      '• Required Permissions: Outlook Send\n• Supported Features: Email sending, automatic schedule import\n• Usage: Send emails from Outlook in task management, or enable auto import settings';

  @override
  String get googleCalendarSetupGuide => 'Google Calendar Setup Guide';

  @override
  String get googleCalendarSetupSteps =>
      'Setup steps for using Google Calendar API:';

  @override
  String get accessGoogleCloudConsole => 'Access Google Cloud Console';

  @override
  String get createOrSelectProject =>
      'Create a new project or select an existing project';

  @override
  String get enableGoogleCalendarAPI => 'Enable Google Calendar API';

  @override
  String get enableGoogleCalendarAPIDescription =>
      'Search for \"Google Calendar API\" in \"APIs & Services\" → \"Library\" and enable it';

  @override
  String get createOAuth2ClientID => 'Create OAuth2 Client ID';

  @override
  String get createOAuth2ClientIDDescription =>
      '\"APIs & Services\" → \"Credentials\" → \"Create Credentials\" → \"OAuth2 Client ID\" → \"Desktop Application\"';

  @override
  String get downloadCredentialsFile => 'Download Credentials File';

  @override
  String get downloadCredentialsFileDescription =>
      'Download the JSON file from the \"Download\" button of the created OAuth2 Client ID';

  @override
  String get placeFileInAppFolder => 'Place File in App Folder';

  @override
  String get placeFileInAppFolderDescription =>
      'Place the downloaded JSON file in the app folder as \"oauth2_credentials.json\"';

  @override
  String get executeOAuth2Authentication => 'Execute OAuth2 Authentication';

  @override
  String get executeOAuth2AuthenticationDescription =>
      'Click the \"Start OAuth2 Authentication\" button in the app to complete authentication';

  @override
  String get generatedFiles => 'Generated Files';

  @override
  String get exportOptions => 'Export Options';

  @override
  String get selectDataToExport => 'Please select the data to export:';

  @override
  String get linksOnly => 'Links Only';

  @override
  String get linksOnlyDescription => 'Export link data only';

  @override
  String get tasksOnly => 'Tasks Only';

  @override
  String get tasksOnlyDescription => 'Export task data only';

  @override
  String get both => 'Both';

  @override
  String get bothDescription => 'Export both links and tasks';

  @override
  String get importOptions => 'Import Options';

  @override
  String get selectDataToImport => 'Please select the data to import:';

  @override
  String get linksOnlyImportDescription => 'Import link data only';

  @override
  String get tasksOnlyImportDescription => 'Import task data only';

  @override
  String get bothImportDescription => 'Import both links and tasks';

  @override
  String exportCompleted(String filePath) {
    return 'Export completed\nSave location: $filePath';
  }

  @override
  String get exportCompletedTitle => 'Export Completed';

  @override
  String get exportError => 'Export Error';

  @override
  String exportErrorMessage(String error) {
    return 'Export error: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Could not open folder: $error';
  }

  @override
  String get ok => 'OK';

  @override
  String get selectFileToImport => 'Select File to Import';

  @override
  String importCompleted(int linksCount, int tasksCount, int groupsCount) {
    return 'Import completed\nLinks: $linksCount\nTasks: $tasksCount\nGroups: $groupsCount';
  }

  @override
  String get importCompletedTitle => 'Import Completed';

  @override
  String get importError => 'Import Error';

  @override
  String importErrorMessage(String error) {
    return 'Import error: $error';
  }

  @override
  String get oauth2AuthCompleted => 'OAuth2 authentication completed';

  @override
  String get thisFileContains =>
      'This file contains the following information:';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get waiting => 'Waiting';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncCompleted => 'Sync Completed';

  @override
  String get syncError => 'Sync Error';

  @override
  String lastSync(String time) {
    return 'Last Sync: $time';
  }

  @override
  String processingItems(int processed, int total) {
    return 'Processing $processed/$total items...';
  }

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String errorCode(String code) {
    return 'Error Code: $code';
  }

  @override
  String get partialSync => 'Partial Sync';

  @override
  String get partialSyncDescription =>
      'You can sync only selected tasks or tasks within a date range';

  @override
  String get individualTaskSyncInfo =>
      'To sync individual tasks, select \"Sync this task\" from the 3-dot menu of each task on the task screen.';

  @override
  String get syncByDateRange => 'Sync by Date Range';

  @override
  String get cleanupDuplicateEvents => 'Clean Up Duplicate Events';

  @override
  String get deleteOrphanedEvents => 'Delete Orphaned Events';

  @override
  String get orphanedEventsDeletion => 'Delete Orphaned Events';

  @override
  String get orphanedEventsDeletionDescription =>
      'Delete events in Google Calendar that do not exist in the app.\nUse this when events for tasks deleted in the app remain in Google Calendar.\n\nThis operation cannot be undone. Do you want to proceed?';

  @override
  String get executeDeletion => 'Execute Deletion';

  @override
  String get detectingOrphanedEvents => 'Detecting orphaned events...';

  @override
  String orphanedEventsDeletionCompleted(int count) {
    return 'Orphaned events deletion completed: $count deleted';
  }

  @override
  String orphanedEventsDeleted(int count) {
    return 'Deleted $count orphaned events';
  }

  @override
  String get noOrphanedEventsFound => 'No orphaned events found';

  @override
  String get orphanedEventsDeletionFailed => 'Orphaned events deletion failed';

  @override
  String get orphanedEventsDeletionError =>
      'An error occurred while deleting orphaned events';

  @override
  String get duplicateEventsCleanup => 'Duplicate Events Cleanup';

  @override
  String get duplicateEventsCleanupDescription =>
      'Detect and delete duplicate events in Google Calendar.\nIf there are multiple events with the same title and date, the older ones will be deleted.\n\nThis operation cannot be undone. Do you want to proceed?';

  @override
  String get executeCleanup => 'Execute Cleanup';

  @override
  String get detectingDuplicateEvents => 'Detecting duplicate events...';

  @override
  String duplicateCleanupCompleted(int found, int removed) {
    return 'Duplicate cleanup completed: $found groups detected, $removed deleted';
  }

  @override
  String duplicateEventsDeleted(int count) {
    return 'Deleted $count duplicate events';
  }

  @override
  String get noDuplicateEventsFound => 'No duplicate events found';

  @override
  String get duplicateCleanupFailed => 'Duplicate cleanup failed';

  @override
  String get duplicateCleanupError =>
      'An error occurred during duplicate cleanup';

  @override
  String get checkSetupMethod => 'Check Setup Method';

  @override
  String get authStartFailed => 'Failed to start authentication';

  @override
  String get storageLocation => 'Storage Location';

  @override
  String get executionMethod => 'Execution Method';

  @override
  String get startOAuth2Authentication => 'Start OAuth2 Authentication';

  @override
  String get appToGoogleCalendarSync => 'App → Google Calendar Sync';

  @override
  String appToGoogleCalendarSyncCompleted(
    int created,
    int updated,
    int deleted,
  ) {
    return 'App → Google Calendar sync completed: $created created, $updated updated, $deleted deleted';
  }

  @override
  String get googleCalendarToAppSync => 'Google Calendar → App Sync';

  @override
  String googleCalendarToAppSyncCompleted(int added, int skipped) {
    return 'Google Calendar → App sync completed: $added added, $skipped skipped';
  }

  @override
  String syncErrorMessage(String error) {
    return 'Sync error: $error';
  }

  @override
  String errorColon(String error) {
    return 'Error: $error';
  }

  @override
  String screenshotLoadFailed(String path) {
    return 'Failed to load screenshot.\nPlease place the image in the assets/help folder.\n($path)';
  }

  @override
  String get bulkLinkAssignment => 'Bulk Link Assignment';

  @override
  String get addDescription => 'Add to existing links';

  @override
  String get remove => 'Remove';

  @override
  String get removeDescription => 'Remove specified links';

  @override
  String get replace => 'Replace';

  @override
  String get replaceDescription => 'Replace all existing links';

  @override
  String get noLinksAvailable => 'No links available';

  @override
  String tasksMerged(int count) {
    return 'Merged $count tasks';
  }

  @override
  String get mergeTask => 'Merge Tasks';

  @override
  String get selectTargetTask => 'Please select the target task:';

  @override
  String get mergeTaskConfirm => 'Merge Tasks';

  @override
  String get mergeTaskConfirmDescription =>
      'Schedules, subtasks, memos, links, and tags from the source task will be merged.\nThe source task will be marked as completed.';

  @override
  String mergeTaskConfirmMessage(String title, int count, String description) {
    return 'Merge $count tasks into \"$title\"?\n\n$description';
  }

  @override
  String get dropToAdd => 'Drop here to add';

  @override
  String get noLinksDragToAdd => 'No links\nDrag here to add';

  @override
  String get noLinksYet => 'No links yet';

  @override
  String get merge => 'Merge';

  @override
  String get apply => 'Apply';

  @override
  String get dueDateBulkChange => 'Bulk Change Due Date';

  @override
  String get notSelected => 'Not Selected';

  @override
  String get bulkTagOperation => 'Bulk Tag Operation';

  @override
  String get addTagDescription => 'Add to existing tags';

  @override
  String get removeTagDescription => 'Remove specified tags';

  @override
  String get someFilesNotRegistered =>
      'Some files/folders could not be accessed and were not registered';

  @override
  String get folderIsEmpty => 'フォルダが空です';

  @override
  String get accessDeniedOrOtherError => 'アクセス権限がないか、その他のエラーが発生しました';

  @override
  String get doesNotExist => '存在しません';

  @override
  String get editMemo => 'Edit Memo';

  @override
  String get enterMemo => 'Enter memo...';

  @override
  String get emptyMemoDeletes => 'Leave empty to delete the memo';

  @override
  String currentMemo(String memo) {
    return 'Current Memo: $memo';
  }

  @override
  String get contentList => 'Content List';

  @override
  String get clickChapterToJump =>
      'Click on the chapter you are interested in to jump!';

  @override
  String get searchByKeyword => 'Search by keyword';

  @override
  String manualLoadFailed(String error) {
    return 'Failed to load manual: $error';
  }

  @override
  String screenshotNotRegistered(String id) {
    return 'Screenshot \"$id\" is not registered.';
  }

  @override
  String videoNotRegistered(String id) {
    return 'Video \"$id\" is not registered. Please check the assets/help/videos folder.';
  }

  @override
  String get manualNotLoaded => 'Manual is not loaded';

  @override
  String get reload => 'Reload';

  @override
  String get retry => 'Retry';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get helpContentNotFound => 'Help content not found.';

  @override
  String get linkNavigatorManual => 'Link Navigator Manual';

  @override
  String get helpCenterGuide =>
      'A guide to help you master the app quickly. Select items of interest from the left navigation.';

  @override
  String get htmlExport => 'Export HTML / Print';

  @override
  String htmlExportFailed(String error) {
    return 'Failed to export HTML: $error';
  }

  @override
  String filesAdded(int count) {
    return 'Added $count file(s)';
  }

  @override
  String foldersAdded(int count) {
    return 'Added $count folder(s)';
  }

  @override
  String linksAdded(int count) {
    return 'Added $count link(s)';
  }

  @override
  String itemsAdded(String files, String folders, String links) {
    return '$files、$folders、$links';
  }

  @override
  String get label => 'Label';

  @override
  String get linkLabelHint => 'Enter link label...';

  @override
  String get pathUrl => 'Path/URL';

  @override
  String get pathUrlHint => 'Enter file path or URL...';

  @override
  String get tagsHint =>
      'Enter comma-separated (e.g., Work, Important, Project A)';

  @override
  String get faviconUrlHint => 'Example: https://www.resonabank.co.jp/';

  @override
  String get icon => 'Icon: ';

  @override
  String get noNameSet => 'No Name Set';

  @override
  String get get => 'Get';

  @override
  String get getSchedulesConfirm => 'Do you want to retrieve schedules?';

  @override
  String schedulesRetrieved(int total, int added, int skipped) {
    return 'Retrieved: $total items\nAdded: $added items\nSkipped: $skipped items';
  }

  @override
  String schedulesRetrievedNoAdd(int total, int skipped) {
    return 'Retrieved: $total items\nAdded: 0 items\nSkipped: $skipped items (already imported)';
  }

  @override
  String schedulesRetrievedNoSchedule(int total) {
    return 'Retrieved: $total items\nNo schedules to import';
  }

  @override
  String get outlookScheduleRetrieval => 'Outlook Schedule Retrieval';

  @override
  String get faviconFallbackDomain => 'Favicon Fallback Domain';

  @override
  String get faviconFallbackHelper =>
      'Set the domain to use when favicon retrieval fails';

  @override
  String get outlookAutoImportCompleted => 'Outlook Auto Import Completed';

  @override
  String uiDensity(String percent) {
    return 'UI Density: $percent%';
  }

  @override
  String get changePriorityMenu => 'Change Priority';

  @override
  String get changeDueDateMenu => 'Change Due Date';

  @override
  String get manageTagsMenu => 'Manage Tags';

  @override
  String get assignLinkMenu => 'Assign Link';

  @override
  String get combineTasksMenu => 'Combine Tasks';

  @override
  String get dragAndDrop => 'Drag & Drop';

  @override
  String get googleIntegration => 'Google Integration';

  @override
  String get notificationsAlerts => 'Notifications & Alerts';

  @override
  String get colorTheme => 'Color Theme';

  @override
  String get shortcuts => 'Shortcuts';

  @override
  String get selectColumnsToExport => 'Select Columns to Export to CSV';

  @override
  String get groupByDueDate => 'Group by Due Date';

  @override
  String get groupByTag => 'Group by Tag';

  @override
  String get groupByProjectLink => 'Group by Project (Link)';

  @override
  String get groupByPriority => 'Group by Priority';

  @override
  String get assignee => 'Assignee';

  @override
  String get returnToLinkManagementScreen => 'Return to Link Management Screen';

  @override
  String get templateDeleteConfirm => 'Delete Template';

  @override
  String templateDeleteMessage(String name) {
    return 'Do you want to delete \"$name\"?';
  }

  @override
  String get templateNameRequired => 'Please enter a template name';

  @override
  String get titleRequired => 'Please enter a title';

  @override
  String get templateSaved => 'Template saved';

  @override
  String get csvColumnId => 'ID';

  @override
  String get csvColumnTitle => 'Title';

  @override
  String get csvColumnDescription => 'Description';

  @override
  String get csvColumnDueDate => 'Due Date';

  @override
  String get csvColumnReminderTime => 'Reminder Time';

  @override
  String get csvColumnPriority => 'Priority';

  @override
  String get csvColumnStatus => 'Status';

  @override
  String get csvColumnTags => 'Tags';

  @override
  String get csvColumnRelatedLinkId => 'Related Link ID';

  @override
  String get csvColumnCreatedAt => 'Created Date';

  @override
  String get csvColumnCompletedAt => 'Completed Date';

  @override
  String get csvColumnStartedAt => 'Started Date';

  @override
  String get csvColumnCompletedAtManual => 'Completed Date (Manual Entry)';

  @override
  String get csvColumnEstimatedMinutes => 'Estimated Minutes';

  @override
  String get csvColumnNotes => 'Notes';

  @override
  String get csvColumnIsRecurring => 'Recurring Task';

  @override
  String get csvColumnRecurringPattern => 'Recurring Pattern';

  @override
  String get csvColumnIsRecurringReminder => 'Recurring Reminder';

  @override
  String get csvColumnRecurringReminderPattern => 'Recurring Reminder Pattern';

  @override
  String get csvColumnNextReminderTime => 'Next Reminder Time';

  @override
  String get csvColumnReminderCount => 'Reminder Count';

  @override
  String get csvColumnHasSubTasks => 'Has Subtasks';

  @override
  String get csvColumnCompletedSubTasksCount => 'Completed Subtasks Count';

  @override
  String get csvColumnTotalSubTasksCount => 'Total Subtasks Count';

  @override
  String get mailSending => 'Mail Sending';

  @override
  String get copyRequestorMemoToBody => 'Copy \"Requestor and Memo\" to body';

  @override
  String get includeSubtasksInBody => 'Include subtasks in body';

  @override
  String get sendingApp => 'Sending App:';

  @override
  String get recipientSelection => 'Recipient Selection';

  @override
  String get addContact => 'Add Contact';

  @override
  String get selectFromSendHistory => 'Select from Send History';

  @override
  String get frequentlyUsedContacts => 'Frequently Used Contacts:';

  @override
  String get emptyMailerCanLaunch => 'Mailer will launch even if empty';

  @override
  String get emptyCanSpecifyAddress =>
      '※If empty, you can specify the address directly in the mailer';

  @override
  String get mailerLaunchInstruction =>
      '※First, please open the mailer with the \"Launch Mailer\" button';

  @override
  String get mailerSendInstruction =>
      '※After sending the email in the mailer, please press the \"Mail Sent Complete\" button';

  @override
  String get taskRelatedMail => 'Task Related Mail';

  @override
  String mailComposeOpened(String app) {
    return 'Opened $app mail compose screen.\nAfter sending the email, please press the \"Mail Sent Complete\" button.';
  }

  @override
  String mailerLaunchError(String error) {
    return 'Mailer launch error: $error';
  }

  @override
  String get pleaseLaunchMailerFirst =>
      'Please press the \"Launch Mailer\" button first';

  @override
  String get mailSentRecorded => 'Mail sent recorded';

  @override
  String mailSentRecordError(String error) {
    return 'Mail sent record error: $error';
  }

  @override
  String get outlookConnectionTestSuccess =>
      'Outlook connection test successful';

  @override
  String get outlookConnectionTestFailed =>
      'Outlook connection test failed: Outlook is not available';

  @override
  String outlookConnectionTestError(String error) {
    return 'Outlook connection test error: $error';
  }

  @override
  String powershellScriptNotFound(
    String scriptName,
    String portablePath,
    String installedPath,
  ) {
    return 'PowerShell script not found: $scriptName\n\nPlease place it in one of the following locations:\n1. Portable version: $portablePath\n2. Installed version: $installedPath';
  }

  @override
  String get name => 'Name';

  @override
  String get nameRequired => 'Please enter a name';

  @override
  String get gmailLaunchFailed => 'Failed to launch Gmail';

  @override
  String outlookNotInstalled(String details) {
    return 'Outlook is not installed or not properly configured.\nPlease use Outlook on a company PC.\nDetails: $details';
  }

  @override
  String outlookLaunchFailed(String error) {
    return 'Failed to launch Outlook: $error';
  }

  @override
  String outlookSearchFailed(String error) {
    return 'Outlook search failed: $error';
  }

  @override
  String unsupportedMailApp(String app) {
    return 'Unsupported mail app: $app';
  }

  @override
  String powershellTimeout(int seconds) {
    return 'PowerShell execution timed out ($seconds seconds)';
  }

  @override
  String powershellScriptError(String error) {
    return 'PowerShell script execution error: $error';
  }

  @override
  String powershellExecutionFailed(int retries) {
    return 'PowerShell execution failed (all $retries attempts)';
  }

  @override
  String get unexpectedJsonFormat => 'Unexpected JSON format';

  @override
  String startDateParseError(String date) {
    return 'Start date parse error: $date';
  }

  @override
  String get oauth2CredentialsNotFound =>
      'OAuth2 credentials file not found. Please check the setup method.';

  @override
  String get invalidCredentialsFormat =>
      'Invalid credentials file format. Please use OAuth2 desktop app credentials.';

  @override
  String get clientIdNotSet => 'client_id is not set in the credentials file.';

  @override
  String get authUrlOpenFailed => 'Failed to open authentication URL';

  @override
  String get noValidAccessToken =>
      'No valid access token. Please execute OAuth2 authentication.';

  @override
  String googleCalendarEventFetchFailed(int statusCode) {
    return 'Failed to fetch Google Calendar events: $statusCode';
  }

  @override
  String eventDeleteFailed(int statusCode) {
    return 'Failed to delete event: $statusCode';
  }

  @override
  String get backupValidationFailed => 'Backup file validation failed';

  @override
  String backupBeforeOperationFailed(String error) {
    return 'Backup before operation failed: $error';
  }

  @override
  String get invalidBackupDataFormat => 'Invalid backup data format';

  @override
  String get invalidBackupFile => 'Invalid backup file';

  @override
  String emailAlreadyRegistered(String email) {
    return 'This email address is already registered: $email';
  }

  @override
  String contactNotFound(String id) {
    return 'Contact not found: $id';
  }

  @override
  String outlookEventFetchFailed(String error) {
    return 'Failed to fetch events from Outlook. Please try again later.\nError: $error';
  }

  @override
  String get outlookEventFetchFailedInfo =>
      'Failed to fetch events from Outlook. Please try again later.';

  @override
  String get tokenExtractionFailed => 'Failed to extract token';

  @override
  String get taskNotSelected => 'Task is not selected';

  @override
  String get noSendHistoryForTask => 'This task has no send history';

  @override
  String get sendHistoryReused => 'Send history reused';

  @override
  String get gmailConnectionTest => 'Gmail Connection Test';

  @override
  String get gmailConnectionTestBody => 'This is a Gmail connection test.';

  @override
  String get gmailConnectionTestSuccess =>
      'Gmail connection test successful: Gmail opened';

  @override
  String gmailConnectionTestError(String error) {
    return 'Gmail connection test error: $error';
  }

  @override
  String get testMailSent => 'Test mail sent';

  @override
  String testMailSendError(String error) {
    return 'Test mail send error: $error';
  }

  @override
  String get noSendHistory => 'No send history';

  @override
  String get sendHistoryAutoRegister =>
      'When you send an email, the recipient will be automatically registered as a contact';

  @override
  String get latestMail => '🆕 Latest mail';

  @override
  String get oldestMail => '⭐ First mail';

  @override
  String get sentColon => 'Sent:';

  @override
  String get subjectColon => 'Subject:';

  @override
  String get toColon => 'To:';

  @override
  String get bodyColon => 'Body:';

  @override
  String get taskLabel => 'Task:';

  @override
  String get relatedTaskInfo => '[Related Task Information]';

  @override
  String get mailInfo => '[Mail Information]';

  @override
  String get sentDateTime => 'Sent Date/Time';

  @override
  String get sentId => 'Sent ID:';

  @override
  String get noMessage => 'No message.';

  @override
  String get noTaskInfo => 'No task information.';

  @override
  String get linksLabel => 'Links:';

  @override
  String get relatedMaterials => '[Related Materials]';

  @override
  String get subtaskProgress => 'Subtask Progress:';

  @override
  String get completedLabel => 'Completed:';

  @override
  String get thisMailSentFromApp =>
      'This email was sent from the Link Navigator app.';

  @override
  String get taskInfoHeader => '📋 Task Information';

  @override
  String get relatedMaterialsLabel => 'Related Materials:';

  @override
  String get gmailLinkNote =>
      '📝 Note: Network share and local file links cannot be clicked directly in Gmail.\nPlease copy the link and paste it into File Explorer or your browser\'s address bar to access it.';

  @override
  String get outlookLinkNote =>
      '📝 Note: In Outlook, network share and local file links are also clickable.\nYou can click the link to access it directly.';

  @override
  String get periodLabel => 'Period:';

  @override
  String get startLabel => 'Start:';

  @override
  String get endLabel => 'End:';

  @override
  String get getSchedules => 'Get Schedules';

  @override
  String get searchSchedules => 'Search schedules...';

  @override
  String get sortByTitle => 'By Title';

  @override
  String get sortByDateTime => 'By Date/Time';

  @override
  String get processing => 'Processing...';

  @override
  String assignToTasks(int count) {
    return 'Assign to Tasks ($count items)';
  }

  @override
  String linkOpened(String label) {
    return 'Opened link \"$label\"';
  }

  @override
  String get linkNotFound => 'Link not found';

  @override
  String get completionDateColon => 'Completion Date:';

  @override
  String get completedColon => 'Completed:';

  @override
  String get copyToExcelOneCellForm => 'Copy to Excel (One Cell Form)';

  @override
  String get excelCopyOnlyInListView =>
      'Excel copy is only available in list view.';

  @override
  String schedulesCopiedToExcel(int count, String format) {
    return 'Copied $count schedules to clipboard in $format format (can be pasted into Excel)';
  }

  @override
  String schedulesCopiedToExcelOneCell(int count) {
    return 'Copied $count schedules to clipboard in one cell form (can be pasted into Excel)';
  }

  @override
  String get oneCellForm => 'One Cell Form';

  @override
  String get tableForm => 'Table Form';

  @override
  String get importOutlookSchedules => 'Import Outlook Schedules';

  @override
  String get noSchedulesToImport => 'No schedules to import';

  @override
  String get meeting => 'Meeting';

  @override
  String get recurring => 'Recurring';

  @override
  String get online => 'Online';

  @override
  String get noMatchingTasks => 'No matching tasks';

  @override
  String get outlookUnavailableSkipped =>
      'Skipped automatic import because Outlook is unavailable';

  @override
  String outlookAutoImportCompletedDetails(int total, int added, int skipped) {
    return 'Outlook auto import completed\nRetrieved: $total items\nAdded: $added items\nSkipped: $skipped items';
  }

  @override
  String outlookAutoImportCompletedNoNew(int total) {
    return 'Outlook auto import completed\nRetrieved: $total items\nNo schedules to import';
  }

  @override
  String outlookAutoImportCompletedSkipped(int total, int skipped) {
    return 'Outlook auto import completed\nRetrieved: $total items\nAdded: 0 items\nSkipped: $skipped items (already imported)';
  }

  @override
  String outlookAutoImportCompletedAdded(int added) {
    return 'Outlook auto import completed: Added $added schedules';
  }

  @override
  String outlookAutoImportCompletedSkippedOnly(int skipped) {
    return 'Outlook auto import completed: $skipped schedules are already imported';
  }

  @override
  String outlookAutoImportError(String error) {
    return 'An error occurred during Outlook auto import.\nError: $error';
  }

  @override
  String get selectDateToCopy => 'Please select the date to copy';

  @override
  String get taskNotFound => 'Task not found';

  @override
  String get relatedTaskNotFound => 'Related task not found';

  @override
  String get excelHeaderDate => 'Date';

  @override
  String get excelHeaderStartTime => 'Start Time';

  @override
  String get excelHeaderEndTime => 'End Time';

  @override
  String get excelHeaderTitle => 'Title';

  @override
  String get excelHeaderLocation => 'Location';

  @override
  String get excelHeaderTaskName => 'Task Name';

  @override
  String get gettingSchedulesFromOutlook => 'Getting schedules from Outlook...';

  @override
  String get gettingSchedules => 'Getting schedules...';

  @override
  String get outlookNotRunningOrUnavailable =>
      'Outlook is not running or unavailable. Please start Outlook and try again.';

  @override
  String get noSchedulesThisMonth => 'No schedules in this month';

  @override
  String get scheduleShortcuts => 'Schedule Shortcuts';

  @override
  String get focusSearchBar => 'Focus on search bar';

  @override
  String get selectIconAndColor => 'Select Icon and Color';

  @override
  String get selectColor => 'Select Color:';

  @override
  String get preview => 'Preview:';

  @override
  String get decide => 'Confirm';

  @override
  String otherSubTasks(int count) {
    return 'Other $count';
  }

  @override
  String get iconGlobe => 'Globe';

  @override
  String get iconFolder => 'Folder';

  @override
  String get iconFolderOpen => 'Open Folder';

  @override
  String get iconFolderSpecial => 'Special Folder';

  @override
  String get iconFolderShared => 'Shared Folder';

  @override
  String get iconFolderZip => 'Zip Folder';

  @override
  String get iconFolderCopy => 'Copy Folder';

  @override
  String get iconFolderDelete => 'Delete Folder';

  @override
  String get iconFolderOff => 'Disabled Folder';

  @override
  String get iconFolderOutlined => 'Folder (Outlined)';

  @override
  String get iconFolderOpenOutlined => 'Open Folder (Outlined)';

  @override
  String get iconFolderSpecialOutlined => 'Special Folder (Outlined)';

  @override
  String get iconFolderSharedOutlined => 'Shared Folder (Outlined)';

  @override
  String get iconFolderZipOutlined => 'Zip Folder (Outlined)';

  @override
  String get iconFolderCopyOutlined => 'Copy Folder (Outlined)';

  @override
  String get iconFolderDeleteOutlined => 'Delete Folder (Outlined)';

  @override
  String get iconFolderOffOutlined => 'Disabled Folder (Outlined)';

  @override
  String get iconFolderUpload => 'Upload Folder';

  @override
  String get iconFolderUploadOutlined => 'Upload Folder (Outlined)';

  @override
  String get iconFileMove => 'Move File';

  @override
  String get iconFileMoveOutlined => 'Move File (Outlined)';

  @override
  String get iconFileRename => 'Rename File';

  @override
  String get iconFileRenameOutlined => 'Rename File (Outlined)';

  @override
  String associateLinksWithTask(String title) {
    return 'Associate links with task \"$title\"';
  }

  @override
  String existingRelatedLinks(int count) {
    return 'Existing related links ($count)';
  }

  @override
  String get clickToExpandAndDelete => 'Click to expand and delete';

  @override
  String get selectLinkToAssociate =>
      'Please select the link you want to associate:';

  @override
  String get searchLinks => 'Search for links...';

  @override
  String selectedLinks(int selected, int existing) {
    return 'Selected links: $selected (Existing: $existing)';
  }

  @override
  String linkedLinksNotFound(int count) {
    return 'Linked links not found ($count link IDs exist)';
  }

  @override
  String get linkDeleted => 'Link deleted';

  @override
  String linkDeletionFailed(String error) {
    return 'Link deletion failed: $error';
  }

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String linkList(int count) {
    return 'Link list: $count';
  }

  @override
  String get linkAssociationUpdated => 'Link association updated';

  @override
  String linkAssociationUpdateFailed(String error) {
    return 'Link association update failed: $error';
  }

  @override
  String get orphanedSchedules => 'Orphaned Schedules';

  @override
  String get orphanedSchedulesDescription =>
      'Task to collect schedules that were linked to non-existent tasks.';

  @override
  String get systemGenerated => 'System Generated';

  @override
  String itemsCountShort(int count) {
    return '$count';
  }

  @override
  String schedulesAssigned(int count) {
    return 'Assigned $count schedules';
  }

  @override
  String tasksCreatedAndSchedulesAssigned(int count) {
    return 'Created $count tasks and assigned schedules';
  }

  @override
  String itemsDisplayed(int count) {
    return '$count displayed';
  }

  @override
  String candidateTasksFound(int count) {
    return 'Found $count candidate tasks';
  }

  @override
  String get changeAssignedTask => 'Change Assigned Task';

  @override
  String get noAssignableTasks => 'No assignable tasks available';

  @override
  String get noOtherTasks => 'No other tasks available';

  @override
  String scheduleAssignedToTask(String scheduleTitle, String taskTitle) {
    return 'Assigned \"$scheduleTitle\" to \"$taskTitle\"';
  }

  @override
  String scheduleTaskAssignmentChangeError(String error) {
    return 'Task assignment change error: $error';
  }

  @override
  String get scheduleTaskAssignmentChangeFailed =>
      'Failed to change schedule task assignment.';

  @override
  String get edit => 'Edit';

  @override
  String get scheduleCopiedAndAdded => 'Schedule copied and added';

  @override
  String get dragOrderManual => 'Drag Order (Manual)';

  @override
  String get memoPad => 'Memo Pad';

  @override
  String get newMemo => 'New Memo';

  @override
  String get deleteMemo => 'Delete Memo';

  @override
  String get deleteMemoConfirm => 'Are you sure you want to delete this memo?';

  @override
  String get memoContentHint => 'Enter memo content...';

  @override
  String get searchMemos => 'Search memos...';

  @override
  String get noMemos => 'No memos';

  @override
  String get noMemosFound => 'No matching memos found';

  @override
  String get memoAdded => 'Memo added';

  @override
  String get memoUpdated => 'Memo updated';

  @override
  String get memoDeleted => 'Memo deleted';

  @override
  String memoSaveError(String error) {
    return 'Failed to save memo: $error';
  }

  @override
  String memoDeleteError(String error) {
    return 'Failed to delete memo: $error';
  }

  @override
  String get memoAddFailed => 'Failed to add memo';

  @override
  String get memoUpdateFailed => 'Failed to update memo';

  @override
  String get memoDeleteFailed => 'Failed to delete memo';

  @override
  String get noTasks => 'No tasks';

  @override
  String get clickToEditAndDragToReorder =>
      'Click to edit\nDrag icon to change order';

  @override
  String get reminderDate => 'Reminder Date';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get selectReminderDate => 'Select Reminder Date';

  @override
  String get selectTime => 'Select Time';

  @override
  String get exportLinksToExcel => 'Export Links to Excel';

  @override
  String get exportLinksToExcelShortcut => 'Export Links to Excel';

  @override
  String get selectGroupsToExport => 'Select Groups to Export';

  @override
  String linksExported(String filePath) {
    return 'Links exported to Excel: $filePath';
  }

  @override
  String linksExportFailed(String error) {
    return 'Failed to export links: $error';
  }

  @override
  String get excelHyperlinkActivationTitle => 'How to Activate Hyperlinks';

  @override
  String get excelHyperlinkActivationDescription =>
      'If hyperlinks are displayed as text strings in the exported Excel file, you can activate them all at once using the following steps:';

  @override
  String get excelHyperlinkActivationStep1 =>
      'Select the Link column (Column C)';

  @override
  String get excelHyperlinkActivationStep2 =>
      'Press Ctrl + H to open the \"Find and Replace\" dialog';

  @override
  String get excelHyperlinkActivationStep3 =>
      'Enter \"=HYPERLINK\" in the \"Find what\" field';

  @override
  String get excelHyperlinkActivationStep4 =>
      'Enter \"=HYPERLINK\" in the \"Replace with\" field and click \"Replace All\"';

  @override
  String get excelHyperlinkActivationNote =>
      'This will cause Excel to re-evaluate the formulas and activate the hyperlinks. The instructions are also documented in the \"How to Activate Hyperlinks\" sheet in the Excel file.';

  @override
  String get excelLinksSheetName => 'Links';

  @override
  String get excelHyperlinkActivationSheetName => 'How to Activate Hyperlinks';

  @override
  String get excelColumnGroupName => 'Group Name';

  @override
  String get excelColumnLabel => 'Label';

  @override
  String get excelColumnLink => 'Link';

  @override
  String get excelColumnMemo => 'Memo';

  @override
  String get excelSecurityWarningTitle => 'About Security Warnings';

  @override
  String get excelSecurityWarningDescription =>
      'When you click a hyperlink, Excel may display a security warning. This is Excel\'s standard security feature for links to local files or network paths.';

  @override
  String get excelSecurityWarningSolution =>
      'If a warning appears, click \"Yes\" to continue. Links to trusted files are safe.';

  @override
  String get officialWebsite => 'Official Website';

  @override
  String get officialWebsiteDescription =>
      'For detailed information, screenshots, and demo videos, please visit our official website.';

  @override
  String get openWebsite => 'Open Website';

  @override
  String get noGroupsSelected => 'No groups selected';

  @override
  String get completionReport => 'Completion Report';

  @override
  String get scheduleEditAvailableAfterTaskCreation =>
      '※ Schedule editing will be available after task creation';

  @override
  String get scheduleOverlap => 'Schedule Overlap';

  @override
  String get overlappingSchedulesMessage =>
      'The following schedules overlap in time:';

  @override
  String get time => 'Time';

  @override
  String get completionNotes => 'Completion Notes';

  @override
  String get completionNotesHint => 'Enter completion details and results';

  @override
  String get completionNotesRequired => 'Please enter completion notes';

  @override
  String get sendCompletionReport => 'Send Completion Report';

  @override
  String get clearReminder => 'Clear Reminder';

  @override
  String get recurringReminder => 'Recurring Reminder';

  @override
  String selectWithCount(int count) {
    return 'Select ($count)';
  }

  @override
  String get to => 'To';

  @override
  String get app => 'App';

  @override
  String get bulkAssignLinks => 'Bulk Assign Links';

  @override
  String get replaceAllTags => 'Replace all existing tags';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get mailAction => 'Mail Action';

  @override
  String get selectMailAction =>
      'Please select a mail action related to this task.';

  @override
  String get reply => 'Reply';

  @override
  String get showMoreCandidates => 'Show More Candidates';

  @override
  String get selectTask => 'Select Task';

  @override
  String get createTaskFirstToAddSchedule =>
      'Please create a task first to add a schedule';

  @override
  String get scheduleCopied => 'Schedule copied';

  @override
  String get scheduleDeleted => 'Schedule deleted';

  @override
  String scheduleFetchFailed(String error) {
    return 'Failed to fetch schedules: $error';
  }

  @override
  String scheduleAssignmentFailed(String title, String error) {
    return 'Failed to assign schedule \"$title\": $error';
  }

  @override
  String taskCreationFailed(String error) {
    return 'Failed to create task: $error';
  }

  @override
  String get needAtLeastTwoGroups =>
      'At least two groups are required to change the order';

  @override
  String get createTaskFirst => 'Please create a task first';

  @override
  String get subTaskTitleRequired => 'Sub task title is required';

  @override
  String historyFetchError(String error) {
    return 'History fetch error: $error';
  }

  @override
  String get completionReportSent => 'Completion report sent';

  @override
  String completionReportSendError(String error) {
    return 'Completion report send error: $error';
  }
}
