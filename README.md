# THubX

**THub V3 的重构版**  
[![License: MIT](https://img.shields.io/badge/License-MIT-orange.svg)](https://opensource.org/licenses/MIT) [![WindUI](https://img.shields.io/badge/UI-WindUI-blue.svg)](https://github.com/Footagesus/WindUI) ![Platform](https://img.shields.io/badge/Platform-Roblox-red.svg)

---

## 简介

THubX 是我对 [THub V3](https://github.com/wjm13206/THub) 的重构。V3 基于 ChronixUI 构建，随着功能增长，UI 层和加载体系逐渐难以维护。这次我用 [WindUI](https://github.com/Footagesus/WindUI) 从头重写了整个界面，顺便优化了模块加载机制

人话: 把 UI 换了、加载机制重写了、修了一些bug

- **WindUI 驱动**，支持图标、主题、侧边栏、可调整窗口尺寸
- **单文件产物**，darklua 打包，`loadstring` 一行加载

---

## 快速开始

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wjm13206/THubX/refs/heads/main/main.lua"))()
```



## 本地构建

### 依赖

- [darklua](https://github.com/seaofvoices/darklua) 0.19.0+（经 [aftman](https://github.com/LPGhatguy/aftman) 安装）

### 步骤

```bash
# 安装 darklua
aftman install

# 构建（Linux/macOS）
npm run build

# 构建（Windows PowerShell）
npm run build:win
```

产物输出到 `dist/THubX.lua`。



## 移动端说明

> 本脚本仅在 PC 端（Windows）经过测试，不保证在手机端完美适配。部分功能（如 V4 飞行）在移动端可能出现异常。

---

## 免责声明

**本仓库仅为代码存档与学术研究目的而公开，不鼓励、不认可、也不参与任何形式的实际使用。**

1. **仅供学习研究**：本项目仅为学习 Luau 编程、UI 框架设计、网络通信等技术而创建。请在下载后 24 小时内删除。
2. **严禁实际使用**：严禁将本代码加载至任何生产环境或游戏客户端。若任何个人执意使用本代码进行任何违反 [Roblox 服务条款](https://en.help.roblox.com/hc/articles/115004647846) 或相关法律法规的行为，该行为与作者**完全无关**，由使用者自行决策并承担全部后果。
3. **法律隔离声明**：本项目代码仅仅是一段非自执行的文本数据，其本身不产生任何计算机行为。任何由第三方工具（脚本执行器、注入器等）导致的代码执行行为属于工具开发者与最终使用者的责任范畴，与本文本数据的创作者无任何因果关系。
4. **不构成鼓励或教唆**：本仓库中技术的展示不构成对任何违法行为的鼓励、教唆、暗示或认可。读者应仅在合法授权范围内进行技术学习。
5. **第三方工具声明**：本代码依赖的底层执行器/注入器非本作者开发，对其安全性与合法性不作任何保证。使用第三方注入工具本身可能违反当地法律及 Roblox 使用条款，使用者需自行评估法律风险。
6. **风险自担**：使用上述技术可能导致的任何后果，包括但不限于账号封禁、数据丢失、民事或刑事责任，均与代码作者**完全无关**，由使用者自行承担全部责任。
7. **开源协议**：本项目基于 **MIT 协议** 开源。可自由使用、修改和分发，但需保留版权声明，且不得将作者名义用于推广或包装衍生作品。
8. **不保证安全**：本代码不保证任何形式的"反检测"效果，不应依赖本代码规避任何反作弊系统。任何相关后果与作者无关。

**继续查看或使用本仓库即表示已阅读、理解并同意本免责声明的全部内容。若不同意上述任一条款，请立即离开本页面并删除所有已获取的副本。**

---

## 鸣谢

THub V3 由我开发，最初 fork 自 Furrycalin 的 ChronixHub。在此感谢所有直接或间接帮助过这个项目的人：

| 名称 | 贡献 |
| --- | --- |
| **Furrycalin / Chronix** | ChronixHub 原始项目 |
| [**WindUI**](https://github.com/Footagesus/WindUI) | 本仓库使用的 UI 框架 |
| **IY** | 部分功能代码借鉴 |

---

## 许可证

[MIT License](https://opensource.org/licenses/MIT)

---

**⭐ 如果这个项目对你有帮助，请给一个 Star！**
