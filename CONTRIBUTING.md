# Contributing to Hermes HUD Web UI

Thanks for your interest in contributing.

## Development Setup

```bash
git clone https://github.com/joeynyc/hermes-hudui.git
cd hermes-hudui

# Install backend
pip install hermes-hud
pip install -e .

# Install frontend
cd frontend
npm install

# Run dev servers (two terminals)
hermes-hudui --dev          # backend on :3001
cd frontend && npm run dev  # frontend on :5173 (proxies /api to :3001)
```

## Project Structure

```
backend/api/        One route file per data domain
frontend/src/components/  One panel per tab
frontend/src/hooks/       Theme system, SWR data fetching
frontend/src/lib/         Shared formatting utilities
```

## Key Patterns

- Backend imports hermes-hud collectors directly — never duplicate data logic
- Each frontend panel fetches its own endpoint via `useApi('/path')`
- Themes are CSS custom properties on `[data-theme]` attribute
- All time formatting goes through `src/lib/utils.ts`

## Adding a New Panel

1. Create `backend/api/my_feature.py` with a FastAPI router
2. Register it in `backend/main.py`
3. Create `frontend/src/components/MyPanel.tsx`
4. Add it to `App.tsx` TabContent switch + GRID_CLASS
5. Add a tab entry in `TopBar.tsx` TABS array

## Adding a New Theme

Add a `[data-theme="name"]` block in `frontend/src/index.css` with the 10 CSS variables, then add an entry in `frontend/src/hooks/useTheme.tsx` THEMES array.

## Code Style

- TypeScript with `any` for API data (we don't own the schema)
- Tailwind utility classes for layout, CSS variables for theme colors
- Panel titles are uppercase, 11px, with glow text-shadow
- Monospace everywhere (JetBrains Mono)

## Pull Requests

- One feature per PR
- Include screenshots for UI changes
- Make sure `npm run build` passes with no errors
- Test on at least one theme

## Questions

Open an issue or reach out.
