vim.api.nvim_create_user_command("InsertToday", function()
  vim.cmd("r !date +\\%Y-\\%m-\\%d")
end, {})
