import Component from '@glimmer/component';
import { type BubbleMenuPluginProps } from '@tiptap/extension-bubble-menu';
import { PluginKey } from '@tiptap/pm/state';
import type { Editor } from '@tiptap/core';
export interface BubbleMenuSignature {
    Element: HTMLDivElement;
    Args: {
        editor: BubbleMenuPluginProps['editor'];
        /**
         * The plugin key.
         * @default 'bubbleMenu'
         */
        pluginKey?: BubbleMenuPluginProps['pluginKey'];
        /**
         * The delay in milliseconds before the menu updates.
         * @default 250
         */
        updateDelay?: BubbleMenuPluginProps['updateDelay'];
        /**
         * The delay in milliseconds before the menu position updates on window resize.
         * @default 60
         */
        resizeDelay?: BubbleMenuPluginProps['resizeDelay'];
        /**
         * Options passed to Floating UI.
         * @default {}
         * @see https://floating-ui.com/docs/computePosition#options
         */
        options?: BubbleMenuPluginProps['options'];
        /**
         * The element to append the menu to.
         * @default The editor's parent element.
         */
        appendTo?: BubbleMenuPluginProps['appendTo'];
        /**
         * Whether the menu should be shown.
         */
        shouldShow?: BubbleMenuPluginProps['shouldShow'];
        /**
         * Returns the virtual element the menu is positioned against.
         * @default Position based on the selection.
         */
        getReferencedVirtualElement?: Required<BubbleMenuPluginProps>['getReferencedVirtualElement'];
    };
    Blocks: {
        default: [];
    };
}
type BubbleMenuOptions = Omit<BubbleMenuPluginProps, 'editor' | 'element' | 'pluginKey'>;
/**
 * A menu that shows next to the selection.
 * @example
 * <BubbleMenu @editor={{this.editor}}>
 *   <button type="button" {{on "click" this.toggleBold}}>Bold</button>
 * </BubbleMenu>
 */
export declare class BubbleMenu extends Component<BubbleMenuSignature> {
    holder: HTMLDivElement | null;
    resolvedPluginKey: string | PluginKey<any>;
    private pluginOptions;
    private registeredEditor;
    updateOptions: import("ember-modifier").FunctionBasedModifier<{
        Args: {
            Positional: [];
            Named: BubbleMenuOptions;
        };
        Element: HTMLDivElement;
    }>;
    setupMenu: import("ember-modifier").FunctionBasedModifier<{
        Args: {
            Positional: [Editor];
            Named: import("ember-modifier/-private/signature").EmptyObject;
        };
        Element: HTMLDivElement;
    }>;
}
export {};
//# sourceMappingURL=bubble-menu.d.ts.map