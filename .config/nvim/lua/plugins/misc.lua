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
        'vimwiki/vimwiki',
        config = function()
            require('vimwiki')
        end
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

    { 'LunarVim/bigfile.nvim' },

    {
        "ellisonleao/gruvbox.nvim",
        lazy = false
    },

    {
        'kyazdani42/nvim-tree.lua',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        version = 'nightly',
        lazy = false,
        config = function()
            require('nvim-tree').setup()
        end
    },
}
