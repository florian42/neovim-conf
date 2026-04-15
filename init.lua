-- Leaders must be set before plugins
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Install/declare plugins via vim.pack
require("config.pack")

-- Core config
require("options")
require("config.autocmds")
require("keymaps")
require("commands")

-- Plugin configs
require("plugins.colorscheme")
require("plugins.editor")
require("plugins.ui")
require("plugins.lsp")
require("plugins.formatting")
require("plugins.filesystem")

-- Native LSP (v0.12) — server configs live in lsp/*.lua
vim.lsp.enable({ 'lua_ls', 'gopls', 'ts_ls', 'denols', 'yamlls', 'basedpyright', 'ocamllsp' })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my_lsp_attach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    map("<leader>cr", vim.lsp.buf.rename, "[C]ode [R]ename")
    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == "ts_ls" then
      map("<leader>co", function()
        vim.lsp.buf.code_action({
          apply = true,
          context = {
            only = {
              "source.removeUnused.ts",
              "source.removeUnused.tsx",
              "source.organizeImports.ts",
              "source.organizeImports.tsx",
            },
          },
        })
      end, "[C]ode Remove Unused Imports")
    end
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = false })
    end
  end,
})
