import { ValueOption } from '../model/ZapNoteTypes';

export const MOOD_OPTIONS: ValueOption[] = [
  { label: '开心 😊', value: '😊', description: '心情明亮的一天' },
  { label: '平静 ☺️', value: '☺️', description: '节奏温和，适合沉淀' },
  { label: '疲惫 😮‍💨', value: '😮‍💨', description: '需要休息和恢复' },
  { label: '难过 😔', value: '😔', description: '把低落也认真放下' },
  { label: '思考 🤔', value: '🤔', description: '记录一个还没想完的问题' }
];

export const WEATHER_OPTIONS: ValueOption[] = [
  { label: '晴天 ☀️', value: '☀️', description: '阳光很好' },
  { label: '阴天 ☁️', value: '☁️', description: '云层很厚' },
  { label: '雨天 🌧️', value: '🌧️', description: '空气潮湿' },
  { label: '大风 🍃', value: '🍃', description: '风把城市吹醒' },
  { label: '夜晚 🌙', value: '🌙', description: '适合安静写字' }
];

export const THEME_OPTIONS: ValueOption[] = [
  { label: '跟随系统', value: 'auto', description: '使用设备当前外观' },
  { label: '浅色模式', value: 'light', description: '明亮干净的纸面' },
  { label: '深色模式', value: 'dark', description: '低亮度夜间记录' }
];

export const LIGHTING_OPTIONS: ValueOption[] = [
  { label: '关闭', value: 'off', description: '不使用额外光效' },
  { label: '柔和', value: 'soft', description: '轻量标题栏材质' },
  { label: '沉浸', value: 'focus', description: '增强标题栏和页签材质' },
  { label: '精致', value: 'exquisite', description: '使用更细腻的系统材质' }
];

export const ENGINE_OPTIONS: ValueOption[] = [
  { label: '豆包识别', value: 'doubao', description: '适合生活照片提取' },
  { label: '通义识别', value: 'qianwen', description: '适合长文本整理' },
  { label: 'DeepSeek', value: 'deepseek', description: '适合摘要与润色' }
];

export const SYNC_OPTIONS: ValueOption[] = [
  { label: '关闭', value: 'off', description: '不自动同步' },
  { label: '每 15 分钟', value: '15m', description: '适合频繁记录' },
  { label: '每 30 分钟', value: '30m', description: '均衡同步频率' },
  { label: '每天一次', value: '1d', description: '轻量备份' }
];

export const PHOTO_STYLE_OPTIONS: ValueOption[] = [
  { label: '原图风格', value: 'original', description: '保持照片原始质感' },
  { label: '柔和相纸', value: 'soft', description: '降低对比度并增加留白' },
  { label: '胶片边框', value: 'film', description: '更有纪念感的预览' }
];
