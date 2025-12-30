import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../services/speech_service.dart';
import '../services/analytics_service.dart';
import '../utils/theme.dart';
import '../utils/date_utils.dart';
import '../widgets/mood_selector.dart';
import '../widgets/tag_input.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _answerController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  final AnalyticsService _analytics = AnalyticsService();

  int? _selectedMood;
  List<String> _tags = [];
  bool _isListening = false;
  bool _isProcessing = false;
  String _speechError = '';
  Timer? _autosaveTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeechService();
    _loadDraft();
    _analytics.trackScreenView('home');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _answerController.dispose();
    _autosaveTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDraft();
    }
  }

  Future<void> _initSpeechService() async {
    if (kIsWeb) return;
    
    _speechService.onResult = (text, isFinal) {
      setState(() {
        if (isFinal) {
          // Append to existing text
          final currentText = _answerController.text;
          if (currentText.isNotEmpty && !currentText.endsWith(' ')) {
            _answerController.text = '$currentText $text';
          } else {
            _answerController.text = currentText + text;
          }
          _answerController.selection = TextSelection.fromPosition(
            TextPosition(offset: _answerController.text.length),
          );
          _isProcessing = false;
        }
      });
    };

    _speechService.onStatusChanged = (status) {
      setState(() {
        _isListening = status == SpeechStatus.listening;
        _isProcessing = status == SpeechStatus.processing;
        if (status == SpeechStatus.error) {
          _speechError = _speechService.lastError;
        }
      });
    };

    _speechService.onError = (error) {
      setState(() {
        _speechError = error;
        _isListening = false;
        _isProcessing = false;
      });
      _showSnackBar(_speechError, isError: true);
    };
  }

  void _loadDraft() {
    final provider = context.read<DiaryProvider>();
    final draft = provider.currentDraft;
    if (draft != null) {
      _answerController.text = draft.answerText;
      _selectedMood = draft.mood;
      _tags = List.from(draft.tags);
    }
  }

  void _startAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 3), () {
      _saveDraft();
    });
  }

  Future<void> _saveDraft() async {
    final provider = context.read<DiaryProvider>();
    if (_answerController.text.isNotEmpty || _selectedMood != null || _tags.isNotEmpty) {
      await provider.saveDraft(
        answerText: _answerController.text,
        mood: _selectedMood,
        tags: _tags,
      );
    }
  }

  Future<void> _toggleSpeech() async {
    if (kIsWeb) {
      _showSnackBar('Web版では音声入力は利用できません', isError: true);
      return;
    }

    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isProcessing = true;
      });
      return;
    }

    // Check if we need to show consent
    final provider = context.read<DiaryProvider>();
    if (!provider.settings.hasSpeechRecognitionConsent) {
      final consent = await _showSpeechConsentDialog();
      if (!consent) return;
      
      await provider.updateSettings(
        provider.settings.copyWith(hasSpeechRecognitionConsent: true),
      );
    }

    // Check and request permissions
    final hasPermission = await _speechService.hasPermissions();
    if (!hasPermission) {
      final granted = await _speechService.requestPermissions();
      if (!granted) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    // Start listening (will initialize if needed)
    final started = await _speechService.startListening();
    if (!started) {
      if (_speechService.status == SpeechStatus.permissionDenied) {
        _showPermissionDeniedDialog();
      } else {
        _showSnackBar(_speechService.lastError, isError: true);
      }
    }
  }

  Future<bool> _showSpeechConsentDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('音声入力について'),
            content: SingleChildScrollView(
              child: Text(_speechService.consentMessage),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('同意する'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('マイクの許可が必要です'),
        content: const Text(
          '音声入力を使用するには、マイクへのアクセスを許可してください。\n\n'
          '設定アプリを開いて、このアプリのマイク権限を有効にしてください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _speechService.openSettings();
            },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }

  Future<void> _swapQuestion() async {
    final provider = context.read<DiaryProvider>();
    if (!provider.canSwapQuestion) {
      _showSnackBar('今日はすでに質問を変更しました', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('質問を変更しますか？'),
        content: const Text('1日1回だけ質問を変更できます。\n変更後は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('変更する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.swapQuestion();
      if (success) {
        _showSnackBar('質問を変更しました');
      }
    }
  }

  Future<void> _saveEntry() async {
    final provider = context.read<DiaryProvider>();
    final text = _answerController.text.trim();

    if (text.isEmpty) {
      _showSnackBar('回答を入力してください', isError: true);
      return;
    }

    if (text.length > 500) {
      _showSnackBar('回答は500文字以内で入力してください', isError: true);
      return;
    }

    final success = await provider.saveEntry(
      answerText: text,
      mood: _selectedMood,
      tags: _tags,
    );

    if (success) {
      _showSnackBar('日記を保存しました');
      _answerController.clear();
      setState(() {
        _selectedMood = null;
        _tags = [];
      });
    } else {
      _showSnackBar(provider.error ?? '保存に失敗しました', isError: true);
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
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeContent(),
            const HistoryScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          final screenNames = ['home', 'history', 'settings'];
          _analytics.trackScreenView(screenNames[index]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: '記録する',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Consumer<DiaryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // If already has entry for today, show completion view
        if (provider.hasEntryToday) {
          return _buildCompletedView(provider);
        }

        return _buildInputView(provider);
      },
    );
  }

  Widget _buildCompletedView(DiaryProvider provider) {
    final entry = provider.todayEntry!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '今日の日記を書きました！',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppDateUtils.formatDisplayDate(DateTime.now()),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.questionText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    entry.answerText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (entry.mood != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          AppTheme.getMoodEmoji(entry.mood!),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppTheme.getMoodLabel(entry.mood!),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: entry.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${provider.streak}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '日連続',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputView(DiaryProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1分日記',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppDateUtils.formatDisplayDate(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
              if (provider.streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 18,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.streak}日',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Today's Question
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '今日の質問',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (provider.canSwapQuestion)
                        TextButton.icon(
                          onPressed: _swapQuestion,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('変更'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.todayQuestion?.text ?? '質問を読み込み中...',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Answer Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _answerController,
                    maxLines: 6,
                    maxLength: 500,
                    onChanged: (value) {
                      _startAutosave();
                    },
                    decoration: InputDecoration(
                      hintText: '今日のあなたの答えを書いてください...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      filled: false,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Divider(),
                  Row(
                    children: [
                      // Speech input button
                      if (!kIsWeb)
                        Material(
                          color: _isListening
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: _isProcessing ? null : _toggleSpeech,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isListening
                                        ? Icons.stop
                                        : (_isProcessing
                                            ? Icons.hourglass_top
                                            : Icons.mic),
                                    color: _isListening
                                        ? Colors.red
                                        : (_isProcessing
                                            ? Colors.grey
                                            : AppTheme.primaryColor),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isListening
                                        ? '停止'
                                        : (_isProcessing ? '処理中...' : '音声で入力'),
                                    style: TextStyle(
                                      color: _isListening
                                          ? Colors.red
                                          : (_isProcessing
                                              ? Colors.grey
                                              : AppTheme.primaryColor),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${_answerController.text.length}/500',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mood Selector
          MoodSelector(
            selectedMood: _selectedMood,
            onMoodSelected: (mood) {
              setState(() {
                _selectedMood = mood;
              });
              _startAutosave();
            },
          ),
          const SizedBox(height: 16),

          // Tag Input
          TagInput(
            tags: _tags,
            onTagsChanged: (tags) {
              setState(() {
                _tags = tags;
              });
              _startAutosave();
            },
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveEntry,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '記録する',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
