import Component from '@glimmer/component';
import { type FloatingMenuPluginProps } from '@tiptap/extension-floating-menu';
import { PluginKey } from '@tiptap/pm/state';
import type { Editor } from '@tiptap/core';
export interface FloatingMenuSignature {
    Element: HTMLDivElement;
    Args: {
        editor: FloatingMenuPluginProps['editor'];
        /**
         * The plugin key.
         * @default 'floatingMenu'
         */
        pluginKey?: FloatingMenuPluginProps['pluginKey'];
        /**
         * The delay in milliseconds before the menu updates.
         * @default 250
         */
        updateDelay?: FloatingMenuPluginProps['updateDelay'];
        /**
         * The delay in milliseconds before the menu position updates on window resize.
         * @default 60
         */
        resizeDelay?: FloatingMenuPluginProps['resizeDelay'];
        /**
         * Options passed to Floating UI.
         * @default {}
         * @see https://floating-ui.com/docs/computePosition#options
         */
        options?: FloatingMenuPluginProps['options'];
        /**
         * The element to append the menu to.
         * @default The editor's parent element.
         */
        appendTo?: FloatingMenuPluginProps['appendTo'];
        /**
         * Whether the menu should be shown.
         */
        shouldShow?: FloatingMenuPluginProps['shouldShow'];
    };
    Blocks: {
        default: [];
    };
}
type FloatingMenuOptions = Omit<FloatingMenuPluginProps, 'editor' | 'element' | 'pluginKey'>;
/**
 * A menu that shows on empty lines.
 * @example
 * <FloatingMenu @editor={{this.editor}}>
 *   <button type="button" {{on "click" this.toggleHeading}}>H1</button>
 * </FloatingMenu>
 */
export declare class FloatingMenu extends Component<FloatingMenuSignature> {
    holder: HTMLDivElement | null;
    resolvedPluginKey: string | PluginKey<any>;
    private pluginOptions;
    private registeredEditor;
    updateOptions: import("ember-modifier").FunctionBasedModifier<{
        Args: {
            Positional: [];
            Named: FloatingMenuOptions;
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
//# sourceMappingURL=floating-menu.d.ts.map