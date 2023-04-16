local M = {}

M.config = {
  border = 'single',
  dir = vim.fn.stdpath('data') .. '/gitpad',
  style = '',
  on_attach = nil,
}

local function is_git_dir()
  if vim.fn.system('git rev-parse --is-inside-work-tree 2>/dev/null') ~= '' then
    return true
  end

  vim.api.nvim_echo({
    {
      '[gitpad.nvim] Current directory is not a git repository',
      'WarningMsg',
    },
  }, true, {})
  return false
end

function M.init_gitpad_file(params)
  local is_branch = params.is_branch or false

  -- get the git repository name of the current directory
  if not is_git_dir() then
    return
  end

  -- create the repository directory if it doesn't exist
  local repository_name = vim.fn.systemlist('basename `git rev-parse --show-toplevel`')[1]
  local notes_dir = vim.fs.normalize(M.config.dir) .. '/' .. repository_name

  -- create the notes directory if it doesn't exist
  if vim.fn.isdirectory(notes_dir) == 0 then
    vim.fn.mkdir(notes_dir, 'p')
  end

  local gitpad_file_path
  local gitpad_default_text

  if is_branch then
    local branch_name = vim.fn.systemlist('basename `git rev-parse --abbrev-ref HEAD`')[1]
    gitpad_file_path = notes_dir .. '/' .. branch_name .. '-branchpad.md'
    gitpad_default_text = '# Branchpad\n\nThis is your Gitpad Branch file.\n'
  else
    gitpad_file_path = notes_dir .. '/gitpad.md'
    gitpad_default_text = '# Gitpad\n\nThis is your Gitpad file.\n'
  end

  -- create the gitpad.md file if it doesn't exist
  if vim.fn.filereadable(gitpad_file_path) == 0 then
    local fd = vim.loop.fs_open(gitpad_file_path, 'w', 438)
    if fd == nil then
      vim.api.nvim_echo({
        {
          '[gitpad.nvim] Unable to create file: ' .. gitpad_file_path,
          'WarningMsg',
        },
      }, true, {})

      return
    end
    vim.loop.fs_write(fd, gitpad_default_text)
    vim.loop.fs_close(fd)
  end

  return gitpad_file_path
end

function M.toggle_window(params)
  local path = params.path

  if path == nil then
    return
  end

  local is_branch = params.is_branch or false
  local title = ' gitpad '
  if is_branch then
    title = ' gitpad:branch '
  end

  local bufinfo = vim.fn.getbufinfo(path)
  local open_bufnr = nil

  if not vim.tbl_isempty(bufinfo) then
    local windows = bufinfo[1].windows
    open_bufnr = bufinfo[1].bufnr

    -- If the buffer is attached to a window, then just hide that window
    if not vim.tbl_isempty(windows) then
      vim.api.nvim_win_hide(windows[1])
      return
    end
  end

  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor((ui.width * 0.5) + 0.5)
  local height = math.floor((ui.height * 0.5) + 0.5)
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = (ui.width - width) / 2,
    row = (ui.height - height) / 2,
    style = M.config.style,
    border = M.config.border,
    focusable = false,
  }

  if vim.fn.has('nvim-0.9.0') == 1 then
    win_opts.title = title
    win_opts.title_pos = 'left'
  end

  -- if there is an exisitng buffer for the current file being toggled
  -- then just open that
  if open_bufnr ~= nil then
    vim.api.nvim_open_win(open_bufnr, true, win_opts)
    return
  end

  open_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(open_bufnr, 'filetype', 'markdown')

  local win_id = vim.api.nvim_open_win(open_bufnr, true, win_opts)

  vim.cmd.highlight('NormalFloat guibg=NONE guifg=NONE')
  vim.cmd.edit(path)
  vim.cmd.autocmd('BufLeave gitpad.md,gitpad*.md silent! wall')

  -- These are all the options being set when style = minimal
  -- But what's kinda annoying is the fact that using is would then
  -- set the `signcolumn` to be `auto` which is not what I want most of the time
  -- So let's just set all minimal options except signcolumn to be no
  if M.config.style == '' then
    vim.api.nvim_win_set_option(win_id, 'number', false)
    vim.api.nvim_win_set_option(win_id, 'relativenumber', false)
    vim.api.nvim_win_set_option(win_id, 'cursorline', false)
    vim.api.nvim_win_set_option(win_id, 'cursorcolumn', false)
    vim.api.nvim_win_set_option(win_id, 'foldcolumn', '0')
    vim.api.nvim_win_set_option(win_id, 'statuscolumn', '')
    vim.api.nvim_win_set_option(win_id, 'signcolumn', 'no')
    vim.api.nvim_win_set_option(win_id, 'colorcolumn', '')
  end

  if M.config.on_attach ~= nil then
    M.config.on_attach()
  end
end

function M.toggle_git_pad()
  local path = M.init_gitpad_file {}
  M.toggle_window { is_branch = false, path = path }
end

function M.toggle_git_pad_branch()
  local path = M.init_gitpad_file { is_branch = true }
  M.toggle_window { is_branch = true, path = path }
end

M.setup = function(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

return M
