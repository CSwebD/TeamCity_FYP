Write-Output "Starting Stability Metrics Test..."

# Define paths and variables
$deploymentsPath = "C:\Deployments\test"
$artifactsPath = "C:\buildAgentFull\artifacts"
$lighthouseReport = "$artifactsPath\lighthouse_report.json"
$performanceCSV = "$artifactsPath\performance_results_stability.csv"
$chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
$testUrl = "http://127.0.0.1:5500/test/index.html"

# Ensure artifacts folder exists
if (!(Test-Path $artifactsPath)) {
    New-Item -Path $artifactsPath -ItemType Directory -Force | Out-Null
}

# Run Lighthouse test to generate the report
Write-Output "Running Lighthouse..."
$lighthouseCmd = "lighthouse $testUrl --chrome-path=`"$chromePath`" --output=json --output-path=`"$lighthouseReport`" --chrome-flags=`"--headless --no-sandbox`""
Invoke-Expression $lighthouseCmd

# Parse Stability Metrics (CLS) from Lighthouse JSON report
$cls = "N/A"
if (Test-Path $lighthouseReport) {
    $lighthouseJson = Get-Content $lighthouseReport -Raw | ConvertFrom-Json
    # Extract the numeric value for cumulative layout shift (CLS)
    $cls = $lighthouseJson.audits."cumulative-layout-shift".numericValue
}
Write-Output "Cumulative Layout Shift (CLS): $cls"

# Log Stability Metrics to a dedicated CSV file
if (!(Test-Path $performanceCSV)) {
    "Timestamp,CLS" | Out-File -Encoding utf8 $performanceCSV
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$row = "$timestamp,$cls"
# Optionally remove non-breaking spaces if needed
$row = $row -replace [char]0xA0, ' '
Add-Content -Path $performanceCSV -Value $row -Encoding UTF8

Write-Output "Stability metrics recorded. Results stored at: $performanceCSV"
