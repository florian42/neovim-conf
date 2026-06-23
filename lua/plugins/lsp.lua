-- fidget.nvim
require("fidget").setup({})

-- nvim-lint
local lint = require("lint")
lint.linters_by_ft = {
  yaml = { "cfn_lint" },
  python = { "ruff" },
}

-- eslint is opt-in: enable per-session with `:EslintToggle` (or set
-- `vim.g.eslint_enabled = true`). Defaults to off.
local eslint_filetypes = {
  typescriptreact = true,
  vue = true,
  javascriptreact = true,
  typescript = true,
  javascript = true,
}

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("lint", { clear = true }),
  callback = function()
    if not vim.opt_local.modifiable:get() then
      return
    end
    if vim.g.eslint_enabled and eslint_filetypes[vim.bo.filetype] then
      lint.try_lint("eslint")
    end
    lint.try_lint()
  end,
})

vim.api.nvim_create_user_command("EslintToggle", function()
  vim.g.eslint_enabled = not vim.g.eslint_enabled
  vim.notify("eslint " .. (vim.g.eslint_enabled and "enabled" or "disabled"))
end, { desc = "Toggle eslint linting" })
