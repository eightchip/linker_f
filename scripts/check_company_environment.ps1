# 会社環境での実行権限確認スクリプト
# このスクリプトを実行して、会社環境での制限事項を確認してください

Write-Host "=== 会社環境での実行権限確認 ===" -ForegroundColor Green
Write-Host ""

# 1. 実行ポリシーの確認
Write-Host "1. PowerShell実行ポリシー:" -ForegroundColor Yellow
try {
    $executionPolicy = Get-ExecutionPolicy
    Write-Host "   現在の実行ポリシー: $executionPolicy" -ForegroundColor White
    
    if ($executionPolicy -eq "Restricted") {
        Write-Host "   ⚠️  制限された実行ポリシーです。スクリプト実行が制限されています。" -ForegroundColor Red
        Write-Host "   解決方法: 管理者に相談するか、一時的に実行ポリシーを変更してください。" -ForegroundColor Yellow
    } elseif ($executionPolicy -eq "RemoteSigned") {
        Write-Host "   ✅ リモート署名済みスクリプトのみ実行可能です。" -ForegroundColor Green
    } elseif ($executionPolicy -eq "Unrestricted") {
        Write-Host "   ✅ すべてのスクリプトが実行可能です。" -ForegroundColor Green
    }
} catch {
    Write-Host "   ❌ 実行ポリシーの確認に失敗しました。" -ForegroundColor Red
}
Write-Host ""

# 2. 管理者権限の確認
Write-Host "2. 管理者権限:" -ForegroundColor Yellow
try {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if ($isAdmin) {
        Write-Host "   ✅ 管理者権限で実行中です。" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  ユーザー権限で実行中です。" -ForegroundColor Yellow
        Write-Host "   会社環境では通常、ユーザー権限での実行が推奨されます。" -ForegroundColor White
    }
} catch {
    Write-Host "   ❌ 権限確認に失敗しました。" -ForegroundColor Red
}
Write-Host ""

# 3. Outlookの確認
Write-Host "3. Outlook環境:" -ForegroundColor Yellow
try {
    $outlookProcess = Get-Process -Name "outlook" -ErrorAction SilentlyContinue
    if ($outlookProcess) {
        Write-Host "   ✅ Outlookが起動しています。" -ForegroundColor Green
        Write-Host "   プロセスID: $($outlookProcess.Id)" -ForegroundColor White
    } else {
        Write-Host "   ⚠️  Outlookが起動していません。" -ForegroundColor Yellow
        Write-Host "   タスク割り当てメール検索にはOutlookの起動が必要です。" -ForegroundColor White
    }
} catch {
    Write-Host "   ❌ Outlookプロセスの確認に失敗しました。" -ForegroundColor Red
}
Write-Host ""

# 4. COM オブジェクトの確認
Write-Host "4. COM オブジェクトアクセス:" -ForegroundColor Yellow
try {
    $outlook = New-Object -ComObject Outlook.Application
    Write-Host "   ✅ Outlook COM オブジェクトにアクセス可能です。" -ForegroundColor Green
    
    # 名前空間の確認
    $namespace = $outlook.GetNamespace("MAPI")
    Write-Host "   ✅ MAPI名前空間にアクセス可能です。" -ForegroundColor Green
    
    # 受信トレイの確認
    $inbox = $namespace.GetDefaultFolder(6)
    Write-Host "   ✅ 受信トレイにアクセス可能です。" -ForegroundColor Green
    
    # COM オブジェクトを解放
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
    Write-Host "   ✅ COM オブジェクトを正常に解放しました。" -ForegroundColor Green
    
} catch {
    Write-Host "   ❌ COM オブジェクトアクセスに失敗しました。" -ForegroundColor Red
    Write-Host "   エラー: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   考えられる原因:" -ForegroundColor Yellow
    Write-Host "   - Outlookが正しくインストールされていない" -ForegroundColor White
    Write-Host "   - 会社のセキュリティポリシーでCOM オブジェクトが制限されている" -ForegroundColor White
    Write-Host "   - Outlookが完全に起動していない" -ForegroundColor White
}
Write-Host ""

# 5. ファイルシステム権限の確認
Write-Host "5. ファイルシステム権限:" -ForegroundColor Yellow
try {
    $currentPath = Get-Location
    $testFile = Join-Path $currentPath "test_write_permission.tmp"
    
    "test" | Out-File -FilePath $testFile -Encoding UTF8
    if (Test-Path $testFile) {
        Remove-Item $testFile -Force
        Write-Host "   ✅ 現在のディレクトリに書き込み権限があります。" -ForegroundColor Green
    } else {
        Write-Host "   ❌ 現在のディレクトリに書き込み権限がありません。" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ ファイルシステム権限の確認に失敗しました。" -ForegroundColor Red
}
Write-Host ""

# 6. ネットワークアクセスの確認
Write-Host "6. ネットワークアクセス:" -ForegroundColor Yellow
try {
    $networkAccess = Test-NetConnection -ComputerName "google.com" -Port 443 -InformationLevel Quiet
    if ($networkAccess) {
        Write-Host "   ✅ インターネットアクセス可能です。" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  インターネットアクセスが制限されている可能性があります。" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️  ネットワークアクセスの確認に失敗しました。" -ForegroundColor Yellow
}
Write-Host ""

# 7. 会社環境での推奨事項
Write-Host "7. 会社環境での推奨事項:" -ForegroundColor Yellow
Write-Host "   - 管理者権限は不要です（ユーザー権限で十分）" -ForegroundColor White
Write-Host "   - 実行ポリシーが制限されている場合は、管理者に相談してください" -ForegroundColor White
Write-Host "   - 機密情報の取り扱いに注意してください" -ForegroundColor White
Write-Host "   - 会社のセキュリティポリシーに従ってください" -ForegroundColor White
Write-Host ""

Write-Host "=== 確認完了 ===" -ForegroundColor Green
Write-Host "問題がない場合は、find_task_assignments_company_safe.ps1 を実行してください。" -ForegroundColor White
