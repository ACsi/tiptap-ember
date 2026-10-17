import { assert } from '@ember/debug';
import type { ComponentLike } from '@glint/template';
import {
  MarkView,
  type Editor,
  type Mark as TiptapMark,
  type MarkViewProps,
  type MarkViewRendererOptions,
} from '@tiptap/core';
import type { Mark as ProseMirrorMark } from '@tiptap/pm/model';
import type { EditorView } from '@tiptap/pm/view';
import {
  createNodeViewContext,
  type MarkViewContext,
} from '../node-view/context.ts';
import { EmberRenderer } from '../renderer/ember-renderer.ts';

/**
 * The args a mark view component receives.
 */
export interface EmberMarkViewArgs<TAttrs = Record<string, unknown>> {
  editor: Editor;
  mark: ProseMirrorMark;
  attrs: Readonly<TAttrs>;
  inline: boolean;
  view: EditorView;
  extension: TiptapMark;
  HTMLAttributes: Record<string, unknown>;
  updateAttributes: (patch: Partial<TAttrs>) => void;

  /**
   * Pass this to `<MarkViewContent>`.
   */
  ctx: MarkViewContext;
}

export interface EmberMarkViewSignature<TAttrs = Record<string, unknown>> {
  Args: EmberMarkViewArgs<TAttrs>;
  Element: HTMLElement;
}

export type EmberMarkViewRendererOptions = MarkViewRendererOptions;

/**
 * Renders an Ember component as a mark view.
 */
export class EmberMarkView<TAttrs = Record<string, unknown>> extends MarkView<
  ComponentLike<EmberMarkViewSignature<TAttrs>>,
  EmberMarkViewRendererOptions
> {
  private readonly contentDOMElement: HTMLElement;
  private readonly ctx: MarkViewContext;
  private readonly renderer: EmberRenderer<EmberMarkViewArgs<TAttrs>>;

  constructor(
    component: ComponentLike<EmberMarkViewSignature<TAttrs>>,
    props: MarkViewProps,
    options: Partial<EmberMarkViewRendererOptions>,
  ) {
    super(component, props, options);

    this.contentDOMElement = document.createElement('span');
    this.contentDOMElement.dataset['markViewContent'] = '';
    this.contentDOMElement.style.whiteSpace = 'inherit';

    this.ctx = createNodeViewContext({
      contentDOM: this.contentDOMElement,
      nodeName: props.mark.type.name,
      kind: 'mark',
    });

    // Marks have no update(), so the props never change
    this.renderer = new EmberRenderer<EmberMarkViewArgs<TAttrs>>(component, {
      editor: props.editor,
      props: {
        editor: props.editor,
        mark: props.mark,
        attrs: props.mark.attrs as Readonly<TAttrs>,
        inline: props.inline,
        view: props.view,
        extension: props.extension,
        HTMLAttributes: props.HTMLAttributes,
        updateAttributes: (patch) => {
          this.updateAttributes(patch);
        },
        ctx: this.ctx,
      },
    });
  }

  override get dom(): HTMLElement {
    const element = this.renderer.element;

    assert(
      '[tiptap-ember] A mark view component must render a single root element.',
      element,
    );

    return element as HTMLElement;
  }

  override get contentDOM(): HTMLElement {
    return this.contentDOMElement;
  }

  // eslint-disable-next-line ember/classic-decorator-hooks
  destroy(): void {
    this.renderer.destroy();
  }
}
