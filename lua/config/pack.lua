local gh = function(x) return 'https://github.com/' .. x end

vim.pack.add({
  -- Editor
  gh('folke/which-key.nvim'),
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
  { src = gh('nvim-treesitter/nvim-treesitter-textobjects'), version = 'main' },
  gh('nvim-treesitter/nvim-treesitter-context'),
  gh('folke/todo-comments.nvim'),
  gh('nvim-lua/plenary.nvim'),
  gh('tpope/vim-sleuth'),
  gh('echasnovski/mini.nvim'),

  -- Filesystem
  gh('echasnovski/mini.icons'),
  gh('stevearc/oil.nvim'),
  { src = gh('ThePrimeagen/harpoon'), version = 'harpoon2' },

  -- Formatting
  gh('stevearc/conform.nvim'),

  -- LSP / Linting
  gh('j-hui/fidget.nvim'),
  gh('mfussenegger/nvim-lint'),

  -- UI
  gh('folke/snacks.nvim'),
  gh('folke/trouble.nvim'),
  gh('lewis6991/gitsigns.nvim'),

  -- Colorschemes
  gh('folke/tokyonight.nvim'),
  gh('ellisonleao/gruvbox.nvim'),
  gh('cormacrelf/dark-notify'),
})
