import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/link_viewmodel.dart'; // Added import for linkViewModelProvider

class TaskDialog extends ConsumerStatefulWidget {
  final TaskItem? task; // nullの場合は新規作成
  final String? relatedLinkId;

  const TaskDialog({
    super.key,
    this.task,
    this.relatedLinkId,
  });

  @override
  ConsumerState<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends ConsumerState<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _estimatedMinutesController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime? _dueDate;
  DateTime? _reminderTime;
  TaskPriority _priority = TaskPriority.medium;
  List<String> _tags = [];
  bool _isRecurring = false;
  String _recurringPattern = 'daily';
  bool _isRecurringReminder = false;
  String _recurringReminderPattern = RecurringReminderPattern.fiveMinutes;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _notesController.text = widget.task!.notes ?? '';
      _estimatedMinutesController.text = widget.task!.estimatedMinutes?.toString() ?? '';
      _dueDate = widget.task!.dueDate;
      _reminderTime = widget.task!.reminderTime;
      _priority = widget.task!.priority;
      _tags = List.from(widget.task!.tags);
      _isRecurring = widget.task!.isRecurring;
      _recurringPattern = widget.task!.recurringPattern ?? 'daily';
      _isRecurringReminder = widget.task!.isRecurringReminder;
      _recurringReminderPattern = widget.task!.recurringReminderPattern ?? RecurringReminderPattern.fiveMinutes;
    } else if (widget.relatedLinkId != null) {
      // リンクから作成された場合、リンク情報を取得して設定
      _initializeFromLink();
    }
    _tagsController.text = _tags.join(', ');
  }

  // リンク情報から初期値を設定
  void _initializeFromLink() {
    try {
      final linkViewModel = ref.read(linkViewModelProvider.notifier);
      final link = linkViewModel.getLinkById(widget.relatedLinkId!);
      if (link != null) {
        _titleController.text = '${link.label}の作業';
        _descriptionController.text = 'リンク: ${link.path}';
        _tags = [link.label, 'リンク関連'];
        _tagsController.text = _tags.join(', ');
        print('リンク情報から初期化: ${link.label}');
      }
    } catch (e) {
      print('リンク情報の取得エラー: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _estimatedMinutesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      
      // タグを解析
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      print('=== タスク作成ダイアログ ===');
      print('タイトル: ${_titleController.text.trim()}');
      print('リマインダー時間: $_reminderTime');
      print('期限日: $_dueDate');
      print('現在時刻: ${DateTime.now()}');
      print('繰り返しリマインダー: $_isRecurringReminder');
      print('繰り返しパターン: $_recurringReminderPattern');

      if (widget.task != null) {
        // 既存タスクの更新
        print('=== タスク更新 ===');
        print('元のリマインダー時間: ${widget.task!.reminderTime}');
        print('ダイアログのリマインダー時間: $_reminderTime');
        print('_reminderTimeの型: ${_reminderTime.runtimeType}');
        print('_reminderTime == null: ${_reminderTime == null}');
        
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          dueDate: _dueDate,
          reminderTime: _reminderTime,
          priority: _priority,
          tags: tags,
          estimatedMinutes: _estimatedMinutesController.text.isNotEmpty
              ? int.tryParse(_estimatedMinutesController.text)
              : null,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isRecurring: _isRecurring,
          recurringPattern: _isRecurring ? _recurringPattern : null,
          isRecurringReminder: _isRecurringReminder,
          recurringReminderPattern: _isRecurringReminder ? _recurringReminderPattern : null,
          // リマインダーがクリアされた場合、関連フィールドもクリア
          nextReminderTime: _reminderTime == null ? null : widget.task!.nextReminderTime,
          reminderCount: _reminderTime == null ? 0 : widget.task!.reminderCount,
        );
        
        print('copyWith後のリマインダー時間: ${updatedTask.reminderTime}');
        print('新しいリマインダー時間: ${updatedTask.reminderTime}');
        print('リマインダーがクリアされた: ${widget.task!.reminderTime != null && updatedTask.reminderTime == null}');
        
        taskViewModel.updateTask(updatedTask);
      } else {
        // 新規タスクの追加
        final task = taskViewModel.createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          dueDate: _dueDate,
          reminderTime: _reminderTime,
          priority: _priority,
          tags: tags,
          relatedLinkId: widget.relatedLinkId,
          estimatedMinutes: _estimatedMinutesController.text.isNotEmpty
              ? int.tryParse(_estimatedMinutesController.text)
              : null,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isRecurring: _isRecurring,
          recurringPattern: _isRecurring ? _recurringPattern : null,
          isRecurringReminder: _isRecurringReminder,
          recurringReminderPattern: _isRecurringReminder ? _recurringReminderPattern : null,
        );

        print('=== 作成されたタスク ===');
        print('タスクID: ${task.id}');
        print('タスクタイトル: ${task.title}');
        print('タスクリマインダー時間: ${task.reminderTime}');
        print('=== タスク作成ダイアログ完了 ===');
        
        taskViewModel.addTask(task);
      }

      Navigator.of(context).pop();
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? (_dueDate ?? DateTime.now()) : (_reminderTime ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
          print('期限日設定: $_dueDate');
        } else {
          // リマインダー日の場合、既存の時刻を保持するか、デフォルト時刻を設定
          if (_reminderTime != null) {
            _reminderTime = DateTime(
              picked.year,
              picked.month,
              picked.day,
              _reminderTime!.hour,
              _reminderTime!.minute,
            );
          } else {
            // デフォルト時刻（9:00）を設定
            _reminderTime = DateTime(
              picked.year,
              picked.month,
              picked.day,
              9,
              0,
            );
          }
          print('リマインダー日設定: $_reminderTime');
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (_reminderTime == null) {
      // リマインダー日が設定されていない場合は、今日の日付を使用
      final now = DateTime.now();
      _reminderTime = DateTime(now.year, now.month, now.day, 9, 0);
    }
    
    final initialTime = TimeOfDay.fromDateTime(_reminderTime!);
    
    // カスタム時間選択ダイアログを表示
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => CustomTimePickerDialog(
        initialTime: initialTime,
      ),
    );
    
    if (result != null) {
      final currentReminderTime = _reminderTime!;
      final selectedDateTime = DateTime(
        currentReminderTime.year,
        currentReminderTime.month,
        currentReminderTime.day,
        result.hour,
        result.minute,
      );
      
      // 過去の時間の場合は翌日に設定
      final now = DateTime.now();
      if (selectedDateTime.isBefore(now)) {
        _reminderTime = selectedDateTime.add(const Duration(days: 1));
      } else {
        _reminderTime = selectedDateTime;
      }
      
      setState(() {});
      print('リマインダー時刻設定: $_reminderTime');
      print('リマインダー日時: ${_reminderTime!.year}/${_reminderTime!.month}/${_reminderTime!.day} ${_reminderTime!.hour}:${_reminderTime!.minute}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.task != null ? Icons.edit : Icons.add_task,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.task != null ? 'タスクを編集' : '新しいタスク',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // タイトル
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'タイトルを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // 説明
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '説明',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // 期限日
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '期限日',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _dueDate != null
                                ? DateFormat('yyyy/MM/dd').format(_dueDate!)
                                : '期限日を選択',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_dueDate != null)
                      IconButton(
                        onPressed: () => setState(() => _dueDate = null),
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // リマインダー
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'リマインダー日',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _reminderTime != null
                                ? DateFormat('yyyy/MM/dd').format(_reminderTime!)
                                : 'リマインダー日を選択',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _reminderTime != null ? () => _selectTime(context) : null,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'リマインダー時刻',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _reminderTime != null
                                ? DateFormat('HH:mm').format(_reminderTime!)
                                : '時刻を選択',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_reminderTime != null)
                      IconButton(
                        onPressed: () {
                          print('=== リマインダークリアボタンクリック ===');
                          print('クリア前のリマインダー時間: $_reminderTime');
                          print('クリア前の繰り返しリマインダー: $_isRecurringReminder');
                          print('クリア前の繰り返しパターン: $_recurringReminderPattern');
                          
                          setState(() {
                            _reminderTime = null;
                            _isRecurringReminder = false;
                            _recurringReminderPattern = '';
                          });
                          
                          print('クリア後のリマインダー時間: $_reminderTime');
                          print('クリア後の繰り返しリマインダー: $_isRecurringReminder');
                          print('クリア後の繰り返しパターン: $_recurringReminderPattern');
                          print('リマインダーをクリアしました');
                        },
                        icon: const Icon(Icons.clear),
                        tooltip: 'リマインダーをクリア',
                      ),
                  ],
                ),
                // リマインダー時間の詳細表示
                if (_reminderTime != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'リマインダー設定: ${DateFormat('yyyy/MM/dd HH:mm').format(_reminderTime!)}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                
                // 優先度
                DropdownButtonFormField<TaskPriority>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: '優先度',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(_getPriorityColor(priority)),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_getPriorityText(priority)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // タグ
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'タグ (カンマ区切り)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 推定時間
                TextFormField(
                  controller: _estimatedMinutesController,
                  decoration: const InputDecoration(
                    labelText: '推定所要時間 (分)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // 繰り返し設定
                Row(
                  children: [
                    Checkbox(
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() => _isRecurring = value ?? false);
                      },
                    ),
                    const Text('繰り返しタスク'),
                    if (_isRecurring) ...[
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _recurringPattern,
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('毎日')),
                          DropdownMenuItem(value: 'weekly', child: Text('毎週')),
                          DropdownMenuItem(value: 'monthly', child: Text('毎月')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _recurringPattern = value);
                          }
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                
                // 繰り返しリマインダー設定
                Row(
                  children: [
                    Checkbox(
                      value: _isRecurringReminder,
                      onChanged: (value) {
                        setState(() => _isRecurringReminder = value ?? false);
                      },
                    ),
                    const Text('繰り返しリマインダー'),
                    if (_isRecurringReminder) ...[
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _recurringReminderPattern,
                        items: RecurringReminderPattern.allPatterns.map((pattern) {
                          return DropdownMenuItem(
                            value: pattern,
                            child: Text(RecurringReminderPattern.getDisplayName(pattern)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _recurringReminderPattern = value);
                          }
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                
                // メモ
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'メモ',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                // ボタン
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveTask,
                      child: Text(widget.task != null ? '更新' : '作成'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 0xFF4CAF50;
      case TaskPriority.medium:
        return 0xFFFF9800;
      case TaskPriority.high:
        return 0xFFF44336;
      case TaskPriority.urgent:
        return 0xFF9C27B0;
    }
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
}

// カスタム時間選択ダイアログ
class CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const CustomTimePickerDialog({
    Key? key,
    required this.initialTime,
  }) : super(key: key);

  @override
  State<CustomTimePickerDialog> createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<CustomTimePickerDialog> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
  }

  void _incrementHour() {
    setState(() {
      _hour = (_hour + 1) % 24;
    });
  }

  void _decrementHour() {
    setState(() {
      _hour = (_hour - 1 + 24) % 24;
    });
  }

  void _incrementMinute() {
    setState(() {
      _minute = (_minute + 1) % 60;
    });
  }

  void _decrementMinute() {
    setState(() {
      _minute = (_minute - 1 + 60) % 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('時間を選択'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 時間のスピンボタン
              Column(
                children: [
                  IconButton(
                    onPressed: _incrementHour,
                    icon: const Icon(Icons.keyboard_arrow_up),
                    tooltip: '時間を増やす',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _hour.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _decrementHour,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: '時間を減らす',
                  ),
                ],
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // 分のスピンボタン
              Column(
                children: [
                  IconButton(
                    onPressed: _incrementMinute,
                    icon: const Icon(Icons.keyboard_arrow_up),
                    tooltip: '分を増やす',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _minute.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _decrementMinute,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: '分を減らす',
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // キーボード入力ボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  final result = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: _hour, minute: _minute),
                  );
                  if (result != null) {
                    setState(() {
                      _hour = result.hour;
                      _minute = result.minute;
                    });
                  }
                },
                icon: const Icon(Icons.keyboard),
                tooltip: 'キーボード入力',
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            TimeOfDay(hour: _hour, minute: _minute),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
