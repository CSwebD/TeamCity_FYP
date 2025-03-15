const puppeteer = require('puppeteer');
const fs = require('fs');
(async () => {
  const browser = await puppeteer.launch({ executablePath: 'C:\Program Files\Google\Chrome\Application\chrome.exe', headless: true });
  const page = await browser.newPage();
  const startTime = Date.now();
  await page.goto('http://localhost/index.html', { waitUntil: 'load' });
  const loadTime = Date.now() - startTime;
  fs.writeFileSync('C:\Deployments\test\loadtime.txt', loadTime.toString());
  await browser.close();
})();
