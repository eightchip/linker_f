import 'dart:io';
import 'package:flutter/material.dart';

class FaviconService {
  /// URLからfaviconを取得する
  /// 失敗時はフォールバックドメインを試行
  static Future<String?> getFaviconUrl(String url, {String? fallbackDomain}) async {
    try {
      // 1. 元のURLからfaviconを取得
      final originalFavicon = await _tryGetFavicon(url);
      if (originalFavicon != null) {
        return originalFavicon;
      }

      // 2. フォールバックドメインが設定されている場合、それを試行
      if (fallbackDomain != null && fallbackDomain.isNotEmpty) {
        final fallbackFavicon = await _tryGetFavicon(fallbackDomain);
        if (fallbackFavicon != null) {
          return fallbackFavicon;
        }
      }

      // 3. ドメインから推測されるフォールバックを試行
      final domainFallback = _getDomainFallback(url);
      if (domainFallback != null) {
        final domainFallbackFavicon = await _tryGetFavicon(domainFallback);
        if (domainFallbackFavicon != null) {
          return domainFallbackFavicon;
        }
      }

      return null;
    } catch (e) {
      print('Favicon取得エラー: $e');
      return null;
    }
  }

  /// 特定のURLからfaviconを取得を試行
  static Future<String?> _tryGetFavicon(String url) async {
    try {
      // Googleのfaviconサービスを使用
      final faviconUrl = 'https://www.google.com/s2/favicons?sz=32&domain_url=$url';
      
      // 実際にfaviconが存在するかチェック（簡易版）
      final uri = Uri.parse(faviconUrl);
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        return faviconUrl;
      }
      
      return null;
    } catch (e) {
      print('Favicon取得失敗 ($url): $e');
      return null;
    }
  }

  /// ドメインから推測されるフォールバックURLを取得
  static String? _getDomainFallback(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      
      // 特定のドメインパターンに対するフォールバック
      if (host.contains('b-direct.resonabank.co.jp')) {
        return 'https://www.resonabank.co.jp/';
      }
      if (host.contains('sharepoint.com')) {
        return 'https://www.microsoft.com/';
      }
      if (host.contains('u-next.jp') || host.contains('unext.jp')) {
        return 'https://video.unext.jp/';
      }
      if (host.contains('amazon.co.jp')) {
        return 'https://www.amazon.co.jp/';
      }
      if (host.contains('youtube.com')) {
        return 'https://www.youtube.com/';
      }
      if (host.contains('github.com')) {
        return 'https://github.com/';
      }
      if (host.contains('google.com')) {
        return 'https://www.google.com/';
      }
      
      // 一般的なパターン：サブドメインからメインドメインを推測
      final parts = host.split('.');
      if (parts.length > 2) {
        // サブドメインがある場合、メインドメインを試行
        final mainDomain = parts.sublist(parts.length - 2).join('.');
        return 'https://www.$mainDomain/';
      }
      
      return null;
    } catch (e) {
      print('ドメインフォールバック解析エラー: $e');
      return null;
    }
  }

  /// favicon取得に失敗した場合のフォールバックアイコンを取得
  static Widget getFallbackIcon(String url, {double size = 20}) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      
      // 特定のドメインに対するカスタムアイコン
      if (host.contains('resonabank.co.jp')) {
        return Icon(Icons.account_balance, color: Colors.green, size: size);
      }
      if (host.contains('sharepoint.com')) {
        return Icon(Icons.business, color: Colors.blue, size: size);
      }
      if (host.contains('u-next.jp') || host.contains('unext.jp')) {
        return Icon(Icons.play_circle_filled, color: Colors.red, size: size);
      }
      if (host.contains('amazon.co.jp')) {
        return Icon(Icons.shopping_cart, color: Colors.orange, size: size);
      }
      if (host.contains('youtube.com')) {
        return Icon(Icons.play_circle_filled, color: Colors.red, size: size);
      }
      if (host.contains('github.com')) {
        return Icon(Icons.code, color: Colors.black, size: size);
      }
      if (host.contains('google.com')) {
        return Icon(Icons.search, color: Colors.blue, size: size);
      }
      
      // デフォルトアイコン
      return Icon(Icons.link, color: Colors.grey, size: size);
    } catch (e) {
      return Icon(Icons.link, color: Colors.grey, size: size);
    }
  }
}
