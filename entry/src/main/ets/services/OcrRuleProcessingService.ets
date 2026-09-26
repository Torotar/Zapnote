import {
  MatchRuleTemplateItem
} from '../model/ZapNoteTypes';
import {
  OcrTextBlockResult,
  OcrTextLineResult,
  OcrTextPointResult,
  OcrTextRecognitionResult,
  OcrTextRecognitionService,
  OcrTextWordResult
} from './OcrTextRecognitionService';
import { MatchRuleKeywordService } from './MatchRuleKeywordService';

export interface OcrRuleProcessingResult {
  originalText: string;
  processedText: string;
  suggestedTitle?: string;
  activeRuleCount: number;
  matchedRuleCount: number;
  summaries: string[];
  changed: boolean;
  processingMode?: string;
  statusMessage?: string;
}

interface OcrBounds {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

interface OcrRawLine {
  blockIndex: number;
  lineIndex: number;
  text: string;
  left: number;
  top: number;
  right: number;
  bottom: number;
  hasGeometry: boolean;
}

interface OcrVisualSegment {
  text: string;
  left: number;
  right: number;
  top: number;
  bottom: number;
  hasGeometry: boolean;
}

interface OcrVisualRow {
  top: number;
  bottom: number;
  segments: OcrVisualSegment[];
  blockIndexes: number[];
  hasGeometry: boolean;
}

interface OcrExtractedText {
  text: string;
  left: number;
  sequence: number;
}

interface OcrSemanticTarget {
  stateIndex: number;
  content: string;
}

interface OcrRuleLineState {
  blockIndexes: number[];
  originalText: string;
  text: string;
  included: boolean;
  segments: OcrVisualSegment[];
  top: number;
  bottom: number;
  hasGeometry: boolean;
  extractedTexts: OcrExtractedText[];
}

export class OcrRuleProcessingService {
  private static semanticPattern(keyword: string): string {
    const normalized: string = keyword.trim();
    if (normalized === '磁力链接') {
      return 'm\\s*a\\s*g\\s*n\\s*e\\s*t\\s*:\\s*\\?\\s*x\\s*t\\s*=\\s*u\\s*r\\s*n\\s*:\\s*b\\s*t\\s*i\\s*h\\s*:' +
        '(?:[A-F0-9](?:\\s*[A-F0-9]){39}|[A-Z2-7](?:\\s*[A-Z2-7]){31})' +
        '(?:&[^\\s"\\\'<>，。]*)?';
    }
    if (normalized === '番号') {
      const separator: string = '[-‐‑‒–—－_\\s]*';
      const letters: string = '[A-Z](?:\\s*[A-Z]){1,9}';
      const digits: string = '\\d(?:\\s*\\d){1,7}';
      return '(?:FC2' + separator + 'PPV' + separator + digits + '|' + letters +
        separator + digits + ')';
    }
    return '';
  }

  private static isSemanticRule(item: MatchRuleTemplateItem): boolean {
    return OcrRuleProcessingService.semanticPattern(item.keyword).length > 0;
  }

  private static isPhotoRule(item: MatchRuleTemplateItem): boolean {
    return item.scopes.indexOf('照片分析') >= 0 || item.scopes.indexOf('照片分享') >= 0;
  }

  private static activeRules(items: MatchRuleTemplateItem[]): MatchRuleTemplateItem[] {
    const result: MatchRuleTemplateItem[] = [];
    items.forEach((item: MatchRuleTemplateItem): void => {
      if (item.kind === 'ai-output' || !item.enabled || item.keyword.trim().length === 0 ||
        !OcrRuleProcessingService.isPhotoRule(item)) {
        return;
      }
      const keywords: string[] = item.matchMode === 'regex' ?
        MatchRuleKeywordService.splitRegex(item.keyword) : MatchRuleKeywordService.splitPlain(item.keyword);
      keywords.forEach((keyword: string, index: number): void => {
        result.push({
          id: item.id + '-runtime-' + index.toString(),
          kind: 'keyword',
          aiConfigId: '',
          scopes: item.scopes,
          keyword: keyword,
          template: item.template,
          enabled: item.enabled,
          action: item.action,
          range: item.range,
          matchMode: item.matchMode,
          linkType: item.linkType
        });
      });
    });
    return result;
  }

  private static fallbackBlocks(text: string): OcrTextBlockResult[] {
    const blocks: OcrTextBlockResult[] = [];
    text.split(/\n\s*\n/).forEach((blockText: string): void => {
      const lines: OcrTextLineResult[] = [];
      blockText.split(/\r?\n/).forEach((lineText: string): void => {
        const value: string = lineText.trim();
        if (value.length > 0) {
          lines.push({ text: value, words: [], cornerPoints: [] });
        }
      });
      if (lines.length > 0) {
        blocks.push({ text: blockText.trim(), lines: lines });
      }
    });
    return blocks;
  }

  private static boundsFromPoints(points: OcrTextPointResult[]): OcrBounds | null {
    if (points.length === 0) {
      return null;
    }
    let left: number = points[0].x;
    let right: number = points[0].x;
    let top: number = points[0].y;
    let bottom: number = points[0].y;
    points.forEach((point: OcrTextPointResult): void => {
      left = Math.min(left, point.x);
      right = Math.max(right, point.x);
      top = Math.min(top, point.y);
      bottom = Math.max(bottom, point.y);
    });
    return {
      left: left,
      top: top,
      right: right,
      bottom: bottom
    };
  }

  private static boundsFromWords(words: OcrTextWordResult[]): OcrBounds | null {
    let result: OcrBounds | null = null;
    words.forEach((word: OcrTextWordResult): void => {
      const wordBounds: OcrBounds | null =
        OcrRuleProcessingService.boundsFromPoints(word.cornerPoints);
      if (wordBounds === null) {
        return;
      }
      if (result === null) {
        result = wordBounds;
        return;
      }
      result.left = Math.min(result.left, wordBounds.left);
      result.top = Math.min(result.top, wordBounds.top);
      result.right = Math.max(result.right, wordBounds.right);
      result.bottom = Math.max(result.bottom, wordBounds.bottom);
    });
    return result;
  }

  private static lineBounds(line: OcrTextLineResult): OcrBounds | null {
    const wordBounds: OcrBounds | null = OcrRuleProcessingService.boundsFromWords(line.words);
    return wordBounds === null ?
      OcrRuleProcessingService.boundsFromPoints(line.cornerPoints) : wordBounds;
  }

  private static createRawLines(result: OcrTextRecognitionResult): OcrRawLine[] {
    const rawLines: OcrRawLine[] = [];
    const blocks: OcrTextBlockResult[] = result.blocks.length > 0 ?
      result.blocks : OcrRuleProcessingService.fallbackBlocks(result.text);
    blocks.forEach((block: OcrTextBlockResult, blockIndex: number): void => {
      if (block.lines.length === 0 && block.text.trim().length > 0) {
        rawLines.push({
          blockIndex: blockIndex,
          lineIndex: 0,
          text: block.text.trim(),
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          hasGeometry: false
        });
        return;
      }
      block.lines.forEach((line: OcrTextLineResult, lineIndex: number): void => {
        const value: string = line.text.trim();
        if (value.length === 0) {
          return;
        }
        const bounds: OcrBounds | null = OcrRuleProcessingService.lineBounds(line);
        rawLines.push({
          blockIndex: blockIndex,
          lineIndex: lineIndex,
          text: value,
          left: bounds === null ? 0 : bounds.left,
          top: bounds === null ? 0 : bounds.top,
          right: bounds === null ? 0 : bounds.right,
          bottom: bounds === null ? 0 : bounds.bottom,
          hasGeometry: bounds !== null
        });
      });
    });
    return rawLines;
  }

  private static sameVisualRow(row: OcrVisualRow, line: OcrRawLine): boolean {
    if (!row.hasGeometry || !line.hasGeometry) {
      return false;
    }
    const overlap: number = Math.min(row.bottom, line.bottom) - Math.max(row.top, line.top);
    const rowHeight: number = Math.max(row.bottom - row.top, 1);
    const lineHeight: number = Math.max(line.bottom - line.top, 1);
    const overlapRatio: number = overlap / Math.min(rowHeight, lineHeight);
    if (overlapRatio >= 0.45) {
      return true;
    }
    const rowCenter: number = (row.top + row.bottom) / 2;
    const lineCenter: number = (line.top + line.bottom) / 2;
    return Math.abs(rowCenter - lineCenter) <= Math.max(rowHeight, lineHeight) * 0.65;
  }

  private static addBlockIndex(indexes: number[], blockIndex: number): void {
    if (indexes.indexOf(blockIndex) < 0) {
      indexes.push(blockIndex);
    }
  }

  private static addLineToRow(row: OcrVisualRow, line: OcrRawLine): void {
    row.top = Math.min(row.top, line.top);
    row.bottom = Math.max(row.bottom, line.bottom);
    row.segments.push({
      text: line.text,
      left: line.left,
      right: line.right,
      top: line.top,
      bottom: line.bottom,
      hasGeometry: line.hasGeometry
    });
    OcrRuleProcessingService.addBlockIndex(row.blockIndexes, line.blockIndex);
  }

  private static createVisualRows(rawLines: OcrRawLine[]): OcrVisualRow[] {
    rawLines.sort((first: OcrRawLine, second: OcrRawLine): number => {
      if (first.hasGeometry && second.hasGeometry) {
        const topDifference: number = first.top - second.top;
        return Math.abs(topDifference) > 2 ? topDifference : first.left - second.left;
      }
      if (first.hasGeometry !== second.hasGeometry) {
        return first.hasGeometry ? -1 : 1;
      }
      if (first.blockIndex !== second.blockIndex) {
        return first.blockIndex - second.blockIndex;
      }
      return first.lineIndex - second.lineIndex;
    });

    const rows: OcrVisualRow[] = [];
    rawLines.forEach((line: OcrRawLine): void => {
      let targetIndex: number = -1;
      for (let index: number = rows.length - 1; index >= 0; index--) {
        if (OcrRuleProcessingService.sameVisualRow(rows[index], line)) {
          targetIndex = index;
          break;
        }
        if (line.hasGeometry && rows[index].hasGeometry && line.top - rows[index].bottom > 80) {
          break;
        }
      }
      if (targetIndex < 0) {
        rows.push({
          top: line.top,
          bottom: line.bottom,
          segments: [{
            text: line.text,
            left: line.left,
            right: line.right,
            top: line.top,
            bottom: line.bottom,
            hasGeometry: line.hasGeometry
          }],
          blockIndexes: [line.blockIndex],
          hasGeometry: line.hasGeometry
        });
        return;
      }
      OcrRuleProcessingService.addLineToRow(rows[targetIndex], line);
    });
    rows.forEach((row: OcrVisualRow): void => {
      row.segments.sort((first: OcrVisualSegment, second: OcrVisualSegment): number => first.left - second.left);
    });
    return rows;
  }

  private static rowText(segments: OcrVisualSegment[]): string {
    const values: string[] = [];
    segments.forEach((segment: OcrVisualSegment): void => {
      const value: string = OcrRuleProcessingService.cleanValueSegment(segment.text);
      if (!OcrRuleProcessingService.isAccessorySegment(value) && values.indexOf(value) < 0) {
        values.push(value);
      }
    });
    return values.join(' ').trim();
  }

  private static createLineStates(result: OcrTextRecognitionResult, includeByDefault: boolean): OcrRuleLineState[] {
    const states: OcrRuleLineState[] = [];
    const rows: OcrVisualRow[] =
      OcrRuleProcessingService.createVisualRows(OcrRuleProcessingService.createRawLines(result));
    rows.forEach((row: OcrVisualRow): void => {
      const text: string = OcrRuleProcessingService.rowText(row.segments);
      if (text.length > 0) {
        states.push({
          blockIndexes: row.blockIndexes,
          originalText: text,
          text: text,
          included: includeByDefault,
          segments: row.segments,
          top: row.top,
          bottom: row.bottom,
          hasGeometry: row.hasGeometry,
          extractedTexts: []
        });
      }
    });
    return states;
  }

  private static numberMatches(text: string): string[] {
    const values: string[] = [];
    const pattern: string = OcrRuleProcessingService.semanticPattern('番号');
    const expression: RegExp = new RegExp(pattern, 'gi');
    let match: RegExpExecArray | null = expression.exec(text);
    while (match !== null) {
      const value: string = match[0];
      const start: number = match.index;
      const end: number = start + value.length;
      const previous: string = start > 0 ? text.charAt(start - 1) : '';
      const next: string = end < text.length ? text.charAt(end) : '';
      const compactValue: string = value.toUpperCase().replace(/[-‐‑‒–—－_\s]/g, '');
      const normalizedValue: string = value.replace(/\s+/g, '');
      const isChatLevel: boolean = /^LV\d+$/.test(compactValue);
      if (!isChatLevel && !/[A-Z0-9]/i.test(previous) && !/[A-Z0-9]/i.test(next) &&
        values.indexOf(normalizedValue) < 0) {
        values.push(normalizedValue);
      }
      if (value.length === 0) {
        expression.lastIndex++;
      }
      match = expression.exec(text);
    }
    return values;
  }

  private static matches(text: string, item: MatchRuleTemplateItem): boolean {
    if (item.keyword.trim() === '番号') {
      return OcrRuleProcessingService.numberMatches(text).length > 0;
    }
    try {
      const semanticPattern: string = OcrRuleProcessingService.semanticPattern(item.keyword);
      const pattern: string = semanticPattern.length > 0 ? semanticPattern :
        (item.matchMode === 'regex' ? item.keyword : OcrRuleProcessingService.regexEscape(item.keyword));
      return new RegExp(pattern, 'i').test(text);
    } catch (error) {
      console.error('OcrRuleProcessingService invalid match pattern: ' + item.keyword);
      return false;
    }
  }

  private static matchingLineIndexes(
    states: OcrRuleLineState[],
    item: MatchRuleTemplateItem
  ): number[] {
    const result: number[] = [];
    states.forEach((state: OcrRuleLineState, index: number): void => {
      if (OcrRuleProcessingService.matches(state.originalText, item)) {
        result.push(index);
      }
    });
    return result;
  }

  private static sharesBlock(state: OcrRuleLineState, blockIndexes: number[]): boolean {
    let shares: boolean = false;
    blockIndexes.forEach((blockIndex: number): void => {
      if (state.blockIndexes.indexOf(blockIndex) >= 0) {
        shares = true;
      }
    });
    return shares;
  }

  private static markBlocks(
    states: OcrRuleLineState[],
    blockIndexes: number[],
    included: boolean
  ): void {
    states.forEach((state: OcrRuleLineState): void => {
      if (OcrRuleProcessingService.sharesBlock(state, blockIndexes)) {
        state.included = included;
      }
    });
  }

  private static applyTemplate(template: string, content: string): string {
    const normalized: string = template.trim();
    if (normalized.length === 0) {
      return content;
    }
    if (normalized.indexOf('{{内容}}') >= 0) {
      return normalized.split('{{内容}}').join(content);
    }
    if (normalized.indexOf('{{content}}') >= 0) {
      return normalized.split('{{content}}').join(content);
    }
    return content;
  }

  private static appendExtractedText(state: OcrRuleLineState, value: string, left: number): void {
    const normalized: string = value.trim();
    if (normalized.length === 0) {
      if (state.extractedTexts.length === 0) {
        state.text = '';
      }
      return;
    }
    let duplicated: boolean = false;
    state.extractedTexts.forEach((item: OcrExtractedText): void => {
      if (item.text === normalized) {
        duplicated = true;
      }
    });
    if (duplicated) {
      return;
    }
    state.extractedTexts.push({
      text: normalized,
      left: left,
      sequence: state.extractedTexts.length
    });
    state.extractedTexts.sort((first: OcrExtractedText, second: OcrExtractedText): number => {
      if (first.left >= 0 && second.left >= 0 && Math.abs(first.left - second.left) > 0.5) {
        return first.left - second.left;
      }
      return first.sequence - second.sequence;
    });
    const values: string[] = [];
    state.extractedTexts.forEach((item: OcrExtractedText): void => {
      values.push(item.text);
    });
    state.text = values.join('\n');
  }

  private static matchedLeft(state: OcrRuleLineState, item: MatchRuleTemplateItem): number {
    if (item.keyword.trim() === '番号') {
      let numberLeft: number = -1;
      state.segments.forEach((segment: OcrVisualSegment): void => {
        if (numberLeft < 0 && segment.hasGeometry &&
          OcrRuleProcessingService.numberMatches(segment.text).length > 0) {
          numberLeft = segment.left;
        }
      });
      return numberLeft;
    }
    let expression: RegExp;
    try {
      const semanticPattern: string = OcrRuleProcessingService.semanticPattern(item.keyword);
      const pattern: string = semanticPattern.length > 0 ? semanticPattern :
        (item.matchMode === 'regex' ? item.keyword : OcrRuleProcessingService.regexEscape(item.keyword));
      expression = new RegExp(pattern, 'i');
    } catch (error) {
      return -1;
    }
    let matchedLeft: number = -1;
    state.segments.forEach((segment: OcrVisualSegment): void => {
      if (matchedLeft >= 0 || !segment.hasGeometry) {
        return;
      }
      if (expression.test(segment.text)) {
        matchedLeft = segment.left;
      }
    });
    if (matchedLeft >= 0 || item.keyword.trim() !== '磁力链接') {
      return matchedLeft;
    }
    state.segments.forEach((segment: OcrVisualSegment): void => {
      if (matchedLeft < 0 && segment.hasGeometry &&
        OcrRuleProcessingService.containsMagnetStart(segment.text)) {
        matchedLeft = segment.left;
      }
    });
    return matchedLeft;
  }

  private static reconstructedMagnetTargets(
    result: OcrTextRecognitionResult,
    states: OcrRuleLineState[],
    item: MatchRuleTemplateItem
  ): OcrSemanticTarget[] {
    const targets: OcrSemanticTarget[] = [];
    if (item.keyword.trim() !== '磁力链接') {
      return targets;
    }
    const links: string[] = OcrTextRecognitionService.extractMagnetLinks(result.text);
    const stateIndexes: number[] = OcrRuleProcessingService.magnetPrefixStateIndexes(states);
    if (links.length === 0 || stateIndexes.length === 0) {
      return targets;
    }
    links.forEach((link: string, index: number): void => {
      targets.push({
        stateIndex: stateIndexes[Math.min(index, stateIndexes.length - 1)],
        content: link
      });
    });
    return targets;
  }

  private static containsMagnetStart(text: string): boolean {
    return /magnet\s*:\s*\?\s*xt\s*=\s*urn\s*:/i.test(text);
  }

  private static magnetPrefixStateIndexes(states: OcrRuleLineState[]): number[] {
    const result: number[] = [];
    states.forEach((state: OcrRuleLineState, index: number): void => {
      let segmentMatchCount: number = 0;
      state.segments.forEach((segment: OcrVisualSegment): void => {
        if (OcrRuleProcessingService.containsMagnetStart(segment.text)) {
          result.push(index);
          segmentMatchCount++;
        }
      });
      if (segmentMatchCount === 0 && OcrRuleProcessingService.containsMagnetStart(state.originalText)) {
        result.push(index);
      }
    });
    return result;
  }

  private static stripLeadingSeparators(value: string): string {
    let result: string = value.trim();
    while (result.length > 0 && ':：=|-—'.indexOf(result.charAt(0)) >= 0) {
      result = result.substring(1).trim();
    }
    return result;
  }

  private static stripTrailingIndicators(value: string): string {
    let result: string = value.trim();
    while (result.length > 0 && '>›»〉'.indexOf(result.charAt(result.length - 1)) >= 0) {
      result = result.substring(0, result.length - 1).trim();
    }
    return result;
  }

  private static isAccessorySegment(value: string): boolean {
    const normalized: string = OcrRuleProcessingService.stripTrailingIndicators(value);
    return normalized === '复制' || normalized === '查看' || normalized === '详情' ||
      normalized === '更多' || normalized === '编辑' || normalized === '删除' ||
      normalized.length === 0;
  }

  private static cleanValueSegment(value: string): string {
    let result: string = OcrRuleProcessingService.stripTrailingIndicators(value);
    const accessoryLabels: string[] = ['复制', '查看', '详情', '更多', '编辑', '删除'];
    accessoryLabels.forEach((label: string): void => {
      const suffixes: string[] = ['| ' + label, '|' + label, '｜ ' + label, '｜' + label];
      suffixes.forEach((suffix: string): void => {
        if (result.endsWith(suffix)) {
          result = result.substring(0, result.length - suffix.length).trim();
        }
      });
    });
    return result;
  }

  private static alignedSegmentScore(reference: OcrVisualSegment, candidate: OcrVisualSegment): number {
    if (!reference.hasGeometry || !candidate.hasGeometry) {
      return -1;
    }
    const referenceHeight: number = Math.max(reference.bottom - reference.top, 1);
    const candidateHeight: number = Math.max(candidate.bottom - candidate.top, 1);
    const overlap: number = Math.min(reference.bottom, candidate.bottom) -
      Math.max(reference.top, candidate.top);
    const referenceCenter: number = (reference.top + reference.bottom) / 2;
    const candidateCenter: number = (candidate.top + candidate.bottom) / 2;
    const verticalDistance: number = Math.abs(referenceCenter - candidateCenter);
    if (overlap <= 0 && verticalDistance > Math.max(referenceHeight, candidateHeight) * 0.8) {
      return -1;
    }
    if (overlap > 0 && overlap / Math.min(referenceHeight, candidateHeight) < 0.2) {
      return -1;
    }
    const referenceCenterX: number = (reference.left + reference.right) / 2;
    const candidateCenterX: number = (candidate.left + candidate.right) / 2;
    if (candidateCenterX <= referenceCenterX) {
      return -1;
    }
    const horizontalDistance: number = Math.max(candidate.left - reference.right, 0);
    return verticalDistance * 10 + horizontalDistance;
  }

  private static bestRightContent(
    reference: OcrVisualSegment,
    candidates: OcrVisualSegment[]
  ): string {
    let bestValue: string = '';
    let bestScore: number = Number.MAX_VALUE;
    candidates.forEach((candidate: OcrVisualSegment): void => {
      const value: string = OcrRuleProcessingService.cleanValueSegment(candidate.text);
      if (OcrRuleProcessingService.isAccessorySegment(value)) {
        return;
      }
      if (!reference.hasGeometry || !candidate.hasGeometry) {
        if (bestValue.length === 0) {
          bestValue = value;
        }
        return;
      }
      const score: number = OcrRuleProcessingService.alignedSegmentScore(reference, candidate);
      if (score >= 0 && score < bestScore) {
        bestScore = score;
        bestValue = value;
      }
    });
    return bestValue;
  }

  private static contentFromMatchedRow(state: OcrRuleLineState, item: MatchRuleTemplateItem): string {
    const keyword: string = item.keyword.toLowerCase();
    let matchedSegmentIndex: number = -1;
    let trailingValue: string = '';
    state.segments.forEach((segment: OcrVisualSegment, index: number): void => {
      if (matchedSegmentIndex >= 0) {
        return;
      }
      const segmentText: string = segment.text.trim();
      const matchIndex: number = segmentText.toLowerCase().indexOf(keyword);
      if (matchIndex < 0) {
        return;
      }
      matchedSegmentIndex = index;
      const trailing: string = OcrRuleProcessingService.cleanValueSegment(
        OcrRuleProcessingService.stripLeadingSeparators(
          segmentText.substring(matchIndex + item.keyword.length)
        )
      );
      if (trailing.length > 0) {
        trailingValue = trailing;
      }
    });
    if (trailingValue.length > 0) {
      return trailingValue;
    }
    if (matchedSegmentIndex >= 0) {
      return OcrRuleProcessingService.bestRightContent(
        state.segments[matchedSegmentIndex],
        state.segments.slice(matchedSegmentIndex + 1)
      );
    }
    return '';
  }

  private static matchedSegment(state: OcrRuleLineState, item: MatchRuleTemplateItem): OcrVisualSegment | null {
    const keyword: string = item.keyword.toLowerCase();
    let result: OcrVisualSegment | null = null;
    state.segments.forEach((segment: OcrVisualSegment): void => {
      if (result === null && segment.text.toLowerCase().indexOf(keyword) >= 0) {
        result = segment;
      }
    });
    return result;
  }

  private static nearbyRightContent(
    states: OcrRuleLineState[],
    stateIndex: number,
    item: MatchRuleTemplateItem
  ): string {
    const matchedSegment: OcrVisualSegment | null =
      OcrRuleProcessingService.matchedSegment(states[stateIndex], item);
    if (matchedSegment === null || !matchedSegment.hasGeometry) {
      return '';
    }
    const candidates: OcrVisualSegment[] = [];
    states.forEach((candidateState: OcrRuleLineState, candidateStateIndex: number): void => {
      if (candidateStateIndex === stateIndex || !candidateState.hasGeometry) {
        return;
      }
      candidateState.segments.forEach((candidate: OcrVisualSegment): void => {
        candidates.push(candidate);
      });
    });
    return OcrRuleProcessingService.bestRightContent(matchedSegment, candidates);
  }

  private static associatedContent(
    states: OcrRuleLineState[],
    stateIndex: number,
    item: MatchRuleTemplateItem
  ): string {
    const rowContent: string =
      OcrRuleProcessingService.contentFromMatchedRow(states[stateIndex], item);
    return rowContent.length > 0 ? rowContent :
      OcrRuleProcessingService.nearbyRightContent(states, stateIndex, item);
  }

  private static visualLineContent(
    states: OcrRuleLineState[],
    stateIndex: number,
    item: MatchRuleTemplateItem
  ): string {
    const state: OcrRuleLineState = states[stateIndex];
    if (item.matchMode === 'regex') {
      return state.originalText;
    }
    if (OcrRuleProcessingService.isSemanticRule(item)) {
      return OcrRuleProcessingService.matchedContent(states, stateIndex, item);
    }
    const content: string = OcrRuleProcessingService.associatedContent(states, stateIndex, item);
    return content.length > 0 ? item.keyword + ' ' + content : state.originalText;
  }

  private static matchedContent(
    states: OcrRuleLineState[],
    stateIndex: number,
    item: MatchRuleTemplateItem
  ): string {
    const state: OcrRuleLineState = states[stateIndex];
    if (item.keyword.trim() === '番号') {
      return OcrRuleProcessingService.numberMatches(state.originalText).join('\n');
    }
    if (item.matchMode === 'regex' || OcrRuleProcessingService.isSemanticRule(item)) {
      try {
        const semanticPattern: string = OcrRuleProcessingService.semanticPattern(item.keyword);
        const pattern: string = semanticPattern.length > 0 ? semanticPattern : item.keyword;
        const matches: RegExpMatchArray | null = state.originalText.match(new RegExp(pattern, 'gi'));
        return matches === null ? '' : matches.join('\n');
      } catch (error) {
        return '';
      }
    }
    return OcrRuleProcessingService.associatedContent(states, stateIndex, item);
  }

  private static regexEscape(value: string): string {
    const symbols: string = '\\^$.*+?()[]{}|';
    let result: string = '';
    for (let index: number = 0; index < value.length; index++) {
      const character: string = value.charAt(index);
      result += symbols.indexOf(character) >= 0 ? '\\' + character : character;
    }
    return result;
  }

  private static replaceMatch(text: string, item: MatchRuleTemplateItem, replacement: string): string {
    try {
      const semanticPattern: string = OcrRuleProcessingService.semanticPattern(item.keyword);
      const pattern: string = semanticPattern.length > 0 ? semanticPattern :
        (item.matchMode === 'regex' ? item.keyword : OcrRuleProcessingService.regexEscape(item.keyword));
      const expression: RegExp = new RegExp(pattern, 'gi');
      return text.replace(expression, replacement);
    } catch (error) {
      console.error('OcrRuleProcessingService replace failed: ' + item.keyword);
      return text;
    }
  }

  private static maskMatch(text: string, item: MatchRuleTemplateItem): string {
    const replacement: string = item.template.trim().length > 0 ? item.template.trim() : '****';
    return OcrRuleProcessingService.replaceMatch(text, item, replacement);
  }

  private static actionLabel(item: MatchRuleTemplateItem): string {
    if (item.action === 'exclude') {
      return '排除';
    }
    if (item.action === 'mask') {
      return '屏蔽';
    }
    return '选取';
  }

  private static addSummary(summaries: string[], item: MatchRuleTemplateItem): void {
    summaries.push(OcrRuleProcessingService.actionLabel(item) + '“' + item.keyword + '”');
  }

  private static buildText(states: OcrRuleLineState[]): string {
    const lines: string[] = [];
    states.forEach((state: OcrRuleLineState): void => {
      if (state.included && state.text.trim().length > 0) {
        lines.push(state.text.trim());
      }
    });
    return lines.join('\n').trim();
  }

  private static maskBlocks(
    states: OcrRuleLineState[],
    blockIndexes: number[],
    replacement: string
  ): void {
    let replacementPlaced: boolean = false;
    states.forEach((state: OcrRuleLineState): void => {
      if (!state.included || !OcrRuleProcessingService.sharesBlock(state, blockIndexes)) {
        return;
      }
      if (!replacementPlaced) {
        state.text = replacement;
        replacementPlaced = true;
      } else {
        state.included = false;
      }
    });
  }

  static process(
    result: OcrTextRecognitionResult,
    items: MatchRuleTemplateItem[]
  ): OcrRuleProcessingResult {
    const originalText: string = result.text.trim();
    const rules: MatchRuleTemplateItem[] = OcrRuleProcessingService.activeRules(items);
    let hasExtractRule: boolean = false;
    rules.forEach((item: MatchRuleTemplateItem): void => {
      if (item.action === 'extract') {
        hasExtractRule = true;
      }
    });
    const states: OcrRuleLineState[] =
      OcrRuleProcessingService.createLineStates(result, !hasExtractRule);
    const summaries: string[] = [];
    let matchedRuleCount: number = 0;

    rules.forEach((item: MatchRuleTemplateItem): void => {
      if (item.action !== 'extract') {
        return;
      }
      const magnetTargets: OcrSemanticTarget[] =
        OcrRuleProcessingService.reconstructedMagnetTargets(result, states, item);
      if (magnetTargets.length > 0) {
        matchedRuleCount++;
        OcrRuleProcessingService.addSummary(summaries, item);
        magnetTargets.forEach((target: OcrSemanticTarget): void => {
          const state: OcrRuleLineState = states[target.stateIndex];
          state.included = true;
          OcrRuleProcessingService.appendExtractedText(
            state,
            OcrRuleProcessingService.applyTemplate(item.template, target.content),
            OcrRuleProcessingService.matchedLeft(state, item)
          );
        });
        return;
      }
      const indexes: number[] = OcrRuleProcessingService.matchingLineIndexes(states, item);
      if (indexes.length === 0) {
        return;
      }
      matchedRuleCount++;
      OcrRuleProcessingService.addSummary(summaries, item);
      indexes.forEach((stateIndex: number): void => {
        const state: OcrRuleLineState = states[stateIndex];
        if (OcrRuleProcessingService.isSemanticRule(item)) {
          const content: string = OcrRuleProcessingService.matchedContent(states, stateIndex, item);
          state.included = true;
          OcrRuleProcessingService.appendExtractedText(
            state,
            OcrRuleProcessingService.applyTemplate(item.template, content),
            OcrRuleProcessingService.matchedLeft(state, item)
          );
        } else if (item.range === 'block') {
          OcrRuleProcessingService.markBlocks(states, state.blockIndexes, true);
        } else if (item.range === 'match') {
          state.included = true;
          OcrRuleProcessingService.appendExtractedText(
            state,
            OcrRuleProcessingService.applyTemplate(
              item.template,
              OcrRuleProcessingService.matchedContent(states, stateIndex, item)
            ),
            OcrRuleProcessingService.matchedLeft(state, item)
          );
        } else {
          state.included = true;
          OcrRuleProcessingService.appendExtractedText(
            state,
            OcrRuleProcessingService.applyTemplate(
              item.template,
              OcrRuleProcessingService.visualLineContent(states, stateIndex, item)
            ),
            OcrRuleProcessingService.matchedLeft(state, item)
          );
        }
      });
    });

    rules.forEach((item: MatchRuleTemplateItem): void => {
      if (item.action !== 'exclude') {
        return;
      }
      const indexes: number[] = OcrRuleProcessingService.matchingLineIndexes(states, item);
      if (indexes.length === 0) {
        return;
      }
      matchedRuleCount++;
      OcrRuleProcessingService.addSummary(summaries, item);
      indexes.forEach((stateIndex: number): void => {
        const state: OcrRuleLineState = states[stateIndex];
        if (item.range === 'block') {
          OcrRuleProcessingService.markBlocks(states, state.blockIndexes, false);
        } else if (item.range === 'match') {
          state.text = OcrRuleProcessingService.replaceMatch(state.text, item, '');
        } else {
          state.included = false;
        }
      });
    });

    rules.forEach((item: MatchRuleTemplateItem): void => {
      if (item.action !== 'mask') {
        return;
      }
      const indexes: number[] = OcrRuleProcessingService.matchingLineIndexes(states, item);
      if (indexes.length === 0) {
        return;
      }
      matchedRuleCount++;
      OcrRuleProcessingService.addSummary(summaries, item);
      indexes.forEach((stateIndex: number): void => {
        const state: OcrRuleLineState = states[stateIndex];
        if (!state.included) {
          return;
        }
        const replacement: string = item.template.trim().length > 0 ? item.template.trim() : '****';
        if (item.range === 'block') {
          OcrRuleProcessingService.maskBlocks(states, state.blockIndexes, replacement);
        } else if (item.range === 'line') {
          state.text = replacement;
        } else {
          state.text = OcrRuleProcessingService.maskMatch(state.text, item);
        }
      });
    });

    const processedText: string = rules.length === 0 ?
      originalText : OcrRuleProcessingService.buildText(states);
    return {
      originalText: originalText,
      processedText: processedText,
      activeRuleCount: rules.length,
      matchedRuleCount: matchedRuleCount,
      summaries: summaries,
      changed: processedText !== originalText,
      processingMode: 'rules',
      statusMessage: ''
    };
  }
}
