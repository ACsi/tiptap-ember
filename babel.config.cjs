/**
 * This babel.config is not used for publishing.
 * It's only for the local editing experience
 * (and linting)
 */
const { buildMacros } = require('@embroider/macros/babel');

const {
  createRegistryPlugin: hbsMinifier,
} = require('ember-hbs-minifier/hbs-minifier-plugin');

const macros = buildMacros();

const templateTransforms = macros.templateMacros;

module.exports = {
  plugins: [
    [
      '@babel/plugin-transform-typescript',
      {
        allExtensions: true,
        allowDeclareFields: true,
        onlyRemoveTypeImports: true,
      },
    ],
    [
      'babel-plugin-ember-template-compilation',
      {
        transforms: [...templateTransforms],
      },
    ],
    [
      'module:decorator-transforms',
      {
        runtime: {
          import: require.resolve('decorator-transforms/runtime-esm'),
        },
      },
    ],
    ...macros.babelMacros,
  ],

  overrides: [
    {
      // Demo only: the whitespace tests need unminified templates
      include: /(^|[\\/])demo-app[\\/]/,
      plugins: [
        [
          'babel-plugin-ember-template-compilation',
          {
            transforms: [...templateTransforms, hbsMinifier({})],
          },
        ],
      ],
    },
  ],

  generatorOpts: {
    compact: false,
  },
};
