Write-Output "Starting Automated Performance Tests..."

# Paths explicitly defined
$deploymentsPath = "C:\Deployments\test"
$artifactsPath = "C:\buildAgentFull\artifacts"
$lighthouseReport = "$artifactsPath\lighthouse_report.json"
$performanceCSV = "$artifactsPath\performance_results.csv"
$puppeteerScript = "$deploymentsPath\puppeteer_test.js"
$tempLoadTimeFile = "$deploymentsPath\loadtime.txt"
$chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"

# Ensure artifacts folder existsz
if (!(Test-Path $artifactsPath)) {
    New-Item -Path $artifactsPath -ItemType Directory -Force | Out-Null
}

# Run Lighthouse test
Write-Output "Running Lighthouse..."
$lighthouseCmd = "lighthouse http://127.0.0.1:5500/test/index.html --chrome-path=`"$chromePath`" --output=json --output-path=`"$lighthouseReport`" --chrome-flags=`"--headless --no-sandbox`""
Invoke-Expression $lighthouseCmd

# Parse Lighthouse results
$lighthouseScore = "N/A"
$tti = "N/A"
if (Test-Path $lighthouseReport) {
    $lighthouseJson = Get-Content $lighthouseReport -Raw | ConvertFrom-Json
    $lighthouseScore = [Math]::Round($lighthouseJson.categories.performance.score * 100, 2)
    $tti = $lighthouseJson.audits.interactive.displayValue
}
Write-Output "Lighthouse Score: $lighthouseScore, TTI: $tti"

# Puppeteer script clearly defined and written to file with TTFB measurement
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
    await page.goto('http://127.0.0.1:5500/test/index.html', { waitUntil: 'load', timeout: 30000 });
    const loadTime = Date.now() - startTime;
    // Calculate TTFB using Navigation Timing API
    const ttfb = await page.evaluate(() => {
      const timing = performance.timing;
      return timing.responseStart - timing.requestStart;
    });
    fs.writeFileSync('C:\\Deployments\\test\\loadtime.txt', JSON.stringify({ loadTime: loadTime, ttfb: ttfb }));
    await browser.close();
  } catch (err) {
    fs.writeFileSync('C:\\Deployments\\test\\loadtime.txt', JSON.stringify({ loadTime: "N/A", ttfb: "N/A" }));
    console.error("Puppeteer error:", err);
  }
})();
"@ | Out-File -Encoding utf8 $puppeteerScript

Write-Output "Running Puppeteer..."
Invoke-Expression "node $puppeteerScript"

# Read Puppeteer results and parse JSON
$loadTimeJson = $null
if (Test-Path $tempLoadTimeFile) {
    $loadTimeJson = Get-Content $tempLoadTimeFile | ConvertFrom-Json
    Remove-Item $tempLoadTimeFile -Force
} else {
    $loadTimeJson = @{ loadTime = "N/A"; ttfb = "N/A" }
}
Write-Output "Puppeteer Load Time: $($loadTimeJson.loadTime) ms"
Write-Output "TTFB: $($loadTimeJson.ttfb) ms"

# Log results explicitly to CSV (header now includes TTFB)
if (!(Test-Path $performanceCSV)) {
    "Timestamp,Load Time (ms),Lighthouse Score,Time to Interactive,TTFB (ms)" | Out-File -Encoding utf8 $performanceCSV
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$row = "$timestamp,$($loadTimeJson.loadTime),$lighthouseScore,$tti,$($loadTimeJson.ttfb)"
# Optionally remove any non-breaking spaces if needed:
$row = $row -replace [char]0xA0, ' '
Add-Content -Path $performanceCSV -Value $row -Encoding UTF8

Write-Output "Performance tests complete. Results stored at: $performanceCSV"