local M = {}
local H = {}
local uv = vim.uv or vim.loop
local gitpad_win_id = nil

M.config = {
  title = 'gitpad',
  dir = vim.fs.normalize(vim.fn.stdpath('data') .. '/gitpad'),
  default_text = nil,
  on_attach = nil,
  window_type = 'floating', -- options: floating, split
  floating_win_opts = {
    relative = 'editor',
    style = '',
    border = 'single',
    focusable = false,
  },
  split_win_opts = {
    split = 'right',
  },
}

function H.is_git_dir()
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

function H.get_branch_filename()
  -- local branch_name = vim.fn.systemlist('basename `git rev-parse --abbrev-ref HEAD`')[1]
  local branch_name = vim.fn.systemlist('git branch --show-current')[1]
  return H.clean_filename(branch_name)
end

function H.clean_filename(filename)
  if filename == nil then
    return nil
  end

  -- remove any spaces in the branch name and replace with a hyphen
  -- replace any forward slashes with a colon so that the file is not created in a subdirectory
  filename = filename:gsub('%s+', '-'):gsub('/', ':')
  return filename
end

function M.init_gitpad_file(opts)
  local clean_name = H.clean_filename(opts.filename) or nil

  -- get the git repository name of the current directory
  if not H.is_git_dir() then
    return
  end

  -- create the repository directory if it doesn't exist
  local repository_path = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  local repository_name = vim.fs.basename(repository_path)
  local notes_dir = vim.fs.normalize(M.config.dir .. '/' .. repository_name)

  -- create the notes directory if it doesn't exist
  if not uv.fs_stat(notes_dir) then
    vim.fn.mkdir(notes_dir, 'p')
  end

  local gitpad_file_path
  local gitpad_default_text

  if clean_name ~= nil then
    gitpad_default_text = '# ' .. clean_name .. ' \n\nThis is your new gitpad file.\n'

    if clean_name == H.get_branch_filename() then
      clean_name = clean_name .. '-branchpad.md'
      gitpad_default_text = '# ' .. clean_name .. ' Branchpad\n\nThis is your gitpad branch file.\n'
    end

    gitpad_file_path = notes_dir .. '/' .. vim.fn.fnameescape(clean_name)
  else
    gitpad_file_path = notes_dir .. '/gitpad.md'
    gitpad_default_text = '# Gitpad\n\nThis is your Gitpad file.\n'
  end

  -- create the gitpad.md file if it doesn't exist
  if not uv.fs_stat(gitpad_file_path) then
    local fd = uv.fs_open(gitpad_file_path, 'w', 438)
    if fd == nil then
      vim.api.nvim_echo({
        {
          '[gitpad.nvim] Unable to create file: ' .. gitpad_file_path,
          'WarningMsg',
        },
      }, true, {})
      return
    end

    -- write the default text to the file
    if M.config.default_text == nil then
      uv.fs_write(fd, gitpad_default_text)
    end
    uv.fs_close(fd)
  end

  return gitpad_file_path
end

function M.close_window(opts)
  local wininfo = vim.fn.getwininfo(gitpad_win_id)

  -- We might have closed the window not via this method so we need to
  -- check if the window id is still valid via `getwininfo`
  if gitpad_win_id == nil or vim.tbl_isempty(wininfo) then
    gitpad_win_id = nil
    return false
  end

  local bufnr = vim.api.nvim_win_get_buf(gitpad_win_id)
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  -- Just ensure that we are closing the correct window
  -- This is just to prevent closing a gitpad project window or gitpad branch window
  if bufname == opts.path then
    vim.api.nvim_win_close(gitpad_win_id, true)
    gitpad_win_id = nil
    return true
  end

  return false
end

function M.open_window(opts)
  local path = opts.path
  local title = opts.title or M.config.title
  local window_type = opts.window_type or M.config.window_type

  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor((ui.width * 0.5) + 0.5)
  local height = math.floor((ui.height * 0.5) + 0.5)

  -- Use this table for supporting more built-in window configurations
  local switch_table = {
    ['floating'] = function()
      local default_float_win_opts = {
        width = width,
        height = height,
        col = (ui.width - width) / 2,
        row = (ui.height - height) / 2,
      }
      default_float_win_opts = vim.tbl_deep_extend('force', default_float_win_opts, M.config.floating_win_opts)
      return vim.tbl_deep_extend('force', default_float_win_opts, opts.floating_win_opts or {})
    end,

    ['split'] = function()
      return vim.tbl_deep_extend('force', M.config.split_win_opts, opts.split_win_opts or {})
    end,
  }

  -- default to floating window
  local win_opts = switch_table['floating']()
  if switch_table[window_type] then
    win_opts = switch_table[window_type]()
  end

  if win_opts['relative'] and vim.fn.has('nvim-0.9.0') == 1 then
    win_opts.title = ' ' .. title .. ' '
    win_opts.title_pos = 'left'
  end

  local bufnr = vim.fn.bufadd(path)
  if gitpad_win_id == nil then
    gitpad_win_id = vim.api.nvim_open_win(bufnr, true, win_opts)
  end

  vim.api.nvim_set_option_value('filetype', 'markdown', { buf = bufnr })
  vim.api.nvim_set_option_value('buflisted', false, { buf = bufnr })

  if win_opts['relative'] then
    vim.api.nvim_set_option_value(
      'winhighlight',
      'Normal:GitpadFloat,FloatBorder:GitpadFloatBorder,FloatTitle:GitpadFloatTitle',
      { win = gitpad_win_id }
    )
  end

  -- These are all the options being set when style = minimal
  -- But what's kinda annoying is the fact that using is would then
  -- set the `signcolumn` to be `auto` which is not what I want most of the time
  -- So let's just set all minimal options except signcolumn to be no
  if M.config.style == '' then
    vim.api.nvim_set_option_value('number', false, { win = gitpad_win_id })
    vim.api.nvim_set_option_value('relativenumber', false, { win = gitpad_win_id })
    vim.api.nvim_set_option_value('cursorline', false, { win = gitpad_win_id })
    vim.api.nvim_set_option_value('cursorcolumn', false, { win = gitpad_win_id })
    vim.api.nvim_set_option_value('foldcolumn', '0', { win = gitpad_win_id })
    vim.api.nvim_set_option_value('statuscolumn', '', { win = gitpad_win_id })
    vim.api.nvim_set_option_value('signcolumn', 'no', { win = gitpad_win_id })
    vim.api.nvim_set_option_value('colorcolumn', '', { win = gitpad_win_id })
  end

  if M.config.on_attach ~= nil then
    M.config.on_attach(vim.api.nvim_win_get_buf(gitpad_win_id))
  end
end

function M.toggle_window(opts)
  if not M.close_window(opts) then
    M.open_window(opts)
  end
end

function M.toggle_gitpad(opts)
  opts = opts or {}
  local path = M.init_gitpad_file(opts)

  M.toggle_window(vim.tbl_deep_extend('force', opts, { path = path }))
end

function M.toggle_gitpad_branch(opts)
  opts = vim.tbl_deep_extend('force', opts or {}, { filename = H.get_branch_filename() })
  M.toggle_gitpad(opts)
end

M.setup = function(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

return M
