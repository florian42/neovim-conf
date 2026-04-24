-- fidget.nvim
require("fidget").setup({})

-- nvim-lint
local lint = require("lint")
lint.linters_by_ft = {
  typescriptreact = { "eslint" },
  javascriptreact = { "eslint" },
  typescript = { "eslint" },
  javascript = { "eslint" },
  yaml = { "cfn_lint" },
  python = { "ruff" },
}

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("lint", { clear = true }),
  callback = function()
    if vim.opt_local.modifiable:get() then
      lint.try_lint()
    end
  end,
})
