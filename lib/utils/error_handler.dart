import 'package:flutter/foundation.dart';

/// 統一されたエラーハンドリング機能
class ErrorHandler {
  /// エラーログの出力（デバッグモードのみ）
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('=== エラー発生 ===');
      print('コンテキスト: $context');
      print('エラー: $error');
      if (stackTrace != null) {
        print('スタックトレース: $stackTrace');
      }
      print('================');
    }
  }

  /// 非同期処理のエラーハンドリング
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation,
    String context, {
    T? defaultValue,
    bool shouldRethrow = false,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      logError(context, e, stackTrace);
      if (shouldRethrow) {
        rethrow;
      }
      return defaultValue;
    }
  }

  /// 同期処理のエラーハンドリング
  static T? handleSync<T>(
    T Function() operation,
    String context, {
    T? defaultValue,
    bool shouldRethrow = false,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      logError(context, e, stackTrace);
      if (shouldRethrow) {
        rethrow;
      }
      return defaultValue;
    }
  }

  /// データベース操作のエラーハンドリング
  static Future<T?> handleDatabaseOperation<T>(
    Future<T> Function() operation,
    String context, {
    T? defaultValue,
  }) async {
    return handleAsync(
      operation,
      'データベース操作: $context',
      defaultValue: defaultValue,
    );
  }

  /// ファイル操作のエラーハンドリング
  static Future<T?> handleFileOperation<T>(
    Future<T> Function() operation,
    String context, {
    T? defaultValue,
  }) async {
    return handleAsync(
      operation,
      'ファイル操作: $context',
      defaultValue: defaultValue,
    );
  }

  /// ネットワーク操作のエラーハンドリング
  static Future<T?> handleNetworkOperation<T>(
    Future<T> Function() operation,
    String context, {
    T? defaultValue,
  }) async {
    return handleAsync(
      operation,
      'ネットワーク操作: $context',
      defaultValue: defaultValue,
    );
  }

  /// UI操作のエラーハンドリング
  static T? handleUIOperation<T>(
    T Function() operation,
    String context, {
    T? defaultValue,
  }) {
    return handleSync(
      operation,
      'UI操作: $context',
      defaultValue: defaultValue,
    );
  }
}

/// エラー結果を表すクラス
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  factory Result.failure(String error) => Result._(error: error, isSuccess: false);

  bool get isFailure => !isSuccess;

  /// 成功時の処理を実行
  void onSuccess(void Function(T data) callback) {
    if (isSuccess && data != null) {
      callback(data);
    }
  }

  /// 失敗時の処理を実行
  void onFailure(void Function(String error) callback) {
    if (isFailure && error != null) {
      callback(error);
    }
  }

  /// 成功時はデータを返し、失敗時はデフォルト値を返す
  T orElse(T defaultValue) => isSuccess && data != null ? data! : defaultValue;
}

/// Result型を使用したエラーハンドリング
class ResultHandler {
  /// 非同期処理をResult型でラップ
  static Future<Result<T>> wrapAsync<T>(
    Future<T> Function() operation,
    String context,
  ) async {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (e, stackTrace) {
      ErrorHandler.logError(context, e, stackTrace);
      return Result.failure(e.toString());
    }
  }

  /// 同期処理をResult型でラップ
  static Result<T> wrapSync<T>(
    T Function() operation,
    String context,
  ) {
    try {
      final result = operation();
      return Result.success(result);
    } catch (e, stackTrace) {
      ErrorHandler.logError(context, e, stackTrace);
      return Result.failure(e.toString());
    }
  }
}
