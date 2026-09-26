import { SettingNavItem } from '../components/SettingNavItem';
import { HuaweiAccountInfo, SettingPanel } from '../model/ZapNoteTypes';
import { ZapNoteHuaweiAccountService } from '../services/ZapNoteHuaweiAccountService';

@Component
export struct SettingsMainPage {
  @Prop diaryCount: number = 0;
  @Prop favoriteCount: number = 0;
  @Prop totalWords: number = 0;
  @Prop recycleBinCount: number = 0;
  @Prop isDark: boolean = false;
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  @Prop privacyEnabled: boolean = true;
  @Prop huaweiAccountOpenId: string = '';
  @Prop huaweiAccountInfo: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
  onPanelChange?: (panel: SettingPanel) => void;
  onToggleChange?: (key: string, isOn: boolean) => void;
  onOpenPrivacyVault?: () => void;

  private noteLongPressTimer: number = -1;

  private changePanel(panel: SettingPanel): void {
    if (this.onPanelChange !== undefined) {
      this.onPanelChange(panel);
    }
  }

  private maskOpenId(openId: string): string {
    if (openId.length <= 8) {
      return openId;
    }
    return openId.substring(0, 4) + '...' + openId.substring(openId.length - 4);
  }

  private accountInfo(): HuaweiAccountInfo {
    return ZapNoteHuaweiAccountService.normalizeInfo(this.huaweiAccountInfo);
  }

  private effectiveOpenId(): string {
    const openId: string = this.accountInfo().openId;
    return openId.length > 0 ? openId : this.huaweiAccountOpenId.trim();
  }

  private hasHuaweiAccount(): boolean {
    const info: HuaweiAccountInfo = this.accountInfo();
    return info.openId.length > 0 || info.unionId.length > 0 || this.huaweiAccountOpenId.trim().length > 0;
  }

  private huaweiAccountTitle(): string {
    const nickName: string = this.accountInfo().nickName;
    if (nickName.length > 0) {
      return nickName;
    }
    return this.hasHuaweiAccount() ? '华为账号用户' : '登录 / 注册';
  }

  private huaweiAccountSubtitle(): string {
    const info: HuaweiAccountInfo = this.accountInfo();
    if (this.hasHuaweiAccount()) {
      if (info.loginStateText.length > 0 && info.loginState !== 'unknown') {
        return info.loginStateText;
      }
      return 'OpenID ' + this.maskOpenId(this.effectiveOpenId());
    }
    return '使用华为账号授权登录';
  }

  private hasHuaweiAvatar(): boolean {
    return this.accountInfo().avatarUri.length > 0;
  }

  private appearanceIcon(): Resource {
    return $rawfile('icons/material_effect_light.svg');
  }

  private appearanceDarkIcon(): Resource {
    return $rawfile('icons/material_effect_dark.svg');
  }

  private autofillIcon(): Resource {
    return $rawfile('icons/ai_config_light.svg');
  }

  private autofillDarkIcon(): Resource {
    return $rawfile('icons/ai_config_dark.svg');
  }

  private syncIcon(): Resource {
    return $rawfile('icons/webdav_light.svg');
  }

  private syncDarkIcon(): Resource {
    return $rawfile('icons/webdav_dark.svg');
  }

  private privacyIcon(): Resource {
    return $rawfile('icons/display_mode_light.svg');
  }

  private privacyDarkIcon(): Resource {
    return $rawfile('icons/display_mode_dark.svg');
  }

  private dataIcon(): Resource {
    return $rawfile('icons/reset_data_light.svg');
  }

  private dataDarkIcon(): Resource {
    return $rawfile('icons/reset_data_dark.svg');
  }

  private recycleBinIcon(): Resource {
    return $rawfile('icons/zap_editor_trash.svg');
  }

  private recycleBinDarkIcon(): Resource {
    return $rawfile('icons/zap_editor_trash_dark.svg');
  }

  private guideIcon(): Resource {
    return $rawfile('icons/book_light.svg');
  }

  private guideDarkIcon(): Resource {
    return $rawfile('icons/book_dark.svg');
  }

  private aboutIcon(): Resource {
    return $rawfile('icons/info.svg');
  }

  private aboutDarkIcon(): Resource {
    return $rawfile('icons/info_dark.svg');
  }

  private agreementIcon(): Resource {
    return $rawfile('icons/book_open.svg');
  }

  private agreementDarkIcon(): Resource {
    return $rawfile('icons/book_open_dark.svg');
  }

  private statementIcon(): Resource {
    return $rawfile('icons/info.svg');
  }

  private statementDarkIcon(): Resource {
    return $rawfile('icons/info_dark.svg');
  }

  @Builder
  private ProfileStat(value: string, label: string, onLongPress?: () => void) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
      Text(label)
        .fontSize(11)
        .fontColor(this.textTertiary)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .onTouch((event: TouchEvent) => {
      const targetAction: (() => void) | undefined = onLongPress !== undefined ? onLongPress :
        label === '\u7b14\u8bb0' ? this.onOpenPrivacyVault : undefined;
      if (targetAction === undefined) {
        return;
      }
      if (event.type === TouchType.Down) {
        if (this.noteLongPressTimer >= 0) {
          clearTimeout(this.noteLongPressTimer);
        }
        this.noteLongPressTimer = setTimeout((): void => {
          this.noteLongPressTimer = -1;
          targetAction();
        }, 600);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        if (this.noteLongPressTimer >= 0) {
          clearTimeout(this.noteLongPressTimer);
          this.noteLongPressTimer = -1;
        }
      }
    })
  }

  @Builder
  private HuaweiAccountSection() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        if (this.hasHuaweiAvatar()) {
          Image(this.accountInfo().avatarUri)
            .width(58)
            .height(58)
            .objectFit(ImageFit.Cover)
            .border({ radius: 29 })
        } else if (this.hasHuaweiAccount()) {
          Text('华')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
        } else {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(30)
            .fontColor([this.isDark ? '#F8FAFC' : '#1F1F1F'])
        }
      }
      .width(58)
      .height(58)
      .backgroundColor(this.hasHuaweiAccount() ? this.selectedAccentColor : this.cardBg)
      .border({ width: 1, color: this.lineColor, radius: 29 })
      .margin({ right: 16 })

      Column() {
        Text(this.huaweiAccountTitle())
          .width('100%')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.huaweiAccountSubtitle())
          .width('100%')
          .fontSize(14)
          .fontColor(this.textSecondary)
          .margin({ top: 7 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)

      Image(this.isDark ? $rawfile('icons/back_dark.svg') : $rawfile('icons/back_light.svg'))
        .width(18)
        .height(18)
        .objectFit(ImageFit.Contain)
        .opacity(this.hasHuaweiAccount() ? 0.54 : 1)
        .scale({ x: -1, y: 1 })
    }
    .width('100%')
    .height(98)
    .padding({ left: 24, right: 20 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 22 })
    .margin({ bottom: 16 })
    .onClick(() => {
      this.changePanel('huaweiAccountLogin');
    })
  }

  @Builder
  private ProfileCard() {
    Column() {
      Text('识录笔记')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.selectedAccentColor)
        .margin({ bottom: 6 })
      Text('极简笔记 · 本地优先 · 数据私有')
        .fontSize(13)
        .fontColor(this.textSecondary)
        .margin({ bottom: 16 })
      Row() {
        this.ProfileStat(this.diaryCount.toString(), '笔记')
        this.ProfileStat(this.favoriteCount.toString(), '收藏')
        this.ProfileStat(this.totalWords.toString(), '字数')
      }
      .width('100%')
    }
    .width('100%')
    .padding(22)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 22 })
    .margin({ bottom: 16 })
  }

  @Builder
  private NavRow(title: string, subtitle: string, icon: string, panel: SettingPanel, iconResource: Resource | null = null,
    darkIconResource: Resource | null = null) {
    SettingNavItem({
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconResource: iconResource,
      darkIconResource: darkIconResource,
      panel: panel,
      accentColor: this.selectedAccentColor,
      cardBg: this.cardBg,
      inputBg: this.inputBg,
      lineColor: this.lineColor,
      textPrimary: this.textPrimary,
      textTertiary: this.textTertiary,
      isDark: this.isDark,
      onSelect: (targetPanel: SettingPanel) => {
        this.changePanel(targetPanel);
      }
    })
  }

  @Builder
  private PrivacyToggleRow() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Image(this.isDark ? this.privacyDarkIcon() : this.privacyIcon())
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
      }
      .width(38)
      .height(38)
      .backgroundColor(this.inputBg)
      .border({ radius: 14 })
      .margin({ right: 12 })

      Column() {
        Text('防窥屏保护')
          .width('100%')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text('检测到他人注视屏幕时，进行弹窗提醒')
          .width('100%')
          .fontSize(12)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ right: 20 })
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.privacyEnabled })
        .selectedColor(this.selectedAccentColor)
        .margin({ left: 8 })
        .onChange((isOn: boolean) => {
          if (this.onToggleChange !== undefined) {
            this.onToggleChange('privacy', isOn);
          }
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 12 })
  }

  @Builder
  private SectionTitle(title: string) {
    Text(title)
      .width('100%')
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.textTertiary)
      .margin({ top: 4, bottom: 8, left: 4 })
  }

  build() {
    Column() {
      this.HuaweiAccountSection()
      this.ProfileCard()

      this.SectionTitle('记录体验')
      this.NavRow('外观定制', '主题、智感握持和沉浸光感', '◐', 'appearance', this.appearanceIcon(), this.appearanceDarkIcon())
      this.NavRow('智能填写', '照片识别和草稿生成偏好', '✦', 'autofill', this.autofillIcon(), this.autofillDarkIcon())

      this.SectionTitle('同步与数据')
      this.NavRow('WebDAV 同步', '账号配置、拉取和推送', '☁', 'sync', this.syncIcon(), this.syncDarkIcon())
      this.NavRow('数据管理', '备份、导入和清空', '▣', 'data', this.dataIcon(), this.dataDarkIcon())
      this.NavRow('回收站', this.recycleBinCount > 0 ? this.recycleBinCount.toString() + ' 篇笔记待处理' : '恢复或永久删除笔记', '',
        'recycleBin', this.recycleBinIcon(), this.recycleBinDarkIcon())

      this.SectionTitle('安全与支持')
      this.PrivacyToggleRow()
      this.NavRow('使用指南', '了解核心记录流程', '?', 'guide', this.guideIcon(), this.guideDarkIcon())
      this.NavRow('关于识录笔记', '版本、理念和说明', 'i', 'about', this.aboutIcon(), this.aboutDarkIcon())
    }
    .width('100%')
  }
}
