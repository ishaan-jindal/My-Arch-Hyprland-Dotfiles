-- Compatibility shim: Neovim 0.11 removed ft_to_lang (Telescope still uses it)
if not vim.treesitter.language.ft_to_lang then
  vim.treesitter.language.ft_to_lang = vim.treesitter.language.get_lang
end

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Basic UI
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.autoread = true
vim.opt.termguicolors = true
vim.o.background = "dark"
vim.opt.signcolumn = "yes" -- prevent layout shift from diagnostics
vim.opt.cursorline = true  -- highlight current line
vim.opt.wrap = false       -- don't wrap long lines in code
vim.opt.scrolloff = 8      -- keep 8 lines of context when scrolling
vim.opt.sidescrolloff = 8

-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Performance tweaks
vim.opt.updatetime = 300
vim.opt.timeoutlen = 400

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Clipboard (Wayland-aware; falls back gracefully)
vim.opt.clipboard = "unnamedplus"

-- Files: persistent undo without swap/backup clutter
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- UI polish (lualine handles mode/status)
vim.opt.showmode = false
vim.opt.laststatus = 3
vim.opt.pumheight = 10

-- Completion menu
vim.opt.completeopt = { "menu", "menuone", "noselect" }
