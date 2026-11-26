// Reach the real departure control using the visible briefing page.
async function depart(page, tap) {
  const current = () => page.evaluate(() => window.__dbwQA);
  let briefing = await current();
  if (briefing.page !== 1) {
    await tap(briefing.tabs[1]);
    await page.waitForFunction(() => window.__dbwQA?.page === 1);
    briefing = await current();
  }
  await tap(briefing.depart);
  await page.waitForFunction(() => window.__dbwQA?.screen === 'run');
}

module.exports = { depart };
