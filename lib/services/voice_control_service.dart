import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../models/link_item.dart';

/// 音声コマンドの種類
enum VoiceCommandType {
  openLink,
  search,
  navigation,
  unknown,
}

/// 音声コマンドのデータクラス
class VoiceCommand {
  final VoiceCommandType type;
  final String target;
  final String originalText;
  final Map<String, dynamic>? parameters;

  VoiceCommand({
    required this.type,
    required this.target,
    required this.originalText,
    this.parameters,
  });

  factory VoiceCommand.unknown() {
    return VoiceCommand(
      type: VoiceCommandType.unknown,
      target: '',
      originalText: '',
    );
  }
}

/// 音声コントロールサービス（一時的に無効化）
class VoiceControlService {
  static final VoiceControlService _instance = VoiceControlService._internal();
  factory VoiceControlService() => _instance;
  VoiceControlService._internal();

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastRecognizedText = '';
  
  // コールバック関数
  Function(VoiceCommand)? onCommandRecognized;
  Function(String)? onTextRecognized;
  Function(bool)? onListeningStateChanged;

  /// 初期化（常に失敗）
  Future<bool> initialize() async {
    if (kDebugMode) {
      print('音声コントロールは現在無効です');
    }
    return false;
  }

  /// 音声認識開始（何もしない）
  Future<void> startListening() async {
    if (kDebugMode) {
      print('音声認識は現在無効です');
    }
  }

  /// 音声認識停止（何もしない）
  Future<void> stopListening() async {
    if (kDebugMode) {
      print('音声認識は現在無効です');
    }
  }

  /// 音声合成（何もしない）
  Future<void> speak(String text) async {
    if (kDebugMode) {
      print('音声合成は現在無効です: $text');
    }
  }

  /// 現在の状態を取得
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastRecognizedText => _lastRecognizedText;

  /// リソースの解放（何もしない）
  void dispose() {
    if (kDebugMode) {
      print('音声コントロールサービスを破棄しました');
    }
  }
}
