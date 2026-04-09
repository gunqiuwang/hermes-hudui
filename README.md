# ☤ Hermes HUD — Web UI

A browser-based consciousness monitor for [Hermes](https://github.com/nousresearch/hermes-agent), the AI agent with persistent memory.

Same data, same soul, same dashboard that made the [TUI version](https://github.com/joeynyc/hermes-hud) popular — now in your browser.


## What It Shows

Everything your agent knows about itself:

- **Identity** — designation, substrate, runtime, days conscious, brain size
- **What I Know** — conversations held, messages exchanged, actions taken, skills acquired
- **What I Remember** — memory capacity bars, user profile state, corrections absorbed
- **What I See** — API keys (present/dark), service health (alive/silent)
- **What I'm Learning** — recently modified skills with categories
- **What I'm Working On** — active projects with dirty file status
- **What Runs While You Sleep** — scheduled cron jobs
- **How I Think** — tool usage patterns with gradient bars
- **My Rhythm** — daily activity sparkline
- **Growth Delta** — snapshot diffs showing what changed
- **Token Costs** — per-model USD cost estimates with daily trend

## Quick Start

```bash
git clone https://github.com/joeynyc/hermes-hudui.git
cd hermes-hudui
python3.11 -m venv venv
source venv/bin/activate
./install.sh
hermes-hudui
```

Open http://localhost:3001

On future runs, just activate and start:

```bash
source venv/bin/activate
hermes-hudui
```

## Requirements

- Python 3.11+
- Node.js 18+ (for building the frontend)
- A running Hermes agent with data in `~/.hermes/`

No other packages required — the Web UI reads directly from your agent's data directory.

## Manual Install

```bash
# 1. Create and activate virtual environment
python3.11 -m venv venv
source venv/bin/activate

# 2. Install this package
pip install -e .

# 3. Build the frontend
cd frontend
npm install
npm run build
cp -r dist/* ../backend/static/

# 4. Start the server
hermes-hudui
```

## CLI Options

```
hermes-hudui                  # Start on :3001
hermes-hudui --port 8080      # Custom port
hermes-hudui --dev            # Development mode (auto-reload)
hermes-hudui --hermes-dir /path  # Custom data directory
```

## Development

Two terminals:

```bash
# Terminal 1: backend with auto-reload
hermes-hudui --dev

# Terminal 2: frontend dev server (hot reload, proxies /api to :3001)
cd frontend && npm run dev
```

Frontend dev server runs on :5173.

## Themes

Four color themes, switchable with `t` key or the theme picker:

| Theme | Key | Mood |
|-------|-----|------|
| **Neural Awakening** | `ai` | Cyan/blue on deep navy. Clean, clinical intelligence. |
| **Blade Runner** | `blade-runner` | Amber/orange on warm black. Neo-noir dystopia. |
| **fsociety** | `fsociety` | Green on pure black. Raw hacker aesthetic. |
| **Anime** | `anime` | Purple/violet on indigo. Psychic energy. |

Optional CRT scanline overlay — toggle via theme picker.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `1`-`9`, `0` | Switch tabs |
| `t` | Toggle theme picker |
| `r` | Refresh all data |
| `Ctrl+K` | Command palette |

## Architecture

```
React Frontend (Vite + SWR)
    ↓ /api/* (proxied in dev)
FastAPI Backend (Python)
    ↓ collectors/*.py
~/.hermes/ (agent data files)
```

Backend collectors read directly from `~/.hermes/` and return dataclasses. The frontend fetches from `/api/*` endpoints via SWR with auto-refresh and renders one panel component per tab.

## Themes as CSS Variables

Each theme is 10 CSS custom properties. To add a new theme:

```css
[data-theme="my-theme"] {
  --hud-bg-deep: #000;
  --hud-bg-surface: #080808;
  --hud-bg-panel: #101010;
  --hud-bg-hover: #181818;
  --hud-primary: #ff6600;
  --hud-primary-dim: #cc5200;
  --hud-primary-glow: rgba(255, 102, 0, 0.4);
  --hud-secondary: #ffaa00;
  --hud-accent: #ff3300;
  --hud-text: #e0e0e0;
  --hud-text-dim: #666;
  --hud-border: rgba(255, 102, 0, 0.25);
  --hud-border-bright: rgba(255, 102, 0, 0.5);
  --hud-success: #00ff66;
  --hud-warning: #ffcc00;
  --hud-error: #ff3333;
  --hud-gradient-start: #cc5200;
  --hud-gradient-end: #ff6600;
}
```

## Relationship to the TUI

This is the browser companion to [hermes-hud](https://github.com/joeynyc/hermes-hud). Both read from the same `~/.hermes/` data directory independently. You can use either one, or both at the same time.

The Web UI is fully standalone — it ships its own data collectors and doesn't require the TUI package. It adds features the TUI doesn't have: dedicated Memory, Skills, and Sessions tabs; per-model token cost tracking; command palette; theme switcher with live preview.

If you also have the TUI installed (`pip install hermes-hud`), you can enable it with `pip install hermes-hudui[tui]`.

## Platform Support

- **macOS** — native, install via `./install.sh`
- **Linux** — native, install via `./install.sh`
- **Windows** — via WSL (Windows Subsystem for Linux)
- **WSL** — install script detects WSL automatically

## License

MIT — see [LICENSE](LICENSE).
