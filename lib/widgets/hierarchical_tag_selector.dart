import 'package:flutter/material.dart';
import '../models/link_item.dart';
import '../utils/tag_manager.dart';

class HierarchicalTagSelector extends StatefulWidget {
  final LinkType linkType;
  final String? initialMainTag;
  final String? initialSubTag;
  final Function(String? mainTag, String? subTag) onTagsChanged;

  const HierarchicalTagSelector({
    super.key,
    required this.linkType,
    this.initialMainTag,
    this.initialSubTag,
    required this.onTagsChanged,
  });

  @override
  State<HierarchicalTagSelector> createState() => _HierarchicalTagSelectorState();
}

class _HierarchicalTagSelectorState extends State<HierarchicalTagSelector> {
  String? _selectedMainTag;
  String? _selectedSubTag;
  final TextEditingController _mainTagController = TextEditingController();
  final TextEditingController _subTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMainTag = widget.initialMainTag;
    _selectedSubTag = widget.initialSubTag;
    _mainTagController.text = _selectedMainTag ?? '';
    _subTagController.text = _selectedSubTag ?? '';
  }

  @override
  void dispose() {
    _mainTagController.dispose();
    _subTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // メインタグ選択
        Text('メインタグ', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildMainTagSelector(),
        
        const SizedBox(height: 16),
        
        // サブタグ選択（メインタグが選択されている場合のみ表示）
        if (_selectedMainTag != null) ...[
          Text('サブタグ', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _buildSubTagSelector(),
        ],
        
        const SizedBox(height: 16),
        
        // タグクリアボタン
        if (_selectedMainTag != null || _selectedSubTag != null)
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _clearTags,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('タグをクリア'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMainTagSelector() {
    final availableTags = TagManager.getMainTags(widget.linkType);
    
    return Column(
      children: [
        // ドロップダウン選択
        DropdownButtonFormField<String>(
          value: _selectedMainTag,
          decoration: const InputDecoration(
            labelText: 'メインタグを選択',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('タグなし'),
            ),
            ...availableTags.map((tag) => DropdownMenuItem<String>(
              value: tag,
              child: Text(tag),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedMainTag = value;
              _selectedSubTag = null; // メインタグが変わったらサブタグをリセット
              _subTagController.clear();
            });
            widget.onTagsChanged(_selectedMainTag, _selectedSubTag);
          },
        ),
        
        const SizedBox(height: 8),
        
        // カスタム入力
        TextField(
          controller: _mainTagController,
          decoration: const InputDecoration(
            labelText: 'カスタムメインタグ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit),
            hintText: '新しいメインタグを入力',
          ),
          onChanged: (value) {
            if (value.isNotEmpty && !availableTags.contains(value)) {
              setState(() {
                _selectedMainTag = value;
                _selectedSubTag = null;
                _subTagController.clear();
              });
              widget.onTagsChanged(_selectedMainTag, _selectedSubTag);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSubTagSelector() {
    if (_selectedMainTag == null) return const SizedBox.shrink();
    
    final availableSubTags = TagManager.getSubTags(_selectedMainTag!);
    
    return Column(
      children: [
        // ドロップダウン選択
        DropdownButtonFormField<String>(
          value: _selectedSubTag,
          decoration: const InputDecoration(
            labelText: 'サブタグを選択',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.subdirectory_arrow_right),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('サブタグなし'),
            ),
            ...availableSubTags.map((tag) => DropdownMenuItem<String>(
              value: tag,
              child: Text(tag),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSubTag = value;
            });
            widget.onTagsChanged(_selectedMainTag, _selectedSubTag);
          },
        ),
        
        const SizedBox(height: 8),
        
        // カスタム入力
        TextField(
          controller: _subTagController,
          decoration: const InputDecoration(
            labelText: 'カスタムサブタグ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit),
            hintText: '新しいサブタグを入力',
          ),
          onChanged: (value) {
            if (value.isNotEmpty && !availableSubTags.contains(value)) {
              setState(() {
                _selectedSubTag = value;
              });
              widget.onTagsChanged(_selectedMainTag, _selectedSubTag);
            }
          },
        ),
      ],
    );
  }

  void _clearTags() {
    setState(() {
      _selectedMainTag = null;
      _selectedSubTag = null;
      _mainTagController.clear();
      _subTagController.clear();
    });
    widget.onTagsChanged(null, null);
  }
}

// タグ表示ウィジェット
class TagDisplayWidget extends StatelessWidget {
  final String? mainTag;
  final String? subTag;
  final VoidCallback? onTap;

  const TagDisplayWidget({
    super.key,
    this.mainTag,
    this.subTag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mainTag == null && subTag == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label,
              size: 14,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              _buildTagText(),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildTagText() {
    if (mainTag != null && subTag != null) {
      return '$mainTag > $subTag';
    } else if (mainTag != null) {
      return mainTag!;
    } else if (subTag != null) {
      return subTag!;
    }
    return '';
  }
}
