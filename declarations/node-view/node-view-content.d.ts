import Component from '@glimmer/component';
import { type ElementFromTagName } from '../renderer/tag.ts';
import { type NodeViewContext } from './context.ts';
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
export default class NodeViewContent<T extends keyof HTMLElementTagNameMap = 'div'> extends Component<NodeViewContentSignature<T>> {
    get tag(): T;
}
export {};
//# sourceMappingURL=node-view-content.d.ts.map