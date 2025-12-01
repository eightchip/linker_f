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

  /// 設定画面のタイトル
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

  /// フォント設定メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'フォント設定'**
  String get fontSettings;

  /// UIカスタマイズメニュー項目
  ///
  /// In ja, this message translates to:
  /// **'UIカスタマイズ'**
  String get uiCustomization;

  /// グリッド設定メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'グリッド設定'**
  String get gridSettings;

  /// カード設定メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'カード設定'**
  String get cardSettings;

  /// アイテム設定メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'アイテム設定'**
  String get itemSettings;

  /// カードビュー設定メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'カードビュー設定'**
  String get cardViewSettings;

  /// 通知設定メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'通知設定'**
  String get notificationSettings;

  /// Gmail連携メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'Gmail連携'**
  String get gmailIntegration;

  /// リセットメニュー項目
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

  /// リンク・タスク画面の説明
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

  /// キャンセルボタン
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// 設定をリセットボタン
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

  /// 保存ボタン
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

  /// リンク数表示
  ///
  /// In ja, this message translates to:
  /// **'{count}件のリンク'**
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

  /// 検索結果なしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'検索結果がありません'**
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

  /// タイプフィルターのラベル
  ///
  /// In ja, this message translates to:
  /// **'タイプ'**
  String get type;

  /// すべてのタイプ
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

  /// 新規タスクダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'新しいタスク'**
  String get newTask;

  /// 一括選択モードメニュー項目
  ///
  /// In ja, this message translates to:
  /// **'一括選択モード'**
  String get bulkSelectMode;

  /// CSV出力メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'CSV出力'**
  String get csvExport;

  /// スケジュール一覧メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'スケジュール一覧'**
  String get scheduleList;

  /// グループ化メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'グループ化'**
  String get grouping;

  /// テンプレートから作成ショートカット説明
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

  /// メモラベル
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get memoLabel;

  /// 全選択ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'全選択'**
  String get selectAll;

  /// 全解除ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'全解除'**
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

  /// なしオプション
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
  /// **'サブタスク: {total}個\n完了: {completed}個'**
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

  /// リンクを追加ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'リンクを追加'**
  String get addLink;

  /// リンクを編集ツールチップ
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

  /// コピーメニュー項目
  ///
  /// In ja, this message translates to:
  /// **'コピー'**
  String get copy;

  /// タスク同期メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'このタスクを同期'**
  String get syncTask;

  /// 削除メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// 優先度：高
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

  /// 優先度：緊急
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

  /// キャンセルステータス
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancelled;

  /// キャンセルステータス（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'止'**
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

  /// 表形式メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'表形式（複数列）'**
  String get tableFormat;

  /// 1セル形式メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'1セル形式（列挙）'**
  String get oneCellFormat;

  /// アクションメニューツールチップ
  ///
  /// In ja, this message translates to:
  /// **'アクション'**
  String get action;

  /// 今日の期限日
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

  /// 本文ラベル
  ///
  /// In ja, this message translates to:
  /// **'本文'**
  String get body;

  /// 依頼先への説明ラベル
  ///
  /// In ja, this message translates to:
  /// **'依頼先への説明'**
  String get descriptionForRequestor;

  /// タグラベル
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

  /// 更新ボタン
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

  /// 説明ラベル
  ///
  /// In ja, this message translates to:
  /// **'説明'**
  String get description;

  /// 追加ボタン
  ///
  /// In ja, this message translates to:
  /// **'追加'**
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

  /// 期限日選択プレースホルダー
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

  /// エクスポートボタン
  ///
  /// In ja, this message translates to:
  /// **'エクスポート'**
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

  /// グループ名を編集ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'グループ名を編集'**
  String get editGroupName;

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

  /// 新しいタスクを作成ショートカット説明
  ///
  /// In ja, this message translates to:
  /// **'新しいタスクを作成'**
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

  /// タスクラベル
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
  /// **'進'**
  String get inProgressShort;

  /// 完了ラベル（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'完'**
  String get completedShort;

  /// 未着手ラベル（短縮版）
  ///
  /// In ja, this message translates to:
  /// **'未'**
  String get notStartedShort;

  /// 進行中ラベル（短縮版2）
  ///
  /// In ja, this message translates to:
  /// **'中'**
  String get inProgressShort2;

  /// 説明文ラベル
  ///
  /// In ja, this message translates to:
  /// **'説明文'**
  String get descriptionText;

  /// 依頼先ラベル
  ///
  /// In ja, this message translates to:
  /// **'依頼先'**
  String get requester;

  /// 通常検索モードラベル
  ///
  /// In ja, this message translates to:
  /// **'通常検索モード'**
  String get normalSearchMode;

  /// 正規表現検索モードラベル
  ///
  /// In ja, this message translates to:
  /// **'正規表現検索モード'**
  String get regexSearchMode;
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
