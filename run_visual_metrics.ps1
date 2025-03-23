Write-Output "Starting Visual Metrics Test..."

# Define paths
$deploymentsPath = "C:\Deployments\test"
$artifactsPath = "C:\buildAgentFull\artifacts"
$lighthouseReport = "$artifactsPath\lighthouse_report.json"
$performanceCSV = "$artifactsPath\performance_results_visual.csv"
$chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
$testUrl = "http://127.0.0.1:5500/test/index.html"

# Ensure artifacts folder exists
if (!(Test-Path $artifactsPath)) {
    New-Item -Path $artifactsPath -ItemType Directory -Force | Out-Null
}

# Run Lighthouse test to generate the report (this assumes Lighthouse is installed)
Write-Output "Running Lighthouse..."
$lighthouseCmd = "lighthouse $testUrl --chrome-path=`"$chromePath`" --output=json --output-path=`"$lighthouseReport`" --chrome-flags=`"--headless --no-sandbox`""
Invoke-Expression $lighthouseCmd

# Parse Lighthouse results for visual metrics
$fcp = "N/A"
$lcp = "N/A"
$speedIndex = "N/A"

if (Test-Path $lighthouseReport) {
    $lighthouseJson = Get-Content $lighthouseReport -Raw -Encoding UTF8 | ConvertFrom-Json
    $fcp = $lighthouseJson.audits."first-contentful-paint".displayValue
    $lcp = $lighthouseJson.audits."largest-contentful-paint".displayValue
    $speedIndex = $lighthouseJson.audits."speed-index".displayValue
}
Write-Output "First Contentful Paint (FCP): $fcp"
Write-Output "Largest Contentful Paint (LCP): $lcp"
Write-Output "Speed Index: $speedIndex"

# Clean the metrics to keep only the numeric part.
# Remove the Unicode character U+00C2 and trailing " s"
$fcpClean = ($fcp.Trim() -replace "[\u00C2]", "") -replace "\s*s$", ""
$lcpClean = ($lcp.Trim() -replace "[\u00C2]", "") -replace "\s*s$", ""
$speedIndexClean = ($speedIndex.Trim() -replace "[\u00C2]", "") -replace "\s*s$", ""

# Log results to a dedicated CSV for visual metrics
if (!(Test-Path $performanceCSV)) {
    "Timestamp,FCP,LCP,Speed Index" | Out-File -Encoding utf8 $performanceCSV
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$row = "$timestamp,$fcpClean,$lcpClean,$speedIndexClean"
$row = $row -replace [char]0xA0, ' '  # Remove non-breaking spaces if present
Add-Content -Path $performanceCSV -Value $row -Encoding UTF8

Write-Output "Visual metrics recorded. Results stored at: $performanceCSV"
