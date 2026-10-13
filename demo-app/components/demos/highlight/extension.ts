import { mergeAttributes, Mark } from '@tiptap/core';
import { EmberMarkViewRenderer } from '#src/index.ts';
import Highlight, { type HighlightColor } from './index.gts';

export default Mark.create({
  name: 'demoHighlight',
  inclusive: false,

  addAttributes() {
    return {
      color: {
        default: 'yellow',
        parseHTML: (element) => element.getAttribute('data-color') ?? 'yellow',
        renderHTML: (attrs) => ({
          'data-color': attrs['color'] as HighlightColor,
        }),
      },
    };
  },

  parseHTML() {
    return [{ tag: 'mark[data-highlight]' }];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      'mark',
      mergeAttributes({ 'data-highlight': '' }, HTMLAttributes),
      0,
    ];
  },

  addMarkView() {
    return EmberMarkViewRenderer(Highlight);
  },
});
