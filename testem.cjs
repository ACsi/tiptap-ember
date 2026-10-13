'use strict';

const { existsSync } = require('node:fs');
const { join } = require('node:path');

// CI has Chrome, the toolbox container only Chromium
function onPath(names) {
  const dirs = (process.env.PATH || '').split(':').filter(Boolean);

  return names.some((name) => dirs.some((dir) => existsSync(join(dir, name))));
}

const useChrome = onPath(['google-chrome', 'google-chrome-stable', 'chrome']);
const browser = useChrome ? 'Chrome' : 'Chromium';

const browserArgs = [
  // --no-sandbox is needed when running Chrome inside a container
  process.env.CI || !useChrome ? '--no-sandbox' : null,
  '--headless=new',
  '--disable-dev-shm-usage',
  '--disable-software-rasterizer',
  '--mute-audio',
  '--remote-debugging-port=0',
  '--window-size=1440,900',
].filter(Boolean);

if (typeof module !== 'undefined') {
  module.exports = {
    test_page: 'tests/index.html?hidepassed',
    cwd: 'dist-tests',
    disable_watching: true,
    launch_in_ci: [browser],
    launch_in_dev: [browser],
    browser_start_timeout: 120,
    browser_args: {
      [browser]: {
        ci: browserArgs,
      },
    },
  };
}
