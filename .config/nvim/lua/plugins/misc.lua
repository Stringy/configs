return {
    {
        'LionC/nest.nvim',
        lazy = false,
        config = function()
            require('binds')
        end
    },

    'habamax/vim-godot',

    {
        'romgrk/barbar.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },
    'tpope/vim-fugitive',
    'tpope/vim-surround',
    'lukas-reineke/indent-blankline.nvim',
    'lukas-reineke/lsp-format.nvim',
    {
        "iamcco/markdown-preview.nvim",
        build = function() vim.fn["mkdp#util#install"]() end,
    },

    'hrsh7th/vim-vsnip',
    'hrsh7th/vim-vsnip-integ',

    {
        'pwntester/octo.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
            'nvim-tree/nvim-web-devicons'
        },
    },

    'simrat39/symbols-outline.nvim',
    {
        'junegunn/goyo.vim',
        keys = {
            '<leader>fo'
        }
    },

    {
        'catppuccin/nvim',
        name = 'catppuccin',
        lazy = false,
        config = function()
            require('catppuccin').setup({
                integrations = {
                    treesitter = true
                }
            })
        end
    },
    {
        'marko-cerovac/material.nvim',
        lazy = false,
        config = function()
            require('material').setup({
                plugins = {
                    'telescope',
                    'which-key',
                    'nvim-tree',
                }
            })
            require('material.functions').change_style('darker')
        end
    },

    { 'LunarVim/bigfile.nvim' },

    {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 1000,
        config = true
    },

    {
        'kyazdani42/nvim-tree.lua',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        version = '*',
        lazy = false,
        config = function()
            require('nvim-tree').setup({
                on_attach = function(bufnr)
                    local api = require("nvim-tree.api")

                    -- Attach default mappings
                    api.config.mappings.default_on_attach(bufnr)

                    vim.keymap.set('n', '.', function()
                        local node = api.tree.get_node_under_cursor()
                        local path = node.absolute_path
                        local codecompanion = require("codecompanion")
                        local chat = codecompanion.last_chat()
                        --if no chat, create one
                        if (chat == nil) then
                            chat = codecompanion.chat()
                        end
                        -- if already added, ignore
                        for _, ref in ipairs(chat.refs) do
                            if ref.path == path then
                                return print("Already added")
                            end
                        end
                        chat.references:add({
                            id = '<file>' .. path .. '</file>',
                            path = path,
                            source = "codecompanion.strategies.chat.slash_commands.file",
                            opts = {
                                pinned = true
                            }
                        })
                    end, { buffer = bufnr, desc = "Add or Pin file to Chat" })
                end
            })
        end
    },

    {
        'folke/zen-mode.nvim',
        opts = {
            window = {
                width = 89,
                options = {
                    number = false,
                    relativenumber = false,
                },
            },
        }
    },

    {
        'folke/trouble.nvim',
        opts = {},
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            {
                "<leader>cs",
                "<cmd>Trouble symbols toggle focus=false<cr>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>cl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Location List (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Quickfix List (Trouble)",
            },
        },
    }
}
