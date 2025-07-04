return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      -- vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
    "cormacrelf/dark-notify",
    config = function()
      require("dark_notify").run()
    end,
  },
  {
    "ellisonleao/gruvbox.nvim",
    branch = "main",
    priority = 1000,
    config = true,
    init = function()
      require("gruvbox").setup({
        terminal_colors = true, -- add neovim terminal colors
        contrast = "hard", -- can be "hard", "soft" or empty string
      })
      vim.cmd.colorscheme("gruvbox")
    end,
  },
}
