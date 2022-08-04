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
        '%.git/*'
    }
})
