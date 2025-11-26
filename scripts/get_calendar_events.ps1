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
    
    # アイテムを安全に列挙
    $itemCount = $items.Count
    for ($i = 1; $i -le $itemCount; $i++) {
        $item = $null
        try {
            $item = $items.Item($i)
            if ($null -eq $item) { continue }
            
            # 型チェック
            if (-not ($item -is [Microsoft.Office.Interop.Outlook.AppointmentItem])) { 
                if ($item) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($item) | Out-Null }
                continue 
            }
            
            # 日付範囲チェック
            if ($null -eq $item.Start) { 
                if ($item) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($item) | Out-Null }
                continue 
            }
            
            try {
                $itemStart = [DateTime]$item.Start
                if ($itemStart -lt $startDate -or $itemStart -gt $endDate) { 
                    if ($item) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($item) | Out-Null }
                    continue 
                }
            } catch {
                if ($item) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($item) | Out-Null }
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
            } catch {
                # 個別アイテムの処理エラーは無視して続行
            } finally {
                if ($item) { 
                    try {
                        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($item) | Out-Null
                    } catch {
                        # 解放エラーは無視
                    }
                    $item = $null
                }
            }
        } catch {
            # アイテム取得エラーは無視して続行
            if ($item) { 
                try {
                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($item) | Out-Null
                } catch {
                    # 解放エラーは無視
                }
                $item = $null
            }
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
    # COMオブジェクトの安全な解放
    if ($items) { 
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($items) | Out-Null
        } catch { }
        $items = $null
    }
    if ($calendar) { 
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($calendar) | Out-Null
        } catch { }
        $calendar = $null
    }
    if ($namespace) { 
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($namespace) | Out-Null
        } catch { }
        $namespace = $null
    }
    if ($outlook) { 
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
}

