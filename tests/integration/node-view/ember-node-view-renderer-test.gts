import Component from '@glimmer/component';
import type Owner from '@ember/owner';
import Service, { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import type { TOC } from '@ember/component/template-only';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  find,
  render,
  click,
  resetOnerror,
  settled,
  setupOnerror,
  type TestContext,
} from '@ember/test-helpers';
import StarterKit from '@tiptap/starter-kit';
import { Extension, Node, type Editor } from '@tiptap/core';
import { NodeSelection, Plugin, PluginKey } from '@tiptap/pm/state';
import {
  Decoration,
  DecorationSet,
  type DecorationSource,
} from '@tiptap/pm/view';
import {
  EmberNodeViewRenderer,
  NodeViewWrapper,
  NodeViewContent,
  EditorContent,
  type EmberNodeViewSignature,
  type NodeViewContext,
} from '#src/index.ts';
import { createTestEditor } from '../../helpers/create-test-editor.ts';

// --- Test components ------------------------------------------------------

const WithContentView: TOC<EmberNodeViewSignature> = <template>
  <NodeViewWrapper @ctx={{@ctx}} data-test-with-content>
    <NodeViewContent @ctx={{@ctx}} />
  </NodeViewWrapper>
</template>;

const DraggableView: TOC<EmberNodeViewSignature> = <template>
  <NodeViewWrapper @ctx={{@ctx}} data-test-draggable>
    <span data-drag-handle>::</span>
    <span>card</span>
  </NodeViewWrapper>
</template>;

class HostState {
  @tracked section = false;
  @tracked as: 'div' | 'section' = 'div';
}

const hostState = new HostState();

const SwappedHostView: TOC<EmberNodeViewSignature> = <template>
  <NodeViewWrapper @ctx={{@ctx}} data-test-swapped-host>
    {{~#if hostState.section~}}
      <NodeViewContent @ctx={{@ctx}} @as="section" data-test-host="section" />
    {{~else~}}
      <NodeViewContent @ctx={{@ctx}} data-test-host="div" />
    {{~/if~}}
  </NodeViewWrapper>
</template>;

const dragOrder: string[] = [];

class OrderedDragView extends Component<EmberNodeViewSignature> {
  record = () => {
    dragOrder.push('wrapper listener');
  };

  <template>
    <NodeViewWrapper
      @ctx={{@ctx}}
      data-test-ordered-drag
      {{on "dragstart" this.record}}
    >
      <span data-drag-handle>::</span>
    </NodeViewWrapper>
  </template>
}

const decorationsProbe: { innerDecorations: DecorationSource | null } = {
  innerDecorations: null,
};

class DecoratedView extends Component<EmberNodeViewSignature> {
  constructor(owner: Owner, args: EmberNodeViewSignature['Args']) {
    super(owner, args);
    decorationsProbe.innerDecorations = args.innerDecorations;
  }

  <template>
    <NodeViewWrapper @ctx={{@ctx}} data-test-decorated>
      <NodeViewContent @ctx={{@ctx}} />
    </NodeViewWrapper>
  </template>
}

interface CounterAttrs {
  count: number;
}

class CounterView extends Component<EmberNodeViewSignature<CounterAttrs>> {
  bump = () => {
    this.args.updateAttributes({ count: (this.args.attrs.count ?? 0) + 1 });
  };

  remove = () => {
    this.args.deleteNode();
  };

  <template>
    <NodeViewWrapper @ctx={{@ctx}} data-test-counter>
      <button type="button" data-test-bump {{on "click" this.bump}}>+</button>
      <button
        type="button"
        data-test-remove
        {{on "click" this.remove}}
      >x</button>
      <span data-test-count>{{@attrs.count}}</span>
    </NodeViewWrapper>
  </template>
}

interface DecoClassAttrs {
  tone: string;
}

// Its own class binding rewrites the class attribute on re-render
class DecoClassView extends Component<EmberNodeViewSignature<DecoClassAttrs>> {
  setLoud = () => {
    this.args.updateAttributes({ tone: 'loud' });
  };

  <template>
    <NodeViewWrapper
      @ctx={{@ctx}}
      class="tone-{{@attrs.tone}}"
      data-test-deco-class
    >
      <button type="button" data-test-set-loud {{on "click" this.setLoud}}>
        loud
      </button>
      <NodeViewContent @ctx={{@ctx}} />
    </NodeViewWrapper>
  </template>
}

class GreetingService extends Service {
  message = 'service-injected';
}

class ServiceView extends Component<EmberNodeViewSignature> {
  @service('greeting') declare greeting: GreetingService;

  <template>
    <NodeViewWrapper @ctx={{@ctx}} data-test-service>
      {{this.greeting.message}}
    </NodeViewWrapper>
  </template>
}

// --- Test extensions ------------------------------------------------------

const WithContentNode = Node.create({
  name: 'withContentNode',
  group: 'block',
  content: 'inline*',
  addNodeView() {
    return EmberNodeViewRenderer(WithContentView);
  },
});

const DraggableNode = Node.create({
  name: 'draggableNode',
  group: 'block',
  atom: true,
  draggable: true,
  selectable: true,
  parseHTML() {
    return [{ tag: 'div[data-draggable-node]' }];
  },
  renderHTML() {
    return ['div', { 'data-draggable-node': '' }];
  },
  addNodeView() {
    return EmberNodeViewRenderer(DraggableView);
  },
});

const SwappedHostNode = Node.create({
  name: 'swappedHostNode',
  group: 'block',
  content: 'inline*',
  addNodeView() {
    return EmberNodeViewRenderer(SwappedHostView);
  },
});

const OrderedDragNode = Node.create({
  name: 'orderedDragNode',
  group: 'block',
  atom: true,
  draggable: true,
  selectable: true,
  addNodeView() {
    return EmberNodeViewRenderer(OrderedDragView);
  },
});

const CounterNode = Node.create({
  name: 'counterNode',
  group: 'block',
  atom: true,
  selectable: true,
  addAttributes() {
    return { count: { default: 0 } };
  },
  addNodeView() {
    return EmberNodeViewRenderer(CounterView);
  },
});

const DecoratedNode = Node.create({
  name: 'decoratedNode',
  group: 'block',
  content: 'inline*',
  addNodeView() {
    return EmberNodeViewRenderer(DecoratedView);
  },
});

const DecoClassNode = Node.create({
  name: 'decoClassNode',
  group: 'block',
  content: 'inline*',
  addAttributes() {
    return {
      tone: { default: 'calm' },
    };
  },
  addNodeView() {
    return EmberNodeViewRenderer(DecoClassView);
  },
});

const ServiceNode = Node.create({
  name: 'serviceNode',
  group: 'block',
  atom: true,
  addNodeView() {
    return EmberNodeViewRenderer(ServiceView);
  },
});

// Node decorations on the test nodes, inline decorations on "deco-me"
const DecorationExtension = Extension.create({
  name: 'decorationExtension',
  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('decorationExtension'),
        props: {
          decorations(state) {
            const found: Decoration[] = [];

            state.doc.descendants((node, pos) => {
              if (
                node.type.name === 'decoratedNode' ||
                node.type.name === 'decoClassNode'
              ) {
                found.push(
                  Decoration.node(pos, pos + node.nodeSize, {
                    class: 'test-outer-deco',
                  }),
                );
              }

              if (node.isText && node.text?.includes('deco-me')) {
                const from = pos + node.text.indexOf('deco-me');

                found.push(
                  Decoration.inline(from, from + 'deco-me'.length, {
                    class: 'test-inner-deco',
                  }),
                );
              }

              return true;
            });

            return DecorationSet.create(state.doc, found);
          },
        },
      }),
    ];
  },
});

// --- Tests ----------------------------------------------------------------

const ctx: { editor: Editor } = { editor: null as unknown as Editor };

module('Integration | NodeView | EmberNodeViewRenderer', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    decorationsProbe.innerDecorations = null;
    dragOrder.length = 0;
    hostState.section = false;
    hostState.as = 'div';
    ctx.editor = createTestEditor({
      extensions: [
        StarterKit,
        WithContentNode,
        CounterNode,
        DraggableNode,
        OrderedDragNode,
        SwappedHostNode,
        DecoratedNode,
        DecoClassNode,
        ServiceNode,
        DecorationExtension,
      ],
      content: '<p></p>',
    });
  });

  hooks.afterEach(function () {
    resetOnerror();

    if (!ctx.editor.isDestroyed) {
      ctx.editor.destroy();
    }
  });

  test('node view components can inject services', async function (this: TestContext, assert) {
    this.owner.register('service:greeting', GreetingService);

    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor.chain().focus().insertContent({ type: 'serviceNode' }).run();
    await settled();

    assert.dom('[data-test-service]').hasText('service-injected');
  });

  test('@updateAttributes propagates to the ProseMirror node', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({ type: 'counterNode', attrs: { count: 0 } })
      .run();
    await settled();

    assert.dom('[data-test-count]').hasText('0', 'initial attr rendered');

    await click('[data-test-bump]');

    assert
      .dom('[data-test-count]')
      .hasText('1', 'attr re-rendered after update');

    const json = ctx.editor.getJSON();
    const counter = (json.content ?? []).find(
      (node) => node.type === 'counterNode',
    );
    assert.strictEqual(
      counter?.attrs?.['count'],
      1,
      'ProseMirror node attrs reflect the update',
    );
  });

  test('@deleteNode removes the node from the document', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor.chain().focus().insertContent({ type: 'counterNode' }).run();
    await settled();

    assert.dom('[data-test-counter]').exists('counter inserted');

    await click('[data-test-remove]');

    assert.dom('[data-test-counter]').doesNotExist('counter removed from DOM');
    const stillThere = (ctx.editor.getJSON().content ?? []).some(
      (node) => node.type === 'counterNode',
    );
    assert.notOk(stillThere, 'counter removed from document');
  });

  test('dragging from a [data-drag-handle] selects the whole node so ProseMirror can reorder it', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor.chain().focus().insertContent({ type: 'draggableNode' }).run();
    await settled();

    const handle = find('[data-drag-handle]');
    assert.ok(handle, 'drag handle rendered');

    const dataTransfer = new DataTransfer();
    handle?.dispatchEvent(
      new DragEvent('dragstart', {
        bubbles: true,
        cancelable: true,
        dataTransfer,
      }),
    );
    await settled();

    const { selection } = ctx.editor.state;
    assert.true(
      selection instanceof NodeSelection,
      'a NodeSelection is created from the handle drag',
    );
    assert.strictEqual(
      (selection as NodeSelection).node.type.name,
      'draggableNode',
      'the whole draggable node is selected',
    );
  });

  test('content moves to a replacement <NodeViewContent>', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({
        type: 'swappedHostNode',
        content: [{ type: 'text', text: 'kept' }],
      })
      .run();
    await settled();

    assert.dom('[data-test-host="div"]').hasText('kept');

    hostState.section = true;
    await settled();

    assert.dom('[data-test-host="section"]').hasText('kept');
  });

  test('changing @as on <NodeViewWrapper> asserts', async function (assert) {
    const nodeCtx = {} as NodeViewContext;

    setupOnerror((error: Error) => {
      assert.step(error.message);
    });

    await render(
      <template>
        <NodeViewWrapper @ctx={{nodeCtx}} @as={{hostState.as}} />
      </template>,
    );

    hostState.as = 'section';
    await settled();

    assert.verifySteps([
      'Assertion Failed: [tiptap-ember] <NodeViewWrapper>: `@as` cannot ' +
        'change after the first render.',
    ]);
  });

  test('core handles dragstart before a dragstart listener on the wrapper', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor.chain().focus().insertContent({ type: 'orderedDragNode' }).run();
    ctx.editor.commands.setTextSelection(ctx.editor.state.doc.content.size - 1);
    await settled();

    // Core selects the node from its dragstart handler
    ctx.editor.on('selectionUpdate', () => {
      dragOrder.push('core');
    });

    find('[data-test-ordered-drag] [data-drag-handle]')!.dispatchEvent(
      new DragEvent('dragstart', {
        bubbles: true,
        cancelable: true,
        dataTransfer: new DataTransfer(),
      }),
    );
    await settled();

    assert.deepEqual(dragOrder, ['core', 'wrapper listener']);
  });

  test('a dragstart retargeted to the wrapper selects the dragged node, not the old selection', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor.chain().focus().insertContent({ type: 'counterNode' }).run();
    ctx.editor
      .chain()
      .insertContentAt(ctx.editor.state.doc.content.size, {
        type: 'draggableNode',
      })
      .run();
    await settled();

    // Leave the counter node-selected — the state a drop leaves behind.
    const { doc } = ctx.editor.state;
    let counterPos = -1;

    doc.descendants((node, pos) => {
      if (node.type.name === 'counterNode') {
        counterPos = pos;
      }
    });

    assert.true(counterPos >= 0, 'counter node inserted');

    ctx.editor.view.dispatch(
      ctx.editor.state.tr.setSelection(
        NodeSelection.create(ctx.editor.state.doc, counterPos),
      ),
    );

    const handle = find(
      '[data-test-draggable] [data-drag-handle]',
    ) as HTMLElement;
    const wrapper = handle.closest<HTMLElement>('[data-node-view-wrapper]')!;
    const counterEl = find('[data-test-counter]') as HTMLElement;
    const handleBox = handle.getBoundingClientRect();
    const counterBox = counterEl.getBoundingClientRect();

    // Chromium: mousedown on the handle, dragstart retargeted to the wrapper
    handle.dispatchEvent(
      new MouseEvent('mousedown', {
        bubbles: true,
        cancelable: true,
        button: 0,
        clientX: handleBox.x + 2,
        clientY: handleBox.y + 2,
      }),
    );
    wrapper.dispatchEvent(
      new DragEvent('dragstart', {
        bubbles: true,
        cancelable: true,
        dataTransfer: new DataTransfer(),
        clientX: counterBox.x + counterBox.width / 2,
        clientY: counterBox.y + counterBox.height / 2,
      }),
    );
    document.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }));
    await settled();

    const { selection } = ctx.editor.state;
    assert.true(selection instanceof NodeSelection, 'node selection active');
    assert.strictEqual(
      (selection as NodeSelection).node.type.name,
      'draggableNode',
      'the grabbed node is selected, not the stale-selected counter',
    );
  });

  test('decorations render on and inside an Ember node view', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({
        type: 'decoratedNode',
        content: [{ type: 'text', text: 'before deco-me after' }],
      })
      .run();
    await settled();

    assert
      .dom('[data-node-view-wrapper].test-outer-deco')
      .exists('outer node decoration attrs applied to the node view dom');
    assert
      .dom('[data-test-decorated] .test-inner-deco')
      .exists('inline decoration drawn inside the node content')
      .hasText('deco-me');
    assert.ok(
      decorationsProbe.innerDecorations,
      'component received @innerDecorations',
    );
  });

  test('decoration classes survive a component re-render that changes the wrapper class', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({
        type: 'decoClassNode',
        content: [{ type: 'text', text: 'tuned' }],
      })
      .run();
    await settled();

    assert
      .dom('[data-test-deco-class]')
      .hasClass('tone-calm', 'component class binding rendered')
      .hasClass('test-outer-deco', 'decoration class applied initially');

    await click('[data-test-set-loud]');

    assert
      .dom('[data-test-deco-class]')
      .hasClass('tone-loud', 'class binding re-rendered with the new attr')
      .hasClass(
        'test-outer-deco',
        'decoration class survived the class re-render',
      );
  });

  test('node view wrapper maps ProseMirror coordinates', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({
        type: 'withContentNode',
        content: [{ type: 'text', text: 'inside-text' }],
      })
      .run();
    await settled();

    const wrapper = find('[data-node-view-wrapper]') as HTMLElement;
    const rect = wrapper.getBoundingClientRect();
    assert.ok(
      rect.width > 0 && rect.height > 0,
      'the node view wrapper element has a real layout box',
    );

    const at = ctx.editor.view.posAtCoords({
      left: rect.left + rect.width / 2,
      top: rect.top + rect.height / 2,
    });
    assert.ok(at, 'posAtCoords resolves a position over the node view');

    let insidePos = -1;
    ctx.editor.state.doc.descendants((node, pos) => {
      if (node.isText && node.text?.includes('inside-text')) {
        insidePos = pos + 2;
      }

      return true;
    });

    const coords = ctx.editor.view.coordsAtPos(insidePos);
    assert.ok(
      coords.bottom > coords.top,
      `coordsAtPos for a text position inside the node view is non-degenerate (top=${coords.top}, bottom=${coords.bottom})`,
    );
  });

  test('selection adds ProseMirror-selectednode to the wrapper element', async function (assert) {
    await render(<template><EditorContent @editor={{ctx.editor}} /></template>);
    ctx.editor
      .chain()
      .focus()
      .insertContent({ type: 'counterNode', attrs: { count: 0 } })
      .run();
    await settled();

    // An inserted atom stays node-selected
    assert
      .dom('[data-test-counter]')
      .hasClass(
        'ProseMirror-selectednode',
        'selection class lands on the node view wrapper element',
      );

    ctx.editor.commands.setTextSelection(ctx.editor.state.doc.content.size);
    await settled();

    assert
      .dom('[data-test-counter]')
      .doesNotHaveClass(
        'ProseMirror-selectednode',
        'deselection removes the class from the wrapper element',
      );
  });
});
