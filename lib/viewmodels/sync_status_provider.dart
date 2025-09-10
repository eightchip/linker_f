import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 同期状態の種類
enum SyncStatus {
  idle,      // 待機中
  syncing,   // 同期中
  success,   // 成功
  error,     // エラー
}

/// 同期状態のデータクラス
class SyncState {
  final SyncStatus status;
  final String? message;
  final String? errorMessage;
  final String? errorCode;
  final DateTime? lastSyncTime;
  final int? progress; // 0-100の進捗
  final int? totalItems;
  final int? processedItems;

  const SyncState({
    this.status = SyncStatus.idle,
    this.message,
    this.errorMessage,
    this.errorCode,
    this.lastSyncTime,
    this.progress,
    this.totalItems,
    this.processedItems,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? message,
    String? errorMessage,
    String? errorCode,
    DateTime? lastSyncTime,
    int? progress,
    int? totalItems,
    int? processedItems,
  }) {
    return SyncState(
      status: status ?? this.status,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      progress: progress ?? this.progress,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
    );
  }

  /// 同期中かどうか
  bool get isSyncing => status == SyncStatus.syncing;
  
  /// エラーがあるかどうか
  bool get hasError => status == SyncStatus.error;
  
  /// 成功したかどうか
  bool get isSuccess => status == SyncStatus.success;
  
  /// 進捗率を取得（0.0-1.0）
  double get progressRatio {
    if (totalItems == null || totalItems == 0) return 0.0;
    return (processedItems ?? 0) / totalItems!;
  }
}

/// 同期状態のプロバイダー
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncState>((ref) {
  return SyncStatusNotifier();
});

/// 同期状態の管理クラス
class SyncStatusNotifier extends StateNotifier<SyncState> {
  SyncStatusNotifier() : super(const SyncState());

  /// 同期開始
  void startSync({String? message, int? totalItems}) {
    state = state.copyWith(
      status: SyncStatus.syncing,
      message: message ?? '同期中...',
      errorMessage: null,
      errorCode: null,
      progress: 0,
      totalItems: totalItems,
      processedItems: 0,
    );
  }

  /// 同期進捗更新
  void updateProgress({
    String? message,
    int? processedItems,
    int? progress,
  }) {
    state = state.copyWith(
      message: message ?? state.message,
      processedItems: processedItems ?? state.processedItems,
      progress: progress ?? state.progress,
    );
  }

  /// 同期成功
  void syncSuccess({String? message}) {
    state = state.copyWith(
      status: SyncStatus.success,
      message: message ?? '同期が完了しました',
      errorMessage: null,
      errorCode: null,
      lastSyncTime: DateTime.now(),
      progress: 100,
    );
  }

  /// 同期エラー
  void syncError({
    required String errorMessage,
    String? errorCode,
    String? message,
  }) {
    state = state.copyWith(
      status: SyncStatus.error,
      message: message ?? '同期に失敗しました',
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }

  /// 状態をリセット
  void reset() {
    state = const SyncState();
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(
      status: SyncStatus.idle,
      errorMessage: null,
      errorCode: null,
    );
  }
}
