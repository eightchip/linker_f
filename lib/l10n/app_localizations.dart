import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// アプリケーションのタイトル
  ///
  /// In ja, this message translates to:
  /// **'Link Navigator'**
  String get appTitle;

  /// Settings label
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// 一般設定セクション
  ///
  /// In ja, this message translates to:
  /// **'一般'**
  String get general;

  /// テーマ設定セクション
  ///
  /// In ja, this message translates to:
  /// **'テーマ'**
  String get theme;

  /// フォント設定セクション
  ///
  /// In ja, this message translates to:
  /// **'フォント'**
  String get font;

  /// バックアップ設定セクション
  ///
  /// In ja, this message translates to:
  /// **'バックアップ'**
  String get backup;

  /// 通知設定セクション
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get notifications;

  /// Outlook連携設定セクション
  ///
  /// In ja, this message translates to:
  /// **'Outlook連携'**
  String get outlook;

  /// 言語設定
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get language;

  /// 日本語
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get japanese;

  /// 英語
  ///
  /// In ja, this message translates to:
  /// **'English'**
  String get english;

  /// 自動取込を有効にするスイッチのタイトル
  ///
  /// In ja, this message translates to:
  /// **'自動取込を有効にする'**
  String get enableAutomaticImport;

  /// 自動取込機能の説明
  ///
  /// In ja, this message translates to:
  /// **'Outlookの個人カレンダーから予定を自動的に取り込みます。取り込んだ予定は「Outlook連携（自動取込）」タスクに紐づけられます。\n\n⚠️ 注意: 自動取込実行時に起動しているOutlookが落ちる場合があります。'**
  String get enableAutomaticImportDescription;

  /// 取込期間セクションのタイトル
  ///
  /// In ja, this message translates to:
  /// **'取込期間'**
  String get importPeriod;

  /// 取込期間の説明
  ///
  /// In ja, this message translates to:
  /// **'明日を起点に、どこまで未来の予定を取り込むか設定します。'**
  String get importPeriodDescription;

  /// 自動取込の頻度セクションのタイトル
  ///
  /// In ja, this message translates to:
  /// **'自動取込の頻度'**
  String get automaticImportFrequency;

  /// アプリ起動時のみの頻度オプション
  ///
  /// In ja, this message translates to:
  /// **'アプリ起動時のみ'**
  String get onlyOnAppStart;

  /// 30分ごとの頻度オプション
  ///
  /// In ja, this message translates to:
  /// **'30分ごと'**
  String get every30Minutes;

  /// 1時間ごとの頻度オプション
  ///
  /// In ja, this message translates to:
  /// **'1時間ごと'**
  String get every1Hour;

  /// 毎朝9:00の頻度オプション
  ///
  /// In ja, this message translates to:
  /// **'毎朝9:00'**
  String get everyMorning9am;

  /// 1週間の期間オプション
  ///
  /// In ja, this message translates to:
  /// **'1週間'**
  String get oneWeek;

  /// 2週間の期間オプション
  ///
  /// In ja, this message translates to:
  /// **'2週間'**
  String get twoWeeks;

  /// 1ヶ月の期間オプション
  ///
  /// In ja, this message translates to:
  /// **'1ヶ月'**
  String get oneMonth;

  /// 3ヶ月の期間オプション
  ///
  /// In ja, this message translates to:
  /// **'3ヶ月'**
  String get threeMonths;

  /// 半年の期間オプション
  ///
  /// In ja, this message translates to:
  /// **'半年'**
  String get halfYear;

  /// 1年の期間オプション
  ///
  /// In ja, this message translates to:
  /// **'1年'**
  String get oneYear;

  /// タスク管理画面のタイトル
  ///
  /// In ja, this message translates to:
  /// **'タスク管理'**
  String get taskManagement;

  /// リンク管理画面のタイトル
  ///
  /// In ja, this message translates to:
  /// **'リンク管理'**
  String get linkManagement;

  /// 選択中のアイテム数
  ///
  /// In ja, this message translates to:
  /// **'{count}件選択中'**
  String itemsSelected(int count);

  /// タスク画面で起動する設定のタイトル
  ///
  /// In ja, this message translates to:
  /// **'タスク画面で起動'**
  String get startWithTaskScreen;

  /// タスク画面で起動する設定の説明
  ///
  /// In ja, this message translates to:
  /// **'アプリ起動時にタスク画面をデフォルトで表示します。オフにすると、リンク管理画面で起動します。'**
  String get startWithTaskScreenDescription;

  /// 外観設定セクション
  ///
  /// In ja, this message translates to:
  /// **'外観'**
  String get appearance;

  /// レイアウト設定セクション
  ///
  /// In ja, this message translates to:
  /// **'レイアウト'**
  String get layout;

  /// データ設定セクション
  ///
  /// In ja, this message translates to:
  /// **'データ'**
  String get data;

  /// 連携設定セクション
  ///
  /// In ja, this message translates to:
  /// **'連携'**
  String get integration;

  /// その他設定セクション
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get others;

  /// 起動設定メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'起動設定'**
  String get startupSettings;

  /// テーマ設定メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'テーマ設定'**
  String get themeSettings;

  /// フォント設定ラベル
  ///
  /// In ja, this message translates to:
  /// **'フォント設定'**
  String get fontSettings;

  /// UIカスタマイズラベル
  ///
  /// In ja, this message translates to:
  /// **'UIカスタマイズ'**
  String get uiCustomization;

  /// グリッド設定ラベル
  ///
  /// In ja, this message translates to:
  /// **'グリッド設定'**
  String get gridSettings;

  /// カード設定ラベル
  ///
  /// In ja, this message translates to:
  /// **'カード設定'**
  String get cardSettings;

  /// Item settings title
  ///
  /// In ja, this message translates to:
  /// **'アイテム設定'**
  String get itemSettings;

  /// カードビュー設定ラベル
  ///
  /// In ja, this message translates to:
  /// **'カードビュー設定'**
  String get cardViewSettings;

  /// Notification settings title
  ///
  /// In ja, this message translates to:
  /// **'通知設定'**
  String get notificationSettings;

  /// Gmail integration title
  ///
  /// In ja, this message translates to:
  /// **'Gmail連携'**
  String get gmailIntegration;

  /// Reset button label
  ///
  /// In ja, this message translates to:
  /// **'リセット'**
  String get reset;

  /// 全画面共通の説明
  ///
  /// In ja, this message translates to:
  /// **'全画面共通'**
  String get allScreens;

  /// リンク画面の説明
  ///
  /// In ja, this message translates to:
  /// **'リンク画面'**
  String get linkScreen;

  /// リンク・タスク画面ラベル
  ///
  /// In ja, this message translates to:
  /// **'リンク・タスク画面'**
  String get linkAndTaskScreens;

  /// タスク一覧の説明
  ///
  /// In ja, this message translates to:
  /// **'タスク一覧'**
  String get taskList;

  /// 連携機能の説明
  ///
  /// In ja, this message translates to:
  /// **'各連携機能には個別の設定が必要です'**
  String get integrationSettingsRequired;

  /// ダークモードのタイトル
  ///
  /// In ja, this message translates to:
  /// **'ダークモード'**
  String get darkMode;

  /// ダークテーマの説明
  ///
  /// In ja, this message translates to:
  /// **'ダークテーマを使用'**
  String get useDarkTheme;

  /// キャンセルラベル
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// Reset settings button label
  ///
  /// In ja, this message translates to:
  /// **'設定をリセット'**
  String get resetSettings;

  /// 設定リセットの確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'すべてのUI設定をデフォルト値にリセットしますか？\nこの操作は取り消せません。'**
  String get resetSettingsConfirm;

  /// リセット実行ボタン
  ///
  /// In ja, this message translates to:
  /// **'リセット実行'**
  String get resetExecuted;

  /// UI設定をリセットボタン
  ///
  /// In ja, this message translates to:
  /// **'UI設定をリセット'**
  String get uiSettingsReset;

  /// UI設定リセットの確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'すべてのUIカスタマイズ設定をデフォルト値にリセットします。\n\nこの操作は取り消せません。\n本当に実行しますか？'**
  String get uiSettingsResetConfirm;

  /// UI設定リセット成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'UI設定をリセットしました'**
  String get uiSettingsResetSuccess;

  /// Save button
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// 閉じるボタン
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// グループを追加メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'グループを追加'**
  String get addGroup;

  /// 検索メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get search;

  /// メモ一括編集メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'メモ一括編集'**
  String get memoBulkEdit;

  /// ショートカットキーメニュー項目
  ///
  /// In ja, this message translates to:
  /// **'ショートカットキー'**
  String get shortcutKeys;

  /// リンク管理ショートカットダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'リンク管理ショートカット'**
  String get linkManagementShortcuts;

  /// グループを追加ショートカットの説明
  ///
  /// In ja, this message translates to:
  /// **'グループを追加'**
  String get addGroupShortcut;

  /// 検索バーを開くショートカットの説明
  ///
  /// In ja, this message translates to:
  /// **'検索バーを開く'**
  String get openSearchBar;

  /// タスク管理画面を開くショートカットの説明
  ///
  /// In ja, this message translates to:
  /// **'タスク管理画面を開く'**
  String get openTaskManagement;

  /// メモ一括編集を開くショートカットの説明
  ///
  /// In ja, this message translates to:
  /// **'メモ一括編集を開く'**
  String get openMemoBulkEdit;

  /// グループの並び順を変更ショートカットの説明
  ///
  /// In ja, this message translates to:
  /// **'グループの並び順を変更'**
  String get changeGroupOrder;

  /// 設定を開くショートカットの説明
  ///
  /// In ja, this message translates to:
  /// **'設定を開く'**
  String get openSettings;

  /// 3点メニューを表示ショートカットの説明
  ///
  /// In ja, this message translates to:
  /// **'3点メニューを表示'**
  String get showThreeDotMenu;

  /// 3点メニューにフォーカスショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'3点メニューにフォーカス'**
  String get focusThreeDotMenu;

  /// 検索バーを閉じるショートカットの説明
  ///
  /// In ja, this message translates to:
  /// **'検索バーを閉じる'**
  String get closeSearchBar;

  /// リンクタイプフィルターを切り替えショートカットの説明
  ///
  /// In ja, this message translates to:
  /// **'リンクタイプフィルターを切り替え'**
  String get switchLinkTypeFilter;

  /// ショートカット一覧を表示ショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'ショートカット一覧を表示'**
  String get showShortcutList;

  /// Links count display
  ///
  /// In ja, this message translates to:
  /// **'{count}個のリンク'**
  String linksCount(int count);

  /// 検索フィールドのプレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'検索（リンク名・メモ内容）'**
  String get searchLinkNameMemo;

  /// 検索結果数
  ///
  /// In ja, this message translates to:
  /// **'{count}件の結果'**
  String resultsCount(int count);

  /// No search results message
  ///
  /// In ja, this message translates to:
  /// **'検索結果なし'**
  String get noSearchResults;

  /// メモなしリンクメッセージ
  ///
  /// In ja, this message translates to:
  /// **'メモが登録されているリンクがありません'**
  String get noMemoLinks;

  /// まとめて保存ボタン
  ///
  /// In ja, this message translates to:
  /// **'まとめて保存'**
  String get saveAll;

  /// 検索バーのプレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'検索（ファイル名・フォルダ名・URL・タグ）'**
  String get searchPlaceholder;

  /// Type field
  ///
  /// In ja, this message translates to:
  /// **'タイプ'**
  String get type;

  /// All option
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get all;

  /// URLタイプ
  ///
  /// In ja, this message translates to:
  /// **'URL'**
  String get url;

  /// フォルダタイプ
  ///
  /// In ja, this message translates to:
  /// **'フォルダ'**
  String get folder;

  /// ファイルタイプ
  ///
  /// In ja, this message translates to:
  /// **'ファイル'**
  String get file;

  /// グローバルメニューのタイトル
  ///
  /// In ja, this message translates to:
  /// **'グローバルメニュー'**
  String get globalMenu;

  /// 共通メニューセクション
  ///
  /// In ja, this message translates to:
  /// **'共通'**
  String get common;

  /// リンク管理メニューセクション
  ///
  /// In ja, this message translates to:
  /// **'リンク管理（リンク管理画面で有効）'**
  String get linkManagementEnabled;

  /// タスク管理メニューセクション
  ///
  /// In ja, this message translates to:
  /// **'タスク管理（タスク管理画面で有効）'**
  String get taskManagementEnabled;

  /// New task label
  ///
  /// In ja, this message translates to:
  /// **'新しいタスク'**
  String get newTask;

  /// Bulk select mode label
  ///
  /// In ja, this message translates to:
  /// **'一括選択モード'**
  String get bulkSelectMode;

  /// CSV export label
  ///
  /// In ja, this message translates to:
  /// **'CSV出力'**
  String get csvExport;

  /// Schedule list label
  ///
  /// In ja, this message translates to:
  /// **'スケジュール一覧'**
  String get scheduleList;

  /// Grouping label
  ///
  /// In ja, this message translates to:
  /// **'グループ化'**
  String get grouping;

  /// Create from template label
  ///
  /// In ja, this message translates to:
  /// **'テンプレートから作成'**
  String get createFromTemplate;

  /// 統計・検索バー表示/非表示ショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'統計・検索バー表示/非表示'**
  String get toggleStatisticsSearchBar;

  /// ヘルプセンターメニュー項目
  ///
  /// In ja, this message translates to:
  /// **'ヘルプセンター'**
  String get helpCenter;

  /// パス/URLラベル
  ///
  /// In ja, this message translates to:
  /// **'パス/URL'**
  String get pathOrUrl;

  /// パス/URL入力フィールドのプレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'ファイルパスまたはURLを入力...'**
  String get enterPathOrUrl;

  /// フォルダアイコン選択のラベル
  ///
  /// In ja, this message translates to:
  /// **'フォルダアイコンを選択:'**
  String get selectFolderIcon;

  /// ホーム画面に戻るツールチップ
  ///
  /// In ja, this message translates to:
  /// **'ホーム画面に戻る'**
  String get homeScreen;

  /// 選択モードを終了ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'選択モードを終了'**
  String get exitSelectionMode;

  /// タスク管理画面の検索バープレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'タスクを検索（タイトル・説明・タグ・依頼先）'**
  String get searchTasks;

  /// 正規表現検索のプレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'正規表現で検索（例: ^プロジェクト.*完了\\\$）'**
  String get searchWithRegex;

  /// 検索履歴ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'検索履歴'**
  String get searchHistory;

  /// 検索履歴がない場合のメッセージ
  ///
  /// In ja, this message translates to:
  /// **'検索履歴がありません'**
  String get noSearchHistory;

  /// クリアツールチップ
  ///
  /// In ja, this message translates to:
  /// **'クリア'**
  String get clear;

  /// 通常検索に切り替えツールチップ
  ///
  /// In ja, this message translates to:
  /// **'通常検索に切り替え'**
  String get switchToNormalSearch;

  /// 正規表現検索に切り替えツールチップ
  ///
  /// In ja, this message translates to:
  /// **'正規表現検索に切り替え'**
  String get switchToRegexSearch;

  /// 検索オプションタイトル
  ///
  /// In ja, this message translates to:
  /// **'検索オプション'**
  String get searchOptions;

  /// メモ追加ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'メモ追加'**
  String get addMemo;

  /// メモ追加可能メッセージ
  ///
  /// In ja, this message translates to:
  /// **'メモはリンク管理画面から追加可能'**
  String get memoCanBeAddedFromLinkManagement;

  /// ピンを外すツールチップ
  ///
  /// In ja, this message translates to:
  /// **'ピンを外す'**
  String get unpin;

  /// ピン留めツールチップ
  ///
  /// In ja, this message translates to:
  /// **'上部にピン留め'**
  String get pinToTop;

  /// ステータスを変更ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'ステータスを変更'**
  String get changeStatus;

  /// 優先度変更ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'優先度を変更'**
  String get changePriority;

  /// フィルターを隠すツールチップ
  ///
  /// In ja, this message translates to:
  /// **'フィルターを隠す'**
  String get hideFilters;

  /// フィルターを表示ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'フィルターを表示'**
  String get showFilters;

  /// グリッド列数変更ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'グリッド列数を変更'**
  String get changeGridColumns;

  /// フィルター保存・読み込みツールチップ
  ///
  /// In ja, this message translates to:
  /// **'フィルター保存・読み込み'**
  String get saveLoadFilters;

  /// 一括操作ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'一括操作'**
  String get bulkOperations;

  /// Memo label with colon
  ///
  /// In ja, this message translates to:
  /// **'メモ:'**
  String get memoLabel;

  /// Select all button
  ///
  /// In ja, this message translates to:
  /// **'すべて選択'**
  String get selectAll;

  /// Deselect all button
  ///
  /// In ja, this message translates to:
  /// **'すべて解除'**
  String get deselectAll;

  /// カードビューツールチップ
  ///
  /// In ja, this message translates to:
  /// **'カードビュー'**
  String get cardView;

  /// リスト表示メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'リスト表示'**
  String get listView;

  /// ステータスラベル
  ///
  /// In ja, this message translates to:
  /// **'ステータス'**
  String get status;

  /// 未着手ステータス
  ///
  /// In ja, this message translates to:
  /// **'未着手'**
  String get notStarted;

  /// 進行中ステータス
  ///
  /// In ja, this message translates to:
  /// **'進行中'**
  String get inProgress;

  /// 完了ラベル
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get completed;

  /// 並び替え順序ラベル
  ///
  /// In ja, this message translates to:
  /// **'並び替え順序'**
  String get sortOrder;

  /// 第1順位ラベル
  ///
  /// In ja, this message translates to:
  /// **'第1順位'**
  String get firstPriority;

  /// 第2順位ラベル
  ///
  /// In ja, this message translates to:
  /// **'第2順位'**
  String get secondPriority;

  /// 第3順位ラベル
  ///
  /// In ja, this message translates to:
  /// **'第3順位'**
  String get thirdPriority;

  /// 期限順並び替え
  ///
  /// In ja, this message translates to:
  /// **'期限順'**
  String get dueDateOrder;

  /// ステータス順並び替え
  ///
  /// In ja, this message translates to:
  /// **'ステータス順'**
  String get statusOrder;

  /// 昇順並び替え
  ///
  /// In ja, this message translates to:
  /// **'昇順'**
  String get ascending;

  /// 降順並び替え
  ///
  /// In ja, this message translates to:
  /// **'降順'**
  String get descending;

  /// 優先度順ラベル
  ///
  /// In ja, this message translates to:
  /// **'優先度順'**
  String get priorityOrder;

  /// タイトル順ラベル
  ///
  /// In ja, this message translates to:
  /// **'タイトル順'**
  String get titleOrder;

  /// 作成日順ラベル
  ///
  /// In ja, this message translates to:
  /// **'作成日順'**
  String get createdOrder;

  /// None label
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get none;

  /// 詳細ボタン
  ///
  /// In ja, this message translates to:
  /// **'詳細'**
  String get details;

  /// リンクを折りたたむボタン
  ///
  /// In ja, this message translates to:
  /// **'リンクを折りたたむ'**
  String get collapseLinks;

  /// リンクを展開ボタン
  ///
  /// In ja, this message translates to:
  /// **'リンクを展開'**
  String get expandLinks;

  /// サブタスクラベル
  ///
  /// In ja, this message translates to:
  /// **'サブタスク'**
  String get subtask;

  /// サブタスクツールチップ
  ///
  /// In ja, this message translates to:
  /// **'サブタスク: {total}\n完了: {completed}'**
  String subtaskTooltip(int total, int completed);

  /// すべて詳細表示ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'すべて詳細表示'**
  String get showAllDetails;

  /// すべて詳細非表示ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'すべて詳細非表示'**
  String get hideAllDetails;

  /// 詳細表示/非表示切り替えショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'詳細表示/非表示切り替え'**
  String get toggleDetails;

  /// 列数ラベル
  ///
  /// In ja, this message translates to:
  /// **'列'**
  String get columns;

  /// 未着手タスクラベル
  ///
  /// In ja, this message translates to:
  /// **'未着手タスク'**
  String get notStartedTasks;

  /// 進行中タスクラベル
  ///
  /// In ja, this message translates to:
  /// **'進行中タスク'**
  String get inProgressTasks;

  /// ステータス変更ラベル
  ///
  /// In ja, this message translates to:
  /// **'ステータス変更'**
  String get statusChange;

  /// 期限日をクリアボタン
  ///
  /// In ja, this message translates to:
  /// **'期限日をクリア'**
  String get clearDueDate;

  /// 履歴クリアボタン
  ///
  /// In ja, this message translates to:
  /// **'履歴クリア'**
  String get clearHistory;

  /// 履歴をクリア確認ボタン
  ///
  /// In ja, this message translates to:
  /// **'履歴をクリア'**
  String get clearHistoryConfirm;

  /// グループ化なしオプション
  ///
  /// In ja, this message translates to:
  /// **'グループ化なし'**
  String get noGrouping;

  /// ステータスでグループ化オプション
  ///
  /// In ja, this message translates to:
  /// **'ステータスでグループ化'**
  String get groupByStatus;

  /// タグなしラベル
  ///
  /// In ja, this message translates to:
  /// **'タグなし'**
  String get noTags;

  /// リンクなしラベル
  ///
  /// In ja, this message translates to:
  /// **'リンクなし'**
  String get noLinks;

  /// 件数表示
  ///
  /// In ja, this message translates to:
  /// **'{label}: {count}件'**
  String countItems(String label, int count);

  /// タップで詳細表示メッセージ
  ///
  /// In ja, this message translates to:
  /// **'タップで詳細表示'**
  String get tapForDetails;

  /// グループを削除ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'グループを削除'**
  String get deleteGroup;

  /// グループ削除確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'このグループを削除しますか？'**
  String get deleteGroupConfirm;

  /// Add link dialog title
  ///
  /// In ja, this message translates to:
  /// **'リンクを追加'**
  String get addLink;

  /// Edit link dialog title
  ///
  /// In ja, this message translates to:
  /// **'リンクを編集'**
  String get editLink;

  /// リンクを削除ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'リンクを削除'**
  String get deleteLink;

  /// リンクからタスクを追加ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'リンクからタスクを追加'**
  String get addTaskFromLink;

  /// Copy tooltip
  ///
  /// In ja, this message translates to:
  /// **'コピー'**
  String get copy;

  /// タスク同期メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'このタスクを同期'**
  String get syncTask;

  /// Delete button
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// High priority label
  ///
  /// In ja, this message translates to:
  /// **'高'**
  String get high;

  /// 優先度：中
  ///
  /// In ja, this message translates to:
  /// **'中'**
  String get medium;

  /// 優先度：低
  ///
  /// In ja, this message translates to:
  /// **'低'**
  String get low;

  /// Urgent priority label
  ///
  /// In ja, this message translates to:
  /// **'緊急'**
  String get urgent;

  /// 優先度：低（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'低'**
  String get lowShort;

  /// 優先度：中（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'中'**
  String get mediumShort;

  /// 優先度：高（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'高'**
  String get highShort;

  /// 優先度：緊急（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'緊'**
  String get urgentShort;

  /// Cancelled status
  ///
  /// In ja, this message translates to:
  /// **'取消'**
  String get cancelled;

  /// キャンセルステータス（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'X'**
  String get cancelledShort;

  /// 期限ラベル
  ///
  /// In ja, this message translates to:
  /// **'期限'**
  String get dueDate;

  /// 着手ラベル
  ///
  /// In ja, this message translates to:
  /// **'着手'**
  String get started;

  /// タスク管理ショートカットダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'タスク管理ショートカット'**
  String get taskManagementShortcuts;

  /// ウィンドウ最小化ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'最小化'**
  String get minimize;

  /// ウィンドウ最大化ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'最大化'**
  String get maximize;

  /// ウィンドウを元のサイズに戻すツールチップ
  ///
  /// In ja, this message translates to:
  /// **'元のサイズに戻す'**
  String get restoreWindow;

  /// ショートカット一覧ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'ショートカット一覧'**
  String get shortcutList;

  /// 予定表画面タイトル
  ///
  /// In ja, this message translates to:
  /// **'予定表'**
  String get scheduleScreen;

  /// 予定表検索バーのプレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'予定タイトル、タスク名、場所で検索'**
  String get searchSchedule;

  /// 表示切り替えツールチップ
  ///
  /// In ja, this message translates to:
  /// **'表示切り替え'**
  String get switchView;

  /// 月次表示メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'月次表示'**
  String get monthlyView;

  /// 過去を表示チェックボックス
  ///
  /// In ja, this message translates to:
  /// **'過去を表示'**
  String get showPast;

  /// Outlookから予定を取り込むツールチップ
  ///
  /// In ja, this message translates to:
  /// **'Outlookから予定を取り込む'**
  String get importFromOutlook;

  /// エクセルにコピーツールチップ
  ///
  /// In ja, this message translates to:
  /// **'エクセルにコピー'**
  String get copyToExcel;

  /// エクセルにコピー（選択日付あり）
  ///
  /// In ja, this message translates to:
  /// **'エクセルにコピー（選択された{count}日分の予定をクリップボードにコピー）'**
  String copyToExcelSelected(int count);

  /// エクセルにコピー（日付未選択）
  ///
  /// In ja, this message translates to:
  /// **'エクセルにコピー（日付を選択してください）'**
  String get copyToExcelSelectDate;

  /// Table format
  ///
  /// In ja, this message translates to:
  /// **'表形式'**
  String get tableFormat;

  /// One cell format
  ///
  /// In ja, this message translates to:
  /// **'1セル形式'**
  String get oneCellFormat;

  /// アクションメニューツールチップ
  ///
  /// In ja, this message translates to:
  /// **'アクション'**
  String get action;

  /// Today group name
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get today;

  /// 残り日数
  ///
  /// In ja, this message translates to:
  /// **'あと{count}日'**
  String daysRemaining(int count);

  /// 残り1日
  ///
  /// In ja, this message translates to:
  /// **'あと1日'**
  String get oneDayRemaining;

  /// 超過日数
  ///
  /// In ja, this message translates to:
  /// **'{count}日超過'**
  String daysOverdue(int count);

  /// 1日超過
  ///
  /// In ja, this message translates to:
  /// **'1日超過'**
  String get oneDayOverdue;

  /// 未設定ラベル
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get notSet;

  /// 他のリンクを表示
  ///
  /// In ja, this message translates to:
  /// **'他{count}個のリンクを表示'**
  String showOtherLinks(int count);

  /// もっと見るボタン
  ///
  /// In ja, this message translates to:
  /// **'もっと見る'**
  String get showMore;

  /// タスク編集ダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'タスクを編集'**
  String get editTask;

  /// タイトルラベル
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get title;

  /// Body title
  ///
  /// In ja, this message translates to:
  /// **'本文'**
  String get body;

  /// Description for Requestor (deprecated, use descriptionForAssignee)
  ///
  /// In ja, this message translates to:
  /// **'依頼先への説明'**
  String get descriptionForRequestor;

  /// 依頼先への説明ラベル
  ///
  /// In ja, this message translates to:
  /// **'担当者への説明'**
  String get descriptionForAssignee;

  /// Tags field
  ///
  /// In ja, this message translates to:
  /// **'タグ'**
  String get tags;

  /// 着手日ラベル
  ///
  /// In ja, this message translates to:
  /// **'着手日'**
  String get startDate;

  /// 完了日ラベル
  ///
  /// In ja, this message translates to:
  /// **'完了日'**
  String get completionDate;

  /// リマインダー機能ラベル
  ///
  /// In ja, this message translates to:
  /// **'リマインダー機能'**
  String get reminderFunction;

  /// リンク関連付けラベル
  ///
  /// In ja, this message translates to:
  /// **'リンク関連付け'**
  String get linkAssociation;

  /// 関連リンクラベル
  ///
  /// In ja, this message translates to:
  /// **'関連リンク'**
  String get relatedLinks;

  /// ピン留めラベル
  ///
  /// In ja, this message translates to:
  /// **'ピン留め'**
  String get pinning;

  /// 予定ラベル
  ///
  /// In ja, this message translates to:
  /// **'予定'**
  String get schedule;

  /// メール送信機能ラベル
  ///
  /// In ja, this message translates to:
  /// **'メール送信機能'**
  String get emailSendingFunction;

  /// メール送信機能を開くラベル
  ///
  /// In ja, this message translates to:
  /// **'メール送信機能を開く'**
  String get openEmailSendingFunction;

  /// メール機能を折りたたむラベル
  ///
  /// In ja, this message translates to:
  /// **'メール機能を折りたたむ'**
  String get collapseMailFunction;

  /// Update button
  ///
  /// In ja, this message translates to:
  /// **'更新'**
  String get update;

  /// 着手日選択プレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'着手日を選択'**
  String get selectStartDate;

  /// サブタスクタイトルラベル
  ///
  /// In ja, this message translates to:
  /// **'サブタスクタイトル'**
  String get subtaskTitle;

  /// 推定時間ラベル
  ///
  /// In ja, this message translates to:
  /// **'推定時間 (分)'**
  String get estimatedTime;

  /// Description
  ///
  /// In ja, this message translates to:
  /// **'説明'**
  String get description;

  /// Add button
  ///
  /// In ja, this message translates to:
  /// **'追加する'**
  String get add;

  /// 作成日ラベル
  ///
  /// In ja, this message translates to:
  /// **'作成日'**
  String get creationDate;

  /// サブタスク名ラベル
  ///
  /// In ja, this message translates to:
  /// **'サブタスク名'**
  String get subtaskName;

  /// タイトル入力エラーメッセージ
  ///
  /// In ja, this message translates to:
  /// **'タイトルを入力してください'**
  String get enterTitle;

  /// 本文の行数制限説明
  ///
  /// In ja, this message translates to:
  /// **'本文は8行まで表示できます。'**
  String get bodyTextCanDisplayUpTo8Lines;

  /// サブタスクなしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'サブタスクがありません'**
  String get noSubtasks;

  /// 推定時間表示
  ///
  /// In ja, this message translates to:
  /// **'推定時間: {minutes}分'**
  String estimatedTimeMinutes(int minutes);

  /// 作成ボタン
  ///
  /// In ja, this message translates to:
  /// **'作成'**
  String get create;

  /// Select due date label
  ///
  /// In ja, this message translates to:
  /// **'期限日を選択'**
  String get selectDueDate;

  /// 優先度ラベル
  ///
  /// In ja, this message translates to:
  /// **'優先度'**
  String get priority;

  /// 着手日をクリアツールチップ
  ///
  /// In ja, this message translates to:
  /// **'着手日をクリア'**
  String get clearStartDate;

  /// 完了日選択プレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'完了日を選択'**
  String get selectCompletionDate;

  /// 完了日をクリアツールチップ
  ///
  /// In ja, this message translates to:
  /// **'完了日をクリア'**
  String get clearCompletionDate;

  /// 上部にピン留め中ラベル
  ///
  /// In ja, this message translates to:
  /// **'上部にピン留め中'**
  String get pinnedToTop;

  /// 正規表現の使い方タイトル
  ///
  /// In ja, this message translates to:
  /// **'正規表現の使い方'**
  String get howToUseRegex;

  /// よく使うパターンラベル
  ///
  /// In ja, this message translates to:
  /// **'よく使うパターン:'**
  String get commonPatterns;

  /// パターンをコピーツールチップ
  ///
  /// In ja, this message translates to:
  /// **'パターンをコピー'**
  String get copyPattern;

  /// パターンコピー完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'「{pattern}」をコピーしました'**
  String patternCopied(String pattern);

  /// 正規表現無効時の警告メッセージ
  ///
  /// In ja, this message translates to:
  /// **'正規表現が無効な場合は自動的に通常検索に切り替わります'**
  String get regexInvalidWarning;

  /// 正規表現例1の説明
  ///
  /// In ja, this message translates to:
  /// **'「プロジェクト」で始まるタスク'**
  String get regexExample1;

  /// 正規表現例2の説明
  ///
  /// In ja, this message translates to:
  /// **'「完了」で終わるタスク'**
  String get regexExample2;

  /// 正規表現例3の説明
  ///
  /// In ja, this message translates to:
  /// **'「プロジェクト」で始まり「完了」で終わるタスク'**
  String get regexExample3;

  /// 正規表現例4の説明
  ///
  /// In ja, this message translates to:
  /// **'「緊急」または「重要」を含むタスク'**
  String get regexExample4;

  /// 正規表現例5の説明
  ///
  /// In ja, this message translates to:
  /// **'日付形式（YYYY-MM-DD）を含むタスク'**
  String get regexExample5;

  /// 正規表現例6の説明
  ///
  /// In ja, this message translates to:
  /// **'2文字以上の大文字を含むタスク'**
  String get regexExample6;

  /// 正規表現例7の説明
  ///
  /// In ja, this message translates to:
  /// **'1〜10文字のタスクタイトル'**
  String get regexExample7;

  /// フィルターを保存ダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'フィルターを保存'**
  String get saveFilter;

  /// フィルター名ラベル
  ///
  /// In ja, this message translates to:
  /// **'フィルター名'**
  String get filterName;

  /// フィルター名の例
  ///
  /// In ja, this message translates to:
  /// **'例: 今週の緊急タスク'**
  String get filterNameExample;

  /// フィルター保存完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'フィルター「{name}」を保存しました'**
  String filterSaved(String name);

  /// 保存されたフィルターなしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'保存されたフィルターがありません'**
  String get noSavedFilters;

  /// フィルター読み込み完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'フィルター「{name}」を読み込みました'**
  String filterLoaded(String name);

  /// フィルタープリセットをエクスポートダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'フィルタープリセットをエクスポート'**
  String get exportFilterPresets;

  /// フィルタープリセットエクスポート完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'フィルタープリセットをエクスポートしました'**
  String get filterPresetsExported;

  /// フィルタープリセットをインポートダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'フィルタープリセットをインポート'**
  String get importFilterPresets;

  /// フィルタープリセットインポート完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'{count}件のフィルタープリセットをインポートしました'**
  String filterPresetsImported(int count);

  /// Export button
  ///
  /// In ja, this message translates to:
  /// **'出力'**
  String get export;

  /// インポートボタン
  ///
  /// In ja, this message translates to:
  /// **'インポート'**
  String get import;

  /// クイックフィルター適用完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'クイックフィルターを適用しました'**
  String get quickFilterApplied;

  /// フィルターリセット完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'フィルターをリセットしました'**
  String get filterReset;

  /// No description provided for @editGroupName.
  ///
  /// In ja, this message translates to:
  /// **'グループ名を編集'**
  String get editGroupName;

  /// New group name label
  ///
  /// In ja, this message translates to:
  /// **'新しいグループ名'**
  String get newGroupName;

  /// Color label
  ///
  /// In ja, this message translates to:
  /// **'色'**
  String get color;

  /// リンクからタスクを作成ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'このリンクからタスクを作成'**
  String get createTaskFromLink;

  /// アクティブなタスクがある場合のツールチップ
  ///
  /// In ja, this message translates to:
  /// **'アクティブなタスクがあります'**
  String get activeTaskExists;

  /// コピー先選択ダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'コピー先を選択'**
  String get selectCopyDestination;

  /// 移動先選択ダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'移動先を選択'**
  String get selectMoveDestination;

  /// リンクコピー完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'「{linkName}」を「{groupName}」にコピーしました'**
  String linkCopied(String linkName, String groupName);

  /// リンク移動完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'「{linkName}」を「{groupName}」に移動しました'**
  String linkMoved(String linkName, String groupName);

  /// コピー失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'コピーに失敗しました: {error}'**
  String copyFailed(String error);

  /// コピー機能が利用できないメッセージ
  ///
  /// In ja, this message translates to:
  /// **'コピー機能が利用できません'**
  String get copyNotAvailable;

  /// 移動機能が利用できないメッセージ
  ///
  /// In ja, this message translates to:
  /// **'移動機能が利用できません'**
  String get moveNotAvailable;

  /// コピー先グループなしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'コピー先のグループがありません'**
  String get noCopyDestinationGroups;

  /// 移動先グループなしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'移動先のグループがありません'**
  String get noMoveDestinationGroups;

  /// ドラッグ&ドロップ説明文
  ///
  /// In ja, this message translates to:
  /// **'ドラッグ&ドロップで並び順を変更できます'**
  String get dragToReorder;

  /// グループ並び順変更完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'グループの並び順を変更しました'**
  String get groupOrderChanged;

  /// タスクテンプレートダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'タスクテンプレート'**
  String get taskTemplate;

  /// テンプレート選択セクションタイトル
  ///
  /// In ja, this message translates to:
  /// **'テンプレートを選択'**
  String get selectTemplate;

  /// タスク詳細セクションタイトル
  ///
  /// In ja, this message translates to:
  /// **'タスク詳細'**
  String get taskDetails;

  /// テンプレート名ラベル
  ///
  /// In ja, this message translates to:
  /// **'テンプレート名'**
  String get templateName;

  /// テンプレート名の例
  ///
  /// In ja, this message translates to:
  /// **'例: 会議準備、定期報告など'**
  String get templateNameExample;

  /// タスク作成ボタン
  ///
  /// In ja, this message translates to:
  /// **'タスクを作成'**
  String get createTask;

  /// テンプレート編集ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'テンプレート編集'**
  String get editTemplate;

  /// 編集完了ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'編集完了'**
  String get editComplete;

  /// 新しいテンプレート追加ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'新しいテンプレートを追加'**
  String get addNewTemplate;

  /// このタスクを同期メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'このタスクを同期'**
  String get syncThisTask;

  /// タスク作成完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'タスクを作成しました'**
  String get taskCreated;

  /// リマインダーラベル
  ///
  /// In ja, this message translates to:
  /// **'リマインダー'**
  String get reminder;

  /// 選択してくださいプレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'選択してください'**
  String get selectPlease;

  /// Create new task button
  ///
  /// In ja, this message translates to:
  /// **'新規タスク作成'**
  String get createNewTask;

  /// 一括選択モードを切り替えショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'一括選択モードを切り替え'**
  String get toggleBatchSelectionMode;

  /// CSVにエクスポートショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'CSVにエクスポート'**
  String get exportToCsv;

  /// 設定画面を開くショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'設定画面を開く'**
  String get openSettingsScreen;

  /// 予定表を開くショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'予定表を開く'**
  String get openSchedule;

  /// グループ化メニューショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'グループ化メニュー'**
  String get groupingMenu;

  /// コンパクト⇔標準表示切り替えショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'コンパクト⇔標準表示切り替え'**
  String get toggleCompactStandardDisplay;

  /// ホームへ戻る / 3点メニューを開くショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'ホームへ戻る / 3点メニューを開く'**
  String get goHomeOrOpenThreeDotMenu;

  /// 履歴ラベル
  ///
  /// In ja, this message translates to:
  /// **'履歴'**
  String get history;

  /// Task label
  ///
  /// In ja, this message translates to:
  /// **'タスク'**
  String get task;

  /// 現在のフィルターを保存メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'現在のフィルターを保存'**
  String get saveCurrentFilter;

  /// フィルター管理メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'フィルター管理'**
  String get filterManagement;

  /// 緊急タスクメニュー項目
  ///
  /// In ja, this message translates to:
  /// **'緊急タスク'**
  String get urgentTasks;

  /// 今日のタスクメニュー項目
  ///
  /// In ja, this message translates to:
  /// **'今日のタスク'**
  String get todayTasks;

  /// 総タスクラベル
  ///
  /// In ja, this message translates to:
  /// **'総'**
  String get total;

  /// 総タスクラベル（完全版）
  ///
  /// In ja, this message translates to:
  /// **'総タスク'**
  String get totalTasks;

  /// 進行中ラベル（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'I'**
  String get inProgressShort;

  /// 完了ラベル（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'C'**
  String get completedShort;

  /// 未着手ラベル（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'N'**
  String get notStartedShort;

  /// 進行中ラベル（短縮版2）
  ///
  /// In ja, this message translates to:
  /// **'I'**
  String get inProgressShort2;

  /// Description text (deprecated, use description)
  ///
  /// In ja, this message translates to:
  /// **'説明文'**
  String get descriptionText;

  /// Requester label
  ///
  /// In ja, this message translates to:
  /// **'依頼者'**
  String get requester;

  /// Normal search mode (deprecated, use normalSearchOption)
  ///
  /// In ja, this message translates to:
  /// **'通常検索モード'**
  String get normalSearchMode;

  /// 通常検索モードラベル
  ///
  /// In ja, this message translates to:
  /// **'通常検索モード'**
  String get normalSearchOption;

  /// 正規表現検索モードラベル
  ///
  /// In ja, this message translates to:
  /// **'正規表現検索モード'**
  String get regexSearchMode;

  /// 予定タイトルラベル
  ///
  /// In ja, this message translates to:
  /// **'予定タイトル'**
  String get scheduleTitle;

  /// 開始日時ラベル
  ///
  /// In ja, this message translates to:
  /// **'開始日時'**
  String get startDateTime;

  /// 終了日時ラベル
  ///
  /// In ja, this message translates to:
  /// **'終了日時'**
  String get endDateTime;

  /// Location label
  ///
  /// In ja, this message translates to:
  /// **'場所'**
  String get location;

  /// 日時選択プレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'日時を選択'**
  String get selectDateTime;

  /// 日時選択プレースホルダー（任意）
  ///
  /// In ja, this message translates to:
  /// **'日時を選択（任意）'**
  String get selectDateTimeOptional;

  /// 予定追加ボタン
  ///
  /// In ja, this message translates to:
  /// **'予定を追加'**
  String get addSchedule;

  /// 予定更新ボタン
  ///
  /// In ja, this message translates to:
  /// **'予定を更新'**
  String get updateSchedule;

  /// 予定追加完了メッセージ
  ///
  /// In ja, this message translates to:
  /// **'予定を追加しました'**
  String get scheduleAdded;

  /// 開始日時必須エラーメッセージ
  ///
  /// In ja, this message translates to:
  /// **'開始日時は必須です'**
  String get startDateTimeRequired;

  /// Outlookデスクトップラベル
  ///
  /// In ja, this message translates to:
  /// **'Outlook（デスクトップ）'**
  String get outlookDesktop;

  /// Gmail Webラベル
  ///
  /// In ja, this message translates to:
  /// **'Gmail（Web）'**
  String get gmailWeb;

  /// Outlookテストボタン
  ///
  /// In ja, this message translates to:
  /// **'Outlookをテスト'**
  String get outlookTest;

  /// Gmailテストボタン
  ///
  /// In ja, this message translates to:
  /// **'Gmailをテスト'**
  String get gmailTest;

  /// 送信履歴ボタン
  ///
  /// In ja, this message translates to:
  /// **'送信履歴'**
  String get sendHistory;

  /// メーラー起動ボタン
  ///
  /// In ja, this message translates to:
  /// **'メーラーを起動'**
  String get launchMailer;

  /// メール送信完了ボタン
  ///
  /// In ja, this message translates to:
  /// **'メール送信完了'**
  String get mailSentComplete;

  /// メーラー起動必須メッセージ
  ///
  /// In ja, this message translates to:
  /// **'まずメーラーを起動してください'**
  String get launchMailerFirst;

  /// タスクコピーダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'タスクをコピー'**
  String get copyTask;

  /// タスクコピー確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'「{title}」をコピーしますか？'**
  String copyTaskConfirm(String title);

  /// 繰り返し期間ラベル
  ///
  /// In ja, this message translates to:
  /// **'繰り返し期間:'**
  String get repeatPeriod;

  /// 月次オプション
  ///
  /// In ja, this message translates to:
  /// **'月次（1か月後）'**
  String get monthly;

  /// 四半期オプション
  ///
  /// In ja, this message translates to:
  /// **'四半期（3か月後）'**
  String get quarterly;

  /// 年次オプション
  ///
  /// In ja, this message translates to:
  /// **'年次（1年後）'**
  String get yearly;

  /// カスタムオプション
  ///
  /// In ja, this message translates to:
  /// **'カスタム'**
  String get custom;

  /// コピー個数ラベル
  ///
  /// In ja, this message translates to:
  /// **'コピー個数:'**
  String get copyCount;

  /// コピー個数表示
  ///
  /// In ja, this message translates to:
  /// **'{count}個'**
  String copyCountLabel(int count);

  /// 月次コピー最大数説明
  ///
  /// In ja, this message translates to:
  /// **'最大12個まで（1か月ずつ期限をずらしてコピー）'**
  String get maxCopiesMonthly;

  /// 四半期コピー最大数説明
  ///
  /// In ja, this message translates to:
  /// **'最大4個まで（3か月ずつ期限をずらしてコピー）'**
  String get maxCopiesQuarterly;

  /// リマインダー時間選択プレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'リマインダー時間を選択（任意）'**
  String get selectReminderTime;

  /// コピーされる内容ラベル
  ///
  /// In ja, this message translates to:
  /// **'コピーされる内容:'**
  String get copiedContent;

  /// タイトルラベル
  ///
  /// In ja, this message translates to:
  /// **'タイトル:'**
  String get titleLabel;

  /// コピーサフィックス
  ///
  /// In ja, this message translates to:
  /// **'コピー'**
  String get copySuffix;

  /// Description label with colon
  ///
  /// In ja, this message translates to:
  /// **'説明:'**
  String get descriptionLabel;

  /// 依頼先・メモラベル
  ///
  /// In ja, this message translates to:
  /// **'依頼先・メモ:'**
  String get requestorMemoLabel;

  /// コピー個数ラベル2
  ///
  /// In ja, this message translates to:
  /// **'コピー個数:'**
  String get copyCountLabel2;

  /// Due date label with colon
  ///
  /// In ja, this message translates to:
  /// **'期限:'**
  String get dueDateLabel;

  /// リマインダーラベル
  ///
  /// In ja, this message translates to:
  /// **'リマインダー:'**
  String get reminderLabel;

  /// 優先度ラベル
  ///
  /// In ja, this message translates to:
  /// **'優先度:'**
  String get priorityLabel;

  /// Status label with colon
  ///
  /// In ja, this message translates to:
  /// **'ステータス:'**
  String get statusLabel;

  /// タグラベル
  ///
  /// In ja, this message translates to:
  /// **'タグ:'**
  String get tagsLabel;

  /// 推定時間ラベル
  ///
  /// In ja, this message translates to:
  /// **'推定時間:'**
  String get estimatedTimeLabel;

  /// 分単位
  ///
  /// In ja, this message translates to:
  /// **'分'**
  String get minutes;

  /// サブタスクラベル
  ///
  /// In ja, this message translates to:
  /// **'サブタスク:'**
  String get subtasksLabel;

  /// ステータスリセット注意書き
  ///
  /// In ja, this message translates to:
  /// **'※ ステータスは「未着手」にリセットされます'**
  String get statusResetNote;

  /// サブタスクコピー注意書き
  ///
  /// In ja, this message translates to:
  /// **'※ サブタスクもコピーされます'**
  String get subtasksCopiedNote;

  /// タスクコピー成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'タスクを{count}個コピーしました'**
  String taskCopiedSuccess(int count);

  /// タスクコピー部分成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'タスクを{success}個コピーしました（{failed}個失敗）'**
  String taskCopiedPartial(int success, int failed);

  /// タスクコピー失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'タスクのコピーに失敗しました'**
  String get taskCopyFailed;

  /// タスク削除ダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'タスクを削除'**
  String get deleteTask;

  /// タスク削除確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'「{title}」を削除しますか？'**
  String deleteTaskConfirm(String title);

  /// 削除オプションラベル
  ///
  /// In ja, this message translates to:
  /// **'削除オプション:'**
  String get deleteOptions;

  /// アプリのみ削除オプション
  ///
  /// In ja, this message translates to:
  /// **'アプリのみ削除'**
  String get deleteAppOnly;

  /// アプリとGoogle Calendarから削除オプション
  ///
  /// In ja, this message translates to:
  /// **'アプリとGoogle Calendarから削除'**
  String get deleteAppAndCalendar;

  /// アプリのみボタン
  ///
  /// In ja, this message translates to:
  /// **'アプリのみ'**
  String get appOnly;

  /// 両方削除ボタン
  ///
  /// In ja, this message translates to:
  /// **'両方削除'**
  String get deleteBoth;

  /// タスク削除成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'「{title}」を削除しました'**
  String taskDeletedSuccess(String title);

  /// 削除失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'削除に失敗しました'**
  String get deleteFailed;

  /// タスク削除成功メッセージ（両方）
  ///
  /// In ja, this message translates to:
  /// **'「{title}」をアプリとGoogle Calendarから削除しました'**
  String taskDeletedFromBoth(String title);

  /// Confirm button
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get confirm;

  /// 選択タスク削除確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'選択した{count}件のタスクを削除しますか？'**
  String deleteSelectedTasks(int count);

  /// バックアップ実行メッセージ
  ///
  /// In ja, this message translates to:
  /// **'バックアップを実行しました。{count}件のタスクを削除します...'**
  String backupExecuted(int count);

  /// Backup failed but continue merge message
  ///
  /// In ja, this message translates to:
  /// **'バックアップに失敗しましたが、結合を続行します: {error}'**
  String backupFailedContinue(String error);

  /// Delete schedule dialog title
  ///
  /// In ja, this message translates to:
  /// **'予定を削除'**
  String get deleteSchedule;

  /// Delete schedule confirmation message
  ///
  /// In ja, this message translates to:
  /// **'「{title}」を削除しますか？'**
  String deleteScheduleConfirm(String title);

  /// 警告ラベル
  ///
  /// In ja, this message translates to:
  /// **'警告'**
  String get warning;

  /// 2つ以上のタスク選択要求メッセージ
  ///
  /// In ja, this message translates to:
  /// **'2つ以上のタスクを選択してください'**
  String get selectAtLeastTwoTasks;

  /// 結合元タスクなしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'結合元のタスクがありません'**
  String get noSourceTasks;

  /// タスク結合前バックアップメッセージ
  ///
  /// In ja, this message translates to:
  /// **'バックアップを実行しました。タスク結合を実行します...'**
  String get backupExecutedMerge;

  /// タスク結合失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'タスク結合に失敗しました'**
  String get taskMergeFailed;

  /// リンク割り当て失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'リンク割り当てに失敗しました'**
  String get linkAssignmentFailed;

  /// ステータス変更失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ステータス変更に失敗しました'**
  String get statusChangeFailed;

  /// 優先度変更失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'優先度変更に失敗しました'**
  String get priorityChangeFailed;

  /// 期限日変更失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'期限日変更に失敗しました'**
  String get dueDateChangeFailed;

  /// タグ変更失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'タグ変更に失敗しました'**
  String get tagChangeFailed;

  /// タスク同期成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'「{title}」をGoogle Calendarに同期しました'**
  String taskSyncedToCalendar(String title);

  /// タスク同期失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'「{title}」の同期に失敗しました: {error}'**
  String taskSyncFailed(String title, String error);

  /// タスク同期エラーメッセージ
  ///
  /// In ja, this message translates to:
  /// **'「{title}」の同期中にエラーが発生しました: {error}'**
  String taskSyncError(String title, String error);

  /// エクスポート失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'エクスポートに失敗しました'**
  String get exportFailed;

  /// 無効なファイル形式メッセージ
  ///
  /// In ja, this message translates to:
  /// **'無効なファイル形式です'**
  String get invalidFileFormat;

  /// インポート失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'インポートに失敗しました'**
  String get importFailed;

  /// 送信済み検索エラーメッセージ
  ///
  /// In ja, this message translates to:
  /// **'送信済み検索エラー'**
  String get sendHistorySearchError;

  /// メーラー起動成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'メーラーを起動しました'**
  String get mailerLaunched;

  /// 返信先メールアドレス未検出メッセージ
  ///
  /// In ja, this message translates to:
  /// **'返信先メールアドレスが見つかりません'**
  String get replyAddressNotFound;

  /// メーラー起動失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'メーラーの起動に失敗しました'**
  String get mailerLaunchFailed;

  /// Link open failed message
  ///
  /// In ja, this message translates to:
  /// **'リンクを開けませんでした: {href}'**
  String linkOpenFailed(String href);

  /// UNCパスオープン失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'UNCパスを開けませんでした: {path}'**
  String uncPathOpenFailed(String path);

  /// URLオープン失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'URLを開けませんでした: {url}'**
  String urlOpenFailed(String url);

  /// ファイルオープン失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ファイルを開けませんでした: {path}'**
  String fileOpenFailed(String path);

  /// Contact add error message
  ///
  /// In ja, this message translates to:
  /// **'連絡先追加エラー: {error}'**
  String contactAddError(String error);

  /// Links added to tasks message
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクにリンクを追加しました'**
  String linksAddedToTasks(int count);

  /// Links removed from tasks message
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクからリンクを削除しました'**
  String linksRemovedFromTasks(int count);

  /// Links replaced in tasks message
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクのリンクを置き換えました'**
  String linksReplacedInTasks(int count);

  /// Links changed in tasks message
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクのリンクを変更しました'**
  String linksChangedInTasks(int count);

  /// Tags added to tasks message
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクにタグを追加しました'**
  String tagsAddedToTasks(int count);

  /// Tags removed from tasks message
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクからタグを削除しました'**
  String tagsRemovedFromTasks(int count);

  /// Tags replaced in tasks message
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクのタグを置き換えました'**
  String tagsReplacedInTasks(int count);

  /// Tags changed in tasks message
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクのタグを変更しました'**
  String tagsChangedInTasks(int count);

  /// Syncing task message
  ///
  /// In ja, this message translates to:
  /// **'「{title}」を同期中...'**
  String syncingTask(String title);

  /// From today one week button
  ///
  /// In ja, this message translates to:
  /// **'今日から1週間'**
  String get fromTodayOneWeek;

  /// From today two weeks button
  ///
  /// In ja, this message translates to:
  /// **'今日から2週間'**
  String get fromTodayTwoWeeks;

  /// From today one month button
  ///
  /// In ja, this message translates to:
  /// **'今日から1ヶ月'**
  String get fromTodayOneMonth;

  /// From today three months button
  ///
  /// In ja, this message translates to:
  /// **'今日から3ヶ月'**
  String get fromTodayThreeMonths;

  /// Tags comma separated label
  ///
  /// In ja, this message translates to:
  /// **'タグ（カンマ区切り）'**
  String get tagsCommaSeparated;

  /// Tags example hint
  ///
  /// In ja, this message translates to:
  /// **'例: 緊急,重要,プロジェクトA'**
  String get tagsExample;

  /// Tomorrow group name
  ///
  /// In ja, this message translates to:
  /// **'明日'**
  String get tomorrow;

  /// This week group name
  ///
  /// In ja, this message translates to:
  /// **'今週'**
  String get thisWeek;

  /// Next week group name
  ///
  /// In ja, this message translates to:
  /// **'来週'**
  String get nextWeek;

  /// This month group name
  ///
  /// In ja, this message translates to:
  /// **'今月'**
  String get thisMonth;

  /// Later group name
  ///
  /// In ja, this message translates to:
  /// **'来月以降'**
  String get later;

  /// Overdue group name
  ///
  /// In ja, this message translates to:
  /// **'期限切れ'**
  String get overdue;

  /// No due date group name
  ///
  /// In ja, this message translates to:
  /// **'期限未設定'**
  String get noDueDate;

  /// カラープリセットラベル
  ///
  /// In ja, this message translates to:
  /// **'カラープリセット'**
  String get colorPresets;

  /// おすすめ配色適用説明
  ///
  /// In ja, this message translates to:
  /// **'ワンタップでおすすめ配色を適用'**
  String get applyRecommendedColors;

  /// アクセントカラーラベル
  ///
  /// In ja, this message translates to:
  /// **'アクセントカラー'**
  String get accentColor;

  /// 色の濃淡ラベル
  ///
  /// In ja, this message translates to:
  /// **'色の濃淡'**
  String get colorIntensity;

  /// コントラスト調整ラベル
  ///
  /// In ja, this message translates to:
  /// **'コントラスト調整'**
  String get contrastAdjustment;

  /// テキスト色設定ラベル
  ///
  /// In ja, this message translates to:
  /// **'テキスト色設定'**
  String get textColorSettings;

  /// カードビューフィールド設定説明
  ///
  /// In ja, this message translates to:
  /// **'カードビューで表示される各フィールドのテキスト色、フォントサイズ、フォントファミリーを個別に設定できます'**
  String get cardViewFieldSettingsDescription;

  /// リアルタイムプレビューラベル
  ///
  /// In ja, this message translates to:
  /// **'リアルタイムプレビュー'**
  String get realtimePreview;

  /// ライブラベル
  ///
  /// In ja, this message translates to:
  /// **'ライブ'**
  String get live;

  /// カード設定説明
  ///
  /// In ja, this message translates to:
  /// **'カードの見た目と動作を調整します。角丸半径、影の強さ、パディングを変更できます。'**
  String get cardSettingsDescription;

  /// 角丸半径ラベル
  ///
  /// In ja, this message translates to:
  /// **'角丸半径'**
  String get cornerRadius;

  /// 影の強さラベル
  ///
  /// In ja, this message translates to:
  /// **'影の強さ'**
  String get shadowStrength;

  /// パディングラベル
  ///
  /// In ja, this message translates to:
  /// **'パディング'**
  String get padding;

  /// サンプルカードラベル
  ///
  /// In ja, this message translates to:
  /// **'サンプルカード'**
  String get sampleCard;

  /// カードプレビュー説明
  ///
  /// In ja, this message translates to:
  /// **'これはカードのプレビューです。設定を変更するとリアルタイムで反映されます。'**
  String get cardPreviewDescription;

  /// サンプルボタンラベル
  ///
  /// In ja, this message translates to:
  /// **'サンプルボタン'**
  String get sampleButton;

  /// アウトラインボタンラベル
  ///
  /// In ja, this message translates to:
  /// **'アウトラインボタン'**
  String get outlineButton;

  /// サンプル入力フィールドラベル
  ///
  /// In ja, this message translates to:
  /// **'サンプル入力フィールド'**
  String get sampleInputField;

  /// 現在の設定表示
  ///
  /// In ja, this message translates to:
  /// **'角丸: {radius}px | 影: {shadow}% | パディング: {padding}px'**
  String currentSettings(String radius, String shadow, String padding);

  /// Button settings title
  ///
  /// In ja, this message translates to:
  /// **'ボタン設定'**
  String get buttonSettings;

  /// カードビュー短縮表記
  ///
  /// In ja, this message translates to:
  /// **'C'**
  String get cardViewShort;

  /// リストビュー短縮表記
  ///
  /// In ja, this message translates to:
  /// **'L'**
  String get listViewShort;

  /// タスクリスト表示設定ラベル
  ///
  /// In ja, this message translates to:
  /// **'タスクリスト表示設定'**
  String get taskListDisplaySettings;

  /// タスクリストフィールド設定説明
  ///
  /// In ja, this message translates to:
  /// **'タスクリストとタスク編集画面で表示される各フィールドのテキスト色、フォントサイズ、フォントファミリーを個別に設定できます'**
  String get taskListFieldSettingsDescription;

  /// カードビュー設定リセットラベル
  ///
  /// In ja, this message translates to:
  /// **'カードビュー設定をリセット'**
  String get resetCardViewSettings;

  /// カードビュー設定リセット確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'カードビューの設定を初期値にリセットしますか？\nこの操作は取り消せません。'**
  String get resetCardViewSettingsConfirm;

  /// テキスト色ラベル
  ///
  /// In ja, this message translates to:
  /// **'テキスト色'**
  String get textColor;

  /// Requestor description (deprecated, use assigneeDescription)
  ///
  /// In ja, this message translates to:
  /// **'依頼先への説明'**
  String get requestorDescription;

  /// 依頼先への説明ラベル
  ///
  /// In ja, this message translates to:
  /// **'担当者への説明'**
  String get assigneeDescription;

  /// 全画面共通ラベル
  ///
  /// In ja, this message translates to:
  /// **'全画面共通'**
  String get allScreensCommon;

  /// アプリ全体のフォントサイズラベル
  ///
  /// In ja, this message translates to:
  /// **'アプリ全体のフォントサイズ: {percentage}%'**
  String appWideFontSize(String percentage);

  /// Auto layout adjustment label
  ///
  /// In ja, this message translates to:
  /// **'自動レイアウト調整'**
  String get autoLayoutAdjustment;

  /// 画面サイズに応じて自動調整説明
  ///
  /// In ja, this message translates to:
  /// **'画面サイズに応じて自動調整'**
  String get autoAdjustToScreenSize;

  /// フィールド設定ラベル
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}設定'**
  String fieldSettings(String fieldName);

  /// カラープリセット名：サンライズ
  ///
  /// In ja, this message translates to:
  /// **'サンライズ'**
  String get colorPresetSunrise;

  /// カラープリセット説明：サンライズ
  ///
  /// In ja, this message translates to:
  /// **'温かみのあるオレンジ系'**
  String get colorPresetSunriseDesc;

  /// カラープリセット名：フォレスト
  ///
  /// In ja, this message translates to:
  /// **'フォレスト'**
  String get colorPresetForest;

  /// カラープリセット説明：フォレスト
  ///
  /// In ja, this message translates to:
  /// **'落ち着いたグリーン系'**
  String get colorPresetForestDesc;

  /// カラープリセット名：ブルーブリーズ
  ///
  /// In ja, this message translates to:
  /// **'ブルーブリーズ'**
  String get colorPresetBreeze;

  /// カラープリセット説明：ブルーブリーズ
  ///
  /// In ja, this message translates to:
  /// **'爽やかなブルー系'**
  String get colorPresetBreezeDesc;

  /// カラープリセット名：ミッドナイト
  ///
  /// In ja, this message translates to:
  /// **'ミッドナイト'**
  String get colorPresetMidnight;

  /// カラープリセット説明：ミッドナイト
  ///
  /// In ja, this message translates to:
  /// **'夜間作業に合うダークテイスト'**
  String get colorPresetMidnightDesc;

  /// カラープリセット名：サクラ
  ///
  /// In ja, this message translates to:
  /// **'サクラ'**
  String get colorPresetSakura;

  /// カラープリセット説明：サクラ
  ///
  /// In ja, this message translates to:
  /// **'柔らかなピンク系'**
  String get colorPresetSakuraDesc;

  /// カラープリセット名：シトラス
  ///
  /// In ja, this message translates to:
  /// **'シトラス'**
  String get colorPresetCitrus;

  /// カラープリセット説明：シトラス
  ///
  /// In ja, this message translates to:
  /// **'フレッシュな黄緑系'**
  String get colorPresetCitrusDesc;

  /// カラープリセット名：スレート
  ///
  /// In ja, this message translates to:
  /// **'スレート'**
  String get colorPresetSlate;

  /// カラープリセット説明：スレート
  ///
  /// In ja, this message translates to:
  /// **'落ち着いたブルーグレー'**
  String get colorPresetSlateDesc;

  /// カラープリセット名：アンバー
  ///
  /// In ja, this message translates to:
  /// **'アンバー'**
  String get colorPresetAmber;

  /// カラープリセット説明：アンバー
  ///
  /// In ja, this message translates to:
  /// **'視認性の高いゴールド調'**
  String get colorPresetAmberDesc;

  /// カラープリセット名：グラファイト
  ///
  /// In ja, this message translates to:
  /// **'グラファイト'**
  String get colorPresetGraphite;

  /// カラープリセット説明：グラファイト
  ///
  /// In ja, this message translates to:
  /// **'モダンなモノトーン'**
  String get colorPresetGraphiteDesc;

  /// プリセット適用成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'{presetName}プリセットを適用しました'**
  String presetApplied(String presetName);

  /// プリセット適用失敗メッセージ
  ///
  /// In ja, this message translates to:
  /// **'プリセットの適用に失敗しました: {error}'**
  String presetApplyFailed(String error);

  /// 自動コントラスト最適化ラベル
  ///
  /// In ja, this message translates to:
  /// **'自動コントラスト最適化'**
  String get autoContrastOptimization;

  /// 自動コントラスト最適化説明
  ///
  /// In ja, this message translates to:
  /// **'ダークモードでテキストの視認性を自動調整'**
  String get autoContrastOptimizationDesc;

  /// アイコンサイズラベル
  ///
  /// In ja, this message translates to:
  /// **'アイコンサイズ'**
  String get iconSize;

  /// リンクアイテムアイコンサイズ説明
  ///
  /// In ja, this message translates to:
  /// **'リンクアイテムのアイコンサイズを調整します。大きくすると視認性が向上しますが、アイテム全体のサイズも大きくなります。'**
  String get linkItemIconSizeDesc;

  /// グリッド設定リセットラベル
  ///
  /// In ja, this message translates to:
  /// **'グリッド設定'**
  String get gridSettingsReset;

  /// グリッド設定リセット説明
  ///
  /// In ja, this message translates to:
  /// **'カラム数: 4、間隔: デフォルト'**
  String get gridSettingsResetDesc;

  /// カード設定リセットラベル
  ///
  /// In ja, this message translates to:
  /// **'カード設定'**
  String get cardSettingsReset;

  /// カード設定リセット説明
  ///
  /// In ja, this message translates to:
  /// **'サイズ: デフォルト、影: デフォルト'**
  String get cardSettingsResetDesc;

  /// アイテム設定リセットラベル
  ///
  /// In ja, this message translates to:
  /// **'アイテム設定'**
  String get itemSettingsReset;

  /// アイテム設定リセット説明
  ///
  /// In ja, this message translates to:
  /// **'フォントサイズ: デフォルト、アイコンサイズ: デフォルト'**
  String get itemSettingsResetDesc;

  /// 青色の名称
  ///
  /// In ja, this message translates to:
  /// **'ブルー'**
  String get colorBlue;

  /// 赤色の名称
  ///
  /// In ja, this message translates to:
  /// **'レッド'**
  String get colorRed;

  /// 緑色の名称
  ///
  /// In ja, this message translates to:
  /// **'グリーン'**
  String get colorGreen;

  /// オレンジ色の名称
  ///
  /// In ja, this message translates to:
  /// **'オレンジ'**
  String get colorOrange;

  /// 紫色の名称
  ///
  /// In ja, this message translates to:
  /// **'パープル'**
  String get colorPurple;

  /// ピンク色の名称
  ///
  /// In ja, this message translates to:
  /// **'ピンク'**
  String get colorPink;

  /// シアン色の名称
  ///
  /// In ja, this message translates to:
  /// **'シアン'**
  String get colorCyan;

  /// グレー色の名称
  ///
  /// In ja, this message translates to:
  /// **'グレー'**
  String get colorGray;

  /// エメラルド色の名称
  ///
  /// In ja, this message translates to:
  /// **'エメラルド'**
  String get colorEmerald;

  /// 黄色の名称
  ///
  /// In ja, this message translates to:
  /// **'イエロー'**
  String get colorYellow;

  /// 黒色の名称
  ///
  /// In ja, this message translates to:
  /// **'黒'**
  String get colorBlack;

  /// 白色の名称
  ///
  /// In ja, this message translates to:
  /// **'白'**
  String get colorWhite;

  /// 薄い（色の濃淡）
  ///
  /// In ja, this message translates to:
  /// **'薄い'**
  String get light;

  /// 標準
  ///
  /// In ja, this message translates to:
  /// **'標準'**
  String get standard;

  /// 濃い（色の濃淡）
  ///
  /// In ja, this message translates to:
  /// **'濃い'**
  String get dark;

  /// 低（コントラスト）
  ///
  /// In ja, this message translates to:
  /// **'低'**
  String get contrastLow;

  /// 高（コントラスト）
  ///
  /// In ja, this message translates to:
  /// **'高'**
  String get contrastHigh;

  /// コントラストラベル
  ///
  /// In ja, this message translates to:
  /// **'コントラスト'**
  String get contrast;

  /// フォントサイズラベル
  ///
  /// In ja, this message translates to:
  /// **'フォントサイズ'**
  String get fontSize;

  /// フォントファミリーラベル
  ///
  /// In ja, this message translates to:
  /// **'フォントファミリー'**
  String get fontFamily;

  /// デフォルト
  ///
  /// In ja, this message translates to:
  /// **'デフォルト'**
  String get defaultValue;

  /// フォントサイズプレビューテキスト
  ///
  /// In ja, this message translates to:
  /// **'プレビュー: このテキストのサイズが{fieldName}に適用されます'**
  String fontSizePreview(String fieldName);

  /// フォントファミリープレビューテキスト
  ///
  /// In ja, this message translates to:
  /// **'フォントプレビュー: このテキストのフォントが{fieldName}に適用されます'**
  String fontFamilyPreview(String fieldName);

  /// Button settings description
  ///
  /// In ja, this message translates to:
  /// **'ボタンの見た目を調整します。角丸半径と影の強さを変更できます。'**
  String get buttonSettingsDescription;

  /// Border radius label
  ///
  /// In ja, this message translates to:
  /// **'角丸半径'**
  String get borderRadius;

  /// Border radius with value
  ///
  /// In ja, this message translates to:
  /// **'角丸半径: {value}px'**
  String borderRadiusPx(String value);

  /// Elevation/shadow intensity label
  ///
  /// In ja, this message translates to:
  /// **'影の強さ'**
  String get elevation;

  /// Elevation with value
  ///
  /// In ja, this message translates to:
  /// **'影の強さ: {value}px'**
  String elevationPx(String value);

  /// Elevation with percentage
  ///
  /// In ja, this message translates to:
  /// **'影の強さ: {value}%'**
  String elevationPercent(String value);

  /// Input field settings title
  ///
  /// In ja, this message translates to:
  /// **'入力フィールド設定'**
  String get inputFieldSettings;

  /// Input field settings description
  ///
  /// In ja, this message translates to:
  /// **'テキスト入力欄の見た目を調整します。角丸半径と枠線の太さを変更できます。'**
  String get inputFieldSettingsDescription;

  /// Border width label
  ///
  /// In ja, this message translates to:
  /// **'枠線の太さ'**
  String get borderWidth;

  /// Border width with value
  ///
  /// In ja, this message translates to:
  /// **'枠線の太さ: {value}px'**
  String borderWidthPx(String value);

  /// Hover effect label
  ///
  /// In ja, this message translates to:
  /// **'ホバー効果'**
  String get hoverEffect;

  /// Hover effect with percentage
  ///
  /// In ja, this message translates to:
  /// **'ホバー効果: {value}%'**
  String hoverEffectPercent(String value);

  /// Gradient label
  ///
  /// In ja, this message translates to:
  /// **'グラデーション'**
  String get gradient;

  /// Gradient with percentage
  ///
  /// In ja, this message translates to:
  /// **'グラデーション: {value}%'**
  String gradientPercent(String value);

  /// General settings title
  ///
  /// In ja, this message translates to:
  /// **'全般設定'**
  String get generalSettings;

  /// Dark mode contrast boost label
  ///
  /// In ja, this message translates to:
  /// **'ダークモードコントラストブースト'**
  String get darkModeContrastBoost;

  /// Auto layout enabled message
  ///
  /// In ja, this message translates to:
  /// **'自動レイアウトが有効です。画面サイズに応じて最適な列数が自動で決定されます。'**
  String get autoLayoutEnabled;

  /// Large screen label
  ///
  /// In ja, this message translates to:
  /// **'大画面（1920px以上）'**
  String get largeScreen;

  /// Columns display
  ///
  /// In ja, this message translates to:
  /// **'{count}列表示'**
  String columnsDisplay(String count);

  /// Optimal for desktop message
  ///
  /// In ja, this message translates to:
  /// **'デスクトップモニターに最適'**
  String get optimalForDesktop;

  /// Medium screen label
  ///
  /// In ja, this message translates to:
  /// **'中画面（1200-1919px）'**
  String get mediumScreen;

  /// Optimal for laptop message
  ///
  /// In ja, this message translates to:
  /// **'ノートPCやタブレットに最適'**
  String get optimalForLaptop;

  /// Small screen label
  ///
  /// In ja, this message translates to:
  /// **'小画面（800-1199px）'**
  String get smallScreen;

  /// Optimal for small screen message
  ///
  /// In ja, this message translates to:
  /// **'小さな画面に最適'**
  String get optimalForSmallScreen;

  /// Minimal screen label
  ///
  /// In ja, this message translates to:
  /// **'最小画面（800px未満）'**
  String get minimalScreen;

  /// Optimal for mobile message
  ///
  /// In ja, this message translates to:
  /// **'モバイル表示に最適'**
  String get optimalForMobile;

  /// Manual layout enabled message
  ///
  /// In ja, this message translates to:
  /// **'手動レイアウト設定が有効です。固定の列数で表示されます。'**
  String get manualLayoutEnabled;

  /// Fixed columns label
  ///
  /// In ja, this message translates to:
  /// **'固定列数'**
  String get fixedColumns;

  /// Same columns for all screens message
  ///
  /// In ja, this message translates to:
  /// **'すべての画面サイズで同じ列数'**
  String get sameColumnsAllScreens;

  /// Use case label
  ///
  /// In ja, this message translates to:
  /// **'使用場面'**
  String get useCase;

  /// Maintain specific display message
  ///
  /// In ja, this message translates to:
  /// **'特定の表示を維持したい場合'**
  String get maintainSpecificDisplay;

  /// Consistent layout needed message
  ///
  /// In ja, this message translates to:
  /// **'一貫したレイアウトが必要な場合'**
  String get consistentLayoutNeeded;

  /// Default column count
  ///
  /// In ja, this message translates to:
  /// **'デフォルト列数: {count}'**
  String defaultColumnCount(String count);

  /// Grid spacing
  ///
  /// In ja, this message translates to:
  /// **'グリッド間隔: {value}px'**
  String gridSpacing(String value);

  /// Card width
  ///
  /// In ja, this message translates to:
  /// **'カード幅: {value}px'**
  String cardWidth(String value);

  /// Card height
  ///
  /// In ja, this message translates to:
  /// **'カード高さ: {value}px'**
  String cardHeight(String value);

  /// Item margin label
  ///
  /// In ja, this message translates to:
  /// **'アイテム間マージン'**
  String get itemMargin;

  /// Item margin with value
  ///
  /// In ja, this message translates to:
  /// **'アイテム間マージン: {value}px'**
  String itemMarginPx(String value);

  /// Item margin description
  ///
  /// In ja, this message translates to:
  /// **'リンクアイテム間の空白スペースを調整します。値を大きくすると、アイテム同士の間隔が広がり、見やすくなります。'**
  String get itemMarginDescription;

  /// Item padding label
  ///
  /// In ja, this message translates to:
  /// **'アイテム内パディング'**
  String get itemPadding;

  /// Item padding with value
  ///
  /// In ja, this message translates to:
  /// **'アイテム内パディング: {value}px'**
  String itemPaddingPx(String value);

  /// Item padding description
  ///
  /// In ja, this message translates to:
  /// **'リンクアイテム内の文字やアイコンと枠線の間の空白を調整します。値を大きくすると、アイテム内がゆとりを持って見やすくなります。'**
  String get itemPaddingDescription;

  /// Font size with value
  ///
  /// In ja, this message translates to:
  /// **'フォントサイズ: {value}px'**
  String fontSizePx(String value);

  /// Font size description
  ///
  /// In ja, this message translates to:
  /// **'リンクアイテムの文字サイズを調整します。小さくすると多くのアイテムを表示できますが、読みにくくなる場合があります。'**
  String get fontSizeDescription;

  /// Button size label
  ///
  /// In ja, this message translates to:
  /// **'ボタンサイズ'**
  String get buttonSize;

  /// Button size with value
  ///
  /// In ja, this message translates to:
  /// **'ボタンサイズ: {value}px'**
  String buttonSizePx(String value);

  /// Button size description
  ///
  /// In ja, this message translates to:
  /// **'編集・削除などのボタンのサイズを調整します。大きくすると操作しやすくなりますが、画面のスペースを多く使用します。'**
  String get buttonSizeDescription;

  /// Auto adjust card height label
  ///
  /// In ja, this message translates to:
  /// **'カード高さ自動調整'**
  String get autoAdjustCardHeight;

  /// Auto adjust card height description
  ///
  /// In ja, this message translates to:
  /// **'コンテンツ量に応じてカードの高さを自動調整（手動設定の高さを最小値として使用）'**
  String get autoAdjustCardHeightDescription;

  /// Backup and export section title
  ///
  /// In ja, this message translates to:
  /// **'データのバックアップ / エクスポート'**
  String get backupExport;

  /// Backup location message
  ///
  /// In ja, this message translates to:
  /// **'保存先: ドキュメント/backups'**
  String get backupLocation;

  /// Save now button label
  ///
  /// In ja, this message translates to:
  /// **'今すぐ保存'**
  String get saveNow;

  /// Open backup folder button label
  ///
  /// In ja, this message translates to:
  /// **'保存先を開く'**
  String get openBackupFolder;

  /// Selective export/import title
  ///
  /// In ja, this message translates to:
  /// **'選択式エクスポート / インポート'**
  String get selectiveExportImport;

  /// Selective export button label
  ///
  /// In ja, this message translates to:
  /// **'選択式エクスポート'**
  String get selectiveExport;

  /// Selective import button label
  ///
  /// In ja, this message translates to:
  /// **'選択式インポート'**
  String get selectiveImport;

  /// Auto backup label
  ///
  /// In ja, this message translates to:
  /// **'自動バックアップ'**
  String get autoBackup;

  /// Auto backup description
  ///
  /// In ja, this message translates to:
  /// **'定期的にデータをバックアップ'**
  String get autoBackupDescription;

  /// Backup interval
  ///
  /// In ja, this message translates to:
  /// **'バックアップ間隔: {days}日'**
  String backupInterval(String days);

  /// Backup interval in days
  ///
  /// In ja, this message translates to:
  /// **'{days}日'**
  String backupIntervalDays(String days);

  /// Notification warning message
  ///
  /// In ja, this message translates to:
  /// **'注意: 通知はアプリが起動中の場合のみ表示されます。アプリを閉じている場合は通知が表示されません。'**
  String get notificationWarning;

  /// Show notifications label
  ///
  /// In ja, this message translates to:
  /// **'通知を表示'**
  String get showNotifications;

  /// Show notifications description
  ///
  /// In ja, this message translates to:
  /// **'タスクの期限やリマインダーが設定されている場合、デスクトップ通知を表示します。アプリが起動中の場合のみ通知が表示されます。'**
  String get showNotificationsDescription;

  /// Notification sound label
  ///
  /// In ja, this message translates to:
  /// **'通知音'**
  String get notificationSound;

  /// Notification sound description
  ///
  /// In ja, this message translates to:
  /// **'通知が表示される際に音を再生します。アプリが起動中の場合のみ音が再生されます。'**
  String get notificationSoundDescription;

  /// Test notification sound button label
  ///
  /// In ja, this message translates to:
  /// **'通知音をテスト'**
  String get testNotificationSound;

  /// Test notification sound description
  ///
  /// In ja, this message translates to:
  /// **'このボタンで通知音をテストできます。アプリが起動中の場合のみ音が再生されます。'**
  String get testNotificationSoundDescription;

  /// Reset to defaults button label
  ///
  /// In ja, this message translates to:
  /// **'設定をデフォルトにリセット'**
  String get resetToDefaults;

  /// Reset layout settings button label
  ///
  /// In ja, this message translates to:
  /// **'レイアウト設定をリセット'**
  String get resetLayoutSettings;

  /// Layout settings reset success message
  ///
  /// In ja, this message translates to:
  /// **'レイアウト設定をリセットしました'**
  String get layoutSettingsReset;

  /// Reset UI settings button label
  ///
  /// In ja, this message translates to:
  /// **'UI設定をリセット'**
  String get resetUISettings;

  /// Reset UI settings confirmation message
  ///
  /// In ja, this message translates to:
  /// **'すべてのUIカスタマイズ設定をデフォルト値にリセットします。\n\nこの操作は取り消せません。\n本当に実行しますか？'**
  String get resetUISettingsConfirm;

  /// Execute reset button label
  ///
  /// In ja, this message translates to:
  /// **'リセット実行'**
  String get executeReset;

  /// Reset details button label
  ///
  /// In ja, this message translates to:
  /// **'リセット機能の詳細'**
  String get resetDetails;

  /// Reset function title
  ///
  /// In ja, this message translates to:
  /// **'リセット機能'**
  String get resetFunction;

  /// Reset function description
  ///
  /// In ja, this message translates to:
  /// **'• 設定リセット: テーマ、通知、連携設定など\n• レイアウトリセット: グリッドサイズ、カード設定など\n• UI設定リセット: カード、ボタン、入力フィールドのカスタマイズ設定\n• データは保持: リンク、タスク、メモは削除されません\n• 詳細は「リセット機能の詳細」ボタンで確認'**
  String get resetFunctionDescription;

  /// Reset details title
  ///
  /// In ja, this message translates to:
  /// **'リセット機能の詳細'**
  String get resetDetailsTitle;

  /// Reset details description
  ///
  /// In ja, this message translates to:
  /// **'リセット機能の詳細説明:'**
  String get resetDetailsDescription;

  /// Reset to defaults step title
  ///
  /// In ja, this message translates to:
  /// **'設定をデフォルトにリセット'**
  String get resetToDefaultsStep;

  /// Reset to defaults step description
  ///
  /// In ja, this message translates to:
  /// **'以下の設定が初期値に戻ります:'**
  String get resetToDefaultsStepDescription;

  /// Theme settings reset item
  ///
  /// In ja, this message translates to:
  /// **'テーマ設定'**
  String get themeSettingsReset;

  /// Theme settings reset value
  ///
  /// In ja, this message translates to:
  /// **'ダークモード: OFF、アクセントカラー: ブルー、濃淡: 100%、コントラスト: 100%'**
  String get themeSettingsResetValue;

  /// Notification settings reset item
  ///
  /// In ja, this message translates to:
  /// **'通知設定'**
  String get notificationSettingsReset;

  /// Notification settings reset value
  ///
  /// In ja, this message translates to:
  /// **'通知: ON、通知音: ON'**
  String get notificationSettingsResetValue;

  /// Integration settings reset item
  ///
  /// In ja, this message translates to:
  /// **'連携設定'**
  String get integrationSettingsReset;

  /// Integration settings reset value
  ///
  /// In ja, this message translates to:
  /// **'Google Calendar: OFF、Gmail連携: OFF、Outlook: OFF'**
  String get integrationSettingsResetValue;

  /// Backup settings reset item
  ///
  /// In ja, this message translates to:
  /// **'バックアップ設定'**
  String get backupSettingsReset;

  /// Backup settings reset value
  ///
  /// In ja, this message translates to:
  /// **'自動バックアップ: ON、間隔: 7日'**
  String get backupSettingsResetValue;

  /// Reset layout settings step title
  ///
  /// In ja, this message translates to:
  /// **'レイアウト設定をリセット'**
  String get resetLayoutSettingsStep;

  /// Reset layout settings step description
  ///
  /// In ja, this message translates to:
  /// **'以下のレイアウト設定が初期値に戻ります:'**
  String get resetLayoutSettingsStepDescription;

  /// Auto sync label
  ///
  /// In ja, this message translates to:
  /// **'自動同期'**
  String get autoSync;

  /// Auto sync description
  ///
  /// In ja, this message translates to:
  /// **'定期的にGoogle Calendarと同期します'**
  String get autoSyncDescription;

  /// Sync interval
  ///
  /// In ja, this message translates to:
  /// **'同期間隔: {minutes}分'**
  String syncInterval(String minutes);

  /// Bidirectional sync label
  ///
  /// In ja, this message translates to:
  /// **'双方向同期'**
  String get bidirectionalSync;

  /// Bidirectional sync description
  ///
  /// In ja, this message translates to:
  /// **'アプリのタスクをGoogle Calendarに送信します'**
  String get bidirectionalSyncDescription;

  /// Show completed tasks label
  ///
  /// In ja, this message translates to:
  /// **'完了タスクを表示'**
  String get showCompletedTasks;

  /// Show completed tasks description
  ///
  /// In ja, this message translates to:
  /// **'Google Calendarで完了したタスクを表示します'**
  String get showCompletedTasksDescription;

  /// Credentials file found message
  ///
  /// In ja, this message translates to:
  /// **'認証情報ファイルが見つかりました'**
  String get credentialsFileFound;

  /// Credentials file not found message
  ///
  /// In ja, this message translates to:
  /// **'認証情報ファイルが見つかりません'**
  String get credentialsFileNotFound;

  /// Outlook settings info title
  ///
  /// In ja, this message translates to:
  /// **'Outlook設定情報'**
  String get outlookSettingsInfo;

  /// Auto layout adjustment description
  ///
  /// In ja, this message translates to:
  /// **'画面サイズに応じて自動調整'**
  String get autoLayoutAdjustmentDescription;

  /// Auto layout enabled label
  ///
  /// In ja, this message translates to:
  /// **'自動レイアウト有効'**
  String get autoLayoutEnabledLabel;

  /// Manual layout settings label
  ///
  /// In ja, this message translates to:
  /// **'手動レイアウト設定'**
  String get manualLayoutSettings;

  /// Animation and effect settings title
  ///
  /// In ja, this message translates to:
  /// **'アニメーション・エフェクト設定'**
  String get animationEffectSettings;

  /// Animation duration
  ///
  /// In ja, this message translates to:
  /// **'アニメーション時間: {ms}ms'**
  String animationDuration(String ms);

  /// Spacing
  ///
  /// In ja, this message translates to:
  /// **'スペーシング: {value}px'**
  String spacing(String value);

  /// Dark mode contrast boost with percentage
  ///
  /// In ja, this message translates to:
  /// **'ダークモードコントラストブースト: {value}%'**
  String darkModeContrastBoostPercent(String value);

  /// Task project settings reset success message
  ///
  /// In ja, this message translates to:
  /// **'プロジェクト一覧設定をリセットしました'**
  String get taskProjectSettingsReset;

  /// Backup folder opened message
  ///
  /// In ja, this message translates to:
  /// **'バックアップフォルダを開きました'**
  String get backupFolderOpened;

  /// Google Calendar label
  ///
  /// In ja, this message translates to:
  /// **'Google Calendar'**
  String get googleCalendar;

  /// Google Calendar integration title
  ///
  /// In ja, this message translates to:
  /// **'Google Calendar連携'**
  String get googleCalendarIntegration;

  /// Google Calendar integration description
  ///
  /// In ja, this message translates to:
  /// **'Google Calendarのイベントをタスクとして同期します'**
  String get googleCalendarIntegrationDescription;

  /// Gmail integration about title
  ///
  /// In ja, this message translates to:
  /// **'Gmail連携について'**
  String get gmailIntegrationAbout;

  /// Gmail integration description
  ///
  /// In ja, this message translates to:
  /// **'タスク編集モーダルからGmailのメール作成画面を起動できます。\nAPIやアクセストークンの設定は不要です。\nGoogleアカウントにログイン済みのブラウザがあれば、そのままGmailの新規作成タブが開きます。'**
  String get gmailIntegrationDescription;

  /// Gmail usage instructions
  ///
  /// In ja, this message translates to:
  /// **'使い方：\n1. タスク編集モーダルを開く\n2. メール送信セクションでGmailを選択\n3. 宛先を入力して「メール送信」ボタンをクリック\n4. Gmailのメール作成画面が開くので、内容を確認して送信します\n（送信履歴はタスク側に記録されます）'**
  String get gmailUsage;

  /// Outlook integration title
  ///
  /// In ja, this message translates to:
  /// **'Outlook連携'**
  String get outlookIntegration;

  /// Outlook integration about title
  ///
  /// In ja, this message translates to:
  /// **'Outlook連携について'**
  String get outlookIntegrationAbout;

  /// Outlook integration description
  ///
  /// In ja, this message translates to:
  /// **'Outlook APIを使用して、メール送信機能を利用できます。'**
  String get outlookIntegrationDescription;

  /// PowerShell file details title
  ///
  /// In ja, this message translates to:
  /// **'PowerShellファイルの詳細'**
  String get powershellFileDetails;

  /// Executable directory path
  ///
  /// In ja, this message translates to:
  /// **'実行ファイルと同じディレクトリ\\Apps'**
  String get executableDirectory;

  /// Outlook connection test title
  ///
  /// In ja, this message translates to:
  /// **'Outlook接続テスト'**
  String get outlookConnectionTest;

  /// Outlook connection test description
  ///
  /// In ja, this message translates to:
  /// **'Outlookアプリケーションとの接続をテストします'**
  String get outlookConnectionTestDescription;

  /// Mail composition support title
  ///
  /// In ja, this message translates to:
  /// **'メール作成支援'**
  String get mailCompositionSupport;

  /// Mail composition support description
  ///
  /// In ja, this message translates to:
  /// **'タスクから返信メールを作成する際の支援機能'**
  String get mailCompositionSupportDescription;

  /// Sent mail search title
  ///
  /// In ja, this message translates to:
  /// **'送信メール検索'**
  String get sentMailSearch;

  /// Sent mail search description
  ///
  /// In ja, this message translates to:
  /// **'送信済みメールの検索・確認機能'**
  String get sentMailSearchDescription;

  /// Outlook calendar events title
  ///
  /// In ja, this message translates to:
  /// **'Outlookカレンダー予定取得'**
  String get outlookCalendarEvents;

  /// Outlook calendar events description
  ///
  /// In ja, this message translates to:
  /// **'Outlookカレンダーから予定を取得してタスクに割り当てる機能'**
  String get outlookCalendarEventsDescription;

  /// Portable version label
  ///
  /// In ja, this message translates to:
  /// **'ポータブル版'**
  String get portableVersion;

  /// Installed version label
  ///
  /// In ja, this message translates to:
  /// **'インストール版'**
  String get installedVersion;

  /// Manual execution label
  ///
  /// In ja, this message translates to:
  /// **'手動実行'**
  String get manualExecution;

  /// Automatic execution label
  ///
  /// In ja, this message translates to:
  /// **'自動実行'**
  String get automaticExecution;

  /// Important notes title
  ///
  /// In ja, this message translates to:
  /// **'重要な注意事項'**
  String get importantNotes;

  /// Important notes content
  ///
  /// In ja, this message translates to:
  /// **'• 管理者権限は不要（ユーザーレベルで実行可能）\n• ファイル名は正確に一致させる必要があります\n• 実行ポリシーが制限されている場合は手動で許可が必要です\n• 会社PCのセキュリティポリシーにより動作しない場合があります\n\n【配置場所】以下のいずれかに配置してください：\n1. ポータブル版: {portablePath}\n2. インストール版: {installedPath}'**
  String importantNotesContent(String portablePath, String installedPath);

  /// Connection test button label
  ///
  /// In ja, this message translates to:
  /// **'接続テスト'**
  String get connectionTest;

  /// Outlook personal calendar auto import title
  ///
  /// In ja, this message translates to:
  /// **'Outlook個人予定の自動取込'**
  String get outlookPersonalCalendarAutoImport;

  /// Outlook settings info content
  ///
  /// In ja, this message translates to:
  /// **'• 必要な権限: Outlook送信\n• 対応機能: メール送信、予定自動取込\n• 使用方法: タスク管理からOutlookでメールを送信、または自動取込設定を有効化'**
  String get outlookSettingsInfoContent;

  /// Google Calendar setup guide title
  ///
  /// In ja, this message translates to:
  /// **'Google Calendar設定ガイド'**
  String get googleCalendarSetupGuide;

  /// Google Calendar setup steps title
  ///
  /// In ja, this message translates to:
  /// **'Google Calendar APIを使用するための設定手順:'**
  String get googleCalendarSetupSteps;

  /// Access Google Cloud Console step
  ///
  /// In ja, this message translates to:
  /// **'Google Cloud Consoleにアクセス'**
  String get accessGoogleCloudConsole;

  /// Create or select project step
  ///
  /// In ja, this message translates to:
  /// **'新しいプロジェクトを作成または既存プロジェクトを選択'**
  String get createOrSelectProject;

  /// Enable Google Calendar API step
  ///
  /// In ja, this message translates to:
  /// **'Google Calendar APIを有効化'**
  String get enableGoogleCalendarAPI;

  /// Enable Google Calendar API description
  ///
  /// In ja, this message translates to:
  /// **'「APIとサービス」→「ライブラリ」→「Google Calendar API」を検索して有効化'**
  String get enableGoogleCalendarAPIDescription;

  /// Create OAuth2 client ID step
  ///
  /// In ja, this message translates to:
  /// **'OAuth2クライアントIDを作成'**
  String get createOAuth2ClientID;

  /// Create OAuth2 client ID description
  ///
  /// In ja, this message translates to:
  /// **'「APIとサービス」→「認証情報」→「認証情報を作成」→「OAuth2クライアントID」→「デスクトップアプリケーション」'**
  String get createOAuth2ClientIDDescription;

  /// Download credentials file step
  ///
  /// In ja, this message translates to:
  /// **'認証情報ファイルをダウンロード'**
  String get downloadCredentialsFile;

  /// Download credentials file description
  ///
  /// In ja, this message translates to:
  /// **'作成したOAuth2クライアントIDの「ダウンロード」ボタンからJSONファイルをダウンロード'**
  String get downloadCredentialsFileDescription;

  /// Place file in app folder step
  ///
  /// In ja, this message translates to:
  /// **'ファイルをアプリフォルダに配置'**
  String get placeFileInAppFolder;

  /// Place file in app folder description
  ///
  /// In ja, this message translates to:
  /// **'ダウンロードしたJSONファイルを「oauth2_credentials.json」としてアプリフォルダに配置'**
  String get placeFileInAppFolderDescription;

  /// Execute OAuth2 authentication step
  ///
  /// In ja, this message translates to:
  /// **'OAuth2認証を実行'**
  String get executeOAuth2Authentication;

  /// Execute OAuth2 authentication description
  ///
  /// In ja, this message translates to:
  /// **'アプリの「OAuth2認証を開始」ボタンをクリックして認証を完了'**
  String get executeOAuth2AuthenticationDescription;

  /// Generated files title
  ///
  /// In ja, this message translates to:
  /// **'生成されるファイル'**
  String get generatedFiles;

  /// Export options title
  ///
  /// In ja, this message translates to:
  /// **'エクスポートオプション'**
  String get exportOptions;

  /// Select data to export message
  ///
  /// In ja, this message translates to:
  /// **'エクスポートするデータを選択してください:'**
  String get selectDataToExport;

  /// Links only option
  ///
  /// In ja, this message translates to:
  /// **'リンクのみ'**
  String get linksOnly;

  /// Links only description
  ///
  /// In ja, this message translates to:
  /// **'リンクデータのみをエクスポート'**
  String get linksOnlyDescription;

  /// Tasks only option
  ///
  /// In ja, this message translates to:
  /// **'タスクのみ'**
  String get tasksOnly;

  /// Tasks only description
  ///
  /// In ja, this message translates to:
  /// **'タスクデータのみをエクスポート'**
  String get tasksOnlyDescription;

  /// Both option
  ///
  /// In ja, this message translates to:
  /// **'両方'**
  String get both;

  /// Both description
  ///
  /// In ja, this message translates to:
  /// **'リンクとタスクの両方をエクスポート'**
  String get bothDescription;

  /// Import options title
  ///
  /// In ja, this message translates to:
  /// **'インポートオプション'**
  String get importOptions;

  /// Select data to import message
  ///
  /// In ja, this message translates to:
  /// **'インポートするデータを選択してください:'**
  String get selectDataToImport;

  /// Links only import description
  ///
  /// In ja, this message translates to:
  /// **'リンクデータのみをインポート'**
  String get linksOnlyImportDescription;

  /// Tasks only import description
  ///
  /// In ja, this message translates to:
  /// **'タスクデータのみをインポート'**
  String get tasksOnlyImportDescription;

  /// Both import description
  ///
  /// In ja, this message translates to:
  /// **'リンクとタスクの両方をインポート'**
  String get bothImportDescription;

  /// Export completed message
  ///
  /// In ja, this message translates to:
  /// **'エクスポートが完了しました\n保存先: {filePath}'**
  String exportCompleted(String filePath);

  /// Export completed title
  ///
  /// In ja, this message translates to:
  /// **'エクスポート完了'**
  String get exportCompletedTitle;

  /// Export error title
  ///
  /// In ja, this message translates to:
  /// **'エクスポートエラー'**
  String get exportError;

  /// Export error message
  ///
  /// In ja, this message translates to:
  /// **'エクスポートエラー: {error}'**
  String exportErrorMessage(String error);

  /// Could not open folder message
  ///
  /// In ja, this message translates to:
  /// **'フォルダを開けませんでした: {error}'**
  String couldNotOpenFolder(String error);

  /// OK button
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get ok;

  /// Select file to import dialog title
  ///
  /// In ja, this message translates to:
  /// **'インポートするファイルを選択'**
  String get selectFileToImport;

  /// Import completed message
  ///
  /// In ja, this message translates to:
  /// **'インポートが完了しました\nリンク: {linksCount}件\nタスク: {tasksCount}件\nグループ: {groupsCount}件'**
  String importCompleted(int linksCount, int tasksCount, int groupsCount);

  /// Import completed title
  ///
  /// In ja, this message translates to:
  /// **'インポート完了'**
  String get importCompletedTitle;

  /// Import error title
  ///
  /// In ja, this message translates to:
  /// **'インポートエラー'**
  String get importError;

  /// Import error message
  ///
  /// In ja, this message translates to:
  /// **'インポートエラー: {error}'**
  String importErrorMessage(String error);

  /// OAuth2 authentication completed
  ///
  /// In ja, this message translates to:
  /// **'OAuth2認証が完了しました'**
  String get oauth2AuthCompleted;

  /// This file contains message
  ///
  /// In ja, this message translates to:
  /// **'このファイルには以下の情報が含まれます：'**
  String get thisFileContains;

  /// Sync status title
  ///
  /// In ja, this message translates to:
  /// **'同期状態'**
  String get syncStatus;

  /// Waiting status
  ///
  /// In ja, this message translates to:
  /// **'待機中'**
  String get waiting;

  /// Syncing status
  ///
  /// In ja, this message translates to:
  /// **'同期中...'**
  String get syncing;

  /// Sync completed status
  ///
  /// In ja, this message translates to:
  /// **'同期完了'**
  String get syncCompleted;

  /// Sync error status
  ///
  /// In ja, this message translates to:
  /// **'同期エラー'**
  String get syncError;

  /// Last sync time
  ///
  /// In ja, this message translates to:
  /// **'最終同期: {time}'**
  String lastSync(String time);

  /// Processing items message
  ///
  /// In ja, this message translates to:
  /// **'{processed}/{total}件処理中...'**
  String processingItems(int processed, int total);

  /// Error message
  ///
  /// In ja, this message translates to:
  /// **'エラー: {message}'**
  String error(String message);

  /// Error code
  ///
  /// In ja, this message translates to:
  /// **'エラーコード: {code}'**
  String errorCode(String code);

  /// Partial sync title
  ///
  /// In ja, this message translates to:
  /// **'部分同期'**
  String get partialSync;

  /// Partial sync description
  ///
  /// In ja, this message translates to:
  /// **'選択したタスクや日付範囲のタスクのみを同期できます'**
  String get partialSyncDescription;

  /// Individual task sync info
  ///
  /// In ja, this message translates to:
  /// **'個別タスクの同期は、タスク画面の各タスクの3点ドットメニューから「このタスクを同期」を選択してください。'**
  String get individualTaskSyncInfo;

  /// Sync by date range button
  ///
  /// In ja, this message translates to:
  /// **'日付範囲で同期'**
  String get syncByDateRange;

  /// Cleanup duplicate events button
  ///
  /// In ja, this message translates to:
  /// **'重複イベントをクリーンアップ'**
  String get cleanupDuplicateEvents;

  /// Delete orphaned events button
  ///
  /// In ja, this message translates to:
  /// **'孤立イベントを削除'**
  String get deleteOrphanedEvents;

  /// Orphaned events deletion title
  ///
  /// In ja, this message translates to:
  /// **'孤立イベント削除'**
  String get orphanedEventsDeletion;

  /// Orphaned events deletion description
  ///
  /// In ja, this message translates to:
  /// **'Google Calendarに残っているが、アプリに存在しないタスクのイベントを削除します。\nアプリで削除されたタスクのイベントがGoogle Calendarに残っている場合に使用してください。\n\nこの操作は取り消せません。実行しますか？'**
  String get orphanedEventsDeletionDescription;

  /// Execute deletion button
  ///
  /// In ja, this message translates to:
  /// **'削除実行'**
  String get executeDeletion;

  /// Detecting orphaned events message
  ///
  /// In ja, this message translates to:
  /// **'孤立イベントを検出中...'**
  String get detectingOrphanedEvents;

  /// Orphaned events deletion completed
  ///
  /// In ja, this message translates to:
  /// **'孤立イベント削除完了: {count}件削除'**
  String orphanedEventsDeletionCompleted(int count);

  /// Orphaned events deleted
  ///
  /// In ja, this message translates to:
  /// **'孤立イベント{count}件を削除しました'**
  String orphanedEventsDeleted(int count);

  /// No orphaned events found
  ///
  /// In ja, this message translates to:
  /// **'孤立イベントは見つかりませんでした'**
  String get noOrphanedEventsFound;

  /// Orphaned events deletion failed
  ///
  /// In ja, this message translates to:
  /// **'孤立イベント削除に失敗しました'**
  String get orphanedEventsDeletionFailed;

  /// Orphaned events deletion error
  ///
  /// In ja, this message translates to:
  /// **'孤立イベント削除中にエラーが発生しました'**
  String get orphanedEventsDeletionError;

  /// Duplicate events cleanup title
  ///
  /// In ja, this message translates to:
  /// **'重複イベントクリーンアップ'**
  String get duplicateEventsCleanup;

  /// Duplicate events cleanup description
  ///
  /// In ja, this message translates to:
  /// **'Google Calendarの重複したイベントを検出・削除します。\n同じタイトルと日付のイベントが複数ある場合、古いものを削除します。\n\nこの操作は取り消せません。実行しますか？'**
  String get duplicateEventsCleanupDescription;

  /// Execute cleanup button
  ///
  /// In ja, this message translates to:
  /// **'クリーンアップ実行'**
  String get executeCleanup;

  /// Detecting duplicate events message
  ///
  /// In ja, this message translates to:
  /// **'重複イベントを検出中...'**
  String get detectingDuplicateEvents;

  /// Duplicate cleanup completed
  ///
  /// In ja, this message translates to:
  /// **'重複クリーンアップ完了: {found}グループ検出、{removed}件削除'**
  String duplicateCleanupCompleted(int found, int removed);

  /// Duplicate events deleted
  ///
  /// In ja, this message translates to:
  /// **'重複イベント{count}件を削除しました'**
  String duplicateEventsDeleted(int count);

  /// No duplicate events found
  ///
  /// In ja, this message translates to:
  /// **'重複イベントは見つかりませんでした'**
  String get noDuplicateEventsFound;

  /// Duplicate cleanup failed
  ///
  /// In ja, this message translates to:
  /// **'重複クリーンアップに失敗しました'**
  String get duplicateCleanupFailed;

  /// Duplicate cleanup error
  ///
  /// In ja, this message translates to:
  /// **'重複クリーンアップ中にエラーが発生しました'**
  String get duplicateCleanupError;

  /// Check setup method button
  ///
  /// In ja, this message translates to:
  /// **'設定方法を確認'**
  String get checkSetupMethod;

  /// Authentication start failed
  ///
  /// In ja, this message translates to:
  /// **'認証の開始に失敗しました'**
  String get authStartFailed;

  /// Storage location label
  ///
  /// In ja, this message translates to:
  /// **'格納場所'**
  String get storageLocation;

  /// Execution method label
  ///
  /// In ja, this message translates to:
  /// **'実行方法'**
  String get executionMethod;

  /// Start OAuth2 authentication button
  ///
  /// In ja, this message translates to:
  /// **'OAuth2認証を開始'**
  String get startOAuth2Authentication;

  /// App to Google Calendar sync button
  ///
  /// In ja, this message translates to:
  /// **'アプリ→Google Calendar同期'**
  String get appToGoogleCalendarSync;

  /// App to Google Calendar sync completed message
  ///
  /// In ja, this message translates to:
  /// **'アプリ→Google Calendar同期完了: 作成{created}件, 更新{updated}件, 削除{deleted}件'**
  String appToGoogleCalendarSyncCompleted(
    int created,
    int updated,
    int deleted,
  );

  /// Google Calendar to app sync button
  ///
  /// In ja, this message translates to:
  /// **'Google Calendar→アプリ同期'**
  String get googleCalendarToAppSync;

  /// Google Calendar to app sync completed message
  ///
  /// In ja, this message translates to:
  /// **'Google Calendar→アプリ同期完了: 追加{added}件, スキップ{skipped}件'**
  String googleCalendarToAppSyncCompleted(int added, int skipped);

  /// Sync error message
  ///
  /// In ja, this message translates to:
  /// **'同期エラー: {error}'**
  String syncErrorMessage(String error);

  /// Error message with colon
  ///
  /// In ja, this message translates to:
  /// **'エラー: {error}'**
  String errorColon(String error);

  /// Screenshot load failed message
  ///
  /// In ja, this message translates to:
  /// **'スクリーンショットを読み込めませんでした。\nassets/help フォルダに画像を配置してください。\n({path})'**
  String screenshotLoadFailed(String path);

  /// Bulk link assignment dialog title
  ///
  /// In ja, this message translates to:
  /// **'リンクを一括割り当て'**
  String get bulkLinkAssignment;

  /// Add description
  ///
  /// In ja, this message translates to:
  /// **'既存のリンクに追加します'**
  String get addDescription;

  /// Remove option
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get remove;

  /// Remove description
  ///
  /// In ja, this message translates to:
  /// **'指定したリンクを削除します'**
  String get removeDescription;

  /// Replace option
  ///
  /// In ja, this message translates to:
  /// **'置換'**
  String get replace;

  /// Replace description
  ///
  /// In ja, this message translates to:
  /// **'既存のリンクを全て置き換えます'**
  String get replaceDescription;

  /// No links available message
  ///
  /// In ja, this message translates to:
  /// **'利用可能なリンクがありません'**
  String get noLinksAvailable;

  /// Tasks merged message
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクを結合しました'**
  String tasksMerged(int count);

  /// Merge task dialog title
  ///
  /// In ja, this message translates to:
  /// **'タスクを結合'**
  String get mergeTask;

  /// Select target task message
  ///
  /// In ja, this message translates to:
  /// **'結合先のタスクを選択してください：'**
  String get selectTargetTask;

  /// Merge task confirm dialog title
  ///
  /// In ja, this message translates to:
  /// **'タスクを結合'**
  String get mergeTaskConfirm;

  /// Merge task confirm description
  ///
  /// In ja, this message translates to:
  /// **'結合元タスクの予定、サブタスク、メモ、リンク、タグが統合されます。\n結合元タスクは完了状態になります。'**
  String get mergeTaskConfirmDescription;

  /// Merge task confirm message
  ///
  /// In ja, this message translates to:
  /// **'「{title}」に{count}件のタスクを結合しますか？\n\n{description}'**
  String mergeTaskConfirmMessage(String title, int count, String description);

  /// Drop to add message
  ///
  /// In ja, this message translates to:
  /// **'ここにドロップして追加'**
  String get dropToAdd;

  /// No links drag to add message
  ///
  /// In ja, this message translates to:
  /// **'リンクなし\nここにドラッグで追加'**
  String get noLinksDragToAdd;

  /// No links yet message
  ///
  /// In ja, this message translates to:
  /// **'リンクがありません'**
  String get noLinksYet;

  /// Merge button label
  ///
  /// In ja, this message translates to:
  /// **'結合'**
  String get merge;

  /// Apply button label
  ///
  /// In ja, this message translates to:
  /// **'適用'**
  String get apply;

  /// Due date bulk change dialog title
  ///
  /// In ja, this message translates to:
  /// **'期限日を一括変更'**
  String get dueDateBulkChange;

  /// Not selected label
  ///
  /// In ja, this message translates to:
  /// **'未選択'**
  String get notSelected;

  /// Bulk tag operation dialog title
  ///
  /// In ja, this message translates to:
  /// **'タグを一括操作'**
  String get bulkTagOperation;

  /// Add tag description
  ///
  /// In ja, this message translates to:
  /// **'既存のタグに追加します'**
  String get addTagDescription;

  /// Remove tag description
  ///
  /// In ja, this message translates to:
  /// **'指定したタグを削除します'**
  String get removeTagDescription;

  /// Some files not registered message
  ///
  /// In ja, this message translates to:
  /// **'一部のファイル/フォルダは登録されませんでした'**
  String get someFilesNotRegistered;

  /// Folder is empty error reason
  ///
  /// In ja, this message translates to:
  /// **'フォルダが空です'**
  String get folderIsEmpty;

  /// Access denied or other error reason
  ///
  /// In ja, this message translates to:
  /// **'アクセス権限がないか、その他のエラーが発生しました'**
  String get accessDeniedOrOtherError;

  /// Does not exist error reason
  ///
  /// In ja, this message translates to:
  /// **'存在しません'**
  String get doesNotExist;

  /// Edit memo dialog title
  ///
  /// In ja, this message translates to:
  /// **'メモを編集'**
  String get editMemo;

  /// Enter memo hint
  ///
  /// In ja, this message translates to:
  /// **'メモを入力...'**
  String get enterMemo;

  /// Empty memo deletes helper text
  ///
  /// In ja, this message translates to:
  /// **'空の場合はメモを削除します'**
  String get emptyMemoDeletes;

  /// Current memo label
  ///
  /// In ja, this message translates to:
  /// **'現在のメモ: {memo}'**
  String currentMemo(String memo);

  /// Content list title
  ///
  /// In ja, this message translates to:
  /// **'コンテンツ一覧'**
  String get contentList;

  /// Click chapter to jump message
  ///
  /// In ja, this message translates to:
  /// **'気になる章をクリックしてジャンプ！'**
  String get clickChapterToJump;

  /// Search by keyword placeholder
  ///
  /// In ja, this message translates to:
  /// **'キーワードで検索'**
  String get searchByKeyword;

  /// Manual load failed message
  ///
  /// In ja, this message translates to:
  /// **'マニュアルの読み込みに失敗しました: {error}'**
  String manualLoadFailed(String error);

  /// Screenshot not registered message
  ///
  /// In ja, this message translates to:
  /// **'スクリーンショット「{id}」は登録されていません。'**
  String screenshotNotRegistered(String id);

  /// Video not registered message
  ///
  /// In ja, this message translates to:
  /// **'動画「{id}」は登録されていません。assets/help/videos フォルダを確認してください。'**
  String videoNotRegistered(String id);

  /// Manual not loaded message
  ///
  /// In ja, this message translates to:
  /// **'マニュアルが読み込まれていません'**
  String get manualNotLoaded;

  /// Reload button label
  ///
  /// In ja, this message translates to:
  /// **'再読み込み'**
  String get reload;

  /// Retry button label
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retry;

  /// Unknown error message
  ///
  /// In ja, this message translates to:
  /// **'未知のエラー'**
  String get unknownError;

  /// Help content not found message
  ///
  /// In ja, this message translates to:
  /// **'ヘルプコンテンツが見つかりませんでした。'**
  String get helpContentNotFound;

  /// Link Navigator manual title
  ///
  /// In ja, this message translates to:
  /// **'Link Navigator 取扱説明書'**
  String get linkNavigatorManual;

  /// Help center guide description
  ///
  /// In ja, this message translates to:
  /// **'アプリをすぐに使いこなすためのガイドです。気になる項目を左のナビから選択してください。'**
  String get helpCenterGuide;

  /// HTML export tooltip
  ///
  /// In ja, this message translates to:
  /// **'HTML出力・印刷'**
  String get htmlExport;

  /// HTML export failed message
  ///
  /// In ja, this message translates to:
  /// **'HTML出力に失敗しました: {error}'**
  String htmlExportFailed(String error);

  /// Files added message
  ///
  /// In ja, this message translates to:
  /// **'ファイルを{count}個追加しました'**
  String filesAdded(int count);

  /// Folders added message
  ///
  /// In ja, this message translates to:
  /// **'フォルダを{count}個追加しました'**
  String foldersAdded(int count);

  /// Links added message
  ///
  /// In ja, this message translates to:
  /// **'リンクを{count}個追加しました'**
  String linksAdded(int count);

  /// Items added combined message
  ///
  /// In ja, this message translates to:
  /// **'{files}、{folders}、{links}'**
  String itemsAdded(String files, String folders, String links);

  /// Label field
  ///
  /// In ja, this message translates to:
  /// **'ラベル'**
  String get label;

  /// Link label hint
  ///
  /// In ja, this message translates to:
  /// **'リンクラベルを入力...'**
  String get linkLabelHint;

  /// Path/URL field
  ///
  /// In ja, this message translates to:
  /// **'パス/URL'**
  String get pathUrl;

  /// Path/URL hint
  ///
  /// In ja, this message translates to:
  /// **'ファイルパスまたはURLを入力...'**
  String get pathUrlHint;

  /// Tags input hint
  ///
  /// In ja, this message translates to:
  /// **'カンマ区切りで入力（例: 仕事, 重要, プロジェクトA）'**
  String get tagsHint;

  /// Favicon URL hint
  ///
  /// In ja, this message translates to:
  /// **'例: https://www.resonabank.co.jp/'**
  String get faviconUrlHint;

  /// Icon label
  ///
  /// In ja, this message translates to:
  /// **'アイコン: '**
  String get icon;

  /// No name set
  ///
  /// In ja, this message translates to:
  /// **'名称未設定'**
  String get noNameSet;

  /// Get button
  ///
  /// In ja, this message translates to:
  /// **'取得'**
  String get get;

  /// Get schedules confirmation message
  ///
  /// In ja, this message translates to:
  /// **'スケジュールを取得しますか？'**
  String get getSchedulesConfirm;

  /// Schedules retrieved message
  ///
  /// In ja, this message translates to:
  /// **'取得: {total}件\n追加: {added}件\nスキップ: {skipped}件'**
  String schedulesRetrieved(int total, int added, int skipped);

  /// Schedules retrieved with no additions message
  ///
  /// In ja, this message translates to:
  /// **'取得: {total}件\n追加: 0件\nスキップ: {skipped}件（既に取り込まれています）'**
  String schedulesRetrievedNoAdd(int total, int skipped);

  /// Schedules retrieved with no schedules message
  ///
  /// In ja, this message translates to:
  /// **'取得: {total}件\n取り込む予定はありませんでした'**
  String schedulesRetrievedNoSchedule(int total);

  /// Outlook schedule retrieval dialog title
  ///
  /// In ja, this message translates to:
  /// **'Outlookスケジュール取得'**
  String get outlookScheduleRetrieval;

  /// Favicon fallback domain label
  ///
  /// In ja, this message translates to:
  /// **'Faviconフォールバックドメイン'**
  String get faviconFallbackDomain;

  /// Favicon fallback helper text
  ///
  /// In ja, this message translates to:
  /// **'favicon取得失敗時に使用するドメインを設定'**
  String get faviconFallbackHelper;

  /// Outlook auto import completed title
  ///
  /// In ja, this message translates to:
  /// **'Outlook自動取り込み完了'**
  String get outlookAutoImportCompleted;

  /// UI density label with percentage
  ///
  /// In ja, this message translates to:
  /// **'UI密度: {percent}%'**
  String uiDensity(String percent);

  /// Change priority menu item
  ///
  /// In ja, this message translates to:
  /// **'優先度変更'**
  String get changePriorityMenu;

  /// Change due date menu item
  ///
  /// In ja, this message translates to:
  /// **'期限日変更'**
  String get changeDueDateMenu;

  /// Manage tags menu item
  ///
  /// In ja, this message translates to:
  /// **'タグを操作'**
  String get manageTagsMenu;

  /// Assign link menu item
  ///
  /// In ja, this message translates to:
  /// **'リンクを割り当て'**
  String get assignLinkMenu;

  /// Combine tasks menu item
  ///
  /// In ja, this message translates to:
  /// **'タスクを結合'**
  String get combineTasksMenu;

  /// Drag and drop highlight tag
  ///
  /// In ja, this message translates to:
  /// **'ドラッグ＆ドロップ'**
  String get dragAndDrop;

  /// Google integration highlight tag
  ///
  /// In ja, this message translates to:
  /// **'Google連携'**
  String get googleIntegration;

  /// Notifications and alerts highlight tag
  ///
  /// In ja, this message translates to:
  /// **'通知・アラート'**
  String get notificationsAlerts;

  /// Color theme highlight tag
  ///
  /// In ja, this message translates to:
  /// **'カラーテーマ'**
  String get colorTheme;

  /// Shortcuts highlight tag
  ///
  /// In ja, this message translates to:
  /// **'ショートカット'**
  String get shortcuts;

  /// CSV export column selection dialog title
  ///
  /// In ja, this message translates to:
  /// **'CSV出力する列を選択'**
  String get selectColumnsToExport;

  /// Group by due date option
  ///
  /// In ja, this message translates to:
  /// **'期限日でグループ化'**
  String get groupByDueDate;

  /// Group by tag option
  ///
  /// In ja, this message translates to:
  /// **'タグでグループ化'**
  String get groupByTag;

  /// Group by project (link) option
  ///
  /// In ja, this message translates to:
  /// **'プロジェクト（リンク）でグループ化'**
  String get groupByProjectLink;

  /// Group by priority option
  ///
  /// In ja, this message translates to:
  /// **'優先度でグループ化'**
  String get groupByPriority;

  /// Assignee field label
  ///
  /// In ja, this message translates to:
  /// **'担当者'**
  String get assignee;

  /// Return to link management screen tooltip
  ///
  /// In ja, this message translates to:
  /// **'リンク管理画面に戻る'**
  String get returnToLinkManagementScreen;

  /// Template delete confirmation dialog title
  ///
  /// In ja, this message translates to:
  /// **'テンプレートを削除'**
  String get templateDeleteConfirm;

  /// Template delete confirmation message
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を削除しますか？'**
  String templateDeleteMessage(String name);

  /// Template name required message
  ///
  /// In ja, this message translates to:
  /// **'テンプレート名を入力してください'**
  String get templateNameRequired;

  /// Title required message
  ///
  /// In ja, this message translates to:
  /// **'タイトルを入力してください'**
  String get titleRequired;

  /// Template saved message
  ///
  /// In ja, this message translates to:
  /// **'テンプレートを保存しました'**
  String get templateSaved;

  /// CSV column: ID
  ///
  /// In ja, this message translates to:
  /// **'ID'**
  String get csvColumnId;

  /// CSV column: Title
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get csvColumnTitle;

  /// CSV column: Description
  ///
  /// In ja, this message translates to:
  /// **'説明'**
  String get csvColumnDescription;

  /// CSV column: Due Date
  ///
  /// In ja, this message translates to:
  /// **'期限'**
  String get csvColumnDueDate;

  /// CSV column: Reminder Time
  ///
  /// In ja, this message translates to:
  /// **'リマインダー時刻'**
  String get csvColumnReminderTime;

  /// CSV column: Priority
  ///
  /// In ja, this message translates to:
  /// **'優先度'**
  String get csvColumnPriority;

  /// CSV column: Status
  ///
  /// In ja, this message translates to:
  /// **'ステータス'**
  String get csvColumnStatus;

  /// CSV column: Tags
  ///
  /// In ja, this message translates to:
  /// **'タグ'**
  String get csvColumnTags;

  /// CSV column: Related Link ID
  ///
  /// In ja, this message translates to:
  /// **'関連リンクID'**
  String get csvColumnRelatedLinkId;

  /// CSV column: Created Date
  ///
  /// In ja, this message translates to:
  /// **'作成日'**
  String get csvColumnCreatedAt;

  /// CSV column: Completed Date
  ///
  /// In ja, this message translates to:
  /// **'完了日'**
  String get csvColumnCompletedAt;

  /// CSV column: Started Date
  ///
  /// In ja, this message translates to:
  /// **'着手日'**
  String get csvColumnStartedAt;

  /// CSV column: Completed Date (Manual Entry)
  ///
  /// In ja, this message translates to:
  /// **'完了日（手動入力）'**
  String get csvColumnCompletedAtManual;

  /// CSV column: Estimated Minutes
  ///
  /// In ja, this message translates to:
  /// **'推定時間(分)'**
  String get csvColumnEstimatedMinutes;

  /// CSV column: Notes
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get csvColumnNotes;

  /// CSV column: Recurring Task
  ///
  /// In ja, this message translates to:
  /// **'繰り返しタスク'**
  String get csvColumnIsRecurring;

  /// CSV column: Recurring Pattern
  ///
  /// In ja, this message translates to:
  /// **'繰り返しパターン'**
  String get csvColumnRecurringPattern;

  /// CSV column: Recurring Reminder
  ///
  /// In ja, this message translates to:
  /// **'繰り返しリマインダー'**
  String get csvColumnIsRecurringReminder;

  /// CSV column: Recurring Reminder Pattern
  ///
  /// In ja, this message translates to:
  /// **'繰り返しリマインダーパターン'**
  String get csvColumnRecurringReminderPattern;

  /// CSV column: Next Reminder Time
  ///
  /// In ja, this message translates to:
  /// **'次のリマインダー時刻'**
  String get csvColumnNextReminderTime;

  /// CSV column: Reminder Count
  ///
  /// In ja, this message translates to:
  /// **'リマインダー回数'**
  String get csvColumnReminderCount;

  /// CSV column: Has Subtasks
  ///
  /// In ja, this message translates to:
  /// **'サブタスク有無'**
  String get csvColumnHasSubTasks;

  /// CSV column: Completed Subtasks Count
  ///
  /// In ja, this message translates to:
  /// **'完了サブタスク数'**
  String get csvColumnCompletedSubTasksCount;

  /// CSV column: Total Subtasks Count
  ///
  /// In ja, this message translates to:
  /// **'総サブタスク数'**
  String get csvColumnTotalSubTasksCount;

  /// Mail sending section title
  ///
  /// In ja, this message translates to:
  /// **'メール送信'**
  String get mailSending;

  /// Copy requestor and memo to body checkbox
  ///
  /// In ja, this message translates to:
  /// **'本文に「依頼先やメモ」をコピー'**
  String get copyRequestorMemoToBody;

  /// Include subtasks in body checkbox
  ///
  /// In ja, this message translates to:
  /// **'本文にサブタスクを含める'**
  String get includeSubtasksInBody;

  /// Sending app label
  ///
  /// In ja, this message translates to:
  /// **'送信アプリ:'**
  String get sendingApp;

  /// Recipient selection section title
  ///
  /// In ja, this message translates to:
  /// **'送信先選択'**
  String get recipientSelection;

  /// Add contact button
  ///
  /// In ja, this message translates to:
  /// **'連絡先を追加'**
  String get addContact;

  /// Select from send history button
  ///
  /// In ja, this message translates to:
  /// **'送信履歴から選択'**
  String get selectFromSendHistory;

  /// Frequently used contacts label
  ///
  /// In ja, this message translates to:
  /// **'よく使われる連絡先:'**
  String get frequentlyUsedContacts;

  /// Empty mailer can launch hint
  ///
  /// In ja, this message translates to:
  /// **'空でもメーラーが起動します'**
  String get emptyMailerCanLaunch;

  /// Empty can specify address helper text
  ///
  /// In ja, this message translates to:
  /// **'※空の場合はメーラーで直接アドレスを指定できます'**
  String get emptyCanSpecifyAddress;

  /// Mailer launch instruction
  ///
  /// In ja, this message translates to:
  /// **'※まず「メーラーを起動」ボタンでメーラーを開いてください'**
  String get mailerLaunchInstruction;

  /// Mailer send instruction
  ///
  /// In ja, this message translates to:
  /// **'※メーラーでメールを送信した後、「メール送信完了」ボタンを押してください'**
  String get mailerSendInstruction;

  /// Task related mail default subject
  ///
  /// In ja, this message translates to:
  /// **'タスク関連メール'**
  String get taskRelatedMail;

  /// Mail compose opened message
  ///
  /// In ja, this message translates to:
  /// **'{app}のメール作成画面を開きました。\nメールを送信した後、「メール送信完了」ボタンを押してください。'**
  String mailComposeOpened(String app);

  /// Mailer launch error message
  ///
  /// In ja, this message translates to:
  /// **'メーラー起動エラー: {error}'**
  String mailerLaunchError(String error);

  /// Please launch mailer first error
  ///
  /// In ja, this message translates to:
  /// **'先に「メーラーを起動」ボタンを押してください'**
  String get pleaseLaunchMailerFirst;

  /// Mail sent recorded message
  ///
  /// In ja, this message translates to:
  /// **'メール送信完了を記録しました'**
  String get mailSentRecorded;

  /// Mail sent record error message
  ///
  /// In ja, this message translates to:
  /// **'メール送信完了記録エラー: {error}'**
  String mailSentRecordError(String error);

  /// Outlook connection test success
  ///
  /// In ja, this message translates to:
  /// **'Outlook接続テスト成功'**
  String get outlookConnectionTestSuccess;

  /// Outlook connection test failed
  ///
  /// In ja, this message translates to:
  /// **'Outlook接続テスト失敗: Outlookが利用できません'**
  String get outlookConnectionTestFailed;

  /// Outlook connection test error
  ///
  /// In ja, this message translates to:
  /// **'Outlook接続テストエラー: {error}'**
  String outlookConnectionTestError(String error);

  /// PowerShell script not found error
  ///
  /// In ja, this message translates to:
  /// **'PowerShellスクリプトが見つかりません: {scriptName}\n\n以下のいずれかの場所に配置してください:\n1. ポータブル版: {portablePath}\n2. インストール版: {installedPath}'**
  String powershellScriptNotFound(
    String scriptName,
    String portablePath,
    String installedPath,
  );

  /// Name label
  ///
  /// In ja, this message translates to:
  /// **'名前'**
  String get name;

  /// Name required error
  ///
  /// In ja, this message translates to:
  /// **'名前を入力してください'**
  String get nameRequired;

  /// Gmail launch failed error
  ///
  /// In ja, this message translates to:
  /// **'Gmailを起動できませんでした'**
  String get gmailLaunchFailed;

  /// Outlook not installed error
  ///
  /// In ja, this message translates to:
  /// **'Outlookがインストールされていないか、正しく設定されていません。\n会社PCでOutlookを使用してください。\n詳細: {details}'**
  String outlookNotInstalled(String details);

  /// Outlook launch failed error
  ///
  /// In ja, this message translates to:
  /// **'Outlook起動に失敗しました: {error}'**
  String outlookLaunchFailed(String error);

  /// Outlook search failed error
  ///
  /// In ja, this message translates to:
  /// **'Outlook検索に失敗しました: {error}'**
  String outlookSearchFailed(String error);

  /// Unsupported mail app error
  ///
  /// In ja, this message translates to:
  /// **'サポートされていないメールアプリ: {app}'**
  String unsupportedMailApp(String app);

  /// PowerShell timeout error
  ///
  /// In ja, this message translates to:
  /// **'PowerShell実行がタイムアウトしました（{seconds}秒）'**
  String powershellTimeout(int seconds);

  /// PowerShell script execution error
  ///
  /// In ja, this message translates to:
  /// **'PowerShellスクリプト実行エラー: {error}'**
  String powershellScriptError(String error);

  /// PowerShell execution failed error
  ///
  /// In ja, this message translates to:
  /// **'PowerShell実行が失敗しました（全{retries}回の試行）'**
  String powershellExecutionFailed(int retries);

  /// Unexpected JSON format error
  ///
  /// In ja, this message translates to:
  /// **'予期しないJSON形式です'**
  String get unexpectedJsonFormat;

  /// Start date parse error
  ///
  /// In ja, this message translates to:
  /// **'開始日時のパースエラー: {date}'**
  String startDateParseError(String date);

  /// OAuth2 credentials not found error
  ///
  /// In ja, this message translates to:
  /// **'OAuth2認証情報ファイルが見つかりません。設定方法を確認してください。'**
  String get oauth2CredentialsNotFound;

  /// Invalid credentials format error
  ///
  /// In ja, this message translates to:
  /// **'認証情報ファイルの形式が正しくありません。OAuth2デスクトップアプリ用の認証情報を使用してください。'**
  String get invalidCredentialsFormat;

  /// Client ID not set error
  ///
  /// In ja, this message translates to:
  /// **'認証情報ファイルに client_id が設定されていません。'**
  String get clientIdNotSet;

  /// Auth URL open failed error
  ///
  /// In ja, this message translates to:
  /// **'認証URLを開けませんでした'**
  String get authUrlOpenFailed;

  /// No valid access token error
  ///
  /// In ja, this message translates to:
  /// **'有効なアクセストークンがありません。OAuth2認証を実行してください。'**
  String get noValidAccessToken;

  /// Google Calendar event fetch failed error
  ///
  /// In ja, this message translates to:
  /// **'Google Calendar イベント取得に失敗しました: {statusCode}'**
  String googleCalendarEventFetchFailed(int statusCode);

  /// Event delete failed error
  ///
  /// In ja, this message translates to:
  /// **'イベント削除に失敗しました: {statusCode}'**
  String eventDeleteFailed(int statusCode);

  /// Backup validation failed error
  ///
  /// In ja, this message translates to:
  /// **'バックアップファイルの検証に失敗しました'**
  String get backupValidationFailed;

  /// Backup before operation failed error
  ///
  /// In ja, this message translates to:
  /// **'操作前のバックアップに失敗しました: {error}'**
  String backupBeforeOperationFailed(String error);

  /// Invalid backup data format error
  ///
  /// In ja, this message translates to:
  /// **'バックアップデータの形式が正しくありません'**
  String get invalidBackupDataFormat;

  /// Invalid backup file error
  ///
  /// In ja, this message translates to:
  /// **'無効なバックアップファイルです'**
  String get invalidBackupFile;

  /// Email already registered error
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に登録されています: {email}'**
  String emailAlreadyRegistered(String email);

  /// Contact not found error
  ///
  /// In ja, this message translates to:
  /// **'連絡先が見つかりません: {id}'**
  String contactNotFound(String id);

  /// Outlook event fetch failed error
  ///
  /// In ja, this message translates to:
  /// **'Outlookから予定を取得できませんでした。後でもう一度お試しください。\nエラー: {error}'**
  String outlookEventFetchFailed(String error);

  /// Outlook event fetch failed info message
  ///
  /// In ja, this message translates to:
  /// **'Outlookから予定を取得できませんでした。後でもう一度お試しください。'**
  String get outlookEventFetchFailedInfo;

  /// Token extraction failed error
  ///
  /// In ja, this message translates to:
  /// **'トークンの抽出に失敗しました'**
  String get tokenExtractionFailed;

  /// Task not selected error
  ///
  /// In ja, this message translates to:
  /// **'タスクが選択されていません'**
  String get taskNotSelected;

  /// No send history for task message
  ///
  /// In ja, this message translates to:
  /// **'このタスクの送信履歴はありません'**
  String get noSendHistoryForTask;

  /// Send history reused message
  ///
  /// In ja, this message translates to:
  /// **'送信履歴を再利用しました'**
  String get sendHistoryReused;

  /// Gmail connection test label
  ///
  /// In ja, this message translates to:
  /// **'Gmail接続テスト'**
  String get gmailConnectionTest;

  /// Gmail connection test body
  ///
  /// In ja, this message translates to:
  /// **'これはGmail接続テストです。'**
  String get gmailConnectionTestBody;

  /// Gmail connection test success message
  ///
  /// In ja, this message translates to:
  /// **'Gmail接続テスト成功: Gmailが開きました'**
  String get gmailConnectionTestSuccess;

  /// Gmail connection test error
  ///
  /// In ja, this message translates to:
  /// **'Gmail接続テストエラー: {error}'**
  String gmailConnectionTestError(String error);

  /// Test mail sent message
  ///
  /// In ja, this message translates to:
  /// **'テストメール送信完了'**
  String get testMailSent;

  /// Test mail send error
  ///
  /// In ja, this message translates to:
  /// **'テストメール送信エラー: {error}'**
  String testMailSendError(String error);

  /// No send history message
  ///
  /// In ja, this message translates to:
  /// **'送信履歴がありません'**
  String get noSendHistory;

  /// Send history auto register message
  ///
  /// In ja, this message translates to:
  /// **'メールを送信すると、宛先が自動で連絡先に登録されます'**
  String get sendHistoryAutoRegister;

  /// Latest mail prefix
  ///
  /// In ja, this message translates to:
  /// **'🆕 最新のメール'**
  String get latestMail;

  /// Oldest mail prefix
  ///
  /// In ja, this message translates to:
  /// **'⭐ 最初のメール'**
  String get oldestMail;

  /// Sent label with colon
  ///
  /// In ja, this message translates to:
  /// **'送信:'**
  String get sentColon;

  /// Subject label with colon
  ///
  /// In ja, this message translates to:
  /// **'件名:'**
  String get subjectColon;

  /// To label with colon
  ///
  /// In ja, this message translates to:
  /// **'To:'**
  String get toColon;

  /// Body label with colon
  ///
  /// In ja, this message translates to:
  /// **'本文:'**
  String get bodyColon;

  /// Task label with colon
  ///
  /// In ja, this message translates to:
  /// **'タスク:'**
  String get taskLabel;

  /// Related task information header
  ///
  /// In ja, this message translates to:
  /// **'【関連タスク情報】'**
  String get relatedTaskInfo;

  /// Mail information header
  ///
  /// In ja, this message translates to:
  /// **'【メール情報】'**
  String get mailInfo;

  /// Sent date/time label
  ///
  /// In ja, this message translates to:
  /// **'送信日時'**
  String get sentDateTime;

  /// Sent ID label with colon
  ///
  /// In ja, this message translates to:
  /// **'送信ID:'**
  String get sentId;

  /// No message text
  ///
  /// In ja, this message translates to:
  /// **'メッセージがありません。'**
  String get noMessage;

  /// No task information text
  ///
  /// In ja, this message translates to:
  /// **'タスク情報がありません。'**
  String get noTaskInfo;

  /// Links label with colon
  ///
  /// In ja, this message translates to:
  /// **'リンク:'**
  String get linksLabel;

  /// Related materials header
  ///
  /// In ja, this message translates to:
  /// **'【関連資料】'**
  String get relatedMaterials;

  /// Subtask progress label with colon
  ///
  /// In ja, this message translates to:
  /// **'サブタスク進捗:'**
  String get subtaskProgress;

  /// Completed label with colon
  ///
  /// In ja, this message translates to:
  /// **'完了:'**
  String get completedLabel;

  /// Mail sent from app message
  ///
  /// In ja, this message translates to:
  /// **'このメールは Link Navigator アプリから送信されました。'**
  String get thisMailSentFromApp;

  /// Task information header
  ///
  /// In ja, this message translates to:
  /// **'📋 タスク情報'**
  String get taskInfoHeader;

  /// Related materials label with colon
  ///
  /// In ja, this message translates to:
  /// **'関連資料:'**
  String get relatedMaterialsLabel;

  /// Gmail link note
  ///
  /// In ja, this message translates to:
  /// **'📝 注意: ネットワーク共有やローカルファイルのリンクは、Gmailでは直接クリックできません。\nリンクをコピーして、ファイルエクスプローラーやブラウザのアドレスバーに貼り付けてアクセスしてください。'**
  String get gmailLinkNote;

  /// Outlook link note
  ///
  /// In ja, this message translates to:
  /// **'📝 注意: Outlookでは、ネットワーク共有やローカルファイルのリンクもクリック可能です。\nリンクをクリックして直接アクセスできます。'**
  String get outlookLinkNote;

  /// Period label with colon
  ///
  /// In ja, this message translates to:
  /// **'期間:'**
  String get periodLabel;

  /// Start label with colon
  ///
  /// In ja, this message translates to:
  /// **'開始:'**
  String get startLabel;

  /// End label with colon
  ///
  /// In ja, this message translates to:
  /// **'終了:'**
  String get endLabel;

  /// Get schedules button
  ///
  /// In ja, this message translates to:
  /// **'予定を取得'**
  String get getSchedules;

  /// Search schedules placeholder
  ///
  /// In ja, this message translates to:
  /// **'予定を検索...'**
  String get searchSchedules;

  /// Sort by title
  ///
  /// In ja, this message translates to:
  /// **'タイトル順'**
  String get sortByTitle;

  /// Sort by date time
  ///
  /// In ja, this message translates to:
  /// **'日時順'**
  String get sortByDateTime;

  /// Processing message
  ///
  /// In ja, this message translates to:
  /// **'処理中...'**
  String get processing;

  /// Assign to tasks button
  ///
  /// In ja, this message translates to:
  /// **'タスクに割り当て ({count}件)'**
  String assignToTasks(int count);

  /// Link opened message
  ///
  /// In ja, this message translates to:
  /// **'リンク「{label}」を開きました'**
  String linkOpened(String label);

  /// Link not found message
  ///
  /// In ja, this message translates to:
  /// **'リンクが見つかりません'**
  String get linkNotFound;

  /// Completion date label with colon
  ///
  /// In ja, this message translates to:
  /// **'完了日:'**
  String get completionDateColon;

  /// Completed label with colon
  ///
  /// In ja, this message translates to:
  /// **'完了:'**
  String get completedColon;

  /// Copy to Excel one cell form
  ///
  /// In ja, this message translates to:
  /// **'エクセルにコピー（1セル形式）'**
  String get copyToExcelOneCellForm;

  /// Excel copy only in list view message
  ///
  /// In ja, this message translates to:
  /// **'エクセルコピーはリスト表示時のみ利用できます。'**
  String get excelCopyOnlyInListView;

  /// Schedules copied to Excel message
  ///
  /// In ja, this message translates to:
  /// **'{count}件の予定を{format}でクリップボードにコピーしました（エクセルに貼り付け可能）'**
  String schedulesCopiedToExcel(int count, String format);

  /// Schedules copied to Excel one cell form message
  ///
  /// In ja, this message translates to:
  /// **'{count}件の予定を1セル形式でクリップボードにコピーしました（エクセルに貼り付け可能）'**
  String schedulesCopiedToExcelOneCell(int count);

  /// One cell form label
  ///
  /// In ja, this message translates to:
  /// **'1セル形式'**
  String get oneCellForm;

  /// Table form label
  ///
  /// In ja, this message translates to:
  /// **'表形式'**
  String get tableForm;

  /// Import Outlook schedules title
  ///
  /// In ja, this message translates to:
  /// **'Outlook予定を取り込む'**
  String get importOutlookSchedules;

  /// No schedules to import message
  ///
  /// In ja, this message translates to:
  /// **'取り込む必要がある予定はありません'**
  String get noSchedulesToImport;

  /// Meeting label
  ///
  /// In ja, this message translates to:
  /// **'会議'**
  String get meeting;

  /// Recurring label
  ///
  /// In ja, this message translates to:
  /// **'定期'**
  String get recurring;

  /// Online label
  ///
  /// In ja, this message translates to:
  /// **'オンライン'**
  String get online;

  /// No matching tasks message
  ///
  /// In ja, this message translates to:
  /// **'条件に合致するタスクがありません'**
  String get noMatchingTasks;

  /// Outlook unavailable skipped message
  ///
  /// In ja, this message translates to:
  /// **'Outlookが利用できないため、自動取り込みをスキップしました'**
  String get outlookUnavailableSkipped;

  /// Outlook auto import completed details
  ///
  /// In ja, this message translates to:
  /// **'Outlook自動取り込み完了\n取得: {total}件\n追加: {added}件\nスキップ: {skipped}件'**
  String outlookAutoImportCompletedDetails(int total, int added, int skipped);

  /// Outlook auto import completed no new schedules
  ///
  /// In ja, this message translates to:
  /// **'Outlook自動取り込み完了\n取得: {total}件\n取り込む予定はありませんでした'**
  String outlookAutoImportCompletedNoNew(int total);

  /// Outlook auto import completed skipped
  ///
  /// In ja, this message translates to:
  /// **'Outlook自動取り込み完了\n取得: {total}件\n追加: 0件\nスキップ: {skipped}件（既に取り込まれています）'**
  String outlookAutoImportCompletedSkipped(int total, int skipped);

  /// Outlook auto import completed added
  ///
  /// In ja, this message translates to:
  /// **'Outlook自動取り込み完了: {added}件の予定を追加しました'**
  String outlookAutoImportCompletedAdded(int added);

  /// Outlook auto import completed skipped only
  ///
  /// In ja, this message translates to:
  /// **'Outlook自動取り込み完了: {skipped}件の予定は既に取り込まれています'**
  String outlookAutoImportCompletedSkippedOnly(int skipped);

  /// Outlook auto import error
  ///
  /// In ja, this message translates to:
  /// **'Outlook自動取り込み中にエラーが発生しました。\nエラー: {error}'**
  String outlookAutoImportError(String error);

  /// Select date to copy message
  ///
  /// In ja, this message translates to:
  /// **'コピーする日付を選択してください'**
  String get selectDateToCopy;

  /// Task not found message
  ///
  /// In ja, this message translates to:
  /// **'タスクが見つかりません'**
  String get taskNotFound;

  /// Related task not found message
  ///
  /// In ja, this message translates to:
  /// **'関連タスクが見つかりませんでした'**
  String get relatedTaskNotFound;

  /// Excel header: Date
  ///
  /// In ja, this message translates to:
  /// **'日付'**
  String get excelHeaderDate;

  /// Excel header: Start Time
  ///
  /// In ja, this message translates to:
  /// **'開始時刻'**
  String get excelHeaderStartTime;

  /// Excel header: End Time
  ///
  /// In ja, this message translates to:
  /// **'終了時刻'**
  String get excelHeaderEndTime;

  /// Excel header: Title
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get excelHeaderTitle;

  /// Excel header: Location
  ///
  /// In ja, this message translates to:
  /// **'場所'**
  String get excelHeaderLocation;

  /// Excel header: Task Name
  ///
  /// In ja, this message translates to:
  /// **'タスク名'**
  String get excelHeaderTaskName;

  /// Getting schedules from Outlook message
  ///
  /// In ja, this message translates to:
  /// **'Outlookから予定を取得中...'**
  String get gettingSchedulesFromOutlook;

  /// Getting schedules message
  ///
  /// In ja, this message translates to:
  /// **'予定を取得中...'**
  String get gettingSchedules;

  /// Outlook not running or unavailable message
  ///
  /// In ja, this message translates to:
  /// **'Outlookが起動していないか、利用できません。Outlookを起動してから再度お試しください。'**
  String get outlookNotRunningOrUnavailable;

  /// No schedules this month message
  ///
  /// In ja, this message translates to:
  /// **'この月には予定がありません'**
  String get noSchedulesThisMonth;

  /// Schedule shortcuts dialog title
  ///
  /// In ja, this message translates to:
  /// **'予定表ショートカット'**
  String get scheduleShortcuts;

  /// Focus on search bar shortcut description
  ///
  /// In ja, this message translates to:
  /// **'検索バーにフォーカス'**
  String get focusSearchBar;

  /// Select icon and color button and dialog title
  ///
  /// In ja, this message translates to:
  /// **'アイコンと色を選択'**
  String get selectIconAndColor;

  /// Select color label
  ///
  /// In ja, this message translates to:
  /// **'色を選択:'**
  String get selectColor;

  /// Preview label
  ///
  /// In ja, this message translates to:
  /// **'プレビュー:'**
  String get preview;

  /// Decide/Confirm button label for icon selection
  ///
  /// In ja, this message translates to:
  /// **'決定'**
  String get decide;

  /// Other subtasks count message
  ///
  /// In ja, this message translates to:
  /// **'他{count}個'**
  String otherSubTasks(int count);

  /// Globe icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'地球アイコン'**
  String get iconGlobe;

  /// Folder icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'フォルダ'**
  String get iconFolder;

  /// Open folder icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'開いたフォルダ'**
  String get iconFolderOpen;

  /// Special folder icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'特別なフォルダ'**
  String get iconFolderSpecial;

  /// Shared folder icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'共有フォルダ'**
  String get iconFolderShared;

  /// Zip folder icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'圧縮フォルダ'**
  String get iconFolderZip;

  /// Copy folder icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'コピーフォルダ'**
  String get iconFolderCopy;

  /// Delete folder icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'削除フォルダ'**
  String get iconFolderDelete;

  /// Off folder icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'無効フォルダ'**
  String get iconFolderOff;

  /// Folder outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'フォルダ（アウトライン）'**
  String get iconFolderOutlined;

  /// Open folder outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'開いたフォルダ（アウトライン）'**
  String get iconFolderOpenOutlined;

  /// Special folder outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'特別なフォルダ（アウトライン）'**
  String get iconFolderSpecialOutlined;

  /// Shared folder outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'共有フォルダ（アウトライン）'**
  String get iconFolderSharedOutlined;

  /// Zip folder outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'圧縮フォルダ（アウトライン）'**
  String get iconFolderZipOutlined;

  /// Copy folder outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'コピーフォルダ（アウトライン）'**
  String get iconFolderCopyOutlined;

  /// Delete folder outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'削除フォルダ（アウトライン）'**
  String get iconFolderDeleteOutlined;

  /// Off folder outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'無効フォルダ（アウトライン）'**
  String get iconFolderOffOutlined;

  /// Upload folder icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'アップロードフォルダ'**
  String get iconFolderUpload;

  /// Upload folder outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'アップロードフォルダ（アウトライン）'**
  String get iconFolderUploadOutlined;

  /// File move icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'ファイル移動'**
  String get iconFileMove;

  /// File move outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'ファイル移動（アウトライン）'**
  String get iconFileMoveOutlined;

  /// File rename icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'ファイル名変更'**
  String get iconFileRename;

  /// File rename outlined icon tooltip
  ///
  /// In ja, this message translates to:
  /// **'ファイル名変更（アウトライン）'**
  String get iconFileRenameOutlined;

  /// Associate links with task subtitle
  ///
  /// In ja, this message translates to:
  /// **'タスク「{title}」にリンクを関連付け'**
  String associateLinksWithTask(String title);

  /// Existing related links title
  ///
  /// In ja, this message translates to:
  /// **'既存の関連リンク（{count}個）'**
  String existingRelatedLinks(int count);

  /// Click to expand and delete instruction
  ///
  /// In ja, this message translates to:
  /// **'クリックして展開・削除'**
  String get clickToExpandAndDelete;

  /// Select link to associate instruction
  ///
  /// In ja, this message translates to:
  /// **'関連付けたいリンクを選択してください：'**
  String get selectLinkToAssociate;

  /// Search links placeholder
  ///
  /// In ja, this message translates to:
  /// **'リンクを検索...'**
  String get searchLinks;

  /// Selected links count display
  ///
  /// In ja, this message translates to:
  /// **'選択されたリンク: {selected}個（既存: {existing}個）'**
  String selectedLinks(int selected, int existing);

  /// Linked links not found message
  ///
  /// In ja, this message translates to:
  /// **'関連付けられたリンクが見つかりません（{count}個のリンクIDが存在）'**
  String linkedLinksNotFound(int count);

  /// Link deleted success message
  ///
  /// In ja, this message translates to:
  /// **'リンクを削除しました'**
  String get linkDeleted;

  /// Link deletion failed message
  ///
  /// In ja, this message translates to:
  /// **'リンクの削除に失敗しました: {error}'**
  String linkDeletionFailed(String error);

  /// Items count display
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String itemsCount(int count);

  /// Link list title
  ///
  /// In ja, this message translates to:
  /// **'リンク一覧: {count}個'**
  String linkList(int count);

  /// Link association updated success message
  ///
  /// In ja, this message translates to:
  /// **'リンクの関連付けを更新しました'**
  String get linkAssociationUpdated;

  /// Link association update failed message
  ///
  /// In ja, this message translates to:
  /// **'リンクの関連付け更新に失敗しました: {error}'**
  String linkAssociationUpdateFailed(String error);

  /// Orphaned schedules task title
  ///
  /// In ja, this message translates to:
  /// **'孤立予定'**
  String get orphanedSchedules;

  /// Orphaned schedules task description
  ///
  /// In ja, this message translates to:
  /// **'存在しないタスクに紐づいていた予定をまとめるためのタスクです。'**
  String get orphanedSchedulesDescription;

  /// System generated tag
  ///
  /// In ja, this message translates to:
  /// **'システム生成'**
  String get systemGenerated;

  /// Items count display (short format)
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String itemsCountShort(int count);

  /// Schedules assigned message
  ///
  /// In ja, this message translates to:
  /// **'{count}件の予定を割り当てました'**
  String schedulesAssigned(int count);

  /// Tasks created and schedules assigned message
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクを作成し、予定を割り当てました'**
  String tasksCreatedAndSchedulesAssigned(int count);

  /// Items displayed count
  ///
  /// In ja, this message translates to:
  /// **'{count}件表示'**
  String itemsDisplayed(int count);

  /// Candidate tasks found message
  ///
  /// In ja, this message translates to:
  /// **'{count}件の候補タスクが見つかりました'**
  String candidateTasksFound(int count);

  /// Change assigned task tooltip and dialog title
  ///
  /// In ja, this message translates to:
  /// **'割当タスクを変更'**
  String get changeAssignedTask;

  /// No assignable tasks message
  ///
  /// In ja, this message translates to:
  /// **'割り当て可能なタスクがありません'**
  String get noAssignableTasks;

  /// No other tasks message
  ///
  /// In ja, this message translates to:
  /// **'他のタスクがありません'**
  String get noOtherTasks;

  /// Schedule assigned to task message
  ///
  /// In ja, this message translates to:
  /// **'「{scheduleTitle}」を「{taskTitle}」に割り当てました'**
  String scheduleAssignedToTask(String scheduleTitle, String taskTitle);

  /// Schedule task assignment change error message
  ///
  /// In ja, this message translates to:
  /// **'タスク割り当て変更エラー: {error}'**
  String scheduleTaskAssignmentChangeError(String error);

  /// Schedule task assignment change failed message
  ///
  /// In ja, this message translates to:
  /// **'予定のタスク割り当て変更に失敗しました。'**
  String get scheduleTaskAssignmentChangeFailed;

  /// Edit label
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get edit;

  /// Schedule copied and added message
  ///
  /// In ja, this message translates to:
  /// **'予定をコピーして追加しました'**
  String get scheduleCopiedAndAdded;

  /// Drag order (manual) option
  ///
  /// In ja, this message translates to:
  /// **'ドラッグ順（手動）'**
  String get dragOrderManual;

  /// Memo pad title
  ///
  /// In ja, this message translates to:
  /// **'メモ帳'**
  String get memoPad;

  /// New memo button label
  ///
  /// In ja, this message translates to:
  /// **'新しいメモ'**
  String get newMemo;

  /// Delete memo dialog title
  ///
  /// In ja, this message translates to:
  /// **'メモを削除'**
  String get deleteMemo;

  /// Delete memo confirmation message
  ///
  /// In ja, this message translates to:
  /// **'このメモを削除しますか？'**
  String get deleteMemoConfirm;

  /// Memo content input hint
  ///
  /// In ja, this message translates to:
  /// **'メモの内容を入力してください...'**
  String get memoContentHint;

  /// Search memos placeholder
  ///
  /// In ja, this message translates to:
  /// **'メモを検索...'**
  String get searchMemos;

  /// No memos message
  ///
  /// In ja, this message translates to:
  /// **'メモがありません'**
  String get noMemos;

  /// No memos found message
  ///
  /// In ja, this message translates to:
  /// **'該当するメモが見つかりません'**
  String get noMemosFound;

  /// Memo added success message
  ///
  /// In ja, this message translates to:
  /// **'メモを追加しました'**
  String get memoAdded;

  /// Memo updated success message
  ///
  /// In ja, this message translates to:
  /// **'メモを更新しました'**
  String get memoUpdated;

  /// Memo deleted success message
  ///
  /// In ja, this message translates to:
  /// **'メモを削除しました'**
  String get memoDeleted;

  /// Memo save error message
  ///
  /// In ja, this message translates to:
  /// **'メモの保存に失敗しました: {error}'**
  String memoSaveError(String error);

  /// Memo delete error message
  ///
  /// In ja, this message translates to:
  /// **'メモの削除に失敗しました: {error}'**
  String memoDeleteError(String error);

  /// Memo add failed message
  ///
  /// In ja, this message translates to:
  /// **'メモの追加に失敗しました'**
  String get memoAddFailed;

  /// Memo update failed message
  ///
  /// In ja, this message translates to:
  /// **'メモの更新に失敗しました'**
  String get memoUpdateFailed;

  /// Memo delete failed message
  ///
  /// In ja, this message translates to:
  /// **'メモの削除に失敗しました'**
  String get memoDeleteFailed;

  /// No tasks message
  ///
  /// In ja, this message translates to:
  /// **'タスクがありません'**
  String get noTasks;

  /// Tooltip message for click to edit and drag to reorder
  ///
  /// In ja, this message translates to:
  /// **'クリックで編集\nドラッグアイコンで順序変更'**
  String get clickToEditAndDragToReorder;

  /// Reminder date label
  ///
  /// In ja, this message translates to:
  /// **'リマインダー日'**
  String get reminderDate;

  /// Reminder time label
  ///
  /// In ja, this message translates to:
  /// **'リマインダー時刻'**
  String get reminderTime;

  /// Select reminder date placeholder
  ///
  /// In ja, this message translates to:
  /// **'リマインダー日を選択'**
  String get selectReminderDate;

  /// Select time dialog title
  ///
  /// In ja, this message translates to:
  /// **'時間を選択'**
  String get selectTime;

  /// Export links to Excel menu item
  ///
  /// In ja, this message translates to:
  /// **'リンクをエクセル出力'**
  String get exportLinksToExcel;

  /// Export links to Excel shortcut description
  ///
  /// In ja, this message translates to:
  /// **'リンクをエクセル出力'**
  String get exportLinksToExcelShortcut;

  /// Select groups to export dialog title
  ///
  /// In ja, this message translates to:
  /// **'エクスポートするグループを選択'**
  String get selectGroupsToExport;

  /// Links exported message
  ///
  /// In ja, this message translates to:
  /// **'リンクをエクセル形式でエクスポートしました: {filePath}'**
  String linksExported(String filePath);

  /// Links export failed message
  ///
  /// In ja, this message translates to:
  /// **'リンクのエクスポートに失敗しました: {error}'**
  String linksExportFailed(String error);

  /// Excel hyperlink activation instruction title
  ///
  /// In ja, this message translates to:
  /// **'ハイパーリンクを有効化する方法'**
  String get excelHyperlinkActivationTitle;

  /// Excel hyperlink activation instruction description
  ///
  /// In ja, this message translates to:
  /// **'エクスポートしたExcelファイルで、ハイパーリンクが文字列として表示されている場合、以下の手順で一括して有効化できます：'**
  String get excelHyperlinkActivationDescription;

  /// Excel hyperlink activation step 1
  ///
  /// In ja, this message translates to:
  /// **'リンク列（C列）を選択します'**
  String get excelHyperlinkActivationStep1;

  /// Excel hyperlink activation step 2
  ///
  /// In ja, this message translates to:
  /// **'Ctrl + H キーを押して「検索と置換」ダイアログを開きます'**
  String get excelHyperlinkActivationStep2;

  /// Excel hyperlink activation step 3
  ///
  /// In ja, this message translates to:
  /// **'検索する文字列に「=HYPERLINK」と入力します'**
  String get excelHyperlinkActivationStep3;

  /// Excel hyperlink activation step 4
  ///
  /// In ja, this message translates to:
  /// **'置換後の文字列にも「=HYPERLINK」と入力し、「すべて置換」をクリックします'**
  String get excelHyperlinkActivationStep4;

  /// Excel hyperlink activation note
  ///
  /// In ja, this message translates to:
  /// **'これにより、Excelが数式を再評価し、ハイパーリンクが有効になります。また、Excelファイルの「ハイパーリンク有効化方法」シートにも手順が記載されています。'**
  String get excelHyperlinkActivationNote;

  /// Excel links sheet name
  ///
  /// In ja, this message translates to:
  /// **'リンク一覧'**
  String get excelLinksSheetName;

  /// Excel hyperlink activation sheet name
  ///
  /// In ja, this message translates to:
  /// **'ハイパーリンク有効化方法'**
  String get excelHyperlinkActivationSheetName;

  /// Excel column header for group name
  ///
  /// In ja, this message translates to:
  /// **'グループ名'**
  String get excelColumnGroupName;

  /// Excel column header for label
  ///
  /// In ja, this message translates to:
  /// **'ラベル'**
  String get excelColumnLabel;

  /// Excel column header for link
  ///
  /// In ja, this message translates to:
  /// **'リンク'**
  String get excelColumnLink;

  /// Excel column header for memo
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get excelColumnMemo;

  /// Excel security warning title
  ///
  /// In ja, this message translates to:
  /// **'セキュリティ警告について'**
  String get excelSecurityWarningTitle;

  /// Excel security warning description
  ///
  /// In ja, this message translates to:
  /// **'ハイパーリンクをクリックすると、Excelのセキュリティ警告が表示される場合があります。これは、ローカルファイルやネットワークパスへのリンクに対するExcelの標準的なセキュリティ機能です。'**
  String get excelSecurityWarningDescription;

  /// Excel security warning solution
  ///
  /// In ja, this message translates to:
  /// **'警告が表示された場合は、「はい」をクリックして続行してください。信頼できるファイルへのリンクであれば安全です。'**
  String get excelSecurityWarningSolution;

  /// Official website label
  ///
  /// In ja, this message translates to:
  /// **'公式サイト'**
  String get officialWebsite;

  /// Official website description
  ///
  /// In ja, this message translates to:
  /// **'詳細な情報やスクリーンショット、デモ動画は公式サイトでご確認いただけます。'**
  String get officialWebsiteDescription;

  /// Open website button text
  ///
  /// In ja, this message translates to:
  /// **'サイトを開く'**
  String get openWebsite;

  /// No groups selected message
  ///
  /// In ja, this message translates to:
  /// **'グループが選択されていません'**
  String get noGroupsSelected;

  /// Completion report title
  ///
  /// In ja, this message translates to:
  /// **'完了報告'**
  String get completionReport;

  /// Note about schedule editing availability
  ///
  /// In ja, this message translates to:
  /// **'※ タスク作成後に予定編集が可能になります'**
  String get scheduleEditAvailableAfterTaskCreation;

  /// Schedule overlap title
  ///
  /// In ja, this message translates to:
  /// **'予定の重複'**
  String get scheduleOverlap;

  /// Overlapping schedules message
  ///
  /// In ja, this message translates to:
  /// **'以下の予定と時間が重複しています：'**
  String get overlappingSchedulesMessage;

  /// Time label
  ///
  /// In ja, this message translates to:
  /// **'時間'**
  String get time;

  /// Completion notes label
  ///
  /// In ja, this message translates to:
  /// **'完了メモ'**
  String get completionNotes;

  /// Completion notes hint
  ///
  /// In ja, this message translates to:
  /// **'完了内容や結果を記入してください'**
  String get completionNotesHint;

  /// Completion notes validation message
  ///
  /// In ja, this message translates to:
  /// **'完了メモを入力してください'**
  String get completionNotesRequired;

  /// Send completion report button
  ///
  /// In ja, this message translates to:
  /// **'完了報告を送信'**
  String get sendCompletionReport;

  /// Clear reminder tooltip
  ///
  /// In ja, this message translates to:
  /// **'リマインダーをクリア'**
  String get clearReminder;

  /// Recurring reminder label
  ///
  /// In ja, this message translates to:
  /// **'繰り返しリマインダー'**
  String get recurringReminder;

  /// Select button with count
  ///
  /// In ja, this message translates to:
  /// **'選択 ({count})'**
  String selectWithCount(int count);

  /// To label
  ///
  /// In ja, this message translates to:
  /// **'宛先'**
  String get to;

  /// App label
  ///
  /// In ja, this message translates to:
  /// **'アプリ'**
  String get app;

  /// Bulk assign links dialog title
  ///
  /// In ja, this message translates to:
  /// **'リンクを一括割り当て'**
  String get bulkAssignLinks;

  /// Replace all tags description
  ///
  /// In ja, this message translates to:
  /// **'既存のタグを全て置き換えます'**
  String get replaceAllTags;

  /// Go to settings button
  ///
  /// In ja, this message translates to:
  /// **'設定画面へ'**
  String get goToSettings;

  /// Mail action title
  ///
  /// In ja, this message translates to:
  /// **'メールアクション'**
  String get mailAction;

  /// Select mail action message
  ///
  /// In ja, this message translates to:
  /// **'このタスクに関連するメールアクションを選択してください。'**
  String get selectMailAction;

  /// Reply button
  ///
  /// In ja, this message translates to:
  /// **'返信'**
  String get reply;

  /// Show more candidates button
  ///
  /// In ja, this message translates to:
  /// **'候補をさらに表示'**
  String get showMoreCandidates;

  /// Select task dialog title
  ///
  /// In ja, this message translates to:
  /// **'タスクを選択'**
  String get selectTask;

  /// Message to create task first to add schedule
  ///
  /// In ja, this message translates to:
  /// **'予定を追加するには、まずタスクを作成してください'**
  String get createTaskFirstToAddSchedule;

  /// Schedule copied message
  ///
  /// In ja, this message translates to:
  /// **'予定をコピーしました'**
  String get scheduleCopied;

  /// Schedule deleted message
  ///
  /// In ja, this message translates to:
  /// **'予定を削除しました'**
  String get scheduleDeleted;

  /// Schedule fetch failed message
  ///
  /// In ja, this message translates to:
  /// **'予定の取得に失敗しました: {error}'**
  String scheduleFetchFailed(String error);

  /// Schedule assignment failed message
  ///
  /// In ja, this message translates to:
  /// **'予定「{title}」の割り当てに失敗しました: {error}'**
  String scheduleAssignmentFailed(String title, String error);

  /// Task creation failed message
  ///
  /// In ja, this message translates to:
  /// **'タスクの作成に失敗しました: {error}'**
  String taskCreationFailed(String error);

  /// Need at least two groups message
  ///
  /// In ja, this message translates to:
  /// **'並び順を変更するには2つ以上のグループが必要です'**
  String get needAtLeastTwoGroups;

  /// Create task first message
  ///
  /// In ja, this message translates to:
  /// **'先にタスクを作成してください'**
  String get createTaskFirst;

  /// Sub task title required message
  ///
  /// In ja, this message translates to:
  /// **'サブタスクのタイトルは必須です'**
  String get subTaskTitleRequired;

  /// History fetch error message
  ///
  /// In ja, this message translates to:
  /// **'履歴取得エラー: {error}'**
  String historyFetchError(String error);

  /// Completion report sent message
  ///
  /// In ja, this message translates to:
  /// **'完了報告を送信しました'**
  String get completionReportSent;

  /// Completion report send error message
  ///
  /// In ja, this message translates to:
  /// **'完了報告送信エラー: {error}'**
  String completionReportSendError(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
