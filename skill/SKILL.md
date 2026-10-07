---
name: daily-diary
description: >
  Collect the last 24 hours of your work signal (meetings, PRs, local AI
  sessions, opt-in Slack/Gmail via Glean) and merge it into today's daily note
  in a plain markdown vault. Designed to run headless on a schedule
  (macOS launchd), but works for a manual run too. Use when the user says
  "daily diary", "update my diary", or when the wrapper invokes this skill.
---

# Daily diary

Build or **merge into** the user's daily work diary from the trailing 24
hours of activity. This is a second-brain capture pass: raw facts gathered,
atomic notes split out, everything wikilinked. Keep it boring — no plugins,
no Dataview, just markdown sections and `[[links]]`.

## Configuration

Read `~/.config/daily-diary/config.json` (written by the setup agent):

```json
{
  "vault_dir": "~/flowstate",
  "sources": ["meetings", "git", "ai_sessions", "slack", "gmail"],
  "schedule": "18:00",
  "catchup_on_boot": true
}
```

Only use the sources listed in `sources`. Missing config -> ask the user.
Resolve `vault_dir` (it may start with `~`) and write **only inside it**.

## Window and target note

- **Window:** the trailing 24 hours, ending now. If today is 18:00, collect
  from yesterday 18:00. All Glean date filters use this window
  (`after:<start>` / `before:now` in YYYY-MM-DD or full timestamps where
  supported). For `find -newermt` on session files, use the window start.
- **Target note:** `01-Daily/<run-day>.md` inside `vault_dir` (create if
  missing), where run-day is today's date — the note named for the day the
  run executes, regardless of which day the items occurred on. Items carry
  their true timestamps, so a morning catch-up run lands yesterday-evening
  items in today's note with yesterday's times attached.
- **Gap catch-up:** if the target note's `last_run:` frontmatter is *later*
  than the window start (laptop-off gap), extend the window start back to
  `last_run` so nothing falls between runs.

## Ground rules

- Glean calls are **read-only**. Never use any Glean write/send/action tools.
- Write **only inside the vault** (from `vault_dir` in config). Touch nothing
  else except read-only peeking at the sources below.
- If a source returns nothing, leave the section with a single `- (none)`
  line — never pad or invent.
- Summarize aggressively: the diary is signal, not a log dump. Condense
  Slack/email to items worth remembering.
- **Merge, never duplicate or blind-append.** If the target note exists:
  read it fully, then insert only items that aren't already represented
  (same meeting / same PR / same session / same thread = already
  represented, skip or enrich in place). Insert new items into the correct
  sections — never dump below the last section. Never remove or rewrite
  existing bullets: the note may contain the user's own manual edits.
- Update `last_run` in the frontmatter to the run's start timestamp
  (`YYYY-MM-DD HH:MM` local). If the note exists without `last_run`, add it.

## Step 1 — Collect

Run these in parallel where possible. `START` = window start (now minus 24h,
or `last_run` if later). Skip every source not in `sources`.

1. `user_activity` (Glean) — start_date=START date, end_date=today+1
   (exclusive; use yesterday's date as start_date when the window crosses
   midnight).
2. `meeting_lookup` (Glean) — after=START, before=today+1. List of meetings
   in the window.
3. For each **significant** meeting (skip routine 1:1s with no outcome, skip
   declined/cancelled): pull transcript/summary from the meeting_lookup
   result. Extract decisions made, action items with owners and due dates,
   follow-ups.
4. `gmail_search` (Glean, opt-in) — query `after:<START-date>
   before:<tomorrow>`. Only notable threads (decisions, requests, approvals,
   blockers).
5. `search` (Glean, opt-in) — Slack signal: query `*` with `app:slack` filter
   and `updated:today` plus yesterday when the window crosses midnight
   (`updated:past_2_weeks` narrowed by timestamps also works). Channels/DMs
   the user participated in within the window; capture decisions, asks, and
   commitments. If keyword search returns nothing, fall back to a name-based
   query.
6. `search` with `app:github` (Glean) and/or `gh` CLI — PRs opened or
   reviewed within the window: repo, PR number, what/why, review outcome
   (merged/approved/changes-requested/open).
7. `memory` (Glean) — read ActiveProjects to know which project names to
   wikilink. Sometimes empty; harmless.
8. **AI coding agent sessions** (`ai_sessions`) — enumerate local agent
   sessions modified after START (all read-only):
   - **Claude Code**: `~/.claude/projects/<munged-path>/<uuid>.jsonl` —
     `find ~/.claude/projects -name '*.jsonl' -newermt '<START>'`. Munged
     path = project directory. First `"type":"user"` line is the opening
     prompt.
   - **Codex**: `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` — check
     today's and yesterday's date dirs when the window crosses midnight;
     filter by mtime >= START. `session_meta` payload has `cwd`; first user
     message is the prompt.
   - **Cursor**: SQLite at
     `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`,
     **open read-only** (`file:...?mode=ro` — never read-write, Cursor is
     likely running). `composerHeaders` with `createdAt` >= START (epoch ms)
     -> per `composerId` read `composerData:<id>` in `cursorDiskKV`, first
     user bubble via `bubbleId:<composerId>:<bubbleId>` (bubble `type==1`).
     Empty drafts (0 headers) — skip.
   - **OpenCode**: `~/.local/share/opencode/storage/session/*/*.json`
     modified after START — `title` + `time.updated`; messages under
     `storage/message/<sessionId>/`.
   - Other agents (e.g. Windsurf) store sessions in binary formats — skip.
   For each session capture: agent, time, project directory, opening prompt
   (1 line), one-line gist of what was done. Skip sessions with no
   meaningful content.

## Step 2 — Atomic notes (`02-Projects/` inside the vault)

One note per significant meeting, one per significant PR. Filename:
`YYYY-MM-DD <Meeting Name>.md` or `YYYY-MM-DD PR <repo>#<number>
<short-title>.md` (wikilink-friendly — no `#` or `/` in the filename; write
`repo#123` inside the note, not in the filename). Use the **activity's
date**, not the run date. Check `02-Projects/` for an existing note before
creating — update it in place instead, same merge rules.

**Meeting note:**

```markdown
---
type: meeting
date: YYYY-MM-DD
---

# <Meeting Name>

**Attendees:** [[Name]], [[Name]]

## Key points
-

## Decisions made
-

## Action items
- [ ] <task> — owner: [[Name]], due: YYYY-MM-DD

## Follow-ups
-

Related: [[YYYY-MM-DD]]
```

**PR note:**

```markdown
---
type: pr
date: YYYY-MM-DD
---

# PR <repo>#<number>: <title>

**Repo:** <repo> · **Role:** raised/reviewed · **Status:** merged/approved/changes requested/open

## What & why
-

## Outcome
-

Related: [[YYYY-MM-DD]]
```

Link-as-you-go: every atomic note gets 2–3 links — the daily note,
`[[Person]]` names, `[[Project]]` names from Glean memory. Dangling links
are fine; they mark future notes.

## Step 3 — Daily note (`01-Daily/<run-day>.md`)

Create if absent, else merge (see ground rules). Structure — adapt to what
exists; drop empty sections except keep the `last_run` frontmatter:

```markdown
---
type: daily
date: YYYY-MM-DD
tags: [work-diary]
last_run: YYYY-MM-DD HH:MM
---

# YYYY-MM-DD

## Inbox
- (raw captures land here — leave empty if none)

## Meetings & outcomes
- **<time> <Meeting Name>** — one-line outcome → [[YYYY-MM-DD <Meeting Name>]]

## Action items on me
- [ ] <task> (from <meeting/PR/email> — due <date> if known)

## PRs raised / reviewed
- [[YYYY-MM-DD PR <repo>#<n> <title>]] — one-line what/why/status

## AI agent sessions
- **<Agent>** <HH:MM> — <project dir> — <one-line gist / opening prompt>

## Slack & email of note
- <condensed signal items with who/what>

## Today's notes
- [[<atomic note 1>]], [[<atomic note 2>]], …

Related: [[YYYY-MM-DD]]
```

## Honesty rules

- End with a line listing empty or failed sources and why (e.g. "Slack
  search returned nothing; fell back to name-based query").
- If a source errors, record it in the note and continue with other sources.
- Never invent items. If the window was empty, say so.

## Step 4 — Report

Finish with a 3-line summary to stdout: target note and whether it was
created or merged, items/atomic notes added vs already-present, any Glean
source that failed or returned empty. Do not send messages anywhere (no
Slack, no email).

## Wrapper contract

The wrapper (`~/.local/bin/daily-diary-run.sh`, installed by the setup
checklist) enforces a PID lockfile and a 2-hour cooldown based on the last
**completed** run — a failed run (non-zero exit) does not bump the cooldown,
so the next scheduled run retries. The skill only needs to exit non-zero
when it did not write the note.
