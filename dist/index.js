import { Editor as Editor$1, NodeView, isNodeViewSelected, MarkView, createWidgetDecoration } from '@tiptap/core';
export * from '@tiptap/core';
import { tracked } from '@glimmer/tracking';
import { buildWaiter } from '@ember/test-waiters';
import { g, i } from 'decorator-transforms/runtime-esm';
import { assert, warn } from '@ember/debug';
import { registerDestructor, destroy } from '@ember/destroyable';
import { getOwner, setOwner } from '@ember/owner';
import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';
import { element as element$1 } from '@ember/helper';
import { NodeSelection } from '@tiptap/pm/state';
import { trackedObject } from '@ember/reactive/collections';
import { renderComponent } from '@ember/renderer';

const waiter$1 = buildWaiter('@acsi/tiptap-ember:editor');

// A change signal only. Reads always return the live state.
class Signal {
  static {
    g(this.prototype, "revision", [tracked], function () {
      return 0;
    });
  }
  #revision = (i(this, "revision"), void 0);
}

// Outside the instance, so the base constructor's reads can entangle it
const signals = new WeakMap();
function signalFor(editor) {
  let signal = signals.get(editor);
  if (!signal) {
    signal = new Signal();
    signals.set(editor, signal);
  }
  return signal;
}

/**
 * A tiptap editor whose state is autotracked. Getters and templates that read
 * it update after every transaction.
 * @example
 * get isBold() {
 *   return this.editor.isActive('bold');
 * }
 */
class Editor extends Editor$1 {
  // Undefined during super(), whose reads must entangle too
  untrackedDepth = 0;
  bumpScheduled = false;

  // `isDestroyed` is also true for a headless or unmounted editor
  disposed = false;
  constructor(options = {}) {
    super(options);
    this.on('beforeTransaction', () => {
      this.scheduleBump();
    });
    this.on('destroy', () => {
      this.disposed = true;
    });
  }
  get state() {
    this.entangle();
    return super.state;
  }
  get storage() {
    this.entangle();
    return super.storage;
  }

  // Untracked, so a menu modifier doesn't re-run on its own registration
  registerPlugin(plugin, handlePlugins) {
    this.untrackedDepth += 1;
    try {
      return super.registerPlugin(plugin, handlePlugins);
    } finally {
      this.untrackedDepth -= 1;
      this.scheduleBump();
    }
  }
  unregisterPlugin(nameOrPluginKeyToRemove) {
    this.untrackedDepth += 1;
    try {
      return super.unregisterPlugin(nameOrPluginKeyToRemove);
    } finally {
      this.untrackedDepth -= 1;
      this.scheduleBump();
    }
  }
  entangle() {
    if (!this.untrackedDepth) {
      void signalFor(this).revision;
    }
  }

  // Deferred: Glimmer forbids changing tracked state it read in the same render
  scheduleBump() {
    if (this.bumpScheduled) {
      return;
    }
    this.bumpScheduled = true;
    const token = waiter$1.beginAsync();
    queueMicrotask(() => {
      this.bumpScheduled = false;
      if (!this.disposed) {
        signalFor(this).revision += 1;
      }
      waiter$1.endAsync(token);
    });
  }
}

/**
 * Creates an editor that is destroyed together with `parent`.
 * @param parent The component or service that owns the editor, usually `this`.
 * @param options The editor options.
 * @returns The editor.
 * @example
 * editor = useEditor(this, {
 *   extensions: [StarterKit],
 *   content: '<p>Hello World!</p>',
 * });
 */
function useEditor(parent, options = {}) {
  assert('[tiptap-ember] useEditor() needs a browser. Render the editor outside FastBoot.', typeof document !== 'undefined');
  const owner = getOwner(parent);
  const editor = new Editor({
    ...options,
    // Set the owner before the initial content renders any view
    onBeforeCreate(props) {
      if (owner) {
        setOwner(props.editor, owner);
      }
      options.onBeforeCreate?.(props);
    }
  });
  registerDestructor(parent, () => {
    editor.destroy();
  });
  return editor;
}

const mountEditor = modifier(function mountEditor(element, [editor, owner]) {
  // Fallback for editors not created with `useEditor`
  if (!getOwner(editor)) {
    setOwner(editor, owner);
  }
  // Also true for an editor without a view, e.g. `element: null`
  if (editor.isDestroyed) {
    return;
  }
  const parent = editor.view.dom.parentNode;
  assert('[tiptap-ember] An editor can only be rendered by one <EditorContent> at a time.', !(parent instanceof Element && parent.hasAttribute('data-tiptap-ember-editor')));
  // Plugins may have added elements next to the editor
  const nodes = parent ? [...parent.childNodes] : [editor.view.dom];
  element.append(...nodes);
  return () => {
    if (editor.isDestroyed) {
      return;
    }
    // Detached, so the editor outlives this element
    document.createElement('div').append(...nodes.filter(node => node.parentNode === element));
  };
});
/**
 * Renders the editor.
 * @example
 * <EditorContent @editor={{this.editor}} />
 */
class EditorContent extends Component {
  get owner() {
    const owner = getOwner(this);
    assert('[tiptap-ember] <EditorContent> needs an owner.', owner);
    return owner;
  }
  static {
    setComponentTemplate(precompileTemplate("<div data-tiptap-ember-editor ...attributes {{mountEditor @editor this.owner}}>\n  {{~yield (hash editor=@editor)~}}\n</div>", {
      strictMode: true,
      scope: () => ({
        mountEditor
      })
    }), this);
  }
}

// Retyped: Glint can't resolve the keyword's element type for a generic tag
const element = element$1;

const noop = () => {};
/**
 * The root element of a node view component.
 * @example
 * <NodeViewWrapper @ctx={{@ctx}} class="callout">
 *   <NodeViewContent @ctx={{@ctx}} />
 * </NodeViewWrapper>
 */
class NodeViewWrapper extends Component {
  // ProseMirror keeps the first element as the node view's dom
  initialAs = this.args.as;
  // Exactly `T`, so `...attributes` keeps the signature's element type
  get tag() {
    assert('[tiptap-ember] <NodeViewWrapper>: `@as` must be a tag name; an empty ' + 'string renders no element.', this.args.as !== '');
    assert('[tiptap-ember] <NodeViewWrapper>: `@as` cannot change after the first render.', this.args.as === this.initialAs);
    return this.args.as ?? 'div';
  }
  get onDragStart() {
    return this.args.ctx.onDragStart ?? noop;
  }
  get decorationClasses() {
    return this.args.ctx.decorationClasses || undefined;
  }
  static {
    setComponentTemplate(precompileTemplate("{{!-- template-lint-disable no-inline-styles --}}\n{{~#let (element this.tag) as |Tag|~}}\n  <Tag {{!-- @glint-expect-error generic Element defers Glint attribute lookup --}} data-node-view-wrapper class={{this.decorationClasses}} style=\"white-space: normal;\" {{!-- Capture, so core runs before listeners from ...attributes --}} {{on \"dragstart\" this.onDragStart capture=true}} ...attributes>\n    {{~yield~}}\n  </Tag>\n{{~/let~}}", {
      strictMode: true,
      scope: () => ({
        element
      })
    }), this);
  }
}

/**
 * Connects `<NodeViewWrapper>`, `<NodeViewContent>` and `<MarkViewContent>`
 * to their view. Pass it on as `@ctx={{@ctx}}`.
 */

function createNodeViewContext(init) {
  return {
    contentDOM: init.contentDOM,
    nodeName: init.nodeName,
    kind: init.kind,
    onDragStart: init.onDragStart,
    get decorationClasses() {
      return init.getDecorationClasses?.();
    }
  };
}
const warnedLeafContexts = new WeakSet();
const attachContentDOM = modifier(function attachContentDOM(element, _positional, {
  ctx
}) {
  const {
    contentDOM
  } = ctx;
  if (!contentDOM) {
    if (!warnedLeafContexts.has(ctx)) {
      warnedLeafContexts.add(ctx);
      const tag = ctx.kind === 'mark' ? 'MarkViewContent' : 'NodeViewContent';
      warn(`[tiptap-ember] <${tag}> has no content to show in the leaf ${ctx.kind} "${ctx.nodeName}". Remove it.`, {
        id: 'tiptap-ember.leaf-content'
      });
    }
    return undefined;
  }
  element.appendChild(contentDOM);
  return () => {
    // A replacement host may already hold it
    if (contentDOM.parentNode === element) {
      contentDOM.remove();
    }
  };
});

/**
 * Where the editable content of a node view goes.
 * @example
 * <NodeViewContent @ctx={{@ctx}} class="content" />
 */
class NodeViewContent extends Component {
  // Exactly `T`, so `...attributes` keeps the signature's element type
  get tag() {
    assert('[tiptap-ember] <NodeViewContent>: `@as` must be a tag name; an empty ' + 'string renders no element.', this.args.as !== '');
    return this.args.as ?? 'div';
  }
  static {
    setComponentTemplate(precompileTemplate("{{~#let (element this.tag) as |Tag|~}}\n  <Tag {{!-- @glint-expect-error generic Element defers Glint attribute lookup --}} data-node-view-content-host ...attributes {{attachContentDOM ctx=@ctx}} />\n{{~/let~}}", {
      strictMode: true,
      scope: () => ({
        element,
        attachContentDOM
      })
    }), this);
  }
}

/**
 * Where the marked text of a mark view goes.
 * @example
 * <span class="highlight">
 *   <MarkViewContent @ctx={{@ctx}} />
 * </span>
 */
class MarkViewContent extends Component {
  // Exactly `T`, so `...attributes` keeps the signature's element type
  get tag() {
    assert('[tiptap-ember] <MarkViewContent>: `@as` must be a tag name; an empty ' + 'string renders no element.', this.args.as !== '');
    return this.args.as ?? 'span';
  }
  static {
    setComponentTemplate(precompileTemplate("{{~#let (element this.tag) as |Tag|~}}\n  <Tag {{!-- @glint-expect-error generic Element defers Glint attribute lookup --}} data-mark-view-content-host ...attributes {{attachContentDOM ctx=@ctx}} />\n{{~/let~}}", {
      strictMode: true,
      scope: () => ({
        element,
        attachContentDOM
      })
    }), this);
  }
}

/**
 * The signature of a component rendered by `EmberRenderer`.
 * Props from the first render are also named args. Props added later are
 * only in `@props`.
 */

// Glimmer can't render re-entrantly. A queued root could never be destroyed.
let rendering = false;

// Rendering revalidates all of the renderer's roots, so a render around it
// may have read any view. Reset on the next microtask.
let renderedThisTurn = false;
function hasRenderedThisTurn() {
  return renderedThisTurn;
}
function markRendered() {
  if (renderedThisTurn) {
    return;
  }
  renderedThisTurn = true;
  queueMicrotask(() => {
    renderedThisTurn = false;
  });
}

// Ember keeps one renderer per owner. A host rendering with the same owner,
// like test-helpers' render(), would queue views created during its render.
const viewOwners = new WeakMap();
function viewOwnerFor(owner) {
  let viewOwner = viewOwners.get(owner);
  if (!viewOwner) {
    // Inherits lookups, so views get the same services. Not a destroyable
    // child of `owner`: owner teardown would pull views out of a live editor.
    viewOwner = Object.create(owner);
    viewOwners.set(owner, viewOwner);
    // An editor created inside a view renders through the same renderer
    viewOwners.set(viewOwner, viewOwner);
  }
  return viewOwner;
}

/**
 * Renders an Ember component into a detached element, for example a
 * suggestion popup. The component must render a single root element.
 * @example
 * const renderer = new EmberRenderer(MentionList, {
 *   editor,
 *   props: { items, command },
 * });
 *
 * document.body.appendChild(renderer.element);
 */
class EmberRenderer {
  renderedComponent;
  editor;
  component;
  renderRoot;

  /**
   * The current props. Changes re-render the component.
   */
  props;
  destroyed = false;
  constructor(component, {
    props,
    editor
  }) {
    this.editor = editor;
    this.component = component;
    this.props = trackedObject(props ?? {});
    const renderRoot = document.createElement('div');
    this.renderRoot = renderRoot;
    this.renderedComponent = this.renderComponent(renderRoot);
  }

  /**
   * The component's root element.
   */
  get element() {
    if (this.renderedComponent.el === null && this.renderRoot) {
      this.renderedComponent.el = this.renderRoot.firstElementChild;
    }
    return this.renderedComponent.el;
  }
  renderComponent(renderRoot) {
    const props = this.props;
    const args = {};

    // Each initial prop is also a named arg, which is how views get `@node`
    for (const key of Object.keys(props)) {
      Object.defineProperty(args, key, {
        enumerable: true,
        get: () => props[key]
      });
    }
    if (!('props' in args)) {
      Object.defineProperty(args, 'props', {
        enumerable: true,
        get: () => this.props
      });
    }
    const owner = getOwner(this.editor);
    assert('[tiptap-ember] The editor has no owner. Create it with `useEditor(this, …)` ' + 'or call `setOwner()` in `onBeforeCreate`.', owner);
    if (rendering) {
      throw new Error('[tiptap-ember] Cannot render a component while another tiptap-ember ' + 'component is rendering. Move the transaction out of the render, ' + 'for example with queueMicrotask().');
    }
    const viewOwner = viewOwnerFor(owner);
    rendering = true;
    markRendered();
    let result;
    try {
      result = renderComponent(this.component, {
        into: renderRoot,
        owner: viewOwner,
        args
      });
    } finally {
      rendering = false;
    }

    // Ember queues a root added during its own render, so nothing is rendered yet
    if (!renderRoot.firstChild) {
      throw new Error('[tiptap-ember] Cannot render a component while Ember is rendering. ' + 'Move the transaction out of the render, for example with queueMicrotask().');
    }
    registerDestructor(this, () => {
      this.destroy();
    });
    const destroy = () => {
      const element = this.element;

      // Move the element back so Glimmer can remove it
      if (element && element.parentNode !== renderRoot) {
        renderRoot.appendChild(element);
      }
      result.destroy();
      this.renderRoot = null;
    };
    return {
      result,
      destroy,
      el: renderRoot.firstElementChild
    };
  }

  /**
   * Merges new props into the current props.
   * @param props The props to change.
   */
  updateProps(props) {
    if (this.destroyed) {
      return;
    }
    const bag = this.props;
    Object.entries(props).forEach(([key, value]) => {
      bag[key] = value;
    });
  }

  /**
   * Destroys the component and removes its element.
   */
  destroy() {
    if (this.destroyed) {
      return;
    }
    this.destroyed = true;
    this.renderedComponent.destroy();
    destroy(this);
  }
}

const waiter = buildWaiter('@acsi/tiptap-ember:node-view');

/**
 * The args a node view component receives.
 */

/**
 * Renders an Ember component as a node view.
 * @see https://tiptap.dev/guide/node-views
 */
class EmberNodeView extends NodeView {
  renderer;
  contentDOMElement;
  static {
    g(this.prototype, "decorationClasses", [tracked], function () {
      return '';
    });
  }
  #decorationClasses = (i(this, "decorationClasses"), void 0);
  currentPos;
  cachedExtensionWithSyncedStorage = null;

  // Compared instead of the tracked values. Reading those inside a render
  // would make our own write assert.
  syncedDecorationClasses = '';
  nodeSelected = false;

  // Writes held by `holdsWrites`, applied on the next microtask
  heldProps = null;
  handleDragStart = event => {
    this.onDragStart(event);

    // Chromium retargets dragstart to the wrapper, so core misses the handle.
    // Select this node ourselves, or ProseMirror drags the old selection.
    if (!this.isDragging || event.target !== this.renderer.element) {
      return;
    }
    const pos = this.getPos();
    if (typeof pos !== 'number' || !NodeSelection.isSelectable(this.node)) {
      return;
    }
    const {
      state
    } = this.editor.view;
    const {
      selection
    } = state;
    if (selection instanceof NodeSelection && selection.from === pos) {
      return;
    }
    this.editor.view.dispatch(state.tr.setSelection(NodeSelection.create(state.doc, pos)));
  };

  // ProseMirror doesn't call update() when only the position changes
  handlePositionUpdate = () => {
    const newPos = this.getPos();
    if (typeof newPos !== 'number' || newPos === this.currentPos) {
      return;
    }
    this.currentPos = newPos;
    this.updateProps({
      getPos: () => this.getPos()
    });
  };
  constructor(component, props, options) {
    super(component, props, options);

    // Set up here, not in mount(): super() calls mount() before our fields exist
    if (this.node.isLeaf) {
      this.contentDOMElement = null;
    } else {
      const contentDOM = document.createElement(this.options.contentDOMElementTag || (this.node.isInline ? 'span' : 'div'));
      contentDOM.dataset['nodeViewContent'] = '';
      contentDOM.style.whiteSpace = 'pre-wrap';
      this.contentDOMElement = contentDOM;
    }
    this.syncedDecorationClasses = this.getDecorationClasses();
    this.decorationClasses = this.syncedDecorationClasses;
    const ctx = createNodeViewContext({
      contentDOM: this.contentDOMElement,
      nodeName: this.node.type.name,
      kind: 'node',
      onDragStart: this.handleDragStart,
      getDecorationClasses: () => this.decorationClasses
    });
    this.renderer = new EmberRenderer(this.component, {
      editor: this.editor,
      props: {
        editor: this.editor,
        node: this.node,
        attrs: this.node.attrs,
        decorations: this.decorations,
        innerDecorations: this.innerDecorations,
        view: this.view,
        selected: false,
        extension: this.extensionWithSyncedStorage,
        HTMLAttributes: this.HTMLAttributes,
        getPos: () => this.getPos(),
        updateAttributes: patch => {
          this.updateAttributes(patch);
        },
        deleteNode: () => {
          this.deleteNode();
        },
        ctx
      }
    });
    this.editor.on('selectionUpdate', this.handleSelectionUpdate);
    if (this.options.trackNodeViewPosition) {
      this.editor.on('update', this.handlePositionUpdate);
    }
    this.currentPos = this.getPos();
  }

  // Reads `storage` from the editor, keeping the extension's prototype
  get extensionWithSyncedStorage() {
    if (!this.cachedExtensionWithSyncedStorage) {
      const {
        editor,
        extension
      } = this;
      this.cachedExtensionWithSyncedStorage = new Proxy(extension, {
        get(target, prop, receiver) {
          if (prop === 'storage') {
            const storage = editor.storage;
            return storage[extension.name] ?? {};
          }
          return Reflect.get(target, prop, receiver);
        }
      });
    }
    return this.cachedExtensionWithSyncedStorage;
  }
  get dom() {
    const element = this.renderer.element;
    if (!element || !element.hasAttribute('data-node-view-wrapper')) {
      throw Error('Please use the NodeViewWrapper component for your node view.');
    }
    return element;
  }
  get contentDOM() {
    return this.contentDOMElement;
  }
  handleSelectionUpdate = () => {
    const pos = this.getPos();
    if (typeof pos !== 'number') {
      return;
    }
    const isSelected = isNodeViewSelected({
      selection: this.editor.state.selection,
      pos,
      nodeSize: this.node.nodeSize,
      selectedOnTextSelection: this.options.selectedOnTextSelection
    });
    if (isSelected) {
      if (!this.nodeSelected) {
        this.selectNode();
      }
    } else {
      if (this.nodeSelected) {
        this.deselectNode();
      }
    }
  };
  update(node, decorations, innerDecorations) {
    const rerenderComponent = () => {
      this.updateProps({
        node: this.node,
        decorations: this.decorations,
        innerDecorations: this.innerDecorations,
        attrs: this.node.attrs
      });
    };
    if (typeof this.options.update === 'function') {
      const oldNode = this.node;
      const oldDecorations = this.decorations;
      const oldInnerDecorations = this.innerDecorations;
      this.node = node;
      this.decorations = decorations;
      this.innerDecorations = innerDecorations;
      this.currentPos = this.getPos();
      this.syncDecorationClasses();
      return this.options.update({
        oldNode,
        oldDecorations,
        oldInnerDecorations,
        newNode: node,
        newDecorations: decorations,
        innerDecorations,
        updateProps: rerenderComponent
      });
    }
    if (node.type !== this.node.type) {
      return false;
    }
    if (node === this.node && decorations === this.decorations && innerDecorations === this.innerDecorations) {
      return true;
    }
    this.node = node;
    this.decorations = decorations;
    this.innerDecorations = innerDecorations;
    this.currentPos = this.getPos();
    this.syncDecorationClasses();
    if (this.options.trackNodeViewPosition) {
      this.updateProps({
        getPos: () => this.getPos()
      });
    }
    rerenderComponent();
    return true;
  }
  selectNode() {
    this.nodeSelected = true;
    this.updateProps({
      selected: true
    });
    this.renderer.element?.classList.add('ProseMirror-selectednode');
  }
  deselectNode() {
    this.nodeSelected = false;
    this.updateProps({
      selected: false
    });
    this.renderer.element?.classList.remove('ProseMirror-selectednode');
  }

  // eslint-disable-next-line ember/classic-decorator-hooks
  destroy() {
    this.renderer.destroy();
    this.editor.off('selectionUpdate', this.handleSelectionUpdate);
    if (this.options.trackNodeViewPosition) {
      this.editor.off('update', this.handlePositionUpdate);
    }
  }

  // Also bound by <NodeViewWrapper>, so a re-render doesn't drop them
  getDecorationClasses() {
    return this.decorations.map(decoration => {
      // ProseMirror allows decorations without attrs
      const attrs = decoration.type.attrs;
      return attrs?.class;
    }).filter(value => Boolean(value)).join(' ');
  }

  // A tracked set always invalidates, so skip unchanged values
  syncDecorationClasses() {
    if (this.holdsWrites) {
      // Recomputed when the held props apply
      this.holdProps({});
      return;
    }
    const classes = this.getDecorationClasses();
    if (classes !== this.syncedDecorationClasses) {
      this.syncedDecorationClasses = classes;
      this.decorationClasses = classes;
    }
  }

  // Glimmer forbids changing what a render read, and once a view renders,
  // a render around it may have read any view. Later writes wait too, so
  // they stay in order.
  get holdsWrites() {
    return this.heldProps !== null || hasRenderedThisTurn();
  }
  updateProps(props) {
    if (this.holdsWrites) {
      this.holdProps(props);
    } else {
      this.renderer.updateProps(props);
    }
  }
  holdProps(props) {
    if (this.heldProps) {
      Object.assign(this.heldProps, props);
      return;
    }
    const heldProps = {
      ...props
    };
    this.heldProps = heldProps;
    const token = waiter.beginAsync();
    queueMicrotask(() => {
      this.heldProps = null;
      this.syncDecorationClasses();
      this.renderer.updateProps(heldProps);
      waiter.endAsync(token);
    });
  }
}

/**
 * Renders an Ember component as a node view.
 * The component must render a `<NodeViewWrapper>` as its root element.
 * @param component The component to render.
 * @param options The node view options.
 * @returns The node view renderer to return from `addNodeView`.
 * @example
 * addNodeView() {
 *   return EmberNodeViewRenderer(Counter);
 * }
 */
function EmberNodeViewRenderer(component, options = {}) {
  return props => new EmberNodeView(component, props, options);
}

/**
 * The args a mark view component receives.
 */

/**
 * Renders an Ember component as a mark view.
 */
class EmberMarkView extends MarkView {
  contentDOMElement;
  ctx;
  renderer;
  constructor(component, props, options) {
    super(component, props, options);
    this.contentDOMElement = document.createElement('span');
    this.contentDOMElement.dataset['markViewContent'] = '';
    this.contentDOMElement.style.whiteSpace = 'inherit';
    this.ctx = createNodeViewContext({
      contentDOM: this.contentDOMElement,
      nodeName: props.mark.type.name,
      kind: 'mark'
    });

    // Marks have no update(), so the props never change
    this.renderer = new EmberRenderer(component, {
      editor: props.editor,
      props: {
        editor: props.editor,
        mark: props.mark,
        attrs: props.mark.attrs,
        inline: props.inline,
        view: props.view,
        extension: props.extension,
        HTMLAttributes: props.HTMLAttributes,
        updateAttributes: patch => {
          this.updateAttributes(patch);
        },
        ctx: this.ctx
      }
    });
  }
  get dom() {
    const element = this.renderer.element;
    assert('[tiptap-ember] A mark view component must render a single root element.', element);
    return element;
  }
  get contentDOM() {
    return this.contentDOMElement;
  }

  // eslint-disable-next-line ember/classic-decorator-hooks
  destroy() {
    this.renderer.destroy();
  }
}

/**
 * Renders an Ember component as a mark view.
 * The component must render a single root element.
 * @param component The component to render.
 * @param options The mark view options.
 * @returns The mark view renderer to return from `addMarkView`.
 * @example
 * addMarkView() {
 *   return EmberMarkViewRenderer(Highlight);
 * }
 */
function EmberMarkViewRenderer(component, options = {}) {
  return props => new EmberMarkView(component, props, options);
}

/**
 * The args every widget component receives next to its own props.
 */

/**
 * The signature of a component rendered by `EmberWidgetRenderer`.
 * Props from the first render are also named args. Props added later are
 * only in `@props`.
 */

const WIDGET_CACHE = Symbol('tiptapEmberWidgetCache');

/**
 * Renders an Ember component as a widget decoration.
 * The component must render a single root element.
 * @param component The component to render.
 * @param options The widget options.
 * @returns The widget decoration to return from `addDecorations`.
 * @example
 * addDecorations() {
 *   return {
 *     create: ({ editor, state }) =>
 *       findMatches(state.doc).map((match) =>
 *         EmberWidgetRenderer(MatchBadge, {
 *           editor,
 *           pos: match.pos,
 *           key: `match-${match.id}`,
 *           props: { label: match.label },
 *         }),
 *       ),
 *   };
 * }
 */
function EmberWidgetRenderer(component, options) {
  const {
    editor
  } = options;
  const props = options.props ?? {};
  return createWidgetDecoration({
    ...options,
    props,
    cacheKey: WIDGET_CACHE,
    context: getPos => ({
      editor,
      getPos
    }),
    create: renderProps => new EmberRenderer(component, {
      editor,
      props: renderProps
    }),
    materialize: renderer => {
      const element = renderer.element;
      assert('[tiptap-ember] A widget component must render a single root element.', element instanceof HTMLElement);
      return element;
    }
  });
}

export { Editor, EditorContent, EmberMarkView, EmberMarkViewRenderer, EmberNodeView, EmberNodeViewRenderer, EmberRenderer, EmberWidgetRenderer, MarkViewContent, NodeViewContent, NodeViewWrapper, useEditor };
//# sourceMappingURL=index.js.map
