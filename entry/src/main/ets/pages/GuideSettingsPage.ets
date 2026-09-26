import {
  allGuideTopics,
  GUIDE_SECTIONS,
  GuideSection,
  GuideTopic
} from '../model/GuideContent';

@Component
export struct GuideSettingsPage {
  @Prop selectedAccentColor: string = '#6366F1';
  @Prop cardBg: string = '#FFFFFF';
  @Prop inputBg: string = '#F1F5F9';
  @Prop lineColor: string = '#E2E8F0';
  @Prop textPrimary: string = '#0F172A';
  @Prop textSecondary: string = '#475569';
  @Prop textTertiary: string = '#94A3B8';
  @State private searchQuery: string = '';
  private searchController: TextInputController = new TextInputController();
  private searchActivatedByTouch: boolean = false;
  onBack?: () => void;
  onOpenSection?: (sectionId: string) => void;
  onOpenTopic?: (topicId: string) => void;

  private markSearchTouch(): void {
    this.searchActivatedByTouch = true;
    setTimeout((): void => {
      this.searchActivatedByTouch = false;
    }, 600);
  }

  private handleSearchEditChange(isEditing: boolean): void {
    if (!isEditing) {
      this.searchActivatedByTouch = false;
      return;
    }
    if (!this.searchActivatedByTouch) {
      this.searchController.stopEditing();
    }
  }

  private isSearching(): boolean {
    return this.searchQuery.trim().length > 0;
  }

  private searchResults(): GuideTopic[] {
    const query: string = this.searchQuery.trim().toLowerCase();
    if (query.length === 0) {
      return [];
    }
    return allGuideTopics().filter((topic: GuideTopic): boolean => {
      return topic.question.toLowerCase().indexOf(query) >= 0 ||
        topic.summary.toLowerCase().indexOf(query) >= 0 ||
        topic.steps.join(' ').toLowerCase().indexOf(query) >= 0 ||
        topic.tip.toLowerCase().indexOf(query) >= 0 ||
        topic.keywords.toLowerCase().indexOf(query) >= 0;
    });
  }

  private openTopic(topicId: string): void {
    if (this.onOpenTopic !== undefined) {
      this.onOpenTopic(topicId);
    }
  }

  private openSection(sectionId: string): void {
    if (this.onOpenSection !== undefined) {
      this.onOpenSection(sectionId);
    }
  }

  @Builder
  private SearchArea() {
    TextInput({ placeholder: '搜索问题，例如：照片识别怎么使用', text: this.searchQuery, controller: this.searchController })
      .width('100%')
      .height(48)
      .enableKeyboardOnFocus(false)
      .fontSize(14)
      .fontColor(this.textPrimary)
      .placeholderColor(this.textTertiary)
      .backgroundColor(this.inputBg)
      .border({ width: 1, color: this.lineColor, radius: 12 })
      .padding({ left: 14, right: 14 })
      .margin({ bottom: 24 })
      .onChange((value: string) => {
        this.searchQuery = value;
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.markSearchTouch();
        }
      })
      .onEditChange((isEditing: boolean) => {
        this.handleSearchEditChange(isEditing);
      })
  }

  @Builder
  private SectionLabel(section: GuideSection) {
    Row() {
      Text(section.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textSecondary)
        .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .width(24)
        .height(28)
        .fontSize(22)
        .fontColor([this.textTertiary])
    }
    .width('100%')
    .padding({ left: 4, right: 12, top: 4, bottom: 4 })
    .margin({ bottom: 9 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openSection(section.id);
    })
  }

  @Builder
  private SearchResultLabel() {
    Text('搜索结果')
      .width('100%')
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.textSecondary)
      .padding({ left: 4 })
      .margin({ bottom: 9 })
  }

  @Builder
  private TopicRow(topic: GuideTopic, showSection: boolean = false) {
    Row() {
      Column() {
        if (showSection) {
          Text(topic.sectionTitle)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.selectedAccentColor)
            .margin({ bottom: 5 })
        }

        Text(topic.question)
          .width('100%')
          .fontSize(15)
          .lineHeight(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(topic.summary)
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(this.textTertiary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .width(24)
        .height(32)
        .fontSize(24)
        .fontColor([this.textTertiary])
        .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openTopic(topic.id);
    })
  }

  @Builder
  private TopicList(topics: GuideTopic[], showSection: boolean = false) {
    Column() {
      ForEach(topics, (topic: GuideTopic, index: number) => {
        this.TopicRow(topic, showSection)
        if (index < topics.length - 1) {
          Divider()
            .color(this.lineColor)
            .margin({ left: 16 })
        }
      }, (topic: GuideTopic) => topic.id)
    }
    .width('100%')
    .backgroundColor(this.cardBg)
    .border({ width: 1, color: this.lineColor, radius: 12 })
  }

  @Builder
  private TopicGroup(section: GuideSection) {
    this.SectionLabel(section)
    this.TopicList(section.topics.slice(0, 3))
    Column()
      .width('100%')
      .height(22)
  }

  @Builder
  private EmptySearchState() {
    Column() {
      Text('没有找到相关问题')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textPrimary)

      Text('试试搜索“同步”“规则”“照片识别”或“本地导出”。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(this.textTertiary)
        .textAlign(TextAlign.Center)
        .margin({ top: 7 })
    }
    .width('100%')
    .padding({ top: 42, bottom: 48, left: 24, right: 24 })
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      this.SearchArea()

      if (this.isSearching()) {
        if (this.searchResults().length === 0) {
          this.EmptySearchState()
        } else {
          this.SearchResultLabel()
          this.TopicList(this.searchResults(), true)
        }
      } else {
        ForEach(GUIDE_SECTIONS, (section: GuideSection) => {
          this.TopicGroup(section)
        }, (section: GuideSection) => section.id)
      }
    }
    .width('100%')
    .padding({ bottom: 34 })
    .alignItems(HorizontalAlign.Start)
  }
}
