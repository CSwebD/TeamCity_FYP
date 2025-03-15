const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();

    const start = Date.now();
    // Updated port to 9090
    await page.goto('http://localhost:9090/index.html', { waitUntil: 'load' });
    const loadTime = Date.now() - start;

    // Extract Performance Metrics
    const metrics = await page.evaluate(() => {
        return {
            firstPaint: performance.timing.responseStart - performance.timing.navigationStart,
            firstContentfulPaint: performance.timing.domContentLoadedEventEnd - performance.timing.navigationStart
        };
    });

    const performanceData = `
    Timestamp: ${new Date().toISOString()}
    Load Time: ${loadTime}ms
    First Paint: ${metrics.firstPaint}ms
    First Contentful Paint: ${metrics.firstContentfulPaint}ms
    `;

    console.log(performanceData);
    fs.appendFileSync('C:/Deployments/performance_results.txt', performanceData);

    await browser.close();
})();
