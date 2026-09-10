return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim', 'Snacks' } },
      workspace = {
        checkThirdParty = false,
        -- VIMRUNTIME alone gives no completion for the plugins this config
        -- actually calls into; vim.pack installs them under site/pack/core/opt.
        library = {
          vim.env.VIMRUNTIME,
          vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'pack', 'core', 'opt'),
        },
      },
    },
  },
}
