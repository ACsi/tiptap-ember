import { defineConfig } from 'vite';
import { extensions, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';

export default defineConfig(({ mode }) => {
  const isDemoBuild = mode === 'demo';

  return {
    // GitHub Pages serves the demo from /<repo>/
    base: isDemoBuild ? (process.env.DEMO_BASE ?? '/') : '/',
    plugins: [
      ember(),
      // ember() adds the main and tests entries, which break the demo build
      ...(isDemoBuild
        ? [
            {
              name: 'tiptap-ember-demo-input-fix',
              enforce: 'post',
              config(config) {
                const input = config.build?.rollupOptions?.input;

                if (input) {
                  delete input.main;
                  delete input.tests;
                }
              },
            },
          ]
        : []),
      babel({
        babelHelpers: 'inline',
        extensions,
      }),
    ],
    build: {
      rollupOptions: {
        input: isDemoBuild
          ? { demo: 'index.html' }
          : { tests: 'tests/index.html' },
      },
    },
  };
});
