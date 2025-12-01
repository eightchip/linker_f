import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../viewmodels/task_viewmodel.dart';
import '../services/snackbar_service.dart';
import '../widgets/app_spacing.dart';
import '../widgets/app_button_styles.dart';
import '../l10n/app_localizations.dart';

class CopyTaskDialog extends ConsumerStatefulWidget {
  final TaskItem task;

  const CopyTaskDialog({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<CopyTaskDialog> createState() => _CopyTaskDialogState();
}

class _CopyTaskDialogState extends ConsumerState<CopyTaskDialog> {
  DateTime? _selectedDueDate;
  DateTime? _selectedReminderTime;
  String _selectedPeriod = 'monthly'; // monthly, quarterly, yearly, custom
  bool _isLoading = false;
  int _copyCount = 1; // コピーする個数

  @override
  void initState() {
    super.initState();
    _calculateInitialDates();
  }

  void _calculateInitialDates() {
    final originalDueDate = widget.task.dueDate;
    final originalReminderTime = widget.task.reminderTime;

    if (originalDueDate != null) {
      _selectedDueDate = _calculateNextDate(originalDueDate, _selectedPeriod);
    }

    if (originalReminderTime != null) {
      _selectedReminderTime = _calculateNextDate(originalReminderTime, _selectedPeriod);
    }
  }

  DateTime _calculateNextDate(DateTime originalDate, String period) {
    switch (period) {
      case 'monthly':
        return _addMonths(originalDate, 1);
      case 'quarterly':
        return _addMonths(originalDate, 3);
      case 'yearly':
        return _addMonths(originalDate, 12);
      case 'custom':
        return originalDate;
      default:
        return _addMonths(originalDate, 1);
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    try {
      return DateTime(
        date.year,
        date.month + months,
        date.day,
        date.hour,
        date.minute,
      );
    } catch (e) {
      // 月の日数が異なる場合（例：1月31日→2月）は月末日を使用
      final nextMonth = DateTime(date.year, date.month + months);
      final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
      final adjustedDay = date.day > lastDayOfNextMonth 
          ? lastDayOfNextMonth 
          : date.day;
      
      return DateTime(
        date.year,
        date.month + months,
        adjustedDay,
        date.hour,
        date.minute,
      );
    }
  }

  void _onPeriodChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedPeriod = value;
        _copyCount = 1; // 期間変更時にコピー個数をリセット
        _calculateInitialDates();
      });
    }
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = DateTime(now.year + 2, 12, 31);
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 30)),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDueDate = selectedDate;
        _selectedPeriod = 'custom';
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final now = DateTime.now();
    final initialTime = _selectedReminderTime ?? now.add(const Duration(hours: 1));
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialTime),
    );

    if (selectedTime != null) {
      final selectedDateTime = DateTime(
        _selectedDueDate?.year ?? now.year,
        _selectedDueDate?.month ?? now.month,
        _selectedDueDate?.day ?? now.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      
      setState(() {
        _selectedReminderTime = selectedDateTime;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.copy, color: Colors.blue),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.copyTask),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.copyTaskConfirm(widget.task.title)),
            const SizedBox(height: AppSpacing.lg),
            
            // 期間選択
            Text(AppLocalizations.of(context)!.repeatPeriod, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(value: 'monthly', child: Text(AppLocalizations.of(context)!.monthly)),
                DropdownMenuItem(value: 'quarterly', child: Text(AppLocalizations.of(context)!.quarterly)),
                DropdownMenuItem(value: 'yearly', child: Text(AppLocalizations.of(context)!.yearly)),
                DropdownMenuItem(value: 'custom', child: Text(AppLocalizations.of(context)!.custom)),
              ],
              onChanged: _onPeriodChanged,
            ),
            
            // コピー個数選択（月次・四半期の場合のみ表示）
            if (_selectedPeriod == 'monthly' || _selectedPeriod == 'quarterly') ...[
              const SizedBox(height: AppSpacing.lg),
              Text(AppLocalizations.of(context)!.copyCount, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _copyCount.toDouble(),
                      min: 1,
                      max: _selectedPeriod == 'monthly' ? 12 : 4,
                      divisions: _selectedPeriod == 'monthly' ? 11 : 3,
                      label: AppLocalizations.of(context)!.copyCountLabel(_copyCount),
                      onChanged: (value) {
                        setState(() {
                          _copyCount = value.round();
                        });
                      },
                    ),
                  ),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.copyCountLabel(_copyCount),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Text(
                _selectedPeriod == 'monthly' 
                  ? AppLocalizations.of(context)!.maxCopiesMonthly
                  : AppLocalizations.of(context)!.maxCopiesQuarterly,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            
            // 期限日選択
            Text(AppLocalizations.of(context)!.dueDateLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _selectDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDueDate != null 
                        ? DateFormat('yyyy/MM/dd').format(_selectedDueDate!)
                        : AppLocalizations.of(context)!.selectDueDate,
                      style: TextStyle(
                        color: _selectedDueDate != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // リマインダー時間選択
            Text(AppLocalizations.of(context)!.reminderLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _selectReminderTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _selectedReminderTime != null 
                        ? DateFormat('yyyy/MM/dd HH:mm').format(_selectedReminderTime!)
                        : AppLocalizations.of(context)!.selectReminderTime,
                      style: TextStyle(
                        color: _selectedReminderTime != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // コピーされる内容の表示
            Text(AppLocalizations.of(context)!.copiedContent, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Text('• ${AppLocalizations.of(context)!.titleLabel} ${widget.task.title} (${AppLocalizations.of(context)!.copySuffix})'),
            if (widget.task.description != null && widget.task.description!.isNotEmpty)
              Text('• ${AppLocalizations.of(context)!.descriptionLabel} ${widget.task.description}'),
            if (widget.task.assignedTo != null && widget.task.assignedTo!.isNotEmpty)
              Text('• ${AppLocalizations.of(context)!.requestorMemoLabel} ${widget.task.assignedTo}'),
            
            // 複数コピーの場合の期限日表示
            if ((_selectedPeriod == 'monthly' || _selectedPeriod == 'quarterly') && _copyCount > 1) ...[
              Text('• ${AppLocalizations.of(context)!.copyCountLabel2} ${AppLocalizations.of(context)!.copyCountLabel(_copyCount)}'),
              Text('• ${AppLocalizations.of(context)!.dueDateLabel} ${_getMultipleDueDatesPreview()}'),
              if (widget.task.reminderTime != null)
                Text('• ${AppLocalizations.of(context)!.reminderLabel} ${_getMultipleReminderTimesPreview()}'),
            ] else ...[
              Text('• ${AppLocalizations.of(context)!.dueDateLabel} ${_selectedDueDate != null ? DateFormat('yyyy/MM/dd').format(_selectedDueDate!) : AppLocalizations.of(context)!.notSet}'),
              Text('• ${AppLocalizations.of(context)!.reminderLabel} ${_selectedReminderTime != null ? DateFormat('yyyy/MM/dd HH:mm').format(_selectedReminderTime!) : AppLocalizations.of(context)!.notSet}'),
            ],
            
            Text('• ${AppLocalizations.of(context)!.priorityLabel} ${_getPriorityText(widget.task.priority)}'),
            Text('• ${AppLocalizations.of(context)!.statusLabel} ${AppLocalizations.of(context)!.notStarted}'),
            if (widget.task.tags.isNotEmpty)
              Text('• ${AppLocalizations.of(context)!.tagsLabel} ${widget.task.tags.join(', ')}'),
            if (widget.task.estimatedMinutes != null && widget.task.estimatedMinutes! > 0)
              Text('• ${AppLocalizations.of(context)!.estimatedTimeLabel} ${widget.task.estimatedMinutes}${AppLocalizations.of(context)!.minutes}'),
            if (widget.task.hasSubTasks)
              Text('• ${AppLocalizations.of(context)!.subtasksLabel} ${AppLocalizations.of(context)!.copyCountLabel(widget.task.totalSubTasksCount)}'),
            const SizedBox(height: AppSpacing.sm),
            Text(AppLocalizations.of(context)!.statusResetNote),
            Text(AppLocalizations.of(context)!.subtasksCopiedNote),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: AppButtonStyles.text(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _copyTask,
          style: AppButtonStyles.primary(context),
          child: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(AppLocalizations.of(context)!.copy),
        ),
      ],
    );
  }

  String _getPriorityText(TaskPriority priority) {
    final l10n = AppLocalizations.of(context)!;
    switch (priority) {
      case TaskPriority.low:
        return l10n.low;
      case TaskPriority.medium:
        return l10n.medium;
      case TaskPriority.high:
        return l10n.high;
      case TaskPriority.urgent:
        return l10n.urgent;
    }
  }

  /// 複数期限日のプレビューを取得
  String _getMultipleDueDatesPreview() {
    if (widget.task.dueDate == null) return AppLocalizations.of(context)!.notSet;
    
    final dates = <String>[];
    for (int i = 0; i < _copyCount && i < 3; i++) {
      DateTime dueDate;
      if (_selectedPeriod == 'monthly') {
        dueDate = _addMonths(widget.task.dueDate!, i + 1);
      } else {
        dueDate = _addMonths(widget.task.dueDate!, (i + 1) * 3);
      }
      dates.add(DateFormat('MM/dd').format(dueDate));
    }
    
    if (_copyCount > 3) {
      dates.add('...');
    }
    
    return dates.join(', ');
  }

  /// 複数リマインダー時間のプレビューを取得
  String _getMultipleReminderTimesPreview() {
    if (widget.task.reminderTime == null) return AppLocalizations.of(context)!.notSet;
    
    final times = <String>[];
    for (int i = 0; i < _copyCount && i < 3; i++) {
      DateTime reminderTime;
      if (_selectedPeriod == 'monthly') {
        reminderTime = _addMonths(widget.task.reminderTime!, i + 1);
      } else {
        reminderTime = _addMonths(widget.task.reminderTime!, (i + 1) * 3);
      }
      times.add(DateFormat('MM/dd HH:mm').format(reminderTime));
    }
    
    if (_copyCount > 3) {
      times.add('...');
    }
    
    return times.join(', ');
  }

  Future<void> _copyTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== タスクコピー開始 ===');
      print('コピー対象タスク: ${widget.task.title}');
      print('選択された期限日: $_selectedDueDate');
      print('選択されたリマインダー時間: $_selectedReminderTime');
      print('選択された期間: $_selectedPeriod');
      print('コピー個数: $_copyCount');
      print('===============================');
      
      int successCount = 0;
      int totalCount = _copyCount;
      
      // 複数コピーの場合
      if ((_selectedPeriod == 'monthly' || _selectedPeriod == 'quarterly') && _copyCount > 1) {
        for (int i = 0; i < _copyCount; i++) {
          // 期限日を計算
          DateTime? dueDate;
          if (widget.task.dueDate != null) {
            if (_selectedPeriod == 'monthly') {
              dueDate = _addMonths(widget.task.dueDate!, i + 1);
            } else if (_selectedPeriod == 'quarterly') {
              dueDate = _addMonths(widget.task.dueDate!, (i + 1) * 3);
            }
          }
          
          // リマインダー時間を計算
          DateTime? reminderTime;
          if (widget.task.reminderTime != null) {
            if (_selectedPeriod == 'monthly') {
              reminderTime = _addMonths(widget.task.reminderTime!, i + 1);
            } else if (_selectedPeriod == 'quarterly') {
              reminderTime = _addMonths(widget.task.reminderTime!, (i + 1) * 3);
            }
          }
          
          // タスクをコピー
          final copiedTask = await ref.read(taskViewModelProvider.notifier).copyTask(
            widget.task,
            newDueDate: dueDate,
            newReminderTime: reminderTime,
          );
          
          if (copiedTask != null) {
            successCount++;
          }
        }
      } else {
        // 単一コピーの場合
        final copiedTask = await ref.read(taskViewModelProvider.notifier).copyTask(
          widget.task,
          newDueDate: _selectedDueDate,
          newReminderTime: _selectedReminderTime,
        );
        
        if (copiedTask != null) {
          successCount = 1;
          totalCount = 1;
        }
      }
      
      // ダイアログを閉じる
      Navigator.of(context).pop();
      
      // 結果メッセージを表示
      final l10n = AppLocalizations.of(context)!;
      if (successCount == totalCount) {
        SnackBarService.showSuccess(
          context,
          l10n.taskCopiedSuccess(successCount),
        );
      } else if (successCount > 0) {
        SnackBarService.showWarning(
          context,
          l10n.taskCopiedPartial(successCount, totalCount - successCount),
        );
      } else {
        SnackBarService.showError(
          context,
          l10n.taskCopyFailed,
        );
      }
    } catch (e) {
      print('タスクコピーエラー: $e');
      final l10n = AppLocalizations.of(context)!;
      SnackBarService.showError(
        context,
        '${l10n.taskCopyFailed}: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
