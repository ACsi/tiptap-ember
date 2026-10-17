import type { ComponentLike } from '@glint/template';
import { NodeView, type Editor, type Node as TiptapNode, type NodeViewRendererOptions, type NodeViewRendererProps } from '@tiptap/core';
import type { Node as ProseMirrorNode } from '@tiptap/pm/model';
import type { Decoration, DecorationSource, EditorView } from '@tiptap/pm/view';
import { type NodeViewContext } from './context.ts';
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
    update: ((props: {
        oldNode: ProseMirrorNode;
        oldDecorations: readonly Decoration[];
        oldInnerDecorations: DecorationSource;
        newNode: ProseMirrorNode;
        newDecorations: readonly Decoration[];
        innerDecorations: DecorationSource;
        updateProps: () => void;
    }) => boolean) | null;
}
/**
 * Renders an Ember component as a node view.
 * @see https://tiptap.dev/guide/node-views
 */
export declare class EmberNodeView<TAttrs = Record<string, unknown>> extends NodeView<ComponentLike<EmberNodeViewSignature<TAttrs>>, Editor, EmberNodeViewRendererOptions> {
    private readonly renderer;
    private readonly contentDOMElement;
    private decorationClasses;
    private currentPos;
    private cachedExtensionWithSyncedStorage;
    private syncedDecorationClasses;
    private nodeSelected;
    private heldProps;
    private readonly handleDragStart;
    private readonly handlePositionUpdate;
    constructor(component: ComponentLike<EmberNodeViewSignature<TAttrs>>, props: NodeViewRendererProps, options: Partial<EmberNodeViewRendererOptions>);
    private get extensionWithSyncedStorage();
    get dom(): HTMLElement;
    get contentDOM(): HTMLElement | null;
    private readonly handleSelectionUpdate;
    update(node: ProseMirrorNode, decorations: readonly Decoration[], innerDecorations: DecorationSource): boolean;
    selectNode(): void;
    deselectNode(): void;
    destroy(): void;
    private getDecorationClasses;
    private syncDecorationClasses;
    private get holdsWrites();
    private updateProps;
    private holdProps;
}
//# sourceMappingURL=ember-node-view.d.ts.map