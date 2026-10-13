import { settled } from '@ember/test-helpers';
import type { TOC } from '@ember/component/template-only';
import type { TestContext } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import StarterKit from '@tiptap/starter-kit';
import { Mark, mergeAttributes, type Editor } from '@tiptap/core';
import {
  EmberMarkViewRenderer,
  MarkViewContent,
  type EmberMarkViewSignature,
} from '#src/index.ts';
import { createOwnedTestEditor } from '../../helpers/create-test-editor.ts';

// Ported from @tiptap/vue-3's VueMarkViewRenderer.test.ts. Keep the case list in sync.

const TestMarkComponent: TOC<EmberMarkViewSignature> = <template>
  <mark><MarkViewContent @ctx={{@ctx}} /></mark>
</template>;

const CustomMark = Mark.create({
  name: 'customMark',

  parseHTML() {
    return [{ tag: 'mark' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['mark', mergeAttributes(HTMLAttributes), 0];
  },

  addMarkView() {
    return EmberMarkViewRenderer(TestMarkComponent);
  },
});

const ctx: { editor: Editor } = { editor: null as unknown as Editor };

async function withMarkedEditor(owner: TestContext['owner']): Promise<void> {
  ctx.editor = createOwnedTestEditor(owner, {
    extensions: [StarterKit, CustomMark],
    content: '<p>This is <mark>marked text</mark> here.</p>',
  });

  await settled();
}

module(
  'Integration | MarkView | EmberMarkViewRenderer IME composition',
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.afterEach(function () {
      if (!ctx.editor.isDestroyed) {
        ctx.editor.destroy();
      }
    });

    test('should handle rapid content changes without errors', async function (this: TestContext, assert) {
      await withMarkedEditor(this.owner);

      assert.ok(
        ctx.editor.view.dom.querySelector('mark'),
        'mark view rendered',
      );

      // Like IME composition
      const { tr } = ctx.editor.state;

      ctx.editor.view.dispatch(tr.insertText('a', 15));
      ctx.editor.view.dispatch(ctx.editor.state.tr.insertText('b', 16));
      ctx.editor.view.dispatch(ctx.editor.state.tr.insertText('c', 17));
      assert.true(
        ctx.editor.state.doc.textContent.includes('abc'),
        'rapid dispatches apply',
      );

      assert.ok(
        ctx.editor.view.dom.querySelector('mark'),
        'mark view still present after changes',
      );
    });

    test('should allow multiple destroy calls without errors', async function (this: TestContext, assert) {
      await withMarkedEditor(this.owner);

      assert.ok(
        ctx.editor.view.dom.querySelector('mark'),
        'mark view rendered',
      );

      // Destroy the editor (which destroys all mark views), then again.
      ctx.editor.destroy();
      ctx.editor.destroy();
      assert.true(ctx.editor.isDestroyed, 'editor destroyed');
    });

    test('should handle content replacement without errors', async function (this: TestContext, assert) {
      await withMarkedEditor(this.owner);

      assert.ok(
        ctx.editor.view.dom.querySelector('mark'),
        'mark view rendered',
      );

      // Replace content entirely, which destroys and recreates mark views.
      ctx.editor.commands.setContent(
        '<p>New content with <mark>new mark</mark>!</p>',
      );
      assert.ok(
        ctx.editor.view.dom.querySelector('mark'),
        'mark view rendered for the new content',
      );

      await settled();

      const newMark = ctx.editor.view.dom.querySelector('mark');

      assert.ok(newMark, 'new mark view present');
      assert.strictEqual(newMark?.textContent, 'new mark');
    });
  },
);
