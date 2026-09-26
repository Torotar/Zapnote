import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

export class ZapNoteCredentialService {
  private static readonly WEBDAV_PASSWORD_ALIAS: string = 'zapnote.webdav.password';
  private static readonly AI_API_KEY_ALIAS: string = 'zapnote.ai.api-key';

  public static async getWebDavPassword(): Promise<string> {
    try {
      const query: asset.AssetMap = new Map();
      query.set(asset.Tag.ALIAS, ZapNoteCredentialService.toBytes(ZapNoteCredentialService.WEBDAV_PASSWORD_ALIAS));
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
      const result: Array<asset.AssetMap> = await asset.query(query);
      if (result.length === 0) {
        return '';
      }
      const secret: Uint8Array | undefined = result[0].get(asset.Tag.SECRET) as Uint8Array | undefined;
      return secret === undefined ? '' : ZapNoteCredentialService.fromBytes(secret);
    } catch (error) {
      console.error('ZapNoteCredentialService getWebDavPassword failed: ' + JSON.stringify(error));
      return '';
    }
  }

  public static async setWebDavPassword(value: string): Promise<boolean> {
    return await ZapNoteCredentialService.setSecret(ZapNoteCredentialService.WEBDAV_PASSWORD_ALIAS, value);
  }

  public static async getAiApiKey(configId: string = ''): Promise<string> {
    return await ZapNoteCredentialService.getSecret(ZapNoteCredentialService.aiApiKeyAlias(configId));
  }

  public static async setAiApiKey(value: string, configId: string = ''): Promise<boolean> {
    return await ZapNoteCredentialService.setSecret(ZapNoteCredentialService.aiApiKeyAlias(configId), value);
  }

  private static aiApiKeyAlias(configId: string): string {
    const normalizedId: string = configId.trim().replace(/[^A-Za-z0-9._-]/g, '_');
    return normalizedId.length > 0 ? ZapNoteCredentialService.AI_API_KEY_ALIAS + '.' + normalizedId :
      ZapNoteCredentialService.AI_API_KEY_ALIAS;
  }

  private static async getSecret(alias: string): Promise<string> {
    try {
      const query: asset.AssetMap = new Map();
      query.set(asset.Tag.ALIAS, ZapNoteCredentialService.toBytes(alias));
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
      const result: Array<asset.AssetMap> = await asset.query(query);
      if (result.length === 0) {
        return '';
      }
      const secret: Uint8Array | undefined = result[0].get(asset.Tag.SECRET) as Uint8Array | undefined;
      return secret === undefined ? '' : ZapNoteCredentialService.fromBytes(secret);
    } catch (error) {
      console.error('ZapNoteCredentialService getSecret failed: ' + JSON.stringify(error));
      return '';
    }
  }

  private static async setSecret(alias: string, value: string): Promise<boolean> {
    try {
      const query: asset.AssetMap = new Map();
      query.set(asset.Tag.ALIAS, ZapNoteCredentialService.toBytes(alias));
      if (value.length === 0) {
        try {
          await asset.remove(query);
        } catch (error) {
          const businessError: BusinessError = error as BusinessError;
          if (businessError.code !== asset.ErrorCode.NOT_FOUND) {
            throw new Error('Asset remove failed, code=' + businessError.code + ', message=' + businessError.message);
          }
        }
        return true;
      }
      const addAttributes: asset.AssetMap = new Map();
      addAttributes.set(asset.Tag.ALIAS, ZapNoteCredentialService.toBytes(alias));
      addAttributes.set(asset.Tag.SECRET, ZapNoteCredentialService.toBytes(value));
      addAttributes.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);
      addAttributes.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
      await asset.add(addAttributes);
      return true;
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      console.error('ZapNoteCredentialService setSecret failed, code=' + businessError.code +
        ', message=' + businessError.message);
      return false;
    }
  }

  private static toBytes(value: string): Uint8Array {
    return new util.TextEncoder().encodeInto(value);
  }

  private static fromBytes(value: Uint8Array): string {
    return util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeToString(value, { stream: false });
  }
}
