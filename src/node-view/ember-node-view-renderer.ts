import type { ComponentLike } from '@glint/template';
import type { NodeViewRenderer } from '@tiptap/core';

import {
  EmberNodeView,
  type EmberNodeViewSignature,
  type EmberNodeViewRendererOptions,
} from './ember-node-view.ts';

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
export function EmberNodeViewRenderer<TAttrs = Record<string, unknown>>(
  component: ComponentLike<EmberNodeViewSignature<TAttrs>>,
  options: Partial<EmberNodeViewRendererOptions> = {},
): NodeViewRenderer {
  return (props) => new EmberNodeView<TAttrs>(component, props, options);
}
