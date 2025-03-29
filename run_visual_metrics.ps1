Write-Output "Starting Visual Metrics Test..."

# Load user count from the JSON configuration file
$usersConfigPath = "C:\Deployments\test\number_of_users.json"
if (Test-Path $usersConfigPath) {
    $config = Get-Content $usersConfigPath -Raw | ConvertFrom-Json
    $users = $config.users
} else {
    Write-Output "Configuration file not found. Using default user count of 1."
    $users = 1
}

# Define paths and variables
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

# Prepare CSV header if it doesn't exist
if (!(Test-Path $performanceCSV)) {
    "Timestamp,User,FCP,LCP,Speed Index" | Out-File -Encoding utf8 $performanceCSV
}

for ($i = 1; $i -le $users; $i++) {
    Write-Output "User $i: Running Lighthouse for Visual Metrics..."

    # Run Lighthouse test to generate the report
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
    Write-Output "User $i - FCP: $fcp, LCP: $lcp, Speed Index: $speedIndex"

    # Clean the metric values to remove stray "Â" characters and trailing " s"
    $fcpClean = ($fcp.Trim() -replace "[\u00C2]", "") -replace "\s*s$", ""
    $lcpClean = ($lcp.Trim() -replace "[\u00C2]", "") -replace "\s*s$", ""
    $speedIndexClean = ($speedIndex.Trim() -replace "[\u00C2]", "") -replace "\s*s$", ""

    # Log results to the CSV file
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $row = "$timestamp,$i,$fcpClean,$lcpClean,$speedIndexClean"
    $row = $row -replace [char]0xA0, ' '  # Remove non-breaking spaces if present
    Add-Content -Path $performanceCSV -Value $row -Encoding UTF8
}

Write-Output "Visual metrics recorded for $users users. Results stored at: $performanceCSV"
