-- mini.icons (icon provider for oil; ships inside mini.nvim)
require("mini.icons").setup({})

-- oil.nvim
require("oil").setup({
  delete_to_trash = true,
  lsp_file_methods = {
    enabled = true,
    timeout_ms = 60000,
    autosave_changes = false,
  },
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = "actions.select",
    ["<C-s>"] = { "actions.select", opts = { vertical = true } },
    ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
    ["<C-t>"] = { "actions.select", opts = { tab = true } },
    ["<C-p>"] = "actions.preview",
    ["<C-c>"] = { "actions.close", mode = "n" },
    ["<C-l>"] = "actions.refresh",
    ["-"] = { "actions.parent", mode = "n" },
    ["_"] = { "actions.open_cwd", mode = "n" },
    ["`"] = { "actions.cd", mode = "n" },
    ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    ["gs"] = { "actions.change_sort", mode = "n" },
    ["gx"] = "actions.open_external",
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
    ["gy"] = { "actions.yank_entry", mode = "n" },
  },
})

vim.keymap.set("n", "<leader>of", function()
  require("oil").open()
end, { desc = "Open Oil" })
