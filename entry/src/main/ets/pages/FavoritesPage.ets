import { HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { createHdsTabTitleBarOptions } from '../components/HdsTabTitleBarOptions';
import { DiaryListTabContent } from '../components/DiaryListTabContent';
import { DiaryEntry } from '../model/ZapNoteTypes';

@Component
export struct FavoritesPage {
  @Prop diaries: DiaryEntry[] = [];
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
  onEdit?: (id: string) => void;
  onToggleFavorite?: (id: string) => void;
  onDeleteRequest?: (id: string) => void;

  @State private activeTagFilter: string = '__all__';
  private scroller: Scroller = new Scroller();

  build() {
    HdsNavigation() {
      DiaryListTabContent({
        diaries: this.diaries,
        searchQuery: '',
        activeTagFilter: this.activeTagFilter,
        tagOptions: this.tagOptions,
        showSearch: false,
        showTagFilter: true,
        emptyTitle: '这里还没有收藏',
        emptySubtitle: '把值得回看的瞬间放在手边。',
        emptyIcon: '',
        emptyIconResource: $rawfile('icons/zap_tab_favorite_red_filled.svg'),
        emptyIconColor: '#EF4444',
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
    .titleBar(createHdsTabTitleBarOptions('收藏', '', this.isDark, this.materialEffectMode))
    .titleMode(HdsNavigationTitleMode.FULL)
    .hideBackButton(true)
    .bindToScrollable([this.scroller])
    .backgroundColor(this.pageBg)
  }
}
