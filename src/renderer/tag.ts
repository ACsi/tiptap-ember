import { element as emberElement } from '@ember/helper';

import type { ComponentLike } from '@glint/template';

export type ElementFromTagName<T extends string> =
  T extends keyof HTMLElementTagNameMap ? HTMLElementTagNameMap[T] : Element;

export type TagComponent<T extends string> = ComponentLike<{
  Element: ElementFromTagName<T>;
  Blocks: { default: [] };
}>;

// Retyped: Glint can't resolve the keyword's element type for a generic tag
export const element = emberElement as unknown as <T extends string>(
  tagName: T,
) => TagComponent<T>;
