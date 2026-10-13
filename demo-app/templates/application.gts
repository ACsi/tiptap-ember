import EditorPage from '../components/editor-page.gts';

const REPO_URL = 'https://github.com/ACsi/tiptap-ember';
const NPM_URL = 'https://www.npmjs.com/package/@acsi/tiptap-ember';

// The trailing empty paragraph avoids a Firefox first-click bug (upstream)
const INITIAL_CONTENT = `
  <h1>tiptap-ember</h1>
  <p>This editor renders Ember components as node views, mark views and widgets.</p>
  <p>Use the toolbar to insert blocks. Edits go through transactions, so undo and redo work.</p>
  <p>Marks work too. Here is a <mark data-highlight data-color="yellow">highlighted span</mark> rendered by an Ember mark view.</p>
  <demo-counter count="5"></demo-counter>
  <div data-callout data-variant="info"><p>This text lives inside a callout node view. Try typing!</p></div>
  <p></p>
`;

<template>
  <div class="page">
    <header class="page-header">
      <div>
        <h1 class="page-header__title">tiptap-ember</h1>
        <p class="page-header__tagline">Ember components for tiptap</p>
      </div>
      <nav class="page-header__links">
        <a href={{REPO_URL}} rel="noopener">GitHub</a>
        <a href={{NPM_URL}} rel="noopener">npm</a>
      </nav>
    </header>

    <section class="page-intro">
      <p>
        Every block below is a plain Ember component: the counter, callout and
        toggle are node views, the highlight is a mark view, and the word count
        next to the title is a widget. Type in the search box to highlight
        matches with decorations. Type
        <kbd>@</kbd>
        to open a mention popup.
      </p>
    </section>

    <EditorPage @content={{INITIAL_CONTENT}} />

    <footer class="page-footer">
      <p>
        MIT licensed ·
        <a href={{REPO_URL}} rel="noopener">source on GitHub</a>
      </p>
    </footer>
  </div>
</template>
