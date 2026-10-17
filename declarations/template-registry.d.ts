import type EditorContent from './editor/editor-content';
import type NodeViewWrapper from './node-view/node-view-wrapper';
import type NodeViewContent from './node-view/node-view-content';
import type MarkViewContent from './mark-view/mark-view-content';
import type { BubbleMenu } from './menus/bubble-menu';
import type { FloatingMenu } from './menus/floating-menu';
export default interface Registry {
    EditorContent: typeof EditorContent;
    NodeViewWrapper: typeof NodeViewWrapper;
    NodeViewContent: typeof NodeViewContent;
    MarkViewContent: typeof MarkViewContent;
    BubbleMenu: typeof BubbleMenu;
    FloatingMenu: typeof FloatingMenu;
}
//# sourceMappingURL=template-registry.d.ts.map