@Component
export struct OcrRecognitionLoadingOverlay {
  @Prop phase: string = 'recognizing';
  @Prop pageBg: string = '#F8FAFC';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop accentColor: string = '#6366F1';

  private title(): string {
    return this.phase === 'processing' ? '正在整理识别结果' : '正在识别内容';
  }

  private description(): string {
    return this.phase === 'processing' ? '正在准备需要确认的内容' : '正在读取图片中的文字';
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
      }
        .width('100%')
        .height('100%')
        .backgroundColor(this.pageBg)
        .opacity(0.8)

      Column({ space: 12 }) {
        LoadingProgress()
          .width(48)
          .height(48)
          .color(this.accentColor)

        Text(this.title())
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)
          .textAlign(TextAlign.Center)

        Text(this.description())
          .fontSize(14)
          .lineHeight(22)
          .fontColor(this.textSecondary)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Block)
    .accessibilityGroup(true)
    .accessibilityText(this.title() + '。' + this.description())
  }
}
