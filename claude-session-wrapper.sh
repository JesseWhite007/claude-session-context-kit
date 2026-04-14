#!/usr/bin/env bash
# claude-session-wrapper.sh
# --------------------------
# Wraps `claude` command to detect if /compress was run before exit.
# If not, offers to re-launch and compress.
#
# Installation:
#   1. Copy this file to ~/bin/ or anywhere in PATH
#   2. chmod +x claude-session-wrapper.sh
#   3. Add to ~/.bashrc or ~/.zshrc:
#        source ~/bin/claude-session-wrapper.sh
#
# This overrides the `claude` command with a function.
# Use `command claude` to bypass the wrapper.

claude() {
    local project_root
    project_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    local log_dir="${project_root}/CC-Session-Logs"

    # Record the newest log file timestamp before session
    local latest_before=""
    local count_before=0
    if [[ -d "$log_dir" ]]; then
        latest_before=$(ls -t "$log_dir"/*.md 2>/dev/null | head -1)
        count_before=$(ls "$log_dir"/*.md 2>/dev/null | wc -l)
    fi

    # Run the real claude command with all arguments
    command claude "$@"
    local exit_code=$?

    # Skip check for non-interactive invocations (e.g. claude -p "...")
    for arg in "$@"; do
        if [[ "$arg" == "-p" || "$arg" == "--print" ]]; then
            return $exit_code
        fi
    done

    # Check if a new log was created during this session
    local latest_after=""
    local count_after=0
    if [[ -d "$log_dir" ]]; then
        latest_after=$(ls -t "$log_dir"/*.md 2>/dev/null | head -1)
        count_after=$(ls "$log_dir"/*.md 2>/dev/null | wc -l)
    fi

    if [[ "$count_before" -eq "$count_after" ]] || [[ "$latest_before" == "$latest_after" ]]; then
        echo ""
        echo "⚠️  未检测到 /compress — 本次 session 上下文可能丢失"
        echo -n "   重新启动 claude 执行压缩？ [y/N] "
        read -r answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            echo "🔄 Resuming session to compress..."
            command claude --resume -p \
                "立即执行 /compress，保存本次 session 的所有工作上下文。自动生成 topic 名称。完成后退出。"
        else
            echo "💡 提示: 下次退出前运行 /compress 保存上下文"
        fi
    else
        echo "✅ Session log saved: $(basename "$latest_after")"
    fi

    return $exit_code
}
