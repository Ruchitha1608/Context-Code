<!-- Updated May 2026 -->
# Contextkit — Feature Handoff (May 2026)

Three features shipped this week. All are live in `contextkit_launch.sh`,
`bin/undo_shield.py`, and `audit.py`.

---

## 1. Undo Shield

**File:** `bin/undo_shield.py`
**Wired as:** `PreToolUse` hook in `.claude/settings.local.json`
**Installed by:** `contextkit_launch.sh` (Claude only)

Intercepts `Write`, `Edit`, `Bash`, `NotebookEdit` tool calls before execution.
Checks `chat_action_graph.json` to score how much attention each target file
received this session (reads + edits, weighted by recency). If a high-attention
file is about to be overwritten or deleted, warns Claude before the operation runs.

**Severity tiers:**
- `rm -rf` on a heavily-edited file → exit 2 (hard block shown directly to user)
- Any other destructive op on a high-attention file → exit 1 (Claude warns, asks to confirm)
- Low-attention or no graph → exit 0 (allow silently)

**Bypass:** `DG_UNDO_SHIELD=0` in environment.

**Attention scoring:**
```
score = sum(kind_weight × 2^(-age_hours))
kind_weight: register_edit=8, edit_observation=5, read=2, read_cache_hit=1
threshold: score >= 2.0 (read 2× OR edited once within the session)
```

**Path matching:** uses `Path.resolve()` against `project_root / relative_path`
from the action graph — no fragile basename matching.

---

## 2. Rate Limit Failover

**File:** `bin/contextkit_launch.sh`
**New flag:** `--model=codex|local|gemini|opencode` on `dgc` and `dg`

When Claude exits non-zero with a rate-limit signal in stderr (`rate limit`,
`overloaded`, `529`, `quota exceeded`, `capacity`), prints available fallback
options with exact copy-paste commands. The session graph is preserved — the
fallback model starts with zero re-exploration cost.

**Auto-detection:**
- `codex` installed → shows `dg "$PROJECT"` and `dgc --model=codex "$PROJECT"`
- Ollama running on `:11434` → queries `/api/tags`, shows first 3 models, offers `dgc --model=local`
- `gemini` installed → shows `dgc --model=gemini`

**`--model=local` routing:**
Sets `OPENAI_BASE_URL=http://localhost:11434/v1` and picks the top Ollama model,
then routes through Codex (which speaks OpenAI-compatible API). Same graph, same context.

**Flag stripping:** `--model=codex|local|gemini|opencode` is stripped before the
Claude CLI flag parser sees remaining args — it won't accidentally forward to Claude.

---

## 3. Vibe Code Auditor

**File:** `audit.py`
**Command:** `dgc audit /path/to/project [--fix] [--json] [--no-color]`

Runs 7 checks against `info_graph.json` + source files:

| Check | Method |
|---|---|
| Dead exports | Graph traversal — exported symbols with no inbound imports/references edges |
| Test coverage | Match code files to test files by stem; sort untested by file size |
| Circular deps | DFS on import edges, up to 10 cycles |
| Copy-paste | Group symbols by `body_hash`, flag groups ≥ 2 with span ≥ 10 lines |
| DB in routes | Regex DB call patterns in files matching `routes/controllers/handlers/api` |
| Orphaned TODOs | `TODO/FIXME/HACK/XXX` in code files |
| Missing error handling | Functions making `fetch/axios/requests/http` calls without try/catch |

**Outputs:**
- ANSI-coloured terminal report with debt score (0–100) + prioritised fix roadmap
- `.contextkit/audit_report.json` — machine-readable full results
- `.contextkit/AUDIT_CONTEXT.md` — injected into every subsequent `prime.sh` for 7 days,
  so Claude starts each session knowing what to fix without being told again

**`--fix` flag:** runs the audit then `exec dgc` — Claude launches with the audit
context already in its system prompt.

**`--model` flag example:**
```bash
dgc audit /my/project          # text report
dgc audit /my/project --fix    # report + launch dgc immediately
dgc audit /my/project --json   # JSON to stdout
```

---

## Files Changed

| File | Change |
|---|---|
| `bin/undo_shield.py` | New file |
| `audit.py` | New file |
| `bin/contextkit_launch.sh` | +audit subcommand, +--model flag, +Undo Shield hook install, +AUDIT_CONTEXT.md injection, +rate limit failover block |

---

## What's Next (from PRODUCT_HANDOFF.md)

**Priority 4 — Dashboard upgrade** (`dashboard/`)
- Add savings-vs-baseline calculation (show `$0.23 saved this session`)
- Rate limit status widget
- Failover model status indicator

**Priority 5 — Episodic Memory Layer** (`episodic_store.py` + `episode_extractor.py`)
- SQLite + sqlite-vec for local vector search over past sessions
- Episode capture at session end (LLM summarises turn into structured episode)
- Inject top-2 relevant past episodes into `prime.sh` at session start
- This is the long-term moat: graph knows WHERE, episodes know HOW

Full research and prioritisation: `PRODUCT_HANDOFF.md`
