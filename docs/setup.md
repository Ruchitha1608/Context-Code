# Setup Guide

## Install (one time)

```bash
curl -sSL https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/install.sh | bash
source ~/.zshrc
```

## Per project — Claude Code

```bash
dgc /path/to/your/project
# or from inside the project:
dgc .
```

## Per project — Codex CLI

```bash
dg /path/to/your/project
```

## Token Tracking

```bash
# Start the live dashboard
cd dashboard && python3 server.py
# Open: http://localhost:5000

# Save a session
dgc-bench --save "with-graph" /path/to/project

# Compare sessions
dgc-bench --compare with-graph without-graph
```

## Lock design intent (persists across sessions)

Call once inside Claude Code after first setup:

```
graph_confirm_decision({
  "key": "design_direction",
  "decision": "Your aesthetic direction here",
  "rationale": "Why this direction"
})
```
