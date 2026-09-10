local jsroot = require('util.jsroot')

return {
  cmd = { 'deno', 'lsp' },
  -- Deno emits ANSI colour codes into LSP messages unless told not to.
  cmd_env = { NO_COLOR = true },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  -- Arbitrated against ts_ls; see lua/util/jsroot.lua.
  root_dir = jsroot.deno,
  workspace_required = true,
  settings = {
    deno = {
      enable = true,
      suggest = {
        imports = {
          hosts = { ['https://deno.land'] = true },
        },
      },
    },
  },
}
