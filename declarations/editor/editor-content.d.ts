import type Owner from '@ember/owner';
import Component from '@glimmer/component';
import type { Editor } from '@tiptap/core';
export interface EditorContentSignature {
    Element: HTMLDivElement;
    Args: {
        editor: Editor;
    };
    Blocks: {
        default: [{
            editor: Editor;
        }];
    };
}
/**
 * Renders the editor.
 * @example
 * <EditorContent @editor={{this.editor}} />
 */
export default class EditorContent extends Component<EditorContentSignature> {
    get owner(): Owner;
}
//# sourceMappingURL=editor-content.d.ts.map