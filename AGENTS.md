# AGENTS.md

THubX 是 Roblox Luau 脚本 hub（WindUI 驱动）。`src/` 多文件经 darklua 打包成单文件 `dist/THubX.lua`，`main.lua` 用 `loadstring` 从 GitHub raw 拉取执行。

## 构建

- 先装 darklua：`rokit install`（`rokit.toml` 锁定 0.19.0）。无 Rokit 时按 `build/build.ps1` 提示用 cargo / winget / 下载 exe。
- Windows（PowerShell）必须用 `npm run build:win`，不要用 `npm run build`（调 bash，会失败）。Linux/macOS 用 `npm run build`。
- 入口固定为 `src/Init.lua`（见两份构建脚本写死的 `$Input`），产物为 `dist/THubX.lua`（中途 `dist/temp.lua` 已被 `.gitignore`）。

## CI 与产物

- `.github/workflows/build.yml`：push 到 `main` 且改动 `src/**`、`build/**`、`package.json`、`rokit.toml` 时触发，跑 `npm run build` 并把 `dist/THubX.lua` commit 回 main。
- `dist/THubX.lua` 是构建产物，**不要手动编辑**；本地构建后无需提交 `dist/`，CI 会覆盖。

## 验证

- 无测试 / lint / 格式化 / 类型检查配置（`package.json` 只有两个 build 脚本）。验证手段只有：本地构建通过 + 进 Roblox 执行器实测。不要臆造命令。

## 架构

- `main.lua`：发布入口，仅拉取远程 `dist/THubX.lua`。本地开发看 `src/Init.lua`。
- `src/Init.lua`：真正入口。`require Core` → `Utils.EnsureSingleRun("THubXLoaded")`（查 `_G.THubXLoaded` / `_G.THubXLoading`）→ `WindowLoader.Create()` → 遍历 `Registry` 逐个 `pcall(mod.Init(Tabs, ctx))`。加载失败只 `warn` 并计入 `failed`，最后 `WindUI:Notify` 汇总；无有效 `Init` 的模块静默跳过。
- `src/UI/Window.lua`：从 `Config.WindUIUrl`（wjm13206 的 WindUI fork）`loadstring` 加载并缓存到 `_G.THubXWindUI`；定义全部 19 个 Tab（以此文件 `Tabs` 表为准）：`Movement` / `Flight` / `ESP` / `Visual` / `Combat` / `Hanker` / `Teleport` / `Interact` / `Protect` / `Camera` / `Data` / `Chat` / `Games` / `Basic` / `ScriptHub` / `Audio` / `Filter` / `FeatureSettings`（功能参数） / `Settings`（界面/系统/存档）。
- `src/Core/`：`Services`（`cloneref` 封装，见下）、`Config`（标题/作者/`Folder`/`WindUIUrl`/主题）、`Utils`（`EnsureSingleRun`、`HttpGetWithRetry`、`NotifyFallback`）、`Unload`（`OnUnload` 注册、`Run` 倒序执行并重置 `_G` 标志；`Window.OnClose`/`OnDestroy` 已自动接 `Run`）、`ConfigStore`（界面存档，见下）、`Confirm`（危险操作二次确认）。
- `src/Modules/Registry.lua`：模块注册表。新模块必须 `entry("Name", function() return require("./X/Y") end)` 注册，否则不加载且不报错。文件夹（`Movement`/`Visual`/`Combat`/`Utility`/`Chat`/`Games`/`Basic`）与 Tab 无绑定，以各模块用的 `Tabs.XXX` 为准。

## 模块约定

- 每个模块 `return` 一个 table，须有 `Title`（string）+ `Init(Tabs, ctx)`。`ctx = { WindUI, Window, Config, Services, Utils, FeatureSettings }`。
- 取服务一律 `Services.XXX`，**不要**直接 `game:GetService`。`Services` 仅预取了 `Players` / `RunService` / `UserInputService` / `TweenService` / `HttpService` / `CoreGui` / `StarterGui` / `LogService` / `MarketplaceService`，其他服务用 `Services.Get("Name")`（内部自动 `cloneref`）。
- 布局（扁平化）：功能 Tab 上**直接挂** `Toggle` / `Button` / `Input`（如 `Tabs.Flight:Toggle(...)`），**不要建 `Section`**；`Slider` / `Keybind` / `Dropdown` / `Colorpicker` 等参数一律 `local s = ctx.FeatureSettings("<模块Title>")` 后挂 `s`（同名复用同一 Section，落在“功能设置”Tab）。`Settings` Tab 只放界面/系统/存档（`Window.lua` 已建好三 Section + 关于类例外），不要塞功能参数。
- 存档（`ConfigStore`）：`WrapTabs` 会给无 `Flag` 元素自动注入唯一 Flag，模块**无需手写 `Flag`**（手写则须全局唯一）；存档按游戏隔离（`WindUI/THubX/config/Game_<PlaceId>.json`），卸载时静默自动 `Save()`，全部模块 `Init` 完后 `Load()`。只提供“删除本游戏设置”按钮，不要自己调 `Save`。
- 危险操作（卸载/删除存档）用 `Confirm.Show(Window, { Title, Content, ConfirmText, OnConfirm })` 二次确认，参考 `Window.lua`。
- 必须 `Unload.OnUnload(fn)` 注册清理（断连接、销毁实例、还原状态），否则卸载残留。

## require 与构建规则

- darklua `bundle.require_mode = "path"`，用相对路径：`Init` 用 `./Core/X`，`UI` 用 `../Core/X`，模块用 `../../Core/X`，`Registry` 用 `./X/Y`。构建时内联成单文件。
- `build/darklua.json` 启用 `remove_types`、`remove_comments`、`rename_variables（include_functions，globals 仅保留 $default/$roblox）`：源码可自由写注释/类型；不要依赖产物变量名调试。
