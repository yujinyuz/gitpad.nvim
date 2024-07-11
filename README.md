# 📝 gitpad.nvim

A minimal neovim plugin for taking down notes for git projects and per branch

![gitpad.nvim screenshot](https://github.com/yujinyuz/gitpad.nvim/assets/10972027/516838f5-9e14-4177-9abc-6f71a4b7feac)

## ✨ Features

- Provides a per repository / per branch way of note taking while working on your code with the help
  of standard or floating windows.
- Supports creating and toggling a separate `{branch}-branchpad.md` file for each branch,
  if desired.
- Extensible note list (daily notes, per-file notes, etc.)

## ⚡️ Requirements

- Neovim >= 0.7.2

Disclaimer: Plugin should work fine with most neovim versions but I have not tested yet

## 📦 Installation

Use your favorite plugin manager to install gitpad.nvim. For example,
using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'yujinyuz/gitpad.nvim',
  config = function()
    require('gitpad').setup({
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    })
  end,
  keys = {
    {
      '<leader>pp',
      function()
        require('gitpad').toggle_gitpad() -- or require('gitpad').toggle_gitpad({ title = 'Project notes' })
      end,
      desc = 'gitpad project',
    },
    {
      '<leader>pb',
      function()
        require('gitpad').toggle_gitpad_branch() -- or require('gitpad').toggle_gitpad_branch({ title = 'Branch notes' })
      end,
      desc = 'gitpad branch',
    },
    {
      '<leader>pvs',
      function()
        require('gitpad').toggle_gitpad_branch({ window_type = 'split', split_win_opts = { split = 'right' } })
      end,
      desc = 'gitpad branch vertical split',
    },

    -- Daily notes
    {
      '<leader>pd',
      function()
        local date_filename = 'daily-' .. os.date('%Y-%m-%d.md')
        require('gitpad').toggle_gitpad({ filename = date_filename }) -- or require('gitpad').toggle_gitpad({ filename = date_filename, title = 'Daily notes' })
      end,
      desc = 'gitpad daily notes',
    },
    -- Per file notes
    {
      '<leader>pf',
      function()
        local filename = vim.fn.expand('%:p') -- or just use vim.fn.bufname()
        if filename == '' then
          vim.notify('empty bufname')
          return
        end
        filename = vim.fn.pathshorten(filename, 2) .. '.md'
        require('gitpad').toggle_gitpad({ filename = filename }) -- or require('gitpad').toggle_gitpad({ filename = filename, title = 'Current file notes' })
      end,
      desc = 'gitpad per file notes',
    },
  },
}

```

## ⚙︎ Configuration

### Setup

gitpad.nvim comes with the following defaults:

```lua
{
  title = 'gitpad', -- The title of the floating window
  dir = vim.fn.stdpath('data') .. '/gitpad', -- The directory where the notes are stored. Possible value is a valid path ie '~/notes'
  default_text = nil, -- Leave this nil if you want to use the default text
  on_attach = function(bufnr)
    -- You can also define a function to be called when the gitpad window is opened, by setting the `on_attach` option:
    -- This is just an example
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', '<Cmd>wq<CR>', { noremap = true, silent = true })
  end,
  window_type = 'floating', -- Options are 'floating' or 'split'
  floating_win_opts = {
    relative = 'editor', -- where the floating window should appear. See :help nvim_open_win()
    style = '', -- The style of the floating window. Possible values are `'minimal'` (no line numbers, statusline, or sign column. See :help nvim_open_win() '), and `''` (default Neovim style).
    border = 'single', -- The border style of the floating window. Possible values are `'single'`, `'double'`, `'shadow'`, `'rounded'`, and `''` (no border).
    focusable = false, -- Enables focus by user actions. See :help nvim_open_win()
  },
  split_win_opts = {
    split = 'right', -- Controls split direction if window_type == 'split'. Options are 'left', 'right', 'above', or 'below'. See :help nvim_open_win()
  },
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
