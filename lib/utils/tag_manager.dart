import '../models/link_item.dart';

class TagManager {
  // メインタグの定義
  static const Map<LinkType, List<String>> mainTags = {
    LinkType.folder: ['ローカル', 'サーバー', 'クラウドストレージ', 'ネットワーク'],
    LinkType.url: ['仕事', 'プライベート', '技術資料', 'ニュース', 'ショッピング', 'エンターテイメント'],
    LinkType.file: ['ドキュメント', '画像', '動画', '音楽', 'アーカイブ', 'その他'],
  };

  // サブタグの定義
  static const Map<String, List<String>> subTags = {
    // フォルダ関連
    'ローカル': ['ドキュメント', 'ダウンロード', 'ピクチャ', 'ミュージック', 'ビデオ', 'デスクトップ'],
    'サーバー': ['Web', 'データベース', 'バックアップ', 'ログ', '設定'],
    'クラウドストレージ': ['Google Drive', 'OneDrive', 'Dropbox', 'iCloud'],
    'ネットワーク': ['共有フォルダ', 'NAS', 'FTP'],
    
    // URL関連
    '仕事': ['メール', 'カレンダー', 'プロジェクト管理', 'ドキュメント', '会議'],
    'プライベート': ['SNS', 'ブログ', '趣味', '学習'],
    '技術資料': ['ドキュメント', 'API', 'チュートリアル', 'サンプルコード'],
    'ニュース': ['技術', '一般', '経済', 'スポーツ'],
    'ショッピング': ['ECサイト', '比較サイト', 'レビュー'],
    'エンターテイメント': ['動画', '音楽', 'ゲーム', '映画'],
    
    // ファイル関連
    'ドキュメント': ['PDF', 'Word', 'Excel', 'PowerPoint', 'テキスト'],
    '画像': ['写真', 'イラスト', 'スクリーンショット', 'アイコン'],
    '動画': ['映画', 'TV', 'YouTube', 'プレゼンテーション'],
    '音楽': ['MP3', 'WAV', 'FLAC', 'プレイリスト'],
    'アーカイブ': ['ZIP', 'RAR', '7Z', 'ISO'],
    'その他': ['実行ファイル', '設定ファイル', 'データファイル'],
  };

  // メインタグの取得
  static List<String> getMainTags(LinkType type) {
    return mainTags[type] ?? [];
  }

  // サブタグの取得
  static List<String> getSubTags(String mainTag) {
    return subTags[mainTag] ?? [];
  }

  // 全メインタグの取得
  static List<String> getAllMainTags() {
    return mainTags.values.expand((tags) => tags).toList();
  }

  // 全サブタグの取得
  static List<String> getAllSubTags() {
    return subTags.values.expand((tags) => tags).toList();
  }

  // タグの検証
  static bool isValidMainTag(LinkType type, String tag) {
    return mainTags[type]?.contains(tag) ?? false;
  }

  static bool isValidSubTag(String mainTag, String subTag) {
    return subTags[mainTag]?.contains(subTag) ?? false;
  }

  // タグの自動提案
  static List<String> suggestMainTags(LinkType type, String query) {
    final tags = getMainTags(type);
    if (query.isEmpty) return tags;
    return tags.where((tag) => tag.toLowerCase().contains(query.toLowerCase())).toList();
  }

  static List<String> suggestSubTags(String mainTag, String query) {
    final tags = getSubTags(mainTag);
    if (query.isEmpty) return tags;
    return tags.where((tag) => tag.toLowerCase().contains(query.toLowerCase())).toList();
  }

  // リンクアイテムのタグフィルタリング
  static bool matchesTagFilter(LinkItem item, String? mainTagFilter, String? subTagFilter) {
    if (mainTagFilter == null && subTagFilter == null) return true;
    
    if (mainTagFilter != null && item.mainTag != mainTagFilter) return false;
    if (subTagFilter != null && item.subTag != subTagFilter) return false;
    
    return true;
  }

  // グループ内のアイテムをタグでフィルタリング
  static List<LinkItem> filterItemsByTag(List<LinkItem> items, String? mainTag, String? subTag) {
    return items.where((item) => matchesTagFilter(item, mainTag, subTag)).toList();
  }

  // タグ統計の取得
  static Map<String, int> getTagStatistics(List<LinkItem> items) {
    final stats = <String, int>{};
    
    for (final item in items) {
      if (item.mainTag != null) {
        stats[item.mainTag!] = (stats[item.mainTag!] ?? 0) + 1;
      }
      if (item.subTag != null) {
        stats[item.subTag!] = (stats[item.subTag!] ?? 0) + 1;
      }
    }
    
    return stats;
  }

  // 人気タグの取得
  static List<String> getPopularTags(List<LinkItem> items, {int limit = 10}) {
    final stats = getTagStatistics(items);
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => e.key).toList();
  }
}
