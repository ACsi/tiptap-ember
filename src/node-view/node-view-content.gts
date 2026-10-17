import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { element, type ElementFromTagName } from '../renderer/tag.ts';
import { attachContentDOM, type NodeViewContext } from './context.ts';

interface NodeViewContentSignature<T extends keyof HTMLElementTagNameMap> {
  Element: ElementFromTagName<T>;
  Args: {
    ctx: NodeViewContext;

    /**
     * The tag of the content element.
     * @default 'div'
     */
    as?: T;
  };
}

/**
 * Where the editable content of a node view goes.
 * @example
 * <NodeViewContent @ctx={{@ctx}} class="content" />
 */
export default class NodeViewContent<
  T extends keyof HTMLElementTagNameMap = 'div',
> extends Component<NodeViewContentSignature<T>> {
  // Exactly `T`, so `...attributes` keeps the signature's element type
  get tag(): T {
    assert(
      '[tiptap-ember] <NodeViewContent>: `@as` must be a tag name; an empty ' +
        'string renders no element.',
      (this.args.as as string | undefined) !== '',
    );

    return this.args.as ?? ('div' as T);
  }

  <template>
    {{~#let (element this.tag) as |Tag|~}}
      <Tag
        {{! @glint-expect-error generic Element defers Glint attribute lookup }}
        data-node-view-content-host
        ...attributes
        {{attachContentDOM ctx=@ctx}}
      />
    {{~/let~}}
  </template>
}
