@Component
export struct AboutSettingsPage {
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  @Prop textPrimary: string = '#0F172A';
  onOpenLegal?: (documentType: string) => void;

  @Builder
  private AppIdentity() {
    Column() {
      Image($r('app.media.app_icon_v2'))
        .width(88)
        .height(88)
        .border({ radius: 22 })
        .shadow({ radius: 12, color: '#18000000', offsetX: 0, offsetY: 4 })

      Text('识录笔记')
        .fontSize(27)
        .lineHeight(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .margin({ top: 16 })

      Text('记录当下，也珍藏每一天')
        .fontSize(14)
        .lineHeight(22)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.selectedAccentColor)
        .margin({ top: 10 })
    }
    .width('100%')
    .padding({ top: 18, bottom: 30 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private SectionLabel(title: string) {
    Text(title)
      .width('100%')
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.textSecondary)
      .margin({ left: 4, bottom: 9 })
  }

  @Builder
  private InfoRow(title: string, value: string) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor(this.textPrimary)
        .layoutWeight(1)

      Text(value)
        .fontSize(14)
        .fontColor(this.textTertiary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private AppInfoGroup() {
    Column() {
      this.InfoRow('当前版本', '1.4.0')
      Divider()
        .color(this.lineColor)
        .margin({ left: 16 })
      this.InfoRow('构建类型', '稳定版')
      Divider()
        .color(this.lineColor)
        .margin({ left: 16 })
      this.InfoRow('数据存储', '本地优先')
      Divider()
        .color(this.lineColor)
        .margin({ left: 16 })
      this.InfoRow('云端同步', '可选 WebDAV')
    }
    .width('100%')
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 12 })
    .margin({ bottom: 22 })
  }

  @Builder
  private LegalRow(title: string, documentType: string) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor(this.textPrimary)
        .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([this.textTertiary])
        .margin({ left: 12 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 14 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (this.onOpenLegal !== undefined) {
        this.onOpenLegal(documentType);
      }
    })
  }

  @Builder
  private LegalGroup() {
    Column() {
      this.LegalRow('用户协议', 'agreement')
      Divider()
        .color(this.lineColor)
        .margin({ left: 16 })
      this.LegalRow('隐私声明', 'privacy')
    }
    .width('100%')
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 12 })
    .margin({ bottom: 22 })
  }

  @Builder
  private OpenSourceGroup() {
    Column() {
      Text('第三方开源许可')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textPrimary)

      Text('本应用部分图标来自 Lucide Icons，遵循 ISC License；部分由 Feather 项目衍生的图标遵循 MIT License。相关版权归原作者所有。')
        .width('100%')
        .fontSize(13)
        .lineHeight(21)
        .fontColor(this.textSecondary)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 12 })
    .margin({ bottom: 28 })
  }

  build() {
    Column() {
      this.AppIdentity()

      this.SectionLabel('应用信息')
      this.AppInfoGroup()

      this.SectionLabel('法律与隐私')
      this.LegalGroup()

      this.SectionLabel('开源信息')
      this.OpenSourceGroup()

      Text('Copyright © 2026 识录笔记')
        .width('100%')
        .fontSize(12)
        .lineHeight(19)
        .fontColor(this.textTertiary)
        .textAlign(TextAlign.Center)

      Text('保留所有权利')
        .width('100%')
        .fontSize(12)
        .lineHeight(19)
        .fontColor(this.textTertiary)
        .textAlign(TextAlign.Center)
        .margin({ top: 2, bottom: 22 })
    }
    .width('100%')
    .padding({ top: 0, left: 0, right: 0, bottom: 34 })
    .alignItems(HorizontalAlign.Start)
  }
}
