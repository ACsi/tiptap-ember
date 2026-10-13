import { mergeAttributes, Node } from '@tiptap/core';
import { EmberNodeViewRenderer } from '#src/index.ts';
import Callout, { type CalloutVariant } from './index.gts';

export default Node.create({
  name: 'demoCallout',
  group: 'block',
  content: 'block+',
  defining: true,
  isolating: true,
  draggable: true,

  addAttributes() {
    return {
      variant: {
        default: 'info',
        parseHTML: (element) => element.getAttribute('data-variant') ?? 'info',
        renderHTML: (attrs) => ({
          'data-variant': attrs['variant'] as CalloutVariant,
        }),
      },
    };
  },

  parseHTML() {
    return [{ tag: 'div[data-callout]' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes({ 'data-callout': '' }, HTMLAttributes), 0];
  },

  addNodeView() {
    return EmberNodeViewRenderer(Callout);
  },
});
