import 'package:flutter_riverpod/flutter_riverpod.dart';

final fontSizeProvider = StateProvider<double>((ref) => 1.0);

final darkModeProvider = StateProvider<bool>((ref) => false);

final accentColorProvider = StateProvider<int>((ref) => 0xFF3B82F6); 