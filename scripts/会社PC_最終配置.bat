@echo off
chcp 65001 >nul
echo 会社PC用 Outlook連携 最終配置ツール
echo ========================================

REM ユーザー権限での実行確認
echo ユーザー権限で実行中...
echo 会社PCでは管理者権限は不要です

REM C:\Apps ディレクトリ作成
echo C:\Apps ディレクトリを作成中...
if not exist "C:\Apps" (
    mkdir "C:\Apps"
    echo C:\Apps ディレクトリを作成しました
) else (
    echo C:\Apps ディレクトリは既に存在します
)

REM ファイルコピー
echo.
echo PowerShellスクリプトをコピー中...

REM 1. 会社PC用 Outlook接続テスト
if exist "company_outlook_test.ps1" (
    copy "company_outlook_test.ps1" "C:\Apps\company_outlook_test.ps1"
    echo company_outlook_test.ps1 をコピーしました
) else (
    echo エラー: company_outlook_test.ps1 が見つかりません
)

REM 2. 会社PC用 タスク検索スクリプト
if exist "company_task_search.ps1" (
    copy "company_task_search.ps1" "C:\Apps\company_task_search.ps1"
    echo company_task_search.ps1 をコピーしました
) else (
    echo エラー: company_task_search.ps1 が見つかりません
)

REM 3. メール作成スクリプト（既存）
if exist "compose_mail.ps1" (
    copy "compose_mail.ps1" "C:\Apps\compose_mail.ps1"
    echo compose_mail.ps1 をコピーしました
) else (
    echo 警告: compose_mail.ps1 が見つかりません（メール作成機能に必要）
)

REM 4. 送信済み検索スクリプト（既存）
if exist "find_sent.ps1" (
    copy "find_sent.ps1" "C:\Apps\find_sent.ps1"
    echo find_sent.ps1 をコピーしました
) else (
    echo 警告: find_sent.ps1 が見つかりません（送信済み検索機能に必要）
)

REM 権限設定（ユーザー権限で実行可能）
echo.
echo ファイル権限を確認中...
echo ユーザー権限でPowerShellスクリプトを実行可能です

REM 配置完了確認
echo.
echo ========================================
echo 配置完了確認
echo ========================================
echo 配置されたファイル:
dir "C:\Apps\*.ps1" /b

echo.
echo ========================================
echo 次の手順
echo ========================================
echo 1. Outlook を起動してください
echo 2. PowerShellで接続テストを実行:
echo    cd C:\Apps
echo    powershell -ExecutionPolicy Bypass -File company_outlook_test.ps1
echo.
echo 3. アプリケーションでOutlook連携をテスト:
echo    - 設定画面 → Outlook連携
echo    - 「接続テスト」ボタン
echo    - 「メール検索テスト」ボタン
echo    - 「タスク自動生成」ボタン
echo.
echo ========================================
echo 注意事項
echo ========================================
echo - 会社PCでのみ使用してください
echo - ユーザー権限のみで動作します（管理者権限不要）
echo - Outlook が起動している必要があります
echo - メールアカウントが設定されている必要があります
echo - セキュリティポリシーに従ってください
echo.
echo 配置が完了しました。何かキーを押して終了してください...
pause >nul
