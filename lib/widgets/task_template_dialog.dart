import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/task_item.dart';
import '../viewmodels/task_viewmodel.dart';

/// タスクテンプレートダイアログ
class TaskTemplateDialog extends ConsumerStatefulWidget {
  const TaskTemplateDialog({super.key});

  @override
  ConsumerState<TaskTemplateDialog> createState() => _TaskTemplateDialogState();
}

class _TaskTemplateDialogState extends ConsumerState<TaskTemplateDialog> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requesterController = TextEditingController();
  final _assigneeController = TextEditingController();
  
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  TimeOfDay? _reminderTime;
  
  List<TaskTemplate> _templates = [];
  bool _isEditing = false;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _requesterController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  /// テンプレートを読み込み
  void _loadTemplates() {
    try {
      final box = Hive.box('templates');
      final templatesData = box.get('templates', defaultValue: <Map>[]);
      
      if (templatesData.isEmpty) {
        // 初回起動時はデフォルトテンプレートを作成
        _templates = _getDefaultTemplates();
        _saveTemplates();
      } else {
        // 保存されたテンプレートを読み込み
        _templates = templatesData.map((data) => TaskTemplate.fromMap(Map<String, dynamic>.from(data))).toList();
      }
    } catch (e) {
      print('テンプレート読み込みエラー: $e');
      _templates = _getDefaultTemplates();
    }
  }

  /// デフォルトテンプレートを取得
  List<TaskTemplate> _getDefaultTemplates() {
    return [
      TaskTemplate(
        name: '会議準備',
        title: '会議資料準備',
        description: '会議資料の準備と配布',
        priority: TaskPriority.high,
        requester: '上司',
        assignee: '自分',
      ),
      TaskTemplate(
        name: '定期報告',
        title: '週次報告書作成',
        description: '週次進捗報告書の作成と提出',
        priority: TaskPriority.medium,
        requester: 'マネージャー',
        assignee: '自分',
      ),
      TaskTemplate(
        name: 'システム保守',
        title: 'システム定期メンテナンス',
        description: 'システムの定期メンテナンス作業',
        priority: TaskPriority.low,
        requester: 'IT部門',
        assignee: '自分',
      ),
      TaskTemplate(
        name: '顧客対応',
        title: '顧客からの問い合わせ対応',
        description: '顧客からの問い合わせへの回答と対応',
        priority: TaskPriority.high,
        requester: '営業部',
        assignee: '自分',
      ),
      TaskTemplate(
        name: '資料作成',
        title: 'プレゼン資料作成',
        description: 'プレゼンテーション用資料の作成',
        priority: TaskPriority.medium,
        requester: 'プロジェクトマネージャー',
        assignee: '自分',
      ),
    ];
  }

  /// テンプレートを保存
  void _saveTemplates() {
    try {
      final box = Hive.box('templates');
      final templatesData = _templates.map((template) => template.toMap()).toList();
      box.put('templates', templatesData);
    } catch (e) {
      print('テンプレート保存エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(
          minWidth: 600,
          minHeight: 500,
          maxWidth: 1000,
          maxHeight: 800,
        ),
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.content_copy,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'タスクテンプレート',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _toggleEditMode(),
                    icon: Icon(_isEditing ? Icons.check : Icons.edit),
                    tooltip: _isEditing ? '編集完了' : 'テンプレート編集',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '閉じる',
                  ),
                ],
              ),
            ),
            
            // コンテンツ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // テンプレート選択
                    Row(
                      children: [
                        Text(
                          'テンプレートを選択',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isEditing) ...[
                          IconButton(
                            onPressed: _addNewTemplate,
                            icon: const Icon(Icons.add),
                            tooltip: '新しいテンプレートを追加',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _templates.length,
                        itemBuilder: (context, index) {
                          final template = _templates[index];
                          return Card(
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _isEditing ? _editTemplate(index) : _loadTemplate(template),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            template.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (_isEditing) ...[
                                          IconButton(
                                            onPressed: () => _deleteTemplate(index),
                                            icon: const Icon(Icons.delete, size: 16),
                                            tooltip: '削除',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      template.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          _getPriorityIcon(template.priority),
                                          size: 12,
                                          color: _getPriorityColor(template.priority),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getPriorityText(template.priority),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _getPriorityColor(template.priority),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // タスク詳細フォーム
                    Text(
                      'タスク詳細',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // テンプレート名
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'テンプレート名',
                                hintText: '例: 会議準備、定期報告など',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // タイトル
                            TextField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'タイトル',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 説明
                            TextField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: '説明',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            
                            // 依頼者・担当者
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _requesterController,
                                    decoration: const InputDecoration(
                                      labelText: '依頼者',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _assigneeController,
                                    decoration: const InputDecoration(
                                      labelText: '担当者',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                      Icon(
                                        _getPriorityIcon(priority),
                                        size: 16,
                                        color: _getPriorityColor(priority),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(_getPriorityText(priority)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _priority = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // 期限日・リマインダー
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectDueDate,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: '期限日',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(
                                        _dueDate != null
                                          ? '${_dueDate!.year}/${_dueDate!.month}/${_dueDate!.day}'
                                          : '選択してください',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectReminderTime,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'リマインダー',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(
                                        _reminderTime != null
                                          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                                          : '選択してください',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // ボタン
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('キャンセル'),
                        ),
                        const SizedBox(width: 16),
                        if (_isEditing) ...[
                          ElevatedButton(
                            onPressed: _saveTemplate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(_editingIndex != null ? '更新' : '保存'),
                          ),
                          const SizedBox(width: 16),
                        ],
                        ElevatedButton(
                          onPressed: _isEditing ? null : _createTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: const Text('タスクを作成'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadTemplate(TaskTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _requesterController.text = template.requester;
      _assigneeController.text = template.assignee;
      _priority = template.priority;
    });
  }

  /// 編集モードの切り替え
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _editingIndex = null;
        _clearForm();
      }
    });
  }

  /// 新しいテンプレートを追加
  void _addNewTemplate() {
    setState(() {
      _editingIndex = null;
      _clearForm();
    });
  }

  /// テンプレートを編集
  void _editTemplate(int index) {
    final template = _templates[index];
    setState(() {
      _editingIndex = index;
      _nameController.text = template.name;
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _requesterController.text = template.requester;
      _assigneeController.text = template.assignee;
      _priority = template.priority;
    });
  }

  /// テンプレートを削除
  void _deleteTemplate(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テンプレートを削除'),
        content: Text('「${_templates[index].name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _templates.removeAt(index);
                if (_editingIndex == index) {
                  _editingIndex = null;
                  _clearForm();
                }
              });
              // データベースに保存
              _saveTemplates();
              Navigator.of(context).pop();
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// テンプレートを保存
  void _saveTemplate() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テンプレート名を入力してください')),
      );
      return;
    }
    
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    final template = TaskTemplate(
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      requester: _requesterController.text.trim(),
      assignee: _assigneeController.text.trim(),
    );

    setState(() {
      if (_editingIndex != null) {
        // 既存テンプレートを更新
        _templates[_editingIndex!] = template;
      } else {
        // 新しいテンプレートを追加
        _templates.add(template);
      }
      _editingIndex = null;
      _clearForm();
    });

    // データベースに保存
    _saveTemplates();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('テンプレートを保存しました')),
    );
  }

  /// フォームをクリア
  void _clearForm() {
    _nameController.clear();
    _titleController.clear();
    _descriptionController.clear();
    _requesterController.clear();
    _assigneeController.clear();
    _priority = TaskPriority.medium;
    _dueDate = null;
    _reminderTime = null;
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
    }
  }

  void _createTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    final task = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      createdAt: DateTime.now(),
      dueDate: _dueDate,
      reminderTime: _reminderTime != null
        ? DateTime(
            _dueDate?.year ?? DateTime.now().year,
            _dueDate?.month ?? DateTime.now().month,
            _dueDate?.day ?? DateTime.now().day,
            _reminderTime!.hour,
            _reminderTime!.minute,
          )
        : null,
    );

    ref.read(taskViewModelProvider.notifier).addTask(task);
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('タスクを作成しました')),
    );
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
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

/// タスクテンプレートクラス
class TaskTemplate {
  final String name;
  final String title;
  final String description;
  final TaskPriority priority;
  final String requester;
  final String assignee;

  TaskTemplate({
    required this.name,
    required this.title,
    required this.description,
    required this.priority,
    required this.requester,
    required this.assignee,
  });

  /// MapからTaskTemplateを作成
  factory TaskTemplate.fromMap(Map<String, dynamic> map) {
    return TaskTemplate(
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: TaskPriority.values[map['priority'] ?? 1],
      requester: map['requester'] ?? '',
      assignee: map['assignee'] ?? '',
    );
  }

  /// TaskTemplateをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'title': title,
      'description': description,
      'priority': priority.index,
      'requester': requester,
      'assignee': assignee,
    };
  }
}
