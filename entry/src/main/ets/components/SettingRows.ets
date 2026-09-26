import { SettingPanel } from '../model/ZapNoteTypes';

@Component
export struct SettingBackHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop inputBg: string = '#F1F5F9';
  @Prop textPrimary: string = '#0F172A';
  @Prop textTertiary: string = '#94A3B8';
  onBack?: () => void;

  build() {
    Row() {
      Button({ type: ButtonType.Normal, stateEffect: false }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(22)
          .fontColor([this.textPrimary])
      }
        .width(38)
        .height(38)
        .backgroundColor(this.inputBg)
        .border({ radius: 14 })
        .onClick(() => {
          if (this.onBack !== undefined) {
            this.onBack();
          }
        })
        .margin({ right: 12 })
      Column() {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text(this.subtitle)
          .fontSize(12)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }
}

@Component
export struct SettingToggleRow {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop value: boolean = false;
  @Prop keyName: string = '';
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textTertiary: string = '#94A3B8';
  onToggleChange?: (key: string, isOn: boolean) => void;

  build() {
    Row() {
      Column() {
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text(this.subtitle)
          .fontSize(12)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.value })
        .selectedColor(this.selectedAccentColor)
        .onChange((isOn: boolean) => {
          if (this.onToggleChange !== undefined) {
            this.onToggleChange(this.keyName, isOn);
          }
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 12 })
  }
}

@Component
export struct SettingSelectRow {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop value: string = '';
  @Prop pickerType: string = '';
  @Prop pickerTitle: string = '';
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textTertiary: string = '#94A3B8';
  onOpenPicker?: (type: string, title: string) => void;

  build() {
    Row() {
      Column() {
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text(this.subtitle)
          .fontSize(12)
          .fontColor(this.textTertiary)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(this.value)
        .fontSize(13)
        .fontColor(this.selectedAccentColor)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .margin({ bottom: 12 })
    .onClick(() => {
      if (this.onOpenPicker !== undefined) {
        this.onOpenPicker(this.pickerType, this.pickerTitle);
      }
    })
  }
}

export type SettingPanelChange = (panel: SettingPanel) => void;
