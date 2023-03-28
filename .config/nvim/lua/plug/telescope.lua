local actions = require('telescope.actions')
local trouble = require('trouble.providers.telescope')

require('telescope').setup({
    pickers = {
        find_files = {
            hidden = true
        },
        live_grep = {
            hidden = true
        }
    },
    vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--hidden",
        "--smart-case"
    },
    file_ignore_patterns = {
        '.git'
    },
    defaults = {
        mappings = {
            i = { ['<c-t>'] = trouble.open_with_trouble },
            n = { ['<c-t>'] = trouble.open_with_trouble },
        }
    }
})

require('telescope').load_extension('fzf')
