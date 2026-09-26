export class ZapNoteTheme {
  static isDark(themeMode: string): boolean {
    return themeMode === 'dark';
  }

  static pageBg(themeMode: string): string {
    if (ZapNoteTheme.isDark(themeMode)) {
      return '#0B1020';
    }
    return '#F8FAFC';
  }

  static cardBg(themeMode: string): string {
    if (ZapNoteTheme.isDark(themeMode)) {
      return '#121A2C';
    }
    return '#FFFFFF';
  }

  static inputBg(themeMode: string): string {
    if (ZapNoteTheme.isDark(themeMode)) {
      return '#1D2638';
    }
    return '#F1F5F9';
  }

  static lineColor(themeMode: string): string {
    if (ZapNoteTheme.isDark(themeMode)) {
      return '#293449';
    }
    return '#E2E8F0';
  }

  static textPrimary(themeMode: string): string {
    return ZapNoteTheme.isDark(themeMode) ? '#F8FAFC' : '#0F172A';
  }

  static textSecondary(themeMode: string): string {
    return ZapNoteTheme.isDark(themeMode) ? '#CBD5E1' : '#475569';
  }

  static textTertiary(themeMode: string): string {
    return ZapNoteTheme.isDark(themeMode) ? '#77849A' : '#94A3B8';
  }
}
