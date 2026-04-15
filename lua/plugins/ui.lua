-- snacks.nvim
require("snacks").setup({
  gh = {},
  bigfile = { enabled = true },
  dashboard = { enabled = false },
  indent = { enabled = false },
  input = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 3000,
  },
  picker = {
    enabled = true,
    sources = {
      gh_issue = {},
      gh_pr = {},
      files = {
        hidden = true,
        ignored = false,
        exclude = { "node_modules", ".venv" },
      },
      grep = {
        hidden = true,
        ignored = false,
        exclude = { "node_modules", ".venv" },
      },
      grep_word = {
        hidden = true,
        ignored = false,
        exclude = { "node_modules", ".venv" },
      },
    },
  },
  quickfile = { enabled = false },
  scroll = { enabled = false },
  statuscolumn = { enabled = true },
  words = { enabled = false },
  styles = {
    notification = {
      wo = { wrap = true },
    },
  },
})

vim.opt.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]

-- Snacks keymaps
local map = vim.keymap.set

-- gh
map("n", "<leader>gi", function() Snacks.picker.gh_issue() end, { desc = "GitHub Issues (open)" })
map("n", "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, { desc = "GitHub Issues (all)" })
map("n", "<leader>gp", function() Snacks.picker.gh_pr() end, { desc = "GitHub Pull Requests (open)" })
map("n", "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, { desc = "GitHub Pull Requests (all)" })

-- Picker
map("n", "<leader>,", function() Snacks.picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>/", function() Snacks.picker.grep({ hidden = true }) end, { desc = "Grep" })
map("n", "<leader>:", function() Snacks.picker.command_history() end, { desc = "Command History" })
map("n", "<leader><space>", function()
  Snacks.picker.recent({
    matcher = {
      ignorecase = true,
      file_pos = true,
      cwd_bonus = false,
      frecency = false,
      history_bonus = true,
    },
    filter = { cwd = true },
  })
end, { desc = "Find Files" })

-- Find
map("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, { desc = "Find Config File" })
map("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Find Files" })
map("n", "<leader>fg", function() Snacks.picker.git_files() end, { desc = "Find Git Files" })

-- Git
map("n", "<leader>gc", function() Snacks.picker.git_log() end, { desc = "Git Log" })
map("n", "<leader>gs", function() Snacks.picker.git_status() end, { desc = "Git Status" })

-- Grep
map("n", "<leader>sb", function() Snacks.picker.lines() end, { desc = "Buffer Lines" })
map("n", "<leader>sB", function() Snacks.picker.grep_buffers() end, { desc = "Grep Open Buffers" })
map("n", "<leader>sg", function() Snacks.picker.grep() end, { desc = "Grep" })
map({ "n", "x" }, "<leader>sw", function() Snacks.picker.grep_word() end, { desc = "Visual selection or word" })

-- Search
map("n", '<leader>s"', function() Snacks.picker.registers() end, { desc = "Registers" })
map("n", "<leader>s/", function() Snacks.picker.search_history() end, { desc = "Search History" })
map("n", "<leader>sa", function() Snacks.picker.autocmds() end, { desc = "Autocmds" })
map("n", "<leader>sc", function() Snacks.picker.command_history() end, { desc = "Command History" })
map("n", "<leader>sC", function() Snacks.picker.commands() end, { desc = "Commands" })
map("n", "<leader>sd", function() Snacks.picker.diagnostics() end, { desc = "Diagnostics" })
map("n", "<leader>sh", function() Snacks.picker.help() end, { desc = "Help Pages" })
map("n", "<leader>sH", function() Snacks.picker.highlights() end, { desc = "Highlights" })
map("n", "<leader>sj", function() Snacks.picker.jumps() end, { desc = "Jumps" })
map("n", "<leader>sk", function() Snacks.picker.keymaps() end, { desc = "Keymaps" })
map("n", "<leader>sM", function() Snacks.picker.man() end, { desc = "Man Pages" })
map("n", "<leader>sR", function() Snacks.picker.resume() end, { desc = "Resume" })
map("n", "<leader>su", function() Snacks.picker.undo() end, { desc = "Undo History" })
map("n", "<leader>sq", function() Snacks.picker.qflist() end, { desc = "Quickfix List" })
map("n", "<leader>uC", function() Snacks.picker.colorschemes() end, { desc = "Colorschemes" })
map("n", "<leader>qp", function() Snacks.picker.projects() end, { desc = "Projects" })
map("n", "<leader>st", function() Snacks.picker.todo_comments() end, { desc = "Todo" })
map("n", "<leader>sT", function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, { desc = "Todo/Fix/Fixme" })

-- Language-specific code search shortcuts
map("n", "<leader>sl", function()
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = vim.api.nvim_get_current_buf() })
  local typescript = "function |class |interface |type |const |let "
  local javascript = "function |class |const |let "
  local patterns = {
    python = "def |class ",
    javascript = javascript,
    typescript = typescript,
    typescriptreact = typescript,
    lua = "function |local function ",
    go = "func |type |var |const ",
    rust = "fn |struct |enum |impl |trait ",
    java = "class |interface |method |public |private ",
    c = "void |int |char |struct |typedef ",
    cpp = "void |int |char |class |struct |namespace ",
  }
  local pattern = patterns[filetype]
  if not pattern then
    vim.notify("No language symbols pattern defined for filetype: " .. (filetype or "unknown"), vim.log.levels.WARN)
    return
  end
  Snacks.picker.grep({ search = pattern })
end, { desc = "Search Language symbols" })

map("n", "<leader>sf", function()
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = vim.api.nvim_get_current_buf() })
  local patterns = {
    python = "def ",
    javascript = "function ",
    typescript = "function ",
    lua = "function ",
    go = "func ",
    rust = "fn ",
    java = "public |private |protected ",
    c = "void |int |char |float |double ",
    cpp = "void |int |char |float |double ",
  }
  local pattern = patterns[filetype]
  if not pattern then
    vim.notify("No functions pattern defined for filetype: " .. (filetype or "unknown"), vim.log.levels.WARN)
    return
  end
  Snacks.picker.grep({ search = pattern })
end, { desc = "Search Functions" })

map("n", "<leader>sy", function()
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = vim.api.nvim_get_current_buf() })
  local patterns = {
    python = "class ",
    javascript = "class ",
    typescript = "class |interface |type ",
    go = "type ",
    rust = "struct |enum |trait ",
    java = "class |interface ",
    c = "struct |typedef ",
    cpp = "class |struct |namespace ",
  }
  local pattern = patterns[filetype]
  if not pattern then
    vim.notify("No types/classes pattern defined for filetype: " .. (filetype or "unknown"), vim.log.levels.WARN)
    return
  end
  Snacks.picker.grep({ search = pattern })
end, { desc = "Search Types/classes" })

-- LSP via Snacks picker
map("n", "gd", function() Snacks.picker.lsp_definitions() end, { desc = "Goto Definition" })
map("n", "gr", function() Snacks.picker.lsp_references() end, { nowait = true, desc = "References" })
map("n", "gI", function() Snacks.picker.lsp_implementations() end, { desc = "Goto Implementation" })
map("n", "gy", function() Snacks.picker.lsp_type_definitions() end, { desc = "Goto T[y]pe Definition" })
map("n", "<leader>cS", function() Snacks.picker.lsp_symbols() end, { desc = "LSP Symbols" })
map("n", "<leader>cs", function() Snacks.picker.lsp_workspace_symbols() end, { desc = "LSP Workspace Symbols" })

-- Snacks utilities
map("n", "<leader>z", function() Snacks.zen() end, { desc = "Toggle Zen Mode" })
map("n", "<leader>Z", function() Snacks.zen.zoom() end, { desc = "Toggle Zoom" })
map("n", "<leader>.", function() Snacks.scratch() end, { desc = "Toggle Scratch Buffer" })
map("n", "<leader>S", function() Snacks.scratch.select() end, { desc = "Select Scratch Buffer" })
map("n", "<leader>n", function() Snacks.notifier.show_history() end, { desc = "Notification History" })
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete Buffer" })
map("n", "<leader>cR", function() Snacks.rename.rename_file() end, { desc = "Rename File" })
map("n", "<leader>gY", function()
  Snacks.gitbrowse({
    open = function(url) vim.fn.setreg("+", url) end,
    notify = false,
  })
end, { desc = "Git Browse (copy)" })
map({ "n", "v" }, "<leader>gB", function() Snacks.gitbrowse() end, { desc = "Git Browse" })
map("n", "<leader>gb", function() Snacks.git.blame_line() end, { desc = "Git Blame Line" })
map("n", "<leader>gf", function() Snacks.lazygit.log_file() end, { desc = "Lazygit Current File History" })
map("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "Lazygit" })
map("n", "<leader>gl", function() Snacks.lazygit.log() end, { desc = "Lazygit Log (cwd)" })
map("n", "<leader>un", function() Snacks.notifier.hide() end, { desc = "Dismiss All Notifications" })
map("n", "<c-/>", function() Snacks.terminal() end, { desc = "Toggle Terminal" })
map("n", "<c-_>", function() Snacks.terminal() end, { desc = "which_key_ignore" })
map({ "n", "t" }, "]]", function() Snacks.words.jump(vim.v.count1) end, { desc = "Next Reference" })
map({ "n", "t" }, "[[", function() Snacks.words.jump(-vim.v.count1) end, { desc = "Prev Reference" })
map("n", "<leader>N", function()
  Snacks.win({
    file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
    width = 0.6,
    height = 0.6,
    wo = { spell = false, wrap = false, signcolumn = "yes", statuscolumn = " ", conceallevel = 3 },
  })
end, { desc = "Neovim News" })

-- Snacks toggles
Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
Snacks.toggle.inlay_hints():map("<leader>uh")
Snacks.toggle.indent():map("<leader>ug")
Snacks.toggle.dim():map("<leader>uD")

-- Debug globals
_G.dd = function(...) Snacks.debug.inspect(...) end
_G.bt = function() Snacks.debug.backtrace() end
vim.print = _G.dd

-- trouble.nvim
require("trouble").setup({})

map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
map("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
map("n", "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "LSP Definitions / references / ... (Trouble)" })
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

-- Trouble integration with Snacks picker
local trouble_actions = require("trouble.sources.snacks").actions
Snacks.config.picker.actions = vim.tbl_deep_extend("force", Snacks.config.picker.actions or {}, trouble_actions)
Snacks.config.picker.win = vim.tbl_deep_extend("force", Snacks.config.picker.win or {}, {
  input = {
    keys = {
      ["<c-t>"] = { "trouble_open", mode = { "n", "i" } },
    },
  },
})

-- gitsigns
require("gitsigns").setup({})
