import { tracked } from '@glimmer/tracking';
import { find, render, settled, waitUntil } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import StarterKit from '@tiptap/starter-kit';
import type { Editor } from '@tiptap/core';
import { EditorContent } from '#src/index.ts';
import { BubbleMenu, FloatingMenu } from '#src/menus/index.ts';
import { createTestEditor } from '../../helpers/create-test-editor.ts';

class State {
  @tracked show = true;
  @tracked editor: Editor | null = null;
  @tracked shouldShow = (): boolean => false;
}

const ctx: { editor: Editor; other: Editor | null; state: State } = {
  editor: null as unknown as Editor,
  other: null,
  state: new State(),
};

function hasPlugin(editor: Editor, name: string): boolean {
  return editor.state.plugins.some((plugin) =>
    (plugin as unknown as { key: string }).key.startsWith(name),
  );
}

module('Integration | Menus | BubbleMenu and FloatingMenu', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    ctx.editor = createTestEditor({
      extensions: [StarterKit],
      content: '<p>Hello</p>',
    });
    ctx.state = new State();
  });

  hooks.afterEach(function () {
    ctx.editor.destroy();
    ctx.other?.destroy();
    ctx.other = null;
  });

  test('<BubbleMenu> registers and unregisters its plugin', async function (assert) {
    await render(
      <template>
        <EditorContent @editor={{ctx.editor}} />
        {{~#if ctx.state.show~}}
          <BubbleMenu @editor={{ctx.editor}} @pluginKey="testBubble">
            <button type="button">Bold</button>
          </BubbleMenu>
        {{~/if~}}
      </template>,
    );

    assert.true(hasPlugin(ctx.editor, 'testBubble'));

    ctx.state.show = false;
    await settled();

    assert.false(hasPlugin(ctx.editor, 'testBubble'));
  });

  test('<FloatingMenu> registers and unregisters its plugin', async function (assert) {
    await render(
      <template>
        <EditorContent @editor={{ctx.editor}} />
        {{~#if ctx.state.show~}}
          <FloatingMenu @editor={{ctx.editor}} @pluginKey="testFloating">
            <button type="button">H1</button>
          </FloatingMenu>
        {{~/if~}}
      </template>,
    );

    assert.true(hasPlugin(ctx.editor, 'testFloating'));

    ctx.state.show = false;
    await settled();

    assert.false(hasPlugin(ctx.editor, 'testFloating'));
  });

  test('removes a visible <BubbleMenu>', async function (assert) {
    await render(
      <template>
        <EditorContent @editor={{ctx.editor}} />
        {{~#if ctx.state.show~}}
          <BubbleMenu
            @editor={{ctx.editor}}
            @updateDelay={{0}}
            class="test-bubble"
          >
            <button type="button">Bold</button>
          </BubbleMenu>
        {{~/if~}}
      </template>,
    );

    ctx.editor.chain().focus().setTextSelection({ from: 1, to: 4 }).run();

    await waitUntil(() => find('.test-bubble'));

    const menu = find('.test-bubble') as HTMLElement;

    assert.strictEqual(
      menu.style.visibility,
      'visible',
      'the attributes are on the positioned element',
    );
    assert.dom('.test-bubble > button').exists();

    ctx.state.show = false;
    await settled();

    assert.false(menu.isConnected);
    assert.false(hasPlugin(ctx.editor, 'bubbleMenu'));
  });

  test('updates the plugin options without registering it again', async function (assert) {
    const registerPlugin = ctx.editor.registerPlugin.bind(ctx.editor);
    let registered = 0;

    ctx.editor.registerPlugin = (...args) => {
      registered += 1;

      return registerPlugin(...args);
    };

    await render(
      <template>
        <EditorContent @editor={{ctx.editor}} />
        <BubbleMenu
          @editor={{ctx.editor}}
          @updateDelay={{0}}
          @shouldShow={{ctx.state.shouldShow}}
          class="test-bubble"
        >
          <button type="button">Bold</button>
        </BubbleMenu>
      </template>,
    );

    ctx.state.shouldShow = () => true;
    await settled();

    ctx.editor.chain().focus().setTextSelection({ from: 1, to: 4 }).run();

    await waitUntil(() => find('.test-bubble'));

    assert.strictEqual(registered, 1);
  });

  test('moves the plugin to a new editor', async function (assert) {
    ctx.other = createTestEditor({
      extensions: [StarterKit],
      content: '<p>Other</p>',
    });
    ctx.state.editor = ctx.editor;

    await render(
      <template>
        {{#if ctx.state.editor}}
          <BubbleMenu @editor={{ctx.state.editor}} @pluginKey="swapBubble" />
        {{/if}}
      </template>,
    );

    assert.true(hasPlugin(ctx.editor, 'swapBubble'));

    ctx.state.editor = ctx.other;
    await settled();

    assert.false(hasPlugin(ctx.editor, 'swapBubble'));
    assert.true(hasPlugin(ctx.other, 'swapBubble'));
  });
});
