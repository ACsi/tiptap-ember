// Ember 7.1 is the floor: it ships the built-in `element` keyword
export default {
  scenarios: [
    {
      name: 'ember-7.1',
      npm: {
        devDependencies: {
          'ember-source': 'npm:ember-source@~7.1.0',
        },
      },
    },
    {
      name: 'ember-latest',
      npm: {
        devDependencies: {
          'ember-source': 'npm:ember-source@latest',
        },
      },
    },
    {
      name: 'ember-beta',
      npm: {
        devDependencies: {
          'ember-source': 'npm:ember-source@beta',
        },
      },
    },
    {
      name: 'ember-alpha',
      npm: {
        devDependencies: {
          'ember-source': 'npm:ember-source@alpha',
        },
      },
    },
  ],
};
