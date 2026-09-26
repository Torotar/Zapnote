import { LinkType, MatchRuleTemplateItem } from '../model/ZapNoteTypes';
import { MatchRuleKeywordService } from './MatchRuleKeywordService';

export interface LinkMatch {
  type: LinkType;
  value: string;
  accessCode: string;
  start: number;
  end: number;
}

export interface LinkIntent {
  mode: 'none' | 'all' | 'specific';
  types: LinkType[];
  linkOnly: boolean;
  template: string;
}

export interface LinkExtractionResult {
  matches: LinkMatch[];
  linksText: string;
  remainingText: string;
}

interface LinkTextSpan {
  start: number;
  end: number;
}

interface MagnetSuffixResult {
  value: string;
  end: number;
}

export class LinkRecognitionService {
  private static readonly SPECIFIC_TYPES: LinkType[] = [
    'magnet', 'baidu', 'aliyun', 'quark', '115', 'tianyi', 'xunlei', 'feishu', 'qq', 'wechat'
  ];

  private static uniqueTypes(types: LinkType[]): LinkType[] {
    const result: LinkType[] = [];
    types.forEach((type: LinkType): void => {
      if (type !== 'none' && result.indexOf(type) < 0) {
        result.push(type);
      }
    });
    return result;
  }

  private static addTypeWhenMatched(result: LinkType[], source: string, pattern: RegExp, type: LinkType): void {
    if (pattern.test(source) && result.indexOf(type) < 0) {
      result.push(type);
    }
  }

  static inferTypes(text: string): LinkType[] {
    const source: string = text.trim();
    if (source.length === 0) {
      return [];
    }
    const result: LinkType[] = [];
    LinkRecognitionService.addTypeWhenMatched(result, source, /磁力(?:链接|地址)?|magnet/i, 'magnet');
    LinkRecognitionService.addTypeWhenMatched(result, source, /百度(?:网盘|云)(?:链接|地址)?/i, 'baidu');
    LinkRecognitionService.addTypeWhenMatched(result, source, /阿里(?:云盘|网盘)(?:链接|地址)?/i, 'aliyun');
    LinkRecognitionService.addTypeWhenMatched(result, source, /夸克(?:网盘)?(?:链接|地址)?/i, 'quark');
    LinkRecognitionService.addTypeWhenMatched(result, source, /115(?:网盘)?(?:链接|地址)?/i, '115');
    LinkRecognitionService.addTypeWhenMatched(result, source, /天翼(?:云盘|网盘)(?:链接|地址)?/i, 'tianyi');
    LinkRecognitionService.addTypeWhenMatched(result, source, /迅雷(?:云盘|网盘)(?:链接|地址)?/i, 'xunlei');
    LinkRecognitionService.addTypeWhenMatched(result, source, /飞书(?:链接|地址|文档)?|Lark(?:链接|地址)?/i, 'feishu');
    LinkRecognitionService.addTypeWhenMatched(result, source, /QQ(?:链接|地址|分享)|腾讯文档(?:链接|地址)?/i, 'qq');
    LinkRecognitionService.addTypeWhenMatched(result, source, /微信(?:链接|地址|分享)|WeChat(?:链接|地址)?/i, 'wechat');
    if (result.length > 0) {
      return result;
    }
    return /(?:链接|网址|URL)/i.test(source) ? ['all'] : [];
  }

  static inferRuleLinkType(item: MatchRuleTemplateItem): LinkType {
    const inferred: LinkType[] = LinkRecognitionService.inferTypes(item.keyword + '\n' + item.template);
    if (inferred.length === 0) {
      return 'none';
    }
    for (let index: number = 0; index < inferred.length; index++) {
      if (inferred[index] !== 'all') {
        return inferred[index];
      }
    }
    return 'all';
  }

  private static isPhotoRule(item: MatchRuleTemplateItem): boolean {
    return item.scopes.indexOf('照片分析') >= 0 || item.scopes.indexOf('照片分享') >= 0;
  }

  private static activeIntentRules(items: MatchRuleTemplateItem[], customEngine: boolean,
    aiConfigId: string): MatchRuleTemplateItem[] {
    const result: MatchRuleTemplateItem[] = [];
    items.forEach((item: MatchRuleTemplateItem): void => {
      if (!item.enabled || !LinkRecognitionService.isPhotoRule(item)) {
        return;
      }
      if (customEngine) {
        if (item.kind === 'ai-output' && (aiConfigId.length === 0 || item.aiConfigId === aiConfigId)) {
          result.push(item);
        }
        return;
      }
      if (item.kind === 'keyword') {
        result.push(item);
      }
    });
    return result;
  }

  private static isLinkOnlyText(text: string): boolean {
    if (text.trim().length === 0) {
      return true;
    }
    let source: string = text;
    source = source.replace(/\{\{(?:内容|链接|磁力链接|百度网盘链接|阿里云盘链接|夸克网盘链接|115网盘链接|天翼云盘链接|迅雷云盘链接|飞书链接|QQ链接|微信链接|网盘提取码)\}\}/gi, '');
    source = source.replace(/磁力|百度|阿里|夸克|115|天翼|迅雷|飞书|Lark|QQ|腾讯文档|微信|WeChat/gi, '');
    source = source.replace(/网盘|云盘|链接|地址|网址|URL|提取码|访问码|密码|口令/gi, '');
    source = source.replace(/识别|提取|选取|输出|填入|保留|整理|查找|检测|获取|全部|所有|仅|只|并|和|及|的|为/gi, '');
    source = source.replace(/图片|照片|笔记|日记|正文|结果|文档|分享|其中|当中|里面|以内|中|内|到/gi, '');
    source = source.replace(/[\s,，、;；:：。.!！?？()（）\[\]【】"'“”‘’_-]/g, '');
    return source.length === 0;
  }

  static resolveIntent(items: MatchRuleTemplateItem[], customEngine: boolean = false,
    aiConfigId: string = '', outputContent: string = ''): LinkIntent {
    const rules: MatchRuleTemplateItem[] = LinkRecognitionService.activeIntentRules(items, customEngine, aiConfigId);
    const inferredTypes: LinkType[] = [];
    const sourceParts: string[] = [];
    let template: string = '';
    rules.forEach((item: MatchRuleTemplateItem): void => {
      const source: string = item.keyword + '\n' + item.template;
      sourceParts.push(source);
      if (template.length === 0 && item.template.trim().length > 0) {
        template = item.template.trim();
      }
      if (item.linkType !== undefined && item.linkType !== 'none') {
        inferredTypes.push(item.linkType);
      }
      LinkRecognitionService.inferTypes(source).forEach((type: LinkType): void => {
        inferredTypes.push(type);
      });
    });
    if (customEngine && outputContent.trim().length > 0) {
      sourceParts.push(outputContent);
      if (template.length === 0) {
        template = outputContent.trim();
      }
      LinkRecognitionService.inferTypes(outputContent).forEach((type: LinkType): void => {
        inferredTypes.push(type);
      });
    }
    const unique: LinkType[] = LinkRecognitionService.uniqueTypes(inferredTypes);
    const specific: LinkType[] = [];
    LinkRecognitionService.SPECIFIC_TYPES.forEach((type: LinkType): void => {
      if (unique.indexOf(type) >= 0) {
        specific.push(type);
      }
    });
    const sourceText: string = sourceParts.join('\n');
    if (specific.length > 0) {
      return {
        mode: 'specific',
        types: specific,
        linkOnly: LinkRecognitionService.isLinkOnlyText(sourceText),
        template: template
      };
    }
    if (unique.indexOf('all') >= 0) {
      return {
        mode: 'all',
        types: ['all'],
        linkOnly: LinkRecognitionService.isLinkOnlyText(sourceText),
        template: template
      };
    }
    return { mode: 'none', types: [], linkOnly: false, template: '' };
  }

  private static normalizedUrl(value: string): string {
    let result: string = value.replace(/\s+/g, '');
    while (result.length > 0 && /[，。；、,;.!！?？)）\]】}]/.test(result.charAt(result.length - 1))) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  private static hostFromUrl(value: string): string {
    const match: RegExpMatchArray | null = value.match(/^(?:https?:\/\/)?([^\/:?#]+)/i);
    return match === null ? '' : match[1].toLowerCase();
  }

  private static hostMatches(host: string, domain: string): boolean {
    return host === domain || host.endsWith('.' + domain);
  }

  private static classifyUrl(value: string): LinkType {
    const host: string = LinkRecognitionService.hostFromUrl(value);
    if (LinkRecognitionService.hostMatches(host, 'pan.baidu.com') ||
      LinkRecognitionService.hostMatches(host, 'yun.baidu.com')) {
      return 'baidu';
    }
    if (LinkRecognitionService.hostMatches(host, 'aliyundrive.com') ||
      LinkRecognitionService.hostMatches(host, 'alipan.com')) {
      return 'aliyun';
    }
    if (LinkRecognitionService.hostMatches(host, 'pan.quark.cn')) {
      return 'quark';
    }
    if (LinkRecognitionService.hostMatches(host, '115.com')) {
      return '115';
    }
    if (LinkRecognitionService.hostMatches(host, 'cloud.189.cn')) {
      return 'tianyi';
    }
    if (LinkRecognitionService.hostMatches(host, 'pan.xunlei.com')) {
      return 'xunlei';
    }
    if (LinkRecognitionService.hostMatches(host, 'feishu.cn') ||
      LinkRecognitionService.hostMatches(host, 'larksuite.com') ||
      LinkRecognitionService.hostMatches(host, 'larkoffice.com')) {
      return 'feishu';
    }
    if (LinkRecognitionService.hostMatches(host, 'mp.weixin.qq.com') ||
      LinkRecognitionService.hostMatches(host, 'weixin.qq.com') ||
      LinkRecognitionService.hostMatches(host, 'work.weixin.qq.com') ||
      LinkRecognitionService.hostMatches(host, 'wechat.com')) {
      return 'wechat';
    }
    if (LinkRecognitionService.hostMatches(host, 'qq.com') || host === 'url.cn') {
      return 'qq';
    }
    return 'web';
  }

  private static addMatch(matches: LinkMatch[], match: LinkMatch): void {
    for (let index: number = 0; index < matches.length; index++) {
      if (matches[index].value.toLowerCase() === match.value.toLowerCase() ||
        (matches[index].start <= match.start && matches[index].end >= match.end)) {
        return;
      }
    }
    matches.push(match);
  }

  private static collectMagnetMatches(text: string, matches: LinkMatch[]): void {
    // OCR may insert spaces between individual Latin characters in the
    // letter-spaced magnet text shown in chat screenshots.
    const prefixPattern: RegExp =
      /m\s*a\s*g\s*n\s*e\s*t\s*[:：]\s*[?？]\s*x\s*t\s*[=＝]\s*u\s*r\s*n\s*[:：]\s*b\s*t\s*i\s*h\s*[:：]/ig;
    let searchIndex: number = 0;
    while (searchIndex < text.length) {
      prefixPattern.lastIndex = searchIndex;
      const item: RegExpExecArray | null = prefixPattern.exec(text);
      if (item === null) {
        break;
      }
      const hashCharacters: string[] = [];
      const sourceIndexes: number[] = [];
      let sourceIndex: number = prefixPattern.lastIndex;
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
      let candidate: string = hashCharacters.join('');
      const correctedHexCandidate: string = candidate
        .replace(/O/g, '0')
        .replace(/[IL]/g, '1')
        .replace(/S/g, '5')
        .replace(/G/g, '6');
      let hashLength: number = 0;
      if (candidate.length >= 40 && /^[A-F0-9]{40}$/.test(candidate.substring(0, 40))) {
        hashLength = 40;
      } else if (correctedHexCandidate.length >= 40 &&
        /^[A-F0-9]{40}$/.test(correctedHexCandidate.substring(0, 40))) {
        candidate = correctedHexCandidate;
        hashLength = 40;
      } else if (candidate.length >= 32 && /^[A-Z2-7]{32}$/.test(candidate.substring(0, 32))) {
        hashLength = 32;
      }
      if (hashLength > 0) {
      const hashEnd: number = sourceIndexes[hashLength - 1] + 1;
      const suffixResult: MagnetSuffixResult =
        LinkRecognitionService.collectMagnetSuffix(text, hashEnd);
      const suffix: string = suffixResult.value;
      const end: number = suffixResult.end;
        LinkRecognitionService.addMatch(matches, {
          type: 'magnet',
          value: 'magnet:?xt=urn:btih:' + candidate.substring(0, hashLength) + suffix,
          accessCode: '',
          start: item.index,
          end: end
        });
        searchIndex = end;
        continue;
      }
      searchIndex = prefixPattern.lastIndex;
    }
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

  private static collectUrlMatches(text: string, matches: LinkMatch[]): void {
    const pattern: RegExp = /https?:\/\/[^\s<>"'，。；、]+/ig;
    let item: RegExpExecArray | null = pattern.exec(text);
    while (item !== null) {
      const normalized: string = LinkRecognitionService.normalizedUrl(item[0]);
      if (normalized.length > 'https://a.b'.length) {
        LinkRecognitionService.addMatch(matches, {
          type: LinkRecognitionService.classifyUrl(normalized),
          value: normalized,
          accessCode: '',
          start: item.index,
          end: item.index + normalized.length
        });
      }
      item = pattern.exec(text);
    }
  }

  private static collectBareMainstreamUrlMatches(text: string, matches: LinkMatch[]): void {
    const pattern: RegExp = /(?:pan\.baidu\.com|yun\.baidu\.com|(?:www\.)?aliyundrive\.com|(?:www\.)?alipan\.com|pan\.quark\.cn|115\.com|cloud\.189\.cn|pan\.xunlei\.com|[A-Za-z0-9-]+\.feishu\.cn|[A-Za-z0-9-]+\.larksuite\.com|docs\.qq\.com|qm\.qq\.com|url\.cn|mp\.weixin\.qq\.com|work\.weixin\.qq\.com)(?:\/[^\s<>"'，。；、]+)?/ig;
    let item: RegExpExecArray | null = pattern.exec(text);
    while (item !== null) {
      const beforeStart: number = Math.max(0, item.index - 8);
      const before: string = text.substring(beforeStart, item.index);
      if (!/https?:\/\/$/i.test(before)) {
        const normalized: string = LinkRecognitionService.normalizedUrl(item[0]);
        LinkRecognitionService.addMatch(matches, {
          type: LinkRecognitionService.classifyUrl(normalized),
          value: normalized,
          accessCode: '',
          start: item.index,
          end: item.index + normalized.length
        });
      }
      item = pattern.exec(text);
    }
  }

  private static isRequestedType(type: LinkType, requestedTypes: LinkType[]): boolean {
    return requestedTypes.indexOf('all') >= 0 || requestedTypes.indexOf(type) >= 0;
  }

  private static attachAccessCodes(text: string, matches: LinkMatch[], spans: LinkTextSpan[]): void {
    for (let index: number = 0; index < matches.length; index++) {
      const nextStart: number = index + 1 < matches.length ? matches[index + 1].start : text.length;
      const searchEnd: number = Math.min(nextStart, matches[index].end + 100);
      const nearby: string = text.substring(matches[index].end, searchEnd);
      const pattern: RegExp = /[\s,，、;；。]*(?:提取码|访问码|密码|口令)\s*[:：]?\s*([A-Za-z0-9]{4,10})/i;
      const codeMatch: RegExpExecArray | null = pattern.exec(nearby);
      if (codeMatch !== null && codeMatch.index <= 32) {
        matches[index].accessCode = codeMatch[1];
        spans.push({
          start: matches[index].end + codeMatch.index,
          end: matches[index].end + codeMatch.index + codeMatch[0].length
        });
      }
    }
  }

  private static remainingText(text: string, spans: LinkTextSpan[]): string {
    const characters: string[] = text.split('');
    spans.forEach((span: LinkTextSpan): void => {
      const end: number = Math.min(span.end, characters.length);
      for (let index: number = Math.max(span.start, 0); index < end; index++) {
        if (characters[index] !== '\n' && characters[index] !== '\r') {
          characters[index] = ' ';
        }
      }
    });
    const lines: string[] = [];
    characters.join('').split(/\r?\n/).forEach((line: string): void => {
      const value: string = line.trim();
      const linkLabelOnly: boolean = /^(?:链接|网址|URL|磁力链接|百度(?:网盘|云)|阿里(?:云盘|网盘)|夸克(?:网盘)?|115(?:网盘)?|天翼(?:云盘|网盘)|迅雷(?:云盘|网盘)|飞书(?:文档)?|QQ|腾讯文档|微信)\s*[:：]?$/i.test(value);
      if (value.length > 0 && !linkLabelOnly) {
        lines.push(value);
      }
    });
    return lines.join('\n').trim();
  }

  private static replaceAll(source: string, search: string, replacement: string): string {
    return source.split(search).join(replacement);
  }

  private static aliasForType(type: LinkType): string {
    if (type === 'magnet') return '{{磁力链接}}';
    if (type === 'baidu') return '{{百度网盘链接}}';
    if (type === 'aliyun') return '{{阿里云盘链接}}';
    if (type === 'quark') return '{{夸克网盘链接}}';
    if (type === '115') return '{{115网盘链接}}';
    if (type === 'tianyi') return '{{天翼云盘链接}}';
    if (type === 'xunlei') return '{{迅雷云盘链接}}';
    if (type === 'feishu') return '{{飞书链接}}';
    if (type === 'qq') return '{{QQ链接}}';
    if (type === 'wechat') return '{{微信链接}}';
    return '{{链接}}';
  }

  static formatMatches(matches: LinkMatch[], template: string = ''): string {
    const result: string[] = [];
    const hasPlaceholder: boolean = /\{\{[^}]+\}\}/.test(template);
    matches.forEach((match: LinkMatch): void => {
      let value: string = match.value;
      if (hasPlaceholder) {
        value = template;
        value = LinkRecognitionService.replaceAll(value, '{{内容}}', match.value);
        value = LinkRecognitionService.replaceAll(value, '{{链接}}', match.value);
        value = LinkRecognitionService.replaceAll(value, LinkRecognitionService.aliasForType(match.type), match.value);
        value = LinkRecognitionService.replaceAll(value, '{{网盘提取码}}', match.accessCode);
      } else if (match.accessCode.length > 0) {
        value += '\n提取码：' + match.accessCode;
      }
      value = value.trim();
      if (value.length > 0 && result.indexOf(value) < 0) {
        result.push(value);
      }
    });
    return result.join('\n').trim();
  }

  static extract(text: string, requestedTypes: LinkType[], template: string = ''): LinkExtractionResult {
    const found: LinkMatch[] = [];
    LinkRecognitionService.collectMagnetMatches(text, found);
    LinkRecognitionService.collectUrlMatches(text, found);
    LinkRecognitionService.collectBareMainstreamUrlMatches(text, found);
    found.sort((left: LinkMatch, right: LinkMatch): number => left.start - right.start);
    const matches: LinkMatch[] = [];
    found.forEach((match: LinkMatch): void => {
      if (LinkRecognitionService.isRequestedType(match.type, requestedTypes)) {
        matches.push(match);
      }
    });
    const spans: LinkTextSpan[] = [];
    matches.forEach((match: LinkMatch): void => {
      spans.push({ start: match.start, end: match.end });
    });
    LinkRecognitionService.attachAccessCodes(text, matches, spans);
    let linksText: string = LinkRecognitionService.formatMatches(matches, template);
    if (linksText.length === 0 && matches.length > 0) {
      linksText = LinkRecognitionService.formatMatches(matches);
    }
    return {
      matches: matches,
      linksText: linksText,
      remainingText: LinkRecognitionService.remainingText(text, spans)
    };
  }

  static rulesWithoutLinkIntent(items: MatchRuleTemplateItem[]): MatchRuleTemplateItem[] {
    const result: MatchRuleTemplateItem[] = [];
    items.forEach((item: MatchRuleTemplateItem): void => {
      if (item.kind !== 'keyword') {
        result.push(item);
        return;
      }
      const keywords: string[] = item.matchMode === 'regex' ?
        MatchRuleKeywordService.splitRegex(item.keyword) : MatchRuleKeywordService.splitPlain(item.keyword);
      const retained: string[] = [];
      keywords.forEach((keyword: string): void => {
        if (LinkRecognitionService.inferTypes(keyword + '\n' + item.template).length === 0) {
          retained.push(keyword);
        }
      });
      if (retained.length > 0) {
        result.push({
          id: item.id,
          kind: item.kind,
          aiConfigId: item.aiConfigId,
          scopes: item.scopes,
          keyword: retained.join('\n'),
          template: item.template,
          enabled: item.enabled,
          action: item.action,
          range: item.range,
          matchMode: item.matchMode,
          linkType: 'none'
        });
      }
    });
    return result;
  }
}
