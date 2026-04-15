-- which-key
require("which-key").setup({
  preset = "helix",
  defaults = {},
  spec = {
    {
      mode = { "n", "v" },
      { "<leader><tab>", group = "tabs" },
      { "<leader>c", group = "code" },
      { "<leader>f", group = "file/find" },
      { "<leader>g", group = "git" },
      { "<leader>gh", group = "hunks" },
      { "<leader>q", group = "quit/session" },
      { "<leader>s", group = "search" },
      { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
      { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
      { "[", group = "prev" },
      { "]", group = "next" },
      { "g", group = "goto" },
      { "gs", group = "surround" },
      { "z", group = "fold" },
      {
        "<leader>b",
        group = "buffer",
        expand = function()
          return require("which-key.extras").expand.buf()
        end,
      },
      {
        "<leader>w",
        group = "windows",
        proxy = "<c-w>",
        expand = function()
          return require("which-key.extras").expand.win()
        end,
      },
      { "gx", desc = "Open with system app" },
    },
  },
})

vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })

-- treesitter
local ts = require("nvim-treesitter")

local wanted = {
  "lua", "vim", "vimdoc", "query", "elixir", "javascript", "html",
  "git_config", "gitcommit", "git_rebase", "gitignore", "gitattributes",
  "ocaml", "luadoc", "diff", "haskell", "markdown", "markdown_inline",
  "python", "tsx", "typescript", "xml", "go",
}
local installed = require("nvim-treesitter.config").get_installed()
local to_install = vim.iter(wanted)
  :filter(function(p) return not vim.tbl_contains(installed, p) end)
  :totable()
if #to_install > 0 then
  ts.install(to_install)
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("my_treesitter", { clear = true }),
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

-- treesitter-textobjects
require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
})

local select_to = require("nvim-treesitter-textobjects.select").select_textobject
local move = require("nvim-treesitter-textobjects.move")

vim.keymap.set({ "x", "o" }, "aa", function() select_to("@parameter.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "ia", function() select_to("@parameter.inner", "textobjects") end)
vim.keymap.set({ "x", "o" }, "af", function() select_to("@function.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "if", function() select_to("@function.inner", "textobjects") end)
vim.keymap.set({ "x", "o" }, "ac", function() select_to("@class.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "ic", function() select_to("@class.inner", "textobjects") end)

vim.keymap.set({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "]a", function() move.goto_next_start("@parameter.inner", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "]F", function() move.goto_next_end("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "]C", function() move.goto_next_end("@class.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "]A", function() move.goto_next_end("@parameter.inner", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "[a", function() move.goto_previous_start("@parameter.inner", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "[F", function() move.goto_previous_end("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "[C", function() move.goto_previous_end("@class.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "[A", function() move.goto_previous_end("@parameter.inner", "textobjects") end)

-- treesitter-context
require("treesitter-context").setup({
  enable = true,
  multiline_threshold = 5,
})

-- todo-comments
require("todo-comments").setup({})

-- mini.nvim
require("mini.ai").setup({ n_lines = 500 })
require("mini.surround").setup()
require("mini.statusline").setup({ use_icons = true })
