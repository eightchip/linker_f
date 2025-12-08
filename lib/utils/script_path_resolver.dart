import 'dart:io';
import 'package:flutter/foundation.dart';

/// PowerShellスクリプトのパスを解決するユーティリティ
/// Releaseフォルダ配下のAppsフォルダのみを対象とする
class ScriptPathResolver {
  /// PowerShellスクリプトファイルのパスを取得
  /// 
  /// 検索場所:
  /// - 実行ファイルと同じディレクトリのAppsフォルダ（Release/Apps）
  /// 
  /// [scriptName] スクリプトファイル名（例: 'compose_mail.ps1'）
  /// 戻り値: スクリプトファイルのパス（見つからない場合はnull）
  static Future<String?> resolveScriptPath(String scriptName) async {
    // 実行ファイルと同じディレクトリのAppsフォルダを確認（Release/Appsのみ）
    try {
      final executablePath = Platform.resolvedExecutable;
      final executableDir = File(executablePath).parent.path;
      final appsPath = '$executableDir\\Apps\\$scriptName';
      final appsFile = File(appsPath);
      
      if (await appsFile.exists()) {
        if (kDebugMode) {
          print('📁 [ScriptPathResolver] スクリプトを使用: $appsPath');
        }
        return appsPath;
      }
    } catch (e) {
      // 実行ファイルのパス取得に失敗した場合
      if (kDebugMode) {
        print('⚠️ [ScriptPathResolver] 実行ファイルパスの取得に失敗: $e');
      }
    }
    
    // スクリプトが見つからない場合
    if (kDebugMode) {
      print('❌ [ScriptPathResolver] スクリプトが見つかりません: $scriptName');
      print('   期待される場所: ${File(Platform.resolvedExecutable).parent.path}\\Apps\\$scriptName');
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
  
  /// スクリプトが見つからない場合のパス情報を取得
  /// [scriptName] スクリプトファイル名
  /// 戻り値: パス情報を含むマップ（portablePath）
  static Map<String, String> getScriptPaths(String scriptName) {
    final executablePath = Platform.resolvedExecutable;
    final executableDir = File(executablePath).parent.path;
    
    return {
      'portablePath': '$executableDir\\Apps\\$scriptName',
    };
  }

  /// スクリプトが見つからない場合のエラーメッセージを生成（非推奨: ローカライゼーション対応のためgetScriptPathsを使用）
  /// [scriptName] スクリプトファイル名
  /// 戻り値: エラーメッセージ
  @Deprecated('Use getScriptPaths and localize in UI layer')
  static String getErrorMessage(String scriptName) {
    final paths = getScriptPaths(scriptName);
    return '''PowerShellスクリプトが見つかりません: $scriptName

以下の場所に配置してください:
${paths['portablePath']}

手動で配置してください。''';
  }
}

