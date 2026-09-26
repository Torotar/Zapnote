import { HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { createHdsTabTitleBarOptions } from '../components/HdsTabTitleBarOptions';
import { DiaryListTabContent } from '../components/DiaryListTabContent';
import { DiaryEntry } from '../model/ZapNoteTypes';

@Component
export struct HomePage {
  @Prop diaries: DiaryEntry[] = [];
  @Prop searchQuery: string = '';
  @Prop tagOptions: string[] = [];
  @Prop materialEffectMode: number = 3;
  @Prop topPadding: number = 132;
  @Prop bottomPadding: number = 154;
  @Prop isDark: boolean = false;
  @Prop pageBg: string = '#F8FAFC';
  @Prop accentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  onSearchChange?: (value: string) => void;
  onEdit?: (id: string) => void;
  onToggleFavorite?: (id: string) => void;
  onDeleteRequest?: (id: string) => void;

  @State private activeTagFilter: string = '__all__';
  private scroller: Scroller = new Scroller();

  build() {
    HdsNavigation() {
      DiaryListTabContent({
        diaries: this.diaries,
        searchQuery: this.searchQuery,
        activeTagFilter: this.activeTagFilter,
        tagOptions: this.tagOptions,
        showSearch: true,
        showTagFilter: true,
        emptyTitle: '落笔生花，从第一篇开始',
        emptySubtitle: '点击右下角的加号按钮，开始记录你的生活小瞬间。',
        emptyIcon: '✦',
        topPadding: this.topPadding,
        bottomPadding: this.bottomPadding,
        isDark: this.isDark,
        accentColor: this.accentColor,
        cardBg: this.cardBg,
        inputBg: this.inputBg,
        lineColor: this.lineColor,
        textPrimary: this.textPrimary,
        textSecondary: this.textSecondary,
        textTertiary: this.textTertiary,
        scroller: this.scroller,
        onSearchChange: (value: string) => {
          if (this.onSearchChange !== undefined) {
            this.onSearchChange(value);
          }
        },
        onTagFilterChange: (value: string) => {
          this.activeTagFilter = value;
        },
        onEdit: (id: string) => {
          if (this.onEdit !== undefined) {
            this.onEdit(id);
          }
        },
        onToggleFavorite: (id: string) => {
          if (this.onToggleFavorite !== undefined) {
            this.onToggleFavorite(id);
          }
        },
        onDeleteRequest: (id: string) => {
          if (this.onDeleteRequest !== undefined) {
            this.onDeleteRequest(id);
          }
        }
      })
    }
    .width('100%')
    .height('100%')
    .titleBar(createHdsTabTitleBarOptions('首页', '', this.isDark, this.materialEffectMode))
    .titleMode(HdsNavigationTitleMode.FULL)
    .hideBackButton(true)
    .bindToScrollable([this.scroller])
    .backgroundColor(this.pageBg)
  }
}
