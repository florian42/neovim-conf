-- tokyonight (available but not active)
require("tokyonight").setup({})

-- gruvbox (active colorscheme)
require("gruvbox").setup({
  terminal_colors = true,
  contrast = "hard",
})
vim.cmd.colorscheme("gruvbox")

-- dark-notify (auto dark/light switching)
require("dark_notify").run()
