#!/usr/bin/env bash
# setup.sh — Install session context kit into a project
# Usage: ./setup.sh [project_root]
#        If no project_root given, uses current directory.

set -euo pipefail

PROJECT_ROOT="${1:-.}"
PROJECT_ROOT=$(cd "$PROJECT_ROOT" && pwd)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "📦 Installing Session Context Kit → ${PROJECT_ROOT}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Create directories
mkdir -p "${PROJECT_ROOT}/.claude/commands"
mkdir -p "${PROJECT_ROOT}/CC-Session-Logs"

# 2. Copy slash commands
for cmd in compress.md resume.md preserve.md; do
    if [[ -f "${PROJECT_ROOT}/.claude/commands/${cmd}" ]]; then
        echo "  ⏭  .claude/commands/${cmd} already exists, skipping"
    else
        cp "${SCRIPT_DIR}/.claude/commands/${cmd}" "${PROJECT_ROOT}/.claude/commands/${cmd}"
        echo "  ✅ .claude/commands/${cmd}"
    fi
done

# 3. Copy CLAUDE.md template (only if not exists)
if [[ -f "${PROJECT_ROOT}/CLAUDE.md" ]]; then
    echo "  ⏭  CLAUDE.md already exists, skipping"
    echo "     Review CLAUDE.md.template and merge Session Management Rules manually"
    cp "${SCRIPT_DIR}/CLAUDE.md.template" "${PROJECT_ROOT}/CLAUDE.md.template"
else
    cp "${SCRIPT_DIR}/CLAUDE.md.template" "${PROJECT_ROOT}/CLAUDE.md"
    echo "  ✅ CLAUDE.md (edit to match your project)"
fi

# 4. Add CC-Session-Logs to .gitignore if git repo
if git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
    GITIGNORE="${PROJECT_ROOT}/.gitignore"
    if ! grep -qF "CC-Session-Logs/" "$GITIGNORE" 2>/dev/null; then
        echo "" >> "$GITIGNORE"
        echo "# Claude Code session logs (local only)" >> "$GITIGNORE"
        echo "CC-Session-Logs/" >> "$GITIGNORE"
        echo "  ✅ Added CC-Session-Logs/ to .gitignore"
    else
        echo "  ⏭  CC-Session-Logs/ already in .gitignore"
    fi
fi

# 5. Install bash wrapper
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 To enable auto-detect (optional):"
echo "   mkdir -p ~/bin"
echo "   cp ${SCRIPT_DIR}/claude-session-wrapper.sh ~/bin/"
echo "   echo 'source ~/bin/claude-session-wrapper.sh' >> ~/.bashrc"
echo ""
echo "📌 Workflow:"
echo "   1. Start session:  claude → /resume"
echo "   2. Work normally"
echo "   3. Mid-session:    /preserve (save key findings)"
echo "   4. End session:    /compress (or just say '收工')"
echo ""
echo "✅ Done!"
