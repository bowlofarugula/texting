---
name: setup
description: One-time setup for texting over iMessage from Claude — installs the imsg engine and walks the Full Disk Access + Automation grants. Use when the user asks to set up texting, when the iMessage tools (send_message/read_messages) are missing or erroring, or before the first send/read on a new Mac.
user-invocable: true
---

# /texting:setup — iMessage connector setup

After this runs, the user can say "text Sam we're confirmed for Friday" or
"any new messages from Sam?" in any Claude session, with normal permission
prompts before anything is sent. There is no background agent and no
auto-reply: Claude only reads or sends when asked.

The macOS iMessage/SMS engine is [`imsg`](https://github.com/openclaw/imsg);
the plugin ships a thin MCP server over it that exposes `send_message`,
`list_chats`, `read_messages`, `search_messages`, and `react` in every
session.

The user may be non-technical. Run every check yourself via Bash; only hand
them the genuinely-human steps (System Settings toggle, macOS prompts), one
at a time, in plain language.

Arguments passed: `$ARGUMENTS` (optional)

---

## Step 1 — install the imsg engine

`imsg` installs via Homebrew. Check first:

```sh
command -v imsg >/dev/null && imsg --version || echo MISSING
```

`MISSING` → install it. If `brew` is present:

```sh
brew install steipete/tap/imsg
```

No `brew`? Install Homebrew first (`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`),
then the line above. After install, confirm `imsg --version` prints a
version.

> The server self-locates the binary (`command -v imsg`, then
> `/opt/homebrew/bin/imsg`, then `/usr/local/bin/imsg`), so a GUI app that
> doesn't inherit your shell PATH still finds it. Override with `IMSG_PATH`
> if it lives somewhere unusual.

## Step 2 — the bun runtime

The MCP server is a bun script.

```sh
bun --version || "$HOME/.bun/bin/bun" --version
```

Missing → `curl -fsSL https://bun.sh/install | bash`. The plugin's `start`
script runs `bun install` itself on first launch, so there's nothing to
install by hand.

## Step 3 — Full Disk Access for the host app

iMessage history lives in `~/Library/Messages/chat.db`, which macOS
protects. Test first — this is the same access `imsg` will get:

```sh
sqlite3 ~/Library/Messages/chat.db "SELECT COUNT(*) FROM chat" 2>&1
```

A number → already granted, skip ahead. `authorization denied` → the grant
target depends on how Claude runs (verified empirically):

- **Claude desktop app**: the grant must go to the **embedded Claude Code
  helper app**, NOT the main Claude app — the desktop launcher disclaims
  TCC responsibility, so a grant on "Claude" never applies. Walk the user
  through: System Settings → Privacy & Security → **Full Disk Access** →
  `+` → press **Cmd+Shift+G** → paste
  `~/Library/Application Support/Claude/claude-code/` → open the version
  folder → select the lowercase **claude.app** → toggle ON. (It shows in
  the FDA list as lowercase "claude".) Re-check after major desktop app
  updates.
- **Terminal CLI**: grant the terminal app (Terminal, iTerm, Ghostty…)
  from Applications.

Quit and reopen the app after granting, then re-run the test.

There is no contact configuration. Names come from **macOS Contacts** —
when the user says "text Sam", Sam is looked up in their real address
book, and unknown people get offered a proper Contacts card.

## Step 4 — first send (the Automation prompt)

Have the user try it: "text me a hello" (to themselves). Two one-time
things happen:

1. A normal Claude permission prompt for the send — that's the
   review-before-send flow working as intended.
2. The macOS **Automation** prompt ("…wants to control Messages") — click
   **Allow**. This is what lets `imsg` hand the message to Messages.app.

Then have them try a read: "what are my recent messages?" → the
`read_messages` tool should return their self-chat.

## Verify

Quickest end-to-end check is the status tool:

```
run /texting:status
```

It reports imsg present, chat.db readable, and Messages reachable.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| tools say `imsg is not installed` | Step 1 — `brew install steipete/tap/imsg`; confirm `imsg --version` |
| no send_message/read_messages tools in session | session predates the plugin enable — restart the session |
| tools error: `authorization denied` / Full Disk Access | FDA on the wrong target — desktop users need the embedded claude.app, step 3 — then restart the app |
| send fails with error `-1743` | Automation prompt was declined — System Settings → Privacy & Security → Automation → enable Messages for the host app |
| sends to Android contacts bounce with a Text Message Forwarding error | enable it: iPhone → Settings → Messages → Text Message Forwarding → this Mac. Worth setting up proactively for users who text Android contacts |

## Auto-reply mode (not installed here)

If you later want Claude to *answer* texts unattended, that's a different
architecture (an always-on headless process driven by `imsg watch`) with
real security tradeoffs. See [docs/AUTOREPLY.md](../../docs/AUTOREPLY.md)
before offering it.
