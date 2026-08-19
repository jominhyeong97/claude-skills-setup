#!/usr/bin/env bash
# ============================================================================
# Claude Code 통합 스킬/플러그인 설치기 (macOS / Linux / WSL)
# Notion "Claude Code SKILLs" 7개 도구를 새 환경에서 한 번에 설치
#   - npx skills 기반은 자동 설치
#   - Claude Code 내부 /plugin 명령은 안내 출력 + 파일 저장
# 실행: bash install.sh
# ============================================================================
set -u

cyan(){ printf '\033[36m%s\033[0m\n' "$*"; }
green(){ printf '\033[32m  [OK] %s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m  [! ] %s\033[0m\n' "$*"; }
red(){ printf '\033[31m  [X ] %s\033[0m\n' "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----------------------------------------------------------------------------
cyan ""; cyan "=== 1. 사전 요구사항 점검 ==="
if have node; then green "Node.js $(node --version)"; else
  yellow "Node.js 미설치. https://nodejs.org 또는 nvm으로 설치하세요."
fi
if have git; then green "git $(git --version | sed 's/git version //')"; else
  yellow "git 미설치. apt/brew 등으로 설치하세요."
fi
have claude && green "Claude Code CLI 감지됨" || yellow "Claude Code CLI 미감지 (/plugin 단계 전 필요)."
if have tmux; then green "tmux $(tmux -V)"; else
  yellow "tmux 미설치 (OMC 'team' 기능용). 'sudo apt install tmux' 또는 'brew install tmux'."
fi

# ----------------------------------------------------------------------------
cyan ""; cyan "=== 2. npx skills 스킬 자동 설치 ==="
if have node; then
  run_skill(){ printf '  -> %s 설치 중...\n' "$1"; shift; if npx --yes "$@"; then green "완료"; else red "실패"; fi; }
  run_skill "sf-skills (Salesforce)" skills add Jaganpro/sf-skills
  run_skill "Skill Creator"          skills add https://github.com/anthropics/skills --skill skill-creator
  run_skill "Find Skills"            skills add https://github.com/vercel-labs/skills --skill find-skills
  run_skill "AgentMemory (8 skills)" skills add rohitg00/agentmemory
else
  red "Node.js가 없어 npx 스킬 설치를 건너뜁니다."
fi

# ----------------------------------------------------------------------------
cyan ""; cyan "=== 3. gstack 설치 (사업성 검토 등 ~50개 슬래시 커맨드) ==="
# 3-1. Bun (gstack 의 browse 바이너리 빌드에 필요)
if have bun; then green "Bun $(bun --version)"; else
  yellow "Bun 미설치 -> 설치 시도"
  if have npm; then npm install -g bun && green "Bun 설치 완료" || red "Bun 설치 실패"
  elif have curl; then curl -fsSL https://bun.sh/install | bash && export PATH="$HOME/.bun/bin:$PATH" && green "Bun 설치 완료"
  else red "Bun 설치 불가 (npm/curl 없음). https://bun.sh 수동 설치."; fi
fi
# 3-2. clone / 업데이트 후 setup
GSTACK_DIR="$HOME/.claude/skills/gstack"
if have git; then
  if [ -d "$GSTACK_DIR/.git" ]; then
    yellow "gstack 이미 존재 -> git pull 로 업데이트"
    git -C "$GSTACK_DIR" pull --ff-only --quiet
  else
    git clone --single-branch --depth 1 --quiet https://github.com/garrytan/gstack.git "$GSTACK_DIR"
  fi
  if [ -f "$GSTACK_DIR/setup" ]; then
    printf '  -> gstack setup 실행 중 (Playwright 다운로드로 수 분 소요될 수 있음)...\n'
    if ( cd "$GSTACK_DIR" && bash ./setup ); then green "gstack 설치 완료 (/office-hours, /review, /qa, /ship 등)"; else red "gstack setup 실패. 수동: cd $GSTACK_DIR && bash ./setup"; fi
  else
    red "gstack setup 스크립트를 찾지 못했습니다: $GSTACK_DIR/setup"
  fi
else
  red "git 없어 gstack 설치를 건너뜁니다."
fi

# ----------------------------------------------------------------------------
cyan ""; cyan "=== 4. agentmemory 전역 설치 (영속 메모리) ==="
if have npm; then
  if have agentmemory; then green "agentmemory $(agentmemory --version) 이미 설치됨"; else
    printf '  -> @agentmemory/agentmemory 전역 설치 중...\n'
    if npm install -g @agentmemory/agentmemory; then green "agentmemory 설치 완료"; else red "agentmemory 설치 실패"; fi
  fi
  yellow "MCP 연결은 Claude Code에서 한 번만 실행하세요: agentmemory connect claude-code"
else
  red "npm 없어 agentmemory 설치를 건너뜁니다."
fi

# ----------------------------------------------------------------------------
cyan ""; cyan "=== 5. Claude Code 내부에서 실행할 /plugin 명령 ==="
OUT="$SCRIPT_DIR/claude-plugin-commands.txt"
cat > "$OUT" <<'EOF'
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
EOF
cat "$OUT"
green "위 명령을 '$OUT' 에도 저장했습니다."

# 클립보드 복사 시도 (있으면)
if have pbcopy; then pbcopy < "$OUT" && green "클립보드(pbcopy)에 복사됨";
elif have xclip; then xclip -selection clipboard < "$OUT" && green "클립보드(xclip)에 복사됨";
elif have clip.exe; then clip.exe < "$OUT" && green "클립보드(clip.exe)에 복사됨"; fi

# --- 개인 스킬 설치 (이 저장소의 skills/ 를 ~/.claude/skills 로) -------------
# 남이 만든 스킬이 아니라 «내 규칙» 을 담은 스킬이다. curl | bash 로 실행할 때는
# 로컬 파일이 없으므로 raw.githubusercontent.com 에서 직접 받는다.
cyan ""; cyan "=== 개인 스킬 설치 ==="
RAW_BASE="https://raw.githubusercontent.com/jominhyeong97/claude-skills-setup/main/skills"
for sk in notion-docs; do
  mkdir -p "$HOME/.claude/skills/$sk"
  if curl -fsSL "$RAW_BASE/$sk/SKILL.md" -o "$HOME/.claude/skills/$sk/SKILL.md"; then
    green "$sk 설치 완료"
  else
    echo "  [X] $sk 설치 실패 — $RAW_BASE/$sk/SKILL.md 를 확인하세요"
  fi
done

cyan ""; cyan "=== 완료 ==="
echo "1) npx 스킬 + gstack + agentmemory 는 자동 설치됨."
echo "2) Claude Code 를 '재시작'한 뒤 위 /plugin 명령을 붙여넣어 마무리하세요."
echo "   (새로 설치된 스킬/플러그인은 Claude Code 를 다시 켜야 목록에 나타납니다.)"
echo "3) 메모리 영속화: Claude Code 안에서 'agentmemory connect claude-code' 1회 실행."
