/**
 * Connects `<NodeViewWrapper>`, `<NodeViewContent>` and `<MarkViewContent>`
 * to their view. Pass it on as `@ctx={{@ctx}}`.
 */
export interface NodeViewContext {
    contentDOM: HTMLElement | null;
    nodeName: string;
    kind: 'node' | 'mark';
    /**
     * Selects the node when a drag starts. Node views only.
     */
    onDragStart?: (event: DragEvent) => void;
    /**
     * The `class` attributes of the node's decorations. Node views only.
     */
    readonly decorationClasses?: string;
}
export type MarkViewContext = NodeViewContext;
export interface NodeViewContextInit {
    contentDOM: HTMLElement | null;
    nodeName: string;
    kind: 'node' | 'mark';
    onDragStart?: (event: DragEvent) => void;
    getDecorationClasses?: () => string;
}
export declare function createNodeViewContext(init: NodeViewContextInit): NodeViewContext;
export declare const attachContentDOM: import("ember-modifier").FunctionBasedModifier<{
    Element: HTMLElement;
    Args: {
        Named: {
            ctx: NodeViewContext;
        };
        Positional: [];
    };
}>;
//# sourceMappingURL=context.d.ts.map