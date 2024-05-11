# 📝 gitpad.nvim

A minimal neovim plugin for taking down notes for git projects and per branch

![gitpad.nvim screenshot](https://user-images.githubusercontent.com/10972027/233791549-0556234c-5cce-45a8-8c35-32f91b2bd001.png)

## ✨ Features
- Provides a command to toggle the `gitpad.md` file in a floating window, so you can take notes while working on your code.
- Supports creating and toggling a separate `branchpad.md` file for each branch, if desired.

## ⚡️ Requirements
- Neovim >= 0.7.2

Disclaimer: Plugin should work fine with Neovim > 0.6.0 but I haven't tested it yet

## 📦 Installation

Use your favorite plugin manager to install gitpad.nvim. For example, using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'yujinyuz/gitpad.nvim',
  config = function()
    require("gitpad").setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
  end
}
```

## ⚙️ Configuration

### Setup

gitpad comes with the following defaults:

```lua
{
  border = 'single', -- The border style of the floating window. Possible values are `'single'`, `'double'`, `'shadow'`, `'rounded'`, and `''` (no border).
  style = '', -- The style of the floating window. Possible values are `'minimal'` (no line numbers, statusline, or sign column. See :help nvim_open_win() '), and `''` (default Neovim style).
  dir = vim.fn.stdpath('data') .. '/gitpad', -- The directory where the notes are stored. Possible value is a valid path ie '~/notes'
  on_attach = function(bufnr)
    -- You can also define a function to be called when the gitpad window is opened, by setting the `on_attach` option:
    -- This is just an example
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', '<Cmd>wq<CR>', { noremap = true, silent = true })
  end,
}
```

## 🚀 Usage

### Toggling the gitpad window

The plugin provides the following methods that you can use to open gitpad or the gitpad branch

```lua
require('gitpad').toggle_gitpad()
-- OR
require('gitpad').toggle_gitpad_branch()
```

## License
This plugin is distributed under the terms of the MIT License.
