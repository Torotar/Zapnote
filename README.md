# 识录笔记 · ZapNote

中文 | [English](#english)

识录笔记是一款使用 ArkTS 和 ArkUI 构建的 HarmonyOS 笔记应用，支持手机与 2 合 1 设备。当前项目版本为 **1.4.0**。

## 功能

- 创建、编辑、收藏和整理笔记，并查看写作统计。
- 从图片识别文字，按规则处理内容；也可配置兼容接口进行 AI 视觉整理。
- 管理照片、文件夹、外观与隐私设置。
- 导入导出本地备份，并配置 WebDAV 同步。

## 构建

使用 DevEco Studio 与 HarmonyOS SDK 6.1.0（API 23）打开项目。Windows 命令行可在项目根目录执行：

```powershell
hvigorw.bat --mode module -p module=entry assembleHap --no-daemon
```

## 构建包

当前版本的 **未签名 HAP** 发布在 GitHub Release：[下载 entry-default-unsigned.hap](https://github.com/Torotar/Zapnote/releases/download/v1.4.0/entry-default-unsigned.hap)。该包未签名，安装或分发前需要使用适用的签名配置重新构建或签名。

## 项目说明

- 应用显示名称：识录笔记
- 应用版本：1.4.0
- 支持设备：phone、2in1
- 主要源码：`entry/src/main/ets`

---

<a id="english"></a>

## English

ZapNote is a HarmonyOS note-taking app built with ArkTS and ArkUI for phones and 2-in-1 devices. The current project version is **1.4.0**.

### Features

- Create, edit, favorite, and organize notes, with writing statistics.
- Recognize text from images and process it with rules; optionally configure a compatible API for AI-powered visual parsing.
- Manage photos, folders, appearance, and privacy settings.
- Import and export local backups, and configure WebDAV sync.

### Build

Open the project with DevEco Studio and HarmonyOS SDK 6.1.0 (API 23). On Windows, run this command from the project root:

```powershell
hvigorw.bat --mode module -p module=entry assembleHap --no-daemon
```

### Build package

The current **unsigned HAP** is published as a GitHub Release asset: [Download entry-default-unsigned.hap](https://github.com/Torotar/Zapnote/releases/download/v1.4.0/entry-default-unsigned.hap). It is unsigned; use an appropriate signing configuration to rebuild or sign it before installation or distribution.

### Project details

- App display name: 识录笔记 (ZapNote)
- App version: 1.4.0
- Supported devices: phone, 2-in-1
- Main source: `entry/src/main/ets`
