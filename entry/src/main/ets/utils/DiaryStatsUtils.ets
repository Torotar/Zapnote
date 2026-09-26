import { DiaryEntry, DiaryFilter, MoodStat } from '../model/ZapNoteTypes';

export class DiaryStatsUtils {
  static countWords(text: string): number {
    return text.replace(/\s+/g, '').length;
  }

  private static startOfDay(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  private static padMinute(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
  }

  static isToday(dateMs: number): boolean {
    const target: Date = new Date(dateMs);
    const today: Date = new Date();
    return target.getFullYear() === today.getFullYear() &&
      target.getMonth() === today.getMonth() &&
      target.getDate() === today.getDate();
  }

  static isThisWeek(dateMs: number): boolean {
    const target: Date = DiaryStatsUtils.startOfDay(new Date(dateMs));
    const today: Date = DiaryStatsUtils.startOfDay(new Date());
    const day: number = today.getDay() === 0 ? 7 : today.getDay();
    const weekStartMs: number = today.getTime() - (day - 1) * 24 * 60 * 60 * 1000;
    const weekEndMs: number = weekStartMs + 7 * 24 * 60 * 60 * 1000;
    return target.getTime() >= weekStartMs && target.getTime() < weekEndMs;
  }

  static isThisMonth(dateMs: number): boolean {
    const target: Date = new Date(dateMs);
    const today: Date = new Date();
    return target.getFullYear() === today.getFullYear() && target.getMonth() === today.getMonth();
  }

  static formatDateText(dateMs: number): string {
    if (dateMs <= 0) {
      return '';
    }
    const date: Date = new Date(dateMs);
    const timeText: string = date.getHours().toString() + ':' + DiaryStatsUtils.padMinute(date.getMinutes());
    if (DiaryStatsUtils.isToday(dateMs)) {
      return '今天 ' + timeText;
    }
    const yesterday: Date = DiaryStatsUtils.startOfDay(new Date());
    yesterday.setDate(yesterday.getDate() - 1);
    const targetDay: Date = DiaryStatsUtils.startOfDay(date);
    if (targetDay.getTime() === yesterday.getTime()) {
      return '昨天 ' + timeText;
    }
    const currentYear: number = new Date().getFullYear();
    if (date.getFullYear() !== currentYear) {
      return date.getFullYear().toString() + '年' + (date.getMonth() + 1).toString() + '月' +
        date.getDate().toString() + '日 ' + timeText;
    }
    return (date.getMonth() + 1).toString() + '月' + date.getDate().toString() + '日 ' + timeText;
  }

  static formatDateTextLegacy(dateMs: number): string {
    if (dateMs <= 0) {
      return '';
    }
    const date: Date = new Date(dateMs);
    const timeText: string = date.getHours().toString() + ':' + DiaryStatsUtils.padMinute(date.getMinutes());
    if (DiaryStatsUtils.isToday(dateMs)) {
      return '今天 ' + timeText;
    }
    const yesterday: Date = DiaryStatsUtils.startOfDay(new Date());
    yesterday.setDate(yesterday.getDate() - 1);
    const targetDay: Date = DiaryStatsUtils.startOfDay(date);
    if (targetDay.getTime() === yesterday.getTime()) {
      return '昨天 ' + timeText;
    }
    return (date.getMonth() + 1).toString() + '月' + date.getDate().toString() + '日 ' + timeText;
  }

  static activityDateMs(entry: DiaryEntry): number {
    if (typeof entry.updatedAt === 'number' && entry.updatedAt > 0) {
      return entry.updatedAt;
    }
    return typeof entry.dateMs === 'number' ? entry.dateMs : 0;
  }

  static createdDateMs(entry: DiaryEntry): number {
    if (typeof entry.createdAt === 'number' && entry.createdAt > 0) {
      return entry.createdAt;
    }
    return typeof entry.dateMs === 'number' ? entry.dateMs : 0;
  }

  static sortDiariesByLatest(diaries: DiaryEntry[]): DiaryEntry[] {
    return [...diaries].sort((left: DiaryEntry, right: DiaryEntry): number => {
      const leftDate: number = DiaryStatsUtils.activityDateMs(left);
      const rightDate: number = DiaryStatsUtils.activityDateMs(right);
      return rightDate - leftDate;
    });
  }

  static filterDiaries(diaries: DiaryEntry[], filter: DiaryFilter, searchQuery: string): DiaryEntry[] {
    const keyword: string = searchQuery.trim().toLowerCase();
    const filtered: DiaryEntry[] = diaries.filter((entry: DiaryEntry): boolean => {
      const matchesFilter: boolean =
        filter === 'all' ||
        (filter === 'today' && DiaryStatsUtils.isToday(DiaryStatsUtils.activityDateMs(entry))) ||
        (filter === 'week' && DiaryStatsUtils.isThisWeek(DiaryStatsUtils.activityDateMs(entry))) ||
        (filter === 'month' && DiaryStatsUtils.isThisMonth(DiaryStatsUtils.activityDateMs(entry))) ||
        (filter === 'favorite' && entry.isFavorite);
      const matchesSearch: boolean =
        keyword.length === 0 ||
        entry.title.toLowerCase().includes(keyword) ||
        entry.body.toLowerCase().includes(keyword);
      return matchesFilter && matchesSearch;
    });
    return DiaryStatsUtils.sortDiariesByLatest(filtered);
  }

  static totalWords(diaries: DiaryEntry[]): number {
    return diaries.reduce((sum: number, entry: DiaryEntry): number => sum + entry.wordCount, 0);
  }

  static countToday(diaries: DiaryEntry[]): number {
    return diaries.filter((entry: DiaryEntry): boolean => {
      return DiaryStatsUtils.isToday(DiaryStatsUtils.activityDateMs(entry));
    }).length;
  }

  static countFavorites(diaries: DiaryEntry[]): number {
    return diaries.filter((entry: DiaryEntry): boolean => entry.isFavorite).length;
  }

  static countWeather(diaries: DiaryEntry[], weather: string): number {
    const normalizedWeather: string = weather.replace(/\uFE0F/g, '').replace(/\s+/g, '').trim();
    return diaries.filter((entry: DiaryEntry): boolean => {
      const value: string = typeof entry.weather === 'string' ? entry.weather : '';
      return value.replace(/\uFE0F/g, '').replace(/\s+/g, '').trim() === normalizedWeather;
    }).length;
  }

  private static normalizeMoodValue(value: string): string {
    const source: string = typeof value === 'string' ? value : '';
    return source.replace(/\uFE0F/g, '').replace(/\s+/g, '').trim();
  }

  private static moodMatches(value: string, emoji: string, label: string): boolean {
    const normalized: string = DiaryStatsUtils.normalizeMoodValue(value);
    const normalizedLower: string = normalized.toLowerCase();
    const englishAlias: string = label === '开心' ? 'happy' :
      label === '平静' ? 'calm' : label === '疲惫' ? 'tired' : label === '难过' ? 'sad' : 'thinking';
    const normalizedEmoji: string = DiaryStatsUtils.normalizeMoodValue(emoji);
    return normalized.indexOf(normalizedEmoji) >= 0 || normalized.indexOf(label) >= 0 ||
      normalizedLower.indexOf(englishAlias) >= 0;
  }

  static moodStats(diaries: DiaryEntry[], accentColor: string): MoodStat[] {
    const colors: string[] = ['#35C586', accentColor, '#8B5CF6', '#60A5FA', '#F59E0B'];
    const moods: string[] = ['😊', '☺️', '😮‍💨', '😔', '🤔'];
    const labels: string[] = ['开心', '平静', '疲惫', '难过', '思考'];
    const counts: number[] = [];
    moods.forEach((mood: string, index: number): void => {
      counts.push(diaries.filter((entry: DiaryEntry): boolean => {
        return DiaryStatsUtils.moodMatches(entry.mood, mood, labels[index]);
      }).length);
    });
    const total: number = Math.max(counts.reduce((sum: number, count: number): number => sum + count, 0), 1);
    const stats: MoodStat[] = [];
    moods.forEach((mood: string, index: number): void => {
      const count: number = counts[index];
      if (count > 0) {
        stats.push({
          label: labels[index],
          emoji: mood,
          color: colors[index],
          count: count,
          percent: Math.round(count * 100 / total)
        });
      }
    });
    return stats.sort((left: MoodStat, right: MoodStat): number => right.count - left.count);
  }
}
