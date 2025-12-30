import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

enum SpeechStatus {
  notInitialized,
  ready,
  listening,
  processing,
  error,
  permissionDenied,
}

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  
  SpeechStatus _status = SpeechStatus.notInitialized;
  SpeechStatus get status => _status;

  String _lastError = '';
  String get lastError => _lastError;

  bool _isInitialized = false;
  bool get isAvailable => _isInitialized && _status != SpeechStatus.permissionDenied;

  // Callbacks
  Function(String text, bool isFinal)? onResult;
  Function(SpeechStatus status)? onStatusChanged;
  Function(String error)? onError;

  /// Initialize speech recognition
  Future<bool> init() async {
    if (kIsWeb) {
      // Web speech recognition has limited support
      _status = SpeechStatus.notInitialized;
      _lastError = 'Web platform does not support speech recognition';
      return false;
    }

    try {
      // Check microphone permission
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        _status = SpeechStatus.permissionDenied;
        _lastError = 'マイクの使用が許可されていません';
        return false;
      }

      // Check speech recognition permission (iOS)
      final speechStatus = await Permission.speech.status;
      if (!speechStatus.isGranted && !speechStatus.isLimited) {
        // Request speech permission
        final result = await Permission.speech.request();
        if (!result.isGranted && !result.isLimited) {
          _status = SpeechStatus.permissionDenied;
          _lastError = '音声認識の使用が許可されていません';
          return false;
        }
      }

      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: kDebugMode,
      );

      if (_isInitialized) {
        _status = SpeechStatus.ready;
      } else {
        _status = SpeechStatus.error;
        _lastError = '音声認識の初期化に失敗しました';
      }

      return _isInitialized;
    } catch (e) {
      _status = SpeechStatus.error;
      _lastError = '音声認識の初期化中にエラーが発生しました: $e';
      return false;
    }
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) return false;

    final status = await Permission.microphone.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _lastError = 'マイクの使用が永久に拒否されています。設定アプリから許可してください。';
      _status = SpeechStatus.permissionDenied;
      return false;
    } else {
      _lastError = 'マイクの使用が拒否されました';
      _status = SpeechStatus.permissionDenied;
      return false;
    }
  }

  /// Request speech recognition permission (iOS)
  Future<bool> requestSpeechPermission() async {
    if (kIsWeb) return false;

    final status = await Permission.speech.request();
    
    if (status.isGranted || status.isLimited) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _lastError = '音声認識の使用が永久に拒否されています。設定アプリから許可してください。';
      return false;
    } else {
      _lastError = '音声認識の使用が拒否されました';
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> isMicrophonePermissionGranted() async {
    if (kIsWeb) return false;
    return await Permission.microphone.isGranted;
  }

  /// Start listening for speech
  Future<bool> startListening({
    Duration maxDuration = const Duration(seconds: 60),
  }) async {
    if (!_isInitialized) {
      final initialized = await init();
      if (!initialized) return false;
    }

    if (_status == SpeechStatus.listening) {
      return true; // Already listening
    }

    if (_status == SpeechStatus.permissionDenied) {
      return false;
    }

    try {
      _status = SpeechStatus.listening;
      onStatusChanged?.call(_status);

      await _speech.listen(
        onResult: (result) {
          onResult?.call(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _status = SpeechStatus.ready;
            onStatusChanged?.call(_status);
          }
        },
        listenFor: maxDuration,
        pauseFor: const Duration(seconds: 3),
        localeId: 'ja-JP', // Japanese locale
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );

      return true;
    } catch (e) {
      _status = SpeechStatus.error;
      _lastError = '音声認識の開始に失敗しました: $e';
      onStatusChanged?.call(_status);
      onError?.call(_lastError);
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_status != SpeechStatus.listening) return;

    _status = SpeechStatus.processing;
    onStatusChanged?.call(_status);

    await _speech.stop();

    _status = SpeechStatus.ready;
    onStatusChanged?.call(_status);
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    await _speech.cancel();
    _status = SpeechStatus.ready;
    onStatusChanged?.call(_status);
  }

  void _handleStatus(String status) {
    if (kDebugMode) {
      debugPrint('Speech status: $status');
    }

    switch (status) {
      case 'listening':
        _status = SpeechStatus.listening;
        break;
      case 'notListening':
        _status = SpeechStatus.ready;
        break;
      case 'done':
        _status = SpeechStatus.ready;
        break;
    }
    onStatusChanged?.call(_status);
  }

  void _handleError(dynamic error) {
    if (kDebugMode) {
      debugPrint('Speech error: $error');
    }

    _status = SpeechStatus.error;
    
    final errorString = error.toString();
    if (errorString.contains('error_network')) {
      _lastError = 'ネットワークエラーが発生しました。インターネット接続を確認してください。';
    } else if (errorString.contains('error_audio')) {
      _lastError = '音声の取得に失敗しました';
    } else if (errorString.contains('error_no_match')) {
      _lastError = '音声を認識できませんでした。もう一度お試しください。';
    } else if (errorString.contains('error_speech_timeout')) {
      _lastError = '音声が検出されませんでした';
    } else {
      _lastError = '音声認識エラーが発生しました';
    }

    onStatusChanged?.call(_status);
    onError?.call(_lastError);
  }

  /// Get speech recognition consent message
  String get consentMessage => '''
音声入力機能について

この機能はデバイスの音声認識サービスを使用します。
音声データはGoogleの音声認識サービスを通じて処理される場合があります。

• 日記の内容はローカルに保存されます
• 音声データは文字変換後に破棄されます
• オフライン時は使用できない場合があります

続行すると、音声認識サービスの使用に同意したことになります。
''';

  /// Check if the device supports speech recognition
  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    
    if (!_isInitialized) {
      await init();
    }
    
    return _isInitialized;
  }

  /// Open app settings for permission
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
