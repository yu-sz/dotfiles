# CLAUDE.md

## Commands

```bash
nrs                # Apply Nix config changes (macOS: nh darwin switch, Linux: nh home switch)
```

Other tasks are managed by `just`. Run `just` to see all available recipes.

No tests or build system.

## Symlink Strategy

All configs follow the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/). New config files must be placed under `config/` and symlinked to `~/.config/`.

`config/*` → `~/.config/`

Special cases:

- `config/claude/*` → `~/.claude/`（`nix/home/agents/claude-code.nix` が管理）
- `config/agents/skills/*` → `~/.agents/skills/` と `~/.claude/skills/`（`nix/home/agents/skills.nix` が skill 単位で symlink。新規 skill は `git add` + `nrs` が必要）
- `config/agents/AGENTS.md` → `~/.codex/AGENTS.md`, `~/.gemini/AGENTS.md`
- `config/zsh/.zshenv` → `~/.zshenv`

Symlinks are declared individually in `nix/home/symlinks.nix`. When adding a new **top-level** file or directory under `config/`, add an entry there. Files inside an already-linked directory need no change.

## AI Agents

- `config/agents/` が Claude Code / Codex / Gemini CLI 共通の正（AGENTS.md / skills）。詳細は [ADR](docs/adr/2026-09-12-ai-agents-declarative-management.md)
- `config/{claude,codex,gemini}` の base（`settings.json` / `config.toml`）は symlink ではなく、`agents-sync` が base ⊕ Nix 生成 MCP ⊕ `*.local.*` を深マージした実ファイルを `~/.claude` 等へ生成する（`nrs` の activation / `just agents-sync`）
- エージェントの実行時変更（`/model` 等）は `just agents-diff` で確認でき、次の `nrs` で base に戻る
- MCP サーバー定義は `nix/home/agents/mcp-servers.nix` に集約（秘匿値は `config/zsh/eager/local.zsh` で export し `${VAR}` 参照）
- ロールバック注意: `darwin-rebuild rollback` では agents-sync の生成物は戻らない。旧世代の activation を再実行すると戻る

## Multi-Machine Strategy

- `darwinConfigurations` in `flake.nix` manages per-host macOS configurations
- `homeConfigurations` in `flake.nix` manages standalone home-manager for Linux
- `specialArgs` passes `username` to absorb differences across machines
- Adding a new machine is automated by `scripts/bootstrap.sh`

## Nix Package Management

| Category              | macOS                                          | Linux                     |
| --------------------- | ---------------------------------------------- | ------------------------- |
| CLI tools (shared)    | `nix/home/packages/`                           | ←                         |
| OS-specific tools     | `nix/home/darwin.nix`                          | `nix/home/linux.nix`      |
| GUI apps              | `nix/hosts/darwin-shared.nix` (homebrew.casks) | `nix/home/linux.nix`      |
| Fonts                 | `nix/hosts/darwin-shared.nix` (fonts.packages) | `nix/home/linux.nix`      |
| System packages (apt) | —                                              | `config/apt/packages.txt` |
| Custom packages       | `nix/overlays/`                                | ←                         |

Exceptions: `wezterm` は macOS では Homebrew cask（aarch64-darwin の nixpkgs 版が未キャッシュで CI タイムアウトするため。09cb343 参照）。`ghostty-bin` / `vscode` は GUI アプリだが Nix 管理。

## Nix Flake Workflow

- Nix flake only sees Git-tracked files. **Always `git add` after creating new files.**
- Run `git status` before `nrs` to check for untracked files.
- When introducing new tools: add package and apply first, then switch configs. Never reference uninstalled tools.
- `nrs` requires sudo on macOS (`nh darwin switch`). Do not run directly — ask the user to run `! nrs` instead.
- `.zshenv` has `unsetopt GLOBAL_RCS`, so HM's `hm-session-vars.sh` is never sourced. Environment variables set via `home.sessionVariables` won't work — use explicit paths instead.

## Lua Config Files

All Lua configs (Neovim, WezTerm, Yazi): module pattern with LuaCATS annotations, `snake_case` naming.

## Skills

Always load the corresponding skill before starting these tasks. Never guess formats without loading the skill first.

- **ADR / Plans**: Run `/writing-adr-plans` and follow its workflow and format. Keep Plans updated during implementation
