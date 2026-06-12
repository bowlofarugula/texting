# texting

Use Claude to text and read iMessages — the same way you'd use it with
Gmail or Slack. macOS only. No background agent, no auto-replies: Claude
only reads or sends when asked, and sends get a normal permission prompt
first (review before it goes out).

```
"Text Sam: confirmed for Friday at 3"
"Any new messages from Sam?"
"Catch me up on my texts"
```

## How it works

The macOS iMessage/SMS engine is [openclaw/imsg](https://github.com/openclaw/imsg),
a mature Swift CLI that reads `~/Library/Messages/chat.db` and drives
Messages.app. The plugin ships a thin MCP server over it, so texting works
as a plugin in the Claude **desktop** app (not just the terminal). It runs
in every session and exposes:

- **`send_message`** — send to a phone number, Apple ID email, contact
  name, or chat_id; works for brand-new contacts (supports attachments).
  Routes iMessage vs SMS automatically — Android recipients work via Text
  Message Forwarding, with SMS fallback when iMessage isn't available
- **`list_chats`** — an inbox-style view of your most recent conversations
- **`read_messages`** — read conversation history; pass a person's handle
  to cover their iMessage and SMS threads at once, or a chat_id for a group
- **`search_messages`** — find messages by text, newest first ("when did
  Sam mention the invoice?")
- **`react`** — tapback the latest message in a thread (love, like, laugh…)
- **`watch`** — wait briefly for incoming messages and return them (with a
  cursor to resume from), for catching a reply that's expected shortly

Names come from **macOS Contacts** — the same cards the user sees in the
Contacts app. The plugin keeps no contact store of its own; people Claude
doesn't recognize get offered a real Contacts card.

| Skill | Does |
| --- | --- |
| `/texting:setup` | One-time install: the `imsg` engine, plus the Full Disk Access toggle |
| `/texting:send` | Send a text (confirms recipient + exact wording first) |
| `/texting:messages` | Read threads, resolve "Sam" → handle via macOS Contacts |
| `/texting:listen` | Session-bound watch: "tell me when Alex replies" — polls, notifies, drafts replies for approval, never auto-sends |
| `/texting:status` | Health check |

## Setup friction (one-time, ~5 minutes)

1. `brew install steipete/tap/imsg` — the engine (the setup skill does it)
2. One Full Disk Access toggle for the app hosting Claude (desktop users:
   the embedded claude.app — the setup skill knows the path), then restart
   it
3. The macOS Automation prompt on the first send

## Security model

Same consent shape as a mail connector: Claude can read any conversation
**when asked** — granting Full Disk Access *is* the "Claude may read my
texts" decision, just like connecting Gmail is the "Claude may read my
email" decision. The guarantees on top:

- Every send is human-approved (permission prompt with the exact text) and
  signed `- Sent by Claude for <name>` — the name defaults to the macOS account first name, can be set per machine ("set my default signature to Acme") or per send ("send this as Acme"), so machine-sent messages are always disclosed.
- Nothing listens for inbound texts; an incoming message cannot trigger
  Claude. Reads happen only when the user asks, about what they asked.
- Message content Claude reads is treated as data — instructions embedded
  in texts are surfaced to the user, never acted on.

## Auto-reply mode

Deliberately **not** part of this plugin's setup. If you want Claude
answering texts unattended, that's an always-on headless process with a
very different risk profile (replies go out unreviewed; the sender
allowlist becomes a real security boundary) — see
[docs/AUTOREPLY.md](docs/AUTOREPLY.md) for the recipe and the checklist of
caveats.

## Credits

Built on [openclaw/imsg](https://github.com/openclaw/imsg) (MIT) — the
iMessage/SMS engine that does the reading, sending, automatic iMessage/SMS
routing, and reactions. This plugin is the MCP surface and skills around it.

See [NOTICE](NOTICE) for full attribution.

## Support & contributing

Best-effort maintenance — I'll do my best to fix bugs and security issues, and contributions
are very welcome. Open an issue or a pull request; help with docs, tests, or features is
encouraged. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[Apache-2.0](LICENSE) © Ian McDonald.
