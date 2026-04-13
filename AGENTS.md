# Repository Guidelines

## Project Structure & Module Organization
This repository is a Neovim configuration written in Lua.

- `init.lua`: entrypoint; loads core modules in `lua/`.
- `lua/config/`: startup and editor lifecycle setup (`lazy.lua`, `autocmds.lua`).
- `lua/plugins/`: plugin specs by concern (`editor.lua`, `ui.lua`, `lsp.lua`, `formatting.lua`, `filesystem.lua`, `colorscheme.lua`).
- `lua/plugins/lang/`: language-specific plugin/LSP configuration.
- `lua/keymaps.lua`, `lua/options.lua`, `lua/commands.lua`: global UX defaults and custom commands.
- `lazy-lock.json`: pinned plugin versions managed by `lazy.nvim`.
- `mise.toml`: local tool version config (`stylua`).

## Build, Test, and Development Commands
- `nvim`: start Neovim with this config.
- `nvim --headless "+Lazy! sync" +qa`: install/update plugins and refresh lockfile state.
- `nvim --headless "+checkhealth" +qa`: run Neovim health checks for providers/tools.
- `stylua .`: format Lua files (configured via `mise.toml` and repo style).

Use `:Lazy`, `:checkhealth`, and `<leader>cf` (Conform) interactively when validating changes.

## Coding Style & Naming Conventions
- Lua uses spaces with 2-space indentation (`.editorconfig`).
- Keep modules focused: one responsibility per file (options, keymaps, plugin group, or language).
- Use lowercase, descriptive filenames (for example `lua/plugins/lang/javascript.lua`).
- Prefer small, explicit plugin specs that `return` tables and group related keymaps with clear `desc` labels.
- Run `stylua` before committing.

## Testing Guidelines
There is no dedicated automated test suite in this repo. Validate changes by:

1. Running `nvim --headless "+checkhealth" +qa`.
2. Opening `nvim` and confirming startup has no errors.
3. Exercising affected workflows (keymaps, LSP attach behavior, formatting/linting on save).

For language-specific changes, verify the relevant formatter/linter is installed (for example `eslint`, `black`, `gofmt`, `ocamlformat`).

## Commit & Pull Request Guidelines
- Keep commit messages short and imperative (current history favors concise subjects like `update`).
- Prefer slightly more specific subjects when possible, e.g. `lsp: adjust ts_ls root detection`.
- PRs should include:
  - What changed and why.
  - Any manual verification steps performed.
  - Screenshots or short clips for visible UI behavior changes (optional but helpful).
