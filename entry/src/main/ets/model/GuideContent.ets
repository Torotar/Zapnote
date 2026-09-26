export interface GuideTopic {
  id: string;
  sectionId: string;
  sectionTitle: string;
  question: string;
  summary: string;
  contentTitle: string;
  steps: string[];
  tip: string;
  keywords: string;
}

export interface GuideSection {
  id: string;
  title: string;
  topics: GuideTopic[];
}


export const SYNC_TOPICS: GuideTopic[] = [{
  id: 'sync-configure',
  sectionId: 'sync',
  sectionTitle: '数据同步',
  question: '怎样配置 WebDAV 同步？',
  summary: '填写服务器与账户信息，先测试连接，再保存可用配置。',
  contentTitle: '操作步骤',
  steps: [
    '进入“设置 > WebDAV 同步 > WebDAV 账户”。',
    '依次填写服务器地址、账号、授权密码和远端路径。',
    '确认服务器地址以 http:// 或 https:// 开头。',
    '先点击测试连接；连接成功后，再保存当前配置。'
  ],
  tip: '建议使用服务商提供的应用授权密码，不要直接使用主账号密码。自定义远端路径会按填写内容保存。',
  keywords: 'WebDAV 配置 服务器 地址 账号 密码 路径 测试连接'
}, {
  id: 'sync-push-pull',
  sectionId: 'sync',
  sectionTitle: '数据同步',
  question: '“推送数据”和“拉取数据”有什么区别？',
  summary: '推送是上传本地备份，拉取是下载云端备份并恢复到本机。',
  contentTitle: '区别说明',
  steps: [
    '“推送数据”会把当前本地内容和照片生成 ZIP 备份，并上传到 WebDAV。',
    '“拉取数据”会从 WebDAV 下载 ZIP 备份并恢复笔记、设置和照片；旧 JSON 仍可读取。',
    '开始前请确认同步范围是笔记、设置还是全部。'
  ],
  tip: '首次使用建议先推送一份本地数据，确认同步日志显示成功后再尝试拉取。',
  keywords: '推送 拉取 上传 下载 备份 同步范围 笔记 设置 全部'
}, {
  id: 'sync-merge-overwrite',
  sectionId: 'sync',
  sectionTitle: '数据同步',
  question: '拉取时应该选择“合并”还是“覆盖”？',
  summary: '合并会保留本地更改；覆盖会以云端备份替换本地笔记。',
  contentTitle: '选择建议',
  steps: [
    '选择“合并”时，会保留本地更改，并补入云端新增笔记。',
    '选择“覆盖”时，会以云端备份为准，替换当前本地笔记列表。',
    '只有同步范围包含笔记时，恢复策略才会生效。'
  ],
  tip: '不确定时优先选择“合并”。使用“覆盖”前建议先导出本地备份。',
  keywords: '合并 覆盖 恢复策略 本地 云端 替换'
}, {
  id: 'sync-auto-log',
  sectionId: 'sync',
  sectionTitle: '数据同步',
  question: '自动同步什么时候执行？',
  summary: '定时模式按选定时间执行，变化同步会在笔记内容改变后触发。',
  contentTitle: '触发方式',
  steps: [
    '定时模式会在应用运行期间，按选定时间尝试同步。',
    '变化同步模式会在笔记内容发生变化后触发。',
    '无论选择哪种模式，都可以随时手动推送或拉取。'
  ],
  tip: '同步结果会写入当前页面的同步日志。失败时先查看日志，再检查网络、服务器地址和账号权限。',
  keywords: '自动同步 定时 变化同步 日志 失败 网络'
}];

export const RULE_TOPICS: GuideTopic[] = [{
  id: 'rule-options',
  sectionId: 'rules',
  sectionTitle: '自定义规则',
  question: '匹配范围、处理动作和作用范围如何配合？',
  summary: '按“在哪运行、做什么、处理哪里”的顺序理解这三组选项。',
  contentTitle: '选项原理',
  steps: [
    '匹配范围用于标记规则适用的入口，可同时选择“剪切板”和“照片分析”。当前 OCR 流程会执行已启用且包含“照片分析”的规则；剪切板范围会随规则保存。',
    '处理动作决定命中后的结果：“选取”仅保留指定范围的内容，“排除”从结果中删除指定范围，“屏蔽”用替换内容覆盖指定范围；未填写替换内容时会显示为 ****。',
    '作用范围决定动作落在哪一层文本：“命中内容”只处理匹配到的内容，“当前行”处理发现关键词的整行，“所在段落”处理该行所属的整段内容。',
    '选择“命中内容”时，正则规则使用实际匹配片段；普通关键词会优先获取关键词在同一视觉行右侧的内容。',
    '将三组选项连起来理解：在“匹配范围”运行后，对“作用范围”执行“处理动作”。例如“照片分析 + 屏蔽 + 命中内容”，会只遮盖照片识别结果中的匹配内容。'
  ],
  tip: '存在“选取”规则时，处理结果会以被选取的内容为主。建议先在照片分析中确认结果，再将内容填入笔记。',
  keywords: '匹配范围 处理动作 作用范围 选取 排除 屏蔽 命中内容 当前行 所在段落 剪切板 照片分析'
}, {
  id: 'rule-enhanced-links',
  sectionId: 'rules',
  sectionTitle: '自定义规则',
  question: '怎样加快主流链接识别？',
  summary: '使用自定义模型时开启“增强链接识别”，让链接由默认模型提取，其他内容继续交给自定义 AI。',
  contentTitle: '设置方法',
  steps: [
    '进入“设置 > 智能填写”，点击页面顶部的“设置”选项。',
    '在“解析模型”中选择一个已经配置好的自定义模型。',
    '开启“增强链接识别”。当关键词或输出要求是通用的“链接”时，应用会提取磁力、网盘、飞书、QQ、微信等主流链接，并只把链接以外的内容交给自定义 AI。',
    '使用自定义模型时，只有开启“增强链接识别”后，应用才会让默认模型提取链接；关键词或输出要求明确写了“磁力链接”“百度网盘链接”“飞书链接”“QQ链接”或“微信链接”等具体类型时，只保留对应类型的链接，不把其他 OCR 内容带入确认页。',
    '切换为默认模型后，该开关会变为不可选择，因为链接已经由默认模型处理。'
  ],
  tip: '链接会按 OCR 中的出现顺序去重并原样保留；网盘提取码会随对应链接一同处理，AI 不会改写链接地址。',
  keywords: '增强链接识别 加快链接识别 磁力链接 网盘链接 飞书链接 QQ链接 微信链接 默认模型 自定义模型 AI OCR'
}, {
  id: 'rule-create',
  sectionId: 'rules',
  sectionTitle: '自定义规则',
  question: '怎样创建自定义规则？',
  summary: '先确定规则何时运行和要处理的内容，再配置匹配条件、输出方式和启用状态。',
  contentTitle: '操作步骤',
  steps: [
    '进入“设置 > 智能填写 > 自定义匹配规则”。',
    '先确定规则的目标：它应在哪个入口运行，命中后是保留、删除还是遮盖内容，以及要处理命中内容、当前行还是所在段落。不了解这些选项时，可先查看“匹配范围、处理动作和作用范围如何配合？”。',
    '选择匹配范围。要让规则参与当前照片 OCR，至少选择“照片分析”；“剪切板”可按需求一同保存为规则的适用范围。',
    '选择处理动作和作用范围，使规则目标与结果一致：提取需要的内容时使用“选取”，删除干扰信息时使用“排除”，隐藏敏感信息时使用“屏蔽”。',
    '输入关键词。普通关键词可用逗号、中文逗号或顿号分隔，并会作为同一条规则保存；需要按固定格式匹配时，打开“使用正则表达式”后每行输入一条正则表达式。',
    '按动作配置输出：选取规则可在输出模板中使用 {{内容}}；屏蔽规则可填写替换内容，留空时使用 ****；排除规则不需要填写输出内容。',
    '确认规则已启用后添加，并从照片分析入口识别一张包含关键词的图片，核对“处理后”内容是否符合预期。'
  ],
  tip: 'OCR 仅执行启用且包含“照片分析”场景的规则。识别完成后仍可在确认页切换原文。',
  keywords: '自定义规则 创建 关键词 正则 选取 排除 屏蔽 模板 场景 照片分析 OCR'
}, {
  id: 'rule-manage',
  sectionId: 'rules',
  sectionTitle: '自定义规则',
  question: '怎样修改、停用或删除规则？',
  summary: '点击已有规则进入编辑，也可以停用或从本机保存内容中删除。',
  contentTitle: '管理方式',
  steps: [
    '在已添加的关键词模板列表中点击规则，进入编辑。',
    '可以修改场景、关键词、动作、作用范围、模板和启用状态。',
    '多条关键词规则可以同时启用；自定义 AI 引擎的多条输出模板也可以同时启用，并会按列表顺序合并为一次 AI 输出要求。',
    '使用列表提供的删除操作并确认后，规则会从本机保存内容中移除。'
  ],
  tip: '规则属于设置数据；当 WebDAV 同步范围包含设置时，会随设置备份一起推送和恢复。',
  keywords: '规则 编辑 停用 删除 滑动 备份 设置同步'
}, {
  id: 'rule-runtime',
  sectionId: 'rules',
  sectionTitle: '自定义规则',
  question: '怎样确认 OCR 规则处理结果？',
  summary: '照片文字识别后会先执行规则，并在确认页保留处理后内容和原文。',
  contentTitle: '确认方式',
  steps: [
    '从首页照片识别或笔记编辑器添加照片后，系统先完成 OCR，再执行已启用的照片分析规则。',
    '确认页会显示命中的规则；存在有效处理结果时，可以在“处理后”和“原文”之间切换。',
    '点击确认页右上角的“规则”按钮，可以临时开启或关闭已有规则。选择后点击菜单底部的“应用”，或点击菜单外部，再在“重新应用规则”弹窗中确认；该选择不会修改设置页保存的启用状态。',
    '可以继续手动修改当前内容，点击“填入正文”后才会写入笔记。'
  ],
  tip: '选取规则未命中或规则过滤了全部内容时，确认页会回退显示原文，避免不可恢复地丢失内容。',
  keywords: '规则 生效 OCR 自动匹配 处理后 原文 确认 回退'
}];

export const RECORD_TOPICS: GuideTopic[] = [{
  id: 'record-double-touch',
  sectionId: 'record',
  sectionTitle: '记录与识别',
  question: '智控键双触识别怎样使用？',
  summary: '开启双触识别后截取当前画面，并按自动识别与双触动作设置处理结果。',
  contentTitle: '操作步骤',
  steps: [
    '进入“设置 > 智能填写”，页面默认显示“双触”选项。',
    '开启“智控键双触识别”，并按系统提示授予截屏权限。',
    '在需要识别当前画面时双触指纹智控键，应用会截取画面并识别文字。',
    '未开启“自动识别并填入”时，会默认打开识别确认页。开启后，“无动作”会静默填入草稿，“点击返回”会打开识别确认页。'
  ],
  tip: '双触识别仅在部分支持指纹智控键双触事件的机型上可用。“照片填入”和“保存到本地相册”也会作用于双触截图。关闭双触识别后，动作选项不可选择。',
  keywords: '智控键 双触 指纹 截屏 识别确认页 无动作 点击返回 自动识别 照片填入'
}, {
  id: 'record-share-photo',
  sectionId: 'record',
  sectionTitle: '记录与识别',
  question: '怎样把手机里的图片分享到识录笔记？',
  summary: '从系统相册的分享面板选择识录笔记，把图片交给应用识别并填入笔记。',
  contentTitle: '操作步骤',
  steps: [
    '在系统相册中打开一张图片，点击“分享”。',
    '在系统分享面板中选择识录笔记，应用会接收这张图片。',
    '如果“自动识别并填入”已关闭，请在弹窗中选择“识别并填入”；开启时会直接开始识别。',
    '关闭“自动识别并填入”时，识别完成后会进入结果确认界面；开启时会直接把识别文字填入笔记正文。'
  ],
  tip: '当前一次分享处理一张图片。分享面板中未看到识录笔记时，可以展开全部应用后再查找。使用手机截图后分享时，即使选择“分享后删除截图”小按钮，分享给识录笔记分析完成后，截图仍会保留在手机相册回收站（最近删除）中；如需彻底删除，请在相册回收站中手动再次删除。',
  keywords: '分享图片 系统相册 分享面板 分享后删除截图 回收站 最近删除 二次删除 识录笔记 识别并填入 笔记'
}, {
  id: 'record-share-auto-recognize',
  sectionId: 'record',
  sectionTitle: '记录与识别',
  question: '“自动识别并填入”怎样设置？',
  summary: '用开关控制分享图片和双触截图是否自动识别并填入。',
  contentTitle: '设置方法',
  steps: [
    '进入“设置 > 智能填写”，点击页面顶部的“设置”选项。',
    '开启“自动识别并填入”后，从系统分享图片到识录笔记时会跳过首次识别确认并直接开始 OCR。',
    '双触识别时，开启该开关后会结合“双触动作选项”决定静默填入或打开确认页。',
    '关闭该开关后，分享图片会先询问是否识别；双触识别则默认打开识别确认页。'
  ],
  tip: '分享图片时，开启后会直接填入正文；双触识别时，选择“点击返回”仍会打开确认页供你检查内容。',
  keywords: '自动识别并填入 开关 分享图片 双触截图 OCR 确认弹窗 智能填写 设置'
}, {
  id: 'record-share-save-diary',
  sectionId: 'record',
  sectionTitle: '记录与识别',
  question: '识别照片是否填入笔记怎样选择？',
  summary: '用“填入、不填入、自选择”控制分享图片或双触截图是否附加到笔记草稿。',
  contentTitle: '选项说明',
  steps: [
    '进入“设置 > 智能填写”，点击页面顶部的“设置”选项。',
    '在“照片填入”下拉选项中选择“填入”，识别后会自动把图片副本附加到笔记草稿。',
    '选择“不填入”，图片只用于文字识别，不会附加到笔记草稿。',
    '选择“自选择”，OCR 完成后会询问是否将这张图片填入当前笔记。'
  ],
  tip: '照片填入与文字填入相互独立。不填入照片时，仍可确认识别结果并把文字填入正文。',
  keywords: '照片填入 分享图片 双触截图 填入 不填入 自选择 笔记 附件 草稿 OCR'
}, {
  id: 'record-share-save-album',
  sectionId: 'record',
  sectionTitle: '记录与识别',
  question: '怎样把识别照片保存到本地相册？',
  summary: '开启“保存到本地相册”后，分享图片或双触截图可通过系统确认另存到相册。',
  contentTitle: '设置方法',
  steps: [
    '进入“设置 > 智能填写”，点击页面顶部的“设置”选项。',
    '开启“保存到本地相册”开关。',
    '分享图片或双触截图完成识别后，按系统弹窗提示确认保存。',
    '关闭开关时，应用不会把识别照片另存到系统相册。'
  ],
  tip: '保存到本地相册与保存到笔记是两个独立选项。取消系统确认或保存失败不会阻止你检查 OCR 结果。',
  keywords: '保存到本地相册 开关 分享图片 双触截图 系统确认 OCR 笔记 独立设置'
}, {
  id: 'record-new',
  sectionId: 'record',
  sectionTitle: '记录与识别',
  question: '怎样快速新建一篇笔记？',
  summary: '使用首页右下角快捷菜单，手写记录或从照片生成草稿。',
  contentTitle: '操作步骤',
  steps: [
    '在首页点击右下角“+”按钮，打开快捷菜单。',
    '选择“手写笔记”可直接进入编辑页。',
    '选择“照片识别”可从图片中提取文字并生成草稿。',
    '编辑页切换到后台时，有内容且发生变化的草稿会自动保存；空白草稿不会生成笔记。'
  ],
  tip: '返回应用后仍可在原编辑页继续编辑已经自动保存的笔记。',
  keywords: '新建 笔记 首页 加号 手写 照片识别 快捷菜单 后台 自动保存 草稿'
}, {
  id: 'record-photo',
  sectionId: 'record',
  sectionTitle: '记录与识别',
  question: '照片识别怎样使用？',
  summary: '从首页或编辑页选择图片，识别文字后写入当前草稿。',
  contentTitle: '操作步骤',
  steps: [
    '从首页快捷菜单选择“照片识别”，或在笔记编辑页添加照片。',
    '选择需要识别的图片，应用会提取其中的文字。',
    '识别文字会写入当前草稿，同时保留所选图片。'
  ],
  tip: '识别内容确认填入后才会进入草稿；切到后台时，有变化的草稿会自动保存。识别失败或没有文字时不会自动填入文字。',
  keywords: '照片识别 OCR 图片 编辑页 草稿'
}, {
  id: 'record-backup',
  sectionId: 'record',
  sectionTitle: '记录与识别',
  question: '本地导出和 WebDAV 同步有什么区别？',
  summary: '本地导出适合手动归档，WebDAV 适合向个人云端反复推送和拉取。',
  contentTitle: '区别说明',
  steps: [
    '本地导出会生成包含 backup.json 和照片的 ZIP 文件，由你选择位置保存，适合手动归档或迁移。',
    'WebDAV 同步会把同一份 ZIP 备份上传到你配置的个人云端路径，适合多次推送和拉取。'
  ],
  tip: '加入笔记的普通照片会按 JPEG 质量 80 保存；透明 PNG 会保持 PNG。重要记录建议同时保留本地导出和可信云端备份。',
  keywords: '本地导出 WebDAV 备份 文件 迁移 云端'
}];

export const GUIDE_SECTIONS: GuideSection[] = [{
  id: 'sync',
  title: '数据同步',
  topics: SYNC_TOPICS
}, {
  id: 'rules',
  title: '自定义规则',
  topics: RULE_TOPICS
}, {
  id: 'record',
  title: '记录与识别',
  topics: RECORD_TOPICS
}];

export function allGuideTopics(): GuideTopic[] {
  return SYNC_TOPICS.concat(RULE_TOPICS).concat(RECORD_TOPICS);
}

export function getGuideTopic(topicId: string): GuideTopic {
  const topics: GuideTopic[] = allGuideTopics();
  const matched: GuideTopic | undefined = topics.find((topic: GuideTopic): boolean => topic.id === topicId);
  return matched === undefined ? topics[0] : matched;
}

export function getGuideSection(sectionId: string): GuideSection {
  const matched: GuideSection | undefined = GUIDE_SECTIONS.find((section: GuideSection): boolean => {
    return section.id === sectionId;
  });
  return matched === undefined ? GUIDE_SECTIONS[0] : matched;
}

export function getGuideRelatedTopics(topicId: string): GuideTopic[] {
  const current: GuideTopic = getGuideTopic(topicId);
  return allGuideTopics().filter((topic: GuideTopic): boolean => {
    return topic.sectionId === current.sectionId && topic.id !== current.id;
  }).slice(0, 3);
}
