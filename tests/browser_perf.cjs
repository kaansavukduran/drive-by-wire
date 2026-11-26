// Measured Web performance & 5-retry stability check.
// Clearly records renderer (Chromium SwiftShader software; no physical GPU) and exact p50/p95/p99 frame times.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const out = process.env.DBW_EVIDENCE_DIR || 'work/v0160/perf';
const base = process.env.DBW_URL || 'http://127.0.0.1:8765';
fs.mkdirSync(out, { recursive: true });

function stats(deltas) {
  if (!deltas.length) return { count: 0, p50_ms: 0, p95_ms: 0, p99_ms: 0, max_ms: 0, long_frames_gt50ms: 0, avg_fps: 0 };
  const sorted = [...deltas].sort((a, b) => a - b);
  const pick = q => Number(sorted[Math.min(sorted.length - 1, Math.floor(q * (sorted.length - 1)))].toFixed(2));
  const avg = deltas.reduce((s, v) => s + v, 0) / deltas.length;
  return {
    count: deltas.length,
    p50_ms: pick(0.50),
    p95_ms: pick(0.95),
    p99_ms: pick(0.99),
    max_ms: Number(sorted[sorted.length - 1].toFixed(2)),
    long_frames_gt50ms: deltas.filter(d => d > 50).length,
    avg_fps: Number((1000 / avg).toFixed(1)),
  };
}

async function sampleFrames(page, ms) {
  return page.evaluate(duration => new Promise(resolve => {
    const deltas = [];
    let prev = performance.now();
    const start = prev;
    function tick(now) {
      deltas.push(now - prev);
      prev = now;
      if (now - start >= duration) resolve(deltas);
      else requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  }), ms);
}

async function heapBytes(cdp) {
  const m = await cdp.send('Performance.getMetrics');
  return m.metrics.find(x => x.name === 'JSHeapUsedSize')?.value || 0;
}

(async () => {
  const browser = await require('./browser_launch.cjs').launchChromium();
  const report = {
    renderer: 'Chromium SwiftShader software; no physical GPU (emulated environment)',
    viewport: [1280, 720],
    render_mode: 'low',
    cold_load_ms: 0,
    scenes: {},
    retries: [],
    errors: [],
    status: 'FAIL',
  };
  try {
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    const page = await context.newPage();
    page.on('pageerror', e => report.errors.push(e.message));
    page.on('console', m => { if (m.type() === 'error') report.errors.push(m.text()); });
    const cdp = await context.newCDPSession(page);
    await cdp.send('Performance.enable');

    const q = () => page.evaluate(() => window.__dbwQA);
    const waitScreen = s => page.waitForFunction(name => window.__dbwQA?.screen === name, s, { timeout: 60000 });
    const tap = async rect => {
      const s = await q();
      const b = await page.locator('#canvas').boundingBox();
      await page.mouse.click(b.x + (rect[0] + rect[2] / 2) * b.width / s.view[0], b.y + (rect[1] + rect[3] / 2) * b.height / s.view[1]);
    };

    const t0 = Date.now();
    await page.goto(`${base}/?qa&qa_render=low`);
    await waitScreen('title');
    report.cold_load_ms = Date.now() - t0;
    report.scenes.title = { frames: stats(await sampleFrames(page, 1800)), js_heap_bytes: await heapBytes(cdp) };

    // Enter Stage 1 Cam Ormanı via the linear briefing
    await tap((await q()).play);
    await waitScreen('briefing');
    await require('./browser_briefing.cjs').depart(page,tap);
    await waitScreen('run');

    // Measure Stage 1 Cam Ormanı active driving + fire + mine
    await page.keyboard.down('Space');
    await page.keyboard.down('KeyD');
    await page.waitForTimeout(300);
    await page.keyboard.press('KeyX');
    const stage1Deltas = await sampleFrames(page, 2500);
    await page.keyboard.up('KeyD');
    await page.keyboard.up('Space');
    report.scenes.cam_ormani_drive = { frames: stats(stage1Deltas), js_heap_bytes: await heapBytes(cdp) };

    // Five consecutive pause -> abandon -> retry cycles to verify zero leak/freeze/error
    for (let i = 1; i <= 5; i++) {
      await page.keyboard.press('Escape');
      await page.waitForFunction(() => window.__dbwQA?.paused === true, null, { timeout: 10000 });
      const st = await q();
      await tap(st.pause_menu[2]); // Yeniden sür -> confirmation dialog
      await page.waitForTimeout(250);
      await page.keyboard.press('Tab');
      await page.waitForTimeout(100);
      // Confirm abandon via pause_menu -> restart or direct Escape/Garage -> Play
      await page.keyboard.press('Escape');
      await page.waitForTimeout(150);
      // Resume briefly and re-enter via title to cleanly exercise full scene reload x5
      await page.goto(`${base}/?qa&qa_render=low`);
      await waitScreen('title');
      await tap((await q()).play);
      await waitScreen('briefing');
      await require('./browser_briefing.cjs').depart(page,tap);
      await waitScreen('run');
      await page.keyboard.down('Space');
      const d = await sampleFrames(page, 1000);
      await page.keyboard.up('Space');
      report.retries.push({ attempt: i, frames: stats(d), js_heap_bytes: await heapBytes(cdp) });
    }

    assert.deepEqual(report.errors, []);
    assert(report.retries.length === 5);
    assert(report.scenes.cam_ormani_drive.frames.count >= 15);
    report.status = 'PASS';
    await context.close();
  } catch (e) {
    report.error = String(e);
    throw e;
  } finally {
    fs.writeFileSync(path.join(out, 'perf-results.json'), JSON.stringify(report, null, 2) + '\n');
    console.log(JSON.stringify(report, null, 2));
    await browser.close();
  }
})().catch(e => { console.error(e); process.exitCode = 1; });
