# Claude Code 스킬 통합 설치 (My Skills Setup)

Notion "👨‍💻 Claude Code SKILLs" 페이지의 **7개 도구 + gstack**을 새 PC에서 한 번에 설치하기 위한 패키지입니다.

## 빠른 시작

### Windows (권장)
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### macOS / Linux / WSL
```bash
bash install.sh
```

## ⚠️ 왜 "완전 자동" 한 방이 아닌가?

이 도구들은 설치 경로가 **두 종류**입니다.

| 설치 방식 | 셸에서 자동? | 대상 |
|---|---|---|
| `npx skills add ...` | ✅ 자동 | sf-skills, Skill Creator, Find Skills |
| `git clone` + `./setup` | ✅ 자동 (Bun 자동 설치) | gstack |
| Claude Code `/plugin ...` 슬래시 명령 | ⚠️ 수동 (대화형) | claude-hud, OMC, Superpowers, PPTX |

Claude Code 슬래시 명령은 **Claude Code를 실행한 상태에서** 입력해야 하므로 일반 셸 스크립트로 자동화할 수 없습니다.
그래서 스크립트는 (1) npx 스킬을 자동 설치하고, (2) 나머지 `/plugin` 명령을 **클립보드에 복사 + `claude-plugin-commands.txt` 파일로 저장**해 줍니다. Claude Code를 켜고 붙여넣기만 하면 됩니다.

## 설치되는 도구

| # | 도구 | 설치 방법 | 비고 |
|---|---|---|---|
| 1 | claude-hud (상태바 HUD) | `/plugin install claude-hud` | Claude Code v1.0.80+ 필요 |
| 2 | oh-my-claudecode (OMC) | `/plugin install oh-my-claudecode` | tmux 권장(team 기능) |
| 3 | Superpowers | `/plugin install superpowers@claude-plugins-official` | |
| 4 | sf-skills | `npx skills add Jaganpro/sf-skills` | SF CLI/Python 선택 |
| 5 | PPTX | `/plugin install document-skills@anthropic-agent-skills` | document-skills 패키지에 포함 |
| 6 | Skill Creator | `npx skills add anthropics/skills --skill skill-creator` | |
| 7 | Find Skills | `npx skills add vercel-labs/skills --skill find-skills` | |
| 8 | gstack | `git clone … ~/.claude/skills/gstack && ./setup` | Bun 필요(스크립트가 자동 설치), ~50개 슬래시 커맨드 |

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

# gstack (Bun 필요: npm i -g bun)
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup
```

## 참고
- OMC npm 패키지명은 GitHub 이름과 달리 `oh-my-claude-sisyphus` 입니다 (`npm i -g oh-my-claude-sisyphus@latest`).
- claude-hud는 git 저장소 안에서 `/claude-hud:setup`을 실행해야 정상 동작합니다.
