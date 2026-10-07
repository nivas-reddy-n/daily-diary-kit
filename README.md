# Daily Diary Kit

A self-installing AI workflow that writes your work diary for you, twice a day.

A scheduled headless Claude Code agent collects the last 24 hours of your work
signal — calendar meetings, PRs you touched, local AI sessions (Claude Code /
Codex / Cursor), and (opt-in) Slack and Gmail signals via Glean — and merges it
into a private daily note in a plain markdown vault on your machine.

Everything stays local. Nothing is uploaded, posted, or shared anywhere.

## What you get

- `01-Daily/<date>.md` — today's diary, auto-merged: it skips what is already
  noted, enriches status changes (open -> merged), and preserves your manual
  edits.
- `02-Projects/<date> <slug>.md` — atomic notes for significant PRs/projects,
  cross-linked from the daily note.
- A rolling 24h window with catch-up: after laptop-off gaps, the next run
  backfills everything since the last completed run (`last_run` frontmatter).
- A wrapper that counts only completed runs: a failed run (API error,
  network blip) exits non-zero and does not start the 2-hour cooldown, so
  the next scheduled run retries automatically.

## Setup: one paste

Open Claude Code and paste the setup prompt from the Google Doc
("Daily Digital Diary - a self-installing AI workflow"), section 4.

The agent will:

1. Verify prerequisites (macOS, git/gh, Claude Code + LLM gateway key,
   Glean MCP).
2. Ask you 6 preference questions (vault path, run time, catch-up, Slack,
   Gmail, Obsidian viewer).
3. Install: skill -> `~/.claude/skills/daily-diary/`, wrapper ->
   `~/.local/bin/daily-diary-run.sh`, launchd plist -> `~/Library/LaunchAgents/`.
4. Run one supervised test diary and show you the result.
5. Prefill a "Set up daily diary" issue in this repo — submit it to log your
   adoption in [ADOPTERS.md](ADOPTERS.md).

## Repo layout

```
skill/                  the daily-diary skill (installed to ~/.claude/skills/)
launchd/                launchd plist template (rendered per user at setup)
setup/                  wrapper script + agent-facing setup checklist
.github/ISSUE_TEMPLATE/ "Set up daily diary" adoption issue template
ADOPTERS.md             the adoption log
KNOWN-ISSUES.md         honest list of current limitations
```

## Prerequisites (summary)

| Requirement | How |
|---|---|
| Mac with macOS | v1 is launchd-based |
| Claude Code CLI | your org's install docs |
| LLM gateway API key | self-generate via your org's API-key channel SOP |
| Glean MCP | self-serve, add to Claude Code per your internal Glean MCP guide |
| git + gh | standard |

Channel names and gateway specifics differ per org — swap in your own in
this table and in `setup/CHECKLIST.md`.

Obsidian is an optional viewer only — the vault is a plain folder of markdown
files that works with any editor. Obsidian is currently IT-blocked; if you
want it, follow IT policy.

## Support

DM the author on Slack. See [KNOWN-ISSUES.md](KNOWN-ISSUES.md) before filing.

## Feedback

A 3-question feedback form lands here 2-3 weeks after you adopt. 30 seconds,
huge help.
