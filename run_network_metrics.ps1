Write-Output "Starting Network Metrics Test..."

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
$performanceCSV = "$artifactsPath\performance_results_network.csv"
$tempNetworkFile = "$deploymentsPath\network_metrics.txt"
$chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
$testUrl = "http://127.0.0.1:5500/test/index.html"
$puppeteerScript = "$deploymentsPath\network_metrics_test.js"

# Ensure artifacts folder exists
if (!(Test-Path $artifactsPath)) {
    New-Item -Path $artifactsPath -ItemType Directory -Force | Out-Null
}

# Prepare CSV header if it doesn't exist
if (!(Test-Path $performanceCSV)) {
    "Timestamp,User,DNS Lookup (ms),TCP Connection (ms),SSL Handshake (ms),TTFB (ms),Response Time (ms),DOM Content Loaded (ms),Total Load Time (ms)" | Out-File -Encoding utf8 $performanceCSV
}

for ($i = 1; $i -le $users; $i++) {
    Write-Output "User $i: Running Network Metrics Test..."

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
    fs.writeFileSync('C:\\Deployments\\test\\network_metrics.txt', JSON.stringify({ error: err.toString() }));
    console.error("Error in Network Metrics Test:", err);
  }
})();
"@ | Out-File -Encoding utf8 $puppeteerScript

    Write-Output "Running Puppeteer for user $i..."
    Invoke-Expression "node $puppeteerScript"

    # Wait to ensure the file is written
    Start-Sleep -Seconds 2

    # Debug: Check if network metrics file exists and output its contents
    if (Test-Path $tempNetworkFile) {
        Write-Output "Network metrics file found for user $i:"
        Get-Content $tempNetworkFile | Write-Output
    } else {
        Write-Output "Network metrics file NOT found for user $i."
    }

    # Read and parse the network metrics from the temporary file
    $networkMetrics = $null
    if (Test-Path $tempNetworkFile) {
        $networkMetrics = Get-Content $tempNetworkFile -Raw | ConvertFrom-Json
        Remove-Item $tempNetworkFile -Force
    } elseif (Test-Path "$deploymentsPath\network_metrics.txt") {
        $networkMetrics = Get-Content "$deploymentsPath\network_metrics.txt" -Raw | ConvertFrom-Json
        Remove-Item "$deploymentsPath\network_metrics.txt" -Force
    } else {
        $networkMetrics = @{ error = "N/A" }
    }

    Write-Output "User $i - Network Metrics:"
    Write-Output $networkMetrics

    # Build CSV row
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($networkMetrics.error -ne $null) {
        $row = "$timestamp,$i,N/A,N/A,N/A,N/A,N/A,N/A,N/A"
    } else {
        $row = "$timestamp,$i,$($networkMetrics.dnsLookup),$($networkMetrics.tcpConnection),$($networkMetrics.sslHandshake),$($networkMetrics.ttfb),$($networkMetrics.responseTime),$($networkMetrics.domContentLoaded),$($networkMetrics.totalLoadTime)"
    }
    $row = $row -replace [char]0xA0, ' '
    Add-Content -Path $performanceCSV -Value $row -Encoding UTF8
}

Write-Output "Network metrics recorded for $users users. Results stored at: $performanceCSV"
