<#
  Claude Code 통합 스킬/플러그인 설치기 (단일 파일 / Windows)
  Notion "Claude Code SKILLs" 도구 + gstack 전체를 명령 한 줄로 설치.

  실행 방법 (둘 중 하나):
    1) 인터넷 한 줄:  irm https://raw.githubusercontent.com/jominhyeong97/claude-skills-setup/main/install-all.ps1 | iex
    2) 파일 실행:     powershell -ExecutionPolicy Bypass -File .\install-all.ps1

  동작:
    - 사전요구(Node/git/claude CLI) 점검 및 winget 자동 설치 시도
    - npx skills 4종 자동 설치 (sf-skills, Skill Creator, Find Skills, AgentMemory)
    - Bun 공식 설치기로 설치 (~/.bun, Node 버전과 무관 / nvm 사용 시에도 안전)
    - gstack 자동 설치 (git clone + ./setup, ~55개 슬래시 커맨드)
    - agentmemory MCP 서버 전역 설치 (npm i -g, 영속 메모리 백엔드)
    - Claude Code 플러그인 7종 자동 설치 (claude CLI 사용, 붙여넣기 불필요)
    - 마지막에 항목별 성공/실패 요약 출력 (조용한 실패 방지)

  변경 이력:
    2026-08-18  Bun 설치를 npm -g 에서 공식 설치기로 교체(실패 원인 제거),
                /plugin 수동 붙여넣기를 claude CLI 자동 설치로 전환,
                최종 결과 요약 추가.
#>

# native 명령(git/bun setup 등)이 stderr로 진행률을 뿜어도 죽지 않도록 Continue.
# 성공/실패는 $LASTEXITCODE 로 직접 판정한다.
$ErrorActionPreference = 'Continue'

function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Write-Ok($t)      { Write-Host "  [OK] $t"   -ForegroundColor Green }
function Write-Warn($t)    { Write-Host "  [! ] $t"   -ForegroundColor Yellow }
function Write-Err($t)     { Write-Host "  [X ] $t"   -ForegroundColor Red }
function Test-Cmd($n)      { return [bool](Get-Command $n -ErrorAction SilentlyContinue) }

# 최종 요약용 결과 수집 (조용한 실패를 막는 장치)
$script:Results = New-Object System.Collections.ArrayList
function Add-Result($name, $ok, $note) {
    $null = $script:Results.Add([PSCustomObject]@{ 항목 = $name; 결과 = $(if ($ok) { 'OK' } else { 'FAIL' }); 비고 = $note })
}

# npx 는 .cmd/.ps1 셈(shim)이라 PowerShell 배열 인자가 한 덩어리로 합쳐지는 버그가 있다.
# 단일 문자열을 cmd /c 에 넘기면 셈 종류와 무관하게 안전하게 분리되고, exit code 도 정확하다.
function Invoke-Npx($label, $argString) {
    Write-Host "  -> $label 설치 중..." -ForegroundColor Gray
    cmd /c "npx --yes $argString"
    if ($LASTEXITCODE -eq 0) { Write-Ok "$label 완료"; Add-Result $label $true '' }
    else { Write-Err "$label 실패 (exit $LASTEXITCODE)"; Add-Result $label $false "exit $LASTEXITCODE" }
}

# 플러그인 1종을 마켓플레이스 등록 + 설치까지 처리한다.
# claude CLI 가 있으면 완전 자동. 없으면 수동 안내용 목록에만 쌓는다.
function Install-Plugin($label, $repo, $plugin) {
    if (-not (Test-Cmd claude)) { Add-Result $label $false 'claude CLI 없음 - 수동 설치 필요'; return }
    Write-Host "  -> $label ..." -ForegroundColor Gray
    cmd /c "claude plugin marketplace add $repo" | Out-Null
    cmd /c "claude plugin install $plugin"
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$label 완료"; Add-Result $label $true ''
    } else {
        Write-Err "$label 실패 (exit $LASTEXITCODE)"; Add-Result $label $false "exit $LASTEXITCODE"
    }
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
if (Test-Cmd claude) { Write-Ok "Claude Code CLI 감지됨 (플러그인 자동 설치 가능)" }
else { Write-Warn "Claude Code CLI 미감지 -> 6단계 플러그인은 수동 설치로 안내됩니다." }
Write-Warn "tmux는 OMC 'team' 기능용(선택). Windows는 WSL 권장."

# --- 2. npx skills 자동 설치 ------------------------------------------------
Write-Section "2. npx skills 스킬 자동 설치"
if (Test-Cmd node) {
    Invoke-Npx 'sf-skills (Salesforce)' 'skills add Jaganpro/sf-skills'
    Invoke-Npx 'Skill Creator'          'skills add https://github.com/anthropics/skills --skill skill-creator'
    Invoke-Npx 'Find Skills'            'skills add https://github.com/vercel-labs/skills --skill find-skills'
    Invoke-Npx 'AgentMemory (8 skills)' 'skills add rohitg00/agentmemory'
} else { Write-Err "Node.js 없음 -> npx 스킬 건너뜀."; Add-Result 'npx skills 4종' $false 'Node.js 없음' }

# --- 3. Bun 설치 ------------------------------------------------------------
# 주의: 예전 버전은 'npm install -g bun' 을 썼는데, nvm 사용 시 Node 버전을 바꾸면
#       bun 이 사라지고 설치 자체도 자주 실패했다(=gstack 이 조용히 누락되던 원인).
#       공식 설치기는 ~/.bun 에 넣으므로 Node 버전과 무관하다.
Write-Section "3. Bun 설치 (gstack 빌드에 필요)"
$bunBin = Join-Path $HOME '.bun\bin'
if ((Test-Path $bunBin) -and ($env:PATH -notlike "*$bunBin*")) { $env:PATH = "$bunBin;$env:PATH" }

if (Test-Cmd bun) { Write-Ok "Bun $(bun --version) 이미 설치됨"; Add-Result 'Bun' $true '기설치' }
else {
    Write-Host "  -> Bun 공식 설치기 실행 중..." -ForegroundColor Gray
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-RestMethod bun.sh/install.ps1 | Invoke-Expression
    } catch { Write-Warn "공식 설치기 실패 -> npm 폴백 시도" }

    if ((Test-Path $bunBin) -and ($env:PATH -notlike "*$bunBin*")) { $env:PATH = "$bunBin;$env:PATH" }

    if (-not (Test-Cmd bun) -and (Test-Cmd npm)) {
        cmd /c "npm install -g bun"
        $npmBin = Join-Path $env:APPDATA 'npm'
        if ((Test-Path $npmBin) -and ($env:PATH -notlike "*$npmBin*")) { $env:PATH = "$env:PATH;$npmBin" }
    }

    if (Test-Cmd bun) { Write-Ok "Bun $(bun --version) 설치 완료"; Add-Result 'Bun' $true '' }
    else { Write-Err "Bun 설치 실패 -> gstack 을 설치할 수 없습니다. https://bun.sh 수동 설치 후 재실행."; Add-Result 'Bun' $false '설치 실패' }
}

# --- 4. gstack 설치 ---------------------------------------------------------
Write-Section "4. gstack 설치 (~55개 슬래시 커맨드)"
$gstackDir = Join-Path $HOME '.claude\skills\gstack'
$gstackReady = $false

if (-not (Test-Cmd bun)) {
    Write-Err "Bun 없음 -> gstack 건너뜀."; Add-Result 'gstack' $false 'Bun 없음'
} elseif (-not (Test-Cmd git)) {
    Write-Err "git 없음 -> gstack 클론 불가."; Add-Result 'gstack' $false 'git 없음'
} else {
    if (Test-Path (Join-Path $gstackDir '.git')) {
        Write-Warn "gstack 이미 존재 -> git pull 로 업데이트"
        git -C $gstackDir pull --ff-only --quiet
        $gstackReady = ($LASTEXITCODE -eq 0)
    } else {
        git clone --single-branch --depth 1 --quiet https://github.com/garrytan/gstack.git $gstackDir
        $gstackReady = ($LASTEXITCODE -eq 0)
    }
    if (-not $gstackReady) { Write-Err "gstack 클론/업데이트 실패"; Add-Result 'gstack' $false 'clone/pull 실패' }
}

# 4-2. setup 실행 (Git for Windows 의 bash 로 ./setup 구동)
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
        if ($setupCode -eq 0) {
            Write-Ok "gstack 설치 완료 (/gstack, /office-hours, /review, /qa, /ship, /cso 등)"
            Add-Result 'gstack' $true '~55 skills'
        } else {
            Write-Err "gstack setup 실패 (exit $setupCode). 수동: cd `"$gstackDir`"; bash ./setup"
            Add-Result 'gstack' $false "setup exit $setupCode"
        }
    } else {
        Write-Err "bash 없음 -> gstack setup 수동 실행 필요: cd `"$gstackDir`"; bash ./setup"
        Add-Result 'gstack' $false 'bash 없음'
    }
}

# --- 5. agentmemory MCP 서버 (영속 메모리 백엔드) ---------------------------
Write-Section "5. agentmemory 전역 설치 (영속 메모리)"
if (Test-Cmd npm) {
    if (Test-Cmd agentmemory) { Write-Ok "agentmemory $(agentmemory --version) 이미 설치됨"; Add-Result 'agentmemory' $true '기설치' }
    else {
        Write-Host "  -> @agentmemory/agentmemory 전역 설치 중..." -ForegroundColor Gray
        cmd /c "npm install -g @agentmemory/agentmemory"
        if ($LASTEXITCODE -eq 0) { Write-Ok "agentmemory 설치 완료"; Add-Result 'agentmemory' $true '' }
        else { Write-Err "agentmemory 설치 실패 (exit $LASTEXITCODE)"; Add-Result 'agentmemory' $false "exit $LASTEXITCODE" }
    }
    Write-Warn "MCP 연결은 Claude Code에서 한 번만 실행하세요: agentmemory connect claude-code"
} else { Write-Err "npm 없음 -> agentmemory 설치 불가."; Add-Result 'agentmemory' $false 'npm 없음' }

# --- 6. Claude Code 플러그인 자동 설치 --------------------------------------
# 예전 버전은 여기서 명령을 클립보드에 복사해 주고 사용자가 직접 붙여넣게 했다.
# claude CLI 의 plugin 서브커맨드로 전부 자동화되므로 붙여넣기 단계를 제거한다.
Write-Section "6. Claude Code 플러그인 자동 설치"
if (Test-Cmd claude) {
    Install-Plugin 'claude-hud (상태바 HUD)'      'jarrodwatts/claude-hud'              'claude-hud'
    Install-Plugin 'oh-my-claudecode (OMC)'       'Yeachan-Heo/oh-my-claudecode'        'oh-my-claudecode'
    Install-Plugin 'Superpowers'                  'obra/superpowers'                    'superpowers'
    Install-Plugin 'PPTX (document-skills)'       'anthropics/skills'                   'document-skills'
    Install-Plugin 'Karpathy Guidelines'          'multica-ai/andrej-karpathy-skills'   'andrej-karpathy-skills'
    Install-Plugin 'Understand-Anything'          'Lum1104/Understand-Anything'         'understand-anything'
    Install-Plugin 'claude-video (/watch)'        'bradautomates/claude-video'          'watch'
    Write-Warn "claude-hud 상태바는 Claude Code 재시작 후 /claude-hud:setup 을 1회 실행하세요."
} else {
    Write-Err "claude CLI 없음 -> 아래 명령을 Claude Code 안에서 직접 실행하세요."
    $pluginCmds = @"
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode
/plugin marketplace add obra/superpowers
/plugin install superpowers
/plugin marketplace add anthropics/skills
/plugin install document-skills
/plugin marketplace add multica-ai/andrej-karpathy-skills
/plugin install andrej-karpathy-skills
/plugin marketplace add Lum1104/Understand-Anything
/plugin install understand-anything
/plugin marketplace add bradautomates/claude-video
/plugin install watch
"@
    $dest = [Environment]::GetFolderPath('Desktop'); if (-not $dest) { $dest = $HOME }
    $outFile = Join-Path $dest 'claude-plugin-commands.txt'
    $pluginCmds | Out-File -FilePath $outFile -Encoding utf8
    Write-Host $pluginCmds -ForegroundColor White
    Write-Ok "위 명령을 '$outFile' 에 저장했습니다."
    try { $pluginCmds | Set-Clipboard; Write-Ok "클립보드에도 복사됨." } catch { Write-Warn "클립보드 복사 실패(무시 가능)." }
}

# --- 7. 결과 요약 -----------------------------------------------------------
# 예전 버전은 실패해도 계속 진행만 하고 요약이 없어서, gstack 이 빠진 것을
# 몇 달 동안 모르고 지나갔다. 아래 표가 그 재발을 막는다.
Write-Section "7. 설치 결과 요약"
$script:Results | Format-Table -AutoSize | Out-String | Write-Host

$failed = @($script:Results | Where-Object { $_.결과 -eq 'FAIL' })
if ($failed.Count -eq 0) {
    Write-Host "전부 성공했습니다." -ForegroundColor Green
} else {
    Write-Host "실패 $($failed.Count)건 -- 아래 항목을 확인하세요:" -ForegroundColor Red
    foreach ($f in $failed) { Write-Host "  - $($f.항목) : $($f.비고)" -ForegroundColor Red }
}

Write-Section "다음 할 일"
Write-Host "1) Claude Code를 '재시작'하세요. (새 스킬/플러그인은 재시작 후 목록에 나타납니다)" -ForegroundColor Green
Write-Host "2) 메모리 영속화: 'agentmemory connect claude-code' 를 1회 실행." -ForegroundColor Green
Write-Host "3) 상태바: /claude-hud:setup 을 1회 실행." -ForegroundColor Green
Write-Host "4) gstack 첫 사용: 새 아이디어면 /office-hours, 기존 코드면 /investigate." -ForegroundColor Green
