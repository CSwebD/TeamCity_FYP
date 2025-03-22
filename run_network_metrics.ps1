Write-Output "Starting Network Metrics Test..."

# Define paths and variables
$deploymentsPath = "C:\Deployments\test"
$artifactsPath = "C:\buildAgentFull\artifacts"
$performanceCSV = "$artifactsPath\performance_results_network.csv"
$tempNetworkFile = "$deploymentsPath\network_metrics.txt"
$chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
$testUrl = "http://127.0.0.1:5500/test/index.html"
$puppeteerScript = "$deploymentsPath\network_metrics_test.js"

# Ensure artifacts folder exists
if (!(Test-Path $artifactsPath)) {
    New-Item -Path $artifactsPath -ItemType Directory -Force | Out-Null
}

# Create the Puppeteer script to measure network metrics
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
    await page.goto('$testUrl', { waitUntil: 'load', timeout: 30000 });
    
    // Extract network timings using the Navigation Timing API
    const timings = await page.evaluate(() => {
      const t = performance.timing;
      return {
        dnsLookup: t.domainLookupEnd - t.domainLookupStart,
        tcpConnection: t.connectEnd - t.connectStart,
        sslHandshake: t.secureConnectionStart > 0 ? t.connectEnd - t.secureConnectionStart : 0,
        ttfb: t.responseStart - t.requestStart,
        responseTime: t.responseEnd - t.responseStart,
        domContentLoaded: t.domContentLoadedEventEnd - t.domContentLoadedEventStart,
        totalLoadTime: t.loadEventEnd - t.navigationStart
      };
    });
    
    fs.writeFileSync('C:\\Deployments\\test\\network_metrics.txt', JSON.stringify(timings));
    await browser.close();
  } catch (err) {
    fs.writeFileSync('C:\\Deployments\\test\\network_metrics.txt', JSON.stringify({ error: "N/A" }));
    console.error("Error in Network Metrics Test:", err);
  }
})();
"@ | Out-File -Encoding utf8 $puppeteerScript

Write-Output "Running Puppeteer for Network Metrics..."
Invoke-Expression "node $puppeteerScript"

# Read and parse the network metrics from the temporary file
$networkMetrics = $null
if (Test-Path $tempNetworkFile) {
    $networkMetrics = Get-Content $tempNetworkFile | ConvertFrom-Json
    Remove-Item $tempNetworkFile -Force
} elseif (Test-Path "$deploymentsPath\network_metrics.txt") {
    $networkMetrics = Get-Content "$deploymentsPath\network_metrics.txt" | ConvertFrom-Json
    Remove-Item "$deploymentsPath\network_metrics.txt" -Force
} else {
    $networkMetrics = @{ error = "N/A" }
}
Write-Output "Network Metrics:"
Write-Output $networkMetrics

# Log the results to a dedicated CSV file for network metrics
$header = "Timestamp,DNS Lookup (ms),TCP Connection (ms),SSL Handshake (ms),TTFB (ms),Response Time (ms),DOM Content Loaded (ms),Total Load Time (ms)"
if (!(Test-Path $performanceCSV)) {
    [System.IO.File]::WriteAllText($performanceCSV, $header + "`r`n", [System.Text.Encoding]::UTF8)
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
if ($networkMetrics.error -ne $null) {
    $row = "$timestamp,N/A,N/A,N/A,N/A,N/A,N/A,N/A"
} else {
    $row = "$timestamp,$($networkMetrics.dnsLookup),$($networkMetrics.tcpConnection),$($networkMetrics.sslHandshake),$($networkMetrics.ttfb),$($networkMetrics.responseTime),$($networkMetrics.domContentLoaded),$($networkMetrics.totalLoadTime)"
}
$row = $row -replace [char]0xA0, ' '  # Remove non-breaking spaces if present
Add-Content -Path $performanceCSV -Value $row -Encoding UTF8

Write-Output "Network metrics recorded. Results stored at: $performanceCSV"
