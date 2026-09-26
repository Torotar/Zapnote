import { EmptyStateCard } from '../components/EmptyStateCard';
import { SyncDataScope, SyncLog } from '../model/ZapNoteTypes';
import { DiaryStatsUtils } from '../utils/DiaryStatsUtils';

@CustomDialog
@Component
struct SyncTimeOptionsDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: this });
  options: string[] = [];
  @State selectedTimes: string[] = [];
  selectedAccentColor: string = '#6366F1';
  cardBg: string = '#FFFFFF';
  inputBg: string = '#F1F5F9';
  lineColor: string = '#E2E8F0';
  textPrimary: string = '#0F172A';
  textSecondary: string = '#475569';
  onConfirm: (value: string[]) => void = (value: string[]) => {};

  private isSelected(time: string): boolean {
    return this.selectedTimes.indexOf(time) >= 0;
  }

  private toggleTime(time: string): void {
    if (this.isSelected(time)) {
      if (this.selectedTimes.length <= 1) {
        return;
      }
      this.selectedTimes = this.selectedTimes.filter((item: string) => item !== time);
      return;
    }
    this.selectedTimes = [...this.selectedTimes, time].sort();
  }

  build() {
    Column() {
      Text('同步时间选项')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .margin({ top: 8 })

      Text('选择需要定时同步的时间，至少保留一个。')
        .fontSize(12)
        .fontColor(this.textSecondary)
        .lineHeight(18)
        .textAlign(TextAlign.Center)
        .margin({ top: 6, bottom: 8 })

      ForEach(this.options, (time: string) => {
        Row() {
          Text(time)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isSelected(time) ? this.selectedAccentColor : this.textPrimary)
            .layoutWeight(1)

          Text(this.isSelected(time) ? '已选' : '选择')
            .fontSize(12)
            .fontColor(this.isSelected(time) ? Color.White : this.selectedAccentColor)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.isSelected(time) ? this.selectedAccentColor : this.inputBg)
            .border({ radius: 10 })
        }
        .width('100%')
        .height(46)
        .padding({ left: 14, right: 10 })
        .margin({ top: 8 })
        .backgroundColor(this.isSelected(time) ? this.inputBg : this.cardBg)
        .border({ width: 1, color: this.isSelected(time) ? this.selectedAccentColor : this.lineColor, radius: 12 })
        .onClick(() => {
          this.toggleTime(time);
        })
      }, (time: string) => time)

      Row() {
        Button('取消')
          .width('44%')
          .height(42)
          .fontColor(this.textPrimary)
          .backgroundColor(this.inputBg)
          .border({ radius: 14 })
          .onClick(() => {
            this.controller.close();
          })

        Button('确定')
          .width('44%')
          .height(42)
          .fontColor(Color.White)
          .backgroundColor(this.selectedAccentColor)
          .border({ radius: 14 })
          .onClick(() => {
            this.onConfirm(this.selectedTimes);
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 16 })
    }
    .padding({ left: 24, right: 24, top: 16, bottom: 20 })
    .backgroundColor(this.cardBg)
    .border({ radius: 20 })
  }
}

@Component
export struct SyncSettingsPage {
  @Prop syncMode: number = 0;
  @Prop syncTimes: string[] = ['08:00', '22:00'];
  @Prop historyLimit: number = 10;
  @Prop syncRestoreStrategy: string = 'merge';
  @Prop syncDataScope: SyncDataScope = 'all';
  @Prop syncLogs: SyncLog[] = [];
  @Prop syncLogRefreshKey: number = 0;
  @Prop isDark: boolean = false;
  @Prop webdavUrl: string = '';
  @Prop webdavUser: string = '';
  @Prop webdavPass: string = '';
  @Prop webdavRemotePath: string = '/zapnote';
  @Prop remoteBackupPath: string = '/zapnote/zapnote-backup.json';
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  onBack?: () => void;
  onSyncModeChange?: (mode: number) => void;
  onSyncTimesChange?: (times: string[]) => void;
  onHistoryLimitChange?: (limit: number) => void;
  onSyncRestoreStrategyChange?: (strategy: string) => void;
  onSyncDataScopeChange?: (scope: SyncDataScope) => void;
  onPullSync?: () => void;
  onPushSync?: () => void;
  onTestWebdav?: () => void;
  onSaveWebdav?: () => void;
  onWebdavInputChange?: (key: string, value: string) => void;

  private readonly syncTimeOptions: string[] = ['06:00', '08:00', '12:30', '18:00', '22:00', '23:30'];
  private readonly historyLimitOptions: number[] = [10, 30, 100];
  private dialogController: CustomDialogController | null = null;

  private webdavConfigured(): boolean {
    return this.webdavUrl.trim().length > 0 && this.webdavUser.trim().length > 0 &&
      this.webdavPass.length > 0 && this.webdavRemotePath.trim().length > 0;
  }

  private syncModeLabel(): string {
    return this.syncMode === 1 ? '数据变化后同步' : '定时同步';
  }

  private syncModeDescription(): string {
    if (this.syncMode === 1) {
      return '笔记内容变化后触发同步，时间选项会保留备用。';
    }
    return '应用运行期间按选定时间自动同步，也可以手动上传或拉取。';
  }

  private getSyncModeOptions(): SelectOption[] {
    return [
      { value: '定时同步' },
      { value: '数据变化后同步' }
    ];
  }

  private getHistoryLimitOptions(): SelectOption[] {
    return [
      { value: '最近 10 条' },
      { value: '最近 30 条' },
      { value: '最近 100 条' }
    ];
  }

  private getSyncDataScopeOptions(): SelectOption[] {
    return [
      { value: '笔记和软件设置' },
      { value: '仅同步笔记数据' },
      { value: '仅同步软件设置' }
    ];
  }

  private historyLimitSelectedIndex(): number {
    const index: number = this.historyLimitOptions.indexOf(this.historyLimit);
    return index >= 0 ? index : 0;
  }

  private syncDataScopeSelectedIndex(): number {
    if (this.syncDataScope === 'diaries') {
      return 1;
    }
    if (this.syncDataScope === 'settings') {
      return 2;
    }
    return 0;
  }

  private historyLimitText(): string {
    return '最近 ' + this.historyLimit.toString() + ' 条';
  }

  private syncTimeSummary(): string {
    if (this.syncTimes.length === 0) {
      return '未选择';
    }
    if (this.syncTimes.length <= 3) {
      return this.syncTimes.join('、');
    }
    return this.syncTimes[0] + '、' + this.syncTimes[1] + ' 等 ' + this.syncTimes.length.toString() + ' 个';
  }

  private visibleSyncLogs(): SyncLog[] {
    return this.syncLogs.slice(0, Math.min(this.historyLimit, this.syncLogs.length));
  }

  private syncLogKey(item: SyncLog, index: number): string {
    if (typeof item.createdAt === 'number') {
      return item.createdAt.toString();
    }
    return item.time + '-' + item.title + '-' + item.detail + '-' + item.type + '-' +
      this.syncLogRefreshKey.toString() + '-' + index.toString();
  }

  private syncLogTimeText(item: SyncLog): string {
    if (typeof item.createdAt === 'number' && item.createdAt > 0) {
      return DiaryStatsUtils.formatDateText(item.createdAt);
    }
    return item.time;
  }

  private syncLogSuccessBg(): string {
    return this.isDark ? '#102A43' : '#DBEAFE';
  }

  private syncLogSuccessBorder(): string {
    return this.isDark ? '#234E7D' : '#93C5FD';
  }

  private syncLogSuccessIcon(): Resource {
    return this.isDark ? $rawfile('icons/webdav_check_line_dark.svg') : $rawfile('icons/webdav_check_line.svg');
  }

  private updateSyncMode(index: number): void {
    if (this.onSyncModeChange !== undefined) {
      this.onSyncModeChange(index === 1 ? 1 : 0);
    }
  }

  private updateHistoryLimit(index: number): void {
    if (this.onHistoryLimitChange !== undefined) {
      this.onHistoryLimitChange(this.historyLimitOptions[index]);
    }
  }

  private restoreStrategyLabel(): string {
    return this.syncRestoreStrategy === 'overwrite' ? '覆盖' : '合并';
  }

  private syncDataScopeLabel(): string {
    if (this.syncDataScope === 'diaries') {
      return '仅同步笔记数据';
    }
    if (this.syncDataScope === 'settings') {
      return '仅同步软件设置';
    }
    return '笔记和软件设置';
  }

  private updateRestoreStrategy(strategy: string): void {
    if (this.onSyncRestoreStrategyChange !== undefined) {
      this.onSyncRestoreStrategyChange(strategy === 'overwrite' ? 'overwrite' : 'merge');
    }
  }

  private updateSyncDataScope(scope: SyncDataScope): void {
    if (this.onSyncDataScopeChange !== undefined) {
      this.onSyncDataScopeChange(scope);
    }
  }

  private updateSyncDataScopeByIndex(index: number): void {
    const scopes: SyncDataScope[] = ['all', 'diaries', 'settings'];
    this.updateSyncDataScope(scopes[index] ?? 'all');
  }

  private openSyncTimeOptions(): void {
    if (this.dialogController) {
      this.dialogController.close();
      this.dialogController = null;
    }
    this.dialogController = new CustomDialogController({
      builder: SyncTimeOptionsDialog({
        options: this.syncTimeOptions,
        selectedTimes: this.syncTimes,
        selectedAccentColor: this.selectedAccentColor,
        cardBg: this.cardBg,
        inputBg: this.inputBg,
        lineColor: this.lineColor,
        textPrimary: this.textPrimary,
        textSecondary: this.textSecondary,
        onConfirm: (value: string[]) => {
          if (this.onSyncTimesChange !== undefined) {
            this.onSyncTimesChange(value);
          }
        }
      }),
      customStyle: false,
      alignment: DialogAlignment.Center,
      autoCancel: true
    });
    this.dialogController.open();
  }

  @Builder
  private SectionTitle(title: string, subtitle: string) {
    Column() {
      Text(title)
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
      if (subtitle.length > 0) {
        Text(subtitle)
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  private OptionButton(label: string, onClick: () => void) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.selectedAccentColor)
      .width(92)
      .height(34)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.inputBg)
      .border({ radius: 12 })
      .onClick(() => {
        onClick();
      })
  }

  @Builder
  private InputField(label: string, placeholder: string, value: string, key: string) {
    Column() {
      Text(label)
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textSecondary)
        .margin({ bottom: 8 })
      TextInput({ placeholder: placeholder, text: value })
        .width('100%')
        .height(48)
        .fontSize(14)
        .fontColor(this.textPrimary)
        .placeholderColor(this.textTertiary)
        .backgroundColor(this.inputBg)
        .border({ width: 1, color: this.lineColor, radius: 14 })
        .padding({ left: 14, right: 14 })
        .type(key === 'pass' ? InputType.Password : InputType.Normal)
        .onChange((text: string) => {
          if (this.onWebdavInputChange !== undefined) {
            this.onWebdavInputChange(key, text);
          }
        })
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private RestoreStrategyRow(value: string, title: string, subtitle: string, recommended: boolean) {
    Row() {
      Stack() {
        if (this.syncRestoreStrategy === value) {
          Text('')
            .width(10)
            .height(10)
            .backgroundColor(this.selectedAccentColor)
            .border({ radius: 5 })
        }
      }
      .width(20)
      .height(20)
      .alignContent(Alignment.Center)
      .border({
        width: 1,
        color: this.syncRestoreStrategy === value ? this.selectedAccentColor : this.textTertiary,
        radius: 10
      })
      .margin({ right: 12 })

      Column() {
        Row() {
          Text(title)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary)
          if (recommended) {
            Text('推荐')
              .fontSize(11)
              .fontColor(this.selectedAccentColor)
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .backgroundColor(this.inputBg)
              .border({ radius: 9 })
              .margin({ left: 8 })
          }
        }
        .width('100%')

        Text(subtitle)
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(this.textSecondary)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(this.syncRestoreStrategy === value ? this.inputBg : this.cardBg)
    .border({
      width: 1,
      color: this.syncRestoreStrategy === value ? this.selectedAccentColor : this.lineColor,
      radius: 14
    })
    .margin({ bottom: 10 })
    .onClick(() => {
      this.updateRestoreStrategy(value);
    })
  }

  @Builder
  private ConfigCard() {
    Column() {
      Row() {
        Column() {
          Text('WebDAV 配置')
            .width('100%')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
          Text('连接坚果云、Nextcloud、群晖等标准 WebDAV 服务。')
            .width('100%')
            .fontSize(12)
            .lineHeight(18)
            .fontColor(this.textSecondary)
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(this.webdavConfigured() ? '已配置' : '未配置')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.webdavConfigured() ? '#047857' : this.selectedAccentColor)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.webdavConfigured() ? '#D1FAE5' : this.inputBg)
          .border({ radius: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({ bottom: 16 })

      this.InputField('WebDAV 服务器地址', '例如 https://dav.example.com/dav/', this.webdavUrl, 'url')
      this.InputField('用户名 / 邮箱', 'example@email.com', this.webdavUser, 'user')
      this.InputField('应用授权密码', '请输入 WebDAV 应用令牌', this.webdavPass, 'pass')
      this.InputField('云端同步路径', '例如 /zapnote', this.webdavRemotePath, 'path')

      Text('备份文件：' + this.remoteBackupPath)
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(this.textTertiary)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(this.inputBg)
        .border({ radius: 12 })
        .margin({ bottom: 14 })

      Row() {
        Button('测试连接')
          .layoutWeight(1)
          .height(46)
          .fontColor(this.selectedAccentColor)
          .backgroundColor(this.inputBg)
          .border({ radius: 14 })
          .onClick(() => {
            if (this.onTestWebdav !== undefined) {
              this.onTestWebdav();
            }
          })
        Button('保存配置')
          .layoutWeight(1)
          .height(46)
          .fontColor('#FFFFFF')
          .backgroundColor(this.selectedAccentColor)
          .border({ radius: 14 })
          .onClick(() => {
            if (this.onSaveWebdav !== undefined) {
              this.onSaveWebdav();
            }
          })
          .margin({ left: 10 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 16 })
  }

  @Builder
  private DataActionsCard() {
    Column() {
      this.SectionTitle('数据交互', '')

      Row() {
        Column() {
          Text('同步内容')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary)
          Text(this.syncDataScopeLabel())
            .fontSize(12)
            .fontColor(this.textSecondary)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ right: 12 })

        Select(this.getSyncDataScopeOptions())
          .selected(this.syncDataScopeSelectedIndex())
          .value(this.syncDataScopeLabel())
          .height(36)
          .padding({ left: 12, right: 8 })
          .backgroundColor(this.inputBg)
          .borderRadius(12)
          .font({ size: 13, weight: FontWeight.Medium })
          .fontColor(this.selectedAccentColor)
          .selectedOptionFont({ size: 13, weight: FontWeight.Medium })
          .optionFont({ size: 13, weight: FontWeight.Normal })
          .onSelect((index: number) => {
            this.updateSyncDataScopeByIndex(index);
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 16 })

      if (this.syncDataScope !== 'settings') {
        Text('笔记拉取策略：' + this.restoreStrategyLabel())
          .width('100%')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)
          .margin({ top: 6, bottom: 10 })

        this.RestoreStrategyRow('merge', '合并云端与本地笔记', '拉取时保留本地更改，并补入云端新增笔记。', true)
        this.RestoreStrategyRow('overwrite', '用云端备份覆盖本地笔记', '拉取时以云端备份为准，替换当前本地列表。', false)
      }
      Row() {
        Button('拉取数据')
          .layoutWeight(1)
          .height(50)
          .fontColor(this.selectedAccentColor)
          .backgroundColor(this.inputBg)
          .border({ radius: 14 })
          .onClick(() => {
            if (this.onPullSync !== undefined) {
              this.onPullSync();
            }
          })
        Button('上传数据')
          .layoutWeight(1)
          .height(50)
          .fontColor('#FFFFFF')
          .backgroundColor(this.selectedAccentColor)
          .border({ radius: 14 })
          .onClick(() => {
            if (this.onPushSync !== undefined) {
              this.onPushSync();
            }
          })
          .margin({ left: 10 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 16 })
  }

  @Builder
  private SyncModeCard() {
    Column() {
      this.SectionTitle('同步管理', this.syncModeDescription())

      Row() {
        Column() {
          Text('同步方式')
            .fontSize(14)
            .fontColor(this.textPrimary)
          Text(this.syncModeLabel())
            .fontSize(12)
            .fontColor(this.textSecondary)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Select(this.getSyncModeOptions())
          .selected(this.syncMode)
          .value(this.syncModeLabel())
          .height(36)
          .padding({ left: 12, right: 8 })
          .backgroundColor(this.inputBg)
          .borderRadius(12)
          .font({ size: 13, weight: FontWeight.Medium })
          .fontColor(this.selectedAccentColor)
          .selectedOptionFont({ size: 13, weight: FontWeight.Medium })
          .optionFont({ size: 13, weight: FontWeight.Normal })
          .onSelect((index: number) => {
            this.updateSyncMode(index);
          })
      }
      .width('100%')
      .margin({ top: 6 })

      Divider()
        .color(this.lineColor)
        .margin({ top: 16, bottom: 16 })

      Row() {
        Column() {
          Text('同步时间')
            .fontSize(14)
            .fontColor(this.textPrimary)
            .width('100%')
          Text('已选择：' + this.syncTimeSummary())
            .fontSize(12)
            .fontColor(this.textSecondary)
            .lineHeight(18)
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ right: 12 })

        this.OptionButton('选项', () => {
          this.openSyncTimeOptions();
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 16 })
  }

  @Builder
  private SyncLogRow(item: SyncLog) {
    Row() {
      if (item.type === 'success') {
        Stack() {
          Image(this.syncLogSuccessIcon())
            .width(16)
            .height(16)
        }
        .width(28)
        .height(28)
        .alignContent(Alignment.Center)
        .backgroundColor(this.syncLogSuccessBg())
        .border({ width: 1, color: this.syncLogSuccessBorder(), radius: 10 })
        .margin({ right: 10 })
      } else {
        Text('!')
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedAccentColor)
          .backgroundColor(this.inputBg)
          .border({ radius: 10 })
          .margin({ right: 10 })
      }
      Column() {
        Text(item.title)
          .width('100%')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text(item.detail + ' · ' + this.syncLogTimeText(item))
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 14 })
    .margin({ bottom: 10 })
  }

  @Builder
  private HistoryCard() {
    Column() {
      Row() {
        Column() {
          Text('同步记录')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary)
            .width('100%')
          Text('查看最近进行过同步的时间。')
            .fontSize(12)
            .fontColor(this.textSecondary)
            .lineHeight(18)
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ right: 12 })

        Select(this.getHistoryLimitOptions())
          .selected(this.historyLimitSelectedIndex())
          .value(this.historyLimitText())
          .height(36)
          .padding({ left: 12, right: 8 })
          .backgroundColor(this.inputBg)
          .borderRadius(12)
          .font({ size: 13, weight: FontWeight.Medium })
          .fontColor(this.selectedAccentColor)
          .selectedOptionFont({ size: 13, weight: FontWeight.Medium })
          .optionFont({ size: 13, weight: FontWeight.Normal })
          .onSelect((index: number) => {
            this.updateHistoryLimit(index);
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({ bottom: 12 })

      if (this.syncLogs.length === 0) {
        EmptyStateCard({ title: '暂无同步记录', subtitle: '完成连接验证、上传或拉取后，记录会出现在这里。', icon: '↺', accentColor: this.selectedAccentColor, cardBg: this.cardBg, lineColor: this.lineColor, textPrimary: this.textPrimary, textTertiary: this.textTertiary })
      } else {
        ForEach(this.visibleSyncLogs(), (item: SyncLog, index: number) => {
          this.SyncLogRow(item)
        }, (item: SyncLog, index: number) => this.syncLogKey(item, index))
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
  }

  build() {
    Column() {
      this.ConfigCard()
      this.DataActionsCard()
      this.SyncModeCard()
      this.HistoryCard()
    }
    .width('100%')
  }
}
