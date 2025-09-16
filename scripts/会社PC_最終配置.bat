@echo off
chcp 65001 >nul
echo ========================================
echo 会社PC用 PowerShellスクリプト配置ツール
echo ========================================
echo.

echo 注意: このツールは管理者権限を必要としません
echo ユーザーレベルの権限で実行されます
echo.

REM 配置先ディレクトリを作成
set "TARGET_DIR=C:\Apps"
echo 配置先ディレクトリ: %TARGET_DIR%

if not exist "%TARGET_DIR%" (
    echo ディレクトリを作成中: %TARGET_DIR%
    mkdir "%TARGET_DIR%"
    if errorlevel 1 (
        echo エラー: ディレクトリの作成に失敗しました
        echo 手動で %TARGET_DIR% を作成してください
        pause
        exit /b 1
    )
) else (
    echo ディレクトリが既に存在します: %TARGET_DIR%
)

echo.
echo PowerShellスクリプトを配置中...

REM スクリプトファイルをコピー
copy "compose_mail.ps1" "%TARGET_DIR%\" >nul
if errorlevel 1 (
    echo エラー: compose_mail.ps1 のコピーに失敗しました
    pause
    exit /b 1
) else (
    echo ✓ compose_mail.ps1 を配置しました
)

copy "find_sent.ps1" "%TARGET_DIR%\" >nul
if errorlevel 1 (
    echo エラー: find_sent.ps1 のコピーに失敗しました
    pause
    exit /b 1
) else (
    echo ✓ find_sent.ps1 を配置しました
)

copy "company_outlook_test.ps1" "%TARGET_DIR%\" >nul
if errorlevel 1 (
    echo エラー: company_outlook_test.ps1 のコピーに失敗しました
    pause
    exit /b 1
) else (
    echo ✓ company_outlook_test.ps1 を配置しました
)

copy "company_task_search.ps1" "%TARGET_DIR%\" >nul
if errorlevel 1 (
    echo エラー: company_task_search.ps1 のコピーに失敗しました
    pause
    exit /b 1
) else (
    echo ✓ company_task_search.ps1 を配置しました
)

echo.
echo ========================================
echo 配置完了
echo ========================================
echo.
echo 配置されたファイル:
echo - %TARGET_DIR%\compose_mail.ps1
echo - %TARGET_DIR%\find_sent.ps1
echo - %TARGET_DIR%\company_outlook_test.ps1
echo - %TARGET_DIR%\company_task_search.ps1
echo.
echo 使用方法:
echo 1. Outlook を起動してください
echo 2. アプリケーションでOutlook連携をテストしてください
echo.
echo 注意事項:
echo - 管理者権限は必要ありません
echo - すべてのファイルは %TARGET_DIR% に配置されています
echo - ファイル名は正確に一致している必要があります
echo - 実行ポリシーが制限されている場合は手動で変更してください
echo.
echo 実行ポリシーの変更方法:
echo Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
echo.
pause