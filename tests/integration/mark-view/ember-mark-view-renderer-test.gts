import type { TOC } from '@ember/component/template-only';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { find, render, settled } from '@ember/test-helpers';
import StarterKit from '@tiptap/starter-kit';
import { Mark, type Editor } from '@tiptap/core';
import {
  EmberMarkViewRenderer,
  MarkViewContent,
  EditorContent,
  type EmberMarkViewSignature,
} from '#src/index.ts';
import { createTestEditor } from '../../helpers/create-test-editor.ts';

const HighlightView: TOC<EmberMarkViewSignature> = <template>
  <MarkViewContent data-test-highlight ...attributes @ctx={{@ctx}} />
</template>;

const HighlightMark = Mark.create({
  name: 'highlightMark',
  inclusive: false,
  addMarkView() {
    return EmberMarkViewRenderer(HighlightView);
  },
});

function insertHighlightedText(editor: Editor, text: string) {
  editor
    .chain()
    .focus()
    .insertContent({
      type: 'text',
      text,
      marks: [{ type: 'highlightMark' }],
    })
    .run();
}

const ctx: { editor: Editor } = { editor: null as unknown as Editor };

module('Integration | MarkView | EmberMarkViewRenderer', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    ctx.editor = createTestEditor({
      extensions: [StarterKit, HighlightMark],
      content: '<p></p>',
    });
  });

  hooks.afterEach(function () {
    if (!ctx.editor.isDestroyed) {
      ctx.editor.destroy();
    }
  });

  test('renders a mark view content host with the marked text', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    insertHighlightedText(ctx.editor, 'marked');
    await settled();

    assert
      .dom('[data-test-highlight]')
      .exists('mark view content host rendered')
      .includesText('marked');
  });

  test('the component root element is the ProseMirror-adopted mark view dom', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    insertHighlightedText(ctx.editor, 'marked-text');
    await settled();

    const root = find('[data-test-highlight]') as HTMLElement;
    assert.strictEqual(
      root.parentElement?.tagName,
      'P',
      'component root element sits directly in the paragraph',
    );

    let insidePos = -1;

    ctx.editor.state.doc.descendants((node, pos) => {
      if (node.isText && node.text?.includes('marked-text')) {
        insidePos = pos + 2;
      }

      return true;
    });

    const coords = ctx.editor.view.coordsAtPos(insidePos);
    assert.ok(
      coords.bottom > coords.top,
      `coordsAtPos inside the marked text is non-degenerate (top=${coords.top}, bottom=${coords.bottom})`,
    );
  });

  test('rapid sequential insertContent does not throw', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);

    for (let i = 0; i < 20; i += 1) {
      insertHighlightedText(ctx.editor, 'x');
    }

    await settled();

    assert.dom('[data-test-highlight]').includesText('xxxxxxxxxxxxxxxxxxxx');
  });

  test('setContent replacement destroys and recreates mark views cleanly', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    insertHighlightedText(ctx.editor, 'first');
    await settled();

    assert.dom('[data-test-highlight]').exists('initial mark rendered');

    ctx.editor.commands.setContent('<p>fresh content</p>');
    await settled();

    assert
      .dom('[data-test-highlight]')
      .doesNotExist('no stale mark view hosts after setContent');
    assert.dom('[data-tiptap-ember-editor]').includesText('fresh content');

    insertHighlightedText(ctx.editor, 'again');
    await settled();

    assert
      .dom('[data-test-highlight]')
      .exists('mark view recreates after a fresh insert')
      .includesText('again');
  });
});
