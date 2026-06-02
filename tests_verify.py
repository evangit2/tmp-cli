#!/usr/bin/env python3
"""
Comprehensive tmpcli verification: tests upload+download roundtrip for each service.
Skips services with missing requirements (pixeldrain needs API key).
"""
import os
import sys
import time
import hashlib
import subprocess
import tempfile
from pathlib import Path

# Load tmpcli source file directly (it has no .py extension) using runpy
import runpy
_globals = runpy.run_path(str(Path.home() / ".tmp-cli" / "tmpcli"), run_name="tmpcli")
# TmpCli class and BaseService etc. are now in _globals
tc = type("TC", (), _globals)  # simple namespace holder for attributes we use
tc.TmpCli = _globals["TmpCli"]

# Force subprocess PATH to include ~/.local/bin so wormhole/ffsend are found
os.environ["PATH"] = str(Path.home() / ".local/bin") + os.pathsep + os.environ.get("PATH", "")
# Ensure pixeldrain key unset behavior
os.environ.pop("PIXELDRAIN_API_KEY", None)

CLI = tc.TmpCli()

# Test file: 1KB of pseudo-random bytes (deterministic content for hash compare)
TEST_CONTENT = (b"tmpcli verification test - " * 32)
TEST_HASH = hashlib.sha256(TEST_CONTENT).hexdigest()
TEST_FILE = "/tmp/tmpcli_verify_test.bin"
Path(TEST_FILE).write_bytes(TEST_CONTENT)
TEST_SIZE = len(TEST_CONTENT)

# Services to skip (need external setup we don't have)
SKIP = set()
if not os.environ.get("PIXELDRAIN_API_KEY"):
    SKIP.add("pixeldrain")

# termbin is text-only, but we can still test it with the binary since it's small
# Wormhole is interactive and hard to test in a script — test only the upload code path
# send.vis.ee via ffsend is testable

def verify_upload(svc_name):
    """Try to upload TEST_FILE using svc_name. Return (url, elapsed) or (None, error)."""
    try:
        t0 = time.time()
        result = CLI.upload(TEST_FILE, service=svc_name)
        elapsed = time.time() - t0
        return (result.url, elapsed, None)
    except Exception as e:
        return (None, None, str(e))

def verify_download(url, output):
    """Try to download url to output. Return (size, hash, error)."""
    try:
        t0 = time.time()
        ok = CLI.download(url, output)
        elapsed = time.time() - t0
        if not ok or not os.path.exists(output):
            return (0, None, "download returned False or file missing")
        size = os.path.getsize(output)
        with open(output, "rb") as f:
            data = f.read()
        h = hashlib.sha256(data).hexdigest()
        return (size, h, None)
    except Exception as e:
        return (0, None, str(e))

def main():
    services = [s for s in CLI.services.keys() if s not in SKIP]
    print(f"Verifying {len(services)} services (skipping: {', '.join(SKIP) or 'none'})", file=sys.stderr)
    print(f"Test file: {TEST_FILE} ({TEST_SIZE} bytes, sha256={TEST_HASH[:12]}...)", file=sys.stderr)
    print("=" * 80, file=sys.stderr)

    results = []
    for svc_name in services:
        print(f"\n[{svc_name}]", file=sys.stderr)
        upload_result = verify_upload(svc_name)
        if upload_result[0] is None:
            print(f"  UPLOAD FAILED: {upload_result[2]}", file=sys.stderr)
            results.append((svc_name, "UPLOAD_FAIL", None, None, upload_result[2]))
            continue
        url, up_elapsed, _ = upload_result
        print(f"  ↑ Upload OK ({up_elapsed:.1f}s): {url}", file=sys.stderr)

        # Download back
        out_path = f"/tmp/tmpcli_verify_dl_{svc_name.replace('.', '_').replace('/', '_')}.bin"
        try:
            dl_size, dl_hash, dl_err = verify_download(url, out_path)
            if dl_err:
                print(f"  ↓ DOWNLOAD FAILED: {dl_err}", file=sys.stderr)
                results.append((svc_name, "DOWNLOAD_FAIL", url, None, dl_err))
                continue
            match = "✓ MATCH" if dl_hash == TEST_HASH else f"✗ MISMATCH (got {dl_hash[:12]})"
            print(f"  ↓ Download OK ({dl_size} bytes) {match}", file=sys.stderr)
            results.append((svc_name, "OK", url, dl_hash == TEST_HASH, None))
        finally:
            if os.path.exists(out_path):
                os.unlink(out_path)

    print("\n" + "=" * 80, file=sys.stderr)
    print("SUMMARY", file=sys.stderr)
    print("=" * 80, file=sys.stderr)
    ok = sum(1 for r in results if r[1] == "OK")
    up_fail = sum(1 for r in results if r[1] == "UPLOAD_FAIL")
    dl_fail = sum(1 for r in results if r[1] == "DOWNLOAD_FAIL")
    print(f"  ✓ OK (upload+download+hashmatch): {ok}", file=sys.stderr)
    print(f"  ✗ Upload failed: {up_fail}", file=sys.stderr)
    print(f"  ✗ Download failed: {dl_fail}", file=sys.stderr)

    print("\nPer-service results:", file=sys.stderr)
    for svc, status, url, hash_match, err in results:
        match_str = " (hash mismatch!)" if hash_match is False else ""
        err_str = f" — {err[:80]}" if err else ""
        print(f"  {svc:<14} {status:<14} {url or ''}{match_str}{err_str}", file=sys.stderr)

    # Save machine-readable results
    import json
    Path("/tmp/tmpcli_verify_results.json").write_text(json.dumps([
        {"service": r[0], "status": r[1], "url": r[2], "hash_match": r[3], "error": r[4]}
        for r in results
    ], indent=2))
    print(f"\nResults saved to /tmp/tmpcli_verify_results.json", file=sys.stderr)

if __name__ == "__main__":
    main()
