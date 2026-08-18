# Claude Code 스킬 통합 설치 (My Skills Setup)

Notion "👨‍💻 Claude Code SKILLs" 페이지의 **11개 도구 + gstack + agentmemory**를 새 PC에서 한 번에 설치하기 위한 패키지입니다.

## 빠른 시작

### Windows (권장) — 명령 한 줄

```powershell
irm https://raw.githubusercontent.com/jominhyeong97/claude-skills-setup/main/install-all.ps1 | iex
```

실행이 막히면(실행 정책 오류):

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/jominhyeong97/claude-skills-setup/main/install-all.ps1 | iex"
```

<details>
<summary>저장소를 클론해서 로컬 파일로 실행하려면</summary>

```powershell
powershell -ExecutionPolicy Bypass -Command "iex ([IO.File]::ReadAllText('.\install-all.ps1',[Text.Encoding]::UTF8))"
```

`-File .\install-all.ps1` 은 쓰지 마세요. 이 파일은 BOM 없는 UTF-8 이라 PowerShell 5.1 의 `-File` 이 ANSI 로 읽어 한글이 깨지고 파싱에 실패합니다.
(BOM 을 붙이면 반대로 `irm | iex` 가 U+FEFF 때문에 깨지므로, BOM 없이 두고 로컬 실행 시 위처럼 UTF-8 로 명시 디코딩합니다.)

</details>

### macOS / Linux / WSL
```bash
bash install.sh
```

## ✅ 이제 완전 자동입니다 (2026-08-18)

전에는 `/plugin` 슬래시 명령을 Claude Code 안에서 직접 붙여넣어야 했습니다. `claude` CLI 의 `plugin` 서브커맨드로 전부 자동화해서 **붙여넣기 단계를 없앴습니다.**

| 설치 방식 | 자동? | 대상 |
|---|---|---|
| `npx skills add ...` | ✅ | sf-skills, Skill Creator, Find Skills, **AgentMemory(8 skills)** |
| Bun 공식 설치기 | ✅ | `~/.bun` (gstack 전제조건) |
| `git clone` + `./setup` | ✅ | **gstack (슬래시 커맨드 55종)** |
| `npm install -g` | ✅ | **agentmemory MCP 서버** |
| `claude plugin install ...` | ✅ | claude-hud, OMC, Superpowers, PPTX, **Karpathy, Understand-Anything, claude-video** |

`claude` CLI 가 없는 환경에서는 마지막 항목만 기존처럼 **클립보드 복사 + `claude-plugin-commands.txt` 저장**으로 자동 폴백합니다.

### 설치 후 수동으로 할 일 (3가지뿐)
1. Claude Code **재시작** — 새 스킬/플러그인은 재시작 후 목록에 나타납니다
2. `agentmemory connect claude-code` 1회
3. `/claude-hud:setup` 1회

### 📋 실패는 조용히 넘어가지 않습니다
스크립트 마지막에 **항목별 OK/FAIL 요약표**가 출력됩니다.

> 이 기능이 없던 시절, `npm install -g bun` 이 실패해 gstack 이 몇 달간 누락됐는데도
> 스크립트가 "완료"로 끝나 아무도 몰랐던 일이 있었습니다. 그래서 추가했습니다.

## 설치되는 도구

| # | 도구 | 설치 방법 | 비고 |
|---|---|---|---|
| 1 | claude-hud (상태바 HUD) | `/plugin install claude-hud` | Claude Code v1.0.80+ 필요 |
| 2 | oh-my-claudecode (OMC) | `/plugin install oh-my-claudecode` | tmux 권장(team 기능) |
| 3 | Superpowers | `/plugin install superpowers` (`marketplace add obra/superpowers`) | |
| 4 | sf-skills | `npx skills add Jaganpro/sf-skills` | SF CLI/Python 선택 |
| 5 | PPTX | `/plugin install document-skills@anthropic-agent-skills` | document-skills 패키지에 포함 |
| 6 | Skill Creator | `npx skills add anthropics/skills --skill skill-creator` | |
| 7 | Find Skills | `npx skills add vercel-labs/skills --skill find-skills` | |
| 8 | gstack | `git clone … ~/.claude/skills/gstack && ./setup` | Bun 필요(스크립트가 공식 설치기로 자동 설치), 슬래시 커맨드 55종 |
| 9 | Karpathy Guidelines | `/plugin install andrej-karpathy-skills` (`marketplace add multica-ai/andrej-karpathy-skills`) | LLM 코딩 실수 방지 4룰 (CLAUDE.md) |
| 10 | Understand-Anything | `/plugin install understand-anything` (`marketplace add Lum1104/Understand-Anything`) | `/understand` 로 코드베이스 지식 그래프 생성 |
| 11 | claude-video | `/plugin install watch` (`marketplace add bradautomates/claude-video`) | `/watch <URL>` 영상 시청, Whisper용 Groq/OpenAI 키 필요 |
| 12 | agentmemory | `npm install -g @agentmemory/agentmemory` + `agentmemory connect claude-code` | 영속 메모리 MCP 서버 + 8개 네이티브 스킬 |

## 사전 요구사항
- **Node.js LTS** (npx 스킬 설치에 필수) — 스크립트가 winget으로 자동 설치 시도
- **git**
- **Claude Code CLI** (`/plugin` 명령용)
- **tmux** (선택, OMC team 기능) — Windows는 WSL 권장

## 수동 설치 (스크립트 없이)
`claude-plugin-commands.txt`의 슬래시 명령을 Claude Code에 붙여넣고,
아래 npx 명령을 셸에서 실행하면 동일합니다.
```bash
npx skills add Jaganpro/sf-skills
npx skills add https://github.com/anthropics/skills --skill skill-creator
npx skills add https://github.com/vercel-labs/skills --skill find-skills
npx skills add rohitg00/agentmemory       # agentmemory 8 native skills

# gstack (Bun 필요: powershell -c "irm bun.sh/install.ps1 | iex"  또는  curl -fsSL https://bun.sh/install | bash)
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup

# agentmemory MCP 서버 (영속 메모리)
npm install -g @agentmemory/agentmemory
# Claude Code 안에서 1회:  agentmemory connect claude-code
```

## 참고
- OMC npm 패키지명은 GitHub 이름과 달리 `oh-my-claude-sisyphus` 입니다 (`npm i -g oh-my-claude-sisyphus@latest`).
- claude-hud는 git 저장소 안에서 `/claude-hud:setup`을 실행해야 정상 동작합니다.
