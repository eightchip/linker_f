import '../models/link_item.dart';

/// 使用頻度統計を計算するユーティリティクラス
class UsageStatistics {
  /// 使用頻度スコアを計算
  /// 使用回数と最終使用日時を基にスコアを算出
  static double calculateUsageScore(LinkItem link) {
    if (link.lastUsed == null) return 0.0;
    
    final now = DateTime.now();
    final daysSinceLastUse = now.difference(link.lastUsed!).inDays;
    
    // 使用回数による基本スコア（重み: 0.6）
    final useCountScore = (link.useCount * 10).clamp(0, 100).toDouble();
    
    // 最終使用日時による時間減衰スコア（重み: 0.4）
    // 1日前: 100点, 7日前: 70点, 30日前: 30点, 90日前: 10点
    double timeScore;
    if (daysSinceLastUse <= 1) {
      timeScore = 100.0;
    } else if (daysSinceLastUse <= 7) {
      timeScore = 100.0 - (daysSinceLastUse - 1) * 5.0;
    } else if (daysSinceLastUse <= 30) {
      timeScore = 70.0 - (daysSinceLastUse - 7) * 1.74;
    } else if (daysSinceLastUse <= 90) {
      timeScore = 30.0 - (daysSinceLastUse - 30) * 0.33;
    } else {
      timeScore = 10.0;
    }
    
    // 重み付き合計
    return (useCountScore * 0.6) + (timeScore * 0.4);
  }
  
  /// 使用頻度レベルを取得（視認性向上のため）
  static UsageLevel getUsageLevel(LinkItem link) {
    final score = calculateUsageScore(link);
    
    if (score >= 80) return UsageLevel.high;
    if (score >= 50) return UsageLevel.medium;
    if (score >= 20) return UsageLevel.low;
    return UsageLevel.veryLow;
  }
  
  /// 使用頻度に応じた色を取得
  static int getUsageColor(LinkItem link) {
    switch (getUsageLevel(link)) {
      case UsageLevel.high:
        return 0xFF4CAF50; // 緑（高頻度）
      case UsageLevel.medium:
        return 0xFFFF9800; // オレンジ（中頻度）
      case UsageLevel.low:
        return 0xFF2196F3; // 青（低頻度）
      case UsageLevel.veryLow:
        return 0xFF9E9E9E; // グレー（非常に低頻度）
    }
  }
  
  /// 使用頻度に応じた背景色を取得
  static int getUsageBackgroundColor(LinkItem link) {
    switch (getUsageLevel(link)) {
      case UsageLevel.high:
        return 0xFFE8F5E8; // 薄い緑
      case UsageLevel.medium:
        return 0xFFFFF3E0; // 薄いオレンジ
      case UsageLevel.low:
        return 0xFFE3F2FD; // 薄い青
      case UsageLevel.veryLow:
        return 0xFFF5F5F5; // 薄いグレー
    }
  }
  
  /// 使用頻度に応じたアイコンを取得
  static String getUsageIcon(LinkItem link) {
    switch (getUsageLevel(link)) {
      case UsageLevel.high:
        return '🔥'; // 高頻度
      case UsageLevel.medium:
        return '⭐'; // 中頻度
      case UsageLevel.low:
        return '📌'; // 低頻度
      case UsageLevel.veryLow:
        return '📌'; // 非常に低頻度
    }
  }
  
  /// 使用頻度の説明文を取得
  static String getUsageDescription(LinkItem link) {
    switch (getUsageLevel(link)) {
      case UsageLevel.high:
        return '高頻度使用';
      case UsageLevel.medium:
        return '中頻度使用';
      case UsageLevel.low:
        return '低頻度使用';
      case UsageLevel.veryLow:
        return '使用頻度低';
    }
  }
}

/// 使用頻度レベル
enum UsageLevel {
  high,      // 高頻度（80点以上）
  medium,    // 中頻度（50-79点）
  low,       // 低頻度（20-49点）
  veryLow,   // 非常に低頻度（20点未満）
}
