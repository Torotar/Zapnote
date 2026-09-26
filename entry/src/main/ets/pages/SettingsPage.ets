import {
  common
} from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  HdsNavigation,
  HdsNavigationMenuItemOptions,
  HdsNavigationTitleMode,
  IconStyleMode
} from '@kit.UIDesignKit';
import { promptAction, SymbolGlyphModifier } from '@kit.ArkUI';
import { createHdsSubPageTitleBarOptions } from '../components/HdsSubPageTitleBarOptions';
import { createHdsTabTitleBarOptions } from '../components/HdsTabTitleBarOptions';
import { getGuideSection, getGuideTopic } from '../model/GuideContent';
import {
  AiVisualEngineConfig,
  AiVisualEngineOption,
  HuaweiAccountInfo,
  MatchRuleAction,
  MatchRuleMode,
  MatchRuleRange,
  MatchRuleTemplateItem,
  RecycleBinEntry,
  SettingPanel,
  SyncDataScope,
  SyncLog
} from '../model/ZapNoteTypes';
import { ZapNoteHuaweiAccountService } from '../services/ZapNoteHuaweiAccountService';
import { MatchRuleKeywordService } from '../services/MatchRuleKeywordService';
import { LinkRecognitionService } from '../services/LinkRecognitionService';
import { ZapNotePreferencesService } from '../services/ZapNotePreferencesService';
import {
  AiVisualModelsResult,
  AiVisualParsingService
} from '../services/AiVisualParsingService';
import { AboutSettingsPage } from './AboutSettingsPage';
import { AppearanceSettingsPage } from './AppearanceSettingsPage';
import { AutofillSettingsPage } from './AutofillSettingsPage';
import { DataSettingsPage } from './DataSettingsPage';
import { GuideCategoryPage } from './GuideCategoryPage';
import { GuideDetailSettingsPage } from './GuideDetailSettingsPage';
import { GuideSettingsPage } from './GuideSettingsPage';
import { HuaweiAccountLoginPage } from './HuaweiAccountLoginPage';
import { RecycleBinSettingsPage } from './RecycleBinSettingsPage';
import { SettingsMainPage } from './SettingsMainPage';
import { SyncSettingsPage } from './SyncSettingsPage';
import { UserAgreementSettingsPage } from './UserAgreementSettingsPage';
import { WebdavSettingsPage } from './WebdavSettingsPage';

const PRIVACY_POLICY_URL: string =
  'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1998868633601755968';
const HUAWEI_ACCOUNT_AUTH_AGREEMENT_URL: string =
  'https://privacy.consumer.huawei.com/legal/id/authentication-terms.htm?code=CN&language=zh-CN';

@Component
export struct SettingsPage {
  @Prop settingsPanel: SettingPanel = 'main';
  @Prop legalPanelSource: string = '';
  @Prop @Watch('handleSystemBackRequest') systemBackRequestKey: number = 0;
  @Prop diaryCount: number = 0;
  @Prop favoriteCount: number = 0;
  @Prop totalWords: number = 0;
  @Prop recycleBinItems: RecycleBinEntry[] = [];
  @Prop materialEffectMode: number = 3;
  @Prop topPadding: number = 132;
  @Prop bottomPadding: number = 154;
  @Prop isDark: boolean = false;
  @Prop pageBg: string = '#F8FAFC';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop themeMode: string = 'light';
  @Prop gripModeEnabled: boolean = false;
  @Prop lightingMode: string = 'off';
  @Prop selectedPhotoStyle: string = 'original';
  @Prop autoFillEnabled: boolean = true;
  @Prop @Watch('syncCurrentEngine') engine: string = 'default';
  @Prop syncMode: number = 0;
  @Prop syncTimes: string[] = ['08:00', '22:00'];
  @Prop historyLimit: number = 10;
  @Prop syncRestoreStrategy: string = 'merge';
  @Prop syncDataScope: SyncDataScope = 'all';
  @Prop syncLogs: SyncLog[] = [];
  @Prop syncLogRefreshKey: number = 0;
  @Prop webdavUrl: string = '';
  @Prop webdavUser: string = '';
  @Prop webdavPass: string = '';
  @Prop webdavRemotePath: string = '/zapnote';
  @Prop remoteBackupPath: string = '/zapnote/zapnote-backup.json';
  @Prop privacyEnabled: boolean = true;
  @Prop vibrateEnabled: boolean = true;
  @Prop doubleTouchEnabled: boolean = false;
  @Prop doubleTouchAction: string = 'none';
  @Prop sharedPhotoSaveMode: string = 'ask';
  @Prop sharedPhotoAutoRecognizeEnabled: boolean = false;
  @Prop sharedPhotoSaveToAlbumEnabled: boolean = false;
  @Prop enhancedLinkRecognitionEnabled: boolean = false;
  @Prop backupPreview: string = '';
  @Prop huaweiAccountOpenId: string = '';
  @Prop huaweiAccountInfo: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
  @State private matchRuleSheetOpen: boolean = false;
  @State private aiConfigSheetOpen: boolean = false;
  @State private aiProvider: string = 'openai-compatible';
  @State private aiConfigId: string = '';
  @State private aiEngineConfigs: AiVisualEngineConfig[] = [];
  @State private aiProviderName: string = '';
  @State private aiBaseUrl: string = '';
  @State private aiModel: string = '';
  @State private aiApiKey: string = '';
  @State private aiOutputContent: string = '';
  @State private aiAvailableModels: string[] = [];
  @State private aiModelsLoading: boolean = false;
  @State private currentEngine: string = 'default';
  @State private engineSelectionRefreshKey: number = 0;
  @State private customRuleEnabled: boolean = true;
  @State private matchRuleScopes: string[] = ['照片分析'];
  @State private matchRuleKeywords: string = '';
  @State private matchRuleTemplate: string = '{{内容}}';
  @State private matchRuleAction: MatchRuleAction = 'extract';
  @State private matchRuleRange: MatchRuleRange = 'line';
  @State private matchRuleMode: MatchRuleMode = 'contains';
  @State private matchRuleKeywordsFocused: boolean = false;
  @State private matchRuleTemplateFocused: boolean = false;
  @State private editingMatchRuleId: string = '';
  @State private editingMatchRuleKeyword: string = '';
  @State private editingMatchRuleScopes: string[] = [];
  @State private editingMatchRuleTemplate: string = '';
  @State private editingMatchRuleEnabled: boolean = true;
  @State private editingMatchRuleAction: MatchRuleAction = 'extract';
  @State private editingMatchRuleRange: MatchRuleRange = 'line';
  @State private editingMatchRuleMode: MatchRuleMode = 'contains';
  @State private aboutLegalDocument: string = '';
  @State private guideSectionId: string = '';
  @State private guideTopicId: string = '';
  @State private matchRuleItems: MatchRuleTemplateItem[] = [];

  onPanelChange?: (panel: SettingPanel, legalPanelSource?: string) => void;
  onToggleChange?: (key: string, isOn: boolean) => void;
  onSyncModeChange?: (mode: number) => void;
  onSyncTimesChange?: (times: string[]) => void;
  onHistoryLimitChange?: (limit: number) => void;
  onSyncRestoreStrategyChange?: (strategy: string) => void;
  onSyncDataScopeChange?: (scope: SyncDataScope) => void;
  onOpenPicker?: (type: string, title: string) => void;
  onValueChange?: (key: string, value: string) => void;
  onAccentColorChange?: (color: string) => void;
  onPullSync?: () => void;
  onPushSync?: () => void;
  onTestWebdav?: () => void;
  onSaveWebdav?: () => void;
  onWebdavInputChange?: (key: string, value: string) => void;
  onExportBackup?: () => void;
  onExportDiagnosticLog?: () => void;
  onImportBackupRequest?: () => void;
  onClearDataRequest?: () => void;
  onClearAppDataRequest?: () => void;
  onRestoreFromRecycleBin?: (id: string) => void;
  onDeleteFromRecycleBinRequest?: (id: string) => void;
  onClearRecycleBinRequest?: () => void;
  onHuaweiAccountLoginSuccess?: (info: HuaweiAccountInfo) => void;
  onHuaweiAccountLogout?: () => void;
  onHuaweiAccountRefresh?: () => void;
  onOpenPrivacyVault?: () => void;

  private mainScroller: Scroller = new Scroller();
  private subPageScroller: Scroller = new Scroller();
  private aboutPageScroller: Scroller = new Scroller();
  private userAgreementScroller: Scroller = new Scroller();
  private guideCategoryScroller: Scroller = new Scroller();
  private guideDetailScroller: Scroller = new Scroller();
  private matchRuleListScroller: Scroller = new Scroller();
  private matchRuleEditorScroller: Scroller = new Scroller();
  private preferencesReady: boolean = false;

  aboutToAppear(): void {
    this.syncCurrentEngine();
    this.loadSavedMatchRuleItems();
    this.loadAiVisualEngineConfig();
  }

  private syncCurrentEngine(): void {
    this.currentEngine = this.engine;
  }

  private forwardValueChange(key: string, value: string): void {
    if (key === 'engine') {
      this.currentEngine = value;
    }
    if (this.onValueChange !== undefined) {
      this.onValueChange(key, value);
    }
  }

  private async ensurePreferencesReady(): Promise<boolean> {
    if (this.preferencesReady) {
      return true;
    }
    try {
      await ZapNotePreferencesService.init(getContext(this) as common.Context);
      this.preferencesReady = true;
      return true;
    } catch (error) {
      console.error('SettingsPage ensurePreferencesReady failed: ' + JSON.stringify(error));
      return false;
    }
  }

  private async loadSavedMatchRuleItems(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    const savedItems: MatchRuleTemplateItem[] | null = await ZapNotePreferencesService.getMatchRuleItems();
    if (savedItems !== null) {
      this.matchRuleItems = savedItems;
    }
  }

  private async saveMatchRuleItems(items: MatchRuleTemplateItem[]): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    await ZapNotePreferencesService.setMatchRuleItems(items);
  }

  private async loadAiVisualEngineConfig(): Promise<void> {
    if (!await this.ensurePreferencesReady()) {
      return;
    }
    const configs: AiVisualEngineConfig[] = await ZapNotePreferencesService.getAiVisualEngineConfigs();
    this.aiEngineConfigs = configs;
    const selectedId: string = this.selectedAiConfigId();
    let selectedConfig: AiVisualEngineConfig | null = null;
    for (let index: number = 0; index < configs.length; index++) {
      if (configs[index].id === selectedId || (selectedId.length === 0 && index === 0)) {
        selectedConfig = configs[index];
        break;
      }
    }
    if (selectedConfig !== null) {
      this.applyAiVisualEngineConfig(selectedConfig);
    } else {
      this.resetAiVisualEngineForm();
    }
    this.aiAvailableModels = [];
  }

  private selectedAiConfigId(): string {
    if (this.currentEngine.startsWith('custom:')) {
      return this.currentEngine.substring('custom:'.length);
    }
    if (this.aiConfigId.length > 0) {
      return this.aiConfigId;
    }
    return '';
  }

  private applyAiVisualEngineConfig(config: AiVisualEngineConfig): void {
    this.aiConfigId = config.id;
    this.aiProvider = config.provider;
    this.aiProviderName = config.providerName;
    this.aiBaseUrl = config.baseUrl;
    this.aiModel = config.model;
    this.aiApiKey = config.apiKey;
    this.aiOutputContent = config.outputContent;
    this.aiAvailableModels = [];
  }

  private resetAiVisualEngineForm(): void {
    this.aiConfigId = '';
    this.aiProvider = 'openai-compatible';
    this.aiProviderName = '';
    this.aiBaseUrl = '';
    this.aiModel = '';
    this.aiApiKey = '';
    this.aiOutputContent = '';
    this.aiAvailableModels = [];
  }

  private currentAiVisualEngineConfig(): AiVisualEngineConfig {
    return {
      id: this.aiConfigId,
      providerName: this.aiProviderName,
      provider: this.aiProvider,
      baseUrl: this.aiBaseUrl,
      model: this.aiModel,
      apiKey: this.aiApiKey,
      outputContent: this.aiOutputContent
    };
  }

  private aiProviderLabel(): string {
    if (this.aiProvider === 'deepseek') {
      return 'DeepSeek';
    }
    if (this.aiProvider === 'xiaomi-mimo-token-plan') {
      return 'Xiaomi MiMo Token Plan';
    }
    return 'OpenAI 兼容接口';
  }

  private aiProviderIndex(): number {
    if (this.aiProvider === 'deepseek') {
      return 0;
    }
    if (this.aiProvider === 'xiaomi-mimo-token-plan') {
      return 1;
    }
    return 2;
  }

  private selectAiProvider(index: number): void {
    this.aiAvailableModels = [];
    this.aiModel = '';
    if (index === 0) {
      this.aiProvider = 'deepseek';
      this.aiBaseUrl = 'https://api.deepseek.com';
      return;
    }
    if (index === 1) {
      this.aiProvider = 'xiaomi-mimo-token-plan';
      this.aiBaseUrl = 'https://token-plan-cn.xiaomimimo.com/v1';
      return;
    }
    this.aiProvider = 'openai-compatible';
    this.aiBaseUrl = '';
  }

  private isCustomAiProvider(): boolean {
    return this.aiProvider === 'openai-compatible';
  }

  private isAiEngineConfigured(): boolean {
    return this.aiBaseUrl.trim().length > 0 && this.aiModel.trim().length > 0 && this.aiApiKey.trim().length > 0;
  }

  private customAiEngineLabel(): string {
    if (!this.isAiEngineConfigured()) {
      return '自定义接口';
    }
    const providerName: string = this.aiProviderName.trim();
    return providerName.length > 0 ? providerName : this.aiProviderLabel() + ' · ' + this.aiModel.trim();
  }

  private aiEngineOptions(): AiVisualEngineOption[] {
    const options: AiVisualEngineOption[] = [];
    for (let index: number = 0; index < this.aiEngineConfigs.length; index++) {
      const config: AiVisualEngineConfig = this.aiEngineConfigs[index];
      const fallbackLabel: string = config.providerName.trim().length > 0 ? config.providerName.trim() :
        config.provider + ' · ' + config.model;
      options.push({ label: fallbackLabel, value: 'custom:' + config.id });
    }
    return options;
  }

  private aiConfigSelectOptions(): SelectOption[] {
    const options: SelectOption[] = [];
    for (let index: number = 0; index < this.aiEngineConfigs.length; index++) {
      const config: AiVisualEngineConfig = this.aiEngineConfigs[index];
      options.push({ value: config.providerName.trim().length > 0 ? config.providerName : '未命名配置' });
    }
    options.push({ value: '新建配置' });
    return options;
  }

  private aiConfigSelectIndex(): number {
    for (let index: number = 0; index < this.aiEngineConfigs.length; index++) {
      if (this.aiEngineConfigs[index].id === this.aiConfigId) {
        return index;
      }
    }
    return this.aiEngineConfigs.length;
  }

  private selectAiConfig(index: number): void {
    if (index < 0 || index >= this.aiEngineConfigs.length) {
      this.resetAiVisualEngineForm();
      return;
    }
    this.applyAiVisualEngineConfig(this.aiEngineConfigs[index]);
  }

  private isCustomEngineSelected(): boolean {
    return this.currentEngine === 'custom' || this.currentEngine.startsWith('custom:');
  }

  private aiModelOptions(): SelectOption[] {
    if (this.aiAvailableModels.length > 0) {
      return this.aiAvailableModels.map((modelName: string): SelectOption => ({ value: modelName }));
    }
    return [{ value: this.aiModel.trim().length > 0 ? this.aiModel.trim() : '请先拉取模型列表' }];
  }

  private aiModelIndex(): number {
    const index: number = this.aiAvailableModels.indexOf(this.aiModel);
    return index >= 0 ? index : 0;
  }

  private openAiConfigSheet(): void {
    this.matchRuleSheetOpen = false;
    this.resetAiVisualEngineForm();
    this.aiConfigSheetOpen = true;
  }

  private closeAiConfigSheet(): void {
    this.aiConfigSheetOpen = false;
    this.aiModelsLoading = false;
    this.engineSelectionRefreshKey++;
  }

  private async fetchAiModels(): Promise<void> {
    if (this.aiModelsLoading) {
      return;
    }
    this.aiModelsLoading = true;
    this.showRuleToast('正在拉取模型列表...');
    const result: AiVisualModelsResult =
      await AiVisualParsingService.fetchAvailableModels(this.currentAiVisualEngineConfig());
    this.aiModelsLoading = false;
    if (!result.success) {
      this.showRuleToast(result.message);
      return;
    }
    this.aiAvailableModels = result.models;
    if (this.aiModel.trim().length === 0 || this.aiAvailableModels.indexOf(this.aiModel) < 0) {
      this.aiModel = this.aiAvailableModels[0];
    }
    this.showRuleToast(result.message);
  }

  private async saveAiVisualEngineConfig(): Promise<void> {
    if (this.aiProviderName.trim().length === 0) {
      this.showRuleToast('请填写备注');
      return;
    }
    if (!this.isAiEngineConfigured()) {
      this.showRuleToast('请填写接口地址、API Key 并选择模型');
      return;
    }
    if (!await this.ensurePreferencesReady()) {
      this.showRuleToast('AI 配置保存失败');
      return;
    }
    try {
      const configId: string = this.aiConfigId.trim().length > 0 ? this.aiConfigId.trim() :
        'ai-' + new Date().getTime().toString();
      this.aiConfigId = configId;
      const config: AiVisualEngineConfig = {
        id: configId,
        providerName: this.aiProviderName,
        provider: this.aiProvider,
        baseUrl: this.aiBaseUrl,
        model: this.aiModel,
        apiKey: this.aiApiKey,
        outputContent: AiVisualParsingService.resolveOutputContent(
          this.matchRuleItems, configId, this.aiOutputContent)
      };
      await ZapNotePreferencesService.setAiVisualEngineConfig(config);
      const nextConfigs: AiVisualEngineConfig[] = [];
      let replaced: boolean = false;
      for (let index: number = 0; index < this.aiEngineConfigs.length; index++) {
        if (this.aiEngineConfigs[index].id === config.id) {
          nextConfigs.push(config);
          replaced = true;
        } else {
          nextConfigs.push(this.aiEngineConfigs[index]);
        }
      }
      if (!replaced) {
        nextConfigs.push(config);
      }
      this.aiEngineConfigs = nextConfigs;
      this.forwardValueChange('engine', 'custom:' + config.id);
      this.closeAiConfigSheet();
      this.showRuleToast(this.aiOutputContent.trim().length > 0 ?
        'AI 配置已保存' : 'AI 配置已保存，请继续填写输出要求');
    } catch (error) {
      console.error('SettingsPage save AI visual config failed: ' + JSON.stringify(error));
      const errorText: string = error instanceof Error ? error.message : JSON.stringify(error);
      this.showRuleToast(errorText.length > 0 && errorText !== '{}' ? 'AI 配置保存失败：' + errorText : 'AI 配置保存失败');
    }
  }

  private aiEngineConfigLabel(config: AiVisualEngineConfig): string {
    const providerName: string = config.providerName.trim();
    return providerName.length > 0 ? providerName : config.provider + ' · ' + config.model;
  }

  private async deleteAiVisualEngine(engineValue: string): Promise<void> {
    if (!engineValue.startsWith('custom:') || !await this.ensurePreferencesReady()) {
      return;
    }
    const configId: string = engineValue.substring('custom:'.length);
    try {
      await ZapNotePreferencesService.deleteAiVisualEngineConfig(configId);
      const nextConfigs: AiVisualEngineConfig[] = [];
      this.aiEngineConfigs.forEach((config: AiVisualEngineConfig): void => {
        if (config.id !== configId) {
          nextConfigs.push(config);
        }
      });
      const nextRules: MatchRuleTemplateItem[] = [];
      this.matchRuleItems.forEach((item: MatchRuleTemplateItem): void => {
        if (!this.isAiOutputTemplate(item) || item.aiConfigId !== configId) {
          nextRules.push(item);
        }
      });
      await this.saveMatchRuleItems(nextRules);
      this.aiEngineConfigs = nextConfigs;
      this.matchRuleItems = nextRules;
      if (this.aiConfigId === configId) {
        if (nextConfigs.length > 0) {
          this.applyAiVisualEngineConfig(nextConfigs[0]);
        } else {
          this.resetAiVisualEngineForm();
        }
      }
      if (this.currentEngine === engineValue) {
        this.forwardValueChange('engine', 'default');
      }
      this.showRuleToast('解析模型已删除');
    } catch (error) {
      console.error('SettingsPage delete AI visual engine failed: ' + JSON.stringify(error));
      const errorText: string = error instanceof Error ? error.message : JSON.stringify(error);
      this.showRuleToast(errorText.length > 0 && errorText !== '{}' ?
        '解析模型删除失败：' + errorText : '解析模型删除失败');
    }
  }

  private requestDeleteAiVisualEngine(engineValue: string): void {
    if (!engineValue.startsWith('custom:')) {
      return;
    }
    const configId: string = engineValue.substring('custom:'.length);
    const target: AiVisualEngineConfig | undefined =
      this.aiEngineConfigs.find((config: AiVisualEngineConfig): boolean => config.id === configId);
    if (target === undefined) {
      return;
    }
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: '删除解析模型',
        message: '删除“' + this.aiEngineConfigLabel(target) +
          '”后，接口配置、API Key 和关联输出模板将一并删除，且无法恢复。',
        buttons: [
          { text: '取消', color: this.textSecondary },
          { text: '删除', color: '#EF4444' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.deleteAiVisualEngine(engineValue);
        }
      }).catch(() => {});
    } catch (error) {
      console.error('SettingsPage delete AI visual engine dialog failed: ' + JSON.stringify(error));
    }
  }

  private async saveAiOutputContent(): Promise<void> {
    const outputContent: string = this.aiOutputContent.trim();
    if (outputContent.length === 0) {
      this.showRuleToast('请填写输出要求');
      return;
    }
    if (this.aiConfigId.trim().length === 0) {
      this.showRuleToast('请先保存 AI 接口配置');
      return;
    }
    if (!await this.ensurePreferencesReady()) {
      this.showRuleToast('输出模板保存失败');
      return;
    }
    try {
      const selectedScopes: string[] = [];
      this.matchRuleScopes.forEach((scope: string): void => {
        selectedScopes.push(scope === '照片分享' ? '照片分析' : scope);
      });
      const next: MatchRuleTemplateItem[] = [];
      this.matchRuleItems.forEach((item: MatchRuleTemplateItem): void => {
        next.push(item);
      });
      next.push({
        id: 'ai-output-' + new Date().getTime().toString(),
        kind: 'ai-output',
        aiConfigId: this.aiConfigId,
        scopes: selectedScopes,
        keyword: '',
        template: outputContent,
        enabled: true,
        action: this.matchRuleAction,
        range: this.matchRuleRange,
        matchMode: 'contains',
        linkType: LinkRecognitionService.inferTypes(outputContent).length > 0 ?
          LinkRecognitionService.inferTypes(outputContent)[0] : 'none'
      });
      await ZapNotePreferencesService.setAiVisualOutputContent(this.aiConfigId,
        AiVisualParsingService.resolveOutputContent(next, this.aiConfigId));
      await this.saveMatchRuleItems(next);
      this.matchRuleItems = next;
      this.aiOutputContent = '';
      this.showRuleToast('输出模板已保存');
    } catch (error) {
      console.error('SettingsPage save AI output template failed: ' + JSON.stringify(error));
      this.showRuleToast('输出模板保存失败');
    }
  }

  private shouldDismissSettingsSheet(sheetDismiss: SheetDismiss): void {
    if (this.aiConfigSheetOpen) {
      this.closeAiConfigSheet();
      sheetDismiss.dismiss();
      return;
    }
    this.shouldDismissMatchRuleSheet(sheetDismiss);
  }

  private changePanel(panel: SettingPanel): void {
    if (panel !== 'about') {
      this.aboutLegalDocument = '';
    }
    if (panel !== 'guide') {
      this.guideSectionId = '';
      this.guideTopicId = '';
    }
    const shouldResetSubPageScroll: boolean = panel !== this.settingsPanel && panel !== 'main';
    if (this.onPanelChange !== undefined) {
      this.onPanelChange(panel);
    }
    if (shouldResetSubPageScroll) {
      this.scrollPanelToTop(panel);
    }
  }

  private openLoginUserAgreement(): void {
    this.aboutLegalDocument = '';
    this.guideSectionId = '';
    this.guideTopicId = '';
    const shouldResetSubPageScroll: boolean = this.settingsPanel !== 'userAgreement';
    if (this.onPanelChange !== undefined) {
      this.onPanelChange('userAgreement', 'huaweiAccountLogin');
    }
    if (shouldResetSubPageScroll) {
      this.scrollPanelToTop('userAgreement');
    }
  }

  private scrollerForPanel(panel: SettingPanel): Scroller {
    if (panel === 'about') {
      return this.aboutPageScroller;
    }
    if (panel === 'userAgreement') {
      return this.userAgreementScroller;
    }
    return this.subPageScroller;
  }

  private currentSubPageScroller(): Scroller {
    return this.scrollerForPanel(this.settingsPanel);
  }

  private legalDocumentScroller(): Scroller {
    return this.userAgreementScroller;
  }

  private scrollScrollerToTop(scroller: Scroller): void {
    setTimeout((): void => {
      scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
    }, 0);
  }

  private scrollPanelToTop(panel: SettingPanel): void {
    this.scrollScrollerToTop(this.scrollerForPanel(panel));
  }

  private openAboutLegalDocument(documentType: string): void {
    if (documentType === 'privacy') {
      this.openExternalPrivacyPolicy();
      return;
    }
    this.aboutLegalDocument = 'agreement';
    this.scrollScrollerToTop(this.legalDocumentScroller());
  }

  private async openExternalUrl(url: string, failureMessage: string, logTag: string): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        uri: url
      });
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      console.error('SettingsPage ' + logTag + ' failed: ' + JSON.stringify(businessError));
      promptAction.showToast({
        message: failureMessage
      });
    }
  }

  private async openExternalPrivacyPolicy(): Promise<void> {
    await this.openExternalUrl(PRIVACY_POLICY_URL, '无法打开隐私政策，请检查浏览器或网络连接',
      'openExternalPrivacyPolicy');
  }

  private async openHuaweiAccountAuthAgreement(): Promise<void> {
    await this.openExternalUrl(HUAWEI_ACCOUNT_AUTH_AGREEMENT_URL,
      '无法打开华为账号用户认证协议，请检查浏览器或网络连接', 'openHuaweiAccountAuthAgreement');
  }

  private closeAboutLegalDocument(): void {
    this.aboutLegalDocument = '';
  }

  private aboutLegalDocumentTitle(): string {
    return this.aboutLegalDocument === 'privacy' ? '隐私声明' : '用户协议';
  }

  private openGuideTopic(topicId: string): void {
    this.guideTopicId = topicId;
    this.scrollScrollerToTop(this.guideDetailScroller);
  }

  private openGuideSection(sectionId: string): void {
    this.guideSectionId = sectionId;
    this.guideTopicId = '';
    this.scrollScrollerToTop(this.guideCategoryScroller);
  }

  private closeGuideSection(): void {
    this.guideTopicId = '';
    this.guideSectionId = '';
  }

  private closeGuideTopic(): void {
    this.guideTopicId = '';
  }

  private guideDetailTitle(): string {
    return getGuideTopic(this.guideTopicId).sectionTitle;
  }

  private guideSectionTitle(): string {
    return getGuideSection(this.guideSectionId).title;
  }

  private backToMain(): void {
    this.changePanel('main');
  }

  private handleSystemBackRequest(): void {
    if (this.settingsPanel === 'main') {
      return;
    }
    if (this.aiConfigSheetOpen) {
      this.closeAiConfigSheet();
      return;
    }
    if (this.matchRuleSheetOpen) {
      this.backFromMatchRuleSheet();
      return;
    }
    this.backFromSubPage();
  }

  private backFromSubPage(): void {
    if (this.settingsPanel === 'guide' && this.guideTopicId.length > 0) {
      this.closeGuideTopic();
      return;
    }
    if (this.settingsPanel === 'guide' && this.guideSectionId.length > 0) {
      this.closeGuideSection();
      return;
    }
    if (this.settingsPanel === 'about' && this.aboutLegalDocument.length > 0) {
      this.closeAboutLegalDocument();
      return;
    }
    if (this.settingsPanel === 'webdav') {
      this.changePanel('sync');
      return;
    }
    if (this.settingsPanel === 'userAgreement') {
      if (this.legalPanelSource === 'huaweiAccountLogin') {
        this.changePanel('huaweiAccountLogin');
        return;
      }
      this.changePanel('about');
      return;
    }
    this.backToMain();
  }

  private subPageTitle(): string {
    if (this.settingsPanel === 'huaweiAccountLogin') {
      return '华为账号登录';
    }
    if (this.settingsPanel === 'appearance') {
      return '外观定制';
    }
    if (this.settingsPanel === 'autofill') {
      return '智能填写';
    }
    if (this.settingsPanel === 'sync') {
      return '同步管理';
    }
    if (this.settingsPanel === 'webdav') {
      return 'WebDAV 账户';
    }
    if (this.settingsPanel === 'privacy') {
      return '防窥屏保护';
    }
    if (this.settingsPanel === 'data') {
      return '数据管理';
    }
    if (this.settingsPanel === 'recycleBin') {
      return '回收站';
    }
    if (this.settingsPanel === 'guide') {
      return '使用指南';
    }
    if (this.settingsPanel === 'userAgreement') {
      return '用户协议';
    }
    return '关于识录笔记';
  }

  private subPageMenuItems(): Array<HdsNavigationMenuItemOptions> | undefined {
    if (this.settingsPanel === 'data') {
      return [{
        content: {
          icon: new SymbolGlyphModifier($r('sys.symbol.trash'))
            .fontSize(24)
            .fontColor([this.isDark ? '#FCA5A5' : '#EF4444']),
          label: '清除软件数据',
          isEnabled: true,
          type: IconStyleMode.NORMAL,
          action: () => {
            if (this.onClearAppDataRequest !== undefined) {
              this.onClearAppDataRequest();
            }
          }
        }
      }];
    }
    if (this.settingsPanel === 'recycleBin') {
      return [{
        content: {
          icon: new SymbolGlyphModifier($r('sys.symbol.trash'))
            .fontSize(24)
            .fontColor([this.isDark ? '#F8FAFC' : '#1A1A2E']),
          label: '清空回收站',
          isEnabled: true,
          type: IconStyleMode.NORMAL,
          action: () => {
            if (this.recycleBinItems.length === 0) {
              try {
                this.getUIContext().getPromptAction().showToast({
                  message: '回收站为空',
                  duration: 1600
                });
              } catch (error) {
              }
              return;
            }
            if (this.onClearRecycleBinRequest !== undefined) {
              this.onClearRecycleBinRequest();
            }
          }
        }
      }];
    }
    return undefined;
  }

  private subPageBottomPadding(): number {
    return 0;
  }

  private async openMatchRuleSheet(): Promise<void> {
    this.aiConfigSheetOpen = false;
    if (this.isCustomEngineSelected()) {
      await this.loadAiVisualEngineConfig();
      // The saved config keeps the active template for AI parsing, while this
      // panel is a new-template entry point and should start empty.
      this.aiOutputContent = '';
    }
    this.matchRuleSheetOpen = true;
    this.scrollScrollerToTop(this.matchRuleListScroller);
  }

  private closeMatchRuleSheet(): void {
    this.matchRuleSheetOpen = false;
    this.editingMatchRuleId = '';
  }

  private backFromMatchRuleSheet(): void {
    if (this.editingMatchRuleId.length > 0) {
      this.backToMatchRuleList();
      return;
    }
    this.closeMatchRuleSheet();
  }

  private shouldDismissMatchRuleSheet(sheetDismiss: SheetDismiss): void {
    if (this.editingMatchRuleId.length > 0) {
      this.backToMatchRuleList();
      return;
    }
    sheetDismiss.dismiss();
  }

  private resetMatchRule(): void {
    this.customRuleEnabled = true;
    this.matchRuleScopes = ['照片分析'];
    this.matchRuleKeywords = '';
    this.matchRuleTemplate = '{{内容}}';
    this.matchRuleAction = 'extract';
    this.matchRuleRange = 'line';
    this.matchRuleMode = 'contains';
    this.matchRuleKeywordsFocused = false;
    this.matchRuleTemplateFocused = false;
  }

  private resetAiOutputRule(): void {
    this.matchRuleScopes = ['照片分析'];
    this.matchRuleAction = 'extract';
    this.matchRuleRange = 'line';
    this.aiOutputContent = '';
  }

  private aiOutputTextAreaHeight(text: string): number {
    const paragraphs: string[] = text.replace(/\r\n/g, '\n').split('\n');
    let lineCount: number = 0;
    paragraphs.forEach((paragraph: string): void => {
      lineCount += Math.max(Math.ceil(paragraph.length / 20), 1);
    });
    const visibleLines: number = Math.max(lineCount, 2);
    return Math.min(60 + (visibleLines - 2) * 22, 196);
  }

  private setMatchRuleKeywordsFocused(isFocused: boolean): void {
    this.matchRuleKeywordsFocused = isFocused;
  }

  private setMatchRuleTemplateFocused(isFocused: boolean): void {
    this.matchRuleTemplateFocused = isFocused;
  }

  private ruleStatusText(): string {
    return this.customRuleEnabled ? '已启用' : '未启用';
  }

  private matchRuleSheetTitle(): string {
    if (this.editingMatchRuleId.length === 0) {
      return '自定义匹配规则';
    }
    return this.isEditingAiOutputTemplate() ? '修改输出模板' : '修改关键词模板';
  }

  private ruleActionLabel(action: MatchRuleAction): string {
    if (action === 'exclude') {
      return '排除';
    }
    if (action === 'mask') {
      return '屏蔽';
    }
    return '选取';
  }

  private ruleRangeLabel(range: MatchRuleRange): string {
    if (range === 'match') {
      return '命中内容';
    }
    if (range === 'block') {
      return '所在段落';
    }
    return '当前行';
  }

  private matchRuleListKey(item: MatchRuleTemplateItem): string {
    return item.id + '|' + item.kind + '|' + item.aiConfigId + '|' + item.keyword + '|' + item.template + '|' +
      item.action + '|' + item.range + '|' + item.matchMode + '|' + (item.enabled ? '1' : '0') + '|' +
      item.scopes.join(',') + '|' + (item.linkType ?? 'none');
  }

  private isAiOutputTemplate(item: MatchRuleTemplateItem): boolean {
    return item.kind === 'ai-output';
  }

  private editingMatchRuleItem(): MatchRuleTemplateItem | undefined {
    return this.matchRuleItems.find((item: MatchRuleTemplateItem) => item.id === this.editingMatchRuleId);
  }

  private isEditingAiOutputTemplate(): boolean {
    const item: MatchRuleTemplateItem | undefined = this.editingMatchRuleItem();
    return item !== undefined && this.isAiOutputTemplate(item);
  }

  private visibleMatchRuleItems(): MatchRuleTemplateItem[] {
    const visible: MatchRuleTemplateItem[] = [];
    this.matchRuleItems.forEach((item: MatchRuleTemplateItem): void => {
      if (this.isCustomEngineSelected()) {
        if (this.isAiOutputTemplate(item) && item.aiConfigId === this.aiConfigId) {
          visible.push(item);
        }
        return;
      }
      if (!this.isAiOutputTemplate(item)) {
        visible.push(item);
      }
    });
    return visible;
  }

  private savedTemplateSectionTitle(): string {
    return this.isCustomEngineSelected() ? '已添加输出模板' : '已添加关键词模板';
  }

  private ruleTemplateTitle(action: MatchRuleAction): string {
    return action === 'mask' ? '替换内容' : '输出模板';
  }

  private ruleTemplatePlaceholder(action: MatchRuleAction): string {
    if (action === 'mask') {
      return '留空时使用 ****';
    }
    if (action === 'exclude') {
      return '排除规则不需要填写';
    }
    return '可使用 {{内容}}，留空则保留原内容';
  }

  private ruleKeywordLabel(item: MatchRuleTemplateItem): string {
    if (this.isAiOutputTemplate(item)) {
      return item.template.trim().replace(/\s+/g, ' ');
    }
    const keywords: string[] = item.matchMode === 'regex' ?
      MatchRuleKeywordService.splitRegex(item.keyword) : MatchRuleKeywordService.splitPlain(item.keyword);
    return keywords.join('、');
  }

  private ruleItemDetail(item: MatchRuleTemplateItem): string {
    const prefix: string = this.isAiOutputTemplate(item) ? 'AI 输出' : this.ruleActionLabel(item.action);
    return prefix + ' · ' + this.ruleRangeLabel(item.range) +
      (!this.isAiOutputTemplate(item) && item.matchMode === 'regex' ? ' · 正则' : '');
  }

  private splitRuleKeywords(value: string): string[] {
    return MatchRuleKeywordService.splitPlain(value);
  }

  private currentRuleKeywords(): string[] {
    if (this.matchRuleMode === 'regex') {
      return MatchRuleKeywordService.splitRegex(this.matchRuleKeywords);
    }
    return this.splitRuleKeywords(this.matchRuleKeywords);
  }

  private currentEditingRuleKeywords(): string[] {
    if (this.editingMatchRuleMode === 'regex') {
      return MatchRuleKeywordService.splitRegex(this.editingMatchRuleKeyword);
    }
    return this.splitRuleKeywords(this.editingMatchRuleKeyword);
  }

  private formatRuleKeywords(keywords: string[], mode: MatchRuleMode): string {
    return mode === 'regex' ? keywords.join('\n') : keywords.join('，');
  }

  private isValidRegex(value: string): boolean {
    try {
      new RegExp(value);
      return true;
    } catch (error) {
      return false;
    }
  }

  private areValidRegexes(values: string[]): boolean {
    let valid: boolean = true;
    values.forEach((value: string): void => {
      if (!this.isValidRegex(value)) {
        valid = false;
      }
    });
    return valid;
  }

  private showRuleToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({
        message: message,
        duration: 1800
      });
    } catch (error) {
      console.error('SettingsPage show rule toast failed: ' + JSON.stringify(error));
    }
  }

  private addMatchRuleTemplates(): void {
    const keywords: string[] = this.currentRuleKeywords();
    if (keywords.length === 0 || this.matchRuleScopes.length === 0) {
      this.showRuleToast('请填写关键词并选择匹配范围');
      return;
    }
    if (this.matchRuleMode === 'regex' && !this.areValidRegexes(keywords)) {
      this.showRuleToast('正则表达式格式不正确');
      return;
    }
    const selectedScopes: string[] = [];
    this.matchRuleScopes.forEach((scope: string): void => {
      selectedScopes.push(scope === '照片分享' ? '照片分析' : scope);
    });
    const next: MatchRuleTemplateItem[] = [];
    this.matchRuleItems.forEach((item: MatchRuleTemplateItem): void => {
      next.push(item);
    });
    const keywordValue: string = this.formatRuleKeywords(keywords, this.matchRuleMode);
    const templateValue: string = this.matchRuleAction === 'mask' && this.matchRuleTemplate.trim().length === 0 ?
      '****' : this.matchRuleTemplate.trim();
    next.push({
      id: 'match-rule-' + new Date().getTime().toString(),
      kind: 'keyword',
      aiConfigId: '',
      scopes: selectedScopes,
      keyword: keywordValue,
      template: templateValue,
      enabled: this.customRuleEnabled,
      action: this.matchRuleAction,
      range: this.matchRuleRange,
      matchMode: this.matchRuleMode,
      linkType: LinkRecognitionService.inferTypes(keywordValue + '\n' + templateValue).length > 0 ?
        LinkRecognitionService.inferTypes(keywordValue + '\n' + templateValue)[0] : 'none'
    });
    this.matchRuleItems = next;
    this.saveMatchRuleItems(next);
    this.showRuleToast('已添加包含 ' + keywords.length.toString() + ' 个关键词的规则');
  }

  private openMatchRuleEditor(item: MatchRuleTemplateItem): void {
    this.editingMatchRuleId = item.id;
    const itemKeywords: string[] = item.matchMode === 'regex' ?
      MatchRuleKeywordService.splitRegex(item.keyword) : MatchRuleKeywordService.splitPlain(item.keyword);
    this.editingMatchRuleKeyword = this.formatRuleKeywords(itemKeywords, item.matchMode);
    const nextScopes: string[] = [];
    item.scopes.forEach((scope: string): void => {
      const normalizedScope: string = scope === '照片分享' ? '照片分析' : scope;
      if (normalizedScope === '智能填写') {
        return;
      }
      if (nextScopes.indexOf(normalizedScope) < 0) {
        nextScopes.push(normalizedScope);
      }
    });
    this.editingMatchRuleScopes = nextScopes;
    this.editingMatchRuleTemplate = item.template;
    this.editingMatchRuleEnabled = item.enabled;
    this.editingMatchRuleAction = item.action;
    this.editingMatchRuleRange = item.range;
    this.editingMatchRuleMode = item.matchMode;
    this.scrollScrollerToTop(this.matchRuleEditorScroller);
  }

  private backToMatchRuleList(): void {
    this.editingMatchRuleId = '';
    this.scrollScrollerToTop(this.matchRuleListScroller);
  }

  private isRuleScopeSelected(scope: string): boolean {
    return this.matchRuleScopes.indexOf(scope) >= 0;
  }

  private selectRuleScope(scope: string, isOn: boolean): void {
    const nextScopes: string[] = [];
    this.matchRuleScopes.forEach((item: string): void => {
      if (item !== scope) {
        nextScopes.push(item);
      }
    });
    if (!isOn && nextScopes.length === 0) {
      return;
    }
    if (isOn) {
      nextScopes.push(scope);
    }
    this.matchRuleScopes = nextScopes;
  }

  private isEditingScopeSelected(scope: string): boolean {
    return this.editingMatchRuleScopes.indexOf(scope) >= 0;
  }

  private selectEditingScope(scope: string, isOn: boolean): void {
    const nextScopes: string[] = [];
    this.editingMatchRuleScopes.forEach((item: string): void => {
      if (item !== scope) {
        nextScopes.push(item);
      }
    });
    if (!isOn && nextScopes.length === 0) {
      return;
    }
    if (isOn) {
      nextScopes.push(scope);
    }
    this.editingMatchRuleScopes = nextScopes;
  }

  private async saveEditingMatchRule(): Promise<void> {
    if (this.editingMatchRuleId.length === 0) {
      return;
    }
    const editingItem: MatchRuleTemplateItem | undefined = this.editingMatchRuleItem();
    if (editingItem === undefined) {
      return;
    }
    if (this.isAiOutputTemplate(editingItem)) {
      const outputContent: string = this.editingMatchRuleTemplate.trim();
      if (outputContent.length === 0 || this.editingMatchRuleScopes.length === 0) {
        this.showRuleToast('请填写输出要求并选择匹配范围');
        return;
      }
      const nextAiItems: MatchRuleTemplateItem[] = [];
      this.matchRuleItems.forEach((item: MatchRuleTemplateItem): void => {
        if (item.id === this.editingMatchRuleId) {
          nextAiItems.push({
            id: item.id,
            kind: 'ai-output',
            aiConfigId: item.aiConfigId,
            scopes: this.editingMatchRuleScopes,
            keyword: '',
            template: outputContent,
            enabled: this.editingMatchRuleEnabled,
            action: this.editingMatchRuleAction,
            range: this.editingMatchRuleRange,
            matchMode: 'contains',
            linkType: LinkRecognitionService.inferTypes(outputContent).length > 0 ?
              LinkRecognitionService.inferTypes(outputContent)[0] : 'none'
          });
          return;
        }
        nextAiItems.push(item);
      });
      try {
        await this.saveMatchRuleItems(nextAiItems);
        if (editingItem.aiConfigId.length > 0) {
          await ZapNotePreferencesService.setAiVisualOutputContent(editingItem.aiConfigId,
            AiVisualParsingService.resolveOutputContent(nextAiItems, editingItem.aiConfigId));
        }
        this.matchRuleItems = nextAiItems;
        this.showRuleToast('输出模板已保存');
      } catch (error) {
        console.error('SettingsPage save AI output template edit failed: ' + JSON.stringify(error));
        this.showRuleToast('输出模板保存失败');
      }
      return;
    }
    const keywords: string[] = this.currentEditingRuleKeywords();
    if (keywords.length === 0 || this.editingMatchRuleScopes.length === 0) {
      this.showRuleToast('请填写关键词并选择匹配范围');
      return;
    }
    if (this.editingMatchRuleMode === 'regex' && !this.areValidRegexes(keywords)) {
      this.showRuleToast('正则表达式格式不正确');
      return;
    }
    const next: MatchRuleTemplateItem[] = [];
    this.matchRuleItems.forEach((item: MatchRuleTemplateItem): void => {
      if (item.id === this.editingMatchRuleId) {
        const keywordValue: string = this.formatRuleKeywords(keywords, this.editingMatchRuleMode);
        const templateValue: string = this.editingMatchRuleAction === 'mask' &&
          this.editingMatchRuleTemplate.trim().length === 0 ? '****' : this.editingMatchRuleTemplate.trim();
        next.push({
          id: item.id,
          kind: 'keyword',
          aiConfigId: '',
          scopes: this.editingMatchRuleScopes,
          keyword: keywordValue,
          template: templateValue,
          enabled: this.editingMatchRuleEnabled,
          action: this.editingMatchRuleAction,
          range: this.editingMatchRuleRange,
          matchMode: this.editingMatchRuleMode,
          linkType: LinkRecognitionService.inferTypes(keywordValue + '\n' + templateValue).length > 0 ?
            LinkRecognitionService.inferTypes(keywordValue + '\n' + templateValue)[0] : 'none'
        });
        return;
      }
      next.push(item);
    });
    this.matchRuleItems = next;
    await this.saveMatchRuleItems(next);
    try {
      this.getUIContext().getPromptAction().showToast({
        message: '包含 ' + keywords.length.toString() + ' 个关键词的规则已保存',
        duration: 1600
      });
    } catch (error) {
      console.error('SettingsPage save match rule toast failed: ' + JSON.stringify(error));
    }
  }

  private async deleteMatchRuleTemplate(id: string): Promise<void> {
    const target: MatchRuleTemplateItem | undefined =
      this.matchRuleItems.find((item: MatchRuleTemplateItem) => item.id === id);
    const next: MatchRuleTemplateItem[] = [];
    this.matchRuleItems.forEach((item: MatchRuleTemplateItem): void => {
      if (item.id !== id) {
        next.push(item);
      }
    });
    await this.saveMatchRuleItems(next);
    this.matchRuleItems = next;
    if (target !== undefined && this.isAiOutputTemplate(target) && target.aiConfigId.length > 0) {
      await ZapNotePreferencesService.setAiVisualOutputContent(target.aiConfigId,
        AiVisualParsingService.resolveOutputContent(next, target.aiConfigId));
    }
    if (this.editingMatchRuleId === id) {
      this.backToMatchRuleList();
    }
    try {
      this.getUIContext().getPromptAction().showToast({
        message: target !== undefined && this.isAiOutputTemplate(target) ? '输出模板已删除' : '关键词模板已删除',
        duration: 1600
      });
    } catch (error) {
      console.error('SettingsPage delete match rule toast failed: ' + JSON.stringify(error));
    }
  }

  private requestDeleteMatchRuleTemplate(id: string): void {
    const target: MatchRuleTemplateItem | undefined = this.matchRuleItems.find((item: MatchRuleTemplateItem) => item.id === id);
    if (target === undefined) {
      return;
    }
    try {
      const isAiOutput: boolean = this.isAiOutputTemplate(target);
      this.getUIContext().getPromptAction().showDialog({
        title: isAiOutput ? '删除输出模板' : '删除关键词模板',
        message: isAiOutput ? '确定删除这个输出模板吗？删除后无法恢复。' :
          '确定删除“' + target.keyword + '”这个关键词模板吗？删除后无法恢复。',
        buttons: [
          { text: '取消', color: this.textSecondary },
          { text: '删除', color: '#EF4444' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.deleteMatchRuleTemplate(id);
          return;
        }
      }).catch(() => {});
    } catch (error) {
      console.error('SettingsPage delete match rule dialog failed: ' + JSON.stringify(error));
    }
  }

  @Builder
  private MatchRuleDeleteAction(item: MatchRuleTemplateItem) {
    Row() {
      Button() {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize(24)
          .fontColor([Color.White])
      }
      .width(38)
      .height(38)
      .backgroundColor('#EF4444')
      .border({ radius: 19 })
      .stateEffect(false)
      .onClick(() => {
        this.requestDeleteMatchRuleTemplate(item.id);
      })
    }
    .width(56)
    .height('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private MatchRuleListItem(item: MatchRuleTemplateItem, index: number) {
    ListItem() {
      Column() {
        Row({ space: 14 }) {
          Text((index + 1).toString() + '. ' + this.ruleKeywordLabel(item))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
            .layoutWeight(1)
            .maxLines(1)
          Text(item.enabled ? '启用' : '停用')
            .fontSize(12)
            .fontColor(item.enabled ? this.selectedAccentColor : this.textTertiary)
        }
        .width('100%')
        Text(this.ruleItemDetail(item))
          .fontSize(12)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
      }
      .width('100%')
      .height(64)
      .padding(12)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(this.cardBg)
      .border({ width: 1, color: this.lineColor, radius: 14 })
      .margin({ top: index === 0 ? 0 : 10 })
      .onClick(() => {
        this.openMatchRuleEditor(item);
      })
    }
    .width('100%')
    .swipeAction({
      end: {
        builder: () => {
          this.MatchRuleDeleteAction(item)
        },
        actionAreaDistance: 56
      },
      edgeEffect: SwipeEdgeEffect.Spring
    })
  }

  @Builder
  private RuleScopeChip(label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.isRuleScopeSelected(label) ? Color.White : this.textPrimary)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(36)
      .padding({ left: 8, right: 8 })
      .backgroundColor(this.isRuleScopeSelected(label) ? this.selectedAccentColor : this.inputBg)
      .border({ width: 1, color: this.isRuleScopeSelected(label) ? this.selectedAccentColor : this.lineColor, radius: 18 })
      .onClick(() => {
        this.selectRuleScope(label, !this.isRuleScopeSelected(label));
      })
  }

  @Builder
  private MatchRuleScopeOption(label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.isEditingScopeSelected(label) ? Color.White : this.textPrimary)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(36)
      .padding({ left: 8, right: 8 })
      .backgroundColor(this.isEditingScopeSelected(label) ? this.selectedAccentColor : this.inputBg)
      .border({ width: 1, color: this.isEditingScopeSelected(label) ? this.selectedAccentColor : this.lineColor, radius: 18 })
      .onClick(() => {
        this.selectEditingScope(label, !this.isEditingScopeSelected(label));
      })
  }

  @Builder
  private RuleActionOption(label: string, action: MatchRuleAction, editing: boolean) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor((editing ? this.editingMatchRuleAction : this.matchRuleAction) === action ?
        Color.White : this.textPrimary)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(36)
      .padding({ left: 6, right: 6 })
      .backgroundColor((editing ? this.editingMatchRuleAction : this.matchRuleAction) === action ?
        this.selectedAccentColor : this.inputBg)
      .border({
        width: 1,
        color: (editing ? this.editingMatchRuleAction : this.matchRuleAction) === action ?
          this.selectedAccentColor : this.lineColor,
        radius: 18
      })
      .onClick(() => {
        if (editing) {
          this.editingMatchRuleAction = action;
        } else {
          this.matchRuleAction = action;
        }
      })
  }

  @Builder
  private RuleRangeOption(label: string, range: MatchRuleRange, editing: boolean) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor((editing ? this.editingMatchRuleRange : this.matchRuleRange) === range ?
        Color.White : this.textPrimary)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(36)
      .padding({ left: 4, right: 4 })
      .backgroundColor((editing ? this.editingMatchRuleRange : this.matchRuleRange) === range ?
        this.selectedAccentColor : this.inputBg)
      .border({
        width: 1,
        color: (editing ? this.editingMatchRuleRange : this.matchRuleRange) === range ?
          this.selectedAccentColor : this.lineColor,
        radius: 18
      })
      .onClick(() => {
        if (editing) {
          this.editingMatchRuleRange = range;
        } else {
          this.matchRuleRange = range;
        }
      })
  }

  @Builder
  private RuleModeRow(editing: boolean) {
    Row() {
      Column() {
        Text('使用正则表达式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)
        Text('关闭时按普通关键词匹配')
          .fontSize(12)
          .fontColor(this.textTertiary)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Toggle({
        type: ToggleType.Switch,
        isOn: (editing ? this.editingMatchRuleMode : this.matchRuleMode) === 'regex'
      })
        .selectedColor(this.selectedAccentColor)
        .onChange((isOn: boolean) => {
          if (editing) {
            this.editingMatchRuleMode = isOn ? 'regex' : 'contains';
          } else {
            this.matchRuleMode = isOn ? 'regex' : 'contains';
          }
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.inputBg)
    .border({ width: 1, color: this.lineColor, radius: 16 })
    .margin({ top: 18 })
  }

  @Builder
  private MatchRuleEditorPanel() {
    Column() {
      if (!this.isEditingAiOutputTemplate()) {
        Column() {
          Text('关键词')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
            .margin({ bottom: 8 })
          if (this.editingMatchRuleMode === 'regex') {
            TextArea({
              placeholder: '每行一个正则表达式',
              text: this.editingMatchRuleKeyword
            })
              .width('100%')
              .height(46)
              .fontSize(14)
              .fontColor(this.textPrimary)
              .placeholderColor(this.textTertiary)
              .padding({ left: 14, right: 14, top: 14, bottom: 10 })
              .backgroundColor(this.inputBg)
              .border({ width: 1, color: this.lineColor, radius: 16 })
              .onChange((value: string) => {
                this.editingMatchRuleKeyword = value;
              })
          } else {
            TextInput({
              placeholder: '用逗号分隔多个关键词',
              text: this.editingMatchRuleKeyword
            })
              .width('100%')
              .height(46)
              .fontSize(14)
              .fontColor(this.textPrimary)
              .placeholderColor(this.textTertiary)
              .padding({ left: 14, right: 14, top: 0, bottom: 0 })
              .backgroundColor(this.inputBg)
              .border({ width: 1, color: this.lineColor, radius: 16 })
              .onChange((value: string) => {
                this.editingMatchRuleKeyword = value;
              })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 0 })
      }

      Column() {
        Text('匹配范围')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 10 })
        Row({ space: 8 }) {
          this.MatchRuleScopeOption('剪切板')
          this.MatchRuleScopeOption('照片分析')
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 0, bottom: 0 })
      .alignItems(HorizontalAlign.Start)
      .margin({ top: this.isEditingAiOutputTemplate() ? 0 : 18 })

      Column() {
        Text('处理动作')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 10 })
        Row({ space: 8 }) {
          this.RuleActionOption('选取', 'extract', true)
          this.RuleActionOption('排除', 'exclude', true)
          this.RuleActionOption('屏蔽', 'mask', true)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 18 })

      Column() {
        Text('作用范围')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 10 })
        Row({ space: 8 }) {
          this.RuleRangeOption('命中内容', 'match', true)
          this.RuleRangeOption('当前行', 'line', true)
          this.RuleRangeOption('所在段落', 'block', true)
        }
        .width('100%')
        if (!this.isEditingAiOutputTemplate()) {
          Text(this.editingMatchRuleMode === 'regex' ?
            '正则规则提取实际匹配片段' : '普通关键词提取同一视觉行中关键词右侧的内容')
            .fontSize(12)
            .lineHeight(18)
            .fontColor(this.textTertiary)
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 18 })

      if (!this.isEditingAiOutputTemplate()) {
        this.RuleModeRow(true)
      }

      Column() {
        Text(this.isEditingAiOutputTemplate() ? '输出要求' : this.ruleTemplateTitle(this.editingMatchRuleAction))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 8 })
        TextArea({
          placeholder: this.isEditingAiOutputTemplate() ?
            '例如：修正错别字，提取姓名、订单号和金额，并按清单格式输出' :
            this.ruleTemplatePlaceholder(this.editingMatchRuleAction),
          text: this.editingMatchRuleTemplate
        })
          .width('100%')
          .height(this.isEditingAiOutputTemplate() ?
            this.aiOutputTextAreaHeight(this.editingMatchRuleTemplate) : 68)
          .fontSize(14)
          .fontColor(this.textPrimary)
          .placeholderColor(this.textTertiary)
          .padding({ left: 14, right: 14, top: 12, bottom: 4 })
          .backgroundColor(this.inputBg)
          .border({ width: 1, color: this.lineColor, radius: 16 })
          .enabled(this.isEditingAiOutputTemplate() || this.editingMatchRuleAction !== 'exclude')
          .opacity(!this.isEditingAiOutputTemplate() && this.editingMatchRuleAction === 'exclude' ? 0.55 : 1)
          .onChange((value: string) => {
            this.editingMatchRuleTemplate = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 18 })

      Row() {
        Text('启用模板')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.editingMatchRuleEnabled })
          .selectedColor(this.selectedAccentColor)
          .onChange((isOn: boolean) => {
            this.editingMatchRuleEnabled = isOn;
          })
      }
      .width('100%')
      .padding(14)
      .backgroundColor(this.inputBg)
      .border({ width: 1, color: this.lineColor, radius: 16 })
      .margin({ top: 18 })

      Button('保存')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontColor(Color.White)
        .backgroundColor(this.selectedAccentColor)
        .border({ radius: 16 })
        .stateEffect(false)
        .margin({ top: 20 })
        .onClick(() => {
          this.saveEditingMatchRule();
        })

      Button(this.isEditingAiOutputTemplate() ? '删除输出模板' : '删除关键词模板')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontColor('#EF4444')
        .backgroundColor(this.inputBg)
        .border({ width: 1, color: '#FCA5A5', radius: 16 })
        .stateEffect(false)
        .margin({ top: 12 })
        .onClick(() => {
          this.requestDeleteMatchRuleTemplate(this.editingMatchRuleId);
        })
    }
    .width('100%')
    .padding({ left: 28, right: 28, top: 12, bottom: 22 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private MatchRuleSavedTemplatesSection() {
    Column() {
      Row() {
        Text(this.savedTemplateSectionTitle())
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .layoutWeight(1)
        Text(this.visibleMatchRuleItems().length.toString() + ' 个')
          .fontSize(13)
          .fontColor(this.selectedAccentColor)
      }
      .width('100%')

      List() {
        ForEach(this.visibleMatchRuleItems(), (item: MatchRuleTemplateItem, index: number) => {
          this.MatchRuleListItem(item, index)
        }, (item: MatchRuleTemplateItem) => this.matchRuleListKey(item))
      }
      .width('100%')
      .height(this.visibleMatchRuleItems().length === 0 ? 0 :
        Math.min(this.visibleMatchRuleItems().length * 64 +
          Math.max(this.visibleMatchRuleItems().length - 1, 0) * 10, 256))
      .scrollBar(BarState.Off)
      .margin({ top: this.visibleMatchRuleItems().length === 0 ? 0 : 10 })
    }
    .width('100%')
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.inputBg)
    .border({ width: 1, color: this.lineColor, radius: 16 })
    .margin({ top: 18 })
  }

  @Builder
  private MatchRuleListPanel() {
    Column() {
      Column() {
        Text('匹配范围')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 10 })
        Row({ space: 8 }) {
          this.RuleScopeChip('剪切板')
          this.RuleScopeChip('照片分析')
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 0 })

      Column() {
        Text('处理动作')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 10 })
        Row({ space: 8 }) {
          this.RuleActionOption('选取', 'extract', false)
          this.RuleActionOption('排除', 'exclude', false)
          this.RuleActionOption('屏蔽', 'mask', false)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 18 })

      Column() {
        Text('作用范围')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 10 })
        Row({ space: 8 }) {
          this.RuleRangeOption('命中内容', 'match', false)
          this.RuleRangeOption('当前行', 'line', false)
          this.RuleRangeOption('所在段落', 'block', false)
        }
        .width('100%')
        Text(this.matchRuleMode === 'regex' ?
          '正则规则提取实际匹配片段' : '普通关键词提取同一视觉行中关键词右侧的内容')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 18 })

      this.RuleModeRow(false)

      Column() {
        Text('关键词')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 8 })
        if (this.matchRuleMode === 'regex') {
          TextArea({
            placeholder: this.matchRuleKeywordsFocused ? '' : '每行一个正则表达式',
            text: this.matchRuleKeywords
          })
            .width('100%')
            .height(46)
            .fontSize(14)
            .fontColor(this.textPrimary)
            .placeholderColor(this.textTertiary)
            .padding({ left: 14, right: 14, top: 14, bottom: 10 })
            .backgroundColor(this.inputBg)
            .border({ width: 1, color: this.lineColor, radius: 16 })
            .onFocus(() => {
              this.setMatchRuleKeywordsFocused(true);
            })
            .onBlur(() => {
              this.setMatchRuleKeywordsFocused(false);
            })
            .onChange((value: string) => {
              this.matchRuleKeywords = value;
            })
        } else {
          TextInput({
            placeholder: this.matchRuleKeywordsFocused ? '' : '用逗号分隔多个关键词',
            text: this.matchRuleKeywords
          })
            .width('100%')
            .height(46)
            .fontSize(14)
            .fontColor(this.textPrimary)
            .placeholderColor(this.textTertiary)
            .padding({ left: 14, right: 14, top: 0, bottom: 0 })
            .backgroundColor(this.inputBg)
            .border({ width: 1, color: this.lineColor, radius: 16 })
            .onFocus(() => {
              this.setMatchRuleKeywordsFocused(true);
            })
            .onBlur(() => {
              this.setMatchRuleKeywordsFocused(false);
            })
            .onChange((value: string) => {
              this.matchRuleKeywords = value;
            })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 18 })

      Column() {
        Text(this.ruleTemplateTitle(this.matchRuleAction))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 8 })
        TextArea({
          placeholder: this.matchRuleTemplateFocused ? '' : this.ruleTemplatePlaceholder(this.matchRuleAction),
          text: this.matchRuleTemplate
        })
          .width('100%')
          .height(68)
          .fontSize(14)
          .fontColor(this.textPrimary)
          .placeholderColor(this.textTertiary)
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .backgroundColor(this.inputBg)
          .border({ width: 1, color: this.lineColor, radius: 16 })
          .enabled(this.matchRuleAction !== 'exclude')
          .opacity(this.matchRuleAction === 'exclude' ? 0.55 : 1)
          .onFocus(() => {
            this.setMatchRuleTemplateFocused(true);
          })
          .onBlur(() => {
            this.setMatchRuleTemplateFocused(false);
          })
          .onChange((value: string) => {
            this.matchRuleTemplate = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 18 })

      this.MatchRuleSavedTemplatesSection()

      Row({ space: 12 }) {
        Button('重置')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(this.textPrimary)
          .backgroundColor(this.inputBg)
          .border({ width: 1, color: this.lineColor, radius: 16 })
          .stateEffect(false)
          .onClick(() => {
            this.resetMatchRule();
          })
        Button('添加')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(this.selectedAccentColor)
          .border({ radius: 16 })
          .stateEffect(false)
          .onClick(() => {
            this.addMatchRuleTemplates();
          })
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('100%')
    .padding({ left: 28, right: 28, top: 12, bottom: 22 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private AiConfigFieldTitle(title: string) {
    Text(title)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.textPrimary)
      .width('100%')
  }

  @Builder
  private AiConfigSheetPanel() {
    Scroll() {
      Column() {
        Column() {
          this.AiConfigFieldTitle('备注')
          Row() {
            TextInput({ text: this.aiProviderName, placeholder: '请输入备注' })
              .layoutWeight(1)
              .height(48)
              .type(InputType.Normal)
              .fontSize(14)
              .fontColor(this.textPrimary)
              .placeholderColor(this.textTertiary)
              .padding({ left: 14, right: 4 })
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .onChange((value: string) => {
                this.aiProviderName = value;
              })

            Select(this.aiConfigSelectOptions())
              .selected(this.aiConfigSelectIndex())
              .value('')
              .width(64)
              .height(48)
              .padding({ left: 0, right: 14 })
              .font({ size: 1 })
              .fontColor(Color.Transparent)
              .selectedOptionFontColor(this.selectedAccentColor)
              .optionFontColor(this.textPrimary)
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .onSelect((index: number) => {
                this.selectAiConfig(index);
              })
          }
          .width('100%')
          .height(48)
          .margin({ top: 8 })
          .backgroundColor(this.inputBg)
          .border({ width: 1, color: this.lineColor, radius: 12 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 18 })

        Column() {
          this.AiConfigFieldTitle('AI 服务商')
          Select([
            { value: 'DeepSeek' },
            { value: 'Xiaomi MiMo Token Plan' },
            { value: 'OpenAI 兼容接口' }
          ])
            .selected(this.aiProviderIndex())
            .value(this.aiProviderLabel())
            .width('100%')
            .height(48)
            .margin({ top: 8 })
            .padding({ left: 14, right: 14 })
            .font({ size: 14, weight: FontWeight.Normal })
            .fontColor(this.textPrimary)
            .selectedOptionFontColor(this.selectedAccentColor)
            .optionFontColor(this.textPrimary)
            .menuAlign(MenuAlignType.END, { dx: 0, dy: 0 })
            .optionWidth(240)
            .backgroundColor(this.inputBg)
            .border({ width: 1, color: this.lineColor, radius: 12 })
            .onSelect((index: number) => {
              this.selectAiProvider(index);
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column() {
          this.AiConfigFieldTitle('Base URL')
          if (this.isCustomAiProvider()) {
            TextInput({ text: this.aiBaseUrl, placeholder: '请输入兼容 OpenAI 的 Base URL' })
              .width('100%')
              .height(48)
              .type(InputType.Normal)
              .fontSize(14)
              .fontColor(this.textPrimary)
              .placeholderColor(this.textTertiary)
              .padding({ left: 14, right: 14 })
              .margin({ top: 8 })
              .backgroundColor(this.inputBg)
              .border({ width: 1, color: this.lineColor, radius: 12 })
              .onChange((value: string) => {
                this.aiBaseUrl = value;
                this.aiAvailableModels = [];
                this.aiModel = '';
              })
          } else {
            Text(this.aiBaseUrl)
              .width('100%')
              .height(48)
              .fontSize(14)
              .fontColor(this.textPrimary)
              .padding({ left: 14, right: 14 })
              .margin({ top: 8 })
              .backgroundColor(this.inputBg)
              .border({ width: 1, color: this.lineColor, radius: 12 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 18 })

        Column() {
          this.AiConfigFieldTitle('模型名')
          Select(this.aiModelOptions())
            .selected(this.aiModelIndex())
            .value(this.aiModel.trim().length > 0 ? this.aiModel : '请先拉取模型列表')
            .width('100%')
            .height(48)
            .margin({ top: 8 })
            .padding({ left: 14, right: 14 })
            .font({ size: 14, weight: FontWeight.Normal })
            .fontColor(this.aiModel.trim().length > 0 ? this.textPrimary : this.textTertiary)
            .selectedOptionFontColor(this.selectedAccentColor)
            .optionFontColor(this.textPrimary)
            .menuAlign(MenuAlignType.END, { dx: 0, dy: 0 })
            .optionWidth(210)
            .backgroundColor(this.inputBg)
            .border({ width: 1, color: this.lineColor, radius: 12 })
            .enabled(this.aiAvailableModels.length > 0)
            .onSelect((index: number, value?: string) => {
              this.aiModel = value ?? this.aiAvailableModels[index];
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 18 })

        Column() {
          this.AiConfigFieldTitle('API Key')
          TextInput({ text: this.aiApiKey, placeholder: '请输入 API Key' })
            .width('100%')
            .height(48)
            .type(InputType.Password)
            .fontSize(14)
            .fontColor(this.textPrimary)
            .placeholderColor(this.textTertiary)
            .padding({ left: 14, right: 14 })
            .margin({ top: 8 })
            .backgroundColor(this.inputBg)
            .border({ width: 1, color: this.lineColor, radius: 12 })
            .onChange((value: string) => {
              this.aiApiKey = value;
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 18 })

        Button(this.aiModelsLoading ? '正在拉取模型...' : '拉取模型列表')
          .width('100%')
          .height(44)
          .fontSize(15)
          .fontColor(this.textPrimary)
          .backgroundColor(this.inputBg)
          .border({ width: 1, color: this.lineColor, radius: 16 })
          .stateEffect(false)
          .enabled(!this.aiModelsLoading)
          .margin({ top: 22 })
          .onClick(() => {
            this.fetchAiModels();
          })

        Button('保存配置')
          .width('100%')
          .height(44)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(this.selectedAccentColor)
          .border({ radius: 16 })
          .stateEffect(false)
          .margin({ top: 12, bottom: 28 })
          .onClick(() => {
            this.saveAiVisualEngineConfig();
          })
      }
      .width('100%')
      .padding({ left: 28, right: 28, top: 14 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.TopStart)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
  }

  @Builder
  private AiOutputRulePanel() {
    Column() {
      Column() {
        Text('匹配范围')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 10 })
        Row({ space: 8 }) {
          this.RuleScopeChip('剪切板')
          this.RuleScopeChip('照片分析')
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text('处理动作')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 10 })
        Row({ space: 8 }) {
          this.RuleActionOption('选取', 'extract', false)
          this.RuleActionOption('排除', 'exclude', false)
          this.RuleActionOption('屏蔽', 'mask', false)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 18 })

      Column() {
        Text('作用范围')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 10 })
        Row({ space: 8 }) {
          this.RuleRangeOption('命中内容', 'match', false)
          this.RuleRangeOption('当前行', 'line', false)
          this.RuleRangeOption('所在段落', 'block', false)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 18 })

      Column() {
        Text('输出要求')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ bottom: 8 })
        TextArea({
          placeholder: '例如：修正错别字，提取姓名、订单号和金额，并按清单格式输出',
          text: this.aiOutputContent
        })
          .width('100%')
          .height(this.aiOutputTextAreaHeight(this.aiOutputContent))
          .fontSize(14)
          .fontColor(this.textPrimary)
          .placeholderColor(this.textTertiary)
          .padding({ left: 14, right: 14, top: 12, bottom: 4 })
          .backgroundColor(this.inputBg)
          .border({ width: 1, color: this.lineColor, radius: 16 })
          .onChange((value: string) => {
            this.aiOutputContent = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 18 })

      this.MatchRuleSavedTemplatesSection()

      Row({ space: 12 }) {
        Button('重置')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(this.textPrimary)
          .backgroundColor(this.inputBg)
          .border({ width: 1, color: this.lineColor, radius: 16 })
          .stateEffect(false)
          .onClick(() => {
            this.resetAiOutputRule();
          })
        Button('保存')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(this.selectedAccentColor)
          .border({ radius: 16 })
          .stateEffect(false)
          .onClick(() => {
            this.saveAiOutputContent();
          })
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('100%')
    .padding({ left: 28, right: 28, top: 12, bottom: 28 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private MatchRuleSheetPanel() {
    if (this.editingMatchRuleId.length > 0) {
      Scroll(this.matchRuleEditorScroller) {
        Column() {
          this.MatchRuleEditorPanel()
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .align(Alignment.TopStart)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .onAppear(() => {
        this.scrollScrollerToTop(this.matchRuleEditorScroller);
      })
    } else {
      Scroll(this.matchRuleListScroller) {
        Column() {
          if (this.isCustomEngineSelected()) {
            this.AiOutputRulePanel()
          } else {
            this.MatchRuleListPanel()
          }
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .align(Alignment.TopStart)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .onAppear(() => {
        this.scrollScrollerToTop(this.matchRuleListScroller);
      })
    }
  }

  @Builder
  private SettingsContent() {
    Column() {
      if (this.settingsPanel === 'main') {
        SettingsMainPage({
          diaryCount: this.diaryCount,
          favoriteCount: this.favoriteCount,
          totalWords: this.totalWords,
          recycleBinCount: this.recycleBinItems.length,
          isDark: this.isDark,
          selectedAccentColor: this.selectedAccentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary,
          textTertiary: this.textTertiary,
          privacyEnabled: this.privacyEnabled,
          huaweiAccountOpenId: this.huaweiAccountOpenId,
          huaweiAccountInfo: this.huaweiAccountInfo,
          onPanelChange: (panel: SettingPanel) => {
            this.changePanel(panel);
          },
          onToggleChange: this.onToggleChange,
          onOpenPrivacyVault: this.onOpenPrivacyVault
        })
      } else if (this.settingsPanel === 'huaweiAccountLogin') {
        HuaweiAccountLoginPage({
          isDark: this.isDark,
          selectedAccentColor: this.selectedAccentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary,
          textTertiary: this.textTertiary,
          huaweiAccountOpenId: this.huaweiAccountOpenId,
          huaweiAccountInfo: this.huaweiAccountInfo,
          onLoginSuccess: (info: HuaweiAccountInfo) => {
            if (this.onHuaweiAccountLoginSuccess !== undefined) {
              this.onHuaweiAccountLoginSuccess(info);
            }
            this.changePanel('main');
          },
          onLogout: () => {
            if (this.onHuaweiAccountLogout !== undefined) {
              this.onHuaweiAccountLogout();
            }
          },
          onRefresh: () => {
            if (this.onHuaweiAccountRefresh !== undefined) {
              this.onHuaweiAccountRefresh();
            }
          },
          onOpenUserAgreement: () => {
            this.openLoginUserAgreement();
          },
          onOpenPrivacyStatement: () => {
            this.openExternalPrivacyPolicy();
          },
          onOpenHuaweiAccountAgreement: () => {
            this.openHuaweiAccountAuthAgreement();
          }
        })
      } else if (this.settingsPanel === 'appearance') {
        AppearanceSettingsPage({
          themeMode: this.themeMode,
          lightingMode: this.lightingMode,
          gripModeEnabled: this.gripModeEnabled,
          selectedAccentColor: this.selectedAccentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textTertiary: this.textTertiary,
          onBack: () => {
            this.backToMain();
          },
          onToggleChange: this.onToggleChange,
          onValueChange: this.onValueChange
        })
      } else if (this.settingsPanel === 'autofill') {
        AutofillSettingsPage({
          autoFillEnabled: this.autoFillEnabled,
          doubleTouchEnabled: this.doubleTouchEnabled,
          doubleTouchAction: this.doubleTouchAction,
          sharedPhotoSaveMode: this.sharedPhotoSaveMode,
          sharedPhotoAutoRecognizeEnabled: this.sharedPhotoAutoRecognizeEnabled,
          sharedPhotoSaveToAlbumEnabled: this.sharedPhotoSaveToAlbumEnabled,
          enhancedLinkRecognitionEnabled: this.enhancedLinkRecognitionEnabled,
          engine: this.currentEngine,
          engineSelectionRefreshKey: this.engineSelectionRefreshKey,
          customEngines: this.aiEngineOptions(),
          vibrateEnabled: this.vibrateEnabled,
          selectedAccentColor: this.selectedAccentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textTertiary: this.textTertiary,
          onBack: () => {
            this.backToMain();
          },
          onToggleChange: this.onToggleChange,
          onValueChange: (key: string, value: string) => {
            this.forwardValueChange(key, value);
          },
          onOpenMatchRuleSheet: () => {
            this.openMatchRuleSheet();
          },
          onOpenAiConfigSheet: () => {
            this.openAiConfigSheet();
          },
          onDeleteEngineRequest: (value: string) => {
            this.requestDeleteAiVisualEngine(value);
          }
        })
      } else if (this.settingsPanel === 'sync') {
        SyncSettingsPage({
          isDark: this.isDark,
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
          remoteBackupPath: this.remoteBackupPath,
          selectedAccentColor: this.selectedAccentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary,
          textTertiary: this.textTertiary,
          onBack: () => {
            this.backToMain();
          },
          onSyncModeChange: this.onSyncModeChange,
          onSyncTimesChange: this.onSyncTimesChange,
          onHistoryLimitChange: this.onHistoryLimitChange,
          onSyncRestoreStrategyChange: this.onSyncRestoreStrategyChange,
          onSyncDataScopeChange: this.onSyncDataScopeChange,
          onPullSync: this.onPullSync,
          onPushSync: this.onPushSync,
          onTestWebdav: this.onTestWebdav,
          onSaveWebdav: this.onSaveWebdav,
          onWebdavInputChange: this.onWebdavInputChange
        })
      } else if (this.settingsPanel === 'webdav') {
        WebdavSettingsPage({
          webdavUrl: this.webdavUrl,
          webdavUser: this.webdavUser,
          webdavPass: this.webdavPass,
          webdavRemotePath: this.webdavRemotePath,
          selectedAccentColor: this.selectedAccentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary,
          textTertiary: this.textTertiary,
          onBack: () => {
            this.changePanel('sync');
          },
          onTestWebdav: this.onTestWebdav,
          onSaveWebdav: this.onSaveWebdav,
          onWebdavInputChange: this.onWebdavInputChange
        })
      } else if (this.settingsPanel === 'data') {
        DataSettingsPage({
          diaryCount: this.diaryCount,
          favoriteCount: this.favoriteCount,
          totalWords: this.totalWords,
          remoteBackupPath: this.remoteBackupPath,
          backupPreview: this.backupPreview,
          isDark: this.isDark,
          selectedAccentColor: this.selectedAccentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary,
          textTertiary: this.textTertiary,
          onBack: () => {
            this.backToMain();
          },
          onExportBackup: this.onExportBackup,
          onExportDiagnosticLog: this.onExportDiagnosticLog,
          onImportBackupRequest: this.onImportBackupRequest,
          onClearDataRequest: this.onClearDataRequest
        })
      } else if (this.settingsPanel === 'recycleBin') {
        RecycleBinSettingsPage({
          items: this.recycleBinItems,
          isDark: this.isDark,
          selectedAccentColor: this.selectedAccentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary,
          textTertiary: this.textTertiary,
          onRestore: this.onRestoreFromRecycleBin,
          onDeletePermanentlyRequest: this.onDeleteFromRecycleBinRequest
        })
      } else if (this.settingsPanel === 'guide') {
        GuideSettingsPage({
          selectedAccentColor: this.selectedAccentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary,
          textTertiary: this.textTertiary,
          onBack: () => {
            this.backToMain();
          },
          onOpenSection: (sectionId: string) => {
            this.openGuideSection(sectionId);
          },
          onOpenTopic: (topicId: string) => {
            this.openGuideTopic(topicId);
          }
        })
      } else if (this.settingsPanel === 'userAgreement') {
        UserAgreementSettingsPage({
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary
        })
      } else {
        AboutSettingsPage({
          selectedAccentColor: this.selectedAccentColor,
          cardBg: this.cardBg,
          inputBg: this.inputBg,
          lineColor: this.lineColor,
          textPrimary: this.textPrimary,
          textSecondary: this.textSecondary,
          textTertiary: this.textTertiary,
          onOpenLegal: (documentType: string) => {
            this.openAboutLegalDocument(documentType);
          }
        })
      }
    }
    .width('100%')
    .margin({ top: this.settingsPanel === 'main' ? 0 : 12 })
  }

  @Builder
  private AboutLegalDocumentContent() {
    UserAgreementSettingsPage({
      cardBg: this.cardBg,
      inputBg: this.inputBg,
      lineColor: this.lineColor,
      textPrimary: this.textPrimary,
      textSecondary: this.textSecondary
    })
  }

  build() {
    if (this.settingsPanel === 'main') {
      HdsNavigation() {
        List({ scroller: this.mainScroller }) {
          ListItem() {
            Column() {
              this.SettingsContent()
            }
            .width('100%')
            .padding({
              left: 24,
              right: 24,
              top: this.topPadding,
              bottom: this.bottomPadding
            })
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .titleBar(createHdsTabTitleBarOptions('设置', '', this.isDark, this.materialEffectMode))
      .titleMode(HdsNavigationTitleMode.FULL)
      .hideBackButton(true)
      .bindToScrollable([this.mainScroller])
      .backgroundColor(this.pageBg)
    } else {
      Stack({ alignContent: Alignment.Bottom }) {
        HdsNavDestination() {
          List({ scroller: this.currentSubPageScroller() }) {
            ListItem() {
              this.SettingsContent()
            }
            .width('100%')

            ListItem() {
              Column()
                .width('100%')
                .height(24)
            }
            .width('100%')
          }
          .width('100%')
          .height('100%')
          .padding({
            left: 20,
            right: 20,
            top: 0,
            bottom: this.subPageBottomPadding()
          })
          .cachedCount(6)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .friction(0.75)
          .scrollBar(BarState.Auto)
        }
        .width('100%')
        .height('100%')
        .titleBar(createHdsSubPageTitleBarOptions(this.subPageTitle(), this.isDark, this.materialEffectMode, () => {
          this.backFromSubPage();
        }, this.subPageMenuItems()))
        .titleMode(HdsNavDestinationTitleMode.MINI)
        .hideBackButton(false)
        .onBackPressed(() => {
          if (this.aiConfigSheetOpen) {
            this.closeAiConfigSheet();
            return true;
          }
          if (this.matchRuleSheetOpen) {
            this.backFromMatchRuleSheet();
            return true;
          }
          this.backFromSubPage();
          return true;
        })
        .bindToScrollable([this.currentSubPageScroller()])
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
        .backgroundColor(this.pageBg)

        if (this.settingsPanel === 'about' && this.aboutLegalDocument.length > 0) {
          HdsNavDestination() {
            List({ scroller: this.legalDocumentScroller() }) {
              ListItem() {
                this.AboutLegalDocumentContent()
              }
              .width('100%')

              ListItem() {
                Column()
                  .width('100%')
                  .height(24)
              }
              .width('100%')
            }
            .width('100%')
            .height('100%')
            .padding({
              left: 20,
              right: 20,
              top: 0,
              bottom: 0
            })
            .cachedCount(2)
            .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
            .friction(0.75)
            .scrollBar(BarState.Auto)
          }
          .width('100%')
          .height('100%')
          .titleBar(createHdsSubPageTitleBarOptions(this.aboutLegalDocumentTitle(), this.isDark,
            this.materialEffectMode, () => {
              this.closeAboutLegalDocument();
            }))
          .titleMode(HdsNavDestinationTitleMode.MINI)
          .hideBackButton(false)
          .onBackPressed(() => {
            this.closeAboutLegalDocument();
            return true;
          })
          .bindToScrollable([this.legalDocumentScroller()])
          .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
          .backgroundColor(this.pageBg)
          .zIndex(2)
        }

        if (this.settingsPanel === 'guide' && this.guideSectionId.length > 0) {
          HdsNavDestination() {
            List({ scroller: this.guideCategoryScroller }) {
              ListItem() {
                GuideCategoryPage({
                  sectionId: this.guideSectionId,
                  cardBg: this.cardBg,
                  lineColor: this.lineColor,
                  textPrimary: this.textPrimary,
                  textTertiary: this.textTertiary,
                  onOpenTopic: (topicId: string) => {
                    this.openGuideTopic(topicId);
                  }
                })
              }
              .width('100%')
            }
            .width('100%')
            .height('100%')
            .padding({
              left: 20,
              right: 20,
              top: 0,
              bottom: 0
            })
            .cachedCount(2)
            .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
            .friction(0.75)
            .scrollBar(BarState.Auto)
          }
          .width('100%')
          .height('100%')
          .titleBar(createHdsSubPageTitleBarOptions(this.guideSectionTitle(), this.isDark,
            this.materialEffectMode, () => {
              this.closeGuideSection();
            }))
          .titleMode(HdsNavDestinationTitleMode.MINI)
          .hideBackButton(false)
          .onBackPressed(() => {
            this.closeGuideSection();
            return true;
          })
          .bindToScrollable([this.guideCategoryScroller])
          .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
          .backgroundColor(this.pageBg)
          .zIndex(2)
        }

        if (this.settingsPanel === 'guide' && this.guideTopicId.length > 0) {
          HdsNavDestination() {
            List({ scroller: this.guideDetailScroller }) {
              ListItem() {
                GuideDetailSettingsPage({
                  topicId: this.guideTopicId,
                  selectedAccentColor: this.selectedAccentColor,
                  cardBg: this.cardBg,
                  inputBg: this.inputBg,
                  lineColor: this.lineColor,
                  textPrimary: this.textPrimary,
                  textSecondary: this.textSecondary,
                  textTertiary: this.textTertiary,
                  onOpenTopic: (topicId: string) => {
                    this.openGuideTopic(topicId);
                  }
                })
              }
              .width('100%')

              ListItem() {
                Column()
                  .width('100%')
                  .height(24)
              }
              .width('100%')
            }
            .width('100%')
            .height('100%')
            .padding({
              left: 20,
              right: 20,
              top: 0,
              bottom: 0
            })
            .cachedCount(2)
            .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
            .friction(0.75)
            .scrollBar(BarState.Auto)
          }
          .width('100%')
          .height('100%')
          .titleBar(createHdsSubPageTitleBarOptions(this.guideDetailTitle(), this.isDark,
            this.materialEffectMode, () => {
              this.closeGuideTopic();
            }))
          .titleMode(HdsNavDestinationTitleMode.MINI)
          .hideBackButton(false)
          .onBackPressed(() => {
            this.closeGuideTopic();
            return true;
          })
          .bindToScrollable([this.guideDetailScroller])
          .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
          .backgroundColor(this.pageBg)
          .zIndex(3)
        }
      }
      .width('100%')
      .height('100%')
      .bindSheet(this.aiConfigSheetOpen || this.matchRuleSheetOpen,
        this.aiConfigSheetOpen ? this.AiConfigSheetPanel() : this.MatchRuleSheetPanel(), {
        height: SheetSize.LARGE,
        dragBar: true,
        showClose: true,
        title: { title: this.aiConfigSheetOpen ? 'AI 接口配置' :
          this.matchRuleSheetTitle() },
        backgroundColor: this.cardBg,
        maskColor: '#66000000',
        shouldDismiss: (sheetDismiss: SheetDismiss) => {
          this.shouldDismissSettingsSheet(sheetDismiss);
        },
        onDisappear: () => {
          this.closeAiConfigSheet();
          this.closeMatchRuleSheet();
        }
      })
    }
  }
}
