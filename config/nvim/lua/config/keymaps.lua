vim.g.mapleader = " "

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Disable default key
keymap.set("n", "s", "<NOP>", opts)
-- jamp start or end
keymap.set({ "n", "v", "x", "s", "o" }, "gg", "gg0", opts)
keymap.set({ "n", "v", "x", "s", "o" }, "G", "G$", opts)

-- Custom ESC for terminal mode
keymap.set("t", "<C-ESC>", [[<C-\><C-n>]], opts)
-- Clear search highlights
keymap.set("n", "<leader>n", ":nohlsearch<CR>", opts)
-- Paste without overwriting register in visual mode
keymap.set("x", "p", '"_dP', opts)

-- Tab control
keymap.set("n", "te", ":tabedit<CR>", opts)
keymap.set("n", "<tab>", ":tabnext<CR>", opts)
keymap.set("n", "<s-tab>", ":tabprev<CR>", opts)
keymap.set("n", "tl", ":tabmove -1<CR>")
keymap.set("n", "tr", ":tabmove +1<CR>")
keymap.set("n", "tc", ":tabclose<CR>")
keymap.set("n", "to", ":tabonly<CR>", opts)

-- Split window
keymap.set("n", "sp", "<C-w>s", opts)
keymap.set("n", "sv", "<C-w>v", opts)
keymap.set("n", "se", "<C-w>=", opts)

-- Move window
keymap.set("n", "sh", "<C-w>h", opts)
keymap.set("n", "sk", "<C-w>k", opts)
keymap.set("n", "sj", "<C-w>j", opts)
keymap.set("n", "sl", "<C-w>l", opts)

-- Resize window
keymap.set("n", ">", "<C-w><", opts)
keymap.set("n", "<", "<C-w>>", opts)
keymap.set("n", "+", "<C-w>+", opts)
keymap.set("n", "<S>-", "<C-w>-", opts)

-- Change window positions
keymap.set("n", "sr", "<C-w>r", opts)
keymap.set("n", "sx", "<C-w>x", opts)
keymap.set("n", "sH", "<C-w>H", opts)
keymap.set("n", "sJ", "<C-w>J", opts)
keymap.set("n", "sK", "<C-w>K", opts)
keymap.set("n", "sL", "<C-w>L", opts)
