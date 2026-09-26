import { http } from '@kit.NetworkKit';

export interface WebDavConnectionTestResult {
  success: boolean;
  message: string;
  responseCode: number;
}

export interface WebDavTransferResult {
  success: boolean;
  message: string;
  responseCode: number;
  content: string;
  fileName: string;
  binaryContent?: ArrayBuffer;
}

export class WebDavService {
  private static readonly PROPFIND_BODY: string =
    '<?xml version="1.0" encoding="utf-8" ?><d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype /></d:prop></d:propfind>';

  public static async testConnection(serverUrl: string, remotePath: string, username: string,
    password: string): Promise<WebDavConnectionTestResult> {
    const url: string = WebDavService.buildTargetUrl(serverUrl, remotePath);
    if (url.length === 0) {
      return WebDavService.result(false, '服务器地址不能为空', 0);
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return WebDavService.result(false, '服务器地址需要以 http:// 或 https:// 开头', 0);
    }

    const request = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(url, {
        method: 'PROPFIND' as http.RequestMethod,
        header: {
          'Authorization': WebDavService.authorizationHeader(username, password),
          'Depth': '0',
          'Content-Type': 'application/xml; charset=utf-8',
          'Accept': 'application/xml,text/xml,*/*'
        },
        extraData: WebDavService.PROPFIND_BODY,
        connectTimeout: 15000,
        readTimeout: 15000
      });
      return WebDavService.resultFromResponseCode(response.responseCode);
    } catch (error) {
      console.error('WebDavService testConnection failed: ' + JSON.stringify(error));
      return WebDavService.result(false, '连接失败，请检查网络、服务器地址或证书配置', 0);
    } finally {
      request.destroy();
    }
  }

  public static async uploadTextFile(serverUrl: string, remotePath: string, username: string, password: string,
    fileName: string, content: string): Promise<WebDavTransferResult> {
    const directoryReady: WebDavConnectionTestResult =
      await WebDavService.ensureRemoteDirectory(serverUrl, remotePath, username, password);
    if (!directoryReady.success) {
      return WebDavService.transferResult(false, directoryReady.message, directoryReady.responseCode, '', fileName);
    }

    const url: string = WebDavService.buildFileUrl(serverUrl, remotePath, fileName);
    const request = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(url, {
        method: 'PUT' as http.RequestMethod,
        header: {
          'Authorization': WebDavService.authorizationHeader(username, password),
          'Content-Type': 'application/json; charset=utf-8'
        },
        extraData: content,
        connectTimeout: 15000,
        readTimeout: 30000
      });

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return WebDavService.transferResult(true, '上传成功：' + fileName, response.responseCode, '', fileName);
      }
      return WebDavService.transferResult(false,
        WebDavService.messageFromTransferCode(response.responseCode, '上传失败'), response.responseCode, '', fileName);
    } catch (error) {
      console.error('WebDavService uploadTextFile failed: ' + JSON.stringify(error));
      return WebDavService.transferResult(false, '上传失败，请检查网络、服务器地址或证书配置', 0, '', fileName);
    } finally {
      request.destroy();
    }
  }

  public static async downloadTextFile(serverUrl: string, remotePath: string, username: string, password: string,
    fileName: string): Promise<WebDavTransferResult> {
    const url: string = WebDavService.buildFileUrl(serverUrl, remotePath, fileName);
    const request = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Authorization': WebDavService.authorizationHeader(username, password),
          'Accept': 'application/json,text/plain,*/*'
        },
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 30000
      });

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return WebDavService.transferResult(true, '拉取成功：' + fileName, response.responseCode,
          WebDavService.responseResultToString(response.result), fileName);
      }
      if (response.responseCode === 404) {
        return WebDavService.transferResult(false, '没有找到云端备份，请先推送本地数据', response.responseCode, '',
          fileName);
      }
      return WebDavService.transferResult(false,
        WebDavService.messageFromTransferCode(response.responseCode, '拉取失败'), response.responseCode, '', fileName);
    } catch (error) {
      console.error('WebDavService downloadTextFile failed: ' + JSON.stringify(error));
      return WebDavService.transferResult(false, '拉取失败，请检查网络、服务器地址或证书配置', 0, '', fileName);
    } finally {
      request.destroy();
    }
  }

  public static async uploadBinaryFile(serverUrl: string, remotePath: string, username: string, password: string,
    fileName: string, content: ArrayBuffer): Promise<WebDavTransferResult> {
    const directoryReady: WebDavConnectionTestResult =
      await WebDavService.ensureRemoteDirectory(serverUrl, remotePath, username, password);
    if (!directoryReady.success) {
      return WebDavService.transferResult(false, directoryReady.message, directoryReady.responseCode, '', fileName);
    }
    const request = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(WebDavService.buildFileUrl(serverUrl, remotePath, fileName), {
        method: 'PUT' as http.RequestMethod,
        header: { 'Authorization': WebDavService.authorizationHeader(username, password), 'Content-Type': 'application/zip' },
        extraData: content,
        connectTimeout: 15000,
        readTimeout: 60000
      });
      return response.responseCode >= 200 && response.responseCode < 300 ?
        WebDavService.transferResult(true, '上传成功：' + fileName, response.responseCode, '', fileName) :
        WebDavService.transferResult(false, WebDavService.messageFromTransferCode(response.responseCode, '上传失败'), response.responseCode, '', fileName);
    } catch (error) {
      console.error('WebDavService uploadBinaryFile failed: ' + JSON.stringify(error));
      return WebDavService.transferResult(false, '上传失败，请检查网络、服务器地址或证书配置', 0, '', fileName);
    } finally {
      request.destroy();
    }
  }

  public static async downloadBinaryFile(serverUrl: string, remotePath: string, username: string, password: string,
    fileName: string): Promise<WebDavTransferResult> {
    const request = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(WebDavService.buildFileUrl(serverUrl, remotePath, fileName), {
        method: http.RequestMethod.GET,
        header: { 'Authorization': WebDavService.authorizationHeader(username, password), 'Accept': 'application/zip,*/*' },
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 60000
      });
      if (response.responseCode >= 200 && response.responseCode < 300 && response.result instanceof ArrayBuffer) {
        const result: WebDavTransferResult = WebDavService.transferResult(true, '拉取成功：' + fileName, response.responseCode, '', fileName);
        result.binaryContent = response.result;
        return result;
      }
      if (response.responseCode === 404) {
        return WebDavService.transferResult(false, '没有找到云端备份，请先推送本地数据', 404, '', fileName);
      }
      return WebDavService.transferResult(false, WebDavService.messageFromTransferCode(response.responseCode, '拉取失败'), response.responseCode, '', fileName);
    } catch (error) {
      console.error('WebDavService downloadBinaryFile failed: ' + JSON.stringify(error));
      return WebDavService.transferResult(false, '拉取失败，请检查网络、服务器地址或证书配置', 0, '', fileName);
    } finally {
      request.destroy();
    }
  }

  private static authorizationHeader(username: string, password: string): string {
    return 'Basic ' + WebDavService.base64Encode(username + ':' + password);
  }

  private static normalizeServerUrl(value: string): string {
    return value.trim();
  }

  private static normalizeRemotePath(value: string): string {
    const trimmed: string = value.trim();
    if (trimmed.length === 0 || trimmed === '/') {
      return '';
    }
    const path: string = trimmed.startsWith('/') ? trimmed : '/' + trimmed;
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  private static buildTargetUrl(serverUrl: string, remotePath: string): string {
    const baseUrl: string = WebDavService.normalizeServerUrl(serverUrl);
    const path: string = WebDavService.normalizeRemotePath(remotePath);
    if (baseUrl.length === 0 || path.length === 0) {
      return baseUrl;
    }
    const base: string = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return base + path;
  }

  private static buildFileUrl(serverUrl: string, remotePath: string, fileName: string): string {
    const dirUrl: string = WebDavService.buildTargetUrl(serverUrl, remotePath);
    if (dirUrl.length === 0) {
      return '';
    }
    return dirUrl.endsWith('/') ? dirUrl + fileName : dirUrl + '/' + fileName;
  }

  private static async ensureRemoteDirectory(serverUrl: string, remotePath: string, username: string,
    password: string): Promise<WebDavConnectionTestResult> {
    const checkResult: WebDavConnectionTestResult =
      await WebDavService.testConnection(serverUrl, remotePath, username, password);
    if (checkResult.success) {
      return checkResult;
    }
    if (checkResult.responseCode !== 404) {
      return checkResult;
    }
    return await WebDavService.createRemoteDirectories(serverUrl, remotePath, username, password);
  }

  private static async createRemoteDirectories(serverUrl: string, remotePath: string, username: string,
    password: string): Promise<WebDavConnectionTestResult> {
    const path: string = WebDavService.normalizeRemotePath(remotePath);
    if (path.length === 0) {
      return WebDavService.result(true, '同步路径已存在', 200);
    }

    const segments: string[] = path.split('/').filter((item: string) => item.length > 0);
    let currentPath: string = '';
    for (let index = 0; index < segments.length; index++) {
      currentPath += '/' + segments[index];
      const created: WebDavConnectionTestResult =
        await WebDavService.createRemoteDirectory(serverUrl, currentPath, username, password);
      if (!created.success) {
        return created;
      }
    }
    return WebDavService.result(true, '同步路径已创建', 201);
  }

  private static async createRemoteDirectory(serverUrl: string, remotePath: string, username: string,
    password: string): Promise<WebDavConnectionTestResult> {
    const url: string = WebDavService.buildTargetUrl(serverUrl, remotePath);
    const request = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(url, {
        method: 'MKCOL' as http.RequestMethod,
        header: {
          'Authorization': WebDavService.authorizationHeader(username, password)
        },
        connectTimeout: 15000,
        readTimeout: 15000
      });
      if (response.responseCode >= 200 && response.responseCode < 300) {
        return WebDavService.result(true, '同步路径已创建', response.responseCode);
      }
      if (response.responseCode === 405) {
        return WebDavService.result(true, '同步路径已存在', response.responseCode);
      }
      if (response.responseCode === 409) {
        return WebDavService.result(false, '同步路径创建失败，请先创建上级目录或修改路径', response.responseCode);
      }
      return WebDavService.result(false,
        WebDavService.messageFromTransferCode(response.responseCode, '同步路径创建失败'), response.responseCode);
    } catch (error) {
      console.error('WebDavService createRemoteDirectory failed: ' + JSON.stringify(error));
      return WebDavService.result(false, '同步路径创建失败，请检查网络或目录权限', 0);
    } finally {
      request.destroy();
    }
  }

  private static resultFromResponseCode(responseCode: number): WebDavConnectionTestResult {
    if (responseCode >= 200 && responseCode < 300) {
      return WebDavService.result(true, 'WebDAV 连接成功', responseCode);
    }
    if (responseCode === 401) {
      return WebDavService.result(false, '认证失败，请检查用户名或应用授权密码', responseCode);
    }
    if (responseCode === 403) {
      return WebDavService.result(false, '服务器拒绝访问，请检查账号权限', responseCode);
    }
    if (responseCode === 404) {
      return WebDavService.result(false, '同步路径不存在，推送时会尝试自动创建', responseCode);
    }
    if (responseCode === 405) {
      return WebDavService.result(false, '服务器不支持 PROPFIND，请检查地址是否为 WebDAV 地址', responseCode);
    }
    return WebDavService.result(false, '连接失败，服务器返回状态码 ' + responseCode.toString(), responseCode);
  }

  private static result(success: boolean, message: string, responseCode: number): WebDavConnectionTestResult {
    return {
      success: success,
      message: message,
      responseCode: responseCode
    };
  }

  private static transferResult(success: boolean, message: string, responseCode: number, content: string,
    fileName: string): WebDavTransferResult {
    return {
      success: success,
      message: message,
      responseCode: responseCode,
      content: content,
      fileName: fileName
    };
  }

  private static messageFromTransferCode(responseCode: number, fallback: string): string {
    if (responseCode === 401) {
      return '认证失败，请检查用户名或应用授权密码';
    }
    if (responseCode === 403) {
      return '服务器拒绝访问，请检查账号权限';
    }
    if (responseCode === 404) {
      return '同步路径不存在，请先创建该目录或修改路径';
    }
    if (responseCode === 409) {
      return '同步路径不可用，请先创建上级目录或修改路径';
    }
    if (responseCode === 507) {
      return '云端空间不足，无法完成同步';
    }
    return fallback + '，服务器返回状态码 ' + responseCode.toString();
  }

  private static responseResultToString(result: string | ArrayBuffer | object): string {
    if (typeof result === 'string') {
      return result;
    }
    if (result instanceof ArrayBuffer) {
      return WebDavService.arrayBufferToUtf8String(result);
    }
    return JSON.stringify(result);
  }

  private static arrayBufferToUtf8String(buffer: ArrayBuffer): string {
    const bytes: Uint8Array = new Uint8Array(buffer);
    let result: string = '';
    let index: number = 0;
    while (index < bytes.length) {
      const first: number = bytes[index];
      if (first < 0x80) {
        result += String.fromCharCode(first);
        index++;
      } else if ((first & 0xE0) === 0xC0 && index + 1 < bytes.length) {
        const code: number = ((first & 0x1F) << 6) | (bytes[index + 1] & 0x3F);
        result += String.fromCharCode(code);
        index += 2;
      } else if ((first & 0xF0) === 0xE0 && index + 2 < bytes.length) {
        const code: number = ((first & 0x0F) << 12) | ((bytes[index + 1] & 0x3F) << 6) |
          (bytes[index + 2] & 0x3F);
        result += String.fromCharCode(code);
        index += 3;
      } else if ((first & 0xF8) === 0xF0 && index + 3 < bytes.length) {
        let codePoint: number = ((first & 0x07) << 18) | ((bytes[index + 1] & 0x3F) << 12) |
          ((bytes[index + 2] & 0x3F) << 6) | (bytes[index + 3] & 0x3F);
        codePoint -= 0x10000;
        result += String.fromCharCode(0xD800 + (codePoint >> 10), 0xDC00 + (codePoint & 0x3FF));
        index += 4;
      } else {
        index++;
      }
    }
    return result;
  }

  private static base64Encode(value: string): string {
    const alphabet: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const bytes: number[] = WebDavService.toUtf8Bytes(value);
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

  private static toUtf8Bytes(value: string): number[] {
    const bytes: number[] = [];
    for (let index = 0; index < value.length; index++) {
      let codePoint: number = value.charCodeAt(index);
      if (codePoint >= 0xD800 && codePoint <= 0xDBFF && index + 1 < value.length) {
        const next: number = value.charCodeAt(index + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          codePoint = 0x10000 + ((codePoint - 0xD800) << 10) + (next - 0xDC00);
          index++;
        }
      }

      if (codePoint <= 0x7F) {
        bytes.push(codePoint);
      } else if (codePoint <= 0x7FF) {
        bytes.push(0xC0 | (codePoint >> 6));
        bytes.push(0x80 | (codePoint & 0x3F));
      } else if (codePoint <= 0xFFFF) {
        bytes.push(0xE0 | (codePoint >> 12));
        bytes.push(0x80 | ((codePoint >> 6) & 0x3F));
        bytes.push(0x80 | (codePoint & 0x3F));
      } else {
        bytes.push(0xF0 | (codePoint >> 18));
        bytes.push(0x80 | ((codePoint >> 12) & 0x3F));
        bytes.push(0x80 | ((codePoint >> 6) & 0x3F));
        bytes.push(0x80 | (codePoint & 0x3F));
      }
    }
    return bytes;
  }
}
