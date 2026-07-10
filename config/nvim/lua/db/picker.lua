local M = {}

function M.pick()
  if not vim.g.dbs then
    require("db.catalog").load()
  end
  local items = vim.tbl_map(function(d)
    return { text = d.name, driver = (d._meta or {}).driver or "?", url = d.url }
  end, vim.g.dbs or {})

  Snacks.picker.pick({
    title = "DB Connections",
    items = items,
    format = function(item)
      return {
        { string.format("%-20s ", item.text), "Identifier" },
        { string.format("[%s]", item.driver), "Comment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      vim.g.db = item.url
      vim.cmd("DBUI")
      vim.notify("DB: " .. item.text, vim.log.levels.INFO)
    end,
  })
end

return M
