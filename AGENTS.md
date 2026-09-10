# Repository Guidelines

## Project Structure & Module Organization
This repository is a Neovim configuration written in Lua, targeting **Neovim 0.12+**.
It uses Neovim's built-in plugin manager (`vim.pack`) and native LSP — there is no
lazy.nvim, no mason, and no nvim-lspconfig.

- `init.lua`: entrypoint. Sets leaders, calls `require("config.pack")`, loads core
  modules and plugin configs, then enables LSP servers via `vim.lsp.enable{...}` and
  installs the `LspAttach` autocmd.
- `lua/config/pack.lua`: the single place plugins are **declared** (`vim.pack.add`).
- `lua/config/autocmds.lua`: editor lifecycle autocmds.
- `lua/plugins/`: plugin **configuration** by concern (`editor.lua`, `ui.lua`,
  `lsp.lua`, `formatting.lua`, `filesystem.lua`, `colorscheme.lua`). These are
  imperative modules — they call `require("x").setup{}` and `vim.keymap.set` at load
  time. They do *not* return spec tables.
- `lsp/*.lua`: one file per language server, each returning a `vim.lsp.Config` table.
  Neovim picks these up from the `lsp/` runtime directory by filename; the name must
  match the string passed to `vim.lsp.enable`.
- `lua/util/`: small shared helpers (e.g. `jsroot.lua`, which arbitrates between
  `denols` and `ts_ls`).
- `lua/keymaps.lua`, `lua/options.lua`, `lua/commands.lua`: global UX defaults and
  custom commands.
- `nvim-pack-lock.json`: pinned plugin revisions. **Managed automatically by
  `vim.pack`** — do not hand-edit. The literal quotes in `"version": "'main'"` are
  deliberate (Lua-literal serialization), not corruption.
- `mise.toml`: pinned tool versions (`mise install` to provision).
- `stylua.toml`: formatting rules. `.githooks/pre-commit` and
  `.github/workflows/lint.yml` both enforce them.
- `docs/nvim-maintenance.md`: the maintenance runbook. Read this before doing any
  update, audit, or dependency work.
- `MIGRATION-PLAN.md`, `plugin-inventory.jsonl`: historical records of the completed
  lazy.nvim → `vim.pack` migration. Superseded; keep for context only.

## Build, Test, and Development Commands
- `nvim`: start Neovim with this config. Missing plugins install on startup.
- `nvim --headless -c 'lua vim.pack.update(nil, { force = true })' -c 'qa!'`: update all
  plugins and refresh the lockfile. Omit `force` to get the confirmation buffer.
- `nvim --headless -c 'lua require("nvim-treesitter").update():wait(600000)' -c 'qa!'`:
  rebuild parsers. **Required after every nvim-treesitter bump** — parser revisions are
  pinned inside the plugin and are invisible to the lockfile.
- `nvim --headless "+checkhealth" +qa`: run health checks.
- `stylua .`: format Lua files. Enforced by CI on every push to `main`.

One-time setup after cloning, to get the auto-formatting pre-commit hook
(git will not enable a tracked hooks dir on its own):

```sh
mise install
git config core.hooksPath .githooks
```

Interactively: `:lsp` (replaces `:LspInfo`/`:LspRestart`), `:restart`, `:checkhealth`,
and `<leader>cf` (Conform).

## Coding Style & Naming Conventions
- Lua uses spaces with 2-space indentation (`.editorconfig`).
- Keep modules focused: one responsibility per file (options, keymaps, plugin group,
  or one LSP server).
- Use lowercase, descriptive filenames (for example `lua/plugins/formatting.lua`).
- `lsp/*.lua` files return a table; `lua/plugins/*.lua` files execute setup calls.
  Don't mix the two contracts.
- Group related keymaps with clear `desc` labels. Before adding a `<leader>` mapping,
  check it isn't already taken — a later `vim.keymap.set` silently overwrites an
  earlier one.
- Formatting is automated: the pre-commit hook reformats fully-staged Lua files
  and re-stages them. A file that is staged *and* has unstaged edits is only
  checked, never rewritten, so the hook can't sweep unstaged work into a commit —
  it fails and asks you to run `stylua .` yourself.
- Use `-- stylua: ignore` (on its own line, with no trailing text, or the
  directive is not recognised) to protect a block where the formatter's output is
  worse — e.g. the treesitter parser list in `lua/plugins/editor.lua`.

## Testing Guidelines
There is no automated test suite. Validate changes by:

1. `nvim --headless -c 'qa!'` — must exit 0 with no output.
2. `nvim --headless "+checkhealth" +qa` — compare warnings against the previous run.
3. Opening a real file per affected language and confirming the server attaches
   (`:lsp`), formatting works (`<leader>cf`), and diagnostics appear.

Note that `:checkhealth vim.deprecated` only reports deprecations that actually fired
in the current session — a headless run will almost always say "no deprecated
functions detected". It is not a static scanner.

For language-specific changes, verify the relevant formatter/linter binary is on
`PATH` (`command -v prettierd`, etc.). conform.nvim and nvim-lint both fail *silently*
when a tool is missing.

## Commit & Pull Request Guidelines
- Keep commit messages short and imperative.
- Prefer specific subjects, e.g. `lsp: arbitrate denols vs ts_ls by root depth`.
- PRs should include:
  - What changed and why.
  - Any manual verification steps performed.
  - Screenshots or short clips for visible UI behavior changes (optional but helpful).
