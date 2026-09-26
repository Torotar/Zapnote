import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { DiaryEntry, RecycleBinEntry } from '../model/ZapNoteTypes';

export class ZapNoteDiaryStorageService {
  private static readonly FILE_NAME: string = 'zapnote-diaries.json';
  private static readonly RECYCLE_BIN_FILE_NAME: string = 'zapnote-recycle-bin.json';
  private static filePath: string = '';
  private static recycleBinFilePath: string = '';

  public static init(context: common.Context): void {
    ZapNoteDiaryStorageService.filePath = context.filesDir + '/' + ZapNoteDiaryStorageService.FILE_NAME;
    ZapNoteDiaryStorageService.recycleBinFilePath =
      context.filesDir + '/' + ZapNoteDiaryStorageService.RECYCLE_BIN_FILE_NAME;
  }

  public static loadDiaries(): DiaryEntry[] {
    if (ZapNoteDiaryStorageService.filePath.length === 0) {
      return [];
    }
    try {
      if (!fileIo.accessSync(ZapNoteDiaryStorageService.filePath)) {
        return [];
      }
      const raw: string = fileIo.readTextSync(ZapNoteDiaryStorageService.filePath);
      const parsed: DiaryEntry[] = JSON.parse(raw) as DiaryEntry[];
      return Array.isArray(parsed) ? ZapNoteDiaryStorageService.cloneDiaries(parsed) : [];
    } catch (error) {
      console.error('ZapNoteDiaryStorageService loadDiaries failed: ' + JSON.stringify(error));
      return [];
    }
  }

  public static saveDiaries(diaries: DiaryEntry[]): boolean {
    if (ZapNoteDiaryStorageService.filePath.length === 0) {
      return false;
    }
    let file: fileIo.File | null = null;
    try {
      file = fileIo.openSync(ZapNoteDiaryStorageService.filePath,
        fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.SYNC);
      fileIo.writeSync(file.fd, JSON.stringify(ZapNoteDiaryStorageService.cloneDiaries(diaries)));
      return true;
    } catch (error) {
      console.error('ZapNoteDiaryStorageService saveDiaries failed: ' + JSON.stringify(error));
      return false;
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          console.error('ZapNoteDiaryStorageService close file failed: ' + JSON.stringify(error));
        }
      }
    }
  }

  public static hasDiaryFile(): boolean {
    if (ZapNoteDiaryStorageService.filePath.length === 0) {
      return false;
    }
    try {
      return fileIo.accessSync(ZapNoteDiaryStorageService.filePath);
    } catch (error) {
      console.error('ZapNoteDiaryStorageService hasDiaryFile failed: ' + JSON.stringify(error));
      return false;
    }
  }

  public static clearAllLocalData(context: common.Context): boolean {
    ZapNoteDiaryStorageService.init(context);
    const diarySaved: boolean = ZapNoteDiaryStorageService.saveDiaries([]);
    const recycleBinSaved: boolean = ZapNoteDiaryStorageService.saveRecycleBin([]);
    const copiedPhotosCleared: boolean =
      ZapNoteDiaryStorageService.removeKnownAppDirectory(context.filesDir, 'zapnote-photos');
    const restoredPhotosCleared: boolean =
      ZapNoteDiaryStorageService.removeKnownAppDirectory(context.filesDir, 'zapnote-backup-photos');
    return diarySaved && recycleBinSaved && copiedPhotosCleared && restoredPhotosCleared;
  }

  public static loadRecycleBin(): RecycleBinEntry[] {
    if (ZapNoteDiaryStorageService.recycleBinFilePath.length === 0) {
      return [];
    }
    try {
      if (!fileIo.accessSync(ZapNoteDiaryStorageService.recycleBinFilePath)) {
        return [];
      }
      const raw: string = fileIo.readTextSync(ZapNoteDiaryStorageService.recycleBinFilePath);
      const parsed: RecycleBinEntry[] = JSON.parse(raw) as RecycleBinEntry[];
      return Array.isArray(parsed) ? ZapNoteDiaryStorageService.cloneRecycleBin(parsed) : [];
    } catch (error) {
      console.error('ZapNoteDiaryStorageService loadRecycleBin failed: ' + JSON.stringify(error));
      return [];
    }
  }

  public static saveRecycleBin(entries: RecycleBinEntry[]): boolean {
    if (ZapNoteDiaryStorageService.recycleBinFilePath.length === 0) {
      return false;
    }
    let file: fileIo.File | null = null;
    try {
      file = fileIo.openSync(ZapNoteDiaryStorageService.recycleBinFilePath,
        fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.SYNC);
      fileIo.writeSync(file.fd, JSON.stringify(ZapNoteDiaryStorageService.cloneRecycleBin(entries)));
      return true;
    } catch (error) {
      console.error('ZapNoteDiaryStorageService saveRecycleBin failed: ' + JSON.stringify(error));
      return false;
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          console.error('ZapNoteDiaryStorageService close recycle bin file failed: ' + JSON.stringify(error));
        }
      }
    }
  }

  private static removeKnownAppDirectory(filesDir: string, folderName: string): boolean {
    const rootPath: string = filesDir + '/' + folderName;
    try {
      if (!fileIo.accessSync(rootPath)) {
        return true;
      }
    } catch (error) {
      return true;
    }
    return ZapNoteDiaryStorageService.removePath(rootPath);
  }

  private static removePath(path: string): boolean {
    try {
      fileIo.unlinkSync(path);
      return true;
    } catch (unlinkError) {
      try {
        const children: string[] = fileIo.listFileSync(path);
        let success: boolean = true;
        children.forEach((name: string) => {
          if (!ZapNoteDiaryStorageService.removePath(path + '/' + name)) {
            success = false;
          }
        });
        fileIo.rmdirSync(path);
        return success;
      } catch (error) {
        console.error('ZapNoteDiaryStorageService removePath failed: ' + JSON.stringify(error));
        return false;
      }
    }
  }

  private static cloneRecycleBin(entries: RecycleBinEntry[]): RecycleBinEntry[] {
    const result: RecycleBinEntry[] = [];
    entries.forEach((entry: RecycleBinEntry) => {
      const diaries: DiaryEntry[] = ZapNoteDiaryStorageService.cloneDiaries([entry.diary]);
      if (diaries.length > 0) {
        result.push({
          diary: diaries[0],
          deletedAt: typeof entry.deletedAt === 'number' ? entry.deletedAt : Date.now()
        });
      }
    });
    return result;
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
}

