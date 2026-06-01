<#
.SYNOPSIS
  Claude Code 통합 스킬/플러그인 설치기 (Windows / PowerShell)
.DESCRIPTION
  Notion "Claude Code SKILLs" 페이지에 정리된 도구 + gstack 을 새 PC에서 한 번에 설치합니다.
  - 셸에서 직접 설치 가능한 것(npx skills, gstack)은 자동 설치합니다.
  - Claude Code 내부에서만 가능한 /plugin 명령은 클립보드/파일로 안내합니다.
.NOTES
  실행: 우클릭 > "PowerShell로 실행" 또는
        powershell -ExecutionPolicy Bypass -File .\install.ps1
#>

[CmdletBinding()]
param(
    [switch]$SkipPrereqCheck
)

# native 명령(git/bun setup 등)이 stderr로 진행률을 뿜어도 죽지 않도록 Continue.
# 성공/실패는 $LASTEXITCODE 로 직접 판정한다.
$ErrorActionPreference = 'Continue'

function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Write-Ok($t)      { Write-Host "  [OK] $t"   -ForegroundColor Green }
function Write-Warn($t)    { Write-Host "  [! ] $t"   -ForegroundColor Yellow }
function Write-Err($t)     { Write-Host "  [X ] $t"   -ForegroundColor Red }
function Test-Cmd($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

# npx 는 셈(shim)이라 PowerShell 배열 인자가 합쳐지는 버그가 있다.
# 단일 문자열을 cmd /c 에 넘기면 안전하게 분리되고 exit code 도 정확하다.
function Invoke-Npx($label, $argString) {
    Write-Host "  -> $label 설치 중..." -ForegroundColor Gray
    cmd /c "npx --yes $argString"
    if ($LASTEXITCODE -eq 0) { Write-Ok "$label 완료" }
    else { Write-Err "$label 실패 (exit $LASTEXITCODE)" }
}

# ----------------------------------------------------------------------------
# 1) 사전 요구사항 점검
# ----------------------------------------------------------------------------
Write-Section "1. 사전 요구사항 점검"

if (-not $SkipPrereqCheck) {
    # Node.js
    if (Test-Cmd node) {
        Write-Ok "Node.js $(node --version)"
    } else {
        Write-Warn "Node.js 미설치 -> 설치 시도 (winget)"
        if (Test-Cmd winget) {
            winget install --silent --accept-source-agreements --accept-package-agreements OpenJS.NodeJS.LTS
            Write-Warn "Node 설치 후 새 터미널에서 이 스크립트를 다시 실행하세요."
        } else {
            Write-Err "winget 없음. https://nodejs.org 에서 Node.js LTS를 수동 설치하세요."
        }
    }

    # git
    if (Test-Cmd git) { Write-Ok "git $((git --version) -replace 'git version ','')" }
    else {
        Write-Warn "git 미설치 -> 설치 시도 (winget)"
        if (Test-Cmd winget) { winget install --silent -e --id Git.Git }
        else { Write-Err "git을 https://git-scm.com 에서 수동 설치하세요." }
    }

    # claude code CLI
    if (Test-Cmd claude) { Write-Ok "Claude Code CLI 감지됨" }
    else { Write-Warn "Claude Code CLI 미감지. /plugin 단계 전에 Claude Code가 설치돼 있어야 합니다." }

    # tmux (OMC team 기능용 - 선택)
    Write-Warn "tmux는 OMC의 'team' 기능에 필요합니다. Windows 네이티브: 'winget install psmux' 또는 WSL 사용 권장."
}

# ----------------------------------------------------------------------------
# 2) npx skills 기반 스킬 자동 설치 (셸에서 직접 가능)
# ----------------------------------------------------------------------------
Write-Section "2. npx skills 스킬 자동 설치"

if (Test-Cmd node) {
    Invoke-Npx 'sf-skills (Salesforce)' 'skills add Jaganpro/sf-skills'
    Invoke-Npx 'Skill Creator'          'skills add https://github.com/anthropics/skills --skill skill-creator'
    Invoke-Npx 'Find Skills'            'skills add https://github.com/vercel-labs/skills --skill find-skills'
    Invoke-Npx 'AgentMemory (8 skills)' 'skills add rohitg00/agentmemory'
} else {
    Write-Err "Node.js가 없어 npx 스킬 설치를 건너뜁니다."
}

# ----------------------------------------------------------------------------
# 3) gstack 설치 (Bun 자동 설치 + git clone + ./setup)
# ----------------------------------------------------------------------------
Write-Section "3. gstack 설치 (사업성 검토 등 ~50개 슬래시 커맨드)"

# 3-1. Bun (gstack 의 browse 바이너리 빌드에 필요)
if (Test-Cmd bun) { Write-Ok "Bun $(bun --version)" }
else {
    Write-Warn "Bun 미설치 -> npm 으로 설치"
    if (Test-Cmd npm) {
        cmd /c "npm install -g bun"
        if ($LASTEXITCODE -eq 0) { Write-Ok "Bun 설치 완료" } else { Write-Err "Bun 설치 실패 (exit $LASTEXITCODE)" }
    } else { Write-Err "npm 없음 -> Bun 설치 불가. https://bun.sh 에서 수동 설치." }
}
$npmBin = Join-Path $env:APPDATA 'npm'
if ((Test-Path $npmBin) -and ($env:PATH -notlike "*$npmBin*")) { $env:PATH = "$env:PATH;$npmBin" }

# 3-2. 클론 / 업데이트
$gstackDir = Join-Path $HOME '.claude\skills\gstack'
$gstackReady = $false
if (Test-Cmd git) {
    if (Test-Path (Join-Path $gstackDir '.git')) {
        Write-Warn "gstack 이미 존재 -> git pull 로 업데이트"
        git -C $gstackDir pull --ff-only --quiet
        $gstackReady = ($LASTEXITCODE -eq 0)
    } else {
        git clone --single-branch --depth 1 --quiet https://github.com/garrytan/gstack.git $gstackDir
        $gstackReady = ($LASTEXITCODE -eq 0)
    }
} else { Write-Err "git 없음 -> gstack 클론 불가." }

# 3-3. setup 실행 (Git for Windows 의 bash 로 ./setup 구동)
if ($gstackReady) {
    $bashExe = $null
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $gitRoot = Split-Path (Split-Path $gitCmd.Source -Parent) -Parent
        foreach ($rel in @('bin\bash.exe','usr\bin\bash.exe')) {
            $cand = Join-Path $gitRoot $rel
            if (Test-Path $cand) { $bashExe = $cand; break }
        }
    }
    if (-not $bashExe -and (Test-Cmd bash)) { $bashExe = 'bash' }
    if ($bashExe) {
        Write-Host "  -> gstack setup 실행 중 (Playwright 다운로드로 수 분 소요될 수 있음)..." -ForegroundColor Gray
        Push-Location $gstackDir
        & $bashExe ./setup
        $setupCode = $LASTEXITCODE
        Pop-Location
        if ($setupCode -eq 0) { Write-Ok "gstack 설치 완료 (/office-hours, /plan-ceo-review, /review, /qa, /ship 등)" }
        else { Write-Err "gstack setup 실패 (exit $setupCode). 수동: cd `"$gstackDir`"; bash ./setup" }
    } else {
        Write-Err "bash 없음 -> gstack setup 수동 실행 필요: cd `"$gstackDir`"; bash ./setup"
    }
}

# ----------------------------------------------------------------------------
# 4) agentmemory 전역 설치 (영속 메모리 백엔드)
# ----------------------------------------------------------------------------
Write-Section "4. agentmemory 전역 설치 (영속 메모리)"
if (Test-Cmd npm) {
    if (Test-Cmd agentmemory) { Write-Ok "agentmemory $(agentmemory --version) 이미 설치됨" }
    else {
        Write-Host "  -> @agentmemory/agentmemory 전역 설치 중..." -ForegroundColor Gray
        cmd /c "npm install -g @agentmemory/agentmemory"
        if ($LASTEXITCODE -eq 0) { Write-Ok "agentmemory 설치 완료" }
        else { Write-Err "agentmemory 설치 실패 (exit $LASTEXITCODE)" }
    }
    Write-Warn "MCP 연결은 Claude Code에서 한 번만 실행하세요: agentmemory connect claude-code"
} else { Write-Err "npm 없음 -> agentmemory 설치 불가." }

# ----------------------------------------------------------------------------
# 5) Claude Code /plugin 명령 안내 (대화형 - 수동 실행 필요)
# ----------------------------------------------------------------------------
Write-Section "5. Claude Code 내부에서 실행할 /plugin 명령"

$pluginCmds = @"
# === Claude Code를 실행한 뒤 아래 명령을 순서대로 붙여넣으세요 ===

# claude-hud (상태바 HUD) — Claude Code v1.0.80+
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/reload-plugins
/claude-hud:setup

# oh-my-claudecode (OMC)
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode
/setup

# Superpowers
/plugin install superpowers@claude-plugins-official

# PPTX (document-skills 패키지에 포함)
/plugin marketplace add anthropics/skills
/plugin install document-skills@anthropic-agent-skills

# Karpathy Guidelines (LLM 코딩 실수 방지 4룰)
/plugin marketplace add multica-ai/andrej-karpathy-skills
/plugin install andrej-karpathy-skills

# Understand-Anything (코드베이스 지식 그래프)
/plugin marketplace add Lum1104/Understand-Anything
/plugin install understand-anything

# claude-video (영상 시청 능력 — /watch <URL>)
/plugin marketplace add bradautomates/claude-video
/plugin install watch
"@

$outFile = Join-Path $PSScriptRoot 'claude-plugin-commands.txt'
$pluginCmds | Out-File -FilePath $outFile -Encoding utf8
Write-Host $pluginCmds -ForegroundColor White
Write-Ok "위 명령을 '$outFile' 에도 저장했습니다."

# 클립보드에 복사 시도
try {
    $pluginCmds | Set-Clipboard
    Write-Ok "명령 목록을 클립보드에 복사했습니다. Claude Code에 붙여넣으세요."
} catch { Write-Warn "클립보드 복사 실패 (무시 가능)." }

Write-Section "완료"
Write-Host "1) 위 npx 스킬 + gstack + agentmemory는 자동 설치되었습니다." -ForegroundColor Green
Write-Host "2) Claude Code를 '재시작'하고 클립보드/파일의 /plugin 명령을 붙여넣어 마무리하세요." -ForegroundColor Green
Write-Host "3) 메모리 영속화: Claude Code 안에서 'agentmemory connect claude-code' 1회 실행." -ForegroundColor Green
