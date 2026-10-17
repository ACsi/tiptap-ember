import type { ComponentLike } from '@glint/template';
import type { Editor } from '@tiptap/core';
export interface EmberRendererOptions<TProps = Record<string, unknown>> {
    /**
     * The component's owner inherits from this editor's owner.
     */
    editor: Editor;
    /**
     * The props passed to the component.
     * @default {}
     */
    props?: TProps;
}
/**
 * The signature of a component rendered by `EmberRenderer`.
 * Props from the first render are also named args. Props added later are
 * only in `@props`.
 */
export interface EmberRendererSignature<TProps = object> {
    Args: TProps & {
        props: TProps;
    };
    Element: HTMLElement;
}
export declare function hasRenderedThisTurn(): boolean;
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
export declare class EmberRenderer<TProps = Record<string, unknown>> {
    private readonly renderedComponent;
    readonly editor: Editor;
    readonly component: ComponentLike<EmberRendererSignature<TProps>>;
    private renderRoot;
    /**
     * The current props. Changes re-render the component.
     */
    readonly props: TProps;
    destroyed: boolean;
    constructor(component: ComponentLike<EmberRendererSignature<TProps>>, { props, editor }: EmberRendererOptions<TProps>);
    /**
     * The component's root element.
     */
    get element(): Element | null;
    private renderComponent;
    /**
     * Merges new props into the current props.
     * @param props The props to change.
     */
    updateProps(props: Partial<TProps>): void;
    /**
     * Destroys the component and removes its element.
     */
    destroy(): void;
}
//# sourceMappingURL=ember-renderer.d.ts.map