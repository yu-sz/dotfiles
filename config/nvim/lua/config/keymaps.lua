---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param desc string
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- Disable default key
map("n", "s", "<NOP>", "Disabled (window command prefix)")
-- jump start or end
map({ "n", "v", "x", "s", "o" }, "gg", "gg0", "Go to first line, first column")
map({ "n", "v", "x", "s", "o" }, "G", "G$", "Go to last line, end of line")

-- Custom ESC for terminal mode
map("t", "<C-ESC>", [[<C-\><C-n>]], "Exit terminal mode")
-- Clear search highlights
map("n", "<leader>n", ":nohlsearch<CR>", "Clear search highlights")
-- Paste without overwriting register in visual mode
map("x", "p", '"_dP', "Paste without overwriting register")

-- Tab control
-- NOTE: <tab> (tabnext) は sidekick.lua の fallback として定義している
map("n", "te", ":tabedit<CR>", "Open new tab")
map("n", "<s-tab>", ":tabprev<CR>", "Previous tab")
map("n", "tl", ":tabmove -1<CR>", "Move tab left")
map("n", "tr", ":tabmove +1<CR>", "Move tab right")
map("n", "tc", ":tabclose<CR>", "Close tab")
map("n", "to", ":tabonly<CR>", "Close other tabs")

-- Split window
map("n", "sp", "<C-w>s", "Split window horizontally")
map("n", "sv", "<C-w>v", "Split window vertically")
map("n", "se", "<C-w>=", "Equalize window sizes")

-- Move window
map("n", "sh", "<C-w>h", "Focus left window")
map("n", "sk", "<C-w>k", "Focus upper window")
map("n", "sj", "<C-w>j", "Focus lower window")
map("n", "sl", "<C-w>l", "Focus right window")

-- Resize window
-- NOTE: 横方向リサイズはインデント演算子 (>>/<<) を潰さないよう winresizer に委譲
map("n", "+", "<C-w>+", "Increase window height")
map("n", "-", "<C-w>-", "Decrease window height")

-- Change window positions
map("n", "sr", "<C-w>r", "Rotate windows")
map("n", "sx", "<C-w>x", "Swap with next window")
map("n", "sH", "<C-w>H", "Move window to far left")
map("n", "sJ", "<C-w>J", "Move window to bottom")
map("n", "sK", "<C-w>K", "Move window to top")
map("n", "sL", "<C-w>L", "Move window to far right")
