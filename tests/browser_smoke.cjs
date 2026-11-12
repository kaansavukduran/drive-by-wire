// Optional visual smoke run. Requires Playwright and a running HTTP server.
// DBW_URL, DBW_CHROMIUM and DBW_EVIDENCE_DIR override defaults.
const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const output = process.env.DBW_EVIDENCE_DIR || 'work/evidence-v050';
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
   await page.addInitScript(() => {
    const Original = window.AudioContext;
    window.__dbwAudio = [];
    if (Original) window.AudioContext = class extends Original { constructor(...args) { super(...args); window.__dbwAudio.push(this); } };
   });
   const errors = result[mobile ? 'touch' : 'desktop'];
   page.on('pageerror', e => errors.push(e.message));
   page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
   await page.goto((process.env.DBW_URL || 'http://127.0.0.1:8765')+'/?qa');
   await page.waitForFunction(() => document.documentElement.dataset.gameState === 'started', null, { timeout: 60000 });
   await page.waitForTimeout(1000);
   const canvas = await page.locator('#canvas').boundingBox();
   const scale = Math.min(canvas.width / 640, canvas.height / 360);
   const point = (x, y, id) => ({ x: canvas.x + (canvas.width - 640 * scale) / 2 + x * scale, y: canvas.y + (canvas.height - 360 * scale) / 2 + y * scale, id });
   if (mobile) {
    const start = point(175, 181);
    await page.touchscreen.tap(start.x, start.y);
    await page.waitForFunction(()=>window.__dbwQA?.screen==='briefing');
    const briefing=await page.evaluate(()=>window.__dbwQA);
    const choice=briefing.steady;
    await page.touchscreen.tap(canvas.x+(choice[0]+choice[2]/2)*canvas.width/briefing.view[0],canvas.y+(choice[1]+choice[3]/2)*canvas.height/briefing.view[1]);
    await page.waitForFunction(()=>window.__dbwQA?.screen==='run');
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
    await page.screenshot({ path: path.join(output, 'title.png') });
    const click = async (x, y) => { const p = point(x, y); await page.mouse.click(p.x, p.y); };
    await click(98, 254);
    await page.waitForTimeout(200);
    await page.screenshot({ path: path.join(output, 'help.png') });
    const help=await page.evaluate(()=>window.__dbwQA);assert(help.help_content[2]<=help.help_scroll[2]+1,'help text must not overflow horizontally');
    await page.keyboard.press('ArrowDown');await page.waitForTimeout(300);assert((await page.evaluate(()=>window.__dbwQA)).help_scroll_value>0,'help must scroll with arrows');
    await page.keyboard.press('Escape');
    await click(250, 254);
    await page.waitForTimeout(200);
    await page.screenshot({ path: path.join(output, 'settings.png') });
    await page.keyboard.press('Escape');
    await page.keyboard.press('Space');
    await page.waitForFunction(()=>window.__dbwQA?.screen==='briefing');
    await page.keyboard.press('Space');
    await page.waitForFunction(()=>window.__dbwQA?.screen==='run');
    await page.waitForTimeout(1000);
    await page.keyboard.down('Space');
    for (let i = 0; i < 8; i++) {
     await page.keyboard.press(i % 2 ? 'ArrowRight' : 'ArrowLeft');
     if (i === 3 || i === 6) await page.keyboard.press('KeyX');
     await page.waitForTimeout(1500);
    }
    await page.keyboard.up('Space');
    result.desktopMetrics = await page.evaluate(() => ({ load_ms: Number(document.documentElement.dataset.loadMs), engine_fps: Number(document.documentElement.dataset.gameFps), godot_static_memory_bytes: Number(document.documentElement.dataset.godotMemoryBytes), audio_context_states: window.__dbwAudio.map(a => a.state) }));
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
  const failureContext = await browser.newContext({ viewport: { width: 1280, height: 720 } });
  const failurePage = await failureContext.newPage();
  await failurePage.route('**/index.pck', route => route.abort('failed'));
  await failurePage.goto(process.env.DBW_URL || 'http://127.0.0.1:8765');
  await failurePage.waitForFunction(() => document.documentElement.dataset.gameState === 'failed', null, { timeout: 60000 });
  assert(await failurePage.locator('#status-retry').isVisible(), 'load failure must offer retry');
  await failurePage.screenshot({ path: path.join(output, 'loading-error.png') });
  await failurePage.unroute('**/index.pck');
  await failurePage.locator('#status-retry').click();
  await failurePage.waitForFunction(() => document.documentElement.dataset.gameState === 'started', null, { timeout: 60000 });
  result.loadFailureRecovery = 'PASS';
  await failureContext.close();
  fs.writeFileSync(path.join(output, 'browser-results.json'), JSON.stringify(result, null, 2) + '\n');
  console.log('Desktop and multitouch browser smoke: PASS', JSON.stringify(result));
 } finally {
  await browser.close();
 }
})().catch(error => { console.error(error); process.exitCode = 1; });
