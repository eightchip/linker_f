# 会社PC用安全版: タスク割り当てメール検索スクリプト
# 最小限の権限で動作するように設計

param(
    [string]$OutputFile = "task_assignments.json"
)

# エラーハンドリングを強化
$ErrorActionPreference = "Stop"

try {
    # Outlookが起動しているかチェック
    $outlookProcess = Get-Process -Name "outlook" -ErrorAction SilentlyContinue
    if (-not $outlookProcess) {
        Write-Warning "Outlookが起動していません。手動でOutlookを起動してください。"
        exit 1
    }
    
    # COM オブジェクトの作成を試行
    try {
        $outlook = New-Object -ComObject Outlook.Application
    } catch {
        Write-Error "Outlook COM オブジェクトの作成に失敗しました。Outlookが正しくインストールされているか確認してください。"
        exit 1
    }
    
    # 名前空間とフォルダの取得
    $namespace = $outlook.GetNamespace("MAPI")
    $inbox = $namespace.GetDefaultFolder(6) # olFolderInbox
    
    # 過去24時間のメールを検索
    $filter = "[ReceivedTime] >= '" + (Get-Date).AddDays(-1).ToString("dd/MM/yyyy HH:mm") + "'"
    $items = $inbox.Items.Restrict($filter)
    
    $taskAssignments = @()
    
    foreach ($item in $items) {
        # 件名と本文の取得
        $subject = $item.Subject
        $body = $item.Body
        
        # キーワードチェック（より安全な方法）
        $keywords = @("依頼", "タスク", "お願い", "業務", "作業", "手伝い")
        $hasKeyword = $false
        
        foreach ($keyword in $keywords) {
            if ($subject -like "*$keyword*" -or $body -like "*$keyword*") {
                $hasKeyword = $true
                break
            }
        }
        
        if ($hasKeyword) {
            # 期日を抽出
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
            if ($subject -like "*緊急*" -or $subject -like "*urgent*" -or $subject -like "*高*" -or 
                $body -like "*緊急*" -or $body -like "*urgent*" -or $body -like "*高*") {
                $priority = "high"
            } elseif ($subject -like "*低*" -or $subject -like "*low*" -or 
                     $body -like "*低*" -or $body -like "*low*") {
                $priority = "low"
            }
            
            # タスクタイトルを抽出
            $taskTitle = $subject
            if ($taskTitle -match "【(.+?)】") {
                $taskTitle = $matches[1]
            }
            
            # タスク説明を抽出（長さ制限）
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
    
    # 結果をファイルに出力
    $taskAssignments | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutputFile -Encoding UTF8
    
    Write-Host "検索完了: $($taskAssignments.Count) 件のタスク割り当てメールを発見"
    
} catch {
    Write-Error "エラーが発生しました: $($_.Exception.Message)"
    # エラーの場合は空の配列を返す
    @() | ConvertTo-Json | Out-File -FilePath $OutputFile -Encoding UTF8
    exit 1
} finally {
    # COM オブジェクトを安全に解放
    if ($outlook) {
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
        } catch {
            # 解放に失敗してもエラーにしない
        }
    }
}
