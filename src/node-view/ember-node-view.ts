import { tracked } from '@glimmer/tracking';
import type { ComponentLike } from '@glint/template';
import {
  isNodeViewSelected,
  NodeView,
  type DecorationWithType,
  type Editor,
  type Node as TiptapNode,
  type NodeViewRendererOptions,
  type NodeViewRendererProps,
} from '@tiptap/core';
import type { Node as ProseMirrorNode } from '@tiptap/pm/model';
import { NodeSelection } from '@tiptap/pm/state';
import type {
  Decoration,
  DecorationAttrs,
  DecorationSource,
  EditorView,
} from '@tiptap/pm/view';
import { EmberRenderer } from '../renderer/ember-renderer.ts';
import { createNodeViewContext, type NodeViewContext } from './context.ts';

/**
 * The args a node view component receives.
 */
export interface EmberNodeViewArgs<TAttrs = Record<string, unknown>> {
  editor: Editor;
  node: ProseMirrorNode;
  attrs: Readonly<TAttrs>;
  decorations: readonly Decoration[];

  /**
   * Decorations inside the node. Only needed when you render the content
   * yourself instead of with `<NodeViewContent>`.
   */
  innerDecorations: DecorationSource;
  view: EditorView;
  selected: boolean;
  extension: TiptapNode;
  getPos: () => number | undefined;
  HTMLAttributes: Record<string, unknown>;
  updateAttributes: (patch: Partial<TAttrs>) => void;
  deleteNode: () => void;

  /**
   * Pass this to `<NodeViewWrapper>` and `<NodeViewContent>`.
   */
  ctx: NodeViewContext;
}

export interface EmberNodeViewSignature<TAttrs = Record<string, unknown>> {
  Args: EmberNodeViewArgs<TAttrs>;
  Element: HTMLElement;
}

export interface EmberNodeViewRendererOptions extends NodeViewRendererOptions {
  /**
   * Replaces the default update. Call `updateProps()` to re-render the
   * component and return whether the update was handled.
   */
  update:
    | ((props: {
        oldNode: ProseMirrorNode;
        oldDecorations: readonly Decoration[];
        oldInnerDecorations: DecorationSource;
        newNode: ProseMirrorNode;
        newDecorations: readonly Decoration[];
        innerDecorations: DecorationSource;
        updateProps: () => void;
      }) => boolean)
    | null;
}

/**
 * Renders an Ember component as a node view.
 * @see https://tiptap.dev/guide/node-views
 */
export class EmberNodeView<TAttrs = Record<string, unknown>> extends NodeView<
  ComponentLike<EmberNodeViewSignature<TAttrs>>,
  Editor,
  EmberNodeViewRendererOptions
> {
  private readonly renderer: EmberRenderer<EmberNodeViewArgs<TAttrs>>;
  private readonly contentDOMElement: HTMLElement | null;
  @tracked private decorationClasses = '';
  private currentPos: number | undefined;
  private cachedExtensionWithSyncedStorage:
    | NodeViewRendererProps['extension']
    | null = null;

  private readonly handleDragStart = (event: DragEvent): void => {
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

    const { state } = this.editor.view;
    const { selection } = state;

    if (selection instanceof NodeSelection && selection.from === pos) {
      return;
    }

    this.editor.view.dispatch(
      state.tr.setSelection(NodeSelection.create(state.doc, pos)),
    );
  };

  // ProseMirror doesn't call update() when only the position changes
  private readonly handlePositionUpdate = (): void => {
    const newPos = this.getPos();

    if (typeof newPos !== 'number' || newPos === this.currentPos) {
      return;
    }

    this.currentPos = newPos;
    this.renderer.updateProps({ getPos: () => this.getPos() });
  };

  constructor(
    component: ComponentLike<EmberNodeViewSignature<TAttrs>>,
    props: NodeViewRendererProps,
    options: Partial<EmberNodeViewRendererOptions>,
  ) {
    super(component, props, options);

    // Set up here, not in mount(): super() calls mount() before our fields exist
    if (this.node.isLeaf) {
      this.contentDOMElement = null;
    } else {
      const contentDOM = document.createElement(
        this.options.contentDOMElementTag ||
          (this.node.isInline ? 'span' : 'div'),
      );
      contentDOM.dataset['nodeViewContent'] = '';
      contentDOM.style.whiteSpace = 'pre-wrap';
      this.contentDOMElement = contentDOM;
    }

    this.decorationClasses = this.getDecorationClasses();

    const ctx = createNodeViewContext({
      contentDOM: this.contentDOMElement,
      nodeName: this.node.type.name,
      kind: 'node',
      onDragStart: this.handleDragStart,
      getDecorationClasses: () => this.decorationClasses,
    });

    this.renderer = new EmberRenderer<EmberNodeViewArgs<TAttrs>>(
      this.component,
      {
        editor: this.editor,
        props: {
          editor: this.editor,
          node: this.node,
          attrs: this.node.attrs as Readonly<TAttrs>,
          decorations: this.decorations,
          innerDecorations: this.innerDecorations,
          view: this.view,
          selected: false,
          extension: this.extensionWithSyncedStorage,
          HTMLAttributes: this.HTMLAttributes,
          getPos: () => this.getPos(),
          updateAttributes: (patch) => {
            this.updateAttributes(patch);
          },
          deleteNode: () => {
            this.deleteNode();
          },
          ctx,
        },
      },
    );

    this.editor.on('selectionUpdate', this.handleSelectionUpdate);

    if (this.options.trackNodeViewPosition) {
      this.editor.on('update', this.handlePositionUpdate);
    }

    this.currentPos = this.getPos();
  }

  // Reads `storage` from the editor, keeping the extension's prototype
  private get extensionWithSyncedStorage(): NodeViewRendererProps['extension'] {
    if (!this.cachedExtensionWithSyncedStorage) {
      const { editor, extension } = this;

      this.cachedExtensionWithSyncedStorage = new Proxy(extension, {
        get(target, prop, receiver) {
          if (prop === 'storage') {
            const storage = editor.storage as unknown as Record<
              string,
              unknown
            >;

            return storage[extension.name] ?? {};
          }

          return Reflect.get(target, prop, receiver) as unknown;
        },
      });
    }

    return this.cachedExtensionWithSyncedStorage;
  }

  override get dom(): HTMLElement {
    const element = this.renderer.element;

    if (!element || !element.hasAttribute('data-node-view-wrapper')) {
      throw Error(
        'Please use the NodeViewWrapper component for your node view.',
      );
    }

    return element as HTMLElement;
  }

  override get contentDOM(): HTMLElement | null {
    return this.contentDOMElement;
  }

  private readonly handleSelectionUpdate = (): void => {
    const pos = this.getPos();

    if (typeof pos !== 'number') {
      return;
    }

    const isSelected = isNodeViewSelected({
      selection: this.editor.state.selection,
      pos,
      nodeSize: this.node.nodeSize,
      selectedOnTextSelection: this.options.selectedOnTextSelection,
    });

    if (isSelected) {
      if (!this.renderer.props.selected) {
        this.selectNode();
      }
    } else {
      if (this.renderer.props.selected) {
        this.deselectNode();
      }
    }
  };

  update(
    node: ProseMirrorNode,
    decorations: readonly Decoration[],
    innerDecorations: DecorationSource,
  ): boolean {
    const rerenderComponent = (): void => {
      this.renderer.updateProps({
        node: this.node,
        decorations: this.decorations,
        innerDecorations: this.innerDecorations,
        attrs: this.node.attrs as Readonly<TAttrs>,
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
        updateProps: rerenderComponent,
      });
    }

    if (node.type !== this.node.type) {
      return false;
    }

    if (
      node === this.node &&
      decorations === this.decorations &&
      innerDecorations === this.innerDecorations
    ) {
      return true;
    }

    this.node = node;
    this.decorations = decorations;
    this.innerDecorations = innerDecorations;
    this.currentPos = this.getPos();
    this.syncDecorationClasses();

    if (this.options.trackNodeViewPosition) {
      this.renderer.updateProps({ getPos: () => this.getPos() });
    }

    rerenderComponent();

    return true;
  }

  selectNode() {
    this.renderer.updateProps({
      selected: true,
    });

    this.renderer.element?.classList.add('ProseMirror-selectednode');
  }

  deselectNode() {
    this.renderer.updateProps({
      selected: false,
    });

    this.renderer.element?.classList.remove('ProseMirror-selectednode');
  }

  // eslint-disable-next-line ember/classic-decorator-hooks
  destroy(): void {
    this.renderer.destroy();
    this.editor.off('selectionUpdate', this.handleSelectionUpdate);

    if (this.options.trackNodeViewPosition) {
      this.editor.off('update', this.handlePositionUpdate);
    }
  }

  // Also bound by <NodeViewWrapper>, so a re-render doesn't drop them
  private getDecorationClasses(): string {
    return this.decorations
      .map((decoration) => {
        // ProseMirror allows decorations without attrs
        const attrs: DecorationAttrs | undefined = (
          decoration as DecorationWithType
        ).type.attrs;

        return attrs?.class;
      })
      .filter((value): value is string => Boolean(value))
      .join(' ');
  }

  // A tracked set always invalidates, so skip unchanged values
  private syncDecorationClasses(): void {
    const classes = this.getDecorationClasses();

    if (classes !== this.decorationClasses) {
      this.decorationClasses = classes;
    }
  }
}
