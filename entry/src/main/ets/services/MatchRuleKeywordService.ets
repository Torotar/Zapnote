export class MatchRuleKeywordService {
  private static uniqueValues(values: string[]): string[] {
    const result: string[] = [];
    values.forEach((item: string): void => {
      const value: string = item.trim();
      if (value.length > 0 && result.indexOf(value) < 0) {
        result.push(value);
      }
    });
    return result;
  }

  static splitPlain(value: string): string[] {
    return MatchRuleKeywordService.uniqueValues(
      value.split(/[,，、;；|\r\n\t\u2028\u2029]+/)
    );
  }

  static splitRegex(value: string): string[] {
    return MatchRuleKeywordService.uniqueValues(
      value.split(/[\r\n\u2028\u2029]+/)
    );
  }
}
