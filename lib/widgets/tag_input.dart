import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TagInput extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;
  final int maxTags;

  const TagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.maxTags = 3,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) return;
    if (widget.tags.length >= widget.maxTags) {
      _showSnackBar('タグは最大${widget.maxTags}個までです');
      return;
    }
    if (widget.tags.contains(trimmedTag)) {
      _showSnackBar('同じタグは追加できません');
      return;
    }
    if (trimmedTag.length > 20) {
      _showSnackBar('タグは20文字以内で入力してください');
      return;
    }

    widget.onTagsChanged([...widget.tags, trimmedTag]);
    _controller.clear();
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(widget.tags.where((t) => t != tag).toList());
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'タグ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(任意・最大${widget.maxTags}個)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tags display
            if (widget.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    side: BorderSide.none,
                    labelStyle: const TextStyle(
                      color: AppTheme.primaryColor,
                    ),
                    deleteIconColor: AppTheme.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Input field
            if (widget.tags.length < widget.maxTags)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'タグを追加...',
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        _addTag(value);
                        _focusNode.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _addTag(_controller.text),
                    icon: const Icon(Icons.add_circle),
                    color: AppTheme.primaryColor,
                    tooltip: 'タグを追加',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
