import type { TOC } from '@ember/component/template-only';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { getRootElement, render, settled } from '@ember/test-helpers';
import StarterKit from '@tiptap/starter-kit';
import type { Editor } from '@tiptap/core';
import {
  EmberRenderer,
  EditorContent,
  type EmberRendererSignature,
} from '#src/index.ts';
import { createTestEditor } from '../../helpers/create-test-editor.ts';

interface LabelProps {
  label: string;
  suffix: string;
}

const Label: TOC<EmberRendererSignature<LabelProps>> = <template>
  <span data-test-label>{{@props.label}}{{@props.suffix}}</span>
</template>;

const NamedLabel: TOC<EmberRendererSignature<LabelProps>> = <template>
  <span data-test-label>{{@label}}{{@suffix}}</span>
</template>;

const ctx: { editor: Editor } = { editor: null as unknown as Editor };

module('Integration | Renderer | EmberRenderer', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    ctx.editor = createTestEditor({
      extensions: [StarterKit],
      content: '<p></p>',
    });
  });

  hooks.afterEach(function () {
    if (!ctx.editor.isDestroyed) {
      ctx.editor.destroy();
    }
  });

  test('element is the component root, detached and ready for a positioner', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);

    const renderer = new EmberRenderer<LabelProps>(Label, {
      editor: ctx.editor,
      props: { label: 'hello', suffix: '!' },
    });
    await settled();

    const element = renderer.element!;

    assert.false(element.isConnected, 'element starts detached');
    assert
      .dom(element)
      .hasAttribute(
        'data-test-label',
        '',
        'element is the component root itself',
      )
      .hasText('hello!');

    renderer.destroy();
  });

  test('updateProps merges and re-renders', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);

    const renderer = new EmberRenderer<LabelProps>(Label, {
      editor: ctx.editor,
      props: { label: 'a', suffix: '-Z' },
    });
    await settled();

    assert.dom(renderer.element).hasText('a-Z');

    renderer.updateProps({ label: 'b' });
    await settled();

    assert
      .dom(renderer.element)
      .hasText('b-Z', 'label updated, untouched suffix preserved');

    renderer.destroy();
  });

  test('initial props keys arrive as individual named args', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);

    const renderer = new EmberRenderer<LabelProps>(NamedLabel, {
      editor: ctx.editor,
      props: { label: 'named', suffix: '-args' },
    });
    await settled();

    assert.dom(renderer.element).hasText('named-args');

    renderer.updateProps({ label: 'renamed' });
    await settled();

    assert
      .dom(renderer.element)
      .hasText('renamed-args', 'named args stay reactive to updateProps');

    renderer.destroy();
  });

  test('rendered content survives a detached → attached move', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);

    const renderer = new EmberRenderer<LabelProps>(Label, {
      editor: ctx.editor,
      props: { label: 'move', suffix: 'd' },
    });
    await settled();

    // What a positioner does with `renderer.element`
    getRootElement().appendChild(renderer.element!);

    assert.true(renderer.element!.isConnected, 'element now in the document');
    assert.dom(renderer.element).hasText('moved');

    renderer.destroy();

    assert.false(
      renderer.element!.isConnected,
      'destroy detached the element from the document',
    );
  });

  test('double destroy and destroy after editor teardown are safe', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);

    const renderer = new EmberRenderer<LabelProps>(Label, {
      editor: ctx.editor,
      props: { label: 'x', suffix: '' },
    });
    await settled();

    renderer.destroy();
    renderer.destroy();
    ctx.editor.destroy();
    renderer.destroy();

    assert.true(renderer.destroyed, 'renderer stays destroyed');
  });
});
