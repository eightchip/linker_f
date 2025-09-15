Param(
    [string]$To = "",
    [string]$Cc = "",
    [string]$Bcc = "",
    [Parameter(Mandatory = $true)][string]$Subject,
    [Parameter(Mandatory = $true)][string]$HtmlPath
)

try {
    # HTMLファイルの内容を読み込み
    $html = Get-Content -Raw -Path $HtmlPath -Encoding UTF8

    # Outlookアプリケーションオブジェクトを作成
    $ol = New-Object -ComObject Outlook.Application
    $mail = $ol.CreateItem(0)  # olMailItem = 0

    # 宛先を設定
    if ($To) { $mail.To = $To }
    if ($Cc) { $mail.CC = $Cc }
    if ($Bcc) { $mail.BCC = $Bcc }

    # 件名と本文を設定
    $mail.Subject = $Subject
    $mail.HTMLBody = $html

    # メール作成画面を表示
    $mail.Display()

    Write-Host "Outlook メール作成画面を開きました"
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Outlook メール作成エラー: $errorMessage"
    
    # より詳細なエラー情報を出力
    if ($_.Exception.InnerException) {
        Write-Error "詳細エラー: $($_.Exception.InnerException.Message)"
    }
    
    # Outlookがインストールされていない場合の特別なメッセージ
    if ($errorMessage -like "*COM*" -or $errorMessage -like "*Outlook*") {
        Write-Error "Outlookがインストールされていないか、正しく設定されていません。"
        Write-Error "会社PCでOutlookを使用してください。"
    }
    
    exit 1
}
