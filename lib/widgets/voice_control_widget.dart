import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../services/voice_control_service.dart';

/// 音声コントロールウィジェット
class VoiceControlWidget extends StatefulWidget {
  final Function(VoiceCommand)? onCommandRecognized;
  final Function(String)? onTextRecognized;
  final bool showFloatingButton;

  const VoiceControlWidget({
    super.key,
    this.onCommandRecognized,
    this.onTextRecognized,
    this.showFloatingButton = true,
  });

  @override
  State<VoiceControlWidget> createState() => _VoiceControlWidgetState();
}

class _VoiceControlWidgetState extends State<VoiceControlWidget>
    with TickerProviderStateMixin {
  final VoiceControlService _voiceService = VoiceControlService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _feedbackText = '';

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeVoiceService() async {
    final initialized = await _voiceService.initialize();
    
    if (mounted) {
      setState(() {
        _isInitialized = initialized;
      });
    }

    if (initialized) {
      _voiceService.onCommandRecognized = _handleCommandRecognized;
      _voiceService.onTextRecognized = _handleTextRecognized;
      _voiceService.onListeningStateChanged = _handleListeningStateChanged;
    }
  }

  void _handleCommandRecognized(VoiceCommand command) {
    widget.onCommandRecognized?.call(command);
    
    setState(() {
      _feedbackText = _getFeedbackText(command);
    });

    // フィードバックテキストを3秒後にクリア
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _feedbackText = '';
        });
      }
    });
  }

  void _handleTextRecognized(String text) {
    setState(() {
      _recognizedText = text;
    });

    widget.onTextRecognized?.call(text);

    // 認識されたテキストを5秒後にクリア
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _recognizedText = '';
        });
      }
    });
  }

  void _handleListeningStateChanged(bool isListening) {
    setState(() {
      _isListening = isListening;
    });

    if (isListening) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }
  }

  String _getFeedbackText(VoiceCommand command) {
    switch (command.type) {
      case VoiceCommandType.openLink:
        return '${command.target}を開きます';
      case VoiceCommandType.search:
        return '${command.target}を検索します';
      case VoiceCommandType.navigation:
        switch (command.target) {
          case 'settings':
            return '設定画面を開きます';
          default:
            return 'ナビゲーションを実行します';
        }
      case VoiceCommandType.unknown:
        return 'コマンドを認識できませんでした';
    }
  }

  Future<void> _toggleListening() async {
    if (!_isInitialized) {
      _showInitializationError();
      return;
    }

    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      await _voiceService.startListening();
    }
  }

  void _showInitializationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('音声認識の初期化に失敗しました。マイク権限を確認してください。'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Windowsでは音声コントロールを無効化
    if (Platform.isWindows) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 音声認識状態の表示
        if (_recognizedText.isNotEmpty || _feedbackText.isNotEmpty)
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: _buildStatusCard(),
          ),

        // フローティングアクションボタン
        if (widget.showFloatingButton)
          Positioned(
            right: 20,
            bottom: 100,
            child: _buildVoiceButton(),
          ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isListening)
              Row(
                children: [
                  Icon(Icons.mic, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '音声認識中...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            if (_recognizedText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.hearing, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '認識されたテキスト:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _recognizedText,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            if (_feedbackText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.feedback, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'フィードバック:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _feedbackText,
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton(
            onPressed: _toggleListening,
            backgroundColor: _colorAnimation.value,
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 28,
            ),
            tooltip: _isListening ? '音声認識停止' : '音声認識開始',
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}

/// 音声コントロール用の小さなウィジェット（ヘッダー用）
class VoiceControlMiniWidget extends StatefulWidget {
  final Function(VoiceCommand)? onCommandRecognized;
  final Function(String)? onTextRecognized;

  const VoiceControlMiniWidget({
    super.key,
    this.onCommandRecognized,
    this.onTextRecognized,
  });

  @override
  State<VoiceControlMiniWidget> createState() => _VoiceControlMiniWidgetState();
}

class _VoiceControlMiniWidgetState extends State<VoiceControlMiniWidget> {
  final VoiceControlService _voiceService = VoiceControlService();
  bool _isInitialized = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    final initialized = await _voiceService.initialize();
    
    if (mounted) {
      setState(() {
        _isInitialized = initialized;
      });
    }

    if (initialized) {
      _voiceService.onCommandRecognized = widget.onCommandRecognized;
      _voiceService.onTextRecognized = widget.onTextRecognized;
      _voiceService.onListeningStateChanged = (isListening) {
        setState(() {
          _isListening = isListening;
        });
      };
    }
  }

  Future<void> _toggleListening() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('音声認識の初期化に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      await _voiceService.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleListening,
      icon: Icon(
        _isListening ? Icons.mic : Icons.mic_none,
        color: _isListening ? Colors.red : Colors.grey,
      ),
      tooltip: _isListening ? '音声認識停止' : '音声認識開始',
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}
