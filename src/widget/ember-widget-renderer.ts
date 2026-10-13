import { assert } from '@ember/debug';
import type { ComponentLike } from '@glint/template';
import {
  createWidgetDecoration,
  type Editor,
  type WidgetDecoration,
  type WidgetDecorationOptions,
} from '@tiptap/core';
import {
  EmberRenderer,
  type EmberRendererSignature,
} from '../renderer/ember-renderer.ts';

/**
 * The args every widget component receives next to its own props.
 */
export interface EmberWidgetDecorationArgs {
  editor: Editor;
  getPos: () => number | undefined;
}

/**
 * The signature of a component rendered by `EmberWidgetRenderer`.
 * Props from the first render are also named args. Props added later are
 * only in `@props`.
 */
export interface EmberWidgetDecorationSignature<
  TProps extends object = object,
> {
  Args: TProps &
    EmberWidgetDecorationArgs & {
      props: TProps & EmberWidgetDecorationArgs;
    };
  Element: HTMLElement;
}

export interface EmberWidgetRendererOptions<
  TProps extends object = object,
> extends WidgetDecorationOptions {
  editor: Editor;

  /**
   * The document position the widget is rendered at.
   */
  pos: number;

  /**
   * A stable, position-independent identifier for the widget.
   * Reusing the same key keeps the component mounted.
   * Good: `comment-${id}`. Bad: a paragraph index or a document position.
   */
  key: string;

  /**
   * The props passed to the component.
   * @default {}
   */
  props?: TProps;
}

type WidgetProps = Record<string, unknown>;

const WIDGET_CACHE = Symbol('tiptapEmberWidgetCache');

/**
 * Renders an Ember component as a widget decoration.
 * The component must render a single root element.
 * @param component The component to render.
 * @param options The widget options.
 * @returns The widget decoration to return from `addDecorations`.
 * @example
 * addDecorations() {
 *   return {
 *     create: ({ editor, state }) =>
 *       findMatches(state.doc).map((match) =>
 *         EmberWidgetRenderer(MatchBadge, {
 *           editor,
 *           pos: match.pos,
 *           key: `match-${match.id}`,
 *           props: { label: match.label },
 *         }),
 *       ),
 *   };
 * }
 */
export function EmberWidgetRenderer<TProps extends object = object>(
  component: ComponentLike<EmberWidgetDecorationSignature<TProps>>,
  options: EmberWidgetRendererOptions<TProps>,
): WidgetDecoration {
  const { editor } = options;
  const props: WidgetProps = options.props ?? {};

  return createWidgetDecoration<EmberRenderer<WidgetProps>>({
    ...options,
    props,
    cacheKey: WIDGET_CACHE,
    context: (getPos) => ({ editor, getPos }),
    create: (renderProps) =>
      new EmberRenderer<WidgetProps>(
        component as unknown as ComponentLike<
          EmberRendererSignature<WidgetProps>
        >,
        { editor, props: renderProps },
      ),
    materialize: (renderer) => {
      const element = renderer.element;

      assert(
        '[tiptap-ember] A widget component must render a single root element.',
        element instanceof HTMLElement,
      );

      return element;
    },
  });
}
