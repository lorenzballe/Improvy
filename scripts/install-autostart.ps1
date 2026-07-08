# Install Auto-Startup (Windows)
# Run this ONCE to setup automatic startup of AI toolkit

Write-Host "🚀 Installing Auto-Startup for Improvy AI Toolkit" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host ""

# Get project path
$projectPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$healthCheckScript = Join-Path $projectPath "scripts\health-check.py"

Write-Host "Project Path: $projectPath" -ForegroundColor Gray
Write-Host "Health Check Script: $healthCheckScript" -ForegroundColor Gray
Write-Host ""

# Check if script exists
if (-not (Test-Path $healthCheckScript)) {
    Write-Host "❌ health-check.py not found at $healthCheckScript" -ForegroundColor Red
    exit 1
}

Write-Host "✓ health-check.py found" -ForegroundColor Green
Write-Host ""

# Create Windows Task Scheduler task
Write-Host "Creating Windows Task Scheduler entry..." -ForegroundColor Yellow
Write-Host ""

$taskName = "ImproveAIToolkitAutoStart"
$taskDescription = "Auto-start 9Router, Ruflo, Graphify for Improvy Flutter"

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "⚠️  Task '$taskName' already exists" -ForegroundColor Yellow
    $choice = Read-Host "Replace it? (Y/n)"
    if ($choice -eq "n" -or $choice -eq "N") {
        Write-Host "Skipping..." -ForegroundColor Gray
        exit 0
    }
    Write-Host "Removing old task..." -ForegroundColor Gray
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create task action
$action = New-ScheduledTaskAction `
    -Execute "python.exe" `
    -Argument "`"$healthCheckScript`""

# Create task trigger (at system startup)
$trigger = New-ScheduledTaskTrigger -AtStartup

# Create task settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

# Register the task
try {
    $task = Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description $taskDescription `
        -RunLevel Highest `
        -ErrorAction Stop

    Write-Host "✅ Task created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Details:" -ForegroundColor Yellow
    Write-Host "  Name: $taskName" -ForegroundColor White
    Write-Host "  Description: $taskDescription" -ForegroundColor White
    Write-Host "  Trigger: At system startup" -ForegroundColor White
    Write-Host "  Action: python.exe $healthCheckScript" -ForegroundColor White
    Write-Host "  Run Level: Highest (admin)" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "❌ Failed to create task: $_" -ForegroundColor Red
    exit 1
}

# Optionally run now
Write-Host ""
$runNow = Read-Host "Run health check now? (Y/n)"
if ($runNow -ne "n" -and $runNow -ne "N") {
    Write-Host ""
    Write-Host "Running health check..." -ForegroundColor Cyan
    Write-Host ""
    & python.exe $healthCheckScript
    Write-Host ""
}

Write-Host "✅ Auto-startup installed!" -ForegroundColor Green
Write-Host ""
Write-Host "Your AI toolkit will now start automatically at system startup." -ForegroundColor Green
Write-Host ""
Write-Host "To manage the task:" -ForegroundColor Yellow
Write-Host "  • Task Scheduler → Windows Logs → $taskName" -ForegroundColor Gray
Write-Host "  • Or run: Get-ScheduledTask -TaskName $taskName" -ForegroundColor Gray
Write-Host ""
Write-Host "To disable/enable:" -ForegroundColor Yellow
Write-Host "  • Disable:  Disable-ScheduledTask -TaskName $taskName" -ForegroundColor Gray
Write-Host "  • Enable:   Enable-ScheduledTask -TaskName $taskName" -ForegroundColor Gray
Write-Host "  • Remove:   Unregister-ScheduledTask -TaskName $taskName" -ForegroundColor Gray
Write-Host ""
