import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

export class PhotoAlbumSaveService {
  static async savePhoto(context: common.UIAbilityContext, sourceUri: string): Promise<boolean> {
    const normalizedUri: string = sourceUri.trim();
    if (normalizedUri.length === 0) {
      return false;
    }
    let sourceFile: fileIo.File | null = null;
    let destinationFile: fileIo.File | null = null;
    try {
      const helper: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      const configs: photoAccessHelper.PhotoCreationConfig[] = [{
        title: '识录笔记-' + Date.now().toString(),
        fileNameExtension: PhotoAlbumSaveService.fileNameExtension(normalizedUri),
        photoType: photoAccessHelper.PhotoType.IMAGE,
        subtype: photoAccessHelper.PhotoSubtype.DEFAULT
      }];
      const destinationUris: string[] = await helper.showAssetsCreationDialog([normalizedUri], configs);
      if (destinationUris.length === 0 || destinationUris[0].trim().length === 0) {
        return false;
      }
      sourceFile = await fileIo.open(normalizedUri, fileIo.OpenMode.READ_ONLY);
      destinationFile = await fileIo.open(destinationUris[0], fileIo.OpenMode.WRITE_ONLY);
      await fileIo.copyFile(sourceFile.fd, destinationFile.fd);
      return true;
    } catch (error) {
      console.error('PhotoAlbumSaveService save photo failed: ' + JSON.stringify(error));
      return false;
    } finally {
      PhotoAlbumSaveService.closeFile(sourceFile);
      PhotoAlbumSaveService.closeFile(destinationFile);
    }
  }

  private static fileNameExtension(sourceUri: string): string {
    const path: string = sourceUri.split('?')[0].split('#')[0];
    const dotIndex: number = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex >= path.length - 1) {
      return 'jpg';
    }
    const extension: string = path.substring(dotIndex + 1).toLowerCase();
    if (extension === 'jpg' || extension === 'jpeg' || extension === 'png' || extension === 'gif' ||
      extension === 'webp' || extension === 'bmp') {
      return extension;
    }
    return 'jpg';
  }

  private static closeFile(file: fileIo.File | null): void {
    if (file === null) {
      return;
    }
    try {
      fileIo.closeSync(file);
    } catch (error) {
      console.error('PhotoAlbumSaveService close file failed: ' + JSON.stringify(error));
    }
  }
}
