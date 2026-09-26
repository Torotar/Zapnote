import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import {
  AiVisualEngineConfig,
  DiaryEntry,
  HuaweiAccountInfo,
  LinkType,
  MatchRuleAction,
  MatchRuleMode,
  MatchRuleRange,
  MatchRuleTemplateKind,
  MatchRuleTemplateItem,
  SyncDataScope,
  SyncLog
} from '../model/ZapNoteTypes';
import { ZapNoteCredentialService } from './ZapNoteCredentialService';
import { ZapNoteHuaweiAccountService } from './ZapNoteHuaweiAccountService';

interface StoredAiVisualEngineConfig {
  id: string;
  providerName: string;
  provider: string;
  baseUrl: string;
  model: string;
  outputContent: string;
}

export class ZapNotePreferencesService {
  public static readonly DEFAULT_WEBDAV_REMOTE_PATH: string = '/zapnote';

  private static pref: preferences.Preferences | null = null;
  private static readonly PREFERENCES_NAME: string = 'zapnote_preferences';
  private static readonly REMOVED_TEST_MATCH_RULE_ID: string = 'match-rule-magnet-link';

  public static async init(context: common.Context): Promise<void> {
    if (ZapNotePreferencesService.pref) {
      return;
    }
    try {
      ZapNotePreferencesService.pref =
        await preferences.getPreferences(context, ZapNotePreferencesService.PREFERENCES_NAME);
    } catch (error) {
      console.error('ZapNotePreferencesService init failed: ' + JSON.stringify(error));
    }
  }

  public static async getHuaweiAccountOpenId(): Promise<string> {
    return await ZapNotePreferencesService.getString('huaweiAccountOpenId', '');
  }

  public static async getHuaweiAccountInfo(): Promise<HuaweiAccountInfo> {
    const raw: string = await ZapNotePreferencesService.getString('huaweiAccountInfo', '');
    if (raw.length > 0) {
      try {
        const parsed: HuaweiAccountInfo = JSON.parse(raw) as HuaweiAccountInfo;
        return ZapNoteHuaweiAccountService.normalizeInfo(parsed);
      } catch (error) {
        console.error('ZapNotePreferencesService getHuaweiAccountInfo failed: ' + JSON.stringify(error));
      }
    }
    const legacyOpenId: string = await ZapNotePreferencesService.getHuaweiAccountOpenId();
    const legacyInfo: HuaweiAccountInfo = ZapNoteHuaweiAccountService.emptyInfo();
    legacyInfo.openId = legacyOpenId;
    legacyInfo.loginState = legacyOpenId.length > 0 ? 'authorized' : 'unknown';
    legacyInfo.loginStateText = legacyOpenId.length > 0 ? '已保存华为账号登录信息' : '未检查登录状态';
    return legacyInfo;
  }

  public static async setHuaweiAccountInfo(value: HuaweiAccountInfo): Promise<void> {
    const normalized: HuaweiAccountInfo = ZapNoteHuaweiAccountService.normalizeInfo(value);
    if (normalized.openId.length === 0 && normalized.unionId.length === 0) {
      await ZapNotePreferencesService.clearHuaweiAccountInfo();
      return;
    }
    await ZapNotePreferencesService.putValue('huaweiAccountInfo', JSON.stringify(normalized));
    if (normalized.openId.length > 0) {
      await ZapNotePreferencesService.putValue('huaweiAccountOpenId', normalized.openId);
    }
  }

  public static async clearHuaweiAccountInfo(): Promise<void> {
    await ZapNotePreferencesService.deleteValue('huaweiAccountInfo');
    await ZapNotePreferencesService.deleteValue('huaweiAccountOpenId');
  }

  public static async setHuaweiAccountOpenId(value: string): Promise<void> {
    const normalizedValue: string = value.trim();
    if (normalizedValue.length === 0) {
      await ZapNotePreferencesService.clearHuaweiAccountOpenId();
      return;
    }
    await ZapNotePreferencesService.putValue('huaweiAccountOpenId', normalizedValue);
  }

  public static async clearHuaweiAccountOpenId(): Promise<void> {
    await ZapNotePreferencesService.deleteValue('huaweiAccountOpenId');
  }

  public static async clearAllAppData(): Promise<boolean> {
    if (!ZapNotePreferencesService.pref) {
      return false;
    }
    try {
      const aiConfigs: AiVisualEngineConfig[] = await ZapNotePreferencesService.getAiVisualEngineConfigs();
      await ZapNoteCredentialService.setWebDavPassword('');
      await ZapNoteCredentialService.setAiApiKey('');
      for (let index: number = 0; index < aiConfigs.length; index++) {
        const configId: string = aiConfigs[index].id.trim();
        if (configId.length > 0) {
          await ZapNoteCredentialService.setAiApiKey('', configId);
        }
      }
      await ZapNotePreferencesService.pref.clear();
      await ZapNotePreferencesService.pref.flush();
      return true;
    } catch (error) {
      console.error('ZapNotePreferencesService clearAllAppData failed: ' + JSON.stringify(error));
      return false;
    }
  }

  public static async getWebDavServerUrl(): Promise<string> {
    return await ZapNotePreferencesService.getString('webDavServerUrl', '');
  }

  public static async setWebDavServerUrl(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('webDavServerUrl', value);
  }

  public static async getWebDavRemotePath(): Promise<string> {
    return await ZapNotePreferencesService.getString('webDavRemotePath',
      ZapNotePreferencesService.DEFAULT_WEBDAV_REMOTE_PATH);
  }

  public static async setWebDavRemotePath(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('webDavRemotePath', value);
  }

  public static async getWebDavUsername(): Promise<string> {
    return await ZapNotePreferencesService.getString('webDavUsername', '');
  }

  public static async setWebDavUsername(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('webDavUsername', value);
  }

  public static async getWebDavPassword(): Promise<string> {
    const protectedValue: string = await ZapNoteCredentialService.getWebDavPassword();
    if (protectedValue.length > 0) {
      return protectedValue;
    }
    const legacyValue: string = await ZapNotePreferencesService.getString('webDavPassword', '');
    if (legacyValue.length > 0 && await ZapNoteCredentialService.setWebDavPassword(legacyValue)) {
      await ZapNotePreferencesService.deleteValue('webDavPassword');
    }
    return legacyValue;
  }

  public static async setWebDavPassword(value: string): Promise<void> {
    if (await ZapNoteCredentialService.setWebDavPassword(value)) {
      await ZapNotePreferencesService.deleteValue('webDavPassword');
    }
  }

  public static async getSyncInterval(): Promise<string> {
    return await ZapNotePreferencesService.getString('syncInterval', 'off');
  }

  public static async setSyncInterval(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('syncInterval', value);
  }

  public static async getWebDavSyncMode(): Promise<number> {
    const value: preferences.ValueType = await ZapNotePreferencesService.getValue('webDavSyncMode', 0);
    return typeof value === 'number' && value === 1 ? 1 : 0;
  }

  public static async setWebDavSyncMode(value: number): Promise<void> {
    await ZapNotePreferencesService.putValue('webDavSyncMode', value === 1 ? 1 : 0);
  }

  public static async getWebDavSyncTimes(): Promise<string[]> {
    const raw: string = await ZapNotePreferencesService.getString('webDavSyncTimes', '["08:00","22:00"]');
    try {
      const parsed: string[] = JSON.parse(raw) as string[];
      return Array.isArray(parsed) ? parsed : ['08:00', '22:00'];
    } catch (error) {
      console.error('ZapNotePreferencesService getWebDavSyncTimes failed: ' + JSON.stringify(error));
      return ['08:00', '22:00'];
    }
  }

  public static async setWebDavSyncTimes(value: string[]): Promise<void> {
    await ZapNotePreferencesService.putValue('webDavSyncTimes', JSON.stringify(value));
  }

  public static async getWebDavHistoryLimit(): Promise<number> {
    const value: preferences.ValueType = await ZapNotePreferencesService.getValue('webDavHistoryLimit', 10);
    if (typeof value === 'number' && (value === 10 || value === 30 || value === 100)) {
      return value;
    }
    return 10;
  }

  public static async setWebDavHistoryLimit(value: number): Promise<void> {
    const normalized: number = value === 30 || value === 100 ? value : 10;
    await ZapNotePreferencesService.putValue('webDavHistoryLimit', normalized);
  }

  public static async getWebDavRestoreStrategy(): Promise<string> {
    const value: string = await ZapNotePreferencesService.getString('webDavRestoreStrategy', 'merge');
    return value === 'overwrite' ? 'overwrite' : 'merge';
  }

  public static async setWebDavRestoreStrategy(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('webDavRestoreStrategy', value === 'overwrite' ? 'overwrite' : 'merge');
  }

  public static async getWebDavSyncDataScope(): Promise<SyncDataScope> {
    const value: string = await ZapNotePreferencesService.getString('webDavSyncDataScope', 'all');
    if (value === 'diaries' || value === 'settings') {
      return value;
    }
    return 'all';
  }

  public static async setWebDavSyncDataScope(value: SyncDataScope): Promise<void> {
    const normalized: SyncDataScope = value === 'diaries' || value === 'settings' ? value : 'all';
    await ZapNotePreferencesService.putValue('webDavSyncDataScope', normalized);
  }

  public static async getSyncOnChange(): Promise<boolean> {
    const value: preferences.ValueType = await ZapNotePreferencesService.getValue('syncOnChange', false);
    return typeof value === 'boolean' ? value : false;
  }

  public static async setSyncOnChange(value: boolean): Promise<void> {
    await ZapNotePreferencesService.putValue('syncOnChange', value);
  }

  public static async getSyncLogs(): Promise<SyncLog[]> {
    const raw: string = await ZapNotePreferencesService.getString('syncLogs', '[]');
    try {
      const parsed: SyncLog[] = JSON.parse(raw) as SyncLog[];
      return Array.isArray(parsed) ? parsed : [];
    } catch (error) {
      console.error('ZapNotePreferencesService getSyncLogs failed: ' + JSON.stringify(error));
      return [];
    }
  }

  public static async setSyncLogs(value: SyncLog[]): Promise<void> {
    await ZapNotePreferencesService.putValue('syncLogs', JSON.stringify(value));
  }

  public static async getThemeMode(): Promise<string> {
    return await ZapNotePreferencesService.getString('themeMode', 'light');
  }

  public static async setThemeMode(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('themeMode', value);
  }

  public static async getLightingMode(): Promise<string> {
    return await ZapNotePreferencesService.getString('lightingMode', 'off');
  }

  public static async setLightingMode(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('lightingMode', value);
  }

  public static async getSelectedAccentColor(): Promise<string> {
    return await ZapNotePreferencesService.getString('selectedAccentColor', '#6366F1');
  }

  public static async setSelectedAccentColor(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('selectedAccentColor', value);
  }

  public static async getGripModeEnabled(): Promise<boolean> {
    const value: preferences.ValueType = await ZapNotePreferencesService.getValue('gripModeEnabled', false);
    return typeof value === 'boolean' ? value : false;
  }

  public static async setGripModeEnabled(value: boolean): Promise<void> {
    await ZapNotePreferencesService.putValue('gripModeEnabled', value);
  }

  public static async getPrivacyEnabled(): Promise<boolean> {
    return await ZapNotePreferencesService.getBoolean('privacyEnabled', true);
  }

  public static async setPrivacyEnabled(value: boolean): Promise<void> {
    await ZapNotePreferencesService.putValue('privacyEnabled', value);
  }

  public static async getAutoFillEnabled(): Promise<boolean> {
    return await ZapNotePreferencesService.getBoolean('autoFillEnabled', true);
  }

  public static async setAutoFillEnabled(value: boolean): Promise<void> {
    await ZapNotePreferencesService.putValue('autoFillEnabled', value);
  }

  public static async getVibrateEnabled(): Promise<boolean> {
    return await ZapNotePreferencesService.getBoolean('vibrateEnabled', true);
  }

  public static async setVibrateEnabled(value: boolean): Promise<void> {
    await ZapNotePreferencesService.putValue('vibrateEnabled', value);
  }

  public static async getDoubleTouchEnabled(): Promise<boolean> {
    return await ZapNotePreferencesService.getBoolean('smartKeyCaptureEnabled', false);
  }

  public static async setDoubleTouchEnabled(value: boolean): Promise<void> {
    await ZapNotePreferencesService.putValue('smartKeyCaptureEnabled', value);
  }

  public static async getDoubleTouchAction(): Promise<string> {
    return await ZapNotePreferencesService.getString('smartKeyDoubleTouchAction', 'none');
  }

  public static async setDoubleTouchAction(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('smartKeyDoubleTouchAction', value);
  }

  public static async getSharedPhotoSaveMode(): Promise<string> {
    return await ZapNotePreferencesService.getString('sharedPhotoSaveMode', 'ask');
  }

  public static async setSharedPhotoSaveMode(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('sharedPhotoSaveMode', value);
  }

  public static async getSharedPhotoAutoRecognizeEnabled(): Promise<boolean> {
    return await ZapNotePreferencesService.getBoolean('sharedPhotoAutoRecognizeEnabled', false);
  }

  public static async setSharedPhotoAutoRecognizeEnabled(value: boolean): Promise<void> {
    await ZapNotePreferencesService.putValue('sharedPhotoAutoRecognizeEnabled', value);
  }

  public static async getSharedPhotoSaveToAlbumEnabled(): Promise<boolean> {
    return await ZapNotePreferencesService.getBoolean('sharedPhotoSaveToAlbumEnabled', false);
  }

  public static async setSharedPhotoSaveToAlbumEnabled(value: boolean): Promise<void> {
    await ZapNotePreferencesService.putValue('sharedPhotoSaveToAlbumEnabled', value);
  }

  public static async getSharedPhotoRecycleBinNoticeShown(): Promise<boolean> {
    return await ZapNotePreferencesService.getBoolean('sharedPhotoRecycleBinNoticeShown', false);
  }

  public static async setSharedPhotoRecycleBinNoticeShown(value: boolean): Promise<void> {
    await ZapNotePreferencesService.putValue('sharedPhotoRecycleBinNoticeShown', value);
  }

  public static async getEnhancedLinkRecognitionEnabled(): Promise<boolean> {
    return await ZapNotePreferencesService.getBoolean('enhancedLinkRecognitionEnabled', false);
  }

  public static async setEnhancedLinkRecognitionEnabled(value: boolean): Promise<void> {
    await ZapNotePreferencesService.putValue('enhancedLinkRecognitionEnabled', value);
  }

  public static async getEngine(): Promise<string> {
    const value: string = await ZapNotePreferencesService.getString('engine', 'default');
    if (value.startsWith('custom:')) {
      return value;
    }
    if (value === 'custom') {
      const configs: AiVisualEngineConfig[] = await ZapNotePreferencesService.getAiVisualEngineConfigs();
      return configs.length > 0 ? 'custom:' + configs[0].id : 'default';
    }
    return 'default';
  }

  public static async setEngine(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('engine', value);
  }

  public static async getAiVisualEngineConfigs(): Promise<AiVisualEngineConfig[]> {
    const raw: string = await ZapNotePreferencesService.getString('aiVisualEngineConfigs', '');
    const configs: AiVisualEngineConfig[] = [];
    let hasStoredConfigList: boolean = false;
    if (raw.length > 0) {
      try {
        const storedConfigs: StoredAiVisualEngineConfig[] = JSON.parse(raw) as StoredAiVisualEngineConfig[];
        if (Array.isArray(storedConfigs)) {
          hasStoredConfigList = true;
          for (let index: number = 0; index < storedConfigs.length; index++) {
            const stored: StoredAiVisualEngineConfig = storedConfigs[index];
            if (!stored.id || stored.id.trim().length === 0) {
              continue;
            }
            configs.push({
              id: stored.id,
              providerName: stored.providerName ?? '',
              provider: stored.provider ?? 'openai-compatible',
              baseUrl: stored.baseUrl ?? '',
              model: stored.model ?? '',
              apiKey: await ZapNoteCredentialService.getAiApiKey(stored.id),
              outputContent: stored.outputContent ?? ''
            });
          }
        }
      } catch (error) {
        console.error('ZapNotePreferencesService parse AI configs failed: ' + JSON.stringify(error));
      }
    }
    if (hasStoredConfigList) {
      return configs;
    }
    const legacyConfig: AiVisualEngineConfig = {
      id: 'legacy',
      providerName: await ZapNotePreferencesService.getString('aiVisualProviderName', ''),
      provider: await ZapNotePreferencesService.getString('aiVisualProvider', 'openai-compatible'),
      baseUrl: await ZapNotePreferencesService.getString('aiVisualBaseUrl', ''),
      model: await ZapNotePreferencesService.getString('aiVisualModel', ''),
      apiKey: await ZapNoteCredentialService.getAiApiKey(),
      outputContent: await ZapNotePreferencesService.getString('aiVisualOutputContent', '')
    };
    return legacyConfig.providerName.length > 0 || legacyConfig.baseUrl.length > 0 || legacyConfig.model.length > 0 ||
      legacyConfig.apiKey.length > 0 || legacyConfig.outputContent.length > 0 ? [legacyConfig] : [];
  }

  public static async getAiVisualEngineConfig(configId: string = ''): Promise<AiVisualEngineConfig> {
    const configs: AiVisualEngineConfig[] = await ZapNotePreferencesService.getAiVisualEngineConfigs();
    for (let index: number = 0; index < configs.length; index++) {
      if (configId.length === 0 || configs[index].id === configId) {
        return configs[index];
      }
    }
    return {
      id: '',
      providerName: '',
      provider: 'openai-compatible',
      baseUrl: '',
      model: '',
      apiKey: '',
      outputContent: ''
    };
  }

  public static async setAiVisualEngineConfig(config: AiVisualEngineConfig): Promise<void> {
    const configs: AiVisualEngineConfig[] = await ZapNotePreferencesService.getAiVisualEngineConfigs();
    const next: StoredAiVisualEngineConfig[] = [];
    let replaced: boolean = false;
    for (let index: number = 0; index < configs.length; index++) {
      const current: AiVisualEngineConfig = configs[index];
      if (current.id === config.id) {
        next.push(ZapNotePreferencesService.storedAiConfig(config));
        replaced = true;
      } else {
        next.push(ZapNotePreferencesService.storedAiConfig(current));
      }
    }
    if (!replaced) {
      next.push(ZapNotePreferencesService.storedAiConfig(config));
    }
    if (!await ZapNoteCredentialService.setAiApiKey(config.apiKey.trim(), config.id)) {
      throw new Error('AI API Key 安全保存失败');
    }
    await ZapNotePreferencesService.putValue('aiVisualEngineConfigs', JSON.stringify(next));
  }

  public static async deleteAiVisualEngineConfig(configId: string): Promise<void> {
    const normalizedId: string = configId.trim();
    if (normalizedId.length === 0) {
      return;
    }
    const configs: AiVisualEngineConfig[] = await ZapNotePreferencesService.getAiVisualEngineConfigs();
    const next: StoredAiVisualEngineConfig[] = [];
    for (let index: number = 0; index < configs.length; index++) {
      if (configs[index].id !== normalizedId) {
        next.push(ZapNotePreferencesService.storedAiConfig(configs[index]));
      }
    }
    if (!await ZapNoteCredentialService.setAiApiKey('', normalizedId)) {
      throw new Error('AI API Key 安全删除失败');
    }
    if (normalizedId === 'legacy') {
      if (!await ZapNoteCredentialService.setAiApiKey('')) {
        throw new Error('旧版 AI API Key 安全删除失败');
      }
      await ZapNotePreferencesService.putValue('aiVisualProviderName', '');
      await ZapNotePreferencesService.putValue('aiVisualProvider', '');
      await ZapNotePreferencesService.putValue('aiVisualBaseUrl', '');
      await ZapNotePreferencesService.putValue('aiVisualModel', '');
      await ZapNotePreferencesService.putValue('aiVisualOutputContent', '');
    }
    await ZapNotePreferencesService.putValue('aiVisualEngineConfigs', JSON.stringify(next));
  }

  public static async setAiVisualOutputContent(configId: string, value: string): Promise<void> {
    const config: AiVisualEngineConfig = await ZapNotePreferencesService.getAiVisualEngineConfig(configId);
    if (config.id.length === 0) {
      return;
    }
    config.outputContent = value.trim();
    await ZapNotePreferencesService.setAiVisualEngineConfig(config);
  }

  private static storedAiConfig(config: AiVisualEngineConfig): StoredAiVisualEngineConfig {
    return {
      id: config.id,
      providerName: config.providerName.trim(),
      provider: config.provider,
      baseUrl: config.baseUrl.trim(),
      model: config.model.trim(),
      outputContent: config.outputContent.trim()
    };
  }

  public static async getSelectedPhotoStyle(): Promise<string> {
    return await ZapNotePreferencesService.getString('selectedPhotoStyle', 'original');
  }

  public static async setSelectedPhotoStyle(value: string): Promise<void> {
    await ZapNotePreferencesService.putValue('selectedPhotoStyle', value);
  }

  public static async getMatchRuleItems(): Promise<MatchRuleTemplateItem[] | null> {
    const raw: string = await ZapNotePreferencesService.getString('matchRuleItems', '');
    if (raw.length === 0) {
      return null;
    }
    try {
      const parsed: MatchRuleTemplateItem[] = JSON.parse(raw) as MatchRuleTemplateItem[];
      return Array.isArray(parsed) ? ZapNotePreferencesService.cloneMatchRuleItems(parsed) : null;
    } catch (error) {
      console.error('ZapNotePreferencesService getMatchRuleItems failed: ' + JSON.stringify(error));
      return null;
    }
  }

  public static async setMatchRuleItems(value: MatchRuleTemplateItem[]): Promise<void> {
    await ZapNotePreferencesService.putValue('matchRuleItems',
      JSON.stringify(ZapNotePreferencesService.cloneMatchRuleItems(value)));
  }

  public static async getDiaries(): Promise<DiaryEntry[]> {
    const raw: string = await ZapNotePreferencesService.getString('diaries', '[]');
    try {
      const parsed: DiaryEntry[] = JSON.parse(raw) as DiaryEntry[];
      return Array.isArray(parsed) ? ZapNotePreferencesService.cloneDiaries(parsed) : [];
    } catch (error) {
      console.error('ZapNotePreferencesService getDiaries failed: ' + JSON.stringify(error));
      return [];
    }
  }

  public static async setDiaries(value: DiaryEntry[]): Promise<void> {
    await ZapNotePreferencesService.putValue('diaries', JSON.stringify(ZapNotePreferencesService.cloneDiaries(value)));
  }

  public static async getDiaryFolders(): Promise<string[]> {
    const raw: string = await ZapNotePreferencesService.getString('diaryFolders', '[]');
    try {
      const parsed: string[] = JSON.parse(raw) as string[];
      return Array.isArray(parsed) ? ZapNotePreferencesService.cloneStringList(parsed) : [];
    } catch (error) {
      console.error('ZapNotePreferencesService getDiaryFolders failed: ' + JSON.stringify(error));
      return [];
    }
  }

  public static async setDiaryFolders(value: string[]): Promise<void> {
    await ZapNotePreferencesService.putValue('diaryFolders', JSON.stringify(ZapNotePreferencesService.cloneStringList(value)));
  }

  private static async getString(key: string, defaultValue: string): Promise<string> {
    const value: preferences.ValueType = await ZapNotePreferencesService.getValue(key, defaultValue);
    return typeof value === 'string' ? value : defaultValue;
  }

  private static async getBoolean(key: string, defaultValue: boolean): Promise<boolean> {
    const value: preferences.ValueType = await ZapNotePreferencesService.getValue(key, defaultValue);
    return typeof value === 'boolean' ? value : defaultValue;
  }

  private static async getValue(key: string, defaultValue: preferences.ValueType): Promise<preferences.ValueType> {
    if (!ZapNotePreferencesService.pref) {
      return defaultValue;
    }
    try {
      return await ZapNotePreferencesService.pref.get(key, defaultValue);
    } catch (error) {
      console.error('ZapNotePreferencesService getValue failed: ' + JSON.stringify(error));
      return defaultValue;
    }
  }

  private static async putValue(key: string, value: preferences.ValueType): Promise<void> {
    if (!ZapNotePreferencesService.pref) {
      return;
    }
    try {
      await ZapNotePreferencesService.pref.put(key, value);
      await ZapNotePreferencesService.pref.flush();
    } catch (error) {
      console.error('ZapNotePreferencesService putValue failed: ' + JSON.stringify(error));
    }
  }

  private static cloneDiaries(diaries: DiaryEntry[]): DiaryEntry[] {
    const result: DiaryEntry[] = [];
    diaries.forEach((entry: DiaryEntry) => {
      const photoUri: string = typeof entry.photoUri === 'string' ? entry.photoUri : '';
      const legacyDateMs: number = typeof entry.dateMs === 'number' ? entry.dateMs : Date.now();
      let photoUris: string[] = Array.isArray(entry.photoUris) ?
        entry.photoUris.filter((item: string) => typeof item === 'string' && item.trim().length > 0) :
        [];
      if (photoUris.length === 0 && photoUri.length > 0) {
        photoUris = [photoUri];
      }
      result.push({
        id: entry.id,
        title: entry.title,
        body: entry.body,
        folderName: typeof entry.folderName === 'string' ? entry.folderName : '',
        dateText: entry.dateText,
        dateMs: legacyDateMs,
        createdAt: typeof entry.createdAt === 'number' && entry.createdAt > 0 ? entry.createdAt : legacyDateMs,
        updatedAt: typeof entry.updatedAt === 'number' && entry.updatedAt > 0 ? entry.updatedAt : legacyDateMs,
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
        thumbnailScale: typeof entry.thumbnailScale === 'number' ? Math.max(1, Math.min(entry.thumbnailScale, 4)) : 1,
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
      });
    });
    return result;
  }

  private static async deleteValue(key: string): Promise<void> {
    if (!ZapNotePreferencesService.pref) {
      return;
    }
    try {
      await ZapNotePreferencesService.pref.delete(key);
      await ZapNotePreferencesService.pref.flush();
    } catch (error) {
      console.error('ZapNotePreferencesService deleteValue failed: ' + JSON.stringify(error));
    }
  }

  private static cloneStringList(items: string[]): string[] {
    const result: string[] = [];
    items.forEach((item: string) => {
      const value: string = typeof item === 'string' ? item.trim() : '';
      if (value.length > 0 && result.indexOf(value) < 0) {
        result.push(value);
      }
    });
    return result;
  }

  private static cloneMatchRuleItems(items: MatchRuleTemplateItem[]): MatchRuleTemplateItem[] {
    const result: MatchRuleTemplateItem[] = [];
    items.forEach((item: MatchRuleTemplateItem) => {
      if (item.id === ZapNotePreferencesService.REMOVED_TEST_MATCH_RULE_ID) {
        return;
      }
      const scopes: string[] = [];
      if (Array.isArray(item.scopes)) {
        item.scopes.forEach((scope: string) => {
          if (typeof scope === 'string' && scope.length > 0) {
            scopes.push(scope);
          }
        });
      }
      result.push({
        id: typeof item.id === 'string' ? item.id : '',
        kind: ZapNotePreferencesService.normalizeMatchRuleTemplateKind(item.kind),
        aiConfigId: typeof item.aiConfigId === 'string' ? item.aiConfigId : '',
        scopes: scopes,
        keyword: typeof item.keyword === 'string' ? item.keyword : '',
        template: typeof item.template === 'string' ? item.template : '',
        enabled: typeof item.enabled === 'boolean' ? item.enabled : true,
        action: ZapNotePreferencesService.normalizeMatchRuleAction(item.action),
        range: ZapNotePreferencesService.normalizeMatchRuleRange(item.range),
        matchMode: ZapNotePreferencesService.normalizeMatchRuleMode(item.matchMode),
        linkType: ZapNotePreferencesService.normalizeLinkType(item.linkType)
      });
    });
    return result;
  }

  private static normalizeMatchRuleAction(value: MatchRuleAction): MatchRuleAction {
    if (value === 'exclude' || value === 'mask') {
      return value;
    }
    return 'extract';
  }

  private static normalizeMatchRuleRange(value: MatchRuleRange): MatchRuleRange {
    if (value === 'match' || value === 'block') {
      return value;
    }
    return 'line';
  }

  private static normalizeMatchRuleMode(value: MatchRuleMode): MatchRuleMode {
    return value === 'regex' ? 'regex' : 'contains';
  }

  private static normalizeMatchRuleTemplateKind(value: MatchRuleTemplateKind): MatchRuleTemplateKind {
    return value === 'ai-output' ? 'ai-output' : 'keyword';
  }

  private static normalizeLinkType(value: LinkType | undefined): LinkType {
    if (value === 'all' || value === 'magnet' || value === 'baidu' || value === 'aliyun' || value === 'quark' ||
      value === '115' || value === 'tianyi' || value === 'xunlei' || value === 'feishu' || value === 'qq' ||
      value === 'wechat' || value === 'web') {
      return value;
    }
    return 'none';
  }
}

