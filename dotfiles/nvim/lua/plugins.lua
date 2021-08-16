local execute = vim.api.nvim_command
local fn = vim.fn

local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
  execute 'packadd packer.nvim'
end

return require('packer').startup(function()
  -- Do I need this?
  use {'tpope/vim-sensible'}

  use {'bogado/file-line'}
  use {'npxbr/gruvbox.nvim', requires = {'rktjmp/lush.nvim'}}
  use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'}
  use {'kyazdani42/nvim-web-devicons'}
  use {'hashivim/vim-terraform'}
  use {'nvim-telescope/telescope.nvim', requires = {'nvim-lua/plenary.nvim'}}
end)
