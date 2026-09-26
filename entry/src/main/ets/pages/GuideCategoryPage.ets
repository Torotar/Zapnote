import { getGuideSection, GuideSection, GuideTopic } from '../model/GuideContent';

@Component
export struct GuideCategoryPage {
  @Prop sectionId: string = 'record';
  @Prop cardBg: string = '#FFFFFF';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textTertiary: string = '#94A3B8';
  onOpenTopic?: (topicId: string) => void;

  private section(): GuideSection {
    return getGuideSection(this.sectionId);
  }

  private openTopic(topicId: string): void {
    if (this.onOpenTopic !== undefined) {
      this.onOpenTopic(topicId);
    }
  }

  @Builder
  private TopicRow(topic: GuideTopic) {
    Row() {
      Column() {
        Text(topic.question)
          .width('100%')
          .fontSize(15)
          .lineHeight(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(topic.summary)
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .width(24)
        .height(32)
        .fontSize(24)
        .fontColor([this.textTertiary])
        .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openTopic(topic.id);
    })
  }

  build() {
    Column() {
      ForEach(this.section().topics, (topic: GuideTopic, index: number) => {
        this.TopicRow(topic)
        if (index < this.section().topics.length - 1) {
          Divider()
            .color(this.lineColor)
            .margin({ left: 16 })
        }
      }, (topic: GuideTopic) => topic.id)
    }
    .width('100%')
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 12 })
    .margin({ top: 4, bottom: 36 })
  }
}
