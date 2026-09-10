# Neovim Config Maintenance Runbook

Maintenance procedure for **this** config: Neovim **0.12.5**, built-in `vim.pack`
plugin manager, native LSP (`lsp/*.lua` + `vim.lsp.enable`), nvim-treesitter
`main` branch. No lazy.nvim, no nvim-lspconfig.

**Source policy.** Every claim below is cited to a primary source. Local runtime
docs are authoritative for this exact build; `$VIMRUNTIME` here resolves to
`/opt/homebrew/Cellar/neovim/0.12.5_1/share/nvim/runtime` (verified via
`nvim --headless -c 'echo $VIMRUNTIME' -c q`). Upstream URLs are given where the
fact lives outside the local tree.

**Verified against this machine on 2026-09-10** — the "Current state" callouts
are point-in-time audit results, not permanent facts. Re-run the checklist to
refresh them.

---

## 1. The checklist

Run top to bottom. Steps marked **(restart)** need `:restart` afterwards
(`:restart` is new in 0.12 and restores the session; `:restart!` does not —
`$VIMRUNTIME/doc/news.txt`, EDITOR under `*news-features*`).

### A. Baseline — before changing anything

1. `git -C ~/.config/nvim status` — commit or stash. The lockfile must be
   version-controlled for any of the rollback steps to work
   (`$VIMRUNTIME/doc/pack.txt`, `*vim.pack-lockfile*`).
2. `nvim --version` — confirm the version you are maintaining against.
3. `:checkhealth` — capture a clean "before" baseline. Headless variant:
   `nvim --headless "+checkhealth" "+w! /tmp/health-before.txt" +qa!`
4. `:checkhealth vim.pack` — must be green *before* you update. It cross-checks
   every lockfile entry against the actual git HEAD on disk
   (`$VIMRUNTIME/lua/vim/pack/health.lua`, `check_plugin_lock_data`).

### B. Update plugins

5. `:lua vim.pack.update()` — downloads, then opens a **confirmation buffer** in
   a new tabpage. Review it. `:write` to confirm, `:quit` to discard.
   Navigate plugin sections with `]]` / `[[`; `gO` for an outline; `K` for
   details at cursor; `gra` for per-plugin code actions ("update", "skip
   updating", "delete") (`$VIMRUNTIME/doc/pack.txt`, `*vim.pack.update()*`).
6. **(restart)** `:restart` to load the updated code.
7. `git -C ~/.config/nvim diff -- nvim-pack-lock.json` — review which revisions
   actually moved.

### C. Re-sync everything downstream of the plugin bump

8. `:TSUpdate` — **mandatory after any nvim-treesitter bump.** Parser revisions
   are pinned inside the plugin, not in your lockfile (see §5).
9. `:checkhealth nvim-treesitter` — confirms tree-sitter CLI ≥ 0.26.1, ABI, and
   per-language query status.
10. `:checkhealth vim.lsp` — check "Enabled Configurations" for unknown
    filetypes and stale keys (see §4).
11. `:ConformInfo` and/or `:checkhealth conform` — verify formatter binaries.
12. Verify nvim-lint binaries **manually** — nvim-lint ships no healthcheck
    (see §7).

### D. Audit

13. `:checkhealth vim.deprecated` — but read §2 first: it only reports
    deprecations **actually triggered this session**, so exercise your config
    before trusting a green result.
14. `:h deprecated-0.12` — read the list for the version you are on.
15. `:h news` — skim `*news-breaking*` and `*news-deprecations*`.
16. Check plugins for archival / dormancy / upstream renames (see §6):
    ```sh
    for repo in $(python3 -c "
    import json; d=json.load(open('nvim-pack-lock.json'))
    [print(v['src'].replace('https://github.com/','')) for v in d['plugins'].values()]"); do
      gh api "repos/$repo" --jq '[.full_name,(.archived|tostring),.pushed_at]|@tsv'
    done
    ```
    A `full_name` that differs from what you asked for means the repo was
    **renamed or transferred**.
17. `stylua .` — repo style gate (`AGENTS.md`, "Coding Style").

### E. If something broke

18. Revert the lockfile, restart, and re-pin — see §1.6 "Rollback".

---

## 2. Plugin management with `vim.pack`

### What `vim.pack` actually is

`vim.pack` is new in 0.12 — listed under `*news-features*` → PLUGINS: "Built-in
plugin manager: |vim.pack|" (`$VIMRUNTIME/doc/news.txt`). It did not exist in
0.11. The docs still label it **experimental**: "WARNING: It is still considered
experimental, yet should be stable enough for daily use."
(`$VIMRUNTIME/doc/pack.txt`, `*vim.pack*`).

It manages plugins **exclusively** in `site/pack/core/opt` under the `data`
stdpath — on this machine
`~/.local/share/nvim/site/pack/core/opt`. "It is assumed that all plugins in the
directory are managed exclusively by `vim.pack`."
(`$VIMRUNTIME/doc/pack.txt`, `*vim.pack-directory*`). Confirmed in source:
`get_plug_dir()` in `$VIMRUNTIME/lua/vim/pack.lua`.

It requires `git` and uses a **partial blobless clone** plus `git checkout`
(`$VIMRUNTIME/doc/pack.txt`, `*vim.pack.add()*`).

### There are no `:Pack` commands

**`vim.pack` in 0.12.5 is a Lua API only.** Verified two ways:

- `$VIMRUNTIME/plugin/` contains no pack plugin file (only `editorconfig.lua`,
  `man.lua`, `net.lua`, `osc52.lua`, `shada.lua`, `spellfile.lua`, and the
  legacy vim plugins).
- Runtime query returned `Pack-related user commands: NONE`:
  ```sh
  nvim --headless -c 'lua local c=vim.api.nvim_get_commands({}); ...' -c 'qa!'
  ```

So you invoke it as `:lua vim.pack.update()`, `:lua vim.pack.del({...})`,
`:lua vim.pack.get()`. (Contrast `:lsp`, which *does* exist as a command in 0.12
— `$VIMRUNTIME/doc/lsp.txt`, `*:lsp*`.)

> `MIGRATION-PLAN.md` in this repo lists "`:PackUpdate` (TBD)" as the
> replacement for `:Lazy`. That command does not exist in core. If you want one,
> you have to define it yourself in `lua/commands.lua`.

### The lockfile is NATIVE, not hand-rolled

`nvim-pack-lock.json` in this repo is **core Neovim's own lockfile**, not custom
tooling. The doc names the exact path:

> "The latest state of all managed plugins is stored inside a
> *vim.pack-lockfile* located at `$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json`."
> — `$VIMRUNTIME/doc/pack.txt`, `*vim.pack-lockfile*`

Source confirms: `lock_get_path()` returns
`vim.fs.joinpath(vim.fn.stdpath('config'), 'nvim-pack-lock.json')`
(`$VIMRUNTIME/lua/vim/pack.lua:231-233`).

Schema, from `$VIMRUNTIME/lua/vim/pack.lua:216-221`:

```lua
--- @class (private) vim.pack.LockData
--- @field rev string       Latest recorded revision.
--- @field src string       Plugin source.
--- @field version? string|vim.VersionRange  Plugin `version`, as supplied in `spec`.
```

Behaviour worth internalising:

- **Put it in version control.** "For a more robust config treat lockfile like
  its part: put under version control, etc. In this case all plugins from the
  lockfile will be installed at once and at lockfile's revision (instead of
  inferring from `version`)." (`pack.txt`, `*vim.pack-lockfile*`)
- **Never hand-edit it.** "Lockfile should not be edited by hand." Corrupted
  entries for *installed* plugins are auto-repaired — including after deleting
  the whole file — but `version` fields go missing for not-yet-added plugins.
  (`pack.txt`, same section; repair logic at `lock_repair()` /
  `lock_sync()`, `$VIMRUNTIME/lua/vim/pack.lua:842-951`.)
- The lockfile wins on first call. Reconciliation happens "on the very first
  `vim.pack` function call to ensure that lockfile is aligned with what is
  actually on the disk."

### Gotcha: `version` is stored with literal quotes

Your lockfile contains:

```json
"nvim-treesitter": {
  "rev": "4916d6592ede8c07973490d9322f187e07dfefac",
  "src": "https://github.com/nvim-treesitter/nvim-treesitter",
  "version": "'main'"
}
```

The `'main'` (quotes inside the JSON string) looks like corruption. **It is
not** — it is deliberate. `lock_write()` serialises a string version as a Lua
literal so that a `vim.VersionRange` can round-trip through `tostring()`:

```lua
l_data.version = type(version) == 'string' and ("'%s'"):format(version) or tostring(version)
```
— `$VIMRUNTIME/lua/vim/pack.lua:822-830`

Do not "fix" it. `:checkhealth vim.pack` accepts it (`is_version()` only checks
the type, `$VIMRUNTIME/lua/vim/pack/health.lua`).

### Pinning, freezing, switching — what's native vs. what needs tooling

| Goal | Native mechanism | Source |
|---|---|---|
| Reproduce exact revisions on another machine | Commit the lockfile, pull, `:restart`, then `vim.pack.update(nil, { target = 'lockfile' })` | `pack.txt` → "Synchronize config across machines" |
| Freeze one plugin | Set `version` in `init.lua` to its current `rev` from the lockfile | `pack.txt` → "Freeze plugin from being updated" |
| Unfreeze | Set `version` back to a branch/tag/range, `:restart` | `pack.txt` → "Unfreeze plugin…" |
| Semver range pinning | `version = vim.version.range('1.0')` — requires the repo to tag semver `v<major>.<minor>.<patch>` | `pack.txt` → `*vim.pack.Spec*` |
| Rollback after a bad update | Revert the lockfile in git, `:restart`, `vim.pack.update({'x'}, { offline = true, target = 'lockfile' })` | `pack.txt` → "Revert plugin after an update" |
| **Auto-update / background checker** | **None.** No equivalent to lazy.nvim's checker. | (absence — no such option in `vim.pack.update()` opts) |
| **Lazy-loading by event/cmd/ft** | **None** in `vim.pack`. `opts.load = false` behaves like `:packadd!`; anything conditional you write yourself. | `pack.txt` → `*vim.pack.add()*` `{load}` |
| **Build/post-install hooks** | Via the `PackChanged` autocommand, not a spec field. | `pack.txt` → `*vim.pack-events*` |

Semver caveat, verbatim: "Target plugins should be Git repositories with
versions as named tags following semver convention `v<major>.<minor>.<patch>`
(with or without `v` prefix). Like `v1.2.0` or `1.2.0`, but not `1.2` or `v1`."
(`pack.txt`, `*vim.pack*`).

### Rollback, step by step

From `$VIMRUNTIME/doc/pack.txt`, "Revert plugin after an update":

1. Revert the lockfile to its pre-update state:
   - tracked: `git checkout HEAD -- nvim-pack-lock.json`
   - untracked: read `nvim-pack.log` in the `log` stdpath
     (`~/.local/state/nvim/nvim-pack.log`), find the prior revisions, and edit
     carefully.
2. `:restart`
3. `:lua vim.pack.update({ 'plugin' }, { offline = true, target = 'lockfile' })`
4. Read the confirmation buffer, confirm with `:write`.

"Every actual update is logged in `nvim-pack.log` file inside `log`
|standard-path|" (`pack.txt`, `*vim.pack.update()*`) — that log is your only
recourse if the lockfile isn't in git.

### Removing a plugin

Order matters (`pack.txt`, "Remove plugins from disk"):

1. Delete the spec from `vim.pack.add()` **first**, or it gets reinstalled.
2. `:restart`
3. `:lua vim.pack.del({ 'plugin-name' })`

To list orphans:

```lua
vim.iter(vim.pack.get())
 :filter(function(x) return not x.active end)
 :map(function(x) return x.spec.name end)
 :totable()
```

### Two sharp edges in `vim.pack.add()`

- **`add()` never verifies the revision on disk.** "If plugin is already present
  on disk, there are no checks about its current revision. The specified
  `version` can be not the one actually present on disk. Execute
  |vim.pack.update()| to synchronize." (`pack.txt`, `*vim.pack.add()*`)
  → Changing `version` in `init.lua` does nothing until you run `update()`.
- **Changing `src` deletes the plugin.** "If exists, check if its `src` is the
  same as input. If not - delete immediately to clean install from the new
  source." (same section) — so a bare URL typo silently wipes and re-clones.

### `vim.pack` does not follow default-branch renames

> "It doesn't update source's default branch if it has changed (like from
> `master` to `main`). To have `version = nil` point to a new default branch,
> re-install the plugin (|vim.pack.del()| + |vim.pack.add()|)."
> — `pack.txt`, `*vim.pack.update()*`

This matters specifically for nvim-treesitter (§5).

---

## 3. Auditing deprecated / removed APIs

### The lifecycle

Neovim uses a three-stage policy
(<https://github.com/neovim/neovim/blob/master/MAINTAIN.md>):

| Stage | Behaviour |
|---|---|
| **Soft deprecation** (release N) | "Use of the deprecated feature will still work." Documentation + `@deprecated` annotation only. No user-visible warning. For Lua, `vim.deprecate()` is called with **current minor + 2** as the removal version. |
| **Hard deprecation** (release N+1) | "Use of the deprecated feature will still work but should issue a warning." |
| **Removal** (release N+2) | Gone. |

Example from the policy: soft-deprecated in v0.10 → hard-deprecated in v0.11 →
removed in v0.12.

The implementation matches exactly. From `vim.deprecate()`
(`$VIMRUNTIME/lua/vim/_core/editor.lua:1259-1290`):

```lua
-- Show a warning only if feature is hard-deprecated (see MAINTAIN.md).
-- Example: if removal `version` is 0.12 (soft-deprecated since 0.10-dev), show warnings
-- starting at 0.11, including 0.11-dev.
...
local hard_deprecated_since = string.format('nvim-%d.%d', major, minor - 1)
if major == nvim_major and vim.fn.has(hard_deprecated_since) == 0 then
  return   -- still soft-deprecated: stay silent
end
```

So: **a soft-deprecated API produces no message at all.** Silence is not proof
your config is clean.

### `:checkhealth vim.deprecated` is a runtime tracker, not a scanner

This is the single most misleading thing in the deprecation workflow.
`vim.deprecate()` registers each hit into a module-level table, and the
healthcheck merely prints that table:

```lua
function vim.deprecate(name, alternative, version, plugin, backtrace)
  plugin = plugin or 'Nvim'
  if plugin == 'Nvim' then
    require('vim.deprecated.health').add(name, version, traceback(), alternative)
```
— `$VIMRUNTIME/lua/vim/_core/editor.lua:1259-1262`

```lua
local deprecated = {} ---@type [string, table, string][]
function M.check()
  if next(deprecated) == nil then
    health.ok('No deprecated functions detected')
    return
  end
```
— `$VIMRUNTIME/lua/vim/deprecated/health.lua`

Consequences:

- The table is **per-session and in-memory**. Only code paths executed since
  startup can appear.
- A headless `nvim --headless "+checkhealth vim.deprecated" +qa` will almost
  always say "No deprecated functions detected" — it never loaded a real
  buffer, never attached LSP, never triggered your autocmds. That result is
  worthless.
- **Correct usage:** start Nvim normally, open representative files for each
  language you configure, trigger LSP attach, format, lint, use your keymaps —
  *then* run `:checkhealth vim.deprecated`.
- The good part: it does register **soft**-deprecated hits too (registration
  happens before the hard-deprecation gate), so the healthcheck is strictly
  more informative than the notification.

The report distinguishes past from future using `vim.fn.has()`:
`will_be_removed = vim.fn.has(removal_version) == 1 and 'was removed' or 'will be removed'`
(`$VIMRUNTIME/lua/vim/deprecated/health.lua`).

### Static auditing (what actually catches things)

Since the healthcheck can't scan, grep. Read `:h deprecated-0.12`
(`$VIMRUNTIME/doc/deprecated.txt`) for the list, then:

```sh
grep -rnE 'vim\.(diff|lsp\.(client_is_stopped|stop_client|set_log_level|get_log_path|get_buffers_by_client_id))|semantic_tokens\.(start|stop)|codelens\.(refresh|clear|display|save|on_codelens)|util\.stylize_markdown|ownsyntax' \
  ~/.config/nvim --include='*.lua'
```

Also grep for the **renamed keys**, which are easy to miss because they are
table fields, not function names:

```sh
grep -rn 'buffer *=' ~/.config/nvim --include='*.lua'   # autocmd/keymap opts: "buffer" -> "buf"
```

`nvim_create_autocmd`/`get_autocmds`/`exec_autocmds`/`clear_autocmds` and
`vim.keymap.set`/`del` renamed `buffer` → `buf` in 0.12
(`$VIMRUNTIME/doc/deprecated.txt`, `*deprecated-0.12*`, API and LUA sections).
The old name still works — "the old name 'buffer' is still accepted, for
backwards compatibility" (`$VIMRUNTIME/doc/news.txt`, `*news-changed*`) — so
this is soft and **silent**.

> Current state of this repo: **clean** — `grep -rn 'buffer *=' --include='*.lua' .`
> returns nothing. Keep it that way; the old spelling is silent, so it creeps
> back in easily when copying snippets written for 0.11 or earlier.

### What was actually *removed* in 0.12

From `$VIMRUNTIME/doc/news.txt` `*news-breaking*` — these are hard failures, not
warnings:

- Diagnostic signs can no longer be configured via `:sign-define` /
  `sign_define()`.
- `vim.diagnostic.disable()` and `vim.diagnostic.is_disabled()` are gone.
- The legacy signature of `vim.diagnostic.enable()` is gone.
- `vim.diff` → renamed to `vim.text.diff`.
- `vim.lsp.semantic_tokens.start()/stop()` → `enable()`.
- JSON `null` in LSP messages is now `vim.NIL`, not `nil`. **Relevant to this
  repo** — `lsp/basedpyright.lua` inspects raw LSP payloads
  (`workspace_edit.changeAnnotations`, `.documentChanges`); a `vim.NIL` there is
  truthy in Lua, so a `if x then` guard behaves differently than under 0.11.
- The `"all"` option to `Query:iter_matches()` was removed.
- `|ft-query-plugin|` no longer enables `vim.treesitter.query.lint()` by default.
- The "shellmenu" plugin was removed; `tohtml` became opt-in (`:packadd nvim.tohtml`).

---

## 4. The `:checkhealth` workflow

`:checkhealth` with no argument runs everything. Completion lists what is
available; on this config that is:

```
conform  fidget  nvim-treesitter  snacks  vim.deprecated  vim.health
vim.lsp  vim.pack  vim.provider  vim.treesitter  which-key
```
(via `vim.fn.getcompletion("", "checkhealth")`)

New in 0.12: "`:checkhealth` shows a summary in the header for every
healthcheck" (`$VIMRUNTIME/doc/news.txt`, `*news-features*` → UI), and
"`:checkhealth vim.lsp` is now available" (same file, LSP section). Health
modules are auto-discovered from any `lua/<plugin>/health.lua` on `runtimepath`
(`$VIMRUNTIME/doc/health.txt`, `*health-dev*`).

Which ones matter, in priority order:

| Check | Why it matters here | What to look for |
|---|---|---|
| **`vim.pack`** | Highest signal. Cross-validates lockfile ↔ disk ↔ git. | `rev` mismatch, `src` mismatch, non-git dirs, detached-HEAD violations |
| **`vim.lsp`** | Only place that shows the *resolved* merged config. | "Enabled Configurations", unknown-filetype warnings, "Active Clients" |
| **`vim.deprecated`** | Only after exercising the config — see §3. | any WARN |
| **`nvim-treesitter`** | Verifies the toolchain the `main` branch needs. | tree-sitter CLI version, ABI, per-language query grid |
| **`conform`** | Enumerates every formatter binary. | "unavailable: Command '…' not found" |
| **`vim.treesitter`** | Core-side parser ABI compatibility. | ABI outside min 13 / max 15 |
| **`vim.provider`** | Only if you use Python/Ruby/Node remote plugins. | Safe to ignore otherwise |

Cosmetic option: `vim.g.health = { style = 'float' }` renders it in a floating
window (`$VIMRUNTIME/doc/health.txt`, `*g:health*`).

### `:checkhealth vim.pack` in detail

`$VIMRUNTIME/lua/vim/pack/health.lua` runs three phases:

1. **basics** — `git` present; lockfile and plugin dir both present. If one
   exists without the other it warns and tells you which recovery to run.
2. **lockfile** — for every entry: types of `rev`/`src`/`version`; directory
   exists; and then the critical comparison —
   `git rev-list -1 HEAD` vs `lock_data.rev`, and `git remote get-url origin`
   vs `lock_data.src` (resolving Git `insteadOf` aliases via
   `git ls-remote --get-url` before failing).
3. **plugin directory** — every dir must be a git repo, and must be at
   **detached HEAD**: "Detached HEAD is a sign that plugin is managed by
   `vim.pack`." A branch-checked-out plugin gets a warning.

One error message encodes a real-world failure mode worth knowing:

> "This can happen after updating plugins with read-only `$XDG_CONFIG_HOME`"

i.e. if your config dir isn't writable, plugins update on disk but the lockfile
silently doesn't, and you drift.

---

## 5. LSP config hygiene under native `lsp/*.lua`

### Timeline: 0.11 vs 0.12

- `vim.lsp.config()`, `vim.lsp.enable()` and the `lsp/<name>.lua` runtime
  directory landed in **0.11** (`$VIMRUNTIME/doc/news-0.11.txt:275-277`; the
  function docs say `Attributes: Since: 0.11.0`).
- **New in 0.12**: the `:lsp` command family (`:lsp enable|disable|restart|stop`),
  `:checkhealth vim.lsp`, `vim.lsp.is_enabled()`, `vim.lsp.get_configs()`,
  `workspace_required`, `exit_timeout` graduating out of `flags`, and
  `vim.lsp.enable()` now *detaching* non-applicable clients
  (`$VIMRUNTIME/doc/news.txt`, `*news-features*` → LSP; `$VIMRUNTIME/doc/lsp.txt`
  `*:lsp*`).

### Valid keys

An `lsp/<name>.lua` file returns a `vim.lsp.Config`, which **extends**
`vim.lsp.ClientConfig` (`$VIMRUNTIME/doc/lsp.txt:864`).

`vim.lsp.Config` adds (`$VIMRUNTIME/doc/lsp.txt:867-920`):

| Key | Type | Notes |
|---|---|---|
| `cmd` | `string[]` or function | function form receives `(dispatchers, config)` — the second arg is **new in 0.12** |
| `filetypes` | `string[]` | `nil` means ALL filetypes |
| `root_markers` | `(string\|string[])[]` | list order = priority; **nested list = equal priority** |
| `root_dir` | `string` or `fun(bufnr, on_dir)` | must call `on_dir()` or LSP won't activate; can be used to conditionally skip |
| `reuse_client` | `fun(client, config, bufnr): boolean` | 0.12 passes the target buffer |

Inherited from `vim.lsp.ClientConfig` (`$VIMRUNTIME/doc/lsp.txt:1796+`):
`capabilities`, `settings`, `init_options`, `handlers`, `commands`,
`on_attach`, `before_init`, `on_error`, `cmd_cwd`, `cmd_env`, `detached`,
`get_language_id`, `name`, `offset_encoding`, `flags`, `exit_timeout`,
`workspace_required`.

### Unknown keys are silently ignored — the big trap

`vim.lsp.config()` validates only that `cfg` is a table
(`$VIMRUNTIME/lua/vim/lsp.lua:371-385`). At client start, `validate_config()`
checks only three fields:

```lua
local function validate_config(config)
  validate('cmd', config.cmd, validate_cmd, 'expected function or table with executable command')
  validate('reuse_client', config.reuse_client, 'function', true)
  validate('filetypes', config.filetypes, 'table', true)
```
— `$VIMRUNTIME/lua/vim/lsp.lua:475-478`

Anything else you write is carried along and ignored. **A leftover
nvim-lspconfig key produces zero errors and zero warnings — it just does
nothing.**

> **Worked example from this repo (found by this audit, since fixed).**
> `lsp/ts_ls.lua` used to set `single_file_support = false`. That is an
> **nvim-lspconfig** key. It does not exist anywhere in the Neovim 0.12.5
> runtime — verified: `grep -rn "single_file_support" $VIMRUNTIME/` returns
> nothing. It was a no-op, and had been for the whole life of the native-LSP
> migration. `:checkhealth vim.lsp` even printed it back
> (`- single_file_support: false`), which reads like confirmation but is just an
> echo of your own table. It has since been replaced with `workspace_required`.
>
> The native equivalent is **`workspace_required = true`**
> (`$VIMRUNTIME/doc/lsp.txt:1934`, "Server requires a workspace"), enforced at
> `$VIMRUNTIME/lua/vim/lsp.lua:755-758`:
> `'skipping config "%s": workspace_required=true, no workspace found'`.
> `workspace_required` is new in 0.12 ("graduated from experimental
> `flags.exit_timeout`"-era changes, `$VIMRUNTIME/doc/news.txt` LSP section).

Audit command:

```sh
grep -rnE 'single_file_support|autostart|on_new_config|docs *=|default_config' ~/.config/nvim/lsp/
```

### How configs merge

Increasing priority, merged with `vim.tbl_deep_extend(..., 'force')`
(`$VIMRUNTIME/doc/lsp.txt`, `*lsp-config-merge*`):

1. `vim.lsp.config('*', …)`
2. all `lsp/<name>.lua` on `runtimepath`
3. all `after/lsp/<name>.lua` on `runtimepath`
4. `vim.lsp.config('<name>', …)` called anywhere else

Two practical consequences:

- **`after/lsp/<name>.lua` is the override hook** for configs shipped by a
  plugin: "This behavior of the 'after/' directory is a standard Vim feature
  |after-directory| which allows you to override `lsp/*.lua` configs provided by
  plugins (such as nvim-lspconfig)."
- **`vim.lsp.config.<name> = {…}` (table assignment) *replaces*** rather than
  merges: "(Re-)define the 'clangd' configuration (overrides the resolved
  chain)" vs. the function call `vim.lsp.config('clangd', {…})` which merges
  (`$VIMRUNTIME/doc/lsp.txt`, `*vim.lsp.config()*`). Assignment vs. call is a
  semantic difference that looks like pure style.

`vim.lsp.config('*', …)` is where global defaults belong — e.g. the documented
recipe for disabling file watching on large workspaces
(`$VIMRUNTIME/doc/lsp.txt`, `*lsp-defaults*`).

### nvim-lspconfig's role now

nvim-lspconfig is **not deprecated**; it has become a *catalog*. Its README
(<https://github.com/neovim/nvim-lspconfig>) states the legacy framework is what
went away:

> "require('lspconfig') (the legacy 'framework' of nvim-lspconfig) is
> **deprecated** in favor of vim.lsp.config (Nvim 0.11+)."

and

> "nvim-lspconfig itself is **NOT deprecated**. It provides server-specific
> configs."

Minimum supported Neovim is 0.11.3+. Its configs live in `lsp/` and are picked
up automatically by core once the plugin is on `runtimepath`.

**Recommended workflow for this repo (which does not install it):** treat the
upstream `lsp/` directory as reference data. When adding a server, copy
<https://github.com/neovim/nvim-lspconfig/blob/master/lsp/SERVER.lua> into your
own `lsp/SERVER.lua` and strip anything not in the key table above. The core
docs endorse exactly this: "Add this code to the file (or copy an example from
https://github.com/neovim/nvim-lspconfig)" (`$VIMRUNTIME/doc/lsp.txt`,
`*lsp-new-config*`).

### Reading `:checkhealth vim.lsp`

It reports log level/path/size, Active Features, Active Clients, **Enabled
Configurations** (the fully resolved merge), File Watcher status, and Position
Encodings.

It also validates filetype names.

> Current state of this repo — 6 warnings, all "Unknown filetype":
> `gotmpl` (gopls); `ocaml.menhir`, `ocaml.interface`, `ocaml.ocamllex`,
> `reason` (ocamllsp); `yaml.docker-compose` (yamlls).
> These are filetypes Neovim's built-in `vim.filetype` never assigns, so those
> entries can never match a buffer. Either register them with
> `vim.filetype.add()` — the mechanism the docs point to for exactly this
> (`$VIMRUNTIME/doc/lsp.txt:872-886`) — or drop them from `filetypes`.

Note "Active Clients: No active clients" in a headless run is expected — no
buffer was opened. Judge attachment interactively.

---

## 6. nvim-treesitter `main` branch

### Branch status

The `main` branch is the future; `master` is frozen but **still the repository's
default branch**. From the README on `master`
(<https://github.com/nvim-treesitter/nvim-treesitter/tree/master>):

> "The `master` branch is frozen and provided for backward compatibility only.
> All future updates happen on the `main` branch, which will become the default
> branch in the future."

**This is why `version = 'main'` is mandatory** in `lua/config/pack.lua`, and why
it must stay there — recall from §2 that `vim.pack.update()` will *not* follow a
default-branch rename. When upstream eventually flips the default to `main`,
configs relying on `version = nil` silently keep tracking frozen `master`; an
explicit `version = 'main'` is immune. This config already does this correctly
for both `nvim-treesitter` and `nvim-treesitter-textobjects`.

### Requirements

From `$VIMRUNTIME/`-adjacent plugin source
(`~/.local/share/nvim/site/pack/core/opt/nvim-treesitter/lua/nvim-treesitter/health.lua`)
and the README:

- **Neovim ≥ 0.12.0** — `if vim.fn.has('nvim-0.12') ~= 1 then health.error(...)`.
- **tree-sitter CLI ≥ 0.26.1** — `local TREE_SITTER_MIN_VER = { 0, 26, 1 }`;
  a missing CLI is `health.error('tree-sitter-cli not found')`, i.e. a hard
  failure, not a warning. Install it via a package manager, not npm.
- **A C compiler**, plus `curl` and `tar` (both explicitly health-checked).
- **ABI ≥ 13** (`NVIM_TREESITTER_MINIMUM_ABI = 13`).

> Current state: tree-sitter-cli 0.26.8 at `~/.cargo/bin/tree-sitter`, ABI 15,
> tar and curl present. All green. Note the CLI is **not** in `mise.toml`
> (which pins only `stylua`) — it's a cargo install, so it is not reproducible
> from this repo. Worth adding to `mise.toml`.

### The new API

`require('nvim-treesitter')` exposes `setup`, `install`, `update`, `uninstall`,
`get_available`, `get_installed`, `indentexpr`
(`.../nvim-treesitter/lua/nvim-treesitter/init.lua`). Documented in
`.../nvim-treesitter/doc/nvim-treesitter.txt`, `*nvim-treesitter-api*`:

- `setup({install_dir})` — **optional**. "You do not need to call `setup` to use
  this plugin with the default settings!" Default install dir is
  `stdpath('data')/site/`.
- `install(langs, {force, generate, max_jobs, summary})` — **asynchronous**. For
  bootstrapping, `:wait()` on it:
  `require('nvim-treesitter').install({...}):wait(300000)`.
- `update(langs?, {max_jobs, summary})` — "Update the parsers and queries if
  older than the revision specified in the manifest." Also async.
- `get_installed(type?)` — only searches nvim-treesitter's own install dir. To
  see parsers from *any* source, use
  `vim.api.nvim_get_runtime_file('parser/*', true)`.

Commands (`*nvim-treesitter-commands*`): `:TSInstall`, `:TSInstall!` (force),
`:TSInstallFromGrammar`, `:TSUpdate`, `:TSUninstall`, **`:TSLog`** (shows
messages from previous install/update/uninstall — the place to look when an
async install fails silently).

### Highlighting is no longer the plugin's job

There is no `highlight = { enable = true }` any more. Highlighting is core
Neovim's `vim.treesitter.start()`, wired via a `FileType` autocommand or
ftplugin (`.../doc/nvim-treesitter.txt`, `*nvim-treesitter-quickstart*`):

```lua
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'rust', 'javascript', 'zig' },
  callback = function()
    vim.treesitter.start()                                    -- highlighting (core)
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'       -- folds (core)
    vim.wo.foldmethod = 'expr'
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"  -- indent (plugin)
  end,
})
```

> This repo's `lua/plugins/editor.lua` calls `pcall(vim.treesitter.start)` on
> every `FileType` with no pattern — a reasonable "try everything, ignore
> failures" approach. It does **not** set `foldexpr` or `indentexpr`, so
> treesitter folding and indentation are off. That's a choice, not a bug.
>
> Also relevant: 0.12 enables treesitter highlighting for Markdown by default
> (`$VIMRUNTIME/doc/news.txt`, `*news-features*` → DEFAULTS).

### Keeping parsers in sync with the plugin — the actual mechanism

Parser revisions are pinned **inside the plugin**, in
`lua/nvim-treesitter/parsers.lua` — 326 pinned `revision` fields on the
currently installed commit. Example:

```lua
ada = {
  install_info = {
    revision = '6b58259a08b1a22ba0247a7ce30be384db618da6',
    url = 'https://github.com/briot/tree-sitter-ada',
  },
  maintainers = { '@briot' },
  tier = 2,
},
```

They are **not** in `nvim-pack-lock.json`, and `vim.pack.update()` knows nothing
about them. The README is explicit:

> "This plugin is only guaranteed to work with specific versions of language
> parsers" — tied to each plugin revision — and "When upgrading the plugin, you
> must make sure that all installed parsers are updated to the latest version"
> via `:TSUpdate`.

**Therefore: every `vim.pack.update()` that moves the `nvim-treesitter` rev must
be followed by `:TSUpdate`.** Otherwise queries shipped by the new plugin rev
are run against parsers built from an old grammar → query errors, broken
highlighting.

You can automate this with the `PackChanged` event
(`$VIMRUNTIME/doc/pack.txt`, `*vim.pack-events*`), which exists for exactly this
purpose:

```lua
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'nvim-treesitter' and ev.data.kind == 'update' then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      require('nvim-treesitter').update()
    end
  end,
})
```

(That is the documented shape — the doc's own `plug-2` example does
`vim.cmd.packadd` then calls into the plugin. Note the hook must be registered
**before** the first `vim.pack.add()` to also fire on install.)

`:checkhealth nvim-treesitter` then prints a per-language grid with columns
`H L F I J` = Highlights, Locals, Folds, Indents, Injections, plus an explicit
"The following errors have been detected in query files:" section — that is your
verification that plugin and parsers agree.

---

## 7. Detecting abandoned plugins and upstream consolidation

### Signals, in order of reliability

1. **GitHub `archived` flag** — unambiguous. `gh api repos/OWNER/NAME --jq .archived`
2. **Repo rename / transfer** — the `full_name` returned differs from the path
   you requested. GitHub redirects keep `git clone` working, so **nothing
   breaks and nothing warns**; you only find out by asking.
3. **`pushed_at` age** — a heuristic. Small, finished plugins legitimately sit
   still for years.
4. **README deprecation notices** — the treesitter `master` freeze (§5) is only
   discoverable this way; no API surfaces it.
5. **Superseded by Neovim core** — check `$VIMRUNTIME/doc/news.txt`
   `*news-features*` and `$VIMRUNTIME/doc/plugins.txt` for built-ins that now
   cover the plugin's job.

Batch script for signals 1–3 (also step 16 of the checklist):

```sh
cd ~/.config/nvim
for repo in $(python3 -c "
import json; d=json.load(open('nvim-pack-lock.json'))
[print(v['src'].replace('https://github.com/','')) for v in d['plugins'].values()]"); do
  gh api "repos/$repo" --jq '[.full_name,(.archived|tostring),.pushed_at]|@tsv' \
    2>/dev/null || echo -e "$repo\tAPI-ERROR"
done
```

### Current state of this repo (2026-09-10)

**No plugin is archived.** Three things stand out:

**a. `echasnovski/*` was transferred to the `nvim-mini` org.**
Requesting `repos/echasnovski/mini.nvim` returned
`full_name: nvim-mini/mini.nvim`; same for `mini.icons`. It kept working via
GitHub's redirect, and `:checkhealth vim.pack` passed throughout — it compares
`git remote get-url origin` against `lock_data.src`, and the remote URL was
still the literal one originally cloned. Nothing anywhere surfaces a transfer;
you only learn about it by querying the API.

`lua/config/pack.lua` has since been updated to `nvim-mini/mini.nvim`.
**Expect that first `:restart` to delete and re-clone the plugin**, per the §2
rule ("If exists, check if its `src` is the same as input. If not - delete
immediately"). That is normal, just slow, and it rewrites the `src` and `rev`
for `mini.nvim` in the lockfile — review that diff rather than assuming it's
noise.

**b. `mini.icons` was redundant.** `mini.nvim` is the full bundle and already
contains `lua/mini/icons.lua`; the standalone `mini.icons` plugin contains
*only* `lua/mini/icons.lua`. With both installed, both put `lua/mini/` on
`runtimepath`, so which `require('mini.icons')` won depended on `runtimepath`
order. The spec has since been dropped from `lua/config/pack.lua`; per §2,
finish the removal with `:restart` then
`:lua vim.pack.del({ 'mini.icons' })` — dropping the spec alone leaves the
directory on disk and the entry in the lockfile.

**c. `tpope/vim-sleuth` last pushed 2024-09-19** — ~2 years dormant, not
archived. Partly superseded: **editorconfig support is built into Neovim**
(`$VIMRUNTIME/doc/plugins.txt:86`, "Builtin plugin: editorconfig"; shipped as
`$VIMRUNTIME/plugin/editorconfig.lua`, added in 0.9). This repo has a root
`.editorconfig`. sleuth still adds value for *other* repos that lack one — keep
or drop deliberately, but know the overlap.

Dormancy table for the rest (`pushed_at`, informational only): harpoon
2025-10-31, trouble.nvim 2025-10-31, which-key.nvim 2025-10-28,
todo-comments.nvim 2025-11-10. All within a year; all fine.

### Core consolidations to re-check on every Neovim upgrade

0.12 absorbed several plugin categories. Before adding a plugin, check whether
core already does it (all `$VIMRUNTIME/doc/news.txt`, `*news-features*`):

| Category | Core equivalent in 0.12 |
|---|---|
| Plugin manager | `vim.pack` |
| LSP config framework | `vim.lsp.config` / `vim.lsp.enable` / `lsp/*.lua` (0.11) |
| Undo-tree viewer | `:Undotree` |
| Diff tool | `:DiffTool` (compares directories and files) |
| Fetch/download from Lua | `vim.net.request()` |
| TS incremental selection | `v_an` / `v_in` / `v_]n` / `v_[n` / `vim.treesitter.select()` |
| Completion (incl. autotrigger) | `vim.lsp.completion.enable()`, `'autocomplete'`, `'complete'` new flags |
| LSP progress in statusline | `vim.ui.progress_status()` in default `'statusline'` |
| Diagnostic status | `vim.diagnostic.status()` in default `'statusline'` |
| Popup-menu borders | `'pumborder'`, `'pummaxwidth'`, `'winborder'` |
| editorconfig | `$VIMRUNTIME/plugin/editorconfig.lua` (since 0.9) |

> Note for this repo: `fidget.nvim` (LSP progress) and `mini.statusline` now
> overlap with core `'statusline'` defaults + `vim.ui.progress_status()`. Not
> obsolete — the plugins do more — but re-evaluate.

---

## 8. Formatting / linting toolchain

### conform.nvim — has a healthcheck, use it

Two entry points, both from
`~/.local/share/nvim/site/pack/core/opt/conform.nvim/`:

- **`:checkhealth conform`** (`lua/conform/health.lua` → `M.check`) — iterates
  `conform.list_all_formatters()` and reports each as OK or
  `"%s unavailable: %s"`.
- **`:ConformInfo`** (registered in `plugin/conform.lua` → `health.show_window`)
  — richer: a floating window with the tail of the conform log, formatters *for
  the current buffer* (including LSP formatters), resolved `exepath` for each
  available formatter, and everything else under "Other formatters". Use this
  when a format silently does nothing.

conform also degrades to `"Formatter failed. See :ConformInfo for details"`
(`lua/conform/init.lua:471`) rather than erroring loudly — so a missing binary
is easy to not notice.

> Current state: `prettier` and `prettierd` are **both missing** from `$PATH`.
> `lua/plugins/formatting.lua` maps js/ts/jsx/tsx/vue to
> `{ "prettierd", "prettier", stop_after_first = true }` — with neither
> installed, formatting those five filetypes is a silent no-op.
> `gofmt`, `ocamlformat`, `ruff_format`, `stylua` are all OK.

### nvim-lint — no healthcheck, verify by hand

`~/.local/share/nvim/site/pack/core/opt/nvim-lint/` has **no `health.lua` and no
user commands** (`ls lua/lint/` → `linters/ parser.lua util.lua`;
`grep -rn "nvim_create_user_command"` → nothing). Missing binaries surface only
as runtime notifications, and those can be suppressed per-call via
`opts.ignore_errors` (`lua/lint.lua:44,105-109,436`).

So verify manually. **Read the `cmd` from the linter definition** — it often
differs from the key you write in `linters_by_ft`:

```sh
P=~/.local/share/nvim/site/pack/core/opt/nvim-lint/lua/lint/linters
for l in cfn_lint ruff eslint; do printf '%-12s ' "$l"; grep -m1 'cmd' "$P/$l.lua"; done
```

> Concretely: this repo configures the linter **`cfn_lint`** (underscore) but
> its `cmd = "cfn-lint"` (hyphen). Checking `command -v cfn_lint` would give a
> false negative.

Combined binary audit for this config:

```sh
for b in stylua ruff prettierd prettier gofmt ocamlformat cfn-lint eslint \
         lua-language-server gopls typescript-language-server vue-language-server \
         deno yaml-language-server basedpyright-langserver ocamllsp \
         tree-sitter curl tar git; do
  printf "%-32s " "$b"
  command -v "$b" >/dev/null 2>&1 && echo "OK  $(command -v $b)" || echo "MISSING"
done
```

> Current state: all present **except `prettierd`, `prettier`, `eslint`**.
> `eslint` is deliberately opt-in here (`:EslintToggle`, off by default) and
> nvim-lint's eslint linter resolves `./node_modules/.bin/eslint` per-project
> before `$PATH` (nvim-lint README, "Security"), so a global miss is expected
> and fine. `prettier`/`prettierd` are a genuine gap.

### Reproducibility note

`mise.toml` pins only `stylua`. Everything else — `ruff`, `gopls`,
`typescript-language-server`, `tree-sitter`, `ocamlformat`, … — comes from
homebrew, cargo, go, opam, and mise installs that this repo doesn't declare.
Adding the LSP servers and formatters to `mise.toml` would make the config
self-bootstrapping and would let `mise install` replace most of the manual
binary audit.

---

## 9. Version-specific gotchas (0.11 → 0.12)

Condensed; each is expanded above with citations.

1. **`vim.pack` is 0.12-only, experimental, and Lua-API-only.** No `:Pack*`
   commands exist. No auto-update, no lazy-loading, no build-hook spec field
   (use `PackChanged`).
2. **`nvim-pack-lock.json` is core's own file**, at
   `$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json`. Never hand-edit. The quoted
   `"version": "'main'"` is intentional Lua-literal serialisation, not corruption.
3. **`vim.pack.add()` does not reconcile revisions.** Editing `version` in
   `init.lua` has no effect until `vim.pack.update()`. Editing `src` deletes and
   re-clones immediately.
4. **`:checkhealth vim.deprecated` only reports what ran this session.** Headless
   runs are meaningless. Soft-deprecated APIs emit no warning at all.
5. **Unknown LSP config keys are silently ignored** (only `cmd`,
   `reuse_client`, `filetypes` are validated) — so ported nvim-lspconfig keys
   like `single_file_support` look fine and do nothing. Use `workspace_required`
   (0.12).
6. **`vim.pack.update()` will not follow a default-branch rename** — pin
   `version = 'main'` for nvim-treesitter explicitly, because `master` is frozen
   but still the default branch.
7. **`:TSUpdate` after every nvim-treesitter bump.** Parser revisions are pinned
   in the plugin's `parsers.lua`, invisible to the lockfile.
8. **tree-sitter CLI ≥ 0.26.1 is a hard requirement** of the `main` branch; a
   missing CLI is `health.error`, not a warning.
9. **LSP JSON `null` is now `vim.NIL`, not `nil`** — any code inspecting raw LSP
   payloads (e.g. `lsp/basedpyright.lua` here) may behave differently, since
   `vim.NIL` is truthy in Lua.
10. **Actually removed in 0.12** (no deprecation warning, straight failure):
    `vim.diagnostic.disable()`, `vim.diagnostic.is_disabled()`, the legacy
    `vim.diagnostic.enable()` signature, `:sign-define` diagnostic signs,
    `vim.diff` (→ `vim.text.diff`), `Query:iter_matches()` `"all"` option.
11. **New default keymaps may collide**: `gra` `gri` `grn` `grr` `grt` `grx`
    `gO`, `<C-S>` in insert mode, and `v_an` / `v_in`
    (`$VIMRUNTIME/doc/lsp.txt`, `*lsp-defaults*`; `$VIMRUNTIME/doc/news.txt`
    DEFAULTS). Remove with `vim.keymap.del()`.

---

## 10. Source index

**Local (authoritative for 0.12.5).** `$VIMRUNTIME` =
`/opt/homebrew/Cellar/neovim/0.12.5_1/share/nvim/runtime`

| Path | Used for |
|---|---|
| `$VIMRUNTIME/doc/pack.txt` | `vim.pack` API, lockfile, examples, events |
| `$VIMRUNTIME/lua/vim/pack.lua` | lockfile path/schema/serialisation |
| `$VIMRUNTIME/lua/vim/pack/health.lua` | `:checkhealth vim.pack` internals |
| `$VIMRUNTIME/doc/lsp.txt` | `lsp-quickstart`, `lsp-config`, `lsp-config-merge`, `lsp-defaults`, `vim.lsp.Config`, `vim.lsp.ClientConfig`, `:lsp` |
| `$VIMRUNTIME/lua/vim/lsp.lua` | config validation, `workspace_required` enforcement |
| `$VIMRUNTIME/doc/deprecated.txt` | `deprecated-0.12`, `deprecated-0.11` |
| `$VIMRUNTIME/lua/vim/_core/editor.lua` | `vim.deprecate()` soft/hard gate |
| `$VIMRUNTIME/lua/vim/deprecated/health.lua` | runtime-only deprecation tracking |
| `$VIMRUNTIME/doc/news.txt` | 0.12 breaking / new / changed / removed |
| `$VIMRUNTIME/doc/news-0.11.txt` | when `vim.lsp.config` landed |
| `$VIMRUNTIME/doc/health.txt` | `health-usage`, `health-dev`, `g:health` |
| `$VIMRUNTIME/doc/lua.txt` | `vim.deprecate()` signature |
| `$VIMRUNTIME/doc/plugins.txt` | builtin `editorconfig` |

**Installed plugins** (`~/.local/share/nvim/site/pack/core/opt/`):
`nvim-treesitter/doc/nvim-treesitter.txt`,
`nvim-treesitter/lua/nvim-treesitter/health.lua`,
`nvim-treesitter/lua/nvim-treesitter/parsers.lua`,
`conform.nvim/lua/conform/health.lua`, `conform.nvim/plugin/conform.lua`,
`nvim-lint/lua/lint.lua`, `nvim-lint/lua/lint/linters/*.lua`,
`nvim-lint/README.md`

**Upstream:**

- <https://github.com/neovim/neovim/blob/master/MAINTAIN.md> — deprecation policy
- <https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md> — requirements, API
- <https://github.com/nvim-treesitter/nvim-treesitter/tree/master> — master-frozen notice
- <https://github.com/neovim/nvim-lspconfig> — catalog role, legacy framework deprecation
