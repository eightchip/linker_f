# Outlook接続テストスクリプト
# 会社PC用の安全なOutlook接続確認

Write-Host "=== Outlook接続テスト ===" -ForegroundColor Cyan
Write-Host ""

# 1. PowerShell実行ポリシー確認
Write-Host "1. PowerShell実行ポリシー:" -ForegroundColor Yellow
$executionPolicy = Get-ExecutionPolicy
Write-Host "   現在の実行ポリシー: $executionPolicy" -ForegroundColor White
if ($executionPolicy -eq "Restricted") {
    Write-Host "   ⚠️  実行ポリシーが制限されています。" -ForegroundColor Yellow
    Write-Host "   解決方法: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
} else {
    Write-Host "   ✅ 実行ポリシーは適切です。" -ForegroundColor Green
}
Write-Host ""

# 2. Outlook プロセスの確認
Write-Host "2. Outlook プロセス確認:" -ForegroundColor Yellow
$outlookProcesses = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
if ($outlookProcesses) {
    Write-Host "   ✅ Outlook が起動しています。" -ForegroundColor Green
    Write-Host "   プロセス数: $($outlookProcesses.Count)" -ForegroundColor White
} else {
    Write-Host "   ⚠️  Outlook が起動していません。" -ForegroundColor Yellow
    Write-Host "   推奨: Outlook を起動してからテストしてください。" -ForegroundColor White
}
Write-Host ""

# 3. Outlook COM オブジェクトテスト
Write-Host "3. Outlook COM オブジェクトテスト:" -ForegroundColor Yellow
try {
    Write-Host "   Outlook COM オブジェクトを作成中..." -ForegroundColor White
    $outlook = New-Object -ComObject Outlook.Application
    Write-Host "   ✅ Outlook COM オブジェクトの作成に成功しました。" -ForegroundColor Green
    
    Write-Host "   MAPI 名前空間にアクセス中..." -ForegroundColor White
    $namespace = $outlook.GetNamespace("MAPI")
    Write-Host "   ✅ MAPI 名前空間へのアクセスに成功しました。" -ForegroundColor Green
    
    Write-Host "   受信トレイフォルダにアクセス中..." -ForegroundColor White
    $inbox = $namespace.GetDefaultFolder(6)  # 6 = olFolderInbox
    Write-Host "   ✅ 受信トレイフォルダへのアクセスに成功しました。" -ForegroundColor Green
    
    Write-Host "   送信済みフォルダにアクセス中..." -ForegroundColor White
    $sentItems = $namespace.GetDefaultFolder(5)  # 5 = olFolderSentMail
    Write-Host "   ✅ 送信済みフォルダへのアクセスに成功しました。" -ForegroundColor Green
    
    Write-Host "   COM オブジェクトを解放中..." -ForegroundColor White
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
    Write-Host "   ✅ COM オブジェクトの解放に成功しました。" -ForegroundColor Green
    
} catch {
    Write-Host "   ❌ Outlook COM オブジェクトテストに失敗しました。" -ForegroundColor Red
    Write-Host "   エラー: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Message -like "*COM*") {
        Write-Host "   解決方法: Outlook を起動してからテストしてください。" -ForegroundColor White
    } elseif ($_.Exception.Message -like "*権限*" -or $_.Exception.Message -like "*permission*") {
        Write-Host "   解決方法: 管理者権限でPowerShellを実行してください。" -ForegroundColor White
    } else {
        Write-Host "   解決方法: Outlook が正しくインストールされているか確認してください。" -ForegroundColor White
    }
}
Write-Host ""

# 4. メールアカウント確認
Write-Host "4. メールアカウント確認:" -ForegroundColor Yellow
try {
    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $accounts = $namespace.Accounts
    
    if ($accounts.Count -gt 0) {
        Write-Host "   ✅ メールアカウントが設定されています。" -ForegroundColor Green
        Write-Host "   アカウント数: $($accounts.Count)" -ForegroundColor White
        for ($i = 0; $i -lt $accounts.Count; $i++) {
            $account = $accounts.Item($i + 1)
            Write-Host "   - $($account.DisplayName) ($($account.SmtpAddress))" -ForegroundColor White
        }
    } else {
        Write-Host "   ⚠️  メールアカウントが設定されていません。" -ForegroundColor Yellow
        Write-Host "   解決方法: Outlook でメールアカウントを設定してください。" -ForegroundColor White
    }
    
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
} catch {
    Write-Host "   ❌ メールアカウント確認に失敗しました。" -ForegroundColor Red
    Write-Host "   エラー: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# 5. 送信済みメール確認
Write-Host "5. 送信済みメール確認:" -ForegroundColor Yellow
try {
    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $sentItems = $namespace.GetDefaultFolder(5)
    $mailCount = $sentItems.Items.Count
    
    Write-Host "   送信済みメール数: $mailCount" -ForegroundColor White
    if ($mailCount -gt 0) {
        Write-Host "   ✅ 送信済みメールがあります。" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  送信済みメールがありません。" -ForegroundColor Yellow
        Write-Host "   推奨: テスト用のメールを送信してください。" -ForegroundColor White
    }
    
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
} catch {
    Write-Host "   ❌ 送信済みメール確認に失敗しました。" -ForegroundColor Red
    Write-Host "   エラー: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# 6. 推奨事項
Write-Host "6. 推奨事項:" -ForegroundColor Yellow
Write-Host "   - Outlook を起動してからテストを実行してください" -ForegroundColor White
Write-Host "   - メールアカウントが正しく設定されているか確認してください" -ForegroundColor White
Write-Host "   - テスト用のメールを送信してから検索テストを実行してください" -ForegroundColor White
Write-Host "   - 会社PCの場合は、セキュリティポリシーを確認してください" -ForegroundColor White
Write-Host ""

Write-Host "=== テスト完了 ===" -ForegroundColor Green
Write-Host "すべてのテストが成功した場合は、アプリケーションでOutlook連携をテストしてください。" -ForegroundColor White
