import Component from '@glimmer/component';
import {
  BubbleMenuPlugin,
  type BubbleMenuPluginProps,
} from '@tiptap/extension-bubble-menu';
import { PluginKey } from '@tiptap/pm/state';
import type { Editor } from '@tiptap/core';
import { modifier } from 'ember-modifier';

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
  Blocks: { default: [] };
}

type BubbleMenuOptions = Omit<
  BubbleMenuPluginProps,
  'editor' | 'element' | 'pluginKey'
>;

/**
 * A menu that shows next to the selection.
 * @example
 * <BubbleMenu @editor={{this.editor}}>
 *   <button type="button" {{on "click" this.toggleBold}}>Bold</button>
 * </BubbleMenu>
 */
export class BubbleMenu extends Component<BubbleMenuSignature> {
  // Holds the menu until the plugin first shows it. Null in FastBoot.
  holder =
    typeof document === 'undefined' ? null : document.createElement('div');

  resolvedPluginKey = this.args.pluginKey ?? new PluginKey('bubbleMenu');

  // A plain copy, so option changes don't re-register the plugin
  private pluginOptions: BubbleMenuOptions = {};

  private registeredEditor: Editor | null = null;

  updateOptions = modifier(
    (_: HTMLDivElement, __: [], named: BubbleMenuOptions) => {
      const options = { ...named };
      const editor = this.registeredEditor;

      this.pluginOptions = options;

      if (!editor) {
        return;
      }

      // Deferred: reading the state here would re-run this on every transaction
      queueMicrotask(() => {
        if (!editor.isDestroyed) {
          editor.view.dispatch(
            editor.state.tr.setMeta(this.resolvedPluginKey, {
              type: 'updateOptions',
              options,
            }),
          );
        }
      });
    },
  );

  setupMenu = modifier((element: HTMLDivElement, [editor]: [Editor]) => {
    element.style.visibility = 'hidden';
    element.style.position = 'absolute';

    editor.registerPlugin(
      BubbleMenuPlugin({
        ...this.pluginOptions,
        editor,
        element,
        pluginKey: this.resolvedPluginKey,
      }),
    );

    this.registeredEditor = editor;

    return () => {
      this.registeredEditor = null;
      editor.unregisterPlugin(this.resolvedPluginKey);
    };
  });

  <template>
    {{#if this.holder}}
      {{#in-element this.holder}}
        <div
          {{this.updateOptions
            updateDelay=@updateDelay
            resizeDelay=@resizeDelay
            options=@options
            appendTo=@appendTo
            shouldShow=@shouldShow
            getReferencedVirtualElement=@getReferencedVirtualElement
          }}
          {{this.setupMenu @editor}}
          ...attributes
        >{{yield}}</div>
      {{/in-element}}
    {{/if}}
  </template>
}
