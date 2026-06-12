---
name: send
description: Send an iMessage to someone from this session. Use when the user asks to text someone, send a message, iMessage a person, or "tell X" something over text. Works on macOS; Claude confirms the exact text before sending.
user-invocable: true
---

# /texting:send — send an iMessage

Arguments passed: `$ARGUMENTS` (free-form, e.g. "Sam let's confirm Friday"
or "+15551234567 the cut is ready")

## Resolve the recipient

You need a handle: phone in `+1` format, an Apple ID email, or a macOS
contact name. Resolve names the same way as `/texting:messages`: macOS
Contacts (AddressBook sqlite) → ask the user. There is no plugin-private
contact store. After a successful send to someone new, offer to add them to
macOS Contacts (`scripts/add-contact.applescript "<Name>" "<handle>"` —
one-time Contacts Automation prompt on first use).

## Confirm, then send

**Always show the exact recipient handle and exact message text and get a
yes before sending.** If the user dictated rough intent ("tell her I'm
running late"), draft the text, show it, let them edit.

Send with the **`send_message` MCP tool** (this plugin's iMessage server):
`to` takes the handle directly — phone, email, contact name, or a numeric
chat_id for groups — and it works for brand-new contacts with no prior
conversation. Supports `files` (absolute paths) for attachments, and an
optional `service` (`auto` default, or `imessage`/`sms` to force a route).
The server appends the `- Sent by Claude for <name>` signature.

## Signature identity

- Default name: `signatureName` in `~/.claude/texting/config.json` if set,
  else the macOS account first name.
- "Send this as Acme" / "sign it from the studio" → pass
  `sign_as: "Acme"` on that send only. Include the signature line in
  the confirmation you show the user.
- "Set my default signature to Acme" / "always sign as X" → set
  `signatureName` in `~/.claude/texting/config.json` (create the file/dir if
  absent; read first and preserve other fields; 2-space indent). Applies
  from the very next send — the server re-reads per call. Confirm what the
  sign-off now looks like.
- Never drop the "Sent by Claude" half — the AI disclosure isn't optional;
  only the name varies.

**Group chats**: resolve "the family group" / "the Sam thread with both of
them" via `list_chats` (or `read_messages`) — group headers carry their
`chat_id`; match on the group's name or its participants and pass that
numeric `chat_id` as `to`. (DMs need no id — pass the handle.) Claude can
message any *existing* group but cannot create a new one (Messages exposes
no API for that) — if no matching group exists, ask the user to create it
in Messages first.

**imsg CLI fallback** — only if the MCP tools aren't available in this
session (e.g. setup incomplete):

```sh
imsg send --to "<handle>" --text "<text>" --service auto
```

Append the signature yourself on this path: two newlines, then
`- Sent by Claude for <first name>` (first word of `id -F`) so machine-sent
texts are always disclosed. Use a group's numeric id with `--chat-id` in
place of `--to`.

## First-ever send on this Mac

The first send triggers a macOS Automation prompt ("…wants to control
Messages") — tell the user to click **Allow**. Error `-1743` afterwards
means it was declined: System Settings → Privacy & Security → Automation →
enable Messages for the app hosting Claude.

## Android / SMS recipients

`send_message` routes iMessage vs SMS automatically: iMessage when the
recipient has it, falling back to SMS otherwise. Read the tool result — it
tells you what happened. SMS sending only works when **Text Message
Forwarding** is enabled (iPhone: Settings → Messages → Text Message
Forwarding → this Mac); the tool's error says exactly that when it's the
blocker.

## Failure modes

- error mentions Text Message Forwarding → it is enabled but OFFLINE more
  often than off: forwarding is a live session that drops when the iPhone
  is asleep or offline (proximity is NOT required — the phone just needs
  power and internet, anywhere). Wake the iPhone and retry before touching
  any settings.
- error mentions Full Disk Access / `authorization denied` → run
  `/texting:setup` step 3.
- `Messages got an error` → open Messages.app once (signed in), retry.
