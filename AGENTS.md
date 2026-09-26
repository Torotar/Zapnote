﻿# 识录笔记（ZapNote）Codex 协作指南

本文档面向 Codex / AI 工程助手，用于在 `Zapnote` 项目中保持一致的工程判断、页面边界、交互语义和验证方式。

## 项目背景

- 项目类型：HarmonyOS ArkTS 应用。
- 工作目录：`C:\Users\torotar\DevEcoStudioProjects\Zapnote`。
- 主要源码目录：`entry/src/main/ets`。
- 页面目录：`entry/src/main/ets/pages`。
- 组件目录：`entry/src/main/ets/components`。
- 服务目录：`entry/src/main/ets/services`。
- 主入口：`entry/src/main/ets/entryability/EntryAbility.ets` 加载 `pages/Index`。
- 声明设备：`phone`、`2in1`。
- 当前 SDK：`targetSdkVersion` / `compatibleSdkVersion` 为 `6.1.0(23)`。
- 当前项目强调原生 HarmonyOS / HDS 体验，不应退回 WebView 或自绘系统级页面壳。

## 协作基本原则

- 先理解真实目标，再实现功能。若用户直接给出实现方案但目标不清，先区分：用户目标、当前方案、可选方案、推荐方案。
- 涉及架构、状态管理、数据模型、权限、依赖、路由、主要 UI 结构时，先说明技术判断依据。
- 重要实现前简短说明：影响范围、可能破坏的模块、验证方式。
- 存在多个实现路径时，至少给出两个方案，并比较复杂度、扩展性、风险、开发成本，再推荐一个。
- 不为短期跑通引入长期难维护的临时方案。如确需临时处理，必须标记 `TODO` 并说明原因。
- 用户反馈“没有变化”“仍然不对”时，继续追到真实可见行为变化，不要只解释上一轮修改。

## 文档一致性

- 当前仓库根目录暂未固定存在 `/docs` 规范目录；若后续创建，应优先保持代码与文档一致。
- 所有大的功能、信息架构、数据结构、权限模型或主要布局调整，都要询问用户是否同步更新 `/docs` 中对应文档，并提出更新大纲。
- 若实现与既有文档或原型偏离，必须说明偏离点、偏离原因和潜在影响。
- 若发现实际功能、UI、数据模型、交互流程与文档不一致，提醒用户选择：更新代码、更新文档、或记录偏差原因。

## 代码与文件边界

- 独立可导航页面应拆成独立页面文件，遵守“一个页面一个文件”。
- 根级页面和主要页面集中在 `entry/src/main/ets/pages`：
  - `Index.ets`
  - `HomePage.ets`
  - `FavoritesPage.ets`
  - `StatsPage.ets`
  - `SettingsPage.ets`
  - `DiaryEditorPage.ets`
- 设置二级页面也应作为真实页面文件维护：
  - `SettingsMainPage.ets`
  - `HuaweiAccountLoginPage.ets`
  - `AppearanceSettingsPage.ets`
  - `AutofillSettingsPage.ets`
  - `SyncSettingsPage.ets`
  - `WebdavSettingsPage.ets`
  - `PrivacySettingsPage.ets`
  - `DataSettingsPage.ets`
  - `RecycleBinSettingsPage.ets`
  - `GuideSettingsPage.ets`
  - `GuideCategoryPage.ets`
  - `GuideDetailSettingsPage.ets`
  - `UserAgreementSettingsPage.ets`
  - `PrivacyStatementSettingsPage.ets`
  - `AboutSettingsPage.ets`
- 可复用 UI 应放在 `entry/src/main/ets/components`，例如：
  - `FloatingActionMenu.ets`
  - `SettingRows.ets`
  - `SettingNavItem.ets`
  - `DiaryEntryCard.ets`
  - `DiaryListTabContent.ets`
  - `EmptyStateCard.ets`
  - `ZapStatCard.ets`
  - `LegalDocumentLayout.ets`
  - `HdsSubPageTitleBarOptions.ets`
  - `HdsTabTitleBarOptions.ets`
- 业务服务应放在 `entry/src/main/ets/services`，例如：
  - `ZapNotePreferencesService.ets`
  - `ZapNoteDiaryStorageService.ets`
  - `ZapNoteBackupService.ets`
  - `ZapNoteCredentialService.ets`
  - `ZapNoteHuaweiAccountService.ets`
  - `WebDavService.ets`
  - `OcrTextRecognitionService.ets`
  - `OcrRuleProcessingService.ets`
  - `MatchRuleKeywordService.ets`
  - `LinkRecognitionService.ets`
  - `AiVisualParsingService.ets`
  - `ScreenCapturePhotoService.ets`
  - `PhotoAlbumSaveService.ets`
  - `ZapNoteAntiPeepService.ets`
  - `ZapNoteFloatingBallService.ets`

## 架构所有权

- `EntryAbility.ets` 负责应用启动、沉浸式窗口、跟随系统色彩同步、系统分享图片入口，不应承载页面业务。
- `Index.ets` 负责四个顶层 tab、编辑器覆盖层、分享/双触图片识别流、备份导入导出、WebDAV 推拉、系统栏颜色和全局设置状态。
- `SettingsPage.ets` 负责设置面板路由、设置页通用 sheet、智能填写配置、自定义规则、AI 引擎配置与设置子页 props 分发。
- `ZapNoteTypes.ets` 是跨页面模型的权威来源。新增日记字段、同步范围、规则字段、设置面板枚举时，优先从这里扩展，再更新服务和页面。
- `GuideContent.ets` 是应用内帮助内容。功能行为改变后，不要只改 UI；同步检查这里的用户说明是否仍准确。
- `ZapNoteTheme.ets` 与 `DiaryStatsUtils.ets` 是共享计算工具。跨页面主题色、统计口径、日期过滤逻辑应优先复用它们，不要在页面内复制。

## 页面与状态约定

- `Index.ets` 是全局协调层，负责顶层状态、页面路由、设置值传递、日记数据流转等。
- `SettingsPage.ets` 是设置页 shell / router / prop handoff 的中心，不要把设置二级页面的壳逻辑散落到子页面。
- 设置页返回后需要保留位置时，优先保持基础设置页挂载，再用二级页覆盖；不要依赖重新构造滚动位置。
- 设置子页应复用 HDS 子页标题栏模式，例如 `HdsNavDestination` 与 `createHdsSubPageTitleBarOptions(...)`。
- 只修改用户要求的页面或行为，除非跨文件状态流确实需要一起改。
- 当前顶层导航是一个底部 `HdsTabs`，四个 tab 为首页、收藏、统计、设置；不要把真实页面内容移到 tabs 外层再留空 `TabContent`。
- 设置子页通常通过 `settingsPanel` 覆盖在设置 tab 之上。新增设置子页时，应更新 `SettingPanel` 类型、`SettingsPage.ets` 分发、入口行、返回路径。
- `SettingPanel` 当前包括：`main`、`huaweiAccountLogin`、`appearance`、`autofill`、`sync`、`webdav`、`privacy`、`data`、`recycleBin`、`guide`、`userAgreement`、`privacyStatement`、`about`。
- 缓存 tab 中的设置计数或状态若不刷新，优先检查 `Index.ets` 的状态传播、remount key、`SettingsPage.ets` props，而不是只改子页局部 `@State`。

## 数据、持久化与备份边界

- 日记主模型是 `DiaryEntry`，包含标题、正文、日期、心情、天气、收藏、字数、照片和缩略图裁剪参数。改动字段时必须检查卡片、编辑器、统计、备份、回收站。
- 回收站模型是 `RecycleBinEntry`，由 `ZapNoteDiaryStorageService.ets` 维护，文件名包括 `zapnote-recycle-bin.json`。
- 日记本体优先走 `ZapNoteDiaryStorageService.ets` 的文件存储；`ZapNotePreferencesService.ets` 中仍有兼容性读取/写入方法，修改启动加载时要确认当前权威路径。
- 稳定配置走 `ZapNotePreferencesService.ets`，包括主题、界面开关、智能填写、双触、分享图片、同步设置、同步日志、规则模板、AI 引擎配置、华为账号信息等。
- WebDAV 密码和 AI API Key 通过 `ZapNoteCredentialService.ets` 的 credential alias 存取。不要把明文密钥新增到普通 preferences、日志、toast、指南或备份展示文案里。
- 备份服务是 `ZapNoteBackupService.ets`。备份 payload 当前包含 app 标识、版本、scope、diaries、settings、folders、photo assets 等，改动时要保持旧数据可恢复。
- 同步范围 `SyncDataScope` 为 `diaries`、`settings`、`all`。WebDAV 推拉、导入导出、设置页说明和应用内指南必须保持一致。
- 本地照片进入日记时要考虑复制到应用文件目录、备份时收集 photo assets、恢复时重建可读 URI，不能只保存临时 picker URI。
- 新增设置项时至少检查：默认值、读取、保存、备份导出、备份恢复、WebDAV 设置范围、页面显示、应用内指南。

## UI 与交互约定

- 优先使用官方 HarmonyOS / HDS 组件和交互。用户提供华为设计/API 链接时，以官方文档为准。
- 中文页面使用中文标签和中文反馈。
- 保持已有稳定 UI，不因局部修复顺手重做无关区域。
- 底部导航、设置页壳、HDS 标题栏等稳定结构不要随意替换。
- 共享标题栏行为属于全局面。修改 `HdsSubPageTitleBarOptions.ets` 或 `HdsTabTitleBarOptions.ets` 会影响大量页面，必须先说明影响面并扩大验证。
- 自定义弹窗、半模态、底部 sheet 等系统交互应优先走官方组件，例如 `bindSheet`。
- `bindSheet` 等全局 sheet 应绑定在外层页面容器，不要挂在过深的子页面或列表项上。
- 用户明确要求保留的交互不能通过禁用来“修复”，例如可拖动的 `HdsTabs`。
- 浮动按钮、右侧快捷操作不能阻塞列表滚动。
- 短暂反馈优先使用 `promptAction.showToast`，除非用户要求持久状态区域。
- 如果 HDS 菜单图标把线性 SVG 渲染成实心或遮罩效果，可保留 HDS 标题栏位置，但用 `stackBuilder` 渲染原始 `Image($rawfile(...))` 或 PixelMap 图标。
- 视觉/动效问题要用用户描述的真实感受作为验收条件，例如键盘收起跳动、拖动越界、标题栏背板变化，不能只以编译通过结束。

## 权限与系统能力

- `module.json5` 当前请求权限：`INTERNET`、`VIBRATE`、`CUSTOM_SCREEN_CAPTURE`、`DLP_GET_HIDE_STATUS`、`DETECT_GESTURE`。
- 新增或移除权限前，必须先说明用户场景、系统弹窗理由、隐私政策影响、商店审核风险和替代方案。
- 图片选择优先使用系统 picker 能力，避免不必要的媒体库读取权限。历史上已移除 `READ_IMAGEVIDEO`，不要为普通选图回退加回来。
- `CUSTOM_SCREEN_CAPTURE` 仅对应用户触发的智控键双触截图识别，应明确本地 OCR、保留/清理策略、上传状态和关闭后的效果。
- `DLP_GET_HIDE_STATUS` 对应防窥/隐私保护能力，修改 `ZapNoteAntiPeepService.ets` 时要同步检查权限理由和设置项。
- `DETECT_GESTURE` 对应持握手势/适人握持能力，首页浮动菜单可跟随左右手，但不要把该设置自动套到所有底部 tab 或无关浮层。
- 网络能力主要服务 WebDAV 和自定义 AI 视觉解析。所有网络失败都应给出可理解的失败原因，不要只显示“失败”。

## 已知功能约定

### 日记编辑

- `DiaryEditorPage.ets` 应保留 HDS 标题栏，不要把标题栏替换成 HTML 原型中的自绘壳。
- 收藏心形按钮不只看本地点击处理，还要检查 `DiaryEditorPage.ets -> Index.ets -> 日记列表/卡片` 的父状态和持久化路径。
- 键盘跟随、输入区避让属于核心交互，编译通过不等于体验完成。
- 编辑器显示时底部 `HdsTabs` 应隐藏，避免编辑器官方工具栏和应用 tab 同时占用底部区域。
- 编辑器底部工具栏优先使用官方 `ToolBar` / `toolbarConfiguration` 路径；不要用手写 `Row + Button` 替代官方编辑器工具栏语义。
- 从编辑器工具栏添加照片时，OCR 确认标题应保持空白并把识别内容追加到正文；首页/分享图片自动路径可继续使用自动标题逻辑。
- 多图、缩略图、全屏预览、双击缩放等照片行为要区分：全屏预览交互不等于卡片缩略图裁剪。

### 设置页

- 设置主页和设置二级页是不同页面语义，应按文件边界拆分。
- `SettingsPage.ets` 负责 `appearance`、`autofill`、`sync`、`webdav`、`privacy`、`data`、`guide`、`about` 等面板切换。
- 共享设置行、开关行、选择行等放在 `SettingRows.ets`，避免每个设置页重复实现。
- 关键词模板删除逻辑应保持在 `SettingsPage.ets` 的权威路径中，滑动删除和点击删除应收敛到同一个确认流程。
- 新增设置入口时要同步检查设置主页、搜索/指南入口、返回链路、持久化、备份范围、深色模式。
- 法律文档和关于页使用独立页面与 `LegalDocumentLayout.ets`，不要塞回 About 页面内的长文本块。
- 回收站是设置体系中的独立目的地，清空操作属于危险动作，应保留确认并刷新设置页计数。

### WebDAV 与数据备份

- WebDAV 同步必须是真实云端 I/O，不接受只写 toast、日志或模拟状态。
- 典型 WebDAV 动作：
  - `PROPFIND`：验证连接或远端路径。
  - `MKCOL`：创建远端目录。
  - `PUT`：上传备份。
  - `GET`：下载备份。
- 空远端路径可以回退默认值；非空自定义路径必须原样保留，不要偷偷改回默认路径。
- 同步日志应能在当前页面实时刷新；注意状态传播和列表行 key 的稳定性。
- 本地导出备份应保存真实用户可选文件，不要停在预览或摘要界面。
- WebDAV 远端文件名可保持稳定，本地导出文件名可以带时间戳。
- `WebDavService.responseResultToString(...)` 需要处理 `ArrayBuffer`、BOM、HTML 响应和非 JSON 失败，避免把服务商错误页当备份解析。
- 推送/拉取前要检查服务器 URL、账号、密码、远端路径、同步范围、恢复策略。恢复策略只在范围包含日记时影响日记合并/覆盖。
- `ZapNoteBackupService.BACKUP_FILE_NAME` 是云端稳定文件名 `zapnote-backup.json`；`exportBackupFileName(...)` 是本地导出时间戳文件名。
- 数据管理页的备份结果/历史区域应保持清晰层级，不要把历史卡片塞进顶部状态卡造成信息噪声。

### OCR 与快捷入口

- OCR 的自然入口是首页浮动菜单和日记编辑页图片按钮。
- OCR 实现应集中在 `OcrTextRecognitionService.ets`，避免页面内重复堆业务逻辑。
- 图片识别涉及文件 URI 时，优先确认真实文件读取和图像解码路径，而不是只处理选择器回调。
- 当前 OCR 后处理扩展点是 `OcrRuleProcessingService.ets`。规则、指南和确认页文案必须围绕实际执行路径写，不要承诺未接入的剪切板/智能填写运行时。
- 自定义规则模型包括 `action`、`range`、`matchMode`、`kind`、`scopes`、`linkType` 等字段。改规则表单时要同步默认兼容、备份恢复和指南。
- 增强链接识别由 `LinkRecognitionService.ets` 处理，主要服务自定义 AI 引擎下的主流链接提取。不要让 AI 改写网盘/磁力/飞书/QQ/微信链接原文。
- 自定义 AI 视觉解析路径是系统 OCR 后调用 `AiVisualParsingService.parseOcrText(...)`，默认规则路径仍应保留 `OcrRuleProcessingService`。
- 分享图片入口由 `EntryAbility.ets` 接收 `ohos.want.action.sendData`，再通过 `AppStorage` 请求键通知 `Index.ets` 消费。
- `consumeSharedPhotoRequest()` 是分享图片统一入口；取消识别不应显示回收站提醒，确认识别后再按一次性提示规则处理。
- 分享截图“删除后仍在系统最近删除/回收站”属于用户教育点，相关说明在 `GuideContent.ets`，改动流程时要同步检查。

### AI 视觉解析

- 自定义 AI 引擎配置包括 provider、baseUrl、model、apiKey、outputContent，多配置选择值使用 `custom:<id>`。
- API Key 应通过 `ZapNoteCredentialService` 保存，备份中只应包含非敏感配置，如 provider、baseUrl、model、outputContent。
- 拉取模型列表和解析 OCR 文本都属于真实网络请求，需处理 HTML 响应、空响应、配置缺失、模型缺失和服务商错误信息。
- 普通默认 OCR/规则路径不要因新增 AI 引擎而退化；自定义 AI 是可选增强，不应成为所有识别的硬依赖。

### 华为账号

- 华为账号信息模型是 `HuaweiAccountInfo`，设置页顶部账号入口和 `HuaweiAccountLoginPage.ets` 负责显示/登录。
- 登录能力应优先使用官方 AccountKit 登录按钮和服务封装，不要用自绘按钮假装官方登录。
- 若设备、签名或环境导致真实登录不可用，界面反馈必须诚实说明，不要展示“已登录”的模拟成功态。

### 统计页

- 统计页调整应尽量围绕用户可见指标和原型结构进行。
- 若出现内层滚动、滚动条异常或卡片高度异常，先定位具体容器高度和嵌套滚动来源。
- 统计口径应复用 `DiaryStatsUtils.ets`。新增日期、周/月、收藏、字数、心情统计时要避免页面内重复计算导致口径漂移。
- 日历/热力图类 UI 要按真实日期核对周几和月份布局，用户可能会手动对照真实日历。

### 主题与沉浸式

- 跟随系统外观的关键路径是：`EntryAbility.ets` 把系统色彩写入 `AppStorage('zapnoteSystemColorMode')`，`Index.ets` 根据 `themeMode` 解析实际 light/dark。
- `auto` 是用户选择值，不等于实际渲染色彩；状态栏、导航栏、页面色值应使用解析后的 light/dark。
- 改系统栏或标题栏材质时要同时检查浅色、深色、护眼、跟随系统四类状态。

## 典型任务决策矩阵

- 要改日记字段：先改 `ZapNoteTypes.ets`，再检查 `DiaryEditorPage.ets`、`DiaryEntryCard.ets`、`DiaryListTabContent.ets`、`HomePage.ets`、`FavoritesPage.ets`、`StatsPage.ets`、`ZapNoteBackupService.ets`、`ZapNoteDiaryStorageService.ets`。
- 要改设置项：先确认是否持久化，再改 `ZapNotePreferencesService.ets`、`Index.ets` 状态、`SettingsPage.ets` props、具体设置子页、备份设置、指南。
- 要改 WebDAV：优先查 `WebDavService.ets`、`ZapNoteBackupService.ets`、`Index.ets` 的 push/pull、`SyncSettingsPage.ets`、`WebdavSettingsPage.ets`、`GuideContent.ets`。
- 要改 OCR：优先查 `OcrTextRecognitionService.ets`、`OcrRuleProcessingService.ets`、`LinkRecognitionService.ets`、`AiVisualParsingService.ets`、`Index.ets` 的确认页、`DiaryEditorPage.ets` 的照片入口。
- 要改分享图片/双触：先查 `EntryAbility.ets`、`Index.ets`、`AutofillSettingsPage.ets`、`ScreenCapturePhotoService.ets`、`PhotoAlbumSaveService.ets`、权限理由和指南。
- 要改设置壳/子页：先查 `SettingPanel`、`SettingsPage.ets` 分发、`SettingsMainPage.ets` 入口、`createHdsSubPageTitleBarOptions(...)`、返回处理和 remount 刷新。
- 要改 HDS 标题栏/底部 tab：先查共享 helper，确认是否影响所有 tab/subpage，再验证四个顶层 tab、设置子页、编辑器覆盖层。
- 要改法律/关于/指南：先查 `GuideContent.ets`、`LegalDocumentLayout.ets`、对应 settings page 和返回链路；文案必须和真实功能一致。

## 实现前检查清单

在进行中等以上改动前，先简短说明：

- 本次用户目标是什么。
- 当前实现方案解决的是目标还是表层方案。
- 影响哪些文件或模块。
- 哪些状态、路由、持久化或权限可能受影响。
- 如何验证：编译、页面检查、交互路径、数据持久化、云端实际结果等。

## 验证方式

- 优先使用 `rg` / `rg --files` 搜索文件和引用。
- 修改 ArkTS 后至少做源码引用检查；影响编译面的改动应运行 HAP 构建。
- 如果需要 Git 信息，优先用 `git -C C:\Users\torotar\DevEcoStudioProjects\Zapnote ...`，避免 shell 不在仓库根目录造成误判。
- 本机曾验证可用的构建方式如下，如路径变化需先检查 DevEco Studio 安装位置：

```powershell
$env:DEVECO_SDK_HOME = "D:\application\other\huawei\DevEco Studio\sdk"
& "D:\application\other\huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" --mode module -p module=entry assembleHap --no-daemon
```

- 若 `hvigor` / `ohpm` 不在 `PATH`，先查找 DevEco Studio 自带 wrapper，不要直接假设命令不可用。
- 构建通过不等于签名、安装或上架通过。遇到 `SignHap`、证书、bundleName、UDID 或设备安装问题时，要把编译结果和签名/安装阻塞分开说明。
- 涉及 WebDAV 的修改必须验证真实远端文件创建、上传、下载或失败提示。
- 涉及导出文件的修改必须验证真实文件写出路径。
- 涉及 UI 行为的修改，编译成功后还要说明用户如何在页面上确认结果。
- 涉及设备能力的修改，如双触、截图、防窥、系统分享、AccountKit，源码和构建只能证明部分正确；最终还需要真机或对应系统能力验证。
- 涉及应用内指南的修改，要用实际入口走一遍：设置入口、指南列表、详情页、返回链路、搜索/相关主题如有。

## 常见问题排查提示

- 中文乱码：优先确认文件编码和读取编码，`AGENTS.md` 与中文 ArkTS 文案保持 UTF-8。不要只修编译错误而留下可见乱码。
- 点击无效：从 UI 回调追到父状态和持久化服务，不要只看当前组件 `onClick`。
- 设置值不生效：检查 `Index.ets` 初始加载、`ZapNotePreferencesService` 读写、props 传递、cached tab/remount、子页本地 `@State`。
- 页面返回异常：检查 `settingsPanel`、覆盖层 `zIndex`、父级 back request、子页内部二级状态，不要用重置整个设置页代替精准返回。
- sheet 位置不对：检查 `bindSheet` 是否挂在外层容器；内层子页只负责发起请求。
- WebDAV “成功但没文件”：必须查真实 `PUT`、远端路径、目录创建、响应码和服务端内容，toast 不算完成。
- 拉取 JSON 失败：检查响应是否 `ArrayBuffer`、BOM、HTML 错误页、空文件或 scope 不含所需数据。
- OCR 识别失败：检查 picker URI、`fileIo.openSync(uri)`、图像源创建、CoreVision 初始化、错误 toast 是否带阶段信息。
- 图标显示异常：区分 rawfile SVG 本身、HDS 菜单模板渲染、标题栏材质背板、深色资源。
- 统计不准：先确认 `dateMs`、`createdAt`、`updatedAt`、`DiaryStatsUtils.activityDateMs()` 的口径，再改 UI。

## 编码与编辑注意

- `AGENTS.md` 和中文 ArkTS 文案必须保持 UTF-8，发现乱码优先修复可见中文。
- 不要大范围格式化无关文件。
- 不要回滚用户未要求回滚的修改。
- 若工作区已有脏改动，先判断是否相关；无关改动忽略，相关改动要顺着现状继续。
- 删除页面、路由、数据字段前，必须先用引用搜索确认影响范围。

## 回复风格

- 最终回复要说明做了什么、关键判断是什么、如何验证。
- 不只交付代码，也要适度解释为什么这样做。
- 若有更长期、更稳的方案，应礼貌但明确提出，不要只迎合即时指令。
