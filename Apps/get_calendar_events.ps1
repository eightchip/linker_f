Param(
    [Parameter(Mandatory = $true)][string]$StartDate,
    [Parameter(Mandatory = $true)][string]$EndDate
)

function Sanitize([string]$value) {
    if ([string]::IsNullOrEmpty($value)) { return "" }
    return ($value -replace "[\r\n\u0000]", " ").Trim()
}

$startDate = [DateTime]::Parse($StartDate)
$endDate = [DateTime]::Parse($EndDate)

$outlook = $null
$namespace = $null
$calendar = $null
$items = $null
$filteredItems = $null
$rawEvents = @()

try {
    # Outlook COMオブジェクトの作成
    $outlook = New-Object -ComObject Outlook.Application
    if ($null -eq $outlook) {
        Write-Error "Outlook COMオブジェクトの作成に失敗しました"
        @() | ConvertTo-Json
        exit 0
    }
    
    $namespace = $outlook.GetNamespace("MAPI")
    if ($null -eq $namespace) {
        Write-Error "MAPI名前空間の取得に失敗しました"
        @() | ConvertTo-Json
        exit 0
    }
    
    $calendar = $namespace.GetDefaultFolder(9)
    if ($null -eq $calendar) {
        Write-Error "カレンダーフォルダの取得に失敗しました"
        @() | ConvertTo-Json
        exit 0
    }
    
    $items = $calendar.Items
    if ($null -eq $items) {
        Write-Error "カレンダーアイテムの取得に失敗しました"
        @() | ConvertTo-Json
        exit 0
    }
    
    $items.IncludeRecurrences = $true
    $items.Sort("[Start]", $true)  # 開始日時でソート（昇順）
    
    # Restrictメソッドを使用して日付範囲でフィルタリング（より安全で効率的）
    $filter = "[Start] >= '" + $startDate.ToString("yyyy-MM-ddTHH:mm:ss") + "' AND [Start] <= '" + $endDate.ToString("yyyy-MM-ddTHH:mm:ss") + "'"
    try {
        $filteredItems = $items.Restrict($filter)
    } catch {
        # Restrictが失敗した場合は全アイテムを使用（後でフィルタリング）
        Write-Warning "Restrictメソッドが失敗しました。全アイテムを使用します: $($_.Exception.Message)"
        $filteredItems = $items
    }
    
    # フィルタリングされたアイテムを安全に列挙（foreachを使用）
    $processedCount = 0
    $maxItems = 10000  # 最大処理件数を制限（無限ループ防止）
    
    foreach ($item in $filteredItems) {
        if ($processedCount -ge $maxItems) {
            Write-Warning "最大処理件数（$maxItems件）に達しました。処理を中断します。"
            break
        }
        
        try {
            # 型チェック
            if (-not ($item -is [Microsoft.Office.Interop.Outlook.AppointmentItem])) { 
                continue 
            }
            
            # 日付範囲チェック（Restrictでフィルタリング済みだが、念のため再チェック）
            if ($null -eq $item.Start) { 
                continue 
            }
            
            $itemStart = $null
            try {
                $itemStart = [DateTime]$item.Start
                if ($itemStart -lt $startDate -or $itemStart -gt $endDate) { 
                    continue 
                }
            } catch {
                continue
            }
            
            # イベントデータを安全に取得
            $event = @{
                Subject = ""
                Start = ""
                End = ""
                Location = ""
                Body = ""
                EntryID = ""
                LastModificationTime = ""
                Organizer = ""
                IsMeeting = $false
                IsRecurring = $false
                IsOnlineMeeting = $false
            }
            
            try {
                if ($null -ne $item.Subject) { $event.Subject = Sanitize($item.Subject) }
                if ($null -ne $item.Start) { $event.Start = $item.Start.ToString("o") }
                if ($null -ne $item.End) { $event.End = $item.End.ToString("o") }
                if ($null -ne $item.Location) { $event.Location = Sanitize($item.Location) }
                if ($null -ne $item.Body) { $event.Body = Sanitize($item.Body) }
                if ($null -ne $item.EntryID) { $event.EntryID = $item.EntryID }
                if ($null -ne $item.LastModificationTime) { $event.LastModificationTime = $item.LastModificationTime.ToString("o") }
                if ($null -ne $item.Organizer) { $event.Organizer = Sanitize($item.Organizer) }
                if ($null -ne $item.IsMeeting) { $event.IsMeeting = [bool]$item.IsMeeting }
                if ($null -ne $item.IsRecurring) { $event.IsRecurring = [bool]$item.IsRecurring }
                if ($null -ne $item.IsOnlineMeeting) { $event.IsOnlineMeeting = [bool]$item.IsOnlineMeeting }
                
                $rawEvents += $event
                $processedCount++
            } catch {
                # 個別アイテムの処理エラーは無視して続行
            }
            
            # 定期的にガベージコレクションを実行（メモリリーク防止）
            if ($processedCount % 500 -eq 0) {
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
            }
        } catch {
            # アイテム処理エラーは無視して続行
        }
    }

    # ソートとJSON変換
    $events = $rawEvents | Sort-Object { 
        if ([string]::IsNullOrEmpty($_.Start)) { 
            [DateTime]::MinValue 
        } else { 
            try {
                [DateTime]::Parse($_.Start) 
            } catch {
                [DateTime]::MinValue
            }
        } 
    }

    $json = $events | ConvertTo-Json -Depth 10 -Compress
    Write-Output $json
} catch {
    Write-Error "予定取得エラー: $($_.Exception.Message)"
    @() | ConvertTo-Json
} finally {
    # フィルタリングされたアイテムコレクションを解放（itemsとは別のオブジェクトの場合）
    if ($null -ne $filteredItems -and $filteredItems -ne $items) {
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($filteredItems) | Out-Null
        } catch { }
        $filteredItems = $null
    }
    
    # COMオブジェクトの安全な解放（逆順で解放）
    if ($null -ne $items) { 
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($items) | Out-Null
        } catch { }
        $items = $null
    }
    if ($null -ne $calendar) { 
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($calendar) | Out-Null
        } catch { }
        $calendar = $null
    }
    if ($null -ne $namespace) { 
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($namespace) | Out-Null
        } catch { }
        $namespace = $null
    }
    if ($null -ne $outlook) { 
        try {
            # Outlookを明示的に終了しない（他のプロセスが使用している可能性があるため）
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
        } catch { }
        $outlook = $null
    }
    
    # ガベージコレクション（複数回実行して確実に解放）
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    # 追加の待機時間（COMオブジェクトの完全な解放を確実にする）
    Start-Sleep -Milliseconds 200
}
