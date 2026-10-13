import type Owner from '@ember/owner';
import { setOwner } from '@ember/owner';
import type { EditorOptions } from '@tiptap/core';
import { Editor } from '#src/index.ts';

export function createTestEditor(options: Partial<EditorOptions>): Editor {
  return new Editor(options);
}

// Owned from the start, so views in the initial content can render headless
export function createOwnedTestEditor(
  owner: Owner,
  options: Partial<EditorOptions>,
): Editor {
  return new Editor({
    ...options,
    onBeforeCreate(props) {
      setOwner(props.editor, owner);
      options.onBeforeCreate?.(props);
    },
  });
}
