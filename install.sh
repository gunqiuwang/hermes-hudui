#!/usr/bin/env bash
# Hermes HUD Web UI — installer
# Works on macOS, Linux, and Windows (WSL)
set -e

echo "🤖 Agent Dashboard — 安装"
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

# Check for agent data directory
AGENT_DIR="${AGENT_HOME:-$HOME/.hermes}"
if [ ! -d "$AGENT_DIR" ]; then
    echo ""
    echo "⚠ 未找到代理数据目录: $AGENT_DIR"
    echo "  仪表盘将为空，直到有代理运行。"
    echo "  选项："
    echo "    1. 先安装并运行代理"
    echo "    2. 设置 AGENT_HOME 为你的代理数据目录"
    echo ""
fi

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "→ Creating virtual environment..."
    $PYTHON -m venv venv
    echo "✔ Virtual environment created"
else
    echo "✔ Virtual environment exists"
fi

# Activate and install
echo "→ 安装 agent-dashboard..."
source venv/bin/activate
pip install -e . -q
echo "✔ 后端安装完成"

# Build frontend
echo "→ 构建前端..."
cd frontend
npm install --silent 2>/dev/null
npm run build 2>/dev/null
cd ..

# Copy to static
echo "→ 部署前端..."
mkdir -p backend/static/assets
cp frontend/dist/index.html backend/static/
cp frontend/dist/assets/* backend/static/assets/
echo "✔ 前端构建并部署完成"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✔ 安装完成。运行方式："
echo ""
echo "  source venv/bin/activate"
echo "  agent-dashboard"
echo ""
echo "  然后打开 http://localhost:3001"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
