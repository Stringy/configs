local common = require('plugins.lsp.common')

return {
    {
        "williamboman/mason.nvim",
        lazy = false
    },

    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        dependencies = { 'williamboman/mason.nvim' }
    },

    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
        },
        config = function()
            common.common()
        end
    },

    {
        'simrat39/rust-tools.nvim',
        ft = 'rust',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
        },
        opts = {
            tools = {
                -- rust-tools options
                autoSetHints = true,
                inlay_hints = {
                    show_parameter_hints = false,
                    parameter_hints_prefix = "",
                    other_hints_prefix = "",
                },
            },
            server = {
                cmd = { 'rustup', 'run', 'stable', 'rust-analyzer', },
                on_attach = common.on_attach,
                flags = common.lsp_flags,
                settings = {
                    -- to enable rust-analyzer settings visit
                    -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
                    ['rust-analyzer'] = {
                        -- enable clippy on save
                        checkOnSave = {
                            command = 'clippy'
                        },
                    }
                }
            },
        }
    },

    {
        'williamboman/nvim-lsp-installer',
        lazy = false,
    },

    {
        'hrsh7th/nvim-cmp',
        config = function()
            local cmp = require('cmp')

            cmp.setup {
                snippet = {
                    expand = function(args)
                        vim.fn["vsnip#anonymous"](args.body)
                    end,
                },

                sources = cmp.config.sources({
                    { name = 'path' },
                    { name = 'buffer' },
                    { name = 'nvim_lsp' },
                    { name = 'vsnip' },
                }),

                mapping = {
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.close(),
                    ['<CR>'] = cmp.mapping.confirm({ select = true })
                }
            }
        end,
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
        }
    },
    {
        'hrsh7th/cmp-nvim-lsp',
        lazy = false,
    },

    'hrsh7th/cmp-buffer',

    {
        'jose-elias-alvarez/null-ls.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim'
        },
        opts = function()
            local null_ls = require('null-ls')
            return {
                sources = {
                    -- diagnostics
                    null_ls.builtins.diagnostics.actionlint,
                    null_ls.builtins.diagnostics.ansiblelint,
                    null_ls.builtins.diagnostics.flake8,
                    null_ls.builtins.diagnostics.hadolint,
                    null_ls.builtins.diagnostics.zsh,
                    null_ls.builtins.diagnostics.checkmake,
                    null_ls.builtins.diagnostics.cmake_lint,
                    null_ls.builtins.diagnostics.fish,

                    -- formatters
                    null_ls.builtins.formatting.autopep8,
                    null_ls.builtins.formatting.shfmt,

                    -- prose
                    null_ls.builtins.hover.dictionary,
                    null_ls.builtins.code_actions.proselint,
                    null_ls.builtins.diagnostics.vale.with({
                        filetypes = {
                            'markdown', 'vimwiki', 'tex', 'asciidoc'
                        }
                    }),
                }
            }
        end
    }
}
