@Component
export struct WebdavSettingsPage {
  @Prop webdavUrl: string = '';
  @Prop webdavUser: string = '';
  @Prop webdavPass: string = '';
  @Prop webdavRemotePath: string = '/zapnote';
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  onBack?: () => void;
  onTestWebdav?: () => void;
  onSaveWebdav?: () => void;
  onWebdavInputChange?: (key: string, value: string) => void;

  private backupFilePath(): string {
    const trimmed: string = this.webdavRemotePath.trim();
    const path: string = trimmed.length === 0 ? '/zapnote' : (trimmed.startsWith('/') ? trimmed : '/' + trimmed);
    const normalized: string = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    return normalized + '/zapnote-backup.json';
  }

  @Builder
  private SectionTitle(title: string, subtitle: string) {
    Column() {
      Text(title)
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
      Text(subtitle)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(this.textTertiary)
        .margin({ top: 4 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  private InputField(label: string, placeholder: string, value: string, key: string) {
    Column() {
      Text(label)
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textSecondary)
        .margin({ bottom: 8 })
      TextInput({ placeholder: placeholder, text: value })
        .width('100%')
        .height(48)
        .fontSize(14)
        .fontColor(this.textPrimary)
        .placeholderColor(this.textTertiary)
        .backgroundColor(this.inputBg)
        .border({ width: 1, color: this.lineColor, radius: 14 })
        .padding({ left: 14, right: 14 })
        .type(key === 'pass' ? InputType.Password : InputType.Normal)
        .onChange((text: string) => {
          if (this.onWebdavInputChange !== undefined) {
            this.onWebdavInputChange(key, text);
          }
        })
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private HelpCard() {
    Column() {
      Text('连接说明')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
      Text('支持坚果云、Nextcloud、群晖等标准 WebDAV 服务。建议使用应用授权密码，不要填写网页登录密码。')
        .width('100%')
        .fontSize(12)
        .lineHeight(19)
        .fontColor(this.textSecondary)
        .margin({ top: 8 })
      Text('保存后将生成或读取：' + this.backupFilePath())
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(this.textTertiary)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(this.inputBg)
        .border({ radius: 12 })
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 16 })
  }

  build() {
    Column() {
      this.HelpCard()
      this.SectionTitle('账户配置', '服务器地址、账号和应用令牌用于直连你的个人云空间。')
      this.InputField('WebDAV 服务器地址', '例如 https://dav.example.com/dav/', this.webdavUrl, 'url')
      this.InputField('账号或邮箱', 'example@email.com', this.webdavUser, 'user')
      this.InputField('应用令牌或授权密码', '请输入 WebDAV 应用授权密码', this.webdavPass, 'pass')
      this.InputField('云端同步路径', '例如 /zapnote', this.webdavRemotePath, 'path')

      Row() {
        Button('验证连接')
          .layoutWeight(1)
          .height(46)
          .fontColor(this.selectedAccentColor)
          .backgroundColor(this.inputBg)
          .border({ radius: 14 })
          .onClick(() => {
            if (this.onTestWebdav !== undefined) {
              this.onTestWebdav();
            }
          })
        Button('保存配置')
          .layoutWeight(1)
          .height(46)
          .fontColor('#FFFFFF')
          .backgroundColor(this.selectedAccentColor)
          .border({ radius: 14 })
          .onClick(() => {
            if (this.onSaveWebdav !== undefined) {
              this.onSaveWebdav();
            }
          })
          .margin({ left: 10 })
      }
      .width('100%')
    }
    .width('100%')
  }
}
