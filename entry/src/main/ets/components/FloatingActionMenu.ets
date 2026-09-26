@Component
export struct FloatingActionMenu {
  @Prop accentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop gripModeEnabled: boolean = false;
  @Prop gripOnLeft: boolean = false;
  onPhotoDraft?: () => void;
  onHandwrite?: () => void;

  private fabSize(): number {
    return 48;
  }

  private fabSideMargin(): number {
    return this.gripModeEnabled ? 16 : 24;
  }

  private fabBottomMargin(): number {
    return this.gripModeEnabled ? 112 : 122;
  }

  private useLeftSide(): boolean {
    return this.gripModeEnabled && this.gripOnLeft;
  }

  private menuWidth(): number {
    return 108;
  }

  @Builder
  private ActionMenu() {
    Menu() {
      MenuItem({ content: '\u7167\u7247\u8BC6\u522B' })
      .width(this.menuWidth())
      .height(48)
      .onClick(() => {
        if (this.onPhotoDraft !== undefined) {
          this.onPhotoDraft();
        }
      })

      MenuItem({ content: '\u624B\u5199\u65E5\u8BB0' })
      .width(this.menuWidth())
      .height(48)
      .onClick(() => {
        if (this.onHandwrite !== undefined) {
          this.onHandwrite();
        }
      })
    }
    .width(this.menuWidth())
    .fontColor(this.textPrimary)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 18 })
    .shadow({
      radius: 18,
      color: '#24000000',
      offsetX: 0,
      offsetY: 8
    })
  }

  build() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($rawfile('icons/zap_fab_pen_dark.svg'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
      }
        .width(this.fabSize())
        .height(this.fabSize())
        .backgroundColor(this.accentColor)
        .shadow({
          radius: 16,
          color: '#456366F1',
          offsetX: 0,
          offsetY: 6
        })
        .bindMenu(this.ActionMenu)
    }
    .width('100%')
    .justifyContent(this.useLeftSide() ? FlexAlign.Start : FlexAlign.End)
    .padding({
      left: this.fabSideMargin(),
      right: this.fabSideMargin()
    })
    .margin({ bottom: this.fabBottomMargin() })
    .hitTestBehavior(HitTestMode.Transparent)
    .animation({
      duration: 250,
      curve: Curve.EaseOut
    })
  }
}
