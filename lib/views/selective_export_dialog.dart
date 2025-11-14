import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/export_config.dart';
import '../models/export_template.dart';
import '../repositories/link_repository.dart';
import '../viewmodels/task_viewmodel.dart';
import '../services/export_template_service.dart';
import '../services/snackbar_service.dart';
import '../widgets/app_button_styles.dart';

/// 選択式エクスポートダイアログ
class SelectiveExportDialog extends ConsumerStatefulWidget {
  final LinkRepository linkRepository;
  final TaskViewModel? taskViewModel;

  const SelectiveExportDialog({
    Key? key,
    required this.linkRepository,
    this.taskViewModel,
  }) : super(key: key);

  @override
  ConsumerState<SelectiveExportDialog> createState() => _SelectiveExportDialogState();
}

class _SelectiveExportDialogState extends ConsumerState<SelectiveExportDialog> {
  ExportConfig _config = ExportConfig();
  int _currentStep = 0;
  final ExportTemplateService _templateService = ExportTemplateService();
  
  // 選択状態
  final Map<String, bool> _selectedGroups = {};
  final Map<String, bool> _selectedLinks = {};
  final Map<String, bool> _selectedTasks = {};
  
  // 検索クエリ
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // タスクフィルター設定
  final Set<String> _selectedTags = {};
  final Set<String> _selectedStatuses = {};
  DateTime? _createdAtStart;
  DateTime? _createdAtEnd;
  DateTime? _dueDateStart;
  DateTime? _dueDateEnd;
  
  // 設定エクスポート設定
  bool _includeUISettings = false;
  bool _includeFeatureSettings = false;
  bool _includeIntegrationSettings = false;
  
  // テンプレート
  List<ExportTemplate> _templates = [];
  ExportTemplate? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _initializeSelections();
    _loadTemplates();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTemplates() async {
    final templates = await _templateService.getAllTemplates();
    setState(() {
      _templates = templates;
    });
  }

  void _initializeSelections() {
    // 全グループを選択
    final groups = widget.linkRepository.getAllGroups();
    for (final group in groups) {
      _selectedGroups[group.id] = true;
    }
    
    // リンクは常にグループに属しているため、グループ選択で自動的に含まれる
    // グループ外のリンクは存在しない（データ整合性の問題で存在する可能性はあるが、UIでは作成できない）
    
    // 全タスクを選択
    if (widget.taskViewModel != null) {
      final tasks = widget.taskViewModel!.tasks;
      for (final task in tasks) {
        _selectedTasks[task.id] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ヘッダー
            Row(
              children: [
                const Icon(Icons.save, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '選択式エクスポート',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // テンプレート選択
                if (_templates.isNotEmpty) ...[
                  DropdownButton<ExportTemplate>(
                    value: _selectedTemplate,
                    hint: const Text('テンプレートを選択'),
                    items: _templates.map((template) {
                      return DropdownMenuItem(
                        value: template,
                        child: Text(template.name),
                      );
                    }).toList(),
                    onChanged: (template) {
                      if (template != null) {
                        _loadTemplate(template);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add),
                    tooltip: 'テンプレートを保存',
                    onPressed: _showSaveTemplateDialog,
                  ),
                ] else
                  IconButton(
                    icon: const Icon(Icons.bookmark_add),
                    tooltip: 'テンプレートを保存',
                    onPressed: _showSaveTemplateDialog,
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ステップインジケーター
            _buildStepIndicator(),
            const SizedBox(height: 16),
            // ステップコンテンツ
            Expanded(
              child: _buildStepContent(),
            ),
            const SizedBox(height: 16),
            // フッター
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    style: AppButtonStyles.text(context),
                    child: const Text('戻る'),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: AppButtonStyles.text(context),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                if (_currentStep < 3)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep++;
                      });
                    },
                    style: AppButtonStyles.primary(context),
                    child: const Text('次へ'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      _finalizeConfig();
                      Navigator.pop(context, _config);
                    },
                    style: AppButtonStyles.primary(context),
                    child: const Text('エクスポート'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _loadTemplate(ExportTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _config = template.config;
      
      // 選択状態を復元
      _selectedGroups.clear();
      for (final id in template.config.selectedGroupIds) {
        _selectedGroups[id] = true;
      }
      
      _selectedLinks.clear();
      for (final id in template.config.selectedLinkIds) {
        _selectedLinks[id] = true;
      }
      
      _selectedTasks.clear();
      for (final id in template.config.selectedTaskIds) {
        _selectedTasks[id] = true;
      }
      
      // タスクフィルターを復元
      if (template.config.taskFilter != null) {
        _selectedTags.clear();
        _selectedTags.addAll(template.config.taskFilter!.tags);
        _selectedStatuses.clear();
        _selectedStatuses.addAll(template.config.taskFilter!.statuses);
        _createdAtStart = template.config.taskFilter!.createdAtStart;
        _createdAtEnd = template.config.taskFilter!.createdAtEnd;
        _dueDateStart = template.config.taskFilter!.dueDateStart;
        _dueDateEnd = template.config.taskFilter!.dueDateEnd;
      }
      
      // 設定を復元
      if (template.config.settingsConfig != null) {
        _includeUISettings = template.config.settingsConfig!.includeUISettings;
        _includeFeatureSettings = template.config.settingsConfig!.includeFeatureSettings;
        _includeIntegrationSettings = template.config.settingsConfig!.includeIntegrationSettings;
      }
    });
  }
  
  Future<void> _showSaveTemplateDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テンプレートを保存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'テンプレート名',
                hintText: '例: 部署標準リンク集',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（任意）',
                hintText: 'このテンプレートの説明',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    
    if (result == true && nameController.text.trim().isNotEmpty) {
      _finalizeConfig();
      final template = ExportTemplate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        config: _config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _templateService.saveTemplate(template);
      await _loadTemplates();
      
      if (mounted) {
        SnackBarService.showSuccess(
          context,
          'テンプレートを保存しました',
        );
      }
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepItem(0, 'データ選択'),
        _buildStepItem(1, 'タスクフィルター'),
        _buildStepItem(2, '設定'),
        _buildStepItem(3, '確認'),
      ],
    );
  }

  Widget _buildStepItem(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isCompleted
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive || isCompleted
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDataSelectionStep();
      case 1:
        return _buildTaskFilterStep();
      case 2:
        return _buildSettingsStep();
      case 3:
        return _buildPreviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDataSelectionStep() {
    final allGroups = widget.linkRepository.getAllGroups();
    final filteredGroups = _searchQuery.isEmpty
        ? allGroups
        : allGroups.where((group) =>
            group.title.toLowerCase().contains(_searchQuery) ||
            group.items.any((item) =>
                item.label.toLowerCase().contains(_searchQuery) ||
                item.path.toLowerCase().contains(_searchQuery))).toList();
    
    // リンクは常にグループに属しているため、グループ外のリンクは存在しない
    // ただし、データ整合性の問題でグループ外のリンクが存在する可能性があるため、
    // エクスポート時にはグループ選択で自動的に含まれる
    
    final allTasks = widget.taskViewModel?.tasks ?? [];
    final filteredTasks = _searchQuery.isEmpty
        ? allTasks
        : allTasks.where((task) =>
            task.title.toLowerCase().contains(_searchQuery) ||
            task.description?.toLowerCase().contains(_searchQuery) == true ||
            task.tags.any((tag) => tag.toLowerCase().contains(_searchQuery))).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 検索バー
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '検索...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Expanded(
          child: Row(
            children: [
              // グループ
              Expanded(
                flex: widget.taskViewModel != null ? 2 : 3,
                child: _buildSelectableList(
                  title: 'グループ',
                  subtitle: 'グループを選択すると、そのグループ内のすべてのリンクが含まれます',
                  items: filteredGroups,
                  selectedMap: _selectedGroups,
                  itemBuilder: (group) => ListTile(
                    title: Text(group.title),
                    subtitle: Text('${group.items.length}件のリンク'),
                    trailing: Checkbox(
                      value: _selectedGroups[group.id] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _selectedGroups[group.id] = value ?? false;
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _selectedGroups[group.id] = !(_selectedGroups[group.id] ?? false);
                      });
                    },
                  ),
                  onSelectAll: () {
                    setState(() {
                      for (final group in filteredGroups) {
                        _selectedGroups[group.id] = true;
                      }
                    });
                  },
                  onDeselectAll: () {
                    setState(() {
                      for (final group in filteredGroups) {
                        _selectedGroups[group.id] = false;
                      }
                    });
                  },
                ),
              ),
              
              if (widget.taskViewModel != null) ...[
                const SizedBox(width: 16),
                // タスク
                Expanded(
                  flex: 2,
                  child: _buildSelectableList(
                    title: 'タスク',
                    subtitle: '個別にタスクを選択します',
                    items: filteredTasks,
                    selectedMap: _selectedTasks,
                    itemBuilder: (task) => ListTile(
                      title: Text(task.title),
                      subtitle: Text('ステータス: ${_getStatusText(task.status)}'),
                      trailing: Checkbox(
                        value: _selectedTasks[task.id] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _selectedTasks[task.id] = value ?? false;
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _selectedTasks[task.id] = !(_selectedTasks[task.id] ?? false);
                        });
                      },
                    ),
                    onSelectAll: () {
                      setState(() {
                        for (final task in filteredTasks) {
                          _selectedTasks[task.id] = true;
                        }
                      });
                    },
                    onDeselectAll: () {
                      setState(() {
                        for (final task in filteredTasks) {
                          _selectedTasks[task.id] = false;
                        }
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // メモを含めるか
        CheckboxListTile(
          title: const Text('メモを含める'),
          value: _config.includeMemos,
          onChanged: (value) {
            setState(() {
              _config = _config.copyWith(includeMemos: value ?? true);
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildSelectableList<T>({
    required String title,
    String? subtitle,
    required List<T> items,
    required Map<String, bool> selectedMap,
    required Widget Function(T) itemBuilder,
    required VoidCallback onSelectAll,
    required VoidCallback onDeselectAll,
    String Function(T)? getId,
  }) {
    final idGetter = getId ?? (item) => (item as dynamic).id as String;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: onSelectAll,
              child: const Text('全選択'),
            ),
            TextButton(
              onPressed: onDeselectAll,
              child: const Text('全解除'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: items.isEmpty
                ? const Center(child: Text('項目がありません'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return itemBuilder(item);
                    },
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '選択: ${items.where((item) => selectedMap[idGetter(item)] ?? false).length} / ${items.length}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTaskFilterStep() {
    if (widget.taskViewModel == null) {
      return const Center(child: Text('タスクデータがありません'));
    }
    
    final allTasks = widget.taskViewModel!.tasks;
    final allTags = allTasks.expand((t) => t.tags).toSet();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'タスクフィルター設定',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // タグフィルター
          _buildSectionHeader('タグ'),
          Wrap(
            spacing: 8,
            children: allTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // ステータスフィルター
          _buildSectionHeader('ステータス'),
          ...['pending', 'inProgress', 'completed', 'cancelled'].map((status) {
            return CheckboxListTile(
              title: Text(_getStatusTextFromString(status)),
              value: _selectedStatuses.contains(status),
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _selectedStatuses.add(status);
                  } else {
                    _selectedStatuses.remove(status);
                  }
                });
              },
            );
          }),
          
          const SizedBox(height: 16),
          
          // 作成日フィルター
          _buildSectionHeader('作成日'),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(_createdAtStart != null
                      ? '開始: ${_formatDate(_createdAtStart!)}'
                      : '開始日を選択'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _createdAtStart ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _createdAtStart = date;
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text(_createdAtEnd != null
                      ? '終了: ${_formatDate(_createdAtEnd!)}'
                      : '終了日を選択'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _createdAtEnd ?? DateTime.now(),
                      firstDate: _createdAtStart ?? DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _createdAtEnd = date;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 期限日フィルター
          _buildSectionHeader('期限日'),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(_dueDateStart != null
                      ? '開始: ${_formatDate(_dueDateStart!)}'
                      : '開始日を選択'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDateStart ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        _dueDateStart = date;
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text(_dueDateEnd != null
                      ? '終了: ${_formatDate(_dueDateEnd!)}'
                      : '終了日を選択'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDateEnd ?? DateTime.now(),
                      firstDate: _dueDateStart ?? DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        _dueDateEnd = date;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '設定エクスポート',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('UI設定'),
            subtitle: const Text('テーマ、色、フォントサイズなど'),
            value: _includeUISettings,
            onChanged: (value) {
              setState(() {
                _includeUISettings = value ?? false;
              });
            },
          ),
          
          CheckboxListTile(
            title: const Text('機能設定'),
            subtitle: const Text('自動バックアップ、通知など'),
            value: _includeFeatureSettings,
            onChanged: (value) {
              setState(() {
                _includeFeatureSettings = value ?? false;
              });
            },
          ),
          
          CheckboxListTile(
            title: const Text('連携設定'),
            subtitle: const Text('Google Calendar、Outlookなど'),
            value: _includeIntegrationSettings,
            onChanged: (value) {
              setState(() {
                _includeIntegrationSettings = value ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    final selectedGroupIds = _selectedGroups.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    final selectedTaskIds = _selectedTasks.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'エクスポート内容の確認',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildPreviewItem('グループ', selectedGroupIds.length),
          _buildPreviewItem('タスク', selectedTaskIds.length),
          _buildPreviewItem('メモを含める', _config.includeMemos ? 1 : 0),
          
          if (_selectedTags.isNotEmpty || _selectedStatuses.isNotEmpty ||
              _createdAtStart != null || _dueDateStart != null)
            _buildPreviewItem('タスクフィルター', 1),
          
          if (_includeUISettings || _includeFeatureSettings || _includeIntegrationSettings)
            _buildPreviewItem('設定', 1),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$count件', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _finalizeConfig() {
    final selectedGroupIds = _selectedGroups.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    final selectedTaskIds = _selectedTasks.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    
    final taskFilter = (_selectedTags.isNotEmpty ||
            _selectedStatuses.isNotEmpty ||
            _createdAtStart != null ||
            _dueDateStart != null)
        ? TaskFilterConfig(
            tags: _selectedTags,
            statuses: _selectedStatuses,
            createdAtStart: _createdAtStart,
            createdAtEnd: _createdAtEnd,
            dueDateStart: _dueDateStart,
            dueDateEnd: _dueDateEnd,
          )
        : null;
    
    final settingsConfig = (_includeUISettings ||
            _includeFeatureSettings ||
            _includeIntegrationSettings)
        ? SettingsExportConfig(
            includeUISettings: _includeUISettings,
            includeFeatureSettings: _includeFeatureSettings,
            includeIntegrationSettings: _includeIntegrationSettings,
          )
        : null;
    
    _config = ExportConfig(
      selectedGroupIds: selectedGroupIds,
      selectedLinkIds: <String>{}, // リンクは常にグループに属しているため空
      selectedTaskIds: selectedTaskIds,
      taskFilter: taskFilter,
      settingsConfig: settingsConfig,
      includeMemos: _config.includeMemos,
    );
  }

  String _getStatusText(dynamic status) {
    final statusStr = status.toString().split('.').last;
    return _getStatusTextFromString(statusStr);
  }

  String _getStatusTextFromString(String status) {
    switch (status) {
      case 'pending':
        return '未着手';
      case 'inProgress':
        return '進行中';
      case 'completed':
        return '完了';
      case 'cancelled':
        return 'キャンセル';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

