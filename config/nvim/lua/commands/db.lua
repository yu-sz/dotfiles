vim.api.nvim_create_user_command("DBPick", function()
  require("db.picker").pick()
end, { desc = "Pick a DB connection from catalog" })
