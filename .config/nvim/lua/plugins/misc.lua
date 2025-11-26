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
            require('material.functions').change_style('lighter')
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
    },
    {
        "rust-lang/rust.vim",
    },
    {
        "mfussenegger/nvim-dap",
    },
    {
        "leoluz/nvim-dap-go",
        config = function()
            require('dap-go').setup({
                -- Additional dap configurations can be added.
                -- dap_configurations accepts a list of tables where each entry
                -- represents a dap configuration. For more details do:
                -- :help dap-configuration
                dap_configurations = {
                    {
                        -- Must be "go" or it will be ignored by the plugin
                        type = "go",
                        name = "Attach remote",
                        mode = "remote",
                        request = "attach",
                    },
                },
                -- delve configurations
                delve = {
                    -- the path to the executable dlv which will be used for debugging.
                    -- by default, this is the "dlv" executable on your PATH.
                    path = "dlv",
                    -- time to wait for delve to initialize the debug session.
                    -- default to 20 seconds
                    initialize_timeout_sec = 20,
                    -- a string that defines the port to start delve debugger.
                    -- default to string "${port}" which instructs nvim-dap
                    -- to start the process in a random available port.
                    -- if you set a port in your debug configuration, its value will be
                    -- assigned dynamically.
                    port = "${port}",
                    -- additional args to pass to dlv
                    args = {},
                    -- the build flags that are passed to delve.
                    -- defaults to empty string, but can be used to provide flags
                    -- such as "-tags=unit" to make sure the test suite is
                    -- compiled during debugging, for example.
                    -- passing build flags using args is ineffective, as those are
                    -- ignored by delve in dap mode.
                    -- avaliable ui interactive function to prompt for arguments get_arguments
                    build_flags = {},
                    -- whether the dlv process to be created detached or not. there is
                    -- an issue on delve versions < 1.24.0 for Windows where this needs to be
                    -- set to false, otherwise the dlv server creation will fail.
                    -- avaliable ui interactive function to prompt for build flags: get_build_flags
                    detached = vim.fn.has("win32") == 0,
                    -- the current working directory to run dlv from, if other than
                    -- the current working directory.
                    cwd = nil,
                },
                -- options related to running closest test
                tests = {
                    -- enables verbosity when running the test.
                    verbose = true,
                },
            })
        end
    }
}
