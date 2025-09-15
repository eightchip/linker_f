# Simple Outlook Connection Test
Write-Host "Outlook Connection Test" -ForegroundColor Cyan

# Test 1: Check if Outlook is running
Write-Host "1. Checking Outlook process..." -ForegroundColor Yellow
$outlookProcesses = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
if ($outlookProcesses) {
    Write-Host "   Outlook is running" -ForegroundColor Green
} else {
    Write-Host "   Outlook is NOT running" -ForegroundColor Red
    Write-Host "   Please start Outlook first" -ForegroundColor White
}

# Test 2: Test COM Object
Write-Host "2. Testing COM Object..." -ForegroundColor Yellow
try {
    $outlook = New-Object -ComObject Outlook.Application
    Write-Host "   COM Object created successfully" -ForegroundColor Green
    
    $namespace = $outlook.GetNamespace("MAPI")
    Write-Host "   MAPI namespace accessed successfully" -ForegroundColor Green
    
    $inbox = $namespace.GetDefaultFolder(6)
    Write-Host "   Inbox folder accessed successfully" -ForegroundColor Green
    
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
    Write-Host "   COM Object released successfully" -ForegroundColor Green
    
} catch {
    Write-Host "   COM Object test failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Test completed" -ForegroundColor Green
