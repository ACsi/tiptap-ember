import Component from '@glimmer/component';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, clearRender, settled } from '@ember/test-helpers';
import StarterKit from '@tiptap/starter-kit';
import {
  EditorContent,
  Editor,
  EmberNodeViewRenderer,
  Node,
  NodeViewWrapper,
  useEditor,
  type EmberNodeViewSignature,
} from '#src/index.ts';

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

  test('owner teardown with mounted views does not throw', async function (assert) {
    // Test teardown destroys the owner without clearing the render first
    await render(<template><ViewHost /></template>);

    assert.dom('[data-test-view-bold]').exists();
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
