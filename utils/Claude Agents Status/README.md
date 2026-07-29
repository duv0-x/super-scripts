# 🤖 Claude Agents Status

Shows the status of your Claude Code **background agent fleet** at a glance.

If you run a long-lived agent per ticket — one that stays open for days or weeks while
waiting for a developer to approve a fix or request a change — this tells you which ones
are still alive, which ones quietly died on startup, and which ones are hoarding disk.

---

### 📋 What Does It Do?

Reads `~/.claude/jobs/*/state.json` and reports, for every background session:

- **State** — `working`, `blocked` or `done`, color-coded
- **Age** — days since the session last changed state
- **Tokens** — how much the session has consumed
- **Tmp** — size of the session's scratch directory
- **Name** — ticket ID or session intent

Sorted by urgency (`working` → `blocked` → `done`, oldest first within each group).

It also flags two conditions automatically:

| Flag | Meaning |
|------|---------|
| `ABANDONADO?` | Blocked for more than 7 days with fewer than 5k tokens — this one is not waiting on anyone, it stalled at startup |
| `tmp pesado` | A `done` session holding more than 10 MB of scratch — safe to compact |

---

### ⚙️ Usage

```bash
./claude-agents.sh            # live fleet only (working + blocked) — default
./claude-agents.sh -a         # all sessions, including done
./claude-agents.sh -d         # done only (candidates for cleanup)
./claude-agents.sh -f         # sort by tmp/ size — who is eating disk
./claude-agents.sh -j         # JSON output, to pipe into jq
./claude-agents.sh <id>       # detail for one session
```

Sample output:

```
ESTADO     EDAD    TOKENS      TMP  ID         NOMBRE
working      0d         0       0K  9435cb43   PIS-102226
blocked     49d         0       0K  9e63f766   implement lkz-52          ← ABANDONADO?
blocked     21d    144439       5M  e0b754df   review ls-121159
done        11d    623591     111M  784c7591   Guardia                   ← tmp pesado

  blocked: 3   done: 1   working: 1
  disco en tmp/: 116 MB
```

The per-session detail view gives you enough to decide without reopening the agent —
its recorded result, the model it ran on, the path to its full transcript, and the last
few timeline events:

```bash
$ ./claude-agents.sh 784c7591
sesión:   784c7591
estado:   done
tokens:   623591
nombre:   Guardia
resultado:file reverted to H2H-Gruponutresa-lbprod; JIRA & KB updated
tmp:      112M
log:      /Users/lx-duv0-x/.claude/projects/.../784c7591-....jsonl
```

---

### 🧹 Cleanup guidance

Clean up by **state**, never by age — a session blocked for 49 days may still be a live
ticket waiting on someone else. Only `done` sessions are safe to touch, and even then
only their `tmp/`: `state.json` and `timeline.jsonl` are ~15 KB each and hold the record
of what the agent actually accomplished.

```bash
# reclaim scratch space from finished sessions older than 14 days
find ~/.claude/jobs -maxdepth 2 -name tmp -type d -mtime +14 | while read -r d; do
  [ "$(jq -r .state "$(dirname "$d")/state.json")" = "done" ] && rm -rf "$d"
done
```

---

### 📦 Requirements

- Claude Code with background agents (populates `~/.claude/jobs/`)
- `jq`
- macOS — uses BSD `stat -f %m`; on Linux swap it for `stat -c %Y`

Override the jobs location with `CLAUDE_JOBS_DIR` if yours is elsewhere.

> ℹ️ Output strings are in Spanish, matching the author's daily use.
