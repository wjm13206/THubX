# AGENTS.md

THubX 是 Roblox Luau 脚本 hub（WindUI 驱动）。darklua 把 `src/` 多文件打包成单文件 `dist/THubX.lua`，由 `main.lua` 经 `loadstring` 从 GitHub raw 拉取执行。

## 构建命令

- 先装 darklua：`rokit install`（`rokit.toml` 锁定 darklua 0.19.0）。无 Rokit 时也可 `cargo install darklua`、winget 或下载 exe 加入 PATH（见 `build/build.ps1` 提示）。
- **Windows（PowerShell）必须用** `npm run build:win` —— 不要用 `npm run build`（后者调 bash 脚本，Windows 上会失败）。
- Linux/macOS：`npm run build`。
- 产物：`dist/THubX.lua`（构建过程临时写 `dist/temp.lua` 后合并，`temp.lua` 在 .gitignore 中）。

## 测试 / Lint / 格式化

仓库**没有**测试、lint、格式化或类型检查配置（无 selene / stylua / luarc / 测试框架）。验证手段只有：本地构建是否通过 + 在 Roblox 执行器中实际运行。不要臆造不存在的命令。

## CI

`.github/workflows/build.yml`：push 到 `main` 且改动 `src/**`、`build/**`、`package.json`、`rokit.toml` 时触发，自动构建并**把 `dist/THubX.lua` commit 回 main**。因此：

- `dist/THubX.lua` 是构建产物，**不要手动编辑**。
- 本地改完源码构建后无需提交 `dist/`——CI 会重建并覆盖。

## 架构

- `main.lua`：发布入口，`loadstring` 拉取远程 `dist/THubX.lua`。非本地开发入口。
- `src/Init.lua`：真正入口。流程：require Core → `Utils.EnsureSingleRun` 防重复 → 创建 WindUI Window → 遍历 `Registry` 逐个 `mod.Init(Tabs, ctx)`。
- `src/Core/`：
  - `Services.lua`：Roblox 服务封装，统一用 `cloneref`（反检测）。模块取服务一律 `Services.XXX`，**不要**直接 `game:GetService`。
  - `Config.lua`：标题/作者/WindUI 远程地址/主题。
  - `Utils.lua`：`EnsureSingleRun`（靠 `_G.THubXLoaded` / `_G.THubXLoading` 防重复加载）、`HttpGetWithRetry`、日志/通知。
  - `Unload.lua`：`OnUnload(fn)` 注册清理回调，`Run()` 倒序执行。
- `src/UI/Window.lua`：创建 WindUI 窗口。WindUI 本身从远程 `loadstring` 加载并缓存到 `_G.THubXWindUI`。定义全部 Tab。
- `src/Modules/Registry.lua`：**模块注册表**。新模块必须在此 `entry("Name", function() return require("./X/Y") end)` 注册，否则不会被加载（且不会报错，只是静默跳过）。
- `src/Modules/{Movement,Visual,Combat,Utility,Chat,Games,Basic}/`：功能模块，按 Tab 分类组织。

## 模块约定

每个模块 `return` 一个 table，必须实现：

- `Title`（string）：显示名。
- `Init(Tabs, ctx)`：接收 Tab 表与上下文 `ctx`（含 `WindUI`、`Window`、`Config`、`Services`、`Utils`、`FeatureSettings`）。布局约定（扁平化）：功能 Tab 上只放 `Toggle`（开关）和 `Button` / `Input`（点按操作），**直接挂 Tab**（如 `Tabs.Movement:Toggle(...)`），**不要建 `Section`**；`Slider` / `Keybind` / `Dropdown` / `Colorpicker` 等参数一律搬进“功能设置”Tab：`local settings = ctx.FeatureSettings("<模块Title>")` 再 `settings:Slider(...)`（同名分组带缓存复用）。“设置”Tab 只保留界面/系统/存档，不要往里面塞功能参数。
- 用 `Unload.OnUnload(fn)` 注册自身清理（断开连接、销毁实例、还原状态），否则卸载时残留。

Tab 名见 `src/UI/Window.lua` 的 `Tabs` 表：`Movement`（移动） / `Flight`（飞行） / `ESP`（透视） / `Visual`（视觉特效） / `Combat` / `Hanker` / `Teleport`（传送与玩家） / `Interact`（互动） / `Protect`（防护） / `Camera`（视角） / `Data`（数据） / `Chat` / `Games` / `Basic` / `ScriptHub` / `Audio` / `Filter` / `FeatureSettings`（功能参数） / `Settings`（界面/系统/存档）。注意文件所在文件夹与 Tab 无绑定关系（如 `Utility/` 下的文件分散在多个 Tab），以各模块源码中的 `Tabs.XXX` 为准。

## require 风格

darklua `bundle.require_mode = "path"`，源码用**相对路径** require（如 `require("../../Core/Services")`、`require("./Core/Config")`），不是 Roblox 的 `game:GetService` / `ReplicatedStorage` 模式。构建时 darklua 会把所有 require 内联成单文件。

## darklua 构建规则

`build/darklua.json` 启用 `remove_types`、`remove_comments`、`rename_variables` 等：

- 源码中的类型注解和注释在产物中会被移除，可自由添加注释/类型，不影响产物体积。
- 变量会被重命名混淆，不要依赖产物中的变量名做调试。
