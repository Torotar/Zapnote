export interface LegalDocumentClause {
  id: string;
  title: string;
  content: string;
}

@Component
export struct LegalDocumentLayout {
  @Prop documentTitle: string = '';
  @Prop documentVersion: string = 'V1.0';
  @Prop updateDate: string = '2026年7月13日';
  @Prop effectiveDate: string = '2026年7月13日';
  @Prop noticeTitle: string = '';
  @Prop noticeText: string = '';
  @Prop clauses: LegalDocumentClause[] = [];
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';

  @Builder
  private DocumentHeader() {
    Column() {
      Text(this.documentTitle)
        .width('100%')
        .fontSize(24)
        .lineHeight(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)

      Text('版本号：' + this.documentVersion)
        .fontSize(13)
        .fontColor(this.textSecondary)
        .margin({ top: 12 })

      Text('更新日期：' + this.updateDate)
        .fontSize(13)
        .fontColor(this.textSecondary)
        .margin({ top: 5 })

      Text('生效日期：' + this.effectiveDate)
        .fontSize(13)
        .fontColor(this.textSecondary)
        .margin({ top: 5 })
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 12 })
    .margin({ bottom: 14 })
  }

  @Builder
  private ReadNotice() {
    Column() {
      Text(this.noticeTitle)
        .width('100%')
        .fontSize(15)
        .lineHeight(22)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textPrimary)

      Text(this.noticeText)
        .width('100%')
        .fontSize(13)
        .lineHeight(21)
        .fontColor(this.textSecondary)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.inputBg)
    .border({ width: 1, color: this.lineColor, radius: 12 })
    .margin({ bottom: 18 })
  }

  @Builder
  private ClauseItem(clause: LegalDocumentClause) {
    Column() {
      Text(clause.id + '. ' + clause.title)
        .width('100%')
        .fontSize(16)
        .lineHeight(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)

      Text(clause.content)
        .width('100%')
        .fontSize(14)
        .lineHeight(24)
        .fontColor(this.textSecondary)
        .margin({ top: 9 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 22 })
  }

  build() {
    Column() {
      this.DocumentHeader()
      this.ReadNotice()
      ForEach(this.clauses, (clause: LegalDocumentClause) => {
        this.ClauseItem(clause)
      }, (clause: LegalDocumentClause) => clause.id)
    }
    .width('100%')
    .padding({ top: 0, left: 0, right: 0, bottom: 34 })
    .alignItems(HorizontalAlign.Start)
  }
}
