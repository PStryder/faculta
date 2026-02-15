# Faculta

> *From Latin **facultas** — capability, power, the capacity to act. The agent's faculties, unified.*

**The agent capability triad for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).**

Three MCP servers that give Claude Code a complete event-driven inner life: the will to act, the awareness to perceive, and the agency to command.

| Server | Role | What It Does |
|--------|------|-------------|
| [**Velle**](https://github.com/PStryder/Velle) | Volition | Self-prompting via Win32 console injection. The agent decides what to do next and gives itself a new turn. |
| [**Expergis**](https://github.com/PStryder/expergis) | Perception | Plugin-based event watching. Detects file changes, cron schedules, and process events, then wakes the agent. |
| [**Arbitrium**](https://github.com/PStryder/arbitrium) | Agency | Persistent shell sessions. Full state persistence (env vars, cwd, aliases) across tool calls with complete output capture. |

## Architecture

```
                         Claude Code
                             |
              +--------------+--------------+
              |              |              |
           Velle         Expergis       Arbitrium
         (volition)    (perception)     (agency)
              |              |              |
         Self-prompt    Event watch    Shell session
              |              |              |
              +-------> Velle HTTP <--------+
                         Sidecar
                        :7839
                           |
                     Win32 Console
                       Injection
                           |
                      Agent wakes up
```

**Velle** is the hub. It owns the injection pipeline (Win32 `WriteConsoleInputW`) and exposes an HTTP sidecar on `127.0.0.1:7839`. Expergis dispatches detected events through this sidecar. Arbitrium operates independently as a persistent shell layer.

## Quick Setup

### Prerequisites

- Python 3.10+
- [uv](https://docs.astral.sh/uv/) (Python package manager)
- Windows (Velle uses Win32 console injection; Expergis and Arbitrium are cross-platform)

### One-Command Install

```bash
git clone https://github.com/PStryder/faculta.git
cd faculta
./setup.sh
```

This will:
1. Clone all three repositories
2. Install dependencies with `uv sync`
3. Print the MCP config to add to Claude Code

### Manual Install

```bash
# Clone each project
git clone https://github.com/PStryder/Velle.git
git clone https://github.com/PStryder/expergis.git
git clone https://github.com/PStryder/arbitrium.git

# Install dependencies
cd Velle && uv sync && cd ..
cd expergis && uv sync && cd ..
cd arbitrium && uv sync && cd ..
```

Then register the MCP servers with Claude Code:

```bash
claude mcp add -s user velle -- /path/to/Velle/.venv/Scripts/python -m velle.server
claude mcp add -s user expergis -- /path/to/expergis/.venv/Scripts/python -m expergis.server
claude mcp add -s user arbitrium -- /path/to/arbitrium/.venv/Scripts/python -m arbitrium.server
```

## Configuration

### Velle — `velle.json`

```json
{
  "turn_limit": 20,
  "cooldown_ms": 1000,
  "budget_usd": 5.00,
  "audit_mode": "both",
  "sidecar_enabled": true,
  "sidecar_port": 7839
}
```

### Expergis — `expergis.json`

```json
{
  "velle_endpoint": "http://127.0.0.1:7839/velle_prompt",
  "rate_limit": {
    "min_interval_ms": 5000,
    "max_events_per_minute": 6,
    "burst_size": 2
  },
  "dedup_window_ms": 10000,
  "watchers": []
}
```

### Arbitrium

No config file needed. Sessions are created at runtime via MCP tools. Logs write to `./logs/`.

## MCP Tools Reference

### Velle (2 tools)
| Tool | Description |
|------|-------------|
| `velle_prompt` | Inject text as user input into the Claude Code session |
| `velle_status` | Check session state: turn count, limits, console availability |

### Expergis (4 tools)
| Tool | Description |
|------|-------------|
| `expergis_watch` | Register a watcher (file, schedule, or process) |
| `expergis_unwatch` | Remove a watcher by ID |
| `expergis_list` | List active watchers with stats |
| `expergis_check` | Poll recent events from the ring buffer |

### Arbitrium (4 tools)
| Tool | Description |
|------|-------------|
| `arbitrium_spawn` | Open a persistent shell session (auto-detects best shell) |
| `arbitrium_exec` | Execute a command and return full output + exit code |
| `arbitrium_list` | List active sessions |
| `arbitrium_close` | Close a session |

## Verification

After setup, verify the full event loop:

```
1. Start Claude Code with all three servers
2. Call expergis_watch on a test directory
3. Modify a file in that directory
4. Confirm: Expergis detects -> Velle sidecar -> agent wakes up
5. Call arbitrium_spawn, then arbitrium_exec to test shell persistence
```

## Security

- **Velle**: Injects keystrokes into the Claude Code console. Guarded by turn limits, cooldown, and audit logging.
- **Expergis**: Watches for events and dispatches to Velle. Rate-limited with dedup. All events audited to JSONL.
- **Arbitrium**: Unrestricted shell access at the user's permission level. All commands and output logged to `./logs/`.

## License

[Apache 2.0](LICENSE)

Each component is independently licensed under Apache 2.0.
