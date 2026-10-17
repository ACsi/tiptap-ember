import Component from '@glimmer/component';
import { BubbleMenuPlugin } from '@tiptap/extension-bubble-menu';
import { PluginKey } from '@tiptap/pm/state';
import { modifier } from 'ember-modifier';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';
import { FloatingMenuPlugin } from '@tiptap/extension-floating-menu';

/**
 * A menu that shows next to the selection.
 * @example
 * <BubbleMenu @editor={{this.editor}}>
 *   <button type="button" {{on "click" this.toggleBold}}>Bold</button>
 * </BubbleMenu>
 */
class BubbleMenu extends Component {
  // Holds the menu until the plugin first shows it. Null in FastBoot.
  holder = typeof document === 'undefined' ? null : document.createElement('div');
  resolvedPluginKey = this.args.pluginKey ?? new PluginKey('bubbleMenu');
  // A plain copy, so option changes don't re-register the plugin
  pluginOptions = {};
  registeredEditor = null;
  updateOptions = modifier((_, __, named) => {
    const options = {
      ...named
    };
    const editor = this.registeredEditor;
    this.pluginOptions = options;
    if (!editor) {
      return;
    }
    // Deferred: reading the state here would re-run this on every transaction
    queueMicrotask(() => {
      if (!editor.isDestroyed) {
        editor.view.dispatch(editor.state.tr.setMeta(this.resolvedPluginKey, {
          type: 'updateOptions',
          options
        }));
      }
    });
  });
  setupMenu = modifier((element, [editor]) => {
    element.style.visibility = 'hidden';
    element.style.position = 'absolute';
    editor.registerPlugin(BubbleMenuPlugin({
      ...this.pluginOptions,
      editor,
      element,
      pluginKey: this.resolvedPluginKey
    }));
    this.registeredEditor = editor;
    return () => {
      this.registeredEditor = null;
      editor.unregisterPlugin(this.resolvedPluginKey);
    };
  });
  static {
    setComponentTemplate(precompileTemplate("{{#if this.holder}}\n  {{#in-element this.holder}}\n    <div {{this.updateOptions updateDelay=@updateDelay resizeDelay=@resizeDelay options=@options appendTo=@appendTo shouldShow=@shouldShow getReferencedVirtualElement=@getReferencedVirtualElement}} {{this.setupMenu @editor}} ...attributes>{{yield}}</div>\n  {{/in-element}}\n{{/if}}", {
      strictMode: true
    }), this);
  }
}

/**
 * A menu that shows on empty lines.
 * @example
 * <FloatingMenu @editor={{this.editor}}>
 *   <button type="button" {{on "click" this.toggleHeading}}>H1</button>
 * </FloatingMenu>
 */
class FloatingMenu extends Component {
  // Holds the menu until the plugin first shows it. Null in FastBoot.
  holder = typeof document === 'undefined' ? null : document.createElement('div');
  resolvedPluginKey = this.args.pluginKey ?? new PluginKey('floatingMenu');
  // A plain copy, so option changes don't re-register the plugin
  pluginOptions = {};
  registeredEditor = null;
  updateOptions = modifier((_, __, named) => {
    const options = {
      ...named
    };
    const editor = this.registeredEditor;
    this.pluginOptions = options;
    if (!editor) {
      return;
    }
    // Deferred: reading the state here would re-run this on every transaction
    queueMicrotask(() => {
      if (!editor.isDestroyed) {
        editor.view.dispatch(editor.state.tr.setMeta(this.resolvedPluginKey, {
          type: 'updateOptions',
          options
        }));
      }
    });
  });
  setupMenu = modifier((element, [editor]) => {
    element.style.visibility = 'hidden';
    element.style.position = 'absolute';
    editor.registerPlugin(FloatingMenuPlugin({
      ...this.pluginOptions,
      editor,
      element,
      pluginKey: this.resolvedPluginKey
    }));
    this.registeredEditor = editor;
    return () => {
      this.registeredEditor = null;
      editor.unregisterPlugin(this.resolvedPluginKey);
    };
  });
  static {
    setComponentTemplate(precompileTemplate("{{#if this.holder}}\n  {{#in-element this.holder}}\n    <div {{this.updateOptions updateDelay=@updateDelay resizeDelay=@resizeDelay options=@options appendTo=@appendTo shouldShow=@shouldShow}} {{this.setupMenu @editor}} ...attributes>{{yield}}</div>\n  {{/in-element}}\n{{/if}}", {
      strictMode: true
    }), this);
  }
}

export { BubbleMenu, FloatingMenu };
//# sourceMappingURL=index.js.map
