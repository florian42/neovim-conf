vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "screen"
-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

vim.opt.autowrite = true -- Enable auto write

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

-- Save undo history
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.swapfile = false

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

vim.opt.smoothscroll = true

vim.opt.expandtab = true -- Use spaces instead of tabs

vim.opt.grepprg = "rg --vimgrep"

vim.opt.shiftround = true -- Round indent
vim.opt.shiftwidth = 2 -- Size of an indent
vim.opt.smartindent = true -- Insert indents automatically

vim.opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time

vim.opt.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]

vim.opt.tabstop = 2 -- Number of spaces tabs count for

vim.opt.termguicolors = true -- True color support

vim.opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode

vim.diagnostic.config({
  virtual_lines = false,
})

vim.o.foldmethod = "expr" -- use tree-sitter for folding method
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99      -- start editing with all folds opened


-- disable some default providers
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

vim.opt.exrc = true -- per project .nvim.lua
