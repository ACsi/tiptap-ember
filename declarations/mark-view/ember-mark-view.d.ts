import type { ComponentLike } from '@glint/template';
import { MarkView, type Editor, type Mark as TiptapMark, type MarkViewProps, type MarkViewRendererOptions } from '@tiptap/core';
import type { Mark as ProseMirrorMark } from '@tiptap/pm/model';
import type { EditorView } from '@tiptap/pm/view';
import { type MarkViewContext } from '../node-view/context.ts';
/**
 * The args a mark view component receives.
 */
export interface EmberMarkViewArgs<TAttrs = Record<string, unknown>> {
    editor: Editor;
    mark: ProseMirrorMark;
    attrs: Readonly<TAttrs>;
    inline: boolean;
    view: EditorView;
    extension: TiptapMark;
    HTMLAttributes: Record<string, unknown>;
    updateAttributes: (patch: Partial<TAttrs>) => void;
    /**
     * Pass this to `<MarkViewContent>`.
     */
    ctx: MarkViewContext;
}
export interface EmberMarkViewSignature<TAttrs = Record<string, unknown>> {
    Args: EmberMarkViewArgs<TAttrs>;
    Element: HTMLElement;
}
export type EmberMarkViewRendererOptions = MarkViewRendererOptions;
/**
 * Renders an Ember component as a mark view.
 */
export declare class EmberMarkView<TAttrs = Record<string, unknown>> extends MarkView<ComponentLike<EmberMarkViewSignature<TAttrs>>, EmberMarkViewRendererOptions> {
    private readonly contentDOMElement;
    private readonly ctx;
    private readonly renderer;
    constructor(component: ComponentLike<EmberMarkViewSignature<TAttrs>>, props: MarkViewProps, options: Partial<EmberMarkViewRendererOptions>);
    get dom(): HTMLElement;
    get contentDOM(): HTMLElement;
    destroy(): void;
}
//# sourceMappingURL=ember-mark-view.d.ts.map