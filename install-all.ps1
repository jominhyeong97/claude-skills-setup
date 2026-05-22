<#
  Claude Code 통합 스킬/플러그인 설치기 (단일 파일 / Windows)
  Notion "Claude Code SKILLs" 7개 도구 설치.

  실행 방법 (둘 중 하나):
    1) 인터넷 한 줄:  irm https://raw.githubusercontent.com/jominhyeong97/claude-skills-setup/main/install-all.ps1 | iex
    2) 파일 실행:     powershell -ExecutionPolicy Bypass -File .\install-all.ps1

  동작:
    - 사전요구(Node/git) 점검 및 winget 자동 설치 시도
    - npx skills 3종 자동 설치 (sf-skills, Skill Creator, Find Skills)
    - Claude Code /plugin 명령은 클립보드 복사 + 바탕화면 txt 저장 (Claude Code에 붙여넣기)
#>

$ErrorActionPreference = 'Stop'

function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Write-Ok($t)      { Write-Host "  [OK] $t"   -ForegroundColor Green }
function Write-Warn($t)    { Write-Host "  [! ] $t"   -ForegroundColor Yellow }
function Write-Err($t)     { Write-Host "  [X ] $t"   -ForegroundColor Red }
function Test-Cmd($n)      { return [bool](Get-Command $n -ErrorAction SilentlyContinue) }

Write-Host "Claude Code 스킬 통합 설치기" -ForegroundColor Magenta

# --- 1. 사전 요구사항 -------------------------------------------------------
Write-Section "1. 사전 요구사항 점검"
if (Test-Cmd node) { Write-Ok "Node.js $(node --version)" }
else {
    Write-Warn "Node.js 미설치 -> winget 설치 시도"
    if (Test-Cmd winget) {
        winget install --silent --accept-source-agreements --accept-package-agreements OpenJS.NodeJS.LTS
        Write-Warn "Node 설치 완료. 새 터미널을 열고 이 명령을 한 번 더 실행하세요 (PATH 갱신)."
    } else { Write-Err "winget 없음. https://nodejs.org 에서 Node LTS 수동 설치." }
}
if (Test-Cmd git)    { Write-Ok "git 감지됨" } else { Write-Warn "git 미설치 (선택). https://git-scm.com" }
if (Test-Cmd claude) { Write-Ok "Claude Code CLI 감지됨" } else { Write-Warn "Claude Code CLI 미감지 (/plugin 단계 전 필요)." }
Write-Warn "tmux는 OMC 'team' 기능용(선택). Windows는 WSL 권장."

# --- 2. npx skills 자동 설치 ------------------------------------------------
Write-Section "2. npx skills 스킬 자동 설치"
if (Test-Cmd node) {
    $skills = @(
        @{ N='sf-skills (Salesforce)'; C=@('skills','add','Jaganpro/sf-skills') },
        @{ N='Skill Creator';          C=@('skills','add','https://github.com/anthropics/skills','--skill','skill-creator') },
        @{ N='Find Skills';            C=@('skills','add','https://github.com/vercel-labs/skills','--skill','find-skills') }
    )
    foreach ($s in $skills) {
        Write-Host "  -> $($s.N) 설치 중..." -ForegroundColor Gray
        try { & npx --yes @($s.C); Write-Ok "$($s.N) 완료" }
        catch { Write-Err "$($s.N) 실패: $($_.Exception.Message)" }
    }
} else { Write-Err "Node.js 없음 -> npx 스킬 건너뜀." }

# --- 3. /plugin 명령 안내 ---------------------------------------------------
Write-Section "3. Claude Code 내부에서 실행할 /plugin 명령"
$pluginCmds = @"
# === Claude Code 실행 후 아래를 순서대로 붙여넣으세요 ===

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

# iex 실행 시 $PSScriptRoot가 비므로 바탕화면(없으면 홈)에 저장
$dest = [Environment]::GetFolderPath('Desktop'); if (-not $dest) { $dest = $HOME }
$outFile = Join-Path $dest 'claude-plugin-commands.txt'
$pluginCmds | Out-File -FilePath $outFile -Encoding utf8
Write-Host $pluginCmds -ForegroundColor White
Write-Ok "위 명령을 '$outFile' 에 저장했습니다."
try { $pluginCmds | Set-Clipboard; Write-Ok "클립보드에도 복사됨 -> Claude Code에 붙여넣기." } catch { Write-Warn "클립보드 복사 실패(무시 가능)." }

Write-Section "완료"
Write-Host "1) npx 스킬 자동 설치 완료." -ForegroundColor Green
Write-Host "2) Claude Code 실행 -> 클립보드/바탕화면 txt의 /plugin 명령 붙여넣기로 마무리." -ForegroundColor Green
