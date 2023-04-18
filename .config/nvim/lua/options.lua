local o       = vim.opt

o.compatible  = false
o.showmatch   = true
o.ignorecase  = true
o.number      = true
o.hlsearch    = true
o.incsearch   = true
o.tabstop     = 4
o.softtabstop = 4
o.expandtab   = true
o.shiftwidth  = 4
o.autoindent  = true
o.cc          = "80"
o.clipboard   = "unnamedplus"
o.cursorline  = true
o.completeopt = {
    "menu",
    "menuone",
    "noselect",
    "noinsert"
}
o.encoding    = "UTF-8"
o.mouse       = "nvi"
o.scrolloff   = 5
o.sidescroll  = 2
o.undofile    = true
o.backup      = false
o.hidden      = true
o.smartcase   = true
o.splitbelow  = true
o.splitright  = true
o.swapfile    = false
o.wrap        = false
o.writebackup = false
o.background  = "dark"
-- o.spell = true

vim.cmd([[
colorscheme catppuccin-mocha
]])
