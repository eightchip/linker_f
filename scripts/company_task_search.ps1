# 会社PC用超安全版: タスク割り当てメール検索スクリプト
# 構文エラーを修正した最終版

param(
    [string]$TestConnection = $false
)

# 機密情報マスキング関数
function Mask-SensitiveInfo {
    param([string]$text)
    
    if ([string]::IsNullOrEmpty($text)) {
        return $text
    }
    
    # クレジットカード番号をマスク
    $text = $text -replace '\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b', '****-****-****-****'
    
    # 社会保障番号をマスク
    $text = $text -replace '\b\d{3}-\d{2}-\d{4}\b', '***-**-****'
    
    # メールアドレスをマスク（ドメイン部分は保持）
    $text = $text -replace '\b[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\.[A-Z|a-z]{2,})\b', '***@$1'
    
    return $text
}

# タスク優先度をマッピング
function Get-TaskPriority {
    param([string]$text)
    
    $text = $text.ToLower()
    if ($text -like "*緊急*" -or $text -like "*urgent*") {
        return "urgent"
    } elseif ($text -like "*高*" -or $text -like "*high*") {
        return "high"
    } elseif ($text -like "*中*" -or $text -like "*medium*") {
        return "medium"
    } elseif ($text -like "*低*" -or $text -like "*low*") {
        return "low"
    } else {
        return "medium"
    }
}

# 日付を抽出
function Extract-Date {
    param([string]$text)
    
    # 日本語の日付パターン
    if ($text -match "(\d{4})年(\d{1,2})月(\d{1,2})日") {
        $year = $matches[1]
        $month = $matches[2].PadLeft(2, '0')
        $day = $matches[3].PadLeft(2, '0')
        return "$year-$month-$day"
    }
    
    # スラッシュ区切りの日付
    if ($text -match "(\d{1,2})/(\d{1,2})/(\d{4})") {
        $month = $matches[1].PadLeft(2, '0')
        $day = $matches[2].PadLeft(2, '0')
        $year = $matches[3]
        return "$year-$month-$day"
    }
    
    # ハイフン区切りの日付
    if ($text -match "(\d{4})-(\d{1,2})-(\d{1,2})") {
        return $matches[0]
    }
    
    return $null
}

try {
    Write-Host "会社PC用 Outlook タスク検索を開始します..." -ForegroundColor Cyan
    
    # Outlook が起動しているか確認
    $outlookProcesses = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
    if (-not $outlookProcesses) {
        Write-Host "エラー: Outlook が起動していません" -ForegroundColor Red
        Write-Host "解決方法: Outlook を起動してからスクリプトを実行してください" -ForegroundColor Yellow
        exit 1
    }
    
    # Outlook COM オブジェクトを作成
    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $inbox = $namespace.GetDefaultFolder(6)  # 受信トレイ
    
    if ($TestConnection -eq "true") {
        Write-Host "接続テスト成功: Outlook に正常に接続できました" -ForegroundColor Green
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
        exit 0
    }
    
    # 過去7日間のメールを検索（期間を拡張）
    $searchDate = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
    $filter = "[ReceivedTime] >= '$searchDate'"
    $emails = $inbox.Items.Restrict($filter)
    
    Write-Host "検索期間: $searchDate 以降" -ForegroundColor Yellow
    Write-Host "検索対象メール数: $($emails.Count)" -ForegroundColor Yellow
    
    $taskAssignments = @()
    $keywordPatterns = @(
        "*業務依頼*", "*タスク依頼*", "*お願い*", "*依頼*",
        "*task*", "*request*", "*assignment*"
    )
    
    $processedCount = 0
    foreach ($email in $emails) {
        if ($email.Class -eq 43) {  # olMail
            $processedCount++
            $subject = $email.Subject
            $body = $email.Body
            $senderName = $email.SenderName
            $senderEmail = $email.SenderEmailAddress
            $receivedTime = $email.ReceivedTime.ToString("yyyy-MM-dd HH:mm:ss")
            
            Write-Host "処理中 ($processedCount): $subject" -ForegroundColor Gray
            
            # キーワードマッチング
            $isTaskEmail = $false
            $matchedPattern = ""
            foreach ($pattern in $keywordPatterns) {
                if ($subject -like $pattern -or $body -like $pattern) {
                    $isTaskEmail = $true
                    $matchedPattern = $pattern
                    break
                }
            }
            
            if ($isTaskEmail) {
                Write-Host "マッチ: $subject (パターン: $matchedPattern)" -ForegroundColor Green
            }
            
            if ($isTaskEmail) {
                # 機密情報をマスク
                $maskedBody = Mask-SensitiveInfo $body
                $maskedSubject = Mask-SensitiveInfo $subject
                
                # タスク情報を抽出
                $priority = Get-TaskPriority $body
                $dueDate = Extract-Date $body
                
                if (-not $dueDate) {
                    $dueDate = (Get-Date).AddDays(7).ToString("yyyy-MM-dd")
                }
                
                $taskAssignment = @{
                    emailId = $email.EntryID
                    emailSubject = $maskedSubject
                    emailBody = $maskedBody
                    requesterEmail = $senderEmail
                    requesterName = $senderName
                    taskTitle = $maskedSubject
                    taskDescription = $maskedBody
                    dueDate = $dueDate
                    priority = $priority
                    receivedAt = $receivedTime
                    source = "Outlook"
                }
                
                $taskAssignments += $taskAssignment
            }
        }
    }
    
    # JSON形式で出力
    $result = @{
        success = $true
        count = $taskAssignments.Count
        tasks = $taskAssignments
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $jsonResult = $result | ConvertTo-Json -Depth 3
    Write-Host $jsonResult
    
    # COM オブジェクトを解放
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
    
} catch {
    Write-Host "エラー: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "詳細: $($_.Exception.StackTrace)" -ForegroundColor Red
    
    $errorResult = @{
        success = $false
        error = $_.Exception.Message
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $jsonError = $errorResult | ConvertTo-Json
    Write-Host $jsonError
    
    exit 1
}