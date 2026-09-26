﻿import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { motion } from '@kit.MultimodalAwarenessKit';
import vibrator from '@ohos.vibrator';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import screenshot from '@ohos.screenshot';
import { KeyCode } from '@ohos.multimodalInput.keyCode';
import { fileIo, picker } from '@kit.CoreFileKit';
import { promptAction, window } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import {
  HdsTabs,
  HdsTabsController,
  hdsMaterial
} from '@kit.UIDesignKit';
import {
  ENGINE_OPTIONS,
  LIGHTING_OPTIONS,
  MOOD_OPTIONS,
  PHOTO_STYLE_OPTIONS,
  SYNC_OPTIONS,
  THEME_OPTIONS,
  WEATHER_OPTIONS
} from '../data/ZapNoteSeedData';
import {
  AiVisualEngineConfig,
  AiVisualEngineBackupConfig,
  DiaryEntry,
  HuaweiAccountInfo,
  LinkType,
  MatchRuleTemplateItem,
  RecycleBinEntry,
  SettingPanel,
  SyncDataScope,
  SyncLog,
  ValueOption,
  ZapNoteBackupSettings
} from '../model/ZapNoteTypes';
import { DiaryStatsUtils } from '../utils/DiaryStatsUtils';
import { ZapNoteTheme } from '../utils/ZapNoteTheme';
import { WebDavConnectionTestResult, WebDavService, WebDavTransferResult } from '../services/WebDavService';
import { ZapNoteBackupExportResult, ZapNoteBackupService, ZapNoteRestoreSummary, ZapNoteBackupZipRestoreResult } from '../services/ZapNoteBackupService';
import {
  OcrTextRecognitionError,
  OcrTextRecognitionResult,
  OcrTextRecognitionService
} from '../services/OcrTextRecognitionService';
import {
  OcrRuleProcessingResult,
  OcrRuleProcessingService
} from '../services/OcrRuleProcessingService';
import { ZapNoteDiaryStorageService } from '../services/ZapNoteDiaryStorageService';
import { ZapNotePreferencesService } from '../services/ZapNotePreferencesService';
import { ZapNoteAntiPeepService } from '../services/ZapNoteAntiPeepService';
import { ZapNoteHuaweiAccountService } from '../services/ZapNoteHuaweiAccountService';
import { ZapNotePrivacyVaultAuthService } from '../services/ZapNotePrivacyVaultAuthService';
import { PhotoAlbumSaveService } from '../services/PhotoAlbumSaveService';
import { ScreenCapturePhotoService } from '../services/ScreenCapturePhotoService';
import {
  AiVisualParseResult,
  AiVisualParsingService
} from '../services/AiVisualParsingService';
import {
  LinkExtractionResult,
  LinkIntent,
  LinkRecognitionService
} from '../services/LinkRecognitionService';
import { FavoritesPage as FavoritesTabPage } from './FavoritesPage';
import { FloatingActionMenu } from '../components/FloatingActionMenu';
import { OcrRecognitionLoadingOverlay } from '../components/OcrRecognitionLoadingOverlay';
import { DiaryEditorPage } from './DiaryEditorPage';
import { HomePage as HomeTabPage } from './HomePage';
import { SettingsPage as SettingsTabPage } from './SettingsPage';
import { StatsPage as StatsTabPage } from './StatsPage';
import { PrivacyVaultPage } from './PrivacyVaultPage';

interface RecognizedPersonCodeTitle {
  person: string;
  code: string;
}

interface BusinessErrorLike {
  code?: number;
  message?: string;
}

interface DiarySaveResult {
  success: boolean;
  updated: boolean;
  emptyDraft: boolean;
}

@CustomDialog
@Component
struct DiaryFolderOptionsDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: this });
  folders: string[] = [];
  selectedFolderName: string = '';
  selectedAccentColor: string = '#6366F1';
  cardBg: string = '#FFFFFF';
  inputBg: string = '#F1F5F9';
  lineColor: string = '#E2E8F0';
  textPrimary: string = '#0F172A';
  textSecondary: string = '#475569';
  textTertiary: string = '#94A3B8';
  @State private newFolderName: string = '';
  @State private creatingNewTag: boolean = false;
  onChoose: (value: string) => void = (value: string) => {};
  onCreate: (value: string) => void = (value: string) => {};

  private optionValues(): string[] {
    const result: string[] = [''];
    this.folders.forEach((folder: string) => {
      const value: string = folder.trim();
      if (value.length > 0 && result.indexOf(value) < 0) {
        result.push(value);
      }
    });
    return result;
  }

  private optionLabel(value: string): string {
    return value.length > 0 ? value : '无标签';
  }

  private canCreateFolder(): boolean {
    return this.newFolderName.trim().length > 0;
  }

  @Builder
  private FolderOption(value: string) {
    Row() {
      Text(this.optionLabel(value))
        .layoutWeight(1)
        .fontSize(16)
        .fontWeight(value === this.selectedFolderName ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(value === this.selectedFolderName ? this.selectedAccentColor : this.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (value === this.selectedFolderName) {
        Text('✓')
          .fontSize(16)
          .fontColor(this.selectedAccentColor)
      }
    }
    .width('100%')
    .height(46)
    .padding({ left: 14, right: 14 })
    .backgroundColor(value === this.selectedFolderName ? this.inputBg : this.cardBg)
    .border({ width: 1, color: value === this.selectedFolderName ? this.selectedAccentColor : this.lineColor, radius: 14 })
    .margin({ top: 8 })
    .onClick(() => {
      this.onChoose(value);
      this.controller.close();
    })
  }

  @Builder
  private NewTagTrigger() {
    Row() {
      Text('+')
        .width(22)
        .height(22)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.selectedAccentColor)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.cardBg)
        .border({ width: 1, color: this.lineColor, radius: 11 })

      Text('新标签')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.selectedAccentColor)
        .margin({ left: 10 })
        .layoutWeight(1)

      Text('创建')
        .fontSize(13)
        .fontColor(this.textTertiary)
    }
    .width('100%')
    .height(46)
    .padding({ left: 14, right: 14 })
    .backgroundColor(this.inputBg)
    .border({ width: 1, color: this.lineColor, radius: 14 })
    .margin({ top: 12 })
    .onClick(() => {
      this.creatingNewTag = true;
    })
  }

  @Builder
  private NewTagInput() {
    Row() {
      TextInput({ placeholder: '输入标签名称', text: this.newFolderName })
        .layoutWeight(1)
        .height(42)
        .fontSize(15)
        .fontColor(this.textPrimary)
        .placeholderColor(this.textTertiary)
        .backgroundColor(this.inputBg)
        .border({ width: 1, color: this.canCreateFolder() ? this.selectedAccentColor : this.lineColor, radius: 14 })
        .padding({ left: 12, right: 10 })
        .onChange((value: string) => {
          this.newFolderName = value;
        })

      Button('✓')
        .width(42)
        .height(42)
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor(this.canCreateFolder() ? this.selectedAccentColor : this.lineColor)
        .border({ radius: 14 })
        .margin({ left: 8 })
        .onClick(() => {
          const value: string = this.newFolderName.trim();
          if (value.length > 0) {
            this.onCreate(value);
            this.controller.close();
          }
        })
    }
    .width('100%')
    .height(46)
    .margin({ top: 12 })
  }

  @Builder
  private NewTagArea() {
    Column() {
      Row() {
        if (this.creatingNewTag) {
          this.NewTagInput()
        } else {
          this.NewTagTrigger()
        }
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      Text('选择标签')
        .width('100%')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .margin({ top: 6, bottom: 4 })

      ForEach(this.optionValues(), (value: string) => {
        this.FolderOption(value)
      }, (value: string) => value.length > 0 ? value : 'none')

      this.NewTagArea()
    }
    .width('100%')
    .padding({ left: 22, right: 22, top: 16, bottom: 20 })
    .backgroundColor(this.cardBg)
    .border({ radius: 22 })
  }
}

@Entry
@Component
struct Index {
  @State private searchQuery: string = '';
  @State private currentTab: number = 0;
  @State private settingsPanel: SettingPanel = 'main';
  @State private settingsBackRequestKey: number = 0;
  @State private settingsContentRefreshKey: number = 0;
  @State private settingsSubPageRouteKey: number = 0;
  @State private settingsLegalPanelSource: string = '';
  @State private statsContentRefreshKey: number = 0;
  @State private diaries: DiaryEntry[] = [];
  @State private recycleBinItems: RecycleBinEntry[] = [];
  @State private diaryFolders: string[] = [];
  @State private editorVisible: boolean = false;
  @State private editorPhotoPreviewOpen: boolean = false;
  @State private editingId: string = '';
  @State private draftTitle: string = '';
  @State private draftBody: string = '';
  @State private draftFolderName: string = '';
  @State private draftDateMs: number = 0;
  @State private draftMood: string = '😊';
  @State private draftWeather: string = '☀️';
  @State private draftFavorite: boolean = false;
  @State private draftHasPhoto: boolean = false;
  @State private draftPhotoInBody: boolean = false;
  @State private draftPhotoUri: string = '';
  @State private draftPhotoUris: string[] = [];
  @State private draftThumbnailPhotoIndex: number = 0;
  @State private draftThumbnailScale: number = 1;
  @State private draftThumbnailOffsetX: number = 0;
  @State private draftThumbnailOffsetY: number = 0;
  @State private draftThumbnailPhotoAspect: number = 1;
  @State private draftPhotoX: number = 0;
  @State private draftPhotoY: number = 0;
  @State private draftPhotoWidth: number = 156;
  @State private draftPhotoHeight: number = 118;
  @State private draftPhotoRotation: number = 0;
  @State private pickerType: string = '';
  @State private metaPickerSheetOpen: boolean = false;
  @State private metaPickerType: string = 'mood';
  @State private ocrReviewSheetOpen: boolean = false;
  @State private ocrReviewText: string = '';
  @State private ocrReviewOriginalText: string = '';
  @State private ocrReviewProcessedText: string = '';
  @State private ocrReviewTitle: string = '';
  @State private ocrReviewProcessedTitle: string = '';
  @State private ocrReviewProcessingMode: string = '';
  @State private ocrReviewShowingOriginal: boolean = false;
  @State private ocrReviewRuleSummary: string = '';
  @State private ocrReviewRuleMenuOpen: boolean = false;
  @State private ocrReviewRuleItems: MatchRuleTemplateItem[] = [];
  @State private ocrReviewSelectedRuleIds: string[] = [];
  @State private ocrReviewAppliedRuleIds: string[] = [];
  @State private ocrReviewRuleSelectionDirty: boolean = false;
  @State private ocrReviewApplyDialogOpen: boolean = false;
  @State private ocrReviewRulesApplying: boolean = false;
  @State private ocrReviewContentEdited: boolean = false;
  @State private ocrReviewKeyboardHeightVp: number = 0;
  @State private ocrLoadingVisible: boolean = false;
  @State private ocrLoadingPhase: string = 'recognizing';
  @State private pendingConfirmId: string = '';
  @State private themeMode: string = 'light';
  @StorageLink('zapnoteSystemColorMode') @Watch('handleSystemColorModeChange') private systemColorMode: string = 'light';
  @StorageLink('zapnoteSharedPhotoUri') private sharedPhotoUri: string = '';
  @StorageLink('zapnoteSharedPhotoError') private sharedPhotoError: string = '';
  @StorageLink('zapnoteSharedPhotoRequestKey') @Watch('handleSharedPhotoRequestChange')
  private sharedPhotoRequestKey: number = 0;
  @StorageLink('zapnotePrivacyVaultBackgroundKey') @Watch('handlePrivacyVaultBackgroundChange')
  private privacyVaultBackgroundKey: number = 0;
  @State private privacyEnabled: boolean = true;
  @State private gripModeEnabled: boolean = false;
  @State private gripOnLeft: boolean = false;
  @State private lightingMode: string = 'off';
  @State private autoFillEnabled: boolean = true;
  @State private engine: string = 'default';
  @State private vibrateEnabled: boolean = true;
  @State private doubleTouchEnabled: boolean = false;
  @State private doubleTouchAction: string = 'none';
  @State private sharedPhotoSaveMode: string = 'ask';
  @State private sharedPhotoAutoRecognizeEnabled: boolean = false;
  @State private sharedPhotoSaveToAlbumEnabled: boolean = false;
  @State private enhancedLinkRecognitionEnabled: boolean = false;
  private smartKeyCaptureInProgress: boolean = false;
  @State private syncInterval: string = 'off';
  @State private syncOnChange: boolean = false;
  @State private syncMode: number = 0;
  @State private syncTimes: string[] = ['08:00', '22:00'];
  @State private historyLimit: number = 10;
  @State private syncRestoreStrategy: string = 'merge';
  @State private syncDataScope: SyncDataScope = 'all';
  @State private webdavUrl: string = '';
  @State private webdavUser: string = '';
  @State private webdavPass: string = '';
  @State private webdavRemotePath: string = ZapNotePreferencesService.DEFAULT_WEBDAV_REMOTE_PATH;
  @State private selectedPhotoStyle: string = 'original';
  @State private selectedAccentColor: string = '#6366F1';
  @State private backupPreview: string = '';
  @State private syncLogs: SyncLog[] = [];
  @State private syncLogRefreshKey: number = 0;
  @State private huaweiAccountOpenId: string = '';
  @State private huaweiAccountInfo: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
  @State private privacyVaultVisible: boolean = false;
  @State private privacyVaultSelectionSheetOpen: boolean = false;
  @State private privacyVaultUnlocked: boolean = false;
  private privacyVaultAuthInProgress: boolean = false;

  private tabsController: HdsTabsController = new HdsTabsController();
  private folderDialogController: CustomDialogController | null = null;
  @State private materialEffectMode: number = 3;
  private preferencesReady: boolean = false;
  private diarySaveTask: Promise<DiarySaveResult> | null = null;
  private diarySaveFeedbackRequested: boolean = false;
  private sharedPhotoPromptInProgress: boolean = false;
  private lastHandledSharedPhotoRequestKey: number = 0;
  private changeSyncTimer: number = -1;
  private scheduledSyncTimer: number = -1;
  private lastScheduledSyncKey: string = '';
  private holdingHandSubscribed: boolean = false;
  private indexPageActive: boolean = false;
  private ocrReviewKeyboardWindow: window.Window | undefined = undefined;
  private ocrReviewKeyboardHeightListenerRegistered: boolean = false;
  private ocrReviewRecognitionResult: OcrTextRecognitionResult | null = null;
  private ocrReviewAllRuleItems: MatchRuleTemplateItem[] = [];
  private ocrReviewShowSuggestedTitle: boolean = true;
  private ocrReviewSessionKey: number = 0;
  private ocrLoadingSessionKey: number = 0;
  private readonly leftHandHeldStatus: number = 1;
  private readonly rightHandHeldStatus: number = 2;
  private handleHoldingHandChange: Callback<motion.HoldingHandStatus> = (status: motion.HoldingHandStatus): void => {
    this.updateGripSideByHoldingHand(status);
  };
  private ocrReviewKeyboardHeightCallback: Callback<number> = (height: number): void => {
    if (!this.indexPageActive) {
      return;
    }
    this.ocrReviewKeyboardHeightVp = this.ocrReviewSheetOpen ? this.keyboardHeightToVp(height) : 0;
  };

  aboutToAppear(): void {
    this.indexPageActive = true;
    this.loadSavedAppearanceConfig();
    this.loadSavedInterfaceConfig();
    this.loadSavedDiaries();
    this.loadSavedRecycleBin();
    this.loadSavedDiaryFolders();
    this.loadSavedSyncConfig();
    this.loadSavedHuaweiAccount();
    this.subscribeHoldingHandChange();
    this.registerOcrReviewKeyboardListener();
    this.scheduleSharedPhotoRequestCheck();
  }

  aboutToDisappear(): void {
    this.indexPageActive = false;
    this.ocrReviewKeyboardHeightVp = 0;
    this.unregisterOcrReviewKeyboardListener();
    this.unsubscribeHoldingHandChange();
    ZapNoteAntiPeepService.disable();
    this.stopSyncTimers();
  }

  private keyboardHeightToVp(height: number): number {
    if (height <= 0) {
      return 0;
    }
    try {
      return Math.max(this.getUIContext().px2vp(height), 0);
    } catch (error) {
      console.error('Index keyboardHeightToVp failed: ' + JSON.stringify(error));
      return 0;
    }
  }

  private async registerOcrReviewKeyboardListener(): Promise<void> {
    if (!this.indexPageActive || this.ocrReviewKeyboardHeightListenerRegistered) {
      return;
    }
    try {
      const hostContext: common.Context | undefined =
        this.getUIContext().getHostContext() as common.Context | undefined;
      if (hostContext === undefined) {
        return;
      }
      const mainWindow: window.Window = await window.getLastWindow(hostContext);
      if (!this.indexPageActive) {
        return;
      }
      this.ocrReviewKeyboardWindow = mainWindow;
      mainWindow.on('keyboardHeightChange', this.ocrReviewKeyboardHeightCallback);
      this.ocrReviewKeyboardHeightListenerRegistered = true;
    } catch (error) {
      console.error('Index register OCR review keyboard listener failed: ' + JSON.stringify(error));
    }
  }

  private unregisterOcrReviewKeyboardListener(): void {
    if (this.ocrReviewKeyboardWindow === undefined) {
      return;
    }
    try {
      if (this.ocrReviewKeyboardHeightListenerRegistered) {
        this.ocrReviewKeyboardWindow.off('keyboardHeightChange', this.ocrReviewKeyboardHeightCallback);
        this.ocrReviewKeyboardHeightListenerRegistered = false;
      }
      this.ocrReviewKeyboardWindow = undefined;
    } catch (error) {
      console.error('Index unregister OCR review keyboard listener failed: ' + JSON.stringify(error));
    }
  }

  onPageShow(): void {
    ZapNoteAntiPeepService.resetMaskFlag();
    if (this.privacyEnabled) {
      this.syncAntiPeepProtection(false);
    }
  }

  onPageHide(): void {
    this.autoSaveEditorOnPageHide();
    this.lockPrivacyVault();
  }

  private autoSaveEditorOnPageHide(): void {
    if (!this.editorVisible || !this.hasUnsavedDraftChanges()) {
      return;
    }
    this.saveDiary(false).then((saved: boolean): void => {
      if (!saved) {
        console.error('Index background diary auto-save did not persist the draft');
      }
    }).catch((error: BusinessErrorLike): void => {
      console.error('Index background diary auto-save failed: ' + JSON.stringify(error));
    });
  }

  private async ensurePreferencesReady(): Promise<boolean> {
    if (this.preferencesReady) {
      return true;
    }
    try {
      const context = getContext(this) as common.Context;
      ZapNoteDiaryStorageService.init(context);
      await ZapNotePreferencesService.init(context);
      this.preferencesReady = true;
      return true;
    } catch (error) {
      console.error('Index ensurePreferencesReady failed: ' + JSON.stringify(error));
      return false;
    }
  }

  private async loadSavedSyncConfig(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    this.webdavUrl = await ZapNotePreferencesService.getWebDavServerUrl();
    this.webdavUser = await ZapNotePreferencesService.getWebDavUsername();
    this.webdavPass = await ZapNotePreferencesService.getWebDavPassword();
    this.webdavRemotePath = this.normalizeRemotePath(await ZapNotePreferencesService.getWebDavRemotePath());
    if (this.webdavRemotePath.length === 0) {
      this.webdavRemotePath = ZapNotePreferencesService.DEFAULT_WEBDAV_REMOTE_PATH;
    }
    this.syncInterval = await ZapNotePreferencesService.getSyncInterval();
    this.syncOnChange = await ZapNotePreferencesService.getSyncOnChange();
    this.syncMode = await ZapNotePreferencesService.getWebDavSyncMode();
    this.syncTimes = await ZapNotePreferencesService.getWebDavSyncTimes();
    this.historyLimit = await ZapNotePreferencesService.getWebDavHistoryLimit();
    this.syncRestoreStrategy = await ZapNotePreferencesService.getWebDavRestoreStrategy();
    this.syncDataScope = await ZapNotePreferencesService.getWebDavSyncDataScope();
    this.syncLogs = await ZapNotePreferencesService.getSyncLogs();
    this.startScheduledSyncTimer();
  }

  private async loadSavedHuaweiAccount(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    const savedInfo: HuaweiAccountInfo = await ZapNotePreferencesService.getHuaweiAccountInfo();
    this.huaweiAccountInfo = savedInfo;
    this.huaweiAccountOpenId = savedInfo.openId;
    this.refreshHuaweiAccountRuntimeState(false);
  }

  private async saveHuaweiAccountLogin(info: HuaweiAccountInfo): Promise<void> {
    const normalizedInfo: HuaweiAccountInfo = ZapNoteHuaweiAccountService.normalizeInfo(info);
    if (normalizedInfo.openId.length === 0 || !await this.ensurePreferencesReady()) {
      this.showToast('未获取到华为账号信息', 'danger');
      return;
    }
    this.huaweiAccountInfo = ZapNoteHuaweiAccountService.mergeInfo(this.huaweiAccountInfo, normalizedInfo);
    this.huaweiAccountOpenId = this.huaweiAccountInfo.openId;
    await ZapNotePreferencesService.setHuaweiAccountInfo(this.huaweiAccountInfo);
    this.showToast('华为账号已登录', 'success');
    this.refreshHuaweiAccountRuntimeState(true);
  }

  private async logoutHuaweiAccount(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      this.showToast('退出失败，请稍后重试', 'danger');
      return;
    }
    this.huaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
    this.huaweiAccountOpenId = '';
    await ZapNotePreferencesService.clearHuaweiAccountInfo();
    this.showToast('已退出华为账号', 'info');
  }

  private async refreshHuaweiAccountRuntimeState(forceAuthorization: boolean): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    const currentInfo: HuaweiAccountInfo = this.huaweiAccountInfo;
    if (currentInfo.openId.length === 0 && currentInfo.unionId.length === 0 && !forceAuthorization) {
      return;
    }
    try {
      let nextInfo: HuaweiAccountInfo = currentInfo;
      try {
        const profileInfo: HuaweiAccountInfo =
          await ZapNoteHuaweiAccountService.requestUserProfile(getContext(this) as common.Context, forceAuthorization);
        nextInfo = ZapNoteHuaweiAccountService.mergeInfo(nextInfo, profileInfo);
      } catch (error) {
        console.error('Index refreshHuaweiAccountRuntimeState profile failed: ' + JSON.stringify(error));
      }
      if (nextInfo.openId.length > 0 || nextInfo.unionId.length > 0) {
        try {
          const stateInfo: HuaweiAccountInfo = await ZapNoteHuaweiAccountService.requestLoginState(nextInfo);
          nextInfo = ZapNoteHuaweiAccountService.mergeInfo(nextInfo, stateInfo);
        } catch (error) {
          console.error('Index refreshHuaweiAccountRuntimeState state failed: ' + JSON.stringify(error));
        }
        try {
          const consistencyInfo: HuaweiAccountInfo =
            await ZapNoteHuaweiAccountService.requestMobileNumberConsistency(nextInfo);
          nextInfo = ZapNoteHuaweiAccountService.mergeInfo(nextInfo, consistencyInfo);
        } catch (error) {
          console.error('Index refreshHuaweiAccountRuntimeState consistency failed: ' + JSON.stringify(error));
        }
      }
      this.huaweiAccountInfo = nextInfo;
      this.huaweiAccountOpenId = nextInfo.openId;
      await ZapNotePreferencesService.setHuaweiAccountInfo(nextInfo);
    } catch (error) {
      console.error('Index refreshHuaweiAccountRuntimeState failed: ' + JSON.stringify(error));
    }
  }

  private async loadSavedAppearanceConfig(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    this.themeMode = await ZapNotePreferencesService.getThemeMode();
    this.lightingMode = await ZapNotePreferencesService.getLightingMode();
    this.materialEffectMode = this.materialEffectModeForLighting(this.lightingMode);
    this.selectedAccentColor = await ZapNotePreferencesService.getSelectedAccentColor();
    this.gripModeEnabled = await ZapNotePreferencesService.getGripModeEnabled();
    this.applyThemeColorMode(this.themeMode);
  }

  private async saveAppearanceValue(key: string, value: string): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    if (key === 'theme') {
      await ZapNotePreferencesService.setThemeMode(value);
    } else if (key === 'lighting') {
      await ZapNotePreferencesService.setLightingMode(value);
    } else if (key === 'accent') {
      await ZapNotePreferencesService.setSelectedAccentColor(value);
    }
  }

  private async saveAppearanceToggle(key: string, value: boolean): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    if (key === 'grip') {
      await ZapNotePreferencesService.setGripModeEnabled(value);
    }
  }

  private async loadSavedDiaries(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    const hasDiaryFile: boolean = ZapNoteDiaryStorageService.hasDiaryFile();
    const fileDiaries: DiaryEntry[] = ZapNoteDiaryStorageService.loadDiaries();
    if (hasDiaryFile) {
      this.diaries = DiaryStatsUtils.sortDiariesByLatest(fileDiaries);
      this.refreshSettingsContent();
      return;
    }
    const preferenceDiaries: DiaryEntry[] = await ZapNotePreferencesService.getDiaries();
    const sortedPreferenceDiaries: DiaryEntry[] = DiaryStatsUtils.sortDiariesByLatest(preferenceDiaries);
    this.diaries = sortedPreferenceDiaries;
    this.refreshSettingsContent();
    if (preferenceDiaries.length > 0) {
      ZapNoteDiaryStorageService.saveDiaries(sortedPreferenceDiaries);
    }
  }

  private async loadSavedRecycleBin(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    this.recycleBinItems = ZapNoteDiaryStorageService.loadRecycleBin()
      .sort((left: RecycleBinEntry, right: RecycleBinEntry): number => right.deletedAt - left.deletedAt);
    this.refreshSettingsContent();
  }

  private async saveRecycleBin(value: RecycleBinEntry[]): Promise<boolean> {
    this.refreshSettingsContent();
    if (!await this.ensurePreferencesReady()) {
      return false;
    }
    return ZapNoteDiaryStorageService.saveRecycleBin(value);
  }

  private async loadSavedDiaryFolders(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    const savedFolders: string[] = await ZapNotePreferencesService.getDiaryFolders();
    const mergedFolders: string[] = this.mergeFolderNames(savedFolders);
    this.diaryFolders = mergedFolders;
    if (mergedFolders.length !== savedFolders.length) {
      await ZapNotePreferencesService.setDiaryFolders(mergedFolders);
    }
  }

  private async saveLocalDiaries(value: DiaryEntry[], triggerChangeSync: boolean = true): Promise<boolean> {
    this.refreshSettingsContent();
    this.statsContentRefreshKey++;
    if (!this.preferencesReady && !await this.ensurePreferencesReady()) {
      return false;
    }
    try {
      const sortedDiaries: DiaryEntry[] = DiaryStatsUtils.sortDiariesByLatest(value);
      const fileSaved: boolean = ZapNoteDiaryStorageService.saveDiaries(sortedDiaries);
      if (fileSaved && triggerChangeSync && this.syncMode === 1) {
        this.scheduleChangeSync();
      }
      return fileSaved;
    } catch (error) {
      console.error('Index saveLocalDiaries failed: ' + JSON.stringify(error));
      return false;
    }
  }

  private scheduleChangeSync(): void {
    if (this.changeSyncTimer >= 0) {
      clearTimeout(this.changeSyncTimer);
    }
    this.changeSyncTimer = setTimeout((): void => {
      this.changeSyncTimer = -1;
      if (this.isWebdavConfigReady()) {
        this.pushSync();
      } else {
        this.addSyncLog('自动同步待配置', '内容已变化，请先完成 WebDAV 配置', 'warning');
      }
    }, 800);
  }

  private startScheduledSyncTimer(): void {
    if (this.scheduledSyncTimer >= 0) {
      clearInterval(this.scheduledSyncTimer);
    }
    this.scheduledSyncTimer = setInterval((): void => {
      this.runScheduledSyncIfDue();
    }, 30000);
    this.runScheduledSyncIfDue();
  }

  private runScheduledSyncIfDue(): void {
    if (this.syncMode !== 0 || !this.isWebdavConfigReady()) {
      return;
    }
    const now: Date = new Date();
    const timeText: string = this.pad2(now.getHours()) + ':' + this.pad2(now.getMinutes());
    if (this.syncTimes.indexOf(timeText) < 0) {
      return;
    }
    const syncKey: string = now.getFullYear().toString() + '-' + this.pad2(now.getMonth() + 1) + '-' +
      this.pad2(now.getDate()) + '-' + timeText;
    if (syncKey === this.lastScheduledSyncKey) {
      return;
    }
    this.lastScheduledSyncKey = syncKey;
    this.pushSync();
  }

  private pad2(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
  }

  private stopSyncTimers(): void {
    if (this.changeSyncTimer >= 0) {
      clearTimeout(this.changeSyncTimer);
      this.changeSyncTimer = -1;
    }
    if (this.scheduledSyncTimer >= 0) {
      clearInterval(this.scheduledSyncTimer);
      this.scheduledSyncTimer = -1;
    }
  }

  private async saveDiaryFolders(value: string[]): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    await ZapNotePreferencesService.setDiaryFolders(value);
  }

  private async loadSavedInterfaceConfig(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    this.privacyEnabled = await ZapNotePreferencesService.getPrivacyEnabled();
    if (this.privacyEnabled) {
      await this.syncAntiPeepProtection(false);
    }
    this.autoFillEnabled = await ZapNotePreferencesService.getAutoFillEnabled();
    this.vibrateEnabled = await ZapNotePreferencesService.getVibrateEnabled();
    this.doubleTouchEnabled = await ZapNotePreferencesService.getDoubleTouchEnabled();
    this.doubleTouchAction = this.normalizeDoubleTouchAction(await ZapNotePreferencesService.getDoubleTouchAction());
    this.sharedPhotoSaveMode = this.normalizeSharedPhotoSaveMode(
      await ZapNotePreferencesService.getSharedPhotoSaveMode());
    this.sharedPhotoAutoRecognizeEnabled =
      await ZapNotePreferencesService.getSharedPhotoAutoRecognizeEnabled();
    this.sharedPhotoSaveToAlbumEnabled = await ZapNotePreferencesService.getSharedPhotoSaveToAlbumEnabled();
    this.enhancedLinkRecognitionEnabled = await ZapNotePreferencesService.getEnhancedLinkRecognitionEnabled();
    this.engine = await ZapNotePreferencesService.getEngine();
    this.selectedPhotoStyle = await ZapNotePreferencesService.getSelectedPhotoStyle();
  }

  private async saveInterfaceToggle(key: string, value: boolean): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    if (key === 'privacy') {
      await ZapNotePreferencesService.setPrivacyEnabled(value);
    } else if (key === 'autofill') {
      await ZapNotePreferencesService.setAutoFillEnabled(value);
    } else if (key === 'vibrate') {
      await ZapNotePreferencesService.setVibrateEnabled(value);
    } else if (key === 'doubleTouch') {
      await ZapNotePreferencesService.setDoubleTouchEnabled(value);
    } else if (key === 'shared-photo-auto-recognize') {
      await ZapNotePreferencesService.setSharedPhotoAutoRecognizeEnabled(value);
    } else if (key === 'shared-photo-save-to-album') {
      await ZapNotePreferencesService.setSharedPhotoSaveToAlbumEnabled(value);
    } else if (key === 'enhanced-link-recognition') {
      await ZapNotePreferencesService.setEnhancedLinkRecognitionEnabled(value);
    }
  }

  private async updatePrivacyProtection(isOn: boolean): Promise<void> {
    this.privacyEnabled = isOn;
    if (!isOn) {
      ZapNoteAntiPeepService.disable();
      await this.saveInterfaceToggle('privacy', false);
      this.showToast('防窥屏保护已关闭', 'info');
      return;
    }

    const enabled: boolean = await this.syncAntiPeepProtection(true);
    this.privacyEnabled = enabled;
    await this.saveInterfaceToggle('privacy', enabled);
    this.showToast(enabled ? '已接入系统防窥保护' : '防窥保护未开启', enabled ? 'success' : 'danger');
  }

  private async syncAntiPeepProtection(requestOptions: boolean): Promise<boolean> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      return await ZapNoteAntiPeepService.enable(context, requestOptions);
    } catch (error) {
      console.error('Index syncAntiPeepProtection failed: ' + JSON.stringify(error));
      return false;
    }
  }

  private async saveInterfaceValue(key: string, value: string): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    if (key === 'engine') {
      await ZapNotePreferencesService.setEngine(value);
    } else if (key === 'photo-style') {
      await ZapNotePreferencesService.setSelectedPhotoStyle(value);
    } else if (key === 'double-touch-action') {
      await ZapNotePreferencesService.setDoubleTouchAction(this.normalizeDoubleTouchAction(value));
    } else if (key === 'shared-photo-save-mode') {
      await ZapNotePreferencesService.setSharedPhotoSaveMode(this.normalizeSharedPhotoSaveMode(value));
    }
  }

  private normalizeDoubleTouchAction(value: string): string {
    return value === 'back' ? 'back' : 'none';
  }

  private normalizeSharedPhotoSaveMode(value: string): string {
    if (value === 'save' || value === 'discard') {
      return value;
    }
    return 'ask';
  }

  private updateCurrentTab(index: number): void {
    if (this.currentTab === index) {
      return;
    }
    this.currentTab = index;
    if (index !== 3) {
      this.changeSettingsPanel('main');
    }
  }

  private handleBackNavigation(): boolean {
    if (this.privacyVaultVisible) {
      if (this.privacyVaultSelectionSheetOpen) {
        this.privacyVaultSelectionSheetOpen = false;
        return true;
      }
      this.closePrivacyVault();
      return true;
    }
    if (this.ocrReviewSheetOpen) {
      this.closeOcrReviewSheet();
      return true;
    }
    if (this.metaPickerSheetOpen) {
      this.closeMetaPickerSheet();
      return true;
    }
    if (this.editorVisible) {
      if (this.editorPhotoPreviewOpen) {
        this.editorPhotoPreviewOpen = false;
        return true;
      }
      this.requestCloseEditor();
      return true;
    }
    if (this.currentTab === 3 && this.settingsPanel !== 'main') {
      this.settingsBackRequestKey++;
      return true;
    }
    if (this.currentTab !== 0) {
      this.updateCurrentTab(0);
      return true;
    }
    return false;
  }

  onBackPress(): boolean {
    return this.handleBackNavigation();
  }

  private isCurrentTab(index: number): boolean {
    return this.currentTab === index;
  }

  private tabIcon(index: number): Resource {
    if (index === 1) {
      if (this.isCurrentTab(index)) {
        return $rawfile('icons/heart_active.svg');
      }
      return this.isDark() ? $rawfile('icons/heart_dark.svg') : $rawfile('icons/heart.svg');
    }
    if (index === 2) {
      if (this.isCurrentTab(index)) {
        return $rawfile('icons/zap_tab_stats_active.svg');
      }
      return this.isDark() ? $rawfile('icons/zap_tab_stats_dark.svg') : $rawfile('icons/zap_tab_stats.svg');
    }
    if (index === 3) {
      if (this.isCurrentTab(index)) {
        return $rawfile('icons/zap_tab_settings_active.svg');
      }
      return this.isDark() ? $rawfile('icons/zap_tab_settings_dark.svg') : $rawfile('icons/zap_tab_settings.svg');
    }
    if (this.isCurrentTab(index)) {
      return $rawfile('icons/zap_tab_home_active.svg');
    }
    return this.isDark() ? $rawfile('icons/zap_tab_home_dark.svg') : $rawfile('icons/zap_tab_home.svg');
  }

  private tabIconColor(index: number): string {
    if (this.isCurrentTab(index)) {
      return this.selectedAccentColor;
    }
    return this.isDark() ? '#CBD5E1' : '#111827';
  }

  private tabMaterialLevel(): hdsMaterial.MaterialLevel {
    if (this.materialEffectMode === 1) {
      return hdsMaterial.MaterialLevel.SMOOTH;
    }
    if (this.materialEffectMode === 2) {
      return hdsMaterial.MaterialLevel.GENTLE;
    }
    return hdsMaterial.MaterialLevel.EXQUISITE;
  }

  @Builder
  private TabIcon(index: number) {
    if (this.isCurrentTab(index)) {
      Image(this.tabIcon(index))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .opacity(1)
    } else {
      Image(this.tabIcon(index))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .opacity(0.76)
    }
  }

  private isDark(): boolean {
    return ZapNoteTheme.isDark(this.effectiveThemeMode());
  }

  private pageBg(): string {
    return ZapNoteTheme.pageBg(this.effectiveThemeMode());
  }

  private cardBg(): string {
    return ZapNoteTheme.cardBg(this.effectiveThemeMode());
  }

  private inputBg(): string {
    return ZapNoteTheme.inputBg(this.effectiveThemeMode());
  }

  private lineColor(): string {
    return ZapNoteTheme.lineColor(this.effectiveThemeMode());
  }

  private textPrimary(): string {
    return ZapNoteTheme.textPrimary(this.effectiveThemeMode());
  }

  private textSecondary(): string {
    return ZapNoteTheme.textSecondary(this.effectiveThemeMode());
  }

  private textTertiary(): string {
    return ZapNoteTheme.textTertiary(this.effectiveThemeMode());
  }

  private effectiveThemeMode(): string {
    if (this.themeMode === 'auto') {
      return this.systemColorMode === 'dark' ? 'dark' : 'light';
    }
    return this.themeMode;
  }

  private topContentPadding(): number {
    return 0;
  }

  private bottomContentPadding(): number {
    return 154;
  }

  private countWords(text: string): number {
    return DiaryStatsUtils.countWords(text);
  }

  private makeDateText(dateMs: number = Date.now()): string {
    return DiaryStatsUtils.formatDateText(dateMs);
  }

  private totalWords(): number {
    return DiaryStatsUtils.totalWords(this.normalDiaries());
  }

  private favoriteCount(): number {
    return DiaryStatsUtils.countFavorites(this.normalDiaries());
  }

  private normalDiaries(): DiaryEntry[] {
    return this.diaries.filter((entry: DiaryEntry): boolean => entry.isPrivate !== true);
  }

  private normalRecycleBinItems(): RecycleBinEntry[] {
    return this.recycleBinItems.filter((entry: RecycleBinEntry): boolean => entry.diary.isPrivate !== true);
  }

  private refreshSettingsContent(): void {
    this.settingsContentRefreshKey++;
  }

  private changeSettingsPanel(panel: SettingPanel, legalPanelSource: string = ''): void {
    const nextLegalPanelSource: string = panel === 'userAgreement' ? legalPanelSource : '';
    if (this.settingsPanel === panel && this.settingsLegalPanelSource === nextLegalPanelSource) {
      return;
    }
    this.settingsPanel = panel;
    this.settingsLegalPanelSource = nextLegalPanelSource;
    this.settingsSubPageRouteKey++;
  }

  private resetDraftState(): void {
    this.editingId = '';
    this.draftTitle = '';
    this.draftBody = '';
    this.draftFolderName = '';
    this.draftDateMs = Date.now();
    this.draftMood = '😊';
    this.draftWeather = '☀️';
    this.draftFavorite = false;
    this.draftHasPhoto = false;
    this.draftPhotoInBody = false;
    this.draftPhotoUri = '';
    this.draftPhotoUris = [];
    this.draftThumbnailPhotoIndex = 0;
    this.draftThumbnailScale = 1;
    this.draftThumbnailOffsetX = 0;
    this.draftThumbnailOffsetY = 0;
    this.draftThumbnailPhotoAspect = 1;
    this.draftPhotoX = 0;
    this.draftPhotoY = 0;
    this.draftPhotoWidth = 156;
    this.draftPhotoHeight = 118;
    this.draftPhotoRotation = 0;
  }

  private resetRuntimeDataState(): void {
    this.searchQuery = '';
    this.diaries = [];
    this.recycleBinItems = [];
    this.diaryFolders = [];
    this.editorVisible = false;
    this.editorPhotoPreviewOpen = false;
    this.resetDraftState();
    this.metaPickerSheetOpen = false;
    this.ocrReviewSheetOpen = false;
    this.ocrReviewKeyboardHeightVp = 0;
    this.ocrReviewText = '';
    this.ocrReviewOriginalText = '';
    this.ocrReviewProcessedText = '';
    this.ocrReviewTitle = '';
    this.ocrReviewProcessedTitle = '';
    this.ocrReviewProcessingMode = '';
    this.ocrReviewShowingOriginal = false;
    this.ocrReviewRuleSummary = '';
    this.ocrReviewRuleMenuOpen = false;
    this.ocrReviewRuleItems = [];
    this.ocrReviewSelectedRuleIds = [];
    this.ocrReviewAppliedRuleIds = [];
    this.ocrReviewRuleSelectionDirty = false;
    this.ocrReviewApplyDialogOpen = false;
    this.ocrReviewRulesApplying = false;
    this.ocrReviewContentEdited = false;
    this.ocrReviewRecognitionResult = null;
    this.ocrReviewAllRuleItems = [];
    this.ocrReviewSessionKey++;
    this.ocrLoadingVisible = false;
    this.ocrLoadingPhase = 'recognizing';
    this.ocrLoadingSessionKey++;
    this.themeMode = 'light';
    this.lightingMode = 'off';
    this.materialEffectMode = this.materialEffectModeForLighting(this.lightingMode);
    this.selectedAccentColor = '#6366F1';
    this.privacyEnabled = true;
    this.gripModeEnabled = false;
    this.autoFillEnabled = true;
    this.engine = 'default';
    this.vibrateEnabled = true;
    this.doubleTouchEnabled = false;
    this.doubleTouchAction = 'none';
    this.sharedPhotoSaveMode = 'ask';
    this.sharedPhotoAutoRecognizeEnabled = false;
    this.sharedPhotoSaveToAlbumEnabled = false;
    this.enhancedLinkRecognitionEnabled = false;
    this.syncInterval = 'off';
    this.syncOnChange = false;
    this.syncMode = 0;
    this.syncTimes = ['08:00', '22:00'];
    this.historyLimit = 10;
    this.syncRestoreStrategy = 'merge';
    this.syncDataScope = 'all';
    this.webdavUrl = '';
    this.webdavUser = '';
    this.webdavPass = '';
    this.webdavRemotePath = ZapNotePreferencesService.DEFAULT_WEBDAV_REMOTE_PATH;
    this.selectedPhotoStyle = 'original';
    this.backupPreview = '软件数据已清除。本机笔记、规则、AI 服务商、WebDAV 配置和偏好已恢复默认。';
    this.syncLogs = [];
    this.syncLogRefreshKey++;
    this.huaweiAccountOpenId = '';
    this.huaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
    this.sharedPhotoUri = '';
    this.sharedPhotoError = '';
    this.applyThemeColorMode(this.themeMode);
    this.statsContentRefreshKey++;
    this.refreshSettingsContent();
  }

  private async clearAllAppData(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      this.showToast('清除失败，请稍后重试', 'danger');
      return;
    }
    this.stopSyncTimers();
    ZapNoteAntiPeepService.disable();
    const context: common.Context = getContext(this) as common.Context;
    const localCleared: boolean = ZapNoteDiaryStorageService.clearAllLocalData(context);
    const preferencesCleared: boolean = await ZapNotePreferencesService.clearAllAppData();
    this.resetRuntimeDataState();
    if (localCleared && preferencesCleared) {
      this.showToast('软件数据已清除', 'danger');
      return;
    }
    this.showToast('核心数据已清除，部分本地文件可能需要重试', 'danger');
  }

  private backupTimeLine(backupTimeText: string): string {
    return backupTimeText.length > 0 ? '\n备份时间：' + backupTimeText : '';
  }

  private normalizeFolderName(value: string): string {
    return value.trim().replace(/\s+/g, ' ');
  }

  private addFolderName(result: string[], value: string): void {
    const folderName: string = this.normalizeFolderName(value);
    if (folderName.length > 0 && result.indexOf(folderName) < 0) {
      result.push(folderName);
    }
  }

  private mergeFolderNames(baseFolders: string[]): string[] {
    const result: string[] = [];
    baseFolders.forEach((folderName: string) => {
      const normalizedFolder: string = this.normalizeFolderName(folderName);
      const hasNormalDiary: boolean = this.diaries.some((entry: DiaryEntry): boolean => {
        return entry.isPrivate !== true &&
          this.normalizeFolderName(typeof entry.folderName === 'string' ? entry.folderName : '') === normalizedFolder;
      });
      if (hasNormalDiary) {
        this.addFolderName(result, folderName);
      }
    });
    this.diaries.forEach((entry: DiaryEntry) => {
      if (entry.isPrivate !== true) {
        this.addFolderName(result, typeof entry.folderName === 'string' ? entry.folderName : '');
      }
    });
    let draftIsPrivate: boolean = false;
    if (this.editingId.length > 0) {
      const editingMatches: DiaryEntry[] = this.diaries.filter((entry: DiaryEntry): boolean => {
        return entry.id === this.editingId;
      });
      draftIsPrivate = editingMatches.length > 0 && editingMatches[0].isPrivate === true;
    }
    if (!draftIsPrivate) {
      this.addFolderName(result, this.draftFolderName);
    }
    return result;
  }

  private savedFolderOptions(): string[] {
    const result: string[] = [];
    this.diaryFolders.forEach((folderName: string) => {
      this.addFolderName(result, folderName);
    });
    this.diaries.forEach((entry: DiaryEntry) => {
      if (entry.isPrivate !== true) {
        this.addFolderName(result, typeof entry.folderName === 'string' ? entry.folderName : '');
      }
    });
    return result;
  }

  private folderOptions(): string[] {
    return this.mergeFolderNames(this.diaryFolders);
  }

  private normalizePhotoUris(value: string[] | undefined): string[] {
    const result: string[] = [];
    if (!Array.isArray(value)) {
      return result;
    }
    value.forEach((item: string) => {
      const uri: string = typeof item === 'string' ? item.trim() : '';
      if (uri.length > 0 && result.indexOf(uri) < 0) {
        result.push(uri);
      }
    });
    return result;
  }

  private resolveDiaryPhotoUris(entry: DiaryEntry): string[] {
    if (Array.isArray(entry.photoUris)) {
      const photoUris: string[] = this.normalizePhotoUris(entry.photoUris);
      if (photoUris.length > 0) {
        return photoUris;
      }
    }
    const photoUri: string = typeof entry.photoUri === 'string' ? entry.photoUri.trim() : '';
    return photoUri.length > 0 ? [photoUri] : [];
  }

  private photoUrisKey(value: string[]): string {
    return this.normalizePhotoUris(value).join('\u001f');
  }

  private hasDraftPhotoAssets(): boolean {
    return this.normalizePhotoUris(this.draftPhotoUris).length > 0 || this.draftPhotoUri.trim().length > 0;
  }

  private async persistPhotoForDiary(photoUri: string): Promise<string> {
    const value: string = photoUri.trim();
    if (value.length === 0) {
      return '';
    }
    try {
      const context = getContext(this) as common.Context;
      return await ZapNoteBackupService.copyPhotoToAppFiles(context, value);
    } catch (error) {
      console.error('Index persistPhotoForDiary failed: ' + JSON.stringify(error));
      return value;
    }
  }

  private cloneEntry(entry: DiaryEntry): DiaryEntry {
    const photoUri: string = typeof entry.photoUri === 'string' ? entry.photoUri : '';
    const photoUris: string[] = this.resolveDiaryPhotoUris(entry);
    return {
      id: entry.id,
      title: entry.title,
      body: entry.body,
      folderName: typeof entry.folderName === 'string' ? entry.folderName : '',
      dateText: entry.dateText,
      dateMs: entry.dateMs,
      createdAt: typeof entry.createdAt === 'number' && entry.createdAt > 0 ? entry.createdAt : entry.dateMs,
      updatedAt: typeof entry.updatedAt === 'number' && entry.updatedAt > 0 ? entry.updatedAt : entry.dateMs,
      mood: entry.mood,
      weather: entry.weather,
      isToday: entry.isToday,
      isThisWeek: entry.isThisWeek,
      isFavorite: entry.isFavorite,
      isPrivate: entry.isPrivate === true,
      wordCount: entry.wordCount,
      hasPhoto: entry.hasPhoto || photoUri.length > 0 || photoUris.length > 0,
      photoInBody: typeof entry.photoInBody === 'boolean' ? entry.photoInBody : false,
      photoUri: photoUri,
      photoUris: photoUris,
      thumbnailPhotoIndex: typeof entry.thumbnailPhotoIndex === 'number' ?
        Math.max(0, Math.min(Math.floor(entry.thumbnailPhotoIndex), Math.max(photoUris.length - 1, 0))) : 0,
      thumbnailScale: typeof entry.thumbnailScale === 'number' ?
        Math.max(1, Math.min(entry.thumbnailScale, 4)) : 1,
      thumbnailOffsetX: typeof entry.thumbnailOffsetX === 'number' ? entry.thumbnailOffsetX : 0,
      thumbnailOffsetY: typeof entry.thumbnailOffsetY === 'number' ? entry.thumbnailOffsetY : 0,
      thumbnailPhotoAspect: typeof entry.thumbnailPhotoAspect === 'number' && entry.thumbnailPhotoAspect > 0 ?
        entry.thumbnailPhotoAspect : 1,
      photoX: typeof entry.photoX === 'number' ? entry.photoX : 0,
      photoY: typeof entry.photoY === 'number' ? entry.photoY : 0,
      photoWidth: typeof entry.photoWidth === 'number' ? entry.photoWidth : 156,
      photoHeight: typeof entry.photoHeight === 'number' ? entry.photoHeight : 118,
      photoRotation: typeof entry.photoRotation === 'number' ? entry.photoRotation : 0,
      photoStyle: entry.photoStyle
    };
  }

  private mergeDiaries(localDiaries: DiaryEntry[], cloudDiaries: DiaryEntry[]): DiaryEntry[] {
    const result: DiaryEntry[] = [];
    const localIds: string[] = [];
    localDiaries.forEach((entry: DiaryEntry) => {
      result.push(this.cloneEntry(entry));
      localIds.push(entry.id);
    });
    cloudDiaries.forEach((entry: DiaryEntry) => {
      if (localIds.indexOf(entry.id) < 0) {
        result.push(this.cloneEntry(entry));
      }
    });
    return DiaryStatsUtils.sortDiariesByLatest(result);
  }

  private normalizeSyncDataScope(scope: SyncDataScope): SyncDataScope {
    if (scope === 'diaries' || scope === 'settings') {
      return scope;
    }
    return 'all';
  }

  private syncDataScopeLabel(scope: SyncDataScope = this.syncDataScope): string {
    if (scope === 'diaries') {
      return '笔记数据';
    }
    if (scope === 'settings') {
      return '软件设置';
    }
    return '笔记数据和软件设置';
  }

  private syncIncludesDiaries(scope: SyncDataScope = this.syncDataScope): boolean {
    return scope === 'diaries' || scope === 'all';
  }

  private syncIncludesSettings(scope: SyncDataScope = this.syncDataScope): boolean {
    return scope === 'settings' || scope === 'all';
  }

  private async currentBackupSettings(): Promise<ZapNoteBackupSettings> {
    let matchRuleItems: MatchRuleTemplateItem[] = [];
    const savedMatchRuleItems: MatchRuleTemplateItem[] | null = await ZapNotePreferencesService.getMatchRuleItems();
    if (savedMatchRuleItems !== null) {
      matchRuleItems = savedMatchRuleItems;
    }
    const aiConfigs: AiVisualEngineConfig[] = await ZapNotePreferencesService.getAiVisualEngineConfigs();
    const aiBackupConfigs: AiVisualEngineBackupConfig[] = [];
    for (let index: number = 0; index < aiConfigs.length; index++) {
      const config: AiVisualEngineConfig = aiConfigs[index];
      aiBackupConfigs.push({
        id: config.id,
        providerName: config.providerName,
        provider: config.provider,
        baseUrl: config.baseUrl,
        model: config.model,
        outputContent: config.outputContent
      });
    }
    const aiConfig: AiVisualEngineConfig = aiConfigs.length > 0 ? aiConfigs[0] :
      await ZapNotePreferencesService.getAiVisualEngineConfig();
    return {
      themeMode: this.themeMode,
      lightingMode: this.lightingMode,
      selectedAccentColor: this.selectedAccentColor,
      gripModeEnabled: this.gripModeEnabled,
      privacyEnabled: this.privacyEnabled,
      autoFillEnabled: this.autoFillEnabled,
      vibrateEnabled: this.vibrateEnabled,
      doubleTouchEnabled: this.doubleTouchEnabled,
      doubleTouchAction: this.doubleTouchAction,
      sharedPhotoSaveMode: this.sharedPhotoSaveMode,
      sharedPhotoAutoRecognizeEnabled: this.sharedPhotoAutoRecognizeEnabled,
      sharedPhotoSaveToAlbumEnabled: this.sharedPhotoSaveToAlbumEnabled,
      enhancedLinkRecognitionEnabled: this.enhancedLinkRecognitionEnabled,
      engine: this.engine,
      aiVisualProviderName: aiConfig.providerName,
      aiVisualProvider: aiConfig.provider,
      aiVisualBaseUrl: aiConfig.baseUrl,
      aiVisualModel: aiConfig.model,
      aiVisualOutputContent: aiConfig.outputContent,
      aiVisualConfigs: aiBackupConfigs,
      selectedPhotoStyle: this.selectedPhotoStyle,
      syncInterval: this.syncInterval,
      syncOnChange: this.syncOnChange,
      syncMode: this.syncMode,
      syncTimes: this.syncTimes,
      historyLimit: this.historyLimit,
      syncRestoreStrategy: this.syncRestoreStrategy,
      syncDataScope: this.syncDataScope,
      webdavUrl: this.webdavUrl,
      webdavUser: this.webdavUser,
      webdavRemotePath: this.webdavRemotePath,
      matchRuleItems: matchRuleItems
    };
  }

  private async applyBackupSettings(settings: ZapNoteBackupSettings): Promise<number> {
    let restoredCount: number = 0;
    if (!await this.ensurePreferencesReady()) {
      return restoredCount;
    }
    if (typeof settings.themeMode === 'string') {
      this.themeMode = settings.themeMode;
      this.applyThemeColorMode(settings.themeMode);
      await ZapNotePreferencesService.setThemeMode(settings.themeMode);
      restoredCount++;
    }
    if (typeof settings.lightingMode === 'string') {
      this.lightingMode = settings.lightingMode;
      this.materialEffectMode = this.materialEffectModeForLighting(settings.lightingMode);
      await ZapNotePreferencesService.setLightingMode(settings.lightingMode);
      restoredCount++;
    }
    if (typeof settings.selectedAccentColor === 'string') {
      this.selectedAccentColor = settings.selectedAccentColor;
      await ZapNotePreferencesService.setSelectedAccentColor(settings.selectedAccentColor);
      restoredCount++;
    }
    if (typeof settings.gripModeEnabled === 'boolean') {
      this.gripModeEnabled = settings.gripModeEnabled;
      await ZapNotePreferencesService.setGripModeEnabled(settings.gripModeEnabled);
      restoredCount++;
    }
    if (typeof settings.privacyEnabled === 'boolean') {
      this.privacyEnabled = settings.privacyEnabled;
      if (settings.privacyEnabled) {
        await this.syncAntiPeepProtection(false);
      } else {
        ZapNoteAntiPeepService.disable();
      }
      await ZapNotePreferencesService.setPrivacyEnabled(settings.privacyEnabled);
      restoredCount++;
    }
    if (typeof settings.autoFillEnabled === 'boolean') {
      this.autoFillEnabled = settings.autoFillEnabled;
      await ZapNotePreferencesService.setAutoFillEnabled(settings.autoFillEnabled);
      restoredCount++;
    }
    if (typeof settings.vibrateEnabled === 'boolean') {
      this.vibrateEnabled = settings.vibrateEnabled;
      await ZapNotePreferencesService.setVibrateEnabled(settings.vibrateEnabled);
      restoredCount++;
    }
    if (typeof settings.doubleTouchEnabled === 'boolean') {
      this.doubleTouchEnabled = settings.doubleTouchEnabled;
      await ZapNotePreferencesService.setDoubleTouchEnabled(settings.doubleTouchEnabled);
      restoredCount++;
    }
    if (typeof settings.doubleTouchAction === 'string') {
      this.doubleTouchAction = this.normalizeDoubleTouchAction(settings.doubleTouchAction);
      await ZapNotePreferencesService.setDoubleTouchAction(this.doubleTouchAction);
      restoredCount++;
    }
    if (typeof settings.sharedPhotoSaveMode === 'string') {
      this.sharedPhotoSaveMode = this.normalizeSharedPhotoSaveMode(settings.sharedPhotoSaveMode);
      await ZapNotePreferencesService.setSharedPhotoSaveMode(this.sharedPhotoSaveMode);
      restoredCount++;
    }
    if (typeof settings.sharedPhotoAutoRecognizeEnabled === 'boolean') {
      this.sharedPhotoAutoRecognizeEnabled = settings.sharedPhotoAutoRecognizeEnabled;
      await ZapNotePreferencesService.setSharedPhotoAutoRecognizeEnabled(this.sharedPhotoAutoRecognizeEnabled);
      restoredCount++;
    }
    if (typeof settings.sharedPhotoSaveToAlbumEnabled === 'boolean') {
      this.sharedPhotoSaveToAlbumEnabled = settings.sharedPhotoSaveToAlbumEnabled;
      await ZapNotePreferencesService.setSharedPhotoSaveToAlbumEnabled(this.sharedPhotoSaveToAlbumEnabled);
      restoredCount++;
    }
    if (typeof settings.enhancedLinkRecognitionEnabled === 'boolean') {
      this.enhancedLinkRecognitionEnabled = settings.enhancedLinkRecognitionEnabled;
      await ZapNotePreferencesService.setEnhancedLinkRecognitionEnabled(this.enhancedLinkRecognitionEnabled);
      restoredCount++;
    }
    if (Array.isArray(settings.aiVisualConfigs)) {
      for (let index: number = 0; index < settings.aiVisualConfigs.length; index++) {
        const backupConfig: AiVisualEngineBackupConfig = settings.aiVisualConfigs[index];
        const currentConfig: AiVisualEngineConfig =
          await ZapNotePreferencesService.getAiVisualEngineConfig(backupConfig.id);
        await ZapNotePreferencesService.setAiVisualEngineConfig({
          id: backupConfig.id,
          providerName: backupConfig.providerName,
          provider: backupConfig.provider,
          baseUrl: backupConfig.baseUrl,
          model: backupConfig.model,
          apiKey: currentConfig.apiKey,
          outputContent: backupConfig.outputContent
        });
      }
      restoredCount++;
    } else if (typeof settings.aiVisualProviderName === 'string' || typeof settings.aiVisualProvider === 'string' ||
      typeof settings.aiVisualBaseUrl === 'string' ||
      typeof settings.aiVisualModel === 'string' || typeof settings.aiVisualOutputContent === 'string') {
      const currentAiConfig: AiVisualEngineConfig = await ZapNotePreferencesService.getAiVisualEngineConfig();
      await ZapNotePreferencesService.setAiVisualEngineConfig({
        id: currentAiConfig.id.length > 0 ? currentAiConfig.id : 'legacy',
        providerName: typeof settings.aiVisualProviderName === 'string' ?
          settings.aiVisualProviderName : currentAiConfig.providerName,
        provider: typeof settings.aiVisualProvider === 'string' ? settings.aiVisualProvider : currentAiConfig.provider,
        baseUrl: typeof settings.aiVisualBaseUrl === 'string' ? settings.aiVisualBaseUrl : currentAiConfig.baseUrl,
        model: typeof settings.aiVisualModel === 'string' ? settings.aiVisualModel : currentAiConfig.model,
        apiKey: currentAiConfig.apiKey,
        outputContent: typeof settings.aiVisualOutputContent === 'string' ?
          settings.aiVisualOutputContent : currentAiConfig.outputContent
      });
      restoredCount++;
    }
    if (typeof settings.engine === 'string') {
      const requestedEngine: string = settings.engine;
      const requestedId: string = requestedEngine.startsWith('custom:') ?
        requestedEngine.substring('custom:'.length) : '';
      const restoredAiConfig: AiVisualEngineConfig =
        await ZapNotePreferencesService.getAiVisualEngineConfig(requestedId);
      this.engine = (requestedEngine === 'custom' || requestedEngine.startsWith('custom:')) &&
        restoredAiConfig.apiKey.trim().length > 0 ? 'custom:' + restoredAiConfig.id : 'default';
      await ZapNotePreferencesService.setEngine(this.engine);
      restoredCount++;
    }
    if (typeof settings.selectedPhotoStyle === 'string') {
      this.selectedPhotoStyle = settings.selectedPhotoStyle;
      await ZapNotePreferencesService.setSelectedPhotoStyle(settings.selectedPhotoStyle);
      restoredCount++;
    }
    if (typeof settings.syncInterval === 'string') {
      this.syncInterval = settings.syncInterval;
      await ZapNotePreferencesService.setSyncInterval(settings.syncInterval);
      restoredCount++;
    }
    if (typeof settings.syncOnChange === 'boolean') {
      this.syncOnChange = settings.syncOnChange;
      await ZapNotePreferencesService.setSyncOnChange(settings.syncOnChange);
      restoredCount++;
    }
    if (typeof settings.syncMode === 'number') {
      this.syncMode = settings.syncMode === 1 ? 1 : 0;
      await ZapNotePreferencesService.setWebDavSyncMode(this.syncMode);
      restoredCount++;
    }
    if (Array.isArray(settings.syncTimes)) {
      this.syncTimes = [...settings.syncTimes].sort();
      await ZapNotePreferencesService.setWebDavSyncTimes(this.syncTimes);
      restoredCount++;
    }
    if (typeof settings.historyLimit === 'number') {
      this.historyLimit = settings.historyLimit === 30 || settings.historyLimit === 100 ? settings.historyLimit : 10;
      await ZapNotePreferencesService.setWebDavHistoryLimit(this.historyLimit);
      restoredCount++;
    }
    if (typeof settings.syncRestoreStrategy === 'string') {
      this.syncRestoreStrategy = settings.syncRestoreStrategy === 'overwrite' ? 'overwrite' : 'merge';
      await ZapNotePreferencesService.setWebDavRestoreStrategy(this.syncRestoreStrategy);
      restoredCount++;
    }
    if (settings.syncDataScope === 'diaries' || settings.syncDataScope === 'settings' || settings.syncDataScope === 'all') {
      this.syncDataScope = settings.syncDataScope;
      await ZapNotePreferencesService.setWebDavSyncDataScope(settings.syncDataScope);
      restoredCount++;
    }
    if (typeof settings.webdavUrl === 'string') {
      this.webdavUrl = settings.webdavUrl;
      await ZapNotePreferencesService.setWebDavServerUrl(settings.webdavUrl);
      restoredCount++;
    }
    if (typeof settings.webdavUser === 'string') {
      this.webdavUser = settings.webdavUser;
      await ZapNotePreferencesService.setWebDavUsername(settings.webdavUser);
      restoredCount++;
    }
    if (typeof settings.webdavPass === 'string') {
      this.webdavPass = settings.webdavPass;
      await ZapNotePreferencesService.setWebDavPassword(settings.webdavPass);
      restoredCount++;
    }
    if (typeof settings.webdavRemotePath === 'string') {
      const restoredPath: string = this.normalizeRemotePath(settings.webdavRemotePath);
      this.webdavRemotePath = restoredPath.length > 0 ? restoredPath : ZapNotePreferencesService.DEFAULT_WEBDAV_REMOTE_PATH;
      await ZapNotePreferencesService.setWebDavRemotePath(this.webdavRemotePath);
      restoredCount++;
    }
    if (Array.isArray(settings.matchRuleItems)) {
      await ZapNotePreferencesService.setMatchRuleItems(settings.matchRuleItems);
      restoredCount++;
    }
    return restoredCount;
  }

  private showToast(message: string, _type: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({
        message: message,
        duration: 2000
      });
    } catch (error) {
      console.error('showToast failed: ' + JSON.stringify(error));
    }
  }

  private askConfirm(action: string, title: string, message: string, targetId: string = ''): void {
    this.pendingConfirmId = targetId;
    const isDanger = action === 'delete-diary' || action === 'delete-private-diary' ||
      action === 'clear-data' || action === 'clear-app-data';
    const confirmText: string = action === 'clear-app-data' ? '清除' : isDanger ? '确认' : '确定';
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: title,
        message: message,
        buttons: [
          { text: '取消', color: this.textSecondary() },
          { text: confirmText, color: isDanger ? '#EF4444' : this.selectedAccentColor }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.runConfirm(action);
        }
      }).catch(() => {});
    } catch (error) {
      console.error('showDialog failed: ' + JSON.stringify(error));
    }
  }

  private isDraftEmpty(): boolean {
    return this.draftTitle.trim().length === 0 && this.draftBody.trim().length === 0 && !this.hasDraftPhotoAssets();
  }

  private hasUnsavedDraftChanges(): boolean {
    if (this.editingId.length === 0) {
      return !this.isDraftEmpty();
    }
    const matches: DiaryEntry[] = this.diaries.filter((entry: DiaryEntry): boolean => entry.id === this.editingId);
    if (matches.length === 0) {
      return !this.isDraftEmpty();
    }
    const entry: DiaryEntry = matches[0];
    const comparableTitle: string = this.draftTitle.trim().length > 0 ? this.draftTitle.trim() : this.defaultDiaryTitle();
    return comparableTitle !== entry.title ||
      this.draftBody.trim() !== entry.body ||
      this.draftFolderName !== (typeof entry.folderName === 'string' ? entry.folderName : '') ||
      this.draftMood !== entry.mood ||
      this.draftWeather !== entry.weather ||
      this.draftFavorite !== entry.isFavorite ||
      this.hasDraftPhotoAssets() !== (entry.hasPhoto || this.resolveDiaryPhotoUris(entry).length > 0 || (typeof entry.photoUri === 'string' && entry.photoUri.length > 0)) ||
      this.draftPhotoInBody !== (typeof entry.photoInBody === 'boolean' ? entry.photoInBody : false) ||
      this.photoUrisKey(this.draftPhotoUris) !== this.photoUrisKey(this.resolveDiaryPhotoUris(entry)) ||
      this.draftThumbnailPhotoIndex !== (typeof entry.thumbnailPhotoIndex === 'number' ?
        Math.max(0, Math.min(Math.floor(entry.thumbnailPhotoIndex),
          Math.max(this.resolveDiaryPhotoUris(entry).length - 1, 0))) : 0) ||
      this.draftThumbnailScale !== (typeof entry.thumbnailScale === 'number' ? entry.thumbnailScale : 1) ||
      this.draftThumbnailOffsetX !== (typeof entry.thumbnailOffsetX === 'number' ? entry.thumbnailOffsetX : 0) ||
      this.draftThumbnailOffsetY !== (typeof entry.thumbnailOffsetY === 'number' ? entry.thumbnailOffsetY : 0) ||
      this.draftThumbnailPhotoAspect !== (typeof entry.thumbnailPhotoAspect === 'number' ?
        entry.thumbnailPhotoAspect : 1) ||
      this.draftPhotoUri !== (typeof entry.photoUri === 'string' ? entry.photoUri : '') ||
      this.draftPhotoX !== entry.photoX ||
      this.draftPhotoY !== entry.photoY ||
      this.draftPhotoWidth !== entry.photoWidth ||
      this.draftPhotoHeight !== entry.photoHeight ||
      this.draftPhotoRotation !== entry.photoRotation ||
      this.selectedPhotoStyle !== entry.photoStyle;
  }

  private requestCloseEditor(): void {
    if (!this.hasUnsavedDraftChanges()) {
      this.editorPhotoPreviewOpen = false;
      this.editorVisible = false;
      return;
    }
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: this.draftExitTitle(),
        message: this.draftExitSummary() + '返回后未保存内容会丢失，是否保存？',
        buttons: [
          { text: '不保存', color: '#EF4444' },
          { text: '继续编辑', color: this.textSecondary() },
          { text: '保存', color: this.selectedAccentColor, primary: true }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 0) {
          this.editorPhotoPreviewOpen = false;
          this.editorVisible = false;
        } else if (result.index === 2) {
          this.saveDiary().then((saved: boolean): void => {
            if (!saved) {
              return;
            }
            this.editorPhotoPreviewOpen = false;
            this.editorVisible = false;
          }).catch((error: BusinessErrorLike) => {
            console.error('requestCloseEditor saveDiary failed: ' + JSON.stringify(error));
            this.showToast('保存失败，请稍后重试', 'danger');
          });
        }
      }).catch(() => {});
    } catch (error) {
      console.error('requestCloseEditor showDialog failed: ' + JSON.stringify(error));
      this.showToast('当前内容还没有保存', 'info');
    }
  }

  private draftExitTitle(): string {
    return this.editingId.length > 0 ? '修改还未保存' : '新笔记还未保存';
  }

  private draftExitSummary(): string {
    const wordCount: number = this.countWords(this.draftBody);
    let summary: string = wordCount > 0 ? '已写 ' + wordCount.toString() + ' 字' : '正文暂为空';
    if (this.draftTitle.trim().length > 0) {
      summary += '，已有标题';
    }
    if (this.hasDraftPhotoAssets()) {
      summary += '，包含照片';
    }
    return summary + '。';
  }

  private runConfirm(action: string): void {
    if (action === 'delete-diary') {
      this.deleteDiary(this.editingId);
    } else if (action === 'delete-private-diary') {
      this.permanentlyDeletePrivateDiary(this.pendingConfirmId);
      this.pendingConfirmId = '';
    } else if (action === 'clear-data') {
      this.moveAllDiariesToRecycleBin();
    } else if (action === 'clear-app-data') {
      this.clearAllAppData();
    } else if (action === 'import-backup') {
      this.importBackup();
    }
  }

  private openPicker(type: string, title: string): void {
    if (type === 'mood' || type === 'weather') {
      this.openMetaPickerSheet(type);
      return;
    }
    this.pickerType = type;
    const options = this.pickerOptions();
    if (options.length === 0) {
      return;
    }
    try {
      this.getUIContext().getPromptAction().showActionMenu({
        title: title,
        buttons: this.pickerActionButtons(options)
      }).then((result: promptAction.ActionMenuSuccessResponse) => {
        const selected = options[result.index];
        if (selected) {
          this.chooseValue(selected.value);
        }
      }).catch(() => {});
    } catch (error) {
      console.error('showActionMenu failed: ' + JSON.stringify(error));
    }
  }

  private openMetaPickerSheet(type: string): void {
    this.ocrReviewSheetOpen = false;
    this.ocrReviewKeyboardHeightVp = 0;
    this.metaPickerType = type === 'weather' ? 'weather' : 'mood';
    this.pickerType = this.metaPickerType;
    this.metaPickerSheetOpen = true;
  }

  private closeMetaPickerSheet(): void {
    this.metaPickerSheetOpen = false;
  }

  private ocrResultWithText(result: OcrTextRecognitionResult, text: string): OcrTextRecognitionResult {
    return {
      text: text,
      photoUri: result.photoUri,
      blocks: []
    };
  }

  private mergeOcrText(primary: string, linksText: string): string {
    const first: string = primary.trim();
    const second: string = linksText.trim();
    if (first.length === 0) {
      return second;
    }
    if (second.length === 0) {
      return first;
    }
    return first + '\n' + second;
  }

  private aiProcessingResult(originalText: string, aiResult: AiVisualParseResult): OcrRuleProcessingResult {
    if (aiResult.success) {
      return {
        originalText: originalText.trim(),
        processedText: aiResult.content.trim(),
        suggestedTitle: aiResult.title.trim(),
        activeRuleCount: 1,
        matchedRuleCount: 1,
        summaries: ['AI 已按输出要求整理'],
        changed: aiResult.title.trim().length > 0 || aiResult.content.trim() !== originalText.trim(),
        processingMode: 'ai',
        statusMessage: aiResult.message
      };
    }
    return {
      originalText: originalText.trim(),
      processedText: originalText.trim(),
      activeRuleCount: 1,
      matchedRuleCount: 0,
      summaries: [],
      changed: false,
      processingMode: 'ai-error',
      statusMessage: aiResult.message
    };
  }

  private localLinkProcessingResult(result: OcrTextRecognitionResult, intent: LinkIntent,
    extraction: LinkExtractionResult, items: MatchRuleTemplateItem[]): OcrRuleProcessingResult {
    const remainingRules: MatchRuleTemplateItem[] = LinkRecognitionService.rulesWithoutLinkIntent(items);
    const otherResult: OcrRuleProcessingResult = OcrRuleProcessingService.process(
      this.ocrResultWithText(result, extraction.remainingText), remainingRules);
    const linkOnly: boolean = intent.linkOnly || intent.mode === 'specific';
    const nonLinkText: string = linkOnly ? '' :
      (otherResult.matchedRuleCount > 0 ? otherResult.processedText : extraction.remainingText);
    const processedText: string = this.mergeOcrText(nonLinkText, extraction.linksText);
    return {
      originalText: result.text.trim(),
      processedText: processedText,
      activeRuleCount: otherResult.activeRuleCount + 1,
      matchedRuleCount: otherResult.matchedRuleCount + 1,
      summaries: otherResult.summaries.concat(['链接已由默认引擎识别']),
      changed: processedText !== result.text.trim(),
      processingMode: 'link',
      statusMessage: '链接已由默认引擎识别'
    };
  }

  private async processOcrResult(result: OcrTextRecognitionResult,
    overrideItems?: MatchRuleTemplateItem[]): Promise<OcrRuleProcessingResult> {
    let items: MatchRuleTemplateItem[] = [];
    if (overrideItems !== undefined) {
      items = overrideItems;
    } else {
      const savedItems: MatchRuleTemplateItem[] | null = await ZapNotePreferencesService.getMatchRuleItems();
      if (savedItems !== null) {
        items = savedItems;
      }
    }
    const customEngineSelected: boolean = this.engine === 'custom' || this.engine.startsWith('custom:');
    if (customEngineSelected) {
      const configId: string = this.engine.startsWith('custom:') ?
        this.engine.substring('custom:'.length) : '';
      const config: AiVisualEngineConfig = await ZapNotePreferencesService.getAiVisualEngineConfig(configId);
      config.outputContent = AiVisualParsingService.resolveOutputContent(items, config.id, config.outputContent);
      const intent: LinkIntent = LinkRecognitionService.resolveIntent(
        items, true, config.id, config.outputContent);
      // Link extraction is an opt-in enhancement for custom engines. Without
      // the switch, the configured AI receives the complete OCR text.
      const shouldSplitLinks: boolean = this.enhancedLinkRecognitionEnabled &&
        (intent.mode === 'specific' || intent.mode === 'all');
      if (shouldSplitLinks) {
        const extraction: LinkExtractionResult = LinkRecognitionService.extract(
          result.text, intent.types, intent.template);
        if (extraction.matches.length > 0) {
          this.showToast('正在使用默认引擎识别链接', 'info');
          // A specific link request (for example “磁力链接”) means the
          // confirmation result must contain only the requested links.
          const linkOnly: boolean = intent.linkOnly || intent.mode === 'specific';
          if (linkOnly || extraction.remainingText.length === 0) {
            return {
              originalText: result.text.trim(),
              processedText: extraction.linksText,
              activeRuleCount: 1,
              matchedRuleCount: 1,
              summaries: ['链接已由默认引擎识别'],
              changed: extraction.linksText !== result.text.trim(),
              processingMode: 'link',
              statusMessage: '链接已由默认引擎识别'
            };
          }
          this.showToast('正在使用 AI 整理其他内容', 'info');
          const splitAiResult: AiVisualParseResult =
            await AiVisualParsingService.parseOcrText(extraction.remainingText, config);
          if (splitAiResult.success) {
            const processedText: string = this.mergeOcrText(splitAiResult.content, extraction.linksText);
            return {
              originalText: result.text.trim(),
              processedText: processedText,
              suggestedTitle: splitAiResult.title.trim(),
              activeRuleCount: 2,
              matchedRuleCount: 2,
              summaries: ['AI 已整理其他内容', '链接已由默认引擎识别'],
              changed: splitAiResult.title.trim().length > 0 || processedText !== result.text.trim(),
              processingMode: 'ai-link',
              statusMessage: 'AI 已整理其他内容，链接已由默认引擎识别'
            };
          }
          const fallbackText: string = this.mergeOcrText(extraction.remainingText, extraction.linksText);
          return {
            originalText: result.text.trim(),
            processedText: fallbackText,
            activeRuleCount: 2,
            matchedRuleCount: 1,
            summaries: ['链接已由默认引擎识别'],
            changed: fallbackText !== result.text.trim(),
            processingMode: 'ai-link-error',
            statusMessage: splitAiResult.message
          };
        }
        if (intent.mode === 'specific' && intent.linkOnly) {
          return {
            originalText: result.text.trim(),
            processedText: result.text.trim(),
            activeRuleCount: 1,
            matchedRuleCount: 0,
            summaries: [],
            changed: false,
            processingMode: 'link',
            statusMessage: '未识别到指定类型的链接'
          };
        }
      }
      this.showToast('正在使用 AI 整理识别内容', 'info');
      const aiResult: AiVisualParseResult = await AiVisualParsingService.parseOcrText(result.text, config);
      return this.aiProcessingResult(result.text, aiResult);
    }
    let intent: LinkIntent = LinkRecognitionService.resolveIntent(items);
    if (intent.mode === 'none') {
      // Older saved rules may not have a photo scope or persisted linkType,
      // even though the user explicitly entered “磁力链接”. Keep the default
      // engine useful by honoring that keyword as a local magnet intent.
      for (let index: number = 0; index < items.length; index++) {
        const item: MatchRuleTemplateItem = items[index];
        if (!item.enabled || item.kind !== 'keyword') {
          continue;
        }
        const inferred: LinkType[] = LinkRecognitionService.inferTypes(item.keyword + '\n' + item.template);
        if (inferred.indexOf('magnet') >= 0) {
          intent = {
            mode: 'specific',
            types: ['magnet'],
            linkOnly: true,
            template: item.template.trim()
          };
          break;
        }
      }
    }
    if (intent.mode !== 'none') {
      const extraction: LinkExtractionResult = LinkRecognitionService.extract(result.text, intent.types, intent.template);
      if (extraction.matches.length > 0) {
        this.showToast('正在使用默认引擎识别链接', 'info');
        return this.localLinkProcessingResult(result, intent, extraction, items);
      }
      const otherResult: OcrRuleProcessingResult = OcrRuleProcessingService.process(
        result, LinkRecognitionService.rulesWithoutLinkIntent(items));
      if (otherResult.matchedRuleCount > 0) {
        return {
          originalText: otherResult.originalText,
          processedText: otherResult.processedText,
          suggestedTitle: otherResult.suggestedTitle,
          activeRuleCount: otherResult.activeRuleCount + 1,
          matchedRuleCount: otherResult.matchedRuleCount,
          summaries: otherResult.summaries,
          changed: otherResult.changed,
          processingMode: otherResult.processingMode,
          statusMessage: otherResult.statusMessage
        };
      }
      return {
        originalText: result.text.trim(),
        processedText: result.text.trim(),
        activeRuleCount: 1,
        matchedRuleCount: 0,
        summaries: [],
        changed: false,
        processingMode: 'link',
        statusMessage: '未识别到符合规则的链接'
      };
    }
    return OcrRuleProcessingService.process(result, items);
  }

  private beginOcrLoading(): number {
    const sessionKey: number = ++this.ocrLoadingSessionKey;
    this.ocrLoadingPhase = 'recognizing';
    this.ocrLoadingVisible = true;
    return sessionKey;
  }

  private updateOcrLoadingPhase(sessionKey: number, phase: string): void {
    if (sessionKey <= 0 || sessionKey !== this.ocrLoadingSessionKey || !this.ocrLoadingVisible) {
      return;
    }
    this.ocrLoadingPhase = phase;
  }

  private finishOcrLoading(sessionKey: number): void {
    if (sessionKey <= 0 || sessionKey !== this.ocrLoadingSessionKey) {
      return;
    }
    this.ocrLoadingVisible = false;
    this.ocrLoadingPhase = 'recognizing';
  }

  private applyOcrReviewProcessingResult(processingResult: OcrRuleProcessingResult,
    showSuggestedTitle: boolean): void {
    this.ocrReviewProcessingMode = processingResult.processingMode ?? '';
    this.ocrReviewOriginalText = processingResult.originalText;
    this.ocrReviewProcessedText = processingResult.processedText;
    this.ocrReviewProcessedTitle = showSuggestedTitle ? this.reviewTitleFor(processingResult) : '';
    this.ocrReviewShowingOriginal = processingResult.matchedRuleCount === 0 ||
      (processingResult.processedText.length === 0 && this.ocrReviewProcessedTitle.length === 0);
    this.ocrReviewText = this.ocrReviewShowingOriginal ?
      this.ocrReviewOriginalText : this.ocrReviewProcessedText;
    this.ocrReviewTitle = this.ocrReviewShowingOriginal ? '' : this.ocrReviewProcessedTitle;
    if (processingResult.processingMode === 'ai') {
      this.ocrReviewRuleSummary = 'AI 已按输出要求整理，可切换查看系统 OCR 原文';
    } else if (processingResult.processingMode === 'ai-link') {
      this.ocrReviewRuleSummary = 'AI 已整理其他内容，链接由默认引擎识别，可切换查看系统 OCR 原文';
    } else if (processingResult.processingMode === 'link') {
      this.ocrReviewRuleSummary = processingResult.statusMessage ?? '链接已由默认引擎识别';
    } else if (processingResult.processingMode === 'ai-link-error') {
      this.ocrReviewRuleSummary = processingResult.statusMessage + '，链接已保留为默认引擎识别结果';
    } else if (processingResult.processingMode === 'ai-error') {
      this.ocrReviewRuleSummary = processingResult.statusMessage + '，当前显示系统 OCR 原文';
    } else if (processingResult.processingMode === 'temporary-none') {
      this.ocrReviewRuleSummary = '本次未启用匹配规则，当前显示系统 OCR 原文';
    } else {
      this.ocrReviewRuleSummary = processingResult.matchedRuleCount > 0 ?
        processingResult.matchedRuleCount.toString() + ' 个关键词已命中：' + processingResult.summaries.join('、') :
        (processingResult.activeRuleCount > 0 ? '启用的关键词未命中，当前显示原文' : '未启用照片分析规则');
    }
  }

  private openOcrReviewSheet(recognitionResult: OcrTextRecognitionResult,
    processingResult: OcrRuleProcessingResult, showSuggestedTitle: boolean = true): void {
    this.metaPickerSheetOpen = false;
    this.ocrReviewRecognitionResult = recognitionResult;
    this.ocrReviewShowSuggestedTitle = showSuggestedTitle;
    this.ocrReviewContentEdited = false;
    this.ocrReviewRuleMenuOpen = false;
    this.ocrReviewRuleItems = [];
    this.ocrReviewSelectedRuleIds = [];
    this.ocrReviewAppliedRuleIds = [];
    this.ocrReviewRuleSelectionDirty = false;
    this.ocrReviewApplyDialogOpen = false;
    this.ocrReviewRulesApplying = false;
    this.ocrReviewSessionKey++;
    this.applyOcrReviewProcessingResult(processingResult, showSuggestedTitle);
    this.ocrReviewKeyboardHeightVp = 0;
    this.ocrReviewSheetOpen = true;
    this.loadOcrReviewRuleItems();
  }

  private isCustomOcrEngineSelected(): boolean {
    return this.engine === 'custom' || this.engine.startsWith('custom:');
  }

  private currentOcrConfigId(): string {
    return this.engine.startsWith('custom:') ? this.engine.substring('custom:'.length) : this.engine;
  }

  private isPhotoMatchRule(item: MatchRuleTemplateItem): boolean {
    return item.scopes.indexOf('照片分析') >= 0 || item.scopes.indexOf('照片分享') >= 0;
  }

  private isCurrentOcrReviewRule(item: MatchRuleTemplateItem): boolean {
    if (!this.isPhotoMatchRule(item)) {
      return false;
    }
    if (this.isCustomOcrEngineSelected()) {
      return item.kind === 'ai-output' && item.aiConfigId === this.currentOcrConfigId();
    }
    return item.kind === 'keyword';
  }

  private async loadOcrReviewRuleItems(): Promise<void> {
    const sessionKey: number = this.ocrReviewSessionKey;
    try {
      const savedItems: MatchRuleTemplateItem[] | null = await ZapNotePreferencesService.getMatchRuleItems();
      if (!this.ocrReviewSheetOpen || sessionKey !== this.ocrReviewSessionKey) {
        return;
      }
      const allItems: MatchRuleTemplateItem[] = savedItems ?? [];
      const visibleItems: MatchRuleTemplateItem[] = [];
      const selectedIds: string[] = [];
      allItems.forEach((item: MatchRuleTemplateItem): void => {
        if (!this.isCurrentOcrReviewRule(item)) {
          return;
        }
        visibleItems.push(item);
        if (item.enabled) {
          selectedIds.push(item.id);
        }
      });
      this.ocrReviewAllRuleItems = allItems;
      this.ocrReviewRuleItems = visibleItems;
      this.ocrReviewSelectedRuleIds = selectedIds;
      this.ocrReviewAppliedRuleIds = selectedIds.slice();
      this.ocrReviewRuleSelectionDirty = false;
    } catch (error) {
      console.error('Index load OCR review rules failed: ' + JSON.stringify(error));
      if (sessionKey === this.ocrReviewSessionKey) {
        this.ocrReviewAllRuleItems = [];
        this.ocrReviewRuleItems = [];
        this.ocrReviewSelectedRuleIds = [];
        this.ocrReviewAppliedRuleIds = [];
        this.ocrReviewRuleSelectionDirty = false;
      }
    }
  }

  private ocrReviewRuleLabel(item: MatchRuleTemplateItem): string {
    const raw: string = item.kind === 'ai-output' ? item.template : item.keyword;
    const normalized: string = raw.trim().replace(/\s+/g, ' ');
    if (normalized.length <= 18) {
      return normalized.length > 0 ? normalized : '未命名规则';
    }
    return normalized.substring(0, 18) + '…';
  }

  private isOcrReviewRuleSelected(id: string): boolean {
    return this.ocrReviewSelectedRuleIds.indexOf(id) >= 0;
  }

  private sameOcrReviewRuleSelection(left: string[], right: string[]): boolean {
    if (left.length !== right.length) {
      return false;
    }
    for (let index: number = 0; index < left.length; index++) {
      if (right.indexOf(left[index]) < 0) {
        return false;
      }
    }
    return true;
  }

  private setOcrReviewRuleSelected(id: string, selected: boolean): void {
    const next: string[] = [];
    this.ocrReviewSelectedRuleIds.forEach((currentId: string): void => {
      if (currentId !== id) {
        next.push(currentId);
      }
    });
    if (selected) {
      next.push(id);
    }
    this.ocrReviewSelectedRuleIds = next;
    this.ocrReviewRuleSelectionDirty =
      !this.sameOcrReviewRuleSelection(next, this.ocrReviewAppliedRuleIds);
  }

  private restoreAppliedOcrReviewRules(): void {
    this.ocrReviewSelectedRuleIds = this.ocrReviewAppliedRuleIds.slice();
    this.ocrReviewRuleSelectionDirty = false;
  }

  private copyOcrRuleWithEnabled(item: MatchRuleTemplateItem, enabled: boolean): MatchRuleTemplateItem {
    const scopes: string[] = [];
    item.scopes.forEach((scope: string): void => {
      scopes.push(scope);
    });
    return {
      id: item.id,
      kind: item.kind,
      aiConfigId: item.aiConfigId,
      scopes: scopes,
      keyword: item.keyword,
      template: item.template,
      enabled: enabled,
      action: item.action,
      range: item.range,
      matchMode: item.matchMode,
      linkType: item.linkType
    };
  }

  private temporaryOcrRuleItems(): MatchRuleTemplateItem[] {
    const visibleIds: string[] = [];
    this.ocrReviewRuleItems.forEach((item: MatchRuleTemplateItem): void => {
      visibleIds.push(item.id);
    });
    const result: MatchRuleTemplateItem[] = [];
    this.ocrReviewAllRuleItems.forEach((item: MatchRuleTemplateItem): void => {
      if (visibleIds.indexOf(item.id) >= 0) {
        result.push(this.copyOcrRuleWithEnabled(item, this.isOcrReviewRuleSelected(item.id)));
      } else {
        result.push(item);
      }
    });
    return result;
  }

  private temporaryRulesDisabledResult(result: OcrTextRecognitionResult): OcrRuleProcessingResult {
    return {
      originalText: result.text.trim(),
      processedText: result.text.trim(),
      activeRuleCount: 0,
      matchedRuleCount: 0,
      summaries: [],
      changed: false,
      processingMode: 'temporary-none',
      statusMessage: '本次未启用匹配规则'
    };
  }

  private async applyOcrReviewRules(): Promise<void> {
    const recognitionResult: OcrTextRecognitionResult | null = this.ocrReviewRecognitionResult;
    if (recognitionResult === null || this.ocrReviewRulesApplying || this.ocrReviewRuleItems.length === 0) {
      return;
    }
    const sessionKey: number = this.ocrReviewSessionKey;
    this.ocrReviewRuleMenuOpen = false;
    this.ocrReviewRulesApplying = true;
    try {
      const processingResult: OcrRuleProcessingResult = this.ocrReviewSelectedRuleIds.length === 0 ?
        this.temporaryRulesDisabledResult(recognitionResult) :
        await this.processOcrResult(recognitionResult, this.temporaryOcrRuleItems());
      if (!this.ocrReviewSheetOpen || sessionKey !== this.ocrReviewSessionKey) {
        return;
      }
      this.applyOcrReviewProcessingResult(processingResult, this.ocrReviewShowSuggestedTitle);
      this.ocrReviewContentEdited = false;
      this.ocrReviewAppliedRuleIds = this.ocrReviewSelectedRuleIds.slice();
      this.ocrReviewRuleSelectionDirty = false;
      this.showToast('已按本次规则重新处理', 'success');
    } catch (error) {
      console.error('Index apply temporary OCR rules failed: ' + JSON.stringify(error));
      if (this.ocrReviewSheetOpen && sessionKey === this.ocrReviewSessionKey) {
        this.showToast('本次规则应用失败，已保留当前内容', 'danger');
      }
    } finally {
      if (sessionKey === this.ocrReviewSessionKey) {
        this.ocrReviewRulesApplying = false;
      }
    }
  }

  private requestApplyOcrReviewRules(): void {
    if (!this.ocrReviewRuleSelectionDirty || this.ocrReviewApplyDialogOpen) {
      this.ocrReviewRuleMenuOpen = false;
      return;
    }
    this.ocrReviewApplyDialogOpen = true;
    this.ocrReviewRuleMenuOpen = false;
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: '重新应用规则',
        message: this.ocrReviewContentEdited ?
          '重新处理会覆盖当前对标题和正文的修改，是否继续？' :
          '是否按当前选择重新处理识别结果？',
        buttons: [
          { text: '取消', color: this.textSecondary() },
          { text: '重新应用', color: this.selectedAccentColor }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        this.ocrReviewApplyDialogOpen = false;
        if (result.index === 1) {
          this.applyOcrReviewRules();
        } else {
          this.restoreAppliedOcrReviewRules();
        }
      }).catch(() => {
        this.ocrReviewApplyDialogOpen = false;
        this.restoreAppliedOcrReviewRules();
      });
    } catch (error) {
      this.ocrReviewApplyDialogOpen = false;
      this.restoreAppliedOcrReviewRules();
      console.error('Index show apply OCR rules dialog failed: ' + JSON.stringify(error));
    }
  }

  private handleOcrReviewRulePopupStateChange(isVisible: boolean): void {
    this.ocrReviewRuleMenuOpen = isVisible;
    if (!isVisible && this.ocrReviewSheetOpen && this.ocrReviewRuleSelectionDirty &&
      !this.ocrReviewApplyDialogOpen && !this.ocrReviewRulesApplying) {
      this.requestApplyOcrReviewRules();
    }
  }

  private ocrProcessingFeedback(processingResult: OcrRuleProcessingResult, fallback: string): string {
    if (processingResult.processingMode === 'ai-link') {
      return 'AI 已整理其他内容，链接已准确保留，请确认';
    }
    if (processingResult.processingMode === 'link') {
      return processingResult.statusMessage ?? '链接已由默认引擎识别，请确认';
    }
    if (processingResult.processingMode === 'ai-link-error') {
      return processingResult.statusMessage + '，链接已由默认引擎识别';
    }
    if (processingResult.processingMode === 'ai') {
      return 'AI 已整理识别内容，请确认';
    }
    if (processingResult.processingMode === 'ai-error') {
      return processingResult.statusMessage + '，已保留系统 OCR 原文';
    }
    return fallback;
  }

  private ocrProcessingFeedbackType(processingResult: OcrRuleProcessingResult): string {
    return processingResult.processingMode === 'ai-error' || processingResult.processingMode === 'ai-link-error' ?
      'danger' : 'success';
  }

  private switchOcrReviewSource(showOriginal: boolean): void {
    if (this.ocrReviewShowingOriginal === showOriginal) {
      return;
    }
    this.ocrReviewShowingOriginal = showOriginal;
    this.ocrReviewText = showOriginal ? this.ocrReviewOriginalText : this.ocrReviewProcessedText;
    this.ocrReviewTitle = showOriginal ? '' : this.ocrReviewProcessedTitle;
  }

  private isAiProcessingMode(mode: string): boolean {
    return mode === 'ai' || mode === 'ai-link';
  }

  private hasOcrReviewComparison(): boolean {
    return this.ocrReviewProcessedTitle.length > 0 ||
      (this.ocrReviewProcessedText.length > 0 && this.ocrReviewProcessedText !== this.ocrReviewOriginalText);
  }

  private closeOcrReviewSheet(): void {
    this.ocrReviewSheetOpen = false;
    this.ocrReviewKeyboardHeightVp = 0;
    this.ocrReviewText = '';
    this.ocrReviewOriginalText = '';
    this.ocrReviewProcessedText = '';
    this.ocrReviewTitle = '';
    this.ocrReviewProcessedTitle = '';
    this.ocrReviewProcessingMode = '';
    this.ocrReviewShowingOriginal = false;
    this.ocrReviewRuleSummary = '';
    this.ocrReviewRuleMenuOpen = false;
    this.ocrReviewRuleItems = [];
    this.ocrReviewSelectedRuleIds = [];
    this.ocrReviewAppliedRuleIds = [];
    this.ocrReviewRuleSelectionDirty = false;
    this.ocrReviewApplyDialogOpen = false;
    this.ocrReviewRulesApplying = false;
    this.ocrReviewContentEdited = false;
    this.ocrReviewRecognitionResult = null;
    this.ocrReviewAllRuleItems = [];
    this.ocrReviewSessionKey++;
  }

  private openFolderPicker(): void {
    if (this.folderDialogController) {
      this.folderDialogController.close();
      this.folderDialogController = null;
    }
    this.folderDialogController = new CustomDialogController({
      builder: DiaryFolderOptionsDialog({
        folders: this.folderOptions(),
        selectedFolderName: this.draftFolderName,
        selectedAccentColor: this.selectedAccentColor,
        cardBg: this.cardBg(),
        inputBg: this.inputBg(),
        lineColor: this.lineColor(),
        textPrimary: this.textPrimary(),
        textSecondary: this.textSecondary(),
        textTertiary: this.textTertiary(),
        onChoose: (value: string) => {
          this.draftFolderName = this.normalizeFolderName(value);
          this.showToast(this.draftFolderName.length > 0 ? '已设为标签：' + this.draftFolderName : '已设为无标签', 'success');
        },
        onCreate: (value: string) => {
          this.createDiaryFolder(value);
        }
      }),
      customStyle: false,
      alignment: DialogAlignment.Center,
      autoCancel: true
    });
    this.folderDialogController.open();
  }

  private createDiaryFolder(value: string): void {
    const folderName: string = this.normalizeFolderName(value);
    if (folderName.length === 0) {
      this.showToast('请输入标签名称', 'danger');
      return;
    }
    const nextFolders: string[] = this.savedFolderOptions();
    const isNewFolder: boolean = nextFolders.indexOf(folderName) < 0;
    if (isNewFolder) {
      nextFolders.push(folderName);
    }
    this.diaryFolders = nextFolders;
    this.saveDiaryFolders(nextFolders);
    this.draftFolderName = folderName;
    this.showToast(isNewFolder ? '已创建标签：' + folderName : '已设为标签：' + folderName, 'success');
  }

  private deleteDiaryFolder(value: string): void {
    const folderName: string = this.normalizeFolderName(value);
    if (folderName.length === 0) {
      return;
    }
    const nextFolders: string[] = [];
    this.diaryFolders.forEach((item: string) => {
      const normalized: string = this.normalizeFolderName(item);
      if (normalized.length > 0 && normalized !== folderName && nextFolders.indexOf(normalized) < 0) {
        nextFolders.push(normalized);
      }
    });
    const nextDiaries: DiaryEntry[] = [];
    this.diaries.forEach((entry: DiaryEntry) => {
      const item: DiaryEntry = this.cloneEntry(entry);
      if (this.normalizeFolderName(item.folderName) === folderName) {
        item.folderName = '';
      }
      nextDiaries.push(item);
    });
    if (this.normalizeFolderName(this.draftFolderName) === folderName) {
      this.draftFolderName = '';
    }
    const mergedFolders: string[] = this.mergeFolderNames(nextFolders);
    this.diaryFolders = mergedFolders;
    this.saveDiaryFolders(mergedFolders);
    this.diaries = nextDiaries;
    this.saveLocalDiaries(nextDiaries);
    this.showToast('标签已删除', 'danger');
  }

  private requestDeleteDiaryFolder(value: string): void {
    const folderName: string = this.normalizeFolderName(value);
    if (folderName.length === 0) {
      return;
    }
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: '删除标签',
        message: '删除“' + folderName + '”后，已归入该标签的笔记会变为无标签，笔记内容不会删除。确定继续吗？',
        buttons: [
          { text: '取消', color: this.textSecondary() },
          { text: '删除', color: '#EF4444' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.deleteDiaryFolder(folderName);
        }
      }).catch(() => {});
    } catch (error) {
      console.error('requestDeleteDiaryFolder showDialog failed: ' + JSON.stringify(error));
    }
  }

  private deleteDraftPhotoByUri(photoUri: string): void {
    const targetUri: string = photoUri.trim();
    if (targetUri.length === 0) {
      return;
    }
    const previousPhotoUris: string[] = this.normalizePhotoUris(this.draftPhotoUris);
    const deletedIndex: number = previousPhotoUris.indexOf(targetUri);
    this.draftPhotoUris = this.normalizePhotoUris(this.draftPhotoUris.filter((item: string) => item !== targetUri));
    if (deletedIndex >= 0 && deletedIndex < this.draftThumbnailPhotoIndex) {
      this.draftThumbnailPhotoIndex--;
    } else if (deletedIndex === this.draftThumbnailPhotoIndex) {
      this.draftThumbnailPhotoIndex = Math.min(this.draftThumbnailPhotoIndex,
        Math.max(this.draftPhotoUris.length - 1, 0));
      this.draftThumbnailScale = 1;
      this.draftThumbnailOffsetX = 0;
      this.draftThumbnailOffsetY = 0;
      this.draftThumbnailPhotoAspect = 1;
    }
    if (this.draftPhotoUri.trim() === targetUri) {
      this.draftPhotoUri = '';
      this.draftPhotoInBody = false;
      this.draftPhotoX = 0;
      this.draftPhotoY = 0;
      this.draftPhotoWidth = 156;
      this.draftPhotoHeight = 118;
      this.draftPhotoRotation = 0;
    }
    this.draftHasPhoto = this.hasDraftPhotoAssets();
    if (!this.draftHasPhoto) {
      this.editorPhotoPreviewOpen = false;
    }
    this.showToast('照片已删除', 'danger');
  }

  private requestDeleteDraftPhoto(photoUri: string): void {
    const targetUri: string = photoUri.trim();
    if (targetUri.length === 0) {
      return;
    }
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: '删除照片',
        message: '删除后这张照片会从当前笔记移除，确定继续吗？',
        buttons: [
          { text: '取消', color: this.textSecondary() },
          { text: '删除', color: '#EF4444' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.deleteDraftPhotoByUri(targetUri);
        }
      }).catch(() => {});
    } catch (error) {
      console.error('requestDeleteDraftPhoto showDialog failed: ' + JSON.stringify(error));
    }
  }

  private pickerOptions(): ValueOption[] {
    if (this.pickerType === 'mood') {
      return MOOD_OPTIONS;
    }
    if (this.pickerType === 'weather') {
      return WEATHER_OPTIONS;
    }
    if (this.pickerType === 'theme') {
      return THEME_OPTIONS;
    }
    if (this.pickerType === 'lighting') {
      return LIGHTING_OPTIONS;
    }
    if (this.pickerType === 'engine') {
      return ENGINE_OPTIONS;
    }
    if (this.pickerType === 'sync') {
      return SYNC_OPTIONS;
    }
    if (this.pickerType === 'photo-style') {
      return PHOTO_STYLE_OPTIONS;
    }
    return [];
  }

  private pickerActionButtons(options: ValueOption[]): [
    promptAction.Button,
    promptAction.Button?,
    promptAction.Button?,
    promptAction.Button?,
    promptAction.Button?,
    promptAction.Button?
  ] {
    const first: promptAction.Button = this.pickerActionButton(options[0]);
    if (options.length === 1) {
      return [first];
    }
    const second: promptAction.Button = this.pickerActionButton(options[1]);
    if (options.length === 2) {
      return [first, second];
    }
    const third: promptAction.Button = this.pickerActionButton(options[2]);
    if (options.length === 3) {
      return [first, second, third];
    }
    const fourth: promptAction.Button = this.pickerActionButton(options[3]);
    if (options.length === 4) {
      return [first, second, third, fourth];
    }
    const fifth: promptAction.Button = this.pickerActionButton(options[4]);
    if (options.length === 5) {
      return [first, second, third, fourth, fifth];
    }
    return [first, second, third, fourth, fifth, this.pickerActionButton(options[5])];
  }

  private pickerActionButton(option: ValueOption): promptAction.Button {
    const selected = option.value === this.currentPickerValue();
    return {
      text: selected ? option.label + '  ✓' : option.label,
      color: selected ? this.selectedAccentColor : this.textPrimary(),
      primary: selected
    };
  }

  private currentPickerValue(): string {
    if (this.pickerType === 'mood') {
      return this.draftMood;
    }
    if (this.pickerType === 'weather') {
      return this.draftWeather;
    }
    if (this.pickerType === 'theme') {
      return this.themeMode;
    }
    if (this.pickerType === 'lighting') {
      return this.lightingMode;
    }
    if (this.pickerType === 'engine') {
      return this.engine;
    }
    if (this.pickerType === 'sync') {
      return this.syncInterval;
    }
    if (this.pickerType === 'photo-style') {
      return this.selectedPhotoStyle;
    }
    return '';
  }

  private metaPickerTitle(): string {
    return this.metaPickerType === 'weather' ? '天气' : '心情';
  }

  private metaPickerSummary(): string {
    return this.metaPickerType === 'weather' ? '选择今天的天气，笔记卡片和统计会同步使用。' :
      '选择此刻的心情，笔记卡片和统计会同步使用。';
  }

  private metaPickerOptions(): ValueOption[] {
    return this.metaPickerType === 'weather' ? WEATHER_OPTIONS : MOOD_OPTIONS;
  }

  private currentMetaPickerValue(): string {
    return this.metaPickerType === 'weather' ? this.draftWeather : this.draftMood;
  }

  private isSelectedMetaOption(option: ValueOption): boolean {
    return option.value === this.currentMetaPickerValue();
  }

  private chooseMetaValue(value: string): void {
    if (this.metaPickerType === 'weather') {
      this.setEditorDraftMeta('weather', value);
      this.showToast('天气已更新', 'success');
    } else {
      this.setEditorDraftMeta('mood', value);
      this.showToast('心情已更新', 'success');
    }
    this.closeMetaPickerSheet();
  }

  private materialEffectModeForLighting(value: string): number {
    if (value === 'off') {
      return 0;
    }
    if (value === 'soft') {
      return 2;
    }
    if (value === 'exquisite') {
      return 4;
    }
    return 3;
  }

  private applyThemeColorMode(value: string): void {
    try {
      const context = getContext(this) as common.Context;
      let colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
      if (value === 'dark') {
        colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      } else if (value === 'light') {
        colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
      }
      context.getApplicationContext().setColorMode(colorMode);
      this.syncSystemColorModeFromContext(context);
      this.applySystemBarsForTheme(context, this.effectiveThemeMode() === 'dark');
    } catch (error) {
      console.error('Index applyThemeColorMode failed: ' + JSON.stringify(error));
    }
  }

  private syncSystemColorModeFromContext(context: common.Context): void {
    const colorMode: number = context.resourceManager.getConfigurationSync().colorMode;
    this.systemColorMode = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'dark' : 'light';
  }

  private handleSystemColorModeChange(): void {
    if (this.themeMode !== 'auto') {
      return;
    }
    try {
      const context = getContext(this) as common.Context;
      this.applySystemBarsForTheme(context, this.effectiveThemeMode() === 'dark');
    } catch (error) {
      console.error('Index handleSystemColorModeChange failed: ' + JSON.stringify(error));
    }
  }

  private async applySystemBarsForTheme(context: common.Context, darkMode: boolean): Promise<void> {
    try {
      const mainWindow: window.Window = await window.getLastWindow(context);
      const backgroundColor: string = this.pageBg();
      mainWindow.setWindowLayoutFullScreen(true);
      mainWindow.setWindowBackgroundColor(backgroundColor);
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: backgroundColor,
        statusBarContentColor: darkMode ? '#FFFFFF' : '#111827',
        navigationBarContentColor: darkMode ? '#FFFFFF' : '#111827'
      });
    } catch (error) {
      console.error('Index applySystemBarsForTheme failed: ' + JSON.stringify(error));
    }
  }

  private updateValue(key: string, value: string): void {
    if (key === 'theme') {
      this.themeMode = value;
      this.applyThemeColorMode(value);
      this.saveAppearanceValue('theme', value);
      this.showToast('设置已更新', 'success');
    } else if (key === 'lighting') {
      this.lightingMode = value;
      this.materialEffectMode = this.materialEffectModeForLighting(value);
      this.saveAppearanceValue('lighting', value);
      this.showToast('设置已更新', 'success');
    } else if (key === 'engine') {
      this.engine = value;
      this.saveInterfaceValue('engine', value);
      this.showToast('设置已更新', 'success');
    } else if (key === 'double-touch-action') {
      this.doubleTouchAction = this.normalizeDoubleTouchAction(value);
      this.saveInterfaceValue('double-touch-action', this.doubleTouchAction);
      this.showToast('双触动作已更新', 'success');
    } else if (key === 'shared-photo-save-mode') {
      this.sharedPhotoSaveMode = this.normalizeSharedPhotoSaveMode(value);
      this.saveInterfaceValue('shared-photo-save-mode', this.sharedPhotoSaveMode);
      this.showToast('照片填入设置已更新', 'success');
    } else if (key === 'shared-photo-auto-recognize') {
      this.updateToggle(key, value === 'true');
    } else if (key === 'shared-photo-save-to-album') {
      this.updateToggle(key, value === 'true');
    }
  }

  private chooseValue(value: string): void {
    if (this.pickerType === 'mood') {
      this.draftMood = value;
    } else if (this.pickerType === 'weather') {
      this.draftWeather = value;
    } else if (this.pickerType === 'theme') {
      this.themeMode = value;
      this.applyThemeColorMode(value);
      this.saveAppearanceValue('theme', value);
    } else if (this.pickerType === 'lighting') {
      this.lightingMode = value;
      this.materialEffectMode = this.materialEffectModeForLighting(value);
      this.saveAppearanceValue('lighting', value);
    } else if (this.pickerType === 'engine') {
      this.engine = value;
      this.saveInterfaceValue('engine', value);
    } else if (this.pickerType === 'sync') {
      this.syncInterval = value;
      this.saveSyncInterval(value);
    } else if (this.pickerType === 'photo-style') {
      this.selectedPhotoStyle = value;
      this.saveInterfaceValue('photo-style', value);
    }
    this.showToast('设置已更新', 'success');
  }

  private openEditor(id: string): void {
    this.editorPhotoPreviewOpen = false;
    this.editingId = id;
    if (id.length === 0) {
      this.draftTitle = '';
      this.draftBody = '';
      this.draftFolderName = '';
      this.draftDateMs = Date.now();
      this.draftMood = '😊';
      this.draftWeather = '☀️';
      this.draftFavorite = false;
      this.draftHasPhoto = false;
      this.draftPhotoInBody = false;
      this.draftPhotoUri = '';
      this.draftPhotoUris = [];
      this.draftThumbnailPhotoIndex = 0;
      this.draftThumbnailScale = 1;
      this.draftThumbnailOffsetX = 0;
      this.draftThumbnailOffsetY = 0;
      this.draftThumbnailPhotoAspect = 1;
      this.draftPhotoX = 0;
      this.draftPhotoY = 0;
      this.draftPhotoWidth = 156;
      this.draftPhotoHeight = 118;
      this.draftPhotoRotation = 0;
      this.editorVisible = true;
      return;
    }
    const matches = this.diaries.filter((entry: DiaryEntry) => entry.id === id);
    if (matches.length === 0) {
      this.showToast('未找到这篇笔记', 'danger');
      return;
    }
    this.draftTitle = matches[0].title;
    this.draftBody = matches[0].body;
    this.draftFolderName = typeof matches[0].folderName === 'string' ? matches[0].folderName : '';
    this.draftDateMs = typeof matches[0].dateMs === 'number' ? matches[0].dateMs : Date.now();
    this.draftMood = matches[0].mood;
    this.draftWeather = matches[0].weather;
    this.draftFavorite = matches[0].isFavorite;
    this.draftPhotoUris = this.resolveDiaryPhotoUris(matches[0]);
    this.draftThumbnailPhotoIndex = typeof matches[0].thumbnailPhotoIndex === 'number' ?
      Math.max(0, Math.min(Math.floor(matches[0].thumbnailPhotoIndex), Math.max(this.draftPhotoUris.length - 1, 0))) : 0;
    this.draftThumbnailScale = typeof matches[0].thumbnailScale === 'number' ?
      Math.max(1, Math.min(matches[0].thumbnailScale, 4)) : 1;
    this.draftThumbnailOffsetX = typeof matches[0].thumbnailOffsetX === 'number' ? matches[0].thumbnailOffsetX : 0;
    this.draftThumbnailOffsetY = typeof matches[0].thumbnailOffsetY === 'number' ? matches[0].thumbnailOffsetY : 0;
    this.draftThumbnailPhotoAspect = typeof matches[0].thumbnailPhotoAspect === 'number' &&
      matches[0].thumbnailPhotoAspect > 0 ? matches[0].thumbnailPhotoAspect : 1;
    this.draftPhotoUri = typeof matches[0].photoUri === 'string' ? matches[0].photoUri : '';
    this.draftHasPhoto = matches[0].hasPhoto || this.hasDraftPhotoAssets();
    this.draftPhotoInBody = typeof matches[0].photoInBody === 'boolean' ? matches[0].photoInBody : false;
    this.draftPhotoX = typeof matches[0].photoX === 'number' ? matches[0].photoX : 0;
    this.draftPhotoY = typeof matches[0].photoY === 'number' ? matches[0].photoY : 0;
    this.draftPhotoWidth = typeof matches[0].photoWidth === 'number' ? matches[0].photoWidth : 156;
    this.draftPhotoHeight = typeof matches[0].photoHeight === 'number' ? matches[0].photoHeight : 118;
    this.draftPhotoRotation = typeof matches[0].photoRotation === 'number' ? matches[0].photoRotation : 0;
    this.editorVisible = true;
  }

  private openPhotoDraft(): void {
    this.recognizePhotoIntoDraft(true, '请选择要识别的照片');
    return;
    this.openEditor('');
    this.draftTitle = '照片里的小瞬间';
    this.draftBody = 'AI 已根据照片生成一段草稿：画面里有值得记住的光线、颜色和心情。你可以继续补充具体发生了什么。';
    this.draftHasPhoto = true;
    this.showToast('已模拟完成照片识别并填入草稿', 'success');
  }

  private async attachPhotoToDraft(): Promise<void> {
    this.showToast('请选择要添加的照片', 'info');
    let photoAdded: boolean = false;
    let loadingSessionKey: number = 0;
    try {
      const selectedPhotoUri: string | null = await OcrTextRecognitionService.pickPhotoUri();
      if (selectedPhotoUri === null) {
        this.showToast('未选择照片', 'info');
        return;
      }
      loadingSessionKey = this.beginOcrLoading();
      const persistedPhotoUri: string = await this.persistPhotoForDiary(selectedPhotoUri);
      this.draftPhotoUris = this.normalizePhotoUris(this.draftPhotoUris.concat([persistedPhotoUri]));
      this.draftHasPhoto = true;
      photoAdded = true;
      const recognitionResult: OcrTextRecognitionResult =
        await OcrTextRecognitionService.recognizePhotoResult(selectedPhotoUri);
      if (recognitionResult.text.trim().length === 0) {
        this.showToast('已添加照片，未识别到文字', 'info');
        return;
      }
      // The editor's photo action starts with an empty review title. The
      // recognized text is confirmed into the body, while an explicitly
      // entered review title can replace the diary title.
      this.updateOcrLoadingPhase(loadingSessionKey, 'processing');
      const processingResult: OcrRuleProcessingResult = await this.processOcrResult(recognitionResult);
      this.finishOcrLoading(loadingSessionKey);
      this.openOcrReviewSheet(recognitionResult, processingResult, false);
    } catch (error) {
      console.error('Index attachPhotoToDraft failed: ' + JSON.stringify(error));
      this.showToast(photoAdded ? this.ocrFailureMessage(error) : '照片添加失败，请稍后重试', 'danger');
    } finally {
      this.finishOcrLoading(loadingSessionKey);
    }
  }

  private recognizedPhotoTitle(): string {
    const today: Date = new Date();
    return today.getFullYear().toString() + '年' + (today.getMonth() + 1).toString() + '月' +
      today.getDate().toString() + '日 · 照片文字';
  }

  private magnetDisplayTitle(text: string): string {
    const links: string[] = OcrTextRecognitionService.extractMagnetLinks(text);
    for (let index: number = 0; index < links.length; index++) {
      const match: RegExpMatchArray | null = links[index].match(/[?&]dn=([^&]+)/i);
      if (match === null || match.length < 2) {
        continue;
      }
      let value: string = match[1].replace(/\+/g, ' ');
      try {
        value = decodeURIComponent(value);
      } catch (error) {
        console.warn('Index decode magnet title failed: ' + JSON.stringify(error));
      }
      value = this.cleanRecognizedField(value);
      if (value.length > 0) {
        return value;
      }
    }
    return links.length > 0 ? '磁力链接' : '';
  }

  private reviewTitleFor(processingResult: OcrRuleProcessingResult): string {
    const suggested: string = (processingResult.suggestedTitle ?? '').trim();
    if (suggested.length > 0) {
      return suggested;
    }
    const source: string = processingResult.processedText.trim().length > 0 ?
      processingResult.processedText : processingResult.originalText;
    const magnetTitle: string = this.magnetDisplayTitle(source);
    if (magnetTitle.length > 0) {
      return magnetTitle;
    }
    const numberMatch: RegExpMatchArray | null =
      source.match(/(?:FC2[-_\s]?PPV[-_\s]?\d{5,8}|[A-Z]{2,10}[-_\s]?\d{2,7})/i);
    if (numberMatch !== null && numberMatch.length > 0) {
      return numberMatch[0].replace(/\s+/g, '').toUpperCase();
    }
    return this.recognizedPhotoTitle();
  }

  private cleanRecognizedField(value: string): string {
    return value.replace(/[【】\[\]（）()《》<>"'“”‘’]+/g, '').replace(/[，。；;、|]+$/g, '').trim();
  }

  private normalizeRecognizedCode(value: string): string {
    const cleaned: string = this.cleanRecognizedField(value)
      .replace(/[‐‑‒–—―－]/g, '-')
      .replace(/[＿_\s]+/g, '-')
      .replace(/--+/g, '-');
    return cleaned.toUpperCase();
  }

  private extractLabeledValue(text: string, labels: string[], valuePattern: RegExp): string {
    for (let index = 0; index < labels.length; index++) {
      const label: string = labels[index];
      const expression: RegExp = new RegExp(label + '\\s*[:：]?\\s*(' + valuePattern.source + ')', 'i');
      const match: RegExpMatchArray | null = text.match(expression);
      if (match !== null && match.length > 1) {
        return this.cleanRecognizedField(match[1]);
      }
    }
    return '';
  }

  private isChatRecognizedText(text: string): boolean {
    return text.indexOf('聊天记录') >= 0 || text.indexOf('群聊') >= 0 || text.indexOf('@') >= 0 ||
      text.indexOf('番号呢') >= 0 || text.match(/\d{1,2}\/\d{1,2}\s+\d{1,2}:\d{2}/) !== null;
  }

  private extractPersonCandidate(value: string, personPattern: RegExp, preferLast: boolean = false): string {
    const cleaned: string = this.cleanRecognizedField(value)
      .replace(/[@＠][A-Za-z0-9_.-]+/g, ' ')
      .replace(/\d{1,2}\/\d{1,2}\s+\d{1,2}:\d{2}/g, ' ')
      .replace(/(番号|番號|作品番号|作品番號|人名|姓名|演员|演員|女优|女優|主演|群聊|聊天记录|聊天|记录|日期|时间)/g, ' ');
    const matches: RegExpMatchArray | null = cleaned.match(new RegExp(personPattern.source, 'g'));
    if (matches === null || matches.length === 0) {
      return '';
    }
    const start: number = preferLast ? matches.length - 1 : 0;
    const end: number = preferLast ? -1 : matches.length;
    const step: number = preferLast ? -1 : 1;
    for (let index = start; index !== end; index += step) {
      const candidate: string = this.cleanRecognizedField(matches[index]);
      if (candidate.length >= 2 && candidate.length <= 12 && candidate.indexOf('番号') < 0 &&
        candidate.indexOf('作品') < 0) {
        return candidate;
      }
    }
    return '';
  }

  private extractPersonCodeTitle(text: string): string {
    const compactText: string = text.replace(/\r/g, '\n').replace(/[‐‑‒–—―－]/g, '-');
    const isChatText: boolean = this.isChatRecognizedText(compactText);
    const codePattern: RegExp = /(?:FC2(?:[-_\s]?PPV)?[-_\s]?\d{5,8}|[A-Z]{2,8}[-_\s]?\d{2,6}(?:[-_\s]?[A-Z0-9]{1,4})?)/i;
    const personPattern: RegExp = /[\u4E00-\u9FA5\u3040-\u30FF\u30A0-\u30FF·・]{2,12}/;
    let code: string = this.extractLabeledValue(compactText, ['番号', '番號', '作品番号', '作品番號'], codePattern);
    let person: string = this.extractLabeledValue(compactText, ['人名', '姓名', '演员', '演員', '女优', '女優', '主演'], personPattern);
    if (code.length === 0) {
      const codeMatch: RegExpMatchArray | null = compactText.match(codePattern);
      if (codeMatch !== null && codeMatch.length > 0) {
        code = codeMatch[0];
      }
    }
    if (person.length === 0) {
      const lines: string[] = compactText.split('\n');
      for (let index = 0; index < lines.length; index++) {
        const line: string = lines[index];
        const lineCodeMatch: RegExpMatchArray | null = line.match(codePattern);
        if (lineCodeMatch !== null && lineCodeMatch.length > 0) {
          const lineCode: string = lineCodeMatch[0];
          const lineCodeIndex: number = line.indexOf(lineCode);
          const beforeCode: string = lineCodeIndex >= 0 ? line.substring(0, lineCodeIndex) : '';
          const afterCode: string = lineCodeIndex >= 0 ? line.substring(lineCodeIndex + lineCode.length) : '';
          person = this.extractPersonCandidate(beforeCode, personPattern, true);
          if (person.length === 0) {
            person = this.extractPersonCandidate(afterCode, personPattern);
          }
          if (person.length > 0) {
            break;
          }
          if (isChatText) {
            continue;
          }
          const previousLine: string = index > 0 ? lines[index - 1] : '';
          const nextLine: string = index + 1 < lines.length ? lines[index + 1] : '';
          person = this.extractPersonCandidate(previousLine, personPattern);
          if (person.length > 0) {
            break;
          }
          person = this.extractPersonCandidate(nextLine, personPattern);
          if (person.length > 0) {
            break;
          }
        }
      }
    }
    if (person.length === 0 || code.length === 0) {
      return '';
    }
    return this.cleanRecognizedField(person) + ' ' + this.normalizeRecognizedCode(code);
  }

  private appendRecognizedText(text: string, hasPhoto: boolean = true, autoTitle: boolean = true): string {
    const trimmedText: string = text.trim();
    if (trimmedText.length === 0) {
      return 'empty';
    }
    const magnetLinks: string[] = OcrTextRecognitionService.extractMagnetLinks(trimmedText);
    const currentBody: string = this.draftBody.trim();
    this.draftBody = currentBody.length === 0 ? trimmedText : currentBody + '\n\n' + trimmedText;
    if (autoTitle && this.draftTitle.trim().length === 0) {
      if (magnetLinks.length > 0) {
        const personCodeTitle: string = this.extractPersonCodeTitle(trimmedText);
        this.draftTitle = personCodeTitle.length > 0 ? personCodeTitle : '磁力链接';
      } else {
        this.draftTitle = this.recognizedPhotoTitle();
      }
    }
    this.draftHasPhoto = hasPhoto;
    return magnetLinks.length > 0 ? 'magnet' : 'text';
  }

  private async fillOcrReviewText(): Promise<void> {
    const title: string = this.ocrReviewTitle.trim();
    const text: string = this.ocrReviewText.trim();
    if (title.length === 0 && text.length === 0) {
      this.showToast('标题和正文不能同时为空', 'info');
      return;
    }
    if (title.length > 0) {
      this.draftTitle = title;
    }
    let appendResult: string = 'empty';
    if (text.length > 0) {
      appendResult = this.appendRecognizedText(text, this.hasDraftPhotoAssets(), false);
    }
    this.closeOcrReviewSheet();
    await this.triggerRecognitionVibration();
    if (title.length > 0) {
      this.showToast(text.length > 0 ? '标题和正文已填入笔记' : '标题已填入笔记', 'success');
      return;
    }
    this.showToast(appendResult === 'empty' ? '没有可填入的正文' : '正文已填入笔记', 'success');
  }

  private async fillProcessedOcrResult(processingResult: OcrRuleProcessingResult): Promise<void> {
    const aiProcessingMode: boolean = this.isAiProcessingMode(processingResult.processingMode ?? '');
    const title: string = aiProcessingMode ?
      (processingResult.suggestedTitle ?? '').trim() : '';
    const text: string = aiProcessingMode ? processingResult.processedText :
      (processingResult.matchedRuleCount > 0 && processingResult.processedText.trim().length > 0 ?
        processingResult.processedText : processingResult.originalText);
    if (title.length === 0 && text.trim().length === 0) {
      return;
    }
    if (title.length > 0) {
      this.draftTitle = title;
    }
    if (text.trim().length > 0) {
      this.appendRecognizedText(text, this.hasDraftPhotoAssets());
    }
    await this.triggerRecognitionVibration();
  }

  private async triggerRecognitionVibration(): Promise<void> {
    if (!this.vibrateEnabled) {
      return;
    }
    try {
      await vibrator.startVibration({
        type: 'preset',
        effectId: vibrator.HapticFeedback.EFFECT_NOTICE_SUCCESS
      }, {
        usage: 'touch'
      });
    } catch (error) {
      console.error('Index trigger recognition vibration failed: ' + JSON.stringify(error));
    }
  }

  private ocrFailureMessage(error: Object): string {
    if (error instanceof OcrTextRecognitionError) {
      if (error.stage === 'capability') {
        return '当前设备不支持本地文字识别';
      }
      if (error.stage === 'picker') {
        return '未能打开相册，请稍后重试';
      }
      if (error.stage === 'decode') {
        return '照片读取失败，请换一张常规图片';
      }
      if (error.stage === 'init') {
        return '文字识别服务初始化失败';
      }
      if (error.code === 200) {
        return '文字识别超时，请重试';
      }
      if (error.code === 401) {
        return '文字识别参数异常，请换一张图片';
      }
      if (error.code === 1001400002) {
        return '文字识别服务异常，请确认设备支持该能力';
      }
      if (error.code === 1001400001) {
        return '文字识别运行失败，请稍后重试';
      }
      if (error.code > 0) {
        return '照片文字识别失败，错误码 ' + error.code.toString();
      }
    }
    return '照片文字识别失败，请稍后重试';
  }

  private async recognizePhotoIntoDraft(openEditorAfterRecognition: boolean, pickerPrompt: string): Promise<void> {
    this.showToast(pickerPrompt, 'info');
    let loadingSessionKey: number = 0;
    try {
      const photoUri: string | null = await OcrTextRecognitionService.pickPhotoUri();
      if (photoUri === null) {
        this.showToast('未选择照片', 'info');
        return;
      }
      loadingSessionKey = this.beginOcrLoading();
      const result: OcrTextRecognitionResult = await OcrTextRecognitionService.recognizePhotoResult(photoUri);
      if (result.text.trim().length === 0) {
        this.showToast('这张照片里没有识别到文字', 'danger');
        return;
      }
      if (openEditorAfterRecognition && !this.editorVisible) {
        this.openEditor('');
      }
      if (result.photoUri.length > 0) {
        const persistedPhotoUri: string = await this.persistPhotoForDiary(result.photoUri);
        this.draftPhotoUris = this.normalizePhotoUris(this.draftPhotoUris.concat([persistedPhotoUri]));
      }
      this.draftHasPhoto = this.hasDraftPhotoAssets();
      this.draftPhotoInBody = false;
      this.updateOcrLoadingPhase(loadingSessionKey, 'processing');
      const processingResult: OcrRuleProcessingResult = await this.processOcrResult(result);
      this.editorVisible = true;
      this.finishOcrLoading(loadingSessionKey);
      this.openOcrReviewSheet(result, processingResult);
      this.showToast(this.ocrProcessingFeedback(processingResult,
        processingResult.matchedRuleCount > 0 ?
          processingResult.matchedRuleCount.toString() + ' 个关键词已处理，请确认内容' :
          '照片文字已识别，请确认内容'), this.ocrProcessingFeedbackType(processingResult));
    } catch (error) {
      console.error('Index recognizePhotoIntoDraft failed: ' + JSON.stringify(error));
      this.showToast(this.ocrFailureMessage(error), 'danger');
    } finally {
      this.finishOcrLoading(loadingSessionKey);
    }
  }

  private handleSharedPhotoRequestChange(): void {
    this.scheduleSharedPhotoRequestCheck();
  }

  private handlePrivacyVaultBackgroundChange(): void {
    this.lockPrivacyVault();
  }

  private async openPrivacyVault(): Promise<void> {
    if (this.privacyVaultVisible || this.privacyVaultAuthInProgress) {
      return;
    }
    if (this.privacyVaultUnlocked) {
      this.privacyVaultVisible = true;
      return;
    }
    this.privacyVaultAuthInProgress = true;
    const result = await ZapNotePrivacyVaultAuthService.authenticate();
    this.privacyVaultAuthInProgress = false;
    if (result.status !== 'success') {
      if (result.message.length > 0) {
        this.showToast(result.message, 'info');
      }
      return;
    }
    this.privacyVaultUnlocked = true;
    this.privacyVaultVisible = true;
  }

  private closePrivacyVault(): void {
    this.privacyVaultSelectionSheetOpen = false;
    if (this.editorVisible && this.editingId.length > 0) {
      const editingMatches: DiaryEntry[] = this.diaries.filter((entry: DiaryEntry): boolean => {
        return entry.id === this.editingId;
      });
      if (editingMatches.length > 0 && editingMatches[0].isPrivate === true) {
        this.editorVisible = false;
        this.editorPhotoPreviewOpen = false;
      }
    }
    this.privacyVaultVisible = false;
  }

  private lockPrivacyVault(): void {
    this.closePrivacyVault();
    this.privacyVaultUnlocked = false;
  }

  private addDiariesToPrivacy(ids: string[]): void {
    if (ids.length === 0) {
      return;
    }
    const next: DiaryEntry[] = [];
    this.diaries.forEach((entry: DiaryEntry) => {
      const item: DiaryEntry = this.cloneEntry(entry);
      if (ids.indexOf(entry.id) >= 0) {
        item.isPrivate = true;
      }
      next.push(item);
    });
    this.diaries = DiaryStatsUtils.sortDiariesByLatest(next);
    this.saveLocalDiaries(this.diaries);
    this.showToast('已加入隐私库', 'success');
  }

  private moveDiaryOutOfPrivacy(id: string): void {
    const next: DiaryEntry[] = [];
    let changed = false;
    this.diaries.forEach((entry: DiaryEntry) => {
      const item: DiaryEntry = this.cloneEntry(entry);
      if (entry.id === id && entry.isPrivate === true) {
        item.isPrivate = false;
        changed = true;
      }
      next.push(item);
    });
    if (!changed) {
      return;
    }
    this.diaries = DiaryStatsUtils.sortDiariesByLatest(next);
    this.saveLocalDiaries(this.diaries);
    this.showToast('已移出隐私库', 'success');
  }

  private requestPermanentDeletePrivateDiary(id: string): void {
    this.askConfirm('delete-private-diary', '永久删除隐私笔记', '删除后无法通过应用恢复，确定继续吗？', id);
  }

  private permanentlyDeletePrivateDiary(id: string): void {
    const matches: DiaryEntry[] = this.diaries.filter((entry: DiaryEntry): boolean =>
      entry.id === id && entry.isPrivate === true);
    if (matches.length === 0) {
      return;
    }
    this.diaries = this.diaries.filter((entry: DiaryEntry): boolean => entry.id !== id);
    this.saveLocalDiaries(this.diaries);
    this.showToast('隐私笔记已永久删除', 'danger');
  }

  private scheduleSharedPhotoRequestCheck(): void {
    setTimeout((): void => {
      this.consumeSharedPhotoRequest();
    }, 0);
  }

  private async consumeSharedPhotoRequest(): Promise<void> {
    const requestKey: number = this.sharedPhotoRequestKey;
    if (this.sharedPhotoPromptInProgress || requestKey <= this.lastHandledSharedPhotoRequestKey) {
      return;
    }
    const photoUri: string = this.sharedPhotoUri.trim();
    const errorMessage: string = this.sharedPhotoError.trim();
    this.lastHandledSharedPhotoRequestKey = requestKey;
    this.sharedPhotoUri = '';
    this.sharedPhotoError = '';

    if (errorMessage.length > 0 || photoUri.length === 0) {
      this.showToast(errorMessage.length > 0 ? errorMessage : '未收到可识别的图片', 'danger');
      return;
    }

    this.sharedPhotoPromptInProgress = true;
    try {
      let shouldRecognize: boolean = this.sharedPhotoAutoRecognizeEnabled;
      if (!shouldRecognize) {
        const result: promptAction.ShowDialogSuccessResponse =
          await this.getUIContext().getPromptAction().showDialog({
            title: '识别图片文字',
            message: '是否识别并填入这张图片？',
            buttons: [
              { text: '暂不', color: this.textSecondary() },
              { text: '识别并填入', color: this.selectedAccentColor }
            ]
        });
        shouldRecognize = result.index === 1;
      }
      if (shouldRecognize) {
        await this.showSharedPhotoRecycleBinNoticeIfNeeded();
        await this.recognizeSharedPhotoIntoDraft(photoUri, !this.sharedPhotoAutoRecognizeEnabled);
      }
    } catch (error) {
      console.error('Index shared photo dialog failed: ' + JSON.stringify(error));
    } finally {
      this.sharedPhotoPromptInProgress = false;
      if (this.sharedPhotoRequestKey > this.lastHandledSharedPhotoRequestKey) {
        this.scheduleSharedPhotoRequestCheck();
      }
    }
  }

  private async showSharedPhotoRecycleBinNoticeIfNeeded(): Promise<void> {
    const preferencesAvailable: boolean = await this.ensurePreferencesReady();
    const noticeShown: boolean = preferencesAvailable ?
      await ZapNotePreferencesService.getSharedPhotoRecycleBinNoticeShown() : false;
    if (noticeShown) {
      return;
    }
    try {
      await this.getUIContext().getPromptAction().showDialog({
        title: '截图删除提醒',
        message: '从手机截图后分享到识录笔记时，即使选择“分享后删除截图”，截图在分析完成后仍会保留在手机相册回收站（最近删除）中。若要彻底删除，请在相册回收站中手动再次删除。',
        buttons: [
          { text: '知道了', color: this.selectedAccentColor }
        ]
      });
      if (preferencesAvailable) {
        await ZapNotePreferencesService.setSharedPhotoRecycleBinNoticeShown(true);
      }
    } catch (error) {
      console.error('Index shared photo recycle bin notice failed: ' + JSON.stringify(error));
    }
  }

  private async recognizeSharedPhotoIntoDraft(photoUri: string, shouldShowReview: boolean): Promise<void> {
    let loadingSessionKey: number = 0;
    try {
      loadingSessionKey = this.beginOcrLoading();
      const result: OcrTextRecognitionResult = await OcrTextRecognitionService.recognizePhotoResult(photoUri);
      this.finishOcrLoading(loadingSessionKey);
      if (!this.editorVisible) {
        this.openEditor('');
      }
      const savePhoto: boolean = await this.shouldFillRecognizedPhoto();
      loadingSessionKey = this.beginOcrLoading();
      this.updateOcrLoadingPhase(loadingSessionKey, 'processing');
      let diaryPhotoUri: string = savePhoto ? await this.copySharedPhotoToAppFiles(photoUri) : '';
      const photoSaved: boolean = diaryPhotoUri.length > 0;
      if (photoSaved) {
        this.attachSharedPhotoCopyToDraft(diaryPhotoUri);
      }
      let albumSaved: boolean = false;
      let temporaryAlbumPhotoUri: string = '';
      if (this.sharedPhotoSaveToAlbumEnabled) {
        let albumSourceUri: string = diaryPhotoUri;
        if (albumSourceUri.length === 0) {
          temporaryAlbumPhotoUri = await this.copySharedPhotoToAppFiles(photoUri);
          albumSourceUri = temporaryAlbumPhotoUri;
        }
        if (albumSourceUri.length > 0) {
          const context = getContext(this) as common.UIAbilityContext;
          albumSaved = await PhotoAlbumSaveService.savePhoto(context, albumSourceUri);
        }
        if (temporaryAlbumPhotoUri.length > 0) {
          await this.deleteTemporarySharedPhoto(temporaryAlbumPhotoUri);
        }
      }
      const saveIncomplete: boolean = (savePhoto && !photoSaved) ||
        (this.sharedPhotoSaveToAlbumEnabled && !albumSaved);
      if (result.text.trim().length === 0) {
        if (saveIncomplete) {
          this.showToast('未识别到文字，照片保存未完成', 'danger');
        } else if (photoSaved && albumSaved) {
          this.showToast('未识别到文字，照片已保存到笔记和本地相册', 'info');
        } else if (photoSaved) {
          this.showToast('未识别到文字，照片已添加到笔记', 'info');
        } else if (albumSaved) {
          this.showToast('未识别到文字，照片已保存到本地相册', 'info');
        } else {
          this.showToast('这张图片里没有识别到文字', 'info');
        }
        return;
      }
      this.updateOcrLoadingPhase(loadingSessionKey, 'processing');
      const processingResult: OcrRuleProcessingResult = await this.processOcrResult(result);
      this.editorVisible = true;
      if (shouldShowReview) {
        this.finishOcrLoading(loadingSessionKey);
        this.openOcrReviewSheet(result, processingResult);
        if (processingResult.processingMode === 'ai-error') {
          this.showToast(this.ocrProcessingFeedback(processingResult, 'AI 整理失败'), 'danger');
        } else if (saveIncomplete) {
          this.showToast('文字已识别，但照片保存未完成，请确认内容', 'danger');
        } else if (photoSaved && albumSaved) {
          this.showToast('照片已保存到笔记和本地相册，文字已识别，请确认内容', 'success');
        } else if (photoSaved) {
          this.showToast('照片已保存，文字已识别，请确认内容', 'success');
        } else if (albumSaved) {
          this.showToast('照片已保存到本地相册，文字已识别，请确认内容', 'success');
        } else {
          this.showToast(this.ocrProcessingFeedback(processingResult,
            processingResult.matchedRuleCount > 0 ?
              processingResult.matchedRuleCount.toString() + ' 个关键词已处理，请确认内容' :
              '图片文字已识别，请确认内容'), this.ocrProcessingFeedbackType(processingResult));
        }
      } else {
        await this.fillProcessedOcrResult(processingResult);
        const fallbackMessage: string = saveIncomplete ?
          '文字已自动填入，但照片保存未完成' : '图片文字已自动填入正文';
        this.showToast(this.ocrProcessingFeedback(processingResult, fallbackMessage),
          processingResult.processingMode === 'ai-error' || saveIncomplete ? 'danger' : 'success');
      }
    } catch (error) {
      console.error('Index recognize shared photo failed: ' + JSON.stringify(error));
      this.showToast(this.ocrFailureMessage(error), 'danger');
    } finally {
      this.finishOcrLoading(loadingSessionKey);
    }
  }

  private async shouldFillRecognizedPhoto(): Promise<boolean> {
    if (this.sharedPhotoSaveMode === 'save') {
      return true;
    }
    if (this.sharedPhotoSaveMode === 'discard') {
      return false;
    }
    try {
      const result: promptAction.ShowDialogSuccessResponse =
        await this.getUIContext().getPromptAction().showDialog({
            title: '照片填入',
            message: '是否将这张照片填入当前笔记？',
          buttons: [
            { text: '不填入', color: this.textSecondary() },
            { text: '填入', color: this.selectedAccentColor }
          ]
        });
      return result.index === 1;
    } catch (error) {
      console.error('Index shared photo save dialog failed: ' + JSON.stringify(error));
      return false;
    }
  }

  private async copySharedPhotoToAppFiles(photoUri: string): Promise<string> {
    const sourceUri: string = photoUri.trim();
    if (sourceUri.length === 0) {
      return '';
    }
    try {
      const context = getContext(this) as common.Context;
      const persistedPhotoUri: string = await ZapNoteBackupService.copyPhotoToAppFiles(context, sourceUri);
      if (persistedPhotoUri.trim().length === 0 || persistedPhotoUri.trim() === sourceUri) {
        return '';
      }
      return persistedPhotoUri.trim();
    } catch (error) {
      console.error('Index copy shared photo failed: ' + JSON.stringify(error));
      return '';
    }
  }

  private attachSharedPhotoCopyToDraft(photoUri: string): void {
    this.draftPhotoUris = this.normalizePhotoUris(this.draftPhotoUris.concat([photoUri]));
    this.draftHasPhoto = true;
  }

  private async deleteTemporarySharedPhoto(photoUri: string): Promise<void> {
    const sourceUri: string = photoUri.trim();
    if (sourceUri.length === 0) {
      return;
    }
    const filePath: string = sourceUri.startsWith('file://') ? sourceUri.substring(7) : sourceUri;
    try {
      await fileIo.unlink(filePath);
    } catch (error) {
      console.error('Index delete temporary shared photo failed: ' + JSON.stringify(error));
    }
  }

  private async ensureScreenCapturePermission(): Promise<boolean> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context,
        ['ohos.permission.CUSTOM_SCREEN_CAPTURE']);
      return result.authResults.length > 0 &&
        result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      console.error('Index request screen capture permission failed: ' + JSON.stringify(error));
      return false;
    }
  }

  private async prepareSmartKeyScreenCapture(): Promise<void> {
    const granted: boolean = await this.ensureScreenCapturePermission();
    if (granted) {
      this.showToast('智控键双触识别已开启', 'success');
      return;
    }
    this.doubleTouchEnabled = false;
    await this.saveInterfaceToggle('doubleTouch', false);
    this.showToast('未授予截屏权限，智控键双触识别未开启', 'warning');
  }

  private async recognizeScreenCaptureIntoDraft(): Promise<void> {
    if (!this.doubleTouchEnabled || this.smartKeyCaptureInProgress || this.ocrLoadingVisible) {
      return;
    }
    this.smartKeyCaptureInProgress = true;
    let temporaryPhotoUri: string = '';
    let loadingSessionKey: number = 0;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      temporaryPhotoUri = await ScreenCapturePhotoService.saveTemporaryPhoto(context, await screenshot.capture());
      if (temporaryPhotoUri.length === 0) {
        throw new Error('Failed to encode screen capture');
      }
      const shouldShowReview: boolean = !this.sharedPhotoAutoRecognizeEnabled || this.doubleTouchAction === 'back';
      if (!this.editorVisible) {
        this.openEditor('');
        if (!shouldShowReview) {
          this.editorVisible = false;
        }
      }
      loadingSessionKey = this.beginOcrLoading();
      const result: OcrTextRecognitionResult =
        await OcrTextRecognitionService.recognizePhotoResult(temporaryPhotoUri);
      this.finishOcrLoading(loadingSessionKey);
      const fillPhoto: boolean = await this.shouldFillRecognizedPhoto();
      loadingSessionKey = this.beginOcrLoading();
      this.updateOcrLoadingPhase(loadingSessionKey, 'processing');
      const diaryPhotoUri: string = fillPhoto ? await this.copySharedPhotoToAppFiles(temporaryPhotoUri) : '';
      if (diaryPhotoUri.length > 0) {
        this.attachSharedPhotoCopyToDraft(diaryPhotoUri);
      }
      if (this.sharedPhotoSaveToAlbumEnabled) {
        await PhotoAlbumSaveService.savePhoto(context, temporaryPhotoUri);
      }
      if (result.text.trim().length === 0) {
        if (shouldShowReview) {
          this.showToast('当前画面未识别到文字', 'info');
        }
        return;
      }
      this.draftHasPhoto = this.hasDraftPhotoAssets();
      this.draftPhotoInBody = false;
      this.updateOcrLoadingPhase(loadingSessionKey, 'processing');
      const processingResult: OcrRuleProcessingResult = await this.processOcrResult(result);
      if (shouldShowReview) {
        this.editorVisible = true;
        this.finishOcrLoading(loadingSessionKey);
        this.openOcrReviewSheet(result, processingResult);
        this.showToast(this.ocrProcessingFeedback(processingResult,
          processingResult.matchedRuleCount > 0 ?
            processingResult.matchedRuleCount.toString() + ' 个关键词已处理，请确认内容' :
            '屏幕文字已识别，请确认内容'), this.ocrProcessingFeedbackType(processingResult));
      } else {
        await this.fillProcessedOcrResult(processingResult);
        if (processingResult.processingMode === 'ai' || processingResult.processingMode === 'ai-error') {
          this.showToast(this.ocrProcessingFeedback(processingResult, '屏幕文字已自动填入正文'),
            this.ocrProcessingFeedbackType(processingResult));
        }
      }
    } catch (error) {
      console.error('Index recognize screen capture failed: ' + JSON.stringify(error));
      const businessError = error as BusinessErrorLike;
      if (businessError.code === 201) {
        this.doubleTouchEnabled = false;
        await this.saveInterfaceToggle('doubleTouch', false);
        this.showToast('截屏权限已失效，请在自动填入设置中重新开启', 'warning');
      } else {
        this.showToast('屏幕截取或文字识别失败，请重试', 'danger');
      }
    } finally {
      this.finishOcrLoading(loadingSessionKey);
      if (temporaryPhotoUri.length > 0) {
        await this.deleteTemporarySharedPhoto(temporaryPhotoUri);
      }
      this.smartKeyCaptureInProgress = false;
    }
  }

  private handleRootKeyEvent(event: KeyEvent): boolean {
    if (event.type !== KeyType.Down || event.keyCode !== KeyCode.KEYCODE_DAGGER_DOUBLE_CLICK) {
      return false;
    }
    this.recognizeScreenCaptureIntoDraft();
    return true;
  }

  private defaultDiaryTitle(): string {
    const today: Date = new Date();
    return today.getFullYear().toString() + '年' + (today.getMonth() + 1).toString() + '月' +
      today.getDate().toString() + '日 · 随想笔记';
  }

  private async saveDiary(showFeedback: boolean = true): Promise<boolean> {
    if (showFeedback) {
      this.diarySaveFeedbackRequested = true;
    }
    if (this.diarySaveTask === null) {
      this.diarySaveTask = this.persistDiaryDraft();
    }
    const saveTask: Promise<DiarySaveResult> = this.diarySaveTask;
    try {
      const result: DiarySaveResult = await saveTask;
      if (this.diarySaveTask === saveTask && this.diarySaveFeedbackRequested) {
        if (result.success) {
          this.editorPhotoPreviewOpen = false;
          this.showToast(result.updated ? '笔记已修改' : '笔记保存成功', 'success');
        } else if (result.emptyDraft) {
          this.showToast('标题、正文或照片至少填写一项', 'danger');
        } else {
          this.showToast('保存失败，请稍后重试', 'danger');
        }
      }
      return result.success;
    } finally {
      if (this.diarySaveTask === saveTask) {
        this.diarySaveTask = null;
        this.diarySaveFeedbackRequested = false;
      }
    }
  }

  private async persistDiaryDraft(): Promise<DiarySaveResult> {
    const body = this.draftBody.trim();
    const title = this.draftTitle.trim();
    const folderName: string = this.normalizeFolderName(this.draftFolderName);
    const savedPhotoUri: string = this.draftPhotoUri;
    const savedPhotoUris: string[] = this.normalizePhotoUris(this.draftPhotoUris);
    const savedHasPhoto: boolean = this.hasDraftPhotoAssets();
    if (title.length === 0 && body.length === 0 && !savedHasPhoto) {
      return { success: false, updated: false, emptyDraft: true };
    }
    const finalTitle = title.length > 0 ? title : this.defaultDiaryTitle();
    const finalBody = body;
    const savedAt: number = Date.now();
    const savedDateText: string = this.makeDateText(savedAt);
    let savedDiaryId: string = this.editingId;
    const next: DiaryEntry[] = [];
    let updated = false;
    this.diaries.forEach((entry: DiaryEntry) => {
      if (entry.id === this.editingId && this.editingId.length > 0) {
        const createdAt: number = typeof entry.createdAt === 'number' && entry.createdAt > 0 ?
          entry.createdAt : entry.dateMs;
        next.push({
          id: entry.id,
          title: finalTitle,
          body: finalBody,
          folderName: folderName,
          dateText: savedDateText,
          dateMs: savedAt,
          createdAt: createdAt,
          updatedAt: savedAt,
          mood: this.draftMood,
          weather: this.draftWeather,
           isToday: true,
           isThisWeek: true,
           isFavorite: this.draftFavorite,
           isPrivate: entry.isPrivate === true,
           wordCount: this.countWords(finalBody),
          hasPhoto: savedHasPhoto,
          photoInBody: this.draftPhotoInBody && savedHasPhoto,
          photoUri: savedPhotoUri,
          photoUris: savedPhotoUris,
          thumbnailPhotoIndex: Math.max(0, Math.min(Math.floor(this.draftThumbnailPhotoIndex),
            Math.max(savedPhotoUris.length - 1, 0))),
          thumbnailScale: this.draftThumbnailScale,
          thumbnailOffsetX: this.draftThumbnailOffsetX,
          thumbnailOffsetY: this.draftThumbnailOffsetY,
          thumbnailPhotoAspect: this.draftThumbnailPhotoAspect,
          photoX: this.draftPhotoX,
          photoY: this.draftPhotoY,
          photoWidth: this.draftPhotoWidth,
          photoHeight: this.draftPhotoHeight,
          photoRotation: this.draftPhotoRotation,
          photoStyle: this.selectedPhotoStyle
        });
        updated = true;
      } else {
        next.push(this.cloneEntry(entry));
      }
    });
    if (!updated) {
      const createdAt: number = savedAt;
      savedDiaryId = 'diary-' + createdAt.toString();
      next.unshift({
        id: savedDiaryId,
        title: finalTitle,
        body: finalBody,
        folderName: folderName,
        dateText: savedDateText,
        dateMs: createdAt,
        createdAt: createdAt,
        updatedAt: savedAt,
        mood: this.draftMood,
        weather: this.draftWeather,
         isToday: true,
         isThisWeek: true,
         isFavorite: this.draftFavorite,
         isPrivate: false,
         wordCount: this.countWords(finalBody),
        hasPhoto: savedHasPhoto,
        photoInBody: this.draftPhotoInBody && savedHasPhoto,
        photoUri: savedPhotoUri,
        photoUris: savedPhotoUris,
        thumbnailPhotoIndex: Math.max(0, Math.min(Math.floor(this.draftThumbnailPhotoIndex),
          Math.max(savedPhotoUris.length - 1, 0))),
        thumbnailScale: this.draftThumbnailScale,
        thumbnailOffsetX: this.draftThumbnailOffsetX,
        thumbnailOffsetY: this.draftThumbnailOffsetY,
        thumbnailPhotoAspect: this.draftThumbnailPhotoAspect,
        photoX: this.draftPhotoX,
        photoY: this.draftPhotoY,
        photoWidth: this.draftPhotoWidth,
        photoHeight: this.draftPhotoHeight,
        photoRotation: this.draftPhotoRotation,
        photoStyle: this.selectedPhotoStyle
      });
    }
    const sortedNext: DiaryEntry[] = DiaryStatsUtils.sortDiariesByLatest(next);
    this.diaries = sortedNext;
    const nextFolders: string[] = this.mergeFolderNames(this.diaryFolders);
    this.diaryFolders = nextFolders;
    this.saveDiaryFolders(nextFolders);
    const saved: boolean = await this.saveLocalDiaries(sortedNext);
    if (!saved) {
      return { success: false, updated: updated, emptyDraft: false };
    }
    this.editingId = savedDiaryId;
    this.draftTitle = finalTitle;
    this.draftBody = finalBody;
    this.draftFolderName = folderName;
    this.draftDateMs = savedAt;
    return { success: true, updated: updated, emptyDraft: false };
  }

  private deleteDiary(id: string): void {
    if (id.length === 0) {
      this.editorPhotoPreviewOpen = false;
      this.editorVisible = false;
      return;
    }
    const matches: DiaryEntry[] = this.diaries.filter((entry: DiaryEntry) => entry.id === id);
    if (matches.length === 0) {
      return;
    }
    const recycled: RecycleBinEntry = {
      diary: this.cloneEntry(matches[0]),
      deletedAt: Date.now()
    };
    this.recycleBinItems = [recycled, ...this.recycleBinItems.filter((entry: RecycleBinEntry): boolean => {
      return entry.diary.id !== id;
    })];
    this.saveRecycleBin(this.recycleBinItems);
    this.diaries = this.diaries.filter((entry: DiaryEntry) => entry.id !== id);
    this.saveLocalDiaries(this.diaries);
    this.editorPhotoPreviewOpen = false;
    this.editorVisible = false;
    this.draftPhotoUris = [];
    this.draftPhotoUri = '';
    this.draftThumbnailPhotoIndex = 0;
    this.draftThumbnailScale = 1;
    this.draftThumbnailOffsetX = 0;
    this.draftThumbnailOffsetY = 0;
    this.draftThumbnailPhotoAspect = 1;
    this.draftHasPhoto = false;
    this.draftPhotoInBody = false;
    this.showToast('笔记已移至回收站', 'info');
  }

  private moveAllDiariesToRecycleBin(): void {
    if (this.diaries.length === 0) {
      this.showToast('暂无笔记可清空', 'info');
      return;
    }
    const privateDiaries: DiaryEntry[] = this.diaries.filter((entry: DiaryEntry): boolean => entry.isPrivate === true);
    const ordinaryDiaries: DiaryEntry[] = this.diaries.filter((entry: DiaryEntry): boolean => entry.isPrivate !== true);
    if (ordinaryDiaries.length === 0) {
      this.showToast('\u9690\u79c1\u7b14\u8bb0\u4ecd\u4fdd\u7559\u5728\u9690\u79c1\u5e93', 'info');
      return;
    }
    const deletedAt: number = Date.now();
    const activeIds: string[] = ordinaryDiaries.map((entry: DiaryEntry): string => entry.id);
    const retained: RecycleBinEntry[] = this.recycleBinItems.filter((entry: RecycleBinEntry): boolean => {
      return activeIds.indexOf(entry.diary.id) < 0;
    });
    const moved: RecycleBinEntry[] = ordinaryDiaries.map((entry: DiaryEntry): RecycleBinEntry => {
      return { diary: this.cloneEntry(entry), deletedAt: deletedAt };
    });
    this.recycleBinItems = [...moved, ...retained];
    this.diaries = privateDiaries;
    this.saveLocalDiaries(privateDiaries);
    this.saveRecycleBin(this.recycleBinItems);
    this.showToast(privateDiaries.length > 0 ?
      '\u666e\u901a\u7b14\u8bb0\u5df2\u79fb\u81f3\u56de\u6536\u7ad9\uff0c\u9690\u79c1\u7b14\u8bb0\u4ecd\u4fdd\u7559\u5728\u9690\u79c1\u5e93' :
      '\u6240\u6709\u7b14\u8bb0\u5df2\u79fb\u81f3\u56de\u6536\u7ad9', 'info');
  }

  private restoreDiaryFromRecycleBin(id: string): void {
    const matches: RecycleBinEntry[] = this.recycleBinItems.filter((entry: RecycleBinEntry): boolean => {
      return entry.diary.id === id;
    });
    if (matches.length === 0) {
      return;
    }
    const restored: DiaryEntry = this.cloneEntry(matches[0].diary);
    const retainedDiaries: DiaryEntry[] = this.diaries.filter((entry: DiaryEntry): boolean => entry.id !== id);
    this.diaries = DiaryStatsUtils.sortDiariesByLatest([restored, ...retainedDiaries]);
    this.recycleBinItems = this.recycleBinItems.filter((entry: RecycleBinEntry): boolean => entry.diary.id !== id);
    this.saveLocalDiaries(this.diaries);
    this.saveRecycleBin(this.recycleBinItems);
    this.showToast('笔记已恢复', 'success');
  }

  private deleteDiaryPermanently(id: string): void {
    this.recycleBinItems = this.recycleBinItems.filter((entry: RecycleBinEntry): boolean => entry.diary.id !== id);
    this.saveRecycleBin(this.recycleBinItems);
    this.showToast('笔记已永久删除', 'danger');
  }

  private requestDeleteDiaryPermanently(id: string): void {
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: '永久删除笔记',
        message: '永久删除后无法恢复，确定继续吗？',
        buttons: [
          { text: '取消', color: this.textSecondary() },
          { text: '永久删除', color: '#EF4444' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.deleteDiaryPermanently(id);
        }
      }).catch(() => {});
    } catch (error) {
      console.error('requestDeleteDiaryPermanently showDialog failed: ' + JSON.stringify(error));
    }
  }

  private requestClearRecycleBin(): void {
    if (this.recycleBinItems.length === 0) {
      return;
    }
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: '清空回收站',
        message: '回收站中的 ' + this.recycleBinItems.length.toString() + ' 篇笔记将被永久删除，且无法恢复。',
        buttons: [
          { text: '取消', color: this.textSecondary() },
          { text: '清空', color: '#EF4444' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.recycleBinItems = [];
          this.saveRecycleBin([]);
          this.showToast('回收站已清空', 'danger');
        }
      }).catch(() => {});
    } catch (error) {
      console.error('requestClearRecycleBin showDialog failed: ' + JSON.stringify(error));
    }
  }

  private requestDeleteDiary(id: string): void {
    if (id.length === 0) {
      return;
    }
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: '确认删除',
        message: '删除后可在设置的回收站中恢复，确定继续吗？',
        buttons: [
          { text: '取消', color: this.textSecondary() },
          { text: '删除', color: '#EF4444' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.deleteDiary(id);
        }
      }).catch(() => {});
    } catch (error) {
      console.error('requestDeleteDiary showDialog failed: ' + JSON.stringify(error));
    }
  }

  private toggleFavorite(id: string): void {
    const next: DiaryEntry[] = [];
    this.diaries.forEach((entry: DiaryEntry) => {
      const item = this.cloneEntry(entry);
      if (entry.id === id) {
        item.isFavorite = !entry.isFavorite;
        this.showToast(item.isFavorite ? '已加入收藏' : '已取消收藏', item.isFavorite ? 'success' : 'info');
      }
      next.push(item);
    });
    this.diaries = next;
    this.diaryFolders = this.mergeFolderNames(this.diaryFolders);
    this.saveDiaryFolders(this.diaryFolders);
    this.saveLocalDiaries(next);
  }

  private setEditorDraftFavorite(value: boolean): void {
    this.draftFavorite = value;
    if (this.editingId.length === 0) {
      return;
    }
    let changed = false;
    const next: DiaryEntry[] = [];
    this.diaries.forEach((entry: DiaryEntry) => {
      const item = this.cloneEntry(entry);
      if (entry.id === this.editingId && item.isFavorite !== value) {
        item.isFavorite = value;
        changed = true;
      }
      next.push(item);
    });
    if (!changed) {
      return;
    }
    this.diaries = next;
    this.saveLocalDiaries(next);
    this.showToast(value ? '已加入收藏' : '已取消收藏', value ? 'success' : 'info');
  }

  private setEditorDraftMeta(type: string, value: string): void {
    if (type === 'weather') {
      this.draftWeather = value;
    } else {
      this.draftMood = value;
    }
    if (this.editingId.length === 0) {
      return;
    }
    let changed = false;
    const changedAt: number = Date.now();
    const next: DiaryEntry[] = [];
    this.diaries.forEach((entry: DiaryEntry) => {
      const item = this.cloneEntry(entry);
      if (entry.id === this.editingId) {
        if (type === 'weather' && item.weather !== value) {
          item.weather = value;
          changed = true;
        } else if (type !== 'weather' && item.mood !== value) {
          item.mood = value;
          changed = true;
        }
        if (changed) {
          item.dateMs = changedAt;
          item.updatedAt = changedAt;
          item.dateText = this.makeDateText(changedAt);
          item.isToday = true;
          item.isThisWeek = true;
          this.draftDateMs = changedAt;
        }
      }
      next.push(item);
    });
    if (!changed) {
      return;
    }
    this.diaries = next;
    this.saveLocalDiaries(next);
  }

  private addSyncLog(title: string, detail: string, type: string): void {
    const createdAt: number = Date.now();
    const next: SyncLog[] = [{
      createdAt: createdAt,
      time: this.makeDateText(createdAt),
      title: title,
      detail: detail,
      type: type
    }];
    this.syncLogs.forEach((item: SyncLog) => {
      if (next.length < 12) {
        next.push(item);
      }
    });
    this.syncLogs = next;
    this.syncLogRefreshKey = this.syncLogRefreshKey + 1;
    this.saveSyncLogs(next);
  }

  private async saveSyncLogs(value: SyncLog[]): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    await ZapNotePreferencesService.setSyncLogs(value);
  }

  private normalizeRemotePath(value: string): string {
    const trimmed: string = value.trim();
    if (trimmed.length === 0 || trimmed === '/') {
      return '';
    }
    const path: string = trimmed.startsWith('/') ? trimmed : '/' + trimmed;
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  private getRemotePathForSync(): string {
    const normalized: string = this.normalizeRemotePath(this.webdavRemotePath);
    return normalized.length > 0 ? normalized : ZapNotePreferencesService.DEFAULT_WEBDAV_REMOTE_PATH;
  }

  private remoteBackupFilePath(): string {
    const path: string = this.getRemotePathForSync();
    return path.endsWith('/') ? path + ZapNoteBackupService.BACKUP_FILE_NAME :
      path + '/' + ZapNoteBackupService.BACKUP_FILE_NAME;
  }

  private isWebdavConfigReady(): boolean {
    return this.webdavUrl.trim().length > 0 && this.webdavUser.trim().length > 0 &&
      this.webdavPass.length > 0 && this.getRemotePathForSync().length > 0;
  }

  private async saveWebdavConfig(showSuccess: boolean = true): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      this.showToast('配置保存失败，请稍后重试', 'danger');
      return;
    }
    this.webdavRemotePath = this.getRemotePathForSync();
    await ZapNotePreferencesService.setWebDavServerUrl(this.webdavUrl.trim());
    await ZapNotePreferencesService.setWebDavRemotePath(this.webdavRemotePath);
    await ZapNotePreferencesService.setWebDavUsername(this.webdavUser.trim());
    await ZapNotePreferencesService.setWebDavPassword(this.webdavPass);
    if (showSuccess) {
      this.showToast('WebDAV 配置已保存', 'success');
    }
  }

  private async testWebdav(): Promise<void> {
    if (!this.isWebdavConfigReady()) {
      this.showToast('请先填写服务器地址、路径、账号和应用令牌', 'danger');
      return;
    }
    await this.saveWebdavConfig(false);
    this.showToast('正在验证 WebDAV 连接...', 'info');
    const result: WebDavConnectionTestResult = await WebDavService.testConnection(
      this.webdavUrl,
      this.webdavRemotePath,
      this.webdavUser,
      this.webdavPass
    );
    this.addSyncLog('连接验证', result.message, result.success ? 'success' : 'warning');
    this.showToast(result.message, result.success ? 'success' : 'danger');
  }

  private async pushSync(): Promise<void> {
    if (!this.isWebdavConfigReady()) {
      this.showToast('请先完成 WebDAV 配置', 'danger');
      return;
    }
    try {
    await this.saveWebdavConfig(false);
    const scope: SyncDataScope = this.normalizeSyncDataScope(this.syncDataScope);
    const includeDiaries: boolean = this.syncIncludesDiaries(scope);
    const includeSettings: boolean = this.syncIncludesSettings(scope);
    const backupSettings: ZapNoteBackupSettings | undefined = includeSettings ? await this.currentBackupSettings() : undefined;
    this.showToast('正在推送' + this.syncDataScopeLabel(scope) + '...', 'info');
    const exportResult = await ZapNoteBackupService.exportBackupZip(getContext(this) as common.Context,
      includeDiaries ? this.diaries : [],
      Date.now(),
      backupSettings,
      scope,
      includeDiaries ? this.diaryFolders : []
    );
    const result: WebDavTransferResult = await WebDavService.uploadBinaryFile(
      this.webdavUrl,
      this.webdavRemotePath,
      this.webdavUser,
      this.webdavPass,
      ZapNoteBackupService.BACKUP_FILE_NAME,
      this.readBackupFileBytes(exportResult.zipPath)
    );
    if (result.success) {
      const diaryText: string = includeDiaries ? this.diaries.length.toString() + ' 篇笔记' : '';
      const settingsText: string = includeSettings ? '软件设置' : '';
      const joinText: string = diaryText.length > 0 && settingsText.length > 0 ? diaryText + '、' + settingsText :
        diaryText + settingsText;
      this.addSyncLog('推送成功', '已上传' + joinText + '到 ' + this.remoteBackupFilePath(), 'success');
      const skippedText: string = exportResult.skippedPhotoCount > 0 ?
        '，跳过 ' + exportResult.skippedPhotoCount.toString() + ' 张图片' : '';
      this.showToast(this.syncDataScopeLabel(scope) + '已推送到云端' + skippedText,
        exportResult.skippedPhotoCount > 0 ? 'warning' : 'success');
      return;
    }
    this.addSyncLog('推送失败', result.message, 'warning');
    this.showToast(result.message, 'danger');
    } catch (error) {
      console.error('Index pushSync failed: ' + JSON.stringify(error));
      this.addSyncLog('推送失败', '生成备份文件时发生异常', 'warning');
      this.showToast('生成备份文件失败，已停止本次推送', 'danger');
    }
  }

  private async pullSync(): Promise<void> {
    if (!this.isWebdavConfigReady()) {
      this.showToast('请先完成 WebDAV 配置', 'danger');
      return;
    }
    await this.saveWebdavConfig(false);
    this.showToast('正在拉取云端备份...', 'info');
    let result: WebDavTransferResult = await WebDavService.downloadBinaryFile(
      this.webdavUrl,
      this.webdavRemotePath,
      this.webdavUser,
      this.webdavPass,
      ZapNoteBackupService.BACKUP_FILE_NAME
    );
    let zipRestore: ZapNoteBackupZipRestoreResult | null = null;
    if (!result.success && result.responseCode === 404) {
      result = await WebDavService.downloadTextFile(this.webdavUrl, this.webdavRemotePath, this.webdavUser, this.webdavPass,
        ZapNoteBackupService.LEGACY_BACKUP_FILE_NAME);
    } else if (result.success && result.binaryContent !== undefined) {
      try {
        const zipPath: string = (getContext(this) as common.Context).cacheDir + '/zapnote-webdav-' + Date.now().toString() + '.zip';
        this.writeBackupFileBytes(zipPath, result.binaryContent);
        zipRestore = await ZapNoteBackupService.restoreBackupZip(getContext(this) as common.Context, zipPath);
      } catch (error) {
        console.error('Index pullSync unzip failed: ' + JSON.stringify(error));
        result = { success: false, message: '云端 ZIP 备份损坏或无法解压', responseCode: 0, content: '', fileName: ZapNoteBackupService.BACKUP_FILE_NAME };
      }
    }
    if (!result.success) {
      this.addSyncLog('拉取失败', result.message, 'warning');
      this.showToast(result.message, 'danger');
      return;
    }
    try {
      const scope: SyncDataScope = this.normalizeSyncDataScope(this.syncDataScope);
      const backupContent: string = zipRestore === null ? result.content : zipRestore.content;
      const backupTimeText: string = ZapNoteBackupService.backupCreatedAtText(backupContent);
      let restoredDiaryText: string = '';
      let restoredSettingsText: string = '';
      if (this.syncIncludesDiaries(scope) && ZapNoteBackupService.hasDiaryData(backupContent)) {
        const restoredDiaries: DiaryEntry[] = zipRestore === null ? ZapNoteBackupService.restoreBackupJson(
          getContext(this) as common.Context, backupContent) : zipRestore.diaries;
        const restoredFolders: string[] = zipRestore === null ? ZapNoteBackupService.restoreDiaryFolders(backupContent) : zipRestore.diaryFolders;
        if (this.syncRestoreStrategy === 'overwrite') {
          const summary: ZapNoteRestoreSummary = ZapNoteBackupService.summarize(restoredDiaries);
          this.diaries = restoredDiaries;
          await this.saveLocalDiaries(restoredDiaries, false);
          this.diaryFolders = this.mergeFolderNames(restoredFolders);
          await this.saveDiaryFolders(this.diaryFolders);
          restoredDiaryText = '已覆盖恢复 ' + summary.diaryCount.toString() + ' 篇笔记，' +
            summary.wordCount.toString() + ' 字';
        } else {
          const localCount: number = this.diaries.length;
          const mergedDiaries: DiaryEntry[] = this.mergeDiaries(this.diaries, restoredDiaries);
          const summary: ZapNoteRestoreSummary = ZapNoteBackupService.summarize(mergedDiaries);
          const addedCount: number = Math.max(mergedDiaries.length - localCount, 0);
          this.diaries = mergedDiaries;
          await this.saveLocalDiaries(mergedDiaries, false);
          this.diaryFolders = this.mergeFolderNames([...this.diaryFolders, ...restoredFolders]);
          await this.saveDiaryFolders(this.diaryFolders);
          restoredDiaryText = '已合并 ' + restoredDiaries.length.toString() + ' 篇云端笔记，新增 ' +
            addedCount.toString() + ' 篇，当前共 ' + summary.diaryCount.toString() + ' 篇，' +
            summary.wordCount.toString() + ' 字';
        }
      }
      if (this.syncIncludesSettings(scope) && ZapNoteBackupService.hasSettingsData(backupContent)) {
        const restoredSettings: ZapNoteBackupSettings | null = ZapNoteBackupService.restoreSettings(backupContent);
        if (restoredSettings !== null) {
          const restoredSettingCount: number = await this.applyBackupSettings(restoredSettings);
          restoredSettingsText = '已恢复 ' + restoredSettingCount.toString() + ' 项软件设置';
        }
      }
      if (restoredDiaryText.length === 0 && restoredSettingsText.length === 0) {
        this.addSyncLog('拉取失败', '云端备份不包含所选同步内容：' + this.syncDataScopeLabel(scope), 'warning');
        this.showToast('云端备份不包含所选同步内容', 'danger');
        return;
      }
      const resultText: string = restoredDiaryText.length > 0 && restoredSettingsText.length > 0 ?
        restoredDiaryText + '；' + restoredSettingsText : restoredDiaryText + restoredSettingsText;
      this.backupPreview = '已拉取云端备份：' + resultText + '。' + this.backupTimeLine(backupTimeText);
      this.addSyncLog('拉取成功', resultText, 'success');
      this.showToast(this.syncDataScopeLabel(scope) + '已从云端恢复', 'success');
    } catch (error) {
      console.error('Index pullSync restore failed: ' + JSON.stringify(error));
      this.addSyncLog('拉取失败', '云端备份格式不正确或解析失败', 'warning');
      this.showToast('云端备份格式不正确，无法恢复', 'danger');
    }
  }

  private async exportBackup(): Promise<void> {
    try {
    const backupCreatedAt: number = Date.now();
    const backupSettings: ZapNoteBackupSettings = await this.currentBackupSettings();
    const context = getContext(this) as common.Context;
    const exportResult = await ZapNoteBackupService.exportBackupZip(context,
      this.diaries,
      backupCreatedAt,
      backupSettings,
      'all',
      this.diaryFolders
    );
    const options = new picker.DocumentSaveOptions();
    options.newFileNames = [exportResult.fileName];
    const documentPicker = new picker.DocumentViewPicker(context);
    let uris: string[] = [];
    try {
      uris = await documentPicker.save(options);
    } catch (error) {
      console.error('Index exportBackup picker failed: ' + JSON.stringify(error));
      this.showToast('未选择备份保存位置', 'warning');
      return;
    }
    if (uris.length === 0) {
      this.showToast('未选择备份保存位置', 'warning');
      return;
    }
    try {
      if (!this.copyFileForBackup(exportResult.zipPath, uris[0])) {
        throw new Error('copy zip failed');
      }
      this.backupPreview = '已导出 ZIP：' + exportResult.fileName + '\n备份内容：' +
        this.diaries.length.toString() + ' 篇笔记，' + this.totalWords().toString() +
        ' 字，收藏 ' + this.favoriteCount().toString() + ' 篇，软件设置，照片 ' + exportResult.photoCount.toString() + ' 张。';
      const skippedText: string = exportResult.skippedPhotoCount > 0 ?
        '，跳过 ' + exportResult.skippedPhotoCount.toString() + ' 张照片' : '';
      this.addSyncLog('本地备份导出', '已导出 ' + this.diaries.length.toString() + ' 篇笔记' + skippedText,
        exportResult.skippedPhotoCount > 0 ? 'warning' : 'success');
      this.showToast('备份文件已导出' + skippedText,
        exportResult.skippedPhotoCount > 0 ? 'warning' : 'success');
    } catch (error) {
      console.error('Index exportBackup write failed: ' + JSON.stringify(error));
      this.showToast('备份文件写入失败', 'danger');
    }
    } catch (error) {
      console.error('Index exportBackup failed: ' + JSON.stringify(error));
      this.addSyncLog('本地备份导出失败', '生成备份文件时发生异常', 'warning');
      this.showToast('生成备份文件失败，已停止导出', 'danger');
    }
  }

  private diagnosticLogFileName(createdAt: number): string {
    const date: Date = new Date(createdAt);
    const month: string = this.pad2(date.getMonth() + 1);
    const day: string = this.pad2(date.getDate());
    const hour: string = this.pad2(date.getHours());
    const minute: string = this.pad2(date.getMinutes());
    const second: string = this.pad2(date.getSeconds());
    return 'zapnote-diagnostic-' + date.getFullYear().toString() +
      month + day + '-' + hour + minute + second + '.txt';
  }

  private diagnosticLogContent(createdAt: number): string {
    const photoCount: number = this.diaries.reduce((count: number, entry: DiaryEntry) => {
      const paths: string[] = Array.isArray(entry.photoUris) ? entry.photoUris :
        (entry.photoUri.trim().length > 0 ? [entry.photoUri] : []);
      return count + paths.length;
    }, 0);
    const lines: string[] = [
      'ZapNote 诊断日志',
      '生成时间: ' + this.makeDateText(createdAt),
      '笔记数量: ' + this.diaries.length.toString(),
      '收藏数量: ' + this.favoriteCount().toString(),
      '字数总计: ' + this.totalWords().toString(),
      '图片引用数量: ' + photoCount.toString(),
      '同步范围: ' + this.syncDataScopeLabel(this.normalizeSyncDataScope(this.syncDataScope)),
      '备份照片策略: ZIP 备份包含日记照片；新加入照片默认 JPEG 质量 80，透明 PNG 保持 PNG。',
      '',
      '最近同步记录:'
    ];
    this.syncLogs.forEach((item: SyncLog) => {
      const itemTime: string = item.time || this.makeDateText(
        item.createdAt === undefined ? createdAt : item.createdAt);
      lines.push(itemTime + ' [' + item.type + '] ' + item.title + ': ' + item.detail);
    });
    return lines.join('\n');
  }

  private async exportDiagnosticLog(): Promise<void> {
    const createdAt: number = Date.now();
    const fileName: string = this.diagnosticLogFileName(createdAt);
    const options = new picker.DocumentSaveOptions();
    options.newFileNames = [fileName];
    let uris: string[] = [];
    try {
      uris = await new picker.DocumentViewPicker(getContext(this) as common.Context).save(options);
      if (uris.length === 0) {
        this.showToast('未选择日志保存位置', 'warning');
        return;
      }
      const file: fileIo.File = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(file.fd, this.diagnosticLogContent(createdAt));
      } finally {
        fileIo.closeSync(file);
      }
      this.showToast('诊断日志已导出', 'success');
    } catch (error) {
      console.error('Index exportDiagnosticLog failed: ' + JSON.stringify(error));
      this.showToast('诊断日志写入失败', 'danger');
    }
  }

  private async importBackup(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    const options = new picker.DocumentSelectOptions();
    options.fileSuffixFilters = ['ZapNote ZIP 备份|.zip', 'JSON 旧备份|.json'];
    options.maxSelectNumber = 1;
    let uris: string[] = [];
    try {
      uris = await new picker.DocumentViewPicker(context).select(options);
    } catch (error) {
      console.error('Index importBackup picker failed: ' + JSON.stringify(error));
      this.showToast('未选择备份文件', 'warning');
      return;
    }
    if (uris.length === 0) {
      this.showToast('未选择备份文件', 'warning');
      return;
    }
    try {
      const isZip: boolean = uris[0].toLowerCase().split('?')[0].endsWith('.zip');
      const zipRestore: ZapNoteBackupZipRestoreResult | null = isZip ?
        await ZapNoteBackupService.restoreBackupZip(context, uris[0]) : null;
      const content: string = zipRestore === null ? this.readBackupFileText(uris[0]) : zipRestore.content;
      const restoredFolders: string[] = ZapNoteBackupService.restoreDiaryFolders(content);
      const restoredDiaries: DiaryEntry[] = zipRestore !== null ? zipRestore.diaries : ZapNoteBackupService.hasDiaryData(content) ?
        ZapNoteBackupService.restoreBackupJson(context, content) : [];
      if (restoredDiaries.length > 0 || restoredFolders.length > 0) {
        this.diaries = this.mergeDiaries(this.diaries, restoredDiaries);
        if (restoredDiaries.length > 0) {
          await this.saveLocalDiaries(this.diaries, false);
        }
        this.diaryFolders = this.mergeFolderNames([...this.diaryFolders, ...restoredFolders]);
        await this.saveDiaryFolders(this.diaryFolders);
      }
      const restoredSettings: ZapNoteBackupSettings | null = ZapNoteBackupService.restoreSettings(content);
      const restoredSettingCount: number = restoredSettings === null ? 0 : await this.applyBackupSettings(restoredSettings);
      if (restoredDiaries.length === 0 && restoredFolders.length === 0 && restoredSettingCount === 0) {
        this.backupPreview = '已读取文件：' + uris[0] + '\n备份文件中没有可恢复的笔记或设置。';
        this.showToast('备份文件中没有可恢复的数据', 'warning');
        return;
      }
      const summary: ZapNoteRestoreSummary = ZapNoteBackupService.summarize(restoredDiaries);
      this.backupPreview = '已导入文件：' + uris[0] + '\n恢复 ' + summary.diaryCount.toString() +
        ' 篇笔记，' + restoredSettingCount.toString() + ' 项设置。' + (zipRestore === null ? '' :
          '\n恢复照片 ' + zipRestore.restoredPhotoCount.toString() + ' 张，跳过 ' + zipRestore.skippedPhotoCount.toString() + ' 张。');
      this.showToast('备份文件已导入', 'success');
    } catch (error) {
      console.error('Index importBackup restore failed: ' + JSON.stringify(error));
      this.showToast('备份文件格式不正确或读取失败', 'danger');
    }
  }

  private copyFileForBackup(sourceUri: string, targetUri: string): boolean {
    let source: fileIo.File | null = null;
    let target: fileIo.File | null = null;
    try {
      source = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY);
      target = fileIo.openSync(targetUri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      fileIo.copyFileSync(source.fd, target.fd);
      return true;
    } catch (error) {
      console.error('Index copy backup file failed: ' + JSON.stringify(error));
      return false;
    } finally {
      if (source !== null) { try { fileIo.closeSync(source); } catch (error) { console.error(JSON.stringify(error)); } }
      if (target !== null) { try { fileIo.closeSync(target); } catch (error) { console.error(JSON.stringify(error)); } }
    }
  }

  private readBackupFileBytes(path: string): ArrayBuffer {
    const file: fileIo.File = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
    try {
      const stat = fileIo.statSync(file.fd);
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      let offset: number = 0;
      while (offset < stat.size) {
        const read: number = fileIo.readSync(file.fd, buffer, { offset: offset, length: stat.size - offset });
        if (read <= 0) { break; }
        offset += read;
      }
      return offset === stat.size ? buffer : buffer.slice(0, offset);
    } finally {
      fileIo.closeSync(file);
    }
  }

  private writeBackupFileBytes(path: string, bytes: ArrayBuffer): void {
    const file: fileIo.File = fileIo.openSync(path,
      fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, bytes);
    } finally {
      fileIo.closeSync(file);
    }
  }

  private readBackupFileText(uri: string): string {
    let file: fileIo.File | null = null;
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      if (!stat || stat.size <= 0) {
        return '';
      }
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      let offset: number = 0;
      while (offset < stat.size) {
        const bytesRead: number = fileIo.readSync(file.fd, buffer, {
          offset: offset,
          length: stat.size - offset
        });
        if (bytesRead <= 0) {
          break;
        }
        offset += bytesRead;
      }
      const data: ArrayBuffer = offset >= stat.size ? buffer : buffer.slice(0, offset);
      return util.TextDecoder.create('utf-8', { ignoreBOM: true })
        .decodeToString(new Uint8Array(data), { stream: false });
    } catch (error) {
      console.error('Index readBackupFileText fd read failed: ' + JSON.stringify(error));
      return fileIo.readTextSync(uri);
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          console.error('Index readBackupFileText close file failed: ' + JSON.stringify(error));
        }
      }
    }
  }

  private updateToggle(key: string, isOn: boolean): void {
    if (key === 'privacy') {
      this.updatePrivacyProtection(isOn);
    } else if (key === 'grip') {
      this.gripModeEnabled = isOn;
      this.saveAppearanceToggle('grip', isOn);
    } else if (key === 'autofill') {
      this.autoFillEnabled = isOn;
      this.saveInterfaceToggle('autofill', isOn);
    } else if (key === 'vibrate') {
      this.vibrateEnabled = isOn;
      this.saveInterfaceToggle('vibrate', isOn);
    } else if (key === 'doubleTouch') {
      this.doubleTouchEnabled = isOn;
      this.saveInterfaceToggle('doubleTouch', isOn);
      if (isOn) {
        this.prepareSmartKeyScreenCapture();
      } else {
        this.showToast('已关闭', 'success');
      }
      return;
    } else if (key === 'shared-photo-auto-recognize') {
      this.sharedPhotoAutoRecognizeEnabled = isOn;
      this.saveInterfaceToggle(key, isOn);
    } else if (key === 'shared-photo-save-to-album') {
      this.sharedPhotoSaveToAlbumEnabled = isOn;
      this.saveInterfaceToggle(key, isOn);
    } else if (key === 'enhanced-link-recognition') {
      if (!(this.engine === 'custom' || this.engine.startsWith('custom:'))) {
        return;
      }
      this.enhancedLinkRecognitionEnabled = isOn;
      this.saveInterfaceToggle(key, isOn);
    } else if (key === 'syncOnChange') {
      this.syncOnChange = isOn;
      this.saveSyncOnChange(isOn);
    }
    this.showToast(isOn ? '已开启' : '已关闭', 'success');
  }

  private async saveSyncInterval(value: string): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    await ZapNotePreferencesService.setSyncInterval(value);
  }

  private async updateSyncMode(mode: number): Promise<void> {
    this.syncMode = mode === 1 ? 1 : 0;
    this.syncOnChange = this.syncMode === 1;
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    await ZapNotePreferencesService.setWebDavSyncMode(this.syncMode);
    await ZapNotePreferencesService.setSyncOnChange(this.syncOnChange);
    this.startScheduledSyncTimer();
    this.showToast('同步方式已更新', 'success');
  }

  private async updateSyncTimes(times: string[]): Promise<void> {
    this.syncTimes = [...times].sort();
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    await ZapNotePreferencesService.setWebDavSyncTimes(this.syncTimes);
    this.startScheduledSyncTimer();
    this.showToast('同步时间已更新', 'success');
  }

  private async updateHistoryLimit(limit: number): Promise<void> {
    this.historyLimit = limit === 30 || limit === 100 ? limit : 10;
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    await ZapNotePreferencesService.setWebDavHistoryLimit(this.historyLimit);
    this.showToast('同步记录条数已更新', 'success');
  }

  private async updateSyncRestoreStrategy(strategy: string): Promise<void> {
    this.syncRestoreStrategy = strategy === 'overwrite' ? 'overwrite' : 'merge';
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    await ZapNotePreferencesService.setWebDavRestoreStrategy(this.syncRestoreStrategy);
    this.showToast('拉取策略已更新', 'success');
  }

  private async updateSyncDataScope(scope: SyncDataScope): Promise<void> {
    this.syncDataScope = this.normalizeSyncDataScope(scope);
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    await ZapNotePreferencesService.setWebDavSyncDataScope(this.syncDataScope);
    this.showToast('同步内容已更新', 'success');
  }

  private async saveSyncOnChange(value: boolean): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    await ZapNotePreferencesService.setSyncOnChange(value);
  }

  private updateGripSideByHoldingHand(status: motion.HoldingHandStatus): void {
    if (!this.gripModeEnabled) {
      return;
    }
    if (!canIUse('SystemCapability.MultimodalAwareness.Motion')) {
      return;
    }
    if (status === this.leftHandHeldStatus) {
      this.gripOnLeft = true;
      return;
    }
    if (status === this.rightHandHeldStatus) {
      this.gripOnLeft = false;
    }
  }

  private subscribeHoldingHandChange(): void {
    if (this.holdingHandSubscribed) {
      return;
    }
    try {
      if (canIUse('SystemCapability.MultimodalAwareness.Motion')) {
        motion.on('holdingHandChanged', this.handleHoldingHandChange);
        this.holdingHandSubscribed = true;
      }
    } catch (error) {
      console.error('Failed to subscribe holdingHandChanged: ' + JSON.stringify(error));
    }
  }

  private unsubscribeHoldingHandChange(): void {
    if (!this.holdingHandSubscribed) {
      return;
    }
    try {
      if (canIUse('SystemCapability.MultimodalAwareness.Motion')) {
        motion.off('holdingHandChanged', this.handleHoldingHandChange);
      }
    } catch (error) {
      console.error('Failed to unsubscribe holdingHandChanged: ' + JSON.stringify(error));
    }
    this.holdingHandSubscribed = false;
  }

  @Builder
  private TabItem(title: string, index: number) {
    Column() {
      this.TabIcon(index)

      Text(title)
        .fontSize(11)
        .lineHeight(14)
        .fontWeight(this.isCurrentTab(index) ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.isCurrentTab(index) ? this.selectedAccentColor : this.tabIconColor(index))
        .opacity(this.isCurrentTab(index) ? 1 : 0.78)
        .margin({ top: 2 })
        .height(14)
        .maxLines(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(56)
    .padding({ top: 4, bottom: 4 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .animation({
      duration: 220,
      curve: Curve.EaseOut
    })
  }

  @Builder
  private FloatingMainTabs() {
    HdsTabs({ barPosition: BarPosition.End, controller: this.tabsController, index: this.currentTab }) {
      TabContent() {
        this.HomePage()
      }
      .tabBar(this.TabItem('首页', 0))
      TabContent() {
        this.FavoritesPage()
      }
      .tabBar(this.TabItem('收藏', 1))
      TabContent() {
        Column() {
          ForEach([this.statsContentRefreshKey], (_: number) => {
            this.StatsPage()
          }, (key: number) => key.toString())
        }
        .width('100%')
        .height('100%')
      }
      .tabBar(this.TabItem('统计', 2))
      TabContent() {
        Column() {
          ForEach([this.settingsContentRefreshKey], (_: number) => {
            this.SettingsPage('main')
          }, (key: number) => key.toString())
        }
        .width('100%')
        .height('100%')
      }
      .tabBar(this.TabItem('设置', 3))
    }
    .width('100%')
    .height('100%')
    .vertical(false)
    .barPosition(BarPosition.End)
    .barOverlap(true)
    .barHeight(56)
    .barFloatingStyle(this.materialEffectMode === 0 ? {
      barBottomMargin: 28
    } : {
      barBottomMargin: 28,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: this.tabMaterialLevel()
      }
    })
    .visibility(this.editorVisible || this.privacyVaultVisible ||
      (this.currentTab === 3 && this.settingsPanel !== 'main') ?
      Visibility.None : Visibility.Visible)
    .animationDuration(320)
    .onTabBarClick((index: number) => {
      this.updateCurrentTab(index);
    })
    .onChange((index: number) => {
      this.updateCurrentTab(index);
    })
  }

  @Builder
  private HomePage() {
    HomeTabPage({
      diaries: this.normalDiaries(),
      searchQuery: this.searchQuery,
      tagOptions: this.folderOptions(),
      materialEffectMode: this.materialEffectMode,
      topPadding: this.topContentPadding(),
      bottomPadding: this.bottomContentPadding(),
      isDark: this.isDark(),
      pageBg: this.pageBg(),
      accentColor: this.selectedAccentColor,
      cardBg: this.cardBg(),
      inputBg: this.inputBg(),
      lineColor: this.lineColor(),
      textPrimary: this.textPrimary(),
      textSecondary: this.textSecondary(),
      textTertiary: this.textTertiary(),
      onSearchChange: (value: string) => {
        this.searchQuery = value;
      },
      onEdit: (id: string) => {
        this.openEditor(id);
      },
      onToggleFavorite: (id: string) => {
        this.toggleFavorite(id);
      },
      onDeleteRequest: (id: string) => {
        this.requestDeleteDiary(id);
      }
    })
  }

  @Builder
  private FavoritesPage() {
    FavoritesTabPage({
      diaries: this.normalDiaries(),
      tagOptions: this.folderOptions(),
      materialEffectMode: this.materialEffectMode,
      topPadding: this.topContentPadding(),
      bottomPadding: this.bottomContentPadding(),
      isDark: this.isDark(),
      pageBg: this.pageBg(),
      accentColor: this.selectedAccentColor,
      cardBg: this.cardBg(),
      inputBg: this.inputBg(),
      lineColor: this.lineColor(),
      textPrimary: this.textPrimary(),
      textSecondary: this.textSecondary(),
      textTertiary: this.textTertiary(),
      onEdit: (id: string) => {
        this.openEditor(id);
      },
      onToggleFavorite: (id: string) => {
        this.toggleFavorite(id);
      },
      onDeleteRequest: (id: string) => {
        this.requestDeleteDiary(id);
      }
    })
  }

  @Builder
  private StatsPage() {
    StatsTabPage({
      diaries: this.normalDiaries(),
      materialEffectMode: this.materialEffectMode,
      topPadding: this.topContentPadding(),
      bottomPadding: this.bottomContentPadding(),
      isDark: this.isDark(),
      pageBg: this.pageBg(),
      accentColor: this.selectedAccentColor,
      cardBg: this.cardBg(),
      lineColor: this.lineColor(),
      textPrimary: this.textPrimary(),
      textSecondary: this.textSecondary(),
      textTertiary: this.textTertiary()
    })
  }

  @Builder
  private SettingsPage(panel: SettingPanel) {
    SettingsTabPage({
      settingsPanel: panel,
      systemBackRequestKey: this.settingsBackRequestKey,
      diaryCount: this.normalDiaries().length,
      favoriteCount: this.favoriteCount(),
      totalWords: this.totalWords(),
      recycleBinItems: this.normalRecycleBinItems(),
      materialEffectMode: this.materialEffectMode,
      topPadding: this.topContentPadding(),
      bottomPadding: this.bottomContentPadding(),
      isDark: this.isDark(),
      pageBg: this.pageBg(),
      cardBg: this.cardBg(),
      inputBg: this.inputBg(),
      lineColor: this.lineColor(),
      textPrimary: this.textPrimary(),
      textSecondary: this.textSecondary(),
      textTertiary: this.textTertiary(),
      selectedAccentColor: this.selectedAccentColor,
      themeMode: this.themeMode,
      gripModeEnabled: this.gripModeEnabled,
      lightingMode: this.lightingMode,
      selectedPhotoStyle: this.selectedPhotoStyle,
      autoFillEnabled: this.autoFillEnabled,
      engine: this.engine,
      syncMode: this.syncMode,
      syncTimes: this.syncTimes,
      historyLimit: this.historyLimit,
      syncRestoreStrategy: this.syncRestoreStrategy,
      syncDataScope: this.syncDataScope,
      syncLogs: this.syncLogs,
      syncLogRefreshKey: this.syncLogRefreshKey,
      webdavUrl: this.webdavUrl,
      webdavUser: this.webdavUser,
      webdavPass: this.webdavPass,
      webdavRemotePath: this.webdavRemotePath,
      remoteBackupPath: this.remoteBackupFilePath(),
      privacyEnabled: this.privacyEnabled,
      vibrateEnabled: this.vibrateEnabled,
      doubleTouchEnabled: this.doubleTouchEnabled,
      doubleTouchAction: this.doubleTouchAction,
      sharedPhotoSaveMode: this.sharedPhotoSaveMode,
      sharedPhotoAutoRecognizeEnabled: this.sharedPhotoAutoRecognizeEnabled,
      sharedPhotoSaveToAlbumEnabled: this.sharedPhotoSaveToAlbumEnabled,
      enhancedLinkRecognitionEnabled: this.enhancedLinkRecognitionEnabled,
      backupPreview: this.backupPreview,
      huaweiAccountOpenId: this.huaweiAccountOpenId,
      huaweiAccountInfo: this.huaweiAccountInfo,
      legalPanelSource: this.settingsLegalPanelSource,
      onPanelChange: (panel: SettingPanel, legalPanelSource?: string) => {
        this.changeSettingsPanel(panel, legalPanelSource === undefined ? '' : legalPanelSource);
      },
      onToggleChange: (key: string, isOn: boolean) => {
        this.updateToggle(key, isOn);
      },
      onSyncModeChange: (mode: number) => {
        this.updateSyncMode(mode);
      },
      onSyncTimesChange: (times: string[]) => {
        this.updateSyncTimes(times);
      },
      onHistoryLimitChange: (limit: number) => {
        this.updateHistoryLimit(limit);
      },
      onSyncRestoreStrategyChange: (strategy: string) => {
        this.updateSyncRestoreStrategy(strategy);
      },
      onSyncDataScopeChange: (scope: SyncDataScope) => {
        this.updateSyncDataScope(scope);
      },
      onOpenPicker: (type: string, title: string) => {
        this.openPicker(type, title);
      },
      onValueChange: (key: string, value: string) => {
        this.updateValue(key, value);
      },
      onAccentColorChange: (color: string) => {
        this.selectedAccentColor = color;
        this.saveAppearanceValue('accent', color);
      },
      onPullSync: () => {
        this.pullSync();
      },
      onPushSync: () => {
        this.pushSync();
      },
      onTestWebdav: () => {
        this.testWebdav();
      },
      onSaveWebdav: () => {
        this.saveWebdavConfig();
        this.changeSettingsPanel('sync');
      },
      onWebdavInputChange: (key: string, value: string) => {
        if (key === 'url') {
          this.webdavUrl = value;
        } else if (key === 'user') {
          this.webdavUser = value;
        } else if (key === 'pass') {
          this.webdavPass = value;
        } else if (key === 'path') {
          this.webdavRemotePath = value;
        }
      },
      onExportBackup: () => {
        this.exportBackup();
      },
      onExportDiagnosticLog: () => {
        this.exportDiagnosticLog();
      },
      onImportBackupRequest: () => {
        this.askConfirm('import-backup', '导入备份', '请选择 ZIP 备份或旧 JSON 备份，内容会合并到当前本地数据。');
      },
      onClearDataRequest: () => {
        this.askConfirm('clear-data', '清空全部笔记', '当前所有本地笔记将移至回收站，确定继续吗？');
      },
      onClearAppDataRequest: () => {
        this.askConfirm('clear-app-data', '清除软件数据',
          '将清除本机笔记、回收站、匹配规则、自定义 AI 服务商、WebDAV 配置、同步日志、账号信息和所有偏好。不会删除云端备份或已导出的 ZIP/JSON 文件。确定继续吗？');
      },
      onRestoreFromRecycleBin: (id: string) => {
        this.restoreDiaryFromRecycleBin(id);
      },
      onDeleteFromRecycleBinRequest: (id: string) => {
        this.requestDeleteDiaryPermanently(id);
      },
      onClearRecycleBinRequest: () => {
        this.requestClearRecycleBin();
      },
      onHuaweiAccountLoginSuccess: (info: HuaweiAccountInfo) => {
        this.saveHuaweiAccountLogin(info);
      },
      onHuaweiAccountLogout: () => {
        this.logoutHuaweiAccount();
      },
      onHuaweiAccountRefresh: () => {
        this.refreshHuaweiAccountRuntimeState(true);
      },
      onOpenPrivacyVault: () => {
        this.openPrivacyVault();
      }
    })
  }

  @Builder
  private MetaPickerTab(type: string, label: string) {
    Button({ type: ButtonType.Capsule, stateEffect: true }) {
      Text(label)
        .width('100%')
        .height(34)
        .fontSize(14)
        .fontWeight(this.metaPickerType === type ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.metaPickerType === type ? Color.White : this.textSecondary())
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height(34)
    .backgroundColor(this.metaPickerType === type ? this.selectedAccentColor : '#00000000')
    .border({ radius: 17 })
    .onClick(() => {
      this.metaPickerType = type;
      this.pickerType = type;
    })
  }

  @Builder
  private MetaPickerOptionRow(option: ValueOption) {
    Row() {
      Text(option.value)
        .width(42)
        .height(42)
        .fontSize(24)
        .textAlign(TextAlign.Center)

      Column() {
        Text(option.label)
          .width('100%')
          .fontSize(16)
          .fontWeight(this.isSelectedMetaOption(option) ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.isSelectedMetaOption(option) ? this.selectedAccentColor : this.textPrimary())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(option.description)
          .width('100%')
          .fontSize(12)
          .fontColor(this.textTertiary())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })

      if (this.isSelectedMetaOption(option)) {
        Text('✓')
          .width(24)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedAccentColor)
          .textAlign(TextAlign.End)
      }
    }
    .width('100%')
    .height(58)
    .padding({ left: 10, right: 12 })
    .backgroundColor(this.isSelectedMetaOption(option) ? this.inputBg() : this.cardBg())
    .border({ width: 1, color: this.isSelectedMetaOption(option) ? this.selectedAccentColor : this.lineColor(), radius: 18 })
    .margin({ top: 8 })
    .onClick(() => {
      this.chooseMetaValue(option.value);
    })
  }

  @Builder
  private MetaPickerSheetPanel() {
    Column() {
      Row() {
        Column() {
          Text(this.metaPickerTitle())
            .width('100%')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary())
            .maxLines(1)

          Text(this.metaPickerSummary())
            .width('100%')
            .fontSize(13)
            .fontColor(this.textTertiary())
            .maxLines(2)
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row() {
        this.MetaPickerTab('mood', '心情')
        this.MetaPickerTab('weather', '天气')
      }
      .width('100%')
      .height(42)
      .padding(4)
      .backgroundColor(this.inputBg())
      .border({ radius: 21 })
      .margin({ top: 18, bottom: 8 })

      ForEach(this.metaPickerOptions(), (option: ValueOption) => {
        this.MetaPickerOptionRow(option)
      }, (option: ValueOption) => option.value)
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 22, bottom: 22 })
    .backgroundColor(this.cardBg())
  }

  @Builder
  private EditorSheetPanel() {
    if (this.ocrReviewSheetOpen) {
      this.OcrRecognitionReviewSheetPanel()
    } else {
      this.MetaPickerSheetPanel()
    }
  }

  private closeEditorSheet(): void {
    if (this.ocrReviewSheetOpen) {
      this.closeOcrReviewSheet();
      return;
    }
    this.closeMetaPickerSheet();
  }

  @Builder
  private OcrReviewRulePopup() {
    Column() {
      List() {
        ForEach(this.ocrReviewRuleItems, (item: MatchRuleTemplateItem) => {
          ListItem() {
            Row({ space: 12 }) {
              Text(this.ocrReviewRuleLabel(item))
                .layoutWeight(1)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.textPrimary())
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Toggle({ type: ToggleType.Switch, isOn: this.isOcrReviewRuleSelected(item.id) })
                .selectedColor(this.selectedAccentColor)
                .onChange((selected: boolean) => {
                  this.setOcrReviewRuleSelected(item.id, selected);
                })
            }
            .width('100%')
            .height(50)
            .padding({ left: 12, right: 8 })
          }
        }, (item: MatchRuleTemplateItem) => item.id)
      }
      .width('100%')
      .height(Math.min(this.ocrReviewRuleItems.length * 50, 250))
      .scrollBar(BarState.Off)

      Divider()
        .width('100%')
        .color(this.lineColor())
        .margin({ top: 4, bottom: 8 })

      Button(this.ocrReviewRulesApplying ? '正在应用…' : '应用')
        .width('100%')
        .height(40)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor(this.selectedAccentColor)
        .border({ radius: 10 })
        .enabled(this.ocrReviewRuleSelectionDirty && !this.ocrReviewRulesApplying)
        .opacity(this.ocrReviewRuleSelectionDirty && !this.ocrReviewRulesApplying ? 1 : 0.55)
        .onClick(() => {
          this.requestApplyOcrReviewRules();
        })
    }
    .width(280)
    .padding(10)
    .backgroundColor(this.cardBg())
    .border({ width: 1, color: this.lineColor(), radius: 16 })
    .shadow({ radius: 18, color: '#22000000', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private OcrRecognitionReviewSheetPanel() {
    Column() {
      Row() {
        Text('识别结果')
          .layoutWeight(1)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary())

        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Row({ space: 4 }) {
            Text('规则')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.ocrReviewRuleItems.length > 0 ? this.textPrimary() : this.textTertiary())
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(14)
              .fontColor([this.ocrReviewRuleItems.length > 0 ? this.textPrimary() : this.textTertiary()])
          }
        }
        .width(68)
        .height(36)
        .padding({ left: 6, right: 4 })
        .backgroundColor(this.inputBg())
        .border({ width: 1, color: this.lineColor(), radius: 12 })
        .clip(true)
        .enabled(this.ocrReviewRuleItems.length > 0 && !this.ocrReviewRulesApplying)
        .opacity(this.ocrReviewRuleItems.length > 0 ? 1 : 0.55)
        .accessibilityText('选择本次匹配规则')
        .onClick(() => {
          this.ocrReviewRuleMenuOpen = !this.ocrReviewRuleMenuOpen;
        })
        .bindPopup(this.ocrReviewRuleMenuOpen, {
          builder: this.OcrReviewRulePopup,
          placement: Placement.BottomRight,
          popupColor: Color.Transparent,
          autoCancel: true,
          enableArrow: false,
          mask: false,
          targetSpace: 8,
          onStateChange: (event) => {
            this.handleOcrReviewRulePopupStateChange(event.isVisible);
          }
        })
      }
        .width('100%')
        .height(36)
        .alignItems(VerticalAlign.Center)

      Text('可修改标题和正文后填入当前笔记')
        .width('100%')
        .fontSize(13)
        .fontColor(this.textTertiary())
        .margin({ top: 6 })

      Text(this.ocrReviewRuleSummary)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(this.ocrReviewRuleSummary.indexOf('已命中') >= 0 ?
          this.selectedAccentColor : this.textTertiary())
        .margin({ top: 8 })

      if (this.hasOcrReviewComparison()) {
        Row({ space: 8 }) {
          Button('处理后')
            .layoutWeight(1)
            .height(36)
            .fontSize(13)
            .fontColor(this.ocrReviewShowingOriginal ? this.textPrimary() : Color.White)
            .backgroundColor(this.ocrReviewShowingOriginal ? this.inputBg() : this.selectedAccentColor)
            .border({ width: 1, color: this.ocrReviewShowingOriginal ? this.lineColor() : this.selectedAccentColor,
              radius: 18 })
            .onClick(() => {
              this.switchOcrReviewSource(false);
            })
          Button('原文')
            .layoutWeight(1)
            .height(36)
            .fontSize(13)
            .fontColor(this.ocrReviewShowingOriginal ? Color.White : this.textPrimary())
            .backgroundColor(this.ocrReviewShowingOriginal ? this.selectedAccentColor : this.inputBg())
            .border({ width: 1, color: this.ocrReviewShowingOriginal ? this.selectedAccentColor : this.lineColor(),
              radius: 18 })
            .onClick(() => {
              this.switchOcrReviewSource(true);
            })
        }
        .width('100%')
        .margin({ top: 12 })
      }

      Column() {
        Text('标题')
          .width('100%')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary())
        TextInput({ placeholder: '笔记标题', text: this.ocrReviewTitle })
          .width('100%')
          .height(46)
          .fontSize(15)
          .fontColor(this.textPrimary())
          .placeholderColor(this.textTertiary())
          .backgroundColor(this.inputBg())
          .border({ width: 1, color: this.lineColor(), radius: 12 })
          .padding({ left: 12, right: 12 })
          .margin({ top: 8 })
          .onChange((value: string) => {
            this.ocrReviewTitle = value;
            this.ocrReviewContentEdited = true;
            if (!this.ocrReviewShowingOriginal) {
              this.ocrReviewProcessedTitle = value;
            }
          })
        Text('正文')
          .width('100%')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary())
          .margin({ top: 14 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 14 })

      TextArea({ placeholder: '笔记正文', text: this.ocrReviewText })
        .width('100%')
        .height(180)
        .fontSize(16)
        .fontColor(this.textPrimary())
        .placeholderColor(this.textTertiary())
        .backgroundColor(this.inputBg())
        .border({ width: 1, color: this.lineColor(), radius: 12 })
        .padding(12)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.ocrReviewText = value;
          this.ocrReviewContentEdited = true;
          if (this.ocrReviewShowingOriginal) {
            this.ocrReviewOriginalText = value;
          } else {
            this.ocrReviewProcessedText = value;
          }
        })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .onClick(() => {
            this.closeOcrReviewSheet();
          })

        Button('填入笔记')
          .layoutWeight(1)
          .margin({ left: 12 })
          .backgroundColor(this.selectedAccentColor)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.fillOcrReviewText();
          })
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 22, bottom: 22 })
    .backgroundColor(this.cardBg())
  }

  @Builder
  private FabMenu() {
    FloatingActionMenu({
      accentColor: this.selectedAccentColor,
      cardBg: this.cardBg(),
      lineColor: this.lineColor(),
      textPrimary: this.textPrimary(),
      gripModeEnabled: this.gripModeEnabled,
      gripOnLeft: this.gripOnLeft,
      onPhotoDraft: () => {
        this.openPhotoDraft();
      },
      onHandwrite: () => {
        this.openEditor('');
      }
    })
  }

  @Builder
  private EditorOverlay() {
    DiaryEditorPage({
      editingId: this.editingId,
      draftTitle: this.draftTitle,
      draftBody: this.draftBody,
      draftFolderName: $draftFolderName,
      tagOptions: this.folderOptions(),
      draftDateMs: this.draftDateMs,
      draftMood: $draftMood,
      draftWeather: $draftWeather,
      draftFavorite: $draftFavorite,
      photoPreviewOpen: $editorPhotoPreviewOpen,
      draftHasPhoto: this.draftHasPhoto,
      draftPhotoInBody: $draftPhotoInBody,
      draftPhotoUri: $draftPhotoUri,
      draftPhotoUris: $draftPhotoUris,
      draftThumbnailPhotoIndex: $draftThumbnailPhotoIndex,
      draftThumbnailScale: $draftThumbnailScale,
      draftThumbnailOffsetX: $draftThumbnailOffsetX,
      draftThumbnailOffsetY: $draftThumbnailOffsetY,
      draftThumbnailPhotoAspect: $draftThumbnailPhotoAspect,
      draftPhotoX: $draftPhotoX,
      draftPhotoY: $draftPhotoY,
      draftPhotoWidth: $draftPhotoWidth,
      draftPhotoHeight: $draftPhotoHeight,
      draftPhotoRotation: $draftPhotoRotation,
      selectedPhotoStyle: this.selectedPhotoStyle,
      materialEffectMode: this.materialEffectMode,
      isDark: this.isDark(),
      pageBg: this.pageBg(),
      cardBg: this.cardBg(),
      inputBg: this.inputBg(),
      lineColor: this.lineColor(),
      textPrimary: this.textPrimary(),
      textSecondary: this.textSecondary(),
      textTertiary: this.textTertiary(),
      selectedAccentColor: this.selectedAccentColor,
      suspendKeyboardAvoidance: this.ocrReviewSheetOpen,
      onClose: () => {
        this.requestCloseEditor();
      },
      onSave: () => {
        this.saveDiary();
      },
      onDeleteRequest: () => {
        const isSavedDiary: boolean = this.editingId.length > 0;
        this.askConfirm(
          'delete-diary',
          isSavedDiary ? '确认删除' : '放弃草稿',
          isSavedDiary ? '删除后可在设置的回收站中恢复，确定继续吗？' : '未保存的笔记内容将丢失，确定放弃吗？'
        );
      },
      onOpenPicker: (type: string, title: string) => {
        this.openPicker(type, title);
      },
      onCreateTag: (value: string) => {
        this.createDiaryFolder(value);
      },
      onDeleteTagRequest: (value: string) => {
        this.requestDeleteDiaryFolder(value);
      },
      onDeletePhotoRequest: (photoUri: string) => {
        this.requestDeleteDraftPhoto(photoUri);
      },
      onDraftTitleChange: (value: string) => {
        this.draftTitle = value;
      },
      onDraftBodyChange: (value: string) => {
        this.draftBody = value;
      },
      onDraftFavoriteChange: (value: boolean) => {
        this.setEditorDraftFavorite(value);
      },
      onDraftHasPhotoChange: (value: boolean) => {
        if (value) {
          this.attachPhotoToDraft();
        } else {
          this.draftHasPhoto = false;
          this.draftPhotoInBody = false;
          this.draftPhotoUri = '';
          this.draftPhotoUris = [];
          this.draftThumbnailPhotoIndex = 0;
          this.draftThumbnailScale = 1;
          this.draftThumbnailOffsetX = 0;
          this.draftThumbnailOffsetY = 0;
          this.draftThumbnailPhotoAspect = 1;
          this.draftPhotoX = 0;
          this.draftPhotoY = 0;
          this.draftPhotoWidth = 156;
          this.draftPhotoHeight = 118;
          this.draftPhotoRotation = 0;
        }
      }
    })
    .width('100%')
    .height('100%')
    .zIndex(200)
  }

  @Builder
  private PrivacyVaultOverlay() {
    PrivacyVaultPage({
      diaries: this.diaries,
      materialEffectMode: this.materialEffectMode,
      isDark: this.isDark(),
      pageBg: this.pageBg(),
      accentColor: this.selectedAccentColor,
      cardBg: this.cardBg(),
      inputBg: this.inputBg(),
      lineColor: this.lineColor(),
      textPrimary: this.textPrimary(),
      textSecondary: this.textSecondary(),
      textTertiary: this.textTertiary(),
      bottomPadding: this.bottomContentPadding(),
      selectionSheetOpen: $privacyVaultSelectionSheetOpen,
      onBack: () => {
        this.closePrivacyVault();
      },
      onAddToPrivacy: (ids: string[]) => {
        this.addDiariesToPrivacy(ids);
      },
      onEdit: (id: string) => {
        this.openEditor(id);
      },
      onToggleFavorite: (id: string) => {
        this.toggleFavorite(id);
      },
      onMoveOutOfPrivacy: (id: string) => {
        this.moveDiaryOutOfPrivacy(id);
      },
      onPermanentDeleteRequest: (id: string) => {
        this.requestPermanentDeletePrivateDiary(id);
      }
    })
      .width('100%')
      .height('100%')
      .zIndex(180)
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      this.FloatingMainTabs()

      if (this.currentTab === 3 && this.settingsPanel !== 'main') {
        Stack() {
          ForEach([this.settingsSubPageRouteKey], (_: number) => {
            this.SettingsPage(this.settingsPanel)
          }, (key: number) => 'settings-sub-page-route-' + key.toString())
        }
        .width('100%')
        .height('100%')
        .zIndex(120)
      }

      if (this.currentTab === 0 && !this.editorVisible) {
        this.FabMenu()
      }

      if (this.editorVisible) {
        this.EditorOverlay()
      }

      if (this.privacyVaultVisible && this.privacyVaultUnlocked && !this.editorVisible) {
        this.PrivacyVaultOverlay()
      }

      if (this.ocrLoadingVisible) {
        OcrRecognitionLoadingOverlay({
          phase: this.ocrLoadingPhase,
          pageBg: this.pageBg(),
          textPrimary: this.textPrimary(),
          textSecondary: this.textSecondary(),
          accentColor: this.selectedAccentColor
        })
          .zIndex(400)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageBg())
    .focusable(true)
    .onKeyEvent((event: KeyEvent): boolean => {
      return this.handleRootKeyEvent(event);
    })
    .bindSheet(this.metaPickerSheetOpen || this.ocrReviewSheetOpen, this.EditorSheetPanel(), {
      height: this.ocrReviewSheetOpen && this.ocrReviewKeyboardHeightVp > 0 ?
        SheetSize.LARGE : SheetSize.FIT_CONTENT,
      detents: [SheetSize.FIT_CONTENT, SheetSize.LARGE],
      dragBar: true,
      showClose: !this.ocrReviewSheetOpen,
      // The review includes a fixed-height text area. Translate the sheet
      // above the keyboard first, then let long review content scroll.
      keyboardAvoidMode: SheetKeyboardAvoidMode.TRANSLATE_AND_SCROLL,
      backgroundColor: this.cardBg(),
      maskColor: '#66000000',
      onDisappear: () => {
        this.closeEditorSheet();
      }
    })
  }
}

