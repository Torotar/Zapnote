import { SegmentButton, SegmentButtonOptions, SymbolGlyphModifier } from '@kit.ArkUI';
import {
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  HdsNavigationMenuItemOptions,
  IconStyleMode
} from '@kit.UIDesignKit';
import { DiaryEntry } from '../model/ZapNoteTypes';
import { DiaryEntryCard } from '../components/DiaryEntryCard';
import { DiaryListTabContent } from '../components/DiaryListTabContent';
import { EmptyStateCard } from '../components/EmptyStateCard';
import { createHdsSubPageTitleBarOptions } from '../components/HdsSubPageTitleBarOptions';

const SELECTION_CARD_ESTIMATED_HEIGHT: number = 185;
const SELECTION_SHEET_FOOTER_HEIGHT: number = 80;
const SELECTION_LIST_BOTTOM_INSET: number = 92;

@Component
export struct PrivacyVaultPage {
  @Prop @Watch('handleDiariesChanged') diaries: DiaryEntry[] = [];
  @Prop materialEffectMode: number = 3;
  @Prop isDark: boolean = false;
  @Prop pageBg: string = '#F8FAFC';
  @Prop accentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  @Prop bottomPadding: number = 24;
  onBack?: () => void;
  onAddToPrivacy?: (ids: string[]) => void;
  onEdit?: (id: string) => void;
  onToggleFavorite?: (id: string) => void;
  onMoveOutOfPrivacy?: (id: string) => void;
  onPermanentDeleteRequest?: (id: string) => void;

  @State private favoritesOnly: boolean = false;
  @State private vaultSegmentSelectedIndexes: number[] = [0];
  @State private vaultSegmentOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [{ text: '全部' }, { text: '收藏' }],
    fontSize: 15,
    selectedFontSize: 15,
    fontWeight: FontWeight.Medium,
    selectedFontWeight: FontWeight.Bold,
    fontColor: '#94A3B8',
    selectedFontColor: Color.White,
    backgroundColor: '#F1F5F9',
    selectedBackgroundColor: '#6366F1'
  });
  @Link selectionSheetOpen: boolean;
  @State private selectedIds: string[] = [];
  @State private selectionSheetDetent: SheetSize = SheetSize.MEDIUM;
  @State private selectionListViewportHeight: number = 0;
  private selectionAutoDetentResolvedKey: string = '';
  private listScroller: Scroller = new Scroller();
  private selectionScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.refreshVaultSegmentOptions();
    this.syncVaultSegmentSelection();
  }

  private refreshVaultSegmentOptions(): void {
    this.vaultSegmentOptions = SegmentButtonOptions.tab({
      buttons: [{ text: '全部' }, { text: '收藏' }],
      fontSize: 15,
      selectedFontSize: 15,
      fontWeight: FontWeight.Medium,
      selectedFontWeight: FontWeight.Bold,
      fontColor: this.textTertiary,
      selectedFontColor: Color.White,
      backgroundColor: this.inputBg,
      selectedBackgroundColor: this.accentColor
    });
  }

  private syncVaultSegmentSelection(): void {
    this.vaultSegmentSelectedIndexes = [this.favoritesOnly ? 1 : 0];
  }

  private changeVaultSegment(index: number): void {
    if (index < 0 || index > 1) {
      return;
    }
    this.favoritesOnly = index === 1;
    this.vaultSegmentSelectedIndexes = [index];
  }

  private selectableDiaries(): DiaryEntry[] {
    return this.diaries.filter((entry: DiaryEntry): boolean => entry.isPrivate !== true);
  }

  private isSelected(id: string): boolean {
    return this.selectedIds.indexOf(id) >= 0;
  }

  private toggleSelected(id: string): void {
    if (this.isSelected(id)) {
      this.selectedIds = this.selectedIds.filter((item: string): boolean => item !== id);
      return;
    }
    this.selectedIds = [...this.selectedIds, id];
  }

  private closeSelectionSheet(): void {
    this.selectionSheetOpen = false;
    this.selectedIds = [];
    this.selectionSheetDetent = SheetSize.MEDIUM;
    this.selectionListViewportHeight = 0;
    this.selectionAutoDetentResolvedKey = '';
  }

  private confirmSelection(): void {
    if (this.selectedIds.length === 0) {
      return;
    }
    const ids: string[] = [...this.selectedIds];
    this.closeSelectionSheet();
    if (this.onAddToPrivacy !== undefined) {
      this.onAddToPrivacy(ids);
    }
  }

  private openSelectionSheet(): void {
    this.selectedIds = [];
    this.selectionSheetDetent = SheetSize.MEDIUM;
    this.selectionListViewportHeight = 0;
    this.selectionAutoDetentResolvedKey = '';
    this.selectionSheetOpen = true;
  }

  private titleBarMenuItems(): Array<HdsNavigationMenuItemOptions> {
    return [{
      content: {
        icon: new SymbolGlyphModifier($r('sys.symbol.plus')).fontSize(24)
          .fontColor([this.isDark ? '#F8FAFC' : '#1A1A2E']),
        label: '\u52a0\u5165\u9690\u79c1\u5e93',
        isEnabled: true,
        type: IconStyleMode.NORMAL,
        action: (): void => this.openSelectionSheet()
      }
    }];
  }

  private areaLengthToNumber(value: Length | undefined): number {
    if (value === undefined) {
      return 0;
    }
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      const result: number = Number.parseFloat(value);
      return Number.isNaN(result) ? 0 : result;
    }
    return 0;
  }

  private selectionListContentHeight(): number {
    const itemCount: number = this.selectableDiaries().length;
    if (itemCount === 0) {
      return 180;
    }
    return itemCount * SELECTION_CARD_ESTIMATED_HEIGHT + 12;
  }

  private selectableDiariesKey(): string {
    return this.selectableDiaries().map((entry: DiaryEntry): string => entry.id).join('|');
  }

  private handleDiariesChanged(): void {
    if (!this.selectionSheetOpen) {
      return;
    }
    const nextKey: string = this.selectableDiariesKey();
    if (nextKey === this.selectionAutoDetentResolvedKey) {
      return;
    }
    this.selectionAutoDetentResolvedKey = '';
    this.updateSelectionSheetDetent();
  }

  private updateSelectionSheetDetent(): void {
    if (!this.selectionSheetOpen || this.selectionListViewportHeight <= 0) {
      return;
    }
    const contentKey: string = this.selectableDiariesKey();
    if (this.selectionAutoDetentResolvedKey === contentKey) {
      return;
    }
    this.selectionSheetDetent = this.selectionListContentHeight() > this.selectionListViewportHeight ?
      SheetSize.LARGE : SheetSize.MEDIUM;
    this.selectionAutoDetentResolvedKey = contentKey;
  }

  @Builder
  private VaultTabs() {
    Column() {
      SegmentButton({
        options: this.vaultSegmentOptions,
        selectedIndexes: $vaultSegmentSelectedIndexes,
        onItemClicked: (index: number): void => this.changeVaultSegment(index)
      })
        .width('100%')
        .borderRadius(18)
        .border({ width: 1, color: this.lineColor })
        .shadow({ radius: 10, color: '#08000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .padding({ left: 24, right: 24 })
    .margin({ bottom: 16 })
  }

  @Builder
  private SelectionCard(entry: DiaryEntry) {
    Stack({ alignContent: Alignment.TopEnd }) {
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

      Stack({ alignContent: Alignment.Center }) {
        if (this.isSelected(entry.id)) {
          SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(16)
          .fontColor([Color.White])
        }
      }
      .width(30)
      .height(30)
      .backgroundColor(this.isSelected(entry.id) ? this.accentColor : this.cardBg)
      .border({ width: 1, color: this.isSelected(entry.id) ? this.accentColor : this.lineColor, radius: 15 })
      .shadow({ radius: 8, color: this.isDark ? '#55000000' : '#220F172A', offsetX: 0, offsetY: 3 })
      .margin({ top: 12, right: 12 })
    }
    .width('100%')
    .accessibilityText((this.isSelected(entry.id) ? '取消选择' : '选择') +
      (entry.title.trim().length > 0 ? entry.title : '无标题笔记'))
    .onClick((): void => this.toggleSelected(entry.id))
  }

  @Builder
  private SelectionSheet() {
    Stack({ alignContent: Alignment.Bottom }) {
      List({ scroller: this.selectionScroller }) {
        if (this.selectableDiaries().length === 0) {
          ListItem() {
            EmptyStateCard({
              title: '\u6ca1\u6709\u53ef\u52a0\u5165\u7684\u7b14\u8bb0',
              subtitle: '\u5f53\u524d\u6240\u6709\u7b14\u8bb0\u90fd\u5df2\u5728\u9690\u79c1\u5e93\u4e2d',
              icon: '',
              accentColor: this.accentColor,
              cardBg: this.cardBg,
              lineColor: this.lineColor,
              textPrimary: this.textPrimary,
              textTertiary: this.textTertiary
            })
          }
          .width('100%')
        } else {
          ForEach(this.selectableDiaries(), (entry: DiaryEntry) => {
            ListItem() {
              this.SelectionCard(entry)
            }
            .width('100%')
            .margin({ bottom: 12 })
          }, (entry: DiaryEntry): string => 'privacy-select-' + entry.id)
        }
        ListItem() {
          Column() {
            Blank().height(20)
          }
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: SELECTION_LIST_BOTTOM_INSET })
      .scrollBar(BarState.Off)
      .onAreaChange((_oldValue: Area, newValue: Area): void => {
        const fullHeight: number = this.areaLengthToNumber(newValue.height);
        this.selectionListViewportHeight = Math.max(0, fullHeight - SELECTION_LIST_BOTTOM_INSET);
        this.updateSelectionSheetDetent();
      })

      Column() {
        Divider()
          .width('100%')
          .height(1)
          .color(this.lineColor)

        Button('加入隐私库', { type: ButtonType.Normal, stateEffect: true })
          .width('100%')
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.selectedIds.length > 0 ? Color.White : this.textTertiary)
          .backgroundColor(this.selectedIds.length > 0 ? this.accentColor : this.inputBg)
          .border({ width: 1, color: this.selectedIds.length > 0 ? this.accentColor : this.lineColor, radius: 14 })
          .enabled(this.selectedIds.length > 0)
          .accessibilityText('确认加入隐私库')
          .onClick((): void => this.confirmSelection())
      }
      .width('100%')
      .height(SELECTION_SHEET_FOOTER_HEIGHT)
      .padding({ left: 20, right: 20, top: 10, bottom: 16 })
      .backgroundColor(this.cardBg)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.cardBg)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      HdsNavDestination() {
      Column() {
        this.VaultTabs()
        DiaryListTabContent({
          diaries: this.diaries,
          showSearch: false,
          showTagFilter: false,
          privacyMode: true,
          privacyFavoritesOnly: this.favoritesOnly,
          topPadding: 0,
          bottomPadding: this.bottomPadding,
          isDark: this.isDark,
          accentColor: this.accentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary,
          textTertiary: this.textTertiary,
          scroller: this.listScroller,
          onEdit: (id: string): void => {
            if (this.onEdit !== undefined) {
              this.onEdit(id);
            }
          },
          onToggleFavorite: (id: string): void => {
            if (this.onToggleFavorite !== undefined) {
              this.onToggleFavorite(id);
            }
          },
          onMoveOutOfPrivacy: (id: string): void => {
            if (this.onMoveOutOfPrivacy !== undefined) {
              this.onMoveOutOfPrivacy(id);
            }
          },
          onPermanentDeleteRequest: (id: string): void => {
            if (this.onPermanentDeleteRequest !== undefined) {
              this.onPermanentDeleteRequest(id);
            }
          }
        })
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ top: 8 })
      }
      .width('100%')
      .height('100%')
      .titleBar(createHdsSubPageTitleBarOptions('\u9690\u79c1\u5e93', this.isDark, this.materialEffectMode,
        (): void => {
          if (this.onBack !== undefined) {
            this.onBack();
          }
        }, this.titleBarMenuItems()))
      .titleMode(HdsNavDestinationTitleMode.MINI)
      .hideBackButton(false)
      .onBackPressed((): boolean => {
        if (this.selectionSheetOpen) {
          this.closeSelectionSheet();
          return true;
        }
        if (this.onBack !== undefined) {
          this.onBack();
        }
        return true;
      })
      .backgroundColor(this.pageBg)
    }
    .width('100%')
    .height('100%')
    .bindSheet(this.selectionSheetOpen, this.SelectionSheet(), {
      height: SheetSize.MEDIUM,
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      detentSelection: this.selectionSheetDetent,
      dragBar: true,
      showClose: true,
      title: {
        title: '选择笔记',
        subtitle: this.selectedIds.length > 0 ? '已选 ' + this.selectedIds.length.toString() + ' 篇' :
          '选择后加入隐私库'
      },
      backgroundColor: this.cardBg,
      maskColor: '#66000000',
      scrollSizeMode: ScrollSizeMode.CONTINUOUS,
      onDisappear: (): void => this.closeSelectionSheet()
    })
  }
}
