import { DiaryEntryCard } from '../components/DiaryEntryCard';
import { RecycleBinEntry } from '../model/ZapNoteTypes';

@Component
export struct RecycleBinSettingsPage {
  @Prop items: RecycleBinEntry[] = [];
  @Prop isDark: boolean = false;
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  onRestore?: (id: string) => void;
  onDeletePermanentlyRequest?: (id: string) => void;

  private mutedTextColor(): string {
    return this.isDark ? this.textTertiary : '#64748B';
  }

  @Builder
  private SummaryCard() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Image(this.isDark ? $rawfile('icons/zap_editor_trash_dark.svg') : $rawfile('icons/zap_editor_trash.svg'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
      }
      .width(48)
      .height(48)
      .backgroundColor(this.inputBg)
      .border({ radius: 14 })
      .margin({ right: 14 })

      Column() {
        Text(this.items.length.toString() + ' 篇笔记')
          .width('100%')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text('回收站内容仅保存在本机，不参与统计和同步')
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(this.mutedTextColor())
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 12 })
  }

  @Builder
  private EmptyState() {
    Column() {
      Image(this.isDark ? $rawfile('icons/zap_editor_trash_dark.svg') : $rawfile('icons/zap_editor_trash.svg'))
        .width(42)
        .height(42)
        .objectFit(ImageFit.Contain)
        .opacity(0.48)
      Text('回收站是空的')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .margin({ top: 16 })
      Text('删除的笔记会显示在这里')
        .fontSize(13)
        .fontColor(this.mutedTextColor())
        .margin({ top: 6 })
    }
    .width('100%')
    .height(260)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private EntryCard(entry: RecycleBinEntry) {
    Column() {
      DiaryEntryCard({
        entry: entry.diary,
        isDark: this.isDark,
        accentColor: this.selectedAccentColor,
        cardBg: this.cardBg,
        inputBg: this.inputBg,
        lineColor: this.lineColor,
        textPrimary: this.textPrimary,
        textSecondary: this.textSecondary,
        textTertiary: this.textTertiary,
        showRecycleActions: true,
        onRestore: this.onRestore,
        onDeletePermanentlyRequest: this.onDeletePermanentlyRequest
      })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  build() {
    Column() {
      this.SummaryCard()
      if (this.items.length === 0) {
        this.EmptyState()
      } else {
        ForEach(this.items, (entry: RecycleBinEntry) => {
          this.EntryCard(entry)
        }, (entry: RecycleBinEntry) => entry.diary.id + '-' + entry.deletedAt.toString())
      }
    }
    .width('100%')
  }
}
