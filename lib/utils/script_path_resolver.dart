import 'dart:io';
import 'package:flutter/foundation.dart';

/// PowerShellスクリプトのパスを解決するユーティリティ
/// ポータブル版対応: 実行ファイルと同じディレクトリのAppsフォルダを優先
/// 後方互換性: %APPDATA%\Appsフォルダにも対応
class ScriptPathResolver {
  /// PowerShellスクリプトファイルのパスを取得
  /// 
  /// 検索順序:
  /// 1. 実行ファイルと同じディレクトリのAppsフォルダ
  /// 2. %APPDATA%\Appsフォルダ（後方互換性）
  /// 
  /// [scriptName] スクリプトファイル名（例: 'compose_mail.ps1'）
  /// 戻り値: スクリプトファイルのパス（見つからない場合はnull）
  static Future<String?> resolveScriptPath(String scriptName) async {
    // 1. 実行ファイルと同じディレクトリのAppsフォルダを確認（ポータブル版対応）
    try {
      final executablePath = Platform.resolvedExecutable;
      final executableDir = File(executablePath).parent.path;
      final portableAppsPath = '$executableDir\\Apps\\$scriptName';
      final portableAppsFile = File(portableAppsPath);
      
      if (await portableAppsFile.exists()) {
        if (kDebugMode) {
          print('📁 [ScriptPathResolver] ポータブル版のスクリプトを使用: $portableAppsPath');
        }
        return portableAppsPath;
      }
    } catch (e) {
      // 実行ファイルのパス取得に失敗した場合は次へ進む
      if (kDebugMode) {
        print('⚠️ [ScriptPathResolver] 実行ファイルパスの取得に失敗: $e');
      }
    }
    
    // 2. %APPDATA%\Appsフォルダを確認（後方互換性）
    try {
      final appdataPath = Platform.environment['APPDATA'] ?? 
        'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Roaming';
      final appdataAppsPath = '$appdataPath\\Apps\\$scriptName';
      final appdataAppsFile = File(appdataAppsPath);
      
      if (await appdataAppsFile.exists()) {
        if (kDebugMode) {
          print('📁 [ScriptPathResolver] APPDATA版のスクリプトを使用: $appdataAppsPath');
        }
        return appdataAppsPath;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ScriptPathResolver] APPDATAパスの取得に失敗: $e');
      }
    }
    
    // スクリプトが見つからない場合
    if (kDebugMode) {
      print('❌ [ScriptPathResolver] スクリプトが見つかりません: $scriptName');
    }
    return null;
  }
  
  /// スクリプトファイルの存在確認
  /// [scriptName] スクリプトファイル名
  /// 戻り値: スクリプトが存在する場合true
  static Future<bool> scriptExists(String scriptName) async {
    final path = await resolveScriptPath(scriptName);
    return path != null;
  }
  
  /// スクリプトが見つからない場合のエラーメッセージを生成
  /// [scriptName] スクリプトファイル名
  /// 戻り値: エラーメッセージ
  static String getErrorMessage(String scriptName) {
    final executablePath = Platform.resolvedExecutable;
    final executableDir = File(executablePath).parent.path;
    final appdataPath = Platform.environment['APPDATA'] ?? 
      'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Roaming';
    
    return '''PowerShellスクリプトが見つかりません: $scriptName

以下のいずれかの場所に配置してください:
1. ポータブル版: $executableDir\\Apps\\$scriptName
2. インストール版: $appdataPath\\Apps\\$scriptName

インストーラーを使用するか、手動で配置してください。''';
  }
}

