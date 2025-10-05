import 'package:flutter_riverpod/flutter_riverpod.dart';

final fontSizeProvider = StateProvider<double>((ref) => 1.0);

final darkModeProvider = StateProvider<bool>((ref) => false);

final accentColorProvider = StateProvider<int>((ref) => 0xFF1E40AF); // 鮮明なブルー色

// 色の濃淡調整（0.0-2.0、1.0が標準）
final colorIntensityProvider = StateProvider<double>((ref) => 1.0);

// コントラスト調整（0.0-2.0、1.0が標準）
final colorContrastProvider = StateProvider<double>((ref) => 1.0);

// テキスト色設定
final textColorProvider = StateProvider<int>((ref) => 0xFF000000);

// タイトル設定
final titleTextColorProvider = StateProvider<int>((ref) => 0xFF000000);
final titleFontSizeProvider = StateProvider<double>((ref) => 1.0);
final titleFontFamilyProvider = StateProvider<String>((ref) => '');

// メモ設定
final memoTextColorProvider = StateProvider<int>((ref) => 0xFF000000);
final memoFontSizeProvider = StateProvider<double>((ref) => 1.0);
final memoFontFamilyProvider = StateProvider<String>((ref) => '');

// 説明設定
final descriptionTextColorProvider = StateProvider<int>((ref) => 0xFF000000);
final descriptionFontSizeProvider = StateProvider<double>((ref) => 1.0);
final descriptionFontFamilyProvider = StateProvider<String>((ref) => ''); 