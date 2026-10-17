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
export declare function useEditor(parent: object, options?: Partial<EditorOptions>): Editor;
//# sourceMappingURL=use-editor.d.ts.map