export interface DiaryEntry {
  id: string;
  title: string;
  body: string;
  folderName: string;
  dateText: string;
  dateMs: number;
  createdAt?: number;
  updatedAt?: number;
  mood: string;
  weather: string;
  isToday: boolean;
  isThisWeek: boolean;
  isFavorite: boolean;
  /** Notes marked private are only rendered by the privacy vault. */
  isPrivate?: boolean;
  wordCount: number;
  hasPhoto: boolean;
  photoInBody: boolean;
  photoUri: string;
  photoUris?: string[];
  thumbnailPhotoIndex?: number;
  thumbnailScale?: number;
  thumbnailOffsetX?: number;
  thumbnailOffsetY?: number;
  thumbnailPhotoAspect?: number;
  photoX: number;
  photoY: number;
  photoWidth: number;
  photoHeight: number;
  photoRotation: number;
  photoStyle: string;
}

export interface RecycleBinEntry {
  diary: DiaryEntry;
  deletedAt: number;
}

export interface ValueOption {
  label: string;
  value: string;
  description: string;
}

export interface MoodStat {
  label: string;
  emoji: string;
  color: string;
  count: number;
  percent: number;
}

export interface SyncLog {
  createdAt?: number;
  time: string;
  title: string;
  detail: string;
  type: string;
}

export type MatchRuleAction = 'extract' | 'exclude' | 'mask';

export type MatchRuleRange = 'match' | 'line' | 'block';

export type MatchRuleMode = 'contains' | 'regex';

export type MatchRuleTemplateKind = 'keyword' | 'ai-output';

export type LinkType = 'none' | 'all' | 'magnet' | 'baidu' | 'aliyun' | 'quark' | '115' | 'tianyi' |
  'xunlei' | 'feishu' | 'qq' | 'wechat' | 'web';

export interface MatchRuleTemplateItem {
  id: string;
  kind: MatchRuleTemplateKind;
  aiConfigId: string;
  scopes: string[];
  keyword: string;
  template: string;
  enabled: boolean;
  action: MatchRuleAction;
  range: MatchRuleRange;
  matchMode: MatchRuleMode;
  linkType?: LinkType;
}

export interface AiVisualEngineConfig {
  id: string;
  providerName: string;
  provider: string;
  baseUrl: string;
  model: string;
  apiKey: string;
  outputContent: string;
}

export interface AiVisualEngineOption {
  label: string;
  value: string;
}

export interface AiVisualEngineBackupConfig {
  id: string;
  providerName: string;
  provider: string;
  baseUrl: string;
  model: string;
  outputContent: string;
}

export interface HuaweiAccountInfo {
  openId: string;
  unionId: string;
  nickName: string;
  avatarUri: string;
  anonymousPhoneNumber: string;
  mobileNumber: string;
  loginState: string;
  loginStateText: string;
  phoneConsistencyState: string;
  phoneConsistencyText: string;
  localNumberConsistency: boolean;
  hasLocalNumberConsistency: boolean;
  phoneAuthorizationGranted: boolean;
  phoneAuthorizationText: string;
  lastUpdatedAt: number;
}

export type SyncDataScope = 'diaries' | 'settings' | 'all';

export interface ZapNoteBackupSettings {
  themeMode?: string;
  lightingMode?: string;
  selectedAccentColor?: string;
  gripModeEnabled?: boolean;
  privacyEnabled?: boolean;
  autoFillEnabled?: boolean;
  vibrateEnabled?: boolean;
  doubleTouchEnabled?: boolean;
  doubleTouchAction?: string;
  sharedPhotoSaveMode?: string;
  sharedPhotoAutoRecognizeEnabled?: boolean;
  sharedPhotoSaveToAlbumEnabled?: boolean;
  enhancedLinkRecognitionEnabled?: boolean;
  engine?: string;
  aiVisualProvider?: string;
  aiVisualProviderName?: string;
  aiVisualBaseUrl?: string;
  aiVisualModel?: string;
  aiVisualOutputContent?: string;
  aiVisualConfigs?: AiVisualEngineBackupConfig[];
  selectedPhotoStyle?: string;
  syncInterval?: string;
  syncOnChange?: boolean;
  syncMode?: number;
  syncTimes?: string[];
  historyLimit?: number;
  syncRestoreStrategy?: string;
  syncDataScope?: SyncDataScope;
  webdavUrl?: string;
  webdavUser?: string;
  webdavPass?: string;
  webdavRemotePath?: string;
  matchRuleItems?: MatchRuleTemplateItem[];
}

export type DiaryFilter = 'all' | 'today' | 'week' | 'month' | 'favorite';

export type SettingPanel = 'main' | 'huaweiAccountLogin' | 'appearance' | 'autofill' | 'sync' | 'webdav' | 'privacy' |
  'data' | 'recycleBin' | 'guide' | 'userAgreement' | 'about';
