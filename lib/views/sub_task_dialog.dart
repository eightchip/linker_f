import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/sub_task.dart';
import '../viewmodels/sub_task_viewmodel.dart';
import '../viewmodels/task_viewmodel.dart';

class SubTaskDialog extends ConsumerStatefulWidget {
  final String parentTaskId;
  final String parentTaskTitle;

  const SubTaskDialog({
    Key? key,
    required this.parentTaskId,
    required this.parentTaskTitle,
  }) : super(key: key);

  @override
  ConsumerState<SubTaskDialog> createState() => _SubTaskDialogState();
}

class _SubTaskDialogState extends ConsumerState<SubTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedMinutesController = TextEditingController();
  final _notesController = TextEditingController();
  
  // 編集用の状態管理
  SubTask? _editingSubTask;
  bool _isEditing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedMinutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addSubTask() async {
    if (_formKey.currentState!.validate()) {
      final subTaskViewModel = ref.read(subTaskViewModelProvider.notifier);
      final taskViewModel = ref.read(taskViewModelProvider.notifier);

      if (_isEditing && _editingSubTask != null) {
        // 編集モード：既存のサブタスクを更新
        final updatedSubTask = _editingSubTask!.copyWith(
          title: _titleController.text.trim(),
          description: _titleController.text.trim().isEmpty 
              ? null 
              : _titleController.text.trim(),
          estimatedMinutes: _estimatedMinutesController.text.isNotEmpty
              ? int.tryParse(_estimatedMinutesController.text)
              : null,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        
        await subTaskViewModel.updateSubTask(updatedSubTask);
        _cancelEdit();
      } else {
        // 新規追加モード
        final subTask = subTaskViewModel.createSubTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          parentTaskId: widget.parentTaskId,
          estimatedMinutes: _estimatedMinutesController.text.isNotEmpty
              ? int.tryParse(_estimatedMinutesController.text)
              : null,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await subTaskViewModel.addSubTask(subTask);
      }
      
      // フォームをクリア
      _clearForm();

      // UIを強制的に更新
      ref.refresh(subTaskViewModelProvider);
      
      // 少し待機してから統計更新を実行
      await Future.delayed(const Duration(milliseconds: 200));
      await taskViewModel.updateSubTaskStatistics(widget.parentTaskId);
      
      // 統計更新後に再度UIを更新
      ref.refresh(taskViewModelProvider);
    }
  }

  // 編集を開始
  void _startEdit(SubTask subTask) {
    setState(() {
      _editingSubTask = subTask;
      _isEditing = true;
      _titleController.text = subTask.title;
      _descriptionController.text = subTask.description ?? '';
      _estimatedMinutesController.text = subTask.estimatedMinutes?.toString() ?? '';
      _notesController.text = subTask.notes ?? '';
    });
  }

  // 編集をキャンセル
  void _cancelEdit() {
    setState(() {
      _editingSubTask = null;
      _isEditing = false;
      _clearForm();
    });
  }

  // フォームをクリア
  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _estimatedMinutesController.clear();
    _notesController.clear();
  }

  void _deleteSubTask(String subTaskId) async {
    final subTaskViewModel = ref.read(subTaskViewModelProvider.notifier);
    final taskViewModel = ref.read(taskViewModelProvider.notifier);

    await subTaskViewModel.deleteSubTask(subTaskId);

    // UIを強制的に更新
    ref.refresh(subTaskViewModelProvider);
    
    // 少し待機してから統計更新を実行
    await Future.delayed(const Duration(milliseconds: 200));
    await taskViewModel.updateSubTaskStatistics(widget.parentTaskId);
    
    // 統計更新後に再度UIを更新
    ref.refresh(taskViewModelProvider);
  }

  void _toggleSubTaskCompletion(String subTaskId, bool isCompleted) {
    final subTaskViewModel = ref.read(subTaskViewModelProvider.notifier);
    final taskViewModel = ref.read(taskViewModelProvider.notifier);

    if (isCompleted) {
      subTaskViewModel.uncompleteSubTask(subTaskId);
    } else {
      subTaskViewModel.completeSubTask(subTaskId);
    }
    
    taskViewModel.updateSubTaskStatistics(widget.parentTaskId);
    
    // UIを強制的に更新
    ref.refresh(subTaskViewModelProvider);
    ref.refresh(taskViewModelProvider);
  }

  void _handleSubTaskReorder(int oldIndex, int newIndex) {
    final subTaskViewModel = ref.read(subTaskViewModelProvider.notifier);
    final subTasks = ref.read(subTaskViewModelProvider)
        .where((subTask) => subTask.parentTaskId == widget.parentTaskId)
        .toList();

    if (oldIndex < newIndex) {
      for (int i = oldIndex; i < newIndex; i++) {
        subTasks[i].order = subTasks[i + 1].order;
      }
      subTasks[newIndex].order = subTasks[oldIndex].order;
    } else {
      for (int i = oldIndex; i > newIndex; i--) {
        subTasks[i].order = subTasks[i - 1].order;
      }
      subTasks[newIndex].order = subTasks[oldIndex].order;
    }

    subTaskViewModel.updateSubTaskOrders(subTasks);
    ref.refresh(subTaskViewModelProvider);
  }

  @override
  Widget build(BuildContext context) {
    final subTasks = ref.watch(subTaskViewModelProvider)
        .where((subTask) => subTask.parentTaskId == widget.parentTaskId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final completedCount = subTasks.where((subTask) => subTask.isCompleted).length;
    final totalCount = subTasks.length;

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.subdirectory_arrow_right,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'サブタスク: ${widget.parentTaskTitle}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Text(
                  '$completedCount/$totalCount 完了',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 進捗バー
            if (totalCount > 0) ...[
              LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  completedCount == totalCount ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // サブタスク追加フォーム
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'サブタスクタイトル *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'タイトルを入力してください';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _estimatedMinutesController,
                          decoration: const InputDecoration(
                            labelText: '推定時間 (分)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: '説明',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addSubTask,
                        child: Text(_isEditing ? '更新' : '追加'),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _cancelEdit,
                          child: const Text('キャンセル'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // サブタスクリスト
            Expanded(
              child: subTasks.isEmpty
                  ? const Center(
                      child: Text(
                        'サブタスクがありません',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: subTasks.length,
                      itemBuilder: (context, index) {
                        final subTask = subTasks[index];
                        return Card(
                          key: ValueKey(subTask.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Checkbox(
                              value: subTask.isCompleted,
                              onChanged: (value) {
                                _toggleSubTaskCompletion(subTask.id, subTask.isCompleted);
                              },
                            ),
                            title: Text(
                              subTask.title,
                              style: TextStyle(
                                decoration: subTask.isCompleted 
                                    ? TextDecoration.lineThrough 
                                    : null,
                                color: subTask.isCompleted 
                                    ? Colors.grey 
                                    : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (subTask.description != null)
                                  Text(subTask.description!),
                                if (subTask.estimatedMinutes != null)
                                  Text(
                                    '推定時間: ${subTask.estimatedMinutes}分',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(
                                  '作成日: ${DateFormat('yyyy/MM/dd HH:mm').format(subTask.createdAt)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                if (subTask.completedAt != null)
                                  Text(
                                    '完了日: ${DateFormat('yyyy/MM/dd HH:mm').format(subTask.completedAt!)}',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _startEdit(subTask),
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: '編集',
                                ),
                                IconButton(
                                  onPressed: () => _deleteSubTask(subTask.id),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: '削除',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        _handleSubTaskReorder(oldIndex, newIndex);
                      },
                      buildDefaultDragHandles: true,
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
