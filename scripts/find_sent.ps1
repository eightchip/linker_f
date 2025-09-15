Param(
    [Parameter(Mandatory = $true)][string]$Token
)

try {
    # Outlookアプリケーションオブジェクトを作成
    $ol = New-Object -ComObject Outlook.Application
    $ns = $ol.GetNamespace("MAPI")
    
    # 送信済みフォルダを取得
    $sent = $ns.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderSentMail)
    $items = $sent.Items
    
    # 送信日時でソート（新しい順）
    $items.Sort("[SentOn]", $true)
    
    # 件名にトークンを含むメールを検索
    $searchFilter = "[Subject] Like '%$Token%'"
    $matches = $items.Restrict($searchFilter)
    
    if ($matches.Count -gt 0) {
        # 最初のマッチしたメールを表示
        $matches.GetFirst().Display()
        Write-Host "送信済みメールが見つかりました: $Token"
    }
    else {
        # メールが見つからない場合のメッセージ
        [System.Windows.Forms.MessageBox]::Show(
            "送信済みに見つかりませんでした：$Token",
            "Outlook検索",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        Write-Host "送信済みメールが見つかりませんでした: $Token"
    }
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Outlook 検索エラー: $errorMessage"
    
    # より詳細なエラー情報を出力
    if ($_.Exception.InnerException) {
        Write-Error "詳細エラー: $($_.Exception.InnerException.Message)"
    }
    
    # Outlookがインストールされていない場合の特別なメッセージ
    if ($errorMessage -like "*COM*" -or $errorMessage -like "*Outlook*") {
        Write-Error "Outlookがインストールされていないか、正しく設定されていません。"
        Write-Error "会社PCでOutlookを使用してください。"
    }
    
    [System.Windows.Forms.MessageBox]::Show(
        "検索中にエラーが発生しました：$errorMessage",
        "Outlook検索エラー",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}
