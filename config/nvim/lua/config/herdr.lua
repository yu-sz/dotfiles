local M = {}

---@param args string[]
---@return table|nil decoded
---@return string|nil err
local function herdr_json(args)
  local cmd = { "herdr" }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { text = true }):wait()
  if res.code ~= 0 then
    return nil, ("`herdr %s` failed: %s"):format(table.concat(args, " "), vim.trim(res.stderr or ""))
  end
  local ok, decoded = pcall(vim.json.decode, res.stdout)
  if not ok or type(decoded) ~= "table" then
    return nil, "failed to parse herdr JSON output"
  end
  return decoded, nil
end

---@param file string
---@param root string|nil
---@return string
local function relativize(file, root)
  if not root or root == "" then
    return file
  end
  local prefix = root:gsub("/+$", "") .. "/"
  if file:sub(1, #prefix) == prefix then
    return file:sub(#prefix + 1)
  end
  return file
end

---@return table|nil target_pane
---@return string|nil abs_file
local function resolve_target()
  if vim.env.HERDR_ENV ~= "1" then
    vim.notify("herdr: not running inside a herdr pane", vim.log.levels.WARN)
    return nil
  end

  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("herdr: current buffer is not backed by a file", vim.log.levels.WARN)
    return nil
  end

  local tab_id = vim.env.HERDR_TAB_ID
  if tab_id == nil or tab_id == "" then
    vim.notify("herdr: HERDR_TAB_ID is not set", vim.log.levels.ERROR)
    return nil
  end
  local self_pane = vim.env.HERDR_PANE_ID

  local list, err = herdr_json({ "pane", "list" })
  if not list then
    vim.notify("herdr: " .. err, vim.log.levels.ERROR)
    return nil
  end

  local panes = (list.result or {}).panes or {}
  for _, pane in ipairs(panes) do
    if pane.tab_id == tab_id and pane.agent ~= nil and pane.pane_id ~= self_pane then
      return pane, file
    end
  end

  vim.notify("herdr: no coding agent found in the current tab", vim.log.levels.WARN)
  return nil
end

---@param range integer[]|nil
local function send_path(range)
  local target, file = resolve_target()
  if not target or not file then
    return
  end

  local payload = "@" .. relativize(file, target.cwd)
  if range then
    local s, e = range[1], range[2]
    if s > e then
      s, e = e, s
    end
    payload = payload .. "#L" .. s
    if e ~= s then
      payload = payload .. "-" .. e
    end
  end

  -- 末尾 LF はリテラル挿入で Enter 押下ではないため prompt は submit されない
  local res = vim.system({ "herdr", "pane", "send-text", target.pane_id, payload .. "\n" }, { text = true }):wait()
  if res.code ~= 0 then
    vim.notify("herdr: send-text failed: " .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
  end
end

function M.send_file_to_agent()
  send_path(nil)
end

function M.send_selection_to_agent()
  -- '</'> マークは visual mode 継続中だと前回選択を指すため line("v")/line(".") を使う
  send_path({ vim.fn.line("v"), vim.fn.line(".") })
end

return M
