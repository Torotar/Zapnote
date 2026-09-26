import { ChipGroup, ChipGroupItemOptions } from '@kit.ArkUI';
import { DiaryStatsUtils } from '../utils/DiaryStatsUtils';
import { DiaryEntry } from '../model/ZapNoteTypes';
import { DiaryEntryCard } from './DiaryEntryCard';
import { EmptyStateCard } from './EmptyStateCard';

interface FavoriteOverride {
  id: string;
  isFavorite: boolean;
}

@Component
export struct DiaryListTabContent {
  @Prop diaries: DiaryEntry[] = [];
  @Prop searchQuery: string = '';
  @Prop activeTagFilter: string = '__all__';
  @Prop tagOptions: string[] = [];
  @Prop showSearch: boolean = true;
  @Prop showTagFilter: boolean = false;
  @Prop privacyMode: boolean = false;
  @Prop privacyFavoritesOnly: boolean = false;
  @Prop emptyTitle: string = '';
  @Prop emptySubtitle: string = '';
  @Prop emptyIcon: string = '';
  @Prop emptyIconResource: Resource | null = null;
  @Prop emptyIconColor: string = '';
  @Prop topPadding: number = 132;
  @Prop bottomPadding: number = 154;
  @Prop isDark: boolean = false;
  @Prop accentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  @State favoriteOverrides: FavoriteOverride[] = [];
  scroller: Scroller = new Scroller();
  private searchController: SearchController = new SearchController();
  private searchActivatedByTouch: boolean = false;
  onSearchChange?: (value: string) => void;
  onTagFilterChange?: (value: string) => void;
  onEdit?: (id: string) => void;
  onToggleFavorite?: (id: string) => void;
  onDeleteRequest?: (id: string) => void;
  onMoveOutOfPrivacy?: (id: string) => void;
  onPermanentDeleteRequest?: (id: string) => void;

  private normalizedTag(value: string): string {
    return value.trim();
  }

  private favoriteDiaries(): DiaryEntry[] {
    return DiaryStatsUtils.filterDiaries(this.diaries, 'favorite', '');
  }

  private privateDiaries(): DiaryEntry[] {
    return this.diaries.filter((entry: DiaryEntry): boolean => entry.isPrivate === true);
  }

  private tagValues(): string[] {
    const result: string[] = ['__all__', ''];
    this.tagOptions.forEach((item: string) => {
      const value: string = this.normalizedTag(item);
      if (value.length > 0 && result.indexOf(value) < 0) {
        result.push(value);
      }
    });
    return result;
  }

  private tagLabel(value: string): string {
    if (value === '__all__') {
      return '全部';
    }
    if (value.length === 0) {
      return '无标签';
    }
    return value;
  }

  private tagItems(): ChipGroupItemOptions[] {
    const items: ChipGroupItemOptions[] = [];
    this.tagValues().forEach((value: string) => {
      items.push({ label: { text: this.tagLabel(value) } });
    });
    return items;
  }

  private selectedTagIndex(): number {
    const values: string[] = this.tagValues();
    const index: number = values.indexOf(this.effectiveTagFilter());
    return index >= 0 ? index : 0;
  }

  private effectiveTagFilter(): string {
    const values: string[] = this.tagValues();
    return values.indexOf(this.activeTagFilter) >= 0 ? this.activeTagFilter : '__all__';
  }

  private tagAt(index: number): string {
    const values: string[] = this.tagValues();
    if (index >= 0 && index < values.length) {
      return values[index];
    }
    return '__all__';
  }

  private tagGroupWidth(): number {
    return Math.max(1, this.tagValues().length) * 88 - 6;
  }

  private effectiveFavorite(entry: DiaryEntry): boolean {
    const matches: FavoriteOverride[] = this.favoriteOverrides.filter((item: FavoriteOverride): boolean => {
      return item.id === entry.id;
    });
    if (matches.length > 0) {
      return matches[0].isFavorite;
    }
    return entry.isFavorite;
  }

  private setFavoriteOverride(id: string, isFavorite: boolean): void {
    const next: FavoriteOverride[] = [];
    let updated = false;
    this.favoriteOverrides.forEach((item: FavoriteOverride) => {
      if (item.id === id) {
        next.push({ id: id, isFavorite: isFavorite });
        updated = true;
      } else {
        next.push(item);
      }
    });
    if (!updated) {
      next.push({ id: id, isFavorite: isFavorite });
    }
    this.favoriteOverrides = next;
  }

  private textSignature(value: string): string {
    let result = value.length;
    for (let index = 0; index < value.length; index++) {
      result = (result * 31 + value.charCodeAt(index)) % 1000000007;
    }
    return result.toString();
  }

  private photoSignature(entry: DiaryEntry): string {
    const parts: string[] = [];
    if (typeof entry.photoUri === 'string' && entry.photoUri.length > 0) {
      parts.push(entry.photoUri);
    }
    if (Array.isArray(entry.photoUris)) {
      entry.photoUris.forEach((photoUri: string) => {
        if (typeof photoUri === 'string' && photoUri.length > 0) {
          parts.push(photoUri);
        }
      });
    }
    return this.textSignature(parts.join('|'));
  }

  private diaryCardKey(entry: DiaryEntry): string {
    const title: string = typeof entry.title === 'string' ? entry.title : '';
    const body: string = typeof entry.body === 'string' ? entry.body : '';
    const folderName: string = typeof entry.folderName === 'string' ? entry.folderName : '';
    const mood: string = typeof entry.mood === 'string' ? entry.mood : '';
    const weather: string = typeof entry.weather === 'string' ? entry.weather : '';
    const dateMs: number = typeof entry.dateMs === 'number' ? entry.dateMs : 0;
    const photoInBody: string = entry.photoInBody ? '1' : '0';
    return entry.id + '-' + dateMs.toString() + '-' + this.textSignature(title) + '-' +
      this.textSignature(body) + '-' + this.textSignature(folderName) + '-' +
      this.textSignature(mood) + '-' + this.textSignature(weather) + '-' +
      photoInBody + '-' + this.photoSignature(entry);
  }

  private visibleDiaries(): DiaryEntry[] {
    if (this.privacyMode) {
      const privateItems: DiaryEntry[] = this.privateDiaries();
      return this.privacyFavoritesOnly ? privateItems.filter((entry: DiaryEntry): boolean => entry.isFavorite) : privateItems;
    }
    const source: DiaryEntry[] = this.showSearch ?
      DiaryStatsUtils.filterDiaries(this.diaries, 'all', this.searchQuery) : this.favoriteDiaries();
    const tagFilter: string = this.effectiveTagFilter();
    if (!this.showTagFilter || tagFilter === '__all__') {
      return source;
    }
    return source.filter((entry: DiaryEntry): boolean => {
      const value: string = this.normalizedTag(typeof entry.folderName === 'string' ? entry.folderName : '');
      return value === tagFilter;
    });
  }

  private markSearchTouch(): void {
    this.searchActivatedByTouch = true;
    setTimeout((): void => {
      this.searchActivatedByTouch = false;
    }, 600);
  }

  private handleSearchEditChange(isEditing: boolean): void {
    if (!isEditing) {
      this.searchActivatedByTouch = false;
      return;
    }
    if (!this.searchActivatedByTouch) {
      this.searchController.stopEditing();
    }
  }

  @Builder
  private SearchPanel() {
    Column() {
      Search({ value: this.searchQuery, placeholder: '搜索笔记标题或正文内容...', controller: this.searchController })
        .width('100%')
        .height(50)
        .enableKeyboardOnFocus(false)
        .fontColor(this.textPrimary)
        .placeholderColor(this.textTertiary)
        .searchIcon({ color: this.textTertiary, size: 18 })
        .backgroundColor(this.inputBg)
        .border({ width: 1, color: this.lineColor, radius: 16 })
        .onChange((value: string) => {
          if (this.onSearchChange !== undefined) {
            this.onSearchChange(value);
          }
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.markSearchTouch();
          }
        })
        .onEditChange((isEditing: boolean) => {
          this.handleSearchEditChange(isEditing);
        })
        .margin({ bottom: 12 })

    }
    .width('100%')
    .padding({ left: 24, right: 24 })
    .margin({ bottom: 12 })
  }

  @Builder
  private TagStatusPanel() {
    Column() {
      Scroll() {
        ChipGroup({
          items: this.tagItems(),
          selectedIndexes: [this.selectedTagIndex()],
          multiple: false,
          itemStyle: {
            size: { width: 82, height: 34 },
            backgroundColor: this.cardBg,
            fontColor: this.textSecondary,
            selectedFontColor: '#FFFFFF',
            selectedBackgroundColor: this.accentColor
          },
          chipGroupSpace: {
            itemSpace: 6,
            startSpace: 0,
            endSpace: 0
          },
          chipGroupPadding: {
            top: 0,
            bottom: 0
          },
          onChange: (selectedIndexes: Array<number>) => {
            if (selectedIndexes.length === 0 || this.onTagFilterChange === undefined) {
              return;
            }
            this.onTagFilterChange(this.tagAt(selectedIndexes[0]));
          }
        })
          .width('100%')
          .constraintSize({ minWidth: this.tagGroupWidth() })
          .height(34)
      }
      .width('100%')
      .height(34)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding({ left: 24, right: 24 })
    .margin({ bottom: 14 })
  }

  @Builder
  private SwipeActions(entry: DiaryEntry) {
    Row() {
      if (this.privacyMode) {
        Button() {
          SymbolGlyph($r('sys.symbol.lock'))
            .fontSize(20)
            .fontColor([Color.White])
        }
        .width(44)
        .height(44)
        .backgroundColor(this.accentColor)
        .border({ radius: 22 })
        .stateEffect(false)
        .accessibilityText('移出隐私库')
        .onClick(() => {
          if (this.onMoveOutOfPrivacy !== undefined) {
            this.onMoveOutOfPrivacy(entry.id);
          }
        })
      } else {
        Button() {
          Image(this.effectiveFavorite(entry) ? $rawfile('icons/zap_tab_favorite_red_filled.svg') :
            $rawfile('icons/zap_tab_favorite.svg'))
            .width(19)
            .height(19)
            .objectFit(ImageFit.Contain)
        }
        .width(44)
        .height(44)
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: this.lineColor, radius: 22 })
        .stateEffect(false)
        .onClick(() => {
          const nextFavorite: boolean = !this.effectiveFavorite(entry);
          this.setFavoriteOverride(entry.id, nextFavorite);
          if (this.onToggleFavorite !== undefined) {
            this.onToggleFavorite(entry.id);
          }
        })
      }

      Button() {
        Image($r('sys.media.ohos_ic_public_edit'))
          .width(19)
          .height(19)
          .fillColor(Color.White)
      }
      .width(44)
      .height(44)
      .backgroundColor('#22C55E')
      .border({ radius: 22 })
      .stateEffect(false)
      .margin({ left: 12 })
      .onClick(() => {
        if (this.onEdit !== undefined) {
          this.onEdit(entry.id);
        }
      })

      Button() {
        Image($rawfile('icons/zap_editor_trash_dark.svg'))
          .width(18)
          .height(18)
          .objectFit(ImageFit.Contain)
      }
      .width(44)
      .height(44)
      .backgroundColor('#EF4444')
      .border({ radius: 22 })
      .stateEffect(false)
      .margin({ left: 12 })
      .onClick(() => {
        if (this.privacyMode && this.onPermanentDeleteRequest !== undefined) {
          this.onPermanentDeleteRequest(entry.id);
        } else if (this.onDeleteRequest !== undefined) {
          this.onDeleteRequest(entry.id);
        }
      })
    }
    .width(180)
    .height('100%')
    .padding({ right: 24 })
    .justifyContent(FlexAlign.End)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private DiaryCardItem(entry: DiaryEntry) {
    ListItem() {
      Column() {
        DiaryEntryCard({
          entry: entry,
          isDark: this.isDark,
          accentColor: this.accentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary,
          textTertiary: this.textTertiary
        })
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .margin({ bottom: 16 })
    .onClick(() => {
      if (this.onEdit !== undefined) {
        this.onEdit(entry.id);
      }
    })
    .swipeAction({
      end: {
        builder: () => {
          this.SwipeActions(entry)
        },
        actionAreaDistance: 180
      },
      edgeEffect: SwipeEdgeEffect.Spring
    })
  }

  build() {
    List({ scroller: this.scroller }) {
      if (this.showSearch) {
        ListItem() {
          this.SearchPanel()
        }
        .width('100%')
      }

      if (this.showTagFilter) {
        ListItem() {
          this.TagStatusPanel()
        }
        .width('100%')
      }

      if (this.visibleDiaries().length === 0) {
        ListItem() {
          Column() {
            EmptyStateCard({
              title: this.emptyTitle,
              subtitle: this.emptySubtitle,
              icon: this.emptyIcon,
              iconResource: this.emptyIconResource,
              iconColor: this.emptyIconColor,
              accentColor: this.accentColor,
              cardBg: this.cardBg,
              lineColor: this.lineColor,
              textPrimary: this.textPrimary,
              textTertiary: this.textTertiary
            })
          }
          .width('100%')
          .padding({ left: 24, right: 24 })
        }
        .width('100%')
      } else {
        ForEach(this.visibleDiaries(), (entry: DiaryEntry) => {
          this.DiaryCardItem(entry)
        }, (entry: DiaryEntry) => this.diaryCardKey(entry))
      }

      ListItem() {
        Column() {
          Blank()
            .height(this.bottomPadding)
        }
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .padding({
      top: this.topPadding
    })
  }
}
