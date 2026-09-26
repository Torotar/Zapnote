import { HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { createHdsTabTitleBarOptions } from '../components/HdsTabTitleBarOptions';
import { ZapStatCard } from '../components/ZapStatCard';
import { WEATHER_OPTIONS } from '../data/ZapNoteSeedData';
import { DiaryEntry, MoodStat, ValueOption } from '../model/ZapNoteTypes';
import { DiaryStatsUtils } from '../utils/DiaryStatsUtils';

interface TimePeriodStat {
  label: string;
  icon: string;
  count: number;
  percent: number;
  isTop: boolean;
}

interface WeatherStat {
  label: string;
  emoji: string;
  count: number;
  percent: number;
}

interface HeatDayStat {
  key: string;
  count: number;
  height: number;
}

@Component
export struct StatsPage {
  @Prop diaries: DiaryEntry[] = [];
  @Prop materialEffectMode: number = 3;
  @Prop topPadding: number = 132;
  @Prop bottomPadding: number = 154;
  @Prop isDark: boolean = false;
  @Prop pageBg: string = '#F8FAFC';
  @Prop accentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';

  private scroller: Scroller = new Scroller();

  private diaryCountIcon(): Resource {
    return $rawfile('icons/book_open.svg');
  }

  private diaryCountDarkIcon(): Resource {
    return $rawfile('icons/book_open_dark.svg');
  }

  private wordCountIcon(): Resource {
    return $rawfile('icons/type.svg');
  }

  private wordCountDarkIcon(): Resource {
    return $rawfile('icons/type_dark.svg');
  }

  private streakIcon(): Resource {
    return $rawfile('icons/flame.svg');
  }

  private streakDarkIcon(): Resource {
    return $rawfile('icons/flame_dark.svg');
  }

  private calendarIcon(): Resource {
    return $rawfile('icons/stat_calendar.svg');
  }

  private calendarDarkIcon(): Resource {
    return $rawfile('icons/stat_calendar_dark.svg');
  }

  private todayCount(): number {
    return DiaryStatsUtils.countToday(this.diaries);
  }

  private totalWords(): number {
    return DiaryStatsUtils.totalWords(this.diaries);
  }

  private recentDayStats(): HeatDayStat[] {
    const dayMs: number = 24 * 60 * 60 * 1000;
    const now: Date = new Date();
    const todayStart: number = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const counts: number[] = [];
    for (let index: number = 6; index >= 0; index--) {
      const start: number = todayStart - index * dayMs;
      const end: number = start + dayMs;
      counts.push(this.diaries.filter((entry: DiaryEntry): boolean => {
        const createdDate: number = DiaryStatsUtils.createdDateMs(entry);
        return createdDate >= start && createdDate < end;
      }).length);
    }
    let maxCount: number = 1;
    counts.forEach((count: number): void => {
      if (count > maxCount) {
        maxCount = count;
      }
    });
    const stats: HeatDayStat[] = [];
    counts.forEach((count: number, index: number): void => {
      stats.push({
        key: index.toString(),
        count: count,
        height: count === 0 ? 24 : Math.max(32, Math.round(count * 82 / maxCount))
      });
    });
    return stats;
  }

  private recentDayTotal(): number {
    return this.recentDayStats().reduce((sum: number, item: HeatDayStat): number => sum + item.count, 0);
  }

  private weatherCount(weather: string): number {
    return DiaryStatsUtils.countWeather(this.diaries, weather);
  }

  private moodStats(): MoodStat[] {
    return DiaryStatsUtils.moodStats(this.diaries, this.accentColor);
  }

  private dominantMood(): MoodStat {
    const stats: MoodStat[] = this.moodStats();
    if (stats.length === 0) {
      return { label: '暂无数据', emoji: '😐', color: this.lineColor, count: 0, percent: 0 };
    }
    if (stats.length > 1 && stats[0].count === stats[1].count) {
      return { label: '情绪均衡', emoji: '✦', color: this.textTertiary, count: stats[0].count, percent: 0 };
    }
    return stats[0];
  }

  private moodStartPercent(item: MoodStat): number {
    let start: number = 0;
    const stats: MoodStat[] = this.moodStats();
    for (let index: number = 0; index < stats.length; index++) {
      if (stats[index].emoji === item.emoji) {
        break;
      }
      start += stats[index].percent;
    }
    return start;
  }

  private moodSegmentPercent(item: MoodStat): number {
    const stats: MoodStat[] = this.moodStats();
    return stats.length > 1 ? Math.max(item.percent - 5, 1) : item.percent;
  }

  private moodCenterText(): string {
    const dominant: MoodStat = this.dominantMood();
    return dominant.label === '情绪均衡' ? dominant.label : dominant.label + '为主';
  }

  private weatherLabel(option: ValueOption): string {
    return option.label.replace(option.value, '').trim();
  }

  private weatherStats(): WeatherStat[] {
    const total: number = Math.max(this.diaries.length, 1);
    const stats: WeatherStat[] = [];
    WEATHER_OPTIONS.forEach((item: ValueOption): void => {
      const count: number = this.weatherCount(item.value);
      if (count > 0) {
        stats.push({
          label: this.weatherLabel(item),
          emoji: item.value,
          count: count,
          percent: Math.round(count * 100 / total)
        });
      }
    });
    return stats.sort((left: WeatherStat, right: WeatherStat): number => right.count - left.count);
  }

  private timePeriodStats(): TimePeriodStat[] {
    const stats: TimePeriodStat[] = [
      { label: '清晨 (0-6时)', icon: '月', count: 0, percent: 0, isTop: false },
      { label: '上午 (6-12时)', icon: '晨', count: 0, percent: 0, isTop: false },
      { label: '下午 (12-18时)', icon: '昼', count: 0, percent: 0, isTop: false },
      { label: '夜晚 (18-24时)', icon: '夜', count: 0, percent: 0, isTop: false }
    ];
    this.diaries.forEach((entry: DiaryEntry): void => {
      const hour: number = new Date(DiaryStatsUtils.activityDateMs(entry)).getHours();
      if (hour < 6) {
        stats[0].count++;
      } else if (hour < 12) {
        stats[1].count++;
      } else if (hour < 18) {
        stats[2].count++;
      } else {
        stats[3].count++;
      }
    });

    let maxCount: number = 1;
    stats.forEach((item: TimePeriodStat): void => {
      if (item.count > maxCount) {
        maxCount = item.count;
      }
    });
    stats.forEach((item: TimePeriodStat): void => {
      item.percent = Math.round(item.count * 100 / maxCount);
      item.isTop = item.count === maxCount && item.count > 0;
    });
    return stats;
  }

  @Builder
  private HeatChart() {
    Column() {
      Row() {
        Text('近 7 日写作记录')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .layoutWeight(1)
        Text(this.recentDayTotal().toString() + ' 次记录')
          .fontSize(12)
          .fontColor(this.textTertiary)
      }
      .width('100%')
      .margin({ bottom: 18 })
      Row({ space: 8 }) {
        ForEach(this.recentDayStats(), (item: HeatDayStat) => {
          Column() {
            Blank()
            Row()
              .width('100%')
              .height(item.height)
              .backgroundColor(item.count === 0 ? this.lineColor : this.accentColor)
              .border({ radius: 8 })
          }
          .layoutWeight(1)
          .height(82)
        }, (item: HeatDayStat) => item.key)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(22)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 22 })
    .margin({ bottom: 16 })
  }

  @Builder
  private MoodLegendRow(item: MoodStat) {
    Row() {
      Row()
        .width(12)
        .height(12)
        .backgroundColor(item.color)
        .border({ radius: 6 })
        .margin({ right: 12 })
      Text(item.emoji)
        .fontSize(15)
        .margin({ right: 8 })
      Text(item.label)
        .fontSize(14)
        .fontColor(this.textSecondary)
        .layoutWeight(1)
      Text(item.percent.toString() + '% (' + item.count.toString() + '篇)')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private MoodPanel() {
    Column() {
      Text('情绪分布比例')
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .margin({ bottom: 16 })
      if (this.moodStats().length === 0) {
        Text('还没有可统计的情绪记录')
          .fontSize(13)
          .fontColor(this.textTertiary)
      } else {
        Stack({ alignContent: Alignment.Center }) {
          ForEach(this.moodStats(), (item: MoodStat) => {
            Progress({ value: this.moodSegmentPercent(item), total: 100, type: ProgressType.Ring })
              .width(146)
              .height(146)
              .color(item.color)
              .backgroundColor(Color.Transparent)
              .style({ strokeWidth: 20, scaleCount: 0, scaleWidth: 0 })
              .rotate({ angle: this.moodStartPercent(item) * 3.6 })
          }, (item: MoodStat) => item.emoji)
          Row()
            .width(104)
            .height(104)
            .backgroundColor(this.cardBg)
            .border({ radius: 52 })
          Column() {
            Text(this.dominantMood().emoji)
              .fontSize(30)
              .margin({ bottom: 8 })
            Text(this.moodCenterText())
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.textTertiary)
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height(156)
        .margin({ bottom: 22 })
        Row({ space: 3 }) {
          ForEach(this.moodStats(), (item: MoodStat) => {
            Row()
              .layoutWeight(item.percent)
              .height(8)
              .backgroundColor(item.color)
              .border({ radius: 4 })
          }, (item: MoodStat) => item.emoji)
        }
        .width('100%')
        .height(8)
        .margin({ bottom: 18 })
        ForEach(this.moodStats(), (item: MoodStat) => {
          this.MoodLegendRow(item)
        }, (item: MoodStat) => item.emoji)
      }
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 24 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 22 })
    .margin({ bottom: 16 })
  }

  @Builder
  private WeatherStatRow(item: WeatherStat) {
    Row({ space: 10 }) {
      Text(item.emoji)
        .width(24)
        .fontSize(18)
        .textAlign(TextAlign.Center)
      Column() {
        Row() {
          Text(item.label)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
            .layoutWeight(1)
          Text(item.count.toString() + '篇 · ' + item.percent.toString() + '%')
            .fontSize(12)
            .fontColor(this.textTertiary)
        }
        .width('100%')
        .margin({ bottom: 8 })
        Row() {
          Row()
            .width(item.percent.toString() + '%')
            .height(6)
            .backgroundColor(this.accentColor)
            .border({ radius: 3 })
        }
        .width('100%')
        .height(6)
        .backgroundColor(this.lineColor)
        .border({ radius: 3 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 12 })
  }

  @Builder
  private WeatherPanel() {
    Column() {
      Text('天气偏好统计')
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .margin({ bottom: 18 })
      if (this.weatherStats().length === 0) {
        Text('暂无天气数据')
          .fontSize(13)
          .fontColor(this.textTertiary)
      } else {
        ForEach(this.weatherStats(), (item: WeatherStat) => {
          this.WeatherStatRow(item)
        }, (item: WeatherStat) => item.emoji)
      }
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 22 })
    .margin({ bottom: 16 })
  }

  @Builder
  private TimePeriodRow(item: TimePeriodStat) {
    Row({ space: 10 }) {
      Text(item.icon)
        .width(22)
        .height(22)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(item.isTop ? this.accentColor : this.textTertiary)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.pageBg)
        .border({ width: 1, color: item.isTop ? this.accentColor : this.lineColor, radius: 11 })
      Column() {
        Row() {
          Text(item.label + (item.isTop ? ' · 最活跃' : ''))
            .fontSize(13)
            .fontWeight(item.isTop ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(item.isTop ? this.accentColor : this.textPrimary)
            .layoutWeight(1)
          Text(item.count.toString() + ' 篇')
            .fontSize(12)
            .fontColor(this.textTertiary)
        }
        .width('100%')
        .margin({ bottom: 6 })
        Row() {
          Row()
            .width(item.percent.toString() + '%')
            .height(6)
            .backgroundColor(item.isTop ? this.accentColor : this.textTertiary)
            .opacity(item.isTop ? 1 : 0.5)
            .border({ radius: 3 })
        }
        .width('100%')
        .height(6)
        .backgroundColor(this.lineColor)
        .border({ radius: 3 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  private TimePeriodPanel() {
    Column() {
      Text('写作时段分析')
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .margin({ bottom: 14 })
      if (this.diaries.length === 0) {
        Text('暂无时段数据')
          .fontSize(13)
          .fontColor(this.textTertiary)
      } else {
        ForEach(this.timePeriodStats(), (item: TimePeriodStat) => {
          this.TimePeriodRow(item)
        }, (item: TimePeriodStat) => item.label)
      }
    }
    .width('100%')
    .padding(22)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 22 })
    .margin({ bottom: 16 })
  }

  build() {
    HdsNavigation() {
      List({ scroller: this.scroller }) {
        ListItem() {
          Column() {
            Grid() {
              GridItem() {
                ZapStatCard({
                  label: '总笔记数',
                  value: this.diaries.length.toString(),
                  unit: '篇',
                  icon: '▣',
                  iconResource: this.diaryCountIcon(),
                  darkIconResource: this.diaryCountDarkIcon(),
                  accentColor: this.accentColor,
                  cardBg: this.cardBg,
                  lineColor: this.lineColor,
                  textPrimary: this.textPrimary,
                  textTertiary: this.textTertiary,
                  isDark: this.isDark
                })
              }
              GridItem() {
                ZapStatCard({
                  label: '连续打卡',
                  value: this.todayCount() > 0 ? '3' : '0',
                  unit: '天',
                  icon: '↟',
                  iconResource: this.streakIcon(),
                  darkIconResource: this.streakDarkIcon(),
                  accentColor: this.accentColor,
                  cardBg: this.cardBg,
                  lineColor: this.lineColor,
                  textPrimary: this.textPrimary,
                  textTertiary: this.textTertiary,
                  isDark: this.isDark
                })
              }
              GridItem() {
                ZapStatCard({
                  label: '累计字数',
                  value: this.totalWords().toString(),
                  unit: '字',
                  icon: 'T',
                  iconResource: this.wordCountIcon(),
                  darkIconResource: this.wordCountDarkIcon(),
                  accentColor: this.accentColor,
                  cardBg: this.cardBg,
                  lineColor: this.lineColor,
                  textPrimary: this.textPrimary,
                  textTertiary: this.textTertiary,
                  isDark: this.isDark
                })
              }
              GridItem() {
                ZapStatCard({
                  label: '本月记录',
                  value: this.diaries.length.toString(),
                  unit: '篇',
                  icon: '□',
                  iconResource: this.calendarIcon(),
                  darkIconResource: this.calendarDarkIcon(),
                  accentColor: this.accentColor,
                  cardBg: this.cardBg,
                  lineColor: this.lineColor,
                  textPrimary: this.textPrimary,
                  textTertiary: this.textTertiary,
                  isDark: this.isDark
                })
              }
            }
            .columnsTemplate('1fr 1fr')
            .rowsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(12)
            .height(190)
            .scrollBar(BarState.Off)
            .margin({ bottom: 16 })

            this.HeatChart()
            this.MoodPanel()
            this.WeatherPanel()
            this.TimePeriodPanel()
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24,
            top: this.topPadding,
            bottom: this.bottomPadding
          })
        }
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .titleBar(createHdsTabTitleBarOptions('统计', '', this.isDark, this.materialEffectMode))
    .titleMode(HdsNavigationTitleMode.FULL)
    .hideBackButton(true)
    .bindToScrollable([this.scroller])
    .backgroundColor(this.pageBg)
  }
}
