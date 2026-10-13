import { Extension } from '@tiptap/core';
import { EmberWidgetRenderer } from '#src/index.ts';
import WordCount from './index.gts';

export default Extension.create({
  name: 'demoWordCount',

  addDecorations() {
    return {
      create: ({ editor, state }) => {
        const first = state.doc.firstChild;

        if (!first?.isTextblock) {
          return [];
        }

        const text = state.doc.textBetween(0, state.doc.content.size, ' ');
        const words = text.split(/\s+/).filter(Boolean).length;

        return [
          EmberWidgetRenderer(WordCount, {
            editor,
            pos: first.nodeSize - 1,
            key: 'word-count',
            props: { words },
            side: 1,
            ignoreSelection: true,
          }),
        ];
      },
    };
  },
});
