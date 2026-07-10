local M = {}

local CATALOG_PATH = "~/.config/db-catalog/connections.toml"

---@param name string
---@param fields string[]
---@param conn table
---@return boolean
local function has_required_fields(name, fields, conn)
  for _, field in ipairs(fields) do
    if conn[field] == nil then
      vim.notify(("db-catalog: %s: missing required field `%s`"):format(name, field), vim.log.levels.WARN)
      return false
    end
  end
  return true
end

---@param name string
---@param conn table
---@return string|nil
local function build_url(name, conn)
  if conn.url then
    return conn.url
  end
  local d = conn.driver
  if d == "postgres" then
    if not has_required_fields(name, { "user", "host", "database" }, conn) then
      return nil
    end
    return string.format(
      "postgres://%s:%s@%s:%d/%s",
      conn.user,
      conn.password or "",
      conn.host,
      tonumber(conn.port) or 5432,
      conn.database
    )
  elseif d == "duckdb" or d == "sqlite" then
    if not has_required_fields(name, { "path" }, conn) then
      return nil
    end
    return d .. ":" .. vim.fn.expand(conn.path)
  elseif d == "bigquery" then
    if not has_required_fields(name, { "project" }, conn) then
      return nil
    end
    -- dadbod の bigquery スキームは `bigquery:project[:dataset]` (`//` なし)
    return "bigquery:" .. conn.project
  end
  -- 未知 driver (clickhouse 等 zsh 専用エントリ) は DBUI に出さない
  return nil
end

---@return table|nil
local function parse_catalog()
  local path = vim.fn.expand(CATALOG_PATH)
  if vim.fn.filereadable(path) == 0 or vim.fn.executable("yq") == 0 then
    return nil
  end
  local out = vim.system({ "yq", "-o", "json", "-p", "toml", path }, { text = true }):wait()
  if out.code ~= 0 then
    vim.notify("db-catalog: TOML parse error\n" .. (out.stderr or ""), vim.log.levels.WARN)
    return nil
  end
  local ok, data = pcall(vim.json.decode, out.stdout)
  if not ok then
    vim.notify("db-catalog: JSON decode error", vim.log.levels.WARN)
    return nil
  end
  return data
end

function M.load()
  local data = parse_catalog()
  if not data then
    return
  end
  local dbs = {}
  for name, conn in pairs(data.connections or {}) do
    local url = build_url(name, conn)
    if url then
      table.insert(dbs, { name = name, url = url, _meta = conn })
    end
  end
  table.sort(dbs, function(a, b)
    return a.name < b.name
  end)
  vim.g.dbs = dbs
end

---sqls 向け接続リスト (sqls は postgres/sqlite のみ対応)
---@return table[]
function M.sqls_connections()
  if not vim.g.dbs then
    M.load()
  end
  local conns = {}
  for _, d in ipairs(vim.g.dbs or {}) do
    local driver = (d._meta or {}).driver
    if driver == "postgres" then
      table.insert(conns, { alias = d.name, driver = "postgresql", dataSourceName = d.url })
    elseif driver == "sqlite" then
      local path = d._meta.path and vim.fn.expand(d._meta.path) or d.url:gsub("^sqlite:", "")
      table.insert(conns, { alias = d.name, driver = "sqlite3", dataSourceName = "file:" .. path })
    end
  end
  return conns
end

return M
