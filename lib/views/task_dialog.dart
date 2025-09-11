import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/link_viewmodel.dart'; // Added import for linkViewModelProvider
import '../services/mail_service.dart';
import '../services/snackbar_service.dart';
import '../services/email_contact_service.dart';
import '../models/email_contact.dart';
import '../models/sent_mail_log.dart';

class TaskDialog extends ConsumerStatefulWidget {
  final TaskItem? task; // nullの場合は新規作成
  final String? relatedLinkId;
  final DateTime? initialDueDate; // 新規作成時の初期期限日
  final VoidCallback? onMailSent; // メール送信後のコールバック

  const TaskDialog({
    super.key,
    this.task,
    this.relatedLinkId,
    this.initialDueDate,
    this.onMailSent,
  });

  @override
  ConsumerState<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends ConsumerState<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assignedToController = TextEditingController();
  
  // メール送信用のコントローラー
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  
  // メール送信の設定
  bool _copyTitleToSubject = true;
  bool _copyMemoToBody = true;
  String _selectedMailApp = 'gmail'; // 'gmail' | 'outlook'
  
  // 連絡先選択
  List<EmailContact> _selectedContacts = [];
  final List<EmailContact> _availableContacts = [];

  // メール送信情報の一時保存
  String? _pendingMailTo;
  String? _pendingMailCc;
  String? _pendingMailBcc;
  String? _pendingMailSubject;
  String? _pendingMailBody;
  String? _pendingMailApp;

  DateTime? _dueDate;
  DateTime? _reminderTime;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.pending; // デフォルトは未着手
  bool _isRecurringReminder = false;
  String _recurringReminderPattern = RecurringReminderPattern.fiveMinutes;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      print('=== タスクダイアログ初期化（既存タスク） ===');
      print('タスクID: ${widget.task!.id}');
      print('タスクタイトル: ${widget.task!.title}');
      print('元の期限日: ${widget.task!.dueDate}');
      print('元のリマインダー時間: ${widget.task!.reminderTime}');
      
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _assignedToController.text = widget.task!.assignedTo ?? '';
      _dueDate = widget.task!.dueDate;
      _reminderTime = widget.task!.reminderTime;
      _priority = widget.task!.priority;
      _status = widget.task!.status;
      _isRecurringReminder = widget.task!.isRecurringReminder;
      _recurringReminderPattern = widget.task!.recurringReminderPattern ?? RecurringReminderPattern.fiveMinutes;
      
      print('初期化後の期限日: $_dueDate');
      print('初期化後のリマインダー時間: $_reminderTime');
      print('=== タスクダイアログ初期化完了 ===');
    } else {
      print('=== タスクダイアログ初期化（新規作成） ===');
      _dueDate = widget.initialDueDate; // 初期期限日を設定
      _reminderTime = null;
      print('初期化後の期限日: $_dueDate');
      print('初期化後のリマインダー時間: $_reminderTime');
      print('=== タスクダイアログ初期化完了 ===');
      
      if (widget.relatedLinkId != null) {
        // リンクから作成された場合、リンク情報を取得して設定
        _initializeFromLink();
      }
    }
    
    // 連絡先リストを初期化
    _loadContacts();
  }

  // リンク情報から初期値を設定
  void _initializeFromLink() {
    try {
      final linkViewModel = ref.read(linkViewModelProvider.notifier);
      final link = linkViewModel.getLinkById(widget.relatedLinkId!);
      if (link != null) {
        _titleController.text = link.label;
        _descriptionController.text = 'リンク: ${link.path}';
        
        // デフォルトのリマインダー時間を設定（1時間後）
        _reminderTime = DateTime.now().add(const Duration(hours: 1));
        print('リンク情報から初期化: ${link.label}');
        print('デフォルトリマインダー時間設定: $_reminderTime');
      }
    } catch (e) {
      print('リンク情報の取得エラー: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    super.dispose();
  }

  /// 連絡先リストを読み込み
  Future<void> _loadContacts() async {
    try {
      final contactService = EmailContactService();
      await contactService.initialize();
      
      // よく使われる連絡先を取得
      final contacts = contactService.getFrequentContacts(limit: 20);
      _availableContacts.clear();
      _availableContacts.addAll(contacts);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print('連絡先読み込みエラー: $e');
      }
    }
  }

  /// モーダル内でのナビゲーション処理
  void _handleModalNavigation(LogicalKeyboardKey key) {
    // 現在フォーカスされているウィジェットを取得
    final currentFocus = FocusScope.of(context);
    
    if (key == LogicalKeyboardKey.arrowRight) {
      // 右矢印：現在のテキストフィールド内でカーソル移動、端に到達したら次のフィールドへ
      final controller = _getCurrentController();
      if (controller != null) {
        final currentPosition = controller.selection.baseOffset;
        final textLength = controller.text.length;
        
        if (currentPosition < textLength) {
          // テキスト内にまだ文字がある場合は右に移動
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: currentPosition + 1),
          );
        } else {
          // テキストの端に到達した場合は次のフィールドに移動
          currentFocus.nextFocus();
        }
      } else {
        // テキストフィールド以外の場合は次のフィールドに移動
        currentFocus.nextFocus();
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      // 左矢印：現在のテキストフィールド内でカーソル移動、端に到達したら前のフィールドへ
      final controller = _getCurrentController();
      if (controller != null) {
        final currentPosition = controller.selection.baseOffset;
        
        if (currentPosition > 0) {
          // テキスト内にまだ文字がある場合は左に移動
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: currentPosition - 1),
          );
        } else {
          // テキストの端に到達した場合は前のフィールドに移動
          currentFocus.previousFocus();
        }
      } else {
        // テキストフィールド以外の場合は前のフィールドに移動
        currentFocus.previousFocus();
      }
    }
  }
  
  /// 現在フォーカスされているテキストフィールドのコントローラーを取得
  TextEditingController? _getCurrentController() {
    // 各コントローラーの選択状態をチェックして、現在フォーカスされているものを特定
    if (_titleController.selection.isValid && _titleController.selection.baseOffset >= 0) {
      return _titleController;
    }
    if (_descriptionController.selection.isValid && _descriptionController.selection.baseOffset >= 0) {
      return _descriptionController;
    }
    if (_assignedToController.selection.isValid && _assignedToController.selection.baseOffset >= 0) {
      return _assignedToController;
    }
    
    // フォーカスされているが選択状態が無効な場合、現在のフォーカスから推測
    final currentFocus = FocusScope.of(context);
    if (currentFocus.focusedChild != null) {
      // デフォルトとしてタイトルコントローラーを返す
      return _titleController;
    }
    
    return null;
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      
      // タグは削除されたため、空のリストを使用
      final tags = <String>[];

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
        print('元の期限日: ${widget.task!.dueDate}');
        print('ダイアログのリマインダー時間: $_reminderTime');
        print('ダイアログの期限日: $_dueDate');
        print('_reminderTimeの型: ${_reminderTime.runtimeType}');
        print('_reminderTime == null: ${_reminderTime == null}');
        print('_dueDate == null: ${_dueDate == null}');
        
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          dueDate: _dueDate,
          reminderTime: _reminderTime,
          priority: _priority,
          status: _status,
          tags: tags,
          estimatedMinutes: null,
          assignedTo: _assignedToController.text.trim().isEmpty
              ? null
              : _assignedToController.text.trim(),
          isRecurringReminder: _isRecurringReminder,
          recurringReminderPattern: _isRecurringReminder ? _recurringReminderPattern : null,
          // リマインダーがクリアされた場合、関連フィールドもクリア
          nextReminderTime: _reminderTime == null ? null : widget.task!.nextReminderTime,
          reminderCount: _reminderTime == null ? 0 : widget.task!.reminderCount,
          clearDueDate: _dueDate == null && widget.task!.dueDate != null, // 期限日が削除された場合
          clearReminderTime: _reminderTime == null && widget.task!.reminderTime != null, // リマインダーが削除された場合
          clearAssignedTo: _assignedToController.text.trim().isEmpty && widget.task!.assignedTo != null, // 依頼先が削除された場合
        );
        
        print('copyWith後のリマインダー時間: ${updatedTask.reminderTime}');
        print('copyWith後の期限日: ${updatedTask.dueDate}');
        print('新しいリマインダー時間: ${updatedTask.reminderTime}');
        print('新しい期限日: ${updatedTask.dueDate}');
        print('リマインダーがクリアされた: ${widget.task!.reminderTime != null && updatedTask.reminderTime == null}');
        print('期限日がクリアされた: ${widget.task!.dueDate != null && updatedTask.dueDate == null}');
        
        print('=== タスク更新時のリマインダー設定 ===');
        print('タスク: ${updatedTask.title}');
        print('リマインダー時間: ${updatedTask.reminderTime}');
        print('変更前のリマインダー時間: ${widget.task!.reminderTime}');
        
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
          status: _status,
          tags: tags,
          relatedLinkId: widget.relatedLinkId,
          estimatedMinutes: null,
          assignedTo: _assignedToController.text.trim().isEmpty
              ? null
              : _assignedToController.text.trim(),
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
    return PopScope(
      canPop: false, // 戻る操作を無効化
      child: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          // モーダル内でのキーボード制御
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowRight) {
              // 左右矢印キーはモーダル内での操作として処理
              // フォーカス移動やフィールド間の移動などに使用
              _handleModalNavigation(event.logicalKey);
              return; // イベントを消費して親の処理を防ぐ
            }
          }
        },
        child: Dialog(
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
                // 説明フィールドは非表示（内部データとして保持）
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
                        onPressed: () {
                          print('=== 期限日クリアボタンクリック ===');
                          print('クリア前の期限日: $_dueDate');
                          
                          setState(() {
                            _dueDate = null;
                          });
                          
                          print('クリア後の期限日: $_dueDate');
                          print('期限日をクリアしました');
                        },
                        icon: const Icon(Icons.clear),
                        tooltip: '期限日をクリア',
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
                
                // ステータス選択
                Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('ステータス:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<TaskStatus>(
                        value: _status,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: TaskStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(_getStatusColor(status)),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_getStatusText(status)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 依頼先
                TextFormField(
                  controller: _assignedToController,
                  decoration: const InputDecoration(
                    labelText: '依頼先やメモ',
                    border: OutlineInputBorder(),
                    hintText: '例: 佐藤さん、メモ',
                  ),
                ),
                const SizedBox(height: 16),
                
                // 繰り返し設定
                // 繰り返しタスク機能は削除（手動コピー機能を使用）
                
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
                        value: RecurringReminderPattern.allPatterns.contains(_recurringReminderPattern) 
                            ? _recurringReminderPattern 
                            : RecurringReminderPattern.fiveMinutes,
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
                // メモフィールドは削除
                const SizedBox(height: 24),
                
                // メール送信セクション
                _buildMailSection(),
                
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

  // ステータスの色を取得
  int _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 0xFF757575; // グレー
      case TaskStatus.inProgress:
        return 0xFF2196F3; // 青
      case TaskStatus.completed:
        return 0xFF4CAF50; // 緑
      case TaskStatus.cancelled:
        return 0xFFF44336; // 赤
    }
  }

  // ステータスのテキストを取得
  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '未着手';
      case TaskStatus.inProgress:
        return '進行中';
      case TaskStatus.completed:
        return '完了';
      case TaskStatus.cancelled:
        return 'キャンセル';
    }
  }

  /// メール送信セクションを構築
  Widget _buildMailSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              const Icon(Icons.email, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'メール送信',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // チェックボックス
          Column(
            children: [
              CheckboxListTile(
                value: _copyTitleToSubject,
                onChanged: (value) {
                  setState(() {
                    _copyTitleToSubject = value ?? true;
                  });
                },
                title: const Text('件名にタイトルをコピー'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                value: _copyMemoToBody,
                onChanged: (value) {
                  setState(() {
                    _copyMemoToBody = value ?? true;
                  });
                },
                title: const Text('本文に「依頼先やメモ」をコピー'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 連絡先選択セクション
          _buildContactSelectionSection(),
          
          const SizedBox(height: 16),
          
          // 宛先入力欄
          TextFormField(
            controller: _toController,
            decoration: const InputDecoration(
              labelText: 'To',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
              hintText: '空でもメーラーが起動します',
              helperText: '※空の場合はメーラーで直接アドレスを指定できます',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ccController,
            decoration: const InputDecoration(
              labelText: 'Cc',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_add),
              hintText: '任意',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bccController,
            decoration: const InputDecoration(
              labelText: 'Bcc',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_add_alt),
              hintText: '任意',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 送信アプリ選択
          Row(
            children: [
              const Text('送信アプリ: '),
              Radio<String>(
                value: 'gmail',
                groupValue: _selectedMailApp,
                onChanged: (value) {
                  setState(() {
                    _selectedMailApp = value!;
                  });
                },
              ),
              const Text('Gmail（Web）'),
              const SizedBox(width: 16),
              Radio<String>(
                value: 'outlook',
                groupValue: _selectedMailApp,
                onChanged: (value) {
                  setState(() {
                    _selectedMailApp = value!;
                  });
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Outlook（デスクトップ）'),
                  Text(
                    '※会社PCでのみ利用可能',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // メール送信ボタン
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendMail,
                      icon: const Icon(Icons.send),
                      label: const Text('メーラーを起動'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // テスト用ボタン
                  ElevatedButton.icon(
                    onPressed: _sendTestMail,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('テスト'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 送信完了ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pendingMailTo != null ? _markMailAsSent : null,
                  icon: const Icon(Icons.check_circle),
                  label: Text(_pendingMailTo != null ? 'メール送信完了' : 'メーラーを先に起動してください'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pendingMailTo != null ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // デバッグ情報を表示
              if (kDebugMode)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'デバッグ: _pendingMailTo = $_pendingMailTo',
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ),
              Text(
                _pendingMailTo != null 
                  ? '※メーラーでメールを送信した後、「メール送信完了」ボタンを押してください'
                  : '※まず「メーラーを起動」ボタンでメーラーを開いてください',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// メール送信を実行（メーラーを起動のみ）
  Future<void> _sendMail() async {
    try {
      final to = _toController.text.trim();
      final cc = _ccController.text.trim();
      final bcc = _bccController.text.trim();

      // 件名と本文を構築
      String subject = _copyTitleToSubject ? _titleController.text.trim() : '';
      String body = _copyMemoToBody ? _assignedToController.text.trim() : '';
      
      // 件名が空の場合はデフォルトの件名を設定
      if (subject.isEmpty) {
        subject = 'タスク関連メール';
      }

      final mailService = MailService();
      await mailService.initialize();
      
      // UUIDを生成
      final token = mailService.makeShortToken();
      final finalSubject = '$subject [$token]';
      final finalBody = '$body\n\n---\n送信ID: $token';
      
      // メール送信情報を一時保存（UUID付き）
      _pendingMailTo = to;
      _pendingMailCc = cc;
      _pendingMailBcc = bcc;
      _pendingMailSubject = finalSubject;
      _pendingMailBody = finalBody;
      _pendingMailApp = _selectedMailApp;
      
      if (kDebugMode) {
        print('=== メーラー起動開始 ===');
        print('アプリ: $_selectedMailApp');
        print('宛先: $to');
        print('件名: $finalSubject');
        print('トークン: $token');
      }
      
      // メーラーを起動（UUID付きでログは保存しない）
      if (_selectedMailApp == 'gmail') {
        await mailService.launchGmail(
          to: to,
          cc: cc,
          bcc: bcc,
          subject: finalSubject,
          body: finalBody,
        );
      } else if (_selectedMailApp == 'outlook') {
        await mailService.launchOutlookDesktop(
          to: to,
          cc: cc,
          bcc: bcc,
          subject: finalSubject,
          body: finalBody,
        );
      }

      if (kDebugMode) {
        print('=== メーラー起動完了 ===');
      }

      // UIを更新してボタンの状態を変更
      setState(() {});

      SnackBarService.showSuccess(context, '${_selectedMailApp == 'gmail' ? 'Gmail' : 'Outlook'}のメール作成画面を開きました。\nメールを送信した後、「メール送信完了」ボタンを押してください。');
      
    } catch (e) {
      SnackBarService.showError(context, 'メーラー起動エラー: $e');
    }
  }

  /// メール送信完了をマーク
  Future<void> _markMailAsSent() async {
    try {
      // 送信情報が保存されていない場合はエラー
      if (_pendingMailTo == null || _pendingMailApp == null) {
        SnackBarService.showError(context, '先に「メーラーを起動」ボタンを押してください');
        return;
      }

      // タスクIDを取得（新規作成の場合は一時的なIDを使用）
      final taskId = widget.task?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

      final mailService = MailService();
      await mailService.initialize();
      
      if (kDebugMode) {
        print('=== メール送信完了マーク ===');
        print('タスクID: $taskId');
        print('アプリ: $_pendingMailApp');
        print('宛先: $_pendingMailTo');
        print('件名: $_pendingMailSubject');
      }
      
      // トークンを抽出（件名から [LN-XXXXXX] を抽出）
      String? token;
      final subjectMatch = RegExp(r'\[(LN-[A-Z0-9]+)\]').firstMatch(_pendingMailSubject!);
      if (subjectMatch != null) {
        token = subjectMatch.group(1);
      }
      
      if (token == null) {
        SnackBarService.showError(context, 'トークンの抽出に失敗しました');
        return;
      }

      // 実際のメール送信ログのみを保存（既存のトークンを使用）
      await mailService.saveMailLogWithToken(
        taskId: taskId,
        app: _pendingMailApp!,
        to: _pendingMailTo!,
        cc: _pendingMailCc ?? '',
        bcc: _pendingMailBcc ?? '',
        subject: _pendingMailSubject!,
        body: _pendingMailBody!,
        token: token,
      );

      // 連絡先の使用回数を更新
      if (_selectedContacts.isNotEmpty) {
        final contactService = EmailContactService();
        await contactService.initialize();
        
        for (final contact in _selectedContacts) {
          await contactService.updateContactUsage(contact.email);
        }
      }

      // 一時保存された情報をクリア
      _pendingMailTo = null;
      _pendingMailCc = null;
      _pendingMailBcc = null;
      _pendingMailSubject = null;
      _pendingMailBody = null;
      _pendingMailApp = null;

      if (kDebugMode) {
        print('=== メール送信完了マーク完了 ===');
      }

      // UIを更新してボタンの状態をリセット
      setState(() {});

      SnackBarService.showSuccess(context, 'メール送信完了を記録しました');
      
      // メール送信後のコールバックを実行
      widget.onMailSent?.call();
    } catch (e) {
      SnackBarService.showError(context, 'メール送信完了記録エラー: $e');
    }
  }

  /// 連絡先選択セクションを構築
  Widget _buildContactSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.contacts, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            const Text(
              '送信先選択',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showContactSelectionDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('連絡先を追加'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 選択された連絡先の表示
        if (_selectedContacts.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _selectedContacts.map((contact) => Chip(
              label: Text(
                contact.shortDisplayName,
                style: const TextStyle(fontSize: 12),
              ),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                setState(() {
                  _selectedContacts.remove(contact);
                  _updateEmailFields();
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
        
        // よく使われる連絡先
        if (_availableContacts.isNotEmpty) ...[
          const Text(
            'よく使われる連絡先:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableContacts.length,
              itemBuilder: (context, index) {
                final contact = _availableContacts[index];
                final isSelected = _selectedContacts.contains(contact);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ActionChip(
                    label: Text(
                      contact.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                    backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedContacts.remove(contact);
      } else {
                          _selectedContacts.add(contact);
                        }
                        _updateEmailFields();
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
        
        // 送信履歴から選択ボタン
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showHistorySelectionDialog,
            icon: const Icon(Icons.history, size: 16),
            label: const Text('送信履歴から選択'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  /// 送信先選択ダイアログを表示
  Future<void> _showContactSelectionDialog() async {
    final result = await showDialog<EmailContact>(
      context: context,
      builder: (context) => _ContactAddDialog(),
    );
    
    if (result != null) {
      setState(() {
        _selectedContacts.add(result);
        _updateEmailFields();
      });
    }
  }

  /// 送信履歴選択ダイアログを表示
  Future<void> _showHistorySelectionDialog() async {
    final result = await showDialog<List<EmailContact>>(
      context: context,
      builder: (context) => _HistorySelectionDialog(),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        for (final contact in result) {
          if (!_selectedContacts.contains(contact)) {
            _selectedContacts.add(contact);
          }
        }
        _updateEmailFields();
      });
    }
  }

  /// メールフィールドを更新
  void _updateEmailFields() {
    final emails = _selectedContacts.map((c) => c.email).toList();
    _toController.text = emails.join(', ');
  }

  /// テスト用メール送信
  Future<void> _sendTestMail() async {
    try {
      final taskId = widget.task?.id ?? 'test_${DateTime.now().millisecondsSinceEpoch}';
      
      final mailService = MailService();
      await mailService.initialize();
      
      if (kDebugMode) {
        print('=== テストメール送信開始 ===');
        print('タスクID: $taskId');
      }
      
      await mailService.sendMail(
        taskId: taskId,
        app: 'gmail',
        to: 'test@example.com',
        cc: '',
        bcc: '',
        subject: 'テストメール',
        body: 'これはテストメールです。',
      );

      if (kDebugMode) {
        print('=== テストメール送信完了 ===');
      }

      SnackBarService.showSuccess(context, 'テストメール送信完了');
      
      // メール送信後のコールバックを実行
      widget.onMailSent?.call();
    } catch (e) {
      SnackBarService.showError(context, 'テストメール送信エラー: $e');
    }
  }

}

// 連絡先追加ダイアログ
class _ContactAddDialog extends StatefulWidget {
  @override
  _ContactAddDialogState createState() => _ContactAddDialogState();
}

class _ContactAddDialogState extends State<_ContactAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _organizationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('連絡先を追加'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名前 *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '名前を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'メールアドレス *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'メールアドレスを入力してください';
                }
                if (!value.contains('@')) {
                  return '有効なメールアドレスを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _organizationController,
              decoration: const InputDecoration(
                labelText: '組織・会社',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final contactService = EmailContactService();
                await contactService.initialize();
                
                final contact = await contactService.addContact(
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  organization: _organizationController.text.trim().isNotEmpty 
                    ? _organizationController.text.trim() 
                    : null,
                );
                
                Navigator.of(context).pop(contact);
              } catch (e) {
                SnackBarService.showError(context, '連絡先追加エラー: $e');
              }
            }
          },
          child: const Text('追加'),
        ),
      ],
    );
  }
}

// 送信履歴選択ダイアログ
class _HistorySelectionDialog extends StatefulWidget {
  @override
  _HistorySelectionDialogState createState() => _HistorySelectionDialogState();
}

class _HistorySelectionDialogState extends State<_HistorySelectionDialog> {
  final List<EmailContact> _selectedContacts = [];
  List<EmailContact> _historyContacts = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryContacts();
  }

  Future<void> _loadHistoryContacts() async {
    try {
      final contactService = EmailContactService();
      await contactService.initialize();
      
      // 登録済みの連絡先から、使用回数順で取得
      _historyContacts = contactService.getFrequentContacts(limit: 50);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print('送信履歴読み込みエラー: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('送信履歴から選択'),
      content: SizedBox(
        width: 450,
        height: 400,
        child: _historyContacts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('送信履歴がありません'),
                  SizedBox(height: 8),
                  Text('メールを送信すると、宛先が自動で連絡先に登録されます', 
                       style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('よく使う連絡先 (${_historyContacts.length}件)', 
                     style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _historyContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _historyContacts[index];
                      final isSelected = _selectedContacts.contains(contact);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: CheckboxListTile(
                          title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contact.email, style: const TextStyle(fontSize: 12)),
                              if (contact.organization != null)
                                Text(contact.organization!, 
                                     style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('使用回数: ${contact.useCount}回', 
                                   style: const TextStyle(fontSize: 10, color: Colors.blue)),
                            ],
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedContacts.add(contact);
                              } else {
                                _selectedContacts.remove(contact);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _selectedContacts.isEmpty
            ? null
            : () => Navigator.of(context).pop(_selectedContacts),
          child: Text('選択 (${_selectedContacts.length})'),
        ),
      ],
    );
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

