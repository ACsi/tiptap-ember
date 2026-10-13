import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { StarterKit } from '@tiptap/starter-kit';
import { EditorContent, useEditor, type Editor } from '#src/index.ts';
import { BubbleMenu, FloatingMenu } from '#src/menus/index.ts';
import CalloutExtension from './demos/callout/extension.ts';
import CounterExtension from './demos/counter/extension.ts';
import HighlightExtension from './demos/highlight/extension.ts';
import MentionExtension from './demos/mention/extension.ts';
import SearchExtension, { setSearchTerm } from './demos/search/extension.ts';
import ToggleExtension from './demos/toggle/extension.ts';
import WordCountExtension from './demos/word-count/extension.ts';

interface EditorPageSignature {
  Args: {
    content: string;
  };
}

interface ButtonState {
  active: boolean;
  disabled: boolean;
}

export default class EditorPage extends Component<EditorPageSignature> {
  editor: Editor = useEditor(this, {
    extensions: [
      StarterKit,
      CounterExtension,
      CalloutExtension,
      HighlightExtension,
      MentionExtension,
      SearchExtension,
      ToggleExtension,
      WordCountExtension,
    ],
    content: this.args.content,
  });

  // Unmounts <EditorContent> while the editor lives on
  @tracked detached = false;

  get json(): string {
    return JSON.stringify(this.editor.getJSON(), null, 2);
  }

  get html(): string {
    return this.editor.getHTML();
  }

  @cached
  get heading1Button(): ButtonState {
    return {
      active: this.editor.isActive('heading', { level: 1 }),
      disabled: !this.editor
        .can()
        .chain()
        .focus()
        .toggleHeading({ level: 1 })
        .run(),
    };
  }

  @cached
  get heading2Button(): ButtonState {
    return {
      active: this.editor.isActive('heading', { level: 2 }),
      disabled: !this.editor
        .can()
        .chain()
        .focus()
        .toggleHeading({ level: 2 })
        .run(),
    };
  }

  @cached
  get highlightButton(): ButtonState {
    return {
      active: this.editor.isActive('demoHighlight'),
      disabled: !this.editor
        .can()
        .chain()
        .focus()
        .toggleMark('demoHighlight', { color: 'yellow' })
        .run(),
    };
  }

  @cached
  get boldButton(): ButtonState {
    return {
      active: this.editor.isActive('bold'),
      disabled: !this.editor.can().chain().focus().toggleBold().run(),
    };
  }

  @cached
  get counterButton(): ButtonState {
    return {
      active: false,
      disabled: !this.editor
        .can()
        .chain()
        .focus()
        .insertContent({ type: 'demoCounter', attrs: { count: 0 } })
        .run(),
    };
  }

  @cached
  get calloutButton(): ButtonState {
    return {
      active: this.editor.isActive('demoCallout'),
      disabled: !this.editor
        .can()
        .chain()
        .focus()
        .insertContent({
          type: 'demoCallout',
          attrs: { variant: 'info' },
          content: [
            {
              type: 'paragraph',
              content: [{ type: 'text', text: 'edit me!' }],
            },
          ],
        })
        .run(),
    };
  }

  @cached
  get toggleButton(): ButtonState {
    return {
      active: this.editor.isActive('demoToggle'),
      disabled: !this.editor
        .can()
        .chain()
        .focus()
        .insertContent({
          type: 'demoToggle',
          attrs: { checked: false },
          content: [
            {
              type: 'paragraph',
              content: [{ type: 'text', text: 'hidden when unchecked' }],
            },
          ],
        })
        .run(),
    };
  }

  @cached
  get undoButton(): ButtonState {
    return { active: false, disabled: !this.editor.can().undo() };
  }

  @cached
  get redoButton(): ButtonState {
    return { active: false, disabled: !this.editor.can().redo() };
  }

  insertCounter = (): void => {
    this.editor
      .chain()
      .focus()
      .insertContent({ type: 'demoCounter', attrs: { count: 0 } })
      .run();
  };

  insertCallout = (): void => {
    this.editor
      .chain()
      .focus()
      .insertContent({
        type: 'demoCallout',
        attrs: { variant: 'info' },
        content: [
          { type: 'paragraph', content: [{ type: 'text', text: 'edit me!' }] },
        ],
      })
      .run();
  };

  insertToggle = (): void => {
    this.editor
      .chain()
      .focus()
      .insertContent({
        type: 'demoToggle',
        attrs: { checked: false },
        content: [
          {
            type: 'paragraph',
            content: [{ type: 'text', text: 'hidden when unchecked' }],
          },
        ],
      })
      .run();
  };

  toggleHeading = (level: 1 | 2): void => {
    this.editor.chain().focus().toggleHeading({ level }).run();
  };

  toggleBold = (): void => {
    this.editor.chain().focus().toggleBold().run();
  };

  toggleHighlight = (): void => {
    this.editor
      .chain()
      .focus()
      .toggleMark('demoHighlight', { color: 'yellow' })
      .run();
  };

  undo = (): void => {
    this.editor.chain().focus().undo().run();
  };

  redo = (): void => {
    this.editor.chain().focus().redo().run();
  };

  toggleDetached = (): void => {
    this.detached = !this.detached;
  };

  handleSearchInput = (event: Event): void => {
    const target = event.target as HTMLInputElement;

    setSearchTerm(this.editor, target.value);
  };

  <template>
    <section class="demo-page">
      <div class="toolbar">
        <button
          type="button"
          class={{if this.heading1Button.active "is-active"}}
          disabled={{this.heading1Button.disabled}}
          {{on "click" (fn this.toggleHeading 1)}}
        >H1</button>
        <button
          type="button"
          class={{if this.heading2Button.active "is-active"}}
          disabled={{this.heading2Button.disabled}}
          {{on "click" (fn this.toggleHeading 2)}}
        >H2</button>
        <button
          type="button"
          class={{if this.highlightButton.active "is-active"}}
          disabled={{this.highlightButton.disabled}}
          {{on "click" this.toggleHighlight}}
        >Highlight</button>
        <button
          type="button"
          disabled={{this.counterButton.disabled}}
          {{on "click" this.insertCounter}}
        >+ Counter</button>
        <button
          type="button"
          class={{if this.calloutButton.active "is-active"}}
          disabled={{this.calloutButton.disabled}}
          {{on "click" this.insertCallout}}
        >+ Callout</button>
        <button
          type="button"
          class={{if this.toggleButton.active "is-active"}}
          disabled={{this.toggleButton.disabled}}
          {{on "click" this.insertToggle}}
        >+ Toggle</button>
        <button
          type="button"
          disabled={{this.undoButton.disabled}}
          {{on "click" this.undo}}
        >Undo</button>
        <button
          type="button"
          disabled={{this.redoButton.disabled}}
          {{on "click" this.redo}}
        >Redo</button>
        <input
          type="search"
          class="toolbar__search"
          placeholder="Highlight matches…"
          aria-label="Highlight matches"
          {{on "input" this.handleSearchInput}}
        />
        <label class="toolbar__detach">
          <input
            type="checkbox"
            checked={{this.detached}}
            {{on "change" this.toggleDetached}}
          />
          Detach editor
        </label>
        <span class="toolbar__hint">Type <kbd>@</kbd> to mention</span>
      </div>

      <BubbleMenu @editor={{this.editor}} class="demo-menu">
        <button
          type="button"
          class={{if this.boldButton.active "is-active"}}
          disabled={{this.boldButton.disabled}}
          {{on "click" this.toggleBold}}
        >Bold</button>
      </BubbleMenu>

      <FloatingMenu @editor={{this.editor}} class="demo-menu">
        <button
          type="button"
          class={{if this.boldButton.active "is-active"}}
          disabled={{this.boldButton.disabled}}
          {{on "click" this.toggleBold}}
        >Bold</button>
      </FloatingMenu>

      {{#if this.detached}}
        <p class="editor-detached-note">
          Editor detached — the instance and its document are still alive.
        </p>
      {{else}}
        <EditorContent class="editor-host" @editor={{this.editor}} />
      {{/if}}

      <pre class="demo-output">{{this.json}}</pre>
      <pre class="demo-output demo-output--wrap">{{this.html}}</pre>
    </section>
  </template>
}
