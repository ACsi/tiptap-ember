import { Extension, type Editor } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Decoration, DecorationSet } from '@tiptap/pm/view';
import type { Node as ProseMirrorNode } from '@tiptap/pm/model';

const searchKey = new PluginKey<string>('demoSearch');

// Node views that get a node decoration when they contain a match
const NODE_VIEW_BLOCKS = new Set(['demoCallout', 'demoToggle']);

export function setSearchTerm(editor: Editor, term: string): void {
  editor.view.dispatch(editor.state.tr.setMeta(searchKey, term));
}

function buildMatchDecorations(
  doc: ProseMirrorNode,
  term: string,
): Decoration[] {
  const decorations: Decoration[] = [];
  const needle = term.toLowerCase();

  doc.descendants((node, pos) => {
    if (
      NODE_VIEW_BLOCKS.has(node.type.name) &&
      node.textContent.toLowerCase().includes(needle)
    ) {
      decorations.push(
        Decoration.node(pos, pos + node.nodeSize, {
          class: 'demo-search-hit--block',
        }),
      );
    }

    if (!node.isText || !node.text) {
      return true;
    }

    const haystack = node.text.toLowerCase();
    let index = haystack.indexOf(needle);

    while (index !== -1) {
      decorations.push(
        Decoration.inline(pos + index, pos + index + needle.length, {
          class: 'demo-search-hit',
        }),
      );
      index = haystack.indexOf(needle, index + needle.length);
    }

    return true;
  });

  return decorations;
}

export default Extension.create({
  name: 'demoSearch',

  addProseMirrorPlugins() {
    return [
      new Plugin<string>({
        key: searchKey,
        state: {
          init: () => '',
          apply(tr, value) {
            const next = tr.getMeta(searchKey) as string | undefined;

            return next ?? value;
          },
        },
        props: {
          decorations(state) {
            const term = searchKey.getState(state) ?? '';

            if (!term) {
              return DecorationSet.empty;
            }

            return DecorationSet.create(
              state.doc,
              buildMatchDecorations(state.doc, term),
            );
          },
        },
      }),
    ];
  },
});
