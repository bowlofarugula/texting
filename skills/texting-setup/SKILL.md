---
name: texting-setup
description: One-time setup for texting over iMessage from Claude — installs the imsg engine and walks the Full Disk Access + Automation grants. Use when the user asks to set up texting, when the iMessage tools (send_message/read_messages) are missing or erroring, or before the first send/read on a new Mac.
user-invocable: true
---

# /texting-setup — iMessage connector setup

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

## Step 1 — install the imsg engine (you do this, via Bash)

The engine is the official **signed and notarized** macOS binary from the
[openclaw/imsg](https://github.com/openclaw/imsg) GitHub release. You download
and install it — the user does nothing and needs no Homebrew or developer
tools; macOS's built-in `curl`/`unzip` do the work. First check whether it's
already there:

```sh
"$HOME/.claude/texting/engine/imsg" --version 2>/dev/null || imsg --version 2>/dev/null || echo MISSING
```

A version number → done, skip to Step 2. (imsg is macOS-only.)

`MISSING` → install it (pinned version, checksum-verified):

```sh
set -e
IMSG_VERSION="v0.11.1"
IMSG_SHA256="a25a541f0c4c8244f301a8495f875964dc4b0c3fd5cbf5ead6a64e4d282d940e"
TMP="$(mktemp -d)"
curl -fsSL -o "$TMP/imsg-macos.zip" \
  "https://github.com/openclaw/imsg/releases/download/$IMSG_VERSION/imsg-macos.zip"
echo "$IMSG_SHA256  $TMP/imsg-macos.zip" | shasum -a 256 -c -
mkdir -p "$HOME/.claude/texting"
rm -rf "$HOME/.claude/texting/engine"
unzip -q "$TMP/imsg-macos.zip" -d "$HOME/.claude/texting/engine"
rm -rf "$TMP"
"$HOME/.claude/texting/engine/imsg" --version
```

A version number at the end → installed. If the checksum line fails, **stop**
— do not install the file — and re-download once; persistent mismatch means
the download is corrupted or tampered with, report it instead of proceeding.

> Resolution order (server and `bin/imsg` launcher alike): `IMSG_PATH` →
> `~/.claude/texting/engine/imsg` → `imsg` on PATH → `/opt/homebrew/bin/imsg`
> → `/usr/local/bin/imsg`. Power-user alternative:
> `brew install steipete/tap/imsg`.

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
when the user says "text Sam", the `send_message` tool passes the name to
imsg, which looks Sam up in their real address book itself (no manual
lookup needed), and unknown people get offered a proper Contacts card.

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
run /texting-status
```

It reports imsg present, chat.db readable, and Messages reachable.

## Optional — the hard approval gate

By default, sends go through the normal review-before-send flow above. For
users who want a **hard stop** — every outgoing message pauses on a yes/no
dialog that only a human can answer, shown in the client with the exact
recipient and text — offer the approval gate, especially on managed or
shared machines where "Claude must never send without my explicit OK" is a
requirement:

- Enable: set `approval: true` in `~/.claude/texting/config.json` (create
  the file/dir if absent; read first and preserve other fields; 2-space
  indent). Applies from the next send — no restart needed.
- Explain the behavior in plain language: a dialog appears before each
  send/reaction; **Decline** cancels it and nothing goes out.
- Caveat: the dialog needs a client that supports approval prompts (MCP
  elicitation — Claude Code does). In a client that can't show them, the
  gate **blocks sends entirely rather than sending unapproved** — that's
  intentional (fail-closed), and turning the gate off is the only way to
  send from such a client.

## Optional — the AI-disclosure signature

By default, messages go out **as-is**: no "- Sent by Claude" stamp. The
signature is opt-in (we don't presume to label the user's own texts). If they
want machine-sent texts disclosed, mention they can enable it:

- Globally: set `signature: true` in `~/.claude/texting/config.json` (and
  optionally `signatureName` for the name); or env `IMESSAGE_APPEND_SIGNATURE=true`.
- Per send: "send this as Acme" → the signature is added for that message only.

Once on, it appends `- Sent by Claude for <name>` (name = sign_as > config
`signatureName` > macOS account first name).

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| tools say `imsg engine not found` | Step 1 wasn't run (or the engine dir was deleted) — run the Step 1 install. Fallback: `brew install steipete/tap/imsg` or set `IMSG_PATH` |
| no send_message/read_messages tools in session | session predates the plugin enable — restart the session |
| tools error: `authorization denied` / Full Disk Access | FDA on the wrong target — desktop users need the embedded claude.app, step 3 — then restart the app |
| send fails with error `-1743` | Automation prompt was declined — System Settings → Privacy & Security → Automation → enable Messages for the host app |
| sends to Android contacts bounce with a Text Message Forwarding error | enable it: iPhone → Settings → Messages → Text Message Forwarding → this Mac. Worth setting up proactively for users who text Android contacts |

## Auto-reply mode (not installed here)

If you later want Claude to *answer* texts unattended, that's a different
architecture (an always-on headless process driven by `imsg watch`) with
real security tradeoffs. See [docs/AUTOREPLY.md](../../docs/AUTOREPLY.md)
before offering it.
