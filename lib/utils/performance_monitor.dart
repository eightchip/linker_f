import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// パフォーマンス監視サービス
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // 監視データ
  final Map<String, _MetricData> _metrics = {};
  final Queue<_PerformanceEvent> _events = Queue();
  final int _maxEvents = 1000;
  
  
  // メモリ使用量
  int _memoryUsage = 0;
  int _peakMemoryUsage = 0;
  
  // タイマー
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  /// 監視を開始
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(interval, (_) => _collectMetrics());
    
    if (kDebugMode) {
      print('パフォーマンス監視を開始しました（間隔: ${interval.inSeconds}秒）');
    }
  }

  /// 監視を停止
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    
    if (kDebugMode) {
      print('パフォーマンス監視を停止しました');
    }
  }

  /// メトリクスを記録
  void recordMetric(String name, double value, {String? unit}) {
    if (!_metrics.containsKey(name)) {
      _metrics[name] = _MetricData(name: name, unit: unit);
    }
    
    _metrics[name]!.addValue(value);
  }

  /// イベントを記録
  void recordEvent(String name, {Map<String, dynamic>? data}) {
    final event = _PerformanceEvent(
      name: name,
      timestamp: DateTime.now(),
      data: data,
    );
    
    _events.add(event);
    
    // 最大イベント数を超えた場合、古いイベントを削除
    if (_events.length > _maxEvents) {
      _events.removeFirst();
    }
  }


  /// メモリ使用量を更新
  void updateMemoryUsage(int bytes) {
    _memoryUsage = bytes;
    if (bytes > _peakMemoryUsage) {
      _peakMemoryUsage = bytes;
    }
  }

  /// パフォーマンス測定を実行
  Future<T> measureAsync<T>(String operationName, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      recordMetric('${operationName}_duration', stopwatch.elapsedMicroseconds.toDouble(), unit: 'μs');
      recordEvent('${operationName}_completed', data: {'duration': stopwatch.elapsedMicroseconds});
      
      return result;
    } catch (e) {
      stopwatch.stop();
      recordMetric('${operationName}_error_duration', stopwatch.elapsedMicroseconds.toDouble(), unit: 'μs');
      recordEvent('${operationName}_error', data: {'duration': stopwatch.elapsedMicroseconds, 'error': e.toString()});
      rethrow;
    }
  }

  /// 同期パフォーマンス測定を実行
  T measureSync<T>(String operationName, T Function() operation) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      recordMetric('${operationName}_duration', stopwatch.elapsedMicroseconds.toDouble(), unit: 'μs');
      recordEvent('${operationName}_completed', data: {'duration': stopwatch.elapsedMicroseconds});
      
      return result;
    } catch (e) {
      stopwatch.stop();
      recordMetric('${operationName}_error_duration', stopwatch.elapsedMicroseconds.toDouble(), unit: 'μs');
      recordEvent('${operationName}_error', data: {'duration': stopwatch.elapsedMicroseconds, 'error': e.toString()});
      rethrow;
    }
  }

  /// メトリクスを収集
  void _collectMetrics() {
    try {
      
      // メモリ使用量を収集
      recordMetric('memory_usage', _memoryUsage.toDouble(), unit: 'bytes');
      recordMetric('peak_memory_usage', _peakMemoryUsage.toDouble(), unit: 'bytes');
      
      // イベント数を記録
      recordMetric('events_count', _events.length.toDouble());
      
      if (kDebugMode) {
        print('メトリクスを収集しました: ${_metrics.length}個のメトリクス、${_events.length}個のイベント');
      }
    } catch (e) {
      if (kDebugMode) {
        print('メトリクス収集エラー: $e');
      }
    }
  }

  /// パフォーマンスレポートを取得
  PerformanceReport generateReport() {
    final report = PerformanceReport(
      metrics: Map.from(_metrics),
      events: List.from(_events),
      memoryStats: _generateMemoryStats(),
      timestamp: DateTime.now(),
    );
    
    return report;
  }


  /// メモリ統計を生成
  _MemoryStats _generateMemoryStats() {
    return _MemoryStats(
      currentUsage: _memoryUsage,
      peakUsage: _peakMemoryUsage,
    );
  }

  /// メトリクスをリセット
  void resetMetrics() {
    _metrics.clear();
    _events.clear();
    _memoryUsage = 0;
    _peakMemoryUsage = 0;
    
    if (kDebugMode) {
      print('パフォーマンスメトリクスをリセットしました');
    }
  }

  /// 特定のメトリクスを取得
  _MetricData? getMetric(String name) {
    return _metrics[name];
  }

  /// すべてのメトリクスを取得
  Map<String, _MetricData> getAllMetrics() {
    return Map.from(_metrics);
  }

  /// 最近のイベントを取得
  List<_PerformanceEvent> getRecentEvents({int count = 10}) {
    return _events.take(count).toList();
  }

  /// 特定のイベントを検索
  List<_PerformanceEvent> searchEvents(String name) {
    return _events.where((event) => event.name.contains(name)).toList();
  }

  /// 監視状態を取得
  bool get isMonitoring => _isMonitoring;
}

/// メトリクスデータ
class _MetricData {
  final String name;
  final String? unit;
  final List<double> values = [];
  final List<DateTime> timestamps = [];
  
  double _min = double.infinity;
  double _max = double.negativeInfinity;
  double _sum = 0.0;
  int _count = 0;

  _MetricData({required this.name, this.unit});

  void addValue(double value) {
    values.add(value);
    timestamps.add(DateTime.now());
    
    _min = value < _min ? value : _min;
    _max = value > _max ? value : _max;
    _sum += value;
    _count++;
    
    // 最大1000個の値まで保持
    if (values.length > 1000) {
      values.removeAt(0);
      timestamps.removeAt(0);
    }
  }

  double get min => _min == double.infinity ? 0.0 : _min;
  double get max => _max == double.negativeInfinity ? 0.0 : _max;
  double get average => _count > 0 ? _sum / _count : 0.0;
  int get count => _count;
  double get sum => _sum;

  String get formattedValue {
    if (unit == null) return average.toStringAsFixed(2);
    return '${average.toStringAsFixed(2)} $unit';
  }
}

/// パフォーマンスイベント
class _PerformanceEvent {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  _PerformanceEvent({
    required this.name,
    required this.timestamp,
    this.data,
  });

  String get formattedTimestamp => 
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
}


/// メモリ統計
class _MemoryStats {
  final int currentUsage;
  final int peakUsage;

  _MemoryStats({
    required this.currentUsage,
    required this.peakUsage,
  });

  String get formattedCurrentUsage => _formatBytes(currentUsage);
  String get formattedPeakUsage => _formatBytes(peakUsage);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// パフォーマンスレポート
class PerformanceReport {
  final Map<String, _MetricData> metrics;
  final List<_PerformanceEvent> events;
  final _MemoryStats memoryStats;
  final DateTime timestamp;

  PerformanceReport({
    required this.metrics,
    required this.events,
    required this.memoryStats,
    required this.timestamp,
  });

  /// レポートをJSON形式で出力
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics.map((key, value) => MapEntry(key, {
        'name': value.name,
        'unit': value.unit,
        'min': value.min,
        'max': value.max,
        'average': value.average,
        'count': value.count,
        'sum': value.sum,
      })),
      'events': events.map((event) => {
        'name': event.name,
        'timestamp': event.timestamp.toIso8601String(),
        'data': event.data,
      }).toList(),
      'memoryStats': {
        'currentUsage': memoryStats.currentUsage,
        'peakUsage': memoryStats.peakUsage,
      },
    };
  }

  /// レポートを文字列形式で出力
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== パフォーマンスレポート ===');
    buffer.writeln('生成時刻: ${timestamp.toIso8601String()}');
    buffer.writeln();
    
    buffer.writeln('--- メトリクス ---');
    for (final metric in metrics.values) {
      buffer.writeln('${metric.name}: ${metric.formattedValue} (min: ${metric.min}, max: ${metric.max}, count: ${metric.count})');
    }
    buffer.writeln();
    
    
    buffer.writeln('--- メモリ統計 ---');
    buffer.writeln('現在使用量: ${memoryStats.formattedCurrentUsage}');
    buffer.writeln('ピーク使用量: ${memoryStats.formattedPeakUsage}');
    buffer.writeln();
    
    buffer.writeln('--- 最近のイベント ---');
    final recentEvents = events.take(5);
    for (final event in recentEvents) {
      buffer.writeln('${event.formattedTimestamp} - ${event.name}');
    }
    
    return buffer.toString();
  }
}

/// パフォーマンス監視の拡張メソッド
extension PerformanceMonitorExtension on PerformanceMonitor {
  /// メモリ使用量を自動更新
  void startMemoryMonitoring() {
    Timer.periodic(const Duration(seconds: 10), (_) {
      // 実際のメモリ使用量を取得する実装が必要
      // 現在はダミーデータを使用
      final dummyMemoryUsage = DateTime.now().millisecondsSinceEpoch % 1000000;
      updateMemoryUsage(dummyMemoryUsage);
    });
  }
}
