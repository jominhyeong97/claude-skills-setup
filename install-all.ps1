<#
  Claude Code 통합 스킬/플러그인 설치기 (단일 파일 / Windows)
  Notion "Claude Code SKILLs" 도구 + gstack 설치.

  실행 방법 (둘 중 하나):
    1) 인터넷 한 줄:  irm https://raw.githubusercontent.com/jominhyeong97/claude-skills-setup/main/install-all.ps1 | iex
    2) 파일 실행:     powershell -ExecutionPolicy Bypass -File .\install-all.ps1

  동작:
    - 사전요구(Node/git) 점검 및 winget 자동 설치 시도
    - npx skills 3종 자동 설치 (sf-skills, Skill Creator, Find Skills)
    - gstack 자동 설치 (Bun 자동 설치 + git clone + ./setup, ~50개 슬래시 커맨드)
    - Claude Code /plugin 명령은 클립보드 복사 + 바탕화면 txt 저장 (Claude Code에 붙여넣기)
#>

# native 명령(git/bun setup 등)이 stderr로 진행률을 뿜어도 죽지 않도록 Continue.
# 성공/실패는 $LASTEXITCODE 로 직접 판정한다.
$ErrorActionPreference = 'Continue'

function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Write-Ok($t)      { Write-Host "  [OK] $t"   -ForegroundColor Green }
function Write-Warn($t)    { Write-Host "  [! ] $t"   -ForegroundColor Yellow }
function Write-Err($t)     { Write-Host "  [X ] $t"   -ForegroundColor Red }
function Test-Cmd($n)      { return [bool](Get-Command $n -ErrorAction SilentlyContinue) }

# npx 는 .cmd/.ps1 셈(shim)이라 PowerShell 배열 인자가 한 덩어리로 합쳐지는 버그가 있다.
# 단일 문자열을 cmd /c 에 넘기면 셈 종류와 무관하게 안전하게 분리되고, exit code 도 정확하다.
function Invoke-Npx($label, $argString) {
    Write-Host "  -> $label 설치 중..." -ForegroundColor Gray
    cmd /c "npx --yes $argString"
    if ($LASTEXITCODE -eq 0) { Write-Ok "$label 완료" }
    else { Write-Err "$label 실패 (exit $LASTEXITCODE)" }
}

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
if (Test-Cmd git)    { Write-Ok "git 감지됨" } else { Write-Warn "git 미설치 (gstack 설치에 필요). https://git-scm.com" }
if (Test-Cmd claude) { Write-Ok "Claude Code CLI 감지됨" } else { Write-Warn "Claude Code CLI 미감지 (/plugin 단계 전 필요)." }
Write-Warn "tmux는 OMC 'team' 기능용(선택). Windows는 WSL 권장."

# --- 2. npx skills 자동 설치 ------------------------------------------------
Write-Section "2. npx skills 스킬 자동 설치"
if (Test-Cmd node) {
    Invoke-Npx 'sf-skills (Salesforce)' 'skills add Jaganpro/sf-skills'
    Invoke-Npx 'Skill Creator'          'skills add https://github.com/anthropics/skills --skill skill-creator'
    Invoke-Npx 'Find Skills'            'skills add https://github.com/vercel-labs/skills --skill find-skills'
} else { Write-Err "Node.js 없음 -> npx 스킬 건너뜀." }

# --- 3. gstack 설치 ---------------------------------------------------------
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
# 방금 설치한 bun(=npm 전역 bin)을 이번 세션 PATH 에 추가
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
        $gitRoot = Split-Path (Split-Path $gitCmd.Source -Parent) -Parent  # ...\Git\cmd -> ...\Git
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

# --- 4. /plugin 명령 안내 ---------------------------------------------------
Write-Section "4. Claude Code 내부에서 실행할 /plugin 명령"
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
Write-Host "1) npx 스킬 + gstack 자동 설치 완료." -ForegroundColor Green
Write-Host "2) Claude Code '재시작' 후 클립보드/바탕화면 txt의 /plugin 명령을 붙여넣어 마무리." -ForegroundColor Green
Write-Host "   (새로 설치된 스킬/플러그인은 Claude Code를 다시 켜야 목록에 나타납니다.)" -ForegroundColor Green
