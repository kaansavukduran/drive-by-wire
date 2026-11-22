// Shared portable Chromium launcher for browser regressions.
// Respects DBW_CHROMIUM first, then system Chromium/Chrome, then Playwright's bundled browser.
const fs = require('node:fs');
const { chromium } = require('playwright');

function resolveExecutablePath() {
  const candidates = [
    process.env.DBW_CHROMIUM,
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
    '/usr/bin/google-chrome',
  ].filter(Boolean);
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return undefined;
}

function launchChromium(extra = {}) {
  const executablePath = resolveExecutablePath();
  const options = {
    headless: true,
    args: [
      '--no-sandbox',
      '--use-gl=angle',
      '--use-angle=swiftshader',
      '--enable-unsafe-swiftshader',
    ],
    ...extra,
  };
  if (executablePath && !options.executablePath) {
    options.executablePath = executablePath;
  }
  return chromium.launch(options);
}

module.exports = { launchChromium, resolveExecutablePath };
