Param([Parameter(Mandatory=$true)][string]$Token)

try {
    $ol  = New-Object -ComObject Outlook.Application
    $ns  = $ol.GetNamespace("MAPI")
    $sent = $ns.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderSentMail)
    $items = $sent.Items
    $items.Sort("[SentOn]", $true)

    # 件名に含まれるケースを優先
    $matches = $items.Restrict("[Subject] Like '%$Token%'")
    if ($matches.Count -eq 0) {
      # 本文に含まれる可能性にも対応（最小範囲で走査）
      $c = 0
      $found = $null
      foreach ($it in $items) {
        $c++
        if ($c -gt 200) { break } # 負荷対策
        try {
          if ($it.HTMLBody -and $it.HTMLBody.Contains($Token)) { $found = $it; break }
        } catch {}
      }
      if ($found) { $found.Display(); exit 0 }
    } else {
      $matches.GetFirst().Display(); exit 0
    }

    [System.Windows.Forms.MessageBox]::Show("送信済みから見つかりませんでした：$Token","Outlook検索")
    exit 1
}
catch {
    Write-Error "Outlook検索エラー: $($_.Exception.Message)"
    exit 1
}