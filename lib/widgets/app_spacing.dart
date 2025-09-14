/// 統一されたスペーシングシステム
class AppSpacing {
  // 基本スペーシング（4px単位）
  static const double xs = 4.0;   // 4px
  static const double sm = 8.0;   // 8px
  static const double md = 12.0;  // 12px
  static const double lg = 16.0;  // 16px
  static const double xl = 20.0;  // 20px
  static const double xxl = 24.0; // 24px
  static const double xxxl = 32.0; // 32px
  
  // コンポーネント固有のスペーシング
  static const double cardPadding = 16.0;
  static const double dialogPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const double buttonSpacing = 8.0;
  static const double inputSpacing = 12.0;
  
  // レイアウト用スペーシング
  static const double pagePadding = 16.0;
  static const double contentSpacing = 16.0;
  static const double listItemSpacing = 8.0;
  
  // アイコンサイズ
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;
  
  // ボーダー半径
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  
  // シャドウ
  static const double shadowBlur = 4.0;
  static const double shadowBlurLarge = 8.0;
  static const double shadowBlurXLarge = 12.0;
  static const double shadowOffset = 2.0;
}

/// 統一されたアイコンサイズ
class AppIconSizes {
  static const double small = 16.0;
  static const double medium = 20.0;
  static const double large = 24.0;
  static const double xLarge = 32.0;
  static const double xxLarge = 48.0;
}

/// 統一されたアニメーション設定
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
