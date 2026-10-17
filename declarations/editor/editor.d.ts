import { Editor as CoreEditor, type EditorOptions } from '@tiptap/core';
import type { EditorState, Plugin, PluginKey } from '@tiptap/pm/state';
/**
 * A tiptap editor whose state is autotracked. Getters and templates that read
 * it update after every transaction.
 * @example
 * get isBold() {
 *   return this.editor.isActive('bold');
 * }
 */
export declare class Editor extends CoreEditor {
    private untrackedDepth;
    private bumpScheduled;
    private disposed;
    constructor(options?: Partial<EditorOptions>);
    get state(): EditorState;
    get storage(): CoreEditor['extensionStorage'];
    registerPlugin(plugin: Plugin, handlePlugins?: (newPlugin: Plugin, plugins: Plugin[]) => Plugin[]): EditorState;
    unregisterPlugin(nameOrPluginKeyToRemove: string | PluginKey | (string | PluginKey)[]): EditorState | undefined;
    private entangle;
    private scheduleBump;
}
//# sourceMappingURL=editor.d.ts.map