import { assert } from '@ember/debug';
import {
  destroy as destroyDestroyable,
  registerDestructor,
} from '@ember/destroyable';
import type Owner from '@ember/owner';
import { getOwner } from '@ember/owner';
import { trackedObject } from '@ember/reactive/collections';
import { renderComponent } from '@ember/renderer';
import type { ComponentLike } from '@glint/template';
import type { Editor } from '@tiptap/core';

export interface EmberRendererOptions<TProps = Record<string, unknown>> {
  /**
   * The component's owner inherits from this editor's owner.
   */
  editor: Editor;

  /**
   * The props passed to the component.
   * @default {}
   */
  props?: TProps;
}

/**
 * The signature of a component rendered by `EmberRenderer`.
 * Props from the first render are also named args. Props added later are
 * only in `@props`.
 */
export interface EmberRendererSignature<TProps = object> {
  Args: TProps & {
    props: TProps;
  };
  Element: HTMLElement;
}

interface RenderedComponent {
  result: ReturnType<typeof renderComponent>;
  destroy: () => void;
  el: Element | null;
}

// Glimmer can't render re-entrantly. A queued root could never be destroyed.
let rendering = false;

// Rendering revalidates all of the renderer's roots, so a render around it
// may have read any view. Reset on the next microtask.
let renderedThisTurn = false;

export function hasRenderedThisTurn(): boolean {
  return renderedThisTurn;
}

function markRendered(): void {
  if (renderedThisTurn) {
    return;
  }

  renderedThisTurn = true;

  queueMicrotask(() => {
    renderedThisTurn = false;
  });
}

// Ember keeps one renderer per owner. A host rendering with the same owner,
// like test-helpers' render(), would queue views created during its render.
const viewOwners = new WeakMap<Owner, Owner>();

function viewOwnerFor(owner: Owner): Owner {
  let viewOwner = viewOwners.get(owner);

  if (!viewOwner) {
    // Inherits lookups, so views get the same services. Not a destroyable
    // child of `owner`: owner teardown would pull views out of a live editor.
    viewOwner = Object.create(owner) as Owner;
    viewOwners.set(owner, viewOwner);
    // An editor created inside a view renders through the same renderer
    viewOwners.set(viewOwner, viewOwner);
  }

  return viewOwner;
}

/**
 * Renders an Ember component into a detached element, for example a
 * suggestion popup. The component must render a single root element.
 * @example
 * const renderer = new EmberRenderer(MentionList, {
 *   editor,
 *   props: { items, command },
 * });
 *
 * document.body.appendChild(renderer.element);
 */
export class EmberRenderer<TProps = Record<string, unknown>> {
  private readonly renderedComponent: RenderedComponent;

  readonly editor: Editor;

  readonly component: ComponentLike<EmberRendererSignature<TProps>>;

  private renderRoot: Element | null;

  /**
   * The current props. Changes re-render the component.
   */
  readonly props: TProps;

  destroyed = false;

  constructor(
    component: ComponentLike<EmberRendererSignature<TProps>>,
    { props, editor }: EmberRendererOptions<TProps>,
  ) {
    this.editor = editor;
    this.component = component;
    this.props = trackedObject(props ?? {}) as TProps;

    const renderRoot = document.createElement('div');

    this.renderRoot = renderRoot;
    this.renderedComponent = this.renderComponent(renderRoot);
  }

  /**
   * The component's root element.
   */
  get element(): Element | null {
    if (this.renderedComponent.el === null && this.renderRoot) {
      this.renderedComponent.el = this.renderRoot.firstElementChild;
    }

    return this.renderedComponent.el;
  }

  private renderComponent(renderRoot: Element): RenderedComponent {
    const props = this.props as Record<string, unknown>;
    const args: Record<string, unknown> = {};

    // Each initial prop is also a named arg, which is how views get `@node`
    for (const key of Object.keys(props)) {
      Object.defineProperty(args, key, {
        enumerable: true,
        get: () => props[key],
      });
    }

    if (!('props' in args)) {
      Object.defineProperty(args, 'props', {
        enumerable: true,
        get: () => this.props,
      });
    }

    const owner = getOwner(this.editor);

    assert(
      '[tiptap-ember] The editor has no owner. Create it with `useEditor(this, …)` ' +
        'or call `setOwner()` in `onBeforeCreate`.',
      owner,
    );

    if (rendering) {
      throw new Error(
        '[tiptap-ember] Cannot render a component while another tiptap-ember ' +
          'component is rendering. Move the transaction out of the render, ' +
          'for example with queueMicrotask().',
      );
    }

    const viewOwner = viewOwnerFor(owner);

    rendering = true;
    markRendered();

    let result;

    try {
      result = renderComponent(this.component, {
        into: renderRoot,
        owner: viewOwner,
        args,
      });
    } finally {
      rendering = false;
    }

    // Ember queues a root added during its own render, so nothing is rendered yet
    if (!renderRoot.firstChild) {
      throw new Error(
        '[tiptap-ember] Cannot render a component while Ember is rendering. ' +
          'Move the transaction out of the render, for example with queueMicrotask().',
      );
    }

    registerDestructor(this, () => {
      this.destroy();
    });

    const destroy = (): void => {
      const element = this.element;

      // Move the element back so Glimmer can remove it
      if (element && element.parentNode !== renderRoot) {
        renderRoot.appendChild(element);
      }

      result.destroy();

      this.renderRoot = null;
    };

    return {
      result,
      destroy,
      el: renderRoot.firstElementChild,
    };
  }

  /**
   * Merges new props into the current props.
   * @param props The props to change.
   */
  updateProps(props: Partial<TProps>): void {
    if (this.destroyed) {
      return;
    }

    const bag = this.props as Record<string, unknown>;

    Object.entries(props).forEach(([key, value]) => {
      bag[key] = value;
    });
  }

  /**
   * Destroys the component and removes its element.
   */
  destroy(): void {
    if (this.destroyed) {
      return;
    }

    this.destroyed = true;
    this.renderedComponent.destroy();
    destroyDestroyable(this);
  }
}
