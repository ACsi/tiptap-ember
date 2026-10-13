import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, resetOnerror, setupOnerror } from '@ember/test-helpers';
import {
  MarkViewContent,
  NodeViewContent,
  NodeViewWrapper,
  type MarkViewContext,
  type NodeViewContext,
} from '#src/index.ts';

// What an untyped (.gjs) caller can pass; the signatures exclude it.
const empty = '' as 'div';
const emptyInline = '' as 'span';
const nodeCtx = {} as NodeViewContext;
const markCtx = {} as MarkViewContext;

module('Integration | Views | empty @as tag', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(function () {
    resetOnerror();
  });

  test('<NodeViewWrapper @as=""> asserts', async function (assert) {
    setupOnerror((error: Error) => {
      assert.step(error.message);
    });

    await render(
      <template><NodeViewWrapper @ctx={{nodeCtx}} @as={{empty}} /></template>,
    );

    assert.verifySteps([
      'Assertion Failed: [tiptap-ember] <NodeViewWrapper>: `@as` must be a ' +
        'tag name; an empty string renders no element.',
    ]);
  });

  test('<NodeViewContent @as=""> asserts', async function (assert) {
    setupOnerror((error: Error) => {
      assert.step(error.message);
    });

    await render(
      <template><NodeViewContent @ctx={{nodeCtx}} @as={{empty}} /></template>,
    );

    assert.verifySteps([
      'Assertion Failed: [tiptap-ember] <NodeViewContent>: `@as` must be a ' +
        'tag name; an empty string renders no element.',
    ]);
  });

  test('<MarkViewContent @as=""> asserts', async function (assert) {
    setupOnerror((error: Error) => {
      assert.step(error.message);
    });

    await render(
      <template>
        <MarkViewContent @ctx={{markCtx}} @as={{emptyInline}} />
      </template>,
    );

    assert.verifySteps([
      'Assertion Failed: [tiptap-ember] <MarkViewContent>: `@as` must be a ' +
        'tag name; an empty string renders no element.',
    ]);
  });
});
