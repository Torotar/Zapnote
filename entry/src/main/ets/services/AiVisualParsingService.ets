import { http } from '@kit.NetworkKit';
import { AiVisualEngineConfig, MatchRuleTemplateItem } from '../model/ZapNoteTypes';

interface AiMessage {
  role: string;
  content: string;
}

interface AiChatRequest {
  model: string;
  messages: AiMessage[];
  temperature: number;
}

interface AiChatChoice {
  message?: AiMessage;
}

interface AiErrorBody {
  message?: string;
}

interface AiChatResponse {
  choices?: AiChatChoice[];
  error?: AiErrorBody;
}

interface AiModelItem {
  id?: string;
}

interface AiModelResponse {
  data?: AiModelItem[];
  error?: AiErrorBody;
}

interface AiStructuredOutput {
  title?: string;
  content?: string;
  body?: string;
}

interface AiParsedOutput {
  title: string;
  content: string;
}

export interface AiVisualParseResult {
  success: boolean;
  title: string;
  content: string;
  message: string;
}

export interface AiVisualModelsResult {
  success: boolean;
  models: string[];
  message: string;
}

export class AiVisualParsingService {
  public static resolveOutputContent(
    items: MatchRuleTemplateItem[],
    configId: string,
    fallback: string = ''
  ): string {
    let hasOutputTemplate: boolean = false;
    const requirements: string[] = [];
    items.forEach((item: MatchRuleTemplateItem): void => {
      if (item.kind !== 'ai-output' || item.aiConfigId !== configId) {
        return;
      }
      hasOutputTemplate = true;
      const requirement: string = item.template.trim();
      if (item.enabled && requirement.length > 0) {
        requirements.push(requirement);
      }
    });
    if (!hasOutputTemplate) {
      return fallback.trim();
    }
    if (requirements.length <= 1) {
      return requirements.length === 1 ? requirements[0] : '';
    }
    const numberedRequirements: string[] = ['请同时满足以下输出要求：'];
    requirements.forEach((requirement: string, index: number): void => {
      numberedRequirements.push((index + 1).toString() + '. ' + requirement);
    });
    return numberedRequirements.join('\n');
  }

  private static stripCodeFence(value: string): string {
    let normalized: string = value.trim();
    if (!normalized.startsWith('```')) {
      return normalized;
    }
    const firstLineEnd: number = normalized.indexOf('\n');
    if (firstLineEnd >= 0) {
      normalized = normalized.substring(firstLineEnd + 1);
    }
    if (normalized.endsWith('```')) {
      normalized = normalized.substring(0, normalized.length - 3);
    }
    return normalized.trim();
  }

  private static parseStructuredOutput(value: string): AiParsedOutput {
    const normalized: string = AiVisualParsingService.stripCodeFence(value);
    const objectStart: number = normalized.indexOf('{');
    const objectEnd: number = normalized.lastIndexOf('}');
    if (objectStart >= 0 && objectEnd > objectStart) {
      try {
        const parsed: AiStructuredOutput =
          JSON.parse(normalized.substring(objectStart, objectEnd + 1)) as AiStructuredOutput;
        const title: string = typeof parsed.title === 'string' ? parsed.title.trim() : '';
        const contentValue: string | undefined = typeof parsed.content === 'string' ? parsed.content : parsed.body;
        const content: string = typeof contentValue === 'string' ? contentValue.trim() : '';
        return { title: title, content: content };
      } catch (error) {
        console.warn('AiVisualParsingService parse structured output failed: ' + JSON.stringify(error));
      }
    }
    const lines: string[] = normalized.split(/\r?\n/);
    let title: string = '';
    const contentLines: string[] = [];
    let hasLabel: boolean = false;
    let collectingContent: boolean = false;
    lines.forEach((line: string): void => {
      const trimmed: string = line.trim();
      if (trimmed.startsWith('标题：') || trimmed.startsWith('标题:')) {
        title = trimmed.substring(3).trim();
        hasLabel = true;
        collectingContent = false;
        return;
      }
      if (trimmed.startsWith('正文：') || trimmed.startsWith('正文:')) {
        contentLines.push(trimmed.substring(3).trim());
        hasLabel = true;
        collectingContent = true;
        return;
      }
      if (collectingContent) {
        contentLines.push(line);
      }
    });
    if (hasLabel) {
      return { title: title, content: contentLines.join('\n').trim() };
    }
    return { title: '', content: normalized };
  }

  public static async parseOcrText(text: string, config: AiVisualEngineConfig): Promise<AiVisualParseResult> {
    const validationMessage: string = AiVisualParsingService.validateConfig(config, true);
    if (validationMessage.length > 0) {
      return { success: false, title: '', content: '', message: validationMessage };
    }
    const request: http.HttpRequest = http.createHttp();
    try {
      const body: AiChatRequest = {
        model: config.model.trim(),
        messages: [
          {
            role: 'system',
            content: '你是 OCR 文本整理助手。只能依据系统 OCR 提供的文字进行整理和纠错，不得补充原文中不存在的事实。请严格遵守用户的输出要求。只返回 JSON 对象，不要代码块或解释：{"title":"笔记标题","content":"笔记正文"}。如果输出要求未要求标题，将 title 设为空字符串；如果未要求正文，将 content 设为空字符串。'
          },
          {
            role: 'user',
            content: '输出要求：\n' + config.outputContent.trim() + '\n\n系统 OCR 识别内容：\n' + text.trim()
          }
        ],
        temperature: 0.2
      };
      const response: http.HttpResponse = await request.request(
        AiVisualParsingService.buildChatUrl(config.baseUrl), {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + config.apiKey.trim()
          },
          extraData: JSON.stringify(body),
          connectTimeout: 30000,
          readTimeout: 60000
        });
      const responseText: string = String(response.result);
      if (AiVisualParsingService.isHtmlResponse(responseText)) {
        return { success: false, title: '', content: '', message: 'AI 接口返回了网页内容，请检查 Base URL' };
      }
      const parsed: AiChatResponse = JSON.parse(responseText) as AiChatResponse;
      if (parsed.error && parsed.error.message) {
        return { success: false, title: '', content: '', message: parsed.error.message };
      }
      if (parsed.choices && parsed.choices.length > 0 && parsed.choices[0].message) {
        const output: AiParsedOutput =
          AiVisualParsingService.parseStructuredOutput(parsed.choices[0].message.content);
        if (output.title.length > 0 || output.content.length > 0) {
          return {
            success: true,
            title: output.title,
            content: output.content,
            message: 'AI 已按输出要求整理'
          };
        }
      }
      return { success: false, title: '', content: '', message: 'AI 接口没有返回可用内容' };
    } catch (error) {
      console.error('AiVisualParsingService parseOcrText failed: ' + JSON.stringify(error));
      return { success: false, title: '', content: '', message: 'AI 整理失败，请检查接口配置或网络连接' };
    } finally {
      request.destroy();
    }
  }

  public static async fetchAvailableModels(config: AiVisualEngineConfig): Promise<AiVisualModelsResult> {
    const validationMessage: string = AiVisualParsingService.validateConfig(config, false);
    if (validationMessage.length > 0) {
      return { success: false, models: [], message: validationMessage };
    }
    const request: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(
        AiVisualParsingService.buildModelsUrl(config.baseUrl), {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + config.apiKey.trim()
          },
          connectTimeout: 30000,
          readTimeout: 30000
        });
      const responseText: string = String(response.result);
      if (AiVisualParsingService.isHtmlResponse(responseText)) {
        return { success: false, models: [], message: '模型列表接口返回了网页内容，请检查 Base URL' };
      }
      const parsed: AiModelResponse = JSON.parse(responseText) as AiModelResponse;
      if (parsed.error && parsed.error.message) {
        return { success: false, models: [], message: parsed.error.message };
      }
      const models: string[] = [];
      if (parsed.data) {
        for (let index: number = 0; index < parsed.data.length && index < 50; index++) {
          const id: string | undefined = parsed.data[index].id;
          if (id && id.trim().length > 0) {
            models.push(id.trim());
          }
        }
      }
      return models.length > 0 ?
        { success: true, models: models, message: '已获取 ' + models.length.toString() + ' 个模型' } :
        { success: false, models: [], message: '接口没有返回可用模型' };
    } catch (error) {
      console.error('AiVisualParsingService fetchAvailableModels failed: ' + JSON.stringify(error));
      return { success: false, models: [], message: '模型列表拉取失败，请检查接口配置或网络连接' };
    } finally {
      request.destroy();
    }
  }

  private static validateConfig(config: AiVisualEngineConfig, requireOutputContent: boolean): string {
    if (config.baseUrl.trim().length === 0) {
      return '请填写 Base URL';
    }
    if (config.apiKey.trim().length === 0) {
      return '请填写 API Key';
    }
    if (requireOutputContent && config.model.trim().length === 0) {
      return '请先拉取并选择模型';
    }
    if (requireOutputContent && config.outputContent.trim().length === 0) {
      return '请在自定义匹配规则中填写输出要求';
    }
    return '';
  }

  private static buildChatUrl(baseUrl: string): string {
    const normalized: string = AiVisualParsingService.normalizeBaseUrl(baseUrl);
    if (normalized.endsWith('/chat/completions')) {
      return normalized;
    }
    if (normalized.endsWith('/models')) {
      return normalized.substring(0, normalized.length - '/models'.length) + '/chat/completions';
    }
    return normalized + '/chat/completions';
  }

  private static buildModelsUrl(baseUrl: string): string {
    const normalized: string = AiVisualParsingService.normalizeBaseUrl(baseUrl);
    if (normalized.endsWith('/chat/completions')) {
      return normalized.substring(0, normalized.length - '/chat/completions'.length) + '/models';
    }
    return normalized.endsWith('/models') ? normalized : normalized + '/models';
  }

  private static normalizeBaseUrl(baseUrl: string): string {
    let normalized: string = baseUrl.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized === 'https://api.openai.com') {
      return 'https://api.openai.com/v1';
    }
    return normalized;
  }

  private static isHtmlResponse(value: string): boolean {
    const normalized: string = value.trim().toLowerCase();
    return normalized.startsWith('<!doctype html') || normalized.startsWith('<html');
  }
}
