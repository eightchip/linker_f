# タスク割り当てメールを検索するPowerShellスクリプト

try {
    # Outlookアプリケーションを起動（より安全な方法）
    try {
        $outlook = New-Object -ComObject Outlook.Application
    } catch {
        # 別の方法でOutlookを起動
        Start-Process "outlook.exe" -WindowStyle Hidden
        Start-Sleep -Seconds 3
        $outlook = New-Object -ComObject Outlook.Application
    }
    
    $namespace = $outlook.GetNamespace("MAPI")
    $inbox = $namespace.GetDefaultFolder(6) # olFolderInbox
    
    # 過去24時間のメールを検索
    $filter = "[ReceivedTime] >= '" + (Get-Date).AddDays(-1).ToString("dd/MM/yyyy HH:mm") + "'"
    $items = $inbox.Items.Restrict($filter)
    
    $taskAssignments = @()
    
    foreach ($item in $items) {
        # 件名に「依頼」「タスク」「お願い」などのキーワードが含まれているかチェック
        $subject = $item.Subject
        $body = $item.Body
        
        if ($subject -match "(依頼|タスク|お願い|業務|作業|手伝い)" -or 
            $body -match "(依頼|タスク|お願い|業務|作業|手伝い)") {
            
            # 期日を抽出（件名や本文から）
            $dueDate = $null
            if ($subject -match "(\d{1,2})/(\d{1,2})") {
                $month = [int]$matches[1]
                $day = [int]$matches[2]
                $currentYear = (Get-Date).Year
                try {
                    $dueDate = Get-Date -Year $currentYear -Month $month -Day $day
                } catch {
                    # 日付が無効な場合はスキップ
                }
            }
            
            # 優先度を判定
            $priority = "medium"
            if ($subject -match "(緊急|urgent|高)" -or $body -match "(緊急|urgent|高)") {
                $priority = "high"
            } elseif ($subject -match "(低|low)" -or $body -match "(低|low)") {
                $priority = "low"
            }
            
            # タスクタイトルを抽出（件名から）
            $taskTitle = $subject
            if ($taskTitle -match "【(.+?)】") {
                $taskTitle = $matches[1]
            }
            
            # タスク説明を抽出（本文から）
            $taskDescription = $body
            if ($taskDescription.Length -gt 500) {
                $taskDescription = $taskDescription.Substring(0, 500) + "..."
            }
            
            $assignment = @{
                emailId = $item.EntryID
                emailSubject = $subject
                emailBody = $body
                requesterEmail = $item.SenderEmailAddress
                requesterName = $item.SenderName
                taskTitle = $taskTitle
                taskDescription = $taskDescription
                dueDate = if ($dueDate) { $dueDate.ToString("yyyy-MM-ddTHH:mm:ss") } else { $null }
                priority = $priority
                receivedAt = $item.ReceivedTime.ToString("yyyy-MM-ddTHH:mm:ss")
            }
            
            $taskAssignments += $assignment
        }
    }
    
    # JSON形式で出力
    $taskAssignments | ConvertTo-Json -Depth 3
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "エラーが発生しました: $errorMessage"
    
    # より詳細なエラー情報を提供
    if ($errorMessage -like "*Class not registered*") {
        Write-Error "Outlook COM オブジェクトが登録されていません。Outlookを一度起動してから再試行してください。"
    } elseif ($errorMessage -like "*80040154*") {
        Write-Error "Outlookの初期化に失敗しました。Outlookが正しくインストールされているか確認してください。"
    }
    
    # エラーの場合は空の配列を返す
    @() | ConvertTo-Json
} finally {
    # COM オブジェクトを安全に解放
    try {
        if ($outlook) {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
        }
    } catch {
        # 解放時のエラーは無視
    }
}
