# tmp-cli installer for Windows PowerShell / PowerShell Core
# Usage:
#   irm https://raw.githubusercontent.com/evangit2/tmp-cli/master/install.ps1 | iex
#   # or with custom repo / install dir:
#   $env:TMPCLI_REPO = "https://raw.githubusercontent.com/evangit2/tmp-cli/master"
#   $env:TMPCLI_HOME = "$HOME\.tmp-cli"
#   irm ... | iex

$ErrorActionPreference = 'Stop'

$REPO = if ($env:TMPCLI_REPO) { $env:TMPCLI_REPO } else { 'https://raw.githubusercontent.com/evangit2/tmp-cli/master' }
$TMPCLI_DIR = if ($env:TMPCLI_HOME) { $env:TMPCLI_HOME } else { Join-Path $HOME '.tmp-cli' }

# Pick a bindir: prefer user-local bin (no admin needed); fall back to a temp dir
# if even that is read-only. We accumulate candidates into a list, then walk it
# and pick the first one that exists-and-writable, or that we can create.
$BINDIR = $null
$bindirCandidates = @(
    (Join-Path $HOME 'bin'),
    (Join-Path $HOME '.local\bin')
)
# LOCALAPPDATA may be null on non-Windows; guard with ?
if ($env:LOCALAPPDATA) {
    $bindirCandidates += (Join-Path $env:LOCALAPPDATA 'tmp-cli\bin')
}
foreach ($candidate in $bindirCandidates) {
    if (Test-Path $candidate) {
        try {
            $tmp = Join-Path $candidate ('.write-test-' + [guid]::NewGuid().ToString('N'))
            [void](New-Item -ItemType File -Path $tmp -Force)
            Remove-Item $tmp -Force
            $BINDIR = $candidate
            break
        } catch { }
    }
}
if (-not $BINDIR) {
    # Try to create ~/.local/bin
    try {
        $candidate = Join-Path $HOME '.local\bin'
        New-Item -ItemType Directory -Path $candidate -Force | Out-Null
        $BINDIR = $candidate
    } catch {
        # Last resort: install alongside the script
        $BINDIR = $TMPCLI_DIR
    }
}

Write-Host "==> tmp-cli installer"
Write-Host "    Platform: windows (PowerShell $($PSVersionTable.PSVersion))"
Write-Host "    Install dir: $TMPCLI_DIR"
Write-Host "    Bin dir:     $BINDIR"

# Create install dir first so partial runs leave the right filesystem state
# (and so re-running after installing Python "just works")
if (-not (Test-Path $TMPCLI_DIR)) {
    New-Item -ItemType Directory -Path $TMPCLI_DIR -Force | Out-Null
}

# Check Python. On Windows 10/11, `python3` and `python` are often broken
# Microsoft Store "App Execution Aliases" that print "Python was not found"
# and exit non-zero even when no real Python is installed. The fix is to
# probe each candidate via `cmd /c <name> --version` and check the exit code:
#   - real Python exits 0 with stdout starting "Python 3.x.y"
#   - MS Store alias exits non-zero with stderr "Python was not found..."
#   - missing command exits 9009 ('not recognized')
# We probe with cmd /c (not directly via &) because the broken alias throws
# a non-terminating NativeCommandError in PowerShell that gets displayed to
# the user as a scary red error block. cmd /c cleanly captures it instead.
# Order: `py -3` first because the Python Launcher is the most reliable
# Windows entry point and bypasses the alias issue entirely.
# On non-Windows, we skip the cmd /c wrapper and just call each candidate
# directly (for installer self-tests on Linux/macOS dev machines).
$py = $null
$pyVer = $null
$isWin = $IsWindows -or ($env:OS -eq 'Windows_NT')
foreach ($name in @('py -3', 'python3', 'python', 'py')) {
    $exe = ($name -split ' ')[0]
    if ($isWin) {
        $probe = cmd /c "$name --version" 2>&1
        $code = $LASTEXITCODE
    } else {
        # On non-Windows, skip candidates that don't exist locally rather
        # than letting `&` throw a non-terminating error for each one.
        $which = Get-Command $exe -ErrorAction SilentlyContinue
        if (-not $which) { continue }
        $probe = & $exe --version 2>&1
        $code = $LASTEXITCODE
    }
    if ($code -eq 0 -and $probe -and (($probe -join "`n") -match 'Python 3')) {
        # 'py' stays as 'py' (launcher); 'py -3' has 2 words — keep just the first
        $py = $exe
        $pyVer = ($probe -join "`n").Trim()
        break
    }
}
if (-not $py) {
    Write-Host "[!] Python 3 is required but no working interpreter was found." -ForegroundColor Red
    Write-Host ""
    Write-Host "    On Windows 10/11, the 'python3' and 'python' commands often point"
    Write-Host "    to broken Microsoft Store placeholders. To fix this:"
    Write-Host ""
    Write-Host "    1. Install Python from https://python.org/downloads/  (check"
    Write-Host "       'Add Python to PATH' in the installer) — recommended"
    Write-Host ""
    Write-Host "    2. OR use the Windows Package Manager:"
    Write-Host "       winget install Python.Python.3.12"
    Write-Host ""
    Write-Host "    3. OR via Chocolatey:"
    Write-Host "       choco install python"
    Write-Host ""
    Write-Host "    Then re-run this installer. (Install dir was already created at"
    Write-Host "    $TMPCLI_DIR so a re-run is safe.)"
    exit 1
}
Write-Host "    Python: $pyVer"

# Download main script
$scriptPath = Join-Path $TMPCLI_DIR 'tmpcli'
Write-Host "    Downloading $REPO/tmpcli ..."
try {
    Invoke-WebRequest -Uri "$REPO/tmpcli" -OutFile $scriptPath -UseBasicParsing
} catch {
    Write-Host "[!] Download failed: $_" -ForegroundColor Red
    exit 1
}
# Bash shebang is harmless on Windows, but chmod is meaningless here.

# Create .ps1 wrapper (preferred on Windows)
$wrapperPs1 = Join-Path $BINDIR 'tmpcli.ps1'
if ($isWin) {
    @"
# tmpcli launcher — auto-generated by install.ps1
# Forwards all args to the python script in $TMPCLI_DIR
& $py "$TMPCLI_DIR\tmpcli" `$args
"@ | Set-Content -Path $wrapperPs1 -Encoding UTF8
} else {
    @"
#!/usr/bin/env pwsh
# tmpcli launcher — auto-generated by install.ps1
# Forwards all args to the python script in $TMPCLI_DIR
& $py "$TMPCLI_DIR/tmpcli" `$args
"@ | Set-Content -Path $wrapperPs1 -Encoding UTF8
    # On non-Windows, .ps1 wrappers are not on PATH conventionally;
    # create a .sh wrapper too for convenience.
    $wrapperSh = Join-Path $BINDIR 'tmpcli'
    @"
#!/usr/bin/env bash
# tmpcli launcher — auto-generated by install.ps1
exec $py "$TMPCLI_DIR/tmpcli" "\$@"
"@ | Set-Content -Path $wrapperSh -Encoding UTF8
    chmod +x $wrapperSh 2>$null
}

# Create .cmd wrapper (works in cmd.exe without execution policy hassles)
$wrapperCmd = Join-Path $BINDIR 'tmpcli.cmd'
@"
@echo off
REM tmpcli launcher — auto-generated by install.ps1
$py "$TMPCLI_DIR\tmpcli" %*
"@ | Set-Content -Path $wrapperCmd -Encoding ASCII

# Create a 'tmpcli' shim in $BINDIR that delegates to tmpcli.cmd
# (this makes `tmpcli` work in cmd.exe and the launcher name is short)
$wrapperBat = Join-Path $BINDIR 'tmpcli.bat'
@"
@echo off
call "$wrapperCmd" %*
"@ | Set-Content -Path $wrapperBat -Encoding ASCII

# PATH check (user PATH only; we don't touch system PATH).
# Skip on non-Windows — we don't auto-modify the user's shell rc.
if ($isWin) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $onPath = $false
    if ($userPath) {
        $pathDirs = $userPath -split ';' | ForEach-Object { $_.TrimEnd('\') }
        $onPath = $pathDirs -contains $BINDIR.TrimEnd('\')
    }

    if (-not $onPath) {
        Write-Host ""
        Write-Host "[!] $BINDIR is not in your user PATH." -ForegroundColor Yellow
        Write-Host "    Adding it for the current user ..."
        $newPath = if ($userPath) { "$userPath;$BINDIR" } else { $BINDIR }
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host "    Done. Open a NEW PowerShell / cmd window for PATH to take effect." -ForegroundColor Yellow
        Write-Host "    (Existing windows still need: `$env:Path += ';$BINDIR')"
    }
}

Write-Host ""
Write-Host "==> tmpcli installed successfully" -ForegroundColor Green
Write-Host "    Script:  $scriptPath"
Write-Host "    Cmd:     $wrapperCmd"
Write-Host "    Bash:    $wrapperPs1"
Write-Host ""
Write-Host "    Quick start:"
Write-Host "      tmpcli list          # show services"
Write-Host "      tmpcli up file.txt   # smart upload"
Write-Host "      tmpcli dl <url>      # download"
Write-Host "      tmpcli catalog       # service limits table"
Write-Host "      tmpcli update        # self-update from GitHub"
Write-Host ""
Write-Host "    If 'tmpcli' isn't recognized, open a new terminal window."
