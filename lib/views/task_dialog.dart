import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../models/link_item.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/link_viewmodel.dart'; // Added import for linkViewModelProvider
import '../viewmodels/ui_customization_provider.dart';
import '../viewmodels/sub_task_viewmodel.dart';
import '../models/sub_task.dart';
import '../services/mail_service.dart';
import '../services/snackbar_service.dart';
import '../services/email_contact_service.dart';
import '../models/email_contact.dart';
import '../models/sent_mail_log.dart';
import '../widgets/app_button_styles.dart';
import '../viewmodels/font_size_provider.dart';
import '../widgets/link_association_dialog.dart';
import 'package:hive/hive.dart';

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
  // サブタスク用
  final _subTaskTitleController = TextEditingController();
  final _subTaskMinutesController = TextEditingController();
  final _subTaskDescriptionController = TextEditingController();
  SubTask? _editingSubTask;
  
  // メール送信用のコントローラー
  final _toController = TextEditingController();
  
  // メール送信の設定
  bool _copyMemoToBody = true;
  String _selectedMailApp = 'outlook'; // 'gmail' | 'outlook' - デフォルトはOutlook
  bool _includeSubtasksInMail = true; // メール本文にサブタスクを含める
  
  // 連絡先選択
  final List<EmailContact> _selectedContacts = [];
  final List<EmailContact> _availableContacts = [];

  // メール送信情報の一時保存
  String? _pendingMailTo;
  String? _pendingMailSubject;
  String? _pendingMailBody;
  String? _pendingMailApp;
  
  // 新規タスク作成時のメール送信情報の一時保存
  Map<String, dynamic>? _pendingMailLog;
  
  // メール機能の表示状態
  bool _isMailSectionExpanded = false;
  
  // リマインダー機能の表示状態
  bool _isReminderSectionExpanded = false;
  
  // サブタスク機能の表示状態
  bool _isSubTaskSectionExpanded = false;
  
  // メールテンプレート
  final List<Map<String, String>> _emailTemplates = [
    {
      'name': '報告書について',
      'subject': '報告書について',
      'body': 'お疲れ様です。\n\n以下についてご確認をお願いいたします。\n\n',
    },
    {
      'name': '会議資料の確認',
      'subject': '会議資料の確認',
      'body': 'いつもお世話になっております。\n\n件名の件について、以下をご連絡いたします。\n\n',
    },
    {
      'name': '進捗状況の共有',
      'subject': '進捗状況の共有',
      'body': 'お疲れ様です。\n\n進捗状況についてご報告いたします。\n\n',
    },
    {
      'name': '質問・相談事項',
      'subject': '質問・相談事項',
      'body': 'いつもお世話になっております。\n\n以下についてご質問・ご相談がございます。\n\n',
    },
  ];

  DateTime? _dueDate;
  DateTime? _reminderTime;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.pending; // デフォルトは未着手
  bool _isRecurringReminder = false;
  String _recurringReminderPattern = RecurringReminderPattern.fiveMinutes;
  
  // ピン留め状態
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      print('=== タスクダイアログ初期化（既存タスク） ===');
      print('タスクID: ${widget.task!.id}');
      print('タスクタイトル: ${widget.task!.title}');
      print('元の期限日: ${widget.task!.dueDate}');
      print('元のリマインダー時間: ${widget.task!.reminderTime}');
      print('関連リンクID数: ${widget.task!.relatedLinkIds.length}');
      print('関連リンクID: ${widget.task!.relatedLinkIds}');
      
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _assignedToController.text = widget.task!.assignedTo ?? '';
      _dueDate = widget.task!.dueDate;
      _reminderTime = widget.task!.reminderTime;
      _priority = widget.task!.priority;
      _status = widget.task!.status;
      _isRecurringReminder = widget.task!.isRecurringReminder;
      _recurringReminderPattern = widget.task!.recurringReminderPattern ?? RecurringReminderPattern.fiveMinutes;
      
      // ピン留め状態を読み込み
      _loadPinnedState();
      
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
    // 説明に混入した「リンク: ...」行を除去
    _sanitizeDescription();
    
    // 連絡先リストを初期化
    Future.microtask(() => _loadContacts());
  }

  void _sanitizeDescription() {
    final text = _descriptionController.text;
    if (text.isEmpty) return;
    final cleaned = text.replaceAll(RegExp(r'^リンク:\s.*$', multiLine: true), '').trim();
    if (cleaned != text) {
      _descriptionController.text = cleaned;
    }
  }

  // リンク情報から初期値を設定
  void _initializeFromLink() {
    try {
      final linkViewModel = ref.read(linkViewModelProvider.notifier);
      final link = linkViewModel.getLinkById(widget.relatedLinkId!);
      if (link != null) {
        _titleController.text = link.label;
        // 説明へリンク文字列を自動挿入しない（カード側の関連リンク表示に任せる）
        
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
    _subTaskTitleController.dispose();
    _subTaskMinutesController.dispose();
    _subTaskDescriptionController.dispose();
    _toController.dispose();
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

  Future<void> _saveTask() async {
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
        print('元のGoogle CalendarイベントID: ${widget.task!.googleCalendarEventId}');
        print('ダイアログのリマインダー時間: $_reminderTime');
        print('ダイアログの期限日: $_dueDate');
        print('_reminderTimeの型: ${_reminderTime.runtimeType}');
        print('_reminderTime == null: ${_reminderTime == null}');
        print('_dueDate == null: ${_dueDate == null}');
        
        // サブタスク統計は最新を維持する
        final latestTask = ref.read(taskViewModelProvider).firstWhere(
          (t) => t.id == widget.task!.id,
          orElse: () => widget.task!,
        );
        final updatedTask = latestTask.copyWith(
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
          // Google CalendarイベントIDを保持
          googleCalendarEventId: widget.task!.googleCalendarEventId,
          // 関連リンクIDを保持
          relatedLinkIds: latestTask.relatedLinkIds,
          clearDueDate: _dueDate == null && widget.task!.dueDate != null, // 期限日が削除された場合
          clearReminderTime: _reminderTime == null && widget.task!.reminderTime != null, // リマインダーが削除された場合
          clearAssignedTo: _assignedToController.text.trim().isEmpty && widget.task!.assignedTo != null, // 依頼先が削除された場合
          clearDescription: _descriptionController.text.trim().isEmpty && widget.task!.description != null, // 説明が削除された場合
        );
        
        print('copyWith後のリマインダー時間: ${updatedTask.reminderTime}');
        print('copyWith後の期限日: ${updatedTask.dueDate}');
        print('copyWith後のGoogle CalendarイベントID: ${updatedTask.googleCalendarEventId}');
        print('新しいリマインダー時間: ${updatedTask.reminderTime}');
        print('新しい期限日: ${updatedTask.dueDate}');
        print('リマインダーがクリアされた: ${widget.task!.reminderTime != null && updatedTask.reminderTime == null}');
        print('期限日がクリアされた: ${widget.task!.dueDate != null && updatedTask.dueDate == null}');
        
        print('=== タスク更新時のリマインダー設定 ===');
        print('タスク: ${updatedTask.title}');
        print('リマインダー時間: ${updatedTask.reminderTime}');
        print('変更前のリマインダー時間: ${widget.task!.reminderTime}');
        
        await taskViewModel.updateTask(updatedTask);
        // 念のためサブタスク統計を最新化
        await ref.read(taskViewModelProvider.notifier).updateSubTaskStatistics(updatedTask.id);
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
        
        await taskViewModel.addTask(task);
        
        // 新規タスク作成時にメール送信情報が一時保存されている場合は、正しいタスクIDで保存
        if (_pendingMailLog != null) {
          try {
            final mailService = MailService();
            await mailService.initialize();
            
            await mailService.saveMailLogWithToken(
              taskId: task.id,
              app: _pendingMailLog!['app'],
              to: _pendingMailLog!['to'],
              subject: _pendingMailLog!['subject'],
              body: _pendingMailLog!['body'],
              token: _pendingMailLog!['token'],
            );
            
            if (kDebugMode) {
              print('新規タスク作成時: メール送信情報を正しいタスクID (${task.id}) で保存完了');
            }
            
            // 一時保存された情報をクリア
            _pendingMailLog = null;
          } catch (e) {
            if (kDebugMode) {
              print('新規タスク作成時: メール送信情報の保存エラー: $e');
            }
          }
        }
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
          // 入力時のキー操作はすべてテキスト入力に委ねる
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).maybePop();
          }
        },
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: Dialog(
            child: Container(
          width: MediaQuery.of(context).size.width * 0.75, // 画面の約75%まで拡張
          constraints: BoxConstraints(
            minWidth: 720,
            maxWidth: 1200,
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          padding: EdgeInsets.all(28 * ref.watch(uiDensityProvider)), // パディングを増やして余裕のあるレイアウトに
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24), // 角丸を大きくしてモダンな印象に
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // スクロール可能なコンテンツ
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
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
                        
                        // ワイド時は左（タイトル+本文+説明）と右（期限+優先度+ステータス+リマインダー）の2カラム
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 900;
                            if (!isWide) {
                              return Column(
                                children: [
                                  _buildLeftColumnControls(context),
                                  const SizedBox(height: 16),
                                  _buildRightColumnControls(context),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: _buildLeftColumnControls(context)),
                                const SizedBox(width: 16),
                                Expanded(flex: 1, child: _buildRightColumnControls(context)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // サブタスク編集セクション（トグル）
                        _buildSubTaskSectionToggle(),
                        
                        // メール送信セクション（アコーディオン）
                        _buildMailSectionAccordion(),
                      ],
                    ),
                  ),
                ),
                
                // 固定フッター（ボタン）
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // チームタスクの場合は完了報告ボタンを追加
                      if (widget.task?.isTeamTask == true && widget.task?.status == TaskStatus.completed) ...[
                        ElevatedButton.icon(
                          onPressed: _showCompletionReportDialog,
                          icon: const Icon(Icons.report),
                          label: const Text('完了報告'),
                          style: AppButtonStyles.primary(context),
                        ),
                        const SizedBox(width: 8),
                      ],
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: AppButtonStyles.text(context),
                        child: const Text('キャンセル'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveTask,
                        style: AppButtonStyles.primary(context),
                        child: Text(widget.task != null ? '更新' : '作成'),
                      ),
                    ],
                  ),
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

  void _loadPinnedState() {
    if (widget.task == null) return;
    try {
      final box = Hive.box('pinnedTasks');
      final ids = box.get('ids', defaultValue: <String>[]) as List;
      _isPinned = ids.contains(widget.task!.id);
    } catch (_) {}
  }

  void _savePinnedState() {
    if (widget.task == null) return;
    try {
      final box = Hive.box('pinnedTasks');
      final ids = (box.get('ids', defaultValue: <String>[]) as List).map((e) => e.toString()).toSet();
      if (_isPinned) {
        ids.add(widget.task!.id);
      } else {
        ids.remove(widget.task!.id);
      }
      box.put('ids', ids.toList());
    } catch (_) {}
  }

  void _togglePin() {
    setState(() {
      _isPinned = !_isPinned;
    });
    _savePinnedState();
  }

  /// 左カラム（タイトル+本文+説明）を構築
  Widget _buildLeftColumnControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイトル
        TextFormField(
          controller: _titleController,
          enableInteractiveSelection: true,
          style: TextStyle(
            color: Color(ref.watch(titleTextColorProvider)),
            fontSize: 16 * ref.watch(titleFontSizeProvider),
            fontFamily: ref.watch(titleFontFamilyProvider).isEmpty ? null : ref.watch(titleFontFamilyProvider),
          ),
          decoration: InputDecoration(
            labelText: 'タイトル *',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'タイトルを入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 本文 + 説明（ワイド時は2カラム）
        _buildBodyAndDescription(context),
      ],
    );
  }

  Widget _buildBodyAndDescription(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        Widget memoField = TextFormField(
          controller: _assignedToController,
          maxLines: isWide ? 10 : 4,
          minLines: 4,
          textAlignVertical: TextAlignVertical.top,
          enableInteractiveSelection: true,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: TextStyle(
            color: Color(ref.watch(memoTextColorProvider)),
            fontSize: 16 * ref.watch(memoFontSizeProvider),
            fontFamily: ref.watch(memoFontFamilyProvider).isEmpty ? null : ref.watch(memoFontFamilyProvider),
          ),
          decoration: InputDecoration(
            labelText: '本文',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        Widget descField = TextFormField(
          controller: _descriptionController,
          maxLines: isWide ? 8 : 3,
          minLines: 1,
          enableInteractiveSelection: true,
          style: TextStyle(
            color: Color(ref.watch(descriptionTextColorProvider)),
            fontSize: 16 * ref.watch(descriptionFontSizeProvider),
            fontFamily: ref.watch(descriptionFontFamilyProvider).isEmpty ? null : ref.watch(descriptionFontFamilyProvider),
          ),
          decoration: InputDecoration(
            labelText: '依頼先への説明',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        if (!isWide) {
          return Column(children: [memoField, const SizedBox(height: 16), descField]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: memoField), const SizedBox(width: 16), Expanded(child: descField)],
        );
      },
    );
  }

  /// 右カラム（期限/優先度/ステータス/リマインダー）を構築
  Widget _buildRightColumnControls(BuildContext context) {
    return Column(
      children: [
        _buildDueDateField(context),
        const SizedBox(height: 16),
        _buildPriorityField(context),
        const SizedBox(height: 16),
        _buildStatusField(context),
        const SizedBox(height: 16),
        _buildReminderToggle(context),
        const SizedBox(height: 16),
        _buildLinkAssociationButton(context),
        const SizedBox(height: 16),
        _buildPinButton(context),
      ],
    );
  }

  Widget _buildDueDateField(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context, true),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '期限日',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _dueDate != null ? DateFormat('yyyy/MM/dd').format(_dueDate!) : '期限日を選択',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (_dueDate != null)
              IconButton(
                onPressed: () => setState(() => _dueDate = null),
                icon: const Icon(Icons.clear, size: 18),
                tooltip: '期限日をクリア',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityField(BuildContext context) {
    return DropdownButtonFormField<TaskPriority>(
      value: _priority,
      decoration: const InputDecoration(
        labelText: '優先度',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      isExpanded: true,
      items: TaskPriority.values.map((priority) {
        return DropdownMenuItem(
          value: priority,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: Color(_getPriorityColor(priority)), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(_getPriorityText(priority)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _priority = value);
      },
    );
  }

  Widget _buildStatusField(BuildContext context) {
    return DropdownButtonFormField<TaskStatus>(
      value: _status,
      decoration: const InputDecoration(
        labelText: 'ステータス',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      isExpanded: true,
      items: TaskStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: Color(_getStatusColor(status)), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(_getStatusText(status)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _status = value);
      },
    );
  }

  Widget _buildReminderToggle(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isReminderSectionExpanded = !_isReminderSectionExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('リマインダー機能', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (_reminderTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Text(DateFormat('MM/dd HH:mm').format(_reminderTime!),
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w500)),
                  ),
                const SizedBox(width: 8),
                Icon(_isReminderSectionExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
        if (_isReminderSectionExpanded) ...[
          const SizedBox(height: 12),
          _buildReminderDetails(context),
        ],
      ],
    );
  }

  Widget _buildReminderDetails(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'リマインダー日',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(_reminderTime != null ? DateFormat('yyyy/MM/dd').format(_reminderTime!) : 'リマインダー日を選択',
                    style: const TextStyle(fontSize: 14)),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(_reminderTime != null ? DateFormat('HH:mm').format(_reminderTime!) : '時刻を選択',
                    style: const TextStyle(fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_reminderTime != null)
              IconButton(
                onPressed: () => setState(() {
                  _reminderTime = null;
                  _isRecurringReminder = false;
                  _recurringReminderPattern = '';
                }),
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'リマインダーをクリア',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(value: _isRecurringReminder, onChanged: (value) => setState(() => _isRecurringReminder = value ?? false)),
            Text('繰り返しリマインダー',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            if (_isRecurringReminder) ...[
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: RecurringReminderPattern.allPatterns.contains(_recurringReminderPattern)
                      ? _recurringReminderPattern : RecurringReminderPattern.fiveMinutes,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 14),
                  items: RecurringReminderPattern.allPatterns.map((pattern) {
                    return DropdownMenuItem(
                      value: pattern,
                      child: Text(RecurringReminderPattern.getDisplayName(pattern), style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _recurringReminderPattern = value);
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// リンク関連付けボタンを構築
  Widget _buildLinkAssociationButton(BuildContext context) {
    if (widget.task == null) return const SizedBox.shrink(); // 新規作成時は非表示
    
    // リンクの数を取得
    final linkCount = widget.task!.relatedLinkIds.length;
    
    return InkWell(
      onTap: () => _showLinkAssociationDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: linkCount > 0 ? Colors.orange.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(
              linkCount > 0 ? Icons.link : Icons.link_off,
              color: linkCount > 0 ? Colors.orange.shade600 : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('リンク関連付け', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (linkCount > 0) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$linkCount',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ピン留めボタンを構築
  Widget _buildPinButton(BuildContext context) {
    if (widget.task == null) return const SizedBox.shrink(); // 新規作成時は非表示
    
    return InkWell(
      onTap: _togglePin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: _isPinned ? Colors.blue.shade300 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: _isPinned ? Colors.blue.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? Colors.blue.shade600 : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isPinned ? '上部にピン留め中' : 'ピン留め',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _isPinned ? Colors.blue.shade600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// リンク関連付けダイアログを表示
  void _showLinkAssociationDialog(BuildContext context) {
    if (widget.task == null) return;
    
    showDialog(
      context: context,
      builder: (context) => LinkAssociationDialog(
        task: widget.task!,
        onLinksUpdated: () {
          // UIを更新
          setState(() {});
        },
      ),
    );
  }

  // サブタスク編集セクション（トグル版）
  Widget _buildSubTaskSectionToggle() {
    final subTasks = ref.watch(subTaskViewModelProvider)
        .where((s) => s.parentTaskId == (widget.task?.id ?? ''))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    
    final hasSubTasks = subTasks.isNotEmpty;
    
    return Column(
      children: [
        // サブタスクヘッダー（トグル）
        InkWell(
          onTap: () => setState(() => _isSubTaskSectionExpanded = !_isSubTaskSectionExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.subdirectory_arrow_right,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'サブタスク',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const Spacer(),
                if (hasSubTasks)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${subTasks.where((s) => s.isCompleted).length}/${subTasks.length} 完了',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  _isSubTaskSectionExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
        
        // サブタスク詳細（展開時のみ表示）
        if (_isSubTaskSectionExpanded) ...[
          const SizedBox(height: 12),
          _buildSubTaskSection(),
        ],
      ],
    );
  }

  // サブタスク編集セクション
  Widget _buildSubTaskSection() {
    final subTasks = ref.watch(subTaskViewModelProvider)
        .where((s) => s.parentTaskId == (widget.task?.id ?? ''))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.subdirectory_arrow_right, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('サブタスク', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (widget.task != null)
                  Text('${subTasks.where((s)=>s.isCompleted).length}/${subTasks.length} 完了',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      TextField(
                        controller: _subTaskTitleController,
                        decoration: InputDecoration(
                          labelText: 'サブタスク名',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade600, width: 2.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                          ),
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _subTaskDescriptionController,
                        decoration: InputDecoration(
                          labelText: '説明',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade600, width: 2.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                          ),
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _subTaskMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '推定(分)',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade600, width: 2.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                      ),
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (widget.task == null) {
                      SnackBarService.showInfo(context, '先にタスクを作成してください');
                      return;
                    }
                    final vm = ref.read(subTaskViewModelProvider.notifier);
                    final minutes = int.tryParse(_subTaskMinutesController.text);
                    if (_editingSubTask == null) {
                      // 追加
                      final title = _subTaskTitleController.text.trim();
                      if (title.isEmpty) {
                        SnackBarService.showError(context, 'サブタスクのタイトルは必須です');
                        return;
                      }
                      final newSub = vm.createSubTask(
                        title: title,
                        description: _subTaskDescriptionController.text.trim().isEmpty
                            ? null
                            : _subTaskDescriptionController.text.trim(),
                        parentTaskId: widget.task!.id,
                        estimatedMinutes: minutes,
                        notes: null,
                      );
                      await vm.addSubTask(newSub);
                    } else {
                      // 更新
                      final title = _subTaskTitleController.text.trim();
                      if (title.isEmpty) {
                        SnackBarService.showError(context, 'サブタスクのタイトルは必須です');
                        return;
                      }
                      final updated = _editingSubTask!.copyWith(
                        title: title,
                        description: _subTaskDescriptionController.text.trim().isEmpty
                            ? _editingSubTask!.description
                            : _subTaskDescriptionController.text.trim(),
                        estimatedMinutes: minutes,
                      );
                      await vm.updateSubTask(updated);
                      _editingSubTask = null;
                    }
                    _subTaskTitleController.clear();
                    _subTaskMinutesController.clear();
                    _subTaskDescriptionController.clear();
                    // 親統計更新
                    await ref.read(taskViewModelProvider.notifier).updateSubTaskStatistics(widget.task!.id);
                    setState((){});
                  },
                  child: Text(_editingSubTask == null ? '追加' : '更新'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.task == null)
              const Text('※ タスク作成後にサブタスク編集が可能になります', style: TextStyle(fontSize: 12, color: Colors.grey)),
            if (widget.task != null)
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: subTasks.length,
                itemBuilder: (context, index) {
                  final s = subTasks[index];
                  return ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: s.isCompleted,
                      onChanged: (_) async {
                        final vm = ref.read(subTaskViewModelProvider.notifier);
                        if (s.isCompleted) {
                          await vm.uncompleteSubTask(s.id);
                        } else {
                          await vm.completeSubTask(s.id);
                        }
                        await ref.read(taskViewModelProvider.notifier).updateSubTaskStatistics(widget.task!.id);
                        setState((){});
                      },
                    ),
                    title: Text(s.title, overflow: TextOverflow.ellipsis),
                    subtitle: Row(children: [
                      if (s.estimatedMinutes!=null)
                        Text('推定: ${s.estimatedMinutes}分', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      if (s.completedAt!=null) ...[
                        const SizedBox(width: 8),
                        Text('完了: ${DateFormat('MM/dd HH:mm').format(s.completedAt!)}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                      ],
                    ]),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _subTaskTitleController.text = s.title;
                          _subTaskMinutesController.text = s.estimatedMinutes?.toString() ?? '';
                          _subTaskDescriptionController.text = s.description ?? '';
                          _editingSubTask = s;
                          setState((){});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await ref.read(subTaskViewModelProvider.notifier).deleteSubTask(s.id);
                          await ref.read(taskViewModelProvider.notifier).updateSubTaskStatistics(widget.task!.id);
                          setState((){});
                        },
                      ),
                    ]),
                  );
                },
              ),
          ],
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

  /// メール送信セクション（アコーディオン）を構築
  Widget _buildMailSectionAccordion() {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.email, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'メール送信機能',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Text(
          _isMailSectionExpanded ? 'メール機能を折りたたむ' : 'メール送信とテンプレート機能',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        initiallyExpanded: _isMailSectionExpanded,
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isMailSectionExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildMailSection(),
          ),
        ],
      ),
    );
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
              CheckboxListTile(
                value: _includeSubtasksInMail,
                onChanged: (value) {
                  setState(() {
                    _includeSubtasksInMail = value ?? true;
                  });
                },
                title: const Text('本文にサブタスクを含める'),
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
            style: TextStyle(
              color: Color(ref.watch(textColorProvider)),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: 'To',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
              ),
              prefixIcon: Icon(Icons.person, color: Colors.grey.shade600),
              hintText: '空でもメーラーが起動します',
              helperText: '※空の場合はメーラーで直接アドレスを指定できます',
              labelStyle: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 送信アプリ選択（縦並びでレイアウト）
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('送信アプリ:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Radio<String>(
                    value: 'outlook',
                    groupValue: _selectedMailApp,
                    onChanged: (value) {
                      setState(() {
                        _selectedMailApp = value!;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text('Outlook（デスクトップ）'),
                  ),
                ],
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'gmail',
                    groupValue: _selectedMailApp,
                    onChanged: (value) {
                      setState(() {
                        _selectedMailApp = value!;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text('Gmail（Web）'),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 各メーラー個別テストボタン（縦並びでレイアウト）
          Column(
            children: [
              // Outlookテストボタン
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedMailApp == 'outlook' ? Colors.blue : Colors.grey.shade300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _selectedMailApp == 'outlook' ? Colors.blue.shade50 : Colors.grey.shade50,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _testOutlookConnection(),
                    icon: const Icon(Icons.business, size: 16),
                    label: const Text('Outlookテスト'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: _selectedMailApp == 'outlook' ? Colors.blue : Colors.grey.shade600,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Gmailテストボタン
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedMailApp == 'gmail' ? Colors.red : Colors.grey.shade300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _selectedMailApp == 'gmail' ? Colors.red.shade50 : Colors.grey.shade50,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _testGmailConnection(),
                    icon: const Icon(Icons.mail, size: 16),
                    label: const Text('Gmailテスト'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: _selectedMailApp == 'gmail' ? Colors.red : Colors.grey.shade600,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
        // テンプレートと履歴ボタン
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showTemplateDialog,
                icon: const Icon(Icons.description),
                label: const Text('テンプレート'),
                style: AppButtonStyles.secondary(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showHistoryDialog,
                icon: const Icon(Icons.history),
                label: const Text('送信履歴'),
                style: AppButtonStyles.primary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
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
                    style: AppButtonStyles.primary(context),
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
                  style: _pendingMailTo != null 
                    ? AppButtonStyles.primary(context)
                    : ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

      // 件名と本文を構築
      String subject = _titleController.text.trim(); // デフォルトでタイトルを件名に
      String body = _copyMemoToBody ? _assignedToController.text.trim() : '';
      
      // 件名が空の場合はデフォルトの件名を設定
      if (subject.isEmpty) {
        subject = 'タスク関連メール';
      }

      final mailService = MailService();
      await mailService.initialize();
      
      // UUIDを生成
      final token = mailService.makeToken();
      final finalSubject = '$subject [$token]';
      final finalBody = _createEnhancedMailBody(body, token);
      
      // メール送信情報を一時保存（UUID付き）
      _pendingMailTo = to;
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
          subject: finalSubject,
          body: finalBody,
        );
      } else if (_selectedMailApp == 'outlook') {
        await mailService.launchOutlookDesktop(
          to: to,
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

      // メーラーでの編集内容は反映せず、元の内容で保存

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

      // 新規タスク作成時の場合は、メール送信情報を一時保存して後で関連付け
      if (widget.task == null) {
        // 一時保存用のメール送信情報を保存
        _pendingMailLog = {
          'taskId': taskId,
          'app': _pendingMailApp!,
          'to': _pendingMailTo!,
          'subject': _pendingMailSubject!,
          'body': _pendingMailBody!,
          'token': token,
        };
        
        if (kDebugMode) {
          print('新規タスク作成時: メール送信情報を一時保存');
        }
      } else {
        // 既存タスクの場合は即座に保存
        await mailService.saveMailLogWithToken(
          taskId: taskId,
          app: _pendingMailApp!,
          to: _pendingMailTo!,
          subject: _pendingMailSubject!,
          body: _pendingMailBody!,
          token: token,
        );
      }

      // 連絡先の使用回数を更新
      if (_selectedContacts.isNotEmpty) {
        final contactService = EmailContactService();
        await contactService.initialize();
        
        for (final contact in _selectedContacts) {
          await contactService.updateContactUsage(contact.email);
        }
      }

      // メール送信完了後の処理
      await _handleMailSentCompletion();

      // 一時保存された情報をクリア
      _pendingMailTo = null;
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
      
      // タスク画面のUIを強制更新（メールバッジ表示のため）
      if (widget.task != null) {
        print('=== メールバッジ表示更新開始 ===');
        print('タスクID: ${widget.task!.id}');
        
        // タスク画面の状態を更新（stateを直接更新）
        final currentTasks = ref.read(taskViewModelProvider);
        ref.read(taskViewModelProvider.notifier).state = [...currentTasks];
        
        // さらに、メールバッジの表示を強制更新するため、少し遅延して再度更新
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            final updatedTasks = ref.read(taskViewModelProvider);
            ref.read(taskViewModelProvider.notifier).state = [...updatedTasks];
            print('メールバッジ表示更新完了');
          }
        });
        
        // さらに遅延して最終更新
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            final finalTasks = ref.read(taskViewModelProvider);
            ref.read(taskViewModelProvider.notifier).state = [...finalTasks];
            print('メールバッジ最終更新完了');
          }
        });
      }
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
          Text(
            'よく使われる連絡先:',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                        color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary 
                          : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    backgroundColor: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Theme.of(context).colorScheme.surface,
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

  /// タスクの関連リンクを取得
  List<LinkItem> _getRelatedLinks(TaskItem task) {
    final groups = ref.read(linkViewModelProvider);
    final relatedLinks = <LinkItem>[];
    
    if (kDebugMode) {
      print('=== 関連リンク取得開始 ===');
      print('タスクID: ${task.id}');
      print('関連リンクID数: ${task.relatedLinkIds.length}');
      print('関連リンクID: ${task.relatedLinkIds}');
      print('リンクグループ数: ${groups.groups.length}');
    }
    
    for (final linkId in task.relatedLinkIds) {
      bool found = false;
      for (final group in groups.groups) {
        for (final link in group.items) {
          if (link.id == linkId) {
            relatedLinks.add(link);
            found = true;
            if (kDebugMode) {
              print('関連リンク発見: ${link.label} (${link.id})');
            }
            break;
          }
        }
        if (found) break;
      }
      if (!found && kDebugMode) {
        print('関連リンクが見つかりません: $linkId');
      }
    }
    
    if (kDebugMode) {
      print('取得された関連リンク数: ${relatedLinks.length}');
      print('=== 関連リンク取得完了 ===');
    }
    
    return relatedLinks;
  }

  /// 強化されたメール本文を作成
  String _createEnhancedMailBody(String originalBody, String token) {
    final currentTime = DateTime.now();
    final formattedTime = '${currentTime.year}年${currentTime.month}月${currentTime.day}日 ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
    
    // タスク情報を取得
    final taskTitle = widget.task?.title ?? _titleController.text.trim();
    final taskDescription = widget.task?.description ?? _descriptionController.text.trim();
    final taskDueDate = widget.task?.dueDate;
    final taskStatus = widget.task?.status;
    
    String taskInfo = '';
    if (taskTitle.isNotEmpty) {
      taskInfo += 'タスク: $taskTitle\n';
    }
    if (taskDescription.isNotEmpty) {
      taskInfo += '説明: $taskDescription\n';
    }
    
    // サブタスク情報を追加（チェックONの時のみ）
    String subtaskInfo = '';
    print('デバッグ: _includeSubtasksInMail=$_includeSubtasksInMail');
    print('デバッグ: widget.task != null=${widget.task != null}');
    if (widget.task != null) {
      print('デバッグ: widget.task!.hasSubTasks=${widget.task!.hasSubTasks}');
      print('デバッグ: widget.task!.totalSubTasksCount=${widget.task!.totalSubTasksCount}');
    }
    if (_includeSubtasksInMail && widget.task != null) {
      // サブタスク詳細リスト
      final subtasks = ref.read(subTaskViewModelProvider)
          .where((s) => s.parentTaskId == widget.task!.id)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      
      if (subtasks.isNotEmpty) {
        subtaskInfo += '\nサブタスク進捗: ${widget.task!.completedSubTasksCount}/${widget.task!.totalSubTasksCount}\n';
      for (final s in subtasks) {
        final mark = s.isCompleted ? '✅' : '⬜️';
        final est = s.estimatedMinutes != null ? ' (${s.estimatedMinutes}分)' : '';
        final done = s.completedAt != null ? '｜完了: ${DateFormat('MM/dd HH:mm').format(s.completedAt!)}' : '';
        subtaskInfo += '- $mark ${s.title}$est$done\n';
      }
      }
    }
    if (taskDueDate != null) {
      final dueDateStr = '${taskDueDate.year}年${taskDueDate.month}月${taskDueDate.day}日';
      taskInfo += '期限: $dueDateStr\n';
    }
    if (taskStatus != null) {
      final statusText = _getStatusText(taskStatus);
      taskInfo += 'ステータス: $statusText\n';
    }
    
    // 関連リンク情報を取得
    String linksInfo = '';
    if (widget.task != null) {
      final relatedLinks = _getRelatedLinks(widget.task!);
      if (relatedLinks.isNotEmpty) {
        linksInfo += 'リンク:\n';
        for (final link in relatedLinks) {
          // Gmail用のリンク表示を改善
          if (link.path.startsWith('http')) {
            // HTTP/HTTPSリンクはそのまま表示
            linksInfo += '• ${link.label}\n  ${link.path}\n';
          } else if (link.path.startsWith(r'\\')) {
            // UNCパスは説明付きで表示
            linksInfo += '• ${link.label}\n  ${link.path}\n';
          } else if (link.path.contains(':\\')) {
            // ローカルファイルパスは説明付きで表示
            linksInfo += '• ${link.label}\n  ${link.path}\n';
          } else {
            // その他のパス
            linksInfo += '• ${link.label} - ${link.path}\n';
          }
        }
        
        // メールアプリに応じた注意書きを追加
        if (_selectedMailApp == 'gmail') {
          linksInfo += '\n📝 注意: ネットワーク共有やローカルファイルのリンクは、Gmailでは直接クリックできません。\n';
          linksInfo += 'リンクをコピーして、ファイルエクスプローラーやブラウザのアドレスバーに貼り付けてアクセスしてください。\n';
        } else if (_selectedMailApp == 'outlook') {
          linksInfo += '\n📝 注意: Outlookでは、ネットワーク共有やローカルファイルのリンクもクリック可能です。\n';
          linksInfo += 'リンクをクリックして直接アクセスできます。\n';
        }
      }
    }
    
    final enhancedBody = '''
${originalBody.isNotEmpty ? originalBody : 'メッセージがありません。'}
────────────────────────────────────────────────────────
【関連タスク情報】
${taskInfo.isNotEmpty ? taskInfo : 'タスク情報がありません。'}
${subtaskInfo.isNotEmpty ? subtaskInfo : ''}
${linksInfo.isNotEmpty ? '────────────────────────────────────────────────────────\n\n【関連資料】\n$linksInfo' : ''}
────────────────────────────────────────────────────────
【メール情報】
送信日時: $formattedTime
送信ID: $token
────────────────────────────────────────────────────────
''';
    
    return enhancedBody;
  }

  /// 強化されたHTMLメール本文を作成
  String _createEnhancedHtmlMailBody(String originalBody, String token) {
    final currentTime = DateTime.now();
    final formattedTime = '${currentTime.year}年${currentTime.month}月${currentTime.day}日 ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
    
    // タスク情報を取得
    final taskTitle = widget.task?.title ?? _titleController.text.trim();
    final taskDescription = widget.task?.description ?? _descriptionController.text.trim();
    final taskDueDate = widget.task?.dueDate;
    final taskStatus = widget.task?.status;
    
    String taskInfo = '';
    if (taskTitle.isNotEmpty) {
      taskInfo += '<div style="margin-bottom: 8px;"><strong>タスク:</strong> $taskTitle</div>';
    }
    if (taskDescription.isNotEmpty) {
      taskInfo += '<div style="margin-bottom: 8px;"><strong>説明:</strong> $taskDescription</div>';
    }
    
    // サブタスク情報を追加（チェックONの時のみ）
    String subtaskInfo = '';
    if (_includeSubtasksInMail && widget.task != null) {
      final subtasks = ref.read(subTaskViewModelProvider)
          .where((s) => s.parentTaskId == widget.task!.id)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      
      if (subtasks.isNotEmpty) {
        final progress = '<div style="margin: 10px 0;"><strong>サブタスク進捗:</strong> ${widget.task!.completedSubTasksCount}/${widget.task!.totalSubTasksCount}</div>';
      final items = subtasks.map((s) {
        final mark = s.isCompleted ? '✅' : '⬜️';
        final est = s.estimatedMinutes != null ? ' (${s.estimatedMinutes}分)' : '';
        final done = s.completedAt != null ? '｜完了: ${DateFormat('MM/dd HH:mm').format(s.completedAt!)}' : '';
        final safe = s.title
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;');
        return '<li>$mark $safe$est$done</li>';
      }).join();
      subtaskInfo += '$progress<ul style="margin: 5px 0 10px 20px;">$items</ul>';
      }
    }
    if (taskDueDate != null) {
      final dueDateStr = '${taskDueDate.year}年${taskDueDate.month}月${taskDueDate.day}日';
      taskInfo += '<div style="margin-bottom: 8px;"><strong>期限:</strong> $dueDateStr</div>';
    }
    if (taskStatus != null) {
      final statusText = _getStatusText(taskStatus);
      taskInfo += '<div style="margin-bottom: 8px;"><strong>ステータス:</strong> $statusText</div>';
    }
    
    // 関連リンク情報を取得
    String linksInfo = '';
    if (widget.task != null) {
      final relatedLinks = _getRelatedLinks(widget.task!);
      if (relatedLinks.isNotEmpty) {
        linksInfo += '<div style="margin: 15px 0;"><strong>関連資料:</strong><ul style="margin: 5px 0;">';
        for (final link in relatedLinks) {
          if (link.path.startsWith('http')) {
            // HTTP/HTTPSリンクはクリック可能
            linksInfo += '<li><a href="${link.path}" style="color: #007bff; text-decoration: underline;">${link.label}</a><br><small style="color: #666;">${link.path}</small></li>';
          } else if (link.path.startsWith(r'\\')) {
            // UNCパスの処理
            if (_selectedMailApp == 'outlook') {
              // Outlookではクリック可能なリンクとして表示
              final encodedPath = Uri.encodeComponent(link.path);
              final fileUrl1 = 'file:///$encodedPath';
              final fileUrl2 = 'file://${link.path.replaceAll(r'\', '/')}';
              linksInfo += '<li style="margin-bottom: 8px;"><a href="$fileUrl1" style="color: #007bff; text-decoration: underline;">${link.label}</a><br>';
              linksInfo += '<small style="color: #666;">${link.path}</small><br>';
              if (link.path.length > 100) {
                linksInfo += '<a href="$fileUrl2" style="color: #6c757d; text-decoration: underline; font-size: 11px;">[代替リンク]</a> ';
              }
              linksInfo += '<small style="color: #999; font-size: 11px;">※ リンクが機能しない場合は、パスをコピーしてエクスプローラーのアドレスバーに貼り付けてください</small></li>';
            } else {
              // Gmailでは説明付きで表示（クリック不可）
              linksInfo += '<li style="margin-bottom: 8px;"><strong>${link.label}</strong><br><small style="color: #666;">${link.path}</small></li>';
            }
          } else if (link.path.contains(':\\')) {
            // ローカルファイルパスの処理
            if (_selectedMailApp == 'outlook') {
              // Outlookではクリック可能なリンクとして表示
              final encodedPath = Uri.encodeComponent(link.path);
              final fileUrl = 'file:///$encodedPath';
              linksInfo += '<li style="margin-bottom: 8px;"><a href="$fileUrl" style="color: #007bff; text-decoration: underline;">${link.label}</a><br><small style="color: #666;">${link.path}</small></li>';
            } else {
              // Gmailでは説明付きで表示（クリック不可）
              linksInfo += '<li style="margin-bottom: 8px;"><strong>${link.label}</strong><br><small style="color: #666;">${link.path}</small></li>';
            }
          } else {
            // その他のパス
            linksInfo += '<li><strong>${link.label}</strong><br><small style="color: #666;">${link.path}</small></li>';
          }
        }
        linksInfo += '</ul>';
        
        // メールアプリに応じた注意書きを追加
        if (_selectedMailApp == 'gmail') {
          linksInfo += '<div style="margin-top: 10px; padding: 8px; background-color: #f8f9fa; border-left: 3px solid #007bff; font-size: 12px; color: #666;">';
          linksInfo += '<strong>📝 注意:</strong> ネットワーク共有やローカルファイルのリンクは、Gmailでは直接クリックできません。<br>';
          linksInfo += 'リンクをコピーして、ファイルエクスプローラーやブラウザのアドレスバーに貼り付けてアクセスしてください。';
          linksInfo += '</div></div>';
        } else if (_selectedMailApp == 'outlook') {
          linksInfo += '<div style="margin-top: 10px; padding: 8px; background-color: #e8f5e8; border-left: 3px solid #28a745; font-size: 12px; color: #666;">';
          linksInfo += '<strong>📝 注意:</strong> Outlookでは、ネットワーク共有やローカルファイルのリンクもクリック可能です。<br>';
          linksInfo += 'リンクをクリックして直接アクセスできます。<br>';
          linksInfo += '<strong>※ 長いパスでリンクが途中で切れる場合は、パスをコピーしてエクスプローラーのアドレスバーに貼り付けてください。</strong>';
          linksInfo += '</div></div>';
        }
      }
    }
    
    final memoHtml = originalBody.isNotEmpty 
        ? '<div style="margin: 15px 0;"><strong>メモ:</strong><br>${originalBody.replaceAll('\n', '<br>')}</div>'
        : '<div style="margin: 15px 0;">メッセージがありません。</div>';
    
    return '''
    <html>
    <body style="font-family: 'Segoe UI', 'Meiryo', sans-serif; font-size: 14px; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background-color: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        
        <div style="border-bottom: 2px solid #007bff; padding-bottom: 10px; margin-bottom: 20px;">
          <h2 style="color: #007bff; margin: 0; font-size: 18px;">📋 タスク情報</h2>
        </div>
        
        <div style="margin-bottom: 20px;">
          ${taskInfo.isNotEmpty ? taskInfo : '<div>タスク情報がありません。</div>'}
          ${subtaskInfo.isNotEmpty ? subtaskInfo : ''}
        </div>
        
        $memoHtml
        
        $linksInfo
        
        <div style="margin-top: 20px; padding-top: 15px; border-top: 1px solid #e9ecef; font-size: 12px; color: #6c757d;">
          <div style="display: inline-block; background-color: #007bff; color: white; padding: 4px 8px; border-radius: 4px; margin-bottom: 8px;">Link Navigator</div>
          <div>送信日時: $formattedTime</div>
          <div>送信ID: $token</div>
        </div>
        
      </div>
    </body>
    </html>
    ''';
  }


  /// メール送信完了後の処理
  Future<void> _handleMailSentCompletion() async {
    try {
      if (kDebugMode) {
        print('=== メール送信完了後の処理開始 ===');
      }
      
      // メール送信完了を記録（必要に応じてタスクのステータスを更新）
      if (widget.task != null) {
        // タスクが存在する場合、メール送信完了を記録
        if (kDebugMode) {
          print('タスク「${widget.task!.title}」のメール送信完了を記録');
        }
        
        // 必要に応じてタスクのメモにメール送信情報を追加
        await _updateTaskWithMailInfo();
      }
      
      if (kDebugMode) {
        print('=== メール送信完了後の処理完了 ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('メール送信完了後の処理エラー: $e');
      }
    }
  }

  /// タスクにメール送信情報を追加
  Future<void> _updateTaskWithMailInfo() async {
    try {
      if (widget.task == null) return;
      
      final taskViewModel = ref.read(taskViewModelProvider.notifier);
      final currentTime = DateTime.now();
      final timeStr = '${currentTime.year}/${currentTime.month}/${currentTime.day} ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
      
      // メール送信情報をメモに追加
      final mailInfo = '\n\n📧 メール送信完了: $timeStr';
      final updatedNotes = '${widget.task!.notes ?? ''}$mailInfo';
      
      // タスクを更新
      final updatedTask = widget.task!.copyWith(
        notes: updatedNotes,
        relatedLinkIds: widget.task!.relatedLinkIds, // 関連リンクIDを保持
      );
      
      await taskViewModel.updateTask(updatedTask);
      
      if (kDebugMode) {
        print('タスク「${widget.task!.title}」にメール送信情報を追加');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タスク更新エラー: $e');
      }
    }
  }

  /// テンプレートダイアログを表示
  Future<void> _showTemplateDialog() async {
    final selectedTemplate = await showDialog<Map<String, String>>(
        context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.description, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('メールテンプレート'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _emailTemplates.length,
              itemBuilder: (context, index) {
                final template = _emailTemplates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop(template);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  template['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '件名: ${template['subject']!}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '本文: ${template['body']!.replaceAll('\n', ' ').substring(0, template['body']!.length > 50 ? 50 : template['body']!.length)}${template['body']!.length > 50 ? '...' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );

    if (selectedTemplate != null) {
      // テンプレートを適用
      setState(() {
        _toController.text = _toController.text.isNotEmpty ? _toController.text : '';
        
        // 件名と本文をテンプレートで更新（既存の内容がある場合は追加）
        final currentSubject = _titleController.text.trim();
        final newSubject = currentSubject.isNotEmpty 
            ? '$currentSubject - ${selectedTemplate['subject']}'
            : selectedTemplate['subject']!;
        
        final currentBody = _assignedToController.text.trim();
        final newBody = currentBody.isNotEmpty 
            ? '$currentBody\n\n${selectedTemplate['body']}'
            : selectedTemplate['body']!;
        
        _titleController.text = newSubject;
        _assignedToController.text = newBody;
      });
      
      SnackBarService.showSuccess(context, 'テンプレート「${selectedTemplate['name']}」を適用しました');
    }
  }

  /// 送信履歴ダイアログを表示
  Future<void> _showHistoryDialog() async {
    try {
      final mailService = MailService();
      await mailService.initialize();
      
      final taskId = widget.task?.id;
      if (taskId == null) {
        SnackBarService.showError(context, 'タスクが選択されていません');
        return;
      }
      
      final mailLogs = mailService.getMailLogsForTask(taskId);
      
      if (mailLogs.isEmpty) {
        SnackBarService.showInfo(context, 'このタスクの送信履歴はありません');
        return;
      }
      
      final selectedLog = await showDialog<SentMailLog>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.history, color: Colors.green),
                const SizedBox(width: 8),
                const Text('送信履歴'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: mailLogs.length,
                itemBuilder: (context, index) {
                  final log = mailLogs[index];
                  final dateStr = DateFormat('MM/dd HH:mm').format(log.composedAt);
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(log);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    log.subject.replaceAll(RegExp(r'\s*\[LN-[A-Z0-9]+\]'), ''), // トークンを除去
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('宛先: ${log.to}'),
                                  Text('送信日時: $dateStr'),
                                  Text('アプリ: ${log.app}'),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      log.body.replaceAll(RegExp(r'---\s*送信ID:.*$', multiLine: true), '').trim(), // 送信ID部分を除去
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
            ],
          );
        },
      );

      if (selectedLog != null) {
        // 履歴から内容を再利用
        setState(() {
          _toController.text = selectedLog.to;
          
          // 件名からトークンを除去して適用
          final subjectWithoutToken = selectedLog.subject.replaceAll(RegExp(r'\s*\[LN-[A-Z0-9]+\]'), '');
          _titleController.text = subjectWithoutToken;
          
          // 本文から送信ID部分を除去して適用
          final bodyWithoutToken = selectedLog.body.replaceAll(RegExp(r'---\s*送信ID:.*$', multiLine: true), '').trim();
          _assignedToController.text = bodyWithoutToken;
        });
        
        SnackBarService.showSuccess(context, '送信履歴を再利用しました');
      }
    } catch (e) {
      SnackBarService.showError(context, '履歴取得エラー: $e');
    }
  }

  /// Outlook接続テスト
  void _testOutlookConnection() async {
    try {
      final mailService = MailService();
      await mailService.initialize();
      
      final isAvailable = await mailService.isOutlookAvailable();
      if (isAvailable) {
        SnackBarService.showSuccess(context, 'Outlook接続テスト成功');
      } else {
        SnackBarService.showError(context, 'Outlook接続テスト失敗: Outlookが利用できません');
      }
    } catch (e) {
      SnackBarService.showError(context, 'Outlook接続テストエラー: $e');
    }
  }

  /// Gmail接続テスト
  void _testGmailConnection() async {
    try {
      final mailService = MailService();
      await mailService.initialize();
      
      await mailService.launchGmail(
        to: '',
        cc: '',
        bcc: '',
        subject: 'Gmail接続テスト',
        body: 'これはGmail接続テストです。',
      );
      
      SnackBarService.showSuccess(context, 'Gmail接続テスト成功: Gmailが開きました');
    } catch (e) {
      SnackBarService.showError(context, 'Gmail接続テストエラー: $e');
    }
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

  /// 完了報告ダイアログを表示
  Future<void> _showCompletionReportDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CompletionReportDialog(
        taskTitle: widget.task?.title ?? '',
        requesterEmail: widget.task?.createdBy ?? '',
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        // 完了報告送信（簡易版）
        await Future.delayed(const Duration(seconds: 1));
        
        SnackBarService.showSuccess(context, '完了報告を送信しました');
      } catch (e) {
        SnackBarService.showError(context, '完了報告送信エラー: $e');
      }
    }
  }

}

// 完了報告ダイアログ
class _CompletionReportDialog extends StatefulWidget {
  final String taskTitle;
  final String requesterEmail;

  const _CompletionReportDialog({
    required this.taskTitle,
    required this.requesterEmail,
  });

  @override
  State<_CompletionReportDialog> createState() => _CompletionReportDialogState();
}

class _CompletionReportDialogState extends State<_CompletionReportDialog> {
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('完了報告'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'タスク: ${widget.taskTitle}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '依頼者: ${widget.requesterEmail}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '完了メモ',
                hintText: '完了内容や結果を記入してください',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '完了メモを入力してください';
                }
                return null;
              },
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_notesController.text.trim());
            }
          },
          child: const Text('完了報告を送信'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
    super.key,
    required this.initialTime,
  });

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

