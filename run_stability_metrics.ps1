Write-Output "Starting Stability Metrics Test..."

# Load user count from the JSON file
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
$performanceCSV = "$artifactsPath\performance_results_stability.csv"
$chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
$testUrl = "http://127.0.0.1:5500/test/index.html"

# Ensure artifacts folder exists
if (!(Test-Path $artifactsPath)) {
    New-Item -Path $artifactsPath -ItemType Directory -Force | Out-Null
}

# Prepare CSV header (with a "User" column) if it doesn't exist
if (!(Test-Path $performanceCSV)) {
    "Timestamp,User,CLS" | Out-File -Encoding utf8 $performanceCSV
}

for ($i = 1; $i -le $users; $i++) {
    Write-Output "User $i: Running Stability Metrics Test..."

    # Run Lighthouse test to generate the report
    Write-Output "Running Lighthouse..."
    $lighthouseCmd = "lighthouse $testUrl --chrome-path=`"$chromePath`" --output=json --output-path=`"$lighthouseReport`" --chrome-flags=`"--headless --no-sandbox`""
    Invoke-Expression $lighthouseCmd

    # Parse Stability Metrics (CLS) from Lighthouse JSON report
    $cls = "N/A"
    if (Test-Path $lighthouseReport) {
        $lighthouseJson = Get-Content $lighthouseReport -Raw -Encoding UTF8 | ConvertFrom-Json
        # Extract the numeric value for Cumulative Layout Shift (CLS)
        $cls = $lighthouseJson.audits."cumulative-layout-shift".numericValue
    }
    Write-Output "User $i - Cumulative Layout Shift (CLS): $cls"

    # Log stability metric result to CSV
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $row = "$timestamp,$i,$cls"
    $row = $row -replace [char]0xA0, ' '  # Remove non-breaking spaces if present
    Add-Content -Path $performanceCSV -Value $row -Encoding utf8
}

Write-Output "Stability metrics recorded for $users users. Results stored at: $performanceCSV"
