import { mergeAttributes, Node } from '@tiptap/core';
import { EmberNodeViewRenderer } from '#src/index.ts';
import Toggle from './index.gts';

export default Node.create({
  name: 'demoToggle',
  group: 'block',
  content: 'block+',
  defining: true,
  isolating: true,

  addAttributes() {
    return {
      checked: {
        default: false,
        parseHTML: (element) => element.getAttribute('data-checked') === 'true',
        renderHTML: (attrs) => ({ 'data-checked': String(attrs['checked']) }),
      },
    };
  },

  parseHTML() {
    return [{ tag: 'div[data-toggle]' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes({ 'data-toggle': '' }, HTMLAttributes), 0];
  },

  addNodeView() {
    return EmberNodeViewRenderer(Toggle);
  },
});
