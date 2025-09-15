# Direct COM Object Test
Write-Host "Testing Outlook COM Object directly..." -ForegroundColor Cyan

try {
    Write-Host "Creating Outlook COM Object..." -ForegroundColor Yellow
    $outlook = New-Object -ComObject Outlook.Application
    Write-Host "SUCCESS: COM Object created" -ForegroundColor Green
    
    Write-Host "Accessing MAPI namespace..." -ForegroundColor Yellow
    $namespace = $outlook.GetNamespace("MAPI")
    Write-Host "SUCCESS: MAPI namespace accessed" -ForegroundColor Green
    
    Write-Host "Accessing Inbox folder..." -ForegroundColor Yellow
    $inbox = $namespace.GetDefaultFolder(6)
    Write-Host "SUCCESS: Inbox folder accessed" -ForegroundColor Green
    
    Write-Host "Releasing COM Object..." -ForegroundColor Yellow
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
    Write-Host "SUCCESS: COM Object released" -ForegroundColor Green
    
    Write-Host "All tests passed!" -ForegroundColor Green
    
} catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error Type: $($_.Exception.GetType().Name)" -ForegroundColor Red
}
