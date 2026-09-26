@Component
export struct EmptyStateCard {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop icon: string = '';
  @Prop iconResource: Resource | null = null;
  @Prop iconColor: string = '';
  @Prop accentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textTertiary: string = '#94A3B8';

  build() {
    Column() {
      if (this.iconResource !== null) {
        Image(this.iconResource)
          .width(34)
          .height(34)
          .objectFit(ImageFit.Contain)
          .fillColor(this.iconColor.length > 0 ? this.iconColor : this.accentColor)
          .margin({ bottom: 12 })
      } else {
        Text(this.icon)
          .fontSize(34)
          .fontColor(this.iconColor.length > 0 ? this.iconColor : this.accentColor)
          .margin({ bottom: 12 })
      }
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .textAlign(TextAlign.Center)
      Text(this.subtitle)
        .fontSize(13)
        .lineHeight(20)
        .fontColor(this.textTertiary)
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(24)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 20 })
  }
}
