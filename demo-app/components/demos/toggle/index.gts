import Component from '@glimmer/component';
import { NodeViewWrapper, NodeViewContent } from '#src/index.ts';
import type { EmberNodeViewSignature } from '#src/index.ts';

export interface ToggleAttrs {
  checked: boolean;
}

export default class Toggle extends Component<
  EmberNodeViewSignature<ToggleAttrs>
> {
  handleToggle = (event: Event): void => {
    const target = event.target as HTMLInputElement;

    this.args.updateAttributes({ checked: target.checked });
  };

  <template>
    <NodeViewWrapper @ctx={{@ctx}} class="demo-toggle">
      <label class="demo-toggle__header" contenteditable="false">
        <input
          type="checkbox"
          checked={{@attrs.checked}}
          {{on "change" this.handleToggle}}
        />
        <span>Show editable content</span>
      </label>
      {{#if @attrs.checked}}
        <NodeViewContent class="demo-toggle__content" @ctx={{@ctx}} />
      {{/if}}
    </NodeViewWrapper>
  </template>
}
