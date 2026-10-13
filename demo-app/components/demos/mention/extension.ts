import { Extension } from '@tiptap/core';
import { PluginKey } from '@tiptap/pm/state';
import Suggestion, {
  type SuggestionKeyDownProps,
  type SuggestionProps,
} from '@tiptap/suggestion';
import { EmberRenderer } from '#src/index.ts';
import MentionList, { type MentionListProps } from './index.gts';
import { MentionState } from './state.ts';

const PEOPLE = [
  'Ada Lovelace',
  'Alan Turing',
  'Grace Hopper',
  'Katherine Johnson',
  'Edsger Dijkstra',
  'Barbara Liskov',
  'Donald Knuth',
];

function positionAt(
  element: Element | null,
  clientRect: SuggestionProps<string>['clientRect'],
): void {
  const rect = clientRect?.();

  if (!rect || !(element instanceof HTMLElement)) {
    return;
  }

  element.style.left = `${rect.left}px`;
  element.style.top = `${rect.bottom + 4}px`;
}

export default Extension.create({
  name: 'demoMention',

  addProseMirrorPlugins() {
    return [
      Suggestion<string, string>({
        editor: this.editor,
        char: '@',
        pluginKey: new PluginKey('demoMention'),

        items: ({ query }) =>
          PEOPLE.filter((name) =>
            name.toLowerCase().includes(query.toLowerCase()),
          ).slice(0, 5),

        command: ({ editor, range, props }) => {
          editor.chain().focus().insertContentAt(range, `@${props} `).run();
        },

        render: () => {
          let renderer: EmberRenderer<MentionListProps> | null = null;
          const state = new MentionState();

          const update = (props: SuggestionProps<string, string>): void => {
            state.items = props.items;
            state.selectedIndex = 0;
            state.command = (item) => props.command(item);
          };

          const teardown = (): void => {
            renderer?.destroy();
            renderer = null;
          };

          return {
            onStart: (props: SuggestionProps<string, string>) => {
              update(props);

              renderer = new EmberRenderer<MentionListProps>(MentionList, {
                editor: props.editor,
                props: { state },
              });

              if (renderer.element) {
                document.body.appendChild(renderer.element);
              }

              positionAt(renderer.element, props.clientRect);
            },

            onUpdate: (props: SuggestionProps<string, string>) => {
              update(props);
              positionAt(renderer?.element ?? null, props.clientRect);
            },

            onKeyDown: (props: SuggestionKeyDownProps) => {
              if (props.event.key === 'Escape') {
                teardown();

                return true;
              }

              return state.onKeyDown(props.event);
            },

            onExit: teardown,
          };
        },
      }),
    ];
  },
});
