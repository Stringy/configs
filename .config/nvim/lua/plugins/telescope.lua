return {
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            { 'nvim-lua/plenary.nvim' }
        },
        keys = {
            '<leader>ff',
            '<leader>fg',
            '<leader>fb',
            '<leader>fh',
            '<leader>fs',
            '<leader>fd',
        },
        config = function()
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
        end
    },

    {
        'nvim-telescope/telescope-fzf-native.nvim',
        build =
        'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
    },

    {
        'folke/trouble.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons'
        },
    },
    'rudism/telescope-dict.nvim',

}
