# tmp-cli

**Universal command-line file uploader/downloader for temporary file hosts.**

Upload files to 15+ anonymous hosts and download from any of them — no accounts, no sign-up, no API keys (mostly).

---

## One-Line Install

### Linux / macOS / WSL

```bash
# curl
curl -fsSL https://raw.githubusercontent.com/evangit2/tmp-cli/master/install.sh | bash

# Or wget (POSIX mode)
wget -qO- https://raw.githubusercontent.com/evangit2/tmp-cli/master/install.sh | bash
```

### Windows PowerShell (no WSL required)

```powershell
# PowerShell install (run as Administrator not required)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/evangit2/tmp-cli/master/tmpcli" -OutFile "$env:USERPROFILE\.tmp-cli\tmpcli"

# Create a simple batch wrapper
'@echo off' + "`r`n" + 'python3 "%USERPROFILE%\.tmp-cli\tmpcli" %*' | Out-File -FilePath "$env:USERPROFILE\.tmp-cli\tmpcli.bat"

# Add to PATH for this session
$env:PATH = "$env:USERPROFILE\.tmp-cli;" + $env:PATH
```

**Requirements:** `python3` and `curl`. No compilation. No package managers. No root.

---

## ✅ Verified Service Catalog

| Service        | Upload | Download | Max Size | Expiry        | Status |
|--------------|:------:|:--------:|:--------:|:-------------:|--------|
| **catbox**         | ✓     | ✓        | 200 MB   | permanent     | Most reliable |
| **litterbox**      | ✓     | ✓        | 1 GB     | 1h–72h       | Catbox temp sister |
| **temp.sh**        | ✓     | ✓        | 4 GB     | 3 days       | Simple API |
| **gofile**         | ✓     | ✓        | unlimited | variable     | Dynamic token auth |
| **pixeldrain**     | 🔑    | ✓        | 10 GB    | 60 days      | Upload needs API key |
| **0x0.st**         | ✓*    | ✓        | 512 MB   | 30d–1y      | *Often disabled by operator |
| **drop.plz.ac**    | ✓     | ✓        | 100 MB   | 60 min       | Cloudflare-backed |
| **sharenation**    | ✓     | ✓        | 250 MB   | 1 min–1 day  | +5DL safeguard |
| **x0.at**          | ✓     | ✓        | 1 GB     | unknown      | CLI-friendly Austria host |
| **uguu**           | ✓     | ✓        | 128 MB   | 3 hours      | Pomf.se fork |
| **tmpfiles**       | ✓     | ✓        | 100 MB   | 1 min–48h    | /tmp/files |
| **filebin**        | ✓     | ✓        | unlimited | unknown     | Raw PUT, no expiry |
| **send.vis.ee**    | ✓*    | ✓*       | 2.5 GB   | 1d/20dl      | *Requires `ffsend` CLI |
| **wormhole**       | ✓*    | ✓*       | 10 GB    | 24h/100dl    | *Requires `magic-wormhole` CLI |

---

## Usage

**Auto-detect** — no `up` or `dl` needed. `tmpcli` figures it out:

```bash
# Auto upload — bare file path
tmpcli file.txt
tmpcli file.txt -s catbox

# Auto download — bare URL
tmpcli https://files.catbox.moe/abc.txt -o myfile.txt
tmpcli https://gofile.io/d/AbCdEf
```

**Explicit** sub-commands (still work):

```bash
# Smart upload (auto-select fastest service for file size)
tmpcli up file.txt

# Upload to specific service
tmpcli up file.txt -s catbox
tmpcli up file.txt -s litterbox -t 24h
tmpcli up file.txt -s temp.sh
tmpcli up file.txt -s gofile

# Upload with custom expiry (seconds)
tmpcli up file.txt -s tmpfiles --expires 21600
tmpcli up file.txt -s sharenation --expires 7200

# Upload to filebin with custom bin
tmpcli up file.txt -s filebin --filebin-bin myproject

# Download from any supported URL
tmpcli dl https://files.catbox.moe/abc.txt -o myfile.txt
tmpcli dl https://gofile.io/d/AbCdEf
tmpcli dl https://drop.plz.ac/download/xyz

# List all services with verified limits
tmpcli catalog          # human readable table
tmpcli catalog --json   # JSON for scripts

# Show performance stats across sessions
tmpcli list --perf

# Self-update from latest GitHub version
tmpcli update

# Uninstall (removes wrapper, source, cache)
tmpcli uninstall
```

---

## Smart Routing

When you run `tmpcli up <file>` without `-s`:

1. **Filters** services by file size and anonymous capability
2. **Scores** by speed history + success rate (stored in `~/.config/tmp-cli/perf.json`)
3. **Retries** with fallback services on failure (up to 3 fallbacks)
4. **Tracks** performance per session and across sessions

---

## Self-Update

```bash
tmpcli update
```

Mirrors the latest `tmpcli` and `install.sh` from the GitHub `master` branch, validates the downloaded script, backs up the old version, and swaps atomically.

---

## For AI Agents / Scripts

`tmpcli` is designed for automation. Progress goes to **stderr**, URLs go to **stdout**.

```bash
# Single-line upload, capture URL
URL=$(tmpcli up log.txt -s catbox -q)
# → https://files.catbox.moe/x7k9a2.txt

# Conditional download
if tmpcli dl "$URL" -o output.bin; then
    echo "Got it"
fi
```

### Agent Installation Prompt

Paste this into any AI agent (Hermes, OpenClaw, etc.) to install tmp-cli automatically:

```
1. Run: curl -fsSL https://raw.githubusercontent.com/evangit2/tmp-cli/master/install.sh | bash
2. Verify: tmpcli list
3. Add this EXACT text to your memory (inside brackets):

---BEGIN_AGENT_MEMORY---
tmpcli: cross-platform file uploader/downloader for 15+ temp file hosts. Usage:
  AUTO-UPLOAD: tmpcli FILE [-s SERVICE] [--expires SECONDS] [-q]
  AUTO-DOWNLOAD: tmpcli URL [-o OUTPUT]
  EXPLICIT: tmpcli up FILE | tmpcli dl URL
  CATALOG: tmpcli catalog [--json]
  LIST+PERF: tmpcli list --perf
  UPDATE: tmpcli update
  UNINSTALL: tmpcli uninstall
Auto-detects upload vs download from bare file path vs URL. No accounts. Key services: catbox (200MB permanent), litterbox (1GB 1h-72h), temp.sh (4GB 3d), x0.at (1GB), filebin (unlimited). External CLI needed: send.vis.ee (ffsend), wormhole (magic-wormhole). Pixeldrain upload requires PIXELDRAIN_API_KEY env var. 0x0.st: Operator often disables uploads; graceful fallback to next-fastest service handles this automatically.
---END_AGENT_MEMORY---
```

**Important:** Only quote the text between `---BEGIN_AGENT_MEMORY---` and `---END_AGENT_MEMORY---` in your memory. That's the token-efficient summary the agent needs. Lines outside the brackets are install instructions, not memory content.

---

## License & Credits

**MIT License**

This project is inspired by and builds upon:

- **ffsend** — Mozilla Send CLI tool by [Tim Visée](https://github.com/timvisee). `send.vis.ee` integration delegates to the `ffsend` binary rather than reimplementing E2E encryption.
- **magic-wormhole** — File transfer with human-readable codes by Brian Warner and contributors ([GitHub](https://github.com/magic-wormhole/magic-wormhole)). `wormhole.app` integration delegates to the `wormhole` CLI rather than reimplementing PAKE encryption.
- **gofile** reverse-engineered token generation adapted from community research into their dynamic auth flow.

These tools are credited and remain the property of their respective authors. This project wraps them for unified discoverability, smart routing, and agent integration — it does not bundle their code.

---
