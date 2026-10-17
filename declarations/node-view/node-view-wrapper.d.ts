import Component from '@glimmer/component';
import { type ElementFromTagName } from '../renderer/tag.ts';
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
/**
 * The root element of a node view component.
 * @example
 * <NodeViewWrapper @ctx={{@ctx}} class="callout">
 *   <NodeViewContent @ctx={{@ctx}} />
 * </NodeViewWrapper>
 */
export default class NodeViewWrapper<T extends keyof HTMLElementTagNameMap = 'div'> extends Component<NodeViewWrapperSignature<T>> {
    private readonly initialAs;
    get tag(): T;
    get onDragStart(): (event: DragEvent) => void;
    get decorationClasses(): string | undefined;
}
export {};
//# sourceMappingURL=node-view-wrapper.d.ts.map