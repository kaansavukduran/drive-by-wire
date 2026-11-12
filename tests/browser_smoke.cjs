// Optional visual smoke run. Requires Playwright and a running HTTP server.
// DBW_URL, DBW_CHROMIUM and DBW_EVIDENCE_DIR override defaults.
const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const output = process.env.DBW_EVIDENCE_DIR || 'work/evidence';
fs.mkdirSync(output, { recursive: true });
const launch = { headless: true, args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] };
if (process.env.DBW_CHROMIUM) launch.executablePath = process.env.DBW_CHROMIUM;
(async () => {
 const browser = await chromium.launch(launch);
 const result = { desktop: [], touch: [] };
 try {
  for (const mobile of [false, true]) {
   const context = await browser.newContext({ viewport: mobile ? { width: 844, height: 390 } : { width: 1280, height: 720 }, hasTouch: mobile, isMobile: mobile });
   const page = await context.newPage();
   const errors = result[mobile ? 'touch' : 'desktop'];
   page.on('pageerror', e => errors.push(e.message));
   page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
   await page.goto(process.env.DBW_URL || 'http://127.0.0.1:8765');
   await page.waitForFunction(() => document.documentElement.dataset.gameState === 'started', null, { timeout: 60000 });
   await page.waitForTimeout(1000);
   const canvas = await page.locator('#canvas').boundingBox();
   const scale = Math.min(canvas.width / 640, canvas.height / 360);
   const point = (x, y, id) => ({ x: canvas.x + (canvas.width - 640 * scale) / 2 + x * scale, y: canvas.y + (canvas.height - 360 * scale) / 2 + y * scale, id });
   if (mobile) {
    const start = point(465, 44);
    await page.touchscreen.tap(start.x, start.y);
    await page.waitForTimeout(1200);
    const cdp = await context.newCDPSession(page);
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [point(48, 333, 0), point(490, 333, 1)] });
    await page.waitForTimeout(1800);
    await page.screenshot({ path: path.join(output, 'mobile-multitouch.png') });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    const pause = point(540, 294);
    await page.touchscreen.tap(pause.x, pause.y);
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(output, 'mobile-pause.png') });
   } else {
    await page.screenshot({ path: path.join(output, 'garage.png') });
    await page.keyboard.press('Space');
    await page.waitForTimeout(1000);
    await page.keyboard.down('Space');
    for (let i = 0; i < 8; i++) {
     await page.keyboard.press(i % 2 ? 'ArrowRight' : 'ArrowLeft');
     if (i === 3 || i === 6) await page.keyboard.press('KeyX');
     await page.waitForTimeout(1500);
    }
    await page.keyboard.up('Space');
    await page.screenshot({ path: path.join(output, 'run.png') });
    await page.keyboard.press('Escape');
    await page.waitForTimeout(250);
    await page.screenshot({ path: path.join(output, 'pause.png') });
    const clip = { x: 448, y: 16, width: 384, height: 70 };
    const before = await page.screenshot({ clip });
    await page.waitForTimeout(500);
    const after = await page.screenshot({ clip });
    assert(before.equals(after), 'the road must remain still during pause');
    await page.keyboard.press('Escape');
   }
   assert.deepEqual(errors, [], 'browser runtime errors');
   await context.close();
  }
  fs.writeFileSync(path.join(output, 'browser-results.json'), JSON.stringify(result, null, 2) + '\n');
  console.log('Desktop and multitouch browser smoke: PASS', JSON.stringify(result));
 } finally {
  await browser.close();
 }
})().catch(error => { console.error(error); process.exitCode = 1; });
