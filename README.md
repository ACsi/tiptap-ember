# @acsi/tiptap-ember

[![Version](https://img.shields.io/npm/v/@acsi/tiptap-ember.svg?label=version)](https://www.npmjs.com/package/@acsi/tiptap-ember)
[![Downloads](https://img.shields.io/npm/dm/@acsi/tiptap-ember.svg)](https://npmcharts.com/compare/@acsi/tiptap-ember?minimal=true)
[![License](https://img.shields.io/npm/l/@acsi/tiptap-ember.svg)](https://www.npmjs.com/package/@acsi/tiptap-ember)

## Introduction

Ember components for [tiptap](https://tiptap.dev). Render node views, mark views, widget decorations, popups and menus as Ember components. For the editor, extensions and commands, see the [tiptap docs](https://tiptap.dev/docs).

[Live demo](https://acsi.github.io/tiptap-ember/) · [Demo source](demo-app/)

## Compatibility

- Ember 7.1 or newer
- tiptap 3.31.4 or newer
- Embroider or ember-auto-import v2

## Installation

```sh
pnpm add @acsi/tiptap-ember @tiptap/core @tiptap/pm @tiptap/starter-kit
```

The menus need their extensions:

```sh
pnpm add @tiptap/extension-bubble-menu @tiptap/extension-floating-menu
```

## Usage

### The editor

Create the editor with `useEditor` and render it with `<EditorContent>`. The editor is destroyed together with `this`.

```gts
import Component from '@glimmer/component';
import StarterKit from '@tiptap/starter-kit';
import { EditorContent, useEditor } from '@acsi/tiptap-ember';

export default class MyEditor extends Component {
  editor = useEditor(this, {
    extensions: [StarterKit],
    content: '<p>Hello World!</p>',
  });

  <template><EditorContent @editor={{this.editor}} /></template>
}
```

`useEditor` returns an `Editor`. You can also create one with `new Editor(options)` and call `editor.destroy()` yourself. Then set the owner in `onBeforeCreate`, so that views in the initial content can render:

```ts
editor = new Editor({
  extensions: [StarterKit],
  onBeforeCreate: ({ editor }) => setOwner(editor, getOwner(this)!),
});
```

### Reactive state

The editor state is autotracked. Getters that read it update after every transaction.

```gts
get isBold() {
  return this.editor.isActive('bold');
}

get canUndo() {
  return this.editor.can().undo();
}
```

A modifier that reads the state re-runs after every transaction. Commands read the state too, so run them from a modifier in a microtask:

```gts
focusOnInsert = modifier(() => {
  queueMicrotask(() => this.editor.commands.focus());
});
```

### Node views

A node view is a component whose root element is `<NodeViewWrapper>`.

```gts
// counter.gts
import Component from '@glimmer/component';
import {
  NodeViewWrapper,
  type EmberNodeViewSignature,
} from '@acsi/tiptap-ember';

interface CounterAttrs {
  count: number;
}

export default class Counter extends Component<
  EmberNodeViewSignature<CounterAttrs>
> {
  increment = () => {
    this.args.updateAttributes({ count: this.args.attrs.count + 1 });
  };

  <template>
    <NodeViewWrapper @ctx={{@ctx}} class="counter">
      {{~! strip ~}}
      <button type="button" {{on "click" this.increment}}>
        Clicked
        {{@attrs.count}}
        times
      </button>
      {{~! strip ~}}
    </NodeViewWrapper>
  </template>
}
```

Return it from `addNodeView` with `EmberNodeViewRenderer`:

```ts
// counter-extension.ts
import { Node, mergeAttributes } from '@tiptap/core';
import { EmberNodeViewRenderer } from '@acsi/tiptap-ember';
import Counter from './counter.gts';

export default Node.create({
  name: 'counter',
  group: 'block',
  atom: true,

  addAttributes() {
    return { count: { default: 0 } };
  },

  parseHTML() {
    return [{ tag: 'counter-node' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['counter-node', mergeAttributes(HTMLAttributes)];
  },

  addNodeView() {
    return EmberNodeViewRenderer(Counter);
  },
});
```

The component gets these args:

| Arg | Description |
| --- | --- |
| `@editor` | The editor instance. |
| `@node` | The ProseMirror node. |
| `@attrs` | The node's attributes. Same as `@node.attrs`. |
| `@decorations` | The node's decorations. |
| `@innerDecorations` | The decorations inside the node. |
| `@view` | The ProseMirror view. |
| `@selected` | Whether the node is selected. |
| `@extension` | The node extension. |
| `@getPos` | Returns the node's document position. |
| `@HTMLAttributes` | The node's rendered HTML attributes. |
| `@updateAttributes` | Updates the node's attributes. |
| `@deleteNode` | Deletes the node. |
| `@ctx` | Pass it to `<NodeViewWrapper>` and `<NodeViewContent>`. |

#### Editable content

Render the node's content with `<NodeViewContent>`:

```gts
<NodeViewWrapper @ctx={{@ctx}} class="callout">
  {{~! strip ~}}
  <NodeViewContent @ctx={{@ctx}} />
  {{~! strip ~}}
</NodeViewWrapper>
```

Both components render a `div`. Use `@as` for another tag, for example `<NodeViewWrapper @as="span">` in an inline node.

#### Dragging

Set `draggable: true` on the node and add a `data-drag-handle` element:

```gts
<span data-drag-handle>⠿</span>
```

### Mark views

A mark view renders the marked text with `<MarkViewContent>`. The component must render a single root element.

```gts
// highlight.gts
import type { TOC } from '@ember/component/template-only';
import {
  MarkViewContent,
  type EmberMarkViewSignature,
} from '@acsi/tiptap-ember';

const Highlight: TOC<EmberMarkViewSignature> = <template>
  <mark class="highlight"><MarkViewContent @ctx={{@ctx}} /></mark>
</template>;

export default Highlight;
```

```ts
addMarkView() {
  return EmberMarkViewRenderer(Highlight);
}
```

The component gets `@editor`, `@mark`, `@attrs`, `@inline`, `@view`, `@extension`, `@HTMLAttributes`, `@updateAttributes` and `@ctx`.

### Widget decorations

Render a component at a document position with `EmberWidgetRenderer`. Give each widget a stable `key`. The component must render a single root element.

```ts
import { Extension } from '@tiptap/core';
import { EmberWidgetRenderer } from '@acsi/tiptap-ember';
import WordCount from './word-count.gts';

export default Extension.create({
  name: 'wordCount',

  addDecorations() {
    return {
      create: ({ editor, state }) => [
        EmberWidgetRenderer(WordCount, {
          editor,
          pos: state.doc.content.size,
          key: 'word-count',
          props: { words: state.doc.textContent.split(/\s+/).length },
        }),
      ],
    };
  },
});
```

The component gets the props as named args (`@words`), plus `@editor` and `@getPos`. A prop that is missing on the first render is only in `@props`. Type the component with `EmberWidgetDecorationSignature<{ words: number }>`.

### Popups

`EmberRenderer` renders a component into a detached element. Use it for [suggestion](https://tiptap.dev/docs/editor/api/utilities/suggestion) popups like mentions or slash commands.

```ts
import { EmberRenderer } from '@acsi/tiptap-ember';
import MentionList from './mention-list.gts';

// in the suggestion `render()` callback
let renderer;

return {
  onStart: (props) => {
    renderer = new EmberRenderer(MentionList, {
      editor: props.editor,
      props: { items: props.items, command: props.command },
    });

    document.body.appendChild(renderer.element);
  },

  onUpdate: (props) => {
    renderer.updateProps({ items: props.items, command: props.command });
  },

  onExit: () => {
    renderer.destroy();
  },
};
```

The component gets the props as named args (`@items`). A prop that is missing on the first render is only in `@props`.

```gts
import type { TOC } from '@ember/component/template-only';
import type { EmberRendererSignature } from '@acsi/tiptap-ember';

interface MentionListProps {
  items: string[];
  command: (item: string) => void;
}

const MentionList: TOC<EmberRendererSignature<MentionListProps>> = <template>
  <ul>
    {{#each @items as |item|}}
      <li>
        <button type="button" {{on "click" (fn @command item)}}>
          {{item}}
        </button>
      </li>
    {{/each}}
  </ul>
</template>;

export default MentionList;
```

The component must render a single root element. See the [mention demo](demo-app/components/demos/mention/) for keyboard navigation.

### Menus

```gts
import { BubbleMenu, FloatingMenu } from '@acsi/tiptap-ember/menus';

<template>
  <BubbleMenu @editor={{this.editor}} class="menu">
    <button type="button" {{on "click" this.toggleBold}}>Bold</button>
  </BubbleMenu>

  <FloatingMenu @editor={{this.editor}} class="menu">
    <button type="button" {{on "click" this.toggleHeading}}>H1</button>
  </FloatingMenu>
</template>
```

The args match the [bubble menu](https://tiptap.dev/docs/editor/extensions/functionality/bubble-menu) and [floating menu](https://tiptap.dev/docs/editor/extensions/functionality/floating-menu) options.

## Whitespace in view templates

Glimmer keeps the whitespace between elements as text nodes. Inside the editor, these text nodes show up as spaces and can confuse ProseMirror. Keep node view and mark view templates free of them, in one of two ways.

**Whitespace control.** A `{{~! strip ~}}` comment removes the whitespace on both sides:

```gts
<NodeViewWrapper @ctx={{@ctx}}>
  {{~! strip ~}}
  <button type="button">Do it</button>
  {{~! strip ~}}
  <NodeViewContent @ctx={{@ctx}} />
  {{~! strip ~}}
</NodeViewWrapper>
```

**[ember-hbs-minifier](https://github.com/Mainmatter/ember-hbs-minifier).** It removes this whitespace for the whole app. In a classic build, `ember install ember-hbs-minifier` is enough. In a Vite build, add it to the template compiler:

```js
// babel.config.cjs
const {
  createRegistryPlugin,
} = require('ember-hbs-minifier/hbs-minifier-plugin');

module.exports = {
  plugins: [
    [
      'babel-plugin-ember-template-compilation',
      {
        transforms: [
          // ...your other transforms
          createRegistryPlugin(),
        ],
      },
    ],
  ],
};
```

Whitespace around the root element doesn't matter. Only the root element ends up in the editor.

## FastBoot

The editor runs only in the browser, and `useEditor` asserts in FastBoot. Render the component that creates the editor only in the browser:

```gts
{{#unless this.fastboot.isFastBoot}}
  <MyEditor />
{{/unless}}
```

## API

Everything comes from `@acsi/tiptap-ember`, except the menus (`@acsi/tiptap-ember/menus`) and the Glint registry (`@acsi/tiptap-ember/template-registry`). The package also re-exports `@tiptap/core`, so `Node`, `Mark`, `Extension` and `mergeAttributes` come from the same import. Its `Editor` is the reactive one below.

### `useEditor`

Creates an editor that is destroyed together with `parent`.

```ts
import { useEditor } from '@acsi/tiptap-ember';

useEditor(parent: object, options?: Partial<EditorOptions>): Editor
```

| Parameter | Description |
| --- | --- |
| `parent` | The component or service that owns the editor, usually `this`. |
| `options` | The [editor settings](https://tiptap.dev/docs/editor/api/editor). Optional. |

Example: [The editor](#the-editor).

### `Editor`

The tiptap editor with autotracked state. Call `editor.destroy()` yourself.

```ts
import { Editor } from '@acsi/tiptap-ember';

new Editor(options?: Partial<EditorOptions>): Editor
```

| Parameter | Description |
| --- | --- |
| `options` | The editor settings. Set the owner in `onBeforeCreate`. Optional. |

Example: [The editor](#the-editor).

### `<EditorContent>`

Renders the editor into a `div`. Attributes go on the `div`, and the block form yields `{ editor }`.

```gts
import { EditorContent } from '@acsi/tiptap-ember';

<EditorContent @editor={{this.editor}} />
```

| Arg | Description |
| --- | --- |
| `@editor` | The editor to render. |

Example: [The editor](#the-editor).

### `EmberNodeViewRenderer`

Renders a component as a node view. Return it from `addNodeView`.

```ts
import { EmberNodeViewRenderer } from '@acsi/tiptap-ember';

EmberNodeViewRenderer(
  component: ComponentLike<EmberNodeViewSignature<Attrs>>,
  options?: Partial<EmberNodeViewRendererOptions>,
): NodeViewRenderer
```

| Parameter | Description |
| --- | --- |
| `component` | The node view. Its root element is `<NodeViewWrapper>`, and its args are listed under [Node views](#node-views). |
| `options.contentDOMElementTag` | The tag of the element that holds the content. Defaults to `div`, or `span` in an inline node. Optional. |
| `options.stopEvent` | `({ event }) => boolean`. Whether the editor ignores an event from inside the view. Optional. |
| `options.ignoreMutation` | `({ mutation }) => boolean`. Whether ProseMirror ignores a DOM change inside the view. Optional. |
| `options.selectedOnTextSelection` | `@selected` is also `true` when the selection is inside the node. Defaults to `false`. Optional. |
| `options.trackNodeViewPosition` | Re-renders when the node moves, so `@getPos()` in a template stays current. Defaults to `false`. Optional. |
| `options.update` | Replaces the default update. Call `updateProps()` to re-render, and return whether the update was handled. Optional. |

Example: [Node views](#node-views).

### `<NodeViewWrapper>`

The root element of a node view.

```gts
import { NodeViewWrapper } from '@acsi/tiptap-ember';

<NodeViewWrapper @ctx={{@ctx}}>…</NodeViewWrapper>
```

| Arg | Description |
| --- | --- |
| `@ctx` | The component's `@ctx`. |
| `@as` | The tag. Defaults to `div`. It can't change after the first render. Optional. |

Example: [Node views](#node-views).

### `<NodeViewContent>`

Where the editable content of a node view goes.

```gts
import { NodeViewContent } from '@acsi/tiptap-ember';

<NodeViewContent @ctx={{@ctx}} />
```

| Arg | Description |
| --- | --- |
| `@ctx` | The component's `@ctx`. |
| `@as` | The tag. Defaults to `div`. Optional. |

Example: [Editable content](#editable-content).

### `EmberMarkViewRenderer`

Renders a component as a mark view. Return it from `addMarkView`.

```ts
import { EmberMarkViewRenderer } from '@acsi/tiptap-ember';

EmberMarkViewRenderer(
  component: ComponentLike<EmberMarkViewSignature<Attrs>>,
  options?: Partial<EmberMarkViewRendererOptions>,
): MarkViewRenderer
```

| Parameter | Description |
| --- | --- |
| `component` | The mark view. It renders a single root element, and its args are listed under [Mark views](#mark-views). |
| `options.ignoreMutation` | `({ mutation }) => boolean`. Whether ProseMirror ignores a DOM change inside the view. Optional. |

Example: [Mark views](#mark-views).

### `<MarkViewContent>`

Where the marked text of a mark view goes.

```gts
import { MarkViewContent } from '@acsi/tiptap-ember';

<MarkViewContent @ctx={{@ctx}} />
```

| Arg | Description |
| --- | --- |
| `@ctx` | The component's `@ctx`. |
| `@as` | The tag. Defaults to `span`. Optional. |

Example: [Mark views](#mark-views).

### `EmberNodeView` and `EmberMarkView`

The classes behind the two renderers. Extend one to change a view method.

```ts
import { EmberMarkView, EmberNodeView } from '@acsi/tiptap-ember';

new EmberNodeView(component, props: NodeViewRendererProps, options: Partial<EmberNodeViewRendererOptions>)
new EmberMarkView(component, props: MarkViewProps, options: Partial<EmberMarkViewRendererOptions>)
```

| Parameter | Description |
| --- | --- |
| `component` | The view component, as for the renderer. |
| `props` | The props tiptap passes to the renderer function. |
| `options` | The renderer options. |

Example:

```ts
addNodeView() {
  return (props) => new MyNodeView(Counter, props, {});
}
```

### `EmberWidgetRenderer`

Renders a component as a widget decoration. Return it from `addDecorations`.

```ts
import { EmberWidgetRenderer } from '@acsi/tiptap-ember';

EmberWidgetRenderer(
  component: ComponentLike<EmberWidgetDecorationSignature<Props>>,
  options: EmberWidgetRendererOptions<Props>,
): WidgetDecoration
```

| Parameter | Description |
| --- | --- |
| `component` | The widget. It renders a single root element and gets the props as named args, plus `@editor`, `@getPos` and `@props`. |
| `options.editor` | The editor. |
| `options.pos` | The document position of the widget. |
| `options.key` | A stable identifier. The same key keeps the component mounted. |
| `options.props` | The props passed to the component. Optional. |
| `options.side`, `.relaxedSide`, `.marks`, `.stopEvent`, `.ignoreSelection`, `.destroy` | ProseMirror's widget options. Optional. |

Example: [Widget decorations](#widget-decorations).

### `EmberRenderer`

Renders a component into a detached element, for example a suggestion popup.

```ts
import { EmberRenderer } from '@acsi/tiptap-ember';

new EmberRenderer(
  component: ComponentLike<EmberRendererSignature<Props>>,
  options: { editor: Editor; props?: Props },
): EmberRenderer
```

| Parameter | Description |
| --- | --- |
| `component` | The component. It renders a single root element. |
| `options.editor` | The editor. The component's owner inherits from the editor's owner. |
| `options.props` | The props passed to the component. Optional. |

| Member | Description |
| --- | --- |
| `element: Element \| null` | The component's root element. Append it where it should show. |
| `props: Props` | The current props. |
| `updateProps(props: Partial<Props>): void` | Merges new props in and re-renders. |
| `destroy(): void` | Tears the component down and removes its element. |
| `destroyed: boolean` | Whether `destroy()` has run. |

Example: [Popups](#popups).

### `<BubbleMenu>` and `<FloatingMenu>`

Menus that show next to the selection and on empty lines. They need `@tiptap/extension-bubble-menu` and `@tiptap/extension-floating-menu`. Attributes go on the menu element.

```gts
import { BubbleMenu, FloatingMenu } from '@acsi/tiptap-ember/menus';

<BubbleMenu @editor={{this.editor}}>…</BubbleMenu>
<FloatingMenu @editor={{this.editor}}>…</FloatingMenu>
```

| Arg | Description |
| --- | --- |
| `@editor` | The editor. |
| `@pluginKey` | The plugin key. Defaults to `'bubbleMenu'` or `'floatingMenu'`. Optional. |
| `@updateDelay` | The delay in milliseconds before the menu updates. Defaults to `250`. Optional. |
| `@resizeDelay` | The delay in milliseconds before the menu moves on window resize. Defaults to `60`. Optional. |
| `@options` | The [Floating UI options](https://floating-ui.com/docs/computePosition#options). Optional. |
| `@appendTo` | The element the menu is appended to. Defaults to the editor's parent element. Optional. |
| `@shouldShow` | Whether the menu should show. Optional. |
| `@getReferencedVirtualElement` | `<BubbleMenu>` only. The virtual element the menu is positioned against. Optional. |

Example: [Menus](#menus).

### Glint registry

Types the components in loose-mode (`.hbs`) templates. `.gts` files don't need it.

```ts
import type TiptapEmberRegistry from '@acsi/tiptap-ember/template-registry';

declare module '@glint/environment-ember-loose/registry' {
  export default interface Registry extends TiptapEmberRegistry {}
}
```

### Types

- `EmberNodeViewSignature<Attrs>`, `EmberNodeViewArgs<Attrs>`, `EmberNodeViewRendererOptions`
- `EmberMarkViewSignature<Attrs>`, `EmberMarkViewArgs<Attrs>`, `EmberMarkViewRendererOptions`
- `EmberWidgetDecorationSignature<Props>`, `EmberWidgetDecorationArgs`, `EmberWidgetRendererOptions<Props>`
- `EmberRendererSignature<Props>`, `EmberRendererOptions<Props>`
- `EditorContentSignature`, `NodeViewContext`, `MarkViewContext`
- `BubbleMenuSignature`, `FloatingMenuSignature` from `@acsi/tiptap-ember/menus`

## Contributing

See the [Contributing](CONTRIBUTING.md) guide for details.

## License

This project is licensed under the [MIT License](LICENSE.md).
