# Claude Code Statusline 市场扫描

> Source: claude-pace 项目研究
> Collected: 2026-03-19（市场数据截至 2026-03-19，GitHub stars 均通过 gh api 实测核实）

## 竞品全景

| 项目 | Stars | 语言 | 形态 | 最后更新 | 特色 |
|------|------:|------|------|----------|------|
| [ccusage](https://github.com/ryoppippi/ccusage) | 11,693 | TypeScript | CLI + statusline | 03-18 | 用量分析 + burn rate |
| [claude-hud](https://github.com/jarrodwatts/claude-hud) | 7,038 | JavaScript | statusline | 03-15 | 功能最全，先行者 |
| [Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor) | 7,009 | Python | 独立 dashboard | 2025-09 | ML 预测，已停更 |
| [ccstatusline](https://github.com/sirmalloc/ccstatusline) | 5,421 | TypeScript | statusline | 03-16 | 高度可定制 + 主题 |
| [CCometixLine](https://github.com/Haleclipse/CCometixLine) | 2,227 | Rust | statusline | 03-14 | 高性能二进制 |
| [claude-powerline](https://github.com/Owloops/claude-powerline) | 931 | TypeScript | statusline | 03-18 | vim powerline 风格 |
| [kamranahmedse/claude-statusline](https://github.com/kamranahmedse/claude-statusline) | 726 | Shell | statusline | 03-10 | 极简 |
| [claude-code-statusline](https://github.com/rz1989s/claude-code-statusline) | 397 | Shell | statusline | 03-14 | 4 行增强 + 主题 |
| [claude-code-usage-bar](https://github.com/leeguooooo/claude-code-usage-bar) | 159 | Python | statusline | 2025-11 | burn rate + 耗尽预测 |
| [claudia-statusline](https://github.com/hagan/claudia-statusline) | 21 | Rust | statusline | 2026-01 | SQLite 持久化 + 云同步 |
| [felipeelias/claude-statusline](https://github.com/felipeelias/claude-statusline) | 2 | Go | statusline | 03-17 | 单二进制，极简 |
| claude-pace | 3 | Bash+jq | statusline | 03-19 | pace tracking，零运行时依赖 |

另有 6+ 个 npm 包：ccstatusline、@owloops/claude-powerline、@illumin8ca/claude-statusline、@chongdashu/cc-statusline、@sponzig/cc-statusline、@this-dot/claude-code-context-status-line。

## 竞品详细分析

### ccusage (11,693 stars) - 综合最强

- 定位：CLI 用量分析工具，statusline 是子功能
- statusline 显示：model、session cost、today cost、5h block 剩余时间、burn rate、context 使用率
- 技术：TypeScript，默认 offline 模式（缓存定价数据），无网络延迟
- 优势：用户量最大，功能覆盖面广，活跃维护
- 与 claude-pace 差异：ccusage 的 burn rate 是趋势展示，不做预测性告警；需要 Node.js 运行时

### claude-hud (7,038 stars) - 先行者

- 功能最全：context 进度条、rate limit 用量、工具活动、子代理状态、Todo 进度、Git 集成
- Usage API 缓存 TTL 60s（成功）/ 15s（失败）
- 已知问题：冷启动因冷缓存/API 超时不显示 usage (#214)、0 字节锁文件永久阻塞 (#220)、Windows 兼容性 (#196)
- 不在 awesome-claude-code 列表中（该列表 29K stars，收录了 5 个 statusline 工具但不含 claude-hud）

### Claude-Code-Usage-Monitor (7,009 stars) - 已停更

- 独立终端 dashboard（非 statusline 嵌入），Python 实现
- 最强预测功能：P90 机器学习 + burn rate，用过去 192 小时历史数据
- HN 获 245 点 / 135 条评论，但代码质量遭批评（"vibe-coding style"，主文件 1000+ 行）
- 最后更新 2025-09-14，已停止活跃维护

### ccstatusline (5,421 stars) - 可定制

- 定位是"格式化器"，不做 API 调用
- powerline 风格、可交互 TUI 配置、多主题
- npm 分发，性能由 Node.js 启动开销决定

### CCometixLine (2,227 stars) - Rust 性能派

- Git 集成、model 显示、usage 追踪、交互式 TUI 配置
- 唯一在 awesome-claude-code 中的 Rust 方案
- 文档未提供具体 ms 性能数字

## 社区分发渠道

| 渠道 | Stars | claude-pace 收录状态 |
|------|------:|---------------------|
| [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | 29,014 | 未收录 |
| Anthropic 官方插件目录 | 12,653 | statusline 类零收录 |

awesome-claude-code 当前收录 5 个 statusline：CCometixLine、ccstatusline、claude-code-statusline、claude-powerline、claudia-statusline。

## 用户痛点与未满足需求

### 核心痛点：配额不透明

1. **突然触限无预警** - $200/月 Max 用户在 10-15 分钟内触限，只看到"usage limit reached"（The Register, 2026-01-05）
2. **配额重置时间不可见** - 2026-03-18 同一天 3 个独立 issue 请求此功能（#35747, #35672, #35827）
3. **5h + 7d 双重窗口认知负担** - 用户分不清在哪个限制下触限

### 官方态度

- **明确拒绝原生 token 指示器**：issue #10593 标记 "Not Planned"（2026-01-19），推荐 ccusage
- **statusline stdin JSON 不暴露配额字段**：session_used_percentage、weekly_used_percentage、resets_at 均缺失
- 第三方工具需绕道 Usage API 或解析本地 JSONL 文件

### 其他需求

- 触限后自动恢复任务执行（#18980, #26775, #35744）
- 推送式配额预警（接近 80% 时主动告警）而非查询式（#35947）
- 跨会话累计用量追踪（#13891, #13892）

## 技术趋势

- **从 Node.js 向轻量运行时迁移**：Rust（CCometixLine, claudia-statusline）、Go（felipeelias）、Shell（kamranahmedse, rz1989s, claude-pace）
- **零依赖安装成为卖点**：Go 单二进制、Bash 脚本 curl 一行装完
- **无公开性能基准**：没有任何工具发布过 hyperfine 或等价的逐 ms 基准数字

## 用户反馈分析（2026-03-24 补充）

### 跨会话每日费用汇总 - 反馈最好的功能

ccusage 的核心价值是"一行命令看金额"和"验证月费值不值"。多篇独立评测一致将"成本可视化"列为选择 ccusage 的首要原因。

### 上下文进度条 - 用户安装 statusline 的首要动机

多个独立来源一致：context bar 是"装机理由"。SAP 社区作者写"context bar alone is worth the install"。

### Rate Limit 5h/7d 可视化 - 第二大需求

v2.1.80 后 stdin 提供官方数据，所有工具机会平等，差异化空间从"有没有"转向"准不准"。

### 子代理状态监控 - 博客热度高，但实际用户投票证据弱

claude-hud 的子代理监控被多篇博客列为第二大价值点。但实际数据不支持"强烈需求"判断：
- 6 条 subagent 相关 issue 全部 0 reactions
- 均为连续编号，疑似维护者或 AI 批量创建，非用户驱动

### Burn Rate / 消耗速率 - 竞品已踩坑

ccusage 的 Live Blocks 功能（实时 token 消耗监控）因准确性问题被正式移除（issue #782）。issue #288 (16 reactions) 和 #483 (11 reactions) 记录了"显示未达限额但实际已触限"的持续性用户抱怨。

### 零运行时依赖 - 真实差异化卖点

ccusage statusline 有严重的进程管理 bug（issue #459, 10 reactions, 17 comments）：`bun x ccusage statusline` 在 hooks 中导致无限进程生成、CPU 100%。

多位社区作者明确将"减少依赖"列为选择工具的考量因素。Go/Rust 单二进制和纯 Bash 方案的出现动机均包含此点。

### 功能蔓延是社区明确警告的反模式

- Ovidiu (Substack): "When everything is highlighted, nothing is"
- ccusage 的 Live Blocks 从功能到移除的全过程就是一个活教材。

## 矛盾与不确定性

1. **子代理监控需求强度矛盾**：博客作者高度评价 vs GitHub issue 0 reactions。可能解释：博客作者是功能全面性的评测视角，而实际用户投票反映的是"最痛的需求"
2. **ccusage statusline 用户粘性 vs bug 严重性矛盾**：被多个第三方依赖为数据源（说明准确性获认可），但同时有最多的准确性投诉。可能解释：CLI 报表准确而 statusline/live 组件不准确
3. **claude-hud stars 从 7,038 (3/19) 跃升至 11,842 (3/24)**：5 天涨 4,804 stars，与 Trending 效应一致

## 竞品功能反馈排名

| 排名 | 功能 | 证据强度 | 是否值得做 |
|------|------|---------|-----------|
| 1 | 跨会话每日费用汇总 | 高（多源独立正面反馈） | 值得评估 - 但订阅制用户可能不关心费用 |
| 2 | 子代理/工具活动监控 | 低（博客热 issue 冷） | 暂不建议 - 等 CC stdin 暴露相关字段 |
| 3 | 多设备数据同步 | 低 | 不建议 |
| 4 | 按项目分组 usage | 低 | 不建议 |

## 结论

**更有价值的方向不是"加竞品有的功能"，而是"把已有功能做到最准最可靠"。** ccusage 的 live blocks 因不准被移除、claude-hud 的 429 永久警告 bug，都说明 statusline 赛道的竞争焦点已从"功能数量"转向"数据准确性和运行可靠性"。
