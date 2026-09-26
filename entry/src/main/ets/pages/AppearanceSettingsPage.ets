import { SegmentButton, SegmentButtonOptions } from '@kit.ArkUI';
import { SettingToggleRow } from '../components/SettingRows';

@Component
export struct AppearanceSettingsPage {
  @Prop @Watch('syncThemeIndex') themeMode: string = 'light';
  @Prop @Watch('syncLightingIndex') lightingMode: string = 'off';
  @Prop gripModeEnabled: boolean = false;
  @Prop @Watch('refreshSegmentOptions') selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop @Watch('refreshSegmentOptions') inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop @Watch('refreshSegmentOptions') textTertiary: string = '#94A3B8';
  @State private themeSelectedIndexes: number[] = [1];
  @State private themeSegmentOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [
      { text: '跟随' },
      { text: '浅色' },
      { text: '深色' }
    ],
    fontSize: 13,
    selectedFontSize: 13,
    fontWeight: FontWeight.Medium,
    selectedFontWeight: FontWeight.Bold,
    fontColor: '#94A3B8',
    selectedFontColor: Color.White,
    backgroundColor: '#F1F5F9',
    selectedBackgroundColor: '#6366F1'
  });
  @State private lightingSelectedIndexes: number[] = [0];
  @State private lightingSegmentOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [
      { text: '关闭' },
      { text: '柔和' },
      { text: '沉浸' },
      { text: '精致' }
    ],
    fontSize: 14,
    selectedFontSize: 14,
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

  private themeValues: string[] = ['auto', 'light', 'dark'];
  private lightingValues: string[] = ['off', 'soft', 'focus', 'exquisite'];

  aboutToAppear(): void {
    this.refreshSegmentOptions();
    this.syncThemeIndex();
    this.syncLightingIndex();
  }

  private refreshSegmentOptions(): void {
    this.themeSegmentOptions = SegmentButtonOptions.tab({
      buttons: [
        { text: '跟随' },
        { text: '浅色' },
        { text: '深色' }
      ],
      fontSize: 13,
      selectedFontSize: 13,
      fontWeight: FontWeight.Medium,
      selectedFontWeight: FontWeight.Bold,
      fontColor: this.textTertiary,
      selectedFontColor: Color.White,
      backgroundColor: this.inputBg,
      selectedBackgroundColor: this.selectedAccentColor
    });
    this.lightingSegmentOptions = SegmentButtonOptions.tab({
      buttons: [
        { text: '关闭' },
        { text: '柔和' },
        { text: '沉浸' },
        { text: '精致' }
      ],
      fontSize: 14,
      selectedFontSize: 14,
      fontWeight: FontWeight.Medium,
      selectedFontWeight: FontWeight.Bold,
      fontColor: this.textTertiary,
      selectedFontColor: Color.White,
      backgroundColor: this.inputBg,
      selectedBackgroundColor: this.selectedAccentColor
    });
  }

  private syncThemeIndex(): void {
    const index: number = Math.max(0, this.themeValues.indexOf(this.themeMode));
    this.themeSelectedIndexes = [index];
  }

  private syncLightingIndex(): void {
    const index: number = Math.max(0, this.lightingValues.indexOf(this.lightingMode));
    this.lightingSelectedIndexes = [index];
  }

  private onThemeChange(index: number): void {
    if (index < 0 || index >= this.themeValues.length) {
      return;
    }
    const value: string = this.themeValues[index];
    this.themeSelectedIndexes = [index];
    if (this.onValueChange !== undefined) {
      this.onValueChange('theme', value);
    }
  }

  private onLightingChange(index: number): void {
    if (index < 0 || index >= this.lightingValues.length) {
      return;
    }
    const value: string = this.lightingValues[index];
    this.lightingSelectedIndexes = [index];
    if (this.onValueChange !== undefined) {
      this.onValueChange('lighting', value);
    }
  }

  @Builder
  private ThemeSegmentRow() {
    Column() {
      Row() {
        Column() {
          Text('外观模式')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
          Text('切换浅色、深色或跟随系统')
            .fontSize(12)
            .fontColor(this.textTertiary)
            .margin({ top: 4 })
            .maxLines(2)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      }
      .width('100%')
      .margin({ bottom: 14 })

      SegmentButton({
        options: this.themeSegmentOptions,
        selectedIndexes: $themeSelectedIndexes,
        onItemClicked: (index: number) => {
          this.onThemeChange(index);
        }
      })
        .width('100%')
        .borderRadius(18)
        .border({ width: 1, color: this.lineColor })
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 12 })
  }

  @Builder
  private LightingSegmentRow() {
    Column() {
      Row() {
        Column() {
          Text('沉浸光感')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
          Text('控制标题栏、页签和工具栏材质效果')
            .fontSize(12)
            .fontColor(this.textTertiary)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      }
      .width('100%')
      .margin({ bottom: 14 })

      SegmentButton({
        options: this.lightingSegmentOptions,
        selectedIndexes: $lightingSelectedIndexes,
        onItemClicked: (index: number) => {
          this.onLightingChange(index);
        }
      })
        .width('100%')
        .borderRadius(18)
        .border({ width: 1, color: this.lineColor })
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 12 })
  }

  build() {
    Column() {
      this.ThemeSegmentRow()
      this.LightingSegmentRow()
      SettingToggleRow({ title: '智感握持', subtitle: '为单手操作保留更舒适的控件位置', value: this.gripModeEnabled, keyName: 'grip', selectedAccentColor: this.selectedAccentColor, cardBg: this.cardBg, lineColor: this.lineColor, textPrimary: this.textPrimary, textTertiary: this.textTertiary, onToggleChange: this.onToggleChange })
    }
    .width('100%')
  }
}
