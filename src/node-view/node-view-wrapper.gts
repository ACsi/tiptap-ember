import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { element, type ElementFromTagName } from '../renderer/tag.ts';

import type { NodeViewContext } from './context.ts';

interface NodeViewWrapperSignature<T extends keyof HTMLElementTagNameMap> {
  Element: ElementFromTagName<T>;
  Args: {
    ctx: NodeViewContext;

    /**
     * The tag of the wrapper element.
     * @default 'div'
     */
    as?: T;
  };
  Blocks: {
    default: [];
  };
}

const noop = (): void => {};

/**
 * The root element of a node view component.
 * @example
 * <NodeViewWrapper @ctx={{@ctx}} class="callout">
 *   <NodeViewContent @ctx={{@ctx}} />
 * </NodeViewWrapper>
 */
export default class NodeViewWrapper<
  T extends keyof HTMLElementTagNameMap = 'div',
> extends Component<NodeViewWrapperSignature<T>> {
  // ProseMirror keeps the first element as the node view's dom
  private readonly initialAs = this.args.as;

  // Exactly `T`, so `...attributes` keeps the signature's element type
  get tag(): T {
    assert(
      '[tiptap-ember] <NodeViewWrapper>: `@as` must be a tag name; an empty ' +
        'string renders no element.',
      (this.args.as as string | undefined) !== '',
    );

    assert(
      '[tiptap-ember] <NodeViewWrapper>: `@as` cannot change after the first render.',
      this.args.as === this.initialAs,
    );

    return this.args.as ?? ('div' as T);
  }

  get onDragStart(): (event: DragEvent) => void {
    return this.args.ctx.onDragStart ?? noop;
  }

  get decorationClasses(): string | undefined {
    return this.args.ctx.decorationClasses || undefined;
  }

  <template>
    {{! template-lint-disable no-inline-styles }}
    {{~#let (element this.tag) as |Tag|~}}
      <Tag
        {{! @glint-expect-error generic Element defers Glint attribute lookup }}
        data-node-view-wrapper
        class={{this.decorationClasses}}
        style="white-space: normal;"
        {{! Capture, so core runs before listeners from ...attributes }}
        {{on "dragstart" this.onDragStart capture=true}}
        ...attributes
      >
        {{~yield~}}
      </Tag>
    {{~/let~}}
  </template>
}
