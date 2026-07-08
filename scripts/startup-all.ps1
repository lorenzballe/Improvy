# Startup All AI Development Tools (9Router + Ruflo + Graphify)
# Windows PowerShell
# Usage: .\scripts\startup-all.ps1

Write-Host "🚀 Improvy AI Development Toolkit - Startup" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Starting: 9Router + Ruflo + Graphify" -ForegroundColor Yellow
Write-Host ""

# Check if tools are installed
$tools = @{
    "9router" = "9router --version"
    "Ruflo" = "ruflo --version"
    "Graphify" = "graphify --version"
}

$allInstalled = $true
foreach ($tool in $tools.Keys) {
    Write-Host "Checking $tool..." -ForegroundColor Cyan
    try {
        $output = Invoke-Expression $tools[$tool] 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $tool installed" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $tool not found" -ForegroundColor Red
            $allInstalled = $false
        }
    } catch {
        Write-Host "  ✗ $tool not found" -ForegroundColor Red
        $allInstalled = $false
    }
}

if (-not $allInstalled) {
    Write-Host ""
    Write-Host "❌ Some tools are missing!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install with:" -ForegroundColor Yellow
    Write-Host "  npm install -g 9router" -ForegroundColor Gray
    Write-Host "  npm install -g ruflo@latest" -ForegroundColor Gray
    Write-Host "  pip install graphifyy" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "✅ All tools installed!" -ForegroundColor Green
Write-Host ""
Write-Host "Starting services..." -ForegroundColor Yellow
Write-Host ""

# Start in background jobs
$jobs = @()

# 1. Start 9Router
Write-Host "[1/3] Starting 9Router (Token Saver)..." -ForegroundColor Cyan
$job1 = Start-Job -Name "9Router" -ScriptBlock {
    9router 2>&1
} -ErrorAction SilentlyContinue
$jobs += $job1
Write-Host "  PID: $($job1.Id)" -ForegroundColor Gray

# 2. Start Ruflo daemon
Write-Host "[2/3] Starting Ruflo daemon (Agent Orchestration)..." -ForegroundColor Cyan
$job2 = Start-Job -Name "Ruflo" -ScriptBlock {
    ruflo daemon start 2>&1
    # Keep it running
    while ($true) { Start-Sleep -Seconds 10 }
} -ErrorAction SilentlyContinue
$jobs += $job2
Write-Host "  PID: $($job2.Id)" -ForegroundColor Gray

# 3. Graphify (ready to use, no daemon)
Write-Host "[3/3] Graphify ready (Knowledge Graph)" -ForegroundColor Cyan
Write-Host "  Use: /graphify . in Claude Code" -ForegroundColor Gray

Write-Host ""
Write-Host "✅ All services started!" -ForegroundColor Green
Write-Host ""
Write-Host "Status:" -ForegroundColor Yellow
Write-Host "  9Router    → http://localhost:20128/dashboard" -ForegroundColor White
Write-Host "  Ruflo      → Agent daemon running" -ForegroundColor White
Write-Host "  Graphify   → Ready via /graphify command" -ForegroundColor White
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "  1. Open Claude Code" -ForegroundColor White
Write-Host "  2. Try: /goal 'implement feature X'" -ForegroundColor Gray
Write-Host "  3. Tools work transparently in background" -ForegroundColor Gray
Write-Host ""
Write-Host "To stop services:" -ForegroundColor Yellow
Write-Host "  Stop-Job -Name 9Router, Ruflo" -ForegroundColor Gray
Write-Host "  Or close this terminal" -ForegroundColor Gray
Write-Host ""
Write-Host "Logs:" -ForegroundColor Yellow
Write-Host "  9Router: http://localhost:20128/logs" -ForegroundColor Gray
Write-Host "  Ruflo:   ruflo logs --follow" -ForegroundColor Gray
Write-Host ""
Write-Host "Running services (Ctrl+C to stop)..." -ForegroundColor Yellow
Write-Host ""

# Keep running
$jobs | Wait-Job | Out-Null
