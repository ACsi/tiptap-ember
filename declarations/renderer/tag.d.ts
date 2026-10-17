import type { ComponentLike } from '@glint/template';
export type ElementFromTagName<T extends string> = T extends keyof HTMLElementTagNameMap ? HTMLElementTagNameMap[T] : Element;
export type TagComponent<T extends string> = ComponentLike<{
    Element: ElementFromTagName<T>;
    Blocks: {
        default: [];
    };
}>;
export declare const element: <T extends string>(tagName: T) => TagComponent<T>;
//# sourceMappingURL=tag.d.ts.map