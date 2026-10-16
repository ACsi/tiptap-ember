import Component from '@glimmer/component';
import type Owner from '@ember/owner';
import type { TOC } from '@ember/component/template-only';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, type TestContext } from '@ember/test-helpers';
import StarterKit from '@tiptap/starter-kit';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Decoration, DecorationSet } from '@tiptap/pm/view';
import {
  EmberNodeViewRenderer,
  Extension,
  Node,
  NodeViewContent,
  NodeViewWrapper,
  type Editor,
  type EmberNodeViewSignature,
} from '#src/index.ts';
import { createOwnedTestEditor } from '../../helpers/create-test-editor.ts';

interface DuringRenderSignature {
  Args: { run: () => void };
}

// Runs @run while Ember renders it
class DuringRender extends Component<DuringRenderSignature> {
  constructor(owner: Owner, args: DuringRenderSignature['Args']) {
    super(owner, args);
    args.run();
  }

  <template></template>
}

const DecoratedView: TOC<EmberNodeViewSignature> = <template>
  <NodeViewWrapper @ctx={{@ctx}} data-test-decorated>
    <span data-test-outer-count>{{@decorations.length}}</span>
    <NodeViewContent @ctx={{@ctx}} />
  </NodeViewWrapper>
</template>;

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

// Decorates decoratedNode only while the editor is editable
const EditableDecorationExtension = Extension.create({
  name: 'editableDecorationExtension',
  addProseMirrorPlugins() {
    const { editor } = this;

    return [
      new Plugin({
        key: new PluginKey('editableDecorationExtension'),
        props: {
          decorations(state) {
            if (!editor.isEditable) {
              return DecorationSet.empty;
            }

            const found: Decoration[] = [];

            state.doc.descendants((node, pos) => {
              if (node.type.name === 'decoratedNode') {
                found.push(
                  Decoration.node(pos, pos + node.nodeSize, {
                    class: 'test-editable-deco',
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

const TextSelectableNode = Node.create({
  name: 'textSelectableNode',
  group: 'block',
  atom: true,
  parseHTML() {
    return [{ tag: 'div[data-text-selectable-node]' }];
  },
  renderHTML() {
    return ['div', { 'data-text-selectable-node': '' }];
  },
  addNodeView() {
    return EmberNodeViewRenderer(SelectableView, {
      selectedOnTextSelection: true,
    });
  },
});

function outerCounts(editor: Editor): (string | null)[] {
  return [...editor.view.dom.querySelectorAll('[data-test-outer-count]')].map(
    (element) => element.textContent,
  );
}

module(
  'Integration | NodeView | EmberNodeViewRenderer during a render',
  function (hooks) {
    setupRenderingTest(hooks);

    test('a decoration change reaches the view', async function (this: TestContext, assert) {
      const editor = createOwnedTestEditor(this.owner, {
        extensions: [StarterKit, DecoratedNode, EditableDecorationExtension],
        content: '<p>a</p><div data-decorated-node>b</div>',
      });

      const run = (): void => {
        editor.setEditable(false);
      };

      await render(<template><DuringRender @run={{run}} /></template>);

      assert.deepEqual(outerCounts(editor), ['0']);
      assert
        .dom('[data-test-decorated]', editor.view.dom)
        .doesNotHaveClass('test-editable-deco');

      editor.destroy();
    });

    test('a text selection selects views with selectedOnTextSelection', async function (this: TestContext, assert) {
      const editor = createOwnedTestEditor(this.owner, {
        extensions: [StarterKit, TextSelectableNode],
        content: '<p>a</p><div data-text-selectable-node></div><p>b</p>',
      });

      const run = (): void => {
        editor.commands.setTextSelection({ from: 1, to: 6 });
      };

      await render(<template><DuringRender @run={{run}} /></template>);

      assert.dom('[data-test-selectable]', editor.view.dom).hasText('selected');

      editor.destroy();
    });

    // ProseMirror doesn't call deselectNode() for a text selection
    test('a later text selection wins over a held selection', async function (this: TestContext, assert) {
      const editor = createOwnedTestEditor(this.owner, {
        extensions: [StarterKit, TextSelectableNode],
        content: '<p>a</p><div data-text-selectable-node></div><p>b</p>',
      });

      // Held, since the views rendered in this turn
      editor.commands.setTextSelection({ from: 1, to: 6 });
      editor.commands.setTextSelection(1);
      await settled();

      assert
        .dom('[data-test-selectable]', editor.view.dom)
        .hasText('idle')
        .doesNotHaveClass('ProseMirror-selectednode');

      editor.destroy();
    });

    test('a view created and selected in the same render renders selected', async function (this: TestContext, assert) {
      const editor = createOwnedTestEditor(this.owner, {
        extensions: [StarterKit, SelectableNode],
        content: '<p>a</p>',
      });

      const run = (): void => {
        editor.commands.setContent('<div data-selectable-node></div><p>b</p>');
        editor.commands.setNodeSelection(0);
      };

      await render(<template><DuringRender @run={{run}} /></template>);

      assert
        .dom('[data-test-selectable]', editor.view.dom)
        .hasText('selected')
        .hasClass('ProseMirror-selectednode');

      editor.destroy();
    });

    // Rendering a view revalidates the others, so the render has read them too
    test('existing views get updates after a new view renders', async function (this: TestContext, assert) {
      const editor = createOwnedTestEditor(this.owner, {
        extensions: [StarterKit, DecoratedNode, EditableDecorationExtension],
        content: '<p>a</p><div data-decorated-node>b</div>',
      });

      const run = (): void => {
        editor.commands.insertContentAt(
          editor.state.doc.content.size,
          '<div data-decorated-node>c</div>',
        );
        editor.setEditable(false);
      };

      await render(<template><DuringRender @run={{run}} /></template>);

      assert.deepEqual(outerCounts(editor), ['0', '0']);

      editor.destroy();
    });
  },
);
