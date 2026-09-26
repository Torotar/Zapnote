@Component
export struct DataSettingsPage {
  @Prop diaryCount: number = 0;
  @Prop favoriteCount: number = 0;
  @Prop totalWords: number = 0;
  @Prop remoteBackupPath: string = '/zapnote/zapnote-backup.json';
  @Prop backupPreview: string = '';
  @Prop isDark: boolean = false;
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  onBack?: () => void;
  onExportBackup?: () => void;
  onExportDiagnosticLog?: () => void;
  onImportBackupRequest?: () => void;
  onClearDataRequest?: () => void;

  private previewText(): string {
    if (this.backupPreview.trim().length === 0) {
      return '导出或导入后，这里会显示备份文件、备份时间和处理结果。';
    }
    return this.backupPreview;
  }

  private dangerTitleColor(): string {
    return this.isDark ? '#FCA5A5' : '#EF4444';
  }

  private dangerTextColor(): string {
    return this.isDark ? '#FECACA' : '#B91C1C';
  }

  private dangerBgColor(): string {
    return this.isDark ? '#3F151D' : '#FFF1F2';
  }

  private dangerLineColor(): string {
    return this.isDark ? '#7F1D1D' : '#FECACA';
  }

  private backupIcon(): Resource {
    return this.isDark ? $rawfile('icons/reset_data_dark.svg') : $rawfile('icons/reset_data_light.svg');
  }

  private importIcon(): Resource {
    return this.isDark ? $rawfile('icons/book_dark.svg') : $rawfile('icons/book_light.svg');
  }

  private clearCacheIcon(): Resource {
    return this.isDark ? $rawfile('icons/clear_cache_dark.svg') : $rawfile('icons/clear_cache_light.svg');
  }

  @Builder
  private Metric(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(label)
        .fontSize(11)
        .fontColor(this.textTertiary)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private StatusCard() {
    Column() {
      Column() {
        Text('备份状态')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text('本地导出与云端恢复共用含照片的 ZIP 备份')
          .fontSize(12)
          .fontColor(this.textTertiary)
          .lineHeight(18)
          .margin({ top: 5 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row() {
        this.Metric('笔记', this.diaryCount.toString() + ' 篇')
        this.Metric('字数', this.totalWords.toString())
        this.Metric('收藏', this.favoriteCount.toString() + ' 篇')
      }
      .width('100%')
      .margin({ top: 18 })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 14 })
  }

  @Builder
  private CompactActionCard(title: string, caption: string, actionText: string, isPrimary: boolean,
    iconResource: Resource | null = null, onTap?: () => void) {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          if (iconResource !== null) {
            Image(iconResource)
              .width(17)
              .height(17)
              .objectFit(ImageFit.Contain)
          }
        }
        .width(32)
        .height(32)
        .backgroundColor(this.inputBg)
        .border({ radius: 12 })

        Text(actionText)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(isPrimary ? this.selectedAccentColor : this.textSecondary)
          .textAlign(TextAlign.End)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(title)
        .width('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .margin({ top: 8 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(caption)
        .width('100%')
        .fontSize(11)
        .fontColor(this.textTertiary)
        .margin({ top: 2 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(94)
    .layoutWeight(1)
    .padding(10)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 16 })
    .onClick(() => {
      if (onTap !== undefined) {
        onTap();
      }
    })
  }

  @Builder
  private ActionGrid() {
    Row({ space: 10 }) {
      this.CompactActionCard('导出备份文件', '含照片的 ZIP 文件', '导出', true, this.backupIcon(), () => {
        if (this.onExportBackup !== undefined) {
          this.onExportBackup();
        }
      })
      this.CompactActionCard('导入备份文件', '选择 ZIP 或旧 JSON', '导入', false, this.importIcon(), () => {
        if (this.onImportBackupRequest !== undefined) {
          this.onImportBackupRequest();
        }
      })
    }
    .width('100%')
    .margin({ bottom: 12 })

    Row() {
      this.CompactActionCard('导出诊断日志', '不包含笔记内容、图片或账号密码', '保存日志', false, this.importIcon(), () => {
        if (this.onExportDiagnosticLog !== undefined) {
          this.onExportDiagnosticLog();
        }
      })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  private DangerZone() {
    Column() {
      Text('危险操作')
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.dangerTitleColor())
        .margin({ bottom: 8 })
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Image(this.clearCacheIcon())
            .width(19)
            .height(19)
            .objectFit(ImageFit.Contain)
        }
        .width(34)
        .height(34)
        .backgroundColor(this.dangerBgColor())
        .border({ width: 1, color: this.dangerLineColor(), radius: 12 })
        .margin({ right: 12 })

        Column() {
          Text('清空全部笔记')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.dangerTitleColor())
          Text('将当前本地笔记移至回收站。操作前建议先导出备份文件。')
            .fontSize(12)
            .lineHeight(16)
            .fontColor(this.dangerTextColor())
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('清空')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.dangerTitleColor())
      }
      .width('100%')
      .height(68)
      .padding({ left: 12, right: 12 })
      .backgroundColor(this.dangerBgColor())
      .border({ width: 1, color: this.dangerLineColor(), radius: 16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        if (this.onClearDataRequest !== undefined) {
          this.onClearDataRequest();
        }
      })
    }
    .width('100%')
    .margin({ top: 6 })
  }

  @Builder
  private BackupRecordCard() {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Image(this.backupIcon())
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
        }
        .width(36)
        .height(36)
        .backgroundColor(this.inputBg)
        .border({ radius: 12 })
        .margin({ right: 12 })

        Column() {
          Text('备份记录')
            .width('100%')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary)
          Text('最近一次导出或导入后的处理结果')
            .width('100%')
            .fontSize(12)
            .lineHeight(18)
            .fontColor(this.textSecondary)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Text(this.previewText())
        .width('100%')
        .fontSize(12)
        .lineHeight(20)
        .fontColor(this.backupPreview.trim().length === 0 ? this.textTertiary : this.textSecondary)
      Text('云端同步文件：' + this.remoteBackupPath)
        .width('100%')
        .fontSize(11)
        .lineHeight(17)
        .fontColor(this.textTertiary)
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ top: 12 })
  }

  build() {
    Column() {
      this.StatusCard()

      this.ActionGrid()
      this.DangerZone()
      this.BackupRecordCard()
    }
    .width('100%')
  }
}
