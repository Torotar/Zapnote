import { getGuideRelatedTopics, getGuideTopic, GuideTopic } from '../model/GuideContent';

@Component
export struct GuideDetailSettingsPage {
  @Prop topicId: string = 'floating-enable';
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  onOpenTopic?: (topicId: string) => void;

  private topic(): GuideTopic {
    return getGuideTopic(this.topicId);
  }

  private openTopic(topicId: string): void {
    if (this.onOpenTopic !== undefined) {
      this.onOpenTopic(topicId);
    }
  }

  @Builder
  private TopicHeader() {
    Column() {
      Text(this.topic().question)
        .width('100%')
        .fontSize(22)
        .lineHeight(31)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)

      Text(this.topic().summary)
        .width('100%')
        .fontSize(14)
        .lineHeight(22)
        .fontColor(this.textSecondary)
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 2, right: 2, bottom: 24 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private StepRow(step: string, index: number) {
    Row() {
      Text((index + 1).toString())
        .width(28)
        .height(28)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.selectedAccentColor)
        .border({ radius: 8 })
        .margin({ right: 12 })

      Text(step)
        .layoutWeight(1)
        .fontSize(14)
        .lineHeight(22)
        .fontColor(this.textSecondary)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .margin({ bottom: 16 })
  }

  @Builder
  private MainContent() {
    Column() {
      Text(this.topic().contentTitle)
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .margin({ bottom: 17 })

      ForEach(this.topic().steps, (step: string, index: number) => {
        this.StepRow(step, index)
      }, (step: string, index: number) => this.topicId + '-step-' + index.toString())
    }
    .width('100%')
    .padding({ top: 20, left: 18, right: 18, bottom: 4 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 12 })
  }

  @Builder
  private TipBlock() {
    Column() {
      Text('请注意')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.selectedAccentColor)

      Text(this.topic().tip)
        .width('100%')
        .fontSize(13)
        .lineHeight(21)
        .fontColor(this.textSecondary)
        .margin({ top: 7 })
    }
    .width('100%')
    .padding({ top: 15, bottom: 15, left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.inputBg)
    .border({ width: 1, color: this.lineColor, radius: 12 })
    .margin({ top: 14 })
  }

  @Builder
  private RelatedRow(topic: GuideTopic, index: number, count: number) {
    Row() {
      Text(topic.question)
        .fontSize(14)
        .lineHeight(21)
        .fontColor(this.textPrimary)
        .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .width(24)
        .height(30)
        .fontSize(22)
        .fontColor([this.textTertiary])
        .margin({ left: 10 })
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 13, bottom: 13 })
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: index < count - 1 ? 1 : 0 }, color: this.lineColor })
    .onClick(() => {
      this.openTopic(topic.id);
    })
  }

  @Builder
  private RelatedTopics() {
    Column() {
      Text('相关问题')
        .width('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textSecondary)
        .padding({ left: 4 })
        .margin({ bottom: 9 })

      Column() {
        ForEach(getGuideRelatedTopics(this.topicId), (topic: GuideTopic, index: number) => {
          this.RelatedRow(topic, index, getGuideRelatedTopics(this.topicId).length)
        }, (topic: GuideTopic) => topic.id)
      }
      .width('100%')
      .backgroundColor(this.cardBg)
      .border({ width: 1, color: this.lineColor, radius: 12 })
    }
    .width('100%')
    .margin({ top: 26 })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      this.TopicHeader()
      this.MainContent()
      this.TipBlock()
      this.RelatedTopics()
    }
    .width('100%')
    .padding({ top: 4, bottom: 36 })
    .alignItems(HorizontalAlign.Start)
  }
}
