<#
.SYNOPSIS
  Claude Code 통합 스킬/플러그인 설치기 (Windows / PowerShell)
.DESCRIPTION
  Notion "Claude Code SKILLs" 페이지에 정리된 7개 도구를 새 PC에서 한 번에 설치합니다.
  - 셸에서 직접 설치 가능한 것(npx skills)은 자동 설치합니다.
  - Claude Code 내부에서만 가능한 /plugin 명령은 클립보드/파일로 안내합니다.
.NOTES
  실행: 우클릭 > "PowerShell로 실행" 또는
        powershell -ExecutionPolicy Bypass -File .\install.ps1
#>

[CmdletBinding()]
param(
    [switch]$SkipPrereqCheck
)

$ErrorActionPreference = 'Stop'

function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Write-Ok($t)      { Write-Host "  [OK] $t"   -ForegroundColor Green }
function Write-Warn($t)    { Write-Host "  [! ] $t"   -ForegroundColor Yellow }
function Write-Err($t)     { Write-Host "  [X ] $t"   -ForegroundColor Red }

function Test-Cmd($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

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
    $npxSkills = @(
        @{ Name = 'sf-skills (Salesforce)'; Cmd = @('skills','add','Jaganpro/sf-skills') },
        @{ Name = 'Skill Creator';          Cmd = @('skills','add','https://github.com/anthropics/skills','--skill','skill-creator') },
        @{ Name = 'Find Skills';            Cmd = @('skills','add','https://github.com/vercel-labs/skills','--skill','find-skills') }
    )
    foreach ($s in $npxSkills) {
        Write-Host "  -> $($s.Name) 설치 중..." -ForegroundColor Gray
        try {
            & npx --yes @($s.Cmd)
            Write-Ok "$($s.Name) 완료"
        } catch {
            Write-Err "$($s.Name) 실패: $($_.Exception.Message)"
        }
    }
} else {
    Write-Err "Node.js가 없어 npx 스킬 설치를 건너뜁니다."
}

# ----------------------------------------------------------------------------
# 3) Claude Code /plugin 명령 안내 (대화형 - 수동 실행 필요)
# ----------------------------------------------------------------------------
Write-Section "3. Claude Code 내부에서 실행할 /plugin 명령"

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
Write-Host "1) 위 npx 스킬은 자동 설치되었습니다." -ForegroundColor Green
Write-Host "2) Claude Code를 실행하고 클립보드/파일의 /plugin 명령을 붙여넣어 마무리하세요." -ForegroundColor Green
