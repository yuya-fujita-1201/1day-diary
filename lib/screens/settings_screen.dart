import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.trackScreenView('settings');
  }

  Future<void> _toggleNotification(bool value) async {
    final provider = context.read<DiaryProvider>();

    if (value) {
      // Check and request permission
      final hasPermission = await _notificationService.isPermissionGranted();
      if (!hasPermission) {
        final granted = await _notificationService.requestPermission();
        if (!granted) {
          _showPermissionDialog();
          return;
        }
      }
    }

    await provider.updateNotificationSettings(enabled: value);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通知の許可が必要です'),
        content: const Text(
          '日記のリマインダーを受け取るには、通知の許可が必要です。\n'
          '設定アプリから通知を許可してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectNotificationTime() async {
    final provider = context.read<DiaryProvider>();
    final settings = provider.settings;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      await provider.updateNotificationSettings(
        hour: pickedTime.hour,
        minute: pickedTime.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;

        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text('設定'),
              floating: true,
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Settings
                  _buildSectionHeader(context, 'リマインダー'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('毎日のリマインダー'),
                          subtitle: Text(
                            settings.notificationEnabled
                                ? '有効'
                                : '無効',
                          ),
                          value: settings.notificationEnabled,
                          onChanged: kIsWeb ? null : _toggleNotification,
                          secondary: Icon(
                            settings.notificationEnabled
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: settings.notificationEnabled
                                ? AppTheme.primaryColor
                                : null,
                          ),
                        ),
                        if (settings.notificationEnabled) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.access_time),
                            title: const Text('通知時刻'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  settings.notificationTimeString,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: kIsWeb ? null : _selectNotificationTime,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (kIsWeb)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        '* Web版では通知機能は利用できません',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Statistics
                  _buildSectionHeader(context, '統計'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.book),
                          title: const Text('総記録数'),
                          trailing: Text(
                            '${provider.entryCount}件',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.local_fire_department),
                          title: const Text('連続記録'),
                          trailing: Text(
                            '${provider.streak}日',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Privacy & Support
                  _buildSectionHeader(context, 'その他'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.privacy_tip),
                          title: const Text('プライバシーポリシー'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            _showInfoDialog(
                              'プライバシーポリシー',
                              '''1分日記のプライバシーポリシー

【データの保存について】
• すべての日記データはお使いの端末内にのみ保存されます
• サーバーへのデータ送信は行いません
• アプリを削除するとデータも削除されます

【音声認識について】
• 音声入力機能はデバイスの音声認識サービスを使用します
• 音声データはGoogleの音声認識サービスで処理される場合があります
• 文字変換後、音声データは破棄されます

【通知について】
• 通知は端末のローカル通知機能を使用します
• 通知のオン/オフは設定から変更できます

【お問い合わせ】
ご質問やご意見がございましたら、アプリのサポートまでお問い合わせください。''',
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.mail),
                          title: const Text('お問い合わせ'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            _showInfoDialog(
                              'お問い合わせ',
                              '''1分日記へのお問い合わせ

アプリに関するご質問、ご意見、バグ報告などがございましたら、以下の方法でお問い合わせください。

【メール】
support@minutediary.example.com

【対応時間】
平日 10:00〜18:00
（土日祝日は翌営業日の対応となります）

お問い合わせの際は、以下の情報を含めていただけると、より迅速に対応できます：
• お使いの端末の機種名
• OSのバージョン
• 問題の詳細な説明

ご協力ありがとうございます。''',
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('アプリについて'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: '1分日記',
                              applicationVersion: '1.0.0',
                              applicationLegalese: '© 2024 Minute Diary',
                              children: [
                                const SizedBox(height: 16),
                                const Text(
                                  '1分日記は、毎日1つの質問に答えるだけで日記を残せるシンプルなアプリです。\n\n'
                                  '忙しい毎日でも、たった1分で今日を振り返ることができます。',
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App version
                  Center(
                    child: Text(
                      'バージョン 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
