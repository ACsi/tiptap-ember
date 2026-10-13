import { settled } from '@ember/test-helpers';
import type { TOC } from '@ember/component/template-only';
import { setOwner } from '@ember/owner';
import type { TestContext } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import StarterKit from '@tiptap/starter-kit';
import type { Editor } from '@tiptap/core';
import { EmberRenderer, type EmberRendererSignature } from '#src/index.ts';
import { createTestEditor } from '../../helpers/create-test-editor.ts';

// Ported from @tiptap/vue-3's VueRenderer.test.ts. Keep the case list in sync.

const TestComponent: TOC<EmberRendererSignature> = <template>
  <div>Test</div>
</template>;

interface ValueProps {
  value: string;
}

const ValueComponent: TOC<EmberRendererSignature<ValueProps>> = <template>
  <div>{{@props.value}}</div>
</template>;

interface CountProps {
  count: number;
}

const CountComponent: TOC<EmberRendererSignature<CountProps>> = <template>
  <div>{{@props.count}}</div>
</template>;

const ContentComponent: TOC<EmberRendererSignature> = <template>
  <div class="test-class">Content</div>
</template>;

const ctx: { editor: Editor } = { editor: null as unknown as Editor };

module('Integration | Renderer | EmberRenderer lifecycle', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function (this: TestContext) {
    ctx.editor = createTestEditor({
      extensions: [StarterKit],
      content: '<p>Hello World</p>',
    });

    setOwner(ctx.editor, this.owner);
  });

  hooks.afterEach(function () {
    if (!ctx.editor.isDestroyed) {
      ctx.editor.destroy();
    }
  });

  test('should initialize with destroyed flag set to false', function (assert) {
    const renderer = new EmberRenderer(TestComponent, {
      editor: ctx.editor,
      props: {},
    });

    assert.false(renderer.destroyed);

    renderer.destroy();
  });

  test('should set destroyed flag to true after destroy', function (assert) {
    const renderer = new EmberRenderer(TestComponent, {
      editor: ctx.editor,
      props: {},
    });

    assert.false(renderer.destroyed);
    renderer.destroy();
    assert.true(renderer.destroyed);
  });

  test('should allow multiple destroy calls without errors', function (assert) {
    const renderer = new EmberRenderer(TestComponent, {
      editor: ctx.editor,
      props: {},
    });

    renderer.destroy();
    renderer.destroy();
    renderer.destroy();

    assert.true(renderer.destroyed);
  });

  test('should not update props when destroyed', function (assert) {
    const renderer = new EmberRenderer<ValueProps>(ValueComponent, {
      editor: ctx.editor,
      props: { value: 'initial' },
    });

    assert.strictEqual(renderer.props.value, 'initial');

    renderer.destroy();
    renderer.updateProps({ value: 'updated' });

    // Props should not be updated after destroy
    assert.strictEqual(renderer.props.value, 'initial');
  });

  // Glimmer renders once, so check the output stays inert instead
  test('should not render when destroyed', async function (assert) {
    const renderer = new EmberRenderer<ValueProps>(ValueComponent, {
      editor: ctx.editor,
      props: { value: 'Test' },
    });

    const elementBefore = renderer.element;

    renderer.destroy();
    renderer.updateProps({ value: 'changed' });
    await settled();

    assert.strictEqual(
      renderer.element,
      elementBefore,
      'element identity is stable after destroy',
    );
    assert
      .dom(renderer.element)
      .hasText('Test', 'destroyed renderer does not re-render');
  });

  test('should handle props updates before destroy', function (assert) {
    const renderer = new EmberRenderer<CountProps>(CountComponent, {
      editor: ctx.editor,
      props: { count: 0 },
    });

    assert.strictEqual(renderer.props.count, 0);

    renderer.updateProps({ count: 5 });
    assert.strictEqual(renderer.props.count, 5);

    renderer.updateProps({ count: 10 });
    assert.strictEqual(renderer.props.count, 10);

    renderer.destroy();
  });

  test('should create and render element', function (assert) {
    const renderer = new EmberRenderer(ContentComponent, {
      editor: ctx.editor,
      props: {},
    });

    assert.ok(renderer.element, 'element created');
    assert.strictEqual(renderer.element?.textContent, 'Content');

    renderer.destroy();
  });
});
