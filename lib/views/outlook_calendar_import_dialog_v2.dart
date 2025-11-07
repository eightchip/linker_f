import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../models/schedule_item.dart';
import '../services/outlook_calendar_service.dart';
import '../viewmodels/schedule_viewmodel.dart';
import '../viewmodels/task_viewmodel.dart';

/// Outlook予定一括取り込みダイアログ（新バージョン）
class OutlookCalendarImportDialogV2 extends ConsumerStatefulWidget {
  const OutlookCalendarImportDialogV2({super.key});

  @override
  ConsumerState<OutlookCalendarImportDialogV2> createState() => _OutlookCalendarImportDialogV2State();
}

class _OutlookCalendarImportDialogV2State extends ConsumerState<OutlookCalendarImportDialogV2> {
  final OutlookCalendarService _outlookService = OutlookCalendarService();
  final _uuid = const Uuid();
  
  // 状態管理
  bool _isLoading = false;
  String? _loadingMessage;
  List<Map<String, dynamic>> _outlookEvents = [];
  List<ScheduleItem> _existingSchedules = [];
  List<TaskItem> _incompleteTasks = [];
  
  // フィルタリング後の予定リスト（変更あり/未取込のみ）
  List<_FilteredEvent> _filteredEvents = [];
  final Set<int> _selectedIndices = {};
  
  // 日付設定（デフォルト：明日から1か月間）
  DateTime? _startDate;
  DateTime? _endDate;
  
  // ソート・検索
  String _searchQuery = '';
  bool _sortByTitle = true; // true: タイトル昇順, false: 日時昇順
  
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day + 1); // 明日
    _endDate = _startDate!.add(const Duration(days: 30)); // 1か月後
  }

  /// 予定を一括取得して照合
  Future<void> _loadAndMatchEvents() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Outlookから予定を取得中...';
      _outlookEvents = [];
      _filteredEvents = [];
      _selectedIndices.clear();
    });

    try {
      // 1. Outlookが利用可能かチェック
      final isAvailable = await _outlookService.isOutlookAvailable();
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Outlookが起動していないか、利用できません。Outlookを起動してから再度お試しください。'),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2. Outlook予定を取得
      setState(() {
        _loadingMessage = '予定を取得中...';
      });
      
      final events = await _outlookService.getCalendarEvents(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _loadingMessage = '既存データと照合中...';
      });

      // 3. 既存予定とタスクを取得
      final scheduleViewModel = ref.read(scheduleViewModelProvider.notifier);
      await scheduleViewModel.waitForInitialization();
      await scheduleViewModel.loadSchedules();
      _existingSchedules = ref.read(scheduleViewModelProvider);

      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      await taskViewModel.forceReloadTasks();
      // 完了済みタスクを除外
      _incompleteTasks = ref.read(taskViewModelProvider)
          .where((task) => task.status != TaskStatus.completed)
          .toList();

      // 4. 照合処理
      setState(() {
        _loadingMessage = '予定を照合中...';
      });

      _filteredEvents = _matchAndFilterEvents(events);

      // 5. ソート
      _sortFilteredEvents();

      setState(() {
        _isLoading = false;
        _outlookEvents = events;
      });

      if (_filteredEvents.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('取り込む必要がある予定はありません。'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予定の取得に失敗しました: $e'),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 予定を照合してフィルタリング
  List<_FilteredEvent> _matchAndFilterEvents(List<Map<String, dynamic>> events) {
    final filtered = <_FilteredEvent>[];

    for (final event in events) {
      final entryId = event['EntryID'] as String? ?? '';
      if (entryId.isEmpty) continue;

      // 既存予定を検索（EntryIDで）
      ScheduleItem? existingSchedule;
      for (final schedule in _existingSchedules) {
        if (schedule.outlookEntryId == entryId) {
          existingSchedule = schedule;
          break;
        }
      }

      // 既存予定がある場合、時間・場所の変更をチェック
      if (existingSchedule != null) {
        final startStr = event['Start'] as String? ?? '';
        final endStr = event['End'] as String? ?? '';
        final location = event['Location'] as String? ?? '';

        DateTime? startDateTime;
        DateTime? endDateTime;
        try {
          if (startStr.isNotEmpty) {
            startDateTime = DateTime.parse(startStr);
          }
          if (endStr.isNotEmpty) {
            endDateTime = DateTime.parse(endStr);
          }
        } catch (e) {
          continue;
        }

        // 時間または場所が変更されているかチェック
        bool hasTimeChange = false;
        bool hasLocationChange = false;

        if (startDateTime != null) {
          // 時間の比較（分単位で比較）
          if (existingSchedule.startDateTime.difference(startDateTime).inMinutes.abs() > 1) {
            hasTimeChange = true;
          }
        }

        if (endDateTime != null && existingSchedule.endDateTime != null) {
          if (existingSchedule.endDateTime!.difference(endDateTime).inMinutes.abs() > 1) {
            hasTimeChange = true;
          }
        }

        // 場所の比較
        final existingLocation = existingSchedule.location ?? '';
        if (existingLocation != location) {
          hasLocationChange = true;
        }

        // 変更がある場合のみ追加
        if (hasTimeChange || hasLocationChange) {
          // 関連タスクが完了済みでないかチェック
          final relatedTask = _incompleteTasks.firstWhere(
            (task) => task.id == existingSchedule!.taskId,
            orElse: () => TaskItem(
              id: '',
              title: '',
              priority: TaskPriority.medium,
              status: TaskStatus.pending,
              tags: [],
              createdAt: DateTime.now(),
            ),
          );

          if (relatedTask.id.isNotEmpty && relatedTask.status != TaskStatus.completed) {
            filtered.add(_FilteredEvent(
              event: event,
              existingSchedule: existingSchedule,
              relatedTask: relatedTask,
              hasTimeChange: hasTimeChange,
              hasLocationChange: hasLocationChange,
            ));
          }
        }
      } else {
        // 未取込の予定
        filtered.add(_FilteredEvent(
          event: event,
          existingSchedule: null,
          relatedTask: null,
          hasTimeChange: false,
          hasLocationChange: false,
        ));
      }
    }

    return filtered;
  }

  /// フィルタリング後の予定をソート
  void _sortFilteredEvents() {
    if (_sortByTitle) {
      // タイトル昇順 → 日時昇順
      _filteredEvents.sort((a, b) {
        final titleA = (a.event['Subject'] as String? ?? '').toLowerCase();
        final titleB = (b.event['Subject'] as String? ?? '').toLowerCase();
        if (titleA != titleB) {
          return titleA.compareTo(titleB);
        }
        // タイトルが同じ場合は日時で比較
        final startA = _getStartDateTime(a.event);
        final startB = _getStartDateTime(b.event);
        if (startA != null && startB != null) {
          return startA.compareTo(startB);
        }
        return 0;
      });
    } else {
      // 日時昇順
      _filteredEvents.sort((a, b) {
        final startA = _getStartDateTime(a.event);
        final startB = _getStartDateTime(b.event);
        if (startA != null && startB != null) {
          return startA.compareTo(startB);
        }
        return 0;
      });
    }
  }

  DateTime? _getStartDateTime(Map<String, dynamic> event) {
    final startStr = event['Start'] as String? ?? '';
    if (startStr.isEmpty) return null;
    try {
      return DateTime.parse(startStr);
    } catch (e) {
      return null;
    }
  }

  /// 開始日を選択
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate!.add(const Duration(days: 30));
        }
      });
    }
  }

  /// 終了日を選択
  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate?.add(const Duration(days: 30)) ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      child: Container(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Outlook予定を取り込む',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // 期間選択と取得ボタン
            Row(
              children: [
                const Text('期間: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _selectStartDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    '開始: ${dateFormat.format(_startDate!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const Text(' ～ ', style: TextStyle(fontSize: 16)),
                TextButton.icon(
                  onPressed: _selectEndDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    '終了: ${dateFormat.format(_endDate!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadAndMatchEvents,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('予定を取得', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 検索とソート
            if (!_isLoading && _filteredEvents.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '予定を検索...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ToggleButtons(
                    isSelected: [_sortByTitle, !_sortByTitle],
                    onPressed: (index) {
                      setState(() {
                        _sortByTitle = index == 0;
                        _sortFilteredEvents();
                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('タイトル順'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('日時順'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // ローディング表示
            if (_isLoading) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        _loadingMessage ?? '処理中...',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ]
            // 予定一覧
            else if (_filteredEvents.isEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        '取り込む必要がある予定はありません',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ]
            else ...[
              Expanded(
                child: _buildEventList(dateFormat, timeFormat),
              ),
            ],
            
            const Divider(height: 32),
            
            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _selectedIndices.isEmpty ? null : () async {
                    await _assignToTasks();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'タスクに割り当て (${_selectedIndices.length}件)',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _selectedIndices.isEmpty ? null : () async {
                    await _createNewTasks();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新規タスク作成', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 選択した予定をタスクに割り当て
  Future<void> _assignToTasks() async {
    if (_selectedIndices.isEmpty) return;

    // 検索フィルタリング後のリストを取得
    final filtered = _filteredEvents.where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final subject = (item.event['Subject'] as String? ?? '').toLowerCase();
      final location = (item.event['Location'] as String? ?? '').toLowerCase();
      return subject.contains(query) || location.contains(query);
    }).toList();

    // 選択された予定を取得
    final selectedEvents = _selectedIndices.map((index) => filtered[index]).toList();

    // タスク選択ダイアログを表示
    final selectedTask = await showDialog<TaskItem>(
      context: context,
      builder: (context) => _TaskSelectionDialog(tasks: _incompleteTasks),
    );

    if (selectedTask == null) return;

    // 予定をタスクに割り当て
    try {
      final scheduleViewModel = ref.read(scheduleViewModelProvider.notifier);
      int successCount = 0;
      int updateCount = 0;

      for (final item in selectedEvents) {
        final scheduleItem = _outlookService.convertEventToScheduleItem(
          taskId: selectedTask.id,
          outlookEvent: item.event,
        );

        if (item.existingSchedule != null) {
          // 既存予定を更新
          final updatedSchedule = item.existingSchedule!.copyWith(
            taskId: selectedTask.id,
            title: scheduleItem.title,
            startDateTime: scheduleItem.startDateTime,
            endDateTime: scheduleItem.endDateTime,
            location: scheduleItem.location,
            notes: scheduleItem.notes,
            updatedAt: DateTime.now(),
            outlookEntryId: scheduleItem.outlookEntryId,
          );
          await scheduleViewModel.updateSchedule(updatedSchedule);
          updateCount++;
        } else {
          // 新規予定を追加
          await scheduleViewModel.addSchedule(scheduleItem);
          successCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${successCount}件の予定を追加、${updateCount}件の予定を更新しました'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予定の割り当てに失敗しました: $e'),
          ),
        );
      }
    }
  }

  /// 選択した予定から新規タスクを作成
  Future<void> _createNewTasks() async {
    if (_selectedIndices.isEmpty) return;

    // 検索フィルタリング後のリストを取得
    final filtered = _filteredEvents.where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final subject = (item.event['Subject'] as String? ?? '').toLowerCase();
      final location = (item.event['Location'] as String? ?? '').toLowerCase();
      return subject.contains(query) || location.contains(query);
    }).toList();

    // 選択された予定を取得
    final selectedEvents = _selectedIndices.map((index) => filtered[index]).toList();

    try {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final scheduleViewModel = ref.read(scheduleViewModelProvider.notifier);
      int successCount = 0;

      for (final item in selectedEvents) {
        final subject = item.event['Subject'] as String? ?? '新規タスク';

        // 新規タスクを作成
        final newTask = TaskItem(
          id: const Uuid().v4(),
          title: subject,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          tags: [],
          createdAt: DateTime.now(),
        );

        await taskViewModel.addTask(newTask);

        // 予定をタスクに割り当て
        final scheduleItem = _outlookService.convertEventToScheduleItem(
          taskId: newTask.id,
          outlookEvent: item.event,
        );

        if (item.existingSchedule != null) {
          // 既存予定を更新
          final updatedSchedule = item.existingSchedule!.copyWith(
            taskId: newTask.id,
            title: scheduleItem.title,
            startDateTime: scheduleItem.startDateTime,
            endDateTime: scheduleItem.endDateTime,
            location: scheduleItem.location,
            notes: scheduleItem.notes,
            updatedAt: DateTime.now(),
            outlookEntryId: scheduleItem.outlookEntryId,
          );
          await scheduleViewModel.updateSchedule(updatedSchedule);
        } else {
          // 新規予定を追加
          await scheduleViewModel.addSchedule(scheduleItem);
        }

        successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount件のタスクを作成し、予定を割り当てました'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('タスクの作成に失敗しました: $e'),
          ),
        );
      }
    }
  }

  Widget _buildEventList(DateFormat dateFormat, DateFormat timeFormat) {
    // 検索フィルタリング
    final filtered = _filteredEvents.where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final subject = (item.event['Subject'] as String? ?? '').toLowerCase();
      final location = (item.event['Location'] as String? ?? '').toLowerCase();
      return subject.contains(query) || location.contains(query);
    }).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final event = item.event;
        final isSelected = _selectedIndices.contains(index);
        final subject = event['Subject'] as String? ?? '';
        final startStr = event['Start'] as String? ?? '';
        final endStr = event['End'] as String? ?? '';
        final location = event['Location'] as String? ?? '';

        DateTime? startDateTime;
        DateTime? endDateTime;
        try {
          if (startStr.isNotEmpty) {
            startDateTime = DateTime.parse(startStr);
          }
          if (endStr.isNotEmpty) {
            endDateTime = DateTime.parse(endStr);
          }
        } catch (e) {
          // パースエラーは無視
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedIndices.remove(index);
                } else {
                  _selectedIndices.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // チェックボックス（左側）
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  
                  // 予定情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // タイトル
                        Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // 日時（大きく表示）
                        if (startDateTime != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                '${dateFormat.format(startDateTime)} ${timeFormat.format(startDateTime)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (endDateTime != null) ...[
                                const Text(' ～ ', style: TextStyle(fontSize: 16)),
                                Text(
                                  timeFormat.format(endDateTime),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        // 場所（大きく表示）
                        if (location.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 20, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // 場所未指定でも表示
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              const Text(
                                '場所未指定',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // 変更情報
                        if (item.hasTimeChange || item.hasLocationChange) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (item.hasTimeChange)
                                Chip(
                                  label: const Text('時間変更', style: TextStyle(fontSize: 12)),
                                  backgroundColor: Colors.orange.shade100,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              if (item.hasLocationChange)
                                Chip(
                                  label: const Text('場所変更', style: TextStyle(fontSize: 12)),
                                  backgroundColor: Colors.orange.shade100,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// フィルタリング後の予定データ
class _FilteredEvent {
  final Map<String, dynamic> event;
  final ScheduleItem? existingSchedule;
  final TaskItem? relatedTask;
  final bool hasTimeChange;
  final bool hasLocationChange;

  _FilteredEvent({
    required this.event,
    this.existingSchedule,
    this.relatedTask,
    required this.hasTimeChange,
    required this.hasLocationChange,
  });
}

/// タスク選択ダイアログ
class _TaskSelectionDialog extends StatelessWidget {
  final List<TaskItem> tasks;

  const _TaskSelectionDialog({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'タスクを選択',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text('利用可能なタスクがありません'),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return ListTile(
                          title: Text(task.title),
                          subtitle: task.description != null && task.description!.isNotEmpty
                              ? Text(
                                  task.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, task),
                        );
                      },
                    ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
