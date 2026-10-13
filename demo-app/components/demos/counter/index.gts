import Component from '@glimmer/component';
import { NodeViewWrapper } from '#src/index.ts';
import type { EmberNodeViewSignature } from '#src/index.ts';

export interface CounterAttrs {
  count: number;
}

export default class Counter extends Component<
  EmberNodeViewSignature<CounterAttrs>
> {
  increment = (): void => {
    this.args.updateAttributes({ count: this.args.attrs.count + 1 });
  };

  decrement = (): void => {
    this.args.updateAttributes({ count: this.args.attrs.count - 1 });
  };

  remove = (): void => {
    this.args.deleteNode();
  };

  <template>
    <NodeViewWrapper @ctx={{@ctx}} class="demo-counter">
      <span data-drag-handle>⠿</span>
      <button type="button" {{on "click" this.decrement}}>−</button>
      <span>{{@attrs.count}}</span>
      <button type="button" {{on "click" this.increment}}>+</button>
      <button type="button" {{on "click" this.remove}}>×</button>
    </NodeViewWrapper>
  </template>
}
