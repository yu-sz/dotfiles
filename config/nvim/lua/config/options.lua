local opt = vim.opt

-- General styling options
opt.title = true
opt.number = true
opt.relativenumber = true
opt.cursorline = true
-- Tab settings
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
-- Indentation
opt.autoindent = true
opt.smartindent = true
opt.backspace = "indent,eol,start"

-- Status line
opt.laststatus = 3
-- Max syntax highlight columns
opt.synmaxcol = 240

-- Command line completion
opt.wildmode = { "longest", "list", "full" }
-- Incremental search
opt.incsearch = true

-- Clipboard integration
opt.clipboard:append({ "unnamedplus" })
-- Enable mouse
opt.mouse = "a"
-- Disable vi compatibility
opt.compatible = false
-- Do not generate swap files
opt.swapfile = false

-- Split window behavior
opt.splitright = true
opt.splitbelow = true

-- Do not wrap lines
vim.wo.wrap = false
-- Display invisible characters
opt.list = true
-- Enable 24-bit color
opt.termguicolors = true
-- Colorscheme settings
opt.background = "dark"
opt.winblend = 0 -- Window opacity
opt.pumblend = 0 -- Popup menu opacity
-- Show sign column to prevent text shifting
opt.signcolumn = "yes"

-- Enable Nerd Fonts
vim.g.have_nerd_font = true
