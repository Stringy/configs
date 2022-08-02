local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

require('packer').startup(function(use)
  -- My plugins here
  use 'wbthomason/packer.nvim'
  use { 
      'kyazdani42/nvim-tree.lua',
      requires = {
          'kyazdani42/nvim-web-devicons',
      },
      tag = 'nightly'
  }
  use 'morhetz/gruvbox'
  use 'neovim/nvim-lspconfig'
  use 'williamboman/nvim-lsp-installer'
  use { 'nvim-treesitter/nvim-treesitter', run=':TSUpdate' }
  use 'LionC/nest.nvim'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'gauteh/vim-cppman'
  use {
      'nvim-telescope/telescope.nvim',
      requires = {
          { 'nvim-lua/plenary.nvim' }
      }
  }
  use 'habamax/vim-godot'
  use {
      'romgrk/barbar.nvim',
      requires = {'kyazdani42/nvim-web-devicons'}
  }
  use 'tpope/vim-fugitive'
  use 'tpope/vim-surround'
  use 'lukas-reineke/indent-blankline.nvim'
  use 'lukas-reineke/lsp-format.nvim'
  use 'shaunsingh/solarized.nvim'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)

require('binds')
require('options')
require('nvim-lsp-installer').setup{}
require('nvim-tree').setup()

require('plugins')
