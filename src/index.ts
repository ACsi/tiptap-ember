export * from '@tiptap/core';

export { Editor } from './editor/editor.ts';
export { useEditor } from './editor/use-editor.ts';
export {
  default as EditorContent,
  type EditorContentSignature,
} from './editor/editor-content.gts';

export { default as NodeViewWrapper } from './node-view/node-view-wrapper.gts';
export { default as NodeViewContent } from './node-view/node-view-content.gts';
export { default as MarkViewContent } from './mark-view/mark-view-content.gts';

export { EmberNodeViewRenderer } from './node-view/ember-node-view-renderer.ts';
export {
  EmberNodeView,
  type EmberNodeViewArgs,
  type EmberNodeViewSignature,
  type EmberNodeViewRendererOptions,
} from './node-view/ember-node-view.ts';
export type { NodeViewContext, MarkViewContext } from './node-view/context.ts';

export { EmberMarkViewRenderer } from './mark-view/ember-mark-view-renderer.ts';
export {
  EmberMarkView,
  type EmberMarkViewArgs,
  type EmberMarkViewSignature,
  type EmberMarkViewRendererOptions,
} from './mark-view/ember-mark-view.ts';

export {
  EmberRenderer,
  type EmberRendererOptions,
  type EmberRendererSignature,
} from './renderer/ember-renderer.ts';

export {
  EmberWidgetRenderer,
  type EmberWidgetDecorationArgs,
  type EmberWidgetDecorationSignature,
  type EmberWidgetRendererOptions,
} from './widget/ember-widget-renderer.ts';
