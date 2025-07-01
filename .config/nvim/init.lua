local opt = vim.opt

-- UI
opt.number = true
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

-- Use terminal colors
vim.cmd("set notermguicolors")

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
    -- Create the BufLeave command here, for this buffer only
    autocmd("BufLeave", {
      buffer = 0, -- 0 means current buffer
      once = true, -- The command should only fire once and then delete itself
      callback = function()
        vim.opt.laststatus = 2
        vim.opt.showmode = true
        vim.opt.ruler = true
      end,
    })
  end,
})


-- Key Mappings
local map_opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

-- Disable Ctrl+Z on Windows
if vim.fn.has("win32") == 1 then
  keymap({ "n", "i" }, "<C-z>", "<Nop>", { noremap = true })
end

-- Insert mode mappings
keymap("i", "<C-H>", "<C-W>", { noremap = true, desc = "Delete word before cursor" }) -- Ctrl+Backspace to delete word
keymap("i", "<C-s>", "<Esc>:w<CR>i", { noremap = true, desc = "Save file" }) -- Ctrl+S to save

-- Tab navigation
keymap("n", "<Tab>", ":tabnext<CR>", { noremap = true, desc = "Next tab" })
keymap("n", "<S-Tab>", ":tabprevious<CR>", { noremap = true, desc = "Previous tab" })
keymap("n", ",i", "<C-i>", { noremap = true, desc = "Jump forward in jumplist" }) -- Fix for Tab breaking Ctrl+i

-- Clear search highlighting
keymap("n", "<C-L>", ":nohlsearch<CR><C-L>", { noremap = true, silent = true, desc = "Clear search highlight" })

-- Search for whole word
keymap("n", "<leader>/", "/\\<\\><left><left>", { noremap = true, desc = "Search for whole word" })

-- Handle wrapped lines
keymap("n", "j", "gj", map_opts)
keymap("n", "k", "gk", map_opts)
keymap("n", "0", "g0", map_opts)
keymap("n", "$", "g$", map_opts)

-- Move lines up/down
keymap("n", "<C-S-j>", ":m .+1<CR>==", { noremap = true, desc = "Move line down" })
keymap("n", "<C-S-k>", ":m .-2<CR>==", { noremap = true, desc = "Move line up" })
keymap("i", "<C-S-j>", "<Esc>:m .+1<CR>==gi", { noremap = true, desc = "Move line down" })
keymap("i", "<C-S-k>", "<Esc>:m .-2<CR>==gi", { noremap = true, desc = "Move line up" })
keymap("v", "<C-S-j>", ":m '>+1<CR>gv=gv", { noremap = true, desc = "Move selection down" })
keymap("v", "<C-S-k>", ":m '<-2<CR>gv=gv", { noremap = true, desc = "Move selection up" })

-- Get help/documentation
keymap("n", "gh", vim.lsp.buf.hover, { desc = "Show documentation" })

-- Disable F1
keymap({ "n", "i" }, "<F1>", "<Esc>", { noremap = true })

-- Disable middle mouse paste
keymap({ "", "i" }, "<MiddleMouse>", "<Nop>", { noremap = true })
keymap({ "", "i" }, "<2-MiddleMouse>", "<Nop>", { noremap = true })
keymap({ "", "i" }, "<3-MiddleMouse>", "<Nop>", { noremap = true })
keymap({ "", "i" }, "<4-MiddleMouse>", "<Nop>", { noremap = true })



local function trim_trailing_whitespace()
  local save = vim.fn.winsaveview()
  vim.cmd("keeppatterns %s/\\s\\+$//e")
  vim.fn.winrestview(save)
end


-- Function to reload vimrc/init.lua
local function user_compile()
  if vim.bo.filetype == "vim" then
    vim.cmd("source $MYVIMRC")
    print("Sourced $MYVIMRC")
  elseif vim.bo.filetype == "lua" and vim.fn.expand("%:t") == "init.lua" then
    vim.cmd("source $MYVIMRC")
    print("Sourced $MYVIMRC (init.lua)")
  end
end
keymap("n", "<leader>ll", user_compile, { noremap = true, desc = "Reload configuration" })


-- Custom Commands
vim.api.nvim_create_user_command("TrimTrailingWhitespace", trim_trailing_whitespace, {})
vim.api.nvim_create_user_command("TRimTrailingWhitespace", trim_trailing_whitespace, {})
vim.api.nvim_create_user_command("Vs", "vs", { nargs = "?", complete = "file" }) -- Add completion
vim.api.nvim_create_user_command("WW", "w !SUDO_ASKPASS=/usr/lib/ssh/ssh-askpass sudo -A tee % > /dev/null", {})
vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.api.nvim_create_user_command("Qa", "qa", {})
