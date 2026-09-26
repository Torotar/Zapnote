import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HuaweiAccountInfo } from '../model/ZapNoteTypes';
import { ZapNoteHuaweiAccountService } from '../services/ZapNoteHuaweiAccountService';

interface HuaweiAccountErrorLike {
  code?: number;
  message?: string;
}

@Component
export struct HuaweiAccountLoginPage {
  @Prop isDark: boolean = false;
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  @Prop huaweiAccountOpenId: string = '';
  @Prop huaweiAccountInfo: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
  @State private localOpenId: string = '';
  @State private localInfo: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
  @State private localLoggedOut: boolean = false;
  @State private agreementAccepted: boolean = false;
  @State private loggingIn: boolean = false;
  @State private statusMessage: string = '';
  private loginCallbacksReady: boolean = false;
  private loginButtonController: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController();
  private loginButtonParams: loginComponentManager.LoginWithHuaweiIDButtonParams = {
    style: loginComponentManager.Style.BUTTON_RED,
    borderRadius: 12,
    supportDarkMode: true,
    loginType: loginComponentManager.LoginType.ID,
    textAndIconStyle: false
  };
  onLoginSuccess?: (info: HuaweiAccountInfo) => void;
  onLogout?: () => void;
  onRefresh?: () => void;
  onOpenUserAgreement?: () => void;
  onOpenPrivacyStatement?: () => void;
  onOpenHuaweiAccountAgreement?: () => void;

  aboutToAppear(): void {
    this.localInfo = ZapNoteHuaweiAccountService.normalizeInfo(this.huaweiAccountInfo);
    if (this.effectiveOpenId().length > 0) {
      this.agreementAccepted = true;
    }
    this.registerLoginCallbacks();
    this.syncAgreementStatus();
  }

  private registerLoginCallbacks(): void {
    if (this.loginCallbacksReady) {
      return;
    }
    this.loginCallbacksReady = true;
    this.loginButtonController.onClickEvent((error: BusinessError, event: loginComponentManager.ClickEvent): void => {
      if (error !== null && error !== undefined && typeof error.code === 'number' && error.code !== 0) {
        return;
      }
      if (event !== loginComponentManager.ClickEvent.HUAWEI_ID_LOGIN_BUTTON) {
        return;
      }
      if (!this.agreementAccepted) {
        this.statusMessage = '请先勾选同意用户协议和隐私声明';
        return;
      }
      this.loggingIn = true;
      this.statusMessage = '正在登录...';
    });
    this.loginButtonController.onClickLoginWithHuaweiIDButton((error: BusinessError,
      credential: loginComponentManager.HuaweiIDCredential): void => {
      this.handleLoginResult(error, credential);
    });
  }

  private syncAgreementStatus(): void {
    this.loginButtonController.setAgreementStatus(this.agreementAccepted ?
      loginComponentManager.AgreementStatus.ACCEPTED : loginComponentManager.AgreementStatus.NOT_ACCEPTED);
  }

  private setAgreementAccepted(value: boolean): void {
    this.agreementAccepted = value;
    this.syncAgreementStatus();
    if (value && this.statusMessage === '请先勾选同意用户协议和隐私声明') {
      this.statusMessage = '';
    }
  }

  private effectiveOpenId(): string {
    if (this.localLoggedOut) {
      return '';
    }
    const local: string = this.localOpenId.trim();
    if (local.length > 0) {
      return local;
    }
    const infoOpenId: string = this.currentInfo().openId;
    return infoOpenId.length > 0 ? infoOpenId : this.huaweiAccountOpenId.trim();
  }

  private currentInfo(): HuaweiAccountInfo {
    return ZapNoteHuaweiAccountService.mergeInfo(this.huaweiAccountInfo, this.localInfo);
  }

  private maskOpenId(openId: string): string {
    if (openId.length <= 8) {
      return openId;
    }
    return openId.substring(0, 4) + '...' + openId.substring(openId.length - 4);
  }

  private primaryAccountText(): string {
    const nickName: string = this.currentInfo().nickName;
    if (nickName.length > 0) {
      return nickName;
    }
    const openId: string = this.effectiveOpenId();
    if (openId.length > 0) {
      return '华为账号用户';
    }
    return '华为账号';
  }

  private accountSubtitleText(): string {
    const openId: string = this.effectiveOpenId();
    if (openId.length > 0) {
      return 'OpenID ' + this.maskOpenId(openId);
    }
    return '使用华为账号授权登录';
  }

  private statusToneColor(): string {
    if (this.statusMessage.indexOf('失败') >= 0 || this.statusMessage.indexOf('取消') >= 0 ||
      this.statusMessage.indexOf('请先') >= 0 || this.statusMessage.indexOf('未获取') >= 0) {
      return '#EF4444';
    }
    if (this.effectiveOpenId().length > 0) {
      return '#16A34A';
    }
    return this.textTertiary;
  }

  private hasAvatar(): boolean {
    return this.currentInfo().avatarUri.length > 0;
  }

  private loginStateText(): string {
    return this.currentInfo().loginStateText;
  }

  private logout(): void {
    this.localOpenId = '';
    this.localInfo = ZapNoteHuaweiAccountService.emptyInfo();
    this.localLoggedOut = true;
    this.setAgreementAccepted(false);
    this.loggingIn = false;
    this.statusMessage = '已退出华为账号';
    if (this.onLogout !== undefined) {
      this.onLogout();
    }
  }

  private handleLoginResult(error: BusinessError, credential: loginComponentManager.HuaweiIDCredential): void {
    if (error !== null && error !== undefined && typeof error.code === 'number' && error.code !== 0) {
      this.loggingIn = false;
      this.handleLoginError(error);
      return;
    }
    if (credential === null || credential === undefined || credential.openID.length === 0) {
      this.loggingIn = false;
      this.statusMessage = '未获取到华为账号信息';
      return;
    }
    const nextInfo: HuaweiAccountInfo =
      ZapNoteHuaweiAccountService.mergeInfo(this.currentInfo(), ZapNoteHuaweiAccountService.infoFromLoginCredential(credential));
    this.localInfo = nextInfo;
    this.localOpenId = nextInfo.openId;
    this.localLoggedOut = false;
    this.setAgreementAccepted(true);
    this.loggingIn = false;
    this.statusMessage = '华为账号已登录';
    if (this.onLoginSuccess !== undefined) {
      this.onLoginSuccess(nextInfo);
    }
  }

  private refreshAccountInfo(): void {
    this.statusMessage = '正在刷新华为账号信息...';
    if (this.onRefresh !== undefined) {
      this.onRefresh();
    }
  }

  private handleLoginError(error: BusinessError): void {
    const accountError: HuaweiAccountErrorLike = error as HuaweiAccountErrorLike;
    if (accountError.code === 1005300001) {
      this.statusMessage = '请先勾选同意用户协议和隐私声明';
      return;
    }
    if (accountError.code === 1001502012) {
      this.statusMessage = '已取消华为账号授权';
      return;
    }
    if (accountError.message !== undefined && accountError.message.length > 0) {
      this.statusMessage = '登录失败：' + accountError.message;
      return;
    }
    this.statusMessage = '登录失败，错误码 ' + error.code.toString();
  }

  private openUserAgreement(): void {
    if (this.onOpenUserAgreement !== undefined) {
      this.onOpenUserAgreement();
    }
  }

  private openPrivacyStatement(): void {
    if (this.onOpenPrivacyStatement !== undefined) {
      this.onOpenPrivacyStatement();
    }
  }

  private openHuaweiAccountAgreement(): void {
    if (this.onOpenHuaweiAccountAgreement !== undefined) {
      this.onOpenHuaweiAccountAgreement();
    }
  }

  @Builder
  private AccountAvatar() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.hasAvatar()) {
        Image(this.currentInfo().avatarUri)
          .width(76)
          .height(76)
          .objectFit(ImageFit.Cover)
          .border({ radius: 38 })
      } else if (this.effectiveOpenId().length > 0) {
        Text('华')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
      } else {
        SymbolGlyph($r('sys.symbol.person'))
          .fontSize(34)
          .fontColor([this.isDark ? '#F8FAFC' : '#1F1F1F'])
      }
    }
    .width(76)
    .height(76)
    .backgroundColor(this.effectiveOpenId().length > 0 ? this.selectedAccentColor : this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 38 })
    .margin({ bottom: 18 })
  }

  @Builder
  private AccountIdentity() {
    Column() {
      Text(this.primaryAccountText())
        .width('100%')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.accountSubtitleText())
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textTertiary)
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 32 })
  }

  @Builder
  private AgreementRow() {
    Row() {
      Toggle({ type: ToggleType.Checkbox, isOn: this.agreementAccepted })
        .width(22)
        .height(22)
        .selectedColor(this.selectedAccentColor)
        .onChange((isOn: boolean) => {
          this.setAgreementAccepted(isOn);
        })

      this.AgreementText()
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private AgreementText() {
    Column() {
      Row() {
        Text('已阅读并同意')
          .fontSize(12)
          .fontColor(this.textSecondary)
          .lineHeight(18)

        Button('《用户协议》')
          .type(ButtonType.Normal)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.selectedAccentColor)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .height(28)
          .padding({ left: 2, right: 2 })
          .stateEffect(true)
          .onClick(() => {
            this.openUserAgreement();
          })
          .hitTestBehavior(HitTestMode.Block)
          .accessibilityText('用户协议')

        Button('《隐私声明》')
          .type(ButtonType.Normal)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.selectedAccentColor)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .height(28)
          .padding({ left: 2, right: 2 })
          .stateEffect(true)
          .onClick(() => {
            this.openPrivacyStatement();
          })
          .hitTestBehavior(HitTestMode.Block)
          .accessibilityText('隐私声明')

        Text('和')
          .fontSize(12)
          .fontColor(this.textSecondary)
          .lineHeight(18)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)

      Row() {
        Text('《华为账号用户认证协议》')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.selectedAccentColor)
          .lineHeight(18)
      }
        .width('100%')
        .height(28)
        .padding({ left: 2, right: 2 })
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.openHuaweiAccountAgreement();
        })
        .hitTestBehavior(HitTestMode.Block)
        .accessibilityText('华为账号用户认证协议')
    }
    .width('100%')
    .layoutWeight(1)
    .margin({ left: 10 })
  }

  @Builder
  private LoginActions() {
    Column() {
      if (this.effectiveOpenId().length > 0) {
        this.AccountStatusPanel()

        Button('刷新账号信息')
          .width('100%')
          .height(48)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(this.selectedAccentColor)
          .border({ radius: 12 })
          .stateEffect(true)
          .onClick(() => {
            this.refreshAccountInfo();
          })

        Button('退出登录')
          .width('100%')
          .height(46)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#EF4444')
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: this.lineColor, radius: 12 })
          .stateEffect(true)
          .onClick(() => {
            this.logout();
          })
          .margin({ top: 12 })
      } else {
        Stack({ alignContent: Alignment.Center }) {
          LoginWithHuaweiIDButton({
            params: this.loginButtonParams,
            controller: this.loginButtonController
          })
            .width('100%')
            .height(48)
            .opacity(this.loggingIn ? 0 : 1)

          if (this.loggingIn) {
            this.LoadingLoginButton()
          }
        }
        .width('100%')
        .height(48)
      }

      if (this.statusMessage.length > 0) {
        Text(this.statusMessage)
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(this.statusToneColor())
          .textAlign(TextAlign.Center)
          .margin({ top: 16 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private LoadingLoginButton() {
    Row({ space: 8 }) {
      LoadingProgress()
        .width(18)
        .height(18)
        .color(Color.White)

      Text('正在登录...')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#E58FA1')
    .border({ radius: 12 })
    .hitTestBehavior(HitTestMode.Block)
    .accessibilityText('正在登录')
  }

  @Builder
  private AccountStatusPanel() {
    Row({ space: 10 }) {
      SymbolGlyph($r('sys.symbol.checkmark'))
        .fontSize(16)
        .fontColor([this.selectedAccentColor])

      Column() {
        Text('登录状态')
          .fontSize(12)
          .fontColor(this.textTertiary)

        Text(this.loginStateText())
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textSecondary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.inputBg)
    .border({ width: 1, color: this.lineColor, radius: 12 })
    .margin({ bottom: 16 })
  }

  build() {
    Column() {
      this.AccountAvatar()
      this.AccountIdentity()
      this.LoginActions()

      Blank()
        .layoutWeight(1)

      this.AgreementRow()
    }
    .width('100%')
    .constraintSize({ minHeight: 660 })
    .padding({ left: 24, right: 24, top: 36, bottom: 32 })
    .alignItems(HorizontalAlign.Center)
  }
}
