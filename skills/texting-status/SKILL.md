---
name: texting-status
description: Check that texting over iMessage is healthy — imsg engine installed, Messages database readable, tools live. Use when the user asks whether texting works, why a send/read failed, or who Claude can text.
user-invocable: true
---

# /texting-status — texting health check

Run all checks, then report in plain language: one line per check with
✅/❌, then a "what to do" section only if something failed (point at the
matching `/texting-setup` step).

1. **imsg engine present**: /texting-setup installs it to `~/.claude/texting/engine` —
   `"${CLAUDE_PLUGIN_ROOT:-.}/bin/imsg" --version 2>/dev/null || imsg --version 2>/dev/null || echo MISSING`.
   `MISSING` → setup step 1 installs it (fallback `brew install steipete/tap/imsg` or set `IMSG_PATH`).
2. **bun present**: `bun --version || "$HOME/.bun/bin/bun" --version`.
   Missing → setup step 2.
3. **Messages DB readable**: `sqlite3 ~/Library/Messages/chat.db "SELECT COUNT(*) FROM chat" 2>&1`.
   `authorization denied` → Full Disk Access on the right target (desktop
   users: the embedded claude.app, see setup step 3); app restart required.
4. **MCP tools live**: check whether the `send_message` / `list_chats` /
   `read_messages` / `search_messages` / `react` / `watch` tools from this
   plugin's iMessage server are available in this session (load via
   ToolSearch if deferred). If present, the fastest single check is to
   **call the `status` tool** — it confirms imsg + chat.db readability in
   one shot. Missing while 1–3 pass → the session predates the plugin;
   restart it.
5. **Config**: read `~/.claude/texting/config.json` (fine if absent) and
   report the two opt-in safeguards in plain language: the **approval
   gate** (`approval: true` → every send pauses on a yes/no dialog only
   the user can answer) and the **AI-disclosure signature**
   (`signature: true` → "- Sent by Claude for <name>" is appended). Name
   resolution needs no separate check — imsg resolves contact names itself
   under the same Full Disk Access grant as chat.db.

If everything passes, suggest: "text yourself a hello, then ask me for your
recent messages."
