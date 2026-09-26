import { SegmentButton, SegmentButtonOptions } from '@kit.ArkUI';
import { AiVisualEngineOption } from '../model/ZapNoteTypes';

@Component
export struct AutofillSettingsPage {
  @Prop autoFillEnabled: boolean = true;
  @Prop doubleTouchEnabled: boolean = false;
  @Prop doubleTouchAction: string = 'none';
  @Prop sharedPhotoSaveMode: string = 'ask';
  @Prop sharedPhotoAutoRecognizeEnabled: boolean = false;
  @Prop sharedPhotoSaveToAlbumEnabled: boolean = false;
  @Prop enhancedLinkRecognitionEnabled: boolean = false;
  @Prop @Watch('syncSelectedEngine') engine: string = 'default';
  @Prop @Watch('syncSelectedEngine') engineSelectionRefreshKey: number = 0;
  @Prop customEngines: AiVisualEngineOption[] = [];
  @Prop vibrateEnabled: boolean = true;
  @Prop @Watch('refreshSegmentOptions') selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop @Watch('refreshSegmentOptions') inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop @Watch('refreshSegmentOptions') textTertiary: string = '#94A3B8';
  @State private activeTab: string = 'double';
  @State private activeTabSelectedIndexes: number[] = [0];
  @State private selectedEngine: string = 'default';
  @State private enhancedLinkRecognitionAvailable: boolean = false;
  @State private engineSelectRenderKey: number = 0;
  @State private segmentOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [
      { text: '双触' },
      { text: '设置' }
    ],
    fontSize: 15,
    selectedFontSize: 15,
    fontWeight: FontWeight.Medium,
    selectedFontWeight: FontWeight.Bold,
    fontColor: '#94A3B8',
    selectedFontColor: Color.White,
    backgroundColor: '#F1F5F9',
    selectedBackgroundColor: '#6366F1'
  });
  onBack?: () => void;
  onToggleChange?: (key: string, isOn: boolean) => void;
  onValueChange?: (key: string, value: string) => void;
  onOpenMatchRuleSheet?: () => void;
  onOpenAiConfigSheet?: () => void;
  onDeleteEngineRequest?: (value: string) => void;

  private tabValues: string[] = ['double', 'engine'];

  aboutToAppear(): void {
    this.syncSelectedEngine();
    this.refreshSegmentOptions();
    this.syncActiveTabIndex();
  }

  private syncSelectedEngine(): void {
    this.applySelectedEngine(this.engine);
    this.engineSelectRenderKey++;
  }

  private applySelectedEngine(value: string): void {
    this.selectedEngine = value;
    this.enhancedLinkRecognitionAvailable = value === 'custom' || value.startsWith('custom:');
  }

  private refreshSegmentOptions(): void {
    this.segmentOptions = SegmentButtonOptions.tab({
      buttons: [
        { text: '双触' },
        { text: '设置' }
      ],
      fontSize: 15,
      selectedFontSize: 15,
      fontWeight: FontWeight.Medium,
      selectedFontWeight: FontWeight.Bold,
      fontColor: this.textTertiary,
      selectedFontColor: Color.White,
      backgroundColor: this.inputBg,
      selectedBackgroundColor: this.selectedAccentColor
    });
  }

  private syncActiveTabIndex(): void {
    const selectedIndex: number = Math.max(0, this.tabValues.indexOf(this.activeTab));
    this.activeTabSelectedIndexes = [selectedIndex];
  }

  private onSegmentChange(index: number): void {
    if (index < 0 || index >= this.tabValues.length) {
      return;
    }
    this.activeTab = this.tabValues[index];
    this.activeTabSelectedIndexes = [index];
  }

  private openRuleSheet(): void {
    if (this.onOpenMatchRuleSheet !== undefined) {
      this.onOpenMatchRuleSheet();
    }
  }

  private engineSelectLabel(): string {
    for (let index: number = 0; index < this.customEngines.length; index++) {
      if (this.customEngines[index].value === this.selectedEngine) {
        return this.customEngines[index].label;
      }
    }
    return '默认';
  }

  private engineSelectIndex(): number {
    for (let index: number = 0; index < this.customEngines.length; index++) {
      if (this.customEngines[index].value === this.selectedEngine) {
        return index + 1;
      }
    }
    return 0;
  }

  private engineSelectOptions(): SelectOption[] {
    const options: SelectOption[] = [{ value: '默认' }];
    for (let index: number = 0; index < this.customEngines.length; index++) {
      options.push({ value: this.customEngines[index].label });
    }
    options.push({ value: '自定义' });
    return options;
  }

  private changeEngine(index: number): void {
    if (index === 0) {
      this.applySelectedEngine('default');
      if (this.onValueChange !== undefined) {
        this.onValueChange('engine', 'default');
      }
      return;
    }
    const customIndex: number = index - 1;
    if (customIndex >= 0 && customIndex < this.customEngines.length) {
      this.applySelectedEngine(this.customEngines[customIndex].value);
      if (this.onValueChange !== undefined) {
        this.onValueChange('engine', this.customEngines[customIndex].value);
      }
      return;
    }
    if (this.onOpenAiConfigSheet !== undefined) {
      this.onOpenAiConfigSheet();
    }
  }

  private requestDeleteEngine(value: string): void {
    if (!value.startsWith('custom:')) {
      return;
    }
    if (value === this.selectedEngine) {
      this.applySelectedEngine('default');
    }
    if (this.onDeleteEngineRequest !== undefined) {
      this.onDeleteEngineRequest(value);
    }
  }

  private isCustomEngineSelected(): boolean {
    return this.enhancedLinkRecognitionAvailable;
  }

  private doubleTouchActionLabel(): string {
    if (this.doubleTouchAction === 'back') {
      return '点击返回';
    }
    return '无动作';
  }

  private doubleTouchActionSelectIndex(): number {
    return this.doubleTouchAction === 'back' ? 1 : 0;
  }

  private changeDoubleTouchAction(index: number): void {
    if (!this.doubleTouchEnabled || this.onValueChange === undefined) {
      return;
    }
    const value: string = index === 1 ? 'back' : 'none';
    this.onValueChange('double-touch-action', value);
  }

  private showDoubleTouchGuide(): void {
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: '双触识别使用方法',
        message: '1. 打开手机“设置”，搜索并进入“双触”功能。\n\n' +
          '2. 在“双触启动应用”列表中选择“识录笔记”。\n\n' +
          '3. 返回本页开启“智控键双触识别”，并按提示授予截屏权限；若系统列表中没有识录笔记，说明当前设备或系统暂不支持第三方应用双触启动。\n\n' +
          '4. 需要识别当前画面时，双触指纹智控键，识录笔记会截取画面、识别文字，并按“双触动作选项”处理结果。',
        buttons: [
          { text: '我知道了', color: this.selectedAccentColor }
        ]
      }).catch(() => {});
    } catch (error) {
      console.error('AutofillSettingsPage double touch guide dialog failed: ' + JSON.stringify(error));
    }
  }

  private sharedPhotoSaveModeLabel(): string {
    if (this.sharedPhotoSaveMode === 'save') {
      return '填入';
    }
    if (this.sharedPhotoSaveMode === 'discard') {
      return '不填入';
    }
    return '自选择';
  }

  private sharedPhotoSaveModeSelectIndex(): number {
    if (this.sharedPhotoSaveMode === 'save') {
      return 0;
    }
    if (this.sharedPhotoSaveMode === 'discard') {
      return 1;
    }
    return 2;
  }

  private changeSharedPhotoSaveMode(index: number): void {
    if (this.onValueChange === undefined) {
      return;
    }
    const value: string = index === 0 ? 'save' : (index === 1 ? 'discard' : 'ask');
    this.onValueChange('shared-photo-save-mode', value);
  }

  @Builder
  private SegmentBar() {
    SegmentButton({
      options: this.segmentOptions,
      selectedIndexes: $activeTabSelectedIndexes,
      onItemClicked: (index: number) => {
        this.onSegmentChange(index);
      }
    })
      .width('100%')
      .borderRadius(18)
      .border({ width: 1, color: this.lineColor })
      .shadow({
        radius: 10,
        color: '#08000000',
        offsetX: 0,
        offsetY: 4
      })
      .margin({ bottom: 22 })
  }

  @Builder
  private DividerLine() {
    Row()
      .width('100%')
      .height(1)
      .backgroundColor(this.lineColor)
  }

  @Builder
  private ToggleRow(title: string, subtitle: string, keyName: string, value: boolean, enabled: boolean = true) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(enabled ? this.textPrimary : this.textTertiary)
          .maxLines(1)
        Text(subtitle)
          .fontSize(13)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .opacity(enabled ? 1 : 0.6)
          .margin({ top: 4 })
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ right: 14 })

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(this.selectedAccentColor)
        .enabled(enabled)
        .opacity(enabled ? 1 : 0.55)
        .onChange((isOn: boolean) => {
          if (enabled && this.onToggleChange !== undefined) {
            this.onToggleChange(keyName, isOn);
          }
        })
    }
    .width('100%')
    .height(84)
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
  }

  @Builder
  private EnhancedLinkRecognitionRow() {
    Row() {
      Column() {
        Text('增强链接识别')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.enhancedLinkRecognitionAvailable ? this.textPrimary : this.textTertiary)
          .maxLines(1)
        Text('提升链接识别速度')
          .fontSize(13)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .opacity(this.enhancedLinkRecognitionAvailable ? 1 : 0.6)
          .margin({ top: 4 })
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ right: 14 })

      Toggle({
        type: ToggleType.Switch,
        isOn: this.enhancedLinkRecognitionEnabled && this.enhancedLinkRecognitionAvailable
      })
        .selectedColor(this.selectedAccentColor)
        .enabled(this.enhancedLinkRecognitionAvailable)
        .opacity(this.enhancedLinkRecognitionAvailable ? 1 : 0.55)
        .onChange((isOn: boolean) => {
          if (this.enhancedLinkRecognitionAvailable && this.onToggleChange !== undefined) {
            this.onToggleChange('enhanced-link-recognition', isOn);
          }
        })
    }
    .width('100%')
    .height(84)
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
  }

  @Builder
  private DoubleTouchActionSelectRow() {
    Row() {
      Column() {
        Text('双触动作选项')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .maxLines(1)
        Text('选择双触识别完成后的操作')
          .fontSize(13)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ right: 14 })

      Select([{ value: '无动作' }, { value: '点击返回' }])
        .selected(this.doubleTouchActionSelectIndex())
        .value(this.doubleTouchActionLabel())
        .font({ size: 15, weight: FontWeight.Medium })
        .fontColor(this.doubleTouchEnabled ? this.textPrimary : this.textTertiary)
        .selectedOptionFontColor(this.selectedAccentColor)
        .optionFontColor(this.textPrimary)
        .backgroundColor(this.inputBg)
        .border({ width: 1, color: this.lineColor, radius: 16 })
        .height(38)
        .width(116)
        .enabled(this.doubleTouchEnabled)
        .opacity(this.doubleTouchEnabled ? 1 : 0.55)
        .onSelect((index: number) => {
          this.changeDoubleTouchAction(index);
        })
    }
    .width('100%')
    .height(84)
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
  }

  @Builder
  private DoubleTouchGuideRow() {
    Row() {
      Column() {
        Text('双触识别使用方法')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .maxLines(1)
        Text('查看系统设置、设备支持与双触触发步骤')
          .fontSize(13)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ right: 14 })

      Row({ space: 8 }) {
        Text('查看')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textTertiary)
          .maxLines(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([this.textTertiary])
          .width(20)
          .height(28)
      }
    }
    .width('100%')
    .height(84)
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    .accessibilityText('双触识别使用方法，查看系统设置、设备支持与双触触发步骤')
    .onClick(() => {
      this.showDoubleTouchGuide();
    })
  }

  @Builder
  private EngineSelectRow() {
    Row() {
      Column() {
        Text('解析模型')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .maxLines(1)
        Text('定义对导入照片分析的 AI 后台服务接口')
          .fontSize(13)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ right: 14 })

      Row({ space: 8 }) {
        ForEach([this.engineSelectRenderKey], (_: number) => {
          Select(this.engineSelectOptions())
            .selected(this.engineSelectIndex())
            .value(this.engineSelectLabel())
            .font({ size: 15, weight: FontWeight.Medium })
            .fontColor(this.textPrimary)
            .selectedOptionFontColor(this.selectedAccentColor)
            .optionFontColor(this.textPrimary)
            .optionWidth(156)
            .backgroundColor(this.inputBg)
            .border({ width: 1, color: this.lineColor, radius: 16 })
            .height(38)
            .width(this.isCustomEngineSelected() ? 110 : 156)
            .onSelect((index: number) => {
              this.changeEngine(index);
            })
        }, (key: number) => key.toString())

        if (this.isCustomEngineSelected()) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.trash'))
              .fontSize(20)
              .fontColor(['#EF4444'])
          }
          .width(38)
          .height(38)
          .padding(0)
          .backgroundColor(this.inputBg)
          .border({ width: 1, color: this.lineColor, radius: 16 })
          .accessibilityText('删除当前解析模型')
          .onClick(() => {
            this.requestDeleteEngine(this.selectedEngine);
          })
        }
      }
      .width(156)
      .height(38)
    }
    .width('100%')
    .height(84)
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
  }

  @Builder
  private SharedPhotoSaveSelectRow() {
    Row() {
      Column() {
        Text('照片填入')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .maxLines(1)
        Text('设置识别后是否将照片填入笔记')
          .fontSize(13)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ right: 14 })

      Select([{ value: '填入' }, { value: '不填入' }, { value: '自选择' }])
        .selected(this.sharedPhotoSaveModeSelectIndex())
        .value(this.sharedPhotoSaveModeLabel())
        .font({ size: 15, weight: FontWeight.Medium })
        .fontColor(this.textPrimary)
        .selectedOptionFontColor(this.selectedAccentColor)
        .optionFontColor(this.textPrimary)
        .backgroundColor(this.inputBg)
        .border({ width: 1, color: this.lineColor, radius: 16 })
        .height(38)
        .width(104)
        .onSelect((index: number) => {
          this.changeSharedPhotoSaveMode(index);
        })
    }
    .width('100%')
    .height(84)
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
  }

  @Builder
  private MatchRuleRow() {
    Row() {
      Column() {
        Text('自定义匹配规则')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .maxLines(1)
        Text(this.selectedEngine.startsWith('custom:') || this.selectedEngine === 'custom' ?
          '设置 AI 整理系统 OCR 文字的输出要求' : '按关键词选取、排除或屏蔽 OCR 内容')
          .fontSize(13)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ right: 14 })

      Row({ space: 8 }) {
        Text('配置')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textTertiary)
          .maxLines(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([this.textTertiary])
          .width(20)
          .height(28)
      }
    }
    .width('100%')
    .height(84)
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    .onClick(() => {
      this.openRuleSheet();
    })
  }

  @Builder
  private SettingsCard() {
    Column() {
      if (this.activeTab === 'double') {
        this.ToggleRow('智控键双触识别', '仅部分机型支持；双触指纹智控键后截取当前画面并识别文字',
          'doubleTouch', this.doubleTouchEnabled)
        this.DividerLine()
        this.DoubleTouchActionSelectRow()
        this.DividerLine()
        this.DoubleTouchGuideRow()
      } else {
        this.ToggleRow('自动识别并填入', '分享图片或双触截图后自动识别并填入',
          'shared-photo-auto-recognize', this.sharedPhotoAutoRecognizeEnabled)
        this.DividerLine()
        this.ToggleRow('保存到本地相册', '识别后将分享图片或双触截图另存到系统相册',
          'shared-photo-save-to-album', this.sharedPhotoSaveToAlbumEnabled)
        this.DividerLine()
        this.SharedPhotoSaveSelectRow()
        this.DividerLine()
        this.EngineSelectRow()
        this.DividerLine()
        this.EnhancedLinkRecognitionRow()
        this.DividerLine()
        this.MatchRuleRow()
        this.DividerLine()
        this.ToggleRow('触控触觉振动反馈', '识别生成笔记草稿后，执行一次触觉反馈', 'vibrate', this.vibrateEnabled)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 24 })
    .clip(true)
    .shadow({
      radius: 18,
      color: '#08000000',
      offsetX: 0,
      offsetY: 8
    })
  }

  build() {
    Column() {
      this.SegmentBar()
      this.SettingsCard()
    }
    .width('100%')
  }
}
