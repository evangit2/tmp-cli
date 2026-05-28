# tmp-cli

**Universal command-line file uploader/downloader for temporary file hosts.**

Upload files to catbox, litterbox, temp.sh, gofile, and download from any of them — all without accounts.

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

## Supported Services

| Service     | Upload  | Download | Max Size | Expiry     | Notes                |
|-------------|---------|----------|----------|------------|----------------------|
| **catbox**      | ✓       | ✓        | 200 MB   | permanent  | Most reliable        |
| **litterbox**   | ✓       | ✓        | 1 GB     | 1h–72h     | Catbox temp sister   |
| **temp.sh**     | ✓       | ✓        | 4 GB     | 3 days     | Simple API           |
| **gofile**      | ✓       | ✓        | unlimited| variable   | Dynamic token auth   |
| **pixeldrain**  | 🔑 key  | ✓        | 10 GB    | 60 days    | Pro/prepaid for anon |
| **0x0.st**      | ✗(down)| ✓        | 512 MB   | 30d–1y     | Uploads disabled ATM |

---

## Usage

```bash
# Upload (smart service selection)
tmp up file.txt

# Upload to specific service
tmp up file.txt -s catbox
tmp up file.txt -s litter -t 24h
tmp up file.txt -s temp.sh
tmp up file.txt -s gofile

# Download from any supported URL
tmp dl https://files.catbox.moe/abc.txt -o myfile.txt
tmp dl https://gofile.io/d/AbCdEf
tmp dl https://temp.sh/xyz/file.zip

# List services + performance stats
tmp list --perf
```

---

## Smart Routing

When you run `tmp up <file>` without `-s`:

1. **Filters** services by file size and anon capability
2. **Scores** by speed history + success rate
3. **Retries** with fallback services on failure
4. **Tracks** speed per service across sessions (stored in `~/.config/tmp-cli/perf.json`)

---

## For AI Agents / Scripts

`tmp` is designed for automation:

```bash
# Single-line upload, only print URL to stdout
URL=$(tmp up log.txt -s catbox)
# → https://files.catbox.moe/x7k9a2.txt

# Download
if tmp dl "$URL" -o output.bin; then
    echo "Got it"
fi
```

All progress info goes to **stderr**, so stdout is clean for piping.

---

## License

MIT
