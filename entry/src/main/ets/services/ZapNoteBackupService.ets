import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { zlib } from '@kit.BasicServicesKit';
import fileUri from '@ohos.file.fileuri';
import {
  AiVisualEngineBackupConfig,
  DiaryEntry,
  MatchRuleTemplateItem,
  SyncDataScope,
  ZapNoteBackupSettings
} from '../model/ZapNoteTypes';

interface ZapNoteBackupPhotoAsset {
  sourceUri: string;
  fileExt: string;
  dataBase64: string;
}

interface ZapNoteBackupPayload {
  app: string;
  version: number;
  createdAt: number;
  createdAtText: string;
  scope: SyncDataScope;
  data: ZapNoteBackupData;
}

interface ZapNoteBackupData {
  diaries?: DiaryEntry[];
  diaryFolders?: string[];
  photos?: ZapNoteBackupPhotoAsset[];
  photoManifest?: ZapNoteBackupPhotoManifest[];
  settings?: ZapNoteBackupSettings;
}

interface ZapNoteBackupRecord {
  app?: string;
  version?: number;
  createdAt?: number;
  createdAtText?: string;
  scope?: SyncDataScope;
  data?: ZapNoteBackupDataRecord;
  diaries?: DiaryEntry[];
  entries?: DiaryEntry[];
  diaryFolders?: string[];
  photos?: ZapNoteBackupPhotoAsset[];
  settings?: ZapNoteBackupSettings;
}

interface ZapNoteBackupDataRecord {
  diaries?: DiaryEntry[];
  entries?: DiaryEntry[];
  diaryFolders?: string[];
  photos?: ZapNoteBackupPhotoAsset[];
  photoManifest?: ZapNoteBackupPhotoManifest[];
  settings?: ZapNoteBackupSettings;
}

export interface ZapNoteBackupExportResult {
  content: string;
  skippedPhotoCount: number;
}

interface ZapNoteBackupPhotoManifest {
  sourceUri: string;
  archivePath: string;
  fileExt: string;
}

export interface ZapNoteBackupZipResult {
  zipPath: string;
  fileName: string;
  photoCount: number;
  skippedPhotoCount: number;
}

export interface ZapNoteBackupZipRestoreResult {
  content: string;
  diaries: DiaryEntry[];
  diaryFolders: string[];
  restoredPhotoCount: number;
  skippedPhotoCount: number;
}

interface ZapNoteBackupPhotoCollectionResult {
  assets: ZapNoteBackupPhotoAsset[];
  skippedPhotoCount: number;
}

export interface ZapNoteRestoreSummary {
  diaryCount: number;
  wordCount: number;
}

export class ZapNoteBackupService {
  public static readonly BACKUP_FILE_NAME: string = 'zapnote-backup.zip';
  public static readonly LEGACY_BACKUP_FILE_NAME: string = 'zapnote-backup.json';
  private static readonly PAYLOAD_APP: string = 'zapnote';
  private static readonly PAYLOAD_VERSION: number = 3;
  // Kept for the legacy photo-copy helper. Portable backup export no longer uses
  // collectPhotoAssets, so these limits cannot trigger large allocations there.
  private static readonly MAX_EMBEDDED_PHOTO_BYTES: number = 2 * 1024 * 1024;
  private static readonly MAX_TOTAL_EMBEDDED_PHOTO_BYTES: number = 8 * 1024 * 1024;
  // Photo bytes are deliberately excluded from portable JSON backups. Encoding every
  // original photo as Base64 created several simultaneous large allocations and could
  // terminate the app before either local export or WebDAV upload began.

  public static async copyPhotoToAppFiles(context: common.Context, photoUri: string): Promise<string> {
    const rootPath: string = context.filesDir + '/zapnote-photos';
    try {
      if (!fileIo.accessSync(rootPath)) {
        fileIo.mkdirSync(rootPath);
      }
    } catch (error) {
      console.error('ZapNoteBackupService prepare local photo folder failed: ' + JSON.stringify(error));
    }
    let file: fileIo.File | null = null;
    try {
      const source: image.ImageSource = image.createImageSource(photoUri);
      const info: image.ImageInfo = await source.getImageInfo();
      const preservePng: boolean = info.alphaType !== image.AlphaType.OPAQUE;
      const targetPath: string = rootPath + '/photo-' + Date.now().toString() + '-' +
        Math.floor(Math.random() * 1000000).toString() + (preservePng ? '.png' : '.jpg');
      file = fileIo.openSync(targetPath,
        fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.SYNC);
      const packer: image.ImagePacker = image.createImagePacker();
      try {
        await packer.packToFile(source, file.fd,
          preservePng ? { format: 'image/png', quality: 100 } : { format: 'image/jpeg', quality: 80 });
      } finally {
        await packer.release();
        await source.release();
      }
      return ZapNoteBackupService.displayFileUri(targetPath);
    } catch (error) {
      console.error('ZapNoteBackupService copyPhotoToAppFiles failed: ' + JSON.stringify(error));
      return '';
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          console.error('ZapNoteBackupService close copied photo failed: ' + JSON.stringify(error));
        }
      }
    }
  }

  public static async exportBackupZip(context: common.Context, diaries: DiaryEntry[], createdAt: number = Date.now(),
    settings?: ZapNoteBackupSettings, scope: SyncDataScope = 'all', diaryFolders: string[] = []): Promise<ZapNoteBackupZipResult> {
    const root: string = context.cacheDir + '/zapnote-backups/' + createdAt.toString();
    const photosDir: string = root + '/photos';
    ZapNoteBackupService.ensureDirectory(context.cacheDir + '/zapnote-backups');
    ZapNoteBackupService.ensureDirectory(root);
    const normalizedScope: SyncDataScope = ZapNoteBackupService.normalizeScope(scope);
    const base: ZapNoteBackupExportResult = await ZapNoteBackupService.exportBackupJsonWithReport(
      diaries, createdAt, settings, normalizedScope, diaryFolders);
    const payload: ZapNoteBackupPayload = JSON.parse(base.content) as ZapNoteBackupPayload;
    const manifest: ZapNoteBackupPhotoManifest[] = [];
    let skipped: number = 0;
    if (normalizedScope !== 'settings') {
      ZapNoteBackupService.ensureDirectory(photosDir);
      const seen: string[] = [];
      for (let entryIndex: number = 0; entryIndex < diaries.length; entryIndex++) {
        const uris: string[] = ZapNoteBackupService.entryPhotoUris(diaries[entryIndex]);
        for (let uriIndex: number = 0; uriIndex < uris.length; uriIndex++) {
          const sourceUri: string = uris[uriIndex];
          if (seen.indexOf(sourceUri) >= 0) {
            continue;
          }
          seen.push(sourceUri);
          const ext: string = ZapNoteBackupService.safePhotoExtension(ZapNoteBackupService.detectPhotoExtension(sourceUri, new ArrayBuffer(0)));
          const archivePath: string = 'photos/photo-' + manifest.length.toString() + ext;
          if (ZapNoteBackupService.copyFile(sourceUri, root + '/' + archivePath)) {
            manifest.push({ sourceUri: sourceUri, archivePath: archivePath, fileExt: ext });
          } else {
            skipped++;
          }
        }
      }
      payload.data.photoManifest = manifest;
      payload.data.photos = [];
    }
    ZapNoteBackupService.writeTextFile(root + '/backup.json', JSON.stringify(payload));
    const zipPath: string = context.cacheDir + '/zapnote-backups/' + ZapNoteBackupService.exportBackupZipFileName(createdAt);
    await zlib.compressFile(root, zipPath, ZapNoteBackupService.zipOptions());
    return { zipPath: zipPath, fileName: ZapNoteBackupService.exportBackupZipFileName(createdAt), photoCount: manifest.length, skippedPhotoCount: skipped };
  }

  public static async restoreBackupZip(context: common.Context, sourceUri: string): Promise<ZapNoteBackupZipRestoreResult> {
    const stamp: number = Date.now();
    const root: string = context.cacheDir + '/zapnote-backup-import-' + stamp.toString();
    const inputZip: string = root + '/source.zip';
    const extracted: string = root + '/content';
    ZapNoteBackupService.ensureDirectory(root);
    ZapNoteBackupService.ensureDirectory(extracted);
    if (!ZapNoteBackupService.copyFile(sourceUri, inputZip)) {
      throw new Error('无法读取 ZIP 备份文件');
    }
    await zlib.decompressFile(inputZip, extracted, ZapNoteBackupService.zipOptions());
    const contentRoot: string = ZapNoteBackupService.findBackupRoot(extracted);
    const jsonPath: string = contentRoot + '/backup.json';
    if (!fileIo.accessSync(jsonPath)) {
      throw new Error('ZIP 备份缺少 backup.json');
    }
    const content: string = fileIo.readTextSync(jsonPath);
    const payload: object | object[] = ZapNoteBackupService.parseBackupContent(content);
    const manifest: ZapNoteBackupPhotoManifest[] = ZapNoteBackupService.extractPhotoManifest(payload);
    const restoredUris: Map<string, string> = new Map<string, string>();
    let skipped: number = 0;
    const photoRoot: string = context.filesDir + '/zapnote-backup-photos';
    ZapNoteBackupService.ensureDirectory(photoRoot);
    manifest.forEach((item: ZapNoteBackupPhotoManifest, index: number) => {
      if (!ZapNoteBackupService.isSafeArchivePhotoPath(item.archivePath)) {
        skipped++;
        return;
      }
      const target: string = photoRoot + '/restored-' + stamp.toString() + '-' + index.toString() +
        ZapNoteBackupService.safePhotoExtension(item.fileExt);
      if (ZapNoteBackupService.copyFile(contentRoot + '/' + item.archivePath, target)) {
        restoredUris.set(item.sourceUri, ZapNoteBackupService.displayFileUri(target));
      } else {
        skipped++;
      }
    });
    return {
      content: content,
      diaries: ZapNoteBackupService.cloneDiaries(ZapNoteBackupService.extractDiaries(payload, true), restoredUris),
      diaryFolders: ZapNoteBackupService.restoreDiaryFolders(content),
      restoredPhotoCount: restoredUris.size,
      skippedPhotoCount: skipped
    };
  }

  public static async exportBackupJson(diaries: DiaryEntry[], createdAt: number = Date.now(),
    settings?: ZapNoteBackupSettings, scope: SyncDataScope = 'all', diaryFolders: string[] = []): Promise<string> {
    const result: ZapNoteBackupExportResult = await ZapNoteBackupService.exportBackupJsonWithReport(
      diaries, createdAt, settings, scope, diaryFolders);
    return result.content;
  }

  public static async exportBackupJsonWithReport(diaries: DiaryEntry[], createdAt: number = Date.now(),
    settings?: ZapNoteBackupSettings, scope: SyncDataScope = 'all', diaryFolders: string[] = []): Promise<ZapNoteBackupExportResult> {
    const normalizedScope: SyncDataScope = ZapNoteBackupService.normalizeScope(scope);
    const data: ZapNoteBackupData = {};
    let skippedPhotoCount: number = 0;
    if (normalizedScope !== 'settings') {
      data.diaries = ZapNoteBackupService.cloneDiaries(diaries);
      data.diaryFolders = ZapNoteBackupService.cloneStringList(diaryFolders);
      data.photos = [];
      skippedPhotoCount = ZapNoteBackupService.countUniquePhotoUris(diaries);
    }
    if (normalizedScope !== 'diaries' && settings !== undefined) {
      data.settings = ZapNoteBackupService.cloneSettings(settings);
    }
    const payload: ZapNoteBackupPayload = {
      app: ZapNoteBackupService.PAYLOAD_APP,
      version: ZapNoteBackupService.PAYLOAD_VERSION,
      createdAt: createdAt,
      createdAtText: ZapNoteBackupService.formatDateTimeText(createdAt),
      scope: normalizedScope,
      data: data
    };
    return {
      content: JSON.stringify(payload),
      skippedPhotoCount: skippedPhotoCount
    };
  }

  public static exportBackupFileName(createdAt: number = Date.now()): string {
    const date: Date = new Date(createdAt);
    return 'zapnote-backup-' + date.getFullYear().toString() +
      ZapNoteBackupService.pad2(date.getMonth() + 1) +
      ZapNoteBackupService.pad2(date.getDate()) + '-' +
      ZapNoteBackupService.pad2(date.getHours()) +
      ZapNoteBackupService.pad2(date.getMinutes()) +
      ZapNoteBackupService.pad2(date.getSeconds()) + '.json';
  }

  public static exportBackupZipFileName(createdAt: number = Date.now()): string {
    return ZapNoteBackupService.exportBackupFileName(createdAt).replace('.json', '.zip');
  }

  public static backupCreatedAtText(content: string): string {
    try {
      const payload: object | object[] = ZapNoteBackupService.parseBackupContent(content);
      if (Array.isArray(payload)) {
        return '';
      }
      const record: ZapNoteBackupRecord = payload as ZapNoteBackupRecord;
      if (typeof record.createdAtText === 'string' && record.createdAtText.length > 0) {
        return record.createdAtText;
      }
      if (typeof record.createdAt === 'number' && !Number.isNaN(record.createdAt)) {
        return ZapNoteBackupService.formatDateTimeText(record.createdAt);
      }
      return '';
    } catch (error) {
      console.error('ZapNoteBackupService backupCreatedAtText failed: ' + JSON.stringify(error));
      return '';
    }
  }

  public static hasDiaryData(content: string): boolean {
    const payload: object | object[] = ZapNoteBackupService.parseBackupContent(content);
    return ZapNoteBackupService.extractDiaries(payload, false).length > 0;
  }

  public static hasSettingsData(content: string): boolean {
    const payload: object | object[] = ZapNoteBackupService.parseBackupContent(content);
    return ZapNoteBackupService.extractSettings(payload) !== null;
  }

  public static restoreBackupJson(contextOrContent: common.Context | string, content?: string): DiaryEntry[] {
    const hasContext: boolean = typeof contextOrContent !== 'string';
    const context: common.Context | undefined = hasContext ? contextOrContent as common.Context : undefined;
    const rawContent: string = hasContext ? (typeof content === 'string' ? content : '') : contextOrContent as string;
    const payload: object | object[] = ZapNoteBackupService.parseBackupContent(rawContent);
    const diaries: DiaryEntry[] = ZapNoteBackupService.extractDiaries(payload, true);
    const restoredPhotoUris: Map<string, string> = context !== undefined ?
      ZapNoteBackupService.restorePhotoAssets(context, ZapNoteBackupService.extractPhotoAssets(payload),
        ZapNoteBackupService.extractCreatedAt(payload)) : new Map<string, string>();
    return ZapNoteBackupService.cloneDiaries(diaries, restoredPhotoUris);
  }

  public static restoreDiaryFolders(content: string): string[] {
    const payload: object | object[] = ZapNoteBackupService.parseBackupContent(content);
    if (Array.isArray(payload)) {
      return [];
    }
    const record: ZapNoteBackupRecord = payload as ZapNoteBackupRecord;
    if (Array.isArray(record.diaryFolders)) {
      return ZapNoteBackupService.cloneStringList(record.diaryFolders);
    }
    if (record.data !== undefined && Array.isArray(record.data.diaryFolders)) {
      return ZapNoteBackupService.cloneStringList(record.data.diaryFolders);
    }
    return [];
  }

  public static restoreSettings(content: string): ZapNoteBackupSettings | null {
    const payload: object | object[] = ZapNoteBackupService.parseBackupContent(content);
    return ZapNoteBackupService.extractSettings(payload);
  }

  public static summarize(diaries: DiaryEntry[]): ZapNoteRestoreSummary {
    let wordCount: number = 0;
    diaries.forEach((entry: DiaryEntry) => {
      wordCount += ZapNoteBackupService.safeNumber(entry.wordCount, 0);
    });
    return {
      diaryCount: diaries.length,
      wordCount: wordCount
    };
  }

  public static formatDateTimeText(dateMs: number): string {
    const normalized: number = dateMs > 0 ? dateMs : Date.now();
    const date: Date = new Date(normalized);
    return date.getFullYear().toString() + '-' + ZapNoteBackupService.pad2(date.getMonth() + 1) + '-' +
      ZapNoteBackupService.pad2(date.getDate()) + ' ' + ZapNoteBackupService.pad2(date.getHours()) + ':' +
      ZapNoteBackupService.pad2(date.getMinutes()) + ':' + ZapNoteBackupService.pad2(date.getSeconds());
  }

  private static zipOptions(): zlib.Options {
    return {
      level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
      memLevel: zlib.MemLevel.MEM_LEVEL_DEFAULT,
      strategy: zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT_STRATEGY
    };
  }

  private static ensureDirectory(path: string): void {
    try {
      if (!fileIo.accessSync(path)) {
        fileIo.mkdirSync(path);
      }
    } catch (error) {
      throw new Error('无法创建备份目录：' + path);
    }
  }

  private static writeTextFile(path: string, content: string): void {
    let file: fileIo.File | null = null;
    try {
      file = fileIo.openSync(path, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(file.fd, content);
    } finally {
      if (file !== null) {
        fileIo.closeSync(file);
      }
    }
  }

  private static copyFile(sourceUri: string, targetPath: string): boolean {
    let source: fileIo.File | null = null;
    let target: fileIo.File | null = null;
    try {
      source = ZapNoteBackupService.openPhotoReadOnly(sourceUri);
      if (source === null) {
        return false;
      }
      target = fileIo.openSync(targetPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.copyFileSync(source.fd, target.fd);
      return true;
    } catch (error) {
      console.error('ZapNoteBackupService copy file failed: ' + JSON.stringify(error));
      return false;
    } finally {
      if (source !== null) {
        try { fileIo.closeSync(source); } catch (error) { console.error(JSON.stringify(error)); }
      }
      if (target !== null) {
        try { fileIo.closeSync(target); } catch (error) { console.error(JSON.stringify(error)); }
      }
    }
  }

  private static extractPhotoManifest(payload: object | object[]): ZapNoteBackupPhotoManifest[] {
    if (Array.isArray(payload)) {
      return [];
    }
    const record: ZapNoteBackupRecord = payload as ZapNoteBackupRecord;
    const source: ZapNoteBackupPhotoManifest[] | undefined = record.data !== undefined &&
      Array.isArray(record.data.photoManifest) ? record.data.photoManifest : undefined;
    if (source === undefined) {
      return [];
    }
    const result: ZapNoteBackupPhotoManifest[] = [];
    source.forEach((item: ZapNoteBackupPhotoManifest) => {
      const sourceUri: string = ZapNoteBackupService.safeString(item.sourceUri);
      const archivePath: string = ZapNoteBackupService.safeString(item.archivePath);
      if (sourceUri.length > 0 && ZapNoteBackupService.isSafeArchivePhotoPath(archivePath)) {
        result.push({ sourceUri: sourceUri, archivePath: archivePath,
          fileExt: ZapNoteBackupService.safePhotoExtension(ZapNoteBackupService.safeString(item.fileExt, '.jpg')) });
      }
    });
    return result;
  }

  private static isSafeArchivePhotoPath(value: string): boolean {
    const path: string = value.trim().replace(/\\/g, '/');
    return path.startsWith('photos/') && path.indexOf('..') < 0 && path.indexOf('//') < 0 && path.length > 'photos/'.length;
  }

  private static findBackupRoot(extracted: string): string {
    if (fileIo.accessSync(extracted + '/backup.json')) {
      return extracted;
    }
    try {
      const children: string[] = fileIo.listFileSync(extracted);
      for (let index: number = 0; index < children.length; index++) {
        const candidate: string = extracted + '/' + children[index];
        if (fileIo.accessSync(candidate + '/backup.json')) {
          return candidate;
        }
      }
    } catch (error) {
      console.error('ZapNoteBackupService inspect ZIP root failed: ' + JSON.stringify(error));
    }
    return extracted;
  }

  private static parseBackupContent(content: string): object | object[] {
    const normalized: string = ZapNoteBackupService.extractJsonText(content);
    const parsed: Object = JSON.parse(normalized) as Object;
    if (typeof parsed === 'string') {
      return JSON.parse(ZapNoteBackupService.extractJsonText(parsed)) as object | object[];
    }
    return parsed as object | object[];
  }

  private static extractJsonText(content: string): string {
    let text: string = content.trim();
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    const objectStart: number = text.indexOf('{');
    const arrayStart: number = text.indexOf('[');
    let start: number = -1;
    let end: number = -1;
    if (objectStart >= 0 && (arrayStart < 0 || objectStart < arrayStart)) {
      start = objectStart;
      end = text.lastIndexOf('}');
    } else if (arrayStart >= 0) {
      start = arrayStart;
      end = text.lastIndexOf(']');
    }
    if (start >= 0 && end >= start) {
      return text.substring(start, end + 1);
    }
    return text;
  }

  private static extractDiaries(payload: object | object[], throwOnMissing: boolean): DiaryEntry[] {
    if (Array.isArray(payload)) {
      return payload as DiaryEntry[];
    }
    const record: ZapNoteBackupRecord = payload as ZapNoteBackupRecord;
    if (Array.isArray(record.diaries)) {
      return record.diaries;
    }
    if (Array.isArray(record.entries)) {
      return record.entries;
    }
    if (record.data !== undefined) {
      if (Array.isArray(record.data.diaries)) {
        return record.data.diaries;
      }
      if (Array.isArray(record.data.entries)) {
        return record.data.entries;
      }
    }
    if (throwOnMissing) {
      throw new Error('backup does not contain diary data');
    }
    return [];
  }

  private static extractSettings(payload: object | object[]): ZapNoteBackupSettings | null {
    if (Array.isArray(payload)) {
      return null;
    }
    const record: ZapNoteBackupRecord = payload as ZapNoteBackupRecord;
    if (record.settings !== undefined) {
      return ZapNoteBackupService.cloneSettings(record.settings);
    }
    if (record.data !== undefined && record.data.settings !== undefined) {
      return ZapNoteBackupService.cloneSettings(record.data.settings);
    }
    return null;
  }

  private static extractCreatedAt(payload: object | object[]): number {
    if (Array.isArray(payload)) {
      return Date.now();
    }
    const record: ZapNoteBackupRecord = payload as ZapNoteBackupRecord;
    return ZapNoteBackupService.safeNumber(record.createdAt, Date.now());
  }

  private static extractPhotoAssets(payload: object | object[]): ZapNoteBackupPhotoAsset[] {
    if (Array.isArray(payload)) {
      return [];
    }
    const record: ZapNoteBackupRecord = payload as ZapNoteBackupRecord;
    const sourcePhotos: ZapNoteBackupPhotoAsset[] | undefined = Array.isArray(record.photos) ? record.photos :
      record.data !== undefined && Array.isArray(record.data.photos) ? record.data.photos : undefined;
    if (sourcePhotos === undefined) {
      return [];
    }
    const result: ZapNoteBackupPhotoAsset[] = [];
    sourcePhotos.forEach((item: ZapNoteBackupPhotoAsset) => {
      const sourceUri: string = ZapNoteBackupService.safeString(item.sourceUri);
      const fileExt: string = ZapNoteBackupService.safePhotoExtension(ZapNoteBackupService.safeString(item.fileExt, '.jpg'));
      const dataBase64: string = ZapNoteBackupService.safeString(item.dataBase64);
      if (sourceUri.length > 0 && dataBase64.length > 0) {
        result.push({
          sourceUri: sourceUri,
          fileExt: fileExt,
          dataBase64: dataBase64
        });
      }
    });
    return result;
  }

  private static normalizeScope(value: SyncDataScope): SyncDataScope {
    if (value === 'diaries' || value === 'settings') {
      return value;
    }
    return 'all';
  }

  private static safeString(value: string | number | boolean | null | undefined, fallback: string = ''): string {
    if (typeof value === 'string') {
      return value;
    }
    if (value === undefined || value === null) {
      return fallback;
    }
    return String(value);
  }

  private static safeNumber(value: string | number | null | undefined, fallback: number): number {
    if (typeof value === 'number' && !Number.isNaN(value)) {
      return value;
    }
    if (typeof value === 'string') {
      const parsed: number = Number.parseFloat(value);
      return Number.isNaN(parsed) ? fallback : parsed;
    }
    return fallback;
  }

  private static safeBoolean(value: string | number | boolean | null | undefined, fallback: boolean): boolean {
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'number') {
      return value !== 0;
    }
    if (typeof value === 'string') {
      return value === 'true' || value === '1';
    }
    return fallback;
  }

  private static pad2(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
  }

  private static async collectPhotoAssets(diaries: DiaryEntry[]): Promise<ZapNoteBackupPhotoCollectionResult> {
    const result: ZapNoteBackupPhotoAsset[] = [];
    const seen: string[] = [];
    let embeddedPhotoBytes: number = 0;
    let skippedPhotoCount: number = 0;
    for (let entryIndex = 0; entryIndex < diaries.length; entryIndex++) {
      const photoUris: string[] = ZapNoteBackupService.entryPhotoUris(diaries[entryIndex]);
      for (let uriIndex = 0; uriIndex < photoUris.length; uriIndex++) {
        const photoUri: string = photoUris[uriIndex];
        if (seen.indexOf(photoUri) >= 0) {
          continue;
        }
        seen.push(photoUri);
        const asset: ZapNoteBackupPhotoAsset | null = await ZapNoteBackupService.readPhotoAsset(photoUri);
        if (asset === null) {
          skippedPhotoCount++;
          continue;
        }
        const photoBytes: number = Math.floor(asset.dataBase64.length * 3 / 4);
        if (photoBytes > ZapNoteBackupService.MAX_EMBEDDED_PHOTO_BYTES ||
          embeddedPhotoBytes + photoBytes > ZapNoteBackupService.MAX_TOTAL_EMBEDDED_PHOTO_BYTES) {
          skippedPhotoCount++;
          continue;
        }
        result.push(asset);
        embeddedPhotoBytes += photoBytes;
      }
    }
    return {
      assets: result,
      skippedPhotoCount: skippedPhotoCount
    };
  }

  private static countUniquePhotoUris(diaries: DiaryEntry[]): number {
    const seen: string[] = [];
    diaries.forEach((entry: DiaryEntry) => {
      ZapNoteBackupService.entryPhotoUris(entry).forEach((photoUri: string) => {
        if (seen.indexOf(photoUri) < 0) {
          seen.push(photoUri);
        }
      });
    });
    return seen.length;
  }

  private static entryPhotoUris(entry: DiaryEntry): string[] {
    const result: string[] = [];
    if (Array.isArray(entry.photoUris)) {
      entry.photoUris.forEach((item: string) => {
        const value: string = typeof item === 'string' ? item.trim() : '';
        if (value.length > 0 && result.indexOf(value) < 0) {
          result.push(value);
        }
      });
    }
    const photoUri: string = typeof entry.photoUri === 'string' ? entry.photoUri.trim() : '';
    if (photoUri.length > 0 && result.indexOf(photoUri) < 0) {
      result.push(photoUri);
    }
    return result;
  }

  private static async readPhotoAsset(photoUri: string): Promise<ZapNoteBackupPhotoAsset | null> {
    const sourceUri: string = photoUri.trim();
    if (sourceUri.length === 0) {
      return null;
    }
    const directAsset: ZapNoteBackupPhotoAsset | null = ZapNoteBackupService.readPhotoAssetFromFile(sourceUri);
    if (directAsset !== null) {
      return directAsset;
    }
    return await ZapNoteBackupService.readPhotoAssetFromImageSource(sourceUri);
  }

  private static readPhotoAssetFromFile(photoUri: string): ZapNoteBackupPhotoAsset | null {
    let file: fileIo.File | null = null;
    try {
      const sourceUri: string = photoUri.trim();
      if (sourceUri.length === 0) {
        return null;
      }
      file = ZapNoteBackupService.openPhotoReadOnly(sourceUri);
      if (file === null) {
        return null;
      }
      const stat = fileIo.statSync(file.fd);
      if (!stat || stat.size <= 0) {
        return null;
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
      if (data.byteLength <= 0) {
        return null;
      }
      return {
        sourceUri: photoUri,
        fileExt: ZapNoteBackupService.detectPhotoExtension(photoUri, data),
        dataBase64: ZapNoteBackupService.base64EncodeBytes(data)
      };
    } catch (error) {
      console.error('ZapNoteBackupService readPhotoAsset failed: ' + JSON.stringify(error));
      return null;
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          console.error('ZapNoteBackupService close photo fd failed: ' + JSON.stringify(error));
        }
      }
    }
  }

  private static async readPhotoAssetFromImageSource(photoUri: string): Promise<ZapNoteBackupPhotoAsset | null> {
    let source: image.ImageSource | null = null;
    let pixelMap: image.PixelMap | null = null;
    try {
      source = image.createImageSource(photoUri);
      pixelMap = await source.createPixelMap();
      const packer: image.ImagePacker = image.createImagePacker();
      const buffer: ArrayBuffer = await packer.packToData(pixelMap, {
        format: 'image/jpeg',
        quality: 95
      });
      if (buffer.byteLength <= 0) {
        return null;
      }
      return {
        sourceUri: photoUri,
        fileExt: '.jpg',
        dataBase64: ZapNoteBackupService.base64EncodeBytes(buffer)
      };
    } catch (error) {
      console.error('ZapNoteBackupService decode photo uri failed: ' + JSON.stringify(error));
      return null;
    } finally {
      if (pixelMap !== null) {
        try {
          await pixelMap.release();
        } catch (error) {
          console.error('ZapNoteBackupService release decoded photo failed: ' + JSON.stringify(error));
        }
      }
      if (source !== null) {
        try {
          await source.release();
        } catch (error) {
          console.error('ZapNoteBackupService release image source failed: ' + JSON.stringify(error));
        }
      }
    }
  }

  private static openPhotoReadOnly(photoUri: string): fileIo.File | null {
    try {
      return fileIo.openSync(photoUri, fileIo.OpenMode.READ_ONLY);
    } catch (error) {
      if (photoUri.startsWith('file://')) {
        try {
          return fileIo.openSync(photoUri.substring(7), fileIo.OpenMode.READ_ONLY);
        } catch (fileError) {
          console.error('ZapNoteBackupService open file uri failed: ' + JSON.stringify(fileError));
        }
      }
      console.error('ZapNoteBackupService open photo read failed: ' + JSON.stringify(error));
      return null;
    }
  }

  private static photoFileSize(photoUri: string): number {
    let file: fileIo.File | null = null;
    try {
      file = ZapNoteBackupService.openPhotoReadOnly(photoUri);
      if (file === null) {
        return 0;
      }
      const stat = fileIo.statSync(file.fd);
      return stat !== undefined && stat !== null && stat.size > 0 ? stat.size : 0;
    } catch (error) {
      return 0;
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          console.error('ZapNoteBackupService close photo size fd failed: ' + JSON.stringify(error));
        }
      }
    }
  }

  private static restorePhotoAssets(context: common.Context, photos: ZapNoteBackupPhotoAsset[],
    createdAt: number): Map<string, string> {
    const result: Map<string, string> = new Map<string, string>();
    if (photos.length === 0) {
      return result;
    }
    const rootPath: string = context.filesDir + '/zapnote-backup-photos';
    try {
      if (!fileIo.accessSync(rootPath)) {
        fileIo.mkdirSync(rootPath);
      }
    } catch (error) {
      console.error('ZapNoteBackupService prepare photo restore folder failed: ' + JSON.stringify(error));
    }
    photos.forEach((photo: ZapNoteBackupPhotoAsset, index: number) => {
      if (photo.sourceUri.length === 0 || result.has(photo.sourceUri)) {
        return;
      }
      let file: fileIo.File | null = null;
      try {
        const bytes: ArrayBuffer = ZapNoteBackupService.base64DecodeToArrayBuffer(photo.dataBase64);
        if (bytes.byteLength <= 0) {
          return;
        }
        const targetPath: string = rootPath + '/restored-' + createdAt.toString() + '-' + index.toString() +
          ZapNoteBackupService.safePhotoExtension(photo.fileExt);
        file = fileIo.openSync(targetPath,
          fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.SYNC);
        fileIo.writeSync(file.fd, bytes);
        result.set(photo.sourceUri, ZapNoteBackupService.displayFileUri(targetPath));
      } catch (error) {
        console.error('ZapNoteBackupService restorePhotoAssets failed: ' + JSON.stringify(error));
      } finally {
        if (file !== null) {
          try {
            fileIo.closeSync(file);
          } catch (error) {
            console.error('ZapNoteBackupService close restored photo failed: ' + JSON.stringify(error));
          }
        }
      }
    });
    return result;
  }

  private static readableFileUri(photoUri: string): string {
    const value: string = photoUri.trim();
    if (value.startsWith('file://')) {
      return value.substring(7);
    }
    return value;
  }

  private static displayFileUri(path: string): string {
    const value: string = path.trim();
    if (value.startsWith('file://') || value.indexOf('://') >= 0) {
      return value;
    }
    try {
      return fileUri.getUriFromPath(value);
    } catch (error) {
      console.error('ZapNoteBackupService get file uri failed: ' + JSON.stringify(error));
      return 'file://' + value;
    }
  }

  private static safePhotoExtension(value: string): string {
    const ext: string = value.trim().toLowerCase();
    if (ext === '.jpg' || ext === '.jpeg' || ext === '.png' || ext === '.gif' || ext === '.webp' || ext === '.bmp') {
      return ext;
    }
    return '.jpg';
  }

  private static detectPhotoExtension(photoUri: string, data: ArrayBuffer): string {
    const bytes: Uint8Array = new Uint8Array(data);
    if (bytes.length >= 3 && bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF) {
      return '.jpg';
    }
    if (bytes.length >= 8 && bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4E &&
      bytes[3] === 0x47 && bytes[4] === 0x0D && bytes[5] === 0x0A && bytes[6] === 0x1A && bytes[7] === 0x0A) {
      return '.png';
    }
    if (bytes.length >= 4 && bytes[0] === 0x47 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x38) {
      return '.gif';
    }
    if (bytes.length >= 12 && bytes[0] === 0x52 && bytes[1] === 0x49 && bytes[2] === 0x46 &&
      bytes[3] === 0x46 && bytes[8] === 0x57 && bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50) {
      return '.webp';
    }
    const dotIndex: number = photoUri.lastIndexOf('.');
    if (dotIndex >= 0) {
      return ZapNoteBackupService.safePhotoExtension(photoUri.substring(dotIndex).split('?')[0].split('#')[0]);
    }
    return '.jpg';
  }

  private static base64EncodeBytes(buffer: ArrayBuffer): string {
    const alphabet: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const bytes: Uint8Array = new Uint8Array(buffer);
    let result: string = '';
    for (let index = 0; index < bytes.length; index += 3) {
      const first: number = bytes[index];
      const second: number = index + 1 < bytes.length ? bytes[index + 1] : 0;
      const third: number = index + 2 < bytes.length ? bytes[index + 2] : 0;
      const triple: number = (first << 16) | (second << 8) | third;
      result += alphabet[(triple >> 18) & 63];
      result += alphabet[(triple >> 12) & 63];
      result += index + 1 < bytes.length ? alphabet[(triple >> 6) & 63] : '=';
      result += index + 2 < bytes.length ? alphabet[triple & 63] : '=';
    }
    return result;
  }

  private static base64DecodeToArrayBuffer(value: string): ArrayBuffer {
    const alphabet: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const lookup: number[] = [];
    for (let index = 0; index < alphabet.length; index++) {
      lookup[alphabet.charCodeAt(index)] = index;
    }
    const normalized: string = value.replace(/\s+/g, '');
    const bytes: number[] = [];
    let buffer: number = 0;
    let bits: number = 0;
    for (let index = 0; index < normalized.length; index++) {
      const code: number = normalized.charCodeAt(index);
      if (code === 61) {
        break;
      }
      const decoded: number = lookup[code];
      if (decoded === undefined || decoded < 0) {
        continue;
      }
      buffer = (buffer << 6) | decoded;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        bytes.push((buffer >> bits) & 0xFF);
      }
    }
    return new Uint8Array(bytes).buffer;
  }

  private static resolveRestoredPhotoUri(photoUri: string, restoredPhotoUris: Map<string, string>): string {
    return restoredPhotoUris.has(photoUri) ? restoredPhotoUris.get(photoUri) as string : photoUri;
  }

  private static cloneDiaries(diaries: DiaryEntry[], restoredPhotoUris: Map<string, string> = new Map<string, string>()): DiaryEntry[] {
    const result: DiaryEntry[] = [];
    diaries.forEach((entry: DiaryEntry) => {
      const body: string = ZapNoteBackupService.safeString(entry.body);
      const legacyDateMs: number = ZapNoteBackupService.safeNumber(entry.dateMs, Date.now());
      let photoUri: string = ZapNoteBackupService.safeString(entry.photoUri);
      let photoUris: string[] = Array.isArray(entry.photoUris) ?
        ZapNoteBackupService.cloneStringList(entry.photoUris) : [];
      if (photoUris.length === 0 && photoUri.length > 0) {
        photoUris = [photoUri];
      }
      photoUris = photoUris.map((item: string) => ZapNoteBackupService.resolveRestoredPhotoUri(item, restoredPhotoUris));
      photoUri = photoUri.length > 0 ? ZapNoteBackupService.resolveRestoredPhotoUri(photoUri, restoredPhotoUris) :
        photoUris.length > 0 ? photoUris[0] : '';
      result.push({
        id: ZapNoteBackupService.safeString(entry.id, 'diary-' + Date.now().toString()),
        title: ZapNoteBackupService.safeString(entry.title),
        body: body,
        folderName: ZapNoteBackupService.safeString(entry.folderName),
        dateText: ZapNoteBackupService.safeString(entry.dateText),
        dateMs: legacyDateMs,
        createdAt: ZapNoteBackupService.safeNumber(entry.createdAt, legacyDateMs),
        updatedAt: ZapNoteBackupService.safeNumber(entry.updatedAt, legacyDateMs),
        mood: ZapNoteBackupService.safeString(entry.mood),
        weather: ZapNoteBackupService.safeString(entry.weather),
        isToday: ZapNoteBackupService.safeBoolean(entry.isToday, false),
        isThisWeek: ZapNoteBackupService.safeBoolean(entry.isThisWeek, false),
        isFavorite: ZapNoteBackupService.safeBoolean(entry.isFavorite, false),
        isPrivate: ZapNoteBackupService.safeBoolean(entry.isPrivate, false),
        wordCount: ZapNoteBackupService.safeNumber(entry.wordCount, body.length),
        hasPhoto: ZapNoteBackupService.safeBoolean(entry.hasPhoto, false) || photoUri.length > 0 || photoUris.length > 0,
        photoInBody: ZapNoteBackupService.safeBoolean(entry.photoInBody, false),
        photoUri: photoUri,
        photoUris: photoUris,
        thumbnailPhotoIndex: Math.max(0, Math.min(Math.floor(
          ZapNoteBackupService.safeNumber(entry.thumbnailPhotoIndex, 0)), Math.max(photoUris.length - 1, 0))),
        thumbnailScale: Math.max(1, Math.min(ZapNoteBackupService.safeNumber(entry.thumbnailScale, 1), 4)),
        thumbnailOffsetX: ZapNoteBackupService.safeNumber(entry.thumbnailOffsetX, 0),
        thumbnailOffsetY: ZapNoteBackupService.safeNumber(entry.thumbnailOffsetY, 0),
        thumbnailPhotoAspect: Math.max(ZapNoteBackupService.safeNumber(entry.thumbnailPhotoAspect, 1), 0.01),
        photoX: ZapNoteBackupService.safeNumber(entry.photoX, 0),
        photoY: ZapNoteBackupService.safeNumber(entry.photoY, 0),
        photoWidth: ZapNoteBackupService.safeNumber(entry.photoWidth, 156),
        photoHeight: ZapNoteBackupService.safeNumber(entry.photoHeight, 118),
        photoRotation: ZapNoteBackupService.safeNumber(entry.photoRotation, 0),
        photoStyle: ZapNoteBackupService.safeString(entry.photoStyle, 'original')
      });
    });
    return result;
  }

  private static cloneSettings(settings: ZapNoteBackupSettings): ZapNoteBackupSettings {
    const result: ZapNoteBackupSettings = {};
    if (typeof settings.themeMode === 'string') {
      result.themeMode = settings.themeMode;
    }
    if (typeof settings.lightingMode === 'string') {
      result.lightingMode = settings.lightingMode;
    }
    if (typeof settings.selectedAccentColor === 'string') {
      result.selectedAccentColor = settings.selectedAccentColor;
    }
    if (typeof settings.gripModeEnabled === 'boolean') {
      result.gripModeEnabled = settings.gripModeEnabled;
    }
    if (typeof settings.privacyEnabled === 'boolean') {
      result.privacyEnabled = settings.privacyEnabled;
    }
    if (typeof settings.autoFillEnabled === 'boolean') {
      result.autoFillEnabled = settings.autoFillEnabled;
    }
    if (typeof settings.vibrateEnabled === 'boolean') {
      result.vibrateEnabled = settings.vibrateEnabled;
    }
    if (typeof settings.doubleTouchEnabled === 'boolean') {
      result.doubleTouchEnabled = settings.doubleTouchEnabled;
    }
    if (typeof settings.doubleTouchAction === 'string') {
      result.doubleTouchAction = settings.doubleTouchAction;
    }
    if (typeof settings.sharedPhotoSaveMode === 'string') {
      result.sharedPhotoSaveMode = settings.sharedPhotoSaveMode;
    }
    if (typeof settings.sharedPhotoAutoRecognizeEnabled === 'boolean') {
      result.sharedPhotoAutoRecognizeEnabled = settings.sharedPhotoAutoRecognizeEnabled;
    }
    if (typeof settings.sharedPhotoSaveToAlbumEnabled === 'boolean') {
      result.sharedPhotoSaveToAlbumEnabled = settings.sharedPhotoSaveToAlbumEnabled;
    }
    if (typeof settings.enhancedLinkRecognitionEnabled === 'boolean') {
      result.enhancedLinkRecognitionEnabled = settings.enhancedLinkRecognitionEnabled;
    }
    if (typeof settings.engine === 'string') {
      result.engine = settings.engine;
    }
    if (typeof settings.aiVisualProvider === 'string') {
      result.aiVisualProvider = settings.aiVisualProvider;
    }
    if (typeof settings.aiVisualProviderName === 'string') {
      result.aiVisualProviderName = settings.aiVisualProviderName;
    }
    if (typeof settings.aiVisualBaseUrl === 'string') {
      result.aiVisualBaseUrl = settings.aiVisualBaseUrl;
    }
    if (typeof settings.aiVisualModel === 'string') {
      result.aiVisualModel = settings.aiVisualModel;
    }
    if (typeof settings.aiVisualOutputContent === 'string') {
      result.aiVisualOutputContent = settings.aiVisualOutputContent;
    }
    if (Array.isArray(settings.aiVisualConfigs)) {
      const configs: AiVisualEngineBackupConfig[] = [];
      for (let index: number = 0; index < settings.aiVisualConfigs.length; index++) {
        const config: AiVisualEngineBackupConfig = settings.aiVisualConfigs[index];
        configs.push({
          id: ZapNoteBackupService.safeString(config.id),
          providerName: ZapNoteBackupService.safeString(config.providerName),
          provider: ZapNoteBackupService.safeString(config.provider, 'openai-compatible'),
          baseUrl: ZapNoteBackupService.safeString(config.baseUrl),
          model: ZapNoteBackupService.safeString(config.model),
          outputContent: ZapNoteBackupService.safeString(config.outputContent)
        });
      }
      result.aiVisualConfigs = configs;
    }
    if (typeof settings.selectedPhotoStyle === 'string') {
      result.selectedPhotoStyle = settings.selectedPhotoStyle;
    }
    if (typeof settings.syncInterval === 'string') {
      result.syncInterval = settings.syncInterval;
    }
    if (typeof settings.syncOnChange === 'boolean') {
      result.syncOnChange = settings.syncOnChange;
    }
    if (typeof settings.syncMode === 'number') {
      result.syncMode = settings.syncMode === 1 ? 1 : 0;
    }
    if (Array.isArray(settings.syncTimes)) {
      result.syncTimes = ZapNoteBackupService.cloneStringList(settings.syncTimes);
    }
    if (typeof settings.historyLimit === 'number') {
      result.historyLimit = settings.historyLimit === 30 || settings.historyLimit === 100 ? settings.historyLimit : 10;
    }
    if (typeof settings.syncRestoreStrategy === 'string') {
      result.syncRestoreStrategy = settings.syncRestoreStrategy === 'overwrite' ? 'overwrite' : 'merge';
    }
    if (settings.syncDataScope === 'diaries' || settings.syncDataScope === 'settings' || settings.syncDataScope === 'all') {
      result.syncDataScope = settings.syncDataScope;
    }
    if (typeof settings.webdavUrl === 'string') {
      result.webdavUrl = settings.webdavUrl;
    }
    if (typeof settings.webdavUser === 'string') {
      result.webdavUser = settings.webdavUser;
    }
    if (typeof settings.webdavPass === 'string') {
      result.webdavPass = settings.webdavPass;
    }
    if (typeof settings.webdavRemotePath === 'string') {
      result.webdavRemotePath = settings.webdavRemotePath;
    }
    if (Array.isArray(settings.matchRuleItems)) {
      result.matchRuleItems = ZapNoteBackupService.cloneMatchRuleItems(settings.matchRuleItems);
    }
    return result;
  }

  private static cloneMatchRuleItems(items: MatchRuleTemplateItem[]): MatchRuleTemplateItem[] {
    const result: MatchRuleTemplateItem[] = [];
    items.forEach((item: MatchRuleTemplateItem) => {
      result.push({
        id: ZapNoteBackupService.safeString(item.id),
        kind: item.kind === 'ai-output' ? 'ai-output' : 'keyword',
        aiConfigId: ZapNoteBackupService.safeString(item.aiConfigId),
        scopes: Array.isArray(item.scopes) ? ZapNoteBackupService.cloneStringList(item.scopes) : [],
        keyword: ZapNoteBackupService.safeString(item.keyword),
        template: ZapNoteBackupService.safeString(item.template),
        enabled: ZapNoteBackupService.safeBoolean(item.enabled, true),
        action: item.action === 'exclude' || item.action === 'mask' ? item.action : 'extract',
        range: item.range === 'match' || item.range === 'block' ? item.range : 'line',
        matchMode: item.matchMode === 'regex' ? 'regex' : 'contains',
        linkType: item.linkType
      });
    });
    return result;
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
}
