﻿import { common } from '@kit.AbilityKit';
import { curves, KeyboardAvoidMode, SymbolGlyphModifier, window } from '@kit.ArkUI';
import {
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  HdsNavigationMenuItemOptions,
  HdsTabs,
  IconStyleMode,
  hdsMaterial
} from '@kit.UIDesignKit';
import { createHdsSubPageTitleBarOptions } from '../components/HdsSubPageTitleBarOptions';
import { MOOD_OPTIONS, WEATHER_OPTIONS } from '../data/ZapNoteSeedData';
import { ValueOption } from '../model/ZapNoteTypes';

interface TextTakeResult {
  text: string;
  nextIndex: number;
  endedByNewline: boolean;
}

interface WrappedTextLine {
  id: string;
  leftText: string;
  rightText: string;
  leftWidth: number;
  gapWidth: number;
  rightWidth: number;
  leftStartIndex: number;
  leftEndIndex: number;
  rightStartIndex: number;
  rightEndIndex: number;
}

interface PhotoWrapBounds {
  left: number;
  right: number;
  top: number;
  bottom: number;
}

interface WrappedCaretPosition {
  visible: boolean;
  x: number;
  y: number;
}

interface EditorHistorySnapshot {
  title: string;
  body: string;
  bodySelectionEnd: number;
}

@Component
export struct DiaryEditorPage {
  @Prop editingId: string = '';
  @Prop draftTitle: string = '';
  @Prop draftBody: string = '';
  @Link draftFolderName: string;
  @Prop tagOptions: string[] = [];
  @Prop draftDateMs: number = 0;
  @Link draftMood: string;
  @Link draftWeather: string;
  @Link draftFavorite: boolean;
  @Prop draftHasPhoto: boolean = false;
  @Link draftPhotoUri: string;
  @Link draftPhotoUris: string[];
  @Link draftThumbnailPhotoIndex: number;
  @Link draftThumbnailScale: number;
  @Link draftThumbnailOffsetX: number;
  @Link draftThumbnailOffsetY: number;
  @Link draftThumbnailPhotoAspect: number;
  @Link draftPhotoX: number;
  @Link draftPhotoY: number;
  @Link draftPhotoWidth: number;
  @Link draftPhotoHeight: number;
  @Link draftPhotoRotation: number;
  @Link draftPhotoInBody: boolean;
  @Prop selectedPhotoStyle: string = 'original';
  @Prop materialEffectMode: number = 3;
  @Prop isDark: boolean = false;
  @Prop pageBg: string = '#F8FAFC';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  @Prop selectedAccentColor: string = '#6366F1';
  // The OCR review sheet is layered above the editor. While it owns focus,
  // keyboard changes must not move the editor underneath it.
  @Prop suspendKeyboardAvoidance: boolean = false;
  @State private titleEditing: boolean = false;
  @State private bodyEditing: boolean = false;
  @State private bodySelectionEnd: number = 0;
  @State private measuredBodyLineCount: number = 0;
  @State private bodyCaretAffinity: string = 'left';
  @State private activePhotoHandle: string = '';
  @State private photoSelected: boolean = false;
  @State private transformStartX: number = 0;
  @State private transformStartY: number = 0;
  @State private transformStartWidth: number = 156;
  @State private transformStartHeight: number = 118;
  @State private transformStartRotation: number = 0;
  @State private transformStartPhotoX: number = 0;
  @State private transformStartPhotoY: number = 0;
  @State private editorCanvasWidth: number = 0;
  @State private editorCanvasHeight: number = 0;
  @State private editorCanvasWindowX: number = 0;
  @State private editorCanvasWindowY: number = 0;
  private editorCanvasContentY: number = 0;
  @State private editorFormHeight: number = 0;
  @State private editorViewportHeight: number = 0;
  @State private editorViewportWindowY: number = 0;
  @State private wrapVersion: number = 0;
  @State private photoAspect: number = 118 / 156;
  @State private fittedPhotoUri: string = '';
  @Link photoPreviewOpen: boolean;
  @State private photoPreviewScale: number = 1;
  @State private photoPreviewPinchStartScale: number = 1;
  @State private photoPreviewSwipeLocked: boolean = false;
  @State private photoPreviewOffsetX: number = 0;
  @State private photoPreviewOffsetY: number = 0;
  @State private photoPreviewPanStartX: number = 0;
  @State private photoPreviewPanStartY: number = 0;
  @State private photoPreviewViewportWidth: number = 0;
  @State private photoPreviewViewportHeight: number = 0;
  @State private previewPhotoIndex: number = 0;
  @State private previewPhotoUri: string = '';
  @State private thumbnailAdjusting: boolean = false;
  @State private thumbnailWorkingScale: number = 1;
  @State private thumbnailWorkingOffsetX: number = 0;
  @State private thumbnailWorkingOffsetY: number = 0;
  @State private thumbnailWorkingAspect: number = 1;
  @State private tagMenuOpen: boolean = false;
  @State private tagCreating: boolean = false;
  @State private newTagName: string = '';
  @State private swipedTagName: string = '';
  @State private thumbnailPhotoUri: string = '';
  @State private thumbnailDragging: boolean = false;
  @State private canUndoEditor: boolean = false;
  @State private canRedoEditor: boolean = false;
  @State private pressedEditorActionIndex: number = -1;
  private bodyTouchStartX: number = 0;
  private bodyTouchStartY: number = 0;
  private bodyTouchCandidateIndex: number = 0;
  private bodyTouchCandidateAffinity: string = 'left';
  private bodyTouchMoved: boolean = false;
  private photoTouchStartX: number = 0;
  private photoTouchStartY: number = 0;
  private photoTouchStartPhotoX: number = 0;
  private photoTouchStartPhotoY: number = 0;
  private photoTouchDragging: boolean = false;
  private photoPreviewResetTimer: number = -1;
  private pendingPreviewDeleteUri: string = '';
  private thumbnailLongPressTimer: number = -1;
  private thumbnailTouchStartX: number = 0;
  private thumbnailTouchStartY: number = 0;
  private thumbnailDragReady: boolean = false;
  private thumbnailDragMoved: boolean = false;
  private suppressNextThumbnailClick: boolean = false;
  private thumbnailPanStartOffsetX: number = 0;
  private thumbnailPanStartOffsetY: number = 0;
  private thumbnailPinchStartScale: number = 1;
  private previousKeyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET;
  private keyboardAvoidModeConfigured: boolean = false;
  private keyboardWindow: window.Window | undefined = undefined;
  private keyboardHeightListenerRegistered: boolean = false;
  private keyboardWillShowListenerRegistered: boolean = false;
  private keyboardWillHideListenerRegistered: boolean = false;
  private keyboardDidShowListenerRegistered: boolean = false;
  private keyboardDidHideListenerRegistered: boolean = false;
  private navigationAvoidAreaListenerRegistered: boolean = false;
  @State private keyboardHeightVp: number = 0;
  @State private editorTabsKeyboardOffsetVp: number = 0;
  @State private keyboardScrollSpaceEnabled: boolean = false;
  @State private keyboardScrollAllowanceVp: number = 0;
  @State private navigationBottomInsetVp: number = 28;
  private pendingKeyboardCaretAdjustment: boolean = false;
  private keyboardCaretAdjustmentTimer: number = -1;
  private keyboardCaretAdjustmentAttempt: number = 0;
  private keyboardHideRestorationPending: boolean = false;
  private keyboardAutoScrollDistance: number = 0;
  private keyboardAutoScrollTracking: boolean = false;
  private keyboardAutoScrollTrackingGeneration: number = 0;
  private pageActive: boolean = false;
  private undoHistory: EditorHistorySnapshot[] = [];
  private redoHistory: EditorHistorySnapshot[] = [];
  private currentEditorSnapshot: EditorHistorySnapshot = { title: '', body: '', bodySelectionEnd: 0 };
  private editorHistoryReady: boolean = false;
  private applyingEditorHistory: boolean = false;
  private lastEditedField: string = 'body';
  private readonly maxEditorHistorySize: number = 100;
  private keyboardHeightCallback: Callback<number> = (height: number): void => {
    if (!this.pageActive) {
      return;
    }
    if (this.suspendKeyboardAvoidance) {
      this.keyboardHeightVp = 0;
      this.editorTabsKeyboardOffsetVp = 0;
      this.keyboardScrollSpaceEnabled = false;
      this.keyboardScrollAllowanceVp = 0;
      this.keyboardAutoScrollTracking = false;
      this.pendingKeyboardCaretAdjustment = false;
      return;
    }
    const previousHeightVp: number = this.keyboardHeightVp;
    const nextHeightVp: number = this.keyboardHeightToVp(height);
    this.updateKeyboardTargetHeight(nextHeightVp);
    if (nextHeightVp > 0 &&
      (!this.keyboardWillShowListenerRegistered || previousHeightVp > 0)) {
      this.animateEditorTabsKeyboardOffset(nextHeightVp);
    } else if (nextHeightVp <= 0 && previousHeightVp > 0 &&
      !this.keyboardWillHideListenerRegistered) {
      this.animateEditorTabsKeyboardOffset(0);
    }
  };
  private keyboardWillShowCallback: Callback<window.KeyboardInfo> = (info: window.KeyboardInfo): void => {
    if (!this.pageActive || this.suspendKeyboardAvoidance) {
      return;
    }
    const targetHeightVp: number = this.keyboardInfoEndHeightVp(info);
    if (targetHeightVp <= 0) {
      return;
    }
    this.updateKeyboardTargetHeight(targetHeightVp);
    this.animateEditorTabsKeyboardOffset(targetHeightVp, info);
  };
  private keyboardWillHideCallback: Callback<window.KeyboardInfo> = (info: window.KeyboardInfo): void => {
    if (!this.pageActive) {
      return;
    }
    this.animateEditorTabsKeyboardOffset(0, info);
  };
  private keyboardDidShowCallback: Callback<window.KeyboardInfo> = (info: window.KeyboardInfo): void => {
    if (!this.pageActive || this.suspendKeyboardAvoidance) {
      return;
    }
    const targetHeightVp: number = this.keyboardInfoEndHeightVp(info);
    if (targetHeightVp <= 0) {
      return;
    }
    this.updateKeyboardTargetHeight(targetHeightVp);
    this.editorTabsKeyboardOffsetVp = targetHeightVp;
  };
  private keyboardDidHideCallback: Callback<window.KeyboardInfo> = (_info: window.KeyboardInfo): void => {
    if (!this.pageActive) {
      return;
    }
    this.editorTabsKeyboardOffsetVp = 0;
    if (this.suspendKeyboardAvoidance) {
      this.keyboardHeightVp = 0;
      this.pendingKeyboardCaretAdjustment = false;
      return;
    }
    this.updateKeyboardTargetHeight(0);
  };
  private navigationAvoidAreaChangeCallback: Callback<window.AvoidAreaOptions> =
    (options: window.AvoidAreaOptions): void => {
      if (!this.pageActive || options.type !== window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        return;
      }
      this.updateNavigationBottomInset(options.area);
    };
  onClose?: () => void;
  onSave?: () => void;
  onDeleteRequest?: () => void;
  onOpenPicker?: (type: string, title: string) => void;
  onCreateTag?: (value: string) => void;
  onDeleteTagRequest?: (value: string) => void;
  onDeletePhotoRequest?: (photoUri: string) => void;
  onDraftTitleChange?: (value: string) => void;
  onDraftBodyChange?: (value: string) => void;
  onDraftFavoriteChange?: (value: boolean) => void;
  onDraftHasPhotoChange?: (value: boolean) => void;

  private scroller: Scroller = new Scroller();
  private thumbnailScroller: Scroller = new Scroller();
  private bodyTextAreaController: TextAreaController = new TextAreaController();
  private readonly bodyTextAreaId: string = 'diary-editor-body-input';
  aboutToAppear(): void {
    this.pageActive = true;
    this.initializeEditorHistory();
    this.enableKeyboardAvoidance();
    this.registerKeyboardListeners();
    this.scheduleBodyLineCountMeasure();
  }

  aboutToDisappear(): void {
    this.pageActive = false;
    this.keyboardHeightVp = 0;
    this.editorTabsKeyboardOffsetVp = 0;
    this.keyboardScrollSpaceEnabled = false;
    this.keyboardScrollAllowanceVp = 0;
    this.keyboardHideRestorationPending = false;
    this.keyboardAutoScrollDistance = 0;
    this.keyboardAutoScrollTracking = false;
    this.pendingKeyboardCaretAdjustment = false;
    this.clearKeyboardCaretAdjustmentTimer();
    this.clearPhotoPreviewResetTimer();
    this.clearThumbnailLongPressTimer();
    this.unregisterKeyboardListeners();
    this.restoreKeyboardAvoidance();
  }

  private copyEditorSnapshot(snapshot: EditorHistorySnapshot): EditorHistorySnapshot {
    return {
      title: snapshot.title,
      body: snapshot.body,
      bodySelectionEnd: snapshot.bodySelectionEnd
    };
  }

  private initializeEditorHistory(): void {
    this.undoHistory = [];
    this.redoHistory = [];
    this.currentEditorSnapshot = {
      title: this.draftTitle,
      body: this.draftBody,
      bodySelectionEnd: this.clampNumber(this.bodySelectionEnd, 0, this.draftBody.length)
    };
    this.editorHistoryReady = true;
    this.applyingEditorHistory = false;
    this.updateEditorHistoryAvailability();
  }

  private editorSnapshotsEqual(left: EditorHistorySnapshot, right: EditorHistorySnapshot): boolean {
    return left.title === right.title && left.body === right.body;
  }

  private updateEditorHistoryAvailability(): void {
    this.canUndoEditor = this.undoHistory.length > 0;
    this.canRedoEditor = this.redoHistory.length > 0;
  }

  private appendEditorHistory(history: EditorHistorySnapshot[], snapshot: EditorHistorySnapshot): void {
    history.push(this.copyEditorSnapshot(snapshot));
    if (history.length > this.maxEditorHistorySize) {
      history.shift();
    }
  }

  private recordEditorSnapshot(nextSnapshot: EditorHistorySnapshot): void {
    if (!this.editorHistoryReady) {
      this.initializeEditorHistory();
    }
    if (this.applyingEditorHistory) {
      this.currentEditorSnapshot = this.copyEditorSnapshot(nextSnapshot);
      return;
    }
    if (this.editorSnapshotsEqual(this.currentEditorSnapshot, nextSnapshot)) {
      this.currentEditorSnapshot = this.copyEditorSnapshot(nextSnapshot);
      return;
    }
    this.appendEditorHistory(this.undoHistory, this.currentEditorSnapshot);
    this.redoHistory = [];
    this.currentEditorSnapshot = this.copyEditorSnapshot(nextSnapshot);
    this.updateEditorHistoryAvailability();
  }

  private recordTitleChange(value: string): void {
    this.lastEditedField = 'title';
    this.recordEditorSnapshot({
      title: value,
      body: this.currentEditorSnapshot.body,
      bodySelectionEnd: this.currentEditorSnapshot.bodySelectionEnd
    });
  }

  private recordBodyChange(value: string): void {
    this.lastEditedField = 'body';
    this.recordEditorSnapshot({
      title: this.currentEditorSnapshot.title,
      body: value,
      bodySelectionEnd: this.bodySelectionEnd
    });
  }

  private applyEditorSnapshot(snapshot: EditorHistorySnapshot): void {
    const restoredSnapshot: EditorHistorySnapshot = this.copyEditorSnapshot(snapshot);
    this.applyingEditorHistory = true;
    this.currentEditorSnapshot = restoredSnapshot;
    this.bodySelectionEnd = this.clampNumber(restoredSnapshot.bodySelectionEnd, 0, restoredSnapshot.body.length);
    if (this.onDraftTitleChange !== undefined) {
      this.onDraftTitleChange(restoredSnapshot.title);
    }
    if (this.onDraftBodyChange !== undefined) {
      this.onDraftBodyChange(restoredSnapshot.body);
    }
    this.refreshWrappedTextLayout();
    this.scheduleWhenActive((): void => {
      this.applyingEditorHistory = false;
      if (this.lastEditedField === 'body') {
        this.focusBodyTextArea();
        this.bodyTextAreaController.caretPosition(this.bodySelectionEnd);
      }
    }, 0);
    this.scheduleWhenActive((): void => {
      if (this.lastEditedField === 'body') {
        this.bodyTextAreaController.caretPosition(this.bodySelectionEnd);
      }
      this.refreshWrappedTextLayout();
    }, 32);
  }

  private undoEditorChange(): void {
    if (!this.editorHistoryReady) {
      this.initializeEditorHistory();
    }
    const previousSnapshot: EditorHistorySnapshot | undefined = this.undoHistory.pop();
    if (previousSnapshot === undefined) {
      this.updateEditorHistoryAvailability();
      return;
    }
    this.appendEditorHistory(this.redoHistory, this.currentEditorSnapshot);
    this.currentEditorSnapshot = this.copyEditorSnapshot(previousSnapshot);
    this.updateEditorHistoryAvailability();
    this.applyEditorSnapshot(previousSnapshot);
  }

  private redoEditorChange(): void {
    if (!this.editorHistoryReady) {
      this.initializeEditorHistory();
    }
    const nextSnapshot: EditorHistorySnapshot | undefined = this.redoHistory.pop();
    if (nextSnapshot === undefined) {
      this.updateEditorHistoryAvailability();
      return;
    }
    this.appendEditorHistory(this.undoHistory, this.currentEditorSnapshot);
    this.currentEditorSnapshot = this.copyEditorSnapshot(nextSnapshot);
    this.updateEditorHistoryAvailability();
    this.applyEditorSnapshot(nextSnapshot);
  }

  private enableKeyboardAvoidance(): void {
    try {
      const uiContext = this.getUIContext();
      this.previousKeyboardAvoidMode = uiContext.getKeyboardAvoidMode();
      uiContext.setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
      this.keyboardAvoidModeConfigured = true;
    } catch (error) {
      console.error('DiaryEditorPage enableKeyboardAvoidance failed: ' + JSON.stringify(error));
    }
  }

  private restoreKeyboardAvoidance(): void {
    if (!this.keyboardAvoidModeConfigured) {
      return;
    }
    try {
      this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode);
      this.keyboardAvoidModeConfigured = false;
    } catch (error) {
      console.error('DiaryEditorPage restoreKeyboardAvoidance failed: ' + JSON.stringify(error));
    }
  }

  private keyboardInfoEndHeightVp(info: window.KeyboardInfo): number {
    return this.keyboardHeightToVp(Math.max(info.endRect.height, 0));
  }

  private updateKeyboardTargetHeight(nextHeightVp: number): void {
    const previousHeightVp: number = this.keyboardHeightVp;
    this.keyboardHeightVp = Math.max(nextHeightVp, 0);
    if (this.keyboardHeightVp > 0 && previousHeightVp <= 0) {
      this.keyboardAutoScrollDistance = 0;
      this.keyboardAutoScrollTracking = false;
      this.keyboardHideRestorationPending = false;
    }
    this.pendingKeyboardCaretAdjustment = this.keyboardHeightVp > 0;
    if (this.keyboardHeightVp > 0) {
      this.adjustBodyCaretDuringKeyboardShow();
    } else if (previousHeightVp > 0) {
      this.handleKeyboardHidden();
    }
  }

  private keyboardAnimationDuration(config: window.WindowAnimationConfig | undefined): number {
    if (config === undefined || config.duration === undefined) {
      return 250;
    }
    return this.clampNumber(config.duration, 0, 3000);
  }

  private keyboardAnimationCurve(config: window.WindowAnimationConfig | undefined): Curve | ICurve {
    if (config === undefined) {
      return Curve.FastOutSlowIn;
    }
    const params: number[] = config.param ?? [];
    if (config.curve === window.WindowAnimationCurve.CUBIC_BEZIER && params.length === 4) {
      return curves.cubicBezierCurve(params[0], params[1], params[2], params[3]);
    }
    if (config.curve === window.WindowAnimationCurve.INTERPOLATION_SPRING && params.length === 4) {
      return curves.interpolatingSpring(params[0], params[1], params[2], params[3]);
    }
    return config.curve === window.WindowAnimationCurve.LINEAR ? Curve.Linear : Curve.FastOutSlowIn;
  }

  private animateEditorTabsKeyboardOffset(targetOffsetVp: number, info?: window.KeyboardInfo): void {
    const target: number = this.suspendKeyboardAvoidance ? 0 : Math.max(targetOffsetVp, 0);
    if (!this.pageActive || Math.abs(target - this.editorTabsKeyboardOffsetVp) <= 0.5) {
      this.editorTabsKeyboardOffsetVp = target;
      return;
    }
    const config: window.WindowAnimationConfig | undefined = info?.config;
    const duration: number = this.keyboardAnimationDuration(config);
    const isTimedAnimation: boolean = config?.curve !== window.WindowAnimationCurve.INTERPOLATION_SPRING;
    if (info?.animated === false || (isTimedAnimation && duration <= 0)) {
      this.editorTabsKeyboardOffsetVp = target;
      return;
    }
    this.getUIContext().animateTo({
      duration: duration,
      curve: this.keyboardAnimationCurve(config)
    }, () => {
      this.editorTabsKeyboardOffsetVp = target;
    });
  }

  private async registerKeyboardListeners(): Promise<void> {
    if (!this.pageActive) {
      return;
    }
    try {
      const hostContext: common.Context | undefined = this.getUIContext().getHostContext() as common.Context | undefined;
      if (hostContext === undefined) {
        return;
      }
      const mainWindow: window.Window = await window.getLastWindow(hostContext);
      if (!this.pageActive) {
        return;
      }
      this.keyboardWindow = mainWindow;
      this.refreshNavigationBottomInset(mainWindow);
      if (!this.keyboardHeightListenerRegistered) {
        mainWindow.on('keyboardHeightChange', this.keyboardHeightCallback);
        this.keyboardHeightListenerRegistered = true;
      }
      if (!this.keyboardWillShowListenerRegistered) {
        try {
          mainWindow.on('keyboardWillShow', this.keyboardWillShowCallback);
          this.keyboardWillShowListenerRegistered = true;
        } catch (error) {
          console.error('DiaryEditorPage register keyboardWillShow failed: ' + JSON.stringify(error));
        }
      }
      if (!this.keyboardWillHideListenerRegistered) {
        try {
          mainWindow.on('keyboardWillHide', this.keyboardWillHideCallback);
          this.keyboardWillHideListenerRegistered = true;
        } catch (error) {
          console.error('DiaryEditorPage register keyboardWillHide failed: ' + JSON.stringify(error));
        }
      }
      if (!this.keyboardDidShowListenerRegistered) {
        try {
          mainWindow.on('keyboardDidShow', this.keyboardDidShowCallback);
          this.keyboardDidShowListenerRegistered = true;
        } catch (error) {
          console.error('DiaryEditorPage register keyboardDidShow failed: ' + JSON.stringify(error));
        }
      }
      if (!this.keyboardDidHideListenerRegistered) {
        try {
          mainWindow.on('keyboardDidHide', this.keyboardDidHideCallback);
          this.keyboardDidHideListenerRegistered = true;
        } catch (error) {
          console.error('DiaryEditorPage register keyboardDidHide failed: ' + JSON.stringify(error));
        }
      }
      if (!this.navigationAvoidAreaListenerRegistered) {
        try {
          mainWindow.on('avoidAreaChange', this.navigationAvoidAreaChangeCallback);
          this.navigationAvoidAreaListenerRegistered = true;
        } catch (error) {
          console.error('DiaryEditorPage register avoidAreaChange failed: ' + JSON.stringify(error));
        }
      }
    } catch (error) {
      console.error('DiaryEditorPage registerKeyboardListeners failed: ' + JSON.stringify(error));
    }
  }

  private unregisterKeyboardListeners(): void {
    if (this.keyboardWindow === undefined) {
      return;
    }
    try {
      if (this.keyboardHeightListenerRegistered) {
        this.keyboardWindow.off('keyboardHeightChange', this.keyboardHeightCallback);
        this.keyboardHeightListenerRegistered = false;
      }
      if (this.keyboardWillShowListenerRegistered) {
        this.keyboardWindow.off('keyboardWillShow', this.keyboardWillShowCallback);
        this.keyboardWillShowListenerRegistered = false;
      }
      if (this.keyboardWillHideListenerRegistered) {
        this.keyboardWindow.off('keyboardWillHide', this.keyboardWillHideCallback);
        this.keyboardWillHideListenerRegistered = false;
      }
      if (this.keyboardDidShowListenerRegistered) {
        this.keyboardWindow.off('keyboardDidShow', this.keyboardDidShowCallback);
        this.keyboardDidShowListenerRegistered = false;
      }
      if (this.keyboardDidHideListenerRegistered) {
        this.keyboardWindow.off('keyboardDidHide', this.keyboardDidHideCallback);
        this.keyboardDidHideListenerRegistered = false;
      }
      if (this.navigationAvoidAreaListenerRegistered) {
        this.keyboardWindow.off('avoidAreaChange', this.navigationAvoidAreaChangeCallback);
        this.navigationAvoidAreaListenerRegistered = false;
      }
      this.keyboardWindow = undefined;
    } catch (error) {
      console.error('DiaryEditorPage unregisterKeyboardListeners failed: ' + JSON.stringify(error));
    }
  }

  private handleKeyboardHidden(): void {
    this.pendingKeyboardCaretAdjustment = false;
    this.keyboardCaretAdjustmentAttempt = 6;
    this.clearKeyboardCaretAdjustmentTimer();
    this.keyboardAutoScrollTracking = false;
    this.bodyEditing = false;
    if (this.keyboardScrollSpaceEnabled && this.keyboardScrollAllowanceVp > 0 &&
      !this.keyboardHideRestorationPending) {
      this.keyboardHideRestorationPending = true;
      this.animateKeyboardScrollBack();
    }
  }

  private defaultTitle(): string {
    const today: Date = new Date();
    return today.getFullYear().toString() + '年' + (today.getMonth() + 1).toString() + '月' +
      today.getDate().toString() + '日 · 随想笔记';
  }

  private editorTitleText(): string {
    return this.editingId.length > 0 ? '未命名笔记' : this.defaultTitle();
  }

  private bodyPlaceholder(): string {
    if (this.showWrappedBodyPreview()) {
      return '';
    }
    return '【今日启示】「心之所向，行之所往。记录即是思绪的延伸。」\n随想笔迹，';
  }

  private pad2(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
  }

  private editorTimeText(): string {
    const normalized: number = this.draftDateMs > 0 ? this.draftDateMs : Date.now();
    const date: Date = new Date(normalized);
    const weekLabels: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return this.pad2(date.getMonth() + 1) + '/' + this.pad2(date.getDate()) + ' ' +
      weekLabels[date.getDay()] + ' ' + this.pad2(date.getHours()) + ':' + this.pad2(date.getMinutes());
  }

  private folderButtonText(): string {
    const value: string = this.draftFolderName.trim();
    return value.length > 0 ? value : '无标签';
  }

  private normalizedTagOptions(): string[] {
    const result: string[] = [''];
    this.tagOptions.forEach((item: string) => {
      const value: string = item.trim();
      if (value.length > 0 && result.indexOf(value) < 0) {
        result.push(value);
      }
    });
    const current: string = this.draftFolderName.trim();
    if (current.length > 0 && result.indexOf(current) < 0) {
      result.push(current);
    }
    return result;
  }

  private tagLabel(value: string): string {
    return value.length > 0 ? value : '无标签';
  }

  private tagMenuWidth(): number {
    return 176;
  }

  private applyTag(value: string): void {
    this.draftFolderName = value.trim();
    this.tagCreating = false;
    this.swipedTagName = '';
    this.tagMenuOpen = true;
  }

  private createTagFromMenu(): void {
    const value: string = this.newTagName.trim();
    if (value.length === 0) {
      return;
    }
    this.draftFolderName = value;
    this.tagCreating = false;
    this.newTagName = '';
    this.swipedTagName = '';
    this.tagMenuOpen = true;
    if (this.onCreateTag !== undefined) {
      this.onCreateTag(value);
    }
  }

  private requestDeleteTag(value: string): void {
    const tagName: string = value.trim();
    if (tagName.length === 0) {
      return;
    }
    this.swipedTagName = '';
    this.tagMenuOpen = true;
    if (this.onDeleteTagRequest !== undefined) {
      this.onDeleteTagRequest(tagName);
    }
  }

  private showWrappedBodyPreview(): boolean {
    return this.draftPhotoInBody && this.hasVisiblePhoto();
  }

  private restoreEditorScrollOffset(offset: OffsetResult): void {
    this.scheduleWhenActive((): void => {
      this.scroller.scrollTo({ xOffset: offset.xOffset, yOffset: this.clampEditorYOffset(offset.yOffset), animation: false });
    }, 0);
    this.scheduleWhenActive((): void => {
      this.scroller.scrollTo({ xOffset: offset.xOffset, yOffset: this.clampEditorYOffset(offset.yOffset), animation: false });
    }, 80);
  }

  private plainCaretLineIndex(): number {
    const caretIndex: number = this.bodyCaretIndex();
    const beforeCaret: string = this.draftBody.substring(0, caretIndex);
    const rowWidth: number = Math.max(this.bodyLayoutWidth(), 40);
    let lineIndex: number = 0;
    const paragraphs: string[] = beforeCaret.split('\n');
    paragraphs.forEach((text: string, index: number): void => {
      const lineCount: number = Math.max(Math.ceil(this.estimatedTextWidth(text) / rowWidth), 1);
      lineIndex += index < paragraphs.length - 1 ? lineCount : Math.max(lineCount - 1, 0);
    });
    return Math.max(lineIndex, 0);
  }

  private bodyCaretBottomForKeyboard(): number {
    if (this.showWrappedBodyPreview()) {
      return this.wrappedCaretPosition().y + this.inlineCaretHeight();
    }
    try {
      const caretOffset: CaretOffset = this.bodyTextAreaController.getCaretOffset();
      const caretTopVp: number = this.getUIContext().px2vp(caretOffset.y);
      if (caretTopVp >= 0) {
        return caretTopVp + this.inlineCaretHeight();
      }
    } catch (_error) {
    }
    return this.plainCaretLineIndex() * this.bodyLineHeight() + this.inlineCaretTop() +
      this.inlineCaretHeight();
  }

  private keyboardHeightToVp(height: number): number {
    if (height <= 0) {
      return 0;
    }
    try {
      return Math.max(this.getUIContext().px2vp(height), 0);
    } catch (error) {
      console.error('DiaryEditorPage keyboardHeightToVp failed: ' + JSON.stringify(error));
      return 0;
    }
  }

  private updateNavigationBottomInset(avoidArea: window.AvoidArea): void {
    let navigationHeightVp: number = 0;
    if (avoidArea.visible && avoidArea.bottomRect.height > 0) {
      try {
        navigationHeightVp = this.getUIContext().px2vp(avoidArea.bottomRect.height);
      } catch (error) {
        console.error('DiaryEditorPage navigation avoid area conversion failed: ' + JSON.stringify(error));
      }
    }
    this.navigationBottomInsetVp = Math.max(navigationHeightVp, 28);
  }

  private refreshNavigationBottomInset(mainWindow: window.Window): void {
    try {
      const avoidArea: window.AvoidArea = mainWindow.getWindowAvoidArea(
        window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      this.updateNavigationBottomInset(avoidArea);
    } catch (error) {
      this.navigationBottomInsetVp = 28;
      console.error('DiaryEditorPage refresh navigation avoid area failed: ' + JSON.stringify(error));
    }
  }

  private navigationSafeBottomInset(): number {
    return Math.max(this.navigationBottomInsetVp, 28);
  }

  private clampEditorYOffset(yOffset: number): number {
    const safeYOffset: number = Math.max(yOffset, 0);
    if (this.editorFormHeight <= 0 || this.editorViewportHeight <= 0) {
      return safeYOffset;
    }
    const maxYOffset: number = Math.max(this.editorFormHeight - this.editorViewportHeight, 0);
    return this.clampNumber(safeYOffset, 0, maxYOffset);
  }

  private keyboardFollowAnimation(): ScrollAnimationOptions {
    return { duration: 140, curve: Curve.EaseOut, canOverScroll: false };
  }

  private adjustBodyCaretAboveKeyboard(animation: ScrollAnimationOptions | boolean): void {
    if (this.suspendKeyboardAvoidance || this.keyboardHeightVp <= 0 || this.lastEditedField !== 'body' ||
      this.activePhotoHandle.length > 0 || this.photoTouchDragging) {
      return;
    }
    const viewportBottom: number = this.editorViewportWindowY + (this.editorViewportHeight > 0 ? this.editorViewportHeight : 760);
    const toolbarTop: number = viewportBottom - this.keyboardHeightVp - this.editorTabsBarHeight();
    const offset: OffsetResult = this.scroller.currentOffset();
    const canvasWindowY: number = this.editorCanvasContentY > 0 ?
      this.editorViewportWindowY + this.editorCanvasContentY - offset.yOffset : this.editorCanvasWindowY;
    const caretBottom: number = canvasWindowY + this.bodyCaretBottomForKeyboard();
    const coveredDistance: number = caretBottom - toolbarTop;
    // Do not move content that is still clear of the toolbar. Once the caret
    // actually enters the toolbar area, restore a half-character gap.
    if (coveredDistance > 0) {
      this.keyboardScrollSpaceEnabled = true;
      this.keyboardScrollAllowanceVp = this.keyboardScrollAllowanceValue();
      const scrollDistance: number = coveredDistance + this.keyboardCaretGap();
      const targetY: number = this.clampEditorYOffset(offset.yOffset + scrollDistance);
      if (targetY - offset.yOffset > 0) {
        this.beginKeyboardAutoScrollTracking(animation);
        this.scroller.scrollTo({ xOffset: offset.xOffset, yOffset: targetY, animation: animation });
      }
    }
  }

  private adjustBodyCaretDuringKeyboardShow(): void {
    if (this.suspendKeyboardAvoidance || this.keyboardHeightVp <= 0) {
      return;
    }
    // Keep one retry chain alive while the keyboard/layout is settling. Do
    // not restart it on every intermediate area or selection callback.
    if (this.keyboardCaretAdjustmentTimer >= 0) {
      return;
    }
    this.clearKeyboardCaretAdjustmentTimer();
    this.keyboardCaretAdjustmentAttempt = 0;
    this.scheduleKeyboardCaretAdjustmentRetry();
  }

  private scheduleKeyboardCaretAdjustmentRetry(): void {
    const attempt: number = this.keyboardCaretAdjustmentAttempt;
    const delay: number = attempt === 0 ? 0 : (attempt === 1 ? 32 :
      (attempt === 2 ? 96 : (attempt === 3 ? 180 : (attempt === 4 ? 320 : 520))));
    this.keyboardCaretAdjustmentTimer = setTimeout((): void => {
      this.keyboardCaretAdjustmentTimer = -1;
      if (this.pageActive && !this.suspendKeyboardAvoidance && this.keyboardHeightVp > 0) {
        this.adjustBodyCaretAboveKeyboard(this.keyboardFollowAnimation());
        this.keyboardCaretAdjustmentAttempt = attempt + 1;
        if (this.keyboardCaretAdjustmentAttempt < 6) {
          this.scheduleKeyboardCaretAdjustmentRetry();
        }
      }
    }, delay);
  }

  private keyboardScrollAllowanceWithoutKeyboard(): number {
    return this.keyboardScrollAllowanceVp;
  }

  private clampEditorYOffsetWithoutKeyboardSpace(yOffset: number): number {
    const safeYOffset: number = Math.max(yOffset, 0);
    if (this.editorFormHeight <= 0 || this.editorViewportHeight <= 0) {
      return safeYOffset;
    }
    const formHeightWithoutKeyboard: number = Math.max(
      this.editorFormHeight - this.keyboardScrollAllowanceWithoutKeyboard(), 0);
    const maxYOffset: number = Math.max(formHeightWithoutKeyboard - this.editorViewportHeight, 0);
    return this.clampNumber(safeYOffset, 0, maxYOffset);
  }

  private keyboardRestoreDuration(distance: number): number {
    return this.clampNumber(120 + distance * 0.5, 120, 460);
  }

  private beginKeyboardAutoScrollTracking(animation: ScrollAnimationOptions | boolean): void {
    this.keyboardAutoScrollTracking = true;
    const generation: number = this.keyboardAutoScrollTrackingGeneration + 1;
    this.keyboardAutoScrollTrackingGeneration = generation;
    const finishDelay: number = animation === false ? 0 : 180;
    this.scheduleWhenActive((): void => {
      if (this.keyboardAutoScrollTrackingGeneration === generation) {
        this.keyboardAutoScrollTracking = false;
      }
    }, finishDelay);
  }

  private animateKeyboardScrollBack(): void {
    const animateBack = (): void => {
      if (!this.pageActive) {
        return;
      }
      const currentOffset: OffsetResult = this.scroller.currentOffset();
      const targetY: number = this.clampEditorYOffsetWithoutKeyboardSpace(
        currentOffset.yOffset - this.keyboardAutoScrollDistance);
      const distance: number = Math.max(currentOffset.yOffset - targetY, 0);
      if (distance <= 0.5) {
        this.keyboardScrollSpaceEnabled = false;
        this.keyboardScrollAllowanceVp = 0;
        this.keyboardHideRestorationPending = false;
        this.keyboardAutoScrollDistance = 0;
        return;
      }
      this.scroller.scrollTo({
        xOffset: currentOffset.xOffset,
        yOffset: targetY,
        animation: {
          duration: this.keyboardRestoreDuration(distance),
          curve: Curve.EaseOut,
          canOverScroll: false
        }
      });
      const finishDelay: number = this.keyboardRestoreDuration(distance) + 32;
      this.scheduleWhenActive((): void => {
        this.keyboardScrollSpaceEnabled = false;
        this.keyboardScrollAllowanceVp = 0;
        this.keyboardHideRestorationPending = false;
        this.keyboardAutoScrollDistance = 0;
      }, finishDelay);
    };
    this.scheduleWhenActive(animateBack, 32);
  }

  private clearKeyboardCaretAdjustmentTimer(): void {
    if (this.keyboardCaretAdjustmentTimer >= 0) {
      clearTimeout(this.keyboardCaretAdjustmentTimer);
      this.keyboardCaretAdjustmentTimer = -1;
    }
  }

  private scheduleWhenActive(action: () => void, delay: number): void {
    setTimeout((): void => {
      if (this.pageActive) {
        action();
      }
    }, delay);
  }

  private stopBodyEditing(): void {
    const offset: OffsetResult = this.scroller.currentOffset();
    if (this.bodyEditing) {
      this.bodyTextAreaController.stopEditing();
      this.restoreEditorScrollOffset(offset);
    }
    this.bodyEditing = false;
  }

  private focusBodyTextArea(): void {
    try {
      this.getUIContext().getFocusController().requestFocus(this.bodyTextAreaId);
    } catch (error) {
      console.error('DiaryEditorPage focusBodyTextArea failed: ' + JSON.stringify(error));
    }
  }

  private requestSave(): void {
    if (this.onSave !== undefined) {
      this.onSave();
    }
  }

  private optionLabel(options: ValueOption[], value: string): string {
    let label = value;
    options.forEach((item: ValueOption): void => {
      if (item.value === value) {
        label = item.label;
      }
    });
    return label;
  }

  private metaValue(type: string): string {
    return type === 'weather' ? this.draftWeather : this.draftMood;
  }

  private openMetaPicker(type: string, title: string): void {
    if (this.onOpenPicker !== undefined) {
      this.onOpenPicker(type, title);
    }
  }

  private clampNumber(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  }

  private normalizePhotoUris(value: string[]): string[] {
    const result: string[] = [];
    value.forEach((item: string) => {
      const uri: string = typeof item === 'string' ? item.trim() : '';
      if (uri.length > 0 && result.indexOf(uri) < 0) {
        result.push(uri);
      }
    });
    return result;
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

  private allThumbnailPhotoUris(): string[] {
    return this.normalizePhotoUris(this.draftPhotoUris);
  }

  private previewPhotoUris(): string[] {
    const photoUris: string[] = this.allThumbnailPhotoUris();
    if (photoUris.length > 0) {
      return photoUris;
    }
    const photoUri: string = this.draftPhotoUri.trim();
    return photoUri.length > 0 ? [photoUri] : [];
  }

  private firstThumbnailPhotoUri(): string {
    const photoUris: string[] = this.previewPhotoUris();
    if (photoUris.length === 0) {
      return '';
    }
    const index: number = Math.floor(this.clampNumber(this.draftThumbnailPhotoIndex, 0, photoUris.length - 1));
    return photoUris[index];
  }

  private isCurrentPreviewThumbnail(): boolean {
    const photoUris: string[] = this.previewPhotoUris();
    if (photoUris.length === 0) {
      return false;
    }
    const thumbnailIndex: number = Math.floor(this.clampNumber(
      this.draftThumbnailPhotoIndex, 0, photoUris.length - 1));
    return thumbnailIndex === this.previewPhotoIndex;
  }

  private setCurrentPreviewAsThumbnail(): void {
    const photoUris: string[] = this.previewPhotoUris();
    if (photoUris.length === 0) {
      return;
    }
    this.draftThumbnailPhotoIndex = Math.floor(this.clampNumber(this.previewPhotoIndex, 0, photoUris.length - 1));
  }

  private beginThumbnailAdjustment(): void {
    const samePhoto: boolean = this.isCurrentPreviewThumbnail();
    this.thumbnailWorkingScale = samePhoto ? this.clampNumber(this.draftThumbnailScale, 1, 4) : 1;
    this.thumbnailWorkingOffsetX = samePhoto ? this.draftThumbnailOffsetX : 0;
    this.thumbnailWorkingOffsetY = samePhoto ? this.draftThumbnailOffsetY : 0;
    this.thumbnailWorkingAspect = samePhoto && this.draftThumbnailPhotoAspect > 0 ?
      this.draftThumbnailPhotoAspect : 1;
    this.thumbnailPinchStartScale = this.thumbnailWorkingScale;
    this.thumbnailAdjusting = true;
    this.clampThumbnailWorkingOffset();
  }

  private cancelThumbnailAdjustment(): void {
    this.thumbnailAdjusting = false;
  }

  private confirmThumbnailAdjustment(): void {
    this.setCurrentPreviewAsThumbnail();
    this.draftThumbnailScale = this.thumbnailWorkingScale;
    this.draftThumbnailOffsetX = this.thumbnailWorkingOffsetX;
    this.draftThumbnailOffsetY = this.thumbnailWorkingOffsetY;
    this.draftThumbnailPhotoAspect = this.thumbnailWorkingAspect;
    this.thumbnailAdjusting = false;
  }

  private thumbnailCropSize(): number {
    return 240;
  }

  private thumbnailWorkingImageWidth(): number {
    const aspect: number = Math.max(this.thumbnailWorkingAspect, 0.01);
    return aspect >= 1 ? this.thumbnailCropSize() * aspect : this.thumbnailCropSize();
  }

  private thumbnailWorkingImageHeight(): number {
    const aspect: number = Math.max(this.thumbnailWorkingAspect, 0.01);
    return aspect >= 1 ? this.thumbnailCropSize() : this.thumbnailCropSize() / aspect;
  }

  private thumbnailWorkingOffsetLimit(imageSize: number): number {
    return Math.max((imageSize * this.thumbnailWorkingScale - this.thumbnailCropSize()) /
      (2 * this.thumbnailCropSize()), 0);
  }

  private clampThumbnailWorkingOffset(): void {
    const limitX: number = this.thumbnailWorkingOffsetLimit(this.thumbnailWorkingImageWidth());
    const limitY: number = this.thumbnailWorkingOffsetLimit(this.thumbnailWorkingImageHeight());
    this.thumbnailWorkingOffsetX = this.clampNumber(this.thumbnailWorkingOffsetX, -limitX, limitX);
    this.thumbnailWorkingOffsetY = this.clampNumber(this.thumbnailWorkingOffsetY, -limitY, limitY);
  }

  private currentPreviewPhotoUri(): string {
    const photoUris: string[] = this.previewPhotoUris();
    if (photoUris.length === 0) {
      return '';
    }
    const index: number = Math.floor(this.clampNumber(this.previewPhotoIndex, 0, photoUris.length - 1));
    return photoUris[index];
  }

  private hasVisiblePhoto(): boolean {
    return this.previewPhotoUris().length > 0;
  }

  private openPhotoPreview(photoUri: string): void {
    const photoUris: string[] = this.previewPhotoUris();
    const targetUri: string = photoUri.trim();
    const targetIndex: number = photoUris.indexOf(targetUri);
    this.previewPhotoIndex = targetIndex >= 0 ? targetIndex : 0;
    this.previewPhotoUri = photoUris.length > 0 ? photoUris[this.previewPhotoIndex] : targetUri;
    this.pendingPreviewDeleteUri = '';
    this.thumbnailAdjusting = false;
    this.clearPhotoPreviewResetTimer();
    this.photoPreviewScale = 1;
    this.photoPreviewPinchStartScale = 1;
    this.photoPreviewSwipeLocked = false;
    this.photoPreviewOffsetX = 0;
    this.photoPreviewOffsetY = 0;
    this.photoPreviewPanStartX = 0;
    this.photoPreviewPanStartY = 0;
    this.photoPreviewOpen = true;
  }

  private updatePreviewPhotoIndex(index: number): void {
    const photoUris: string[] = this.previewPhotoUris();
    if (photoUris.length === 0) {
      this.previewPhotoIndex = 0;
      this.previewPhotoUri = '';
      return;
    }
    this.previewPhotoIndex = Math.floor(this.clampNumber(index, 0, photoUris.length - 1));
    this.thumbnailAdjusting = false;
    this.previewPhotoUri = photoUris[this.previewPhotoIndex];
    this.photoPreviewScale = 1;
    this.photoPreviewPinchStartScale = 1;
    this.photoPreviewSwipeLocked = false;
    this.photoPreviewOffsetX = 0;
    this.photoPreviewOffsetY = 0;
    this.photoPreviewPanStartX = 0;
    this.photoPreviewPanStartY = 0;
  }

  private closePhotoPreview(): void {
    this.clearPhotoPreviewResetTimer();
    this.thumbnailAdjusting = false;
    this.photoPreviewOpen = false;
    this.photoPreviewResetTimer = setTimeout((): void => {
      if (this.pageActive) {
        this.resetPhotoPreviewTransform();
      }
    }, 220);
  }

  private clearPhotoPreviewResetTimer(): void {
    if (this.photoPreviewResetTimer >= 0) {
      clearTimeout(this.photoPreviewResetTimer);
      this.photoPreviewResetTimer = -1;
    }
  }

  private resetPhotoPreviewTransform(): void {
    this.photoPreviewResetTimer = -1;
    this.photoPreviewScale = 1;
    this.photoPreviewPinchStartScale = 1;
    this.photoPreviewSwipeLocked = false;
    this.photoPreviewOffsetX = 0;
    this.photoPreviewOffsetY = 0;
    this.photoPreviewPanStartX = 0;
    this.photoPreviewPanStartY = 0;
    this.draftHasPhoto = this.hasVisiblePhoto();
    this.previewPhotoUri = '';
  }

  private photoPreviewPanFactor(): number {
    return Math.max(this.photoPreviewScale, 1.2);
  }

  private isPhotoPreviewZoomed(): boolean {
    return this.photoPreviewScale > 1.01;
  }

  private photoPreviewPanDistance(): number {
    return this.isPhotoPreviewZoomed() ? 1 : 100000;
  }

  private photoPreviewOffsetLimit(axisSize: number): number {
    if (axisSize <= 0 || !this.isPhotoPreviewZoomed()) {
      return 0;
    }
    return axisSize * (this.photoPreviewScale - 1) / 2 + 24;
  }

  private clampPhotoPreviewOffset(value: number, axisSize: number): number {
    const limit: number = this.photoPreviewOffsetLimit(axisSize);
    if (limit <= 0) {
      return 0;
    }
    return this.clampNumber(value, -limit, limit);
  }

  private settlePhotoPreviewOffset(): void {
    if (this.isPhotoPreviewZoomed()) {
      return;
    }
    this.getUIContext()?.animateTo({ duration: 180, curve: Curve.EaseOut }, () => {
      this.photoPreviewOffsetX = 0;
      this.photoPreviewOffsetY = 0;
      this.photoPreviewPanStartX = 0;
      this.photoPreviewPanStartY = 0;
    });
  }

  private togglePhotoPreviewDoubleTapZoom(): void {
    const zoomIn: boolean = !this.isPhotoPreviewZoomed();
    const targetScale: number = zoomIn ? 2 : 1;
    const applyZoom: () => void = (): void => {
      this.photoPreviewScale = targetScale;
      this.photoPreviewPinchStartScale = targetScale;
      if (zoomIn) {
        this.photoPreviewOffsetX = this.clampPhotoPreviewOffset(
          this.photoPreviewOffsetX, this.photoPreviewViewportWidth);
        this.photoPreviewOffsetY = this.clampPhotoPreviewOffset(
          this.photoPreviewOffsetY, this.photoPreviewViewportHeight);
      } else {
        this.photoPreviewOffsetX = 0;
        this.photoPreviewOffsetY = 0;
        this.photoPreviewPanStartX = 0;
        this.photoPreviewPanStartY = 0;
      }
      this.photoPreviewSwipeLocked = zoomIn;
    };
    const uiContext = this.getUIContext();
    if (uiContext !== undefined) {
      uiContext.animateTo({ duration: 180, curve: Curve.EaseOut }, applyZoom);
    } else {
      applyZoom();
    }
  }

  private areaLengthToNumber(value: Length | undefined): number {
    if (value === undefined) {
      return 0;
    }
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      const result: number = Number.parseFloat(value);
      return Number.isNaN(result) ? 0 : result;
    }
    return 0;
  }

  private photoObjectWidth(): number {
    return this.draftPhotoWidth + 18;
  }

  private photoObjectHeight(): number {
    return this.draftPhotoHeight + 18;
  }

  private minPhotoX(): number {
    return -9;
  }

  private minPhotoY(): number {
    return 0;
  }

  private clampPhotoX(value: number): number {
    const minX: number = this.minPhotoX();
    const maxX: number = this.editorCanvasWidth > 0 ? Math.max(this.editorCanvasWidth - this.photoObjectWidth() - minX, minX) : 260;
    return Math.round(this.clampNumber(value, minX, maxX));
  }

  private clampPhotoY(value: number): number {
    const minY: number = this.minPhotoY();
    const maxY: number = this.editorCanvasHeight > 0 ? Math.max(this.editorCanvasHeight - this.photoObjectHeight() - minY, minY) : 548;
    return Math.round(this.clampNumber(value, minY, maxY));
  }

  private refreshWrappedTextLayout(): void {
    this.wrapVersion = this.wrapVersion >= 999999 ? 0 : this.wrapVersion + 1;
    this.scheduleBodyLineCountMeasure();
  }

  private updateMeasuredBodyLineCount(): void {
    try {
      const nextLineCount: number = this.bodyTextAreaController.getTextContentLineCount();
      if (nextLineCount > 0 && nextLineCount !== this.measuredBodyLineCount) {
        this.measuredBodyLineCount = nextLineCount;
      }
    } catch (error) {
      console.error('DiaryEditorPage updateMeasuredBodyLineCount failed: ' + JSON.stringify(error));
    }
  }

  private scheduleBodyLineCountMeasure(): void {
    this.scheduleWhenActive((): void => {
      this.updateMeasuredBodyLineCount();
    }, 0);
    this.scheduleWhenActive((): void => {
      this.updateMeasuredBodyLineCount();
    }, 32);
  }

  private clampPhotoPosition(): void {
    const nextX: number = this.clampPhotoX(this.draftPhotoX);
    const nextY: number = this.clampPhotoY(this.draftPhotoY);
    const changed: boolean = nextX !== this.draftPhotoX || nextY !== this.draftPhotoY;
    this.draftPhotoX = nextX;
    this.draftPhotoY = nextY;
    if (changed) {
      this.refreshWrappedTextLayout();
    }
  }

  private clearThumbnailLongPressTimer(): void {
    if (this.thumbnailLongPressTimer >= 0) {
      clearTimeout(this.thumbnailLongPressTimer);
      this.thumbnailLongPressTimer = -1;
    }
  }

  private beginThumbnailLongPress(event: TouchEvent): void {
    this.clearThumbnailLongPressTimer();
    this.thumbnailDragReady = false;
    this.thumbnailDragMoved = false;
    this.thumbnailDragging = false;
    if (event.changedTouches.length === 0) {
      return;
    }
    const touch: TouchObject = event.changedTouches[0];
    this.thumbnailTouchStartX = touch.windowX;
    this.thumbnailTouchStartY = touch.windowY;
    this.thumbnailLongPressTimer = setTimeout((): void => {
      if (!this.pageActive) {
        return;
      }
      this.thumbnailDragReady = true;
      this.thumbnailDragging = true;
      this.suppressNextThumbnailClick = true;
      this.stopBodyEditing();
    }, 420);
  }

  private placePhotoInBodyAtWindowPoint(windowX: number, windowY: number, photoUri: string): boolean {
    if (!this.hasVisiblePhoto()) {
      return false;
    }
    const canvasHeight: number = this.editorCanvasHeight > 0 ? this.editorCanvasHeight : this.editorContentHeight();
    const canvasBottom: number = this.editorCanvasWindowY + canvasHeight;
    const canvasWidth: number = this.editorCanvasWidth > 0 ? this.editorCanvasWidth : 0;
    const canvasRight: number = this.editorCanvasWindowX + canvasWidth;
    if (this.editorCanvasWindowY <= 0 || this.editorCanvasWindowX <= 0 ||
      windowX < this.editorCanvasWindowX - 8 || windowX > canvasRight + 8 ||
      windowY < this.editorCanvasWindowY - 8 || windowY > canvasBottom + 8) {
      return false;
    }
    this.draftPhotoUri = photoUri;
    this.draftPhotoInBody = true;
    this.photoSelected = true;
    this.draftPhotoX = this.clampPhotoX(windowX - this.editorCanvasWindowX - this.photoObjectWidth() / 2);
    this.draftPhotoY = this.clampPhotoY(windowY - this.editorCanvasWindowY - this.photoObjectHeight() / 2);
    this.refreshWrappedTextLayout();
    return true;
  }

  private handleThumbnailTouch(event: TouchEvent, photoUri: string): void {
    if (!this.hasVisiblePhoto()) {
      return;
    }
    if (event.type === TouchType.Down) {
      this.thumbnailPhotoUri = photoUri;
      this.beginThumbnailLongPress(event);
      return;
    }
    if (event.type === TouchType.Move && event.changedTouches.length > 0) {
      const touch: TouchObject = event.changedTouches[0];
      const dx: number = touch.windowX - this.thumbnailTouchStartX;
      const dy: number = touch.windowY - this.thumbnailTouchStartY;
      if (!this.thumbnailDragReady && Math.sqrt(dx * dx + dy * dy) > 10) {
        this.clearThumbnailLongPressTimer();
      }
      if (this.thumbnailDragReady) {
        this.suppressNextThumbnailClick = true;
        this.thumbnailDragMoved = true;
      }
      return;
    }
    if (event.type === TouchType.Up) {
      this.clearThumbnailLongPressTimer();
      if (this.thumbnailDragReady && event.changedTouches.length > 0) {
        const touch: TouchObject = event.changedTouches[0];
        if (this.placePhotoInBodyAtWindowPoint(touch.windowX, touch.windowY, this.thumbnailPhotoUri)) {
          this.thumbnailDragMoved = true;
        }
      }
      if (!this.thumbnailDragMoved) {
        this.thumbnailDragging = false;
      }
      this.thumbnailDragReady = false;
      this.thumbnailDragging = false;
      this.thumbnailPhotoUri = '';
    }
    if (event.type === TouchType.Cancel) {
      this.clearThumbnailLongPressTimer();
      this.thumbnailDragReady = false;
      this.thumbnailDragMoved = false;
      this.thumbnailDragging = false;
      this.thumbnailPhotoUri = '';
    }
  }

  private editorScrollDirection(): ScrollDirection {
    return ScrollDirection.Vertical;
  }

  private editorWillScroll(_xOffset: number, yOffset: number, _scrollState: ScrollState, scrollSource: ScrollSource): void | OffsetResult {
    if (this.keyboardHeightVp > 0 && this.keyboardAutoScrollTracking && yOffset > 0 &&
      (scrollSource === ScrollSource.SCROLLER || scrollSource === ScrollSource.SCROLLER_ANIMATION)) {
      this.keyboardAutoScrollDistance += yOffset;
    }
    if (this.keyboardHeightVp > 0 &&
      (scrollSource === ScrollSource.DRAG || scrollSource === ScrollSource.FLING ||
        scrollSource === ScrollSource.OTHER_USER_INPUT || scrollSource === ScrollSource.SCROLL_BAR ||
        scrollSource === ScrollSource.SCROLL_BAR_FLING)) {
      // A user scroll takes ownership of the position. Do not let a pending
      // keyboard-settling retry pull the first swipe back.
      this.pendingKeyboardCaretAdjustment = false;
      this.keyboardCaretAdjustmentAttempt = 6;
      this.clearKeyboardCaretAdjustmentTimer();
      this.keyboardAutoScrollTracking = false;
      this.keyboardAutoScrollTrackingGeneration++;
    }
    if (this.activePhotoHandle.length > 0 || this.photoTouchDragging) {
      return { xOffset: 0, yOffset: 0 };
    }
    return undefined;
  }

  private bodyFontSize(): number {
    return 18;
  }

  private titleFontSize(): number {
    return 24;
  }

  private titleLineHeight(): number {
    return 30;
  }

  private titleInputTop(): number {
    return Math.round((48 - this.titleLineHeight()) / 2);
  }

  private bodyLineHeight(): number {
    return 24;
  }

  private inlineCaretHeight(): number {
    return this.bodyFontSize();
  }

  private inlineCaretTop(): number {
    return Math.round((this.bodyLineHeight() - this.inlineCaretHeight()) / 2);
  }

  private bodyHorizontalInset(): number {
    return 0;
  }

  private editorFormTopPadding(): number {
    return 0;
  }

  private editorBottomSafeInset(): number {
    return this.photoPreviewOpen ? 0 : 96;
  }

  private bodyBottomSafeDistance(): number {
    return this.bodyLineHeight();
  }

  private editorFormBottomPadding(): number {
    return 0;
  }

  private editorHeaderBlockHeight(): number {
    return 48 + 1 + 16;
  }

  private editorMetaBlockHeight(): number {
    return 30 + 8 + 40 + 8;
  }

  private editorThumbnailBlockHeight(): number {
    return this.hasVisiblePhoto() ? 66 + 16 : 0;
  }

  private editorMinimumContentHeight(): number {
    if (this.editorViewportHeight <= 0) {
      return this.bodyLineHeight() + this.bodyBottomSafeDistance();
    }
    const occupiedHeight: number = this.editorFormTopPadding() + this.editorHeaderBlockHeight() +
      this.editorMetaBlockHeight() + this.editorThumbnailBlockHeight() + this.editorFormBottomPadding();
    return Math.max(
      this.editorViewportHeight - occupiedHeight,
      this.bodyLineHeight() + this.bodyBottomSafeDistance()
    );
  }

  private estimatedPlainBodyLineCount(): number {
    if (this.draftBody.length === 0) {
      return 1;
    }
    const rowWidth: number = Math.max(this.bodyLayoutWidth(), 40);
    let lineCount: number = 0;
    const paragraphs: string[] = this.draftBody.split('\n');
    paragraphs.forEach((text: string): void => {
      const textWidth: number = this.estimatedTextWidth(text);
      lineCount += Math.max(Math.ceil(textWidth / rowWidth), 1);
    });
    return Math.max(lineCount, 1);
  }

  private editorBodyHeight(): number {
    const visibleLineCount: number = this.showWrappedBodyPreview() && this.draftBody.length > 0 ?
      Math.max(this.wrappedTextLines().length, 1) : this.estimatedPlainBodyLineCount();
    const lineCount: number = Math.max(visibleLineCount, this.measuredBodyLineCount);
    const textHeight: number = lineCount * this.bodyLineHeight() + this.bodyBottomSafeDistance();
    const photoBottom: number = this.showWrappedBodyPreview() ? this.draftPhotoY + this.photoObjectHeight() + this.bodyBottomSafeDistance() : 0;
    return Math.max(textHeight, photoBottom, this.bodyLineHeight() + this.bodyBottomSafeDistance());
  }

  private editorContentHeight(): number {
    return Math.max(this.editorBodyHeight() + this.editorBottomSafeInset(), this.editorMinimumContentHeight());
  }

  private bodyLayoutWidth(): number {
    return this.editorCanvasWidth > 0 ? Math.max(this.editorCanvasWidth - this.bodyHorizontalInset() * 2, 40) : 330;
  }

  private estimatedCharWidth(char: string): number {
    if (char === ' ') {
      return 6;
    }
    const code: number = char.charCodeAt(0);
    if (code < 128) {
      return 10.5;
    }
    return 19;
  }

  private estimatedTextWidth(text: string): number {
    let width: number = 0;
    for (let index = 0; index < text.length; index++) {
      width += this.estimatedCharWidth(text.charAt(index));
    }
    return width;
  }

  private bodyIndexByLocalX(text: string, startIndex: number, localX: number): number {
    let usedWidth: number = 0;
    for (let index = 0; index < text.length; index++) {
      const charWidth: number = this.estimatedCharWidth(text.charAt(index));
      if (localX <= usedWidth + charWidth / 2) {
        return startIndex + index;
      }
      usedWidth += charWidth;
    }
    return startIndex + text.length;
  }

  private bodyCaretIndex(): number {
    return Math.round(this.clampNumber(this.bodySelectionEnd, 0, this.draftBody.length));
  }

  private segmentCaretOffset(text: string, startIndex: number): number {
    return Math.round(this.clampNumber(this.bodyCaretIndex() - startIndex, 0, text.length));
  }

  private segmentTextBeforeCaret(text: string, startIndex: number): string {
    return text.substring(0, this.segmentCaretOffset(text, startIndex));
  }

  private segmentTextAfterCaret(text: string, startIndex: number): string {
    return text.substring(this.segmentCaretOffset(text, startIndex));
  }

  private segmentTextBeforeCaretWidth(text: string, startIndex: number, segmentWidth: number): number {
    return this.clampNumber(
      this.estimatedTextWidth(this.segmentTextBeforeCaret(text, startIndex)),
      0,
      Math.max(segmentWidth - 2, 0)
    );
  }

  private lineRightHasCaret(line: WrappedTextLine): boolean {
    const caretIndex: number = this.bodyCaretIndex();
    if (!this.showWrappedBodyPreview() || !this.bodyEditing || line.rightText.length === 0 ||
      caretIndex < line.rightStartIndex || caretIndex > line.rightEndIndex) {
      return false;
    }
    if (caretIndex === line.rightStartIndex && line.leftEndIndex === line.rightStartIndex &&
      this.bodyCaretAffinity !== 'right') {
      return false;
    }
    return true;
  }

  private lineLeftHasCaret(line: WrappedTextLine): boolean {
    const caretIndex: number = this.bodyCaretIndex();
    if (!this.showWrappedBodyPreview() || !this.bodyEditing || line.leftText.length === 0 ||
      caretIndex < line.leftStartIndex || caretIndex > line.leftEndIndex) {
      return false;
    }
    if (caretIndex === line.leftEndIndex && line.leftEndIndex === line.rightStartIndex &&
      line.rightText.length > 0 && this.bodyCaretAffinity === 'right') {
      return false;
    }
    return true;
  }

  private updateBodySelectionAfterChange(value: string, options?: TextChangeOptions): void {
    let nextIndex: number = this.bodySelectionEnd;
    const oldIndex: number = this.bodySelectionEnd;
    if (options !== undefined && options.rangeAfter !== undefined) {
      if (options.rangeAfter.end !== undefined) {
        nextIndex = options.rangeAfter.end;
      } else if (options.rangeAfter.start !== undefined) {
        nextIndex = options.rangeAfter.start;
      }
    } else {
      nextIndex = this.bodySelectionEnd + value.length - this.draftBody.length;
    }
    this.bodySelectionEnd = this.clampNumber(nextIndex, 0, value.length);
    if (this.bodySelectionEnd > oldIndex) {
      this.bodyCaretAffinity = 'left';
    }
  }

  private takeTextSegment(source: string, startIndex: number, width: number): TextTakeResult {
    if (width < 10 || startIndex >= source.length) {
      return { text: '', nextIndex: startIndex, endedByNewline: false };
    }
    let index: number = startIndex;
    let usedWidth: number = 0;
    let text: string = '';
    let endedByNewline: boolean = false;
    while (index < source.length) {
      const char: string = source.charAt(index);
      if (char === '\n') {
        index++;
        endedByNewline = true;
        break;
      }
      const charWidth: number = this.estimatedCharWidth(char);
      if (text.length > 0 && usedWidth + charWidth > width) {
        break;
      }
      if (text.length === 0 && charWidth > width) {
        break;
      }
      text += char;
      usedWidth += charWidth;
      index++;
    }
    return { text: text, nextIndex: index, endedByNewline: endedByNewline };
  }

  private photoWrapBounds(): PhotoWrapBounds {
    const angle: number = this.draftPhotoRotation * Math.PI / 180;
    const cos: number = Math.abs(Math.cos(angle));
    const sin: number = Math.abs(Math.sin(angle));
    const rotatedWidth: number = this.draftPhotoWidth * cos + this.draftPhotoHeight * sin;
    const rotatedHeight: number = this.draftPhotoWidth * sin + this.draftPhotoHeight * cos;
    const centerX: number = this.draftPhotoX + 9 + this.draftPhotoWidth / 2 - this.bodyHorizontalInset();
    const centerY: number = this.draftPhotoY + 9 + this.draftPhotoHeight / 2;
    return {
      left: this.clampNumber(centerX - rotatedWidth / 2 - this.photoTextWrapGap(), 0, this.bodyLayoutWidth()),
      right: this.clampNumber(centerX + rotatedWidth / 2 + this.photoTextWrapGap(), 0, this.bodyLayoutWidth()),
      top: centerY - rotatedHeight / 2 - this.photoTextVerticalGap(),
      bottom: centerY + rotatedHeight / 2 + this.photoTextVerticalGap()
    };
  }

  private photoWrapKey(): string {
    const bounds: PhotoWrapBounds = this.photoWrapBounds();
    return this.wrapVersion.toString() + '-' +
      Math.round(bounds.left).toString() + '-' +
      Math.round(bounds.right).toString() + '-' +
      Math.round(bounds.top).toString() + '-' +
      Math.round(bounds.bottom).toString() + '-' +
      Math.round(this.bodyLayoutWidth()).toString() + '-' +
      this.bodyHorizontalInset().toString();
  }

  private photoWrapLeft(): number {
    return this.photoWrapBounds().left;
  }

  private photoWrapRight(): number {
    return this.photoWrapBounds().right;
  }

  private photoWrapTop(): number {
    return this.photoWrapBounds().top;
  }

  private photoWrapBottom(): number {
    return this.photoWrapBounds().bottom;
  }

  private wrappedTextLines(): WrappedTextLine[] {
    const lines: WrappedTextLine[] = [];
    const content: string = this.draftBody;
    if (!this.showWrappedBodyPreview() || content.length === 0) {
      return lines;
    }
    const canvasWidth: number = this.bodyLayoutWidth();
    const wrapKey: string = this.photoWrapKey() + '-' + content.length.toString();
    const wrapBounds: PhotoWrapBounds = this.photoWrapBounds();
    let index: number = 0;
    let rowIndex: number = 0;
    const maxRows: number = Math.max(content.length + 4, 120);
    while (index < content.length && rowIndex < maxRows) {
      const rowTop: number = rowIndex * this.bodyLineHeight();
      const rowCenter: number = rowTop + this.bodyLineHeight() / 2;
      const overlapsPhoto: boolean = rowCenter >= wrapBounds.top && rowCenter <= wrapBounds.bottom;
      let leftWidth: number = canvasWidth;
      let gapWidth: number = 0;
      let rightWidth: number = 0;
      if (overlapsPhoto) {
        const rawLeftWidth: number = wrapBounds.left;
        const rawRightStart: number = wrapBounds.right;
        const rawRightWidth: number = Math.max(canvasWidth - rawRightStart, 0);
        leftWidth = rawLeftWidth >= this.minWrapSegmentWidth() ? rawLeftWidth : 0;
        rightWidth = rawRightWidth >= this.minWrapSegmentWidth() ? rawRightWidth : 0;
        gapWidth = Math.max(canvasWidth - leftWidth - rightWidth, 0);
      }
      const rowStartIndex: number = index;
      const leftStartIndex: number = index;
      const leftTake: TextTakeResult = this.takeTextSegment(content, index, leftWidth);
      index = leftTake.nextIndex;
      let rightText: string = '';
      let leftText: string = leftTake.text;
      let leftEndIndex: number = leftStartIndex + leftText.length;
      let rightStartIndex: number = index;
      let rightEndIndex: number = index;
      if (!leftTake.endedByNewline && rightWidth > 0) {
        rightStartIndex = index;
        const rightTake: TextTakeResult = this.takeTextSegment(content, index, rightWidth);
        rightText = rightTake.text;
        rightEndIndex = rightStartIndex + rightText.length;
        index = rightTake.nextIndex;
      }
      if (index === rowStartIndex && leftWidth <= 0 && rightWidth <= 0) {
        leftText = '';
        leftEndIndex = leftStartIndex;
      } else if (index === rowStartIndex) {
        leftText = content.charAt(index);
        index++;
        leftEndIndex = index;
      }
      lines.push({
        id: wrapKey + '-' + rowIndex.toString() + '-' + rowStartIndex.toString(),
        leftText: leftText,
        rightText: rightText,
        leftWidth: leftWidth,
        gapWidth: gapWidth,
        rightWidth: rightWidth,
        leftStartIndex: leftStartIndex,
        leftEndIndex: leftEndIndex,
        rightStartIndex: rightStartIndex,
        rightEndIndex: rightEndIndex
      });
      rowIndex++;
    }
    return lines;
  }

  private wrappedCaretPosition(): WrappedCaretPosition {
    if (!this.showWrappedBodyPreview() || !this.bodyEditing) {
      return { visible: false, x: 0, y: 0 };
    }
    const caretIndex: number = this.clampNumber(this.bodySelectionEnd, 0, this.draftBody.length);
    if (this.draftBody.length === 0) {
      return { visible: true, x: 0, y: this.inlineCaretTop() };
    }
    const lines: WrappedTextLine[] = this.wrappedTextLines();
    for (let rowIndex = 0; rowIndex < lines.length; rowIndex++) {
      const line: WrappedTextLine = lines[rowIndex];
      const rowY: number = rowIndex * this.bodyLineHeight() + this.inlineCaretTop();
      if (line.leftText.length > 0 && caretIndex >= line.leftStartIndex && caretIndex <= line.leftEndIndex) {
        const leftOffset: number = this.estimatedTextWidth(this.draftBody.substring(line.leftStartIndex, caretIndex));
        return { visible: true, x: this.clampNumber(leftOffset, 0, line.leftWidth), y: rowY };
      }
      if (line.rightText.length > 0 && caretIndex >= line.rightStartIndex && caretIndex <= line.rightEndIndex) {
        const rightOffset: number = this.estimatedTextWidth(this.draftBody.substring(line.rightStartIndex, caretIndex));
        return {
          visible: true,
          x: this.clampNumber(line.leftWidth + line.gapWidth + rightOffset, line.leftWidth + line.gapWidth, this.bodyLayoutWidth()),
          y: rowY
        };
      }
      if (caretIndex <= line.leftStartIndex) {
        return { visible: true, x: 0, y: rowY };
      }
    }
    const lastRowY: number = Math.max(lines.length - 1, 0) * this.bodyLineHeight() + this.inlineCaretTop();
    return { visible: true, x: this.bodyLayoutWidth(), y: lastRowY };
  }

  private wrappedCaretVisible(): boolean {
    return this.showWrappedBodyPreview() && this.bodyEditing && this.draftBody.length === 0;
  }

  private wrappedCaretX(): number {
    return this.wrappedCaretPosition().x;
  }

  private wrappedCaretY(): number {
    return this.wrappedCaretPosition().y;
  }

  private bodyLineFromLocalY(localY: number): WrappedTextLine | undefined {
    const lines: WrappedTextLine[] = this.wrappedTextLines();
    if (lines.length === 0) {
      return undefined;
    }
    const rowIndex: number = Math.round(this.clampNumber(Math.floor(localY / this.bodyLineHeight()), 0, lines.length - 1));
    return lines[rowIndex];
  }

  private bodyCaretAffinityFromPoint(line: WrappedTextLine, localX: number): string {
    const rightStartX: number = line.leftWidth + line.gapWidth;
    if (line.rightText.length === 0 || localX <= line.leftWidth) {
      return 'left';
    }
    if (localX >= rightStartX) {
      return 'right';
    }
    const gapMiddle: number = line.leftWidth + line.gapWidth / 2;
    return localX < gapMiddle ? 'left' : 'right';
  }

  private bodyTapMoveThreshold(): number {
    return 12;
  }

  private bodyLocalX(touch: TouchObject): number {
    return touch.windowX - this.editorCanvasWindowX - this.bodyHorizontalInset();
  }

  private bodyLocalY(touch: TouchObject): number {
    return touch.windowY - this.editorCanvasWindowY;
  }

  private applyBodyCaretPosition(index: number): void {
    const nextIndex: number = Math.round(this.clampNumber(index, 0, this.draftBody.length));
    this.bodySelectionEnd = nextIndex;
    this.bodyTextAreaController.caretPosition(nextIndex);
    if (this.showWrappedBodyPreview()) {
      this.scheduleWhenActive((): void => {
        this.bodySelectionEnd = nextIndex;
        this.bodyTextAreaController.caretPosition(nextIndex);
        this.refreshWrappedTextLayout();
      }, 0);
      this.scheduleWhenActive((): void => {
        this.bodySelectionEnd = nextIndex;
        this.bodyTextAreaController.caretPosition(nextIndex);
        this.refreshWrappedTextLayout();
        this.adjustBodyCaretAboveKeyboard(false);
      }, 32);
    }
  }

  private bodyIndexFromWrappedPoint(localX: number, localY: number): number {
    if (!this.showWrappedBodyPreview() || this.draftBody.length === 0) {
      return 0;
    }
    const line: WrappedTextLine | undefined = this.bodyLineFromLocalY(localY);
    if (line === undefined) {
      return 0;
    }
    this.bodyCaretAffinity = this.bodyCaretAffinityFromPoint(line, localX);
    const rightStartX: number = line.leftWidth + line.gapWidth;
    if (localX <= line.leftWidth || line.rightText.length === 0) {
      return this.bodyIndexByLocalX(line.leftText, line.leftStartIndex, this.clampNumber(localX, 0, line.leftWidth));
    }
    if (localX >= rightStartX) {
      return this.bodyIndexByLocalX(line.rightText, line.rightStartIndex, this.clampNumber(localX - rightStartX, 0, line.rightWidth));
    }
    const gapMiddle: number = line.leftWidth + line.gapWidth / 2;
    return localX < gapMiddle ? line.leftEndIndex : line.rightStartIndex;
  }

  private prepareBodyCaretCandidate(touch: TouchObject): void {
    const localX: number = this.bodyLocalX(touch);
    const localY: number = this.bodyLocalY(touch);
    const line: WrappedTextLine | undefined = this.bodyLineFromLocalY(localY);
    this.bodyTouchCandidateAffinity = line === undefined ? this.bodyCaretAffinity : this.bodyCaretAffinityFromPoint(line, localX);
    this.bodyTouchCandidateIndex = this.clampNumber(this.bodyIndexFromWrappedPoint(localX, localY), 0, this.draftBody.length);
  }

  private handleBodyTouch(event: TouchEvent): void {
    if (!this.showWrappedBodyPreview() || event.changedTouches.length === 0) {
      return;
    }
    const touch: TouchObject = event.changedTouches[0];
    if (event.type === TouchType.Down) {
      this.bodyTouchStartX = touch.windowX;
      this.bodyTouchStartY = touch.windowY;
      this.bodyTouchMoved = false;
      this.prepareBodyCaretCandidate(touch);
      return;
    }
    if (event.type === TouchType.Move) {
      const dx: number = touch.windowX - this.bodyTouchStartX;
      const dy: number = touch.windowY - this.bodyTouchStartY;
      if (Math.sqrt(dx * dx + dy * dy) > this.bodyTapMoveThreshold()) {
        this.bodyTouchMoved = true;
      }
      return;
    }
    if (event.type === TouchType.Up) {
      if (!this.bodyTouchMoved) {
        this.bodyEditing = true;
        this.focusBodyTextArea();
        this.bodyCaretAffinity = this.bodyTouchCandidateAffinity;
        this.applyBodyCaretPosition(this.bodyTouchCandidateIndex);
      }
      return;
    }
    if (event.type === TouchType.Cancel) {
      this.bodyTouchMoved = false;
    }
  }

  private photoRotationAngle(): string {
    return this.draftPhotoRotation.toString() + 'deg';
  }

  private photoTextWrapGap(): number {
    return 16;
  }

  private photoTextVerticalGap(): number {
    return 0;
  }

  private minWrapSegmentWidth(): number {
    return 24;
  }

  private photoWrapMaxPadding(): number {
    return Math.max(this.editorCanvasWidth - 92, 0);
  }

  private photoIsOnLeftSide(): boolean {
    if (!this.hasVisiblePhoto()) {
      return false;
    }
    if (this.editorCanvasWidth <= 0) {
      return true;
    }
    return this.draftPhotoX + this.photoObjectWidth() / 2 < this.editorCanvasWidth / 2;
  }

  private photoTextLeftInset(): number {
    if (!this.hasVisiblePhoto() || !this.photoIsOnLeftSide()) {
      return 0;
    }
    return this.clampNumber(this.draftPhotoX + this.photoObjectWidth() + this.photoTextWrapGap(), 0, this.photoWrapMaxPadding());
  }

  private photoTextRightInset(): number {
    if (!this.hasVisiblePhoto() || this.photoIsOnLeftSide() || this.editorCanvasWidth <= 0) {
      return 0;
    }
    return this.clampNumber(this.editorCanvasWidth - this.draftPhotoX + this.photoTextWrapGap(), 0, this.photoWrapMaxPadding());
  }

  private boundedPhotoWidth(requestedWidth: number, aspect: number): number {
    const safeAspect: number = Math.max(aspect, 0.1);
    const minWidth: number = 72;
    const maxWidth: number = 260;
    const minHeight: number = 72;
    const maxHeight: number = 340;
    let nextWidth: number = this.clampNumber(requestedWidth, minWidth, maxWidth);
    let nextHeight: number = nextWidth * safeAspect;
    if (nextHeight > maxHeight) {
      nextWidth = maxHeight / safeAspect;
    } else if (nextHeight < minHeight) {
      nextWidth = minHeight / safeAspect;
    }
    return Math.round(this.clampNumber(nextWidth, minWidth, maxWidth));
  }

  private fitPhotoFrame(sourceWidth: number, sourceHeight: number): void {
    if (!this.hasVisiblePhoto() || sourceWidth <= 0 || sourceHeight <= 0) {
      return;
    }
    const aspect: number = sourceHeight / sourceWidth;
    this.photoAspect = Math.max(aspect, 0.1);
    const isDefaultFrame: boolean = Math.abs(this.draftPhotoWidth - 156) < 1 && Math.abs(this.draftPhotoHeight - 118) < 1;
    const expectedHeight: number = Math.round(this.draftPhotoWidth * this.photoAspect);
    const frameMatchesPhoto: boolean = Math.abs(this.draftPhotoHeight - expectedHeight) <= 2;
    if (this.fittedPhotoUri === this.draftPhotoUri && !isDefaultFrame && frameMatchesPhoto) {
      return;
    }
    if (!isDefaultFrame) {
      const correctedWidth: number = this.boundedPhotoWidth(this.draftPhotoWidth, this.photoAspect);
      this.draftPhotoWidth = correctedWidth;
      this.draftPhotoHeight = Math.round(correctedWidth * this.photoAspect);
      this.clampPhotoPosition();
      this.fittedPhotoUri = this.draftPhotoUri;
      this.refreshWrappedTextLayout();
      return;
    }
    const nextWidth: number = this.boundedPhotoWidth(156, this.photoAspect);
    this.draftPhotoWidth = nextWidth;
    this.draftPhotoHeight = Math.round(nextWidth * this.photoAspect);
    this.clampPhotoPosition();
    this.fittedPhotoUri = this.draftPhotoUri;
    this.refreshWrappedTextLayout();
  }

  private beginPhotoTransform(event: TouchEvent, handle: string): boolean {
    if (event.changedTouches.length === 0) {
      return false;
    }
    const touch: TouchObject = event.changedTouches[0];
    this.activePhotoHandle = handle;
    this.transformStartX = touch.windowX;
    this.transformStartY = touch.windowY;
    this.transformStartWidth = this.draftPhotoWidth;
    this.transformStartHeight = this.draftPhotoHeight;
    this.transformStartRotation = this.draftPhotoRotation;
    this.transformStartPhotoX = this.draftPhotoX;
    this.transformStartPhotoY = this.draftPhotoY;
    this.photoSelected = true;
    this.stopBodyEditing();
    return true;
  }

  private updatePhotoResize(event: TouchEvent, handle: string): void {
    if (event.changedTouches.length === 0 || this.activePhotoHandle !== handle) {
      return;
    }
    const touch: TouchObject = event.changedTouches[0];
    const dx: number = touch.windowX - this.transformStartX;
    const dy: number = touch.windowY - this.transformStartY;
    let delta: number = 0;
    if (handle === 'br') {
      delta = (dx + dy) / 2;
    } else if (handle === 'tr') {
      delta = (dx - dy) / 2;
    } else if (handle === 'bl') {
      delta = (-dx + dy) / 2;
    } else {
      delta = (-dx - dy) / 2;
    }
    const aspect: number = this.photoAspect > 0 ? this.photoAspect : this.transformStartHeight / Math.max(this.transformStartWidth, 1);
    const nextWidth: number = this.boundedPhotoWidth(this.transformStartWidth + delta, aspect);
    this.draftPhotoWidth = nextWidth;
    this.draftPhotoHeight = Math.round(nextWidth * Math.max(aspect, 0.1));
    this.clampPhotoPosition();
    this.refreshWrappedTextLayout();
  }

  private updatePhotoMove(event: TouchEvent): void {
    if (event.changedTouches.length === 0 || this.activePhotoHandle !== 'move') {
      return;
    }
    const touch: TouchObject = event.changedTouches[0];
    const nextX: number = this.clampPhotoX(this.transformStartPhotoX + touch.windowX - this.transformStartX);
    const nextY: number = this.clampPhotoY(this.transformStartPhotoY + touch.windowY - this.transformStartY);
    if (nextX !== this.draftPhotoX || nextY !== this.draftPhotoY) {
      this.draftPhotoX = nextX;
      this.draftPhotoY = nextY;
      this.refreshWrappedTextLayout();
    }
  }

  private handleResizeTouch(event: TouchEvent, handle: string): void {
    if (event.type === TouchType.Down) {
      this.beginPhotoTransform(event, handle);
      return;
    }
    if (event.type === TouchType.Move) {
      this.updatePhotoResize(event, handle);
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.activePhotoHandle = '';
    }
  }

  private handlePhotoMoveTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      if (event.changedTouches.length === 0) {
        return;
      }
      const touch: TouchObject = event.changedTouches[0];
      this.photoTouchStartX = touch.windowX;
      this.photoTouchStartY = touch.windowY;
      this.photoTouchStartPhotoX = this.draftPhotoX;
      this.photoTouchStartPhotoY = this.draftPhotoY;
      this.photoTouchDragging = false;
      this.photoSelected = true;
      this.stopBodyEditing();
      return;
    }
    if (event.type === TouchType.Move) {
      if (event.changedTouches.length === 0) {
        return;
      }
      const touch: TouchObject = event.changedTouches[0];
      const dx: number = touch.windowX - this.photoTouchStartX;
      const dy: number = touch.windowY - this.photoTouchStartY;
      if (!this.photoTouchDragging && Math.sqrt(dx * dx + dy * dy) > this.bodyTapMoveThreshold()) {
        const offset: OffsetResult = this.scroller.currentOffset();
        this.photoTouchDragging = true;
        this.activePhotoHandle = 'move';
        this.transformStartX = this.photoTouchStartX;
        this.transformStartY = this.photoTouchStartY;
        this.transformStartPhotoX = this.photoTouchStartPhotoX;
        this.transformStartPhotoY = this.photoTouchStartPhotoY;
        this.restoreEditorScrollOffset(offset);
      }
      this.updatePhotoMove(event);
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.activePhotoHandle = '';
      this.photoTouchDragging = false;
    }
  }

  private handleRotateTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.beginPhotoTransform(event, 'rotate');
      return;
    }
    if (event.type === TouchType.Move && this.activePhotoHandle === 'rotate') {
      if (event.changedTouches.length === 0) {
        return;
      }
      const touch: TouchObject = event.changedTouches[0];
      const dx: number = touch.windowX - this.transformStartX;
      this.draftPhotoRotation = this.clampNumber(this.transformStartRotation + dx * 0.7, -180, 180);
      this.refreshWrappedTextLayout();
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.activePhotoHandle = '';
    }
  }

  private deleteDraftPhoto(): void {
    const targetUri: string = this.currentPreviewPhotoUri().length > 0 ? this.currentPreviewPhotoUri() : this.thumbnailPhotoUri;
    if (targetUri.length > 0) {
      const previousPhotoUris: string[] = this.previewPhotoUris();
      const deletedIndex: number = previousPhotoUris.indexOf(targetUri);
      this.draftPhotoUris = this.normalizePhotoUris(this.draftPhotoUris.filter((item: string) => item !== targetUri));
      if (deletedIndex >= 0 && deletedIndex < this.draftThumbnailPhotoIndex) {
        this.draftThumbnailPhotoIndex--;
      } else if (deletedIndex === this.draftThumbnailPhotoIndex) {
        this.draftThumbnailPhotoIndex = Math.min(this.draftThumbnailPhotoIndex,
          Math.max(this.previewPhotoUris().length - 1, 0));
        this.draftThumbnailScale = 1;
        this.draftThumbnailOffsetX = 0;
        this.draftThumbnailOffsetY = 0;
        this.draftThumbnailPhotoAspect = 1;
      }
      this.refreshWrappedTextLayout();
      this.pendingPreviewDeleteUri = '';
    } else {
      this.pendingPreviewDeleteUri = '';
    }
    this.draftHasPhoto = this.hasVisiblePhoto();
    this.photoSelected = false;
    this.activePhotoHandle = '';
    this.fittedPhotoUri = '';
    this.thumbnailPhotoUri = '';
    if (this.previewPhotoUris().length > 0) {
      this.updatePreviewPhotoIndex(this.previewPhotoIndex);
    } else {
      this.photoPreviewOpen = false;
      this.closePhotoPreview();
    }
  }

  private removePhotoFromBody(): void {
    this.photoSelected = false;
    this.activePhotoHandle = '';
    this.draftPhotoInBody = false;
    this.draftPhotoX = 0;
    this.draftPhotoY = 0;
    this.draftPhotoWidth = 156;
    this.draftPhotoHeight = 118;
    this.draftPhotoRotation = 0;
    this.refreshWrappedTextLayout();
  }

  private toggleDraftFavorite(): void {
    this.draftFavorite = !this.draftFavorite;
    if (this.onDraftFavoriteChange !== undefined) {
      this.onDraftFavoriteChange(this.draftFavorite);
    }
  }

  private addPhotoFromEditorTabs(): void {
    if (this.onDraftHasPhotoChange !== undefined) {
      this.onDraftHasPhotoChange(true);
    }
  }

  private editorActionEnabled(index: number): boolean {
    if (index === 0) {
      return this.canUndoEditor;
    }
    if (index === 1) {
      return this.canRedoEditor;
    }
    return true;
  }

  private isEditorActionSelected(index: number): boolean {
    if (index === 3) {
      return this.draftFavorite;
    }
    return this.editorActionEnabled(index) && this.pressedEditorActionIndex === index;
  }

  private handleEditorActionTouch(event: TouchEvent, index: number): void {
    if (event.type === TouchType.Down) {
      this.pressedEditorActionIndex = this.editorActionEnabled(index) ? index : -1;
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      if (this.pressedEditorActionIndex === index) {
        this.pressedEditorActionIndex = -1;
      }
    }
  }

  private editorActionIcon(index: number): Resource {
    if (index === 0) {
      if (this.isEditorActionSelected(index)) {
        return $rawfile('icons/zap_editor_undo_active.svg');
      }
      return this.isDark ? $rawfile('icons/zap_editor_undo_dark.svg') : $rawfile('icons/zap_editor_undo.svg');
    }
    if (index === 1) {
      if (this.isEditorActionSelected(index)) {
        return $rawfile('icons/zap_editor_redo_active.svg');
      }
      return this.isDark ? $rawfile('icons/zap_editor_redo_dark.svg') : $rawfile('icons/zap_editor_redo.svg');
    }
    if (index === 2) {
      if (this.isEditorActionSelected(index)) {
        return $rawfile('icons/zap_editor_photo_active.svg');
      }
      return this.isDark ? $rawfile('icons/zap_editor_photo_dark.svg') : $rawfile('icons/zap_editor_photo.svg');
    }
    if (index === 3) {
      if (this.draftFavorite) {
        return $rawfile('icons/zap_editor_heart_filled_red.svg');
      }
      return this.isDark ? $rawfile('icons/zap_editor_heart_dark.svg') : $rawfile('icons/zap_editor_heart.svg');
    }
    if (this.isEditorActionSelected(index)) {
      return $rawfile('icons/zap_editor_trash_active.svg');
    }
    return this.isDark ? $rawfile('icons/zap_editor_trash_dark.svg') : $rawfile('icons/zap_editor_trash.svg');
  }

  private editorTabsMaterialLevel(): hdsMaterial.MaterialLevel {
    if (this.materialEffectMode === 1) {
      return hdsMaterial.MaterialLevel.SMOOTH;
    }
    if (this.materialEffectMode === 2) {
      return hdsMaterial.MaterialLevel.GENTLE;
    }
    return hdsMaterial.MaterialLevel.EXQUISITE;
  }

  private editorTabsBarHeight(): number {
    return 56;
  }

  private editorTabsBaseBottomMargin(): number {
    return this.navigationSafeBottomInset();
  }

  private keyboardCaretGap(): number {
    return this.bodyFontSize() * 0.5;
  }

  private keyboardScrollAllowance(): number {
    if (this.suspendKeyboardAvoidance || !this.keyboardScrollSpaceEnabled) {
      return 0;
    }
    return this.keyboardHeightVp > 0 ? this.keyboardScrollAllowanceValue() : this.keyboardScrollAllowanceVp;
  }

  private keyboardScrollAllowanceValue(): number {
    return this.keyboardHeightVp + this.editorTabsBarHeight() + this.keyboardCaretGap();
  }

  private editorTabsBottomMargin(): number {
    if (this.suspendKeyboardAvoidance) {
      return this.editorTabsBaseBottomMargin();
    }
    return this.editorTabsBaseBottomMargin() + this.editorTabsKeyboardOffsetVp;
  }

  private handleEditorTabClick(index: number): void {
    if (!this.editorActionEnabled(index)) {
      return;
    }
    this.pressedEditorActionIndex = -1;
    if (index === 0) {
      this.undoEditorChange();
      return;
    }
    if (index === 1) {
      this.redoEditorChange();
      return;
    }
    if (index === 2) {
      this.addPhotoFromEditorTabs();
      return;
    }
    if (index === 3) {
      this.toggleDraftFavorite();
      return;
    }
    if (this.onDeleteRequest !== undefined) {
      this.onDeleteRequest();
    }
  }

  @Builder
  private EditorActionTabIcon(index: number) {
    Image(this.editorActionIcon(index))
      .width(24)
      .height(24)
      .objectFit(ImageFit.Contain)
      .opacity(this.editorActionEnabled(index) ? (this.isEditorActionSelected(index) ? 1 : 0.76) : 0.32)
  }

  @Builder
  private EditorActionTabItem(title: string, index: number) {
    Column() {
      this.EditorActionTabIcon(index)

      Text(title)
        .fontSize(11)
        .lineHeight(14)
        .fontWeight(this.isEditorActionSelected(index) ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(!this.editorActionEnabled(index) ? this.textTertiary :
          (index === 3 && this.draftFavorite ? '#EF4444' :
            (this.isEditorActionSelected(index) ? this.selectedAccentColor : (this.isDark ? '#CBD5E1' : '#111827'))))
        .opacity(this.editorActionEnabled(index) ? (this.isEditorActionSelected(index) ? 1 : 0.78) : 0.42)
        .margin({ top: 2 })
        .height(14)
        .maxLines(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(this.editorTabsBarHeight())
    .padding({ top: 4, bottom: 4 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .onTouch((event: TouchEvent) => {
      this.handleEditorActionTouch(event, index);
    })
    .animation({
      duration: 220,
      curve: Curve.EaseOut
    })
  }

  @Builder
  private EditorTabs() {
    HdsTabs({ barPosition: BarPosition.End, index: 0 }) {
      TabContent() {
        this.EditorPageContent()
      }
      .tabBar(this.EditorActionTabItem('撤销', 0))
      TabContent() {
      }
      .tabBar(this.EditorActionTabItem('重做', 1))
      TabContent() {
      }
      .tabBar(this.EditorActionTabItem('图片', 2))
      TabContent() {
      }
      .tabBar(this.EditorActionTabItem('收藏', 3))
      TabContent() {
      }
      .tabBar(this.EditorActionTabItem('删除', 4))
    }
    .width('100%')
    .height('100%')
    .vertical(false)
    .scrollable(false)
    .barPosition(BarPosition.End)
    .barOverlap(true)
    .barHeight(this.editorTabsBarHeight())
    .barFloatingStyle(this.materialEffectMode === 0 ? {
      barBottomMargin: this.editorTabsBottomMargin()
    } : {
      barBottomMargin: this.editorTabsBottomMargin(),
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: this.editorTabsMaterialLevel()
      }
    })
    .animationDuration(320)
    .onTabBarClick((index: number) => {
      this.handleEditorTabClick(index);
    })
    .onContentWillChange((_currentIndex: number, _comingIndex: number) => {
      return false;
    })
  }

  private deleteCurrentPreviewPhoto(): void {
    const photoUri: string = this.currentPreviewPhotoUri();
    if (this.onDeletePhotoRequest !== undefined && photoUri.length > 0) {
      this.onDeletePhotoRequest(photoUri);
      return;
    }
    this.deleteDraftPhoto();
  }

  private titleBarMenuItems(): Array<HdsNavigationMenuItemOptions> | undefined {
    const iconColor: string = this.photoPreviewOpen || this.isDark ? '#F8FAFC' : '#1A1A2E';
    if (this.photoPreviewOpen) {
      if (this.thumbnailAdjusting) {
        return undefined;
      }
      return [{
        content: {
          icon: new SymbolGlyphModifier($r('sys.symbol.arrow_up_left_and_arrow_down_right'))
            .fontSize(24)
            .fontColor([iconColor]),
          label: '调整缩略图',
          isEnabled: true,
          type: IconStyleMode.NORMAL,
          action: () => {
            this.beginThumbnailAdjustment();
          }
        }
      }, {
        content: {
          icon: new SymbolGlyphModifier($r('sys.symbol.trash'))
            .fontSize(24)
            .fontColor([iconColor]),
          label: '删除照片',
          isEnabled: true,
          type: IconStyleMode.NORMAL,
          action: () => {
            this.deleteCurrentPreviewPhoto();
          }
        }
      }];
    }
    return [{
      content: {
        icon: new SymbolGlyphModifier($r('sys.symbol.checkmark'))
          .fontSize(24)
          .fontColor([iconColor]),
        label: '保存笔记',
        isEnabled: true,
        type: IconStyleMode.NORMAL,
        action: () => {
          this.requestSave();
        }
      }
    }];
  }

  @Builder
  private MetaRow(label: string, options: ValueOption[], type: string, pickerTitle: string) {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Row() {
        Text(label)
          .width(40)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textSecondary)
          .maxLines(1)

        Text(this.optionLabel(options, this.metaValue(type)))
          .layoutWeight(1)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .width(12)
          .fontSize(16)
          .fontColor([this.textTertiary])
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)
    }
    .layoutWeight(1)
    .height(40)
    .padding({ left: 11, right: 8 })
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 20 })
    .onClick(() => {
      this.openMetaPicker(type, pickerTitle);
    })
  }

  @Builder
  private EditorTitle() {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Start }) {
          TextInput({ placeholder: '', text: this.draftTitle })
            .width('100%')
            .height(this.titleLineHeight())
            .position({ x: 0, y: this.titleInputTop() })
            .fontSize(this.titleFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
            .lineHeight(this.titleLineHeight())
            .backgroundColor('#00000000')
            .border({ width: 0 })
            .borderRadius(0)
            .padding(0)
            .caretColor(this.selectedAccentColor)
            .caretStyle({ width: 2, color: this.selectedAccentColor })
            .onEditChange((isEditing: boolean) => {
              this.titleEditing = isEditing;
              if (isEditing) {
                this.lastEditedField = 'title';
              }
            })
            .onClick(() => {
              this.titleEditing = true;
              this.lastEditedField = 'title';
            })
            .onChange((value: string) => {
              this.recordTitleChange(value);
              if (this.onDraftTitleChange !== undefined) {
                this.onDraftTitleChange(value);
              }
            })

          if (this.draftTitle.length === 0 && !this.titleEditing) {
            Text(this.editorTitleText())
              .width('100%')
              .height(this.titleLineHeight())
              .position({ x: 0, y: this.titleInputTop() })
              .fontSize(this.titleFontSize())
              .fontWeight(FontWeight.Bold)
              .fontColor(this.textPrimary)
              .lineHeight(this.titleLineHeight())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .onClick(() => {
                this.titleEditing = true;
              })
          }
        }
          .layoutWeight(1)
          .height(48)

      }
      .width('100%')

      Row()
        .width('100%')
        .height(1)
        .backgroundColor(this.lineColor)
        .opacity(this.isDark ? 0.55 : 0.75)
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  @Builder
  private TagMenuItem(value: string) {
    Stack({ alignContent: Alignment.End }) {
      if (value.length > 0) {
        Text('X')
          .width(30)
          .height(30)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .backgroundColor('#EF4444')
          .border({ radius: 10 })
          .margin({ right: 13 })
          .opacity(this.swipedTagName === value ? 1 : 0)
          .translate({ x: this.swipedTagName === value ? 0 : 12, y: 0, z: 0 })
          .scale({
            x: this.swipedTagName === value ? 1 : 0.72,
            y: this.swipedTagName === value ? 1 : 0.72,
            centerX: '50%',
            centerY: '50%'
          })
          .zIndex(this.swipedTagName === value ? 2 : 0)
          .animation({
            duration: 180,
            curve: Curve.EaseOut
          })
          .onClick(() => {
            if (this.swipedTagName === value) {
              this.requestDeleteTag(value);
            }
          })
      }

      Row() {
        Text(this.tagLabel(value))
          .width('100%')
          .height(40)
          .fontSize(15)
          .fontColor(this.textPrimary)
          .fontWeight(value === this.draftFolderName ? FontWeight.Medium : FontWeight.Regular)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(this.tagMenuWidth() - 16)
      .height(40)
      .padding({ left: 14, right: value.length > 0 && this.swipedTagName === value ? 48 : 14 })
      .margin({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(value === this.draftFolderName ? this.inputBg : this.cardBg)
      .border({ radius: 12 })
      .translate({ x: value.length > 0 && this.swipedTagName === value ? -4 : 0, y: 0, z: 0 })
      .zIndex(1)
      .animation({
        duration: 180,
        curve: Curve.EaseOut
      })
      .onClick(() => {
        this.applyTag(value);
      })
    }
    .width(this.tagMenuWidth())
    .height(48)
    .clip(true)
    .gesture(
      PanGesture({ fingers: 1, distance: 8 })
        .onActionUpdate((event: GestureEvent) => {
          if (value.length === 0) {
            return;
          }
          const panEvent: PanGestureEvent = event as PanGestureEvent;
          if (panEvent.offsetX < -18) {
            this.swipedTagName = value;
          } else if (panEvent.offsetX > 18 && this.swipedTagName === value) {
            this.swipedTagName = '';
          }
        })
    )
  }

  @Builder
  private NewTagMenuItem() {
    if (this.tagCreating) {
      Row() {
        TextInput({ placeholder: '输入标签', text: this.newTagName })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .fontColor(this.textPrimary)
          .placeholderColor(this.textTertiary)
          .backgroundColor(this.inputBg)
          .border({ width: 1, color: this.newTagName.trim().length > 0 ? this.selectedAccentColor : this.lineColor, radius: 11 })
          .padding({ left: 10, right: 8 })
          .onChange((value: string) => {
            this.newTagName = value;
            this.tagMenuOpen = true;
          })

        Text('创建')
          .width(58)
          .height(36)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.newTagName.trim().length > 0 ? this.selectedAccentColor : this.lineColor)
          .border({ radius: 11 })
          .margin({ left: 6 })
          .onClick(() => {
            this.createTagFromMenu();
          })
      }
      .width(this.tagMenuWidth())
      .height(48)
      .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    } else {
      Row() {
        Text('新标签')
          .width('100%')
          .height(40)
          .fontSize(15)
          .fontColor(this.selectedAccentColor)
          .textAlign(TextAlign.Start)
      }
      .width(this.tagMenuWidth() - 16)
      .height(40)
      .padding({ left: 14, right: 14 })
      .margin({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(this.cardBg)
      .onClick(() => {
        this.tagCreating = true;
        this.tagMenuOpen = true;
      })
    }
  }

  @Builder
  private TagMenuDivider() {
    Row()
      .width(this.tagMenuWidth() - 24)
      .height(1)
      .backgroundColor(this.lineColor)
      .opacity(this.isDark ? 0.55 : 0.75)
      .margin({ left: 12, right: 12, top: 4, bottom: 4 })
  }

  @Builder
  private TagDropdownMenu() {
    Menu() {
      ForEach(this.normalizedTagOptions(), (value: string) => {
        this.TagMenuItem(value)
      }, (value: string) => value.length > 0 ? value : 'none')

      this.TagMenuDivider()
      this.NewTagMenuItem()
    }
    .width(this.tagMenuWidth())
    .padding({ top: 4, bottom: 4 })
    .fontColor(this.textPrimary)
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 16 })
    .shadow({ radius: 18, color: '#22000000', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private EditorInfoRow() {
    Row() {
      Button({ type: ButtonType.Capsule, stateEffect: true }) {
        Row() {
          Text(this.folderButtonText())
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 76 })

          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(12)
            .fontColor([this.textTertiary])
            .margin({ left: 4 })
        }
        .height(30)
      }
      .height(30)
      .constraintSize({ minWidth: 68, maxWidth: 112 })
      .padding({ left: 10, right: 8 })
      .backgroundColor(this.inputBg)
      .border({ width: 1, color: this.lineColor, radius: 15 })
      .onClick(() => {
        this.tagMenuOpen = !this.tagMenuOpen;
      })
      .bindMenu(this.tagMenuOpen, this.TagDropdownMenu)

      Blank()

      Text(this.editorTimeText())
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textTertiary)
        .textAlign(TextAlign.End)
        .maxLines(1)
    }
    .width('100%')
    .height(30)
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8 })
  }

  @Builder
  private MetaPanel() {
    Row() {
      this.MetaRow('心情', MOOD_OPTIONS, 'mood', '选择心情')
      Blank()
        .width(8)
      this.MetaRow('天气', WEATHER_OPTIONS, 'weather', '选择天气')
    }
    .width('100%')
    .height(40)
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8 })
  }

  private resizeHandleX(handle: string): number {
    return handle === 'tr' || handle === 'br' ? this.draftPhotoWidth : 0;
  }

  private resizeHandleY(handle: string): number {
    return handle === 'bl' || handle === 'br' ? this.draftPhotoHeight : 0;
  }

  private rotateHandleX(): number {
    return Math.round((this.photoObjectWidth() - 28) / 2);
  }

  @Builder
  private ResizeHandle(handle: string) {
    Stack()
      .width(18)
      .height(18)
      .backgroundColor('#FFFFFF')
      .border({ width: 2, color: this.selectedAccentColor, radius: 9 })
      .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 1 })
      .position({ x: this.resizeHandleX(handle), y: this.resizeHandleY(handle) })
      .zIndex(4)
      .onTouch((event: TouchEvent) => {
        this.handleResizeTouch(event, handle);
      })
  }

  @Builder
  private RotateHandle() {
    Column() {
      Text('↻')
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .fontSize(20)
        .fontColor(this.selectedAccentColor)
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: this.selectedAccentColor, radius: 14 })
      Row()
        .width(1)
        .height(18)
        .backgroundColor(this.selectedAccentColor)
    }
    .width(28)
    .height(46)
    .onTouch((event: TouchEvent) => {
      this.handleRotateTouch(event);
    })
  }

  @Builder
  private PhotoDeleteHandle() {
    Stack({ alignContent: Alignment.Center }) {
      Image(this.isDark ? $rawfile('icons/zap_editor_trash_dark.svg') : $rawfile('icons/zap_editor_trash.svg'))
        .width(16)
        .height(16)
        .objectFit(ImageFit.Contain)
    }
    .width(28)
    .height(28)
    .backgroundColor(this.isDark ? this.selectedAccentColor : '#FFFFFF')
    .border({ width: 1, color: this.selectedAccentColor, radius: 14 })
    .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 1 })
    .onClick(() => {
      this.removePhotoFromBody();
    })
  }

  @Builder
  private RotateHandleLayer() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.RotateHandle()

      Row() {
        Blank()
          .width(36)
        this.PhotoDeleteHandle()
      }
      .width(64)
      .height(28)
    }
    .width(64)
    .height(46)
    .position({ x: this.rotateHandleX(), y: -46 })
    .zIndex(5)
  }

  @Builder
  private PhotoFrameLayer() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image(this.photoImageSource(this.draftPhotoUri))
        .width(this.draftPhotoWidth)
        .height(this.draftPhotoHeight)
        .objectFit(ImageFit.Fill)
        .draggable(false)
        .backgroundColor(this.isDark ? '#101827' : '#FFFFFF')
        .border({ width: 1, color: this.selectedAccentColor, radius: 10 })
        .position({ x: 9, y: 9 })
        .onTouch((event: TouchEvent) => {
          this.handlePhotoMoveTouch(event);
        })
        .onComplete((event) => {
          if (event !== undefined) {
            this.fitPhotoFrame(event.width, event.height);
          }
        })

      if (this.photoSelected) {
        this.ResizeHandle('tl')
        this.ResizeHandle('tr')
        this.ResizeHandle('bl')
        this.ResizeHandle('br')
      }
    }
    .width(this.draftPhotoWidth + 18)
    .height(this.draftPhotoHeight + 18)
    .position({ x: 0, y: 0 })
  }

  @Builder
  private PhotoObject() {
    if (this.showWrappedBodyPreview()) {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.photoSelected) {
          this.RotateHandleLayer()
        }
        this.PhotoFrameLayer()
      }
      .width(this.draftPhotoWidth + 18)
      .height(this.draftPhotoHeight + 18)
      .rotate({ z: 1, angle: this.photoRotationAngle() })
      .position({ x: this.draftPhotoX, y: this.draftPhotoY })
    }
  }

  @Builder
  private InlineBodyCaret(caretX: number, caretY: number) {
    Row()
      .width(2)
      .height(this.inlineCaretHeight())
      .backgroundColor(this.selectedAccentColor)
      .borderRadius(1)
      .position({ x: caretX, y: caretY })
      .zIndex(2)
      .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  private WrappedSegmentText(text: string, startIndex: number, _endIndex: number, width: number, showCaret: boolean) {
    Stack({ alignContent: Alignment.TopStart }) {
      Text(text)
        .width(width)
        .fontSize(this.bodyFontSize())
        .fontColor(this.textSecondary)
        .lineHeight(this.bodyLineHeight())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Clip })

      if (showCaret) {
        this.InlineBodyCaret(this.segmentTextBeforeCaretWidth(text, startIndex, width), this.inlineCaretTop())
      }
    }
    .width(width)
    .height(this.bodyLineHeight())
    .clip(true)
  }

  @Builder
  private WrappedBodyDisplay() {
    if (this.showWrappedBodyPreview() && this.draftBody.length > 0) {
      Column() {
        ForEach(this.wrappedTextLines(), (line: WrappedTextLine) => {
          Row() {
            this.WrappedSegmentText(line.leftText, line.leftStartIndex, line.leftEndIndex, line.leftWidth, this.lineLeftHasCaret(line))

            Blank()
              .width(line.gapWidth)
              .height(this.bodyLineHeight())

            this.WrappedSegmentText(line.rightText, line.rightStartIndex, line.rightEndIndex, line.rightWidth, this.lineRightHasCaret(line))
          }
          .width('100%')
          .height(this.bodyLineHeight())
        }, (line: WrappedTextLine) => line.id)
      }
      .width(this.bodyLayoutWidth())
      .height(this.editorBodyHeight())
      .position({ x: this.bodyHorizontalInset(), y: 0 })
      .alignItems(HorizontalAlign.Start)
      .hitTestBehavior(HitTestMode.Transparent)
    }
  }

  @Builder
  private WrappedBodyTouchLayer() {
    if (this.showWrappedBodyPreview()) {
      Row()
        .width('100%')
        .height(this.editorContentHeight())
        .backgroundColor('#00000000')
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down && this.activePhotoHandle.length === 0) {
            this.photoSelected = false;
          }
          this.handleBodyTouch(event);
        })
        .hitTestBehavior(HitTestMode.Transparent)
    }
  }

  @Builder
  private WrappedBodyCaret() {
    if (this.wrappedCaretVisible()) {
      Row()
        .width(2)
        .height(this.inlineCaretHeight())
        .backgroundColor(this.selectedAccentColor)
        .borderRadius(1)
        .position({ x: this.wrappedCaretX() + this.bodyHorizontalInset(), y: this.wrappedCaretY() })
        .zIndex(3)
        .hitTestBehavior(HitTestMode.Transparent)
    }
  }

  @Builder
  private ThumbnailPhotoItem(photoUri: string) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Image(this.photoImageSource(photoUri))
        .width(56)
        .height(56)
        .objectFit(ImageFit.Cover)
        .border({ width: 2, color: this.selectedAccentColor, radius: 12 })
        .clip(true)
        .opacity(this.thumbnailDragging && this.thumbnailPhotoUri === photoUri ? 0.72 : 1)
        .onTouch((event: TouchEvent) => {
          this.handleThumbnailTouch(event, photoUri);
        })
        .onClick(() => {
          if (this.suppressNextThumbnailClick) {
            this.suppressNextThumbnailClick = false;
            return;
          }
          this.openPhotoPreview(photoUri);
        })

      if (this.allThumbnailPhotoUris().length > 1) {
        Text(this.allThumbnailPhotoUris().length.toString())
          .height(18)
          .constraintSize({ minWidth: 18 })
          .padding({ left: 5, right: 5 })
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .backgroundColor('#99000000')
          .border({ radius: 9 })
          .margin({ top: 4, right: 4 })
          .zIndex(3)
      }

    }
    .width(56)
    .height(56)
  }

  @Builder
  private ThumbnailChoice() {
    if (this.firstThumbnailPhotoUri().length > 0) {
      Row() {
        Text('首页卡片缩略图')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textSecondary)
          .layoutWeight(1)
          .maxLines(1)

        this.ThumbnailPhotoItem(this.firstThumbnailPhotoUri())
      }
      .width('100%')
      .height(66)
      .padding({ left: 14, right: 10 })
      .backgroundColor(this.inputBg)
      .border({ width: 1, color: this.lineColor, radius: 16 })
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 16 })
    }
  }

  @Builder
  private PreviewPhotoImage(photoUri: string) {
    Image(this.photoImageSource(photoUri))
      .width('100%')
      .height('100%')
      .objectFit(ImageFit.Contain)
      .padding({ left: 8, right: 8, top: 0, bottom: 0 })
      .draggable(false)
      .translate({ x: this.photoPreviewOffsetX, y: this.photoPreviewOffsetY, z: 0 })
      .scale({ x: this.photoPreviewScale, y: this.photoPreviewScale, centerX: '50%', centerY: '50%' })
  }

  @Builder
  private PreviewPhotoPage(photoUri: string) {
    Stack({ alignContent: Alignment.Center }) {
      this.PreviewPhotoImage(photoUri)
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.photoPreviewViewportWidth = this.areaLengthToNumber(newValue.width);
      this.photoPreviewViewportHeight = this.areaLengthToNumber(newValue.height);
    })
    .gesture(
      GestureGroup(GestureMode.Parallel,
        TapGesture({ count: 2 })
          .onAction(() => {
            this.togglePhotoPreviewDoubleTapZoom();
          }),
        PinchGesture({ fingers: 2, distance: 5 })
          .onActionStart((_event: GestureEvent) => {
            this.photoPreviewPinchStartScale = this.photoPreviewScale;
            this.photoPreviewSwipeLocked = true;
          })
          .onActionUpdate((event: GestureEvent) => {
            const pinchEvent: PinchGestureEvent = event as PinchGestureEvent;
            const nextScale: number = this.clampNumber(this.photoPreviewPinchStartScale * pinchEvent.scale, 0.6, 4);
            this.photoPreviewScale = nextScale;
            if (nextScale > 1.01) {
              this.photoPreviewOffsetX = this.clampPhotoPreviewOffset(
                this.photoPreviewOffsetX, this.photoPreviewViewportWidth);
              this.photoPreviewOffsetY = this.clampPhotoPreviewOffset(
                this.photoPreviewOffsetY, this.photoPreviewViewportHeight);
            }
          })
          .onActionEnd((_event: GestureEvent) => {
            this.photoPreviewPinchStartScale = this.photoPreviewScale;
            this.settlePhotoPreviewOffset();
            this.photoPreviewSwipeLocked = this.isPhotoPreviewZoomed();
          }),
        PanGesture({ fingers: 1, direction: PanDirection.All, distance: this.photoPreviewPanDistance() })
          .onActionStart((_event: GestureEvent) => {
            this.photoPreviewPanStartX = this.photoPreviewOffsetX;
            this.photoPreviewPanStartY = this.photoPreviewOffsetY;
          })
          .onActionUpdate((event: GestureEvent) => {
            if (!this.isPhotoPreviewZoomed()) {
              return;
            }
            const panEvent: PanGestureEvent = event as PanGestureEvent;
            this.photoPreviewOffsetX = this.clampPhotoPreviewOffset(
              this.photoPreviewPanStartX + panEvent.offsetX * this.photoPreviewPanFactor(),
              this.photoPreviewViewportWidth);
            this.photoPreviewOffsetY = this.clampPhotoPreviewOffset(
              this.photoPreviewPanStartY + panEvent.offsetY * this.photoPreviewPanFactor(),
              this.photoPreviewViewportHeight);
          })
          .onActionEnd((_event: GestureEvent) => {
            this.photoPreviewPanStartX = this.photoPreviewOffsetX;
            this.photoPreviewPanStartY = this.photoPreviewOffsetY;
          })
      )
    )
  }

  @Builder
  private ThumbnailAdjustmentView() {
    Column() {
      Text('拖动调整主体，双指缩放')
        .fontSize(14)
        .fontColor('#CCFFFFFF')
        .margin({ bottom: 18 })

      Stack({ alignContent: Alignment.Center }) {
        Image(this.photoImageSource(this.currentPreviewPhotoUri()))
          .width(this.thumbnailWorkingImageWidth())
          .height(this.thumbnailWorkingImageHeight())
          .objectFit(ImageFit.Fill)
          .draggable(false)
          .scale({
            x: this.thumbnailWorkingScale,
            y: this.thumbnailWorkingScale,
            centerX: '50%',
            centerY: '50%'
          })
          .translate({
            x: this.thumbnailWorkingOffsetX * this.thumbnailCropSize(),
            y: this.thumbnailWorkingOffsetY * this.thumbnailCropSize(),
            z: 0
          })
          .onComplete((event) => {
            if (event !== undefined && event.width > 0 && event.height > 0) {
              this.thumbnailWorkingAspect = event.width / event.height;
              this.clampThumbnailWorkingOffset();
            }
          })
      }
      .width(this.thumbnailCropSize())
      .height(this.thumbnailCropSize())
      .border({ width: 2, color: '#FFFFFF', radius: 18 })
      .clip(true)
      .gesture(
        GestureGroup(GestureMode.Parallel,
          PinchGesture({ fingers: 2, distance: 5 })
            .onActionStart((_event: GestureEvent) => {
              this.thumbnailPinchStartScale = this.thumbnailWorkingScale;
            })
            .onActionUpdate((event: GestureEvent) => {
              const pinchEvent: PinchGestureEvent = event as PinchGestureEvent;
              this.thumbnailWorkingScale = this.clampNumber(
                this.thumbnailPinchStartScale * pinchEvent.scale, 1, 4);
              this.clampThumbnailWorkingOffset();
            })
            .onActionEnd((_event: GestureEvent) => {
              this.thumbnailPinchStartScale = this.thumbnailWorkingScale;
              this.clampThumbnailWorkingOffset();
            }),
          PanGesture({ fingers: 1, direction: PanDirection.All, distance: 1 })
            .onActionStart((_event: GestureEvent) => {
              this.thumbnailPanStartOffsetX = this.thumbnailWorkingOffsetX;
              this.thumbnailPanStartOffsetY = this.thumbnailWorkingOffsetY;
            })
            .onActionUpdate((event: GestureEvent) => {
              const panEvent: PanGestureEvent = event as PanGestureEvent;
              this.thumbnailWorkingOffsetX = this.thumbnailPanStartOffsetX +
                panEvent.offsetX / this.thumbnailCropSize();
              this.thumbnailWorkingOffsetY = this.thumbnailPanStartOffsetY +
                panEvent.offsetY / this.thumbnailCropSize();
              this.clampThumbnailWorkingOffset();
            })
            .onActionEnd((_event: GestureEvent) => {
              this.clampThumbnailWorkingOffset();
            })
        )
      )

      Text('首页卡片预览')
        .fontSize(13)
        .fontColor('#99FFFFFF')
        .margin({ top: 12, bottom: 24 })

      Row({ space: 12 }) {
        Button('取消', { type: ButtonType.Capsule })
          .width(112)
          .height(44)
          .fontColor('#FFFFFF')
          .backgroundColor('#55475569')
          .border({ width: 1, color: '#55FFFFFF' })
          .onClick(() => {
            this.cancelThumbnailAdjustment();
          })

        Button('完成', { type: ButtonType.Capsule })
          .width(112)
          .height(44)
          .fontColor('#FFFFFF')
          .backgroundColor(this.selectedAccentColor)
          .onClick(() => {
            this.confirmThumbnailAdjustment();
          })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: 88, bottom: 32 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private PhotoPreviewOverlay() {
    if (this.previewPhotoUris().length > 0) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor('#E6000000')
          .opacity(this.photoPreviewOpen ? 1 : 0)
          .animation({
            duration: 200,
            curve: Curve.EaseOut
          })

        if (this.thumbnailAdjusting) {
          this.ThumbnailAdjustmentView()
        } else {
          Swiper() {
            ForEach(this.previewPhotoUris(), (photoUri: string) => {
              this.PreviewPhotoPage(photoUri)
            }, (photoUri: string) => photoUri)
          }
          .width('100%')
          .height('100%')
          .index(this.previewPhotoIndex)
          .indicator(false)
          .loop(false)
          .disableSwipe(this.photoPreviewSwipeLocked)
          .duration(220)
          .curve(Curve.EaseOut)
          .opacity(this.photoPreviewOpen ? 1 : 0)
          .scale({
            x: this.photoPreviewOpen ? 1 : 0.96,
            y: this.photoPreviewOpen ? 1 : 0.96,
            centerX: '50%',
            centerY: '50%'
          })
          .animation({
            duration: 200,
            curve: Curve.EaseOut
          })
          .onChange((index: number) => {
            this.updatePreviewPhotoIndex(index);
          })
        }

      }
      .width('100%')
      .layoutWeight(1)
      .opacity(this.photoPreviewOpen ? 1 : 0)
      .animation({
        duration: 200,
        curve: Curve.EaseOut
      })
      .zIndex(999)
      .enabled(this.photoPreviewOpen)
      .hitTestBehavior(this.photoPreviewOpen ? HitTestMode.Default : HitTestMode.Transparent)
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    }
  }

  @Builder
  private EditorForm() {
    Column() {
      this.EditorTitle()
      this.EditorInfoRow()
      this.MetaPanel()
      if (this.hasVisiblePhoto()) {
        this.ThumbnailChoice()
      }

      Stack({ alignContent: Alignment.BottomEnd }) {
        this.WrappedBodyDisplay()

        TextArea({ placeholder: this.bodyPlaceholder(), text: this.draftBody, controller: this.bodyTextAreaController })
          .id(this.bodyTextAreaId)
          .width('100%')
          .height(this.editorContentHeight())
          .position({ x: 0, y: 0 })
          .fontSize(this.bodyFontSize())
          .fontColor(this.showWrappedBodyPreview() ? '#00000000' : this.textSecondary)
          .placeholderColor(this.showWrappedBodyPreview() ? '#00000000' : this.textSecondary)
          .caretColor(this.showWrappedBodyPreview() ? '#00000000' : this.selectedAccentColor)
          .lineHeight(this.bodyLineHeight())
          .backgroundColor('#00000000')
          .border({ width: 0 })
          .borderRadius(0)
          .barState(BarState.Off)
          .padding({ left: this.bodyHorizontalInset(), right: this.bodyHorizontalInset(), top: 0, bottom: this.editorBottomSafeInset() })
          .hitTestBehavior(this.showWrappedBodyPreview() ? HitTestMode.None : HitTestMode.Default)
          .onAreaChange((_oldValue: Area, _newValue: Area) => {
            this.scheduleBodyLineCountMeasure();
          })
          .onEditChange((isEditing: boolean) => {
            this.bodyEditing = isEditing;
            if (isEditing) {
              this.lastEditedField = 'body';
              this.adjustBodyCaretDuringKeyboardShow();
            }
          })
          .onTextSelectionChange((_selectionStart: number, selectionEnd: number) => {
            if (!this.showWrappedBodyPreview()) {
              this.bodySelectionEnd = this.clampNumber(selectionEnd, 0, this.draftBody.length);
              this.adjustBodyCaretDuringKeyboardShow();
            }
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down && this.activePhotoHandle.length === 0) {
              this.photoSelected = false;
              this.bodyEditing = true;
            }
            this.handleBodyTouch(event);
          })
          .onChange((value: string, _previewText?: PreviewText, options?: TextChangeOptions) => {
            this.updateBodySelectionAfterChange(value, options);
            this.recordBodyChange(value);
            this.refreshWrappedTextLayout();
            this.adjustBodyCaretDuringKeyboardShow();
            if (this.onDraftBodyChange !== undefined) {
              this.onDraftBodyChange(value);
            }
          })
        this.WrappedBodyTouchLayer()
        this.WrappedBodyCaret()
        this.PhotoObject()
      }
      .width('100%')
      .height(this.editorContentHeight())
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        const nextWidth: number = this.areaLengthToNumber(newValue.width);
        const nextHeight: number = this.areaLengthToNumber(newValue.height);
        this.editorCanvasWindowX = this.areaLengthToNumber(newValue.globalPosition.x);
        this.editorCanvasWindowY = this.areaLengthToNumber(newValue.globalPosition.y);
        this.editorCanvasContentY = this.areaLengthToNumber(newValue.position.y);
        const changed: boolean = nextWidth !== this.editorCanvasWidth || nextHeight !== this.editorCanvasHeight;
        this.editorCanvasWidth = nextWidth;
        this.editorCanvasHeight = nextHeight;
        this.clampPhotoPosition();
        if (changed) {
          this.refreshWrappedTextLayout();
        }
      })

      if (this.keyboardScrollAllowance() > 0) {
        Blank()
          .width('100%')
          .height(this.keyboardScrollAllowance())
          .hitTestBehavior(HitTestMode.Transparent)
      }
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: this.editorFormTopPadding(), bottom: this.editorFormBottomPadding() })
    .alignItems(HorizontalAlign.Start)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const previousHeight: number = this.editorFormHeight;
      const nextHeight: number = this.areaLengthToNumber(newValue.height);
      this.editorFormHeight = nextHeight;
      if (this.pendingKeyboardCaretAdjustment && this.keyboardHeightVp > 0 &&
        Math.abs(nextHeight - previousHeight) > 0.5) {
        this.pendingKeyboardCaretAdjustment = false;
        this.adjustBodyCaretAboveKeyboard(this.keyboardFollowAnimation());
      }
    })
  }

  @Builder
  private EditorPageContent() {
    Column() {
      Scroll(this.scroller) {
        this.EditorForm()
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(this.editorScrollDirection())
      .edgeEffect(EdgeEffect.Spring)
      .nestedScroll({ scrollForward: NestedScrollMode.SELF_FIRST, scrollBackward: NestedScrollMode.SELF_FIRST })
      .onWillScroll((xOffset: number, yOffset: number, scrollState: ScrollState, scrollSource: ScrollSource) => {
        return this.editorWillScroll(xOffset, yOffset, scrollState, scrollSource);
      })
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        const nextHeight: number = this.areaLengthToNumber(newValue.height);
        this.editorViewportHeight = nextHeight;
        this.editorViewportWindowY = this.areaLengthToNumber(newValue.globalPosition.y);
      })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: this.navigationSafeBottomInset() })
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        this.EditorTabs()

        this.PhotoPreviewOverlay()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .titleBar(createHdsSubPageTitleBarOptions(
      this.photoPreviewOpen ? (this.thumbnailAdjusting ? '调整缩略图' : '') :
        (this.editingId.length > 0 ? '编辑笔记' : '新建笔记'),
      this.photoPreviewOpen ? true : this.isDark,
      this.materialEffectMode,
      () => {
        if (this.photoPreviewOpen) {
          if (this.thumbnailAdjusting) {
            this.cancelThumbnailAdjustment();
            return;
          }
          this.closePhotoPreview();
          return;
        }
        if (this.onClose !== undefined) {
          this.onClose();
        }
      },
      this.titleBarMenuItems(),
      this.photoPreviewOpen
    ))
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .hideBackButton(false)
    .onBackPressed(() => {
      if (this.photoPreviewOpen) {
        if (this.thumbnailAdjusting) {
          this.cancelThumbnailAdjustment();
          return true;
        }
        this.closePhotoPreview();
        return true;
      }
      if (this.onClose !== undefined) {
        this.onClose();
      }
      return true;
    })
    .bindToScrollable([this.scroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .backgroundColor(this.photoPreviewOpen ? '#000000' : this.pageBg)
  }
}

