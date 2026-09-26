import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;
const SHARE_ACTION = 'ohos.want.action.sendData';
const SHARED_PHOTO_URI_KEY = 'zapnoteSharedPhotoUri';
const SHARED_PHOTO_ERROR_KEY = 'zapnoteSharedPhotoError';
const SHARED_PHOTO_REQUEST_KEY = 'zapnoteSharedPhotoRequestKey';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      this.syncSystemColorMode();
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    this.handleSharedPhotoWant(want);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleSharedPhotoWant(want);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    this.syncSystemColorMode(newConfig.colorMode);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    this.configureImmersiveWindow(windowStage);

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  private configureImmersiveWindow(windowStage: window.WindowStage): void {
    try {
      const mainWindow = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true);
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: '#111827',
        navigationBarContentColor: '#111827'
      });
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to configure immersive window. Cause: %{public}s', JSON.stringify(err));
    }
  }

  private syncSystemColorMode(colorMode?: ConfigurationConstant.ColorMode): void {
    let currentMode: number | undefined = colorMode;
    if (currentMode === undefined) {
      currentMode = this.context.resourceManager.getConfigurationSync().colorMode;
    }
    AppStorage.setOrCreate<string>('zapnoteSystemColorMode',
      currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'dark' : 'light');
  }

  private async handleSharedPhotoWant(want: Want): Promise<void> {
    if (want.action !== SHARE_ACTION) {
      return;
    }
    try {
      const sharedData: systemShare.SharedData = await systemShare.getSharedData(want);
      const records: systemShare.SharedRecord[] = sharedData.getRecords();
      let photoUri: string = '';
      for (let index: number = 0; index < records.length; index++) {
        const recordUri: string | undefined = records[index].uri;
        if (typeof recordUri === 'string' && recordUri.trim().length > 0) {
          photoUri = recordUri.trim();
          break;
        }
      }
      if (photoUri.length === 0) {
        this.publishSharedPhotoRequest('', '未收到可识别的图片');
        return;
      }
      this.publishSharedPhotoRequest(photoUri, '');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to parse shared photo. Cause: %{public}s', JSON.stringify(error));
      this.publishSharedPhotoRequest('', '图片分享内容读取失败，请重试');
    }
  }

  private publishSharedPhotoRequest(photoUri: string, errorMessage: string): void {
    const currentRequestKey: number = AppStorage.get<number>(SHARED_PHOTO_REQUEST_KEY) ?? 0;
    AppStorage.setOrCreate<string>(SHARED_PHOTO_URI_KEY, photoUri);
    AppStorage.setOrCreate<string>(SHARED_PHOTO_ERROR_KEY, errorMessage);
    AppStorage.setOrCreate<number>(SHARED_PHOTO_REQUEST_KEY, currentRequestKey + 1);
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    const currentKey: number = AppStorage.get<number>('zapnotePrivacyVaultBackgroundKey') ?? 0;
    AppStorage.setOrCreate<number>('zapnotePrivacyVaultBackgroundKey', currentKey + 1);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
