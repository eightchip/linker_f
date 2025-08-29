import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/layout_settings_provider.dart';

class LayoutSettingsScreen extends ConsumerStatefulWidget {
  const LayoutSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LayoutSettingsScreen> createState() => _LayoutSettingsScreenState();
}

class _LayoutSettingsScreenState extends ConsumerState<LayoutSettingsScreen> {
  late LayoutSettings _currentSettings;
  late TextEditingController _crossAxisCountController;
  late TextEditingController _gridSpacingController;
  late TextEditingController _cardWidthController;
  late TextEditingController _cardHeightController;
  late TextEditingController _marginController;
  late TextEditingController _paddingController;
  late TextEditingController _fontSizeController;
  late TextEditingController _iconSizeController;
  late TextEditingController _buttonSizeController;

  @override
  void initState() {
    super.initState();
    _currentSettings = ref.read(layoutSettingsProvider);
    _crossAxisCountController = TextEditingController(text: _currentSettings.defaultCrossAxisCount.toString());
    _gridSpacingController = TextEditingController(text: _currentSettings.defaultGridSpacing.toString());
    _cardWidthController = TextEditingController(text: _currentSettings.cardWidth.toString());
    _cardHeightController = TextEditingController(text: _currentSettings.cardHeight.toString());
    _marginController = TextEditingController(text: _currentSettings.linkItemMargin.toString());
    _paddingController = TextEditingController(text: _currentSettings.linkItemPadding.toString());
    _fontSizeController = TextEditingController(text: _currentSettings.linkItemFontSize.toString());
    _iconSizeController = TextEditingController(text: _currentSettings.linkItemIconSize.toString());
    _buttonSizeController = TextEditingController(text: _currentSettings.buttonSize.toString());
  }

  @override
  void dispose() {
    _crossAxisCountController.dispose();
    _gridSpacingController.dispose();
    _cardWidthController.dispose();
    _cardHeightController.dispose();
    _marginController.dispose();
    _paddingController.dispose();
    _fontSizeController.dispose();
    _iconSizeController.dispose();
    _buttonSizeController.dispose();
    super.dispose();
  }

  void _updateSettings() {
    final newSettings = LayoutSettings(
      defaultCrossAxisCount: int.tryParse(_crossAxisCountController.text) ?? _currentSettings.defaultCrossAxisCount,
      defaultGridSpacing: double.tryParse(_gridSpacingController.text) ?? _currentSettings.defaultGridSpacing,
      cardWidth: double.tryParse(_cardWidthController.text) ?? _currentSettings.cardWidth,
      cardHeight: double.tryParse(_cardHeightController.text) ?? _currentSettings.cardHeight,
      linkItemMargin: double.tryParse(_marginController.text) ?? _currentSettings.linkItemMargin,
      linkItemPadding: double.tryParse(_paddingController.text) ?? _currentSettings.linkItemPadding,
      linkItemFontSize: double.tryParse(_fontSizeController.text) ?? _currentSettings.linkItemFontSize,
      linkItemIconSize: double.tryParse(_iconSizeController.text) ?? _currentSettings.linkItemIconSize,
      buttonSize: double.tryParse(_buttonSizeController.text) ?? _currentSettings.buttonSize,
      autoAdjustLayout: _currentSettings.autoAdjustLayout,
    );
    
    ref.read(layoutSettingsProvider.notifier).updateSettings(newSettings);
    setState(() {
      _currentSettings = newSettings;
    });
  }

  void _resetToDefaults() {
    ref.read(layoutSettingsProvider.notifier).resetToDefaults();
    final defaultSettings = ref.read(layoutSettingsProvider);
    setState(() {
      _currentSettings = defaultSettings;
      _crossAxisCountController.text = defaultSettings.defaultCrossAxisCount.toString();
      _gridSpacingController.text = defaultSettings.defaultGridSpacing.toString();
      _cardWidthController.text = defaultSettings.cardWidth.toString();
      _cardHeightController.text = defaultSettings.cardHeight.toString();
      _marginController.text = defaultSettings.linkItemMargin.toString();
      _paddingController.text = defaultSettings.linkItemPadding.toString();
      _fontSizeController.text = defaultSettings.linkItemFontSize.toString();
      _iconSizeController.text = defaultSettings.linkItemIconSize.toString();
      _buttonSizeController.text = defaultSettings.buttonSize.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(layoutSettingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('レイアウト設定'),
        actions: [
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.refresh),
            tooltip: 'デフォルトに戻す',
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: '閉じる',
          ),
        ],
      ),
      body: Row(
        children: [
          // 左側: プレビュー
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300, width: 2),
                ),
              ),
              child: _buildPreview(),
            ),
          ),
          
          // 右側: 設定パネル
          Container(
            width: 350,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 自動調整設定
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome),
                              const SizedBox(width: 8),
                              const Text('自動調整設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text('画面サイズに応じて自動調整'),
                            subtitle: const Text('ON: グリッド設定を無視して最適化\nOFF: 下記のグリッド設定を適用'),
                            value: settings.autoAdjustLayout,
                            onChanged: (value) {
                              ref.read(layoutSettingsProvider.notifier).toggleAutoAdjustLayout();
                              setState(() {
                                _currentSettings = ref.read(layoutSettingsProvider);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // グリッド設定
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.grid_view),
                              const SizedBox(width: 8),
                              const Text('グリッド設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // 列数設定
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('デフォルト列数', style: TextStyle(fontWeight: FontWeight.w500)),
                                    const Text('画面最大時の列数（2-6）', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _crossAxisCountController,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) => _updateSettings(),
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                              onPressed: () {
                                                final current = int.tryParse(_crossAxisCountController.text) ?? 4;
                                                if (current < 6) {
                                                  _crossAxisCountController.text = (current + 1).toString();
                                                  _updateSettings();
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                              onPressed: () {
                                                final current = int.tryParse(_crossAxisCountController.text) ?? 4;
                                                if (current > 2) {
                                                  _crossAxisCountController.text = (current - 1).toString();
                                                  _updateSettings();
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('グリッド間隔', style: TextStyle(fontWeight: FontWeight.w500)),
                                    const Text('カード間の間隔（px）', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _gridSpacingController,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) => _updateSettings(),
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                              onPressed: () {
                                                final current = double.tryParse(_gridSpacingController.text) ?? 8.0;
                                                _gridSpacingController.text = (current + 1.0).toString();
                                                _updateSettings();
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                              onPressed: () {
                                                final current = double.tryParse(_gridSpacingController.text) ?? 8.0;
                                                if (current > 1.0) {
                                                  _gridSpacingController.text = (current - 1.0).toString();
                                                  _updateSettings();
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // カードサイズ設定
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('カードサイズ', style: TextStyle(fontWeight: FontWeight.w500)),
                              const Text('各カードの幅と高さを直接設定できます（px）', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('幅', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _cardWidthController,
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                                keyboardType: TextInputType.number,
                                                onChanged: (value) => _updateSettings(),
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                                  onPressed: () {
                                                    final current = double.tryParse(_cardWidthController.text) ?? 200.0;
                                                    _cardWidthController.text = (current + 10.0).toString();
                                                    _updateSettings();
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                                  onPressed: () {
                                                    final current = double.tryParse(_cardWidthController.text) ?? 200.0;
                                                    if (current > 100.0) {
                                                      _cardWidthController.text = (current - 10.0).toString();
                                                      _updateSettings();
                                                    }
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('高さ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _cardHeightController,
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                                keyboardType: TextInputType.number,
                                                onChanged: (value) => _updateSettings(),
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                                  onPressed: () {
                                                    final current = double.tryParse(_cardHeightController.text) ?? 120.0;
                                                    _cardHeightController.text = (current + 10.0).toString();
                                                    _updateSettings();
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                                  onPressed: () {
                                                    final current = double.tryParse(_cardHeightController.text) ?? 120.0;
                                                    if (current > 60.0) {
                                                      _cardHeightController.text = (current - 10.0).toString();
                                                      _updateSettings();
                                                    }
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // リンクアイテム設定
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.link),
                              const SizedBox(width: 8),
                              const Text('リンクアイテム設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // マージンとパディング
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('アイテム間マージン', style: TextStyle(fontWeight: FontWeight.w500)),
                                    const Text('リンク間の余白（px）', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _marginController,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) => _updateSettings(),
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                              onPressed: () {
                                                final current = double.tryParse(_marginController.text) ?? 1.0;
                                                _marginController.text = (current + 0.5).toString();
                                                _updateSettings();
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                              onPressed: () {
                                                final current = double.tryParse(_marginController.text) ?? 1.0;
                                                if (current > 0.0) {
                                                  _marginController.text = (current - 0.5).toString();
                                                  _updateSettings();
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('アイテム内パディング', style: TextStyle(fontWeight: FontWeight.w500)),
                                    const Text('リンク内の余白（px）', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _paddingController,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) => _updateSettings(),
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                              onPressed: () {
                                                final current = double.tryParse(_paddingController.text) ?? 2.0;
                                                _paddingController.text = (current + 0.5).toString();
                                                _updateSettings();
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                              onPressed: () {
                                                final current = double.tryParse(_paddingController.text) ?? 2.0;
                                                if (current > 0.0) {
                                                  _paddingController.text = (current - 0.5).toString();
                                                  _updateSettings();
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // フォントサイズとアイコンサイズ
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('フォントサイズ', style: TextStyle(fontWeight: FontWeight.w500)),
                                    const Text('リンク名のフォントサイズ（px）', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _fontSizeController,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) => _updateSettings(),
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                              onPressed: () {
                                                final current = double.tryParse(_fontSizeController.text) ?? 9.0;
                                                if (current < 20.0) {
                                                  _fontSizeController.text = (current + 0.5).toString();
                                                  _updateSettings();
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                              onPressed: () {
                                                final current = double.tryParse(_fontSizeController.text) ?? 9.0;
                                                if (current > 6.0) {
                                                  _fontSizeController.text = (current - 0.5).toString();
                                                  _updateSettings();
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('アイコンサイズ', style: TextStyle(fontWeight: FontWeight.w500)),
                                    const Text('リンクアイコンのサイズ（px）', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _iconSizeController,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) => _updateSettings(),
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                              onPressed: () {
                                                final current = double.tryParse(_iconSizeController.text) ?? 18.0;
                                                if (current < 30.0) {
                                                  _iconSizeController.text = (current + 1.0).toString();
                                                  _updateSettings();
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                              onPressed: () {
                                                final current = double.tryParse(_iconSizeController.text) ?? 18.0;
                                                if (current > 12.0) {
                                                  _iconSizeController.text = (current - 1.0).toString();
                                                  _updateSettings();
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // ボタンサイズ
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ボタンサイズ', style: TextStyle(fontWeight: FontWeight.w500)),
                              const Text('アクションボタンのサイズ（px）', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _buttonSizeController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => _updateSettings(),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                        onPressed: () {
                                          final current = double.tryParse(_buttonSizeController.text) ?? 24.0;
                                          if (current < 40.0) {
                                            _buttonSizeController.text = (current + 1.0).toString();
                                            _updateSettings();
                                          }
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                        onPressed: () {
                                          final current = double.tryParse(_buttonSizeController.text) ?? 24.0;
                                          if (current > 16.0) {
                                            _buttonSizeController.text = (current - 1.0).toString();
                                            _updateSettings();
                                          }
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // プレビューを構築
  Widget _buildPreview() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // ヘッダー部分
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Link Navigator',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                  tooltip: '設定',
                ),
              ],
            ),
          ),
          
          // メインコンテンツ
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGridPreview(),
            ),
          ),
        ],
      ),
    );
  }

  // グリッドプレビューを構築
  Widget _buildGridPreview() {
    // 現在の設定に基づいてグリッドを構築
    final crossAxisCount = _currentSettings.autoAdjustLayout 
        ? _calculateOptimalCrossAxisCount(MediaQuery.of(context).size.width)
        : _currentSettings.defaultCrossAxisCount;
    
    return GridView.builder(
      padding: EdgeInsets.all(_currentSettings.defaultGridSpacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: _currentSettings.defaultGridSpacing,
        mainAxisSpacing: _currentSettings.defaultGridSpacing,
        childAspectRatio: _currentSettings.cardWidth / _currentSettings.cardHeight,
      ),
      itemCount: 12, // サンプルアイテム数
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.all(_currentSettings.linkItemMargin),
          padding: EdgeInsets.all(_currentSettings.linkItemPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link,
                size: _currentSettings.linkItemIconSize,
                color: Colors.blue,
              ),
              const SizedBox(height: 4),
              Text(
                'リンク${index + 1}',
                style: TextStyle(
                  fontSize: _currentSettings.linkItemFontSize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(
                    Icons.edit,
                    size: _currentSettings.buttonSize,
                    color: Colors.grey.shade600,
                  ),
                  Icon(
                    Icons.delete,
                    size: _currentSettings.buttonSize,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 最適な列数を計算（自動調整時）
  int _calculateOptimalCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    if (width < 1500) return 5;
    return 6;
  }
}
