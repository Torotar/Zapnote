import { SettingPanel } from '../model/ZapNoteTypes';

@Component
export struct SettingNavItem {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop icon: string = '';
  @Prop iconResource: Resource | null = null;
  @Prop darkIconResource: Resource | null = null;
  @Prop panel: SettingPanel = 'main';
  @Prop accentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textTertiary: string = '#94A3B8';
  @Prop isDark: boolean = false;
  onSelect?: (panel: SettingPanel) => void;

  build() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
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
        .width(38)
        .height(38)
        .backgroundColor(this.inputBg)
        .border({ radius: 14 })
        .margin({ right: 12 })
      Column() {
        Text(this.title)
          .width('100%')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text(this.subtitle)
          .width('100%')
          .fontSize(12)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontColor([this.textTertiary])
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 12 })
    .onClick(() => {
      if (this.onSelect !== undefined) {
        this.onSelect(this.panel);
      }
    })
  }
}
