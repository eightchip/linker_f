import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../models/email_contact.dart';
import '../models/sent_mail_log.dart';

class EmailContactService {
  static final EmailContactService _instance = EmailContactService._internal();
  factory EmailContactService() => _instance;
  EmailContactService._internal();

  static const String _boxName = 'email_contacts';
  Box<EmailContact>? _box;

  /// サービスを初期化
  Future<void> initialize() async {
    if (_box == null) {
      _box = await Hive.openBox<EmailContact>(_boxName);
      
      // 初回起動時にデフォルト連絡先を追加
      if (_box!.isEmpty) {
        await _initializeDefaultContacts();
      }
      
      if (kDebugMode) {
        print('EmailContactService初期化完了: ${_box!.length}件の連絡先を読み込み');
      }
    }
  }
  
  /// デフォルトの連絡先を初期化
  Future<void> _initializeDefaultContacts() async {
    final defaultContacts = [
      EmailContact(
        id: const Uuid().v4(),
        name: 'サンプル連絡先1',
        email: 'contact1@example.com',
        organization: 'サンプル会社',
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
        useCount: 0,
      ),
      EmailContact(
        id: const Uuid().v4(),
        name: 'サンプル連絡先2',
        email: 'contact2@example.com',
        organization: 'テスト会社',
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
        useCount: 0,
      ),
    ];
    
    for (final contact in defaultContacts) {
      await _box!.put(contact.id, contact);
    }
  }

  /// すべての連絡先を取得
  List<EmailContact> getAllContacts() {
    if (_box == null) return [];
    return _box!.values.toList();
  }

  /// よく使われる連絡先を取得（使用回数順）
  List<EmailContact> getFrequentContacts({int limit = 10}) {
    if (_box == null) return [];
    final sorted = _box!.values.toList();
    sorted.sort((a, b) => b.useCount.compareTo(a.useCount));
    return sorted.take(limit).toList();
  }


  /// 連絡先を追加
  Future<EmailContact> addContact({
    required String name,
    required String email,
    String? organization,
  }) async {
    if (_box == null) {
      await initialize();
    }
    
    // 重複チェック
    final existing = _box!.values.where((c) => c.email.toLowerCase() == email.toLowerCase()).firstOrNull;
    if (existing != null) {
      throw Exception('このメールアドレスは既に登録されています: $email');
    }

    final contact = EmailContact(
      id: const Uuid().v4(),
      name: name,
      email: email,
      organization: organization,
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
      useCount: 1,
    );

    await _box!.put(contact.id, contact);
    
    if (kDebugMode) {
      print('連絡先を追加: ${contact.displayName}');
      print('保存後の連絡先数: ${_box!.length}');
    }

    return contact;
  }

  /// 連絡先を更新
  Future<EmailContact> updateContact(EmailContact contact) async {
    if (_box == null) {
      await initialize();
    }
    
    if (!_box!.containsKey(contact.id)) {
      throw Exception('連絡先が見つかりません: ${contact.id}');
    }

    await _box!.put(contact.id, contact);
    
    if (kDebugMode) {
      print('連絡先を更新: ${contact.displayName}');
    }

    return contact;
  }

  /// 連絡先を削除
  Future<void> deleteContact(String contactId) async {
    if (_box == null) return;
    
    final contact = _box!.get(contactId);
    if (contact == null) {
      throw Exception('連絡先が見つかりません: $contactId');
    }

    await _box!.delete(contactId);
    
    if (kDebugMode) {
      print('連絡先を削除: ${contact.displayName}');
    }
  }

  /// 連絡先の使用回数を更新
  Future<void> updateContactUsage(String email) async {
    if (_box == null) return;
    
    final contact = _box!.values.where((c) => c.email.toLowerCase() == email.toLowerCase()).firstOrNull;
    if (contact != null) {
      final updatedContact = contact.copyWith(
        lastUsedAt: DateTime.now(),
        useCount: contact.useCount + 1,
      );
      
      await _box!.put(contact.id, updatedContact);
      
      if (kDebugMode) {
        print('連絡先使用回数を更新: ${contact.email} -> ${contact.useCount + 1}');
      }
    }
  }

  /// 送信履歴から連絡先を抽出
  List<EmailContact> extractContactsFromHistory(List<SentMailLog> logs) {
    final contactMap = <String, EmailContact>{};
    
    for (final log in logs) {
      // To, Cc, Bccから連絡先を抽出
      final emails = [
        log.to,
        log.cc,
        log.bcc,
      ].where((email) => email.isNotEmpty).toList();

      for (final email in emails) {
        final cleanEmail = email.trim();
        if (cleanEmail.isNotEmpty && !contactMap.containsKey(cleanEmail)) {
          // メールアドレスから名前を推定
          String name = cleanEmail;
          if (cleanEmail.contains('@')) {
            name = cleanEmail.split('@')[0];
            name = name.replaceAll('.', ' ').replaceAll('_', ' ');
            name = name.split(' ').map((word) => 
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
            ).join(' ');
          }

          contactMap[cleanEmail] = EmailContact(
            id: const Uuid().v4(),
            name: name,
            email: cleanEmail,
            organization: null,
            createdAt: log.composedAt,
            lastUsedAt: log.composedAt,
            useCount: 1,
          );
        }
      }
    }

    return contactMap.values.toList();
  }

  /// メールアドレスで連絡先を検索
  EmailContact? getContactByEmail(String email) {
    if (_box == null) return null;
    return _box!.values.where((c) => c.email.toLowerCase() == email.toLowerCase()).firstOrNull;
  }

  /// 連絡先を検索
  List<EmailContact> searchContacts(String query) {
    if (query.isEmpty) return getAllContacts();
    
    final lowercaseQuery = query.toLowerCase();
    if (_box == null) return [];
    
    return _box!.values.where((contact) =>
      contact.name.toLowerCase().contains(lowercaseQuery) ||
      contact.email.toLowerCase().contains(lowercaseQuery) ||
      (contact.organization?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }

  /// リソースを解放
  Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }
}
