import { tracked } from '@glimmer/tracking';
import { buildWaiter } from '@ember/test-waiters';
import { Editor as CoreEditor, type EditorOptions } from '@tiptap/core';
import type { EditorState, Plugin, PluginKey } from '@tiptap/pm/state';

const waiter = buildWaiter('@acsi/tiptap-ember:editor');

// A change signal only. Reads always return the live state.
class Signal {
  @tracked revision = 0;
}

// Outside the instance, so the base constructor's reads can entangle it
const signals = new WeakMap<object, Signal>();

function signalFor(editor: object): Signal {
  let signal = signals.get(editor);

  if (!signal) {
    signal = new Signal();
    signals.set(editor, signal);
  }

  return signal;
}

/**
 * A tiptap editor whose state is autotracked. Getters and templates that read
 * it update after every transaction.
 * @example
 * get isBold() {
 *   return this.editor.isActive('bold');
 * }
 */
export class Editor extends CoreEditor {
  // Undefined during super(), whose reads must entangle too
  private untrackedDepth = 0;

  private bumpScheduled = false;

  // `isDestroyed` is also true for a headless or unmounted editor
  private disposed = false;

  constructor(options: Partial<EditorOptions> = {}) {
    super(options);

    this.on('beforeTransaction', () => {
      this.scheduleBump();
    });

    this.on('destroy', () => {
      this.disposed = true;
    });
  }

  override get state(): EditorState {
    this.entangle();

    return super.state;
  }

  override get storage(): CoreEditor['extensionStorage'] {
    this.entangle();

    return super.storage;
  }

  // Untracked, so a menu modifier doesn't re-run on its own registration
  override registerPlugin(
    plugin: Plugin,
    handlePlugins?: (newPlugin: Plugin, plugins: Plugin[]) => Plugin[],
  ): EditorState {
    this.untrackedDepth += 1;

    try {
      return super.registerPlugin(plugin, handlePlugins);
    } finally {
      this.untrackedDepth -= 1;
      this.scheduleBump();
    }
  }

  override unregisterPlugin(
    nameOrPluginKeyToRemove: string | PluginKey | (string | PluginKey)[],
  ): EditorState | undefined {
    this.untrackedDepth += 1;

    try {
      return super.unregisterPlugin(nameOrPluginKeyToRemove);
    } finally {
      this.untrackedDepth -= 1;
      this.scheduleBump();
    }
  }

  private entangle(): void {
    if (!this.untrackedDepth) {
      void signalFor(this).revision;
    }
  }

  // Deferred: Glimmer forbids changing tracked state it read in the same render
  private scheduleBump(): void {
    if (this.bumpScheduled) {
      return;
    }

    this.bumpScheduled = true;

    const token = waiter.beginAsync();

    queueMicrotask(() => {
      this.bumpScheduled = false;

      if (!this.disposed) {
        signalFor(this).revision += 1;
      }

      waiter.endAsync(token);
    });
  }
}
