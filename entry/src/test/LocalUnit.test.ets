import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { DiaryEntry, MatchRuleTemplateItem } from '../main/ets/model/ZapNoteTypes';
import { ZapNoteBackupService } from '../main/ets/services/ZapNoteBackupService';
import { MatchRuleKeywordService } from '../main/ets/services/MatchRuleKeywordService';
import { LinkRecognitionService } from '../main/ets/services/LinkRecognitionService';
import { OcrRuleProcessingService } from '../main/ets/services/OcrRuleProcessingService';
import {
  OcrTextBlockResult,
  OcrTextLineResult,
  OcrTextPointResult,
  OcrTextRecognitionResult,
  OcrTextRecognitionService
} from '../main/ets/services/OcrTextRecognitionService';

function ocrCorners(left: number, top: number, right: number, bottom: number): OcrTextPointResult[] {
  return [
    { x: left, y: top },
    { x: right, y: top },
    { x: right, y: bottom },
    { x: left, y: bottom }
  ];
}

function ocrLine(text: string, left: number, top: number, right: number, bottom: number): OcrTextLineResult {
  return {
    text: text,
    words: [{ text: text, cornerPoints: ocrCorners(left, top, right, bottom) }],
    cornerPoints: ocrCorners(left, top, right, bottom)
  };
}

function ocrBlock(line: OcrTextLineResult): OcrTextBlockResult {
  return { text: line.text, lines: [line] };
}

function orderOcrResult(): OcrTextRecognitionResult {
  return {
    text: '订单编号\n5124091824635039615 | 复制\n交易快照\n发生交易争议时，可作为判断依据\n付款时间\n2026-07-13 15:17:38',
    photoUri: '',
    blocks: [
      ocrBlock(ocrLine('订单编号', 24, 20, 142, 52)),
      ocrBlock(ocrLine('5124091824635039615 | 复制', 370, 23, 750, 53)),
      ocrBlock(ocrLine('交易快照', 24, 90, 142, 122)),
      ocrBlock(ocrLine('发生交易争议时，可作为判断依据', 310, 91, 740, 123)),
      ocrBlock(ocrLine('付款时间', 24, 160, 142, 192)),
      ocrBlock(ocrLine('2026-07-13 15:17:38', 480, 162, 742, 194))
    ]
  };
}

function groupedMagnetAndCodeOcrResult(): OcrTextRecognitionResult {
  const magnetPrefixStart: string = 'magnet:?xt=urn:b';
  const magnetPrefixEnd: string = 'tih:E03DBB264';
  const hashMiddle: string = '6E6A46738DAFC6F84A29F02233';
  const hashEnd: string = '3A07C';
  const secondMagnetPrefixStart: string = 'magnet:?xt=urn:b';
  const secondMagnetPrefixEnd: string = 'tih:47cc595813b0b1fb0333c65fe636ba3ea25a98c6';
  return {
    text: 'LV100 光\n@武安谟 ' + magnetPrefixStart + '\n' + magnetPrefixEnd + '\n' +
      hashMiddle + '\n' + hashEnd + '\nABP-123\n@葡萄糖酸不酸 ' + secondMagnetPrefixStart + '\n' +
      secondMagnetPrefixEnd,
    photoUri: '',
    blocks: [
      ocrBlock(ocrLine('LV100 光', 20, 20, 180, 52)),
      ocrBlock(ocrLine('@武安谟 ' + magnetPrefixStart, 20, 62, 480, 94)),
      ocrBlock(ocrLine('ABP-123', 500, 62, 620, 94)),
      ocrBlock(ocrLine(magnetPrefixEnd, 20, 104, 460, 136)),
      ocrBlock(ocrLine(hashMiddle, 20, 146, 460, 178)),
      ocrBlock(ocrLine(hashEnd, 20, 188, 120, 220)),
      ocrBlock(ocrLine('@葡萄糖酸不酸 ' + secondMagnetPrefixStart, 20, 230, 480, 262)),
      ocrBlock(ocrLine(secondMagnetPrefixEnd, 20, 272, 640, 304))
    ]
  };
}

function extractRule(keyword: string, template: string): MatchRuleTemplateItem {
  return {
    id: 'test-' + keyword,
    kind: 'keyword',
    aiConfigId: '',
    scopes: ['照片分析'],
    keyword: keyword,
    template: template,
    enabled: true,
    action: 'extract',
    range: 'match',
    matchMode: 'contains'
  };
}

export default function localUnitTest() {
  describe('localUnitTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    });
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    });
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    });
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    });
    it('assertContain', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let a = 'abc';
      let b = 'b';
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });

    it('backupRoundTrip', 0, async () => {
      const diary: DiaryEntry = {
        id: 'test-1',
        title: '测试日记',
        body: '备份往返测试',
        folderName: '测试',
        dateText: '2026-07-12',
        dateMs: 1780000000000,
        mood: 'happy',
        weather: 'sunny',
        isToday: true,
        isThisWeek: true,
        isFavorite: false,
        wordCount: 6,
        hasPhoto: false,
        photoInBody: false,
        photoUri: '',
        photoX: 0,
        photoY: 0,
        photoWidth: 156,
        photoHeight: 118,
        photoRotation: 0,
        photoStyle: 'original'
      };
      const content: string = await ZapNoteBackupService.exportBackupJson([diary], 1780000000000, undefined, 'diaries', ['测试']);
      const restored: DiaryEntry[] = ZapNoteBackupService.restoreBackupJson(content);
      expect(restored.length).assertEqual(1);
      expect(restored[0].id).assertEqual('test-1');
      expect(ZapNoteBackupService.restoreDiaryFolders(content)[0]).assertEqual('测试');
    });

    it('splitMultipleMatchRuleKeywords', 0, () => {
      const keywords: string[] = MatchRuleKeywordService.splitPlain(
        '订单编号\r\n付款时间，微信交易号；磁力链接、番号'
      );
      expect(keywords.length).assertEqual(5);
      expect(keywords[0]).assertEqual('订单编号');
      expect(keywords[4]).assertEqual('番号');
    });

    it('extractWrappedMagnetLink', 0, () => {
      const text: string = 'magnet:?xt=urn:btih:E03DBB264\n' +
        '6E6A46738DAFC6F84A29F02233\n' +
        '3A07C\n羊宫妃娜我来草拟啦';
      expect(OcrTextRecognitionService.extractMagnetLink(text)).assertEqual(
        'magnet:?xt=urn:btih:E03DBB2646E6A46738DAFC6F84A29F022333A07C'
      );
    });

    it('extractWrappedMagnetPrefixAndHash', 0, () => {
      const text: string = '@武安谟 magnet:?xt=urn:b\n' +
        'tih:E03DBB264\n6E6A46738DAFC6F84A29F02233\n3A07C';
      expect(OcrTextRecognitionService.extractMagnetLink(text)).assertEqual(
        'magnet:?xt=urn:btih:E03DBB2646E6A46738DAFC6F84A29F022333A07C'
      );
    });

    it('extractMultipleWrappedMagnetLinks', 0, () => {
      const text: string = 'magnet:?xt=urn:b\ntih:E03DBB2646E6A46738DAFC6F84A29F022333A07C\n' +
        '@葡萄糖酸不酸 magnet:?xt=urn:b\ntih:47cc595813b0b1fb0333c65fe636ba3ea25a98c6';
      const links: string[] = OcrTextRecognitionService.extractMagnetLinks(text);
      expect(links.length).assertEqual(2);
      expect(links[0]).assertEqual(
        'magnet:?xt=urn:btih:E03DBB2646E6A46738DAFC6F84A29F022333A07C'
      );
      expect(links[1]).assertEqual(
        'magnet:?xt=urn:btih:47CC595813B0B1FB0333C65FE636BA3EA25A98C6'
      );
    });

    it('stopMagnetLinkAfterCompleteHash', 0, () => {
      const text: string = 'magnet:?xt=urn:btih:E03DBB2646E6A46738DAFC6F84A29F022333A07C\nABCDEF';
      expect(OcrTextRecognitionService.extractMagnetLink(text)).assertEqual(
        'magnet:?xt=urn:btih:E03DBB2646E6A46738DAFC6F84A29F022333A07C'
      );
    });

    it('extractOnlyAlignedOrderNumber', 0, () => {
      const processed: string = OcrRuleProcessingService.process(
        orderOcrResult(),
        [extractRule('订单编号', '订单编号：{{内容}}')]
      ).processedText;
      expect(processed).assertEqual('订单编号：5124091824635039615');
    });

    it('extractMultipleValuesFromOneGroupedRule', 0, () => {
      const processed: string = OcrRuleProcessingService.process(
        orderOcrResult(),
        [
          extractRule('订单编号\n付款时间', '{{内容}}')
        ]
      ).processedText;
      expect(processed).assertEqual('5124091824635039615\n2026-07-13 15:17:38');
    });

    it('extractGroupedMagnetAndCodeFromLeftToRight', 0, () => {
      const rule: MatchRuleTemplateItem = extractRule('番号\n磁力链接', '');
      rule.range = 'block';
      const result = OcrRuleProcessingService.process(
        groupedMagnetAndCodeOcrResult(),
        [rule]
      );
      expect(result.matchedRuleCount).assertEqual(2);
      expect(result.processedText).assertEqual(
        'magnet:?xt=urn:btih:E03DBB2646E6A46738DAFC6F84A29F022333A07C\nABP-123\n' +
        'magnet:?xt=urn:btih:47CC595813B0B1FB0333C65FE636BA3EA25A98C6'
      );
    });

    it('resolveSpecificLinkIntentBeforeGenericLinkIntent', 0, () => {
      const rule: MatchRuleTemplateItem = extractRule('链接\n微信链接', '{{链接}}');
      const intent = LinkRecognitionService.resolveIntent([rule]);
      expect(intent.mode).assertEqual('specific');
      expect(intent.types.length).assertEqual(1);
      expect(intent.types[0]).assertEqual('wechat');
      expect(intent.linkOnly).assertTrue();
    });

    it('extractMainstreamLinksAndKeepOtherTextForAi', 0, () => {
      const source: string = '会议记录\n百度网盘 https://pan.baidu.com/s/abc123 提取码: A8B9\n' +
        '飞书 https://example.feishu.cn/docx/xyz\n微信 https://mp.weixin.qq.com/s/demo';
      const extracted = LinkRecognitionService.extract(source, ['all']);
      expect(extracted.matches.length).assertEqual(3);
      expect(extracted.matches[0].type).assertEqual('baidu');
      expect(extracted.matches[0].accessCode).assertEqual('A8B9');
      expect(extracted.matches[1].type).assertEqual('feishu');
      expect(extracted.matches[2].type).assertEqual('wechat');
      expect(extracted.remainingText).assertEqual('会议记录');
    });

    it('specificLinkTypeFiltersOtherMainstreamLinks', 0, () => {
      const source: string = 'https://pan.baidu.com/s/baidu\nhttps://docs.qq.com/doc/qq';
      const extracted = LinkRecognitionService.extract(source, ['baidu'], '{{百度网盘链接}}');
      expect(extracted.matches.length).assertEqual(1);
      expect(extracted.matches[0].type).assertEqual('baidu');
      expect(extracted.linksText).assertEqual('https://pan.baidu.com/s/baidu');
      expect(extracted.remainingText).assertEqual('https://docs.qq.com/doc/qq');
    });

    it('extractBareMainstreamLinkWithoutTreatingChatTextAsLink', 0, () => {
      const extracted = LinkRecognitionService.extract(
        '微信聊天记录\n百度网盘 pan.baidu.com/s/bare123 提取码 9Z8Y', ['all']);
      expect(extracted.matches.length).assertEqual(1);
      expect(extracted.matches[0].type).assertEqual('baidu');
      expect(extracted.matches[0].value).assertEqual('pan.baidu.com/s/bare123');
      expect(extracted.matches[0].accessCode).assertEqual('9Z8Y');
      expect(extracted.remainingText).assertEqual('微信聊天记录');
    });
  });
}
