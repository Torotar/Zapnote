<a id="chinese"></a>

# 识录笔记 / ZapNote

中文 | [English](#zapnote-english)

## 简介

识录笔记（ZapNote）是一款使用 ArkTS 和 ArkUI 构建的 HarmonyOS 笔记管理应用。它可以从图片中识别文字，在设备上创建、编辑和整理笔记，并提供本地备份与 WebDAV 同步功能。

## 功能

- 创建、编辑、搜索、收藏和整理笔记，并查看写作统计。
- 从图片识别文字，按自定义规则处理内容。
- 可选配置兼容接口进行 AI 视觉整理；默认 OCR 与规则处理不依赖 AI 服务。
- 管理笔记文件夹、照片、外观与隐私设置。
- 导入和导出本地备份，并配置 WebDAV 同步。

AI 视觉整理需要用户配置兼容的服务接口。WebDAV 同步需要服务器地址、远端路径、用户名和密码；可在设置中选择同步内容范围。

## 环境要求

- DevEco Studio，以及与项目配置兼容的 HarmonyOS SDK。
- 项目配置的模型版本为 6.1.1，目标 SDK 与兼容 SDK 为 6.1.0（API 23）。
- 项目使用 ArkTS / ArkUI，支持 phone 与 2in1 设备；依赖通过项目中的 OHPM 配置管理。

## 构建

1. 在 DevEco Studio 中打开本项目根目录。
2. 等待项目同步完成，并确认已安装项目所需的 HarmonyOS SDK。
3. 使用 **Build > Build Hap(s)/APP(s)** 构建应用。

本仓库当前不包含 `hvigorw.bat` 命令行包装脚本；命令行构建方式需以本机 DevEco Studio 安装和项目生成的工具链为准。源码测试位于 `entry/src/test` 和 `entry/src/ohosTest`，请使用 DevEco Studio 中与当前 SDK 匹配的测试运行配置执行。


## 项目结构

- `AppScope/`：应用级配置与资源。
- `entry/src/main/ets/`：ArkTS 页面、组件、数据模型和服务。
- `entry/src/test/`：本地单元测试。
- `entry/src/ohosTest/`：设备侧测试。

## 许可证

本仓库尚未指定开源许可证。未经另行许可，代码仍受其适用的版权保护。

---

<a id="zapnote-english"></a>

# ZapNote

[中文](#chinese) | English

## Overview

ZapNote (识录笔记) is a HarmonyOS note management app built with ArkTS and ArkUI. It can recognize text in images, create, edit, and organize notes on the device, and provide local backup and WebDAV sync.

## Features

- Create, edit, search, favorite, and organize notes, with writing statistics.
- Recognize text from images and process it with custom rules.
- Optionally configure a compatible API for AI visual parsing; the default OCR and rule-processing flow does not depend on an AI service.
- Manage note folders, photos, appearance, and privacy settings.
- Import and export local backups, and configure WebDAV sync.

AI visual parsing requires a user-configured compatible service API. WebDAV sync requires a server URL, remote path, username, and password; the sync data scope can be selected in settings.

## Requirements

- DevEco Studio and a HarmonyOS SDK compatible with the project configuration.
- The project model version is 6.1.1; its target and compatible SDK versions are 6.1.0 (API 23).
- The project uses ArkTS / ArkUI, supports phone and 2-in-1 devices, and manages dependencies through its OHPM configuration.

## Build

1. Open the project root in DevEco Studio.
2. Wait for project sync to finish and confirm that the required HarmonyOS SDK is installed.
3. Build the app with **Build > Build Hap(s)/APP(s)**.

This repository does not currently include an `hvigorw.bat` command-line wrapper. For command-line builds, use the toolchain generated or provided by your local DevEco Studio installation. Source tests are under `entry/src/test` and `entry/src/ohosTest`; run them with a test configuration compatible with the installed SDK.

The GitHub [v1.4.0 Release](https://github.com/Torotar/Zapnote/releases/tag/v1.4.0) includes the existing unsigned HAP: [Download entry-default-unsigned.hap](https://github.com/Torotar/Zapnote/releases/download/v1.4.0/entry-default-unsigned.hap). Sign it with an appropriate configuration before installation or distribution.

## Project layout

- `AppScope/`: app-level configuration and resources.
- `entry/src/main/ets/`: ArkTS pages, components, data models, and services.
- `entry/src/test/`: local unit tests.
- `entry/src/ohosTest/`: on-device tests.

## License

No open-source license has been specified for this repository. The code remains protected by applicable copyright unless permission is granted separately.
