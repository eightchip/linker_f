import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/app_spacing.dart';
import '../widgets/app_button_styles.dart';

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
          const Text('タスクをコピー'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${widget.task.title}」をコピーしますか？'),
            const SizedBox(height: AppSpacing.lg),
            
            // 期間選択
            const Text('繰り返し期間:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('月次（1か月後）')),
                DropdownMenuItem(value: 'quarterly', child: Text('四半期（3か月後）')),
                DropdownMenuItem(value: 'yearly', child: Text('年次（1年後）')),
                DropdownMenuItem(value: 'custom', child: Text('カスタム')),
              ],
              onChanged: _onPeriodChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // 期限日選択
            const Text('期限日:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        : '期限日を選択',
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
            const Text('リマインダー時間:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        : 'リマインダー時間を選択（任意）',
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
            const Text('コピーされる内容:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Text('• タイトル: ${widget.task.title} (コピー)'),
            if (widget.task.description != null && widget.task.description!.isNotEmpty)
              Text('• 説明: ${widget.task.description}'),
            if (widget.task.assignedTo != null && widget.task.assignedTo!.isNotEmpty)
              Text('• 依頼先・メモ: ${widget.task.assignedTo}'),
            Text('• 期限日: ${_selectedDueDate != null ? DateFormat('yyyy/MM/dd').format(_selectedDueDate!) : '未設定'}'),
            Text('• リマインダー: ${_selectedReminderTime != null ? DateFormat('yyyy/MM/dd HH:mm').format(_selectedReminderTime!) : '未設定'}'),
            Text('• 優先度: ${_getPriorityText(widget.task.priority)}'),
            Text('• ステータス: 未着手'),
            if (widget.task.tags.isNotEmpty)
              Text('• タグ: ${widget.task.tags.join(', ')}'),
            if (widget.task.estimatedMinutes != null && widget.task.estimatedMinutes! > 0)
              Text('• 推定時間: ${widget.task.estimatedMinutes}分'),
            if (widget.task.hasSubTasks)
              Text('• サブタスク: ${widget.task.totalSubTasksCount}個'),
            const SizedBox(height: AppSpacing.sm),
            const Text('※ ステータスは「未着手」にリセットされます'),
            const Text('※ サブタスクもコピーされます'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: AppButtonStyles.text(context),
          child: const Text('キャンセル'),
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
            : const Text('コピー'),
        ),
      ],
    );
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '緊急';
    }
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
      print('===============================');
      
      // タスクをコピー
      final copiedTask = await ref.read(taskViewModelProvider.notifier).copyTask(
        widget.task,
        newDueDate: _selectedDueDate,
        newReminderTime: _selectedReminderTime,
      );
      
      // ダイアログを閉じる
      Navigator.of(context).pop();
      
      if (copiedTask != null) {
        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('タスク「${copiedTask.title}」をコピーしました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // エラーメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('タスクのコピーに失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('タスクコピーエラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('タスクのコピーに失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
