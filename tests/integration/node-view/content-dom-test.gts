import { settled } from '@ember/test-helpers';
import type { TOC } from '@ember/component/template-only';
import type Owner from '@ember/owner';
import type { TestContext } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import StarterKit from '@tiptap/starter-kit';
import { mergeAttributes, Node, type Editor } from '@tiptap/core';
import type { ComponentLike } from '@glint/template';
import {
  EmberNodeViewRenderer,
  NodeViewContent,
  NodeViewWrapper,
  type EmberNodeViewRendererOptions,
  type EmberNodeViewSignature,
} from '#src/index.ts';
import { createOwnedTestEditor } from '../../helpers/create-test-editor.ts';

// Ported from @tiptap/vue-3's VueNodeViewRenderer.test.ts. Keep the case list in sync.

type PmHTMLElement = HTMLElement & {
  pmViewDesc?: { spec?: { contentDOM?: unknown } };
};

const ComponentWithoutContent: TOC<EmberNodeViewSignature> = <template>
  <NodeViewWrapper @ctx={{@ctx}} class="no-content">
    <div class="custom-content">Custom UI</div>
  </NodeViewWrapper>
</template>;

const ComponentWithContent: TOC<EmberNodeViewSignature> = <template>
  <NodeViewWrapper @ctx={{@ctx}} class="with-content">
    <NodeViewContent @ctx={{@ctx}} class="content-editable" />
  </NodeViewWrapper>
</template>;

const LeafComponent: TOC<EmberNodeViewSignature> = <template>
  <NodeViewWrapper @ctx={{@ctx}} class="leaf">
    <div class="leaf-content">Leaf</div>
  </NodeViewWrapper>
</template>;

function createBlockNode(
  component: ComponentLike<EmberNodeViewSignature>,
  options?: Partial<EmberNodeViewRendererOptions>,
) {
  return Node.create({
    name: 'customBlock',
    group: 'block',
    content: 'inline*',
    parseHTML: () => [{ tag: 'custom-block' }],
    renderHTML: ({ HTMLAttributes }) => [
      'custom-block',
      mergeAttributes(HTMLAttributes),
      0,
    ],
    addNodeView: () => EmberNodeViewRenderer(component, options),
  });
}

function createLeafNode(component: ComponentLike<EmberNodeViewSignature>) {
  return Node.create({
    name: 'customLeaf',
    group: 'block',
    atom: true,
    parseHTML: () => [{ tag: 'custom-leaf' }],
    renderHTML: ({ HTMLAttributes }) => [
      'custom-leaf',
      mergeAttributes(HTMLAttributes),
    ],
    addNodeView: () => EmberNodeViewRenderer(component),
  });
}

const ctx: { editor: Editor } = { editor: null as unknown as Editor };

async function withEditor(
  owner: Owner,
  content: string,
  component: ComponentLike<EmberNodeViewSignature>,
  leaf = false,
  options?: Partial<EmberNodeViewRendererOptions>,
): Promise<void> {
  ctx.editor = createOwnedTestEditor(owner, {
    extensions: [
      StarterKit,
      leaf ? createLeafNode(component) : createBlockNode(component, options),
    ],
    content,
  });

  await settled();
}

module(
  'Integration | NodeView | EmberNodeViewRenderer contentDOM',
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.afterEach(function () {
      if (!ctx.editor.isDestroyed) {
        ctx.editor.destroy();
      }
    });

    test('does not thrash the DOM when <NodeViewContent> is absent', async function (this: TestContext, assert) {
      await withEditor(
        this.owner,
        '<custom-block>Hello World</custom-block>',
        ComponentWithoutContent,
      );

      const root = ctx.editor.view.dom;

      // Node view wrapper should mount
      assert.ok(
        root.querySelector('[data-node-view-wrapper]'),
        'node view wrapper mounted',
      );

      // Detached without <NodeViewContent>, like React
      assert.notOk(
        root.querySelector('[data-node-view-content]'),
        'content element stays detached',
      );

      // Verify the internal contentDOM is not null (fixes the thrashing bug)
      const wrapper = root.querySelector<PmHTMLElement>(
        '[data-node-view-wrapper]',
      );

      assert.ok(
        wrapper?.pmViewDesc?.spec?.contentDOM,
        'contentDOM is preserved on the NodeView spec',
      );
    });

    test('returns null for leaf nodes', async function (this: TestContext, assert) {
      await withEditor(this.owner, '<custom-leaf />', LeafComponent, true);

      assert.notOk(
        ctx.editor.view.dom.querySelector('[data-node-view-content]'),
        'leaf node renders no content element',
      );
    });

    test('works with <NodeViewContent> in the component', async function (this: TestContext, assert) {
      await withEditor(
        this.owner,
        '<custom-block>Hello World</custom-block>',
        ComponentWithContent,
      );

      const content = ctx.editor.view.dom.querySelector(
        '[data-node-view-content]',
      );

      assert.ok(content, 'content element mounted');
      assert.true(
        content!.textContent!.includes('Hello World'),
        'content element holds the node text',
      );
    });

    test('does not throw on destroy', async function (this: TestContext, assert) {
      await withEditor(
        this.owner,
        '<custom-block>Hello World</custom-block>',
        ComponentWithoutContent,
      );

      ctx.editor.destroy();
      assert.true(ctx.editor.isDestroyed, 'editor destroyed');
    });

    test('use custom content dom element tag', async function (this: TestContext, assert) {
      await withEditor(
        this.owner,
        '<custom-block>Hello World</custom-block>',
        ComponentWithContent,
        false,
        { contentDOMElementTag: 'custom-content-dom' },
      );

      assert.ok(
        ctx.editor.view.dom.querySelector('custom-content-dom'),
        'content element uses the custom tag',
      );
    });
  },
);
