import type { TOC } from '@ember/component/template-only';
import type { EmberWidgetDecorationSignature } from '#src/index.ts';

export interface WordCountProps {
  words: number;
}

const WordCount: TOC<EmberWidgetDecorationSignature<WordCountProps>> =
  <template>
    <span class="demo-word-count">{{@words}} words</span>
  </template>;

export default WordCount;
