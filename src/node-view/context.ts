import { warn } from '@ember/debug';
import { modifier } from 'ember-modifier';

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

export function createNodeViewContext(
  init: NodeViewContextInit,
): NodeViewContext {
  return {
    contentDOM: init.contentDOM,
    nodeName: init.nodeName,
    kind: init.kind,
    onDragStart: init.onDragStart,

    get decorationClasses(): string | undefined {
      return init.getDecorationClasses?.();
    },
  };
}

const warnedLeafContexts = new WeakSet<NodeViewContext>();

export const attachContentDOM = modifier<{
  Element: HTMLElement;
  Args: { Positional: []; Named: { ctx: NodeViewContext } };
}>(function attachContentDOM(element, _positional, { ctx }) {
  const { contentDOM } = ctx;

  if (!contentDOM) {
    if (!warnedLeafContexts.has(ctx)) {
      warnedLeafContexts.add(ctx);

      const tag = ctx.kind === 'mark' ? 'MarkViewContent' : 'NodeViewContent';

      warn(
        `[tiptap-ember] <${tag}> has no content to show in the leaf ${ctx.kind} "${ctx.nodeName}". Remove it.`,
        { id: 'tiptap-ember.leaf-content' },
      );
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
