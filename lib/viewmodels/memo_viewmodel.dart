import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/memo_item.dart';

final memoViewModelProvider = StateNotifierProvider<MemoViewModel, List<MemoItem>>((ref) {
  return MemoViewModel();
});

class MemoViewModel extends StateNotifier<List<MemoItem>> {
  MemoViewModel() : super([]) {
    _initializeMemoBox();
  }

  static const String _boxName = 'memos';
  Box<MemoItem>? _memoBox;
  final _uuid = const Uuid();
  bool _isInitialized = false;

  Future<void> waitForInitialization() async {
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _initializeMemoBox() async {
    try {
      if (!Hive.isAdapterRegistered(32)) {
        Hive.registerAdapter(MemoItemAdapter());
      }
      
      _memoBox = await Hive.openBox<MemoItem>(_boxName);
      await _loadMemos();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('メモ帳ボックス初期化完了: ${state.length}件');
      }
    } catch (e) {
      print('メモ帳ボックス初期化エラー: $e');
      _isInitialized = true; // エラーでも初期化完了として扱う
      state = [];
    }
  }

  Future<void> _loadMemos() async {
    try {
      if (_memoBox == null || !_memoBox!.isOpen) {
        await _initializeMemoBox();
      }
      
      final memos = _memoBox!.values.toList();
      // 更新日時の降順でソート（新しいものが上）
      memos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = memos;
    } catch (e) {
      print('メモ読み込みエラー: $e');
      state = [];
    }
  }

  /// メモを追加
  Future<void> addMemo(String content) async {
    try {
      if (_memoBox == null || !_memoBox!.isOpen) {
        await _initializeMemoBox();
      }

      final now = DateTime.now();
      final memo = MemoItem(
        id: _uuid.v4(),
        content: content.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await _memoBox!.put(memo.id, memo);
      await _memoBox!.flush();
      await _loadMemos();

      if (kDebugMode) {
        print('メモを追加しました: ${memo.id}');
      }
    } catch (e) {
      print('メモ追加エラー: $e');
      rethrow;
    }
  }

  /// メモを更新
  Future<void> updateMemo(String id, String content) async {
    try {
      if (_memoBox == null || !_memoBox!.isOpen) {
        await _initializeMemoBox();
      }

      final existingMemo = _memoBox!.get(id);
      if (existingMemo == null) {
        throw Exception('メモが見つかりません: $id');
      }

      final updatedMemo = existingMemo.copyWith(
        content: content.trim(),
        updatedAt: DateTime.now(),
      );

      await _memoBox!.put(id, updatedMemo);
      await _memoBox!.flush();
      await _loadMemos();

      if (kDebugMode) {
        print('メモを更新しました: $id');
      }
    } catch (e) {
      print('メモ更新エラー: $e');
      rethrow;
    }
  }

  /// メモを削除
  Future<void> deleteMemo(String id) async {
    try {
      if (_memoBox == null || !_memoBox!.isOpen) {
        await _initializeMemoBox();
      }

      await _memoBox!.delete(id);
      await _memoBox!.flush();
      await _loadMemos();

      if (kDebugMode) {
        print('メモを削除しました: $id');
      }
    } catch (e) {
      print('メモ削除エラー: $e');
      rethrow;
    }
  }

  /// メモを検索
  List<MemoItem> searchMemos(String query) {
    if (query.isEmpty) {
      return state;
    }
    
    final lowerQuery = query.toLowerCase();
    return state.where((memo) {
      return memo.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}




