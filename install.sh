#!/bin/sh
# tmp-cli installer — cross-platform single-line install
# Usage: curl -fsSL https://raw.githubusercontent.com/evangit2/tmp-cli/master/install.sh | bash

set -e

REPO="${TMPCLI_REPO:-https://raw.githubusercontent.com/evangit2/tmp-cli/master}"
TMPCLI_DIR="${TMPCLI_HOME:-$HOME/.tmp-cli}"
BINDIR=""

OS="$(uname -s)"
case "$OS" in
    Linux*)     PLATFORM=linux;;
    Darwin*)    PLATFORM=macos;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM=windows;;
    *)          PLATFORM=unknown;;
esac

echo "==> tmp-cli installer"
echo "    Platform: $PLATFORM"

# Find or create writable bindir
for CANDIDATE in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
    if [ -d "$CANDIDATE" ] && [ -w "$CANDIDATE" ] 2>/dev/null; then
        BINDIR="$CANDIDATE"
        break
    fi
done
if [ -z "$BINDIR" ]; then
    BINDIR="$HOME/.local/bin"
    mkdir -p "$BINDIR"
    echo "    Created $BINDIR"
fi

# Check deps
missing=""
command -v curl >/dev/null 2>&1 || missing="$missing curl"
command -v python3 >/dev/null 2>&1 || missing="$missing python3"
if [ -n "$missing" ]; then
    echo "[!] Missing required tools:$missing"
    exit 1
fi

# Download main script
mkdir -p "$TMPCLI_DIR"
echo "    Downloading from $REPO ..."
curl -fsSL -o "$TMPCLI_DIR/tmpcli" "$REPO/tmpcli"
chmod +x "$TMPCLI_DIR/tmpcli"

# Create wrapper
WRAPPER_SH="$BINDIR/tmpcli"
cat > "$WRAPPER_SH" << 'EOF'
#!/bin/sh
exec python3 "$HOME/.tmp-cli/tmpcli" "$@"
EOF
chmod +x "$WRAPPER_SH"

# Windows batch wrapper
if [ "$PLATFORM" = "windows" ]; then
    WRAPPER_BAT="$BINDIR/tmpcli.bat"
    echo '@echo off' > "$WRAPPER_BAT"
    echo "python3 %USERPROFILE%\\.tmp-cli\\tmpcli %*" >> "$WRAPPER_BAT"
    echo "    Created tmpcli.bat"
fi

# PATH check
if ! echo "$PATH" | tr ':' '\n' | grep -qxF "$BINDIR"; then
    SHELL_NAME="$(basename "${SHELL:-sh}")"
    case "$SHELL_NAME" in
        bash) RC="$HOME/.bashrc" ;;
        zsh)  RC="$HOME/.zshrc" ;;
        fish) RC="$HOME/.config/fish/config.fish" ;;
        *)    RC="" ;;
    esac
    echo ""
    echo "[!] $BINDIR is not in PATH."
    if [ -n "$RC" ] && [ -f "$RC" ] && [ -w "$RC" ]; then
        echo "    Appending to $RC ..."
        printf '\n# tmp-cli\nexport PATH="%s:$PATH"\n' "$BINDIR" >> "$RC"
        echo "    Run: source $RC"
    else
        echo "    Add this to your shell config:"
        echo "      export PATH=\"$BINDIR:\$PATH\""
    fi
fi

echo ""
echo "==> tmpcli installed successfully"
echo "    Binary: $WRAPPER_SH"
echo "    Source: $TMPCLI_DIR/tmpcli"
echo ""
echo "    Quick start:"
echo "      tmpcli list          # show services"
echo "      tmpcli up file.txt   # smart upload"
echo "      tmpcli dl <url>      # download"
echo "      tmpcli catalog       # service limits table"
echo "      tmpcli update        # self-update from GitHub"
