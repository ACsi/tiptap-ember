import Component from '@glimmer/component';
import type Owner from '@ember/owner';
import type { TOC } from '@ember/component/template-only';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  render,
  clearRender,
  resetOnerror,
  settled,
  setupOnerror,
} from '@ember/test-helpers';
import { modifier } from 'ember-modifier';
import StarterKit from '@tiptap/starter-kit';
import { Mark, Node, type Editor } from '@tiptap/core';
import {
  EmberNodeViewRenderer,
  EmberMarkViewRenderer,
  NodeViewWrapper,
  NodeViewContent,
  MarkViewContent,
  EditorContent,
  type EmberNodeViewSignature,
  type EmberMarkViewSignature,
} from '#src/index.ts';
import { createTestEditor } from '../../helpers/create-test-editor.ts';

// Views live with the editor, not with <EditorContent>

const probe = { created: 0, destroyed: 0 };

class ProbeView extends Component<EmberNodeViewSignature> {
  constructor(owner: Owner, args: EmberNodeViewSignature['Args']) {
    super(owner, args);
    probe.created += 1;
  }

  willDestroy(): void {
    super.willDestroy();
    probe.destroyed += 1;
  }

  <template>
    <NodeViewWrapper @ctx={{@ctx}} data-test-probe>
      <NodeViewContent @ctx={{@ctx}} />
    </NodeViewWrapper>
  </template>
}

const ProbeNode = Node.create({
  name: 'probeNode',
  group: 'block',
  content: 'inline*',
  // A node view still needs HTML (de)serialization for getHTML/copy-paste.
  parseHTML() {
    return [{ tag: 'div[data-probe-node]' }];
  },
  renderHTML() {
    return ['div', { 'data-probe-node': '' }, 0];
  },
  addNodeView() {
    return EmberNodeViewRenderer(ProbeView);
  },
});

// Creates another view from a deferred dispatch, the supported way
const spawnerProbe = { created: 0, destroyed: 0 };
const spawnedProbe = { created: 0, destroyed: 0 };

class SpawnerView extends Component<EmberNodeViewSignature> {
  constructor(owner: Owner, args: EmberNodeViewSignature['Args']) {
    super(owner, args);
    spawnerProbe.created += 1;

    queueMicrotask(() => {
      const { editor } = args;

      if (editor.isDestroyed) {
        return;
      }

      editor.commands.insertContentAt(editor.state.doc.content.size, {
        type: 'spawnedNode',
      });
    });
  }

  willDestroy(): void {
    super.willDestroy();
    spawnerProbe.destroyed += 1;
  }

  <template>
    <NodeViewWrapper @ctx={{@ctx}} data-test-spawner>spawner</NodeViewWrapper>
  </template>
}

class SpawnedView extends Component<EmberNodeViewSignature> {
  constructor(owner: Owner, args: EmberNodeViewSignature['Args']) {
    super(owner, args);
    spawnedProbe.created += 1;
  }

  willDestroy(): void {
    super.willDestroy();
    spawnedProbe.destroyed += 1;
  }

  <template>
    <NodeViewWrapper @ctx={{@ctx}} data-test-spawned>spawned</NodeViewWrapper>
  </template>
}

const SpawnerNode = Node.create({
  name: 'spawnerNode',
  group: 'block',
  atom: true,
  addNodeView() {
    return EmberNodeViewRenderer(SpawnerView);
  },
});

const SpawnedNode = Node.create({
  name: 'spawnedNode',
  group: 'block',
  atom: true,
  addNodeView() {
    return EmberNodeViewRenderer(SpawnedView);
  },
});

// Same dispatch, but during its own render
class SyncSpawnerView extends Component<EmberNodeViewSignature> {
  constructor(owner: Owner, args: EmberNodeViewSignature['Args']) {
    super(owner, args);

    args.editor.commands.insertContentAt(args.editor.state.doc.content.size, {
      type: 'spawnedNode',
    });
  }

  <template>
    <NodeViewWrapper @ctx={{@ctx}} data-test-sync-spawner>sync</NodeViewWrapper>
  </template>
}

let spawnedOnUpdate = false;

// Creates another view while Ember re-renders this one
class UpdateSpawnerView extends Component<
  EmberNodeViewSignature<{ count: number }>
> {
  spawn = modifier((_: HTMLElement, [count]: [number]) => {
    if (count > 0 && !spawnedOnUpdate) {
      spawnedOnUpdate = true;

      const { editor } = this.args;

      editor.commands.insertContentAt(editor.state.doc.content.size, {
        type: 'spawnedNode',
      });
    }
  });

  <template>
    <NodeViewWrapper @ctx={{@ctx}} {{this.spawn @attrs.count}}>
      update
    </NodeViewWrapper>
  </template>
}

const UpdateSpawnerNode = Node.create({
  name: 'updateSpawnerNode',
  group: 'block',
  atom: true,
  addAttributes() {
    return { count: { default: 0 } };
  },
  addNodeView() {
    return EmberNodeViewRenderer(UpdateSpawnerView);
  },
});

const SyncSpawnerNode = Node.create({
  name: 'syncSpawnerNode',
  group: 'block',
  atom: true,
  addNodeView() {
    return EmberNodeViewRenderer(SyncSpawnerView);
  },
});

const HighlightView: TOC<EmberMarkViewSignature> = <template>
  <MarkViewContent data-test-highlight ...attributes @ctx={{@ctx}} />
</template>;

const HighlightMark = Mark.create({
  name: 'highlightMark',
  inclusive: false,
  addMarkView() {
    return EmberMarkViewRenderer(HighlightView);
  },
});

const ctx: { editor: Editor } = { editor: null as unknown as Editor };

function insertProbeNode(editor: Editor, text: string) {
  editor
    .chain()
    .focus()
    .insertContent({
      type: 'probeNode',
      content: [{ type: 'text', text }],
    })
    .run();
}

module(
  'Integration | Editor | editor outlives <EditorContent>',
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      probe.created = 0;
      probe.destroyed = 0;
      spawnerProbe.created = 0;
      spawnerProbe.destroyed = 0;
      spawnedProbe.created = 0;
      spawnedProbe.destroyed = 0;
      spawnedOnUpdate = false;
      ctx.editor = createTestEditor({
        extensions: [
          StarterKit,
          ProbeNode,
          SpawnerNode,
          SpawnedNode,
          SyncSpawnerNode,
          UpdateSpawnerNode,
          HighlightMark,
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

    test('node view components survive host unmount and are torn down with the editor', async function (assert) {
      await render(
        <template><EditorContent @editor={{ctx.editor}} /></template>,
      );
      insertProbeNode(ctx.editor, 'kept-text');
      await settled();

      assert
        .dom('[data-test-probe]')
        .exists('node view rendered while mounted');
      assert.true(probe.created > 0, 'probe component instantiated');

      const createdWhileMounted = probe.created;

      await clearRender();

      assert.false(ctx.editor.isDestroyed, 'editor survives the unmount');
      assert.strictEqual(
        probe.destroyed,
        0,
        'view components are NOT torn down on host unmount (they live with the editor)',
      );

      ctx.editor.commands.insertContentAt(
        ctx.editor.state.doc.content.size,
        '<p>appended-offline</p>',
      );

      assert.true(
        ctx.editor.getHTML().includes('appended-offline'),
        'the surviving editor still accepts commands',
      );
      assert.true(
        ctx.editor.getHTML().includes('kept-text'),
        'document content is preserved',
      );

      ctx.editor.destroy();
      await settled();

      assert.strictEqual(
        probe.destroyed,
        createdWhileMounted,
        'every node view component is torn down when the editor is destroyed',
      );
    });

    test('remounting a surviving editor reattaches node views without recreating them', async function (assert) {
      await render(
        <template><EditorContent @editor={{ctx.editor}} /></template>,
      );
      insertProbeNode(ctx.editor, 'kept-text');
      await settled();

      await clearRender();

      assert.strictEqual(
        probe.destroyed,
        0,
        'the view survives while the editor lives on, unhosted',
      );

      ctx.editor.commands.insertContentAt(ctx.editor.state.doc.content.size, {
        type: 'probeNode',
        content: [{ type: 'text', text: 'offline-born' }],
      });
      await settled();

      const createdBeforeRemount = probe.created;

      await render(
        <template><EditorContent @editor={{ctx.editor}} /></template>,
      );

      assert
        .dom('[data-test-probe]')
        .exists({ count: 2 }, 'both node views render after remount');
      assert.strictEqual(
        probe.created,
        createdBeforeRemount,
        'remount reattaches the existing views instead of recreating them',
      );
      assert
        .dom('[data-tiptap-ember-editor]')
        .includesText('kept-text', 'contentDOM text reattached')
        .includesText('offline-born', 'node view born while unhosted renders');
    });

    test('marked content survives unmount and remount of the host', async function (assert) {
      await render(
        <template><EditorContent @editor={{ctx.editor}} /></template>,
      );
      ctx.editor
        .chain()
        .focus()
        .insertContent({
          type: 'text',
          text: 'marked-kept',
          marks: [{ type: 'highlightMark' }],
        })
        .run();
      await settled();

      assert.dom('[data-test-highlight]').exists('mark view rendered');

      await clearRender();
      await render(
        <template><EditorContent @editor={{ctx.editor}} /></template>,
      );

      assert
        .dom('[data-test-highlight]')
        .exists('mark view rendered again after remount')
        .includesText('marked-kept');
    });

    test("a view inserted by another view's deferred dispatch is destroyed with the editor", async function (assert) {
      await render(
        <template><EditorContent @editor={{ctx.editor}} /></template>,
      );
      ctx.editor.commands.insertContentAt(ctx.editor.state.doc.content.size, {
        type: 'spawnerNode',
      });
      await settled();

      assert.dom('[data-test-spawner]').exists('spawner view rendered');
      assert
        .dom('[data-test-spawned]')
        .exists('view inserted by the spawner rendered');
      assert.strictEqual(
        spawnerProbe.created,
        1,
        'spawner component constructed exactly once',
      );
      assert.strictEqual(
        spawnedProbe.created,
        1,
        'spawned component constructed exactly once',
      );

      await clearRender();

      assert.strictEqual(
        spawnerProbe.destroyed,
        0,
        'spawner survives host unmount (lives with the editor)',
      );
      assert.strictEqual(
        spawnedProbe.destroyed,
        0,
        'spawned view survives host unmount',
      );

      ctx.editor.destroy();
      await settled();

      assert.strictEqual(
        spawnerProbe.destroyed,
        spawnerProbe.created,
        'spawner component destroyed with the editor',
      );
      assert.strictEqual(
        spawnedProbe.destroyed,
        spawnedProbe.created,
        'spawned component destroyed with the editor',
      );
    });

    test('a synchronous view-creating dispatch during render fails fast', async function (assert) {
      await render(
        <template><EditorContent @editor={{ctx.editor}} /></template>,
      );

      assert.throws(
        () => {
          ctx.editor.commands.insertContentAt(
            ctx.editor.state.doc.content.size,
            {
              type: 'syncSpawnerNode',
            },
          );
        },
        /Cannot render a component while another tiptap-ember component is rendering/,
        're-entrancy guard rejects the nested render with the actionable error',
      );

      assert.strictEqual(
        spawnedProbe.created,
        0,
        'no spawned component was constructed (nothing was enqueued)',
      );
    });

    test('a view-creating dispatch during an Ember re-render fails with a clear error', async function (assert) {
      setupOnerror((error: Error) => {
        assert.step(error.message);
      });

      await render(
        <template><EditorContent @editor={{ctx.editor}} /></template>,
      );
      ctx.editor.commands.insertContentAt(0, { type: 'updateSpawnerNode' });
      await settled();

      ctx.editor.view.dispatch(
        ctx.editor.state.tr.setNodeMarkup(0, undefined, { count: 1 }),
      );
      await settled();

      assert.verifySteps([
        '[tiptap-ember] Cannot render a component while Ember is rendering. ' +
          'Move the transaction out of the render, for example with queueMicrotask().',
      ]);
    });
  },
);
