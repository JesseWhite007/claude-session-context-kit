# Session Context Kit for Claude Code

解决 Claude Code 跨 session 上下文丢失问题的三层方案。

## 问题

1. **跨 session 无记忆** — 关闭 session 后所有上下文消失
2. **Auto-compact 静默压缩** — 长对话中 context window 满后自动压缩，丢失关键细节
3. **冷启动成本高** — 每次新 session 都要重新解释项目背景

## 方案架构

```
┌─────────────────────────────────────────────┐
│  Layer 3: .skill 文件 (领域知识)             │
│  → XBSA协议、DB特性、平台架构等长期知识       │
├─────────────────────────────────────────────┤
│  Layer 2: CLAUDE.md (项目状态)               │
│  → 当前分支、活跃任务、架构决策、已知问题      │
├─────────────────────────────────────────────┤
│  Layer 1: CC-Session-Logs/ (会话记录)        │
│  → 每次 session 的工作摘要、文件变更、下一步   │
└─────────────────────────────────────────────┘
```

## 安装

```bash
cd /path/to/your/project
bash /path/to/session-context-kit/setup.sh .
```

安装后的项目结构：

```
your-project/
├── CLAUDE.md                    # 项目持久状态（自动+手动维护）
├── .claude/
│   └── commands/
│       ├── compress.md          # /compress 命令
│       ├── resume.md            # /resume 命令
│       └── preserve.md          # /preserve 命令
├── CC-Session-Logs/             # 会话日志（.gitignore）
│   ├── 20260414-153000_yashandb-pitr-debug.md
│   └── 20260414-180000_redis-aof-backup.md
└── .gitignore                   # 自动添加 CC-Session-Logs/
```

## 工作流

如果你想恢复上一次已经结束的 session（没 compress 的）：
bashclaude --resume

### 开始工作

```
$ claude

> /resume

📋 Session Resumed
━━━━━━━━━━━━━━━━━
Project: drbksoft/i2soft
Branch: feature/yashandb-pitr
Last session: 2026-04-14 — yashandb-pitr-debug

Unfinished tasks:
- [ ] 验证 RESTORE DATABASE UNTIL TIME 是否透传 PARAMS
- [ ] 补充 mapfile 自动生成逻辑

Ready to continue. What should we work on?
```

### 工作中（重要发现时）

```
> /preserve
✅ Preserved 2 items to CLAUDE.md
  - Key Decision: YashanDB archive restore 必须按 sequence 顺序
  - Known Issue: v23.4.x 不支持已删除 tablespace 的恢复
```

### 结束工作

```
> /compress
✅ Session compressed → CC-Session-Logs/20260414-180000_yashandb-archive-restore.md
```

或者直接说 "收工" / "今天到这"，Claude 会自动执行 /compress。

### 忘记 compress 时（bash wrapper 兜底）

```
$ claude    # 工作完直接 Ctrl+C 退出
⚠️  未检测到 /compress — 本次 session 上下文可能丢失
   重新启动 claude 执行压缩？ [y/N] y
🔄 Resuming session to compress...
✅ Session compressed → CC-Session-Logs/20260414-183000_redis-cluster-restore.md
```

## 安装 bash wrapper（可选）

```bash
mkdir -p ~/bin
cp claude-session-wrapper.sh ~/bin/
chmod +x ~/bin/claude-session-wrapper.sh
echo 'source ~/bin/claude-session-wrapper.sh' >> ~/.bashrc
source ~/.bashrc
```

## 与 .skill 文件配合

如果你已有自定义 `.skill` 文件（如 `db-backup-integration`），它们提供**领域级**知识，
与本 kit 的**会话级**上下文互补：

| 层级 | 内容 | 更新频率 | 示例 |
|------|------|----------|------|
| `.skill` | 领域知识、协议规范 | 很少 | XBSA流式恢复行为、PITR工作流 |
| `CLAUDE.md` | 项目状态、决策 | 每次 session | 当前分支、阻塞问题 |
| `CC-Session-Logs/` | 单次工作记录 | 每次 session | 改了哪些文件、调试发现 |

## 日志清理

Session logs 会随时间积累。建议定期清理超过 30 天的日志：

```bash
find CC-Session-Logs/ -name "*.md" -mtime +30 -delete
```

或加入 crontab：

```bash
0 3 * * 0 find /path/to/project/CC-Session-Logs/ -name "*.md" -mtime +30 -delete
```

