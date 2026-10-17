import Component from '@glimmer/component';
import { type ElementFromTagName } from '../renderer/tag.ts';
import { type MarkViewContext } from '../node-view/context.ts';
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
export default class MarkViewContent<T extends keyof HTMLElementTagNameMap = 'span'> extends Component<MarkViewContentSignature<T>> {
    get tag(): T;
}
export {};
//# sourceMappingURL=mark-view-content.d.ts.map