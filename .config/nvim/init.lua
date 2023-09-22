local fn = vim.fn
local lazy_path = fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazy_path) then
    fn.system({
        'git', 'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazy_path
    })
end

vim.opt.rtp:prepend(lazy_path)

require('lazy').setup({
    -- My plugins here
    {
        'kyazdani42/nvim-tree.lua',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        version = 'nightly'
    },
    'neovim/nvim-lspconfig',
    'williamboman/nvim-lsp-installer',
    {
        'nvim-treesitter/nvim-treesitter',
        config = function()
            require('plug/treesitter')
        end,
        lazy = false
    },
    {
        'LionC/nest.nvim',
        lazy = false,
        config = function()
            require('binds')
        end
    },
    {
        'hrsh7th/nvim-cmp',
        config = function()
            require('plug/cmp')
        end,
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
        }
    },
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    -- use 'gauteh/vim-cppman'
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
            require('plug/telescope')
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
        "folke/which-key.nvim",
        config = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
            require("which-key").setup {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            }
        end
    },

    {
        'pwntester/octo.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
            'nvim-tree/nvim-web-devicons'
        },
    },

    {
        'jose-elias-alvarez/null-ls.nvim',
        dependencies = {
            { 'nvim-lua/plenary.nvim' }
        },
        config = function()
            require('plug/null-ls')
        end
    },

    {
        'nvim-telescope/telescope-fzf-native.nvim',
        build =
        'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
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
            require('plug/vimwiki')
        end
    },

    {
        'folke/trouble.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons'
        },
    },
    'rudism/telescope-dict.nvim',
    {
        'catppuccin/nvim',
        name = 'catppuccin',
        lazy = false,
        config = function()
            require('plug/colorscheme')
        end
    },
    {
        "ellisonleao/gruvbox.nvim",
        lazy = false
    },

    { 'LunarVim/bigfile.nvim' },
})

require('binds')
require('options')
require('nvim-lsp-installer').setup {}
require('nvim-tree').setup()

require('plugins')
