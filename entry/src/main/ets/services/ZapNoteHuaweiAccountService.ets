import { common } from '@kit.AbilityKit';
import { authentication, loginComponentManager } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { HuaweiAccountInfo } from '../model/ZapNoteTypes';

export class ZapNoteHuaweiAccountService {
  public static emptyInfo(): HuaweiAccountInfo {
    return {
      openId: '',
      unionId: '',
      nickName: '',
      avatarUri: '',
      anonymousPhoneNumber: '',
      mobileNumber: '',
      loginState: 'unknown',
      loginStateText: '未检查登录状态',
      phoneConsistencyState: 'notChecked',
      phoneConsistencyText: '未启用手机号校验',
      localNumberConsistency: false,
      hasLocalNumberConsistency: false,
      phoneAuthorizationGranted: false,
      phoneAuthorizationText: '未申请手机号授权',
      lastUpdatedAt: 0
    };
  }

  public static normalizeInfo(value: HuaweiAccountInfo | null): HuaweiAccountInfo {
    const empty: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
    if (value === null) {
      return empty;
    }
    return {
      openId: ZapNoteHuaweiAccountService.safeString(value.openId),
      unionId: ZapNoteHuaweiAccountService.safeString(value.unionId),
      nickName: ZapNoteHuaweiAccountService.safeString(value.nickName),
      avatarUri: ZapNoteHuaweiAccountService.safeString(value.avatarUri),
      anonymousPhoneNumber: ZapNoteHuaweiAccountService.safeString(value.anonymousPhoneNumber),
      mobileNumber: ZapNoteHuaweiAccountService.safeString(value.mobileNumber),
      loginState: ZapNoteHuaweiAccountService.safeString(value.loginState, empty.loginState),
      loginStateText: ZapNoteHuaweiAccountService.safeString(value.loginStateText, empty.loginStateText),
      phoneConsistencyState: ZapNoteHuaweiAccountService.safeString(value.phoneConsistencyState,
        empty.phoneConsistencyState),
      phoneConsistencyText: ZapNoteHuaweiAccountService.safeString(value.phoneConsistencyText,
        empty.phoneConsistencyText),
      localNumberConsistency: typeof value.localNumberConsistency === 'boolean' ? value.localNumberConsistency :
        empty.localNumberConsistency,
      hasLocalNumberConsistency: typeof value.hasLocalNumberConsistency === 'boolean' ? value.hasLocalNumberConsistency :
        empty.hasLocalNumberConsistency,
      phoneAuthorizationGranted: typeof value.phoneAuthorizationGranted === 'boolean' ? value.phoneAuthorizationGranted :
        empty.phoneAuthorizationGranted,
      phoneAuthorizationText: ZapNoteHuaweiAccountService.safeString(value.phoneAuthorizationText,
        empty.phoneAuthorizationText),
      lastUpdatedAt: typeof value.lastUpdatedAt === 'number' ? value.lastUpdatedAt : empty.lastUpdatedAt
    };
  }

  public static mergeInfo(base: HuaweiAccountInfo, patch: HuaweiAccountInfo): HuaweiAccountInfo {
    const normalizedBase: HuaweiAccountInfo = ZapNoteHuaweiAccountService.normalizeInfo(base);
    const normalizedPatch: HuaweiAccountInfo = ZapNoteHuaweiAccountService.normalizeInfo(patch);
    return {
      openId: normalizedPatch.openId.length > 0 ? normalizedPatch.openId : normalizedBase.openId,
      unionId: normalizedPatch.unionId.length > 0 ? normalizedPatch.unionId : normalizedBase.unionId,
      nickName: normalizedPatch.nickName.length > 0 ? normalizedPatch.nickName : normalizedBase.nickName,
      avatarUri: normalizedPatch.avatarUri.length > 0 ? normalizedPatch.avatarUri : normalizedBase.avatarUri,
      anonymousPhoneNumber: normalizedPatch.anonymousPhoneNumber.length > 0 ? normalizedPatch.anonymousPhoneNumber :
        normalizedBase.anonymousPhoneNumber,
      mobileNumber: normalizedPatch.mobileNumber.length > 0 ? normalizedPatch.mobileNumber : normalizedBase.mobileNumber,
      loginState: normalizedPatch.loginState !== 'unknown' ? normalizedPatch.loginState : normalizedBase.loginState,
      loginStateText: normalizedPatch.loginState !== 'unknown' ? normalizedPatch.loginStateText :
        normalizedBase.loginStateText,
      phoneConsistencyState: normalizedPatch.phoneConsistencyState !== 'notChecked' ?
        normalizedPatch.phoneConsistencyState : normalizedBase.phoneConsistencyState,
      phoneConsistencyText: normalizedPatch.phoneConsistencyState !== 'notChecked' ?
        normalizedPatch.phoneConsistencyText : normalizedBase.phoneConsistencyText,
      localNumberConsistency: normalizedPatch.hasLocalNumberConsistency ? normalizedPatch.localNumberConsistency :
        normalizedBase.localNumberConsistency,
      hasLocalNumberConsistency: normalizedPatch.hasLocalNumberConsistency || normalizedBase.hasLocalNumberConsistency,
      phoneAuthorizationGranted: normalizedPatch.phoneAuthorizationGranted || normalizedBase.phoneAuthorizationGranted,
      phoneAuthorizationText: normalizedPatch.phoneAuthorizationGranted ? normalizedPatch.phoneAuthorizationText :
        normalizedBase.phoneAuthorizationText,
      lastUpdatedAt: Math.max(normalizedBase.lastUpdatedAt, normalizedPatch.lastUpdatedAt)
    };
  }

  public static infoFromLoginCredential(credential: loginComponentManager.HuaweiIDCredential): HuaweiAccountInfo {
    const info: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
    if (credential === null || credential === undefined) {
      return info;
    }
    info.openId = ZapNoteHuaweiAccountService.safeString(credential.openID);
    info.unionId = ZapNoteHuaweiAccountService.safeString(credential.unionID);
    info.loginState = info.openId.length > 0 || info.unionId.length > 0 ? 'authorized' : 'unknown';
    info.loginStateText = info.loginState === 'authorized' ? '华为账号已登录' : '未获取到账号标识';
    info.lastUpdatedAt = Date.now();
    return info;
  }

  public static async requestUserProfile(context: common.Context, forceAuthorization: boolean): Promise<HuaweiAccountInfo> {
    const request = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
    request.scopes = ['openid', 'profile'];
    request.forceAuthorization = forceAuthorization;
    request.state = util.generateRandomUUID();
    request.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256;
    const response = await ZapNoteHuaweiAccountService.executeAuthorizationRequest(context, request);
    const data = response.data;
    const info: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
    if (data !== null && data !== undefined) {
      info.openId = ZapNoteHuaweiAccountService.safeString(data.openID);
      info.unionId = ZapNoteHuaweiAccountService.safeString(data.unionID);
      info.nickName = ZapNoteHuaweiAccountService.safeString(data.nickName);
      info.avatarUri = ZapNoteHuaweiAccountService.safeString(data.avatarUri);
    }
    info.lastUpdatedAt = Date.now();
    return info;
  }

  public static async requestLoginState(info: HuaweiAccountInfo): Promise<HuaweiAccountInfo> {
    const request: authentication.StateRequest = {
      idType: ZapNoteHuaweiAccountService.idTypeForInfo(info),
      idValue: ZapNoteHuaweiAccountService.idValueForInfo(info)
    };
    const result: authentication.StateResult = await new authentication.HuaweiIDProvider().getHuaweiIDState(request);
    const next: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
    next.loginState = ZapNoteHuaweiAccountService.loginStateKey(result.state);
    next.loginStateText = ZapNoteHuaweiAccountService.loginStateText(result.state);
    next.lastUpdatedAt = Date.now();
    return next;
  }

  public static async requestMobileNumberConsistency(info: HuaweiAccountInfo): Promise<HuaweiAccountInfo> {
    const mobileNumber: string = ZapNoteHuaweiAccountService.safeString(info.mobileNumber);
    if (mobileNumber.length === 0) {
      const noPhone: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
      noPhone.phoneConsistencyState = 'noPhone';
      noPhone.phoneConsistencyText = '未启用手机号校验';
      noPhone.lastUpdatedAt = Date.now();
      return noPhone;
    }
    const request: authentication.ConsistencyRequest = {
      idType: ZapNoteHuaweiAccountService.idTypeForInfo(info),
      idValue: ZapNoteHuaweiAccountService.idValueForInfo(info),
      mobileNumber: mobileNumber
    };
    const result: authentication.ConsistencyResult =
      await new authentication.HuaweiIDProvider().getMobileNumberConsistency(request);
    const next: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
    next.phoneConsistencyState = ZapNoteHuaweiAccountService.consistencyStateKey(result.state);
    next.phoneConsistencyText = ZapNoteHuaweiAccountService.consistencyStateText(result.state);
    next.lastUpdatedAt = Date.now();
    return next;
  }

  public static authErrorMessage(error: BusinessError): string {
    if (error.code === 1001502001) {
      return '设备未登录华为账号';
    }
    if (error.code === 1001502002) {
      return '应用尚未获得华为账号授权';
    }
    if (error.code === 1001502014) {
      return '应用未申请所需账号权限';
    }
    if (error.code === 1001500003) {
      return '当前账号权限或 scope 暂不支持';
    }
    if (error.code === 1001502005) {
      return '网络异常，请稍后重试';
    }
    if (error.code === 1001502012) {
      return '用户取消授权';
    }
    if (error.message !== undefined && error.message.length > 0) {
      return error.message;
    }
    return '华为账号服务异常，错误码 ' + error.code.toString();
  }

  private static async executeAuthorizationRequest(context: common.Context,
    request: authentication.AuthorizationWithHuaweiIDRequest): Promise<authentication.AuthorizationWithHuaweiIDResponse> {
    const controller = new authentication.AuthenticationController(context);
    const response = await controller.executeRequest(request) as authentication.AuthorizationWithHuaweiIDResponse;
    if (response.state !== undefined && response.state.length > 0 && response.state !== request.state) {
      throw new Error('华为账号授权 state 校验失败');
    }
    return response;
  }

  private static idTypeForInfo(info: HuaweiAccountInfo): authentication.IdType {
    return ZapNoteHuaweiAccountService.safeString(info.unionId).length > 0 ?
      authentication.IdType.UNION_ID : authentication.IdType.OPEN_ID;
  }

  private static idValueForInfo(info: HuaweiAccountInfo): string {
    const unionId: string = ZapNoteHuaweiAccountService.safeString(info.unionId);
    if (unionId.length > 0) {
      return unionId;
    }
    return ZapNoteHuaweiAccountService.safeString(info.openId);
  }

  private static loginStateKey(state: authentication.State): string {
    if (state === authentication.State.AUTHORIZED) {
      return 'authorized';
    }
    if (state === authentication.State.UNAUTHORIZED) {
      return 'unauthorized';
    }
    if (state === authentication.State.UNLOGGED_IN) {
      return 'unloggedIn';
    }
    return 'unknown';
  }

  private static loginStateText(state: authentication.State): string {
    if (state === authentication.State.AUTHORIZED) {
      return '华为账号已登录且与当前账号一致';
    }
    if (state === authentication.State.UNAUTHORIZED) {
      return '设备已登录其他华为账号';
    }
    if (state === authentication.State.UNLOGGED_IN) {
      return '设备未登录华为账号';
    }
    return '未检查登录状态';
  }

  private static consistencyStateKey(state: authentication.ConsistencyState): string {
    if (state === authentication.ConsistencyState.CONSISTENT) {
      return 'consistent';
    }
    if (state === authentication.ConsistencyState.INCONSISTENT_WITH_DEVICES) {
      return 'inconsistentWithDevices';
    }
    if (state === authentication.ConsistencyState.INCONSISTENT) {
      return 'inconsistent';
    }
    return 'notChecked';
  }

  private static consistencyStateText(state: authentication.ConsistencyState): string {
    if (state === authentication.ConsistencyState.CONSISTENT) {
      return '账号绑定手机号、传入手机号与本机号码一致';
    }
    if (state === authentication.ConsistencyState.INCONSISTENT_WITH_DEVICES) {
      return '账号手机号一致，但与本机 SIM 不一致或无 SIM';
    }
    if (state === authentication.ConsistencyState.INCONSISTENT) {
      return '传入手机号与当前华为账号绑定手机号不一致';
    }
    return '未启用手机号校验';
  }

  private static safeString(value: Object | string | undefined, defaultValue: string = ''): string {
    if (typeof value === 'string') {
      return value.trim();
    }
    return defaultValue;
  }
}
