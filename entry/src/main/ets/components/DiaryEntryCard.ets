﻿import { DiaryEntry } from '../model/ZapNoteTypes';

import { DiaryStatsUtils } from '../utils/DiaryStatsUtils';

@Component
export struct DiaryEntryCard {
  @Prop entry: DiaryEntry = {
    id: '',
    title: '',
    body: '',
    folderName: '',
    dateText: '',
    dateMs: 0,
    mood: '',
    weather: '',
    isToday: false,
    isThisWeek: false,
    isFavorite: false,
    isPrivate: false,
    wordCount: 0,
    hasPhoto: false,
    photoInBody: false,
    photoUri: '',
    photoUris: [],
    thumbnailPhotoIndex: 0,
    thumbnailScale: 1,
    thumbnailOffsetX: 0,
    thumbnailOffsetY: 0,
    thumbnailPhotoAspect: 1,
    photoX: 0,
    photoY: 0,
    photoWidth: 156,
    photoHeight: 118,
    photoRotation: 0,
    photoStyle: ''
  };
  @Prop isDark: boolean = false;
  @Prop accentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  @Prop showRecycleActions: boolean = false;
  @State private loadedThumbnailAspect: number = 0;
  onRestore?: (id: string) => void;
  onDeletePermanentlyRequest?: (id: string) => void;

  private displayDateText(): string {
    const dateText: string = DiaryStatsUtils.formatDateText(this.entry.dateMs);
    return dateText.length > 0 ? dateText : this.entry.dateText;
  }

  private tagText(): string {
    if (typeof this.entry.folderName !== 'string') {
      return '';
    }
    return this.entry.folderName.trim();
  }

  private hasThumbnail(): boolean {
    if (this.thumbnailUri().length > 0) {
      return true;
    }
    return this.entry.hasPhoto && typeof this.entry.photoUri === 'string' && this.entry.photoUri.trim().length > 0;
  }

  private thumbnailUri(): string {
    if (Array.isArray(this.entry.photoUris) && this.entry.photoUris.length > 0) {
      const requestedIndex: number = typeof this.entry.thumbnailPhotoIndex === 'number' ?
        Math.floor(this.entry.thumbnailPhotoIndex) : 0;
      if (requestedIndex >= 0 && requestedIndex < this.entry.photoUris.length) {
        const requestedUri: string = typeof this.entry.photoUris[requestedIndex] === 'string' ?
          this.entry.photoUris[requestedIndex].trim() : '';
        if (requestedUri.length > 0) {
          return requestedUri;
        }
      }
      for (let index = 0; index < this.entry.photoUris.length; index++) {
        const uri: string = typeof this.entry.photoUris[index] === 'string' ? this.entry.photoUris[index].trim() : '';
        if (uri.length > 0) {
          return uri;
        }
      }
    }
    return typeof this.entry.photoUri === 'string' ? this.entry.photoUri.trim() : '';
  }

  private photoImageSource(photoUri: string): string {
    const value: string = photoUri.trim();
    if (value.startsWith('/') && !value.startsWith('//')) {
      return 'file://' + value;
    }
    if (value.startsWith('file:/') && !value.startsWith('file://')) {
      return 'file://' + value.substring(6);
    }
    return value;
  }

  private thumbnailScale(): number {
    const value: number = typeof this.entry.thumbnailScale === 'number' ? this.entry.thumbnailScale : 1;
    return Math.max(1, Math.min(value, 4));
  }

  private thumbnailAspect(): number {
    if (this.loadedThumbnailAspect > 0) {
      return this.loadedThumbnailAspect;
    }
    const savedAspect: number = typeof this.entry.thumbnailPhotoAspect === 'number' ?
      this.entry.thumbnailPhotoAspect : 0;
    return savedAspect > 0 ? savedAspect : 1;
  }

  private hasCustomThumbnailTransform(): boolean {
    const offsetX: number = typeof this.entry.thumbnailOffsetX === 'number' ? this.entry.thumbnailOffsetX : 0;
    const offsetY: number = typeof this.entry.thumbnailOffsetY === 'number' ? this.entry.thumbnailOffsetY : 0;
    return Math.abs(this.thumbnailScale() - 1) > 0.001 || Math.abs(offsetX) > 0.001 || Math.abs(offsetY) > 0.001;
  }

  private thumbnailImageWidth(): number {
    const aspect: number = this.thumbnailAspect();
    return aspect >= 1 ? 76 * aspect : 76;
  }

  private thumbnailImageHeight(): number {
    const aspect: number = this.thumbnailAspect();
    return aspect >= 1 ? 76 : 76 / aspect;
  }

  private thumbnailOffset(value: number | undefined, imageSize: number): number {
    const normalized: number = typeof value === 'number' ? Math.max(-4, Math.min(value, 4)) : 0;
    const limit: number = Math.max((imageSize * this.thumbnailScale() - 76) / 2, 0);
    return Math.max(-limit, Math.min(normalized * 76, limit));
  }

  private accessibilityTitle(): string {
    const title: string = this.entry.title.trim();
    return title.length > 0 ? title : '无标题笔记';
  }

  private dangerBgColor(): string {
    return this.isDark ? '#3F151D' : '#FFF1F2';
  }

  private dangerLineColor(): string {
    return this.isDark ? '#7F1D1D' : '#FECACA';
  }

  @Builder
  private MetaChip(text: string) {
    Text(text)
      .width(38)
      .height(28)
      .textAlign(TextAlign.Center)
      .fontSize(16)
      .backgroundColor(this.inputBg)
      .border({ width: 1, color: this.lineColor, radius: 10 })
      .margin({ left: 8 })
  }

  @Builder
  private TagHint() {
    if (this.tagText().length > 0) {
      Text(this.tagText())
        .height(22)
        .constraintSize({ maxWidth: 92 })
        .padding({ left: 9, right: 9 })
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.accentColor)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .backgroundColor(this.isDark ? '#1E1B4B' : '#EEF2FF')
        .border({ width: 1, color: this.isDark ? '#3730A3' : '#C7D2FE', radius: 11 })
        .margin({ left: 8 })
    }
  }

  @Builder
  private PhotoThumb() {
    if (this.hasThumbnail()) {
      Stack({ alignContent: Alignment.Center }) {
        if (this.hasCustomThumbnailTransform()) {
          Image(this.photoImageSource(this.thumbnailUri()))
            .width(this.thumbnailImageWidth())
            .height(this.thumbnailImageHeight())
            .objectFit(ImageFit.Fill)
            .draggable(false)
            .scale({ x: this.thumbnailScale(), y: this.thumbnailScale(), centerX: '50%', centerY: '50%' })
            .translate({
              x: this.thumbnailOffset(this.entry.thumbnailOffsetX, this.thumbnailImageWidth()),
              y: this.thumbnailOffset(this.entry.thumbnailOffsetY, this.thumbnailImageHeight()),
              z: 0
            })
            .onComplete((event) => {
              if (event !== undefined && event.width > 0 && event.height > 0) {
                this.loadedThumbnailAspect = event.width / event.height;
              }
            })
        } else {
          Image(this.photoImageSource(this.thumbnailUri()))
            .width(76)
            .height(76)
            .objectFit(ImageFit.Cover)
            .draggable(false)
        }
      }
      .width(76)
      .height(76)
      .border({ width: 1, color: this.lineColor, radius: 14 })
      .clip(true)
      .margin({ left: 14 })
    }
  }

  @Builder
  private RecycleActions() {
    Divider()
      .width('100%')
      .height(1)
      .color(this.lineColor)
      .margin({ top: 18, bottom: 14 })

    Row() {
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Row() {
          Image($rawfile('icons/zap_editor_undo_dark.svg'))
            .width(19)
            .height(19)
            .objectFit(ImageFit.Contain)
            .margin({ right: 8 })
          Text('恢复笔记')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
      }
      .layoutWeight(1)
      .height(48)
      .backgroundColor(this.accentColor)
      .border({ radius: 12 })
      .accessibilityText('恢复' + this.accessibilityTitle())
      .accessibilityDescription('将这篇笔记恢复到笔记列表')
      .onClick(() => {
        if (this.onRestore !== undefined) {
          this.onRestore(this.entry.id);
        }
      })

      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Image(this.isDark ? $rawfile('icons/zap_editor_trash_dark.svg') : $rawfile('icons/zap_editor_trash.svg'))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
      }
      .width(48)
      .height(48)
      .backgroundColor(this.dangerBgColor())
      .border({ width: 1, color: this.dangerLineColor(), radius: 12 })
      .margin({ left: 8 })
      .accessibilityText('永久删除' + this.accessibilityTitle())
      .accessibilityDescription('永久删除后无法恢复')
      .onClick(() => {
        if (this.onDeletePermanentlyRequest !== undefined) {
          this.onDeletePermanentlyRequest(this.entry.id);
        }
      })
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Row() {
          Text(this.displayDateText())
            .fontSize(13)
            .fontColor(this.textTertiary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          this.TagHint()
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        this.MetaChip(this.entry.mood)
        this.MetaChip(this.entry.weather)
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row() {
        Column() {
          Text(this.entry.title)
            .width('100%')
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 12 })

          Text(this.entry.body)
            .width('100%')
            .fontSize(15)
            .lineHeight(24)
            .fontColor(this.textSecondary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)

        this.PhotoThumb()
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (this.showRecycleActions) {
        this.RecycleActions()
      }
    }
    .width('100%')
    .padding(22)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 22 })
    .shadow({ radius: 18, color: this.isDark ? '#33000000' : '#140F172A', offsetX: 0, offsetY: 8 })
    .hitTestBehavior(this.showRecycleActions ? HitTestMode.Default : HitTestMode.Transparent)
  }
}
