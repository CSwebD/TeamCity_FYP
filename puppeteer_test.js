﻿const puppeteer = require('puppeteer');
const fs = require('fs');
(async () => {
  try {
    const browser = await puppeteer.launch({
      executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
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
