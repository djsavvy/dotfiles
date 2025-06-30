-- Modern Neovim Configuration in Lua
-- Migrated from init.vim to match modern standards

-- Set leader key early
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable built-in vim plugins
vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1

-- General Options
local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = false
opt.showtabline = 2
opt.showmode = false
opt.cmdheight = 1
opt.ignorecase = true
opt.smartcase = true
opt.showmatch = true
opt.foldcolumn = "1"
opt.wildmenu = true
opt.inccommand = "split"
opt.hidden = true
opt.spell = true
opt.wrap = true
opt.linebreak = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"

-- Indentation
opt.autoindent = true
opt.smartindent = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Sign column
if vim.fn.has("patch-8.1.1564") == 1 then
  opt.signcolumn = "number"
else
  opt.signcolumn = "yes"
end

-- Session options
opt.sessionoptions:remove("options")
opt.sessionoptions:remove("folds")

-- Speed up python startup
vim.g.python_host_skip_check = 1
vim.g.python3_host_skip_check = 1

-- Platform-specific settings
if vim.fn.has("win32") == 1 then
  opt.shell = "pwsh.exe\\ -NoLogo"
  opt.shellpipe = "\\|"
  opt.shellxquote = ""
  opt.shellcmdflag = "-NoLogo\\ -ExecutionPolicy\\ RemoteSigned\\ -Command"
  opt.shellredir = "\\|\\ Out-File\\ -Encoding\\ UTF8"
end

-- Highlight line numbers in grey
vim.cmd("highlight LineNr ctermfg=DarkGrey")

-- Auto Commands
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Filetype-specific settings
autocmd("FileType", {
  group = augroup("FiletypeSettings", { clear = true }),
  pattern = { "ocaml", "javascript", "html" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.tabstop = 2
  end,
})

-- FZF settings
local fzf_group = augroup("FzfSettings", { clear = true })

autocmd("FileType", {
  group = fzf_group,
  pattern = "fzf",
  callback = function()
    vim.opt_local.laststatus = 0
    vim.opt_local.showmode = false
    vim.opt_local.ruler = false
  end,
})

autocmd("BufLeave", {
  group = fzf_group,
  pattern = "*",
  callback = function()
    if vim.bo.filetype == "fzf" then
      vim.opt.laststatus = 2
      vim.opt.showmode = true
      vim.opt.ruler = true
    end
  end,
})

-- Key Mappings
local keymap = vim.keymap.set

-- Disable Ctrl+Z on Windows
if vim.fn.has("win32") == 1 then
  keymap("n", "<C-z>", "<Nop>")
end

-- Insert mode mappings
keymap("i", "<C-H>", "<C-W>") -- Ctrl+Backspace to delete word
keymap("i", "<C-s>", "<Esc>:w<CR>i") -- Ctrl+S to save

-- Tab navigation
keymap("n", "<Tab>", ":tabnext<CR>")
keymap("n", "<S-Tab>", ":tabprevious<CR>")
keymap("n", ",i", "<C-i>") -- Fix for Tab breaking Ctrl+i

-- Clear search highlighting
keymap("n", "<C-L>", ":nohlsearch<CR><C-L>", { silent = true })

-- Search for whole word
keymap("n", "<leader>/", "/\\<\\><left><left>")

-- Handle wrapped lines
keymap("n", "j", "gj", { silent = true })
keymap("n", "k", "gk", { silent = true })
keymap("n", "0", "g0", { silent = true })
keymap("n", "$", "g$", { silent = true })

-- Move lines up/down
keymap("n", "<C-S-j>", ":m .+1<CR>==")
keymap("n", "<C-S-k>", ":m .-2<CR>==")
keymap("i", "<C-S-j>", "<Esc>:m .+1<CR>==gi")
keymap("i", "<C-S-k>", "<Esc>:m .-2<CR>==gi")
keymap("v", "<C-S-j>", ":m '>+1<CR>gv=gv")
keymap("v", "<C-S-k>", ":m '<-2<CR>gv=gv")

-- Get help/documentation
keymap("n", "gh", function()
  if vim.bo.filetype == "vim" then
    vim.cmd("help " .. vim.fn.expand("<cword>"))
  end
end, { silent = true })

-- Disable F1
keymap("n", "<F1>", "<Esc>")
keymap("i", "<F1>", "<Esc>")

-- Disable middle mouse
keymap("", "<MiddleMouse>", "<Nop>")
keymap("i", "<MiddleMouse>", "<Nop>")
keymap("", "<2-MiddleMouse>", "<Nop>")
keymap("i", "<2-MiddleMouse>", "<Nop>")
keymap("", "<3-MiddleMouse>", "<Nop>")
keymap("i", "<3-MiddleMouse>", "<Nop>")
keymap("", "<4-MiddleMouse>", "<Nop>")
keymap("i", "<4-MiddleMouse>", "<Nop>")

-- Functions
local function trim_trailing_whitespace()
  local save = vim.fn.winsaveview()
  vim.cmd("keeppatterns %s/\\s\\+$//e")
  vim.fn.winrestview(save)
end

local function user_compile()
  if vim.bo.filetype == "vim" then
    vim.cmd("source $MYVIMRC")
  end
end

-- Commands
vim.api.nvim_create_user_command("TrimTrailingWhitespace", trim_trailing_whitespace, {})
vim.api.nvim_create_user_command("TRimTrailingWhitespace", trim_trailing_whitespace, {})
vim.api.nvim_create_user_command("Vs", "vs", {})
vim.api.nvim_create_user_command("WW", "w !SUDO_ASKPASS=/usr/lib/ssh/ssh-askpass sudo -A tee % > /dev/null", {})
vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.api.nvim_create_user_command("Qa", "qa", {})

-- Leader+ll to compile
keymap("n", "<leader>ll", user_compile)

-- Plugin settings
vim.g.closetag_filenames = '*.html,*.xhtml,*.phtml,*.js'
vim.g.closetag_filetypes = 'html,xhtml,phtml,javascript,jsx,javascript.jsx,javascriptreact,typescript.jsx,typescript.tsx,typescriptreact'

-- Legacy settings
vim.g.C_Ctrl_j = "off"