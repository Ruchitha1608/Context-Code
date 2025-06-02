

A context engine that makes Claude Code, Codex CLI, Gemini CLI, Cursor, OpenCode, and GitHub Copilot **30-45% cheaper** without sacrificing quality. It builds a semantic graph of your codebase and pre-loads the right files into every prompt — so your AI spends tokens reasoning, not exploring.


---

## How It Works

```
You run: ckc /path/to/project
         ↓
1. Project scanned → semantic graph built (files, symbols, imports)
2. You ask a question
3. Graph identifies the relevant files → packs them into context
4. Claude gets your question + the right code already loaded
5. Fewer turns, fewer tokens, better answers
```

Token savings **compound** across a session. The graph remembers which files were read, edited, and queried — each turn gets cheaper.

---

## Results

Benchmarked across 80+ prompts (5 complexity levels) on a real-world full-stack app.

| Metric | Without ContextKit | With ContextKit |
|--------|-------------------|-----------------|
| Avg cost per prompt | $0.46 | **$0.27** |
| Avg turns | 16.8 | **10.3** |
| Avg response time | 186s | **134s** |
| Quality (regex scorer) | 82.7/100 | **87.1/100** |

Cost wins on **16 out of 20** prompts. Quality equal or better on all complexity levels.

---

## Install

Full setup guide at [contextkit.dev/setup](https://contextkit.dev/setup).

**macOS / Linux:**
```bash
curl -sSL https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/install.sh | bash
source ~/.zshrc   # or ~/.bashrc / ~/.profile
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/install.ps1 | iex
```

**Windows (Scoop):**
```powershell
scoop bucket add contextkit https://github.com/Ruchitha1608/scoop-contextkit
scoop install contextkit
```

**Prerequisites:** Python 3.10+, Node.js 18+, Claude Code or Codex CLI. The installer detects missing tools and offers to install them via winget (Windows) or homebrew (macOS).

---

## Usage

> **⚠️ Important:** Always use `ckc` (not `claude` directly) to ensure the MCP server is running. Running `claude` alone will result in "MCP Server Connection Failed" errors.

### Claude Code (`ckc`)

```bash
ckc                              # scan current directory, launch Claude
ckc /path/to/project             # scan a specific project
ckc /path/to/project "fix the login bug"   # start with a prompt
```

### Codex CLI (`ck`)

```bash
ck                               # scan current directory, launch Codex
ck /path/to/project              # scan a specific project
ck /path/to/project "add tests"  # start with a prompt
```

### Other AI Assistants (`contextkit`)

You can also use the `contextkit` command directly with any supported assistant:

```bash
contextkit .                      # current directory, default (Claude)
contextkit . --cursor             # Cursor
contextkit . --gemini             # Gemini CLI
contextkit . --opencode           # OpenCode
contextkit . --copilot            # GitHub Copilot
contextkit . --codex              # Codex CLI
contextkit /path/to/project --cursor           # specific project
contextkit /path/to/project --gemini "add tests"  # with a prompt
```

Or via the `ckc` / `ck` aliases with an assistant flag:

```bash
ckc --gemini /path/to/project    # Gemini CLI
ckc --cursor /path/to/project    # Cursor
ckc --opencode /path/to/project  # OpenCode
ckc --copilot /path/to/project   # GitHub Copilot
```

Typo detection is built in — `--claud` or `--gemi` will suggest the correct flag instead of silently failing.

### Windows

```powershell
ckc .                            # from inside the project directory
ckc "D:\projects\my-app"         # any drive, any path
ck "C:\work\backend"             # Codex CLI
ckc --gemini "D:\projects\app"   # Gemini CLI on Windows
```

---

## What It Does Under the Hood

1. **Scans your project** — extracts files, functions, classes, import relationships into a local graph. Supports TS/JS, Python, Go, Swift, Rust, Java, Kotlin, C#, Ruby, and PHP.
2. **Pre-loads context** — when you ask a question, the graph ranks relevant files and packs them into the prompt before Claude sees it. No extra tool calls needed.
3. **Remembers across turns** — files you've read or edited are prioritized in future turns. Context compounds.
4. **MCP tools available** — Claude can still explore the codebase via graph-aware tools (`graph_read`, `graph_retrieve`, `graph_neighbors`, etc.) when it needs to go deeper.

All processing is local. No code leaves your machine.

---

## Data & Files

All data lives in `<project>/.contextkit/` (gitignored automatically).

| File | Description |
|---|---|
| `info_graph.json` | Semantic graph of the project: files, symbols, edges |
| `chat_action_graph.json` | Session memory: reads, edits, queries, decisions |
| `context-store.json` | Persistent store for decisions/tasks/facts across sessions |
| `mcp_server.log` | MCP server logs |

Global files in `~/.contextkit/`:
| File | Description |
|---|---|
| `ckc.ps1` / `ck.ps1` | Launcher scripts (auto-updated) |
| `venv/` | Python virtual environment for dependencies |
| `version.txt` | Current installed version |

---

## Configuration

All optional, via environment variables:

| Variable | Default | Description |
|---|---|---|
| `DG_HARD_MAX_READ_CHARS` | `4000` | Max characters per file read |
| `DG_TURN_READ_BUDGET_CHARS` | `18000` | Total read budget per turn |
| `DG_FALLBACK_MAX_CALLS_PER_TURN` | `1` | Max fallback grep calls per turn |
| `DG_RETRIEVE_CACHE_TTL_SEC` | `900` | Retrieval cache TTL (15 min) |
| `DG_MCP_PORT` | auto (8080-8099) | Force a specific MCP server port |

---

## Context Store

Decisions, tasks, and facts from your sessions are persisted in `.contextkit/context-store.json` and re-injected at the start of the next session. This gives Claude continuity across conversations.

You can also create a `CONTEXT.md` in your project root for free-form session notes.

---

## Token Tracking

A token-counter dashboard is registered automatically with Claude Code:

```
http://localhost:8899
```

Usage from inside a Claude session:
```
count_tokens({text: "<content>"})   # estimate tokens before reading
get_session_stats()                  # running session cost
```

---

## Self-Update

The launcher checks for updates on every run and auto-updates if a new version is available. No manual intervention needed.

Current version: **3.9.91**

---

## Troubleshooting

### "MCP Server Connection Failed" or "HTTP 404: Not Found"

**Cause:** The contextkit MCP server isn't running. This happens when running `claude` directly instead of through `ckc`.

**Solution:** Always use `ckc` instead of `claude`:

```bash
# ContextKit — contextkit CLI | ❌ Don't run:
claude

# ContextKit — contextkit CLI | ✅ Run this:
ckc
ckc /path/to/project
```

The `ckc` launcher automatically starts the MCP server and registers it with Claude Code.

**If the error persists:**

1. **Clean up stale configs:**
   ```bash
   claude mcp remove contextkit
   claude mcp remove token-counter --scope user
   ```

2. **Run ckc again** (it will re-register automatically):
   ```bash
   ckc
   ```

3. **Check if the server started:**
   ```bash
   # Verify MCP server is running:
   lsof -i :8080-8099 | grep python
   
   # Check logs:
   cat .contextkit/run/claude/mcp_server.log
   ```

4. **Fresh install** (if nothing else works):
   ```bash
   rm -rf ~/.contextkit
   claude mcp remove contextkit 2>/dev/null
   curl -sSL https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/install.sh | bash
   source ~/.zshrc  # or ~/.bashrc
   ```

### MCP Server Won't Start

**Check the logs:**
```bash
cat .contextkit/run/claude/mcp_server.log
```

**Common issues:**
- **Port already in use:** Set a custom port with `DG_MCP_PORT=8090 ckc`
- **Python dependencies missing:** Re-run installer or `pip install contextkit mcp uvicorn --upgrade`
- **Permission errors:** Check file permissions in `.contextkit/`

### Session-Specific Issues

**Resume not working?** The MCP server is session-based — it stops when you exit. To resume with contextkit:
```bash
ckc --resume <session-id>
```

**Context not persisting?** Check if `.contextkit/context-store.json` exists and is writable.

---

## Privacy & Security

- **All project data stays local.** Graphs, session data, and code never leave your machine.
- The only outbound calls are:
  - **Version check** — fetches a version string (no project data).
  - **Heartbeat** — sends a random install ID and `platform` only. No hardware fingerprinting, no file names, no code.
  - **One-time feedback** — optional rating after first day of use.
- `.contextkit/` is automatically added to `.gitignore`.

---

## Uninstall

**macOS / Linux:**
```bash
rm -rf ~/.contextkit
sed -i.bak '/\.contextkit/d' ~/.zshrc ~/.bashrc 2>/dev/null
rm -rf .contextkit .claude/settings.local.json
claude mcp remove token-counter --scope user 2>/dev/null
claude mcp remove contextkit 2>/dev/null
rm -rf ~/.claude/token-counter
rm -f ~/.claude/token-counter-stop.sh
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE.contextkit" -Recurse -Force -ErrorAction SilentlyContinue
$p = [Environment]::GetEnvironmentVariable("PATH","User") -split ";" | Where-Object { $_ -notlike "*\.contextkit*" }
[Environment]::SetEnvironmentVariable("PATH", ($p -join ";"), "User")
Remove-Item ".contextkit" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".claude\settings.local.json" -Force -ErrorAction SilentlyContinue
claude mcp remove token-counter --scope user 2>$null
claude mcp remove contextkit 2>$null
Remove-Item "$env:USERPROFILE\.claude\token-counter" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\.claude\token-counter-stop.ps1" -Force -ErrorAction SilentlyContinue
```

> The PATH/project commands remove the global install. Run the project-local commands inside each project you used contextkit with.

---

## Contributing

PRs are welcome — bug fixes, new AI assistant support, install improvements, docs.

**Note:** The graph engine (`contextkit`) is a separate proprietary component distributed via PyPI. The core graph intelligence is not open source. See [contextkit.dev/pro](https://contextkit.dev/pro) for Pro features.

---

## Community

Have a question, found a bug, or want to share feedback?

**[Open an issue or discussion on GitHub](https://github.com/Ruchitha1608/Context-Code/issues)**

- Get help with setup
- Report bugs
- Share workflows
- Follow releases

---

## Star History

<a href="https://www.star-history.com/?repos=Ruchitha1608%2FContext-Code&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=Ruchitha1608/Context-Code&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=Ruchitha1608/Context-Code&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=Ruchitha1608/Context-Code&type=date&legend=top-left" />
 </picture>
</a>

---

## License

All rights reserved. Unauthorized use, reproduction, or distribution is prohibited.
