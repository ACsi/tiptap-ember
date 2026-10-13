import type { TOC } from '@ember/component/template-only';
import type { EmberRendererSignature } from '#src/index.ts';
import type { MentionState } from './state.ts';

export interface MentionListProps {
  state: MentionState;
}

const MentionList: TOC<EmberRendererSignature<MentionListProps>> = <template>
  <ul class="demo-mention">
    {{#each @state.rows key="item" as |row index|}}
      <li>
        <button
          type="button"
          class={{if row.active "is-active"}}
          {{on "click" (fn @state.select index)}}
        >{{row.item}}</button>
      </li>
    {{else}}
      <li class="demo-mention__empty">No matches</li>
    {{/each}}
  </ul>
</template>;

export default MentionList;
