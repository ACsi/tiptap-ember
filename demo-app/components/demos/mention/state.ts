import { tracked } from '@glimmer/tracking';

export interface MentionRow {
  item: string;
  active: boolean;
}

export class MentionState {
  @tracked items: string[] = [];

  @tracked selectedIndex = 0;

  command: (item: string) => void = () => {};

  get activeIndex(): number {
    const { length } = this.items;

    if (length === 0) {
      return 0;
    }

    return ((this.selectedIndex % length) + length) % length;
  }

  get rows(): MentionRow[] {
    const active = this.activeIndex;

    return this.items.map((item, index) => ({
      item,
      active: index === active,
    }));
  }

  onKeyDown(event: KeyboardEvent): boolean {
    if (this.items.length === 0) {
      return false;
    }

    if (event.key === 'ArrowUp') {
      this.selectedIndex = this.activeIndex - 1;

      return true;
    }

    if (event.key === 'ArrowDown') {
      this.selectedIndex = this.activeIndex + 1;

      return true;
    }

    if (event.key === 'Enter') {
      this.select(this.activeIndex);

      return true;
    }

    return false;
  }

  select = (index: number): void => {
    const item = this.items[index];

    if (item) {
      this.command(item);
    }
  };
}
