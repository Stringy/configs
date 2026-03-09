local common = require('plugins.common.lsp')

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
          'mrcjkb/rustaceanvim',
          version = '^8',
          lazy = false,
          dependencies = { 'lukas-reineke/lsp-format.nvim' },
          init = function()
              vim.g.rustaceanvim = {
                  server = {
                      on_attach = common.on_attach,
                      settings = {
                          ['rust-analyzer'] = {
                              checkOnSave = true,
                              check = {
                                  command = 'clippy',
                              },
                              diagnostics = {
                                  enable = true,
                              },
                              inlayHints = {
                                  chainingHints = { enable = true },
                                  typeHints = { enable = true },
                                  parameterHints = { enable = true },
                              },
                          },
                      },
                  },
              }
          end,
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

                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.close(),
                    ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item(), {'i', 'c'}),
                    ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item(), {'i', 'c'}),
                    ['<CR>'] = cmp.mapping.confirm({select=true}),
                })
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
        'nvimtools/none-ls.nvim',
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
                    -- null_ls.builtins.diagnostics.flake8,
                    null_ls.builtins.diagnostics.hadolint,
                    null_ls.builtins.diagnostics.zsh,
                    null_ls.builtins.diagnostics.checkmake,
                    null_ls.builtins.diagnostics.cmake_lint,
                    null_ls.builtins.diagnostics.fish,

                    -- formatters
                    -- null_ls.builtins.formatting.autopep8,
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
