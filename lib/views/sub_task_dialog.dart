import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/sub_task.dart';
import '../viewmodels/sub_task_viewmodel.dart';
import '../viewmodels/task_viewmodel.dart';
import '../l10n/app_localizations.dart';

class SubTaskDialog extends ConsumerStatefulWidget {
  final String parentTaskId;
  final String parentTaskTitle;

  const SubTaskDialog({
    super.key,
    required this.parentTaskId,
    required this.parentTaskTitle,
  });

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
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
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
    ref.invalidate(subTaskViewModelProvider);
    
    // 統計更新を即座に実行
    await taskViewModel.updateSubTaskStatistics(widget.parentTaskId);
    
    // 統計更新後に再度UIを更新
    ref.invalidate(taskViewModelProvider);
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
    ref.invalidate(subTaskViewModelProvider);
    
    // 統計更新を即座に実行
    await taskViewModel.updateSubTaskStatistics(widget.parentTaskId);
    
    // 統計更新後に再度UIを更新
    ref.invalidate(taskViewModelProvider);
  }

  void _toggleSubTaskCompletion(String subTaskId, bool isCompleted) async {
    final subTaskViewModel = ref.read(subTaskViewModelProvider.notifier);
    final taskViewModel = ref.read(taskViewModelProvider.notifier);

    print('=== サブタスク完了状態変更 ===');
    print('サブタスクID: $subTaskId');
    print('完了状態: $isCompleted');
    print('親タスクID: ${widget.parentTaskId}');

    if (isCompleted) {
      subTaskViewModel.uncompleteSubTask(subTaskId);
    } else {
      subTaskViewModel.completeSubTask(subTaskId);
    }
    
    // UIを即座に更新
    ref.invalidate(subTaskViewModelProvider);
    
    // 統計更新を即座に実行
    await taskViewModel.updateSubTaskStatistics(widget.parentTaskId);
    
    // 統計更新後に再度UIを更新
    ref.invalidate(taskViewModelProvider);
    
    print('=== サブタスク完了状態変更完了 ===');
  }


  @override
  Widget build(BuildContext context) {
    final subTasks = ref.watch(subTaskViewModelProvider)
        .where((subTask) => subTask.parentTaskId == widget.parentTaskId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final completedCount = subTasks.where((subTask) => subTask.isCompleted).length;
    final totalCount = subTasks.length;

    return PopScope(
      canPop: false, // 戻る操作を無効化
      child: Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                    '${AppLocalizations.of(context)!.subtask}: ${widget.parentTaskTitle}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedCount/$totalCount ${AppLocalizations.of(context)!.completed}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                          decoration: InputDecoration(
                            labelText: '${AppLocalizations.of(context)!.subtaskTitle} *',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)!.enterTitle;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _estimatedMinutesController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.estimatedTime,
                            border: const OutlineInputBorder(),
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
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.description,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addSubTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_isEditing ? AppLocalizations.of(context)!.update : AppLocalizations.of(context)!.add),
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
            
            // サブタスクリスト（並び替え可能）
            Expanded(
              child: subTasks.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noSubtasks,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: subTasks.length,
                      onReorder: (oldIndex, newIndex) async {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final List<SubTask> reorderedSubTasks = List.from(subTasks);
                        final SubTask movedSubTask = reorderedSubTasks.removeAt(oldIndex);
                        reorderedSubTasks.insert(newIndex, movedSubTask);
                        
                        // 順序を更新してViewModelに保存
                        final subTaskViewModel = ref.read(subTaskViewModelProvider.notifier);
                        await subTaskViewModel.updateSubTaskOrders(reorderedSubTasks);
                        
                        // UIを更新
                        ref.invalidate(subTaskViewModelProvider);
                        setState(() {});
                      },
                      itemBuilder: (context, index) {
                        final subTask = subTasks[index];
                        return Card(
                          key: ValueKey(subTask.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: subTask.isCompleted,
                                  onChanged: (value) {
                                    _toggleSubTaskCompletion(subTask.id, subTask.isCompleted);
                                  },
                                ),
                                Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey[400],
                                ),
                              ],
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
                                    AppLocalizations.of(context)!.estimatedTimeMinutes(subTask.estimatedMinutes!),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(
                                  '${AppLocalizations.of(context)!.creationDate}: ${DateFormat('yyyy/MM/dd HH:mm').format(subTask.createdAt)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                if (subTask.completedAt != null)
                                  Text(
                                    '${AppLocalizations.of(context)!.completionDateColon} ${DateFormat('yyyy/MM/dd HH:mm').format(subTask.completedAt!)}',
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
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}
