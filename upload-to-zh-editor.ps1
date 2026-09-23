# Qingyi Edu - macOS installers: download -> push code -> publish Release (Windows / PowerShell)
#
# One-liner (run in PowerShell on the Windows machine):
#   irm https://raw.githubusercontent.com/langcher752-droid/qingyi-mac-builds/main/upload-to-zh-editor.ps1 | iex
#
# NOTE: this file is intentionally ASCII-only. PowerShell 5.1 decodes
# "irm | iex" output as Windows-1252, so non-ASCII text here would be garbled.
# Chinese text (release notes) lives in release-notes-zh.txt, which is read as UTF-8 by gh.

$ErrorActionPreference = 'Stop'

$SrcRepo  = 'langcher752-droid/qingyi-mac-builds'
$SrcTag   = 'mac-v1.0.0'
$DstRepo  = 'Arthurchen-01/zh-editor'
$DstTag   = 'v1.0.0-mac'
$DmgArm   = 'Qingyi-Mac-AppleSilicon.dmg'   # Apple Silicon (M1/M2/M3/M4)
$DmgIntel = 'Qingyi-Mac-Intel.dmg'          # Intel Mac
$RawBase  = 'https://raw.githubusercontent.com/langcher752-droid/qingyi-mac-builds/main'

function Say($m) { Write-Host ''; Write-Host $m -ForegroundColor Cyan }

function Update-Path {
    $m = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $u = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = @($m, $u) -join ';'
}

function Ensure-Tool($cmd, $wingetId, $hint) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { return $true }
    Say "[!] '$cmd' not found. Trying: winget install $wingetId"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            winget install --id $wingetId -e --silent `
                --accept-source-agreements --accept-package-agreements
        } catch {
            Write-Host "    winget failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        Update-Path
    }
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { return $true }
    Write-Host "    Please install it manually: $hint" -ForegroundColor Yellow
    return $false
}

Say '== Step 1/4: check tools =='
if (-not (Ensure-Tool gh  'GitHub.cli' 'https://cli.github.com')) { exit 1 }
if (-not (Ensure-Tool git 'Git.Git'    'https://git-scm.com/download/win')) { exit 1 }
Write-Host "    gh  : $((Get-Command gh).Source)"
Write-Host "    git : $((Get-Command git).Source)"

gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Say 'Not signed in to GitHub. Starting "gh auth login" ...'
    gh auth login
    if ($LASTEXITCODE -ne 0) { Write-Host 'Login failed or cancelled.' -ForegroundColor Red; exit 1 }
}
$me = (gh api user -q '.login') | Select-Object -First 1
Write-Host "    signed in as: $me"

$push = ''
try { $push = (gh api "repos/$DstRepo" -q '.permissions.push') | Select-Object -First 1 } catch { }
if ($push -ne 'true') {
    Write-Host "    [!] $me may not have write access to $DstRepo - will try anyway." -ForegroundColor Yellow
}

$tmp = Join-Path $env:TEMP ('qingyi-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp | Out-Null
Write-Host "    temp dir: $tmp"

Say '== Step 2/4: download installers + code bundle =='
gh release download $SrcTag --repo $SrcRepo --dir $tmp
Get-ChildItem -Path $tmp | Select-Object Name, Length | Format-Table -AutoSize
foreach ($f in @($DmgArm, $DmgIntel, 'mac-packaging.bundle')) {
    if (-not (Test-Path (Join-Path $tmp $f))) {
        Write-Host "    missing download: $f" -ForegroundColor Red; exit 1
    }
}

Say "== Step 3/4: push macOS packaging commit to $DstRepo =="
gh auth setup-git | Out-Null
Push-Location $tmp
try {
    git clone --quiet "https://github.com/$DstRepo.git" zh-editor
    Set-Location zh-editor
    git fetch --quiet "$tmp\mac-packaging.bundle" refs/heads/main:refs/remotes/bundle/main
    if ($LASTEXITCODE -ne 0) {
        Write-Host '    [!] could not load the code bundle - skipping code push.' -ForegroundColor Yellow
    } else {
        git push origin refs/remotes/bundle/main:main
        if ($LASTEXITCODE -ne 0) {
            Write-Host '    [!] push failed (no permission, or remote main moved). Skipping.' -ForegroundColor Yellow
        } else {
            Write-Host '    pushed OK'
        }
    }
    Set-Location $tmp
} finally {
    Pop-Location
}

Say "== Step 4/4: publish Release $DstTag on $DstRepo =="
$notesFile = Join-Path $tmp 'release-notes-zh.txt'
try {
    Invoke-WebRequest -Uri "$RawBase/release-notes-zh.txt" -OutFile $notesFile -UseBasicParsing
} catch {
    [System.IO.File]::WriteAllText($notesFile,
        "macOS installers: Apple Silicon + Intel.`n",
        (New-Object System.Text.UTF8Encoding($false)))
}

gh release view $DstTag --repo $DstRepo *> $null
if ($LASTEXITCODE -eq 0) {
    gh release upload $DstTag --repo $DstRepo --clobber `
        (Join-Path $tmp $DmgArm) (Join-Path $tmp $DmgIntel)
} else {
    gh release create $DstTag --repo $DstRepo `
        --title 'macOS installers (Intel + Apple Silicon)' `
        --notes-file $notesFile `
        (Join-Path $tmp $DmgArm) (Join-Path $tmp $DmgIntel)
}
if ($LASTEXITCODE -ne 0) { Write-Host 'Release step failed.' -ForegroundColor Red; exit 1 }

Say '== Done =='
Write-Host "code      : https://github.com/$DstRepo"
Write-Host "installers: https://github.com/$DstRepo/releases/tag/$DstTag"
Write-Host "temp dir  : $tmp (safe to delete)"
