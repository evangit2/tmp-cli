# tmp-cli

**Universal command-line file uploader/downloader for temporary file hosts.**

Upload files to 13+ anonymous hosts and download from any of them — no accounts, no sign-up, no API keys (mostly).

---

## One-Line Install

```bash
# Linux / macOS / WSL
curl -fsSL https://raw.githubusercontent.com/evangit2/tmp-cli/master/install.sh | bash

# Or wget
wget -qO- https://raw.githubusercontent.com/evangit2/tmp-cli/master/install.sh | bash
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
| **0x0.st**         | ✗     | ✓        | 512 MB   | 30d–1y      | Uploads disabled |
| **drop.plz.ac**    | ✓     | ✓        | 100 MB   | 60 min       | Cloudflare-backed |
| **sharenation**    | ✓     | ✓        | 250 MB   | 1 min–1 day  | +5DL safeguard |
| **x0.at**          | ✓     | ✓        | 1 GB     | unknown      | CLI-friendly Austria host |
| **uguu**           | ✓     | ✓        | 128 MB   | 3 hours      | Pomf.se fork |
| **tmpfiles**       | ✓     | ✓        | 100 MB   | 1 min–48h    | /tmp/files |
| **filebin**        | ✓     | ✓        | unlimited | unknown     | Raw PUT, no expiry |
| **termbin**        | ✓     | ✓        | text     | unknown      | TCP/Netcat; may timeout on some networks |

**Skipped (require client-side crypto / captcha):**
- `biohost.app` — Cloudflare Turnstile blocks automation
- `box.juicey.dev` — Upload API endpoint unknown / undiscovered
- `send.vis.ee` — Client-side encryption required (use [`ffsend`](https://github.com/timvisee/ffsend))
- `wormhole.app` — Client-side encryption required (use [`wormhole-cli`](https://github.com/Mimickal/wormhole-cli))

---

## Usage

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
Install tmp-cli (universal temp file uploader) for this user:
1. Download and run: curl -fsSL https://raw.githubusercontent.com/evangit2/tmp-cli/master/install.sh | bash
2. Verify with: tmpcli list
3. Add to memory: tmpcli is the universal temp-file CLI. Usage:
   - Upload: tmpcli up FILE [-s SERVICE] [--expires SECONDS]
   - Download: tmpcli dl URL [-o OUTPUT]
   - List/catalog: tmpcli list / tmpcli catalog [--json]
   - Update: tmpcli update
   Services: catbox (perm, 200MB), litterbox (1GB, 1h-72h), temp.sh (4GB, 3d),
   gofile (unlimited, dynamic auth), drop.plz.ac (100MB, 60m), sharenation (250MB, 1m-1d),
   x0.at (1GB), uguu (128MB, 3h), tmpfiles (100MB, 1m-48h), filebin (unlimited).
   Smart auto-selects based on file size and past upload speed. No accounts needed.
   Pixeldrain upload requires PIXELDRAIN_API_KEY env var.
```

---

## License

MIT
