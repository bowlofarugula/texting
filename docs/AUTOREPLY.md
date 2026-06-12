# Auto-reply mode (optional, not installed by default)

The texting plugin's default model is **human-in-the-loop**: Claude reads
and sends iMessages only when asked, with normal permission prompts. You
may eventually want the other thing — Claude *answering* texts
unattended. That's a fundamentally different posture; read this whole page
before standing it up.

## Why this needs its own machinery

The plugin's MCP tools serve an *open* Claude session. Auto-reply is the
case where **no session is open** — someone texts at 3am and something has
to wake Claude. There's nothing to schedule a poll against, so you need a
persistent process running 24/7.

The right primitive for that process is `imsg watch`, which **streams** new
messages as line-delimited JSON instead of polling:

```sh
imsg watch --json
# → one JSON object per new message, as it arrives
```

An auto-replier is a long-lived loop that reads those lines, hands each
inbound message to a headless `claude` turn, and sends the reply back with
`imsg send`. A LaunchAgent (`KeepAlive`) keeps the loop alive across crashes
and reboots.

## What changes (the security model)

- The loop runs `claude` headless with broad permissions. **Everyone whose
  messages you feed it can instruct that agent** — file access, connectors,
  everything the owner's Claude can do. Your inbound filter (which senders
  the watch loop forwards) stops being a convenience and becomes a real
  security boundary: "people with operator access to this Mac."
- Replies go out with **no human review**. The `- Sent by Claude for <name>`
  signature still discloses the machine, but nobody approves the wording.
- Message content is still data, never instructions. The loop's prompt must
  treat quoted/forwarded third-party text as data and refuse to act on
  "tell Claude to…" requests embedded in a message.

## Hard requirements

- `imsg` installed and granted **Full Disk Access** (read) **and**
  **Automation → Messages** (send) for the launchd context — note that
  under launchd the granted process is the one that *spawns* imsg (bun /
  claude), and those grants are version-pinned and break silently when a
  CLI update moves the binary.
- A standalone authenticated `claude` CLI (the desktop app's embedded copy
  can't be driven by launchd) and `bun` on PATH.
- A keep-alive that holds the loop open — a bare `claude -p` exits after one
  turn; the watch loop is what keeps it fed.

## Checklist before enabling

- [ ] You understand replies go out unreviewed
- [ ] The inbound filter is reduced to the owner (+ at most a trusted
      teammate) — never the people who text in
- [ ] FDA + Automation grants in place for the launchd context; you have a
      plan for re-granting after CLI updates
- [ ] The standing prompt treats message content as data, not instructions
