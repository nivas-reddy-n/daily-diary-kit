# Setup checklist (for the setup agent)

Work through this in order. Stop and report at the first failed prerequisite.
Never print, store, or echo API keys. Touch nothing outside: `~/.claude`,
`~/.config/daily-diary`, `~/.local/bin`, `~/Library/LaunchAgents`,
`~/Library/Logs`, and the user's vault folder.

## 0. Context

- Kit repo: the repo this checklist lives in (see README).
- The user pasted the one-step setup prompt from the Google Doc.

## 1. Verify prerequisites (report pass/fail for each)

1. macOS: `sw_vers` (launchd is macOS-only in v1).
2. git installed: `git --version`.
3. GitHub auth: `gh auth status` (needed for PR tracking; warn if missing).
4. Claude Code CLI on PATH: `claude --version`.
5. Claude Code authentication works (LLM gateway key, e.g. a corporate AI
   gateway). If auth fails, tell the user to generate a key via their org's
   API-key channel SOP and stop until confirmed.
6. Glean MCP reachable from Claude Code (list MCP servers). If missing, point
   to the user's internal Glean MCP setup guide; stop until enabled.

## 2. Ask preference questions (one at a time, wait for each answer)

| # | Question | Default |
|---|---|---|
| a | Vault folder | `~/flowstate` |
| b | Daily run time (24h) | `18:00` |
| c | Morning catch-up run on boot | on |
| d | Slack signals in the diary | off |
| e | Gmail signals in the diary | off |
| f | Obsidian viewer install | skip (IT-blocked; install only per IT policy) |

## 3. Install

1. Copy `skill/` to `~/.claude/skills/daily-diary/`.
2. Write answers to `~/.config/daily-diary/config.json`:
   `{"vault_dir": "...", "sources": [...], "schedule": "HH:MM",
   "catchup_on_boot": true|false}` — include "slack"/"gmail" in `sources`
   only if opted in. Always include "meetings", "git", "ai_sessions".
3. Install `setup/daily-diary-run.sh` to `~/.local/bin/daily-diary-run.sh`
   and `chmod +x`.
4. Render `launchd/com.user.daily-diary.plist.template` with the username and
   schedule; write to
   `~/Library/LaunchAgents/com.<user>.daily-diary.plist`; then
   `launchctl load` it. If (c) is off, remove the `RunAtLoad` key.
5. Create vault folders: `<vault>/01-Daily/` and `<vault>/02-Projects/`.
6. If the user chose Obsidian and IT policy allows, install it; otherwise
   skip silently.

## 4. Verify

1. `bash -n ~/.local/bin/daily-diary-run.sh` (syntax check).
2. `plutil -lint ~/Library/LaunchAgents/com.<user>.daily-diary.plist`.
3. `launchctl list | grep daily-diary`.
4. Run one supervised test: `claude -p "Run the /daily-diary skill now."`
   and show the created note and `tail -20 ~/Library/Logs/daily-diary.log`.
5. Explain the cooldown contract to the user: the wrapper counts only
   **completed** runs — a failed run (e.g. network/API error) exits non-zero
   and does not bump the cooldown, so the next scheduled run retries
   automatically. State lives in `~/.local/state/daily-diary/`.

## 5. Log adoption

Prefill the kit repo's "Set up daily diary" issue (name, team, date) and ask
the user to submit it.
