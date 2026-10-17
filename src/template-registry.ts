// Easily allow apps, which are not yet using strict mode templates, to consume your Glint types, by importing this file.
// Add all your components, helpers and modifiers to the template registry here, so apps don't have to do this.
// See https://typed-ember.gitbook.io/glint/environments/ember/authoring-addons

import type EditorContent from './editor/editor-content.gts';
import type NodeViewWrapper from './node-view/node-view-wrapper.gts';
import type NodeViewContent from './node-view/node-view-content.gts';
import type MarkViewContent from './mark-view/mark-view-content.gts';
import type { BubbleMenu } from './menus/bubble-menu.gts';
import type { FloatingMenu } from './menus/floating-menu.gts';

export default interface Registry {
  EditorContent: typeof EditorContent;
  NodeViewWrapper: typeof NodeViewWrapper;
  NodeViewContent: typeof NodeViewContent;
  MarkViewContent: typeof MarkViewContent;
  BubbleMenu: typeof BubbleMenu;
  FloatingMenu: typeof FloatingMenu;
}
