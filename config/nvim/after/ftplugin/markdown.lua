local opt = vim.opt_local

opt.comments = "b:*,b:-,b:+,b:1.,nb:>"

opt.formatoptions:remove("c")
opt.formatoptions:append("jro")

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local CHECKBOX_PATTERN = "^(%s*)([%-%*%+])%s*%[.%]"
local LIST_PATTERN = "^(%s*)([%-%*%+])%s"

--- Parse checkbox line and return indent, marker. Returns nil if not a checkbox.
---@param line string
---@return string?, string?
local function parse_checkbox(line)
  local indent, marker = line:match(CHECKBOX_PATTERN)
  return indent, marker
end

--- Parse list line and return indent, marker. Returns nil if not a list.
---@param line string
---@return string?, string?
local function parse_list(line)
  local indent, marker = line:match(LIST_PATTERN)
  return indent, marker
end

--- Check if line has only marker (empty content).
---@param line string
---@param pattern string
---@return boolean
local function is_empty_item(line, pattern)
  return line:match(pattern .. "%s*$") ~= nil
end

--- Check if line is a list item (unordered or ordered).
---@param line string
---@return boolean
local function is_list_line(line)
  return line:match("^%s*[%-%*%+]%s") ~= nil or line:match("^%s*%d+%.%s") ~= nil
end

--------------------------------------------------------------------------------
-- Keymap handlers
--------------------------------------------------------------------------------

--- Continue list item on Enter. Empty item clears the line.
local function continue_list_cr()
  local line = vim.api.nvim_get_current_line()

  local indent, marker = parse_checkbox(line)
  if marker then
    if is_empty_item(line, CHECKBOX_PATTERN) then
      vim.api.nvim_set_current_line("")
      return
    end
    vim.api.nvim_put({ "", indent .. marker .. " [ ] " }, "c", true, true)
    vim.cmd("startinsert!")
    return
  end

  indent, marker = parse_list(line)
  if marker then
    if is_empty_item(line, LIST_PATTERN) then
      vim.api.nvim_set_current_line("")
      return
    end
    vim.api.nvim_put({ "", indent .. marker .. " " }, "c", true, true)
    vim.cmd("startinsert!")
    return
  end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
end

--- Insert new checkbox item in specified direction.
---@param direction "below"|"above"
local function continue_checkbox(direction)
  local line = vim.api.nvim_get_current_line()
  local indent, marker = parse_checkbox(line)
  if marker then
    local put_type = direction == "below" and "l" or "L"
    vim.api.nvim_put({ indent .. marker .. " [ ] " }, put_type, true, true)
    vim.cmd("startinsert!")
  else
    local fallback = direction == "below" and "o" or "O"
    vim.api.nvim_feedkeys(fallback, "n", false)
  end
end

--- Indent list item by 2 spaces.
local function indent_list()
  local line = vim.api.nvim_get_current_line()
  if is_list_line(line) then
    local col = vim.fn.col(".")
    vim.api.nvim_set_current_line("  " .. line)
    vim.fn.cursor(0, col + 2)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
  end
end

--- Outdent list item by 2 spaces.
local function outdent_list()
  local line = vim.api.nvim_get_current_line()
  if is_list_line(line) and line:match("^  ") then
    local col = vim.fn.col(".")
    vim.api.nvim_set_current_line(line:sub(3))
    vim.fn.cursor(0, math.max(1, col - 2))
  end
end

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------

vim.keymap.set("i", "<CR>", continue_list_cr, { buffer = true, desc = "Continue list item" })
vim.keymap.set("n", "o", function()
  continue_checkbox("below")
end, { buffer = true, desc = "New checkbox below" })
vim.keymap.set("n", "O", function()
  continue_checkbox("above")
end, { buffer = true, desc = "New checkbox above" })
vim.keymap.set("i", "<Tab>", indent_list, { buffer = true, desc = "Indent list item" })
vim.keymap.set("i", "<S-Tab>", outdent_list, { buffer = true, desc = "Outdent list item" })
