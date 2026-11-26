// Reach the real departure control using the visible briefing page.
async function depart(page, tap) {
  const current = () => page.evaluate(() => window.__dbwQA);
  let briefing = await current();
  if (briefing.page !== 1) {
    await tap(briefing.tabs[1]);
    await page.waitForFunction(() => window.__dbwQA?.page === 1);
    briefing = await current();
  }
  if (briefing.depart) {
    await tap(briefing.depart);
  } else {
    // Published 0.16.0 supports baseline comparisons with the same driver.
    if (!briefing.reply_ready) {
      await tap(briefing.radio_answers[0]);
      await page.waitForFunction(() => window.__dbwQA?.reply_ready);
      briefing = await current();
    }
    await tap(briefing.reply_continue);
  }
  await page.waitForFunction(() => window.__dbwQA?.screen === 'run');
}

module.exports = { depart };
