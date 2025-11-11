import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/schedule_item.dart';
import '../models/task_item.dart';
import '../viewmodels/schedule_viewmodel.dart';
import '../viewmodels/task_viewmodel.dart';
import 'task_dialog.dart';
import 'home_screen.dart'; // HighlightedText用
import 'outlook_calendar_import_dialog_v2.dart';
import '../widgets/shortcut_help_dialog.dart';
import '../services/snackbar_service.dart';

enum ScheduleCalendarView { list, week, month }

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _OpenShortcutIntent extends Intent {
  const _OpenShortcutIntent();
}

class ScheduleCalendarScreen extends ConsumerStatefulWidget {
  const ScheduleCalendarScreen({super.key});

  @override
  ConsumerState<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends ConsumerState<ScheduleCalendarScreen> {
  bool _localeInitialized = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // 日付範囲フィルター: 'future'（デフォルト）、'past'
  String _dateFilter = 'future'; // デフォルトは未来のみ
  
  // 過去表示チェックボックス
  bool _showPast = false;
  
  // 選択された日付（エクセルコピー用）
  Set<DateTime> _selectedDates = {};
  
  // タスク別フィルター
  String? _selectedTaskId;
  
  // 検索クエリ
  String _searchQuery = '';
  
  // 今日の日付の位置を保持
  GlobalKey? _todayKey;
  ScheduleCalendarView _currentView = ScheduleCalendarView.list;

  @override
  void initState() {
    super.initState();
    // 日本語ロケールを初期化
    _initializeLocale();
    // 画面表示時にデータを再読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = ref.read(scheduleViewModelProvider.notifier);
      await vm.waitForInitialization();
      // 初期化完了後にデータを再読み込み
      if (mounted) {
        // データベースから最新のデータを読み込む
        await vm.loadSchedules();
        // Riverpodの状態を強制的に更新
        if (mounted) {
          ref.invalidate(scheduleViewModelProvider);
          // 今日の位置にジャンプ
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToToday();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeLocale() async {
    if (!_localeInitialized) {
      await initializeDateFormatting('ja_JP', null);
      _localeInitialized = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(scheduleViewModelProvider);
    final tasks = ref.watch(taskViewModelProvider);
    final now = DateTime.now();
    
    // タスク別フィルターを適用
    List<ScheduleItem> taskFilteredSchedules = schedules;
    if (_selectedTaskId != null) {
      taskFilteredSchedules = schedules.where((s) => s.taskId == _selectedTaskId).toList();
    }
    
    // 日付範囲フィルターを適用（未来/過去のみ）
    final filteredSchedules = taskFilteredSchedules.where((schedule) {
      if (_dateFilter == 'future') {
        return schedule.startDateTime.isAfter(now);
      } else if (_dateFilter == 'past') {
        return schedule.startDateTime.isBefore(now);
      }
      return true; // 'all'
    }).toList();
    
    // 検索フィルターを適用
    final searchFilteredSchedules = _searchQuery.isEmpty
        ? filteredSchedules
        : filteredSchedules.where((schedule) {
            final task = tasks.firstWhere(
              (t) => t.id == schedule.taskId,
              orElse: () => TaskItem(
                id: schedule.taskId,
                title: '',
                createdAt: DateTime.now(),
              ),
            );
            final queryLower = _searchQuery.toLowerCase();
            return schedule.title.toLowerCase().contains(queryLower) ||
                task.title.toLowerCase().contains(queryLower) ||
                (schedule.location != null && schedule.location!.toLowerCase().contains(queryLower));
          }).toList();
    
    // 日付ごとにグループ化
    final schedulesByDate = <DateTime, List<ScheduleItem>>{};
    for (final schedule in searchFilteredSchedules) {
      final dateKey = DateTime(
        schedule.startDateTime.year,
        schedule.startDateTime.month,
        schedule.startDateTime.day,
      );
      if (!schedulesByDate.containsKey(dateKey)) {
        schedulesByDate[dateKey] = [];
      }
      schedulesByDate[dateKey]!.add(schedule);
    }

    // 日付順にソート
    final sortedDates = schedulesByDate.keys.toList()..sort();

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.f1): const _OpenShortcutIntent(),
      },
      child: Actions(
        actions: {
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (intent) {
              _focusSearchField();
              return null;
            },
          ),
          _OpenShortcutIntent: CallbackAction<_OpenShortcutIntent>(
            onInvoke: (intent) {
              _showShortcutGuide(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
      appBar: AppBar(
        title: const Text('予定表'),
        actions: [
          Tooltip(
            message: 'ショートカット一覧 (F1)',
            child: IconButton(
              icon: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
              onPressed: () => _showShortcutGuide(context),
            ),
          ),
          PopupMenuButton<ScheduleCalendarView>(
            tooltip: '表示切り替え',
            icon: Icon(
              _currentView == ScheduleCalendarView.list
                  ? Icons.view_list
                  : _currentView == ScheduleCalendarView.week
                      ? Icons.view_week
                      : Icons.calendar_month,
              color: Theme.of(context).colorScheme.primary,
            ),
            onSelected: (layout) {
              setState(() {
                _currentView = layout;
                _todayKey = null;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ScheduleCalendarView.list,
                child: Row(
                  children: [
                    Icon(Icons.view_list),
                    SizedBox(width: 8),
                    Text('リスト表示'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ScheduleCalendarView.week,
                child: Row(
                  children: [
                    Icon(Icons.view_week),
                    SizedBox(width: 8),
                    Text('週次表示'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ScheduleCalendarView.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('月次表示'),
                  ],
                ),
              ),
            ],
          ),
          // 一括選択ボタン
          if (_selectedDates.isNotEmpty || sortedDates.isNotEmpty)
            IconButton(
              icon: Icon(_selectedDates.length == sortedDates.length ? Icons.deselect : Icons.select_all),
              tooltip: _selectedDates.length == sortedDates.length ? '全解除' : '全選択',
              onPressed: () {
                setState(() {
                  if (_selectedDates.length == sortedDates.length) {
                    // 全解除
                    _selectedDates.clear();
                  } else {
                    // 全選択
                    _selectedDates = Set.from(sortedDates);
                  }
                });
              },
            ),
          // 過去表示チェックボックス
          Row(
            children: [
              Checkbox(
                value: _showPast,
                onChanged: (value) {
                  setState(() {
                    _showPast = value ?? false;
                    _dateFilter = _showPast ? 'past' : 'future';
                    // フィルター変更時は選択をクリア
                    _selectedDates.clear();
                  });
                },
              ),
              const Text('過去を表示', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
            ],
          ),
          // エクセルにコピーボタン（形式選択メニュー付き、選択された日付の予定のみ）
          PopupMenuButton<String>(
            icon: const Icon(Icons.content_copy),
            tooltip: _selectedDates.isEmpty 
                ? 'エクセルにコピー（日付を選択してください）'
                : 'エクセルにコピー（選択された${_selectedDates.length}日分の予定をクリップボードにコピー）',
            onSelected: (value) {
              if (_currentView != ScheduleCalendarView.list) {
                SnackBarService.showInfo(context, 'エクセルコピーはリスト表示時のみ利用できます。');
                return;
              }
              if (value == 'table') {
                _copyToExcel(isOneCellForm: false);
              } else if (value == 'onecell') {
                _copyToExcel(isOneCellForm: true);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'table',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 20),
                    SizedBox(width: 8),
                    Text('表形式（複数列）'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'onecell',
                child: Row(
                  children: [
                    Icon(Icons.list, size: 20),
                    SizedBox(width: 8),
                    Text('1セル形式（列挙）'),
                  ],
                ),
              ),
            ],
          ),
          // Outlook連携ボタン
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Outlookから予定を取り込む',
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => const OutlookCalendarImportDialogV2(),
              );
              if (result == true) {
                final vm = ref.read(scheduleViewModelProvider.notifier);
                await vm.loadSchedules();
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バーとタスクフィルター
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 検索バー
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: '予定タイトル、タスク名、場所で検索',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // タスクフィルター（予定あり未完了タスクのみ）
                DropdownButton<String?>(
                  value: _selectedTaskId,
                  hint: const Text('タスク'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('すべて'),
                    ),
                    // 予定があり、未完了のタスクのみ表示
                    ...tasks.where((task) {
                      if (task.status == TaskStatus.completed) return false;
                      // このタスクに紐づく予定があるかチェック
                      return schedules.any((s) => s.taskId == task.id);
                    }).map((task) => DropdownMenuItem<String?>(
                      value: task.id,
                      child: SizedBox(
                        width: 200,
                        child: Text(
                          task.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTaskId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // 予定リスト
          Expanded(
            child: searchFilteredSchedules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _dateFilter == 'future'
                              ? '未来の予定がありません'
                              : _dateFilter == 'past'
                                  ? '過去の予定がありません'
                                  : '予定がありません',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _buildCurrentView(
                    sortedDates: sortedDates,
                    schedulesByDate: schedulesByDate,
                    tasks: tasks,
                    now: now,
                  ),
          ),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        tooltip: '予定を追加',
        child: const Icon(Icons.add),
      ),
    ),
        ),
      ),
    );
  }


  void _scrollToToday() {
    if (_todayKey?.currentContext != null) {
      Scrollable.ensureVisible(
        _todayKey!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0, // 画面の上部に配置
      );
    }
  }

  void _focusSearchField() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  Future<void> _showAddScheduleDialog() async {
    final tasks = ref.read(taskViewModelProvider);
    if (tasks.isEmpty) {
      if (mounted) {
        SnackBarService.showInfo(context, '予定を追加するには、まずタスクを作成してください');
      }
      return;
    }

    // タスク選択ダイアログ
    final selectedTask = await showDialog<TaskItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.title),
                onTap: () => Navigator.pop(context, task),
              );
            },
          ),
        ),
      ),
    );

    if (selectedTask != null && mounted) {
      // タスク編集モーダルを開く（予定セクションを展開）
      showDialog(
        context: context,
        builder: (context) => TaskDialog(task: selectedTask),
      );
    }
  }

  Widget _buildDateSection(
    DateTime date,
    List<ScheduleItem> schedules,
    List<TaskItem> tasks,
    GlobalKey? dateKey,
    DateTime now,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    // ロケールが初期化されていない場合はデフォルト形式を使用
    final dateFormat = _localeInitialized
        ? DateFormat('yyyy年MM月dd日(E)', 'ja_JP')
        : DateFormat('yyyy/MM/dd (E)');
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final isPast = DateTime(date.year, date.month, date.day).isBefore(DateTime(now.year, now.month, now.day));
    final Color headerBaseColor;
    final Color headerColor;
    final Color dateTextColor;
    final Color countBackgroundColor;
    final Color countTextColor;

    if (isToday) {
      headerBaseColor = colorScheme.primary;
      headerColor = colorScheme.primary.withOpacity(0.18);
      dateTextColor = colorScheme.primary;
      countBackgroundColor = colorScheme.primary.withOpacity(0.24);
      countTextColor = colorScheme.primary;
    } else if (isPast) {
      headerBaseColor = colorScheme.error;
      headerColor = Color.alphaBlend(headerBaseColor.withOpacity(0.12), colorScheme.surface);
      dateTextColor = colorScheme.onErrorContainer.withOpacity(0.9);
      countBackgroundColor = headerBaseColor.withOpacity(0.45);
      countTextColor = colorScheme.onPrimary;
    } else {
      headerBaseColor = colorScheme.secondary;
      headerColor = Color.alphaBlend(headerBaseColor.withOpacity(0.12), colorScheme.surface);
      dateTextColor = colorScheme.onSecondaryContainer;
      countBackgroundColor = headerBaseColor.withOpacity(0.45);
      countTextColor = colorScheme.onPrimary;
    }
    
    // 日付のみ（時刻を0に）で比較
    final dateOnly = DateTime(date.year, date.month, date.day);
    final isSelected = _selectedDates.any((selectedDate) =>
        selectedDate.year == dateOnly.year &&
        selectedDate.month == dateOnly.month &&
        selectedDate.day == dateOnly.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: dateKey,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday
                  ? headerBaseColor.withOpacity(0.55)
                  : headerBaseColor.withOpacity(0.4),
              width: isToday ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // チェックボックス
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedDates.add(dateOnly);
                    } else {
                      _selectedDates.removeWhere((selectedDate) =>
                          selectedDate.year == dateOnly.year &&
                          selectedDate.month == dateOnly.month &&
                          selectedDate.day == dateOnly.day);
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(date),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: dateTextColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: countBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${schedules.length}件',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: countTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...schedules.map((schedule) {
          TaskItem task;
          try {
            task = tasks.firstWhere((t) => t.id == schedule.taskId);
          } catch (e) {
            task = TaskItem(
              id: schedule.taskId,
              title: 'タスクが見つかりません',
              createdAt: DateTime.now(),
            );
          }
          
          return _buildScheduleCard(schedule, task, now);
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildScheduleCard(
    ScheduleItem schedule,
    TaskItem task,
    DateTime now,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeFormat = DateFormat('HH:mm');
    final hasEndTime = schedule.endDateTime != null;
    final timeText = hasEndTime
        ? '${timeFormat.format(schedule.startDateTime)} - ${timeFormat.format(schedule.endDateTime!)}'
        : timeFormat.format(schedule.startDateTime);
    
    // 過去の予定かどうかを判定
    final isPast = schedule.startDateTime.isBefore(now);
    final isToday = DateUtils.isSameDay(schedule.startDateTime, now);
    
    // 重複チェック
    final schedules = ref.read(scheduleViewModelProvider);
    final hasOverlap = _checkScheduleOverlap(schedule, schedules);
    final Color baseColor;
    if (hasOverlap) {
      baseColor = colorScheme.secondary;
    } else if (isPast) {
      baseColor = colorScheme.outline;
    } else if (isToday) {
      baseColor = colorScheme.primary;
    } else {
      baseColor = colorScheme.tertiary;
    }
    final Color gradientStart;
    final Color gradientEnd;
    if (isToday) {
      gradientStart = colorScheme.primary.withOpacity(0.24);
      gradientEnd = colorScheme.primary.withOpacity(0.08);
    } else {
      gradientStart = Color.alphaBlend(baseColor.withOpacity(0.1), colorScheme.surface);
      gradientEnd = Color.alphaBlend(baseColor.withOpacity(0.03), colorScheme.surface);
    }
    final timeTextColor = isToday ? colorScheme.primary : colorScheme.onSurface;
    final timeIconColor = isToday ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: Colors.transparent,
      elevation: 1,
      shadowColor: baseColor.withOpacity(0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasOverlap ? baseColor.withOpacity(0.6) : baseColor.withOpacity(0.25),
          width: hasOverlap ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // タスク編集モーダルを開く
          final tasks = ref.read(taskViewModelProvider);
          try {
            final task = tasks.firstWhere((t) => t.id == schedule.taskId);
            showDialog(
              context: context,
              builder: (context) => TaskDialog(task: task),
            );
          } catch (e) {
            // タスクが見つからない場合は何もしない
          }
        },
        onLongPress: () {
          _showScheduleMenu(schedule, task);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: timeIconColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: timeTextColor,
                      ),
                    ),
                    if (schedule.location != null && schedule.location!.isNotEmpty) ...[
                      const SizedBox(width: 14),
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: timeIconColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          schedule.location!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                _searchQuery.isEmpty
                    ? Text(
                        schedule.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      )
                    : HighlightedText(
                        text: schedule.title,
                        highlight: _searchQuery,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    final tasks = ref.read(taskViewModelProvider);
                    try {
                      final task = tasks.firstWhere((t) => t.id == schedule.taskId);
                      showDialog(
                        context: context,
                        builder: (context) => TaskDialog(task: task),
                      );
                    } catch (e) {
                      SnackBarService.showWarning(context, '関連タスクが見つかりませんでした');
                    }
                  },
                  child: _searchQuery.isEmpty
                      ? Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        )
                      : HighlightedText(
                          text: task.title,
                          highlight: _searchQuery,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView({
    required List<DateTime> sortedDates,
    required Map<DateTime, List<ScheduleItem>> schedulesByDate,
    required List<TaskItem> tasks,
    required DateTime now,
  }) {
    final taskMap = {for (final task in tasks) task.id: task};

    switch (_currentView) {
      case ScheduleCalendarView.list:
        return _buildListView(sortedDates, schedulesByDate, tasks, now);
      case ScheduleCalendarView.week:
        return _buildWeekView(schedulesByDate, taskMap);
      case ScheduleCalendarView.month:
        return _buildMonthView(schedulesByDate, taskMap);
    }
  }

  Widget _buildListView(
    List<DateTime> sortedDates,
    Map<DateTime, List<ScheduleItem>> schedulesByDate,
    List<TaskItem> tasks,
    DateTime now,
  ) {
    _todayKey = null;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dateSchedules = schedulesByDate[date]!;
        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

        if (isToday && _todayKey == null) {
          _todayKey = GlobalKey();
        }

        return _buildDateSection(
          date,
          dateSchedules,
          tasks,
          isToday ? _todayKey : null,
          now,
        );
      },
    );
  }

  Widget _buildWeekView(
    Map<DateTime, List<ScheduleItem>> schedulesByDate,
    Map<String, TaskItem> taskMap,
  ) {
    final sortedDates = schedulesByDate.keys.toList()..sort();
    final Map<DateTime, List<DateTime>> weekGroups = {};
    for (final date in sortedDates) {
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      weekGroups.putIfAbsent(weekStart, () => []);
      weekGroups[weekStart]!.add(date);
    }
    final weekStarts = weekGroups.keys.toList()..sort();
    final dayLabelFormat =
        _localeInitialized ? DateFormat('M/d(E)', 'ja_JP') : DateFormat('M/d (E)');
    final headerFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: weekStarts.length,
      itemBuilder: (context, index) {
        final weekStart = weekStarts[index];
        final weekEnd = weekStart.add(const Duration(days: 6));
        final days = List.generate(7, (offset) => weekStart.add(Duration(days: offset)));

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${headerFormat.format(weekStart)} 〜 ${headerFormat.format(weekEnd)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ...days
                    .where((day) => (schedulesByDate[day] ?? []).isNotEmpty)
                    .map((day) {
                  final entries = schedulesByDate[day] ?? [];
                  final label = dayLabelFormat.format(day);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: entries.map((schedule) {
                              final task = taskMap[schedule.taskId];
                              final title = schedule.title.isNotEmpty
                                  ? schedule.title
                                  : task?.title ?? '';
                              final time = timeFormat.format(schedule.startDateTime);
                              return Text('$time  $title',
                                  style: const TextStyle(height: 1.3));
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthView(
    Map<DateTime, List<ScheduleItem>> schedulesByDate,
    Map<String, TaskItem> taskMap,
  ) {
    final sortedDates = schedulesByDate.keys.toList()..sort();
    final Map<DateTime, List<DateTime>> monthGroups = {};
    for (final date in sortedDates) {
      final monthStart = DateTime(date.year, date.month, 1);
      monthGroups.putIfAbsent(monthStart, () => []);
      monthGroups[monthStart]!.add(date);
    }
    final monthStarts = monthGroups.keys.toList()..sort();
    final dayLabelFormat =
        _localeInitialized ? DateFormat('d日(E)', 'ja_JP') : DateFormat('d (E)');
    final monthHeaderFormat =
        _localeInitialized ? DateFormat('yyyy年MM月', 'ja_JP') : DateFormat('yyyy/MM');
    final timeFormat = DateFormat('HH:mm');

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: monthStarts.length,
      itemBuilder: (context, index) {
        final monthStart = monthStarts[index];
        final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
        final daysInMonth = monthEnd.day;
        final days = List.generate(
          daysInMonth,
          (offset) => DateTime(monthStart.year, monthStart.month, offset + 1),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthHeaderFormat.format(monthStart),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ...days
                    .where((day) => (schedulesByDate[day] ?? []).isNotEmpty)
                    .map((day) {
                  final entries = schedulesByDate[day] ?? [];
                  final label = dayLabelFormat.format(day);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: entries.map((schedule) {
                              final task = taskMap[schedule.taskId];
                              final title = schedule.title.isNotEmpty
                                  ? schedule.title
                                  : task?.title ?? '';
                              final time = timeFormat.format(schedule.startDateTime);
                              return Text(
                                '$time  $title',
                                style: const TextStyle(height: 1.3),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showScheduleMenu(ScheduleItem schedule, TaskItem task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('編集'),
              onTap: () {
                Navigator.pop(context);
                _editSchedule(schedule, task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('コピー'),
              onTap: () {
                Navigator.pop(context);
                _copySchedule(schedule, task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('削除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteSchedule(schedule);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('エクセルにコピー'),
              onTap: () {
                Navigator.pop(context);
                _copyToExcel();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showShortcutGuide(BuildContext context) {
    showShortcutHelpDialog(
      context,
      title: '予定表ショートカット',
      entries: const [
        ShortcutHelpEntry('F1', 'ショートカット一覧を表示'),
        ShortcutHelpEntry('Ctrl + F', '検索バーにフォーカス'),
      ],
    );
  }

  Future<void> _editSchedule(ScheduleItem schedule, TaskItem task) async {
    // タスク編集モーダルを開く（予定セクションを展開）
    await showDialog(
      context: context,
      builder: (context) => TaskDialog(task: task),
    );
    
    // モーダルが閉じた後にデータを再読み込み
    if (mounted) {
      final vm = ref.read(scheduleViewModelProvider.notifier);
      await vm.loadSchedules();
    }
  }

  Future<void> _copySchedule(ScheduleItem schedule, TaskItem task) async {
    // 日時選択ダイアログ
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: schedule.startDateTime.add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate == null || !mounted) return;
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(schedule.startDateTime),
    );
    
    if (pickedTime == null || !mounted) return;
    
    // 終了日時の計算
    DateTime? newEndDateTime;
    if (schedule.endDateTime != null) {
      final duration = schedule.endDateTime!.difference(schedule.startDateTime);
      newEndDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ).add(duration);
    }
    
    // 新しい予定を作成
    final vm = ref.read(scheduleViewModelProvider.notifier);
    final newSchedule = vm.createSchedule(
      taskId: schedule.taskId,
      title: schedule.title,
      startDateTime: DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
      endDateTime: newEndDateTime,
      location: schedule.location,
      notes: schedule.notes,
    );
    
    await vm.addSchedule(newSchedule);
    
    if (mounted) {
      SnackBarService.showSuccess(context, '予定をコピーしました');
    }
  }

  bool _checkScheduleOverlap(ScheduleItem schedule, List<ScheduleItem> allSchedules) {
    for (final otherSchedule in allSchedules) {
      if (otherSchedule.id == schedule.id) continue;
      if (otherSchedule.taskId == schedule.taskId) continue;

      final scheduleStart = schedule.startDateTime;
      final scheduleEnd = schedule.endDateTime ?? scheduleStart.add(const Duration(hours: 1));
      final otherStart = otherSchedule.startDateTime;
      final otherEnd = otherSchedule.endDateTime ?? otherStart.add(const Duration(hours: 1));

      if (scheduleStart.isBefore(otherEnd) && scheduleEnd.isAfter(otherStart)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _deleteSchedule(ScheduleItem schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予定を削除'),
        content: Text('「${schedule.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      final vm = ref.read(scheduleViewModelProvider.notifier);
      await vm.deleteSchedule(schedule.id);
      
      if (mounted) {
        SnackBarService.showSuccess(context, '予定を削除しました');
      }
    }
  }

  /// 予定をエクセル形式でクリップボードにコピー
  /// [isOneCellForm] trueの場合は1セル形式（列挙）、falseの場合は表形式（複数列）
  Future<void> _copyToExcel({bool isOneCellForm = false}) async {
    final schedules = ref.read(scheduleViewModelProvider);
    final tasks = ref.read(taskViewModelProvider);
    final now = DateTime.now();
    
    // フィルタリング（現在のフィルター設定を適用）
    List<ScheduleItem> filteredSchedules = schedules;
    
    // タスク別フィルター
    if (_selectedTaskId != null) {
      filteredSchedules = filteredSchedules.where((s) => s.taskId == _selectedTaskId).toList();
    }
    
    // 日付範囲フィルター
    filteredSchedules = filteredSchedules.where((schedule) {
      if (_dateFilter == 'future') {
        return schedule.startDateTime.isAfter(now);
      } else if (_dateFilter == 'past') {
        return schedule.startDateTime.isBefore(now);
      }
      return true;
    }).toList();
    
    // 検索フィルター
    if (_searchQuery.isNotEmpty) {
      filteredSchedules = filteredSchedules.where((schedule) {
        final task = tasks.firstWhere(
          (t) => t.id == schedule.taskId,
          orElse: () => TaskItem(
            id: schedule.taskId,
            title: '',
            createdAt: DateTime.now(),
          ),
        );
        final queryLower = _searchQuery.toLowerCase();
        return schedule.title.toLowerCase().contains(queryLower) ||
            task.title.toLowerCase().contains(queryLower) ||
            (schedule.location != null && schedule.location!.toLowerCase().contains(queryLower));
      }).toList();
    }
    
    // 選択された日付の予定のみにフィルター
    if (_selectedDates.isNotEmpty) {
      filteredSchedules = filteredSchedules.where((schedule) {
        final scheduleDate = DateTime(
          schedule.startDateTime.year,
          schedule.startDateTime.month,
          schedule.startDateTime.day,
        );
        return _selectedDates.any((selectedDate) =>
            selectedDate.year == scheduleDate.year &&
            selectedDate.month == scheduleDate.month &&
            selectedDate.day == scheduleDate.day);
      }).toList();
    }
    
    // 選択された日付がない場合は警告
    if (_selectedDates.isEmpty) {
      if (mounted) {
        SnackBarService.showWarning(context, 'コピーする日付を選択してください');
      }
      return;
    }
    
    // 日付順にソート
    filteredSchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    
    final buffer = StringBuffer();
    final timeFormat = DateFormat('HH:mm');
    final oneCellDateFormat = DateFormat('MM/dd');
    
    if (isOneCellForm) {
      // 1セル形式（列挙形式）
      for (final schedule in filteredSchedules) {
        final task = tasks.firstWhere(
          (t) => t.id == schedule.taskId,
          orElse: () => TaskItem(
            id: schedule.taskId,
            title: 'タスクが見つかりません',
            createdAt: DateTime.now(),
          ),
        );

        final dateLabel = oneCellDateFormat.format(schedule.startDateTime);
        final startTime = timeFormat.format(schedule.startDateTime);
        final endTime = schedule.endDateTime != null
            ? timeFormat.format(schedule.endDateTime!)
            : null;
        final location = (schedule.location ?? '')
            .replaceAll('\t', ' ')
            .replaceAll('\n', ' ')
            .trim();
        final displayTitle = schedule.title.isNotEmpty
            ? schedule.title
            : task.title;

        final bufferLine = StringBuffer('・$dateLabel $startTime');
        if (endTime != null && endTime.isNotEmpty) {
          bufferLine.write('~$endTime');
        }
        if (location.isNotEmpty) {
          bufferLine.write(' $location');
        }
        bufferLine.write(' $displayTitle');
        buffer.writeln(bufferLine.toString());
      }
    } else {
      // 表形式（タブ区切り、複数列）
      final dateFormat = DateFormat('yyyy/MM/dd');
      
      // ヘッダー
      buffer.writeln('日付\t開始時刻\t終了時刻\tタイトル\t場所\tタスク名');
      
      // データ行
      for (final schedule in filteredSchedules) {
        final task = tasks.firstWhere(
          (t) => t.id == schedule.taskId,
          orElse: () => TaskItem(
            id: schedule.taskId,
            title: 'タスクが見つかりません',
            createdAt: DateTime.now(),
          ),
        );
        
        final date = dateFormat.format(schedule.startDateTime);
        final startTime = timeFormat.format(schedule.startDateTime);
        final endTime = schedule.endDateTime != null
            ? timeFormat.format(schedule.endDateTime!)
            : '';
        final title = schedule.title.replaceAll('\t', ' ').replaceAll('\n', ' ');
        final location = (schedule.location ?? '').replaceAll('\t', ' ').replaceAll('\n', ' ');
        final taskTitle = task.title.replaceAll('\t', ' ').replaceAll('\n', ' ');
        
        buffer.writeln('$date\t$startTime\t$endTime\t$title\t$location\t$taskTitle');
      }
    }
    
    // クリップボードにコピー
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    if (mounted) {
      final formatText = isOneCellForm ? '1セル形式' : '表形式';
      SnackBarService.showSuccess(context, '${filteredSchedules.length}件の予定を$formatTextでクリップボードにコピーしました（エクセルに貼り付け可能）');
    }
  }
}

