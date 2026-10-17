import type { ComponentLike } from '@glint/template';
import type { MarkViewRenderer } from '@tiptap/core';
import { type EmberMarkViewSignature, type EmberMarkViewRendererOptions } from './ember-mark-view.ts';
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
export declare function EmberMarkViewRenderer<TAttrs = Record<string, unknown>>(component: ComponentLike<EmberMarkViewSignature<TAttrs>>, options?: Partial<EmberMarkViewRendererOptions>): MarkViewRenderer;
//# sourceMappingURL=ember-mark-view-renderer.d.ts.map