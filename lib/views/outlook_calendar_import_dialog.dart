import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../services/outlook_calendar_service.dart';
import '../viewmodels/schedule_viewmodel.dart';

/// Outlook予定取り込みダイアログ
class OutlookCalendarImportDialog extends ConsumerStatefulWidget {
  final TaskItem task;

  const OutlookCalendarImportDialog({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<OutlookCalendarImportDialog> createState() => _OutlookCalendarImportDialogState();
}

class _OutlookCalendarImportDialogState extends ConsumerState<OutlookCalendarImportDialog> {
  final OutlookCalendarService _outlookService = OutlookCalendarService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _outlookEvents = [];
  final Set<int> _selectedIndices = {};
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 30));
  }

  Future<void> _loadOutlookEvents() async {
    setState(() {
      _isLoading = true;
      _outlookEvents = [];
      _selectedIndices.clear();
    });

    try {
      // Outlookが利用可能かチェック
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

      // 予定を取得
      final events = await _outlookService.getCalendarEvents(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _outlookEvents = events;
        _isLoading = false;
      });

      if (events.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('指定期間内に予定が見つかりませんでした。'),
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

  Future<void> _importSelectedEvents() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('取り込む予定を選択してください')),
      );
      return;
    }

    try {
      final scheduleViewModel = ref.read(scheduleViewModelProvider.notifier);
      final selectedEvents = _selectedIndices.map((i) => _outlookEvents[i]).toList();

      for (final event in selectedEvents) {
        final scheduleItem = _outlookService.convertEventToScheduleItem(
          taskId: widget.task.id,
          outlookEvent: event,
        );
        await scheduleViewModel.addSchedule(scheduleItem);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIndices.length}件の予定を取り込みました'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予定の取り込みに失敗しました: $e'),
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final pickedStart = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedStart == null) return;

    final pickedEnd = await showDatePicker(
      context: context,
      initialDate: _endDate ?? pickedStart.add(const Duration(days: 30)),
      firstDate: pickedStart,
      lastDate: DateTime(2100),
    );

    if (pickedEnd == null) return;

    setState(() {
      _startDate = pickedStart;
      _endDate = pickedEnd;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');

    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Outlook予定を取り込む',
                  style: TextStyle(
                    fontSize: 18,
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
            const Divider(),
            const SizedBox(height: 8),
            // 日付範囲選択
            Row(
              children: [
                Text('期間: '),
                TextButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    '${dateFormat.format(_startDate!)} ～ ${dateFormat.format(_endDate!)}',
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadOutlookEvents,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('予定を取得'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 予定一覧
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _outlookEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                '予定がありません',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadOutlookEvents,
                                child: const Text('再度取得'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _outlookEvents.length,
                          itemBuilder: (context, index) {
                            final event = _outlookEvents[index];
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

                            return CheckboxListTile(
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
                              title: Text(
                                subject,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (startDateTime != null) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${dateFormat.format(startDateTime)} ${timeFormat.format(startDateTime)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        if (endDateTime != null) ...[
                                          const Text(' ～ ', style: TextStyle(fontSize: 12)),
                                          Text(
                                            timeFormat.format(endDateTime),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                  if (location.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            style: const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const Divider(),
            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedIndices.isEmpty ? null : _importSelectedEvents,
                  child: Text('取り込む (${_selectedIndices.length}件)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

