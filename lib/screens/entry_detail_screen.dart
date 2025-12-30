import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import '../utils/theme.dart';
import '../utils/date_utils.dart';
import '../services/analytics_service.dart';
import '../widgets/mood_selector.dart';
import '../widgets/tag_input.dart';

class EntryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;

  const EntryDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  late TextEditingController _answerController;
  late int? _selectedMood;
  late List<String> _tags;
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController(text: widget.entry.answerText);
    _selectedMood = widget.entry.mood;
    _tags = List.from(widget.entry.tags);
    _analytics.trackScreenView('entry_detail');
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing && _hasChanges) {
      _showSaveConfirmDialog();
    } else {
      setState(() {
        _isEditing = !_isEditing;
        if (!_isEditing) {
          // Reset to original values
          _answerController.text = widget.entry.answerText;
          _selectedMood = widget.entry.mood;
          _tags = List.from(widget.entry.tags);
          _hasChanges = false;
        }
      });
    }
  }

  Future<void> _showSaveConfirmDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('変更を保存しますか？'),
        content: const Text('編集内容が変更されています。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('破棄'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _saveEntry();
    } else if (result == 'discard') {
      setState(() {
        _isEditing = false;
        _answerController.text = widget.entry.answerText;
        _selectedMood = widget.entry.mood;
        _tags = List.from(widget.entry.tags);
        _hasChanges = false;
      });
    }
  }

  Future<void> _saveEntry() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('回答を入力してください', isError: true);
      return;
    }

    if (text.length > 500) {
      _showSnackBar('回答は500文字以内で入力してください', isError: true);
      return;
    }

    final provider = context.read<DiaryProvider>();
    final success = await provider.updateEntry(
      entryId: widget.entry.id,
      answerText: text,
      mood: _selectedMood,
      tags: _tags,
    );

    if (success) {
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
      _showSnackBar('保存しました');
    } else {
      _showSnackBar(provider.error ?? '保存に失敗しました', isError: true);
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('日記を削除しますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<DiaryProvider>();
      final success = await provider.deleteEntry(widget.entry.id);

      if (success) {
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showSnackBar(provider.error ?? '削除に失敗しました', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppDateUtils.formatDisplayDateFull(
          AppDateUtils.parseDate(widget.entry.date),
        )),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveEntry,
              tooltip: '保存',
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
              tooltip: '編集',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteEntry();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('削除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '質問',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.entry.questionText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Answer
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '回答',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isEditing) ...[
                          const Spacer(),
                          Text(
                            '${_answerController.text.length}/500',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      TextField(
                        controller: _answerController,
                        maxLines: null,
                        minLines: 4,
                        maxLength: 500,
                        onChanged: (value) {
                          setState(() {
                            _hasChanges = true;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: '回答を入力...',
                          border: InputBorder.none,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    else
                      Text(
                        widget.entry.answerText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mood
            if (_isEditing)
              MoodSelector(
                selectedMood: _selectedMood,
                onMoodSelected: (mood) {
                  setState(() {
                    _selectedMood = mood;
                    _hasChanges = true;
                  });
                },
              )
            else if (widget.entry.mood != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.getMoodColor(widget.entry.mood!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '気分',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        AppTheme.getMoodEmoji(widget.entry.mood!),
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTheme.getMoodLabel(widget.entry.mood!),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),

            if (_isEditing || widget.entry.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              if (_isEditing)
                TagInput(
                  tags: _tags,
                  onTagsChanged: (tags) {
                    setState(() {
                      _tags = tags;
                      _hasChanges = true;
                    });
                  },
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'タグ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.entry.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              side: BorderSide.none,
                              labelStyle: const TextStyle(
                                color: AppTheme.primaryColor,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // Timestamps
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimestampRow(
                      context,
                      icon: Icons.add,
                      label: '作成日時',
                      timestamp: widget.entry.createdAt,
                    ),
                    if (widget.entry.updatedAt != widget.entry.createdAt) ...[
                      const SizedBox(height: 8),
                      _buildTimestampRow(
                        context,
                        icon: Icons.edit,
                        label: '更新日時',
                        timestamp: widget.entry.updatedAt,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _toggleEdit,
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _hasChanges ? _saveEntry : null,
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DateTime timestamp,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
        const SizedBox(width: 8),
        Text(
          '${AppDateUtils.formatDisplayDateFull(timestamp)} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
