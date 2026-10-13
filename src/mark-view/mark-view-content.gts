import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { element, type ElementFromTagName } from '../renderer/tag.ts';
import {
  attachContentDOM,
  type MarkViewContext,
} from '../node-view/context.ts';

interface MarkViewContentSignature<T extends keyof HTMLElementTagNameMap> {
  Element: ElementFromTagName<T>;
  Args: {
    ctx: MarkViewContext;

    /**
     * The tag of the content element.
     * @default 'span'
     */
    as?: T;
  };
}

/**
 * Where the marked text of a mark view goes.
 * @example
 * <span class="highlight">
 *   <MarkViewContent @ctx={{@ctx}} />
 * </span>
 */
export default class MarkViewContent<
  T extends keyof HTMLElementTagNameMap = 'span',
> extends Component<MarkViewContentSignature<T>> {
  // Exactly `T`, so `...attributes` keeps the signature's element type
  get tag(): T {
    assert(
      '[tiptap-ember] <MarkViewContent>: `@as` must be a tag name; an empty ' +
        'string renders no element.',
      (this.args.as as string | undefined) !== '',
    );

    return this.args.as ?? ('span' as T);
  }

  <template>
    {{~#let (element this.tag) as |Tag|~}}
      <Tag
        {{! @glint-expect-error generic Element defers Glint attribute lookup }}
        data-mark-view-content-host
        ...attributes
        {{attachContentDOM ctx=@ctx}}
      />
    {{~/let~}}
  </template>
}
