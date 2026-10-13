import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { find, render, clearRender } from '@ember/test-helpers';
import StarterKit from '@tiptap/starter-kit';
import { Extension, type Editor } from '@tiptap/core';
import { Plugin } from '@tiptap/pm/state';
import { EditorContent } from '#src/index.ts';
import { createTestEditor } from '../../helpers/create-test-editor.ts';

// Adds an element next to the editor, like a drag handle
const SiblingExtension = Extension.create({
  name: 'siblingExtension',
  addProseMirrorPlugins() {
    return [
      new Plugin({
        view(view) {
          const element = document.createElement('div');

          element.dataset['testSibling'] = '';
          view.dom.parentNode?.appendChild(element);

          return {
            destroy() {
              element.remove();
            },
          };
        },
      }),
    ];
  },
});

// Templates can't reference a `let`
const ctx: { editor: Editor } = { editor: null as unknown as Editor };

module('Integration | Editor | EditorContent', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    ctx.editor = createTestEditor({
      extensions: [StarterKit],
      content: '<p>Hello World</p>',
    });
  });

  hooks.afterEach(function () {
    if (!ctx.editor.isDestroyed) {
      ctx.editor.destroy();
    }
  });

  test('mounts the ProseMirror view inside [data-tiptap-ember-editor]', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);

    const wrapper = find('[data-tiptap-ember-editor]');
    assert.ok(wrapper, 'wrapper element rendered');
    assert.strictEqual(
      ctx.editor.view.dom.parentElement,
      wrapper,
      'ProseMirror view DOM is parented under the wrapper',
    );
    assert.dom('[data-tiptap-ember-editor]').includesText('Hello World');
    assert.deepEqual(
      [...wrapper!.childNodes],
      [ctx.editor.view.dom],
      'nothing else, not even whitespace',
    );
  });

  // Glimmer must not touch nodes ProseMirror owns
  test('does not replace ProseMirror-owned DOM on unmount', async function (assert) {
    // eslint-disable-next-line @typescript-eslint/unbound-method
    const original = Node.prototype.replaceChild;
    let calls = 0;
    Node.prototype.replaceChild = function patched<T extends Node>(
      this: Node,
      newChild: Node,
      oldChild: T,
    ): T {
      calls += 1;
      return original.call(this, newChild, oldChild) as T;
    };

    try {
      await render(
        <template><EditorContent @editor={{ctx.editor}} /></template>,
      );

      const beforeUnmount = calls;

      await clearRender();

      assert.strictEqual(
        calls - beforeUnmount,
        0,
        'replaceChild was not called during unmount',
      );
    } finally {
      Node.prototype.replaceChild = original;
    }
  });

  test('moves elements that plugins added next to the editor', async function (assert) {
    ctx.editor.destroy();
    ctx.editor = createTestEditor({
      extensions: [StarterKit, SiblingExtension],
      content: '<p>Hello World</p>',
    });

    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);

    assert.dom('[data-tiptap-ember-editor] > [data-test-sibling]').exists();

    await clearRender();
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);

    assert
      .dom('[data-tiptap-ember-editor] > [data-test-sibling]')
      .exists('they move back and forth with the editor');
  });

  test('renders an empty element for an editor without a view', async function (assert) {
    const unmounted = createTestEditor({
      extensions: [StarterKit],
      element: null,
    });

    ctx.editor.destroy();

    await render(
      <template>
        <EditorContent @editor={{unmounted}} data-test-unmounted />
        <EditorContent @editor={{ctx.editor}} data-test-destroyed />
      </template>,
    );

    assert.dom('[data-test-unmounted]').hasNoText();
    assert.dom('[data-test-destroyed]').hasNoText();

    unmounted.destroy();
  });

  test('yields { editor } in block form', async function (assert) {
    await render(
      <template>
        <EditorContent @editor={{ctx.editor}} as |api|>
          <span data-test-block-yield>{{if
              api.editor.isEditable
              "yes"
              "no"
            }}</span>
        </EditorContent>
      </template>,
    );

    assert.dom('[data-test-block-yield]').hasText('yes');
  });
});
