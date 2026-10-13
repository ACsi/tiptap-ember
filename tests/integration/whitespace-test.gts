import type { TOC } from '@ember/component/template-only';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { find, render, settled } from '@ember/test-helpers';
import StarterKit from '@tiptap/starter-kit';
import { Mark, Node, type Editor } from '@tiptap/core';
import {
  EmberMarkViewRenderer,
  EmberNodeViewRenderer,
  MarkViewContent,
  NodeViewContent,
  NodeViewWrapper,
  EditorContent,
  type EmberMarkViewSignature,
  type EmberNodeViewSignature,
} from '#src/index.ts';
import { createTestEditor } from '../helpers/create-test-editor.ts';

// Flush templates, so any whitespace text node comes from the library

// prettier-ignore
const FlushNodeView: TOC<EmberNodeViewSignature> = <template><NodeViewWrapper @ctx={{@ctx}} data-test-flush-node><NodeViewContent @ctx={{@ctx}} /></NodeViewWrapper></template>;

// prettier-ignore
const FlushMarkView: TOC<EmberMarkViewSignature> = <template><MarkViewContent data-test-flush-mark @ctx={{@ctx}} /></template>;

// No whitespace control on purpose
const SpaciousMarkView: TOC<EmberMarkViewSignature> = <template>
  <span data-test-spacious-mark>
    <MarkViewContent @ctx={{@ctx}} />
  </span>
</template>;

// The whitespace control the README recommends
const TildeNodeView: TOC<EmberNodeViewSignature> = <template>
  {{~! strip ~}}
  <NodeViewWrapper @ctx={{@ctx}} data-test-tilde-node>
    {{~! strip ~}}
    <button type="button" data-test-tilde-button>x</button>
    {{~! strip ~}}
    <NodeViewContent @ctx={{@ctx}} />
    {{~! strip ~}}
  </NodeViewWrapper>
  {{~! strip ~}}
</template>;

const FlushNode = Node.create({
  name: 'flushNode',
  group: 'block',
  content: 'inline*',
  addNodeView() {
    return EmberNodeViewRenderer(FlushNodeView);
  },
});

const TildeNode = Node.create({
  name: 'tildeNode',
  group: 'block',
  content: 'inline*',
  addNodeView() {
    return EmberNodeViewRenderer(TildeNodeView);
  },
});

const FlushMark = Mark.create({
  name: 'flushMark',
  addMarkView() {
    return EmberMarkViewRenderer(FlushMarkView);
  },
});

const SpaciousMark = Mark.create({
  name: 'spaciousMark',
  addMarkView() {
    return EmberMarkViewRenderer(SpaciousMarkView);
  },
});

const ctx: { editor: Editor } = { editor: null as unknown as Editor };

function whitespaceTextChildren(el: Element): Text[] {
  const out: Text[] = [];

  el.childNodes.forEach((node) => {
    if (node instanceof Text && /^\s*$/.test(node.data)) {
      out.push(node);
    }
  });

  return out;
}

function assertNoStrayWhitespace(
  assert: Assert,
  selector: string,
  label: string,
): void {
  const el = find(selector);
  assert.ok(el, `${label} (${selector}) rendered`);

  if (!el) {
    return;
  }

  const stray = whitespaceTextChildren(el);
  assert.strictEqual(
    stray.length,
    0,
    `${label} has no whitespace text-node children ` +
      `(found ${stray.length})`,
  );
}

module('Integration | Views | whitespace in templates', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    ctx.editor = createTestEditor({
      extensions: [StarterKit, FlushNode, TildeNode, FlushMark, SpaciousMark],
      content: '<p></p>',
    });
  });

  hooks.afterEach(function () {
    if (!ctx.editor.isDestroyed) {
      ctx.editor.destroy();
    }
  });

  test('node view: library templates add no whitespace text nodes', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({
        type: 'flushNode',
        content: [{ type: 'text', text: 'flush' }],
      })
      .run();
    await settled();

    assertNoStrayWhitespace(
      assert,
      '[data-node-view-wrapper]',
      'ProseMirror node view root',
    );
  });

  test('mark view: library templates add no whitespace text nodes', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({
        type: 'text',
        text: 'marked',
        marks: [{ type: 'flushMark' }],
      })
      .run();
    await settled();

    assertNoStrayWhitespace(
      assert,
      '[data-test-flush-mark]',
      'ProseMirror-adopted mark view root',
    );
  });

  test('mark view: outer template whitespace is never adopted by ProseMirror', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({
        type: 'text',
        text: 'spacious',
        marks: [{ type: 'spaciousMark' }],
      })
      .run();
    await settled();

    const root = find('[data-test-spacious-mark]');
    assert.ok(root, 'mark view root rendered');

    const paragraph = root?.parentElement;
    assert.strictEqual(
      paragraph?.tagName,
      'P',
      'root element adopted directly into the paragraph',
    );

    if (!paragraph) {
      return;
    }

    const stray = whitespaceTextChildren(paragraph);
    assert.strictEqual(
      stray.length,
      0,
      'paragraph around the mark view has no whitespace text-node children ' +
        `(found ${stray.length})`,
    );
  });

  // Fails once Glimmer drops this whitespace, so the README whitespace section can go
  test('Glimmer still keeps whitespace between elements in view templates', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({
        type: 'text',
        text: 'spacious',
        marks: [{ type: 'spaciousMark' }],
      })
      .run();
    await settled();

    const root = find('[data-test-spacious-mark]');
    assert.ok(root, 'mark view root rendered');

    if (!root) {
      return;
    }

    assert.true(whitespaceTextChildren(root).length > 0);
  });

  test('user templates: Handlebars whitespace control strips text nodes', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({
        type: 'tildeNode',
        content: [{ type: 'text', text: 'tilde' }],
      })
      .run();
    await settled();

    assertNoStrayWhitespace(
      assert,
      '[data-node-view-wrapper]',
      'ProseMirror node view root around the tilde template',
    );
    assertNoStrayWhitespace(
      assert,
      '[data-test-tilde-node]',
      'tilde-stripped user template',
    );
    assert.dom('[data-test-tilde-node] [data-test-tilde-button]').exists();
    assert
      .dom('[data-test-tilde-node] [data-node-view-content-host]')
      .includesText('tilde');
  });
});
