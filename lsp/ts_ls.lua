local jsroot = require("util.jsroot")

-- Vue SFC support requires @vue/typescript-plugin loaded *into* tsserver, with
-- vue_ls forwarding tsserver requests to us (see lsp/vue_ls.lua). The plugin is
-- a separate npm package from @vue/language-server, so resolve it at load time
-- and only register it when it is actually present — otherwise tsserver refuses
-- to start with a bad plugin path.
local function vue_plugin()
  -- mise lays npm tools out as
  --   installs/npm-<tool>/<version>/node_modules/<pkg>
  -- and keeps a `latest` symlink alongside the pinned versions, so prefer that
  -- and it survives version bumps. Globs are ordered most- to least-specific.
  local patterns = {
    "~/.local/share/mise/installs/npm-vue-typescript-plugin/latest/node_modules/@vue/typescript-plugin",
    "~/.local/share/mise/installs/npm-vue-typescript-plugin/*/node_modules/@vue/typescript-plugin",
    "~/.local/share/npm/lib/node_modules/@vue/typescript-plugin",
    "/opt/homebrew/lib/node_modules/@vue/typescript-plugin",
  }
  for _, pat in ipairs(patterns) do
    for _, dir in ipairs(vim.fn.glob(vim.fn.expand(pat), true, true)) do
      if vim.uv.fs_stat(dir) then
        return {
          name = "@vue/typescript-plugin",
          location = dir,
          languages = { "vue" },
        }
      end
    end
  end
  return nil
end

local plugins = {}
local vue = vue_plugin()
if vue then table.insert(plugins, vue) end

return {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  -- Arbitrated against denols; see lua/util/jsroot.lua.
  root_dir = jsroot.node,
  -- Without this a buffer with no project root starts the server anyway with
  -- root_dir = nil. `single_file_support` (the old lspconfig key) is NOT a
  -- vim.lsp.Config field and was silently ignored.
  workspace_required = true,
  init_options = {
    hostInfo = "neovim",
    plugins = plugins,
  },
  settings = {
    typescript = {
      preferences = {
        importModuleSpecifierPreference = "non-relative",
      },
    },
  },
}
