import { assert } from '@ember/debug';
import { registerDestructor } from '@ember/destroyable';
import { getOwner, setOwner } from '@ember/owner';
import type { EditorOptions } from '@tiptap/core';
import { Editor } from './editor.ts';

/**
 * Creates an editor that is destroyed together with `parent`.
 * @param parent The component or service that owns the editor, usually `this`.
 * @param options The editor options.
 * @returns The editor.
 * @example
 * editor = useEditor(this, {
 *   extensions: [StarterKit],
 *   content: '<p>Hello World!</p>',
 * });
 */
export function useEditor(
  parent: object,
  options: Partial<EditorOptions> = {},
): Editor {
  assert(
    '[tiptap-ember] useEditor() needs a browser. Render the editor outside FastBoot.',
    typeof document !== 'undefined',
  );

  const owner = getOwner(parent);

  const editor = new Editor({
    ...options,
    // Set the owner before the initial content renders any view
    onBeforeCreate(props) {
      if (owner) {
        setOwner(props.editor, owner);
      }

      options.onBeforeCreate?.(props);
    },
  });

  registerDestructor(parent, () => {
    editor.destroy();
  });

  return editor;
}
