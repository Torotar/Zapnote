import { textRecognition } from '@kit.CoreVisionKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

export interface OcrTextRecognitionResult {
  text: string;
  photoUri: string;
  blocks: OcrTextBlockResult[];
}

export interface OcrTextPointResult {
  x: number;
  y: number;
}

export interface OcrTextWordResult {
  text: string;
  cornerPoints: OcrTextPointResult[];
}

export interface OcrTextLineResult {
  text: string;
  words: OcrTextWordResult[];
  cornerPoints: OcrTextPointResult[];
}

export interface OcrTextBlockResult {
  text: string;
  lines: OcrTextLineResult[];
}

interface MagnetSuffixResult {
  value: string;
  end: number;
}

interface OcrBusinessError {
  code?: number;
  message?: string;
}

export class OcrTextRecognitionError extends Error {
  readonly stage: string;
  readonly code: number;
  readonly detail: string;

  constructor(stage: string, message: string, code: number = -1, detail: string = '') {
    super(message);
    this.stage = stage;
    this.code = code;
    this.detail = detail;
  }
}

export class OcrTextRecognitionService {
  private static initialized: boolean = false;
  private static readonly MAGNET_PREFIX: string = 'magnet:?xt=urn:btih:';

  private static makeError(stage: string, message: string, error?: Object): OcrTextRecognitionError {
    if (error === undefined) {
      return new OcrTextRecognitionError(stage, message);
    }
    const businessError = error as OcrBusinessError;
    const code: number = typeof businessError.code === 'number' ? businessError.code : -1;
    const detail: string = typeof businessError.message === 'string' ? businessError.message : JSON.stringify(error);
    return new OcrTextRecognitionError(stage, message, code, detail);
  }

  private static async ensureInitialized(): Promise<void> {
    if (!canIUse('SystemCapability.AI.OCR.TextRecognition')) {
      throw new OcrTextRecognitionError('capability', 'Current device does not support text recognition');
    }
    if (OcrTextRecognitionService.initialized) {
      return;
    }
    let ready: boolean = false;
    try {
      ready = await textRecognition.init();
    } catch (error) {
      console.error('OcrTextRecognitionService init failed: ' + JSON.stringify(error));
      throw OcrTextRecognitionService.makeError('init', 'Text recognition service init failed', error);
    }
    if (!ready) {
      throw new OcrTextRecognitionError('init', 'Text recognition service init failed');
    }
    OcrTextRecognitionService.initialized = true;
  }

  static async pickPhotoUri(): Promise<string | null> {
    const picker = new photoAccessHelper.PhotoViewPicker();
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    options.isPhotoTakingSupported = true;
    options.isSearchSupported = true;

    let result: photoAccessHelper.PhotoSelectResult;
    try {
      result = await picker.select(options);
    } catch (error) {
      console.error('OcrTextRecognitionService pick photo failed: ' + JSON.stringify(error));
      throw OcrTextRecognitionService.makeError('picker', 'Photo selection failed', error);
    }
    if (result.photoUris.length === 0) {
      return null;
    }
    return result.photoUris[0];
  }

  private static clonePoints(points: textRecognition.PixelPoint[]): OcrTextPointResult[] {
    const result: OcrTextPointResult[] = [];
    points.forEach((point: textRecognition.PixelPoint): void => {
      result.push({
        x: point.x,
        y: point.y
      });
    });
    return result;
  }

  private static cloneWords(words: textRecognition.TextWord[]): OcrTextWordResult[] {
    const result: OcrTextWordResult[] = [];
    words.forEach((word: textRecognition.TextWord): void => {
      result.push({
        text: word.value,
        cornerPoints: OcrTextRecognitionService.clonePoints(word.cornerPoints)
      });
    });
    return result;
  }

  private static cloneLines(lines: textRecognition.TextLine[]): OcrTextLineResult[] {
    const result: OcrTextLineResult[] = [];
    lines.forEach((line: textRecognition.TextLine): void => {
      result.push({
        text: line.value,
        words: OcrTextRecognitionService.cloneWords(line.words),
        cornerPoints: OcrTextRecognitionService.clonePoints(line.cornerPoints)
      });
    });
    return result;
  }

  private static cloneBlocks(blocks: textRecognition.TextBlock[]): OcrTextBlockResult[] {
    const result: OcrTextBlockResult[] = [];
    blocks.forEach((block: textRecognition.TextBlock): void => {
      result.push({
        text: block.value,
        lines: OcrTextRecognitionService.cloneLines(block.lines)
      });
    });
    return result;
  }

  private static textFromBlocks(blocks: OcrTextBlockResult[]): string {
    const lines: string[] = [];
    blocks.forEach((block: OcrTextBlockResult): void => {
      if (block.lines.length === 0) {
        const blockText: string = block.text.trim();
        if (blockText.length > 0) {
          lines.push(blockText);
        }
        return;
      }
      block.lines.forEach((line: OcrTextLineResult): void => {
        const lineText: string = line.text.trim();
        if (lineText.length > 0) {
          lines.push(lineText);
        }
      });
    });
    return lines.join('\n').trim();
  }

  static extractMagnetLinks(text: string): string[] {
    const links: string[] = [];
    const prefixExpression: RegExp =
      /m\s*a\s*g\s*n\s*e\s*t\s*[:：]\s*[?？]\s*x\s*t\s*[=＝]\s*u\s*r\s*n\s*[:：]\s*b\s*t\s*i\s*h\s*[:：]/ig;
    let searchIndex: number = 0;
    while (searchIndex < text.length) {
      prefixExpression.lastIndex = searchIndex;
      const prefixMatch: RegExpExecArray | null = prefixExpression.exec(text);
      if (prefixMatch === null) {
        break;
      }
      const hashCharacters: string[] = [];
      const sourceIndexes: number[] = [];
      let sourceIndex: number = prefixExpression.lastIndex;
      while (sourceIndex < text.length && hashCharacters.length < 40) {
        const character: string = text.charAt(sourceIndex);
        if (/\s/.test(character)) {
          sourceIndex++;
          continue;
        }
        if (!/[A-Z0-9]/i.test(character)) {
          break;
        }
        hashCharacters.push(character.toUpperCase());
        sourceIndexes.push(sourceIndex);
        sourceIndex++;
      }
      let hashCandidate: string = hashCharacters.join('');
      const correctedHexCandidate: string = hashCandidate
        .replace(/O/g, '0')
        .replace(/[IL]/g, '1')
        .replace(/S/g, '5')
        .replace(/G/g, '6');
      let hashLength: number = 0;
      if (hashCandidate.length >= 40 && /^[A-F0-9]{40}$/.test(hashCandidate.substring(0, 40))) {
        hashLength = 40;
      } else if (correctedHexCandidate.length >= 40 &&
        /^[A-F0-9]{40}$/.test(correctedHexCandidate.substring(0, 40))) {
        hashCandidate = correctedHexCandidate;
        hashLength = 40;
      } else if (hashCandidate.length >= 32 && /^[A-Z2-7]{32}$/.test(hashCandidate.substring(0, 32))) {
        hashLength = 32;
      }
      if (hashLength > 0) {
        const hash: string = hashCandidate.substring(0, hashLength);
        const hashEndIndex: number = sourceIndexes[hashLength - 1] + 1;
        const suffixResult: MagnetSuffixResult =
          OcrTextRecognitionService.collectMagnetSuffix(text, hashEndIndex);
        const link: string = OcrTextRecognitionService.MAGNET_PREFIX + hash + suffixResult.value;
        if (links.indexOf(link) < 0) {
          links.push(link);
        }
        searchIndex = suffixResult.end > hashEndIndex ? suffixResult.end : hashEndIndex;
        continue;
      }
      searchIndex = prefixExpression.lastIndex;
    }
    return links;
  }

  private static collectMagnetSuffix(text: string, start: number): MagnetSuffixResult {
    let index: number = start;
    while (index < text.length && /\s/.test(text.charAt(index))) {
      index++;
    }
    if (index >= text.length || text.charAt(index) !== '&') {
      return { value: '', end: start };
    }
    let value: string = '';
    while (index < text.length) {
      const character: string = text.charAt(index);
      if (/\s/.test(character)) {
        let nextIndex: number = index;
        while (nextIndex < text.length && /\s/.test(text.charAt(nextIndex))) {
          nextIndex++;
        }
        if (nextIndex >= text.length) {
          break;
        }
        const nextCharacter: string = text.charAt(nextIndex);
        const previousCharacter: string = value.length > 0 ? value.charAt(value.length - 1) : '';
        const continuesQuery: boolean = nextCharacter === '&' || previousCharacter === '=' ||
          (/[A-Za-z0-9]/.test(previousCharacter) && /[0-9]/.test(nextCharacter));
        if (!continuesQuery) {
          break;
        }
        index = nextIndex;
        continue;
      }
      if (!/[A-Za-z0-9%._~:/?=&+\-]/.test(character)) {
        break;
      }
      value += character;
      index++;
    }
    return { value: value, end: index };
  }

  static extractMagnetLink(text: string): string {
    const links: string[] = OcrTextRecognitionService.extractMagnetLinks(text);
    return links.length > 0 ? links[0] : '';
  }

  private static magnetQualityScore(text: string): number {
    const links: string[] = OcrTextRecognitionService.extractMagnetLinks(text);
    let score: number = links.length * 100000;
    links.forEach((link: string): void => {
      // Prefer the OCR source that preserves more of the magnet query, such
      // as &dn=... and &xl=..., when both sources find the same hash count.
      score += link.length;
    });
    return score;
  }

  private static completeRecognitionText(value: string, blocks: OcrTextBlockResult[]): string {
    const recognizedText: string = value.trim();
    const blockText: string = OcrTextRecognitionService.textFromBlocks(blocks);
    if (recognizedText.length === 0) {
      return blockText;
    }
    const recognizedScore: number = OcrTextRecognitionService.magnetQualityScore(recognizedText);
    const blockScore: number = OcrTextRecognitionService.magnetQualityScore(blockText);
    if (blockScore > recognizedScore) {
      return blockText;
    }
    return recognizedText;
  }

  private static async recognizePhotoUri(photoUri: string): Promise<OcrTextRecognitionResult> {
    let file: fileIo.File | null = null;
    let source: image.ImageSource;
    try {
      file = fileIo.openSync(photoUri, fileIo.OpenMode.READ_ONLY);
      source = image.createImageSource(file.fd);
    } catch (error) {
      console.error('OcrTextRecognitionService open photo fd failed: ' + JSON.stringify(error));
      try {
        source = image.createImageSource(photoUri);
      } catch (sourceError) {
        console.error('OcrTextRecognitionService create image source failed: ' + JSON.stringify(sourceError));
        throw OcrTextRecognitionService.makeError('decode', 'Image source create failed', sourceError);
      }
    }
    let pixelMap: image.PixelMap | null = null;
    try {
      pixelMap = await source.createPixelMap();
    } catch (error) {
      console.error('OcrTextRecognitionService create pixelMap failed: ' + JSON.stringify(error));
      throw OcrTextRecognitionService.makeError('decode', 'Image decode failed', error);
    }
    try {
      const result: textRecognition.TextRecognitionResult = await textRecognition.recognizeText({
        pixelMap: pixelMap
      }, {
        isDirectionDetectionSupported: true
      });
      const blocks: OcrTextBlockResult[] = OcrTextRecognitionService.cloneBlocks(result.blocks);
      return {
        text: OcrTextRecognitionService.completeRecognitionText(result.value, blocks),
        photoUri: photoUri,
        blocks: blocks
      };
    } catch (error) {
      console.error('OcrTextRecognitionService recognize text failed: ' + JSON.stringify(error));
      throw OcrTextRecognitionService.makeError('recognize', 'Text recognition failed', error);
    } finally {
      if (pixelMap !== null) {
        try {
          await pixelMap.release();
        } catch (error) {
          console.error('OcrTextRecognitionService release pixelMap failed: ' + JSON.stringify(error));
        }
      }
      try {
        await source.release();
      } catch (error) {
        console.error('OcrTextRecognitionService release image source failed: ' + JSON.stringify(error));
      }
      if (file !== null) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          console.error('OcrTextRecognitionService close photo fd failed: ' + JSON.stringify(error));
        }
      }
    }
  }

  static async pickAndRecognizeText(): Promise<OcrTextRecognitionResult | null> {
    const photoUri: string | null = await OcrTextRecognitionService.pickPhotoUri();
    if (photoUri === null) {
      return null;
    }
    return await OcrTextRecognitionService.recognizePhotoResult(photoUri);
  }

  static async recognizePhotoResult(photoUri: string): Promise<OcrTextRecognitionResult> {
    await OcrTextRecognitionService.ensureInitialized();
    return await OcrTextRecognitionService.recognizePhotoUri(photoUri);
  }

  static async recognizePixelMap(pixelMap: image.PixelMap): Promise<OcrTextRecognitionResult> {
    try {
      await OcrTextRecognitionService.ensureInitialized();
      const result: textRecognition.TextRecognitionResult = await textRecognition.recognizeText({
        pixelMap: pixelMap
      }, {
        isDirectionDetectionSupported: true
      });
      const blocks: OcrTextBlockResult[] = OcrTextRecognitionService.cloneBlocks(result.blocks);
      return {
        text: OcrTextRecognitionService.completeRecognitionText(result.value, blocks),
        photoUri: '',
        blocks: blocks
      };
    } catch (error) {
      console.error('OcrTextRecognitionService recognize pixelMap failed: ' + JSON.stringify(error));
      throw OcrTextRecognitionService.makeError('recognize', 'Text recognition failed', error);
    } finally {
      try {
        await pixelMap.release();
      } catch (error) {
        console.error('OcrTextRecognitionService release captured pixelMap failed: ' + JSON.stringify(error));
      }
    }
  }

  static async recognizePhotoText(photoUri: string): Promise<string> {
    const result: OcrTextRecognitionResult = await OcrTextRecognitionService.recognizePhotoResult(photoUri);
    return result.text;
  }

  static async release(): Promise<void> {
    if (!OcrTextRecognitionService.initialized) {
      return;
    }
    await textRecognition.release();
    OcrTextRecognitionService.initialized = false;
  }
}
