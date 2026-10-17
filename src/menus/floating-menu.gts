import Component from '@glimmer/component';
import {
  FloatingMenuPlugin,
  type FloatingMenuPluginProps,
} from '@tiptap/extension-floating-menu';
import { PluginKey } from '@tiptap/pm/state';
import type { Editor } from '@tiptap/core';
import { modifier } from 'ember-modifier';

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
  Blocks: { default: [] };
}

type FloatingMenuOptions = Omit<
  FloatingMenuPluginProps,
  'editor' | 'element' | 'pluginKey'
>;

/**
 * A menu that shows on empty lines.
 * @example
 * <FloatingMenu @editor={{this.editor}}>
 *   <button type="button" {{on "click" this.toggleHeading}}>H1</button>
 * </FloatingMenu>
 */
export class FloatingMenu extends Component<FloatingMenuSignature> {
  // Holds the menu until the plugin first shows it. Null in FastBoot.
  holder =
    typeof document === 'undefined' ? null : document.createElement('div');

  resolvedPluginKey = this.args.pluginKey ?? new PluginKey('floatingMenu');

  // A plain copy, so option changes don't re-register the plugin
  private pluginOptions: FloatingMenuOptions = {};

  private registeredEditor: Editor | null = null;

  updateOptions = modifier(
    (_: HTMLDivElement, __: [], named: FloatingMenuOptions) => {
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
      FloatingMenuPlugin({
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
          }}
          {{this.setupMenu @editor}}
          ...attributes
        >{{yield}}</div>
      {{/in-element}}
    {{/if}}
  </template>
}
