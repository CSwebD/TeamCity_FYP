Write-Output "Starting Overall Load Metrics Test..."

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
$performanceCSV = "$artifactsPath\performance_results_overall.csv"
$tempLoadTimeFile = "$deploymentsPath\loadtime.txt"
$chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
$testUrl = "http://127.0.0.1:5500/test/index.html"
$puppeteerScript = "$deploymentsPath\overall_load_test.js"

# Ensure artifacts folder exists
if (!(Test-Path $artifactsPath)) {
    New-Item -Path $artifactsPath -ItemType Directory -Force | Out-Null
}

# Prepare CSV header if it doesn't exist
if (!(Test-Path $performanceCSV)) {
    "Timestamp,User,Overall Load Time (ms),TTFB (ms)" | Out-File -Encoding utf8 $performanceCSV
}

for ($i = 1; $i -le $users; $i++) {
    Write-Output "User $i: Running Overall Load Metrics Test..."

    # Create the Puppeteer script that measures overall load time and TTFB
    @"
const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
  try {
    const browser = await puppeteer.launch({
      executablePath: '$chromePath',
      headless: true,
      args: ['--no-sandbox']
    });
    const page = await browser.newPage();
    await page.setCacheEnabled(false);
    const startTime = Date.now();
    await page.goto('$testUrl', { waitUntil: 'load', timeout: 30000 });
    const loadTime = Date.now() - startTime;
    // Calculate TTFB using the Navigation Timing API
    const ttfb = await page.evaluate(() => {
      const timing = performance.timing;
      return timing.responseStart - timing.requestStart;
    });
    fs.writeFileSync('C:\\Deployments\\test\\loadtime.txt', JSON.stringify({ loadTime, ttfb }));
    await browser.close();
  } catch (err) {
    fs.writeFileSync('C:\\Deployments\\test\\loadtime.txt', JSON.stringify({ loadTime: "N/A", ttfb: "N/A" }));
    console.error("Error in Overall Load Metrics:", err);
  }
})();
"@ | Out-File -Encoding utf8 $puppeteerScript

    Write-Output "Running Puppeteer for user $i..."
    Invoke-Expression "node $puppeteerScript"

    # Read and parse Puppeteer results
    $loadTimeJson = $null
    if (Test-Path $tempLoadTimeFile) {
        $loadTimeJson = Get-Content $tempLoadTimeFile -Raw | ConvertFrom-Json
        Remove-Item $tempLoadTimeFile -Force
    } else {
        $loadTimeJson = @{ loadTime = "N/A"; ttfb = "N/A" }
    }
    Write-Output "User $i - Overall Load Time: $($loadTimeJson.loadTime) ms"
    Write-Output "User $i - TTFB: $($loadTimeJson.ttfb) ms"

    # Log the results to the CSV file for each user
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $row = "$timestamp,$i,$($loadTimeJson.loadTime),$($loadTimeJson.ttfb)"
    $row = $row -replace [char]0xA0, ' '
    Add-Content -Path $performanceCSV -Value $row -Encoding UTF8
}

Write-Output "Overall Load Metrics recorded for $users users. Results stored at: $performanceCSV"
