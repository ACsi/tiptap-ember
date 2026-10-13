import { assert } from '@ember/debug';
import type Owner from '@ember/owner';
import { getOwner, setOwner } from '@ember/owner';
import Component from '@glimmer/component';
import type { Editor } from '@tiptap/core';
import { modifier } from 'ember-modifier';

export interface EditorContentSignature {
  Element: HTMLDivElement;
  Args: {
    editor: Editor;
  };
  Blocks: {
    default: [{ editor: Editor }];
  };
}

const mountEditor = modifier<{
  Element: HTMLElement;
  Args: { Positional: [Editor, Owner] };
}>(function mountEditor(element, [editor, owner]) {
  // Fallback for editors not created with `useEditor`
  if (!getOwner(editor)) {
    setOwner(editor, owner);
  }

  // Also true for an editor without a view, e.g. `element: null`
  if (editor.isDestroyed) {
    return;
  }

  const parent = editor.view.dom.parentNode;

  assert(
    '[tiptap-ember] An editor can only be rendered by one <EditorContent> at a time.',
    !(
      parent instanceof Element &&
      parent.hasAttribute('data-tiptap-ember-editor')
    ),
  );

  // Plugins may have added elements next to the editor
  const nodes = parent ? [...parent.childNodes] : [editor.view.dom];

  element.append(...nodes);

  return () => {
    if (editor.isDestroyed) {
      return;
    }

    // Detached, so the editor outlives this element
    document
      .createElement('div')
      .append(...nodes.filter((node) => node.parentNode === element));
  };
});

/**
 * Renders the editor.
 * @example
 * <EditorContent @editor={{this.editor}} />
 */
export default class EditorContent extends Component<EditorContentSignature> {
  get owner(): Owner {
    const owner = getOwner(this);

    assert('[tiptap-ember] <EditorContent> needs an owner.', owner);

    return owner;
  }

  <template>
    <div
      data-tiptap-ember-editor
      ...attributes
      {{mountEditor @editor this.owner}}
    >
      {{~yield (hash editor=@editor)~}}
    </div>
  </template>
}
