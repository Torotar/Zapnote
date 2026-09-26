import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';

export class ScreenCapturePhotoService {
  static async saveTemporaryPhoto(context: common.Context, pixelMap: image.PixelMap): Promise<string> {
    const targetPath: string = context.cacheDir + '/zapnote-capture-' + Date.now().toString() + '.jpg';
    let file: fileIo.File | null = null;
    const packer: image.ImagePacker = image.createImagePacker();
    try {
      const buffer: ArrayBuffer = await packer.packToData(pixelMap, {
        format: 'image/jpeg',
        quality: 95
      });
      file = fileIo.openSync(targetPath,
        fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.SYNC);
      fileIo.writeSync(file.fd, buffer);
      return targetPath;
    } catch (error) {
      console.error('ScreenCapturePhotoService save temporary photo failed: ' + JSON.stringify(error));
      return '';
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          console.error('ScreenCapturePhotoService close temporary photo failed: ' + JSON.stringify(error));
        }
      }
      try {
        await packer.release();
      } catch (error) {
        console.error('ScreenCapturePhotoService release image packer failed: ' + JSON.stringify(error));
      }
      try {
        await pixelMap.release();
      } catch (error) {
        console.error('ScreenCapturePhotoService release pixel map failed: ' + JSON.stringify(error));
      }
    }
  }
}
