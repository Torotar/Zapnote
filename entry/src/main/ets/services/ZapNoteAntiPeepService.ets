import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { dlpAntiPeep } from '@kit.DeviceSecurityKit';

export class ZapNoteAntiPeepService {
  private static hostContext: common.UIAbilityContext | undefined = undefined;
  private static subscribed: boolean = false;
  private static hasShownMask: boolean = false;

  private static readonly onStatusChange: Callback<dlpAntiPeep.DlpAntiPeepStatus> =
    async (status: dlpAntiPeep.DlpAntiPeepStatus): Promise<void> => {
      if (status === dlpAntiPeep.DlpAntiPeepStatus.PASS) {
        return;
      }
      if (status === dlpAntiPeep.DlpAntiPeepStatus.HIDE && !ZapNoteAntiPeepService.hasShownMask) {
        await ZapNoteAntiPeepService.setMaskLayer();
      }
    };

  static async enable(context: common.UIAbilityContext, requestOptions: boolean): Promise<boolean> {
    ZapNoteAntiPeepService.hostContext = context;
    ZapNoteAntiPeepService.hasShownMask = false;
    try {
      let isOpen: boolean = await dlpAntiPeep.isDlpAntiPeepSwitchOn();
      if (!isOpen && requestOptions) {
        const result: dlpAntiPeep.AntiPeepOptionsResult =
          await dlpAntiPeep.requestAntiPeepOptions(context);
        if (result === dlpAntiPeep.AntiPeepOptionsResult.SUCCESS ||
          result === dlpAntiPeep.AntiPeepOptionsResult.ALREADY_ON) {
          isOpen = true;
        } else {
          isOpen = await dlpAntiPeep.isDlpAntiPeepSwitchOn();
        }
      }
      if (!isOpen) {
        ZapNoteAntiPeepService.disable();
        return false;
      }
      ZapNoteAntiPeepService.subscribe();
      return true;
    } catch (error) {
      console.error('ZapNoteAntiPeepService enable failed: ' + JSON.stringify(error));
      ZapNoteAntiPeepService.disable();
      return false;
    }
  }

  static disable(): void {
    try {
      if (ZapNoteAntiPeepService.subscribed) {
        dlpAntiPeep.off('dlpAntiPeep', ZapNoteAntiPeepService.onStatusChange);
      }
    } catch (error) {
      console.error('ZapNoteAntiPeepService disable failed: ' + JSON.stringify(error));
    }
    ZapNoteAntiPeepService.subscribed = false;
    ZapNoteAntiPeepService.hasShownMask = false;
    ZapNoteAntiPeepService.hostContext = undefined;
  }

  static resetMaskFlag(): void {
    ZapNoteAntiPeepService.hasShownMask = false;
  }

  private static subscribe(): void {
    if (ZapNoteAntiPeepService.subscribed) {
      return;
    }
    dlpAntiPeep.on('dlpAntiPeep', ZapNoteAntiPeepService.onStatusChange);
    ZapNoteAntiPeepService.subscribed = true;
  }

  private static async setMaskLayer(): Promise<void> {
    const context: common.UIAbilityContext | undefined = ZapNoteAntiPeepService.hostContext;
    if (!context) {
      return;
    }
    try {
      const windowClass: window.Window = await window.getLastWindow(context);
      const windowId: number = windowClass.getWindowProperties().id;
      await dlpAntiPeep.setAntiPeepMaskLayer(windowId);
      ZapNoteAntiPeepService.hasShownMask = true;
    } catch (error) {
      console.error('ZapNoteAntiPeepService setMaskLayer failed: ' + JSON.stringify(error));
    }
  }
}
