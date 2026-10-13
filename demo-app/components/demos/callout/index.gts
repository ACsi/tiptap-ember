import Component from '@glimmer/component';
import { NodeViewWrapper, NodeViewContent } from '#src/index.ts';
import type { EmberNodeViewSignature } from '#src/index.ts';

export type CalloutVariant = 'info' | 'warn';

export interface CalloutAttrs {
  variant: CalloutVariant;
}

export default class Callout extends Component<
  EmberNodeViewSignature<CalloutAttrs>
> {
  toggleVariant = (): void => {
    const next: CalloutVariant =
      this.args.attrs.variant === 'info' ? 'warn' : 'info';
    this.args.updateAttributes({ variant: next });
  };

  <template>
    <NodeViewWrapper
      @ctx={{@ctx}}
      class="demo-callout demo-callout--{{@attrs.variant}}"
    >
      <header class="demo-callout__header" contenteditable="false">
        <span data-drag-handle>⠿</span>
        <span>{{@attrs.variant}}</span>
        <button type="button" {{on "click" this.toggleVariant}}>
          toggle
        </button>
      </header>
      <NodeViewContent class="demo-callout__content" @ctx={{@ctx}} />
    </NodeViewWrapper>
  </template>
}
