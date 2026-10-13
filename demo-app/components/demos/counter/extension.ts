import { mergeAttributes, Node } from '@tiptap/core';
import { EmberNodeViewRenderer } from '#src/index.ts';
import Counter from './index.gts';

export default Node.create({
  name: 'demoCounter',
  group: 'block',
  atom: true,
  selectable: true,
  draggable: true,

  addAttributes() {
    return {
      count: {
        default: 0,
        parseHTML: (element) => Number(element.getAttribute('count')) || 0,
        renderHTML: (attrs) => ({ count: attrs['count'] as number }),
      },
    };
  },

  parseHTML() {
    return [{ tag: 'demo-counter' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['demo-counter', mergeAttributes(HTMLAttributes)];
  },

  addNodeView() {
    return EmberNodeViewRenderer(Counter);
  },
});
