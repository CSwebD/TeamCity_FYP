Write-Output "Starting Interaction Metrics Test..."

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
$performanceCSV = "$artifactsPath\performance_results_interaction.csv"
$chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
$testUrl = "http://127.0.0.1:5500/test/index.html"

# Ensure artifacts folder exists
if (!(Test-Path $artifactsPath)) {
    New-Item -Path $artifactsPath -ItemType Directory -Force | Out-Null
}

# Prepare CSV header if it doesn't exist
if (!(Test-Path $performanceCSV)) {
    "Timestamp,User,TTI,Total Blocking Time (ms)" | Out-File -Encoding utf8 $performanceCSV
}

for ($i = 1; $i -le $users; $i++) {
    Write-Output "User $i: Running Interaction Metrics Test..."

    # Run Lighthouse test to generate the report
    Write-Output "Running Lighthouse..."
    $lighthouseCmd = "lighthouse $testUrl --chrome-path=`"$chromePath`" --output=json --output-path=`"$lighthouseReport`" --chrome-flags=`"--headless --no-sandbox`""
    Invoke-Expression $lighthouseCmd

    # Parse Interaction Metrics from Lighthouse report
    $tti = "N/A"
    $tbt = "N/A"
    if (Test-Path $lighthouseReport) {
        $lighthouseJson = Get-Content $lighthouseReport -Raw | ConvertFrom-Json
        # Extract TTI (display value, e.g., "0.7 s")
        $tti = $lighthouseJson.audits.interactive.displayValue
        # Extract Total Blocking Time as a numeric value (in milliseconds)
        $tbt = $lighthouseJson.audits."total-blocking-time".numericValue
    }
    Write-Output "User $i - Time to Interactive (TTI): $tti"
    Write-Output "User $i - Total Blocking Time (TBT): $tbt ms"

    # Clean the TTI value to remove stray "Â" characters and trailing " s"
    $ttiClean = ($tti.Trim() -replace "[\u00C2]", "") -replace "\s*s$", ""

    # Log the results to the CSV file
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $row = "$timestamp,$i,$ttiClean,$tbt"
    # Optionally remove non-breaking spaces if present
    $row = $row -replace [char]0xA0, ' '
    Add-Content -Path $performanceCSV -Value $row -Encoding UTF8
}

Write-Output "Interaction metrics recorded for $users users. Results stored at: $performanceCSV"
