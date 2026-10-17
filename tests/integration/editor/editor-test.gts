import Component from '@glimmer/component';
import type Owner from '@ember/owner';
import type { TOC } from '@ember/component/template-only';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { destroy } from '@ember/destroyable';
import { renderComponent } from '@ember/renderer';
import {
  render,
  clearRender,
  settled,
  type TestContext,
} from '@ember/test-helpers';
import StarterKit from '@tiptap/starter-kit';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Decoration, DecorationSet } from '@tiptap/pm/view';
import {
  EditorContent,
  Editor,
  EmberMarkViewRenderer,
  EmberNodeViewRenderer,
  EmberWidgetRenderer,
  Extension,
  Mark,
  MarkViewContent,
  Node,
  NodeViewContent,
  NodeViewWrapper,
  useEditor,
  type Content,
  type EmberMarkViewSignature,
  type EmberNodeViewSignature,
  type EmberWidgetDecorationSignature,
} from '#src/index.ts';
import { createOwnedTestEditor } from '../../helpers/create-test-editor.ts';

// Module-scope holder so tests can drive the editor the host created.
const holder: { editor: Editor | null } = { editor: null };

function capture(editor: Editor): Editor {
  holder.editor = editor;

  return editor;
}

// No <EditorContent>, so only the tracked state can update the output
class Probe extends Component {
  editor = capture(
    useEditor(this, {
      extensions: [StarterKit],
      content: '<p>hello</p>',
    }),
  );

  get bold(): string {
    return String(this.editor.isActive('bold'));
  }

  get text(): string {
    return this.editor.state.doc.textContent;
  }

  <template>
    <span data-test-bold>{{this.bold}}</span>
    <span data-test-text>{{this.text}}</span>
  </template>
}

class Host extends Component {
  editor = capture(
    useEditor(this, {
      extensions: [StarterKit],
      content: '<p>managed</p>',
    }),
  );

  <template><EditorContent @editor={{this.editor}} /></template>
}

class BoldView extends Component<EmberNodeViewSignature> {
  get bold(): string {
    return String(this.args.editor.isActive('bold'));
  }

  <template>
    <NodeViewWrapper @ctx={{@ctx}} data-test-view-bold>
      {{~this.bold~}}
    </NodeViewWrapper>
  </template>
}

const BoldNode = Node.create({
  name: 'boldNode',
  group: 'block',
  atom: true,
  parseHTML() {
    return [{ tag: 'bold-node' }];
  },
  renderHTML() {
    return ['bold-node'];
  },
  addNodeView() {
    return EmberNodeViewRenderer(BoldView);
  },
});

class ViewHost extends Component {
  editor = capture(
    useEditor(this, {
      extensions: [StarterKit, BoldNode],
      content: '<p>plain <strong>bold</strong></p><bold-node></bold-node>',
    }),
  );

  <template><EditorContent @editor={{this.editor}} /></template>
}

class DecoratedView extends Component<EmberNodeViewSignature> {
  get innerCount(): number {
    let count = 0;

    this.args.innerDecorations.forEachSet((set) => {
      count += set.find().length;
    });

    return count;
  }

  <template>
    <NodeViewWrapper @ctx={{@ctx}} data-test-decorated>
      <span data-test-outer-count>{{@decorations.length}}</span>
      <span data-test-inner-count>{{this.innerCount}}</span>
      <NodeViewContent @ctx={{@ctx}} />
    </NodeViewWrapper>
  </template>
}

const DecoratedNode = Node.create({
  name: 'decoratedNode',
  group: 'block',
  content: 'inline*',
  parseHTML() {
    return [{ tag: 'div[data-decorated-node]' }];
  },
  renderHTML() {
    return ['div', { 'data-decorated-node': '' }, 0];
  },
  addNodeView() {
    return EmberNodeViewRenderer(DecoratedView);
  },
});

// A node decoration on decoratedNode, an inline one on "deco-me"
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
              if (node.type.name === 'decoratedNode') {
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

// The view draws before plugins load, so their decorations arrive as updates
class DecoratedHost extends Component {
  editor = useEditor(this, {
    extensions: [StarterKit, DecoratedNode, DecorationExtension],
    content: '<p>a</p><div data-decorated-node>deco-me</div>',
  });

  <template><EditorContent @editor={{this.editor}} /></template>
}

// The initial caret is inside the leading view
class LeadingViewHost extends Component {
  editor = useEditor(this, {
    extensions: [StarterKit, DecoratedNode],
    content: '<div data-decorated-node></div><p>a</p>',
  });

  <template><EditorContent @editor={{this.editor}} /></template>
}

const SelectableView: TOC<EmberNodeViewSignature> = <template>
  <NodeViewWrapper @ctx={{@ctx}} data-test-selectable>
    {{~if @selected "selected" "idle"~}}
  </NodeViewWrapper>
</template>;

const SelectableNode = Node.create({
  name: 'selectableNode',
  group: 'block',
  atom: true,
  parseHTML() {
    return [{ tag: 'div[data-selectable-node]' }];
  },
  renderHTML() {
    return ['div', { 'data-selectable-node': '' }];
  },
  addNodeView() {
    return EmberNodeViewRenderer(SelectableView);
  },
});

// Queues a selection change while it renders, like a command from a modifier
class QueuingView extends Component<EmberNodeViewSignature> {
  constructor(owner: Owner, args: EmberNodeViewSignature['Args']) {
    super(owner, args);

    queueMicrotask(() => {
      args.editor.commands.setTextSelection(3);
    });
  }

  <template>
    <NodeViewWrapper @ctx={{@ctx}} data-test-queuing>
      {{~if @selected "selected" "idle"~}}
    </NodeViewWrapper>
  </template>
}

const QueuingNode = Node.create({
  name: 'queuingNode',
  group: 'block',
  atom: true,
  parseHTML() {
    return [{ tag: 'div[data-queuing-node]' }];
  },
  renderHTML() {
    return ['div', { 'data-queuing-node': '' }];
  },
  addNodeView() {
    return EmberNodeViewRenderer(QueuingView);
  },
});

// The initial selection is a node selection on the leading atom
class SelectableHost extends Component {
  editor = useEditor(this, {
    extensions: [StarterKit, SelectableNode],
    content: '<div data-selectable-node></div><p>a</p>',
  });

  <template><EditorContent @editor={{this.editor}} /></template>
}

const HighlightView: TOC<EmberMarkViewSignature> = <template>
  <mark data-test-highlight><MarkViewContent @ctx={{@ctx}} /></mark>
</template>;

const HighlightMark = Mark.create({
  name: 'highlightMark',
  parseHTML() {
    return [{ tag: 'mark' }];
  },
  renderHTML() {
    return ['mark', 0];
  },
  addMarkView() {
    return EmberMarkViewRenderer(HighlightView);
  },
});

const CountView: TOC<EmberWidgetDecorationSignature<{ count: number }>> =
  <template>
    <span data-test-count>{{@count}}</span>
  </template>;

const CountExtension = Extension.create({
  name: 'countExtension',
  addDecorations() {
    return {
      create: ({ editor, state }) => [
        EmberWidgetRenderer(CountView, {
          editor,
          pos: state.doc.content.size,
          key: 'count',
          props: { count: state.doc.childCount },
        }),
      ],
    };
  },
});

class ContentHost extends Component<{ Args: { content: Content } }> {
  editor = useEditor(this, {
    extensions: [StarterKit, HighlightMark, CountExtension],
    content: this.args.content,
  });

  <template><EditorContent @editor={{this.editor}} /></template>
}

module('Integration | Editor | Editor and useEditor', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(function () {
    holder.editor = null;
  });

  test('plain getters over editor state re-render on transactions', async function (assert) {
    await render(<template><Probe /></template>);

    const editor = holder.editor!;
    assert.dom('[data-test-text]').hasText('hello');
    assert.dom('[data-test-bold]').hasText('false');

    editor.chain().selectAll().setBold().run();
    await settled();

    assert
      .dom('[data-test-bold]')
      .hasText('true', 'mark state change reached the template untouched');

    editor.commands.insertContentAt(6, ' world');
    await settled();

    assert
      .dom('[data-test-text]')
      .hasText('hello world', 'document change reached the template');
  });

  test('views in the initial content re-render on transactions', async function (assert) {
    await render(<template><ViewHost /></template>);

    const editor = holder.editor!;
    assert.dom('[data-test-view-bold]').hasText('false');

    // Selection only, so the node view gets no update()
    editor.commands.setTextSelection({ from: 8, to: 10 });
    await settled();

    assert.dom('[data-test-view-bold]').hasText('true');
  });

  // What render() does since test-helpers 5.5, without depending on its version
  test('views in the initial content render when the host renders through renderComponent', async function (this: TestContext, assert) {
    const into = document.createElement('div');

    renderComponent(ViewHost, { into, owner: this.owner });
    await settled();

    assert.dom('[data-test-view-bold]', into).hasText('false');
  });

  test('views in the initial content get decorations from plugins', async function (assert) {
    await render(<template><DecoratedHost /></template>);

    assert
      .dom('[data-test-decorated]')
      .hasClass('test-outer-deco', 'node decoration class on the wrapper');
    assert
      .dom('[data-test-outer-count]')
      .hasText('1', 'component received the node decoration');
    assert
      .dom('[data-test-inner-count]')
      .hasText('1', 'component received the inner decoration');
  });

  test('a view at the start of the initial content renders node-selected', async function (assert) {
    await render(<template><SelectableHost /></template>);

    assert
      .dom('[data-test-selectable]')
      .hasText('selected', 'component received @selected')
      .hasClass('ProseMirror-selectednode');
  });

  // The queued change runs before the held props apply
  test('a selection change queued while views render wins over the initial node selection', async function (this: TestContext, assert) {
    const editor = createOwnedTestEditor(this.owner, {
      extensions: [StarterKit, QueuingNode],
      content: '<div data-queuing-node></div><p>a</p>',
    });

    await settled();

    assert
      .dom('[data-test-queuing]', editor.view.dom)
      .hasText('idle', 'the queued deselection is the one applied')
      .doesNotHaveClass('ProseMirror-selectednode');

    editor.destroy();
  });

  test('mark views in the initial content render', async function (assert) {
    await render(
      <template>
        <ContentHost @content="<p><mark>marked</mark></p>" />
      </template>,
    );

    assert.dom('[data-test-highlight]').hasText('marked');
  });

  test('widgets in the initial state render', async function (assert) {
    await render(
      <template>
        <ContentHost @content="<p>a</p><p>b</p>" />
      </template>,
    );

    assert.dom('[data-test-count]').hasText('2');
  });

  test('owner teardown with mounted views does not throw', async function (assert) {
    // Test teardown destroys the owner without clearing the render first
    await render(<template><ViewHost /></template>);

    assert.dom('[data-test-view-bold]').exists();
  });

  test('owner teardown with the caret in a view does not throw', async function (assert) {
    await render(<template><LeadingViewHost /></template>);

    assert.dom('[data-test-decorated]').exists();
  });

  // A child owner, so the test can check the editor after the teardown
  test('owner teardown does not edit the document', async function (this: TestContext, assert) {
    const owner = Object.create(this.owner) as Owner;

    renderComponent(ViewHost, { into: document.createElement('div'), owner });
    await settled();

    let updates = 0;

    holder.editor!.on('update', () => {
      updates += 1;
    });

    destroy(owner);
    await settled();

    assert.strictEqual(updates, 0);
  });

  test('owner teardown leaves views to their editor', async function (this: TestContext, assert) {
    const owner = Object.create(this.owner) as Owner;
    const editor = createOwnedTestEditor(owner, {
      extensions: [StarterKit, BoldNode],
      content: '<p>a</p><bold-node></bold-node>',
    });
    const { dom } = editor.view;

    destroy(owner);
    await settled();

    assert.dom('[data-test-view-bold]', dom).exists('kept after the teardown');

    editor.destroy();
    await settled();

    assert
      .dom('[data-test-view-bold]', dom)
      .doesNotExist('destroyed with the editor');
  });

  test('state getter reflects transactions synchronously', function (assert) {
    const editor = new Editor({
      extensions: [StarterKit],
      content: '<p>abc</p>',
    });

    assert.strictEqual(editor.state.doc.textContent, 'abc');

    editor.commands.insertContentAt(4, 'd');

    assert.strictEqual(
      editor.state.doc.textContent,
      'abcd',
      'tracked state getter returns the post-transaction state',
    );

    editor.destroy();
  });

  test('useEditor destroys the editor when the owner is torn down', async function (assert) {
    await render(<template><Host /></template>);

    const editor = holder.editor;
    assert.ok(editor, 'editor created via useEditor');
    assert.false(editor!.isDestroyed, 'editor is alive while rendered');

    await clearRender();

    assert.true(
      editor!.isDestroyed,
      'editor is destroyed when the host component is torn down',
    );
  });
});
