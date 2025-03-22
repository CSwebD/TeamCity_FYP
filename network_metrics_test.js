const puppeteer = require('puppeteer');
const fs = require('fs');
(async () => {
  try {
    const browser = await puppeteer.launch({
      executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
      headless: true,
      args: ['--no-sandbox']
    });
    const page = await browser.newPage();
    await page.goto('http://127.0.0.1:5500/test/index.html', { waitUntil: 'load', timeout: 30000 });
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
