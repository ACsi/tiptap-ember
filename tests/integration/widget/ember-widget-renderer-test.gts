import Component from '@glimmer/component';
import type { TOC } from '@ember/component/template-only';
import { getOwner } from '@ember/owner';
import { settled, type TestContext } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import StarterKit from '@tiptap/starter-kit';
import {
  DECORATION_MANAGER_PLUGIN_KEY,
  Extension,
  type AnyExtension,
  type Editor,
} from '@tiptap/core';
import type Owner from '@ember/owner';
import {
  EmberWidgetRenderer,
  type EmberWidgetDecorationSignature,
} from '#src/index.ts';
import { createOwnedTestEditor } from '../../helpers/create-test-editor.ts';

// Ported from @tiptap/vue-3's VueWidgetRenderer.test.ts. Keep the case list in sync.

const counts = { renders: 0, destroyed: 0 };
const owners: Array<Owner | undefined> = [];

function countRender(index: number): number {
  counts.renders += 1;

  return index;
}

class Counter extends Component<
  EmberWidgetDecorationSignature<{ index: number }>
> {
  constructor(owner: Owner, args: Counter['args']) {
    super(owner, args);
    owners.push(getOwner(this));
  }

  willDestroy(): void {
    super.willDestroy();
    counts.destroyed += 1;
  }

  <template>
    <button type="button" class="counter">{{countRender @index}}</button>
  </template>
}

const propLog: Array<{ size: number; hasEditor: boolean; hasGetPos: boolean }> =
  [];

function logProps(
  props: { editor?: unknown; getPos?: unknown },
  size: number,
): string {
  propLog.push({
    size,
    hasEditor: Boolean(props.editor),
    hasGetPos: typeof props.getPos === 'function',
  });

  return '';
}

const PropSpy: TOC<EmberWidgetDecorationSignature<{ size: number }>> =
  <template>
    <span class="spy" data-size={{@size}}>{{logProps @props @size}}</span>
  </template>;

// Index-based keys churn on purpose, to cover re-keying
function paragraphWidgets(): AnyExtension {
  return Extension.create({
    name: 'paragraphWidgets',
    addDecorations() {
      return {
        create: ({ editor, state }) => {
          const decorations: ReturnType<typeof EmberWidgetRenderer>[] = [];
          let index = 0;

          state.doc.forEach((node, offset) => {
            if (node.type.name !== 'paragraph') {
              return;
            }

            decorations.push(
              EmberWidgetRenderer(Counter, {
                editor,
                pos: offset + node.nodeSize - 1,
                key: `p-${index}`,
                props: { index },
                side: 1,
              }),
            );

            index += 1;
          });

          return decorations;
        },
      };
    },
  });
}

function spyWidget(): AnyExtension {
  return Extension.create({
    name: 'spyWidget',
    addDecorations() {
      return {
        create: ({ editor, state }) => {
          const first = state.doc.firstChild;

          if (!first) {
            return [];
          }

          return [
            EmberWidgetRenderer(PropSpy, {
              editor,
              pos: first.nodeSize - 1,
              key: 'spy-stable',
              props: { size: state.doc.content.size },
              side: 1,
            }),
          ];
        },
      };
    },
  });
}

const ctx: { editor: Editor | null } = { editor: null };

module('Integration | Widget | EmberWidgetRenderer', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    counts.renders = 0;
    counts.destroyed = 0;
    owners.length = 0;
    propLog.length = 0;
  });

  hooks.afterEach(function () {
    ctx.editor?.destroy();
    ctx.editor = null;
  });

  function mount(
    owner: Owner,
    content: string,
    extensions: AnyExtension[] = [],
  ): Editor {
    ctx.editor = createOwnedTestEditor(owner, {
      extensions: [StarterKit, paragraphWidgets(), ...extensions],
      content,
    });

    return ctx.editor;
  }

  function widgets(editor: Editor): NodeListOf<Element> {
    return editor.view.dom.querySelectorAll('.counter');
  }

  test('renders a widget per paragraph', function (this: TestContext, assert) {
    const editor = mount(this.owner, '<p>aaa</p><p>bbb</p>');

    assert.strictEqual(widgets(editor).length, 2);
  });

  test('passes ProseMirror widget options through', function (this: TestContext, assert) {
    let destroyCalls = 0;
    const stopEvent = (): boolean => true;
    const destroy = (): void => {
      destroyCalls += 1;
    };

    const extension = Extension.create({
      name: 'widgetOptions',
      addDecorations: () => ({
        create: ({ editor }) => [
          EmberWidgetRenderer(Counter, {
            editor,
            pos: 1,
            key: 'options',
            props: { index: 0 },
            side: -1,
            relaxedSide: true,
            ignoreSelection: true,
            stopEvent,
            destroy,
          }),
        ],
      }),
    });

    const editor = mount(this.owner, '<p>a</p>', [extension]);

    const specs =
      DECORATION_MANAGER_PLUGIN_KEY.getState(editor.state)
        ?.mergedDecorationSet.find()
        .map((widget) => widget.spec as Record<string, unknown>) ?? [];
    const spec = specs.find((widgetSpec) => widgetSpec['key'] === 'options');

    assert.strictEqual(spec?.['side'], -1);
    assert.true(spec?.['relaxedSide']);
    assert.true(spec?.['ignoreSelection']);
    assert.strictEqual(spec?.['stopEvent'], stopEvent);
    assert.strictEqual(typeof spec?.['destroy'], 'function');

    editor.destroy();
    ctx.editor = null;

    assert.strictEqual(destroyCalls, 0);
  });

  test('does not re-render widgets when props are unchanged on a transaction', async function (this: TestContext, assert) {
    const editor = mount(this.owner, '<p>aaa</p><p>bbb</p>');

    await settled();

    const afterMount = counts.renders;

    editor.commands.insertContentAt(2, 'X');
    editor.commands.insertContentAt(2, 'Y');
    editor.commands.insertContentAt(2, 'Z');

    await settled();

    assert.strictEqual(counts.renders, afterMount);
  });

  test('does not push props while a transaction is being applied', async function (this: TestContext, assert) {
    const editor = mount(this.owner, '<p>aaa</p>', [spyWidget()]);

    await settled();

    const spy = editor.view.dom.querySelector('.spy');
    const before = spy?.getAttribute('data-size');

    editor.commands.insertContentAt(2, 'X');

    assert.strictEqual(spy?.getAttribute('data-size'), before);

    await settled();

    assert.notStrictEqual(spy?.getAttribute('data-size'), before);
  });

  test('never drops editor/getPos from widget props across updates', async function (this: TestContext, assert) {
    const editor = mount(this.owner, '<p>aaa</p>', [spyWidget()]);

    await settled();

    assert.true(propLog.length > 0);

    editor.commands.insertContentAt(2, 'X');
    editor.commands.insertContentAt(2, 'Y');

    await settled();

    assert.true(propLog.length > 1);
    assert.true(propLog.every((entry) => entry.hasEditor && entry.hasGetPos));
  });

  test('keeps every widget mounted when keys are reassigned by a split', function (this: TestContext, assert) {
    const editor = mount(this.owner, '<p>aaa</p><p>bbb</p>');

    assert.strictEqual(widgets(editor).length, 2);

    editor.chain().setTextSelection(2).splitBlock().run();

    assert.strictEqual(editor.state.doc.childCount, 3);
    assert.strictEqual(widgets(editor).length, 3);
  });

  test('removes the widget when a paragraph is removed', function (this: TestContext, assert) {
    const editor = mount(this.owner, '<p>aaa</p><p>bbb</p>');

    assert.strictEqual(widgets(editor).length, 2);

    editor.chain().setTextSelection(6).joinBackward().run();

    assert.strictEqual(editor.state.doc.childCount, 1);
    assert.strictEqual(widgets(editor).length, 1);
  });

  test('removes stale widgets when setContent replaces the whole document', function (this: TestContext, assert) {
    const editor = mount(this.owner, '<p>a</p><p>b</p><p>c</p>');

    assert.strictEqual(widgets(editor).length, 3);

    editor.commands.setContent('<p>only</p>');

    assert.strictEqual(editor.state.doc.childCount, 1);
    assert.strictEqual(widgets(editor).length, 1);
  });

  test('destroys all active widget components when the editor is destroyed', async function (this: TestContext, assert) {
    const editor = mount(this.owner, '<p>a</p><p>b</p>');

    assert.strictEqual(widgets(editor).length, 2);

    editor.destroy();
    ctx.editor = null;

    await settled();

    assert.strictEqual(counts.destroyed, 2);
  });

  test('does not leak components after undo of a paragraph split', async function (this: TestContext, assert) {
    const editor = mount(this.owner, '<p>a</p><p>b</p>');

    editor.chain().setTextSelection(2).splitBlock().run();

    assert.strictEqual(widgets(editor).length, 3);

    editor.commands.undo();

    await settled();

    assert.strictEqual(editor.state.doc.childCount, 2);
    assert.strictEqual(widgets(editor).length, 2);
    assert.strictEqual(counts.destroyed, 1);
  });

  test('renders with the editor owner', function (this: TestContext, assert) {
    mount(this.owner, '<p>a</p>');

    assert.strictEqual(owners.length, 1);
    assert.strictEqual(owners[0], this.owner);
  });

  test('hands the component root element to ProseMirror', function (this: TestContext, assert) {
    const editor = mount(this.owner, '<p>a</p>');
    const widget = widgets(editor)[0];

    assert.strictEqual(widget?.parentElement?.tagName, 'P');
  });
});
