import userAuth from '@ohos.userIAM.userAuth';
import cryptoFramework from '@ohos.security.cryptoFramework';

export type PrivacyAuthStatus = 'success' | 'canceled' | 'failed' | 'unsupported' | 'locked' | 'timeout' | 'error';

export interface PrivacyAuthResult {
  status: PrivacyAuthStatus;
  message: string;
}

interface PrivacyAuthError {
  code?: number;
  message?: string;
}

/** Keeps platform authentication details out of the page and data layers. */
export class ZapNotePrivacyVaultAuthService {
  public static async authenticate(): Promise<PrivacyAuthResult> {
    try {
      let selectedType: userAuth.UserAuthType | undefined = undefined;
      let unavailableCode: number = userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT;
      const candidateTypes: userAuth.UserAuthType[] = [
        userAuth.UserAuthType.FACE,
        userAuth.UserAuthType.FINGERPRINT,
        userAuth.UserAuthType.PIN
      ];
      for (let index = 0; index < candidateTypes.length; index++) {
        const authType: userAuth.UserAuthType = candidateTypes[index];
        try {
          userAuth.getAvailableStatus(authType, userAuth.AuthTrustLevel.ATL2);
          selectedType = authType;
          break;
        } catch (error) {
          const typedError: PrivacyAuthError = error as PrivacyAuthError;
          if (typeof typedError.code === 'number') {
            unavailableCode = typedError.code;
          }
        }
      }
      if (selectedType === undefined) {
        return ZapNotePrivacyVaultAuthService.resultFromError({ code: unavailableCode });
      }
      let instance: userAuth.UserAuthInstance;
      try {
        const challenge: Uint8Array = cryptoFramework.createRandom().generateRandomSync(16).data;
        instance = userAuth.getUserAuthInstance({
          challenge: challenge,
          authType: [selectedType],
          authTrustLevel: userAuth.AuthTrustLevel.ATL2
        }, {
          title: '验证后进入隐私库'
        });
      } catch (error) {
        return ZapNotePrivacyVaultAuthService.resultFromError(error as PrivacyAuthError, '创建认证会话');
      }
      return await new Promise<PrivacyAuthResult>((resolve) => {
        let completed: boolean = false;
        const finish = (result: PrivacyAuthResult): void => {
          if (completed) {
            return;
          }
          completed = true;
          try {
            instance.off('result', callback);
          } catch (error) {
          }
          resolve(result);
        };
        const callback: userAuth.IAuthCallback = {
          onResult: (result: userAuth.UserAuthResult): void => {
            if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
              finish({ status: 'success', message: '' });
            } else if (result.result === userAuth.UserAuthResultCode.CANCELED) {
              finish({ status: 'canceled', message: '已取消进入隐私库' });
            } else if (result.result === userAuth.UserAuthResultCode.TIMEOUT) {
              finish({ status: 'timeout', message: '认证超时，请重试' });
            } else if (result.result === userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT ||
              result.result === userAuth.UserAuthResultCode.TRUST_LEVEL_NOT_SUPPORT) {
              finish({ status: 'unsupported', message: '当前设备不支持系统认证' });
            } else if (result.result === userAuth.UserAuthResultCode.NOT_ENROLLED) {
              finish({ status: 'unsupported', message: '设备尚未录入可用的系统认证方式' });
            } else if (result.result === userAuth.UserAuthResultCode.LOCKED) {
              finish({ status: 'locked', message: '系统认证已锁定，请稍后重试' });
            } else if (result.result === userAuth.UserAuthResultCode.BUSY) {
              finish({ status: 'error', message: '系统认证服务正忙，请稍后重试' });
            } else {
              finish({ status: 'failed', message: '认证失败，未进入隐私库' });
            }
          }
        };
        try {
          instance.on('result', callback);
        } catch (error) {
          finish(ZapNotePrivacyVaultAuthService.resultFromError(error as PrivacyAuthError, '订阅认证结果'));
          return;
        }
        try {
          instance.start();
        } catch (error) {
          finish(ZapNotePrivacyVaultAuthService.resultFromError(error as PrivacyAuthError, '启动认证'));
        }
      });
    } catch (error) {
      return ZapNotePrivacyVaultAuthService.resultFromError(error as PrivacyAuthError, '准备认证');
    }
  }

  private static resultFromError(error: PrivacyAuthError, stage?: string): PrivacyAuthResult {
    const code: number = typeof error.code === 'number' ? error.code : -1;
    const stageText: string = stage ? '（' + stage + '）' : '';
    if (code === userAuth.UserAuthResultCode.CANCELED) {
      return { status: 'canceled', message: '已取消进入隐私库' };
    }
    if (code === userAuth.UserAuthResultCode.TIMEOUT) {
      return { status: 'timeout', message: '认证超时，请重试' };
    }
    if (code === userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT ||
      code === userAuth.UserAuthResultCode.TRUST_LEVEL_NOT_SUPPORT) {
      return { status: 'unsupported', message: '当前设备未配置可用的系统认证' };
    }
    if (code === userAuth.UserAuthResultCode.NOT_ENROLLED) {
      return { status: 'unsupported', message: '设备尚未录入可用的系统认证方式' };
    }
    if (code === userAuth.UserAuthResultCode.LOCKED) {
      return { status: 'locked', message: '系统认证已锁定，请稍后重试' };
    }
    if (code === userAuth.UserAuthResultCode.BUSY) {
      return { status: 'error', message: '系统认证服务正忙，请稍后重试' };
    }
    if (code === userAuth.UserAuthResultCode.INVALID_PARAMETERS) {
      return { status: 'error', message: '系统认证参数无效，请更新应用后重试' };
    }
    if (code === 12500013) {
      return { status: 'error', message: '系统 PIN 已过期，请先在系统设置中更新 PIN' };
    }
    if (code === userAuth.UserAuthResultCode.GENERAL_ERROR) {
      return { status: 'error', message: '系统认证服务暂不可用，请确认设备已设置锁屏后重试' };
    }
    if (code === 401) {
      return { status: 'error', message: '系统认证请求参数校验失败' + stageText + '，请重试' };
    }
    if (code === 201) {
      return { status: 'error', message: '应用没有系统认证权限，请重新安装并授权' };
    }
    return { status: 'error', message: code >= 0 ?
      '无法启动系统认证（错误码 ' + code.toString() + '），请稍后重试' :
      '无法启动系统认证，请稍后重试' };
  }
}
