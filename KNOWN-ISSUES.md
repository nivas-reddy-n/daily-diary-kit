# Known issues (honest list, checked 2026-10-01)

1. **Slack keyword search can return nothing.** The skill falls back to a
   name-based query; some runs may end up thin on Slack signal. The note's
   honesty line will say so.
2. **Glean "ActiveProjects memory" is sometimes empty.** Harmless; git/PR
   sources still cover work items.
3. **API connectivity blips can stall a run.** Headless runs retry on
   `ENOTFOUND`-type errors; a bad network day can stretch a run from ~3
   minutes to much longer. The log (`~/Library/Logs/daily-diary.log`) shows
   exactly what happened. If a run fails, the wrapper does not count it as
   completed — the next scheduled run retries without waiting out the
   cooldown.
