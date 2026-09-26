@Component
export struct ZapStatCard {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop unit: string = '';
  @Prop icon: string = '';
  @Prop iconResource: Resource | null = null;
  @Prop darkIconResource: Resource | null = null;
  @Prop accentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textTertiary: string = '#94A3B8';
  @Prop isDark: boolean = false;

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(12)
          .fontColor(this.textTertiary)
          .layoutWeight(1)
        if (this.iconResource !== null) {
          if (this.isDark && this.darkIconResource !== null) {
            Image(this.darkIconResource)
              .width(20)
              .height(20)
              .objectFit(ImageFit.Contain)
          } else {
            Image(this.iconResource)
              .width(20)
              .height(20)
              .objectFit(ImageFit.Contain)
          }
        } else {
          Text(this.icon)
            .fontSize(18)
            .fontColor(this.isDark ? Color.White : this.accentColor)
        }
      }
      .width('100%')
      .margin({ bottom: 10 })
      Row() {
        Text(this.value)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text(this.unit)
          .fontSize(12)
          .fontColor(this.textTertiary)
          .margin({ left: 4, top: 10 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
  }
}
