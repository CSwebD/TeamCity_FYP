Write-Output "Starting Interaction Metrics Test..."

# Define paths and variables
$deploymentsPath = "C:\Deployments\test"
$artifactsPath = "C:\buildAgentFull\artifacts"
$lighthouseReport = "$artifactsPath\lighthouse_report.json"
$performanceCSV = "$artifactsPath\performance_results_interaction.csv"
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

# Parse Interaction Metrics from Lighthouse report
$tti = "N/A"
$tbt = "N/A"
if (Test-Path $lighthouseReport) {
    $lighthouseJson = Get-Content $lighthouseReport -Raw | ConvertFrom-Json
    # Extract TTI (usually a display value, e.g., "0.7 s")
    $tti = $lighthouseJson.audits.interactive.displayValue
    # Extract Total Blocking Time as a numeric value (in milliseconds)
    $tbt = $lighthouseJson.audits."total-blocking-time".numericValue
}
Write-Output "Time to Interactive (TTI): $tti"
Write-Output "Total Blocking Time (TBT): $tbt ms"

# Clean the TTI value to remove stray "Â" and trailing " s"
$ttiClean = ($tti.Trim() -replace "[\u00C2]", "") -replace "\s*s$", ""

# Log results to a dedicated CSV for interaction metrics
if (!(Test-Path $performanceCSV)) {
    "Timestamp,TTI,Total Blocking Time (ms)" | Out-File -Encoding utf8 $performanceCSV
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$row = "$timestamp,$ttiClean,$tbt"
$row = $row -replace [char]0xA0, ' '  # Remove non-breaking spaces if present
Add-Content -Path $performanceCSV -Value $row -Encoding UTF8

Write-Output "Interaction metrics recorded. Results stored at: $performanceCSV"
