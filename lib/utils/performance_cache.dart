import 'dart:collection';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// パフォーマンス最適化のためのキャッシュ機能
class PerformanceCache {
  static final Map<String, _CacheEntry> _cache = {};
  static const int _maxCacheSize = 100;
  static const Duration _defaultExpiration = Duration(minutes: 5);

  /// キャッシュから値を取得
  static T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// キャッシュに値を保存
  static void set<T>(String key, T value, {Duration? expiration}) {
    _cleanupExpiredEntries();
    
    if (_cache.length >= _maxCacheSize) {
      _evictOldestEntry();
    }

    _cache[key] = _CacheEntry(
      value: value,
      expiration: expiration ?? _defaultExpiration,
    );
  }

  /// キャッシュから値を削除
  static void remove(String key) {
    _cache.remove(key);
  }

  /// キャッシュをクリア
  static void clear() {
    _cache.clear();
  }

  /// 期限切れのエントリを削除
  static void _cleanupExpiredEntries() {
    final expiredKeys = _cache.keys
        .where((key) => _cache[key]!.isExpired)
        .toList();
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// 最も古いエントリを削除
  static void _evictOldestEntry() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
        oldestTime = entry.value.createdAt;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }

  /// キャッシュの統計情報を取得
  static Map<String, dynamic> getStats() {
    _cleanupExpiredEntries();
    
    return {
      'size': _cache.length,
      'maxSize': _maxCacheSize,
      'keys': _cache.keys.toList(),
    };
  }
}

/// キャッシュエントリ
class _CacheEntry {
  final dynamic value;
  final Duration expiration;
  final DateTime createdAt;

  _CacheEntry({
    required this.value,
    required this.expiration,
  }) : createdAt = DateTime.now();

  bool get isExpired {
    return DateTime.now().isAfter(createdAt.add(expiration));
  }
}

/// メモ化機能を提供するミックスイン
mixin MemoizationMixin {
  final Map<String, dynamic> _memoCache = {};

  /// メモ化された値を取得または計算
  T memoize<T>(String key, T Function() compute) {
    if (_memoCache.containsKey(key)) {
      return _memoCache[key] as T;
    }

    final result = compute();
    _memoCache[key] = result;
    return result;
  }

  /// メモ化された値をクリア
  void clearMemo(String key) {
    _memoCache.remove(key);
  }

  /// すべてのメモ化された値をクリア
  void clearAllMemos() {
    _memoCache.clear();
  }
}

/// 遅延読み込み機能
class LazyLoader<T> {
  T? _value;
  bool _isLoaded = false;
  final Future<T> Function() _loader;

  LazyLoader(this._loader);

  /// 値を取得（必要に応じて読み込み）
  Future<T> get() async {
    if (!_isLoaded) {
      _value = await _loader();
      _isLoaded = true;
    }
    return _value!;
  }

  /// 強制的に再読み込み
  Future<T> reload() async {
    _isLoaded = false;
    return await get();
  }

  /// 読み込み済みかどうか
  bool get isLoaded => _isLoaded;

  /// 現在の値（読み込み済みの場合のみ）
  T? get currentValue => _isLoaded ? _value : null;
}

/// バッチ処理機能
class BatchProcessor<T> {
  final List<T> _items = [];
  final Duration _batchDelay;
  final void Function(List<T>) _processor;
  Timer? _timer;

  BatchProcessor({
    required void Function(List<T>) processor,
    Duration batchDelay = const Duration(milliseconds: 100),
  }) : _processor = processor, _batchDelay = batchDelay;

  /// アイテムを追加
  void add(T item) {
    _items.add(item);
    _scheduleProcessing();
  }

  /// 複数のアイテムを追加
  void addAll(List<T> items) {
    _items.addAll(items);
    _scheduleProcessing();
  }

  /// 処理をスケジュール
  void _scheduleProcessing() {
    _timer?.cancel();
    _timer = Timer(_batchDelay, process);
  }

  /// バッチ処理を実行
  void process() {
    if (_items.isNotEmpty) {
      final itemsToProcess = List<T>.from(_items);
      _items.clear();
      _processor(itemsToProcess);
    }
  }

  /// 強制的に処理を実行
  void flush() {
    _timer?.cancel();
    process();
  }

  /// リソースを解放
  void dispose() {
    _timer?.cancel();
    _items.clear();
  }
}

/// デバウンス機能
class Debouncer {
  Timer? _timer;

  /// デバウンス処理を実行
  void run(VoidCallback action, {Duration delay = const Duration(milliseconds: 300)}) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// リソースを解放
  void dispose() {
    _timer?.cancel();
  }
}

/// スロットリング機能
class Throttler {
  DateTime? _lastRun;

  /// スロットリング処理を実行
  bool run(VoidCallback action, {Duration interval = const Duration(milliseconds: 100)}) {
    final now = DateTime.now();
    
    if (_lastRun == null || now.difference(_lastRun!) >= interval) {
      action();
      _lastRun = now;
      return true;
    }
    
    return false;
  }
}
