return {
  'stevearc/oil.nvim',
  version = "*",
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    delete_to_trash = false,
  },
  config = function (_, opts)
	  require("oil").setup(opts)
  end,
  keys = {
        { "<leader>of", function() require("oil").open() end, desc = "Open Oil" },
  },
  -- Optional dependencies
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
}
