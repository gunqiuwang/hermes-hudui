# CLAUDE.md

本文件为Claude Code提供项目指南。

## 项目概述

代理监控仪表盘 — 一个基于浏览器的AI代理监控仪表盘。它读取 `~/.hermes/` 目录中的代理数据，并显示身份、记忆、技能、会话、定时任务、项目、成本、活动模式、修正和实时聊天等13个标签页。

## 命令

### 开发环境设置（一次性）
```bash
./install.sh        # 构建前端，安装Python包
```

### 全栈开发
```bash
agent-dashboard --dev          # 终端1：后端运行在 :3001（自动重载）
cd frontend && npm run dev     # 终端2：前端运行在 :5173（代理 /api → :3001）
```

### 前端
```bash
cd frontend
npm run dev      # 开发服务器运行在 :5173
npm run build    # 生产构建（先运行 tsc）
npm run lint     # ESLint
npm run preview  # 预览生产构建
```

### 后端CLI
```bash
agent-dashboard                         # 运行在 :3001
agent-dashboard --port 8080             # 自定义端口
agent-dashboard --agent-dir /path       # 覆盖 ~/.hermes/ 位置
```

### 发布工作流
```bash
# 1. 更新版本号：pyproject.toml, App.tsx, BootScreen.tsx, CHANGELOG.md
# 2. 构建并部署静态资源：
cd frontend && npm run build && cd ..
rm -rf backend/static/assets/* && cp -r frontend/dist/* backend/static/
# 3. 提交、打标签、推送：
git add -f backend/static/assets/ && git commit && git tag v0.X.Y && git push --tags
# 4. GitHub发布：
gh release create v0.X.Y --title "v0.X.Y" --notes "..."
```

## 架构

```
React前端 (Vite + Tailwind)
    ↓ /api/* (开发时代理)
FastAPI后端 (Python)
    ↓ collectors/*.py        ↓ chat/engine.py
~/.hermes/ (代理数据)     hermes CLI (子进程)
```

### 后端 (`backend/`)

- **`main.py`** — FastAPI应用 + CLI入口。设置 `HERMES_HOME`，启动Uvicorn。
- **`collectors/`** — 每个数据领域一个模块（记忆、技能、会话、定时任务、项目、模式）。每个模块读取 `~/.hermes/` 并返回 `models.py` 中的数据类。
- **`models.py`** — 所有数据类（`HUDState`, `MemoryState`, `SkillsState` 等）。`@property` 字段包含在序列化中。
- **`serialize.py`** — `to_dict()` 递归将数据类转换为JSON安全的字典。
- **`routes/`** — FastAPI路由处理器，调用收集器并返回序列化数据。
- **`api/memory.py`** — 记忆CRUD端点。使用 `fcntl.flock` + 原子写入（`tempfile.mkstemp` → `os.replace`）匹配hermes-agent的 `MemoryStore` 锁定模式。
- **`api/sessions.py`** — 会话搜索（标题 + FTS）。过滤 `source != 'tool'` 以排除HUD生成的会话。
- **`api/chat.py`** — 聊天会话CRUD，SSE流端点，取消端点。
- **`chat/engine.py`** — 单例 `ChatEngine` 为每条消息生成 `hermes chat -q <msg> -Q --source tool`。从stdout捕获 `hermes_session_id`，完成后查询 `state.db` 获取工具调用和推理。
- **`chat/streamer.py`** — SSE事件发射器（`emit_token`, `emit_tool_start`, `emit_tool_end`, `emit_reasoning`, `emit_done`）。
- **`cache.py`** — 基于Mtime的缓存失效（会话30秒，技能60秒，模式60秒，配置45秒）。端点：`GET /api/cache/stats`, `POST /api/cache/clear`。
- **`websocket.py`** — 通过 `watchfiles` 监控 `~/.hermes/`，广播 `data_changed` 事件。前端通过SWR变异自动刷新。

### 前端 (`frontend/src/`)

- **`App.tsx`** — 根组件：标签管理器、主题提供者、命令面板。聊天标签使用固定高度容器；其他标签正常滚动。
- **`hooks/useApi.ts`** — SWR包装器，支持自动刷新、5秒去重、3次重试。
- **`hooks/useChat.ts`** — 聊天状态：SSE流、会话CRUD、每会话消息缓存（内存 `Map` + localStorage持久化）。在会话切换和页面刷新时恢复消息。
- **`components/Panel.tsx`** — 共享面板包装器（标题、边框、发光）。导出 `CapacityBar`, `Sparkline`。`noPadding` 属性用于ChatPanel。
- **`components/chat/`** — `SessionSidebar`, `MessageThread`, `MessageBubble`, `Composer`, `ToolCallCard`, `ReasoningBlock`。
- **`components/MemoryPanel.tsx`** — 内联编辑，悬停显示控件，两击删除，可展开添加表单。
- **`lib/utils.ts`** — `timeAgo()`, `formatDur()`, `formatTokens()`, `formatSize()`, `truncate()`。

## 关键约定

**添加标签：** 在 `backend/collectors/` 中创建收集器，在 `models.py` 中创建数据类，在 `backend/routes/` 中创建路由，在面板组件中使用 `useApi`，在 `TopBar.tsx` 的 TABS + `App.tsx` 的 TabContent/GRID_CLASS 中注册。

**聊天引擎：** 每条消息无状态子进程。后端无消息持久化 — 历史保存在localStorage中。服务器重启时，ChatPanel重新创建后端会话并将localStorage键迁移到新ID。

**记忆编辑：** 同步 `def` 端点（非 `async`），因此FastAPI自动线程化阻塞I/O。通过 `fcntl.flock` 在 `.lock` 文件上进行文件锁定。通过 `tempfile.mkstemp` + `os.replace` 进行原子写入。条目由 `\n§\n` 分隔。

**样式：** Tailwind用于布局，CSS变量（`var(--hud-*)`）用于主题。Funnel Sans字体。四种主题：`ai`, `blade-runner`, `fsociety`, `anime`。

**TypeScript：** 对API响应类型使用 `any` — 模式由后端拥有。

**版本字符串：** 必须在 `pyproject.toml`, `App.tsx` 状态栏, `BootScreen.tsx`, 和 `CHANGELOG.md` 之间保持同步。

**代币成本：** `backend/api/token_costs.py` 中硬编码的 `MODEL_PRICING`。对于未知模型回退到Claude Opus定价。
