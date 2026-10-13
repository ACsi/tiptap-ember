import Component from '@glimmer/component';
import { MarkViewContent } from '#src/index.ts';
import type { EmberMarkViewSignature } from '#src/index.ts';

export type HighlightColor = 'yellow' | 'green' | 'pink';

export interface HighlightAttrs {
  color: HighlightColor;
}

const ORDER: HighlightColor[] = ['yellow', 'green', 'pink'];

export default class Highlight extends Component<
  EmberMarkViewSignature<HighlightAttrs>
> {
  cycle = (): void => {
    const current = this.args.attrs.color;
    const next = ORDER[(ORDER.indexOf(current) + 1) % ORDER.length]!;
    this.args.updateAttributes({ color: next });
  };

  <template>
    <span class="demo-highlight demo-highlight--{{@attrs.color}}">
      {{! Before the content, or ArrowRight gets stuck at the mark end }}
      <button
        type="button"
        contenteditable="false"
        class="demo-highlight__chip"
        {{on "click" this.cycle}}
      >{{@attrs.color}}</button>
      <MarkViewContent @ctx={{@ctx}} />
    </span>
  </template>
}
