#!/usr/bin/env bash
# Hermes HUD Web UI — installer
# Works on macOS, Linux, and Windows (WSL)
set -e

echo "☤ Hermes HUD Web UI — Install"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect platform
PLATFORM="$(uname -s)"
case "$PLATFORM" in
    Darwin*)  OS="macos";;
    Linux*)   OS="linux";;
    *)        echo "✗ Unsupported platform: $PLATFORM"; exit 1;;
esac
echo "✔ Platform: $OS"

# Check Python (3.11+)
PYTHON=""
for cmd in python3.12 python3.11 python3.13 python3; do
    if command -v "$cmd" &>/dev/null; then
        version=$("$cmd" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null) || continue
        major=$(echo "$version" | cut -d. -f1)
        minor=$(echo "$version" | cut -d. -f2)
        if [ "$major" -ge 3 ] && [ "$minor" -ge 11 ]; then
            PYTHON="$cmd"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    echo "✗ Python 3.11+ required"
    if [ "$OS" = "macos" ]; then
        echo "  Install: brew install python@3.12"
    else
        echo "  Install: sudo apt install python3.11 python3.11-venv"
    fi
    exit 1
fi
echo "✔ Python: $($PYTHON --version)"

# Check Node.js (18+)
if ! command -v node &>/dev/null; then
    echo "✗ Node.js 18+ required"
    if [ "$OS" = "macos" ]; then
        echo "  Install: brew install node"
    else
        echo "  Install: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs"
    fi
    exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "✗ Node.js 18+ required (found v$NODE_VERSION)"
    exit 1
fi
echo "✔ Node: $(node -version)"

# Check npm
if ! command -v npm &>/dev/null; then
    echo "✗ npm required but not found (install Node.js)"
    exit 1
fi

# Install hermes-hud (data collectors)
if ! $PYTHON -c "import hermes_hud" 2>/dev/null; then
    echo "→ Installing hermes-hud (data collectors)..."
    if [ -d "../hermes-hud" ]; then
        $PYTHON -m pip install -e ../hermes-hud -q
    else
        $PYTHON -m pip install hermes-hud -q
    fi
fi
echo "✔ hermes-hud installed"

# Install this package
echo "→ Installing hermes-hudui..."
$PYTHON -m pip install -e . -q
echo "✔ Backend installed"

# Build frontend
echo "→ Building frontend..."
cd frontend
npm install --silent 2>/dev/null
npm run build 2>/dev/null
cd ..

# Copy to static
echo "→ Deploying frontend..."
mkdir -p backend/static/assets
cp frontend/dist/index.html backend/static/
cp frontend/dist/assets/* backend/static/assets/
echo "✔ Frontend built and deployed"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✔ Ready. Run:"
echo ""
echo "  hermes-hudui"
echo ""
echo "  Then open http://localhost:3001"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
