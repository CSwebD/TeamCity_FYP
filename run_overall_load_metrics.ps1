Write-Output "Starting Overall Load Metrics Test..."

# Define paths
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

# Create the Puppeteer script to measure overall load time and TTFB
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

Write-Output "Running Puppeteer..."
Invoke-Expression "node $puppeteerScript"

# Read and parse Puppeteer results
$loadTimeJson = $null
if (Test-Path $tempLoadTimeFile) {
    $loadTimeJson = Get-Content $tempLoadTimeFile | ConvertFrom-Json
    Remove-Item $tempLoadTimeFile -Force
} else {
    $loadTimeJson = @{ loadTime = "N/A"; ttfb = "N/A" }
}
Write-Output "Overall Load Time: $($loadTimeJson.loadTime) ms"
Write-Output "TTFB: $($loadTimeJson.ttfb) ms"

# Log results to a dedicated CSV for overall load metrics
$header = "Timestamp,Overall Load Time (ms),TTFB (ms)"
if (!(Test-Path $performanceCSV)) {
    [System.IO.File]::WriteAllText($performanceCSV, $header + "`r`n", [System.Text.Encoding]::UTF8)
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$row = "$timestamp,$($loadTimeJson.loadTime),$($loadTimeJson.ttfb)"
# Optionally remove non-breaking spaces if needed:
$row = $row -replace [char]0xA0, ' '
Add-Content -Path $performanceCSV -Value $row -Encoding UTF8

Write-Output "Overall Load Metrics recorded. Results stored at: $performanceCSV"
