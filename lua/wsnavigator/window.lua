local Window = {}
Window.__index = Window

-- ## Window utils
function Window.remove_win(win)
  vim.api.nvim_win_close(win.win_hdr, true)
  vim.api.nvim_buf_delete(win.buf_hdr, { force = true })
end

function Window.close_win(win_hdr)
  vim.api.nvim_win_close(win_hdr, true)
end

function Window.is_win_exist(win_hdr)
  return vim.api.nvim_win_is_valid(win_hdr)
end

function Window.is_hidden(win_hdr)
  local opts = vim.api.nvim_win_get_config(win_hdr)
  return opts.hide
end

function Window.hide(win_hdr)
  local opts = vim.api.nvim_win_get_config(win_hdr)
  opts.hide = true
  vim.api.nvim_win_set_config(win_hdr, opts)
end

function Window.unhide(win_hdr)
  local opts = vim.api.nvim_win_get_config(win_hdr)
  opts.hide = false
  vim.api.nvim_win_set_config(win_hdr, opts)
end

function Window.toggle_hide(win_hdr)
  local opts = vim.api.nvim_win_get_config(win_hdr)
  opts.hide = not opts.hide
  vim.api.nvim_win_set_config(win_hdr, opts)
end

-- ## Window class
function Window:new(_opts)
  local self = setmetatable({}, Window)

  _opts = _opts or {}

  local function _open_win(buf_hdr, win_opts)
    local win_hdr = vim.api.nvim_open_win(buf_hdr, true, win_opts)

    vim.api.nvim_set_option_value(
      'winhl',
      'Normal:' .. _opts.float.float_hl .. ',FloatBorder:' .. _opts.float.border_hl,
      { win = win_hdr }
    )
    vim.api.nvim_set_option_value('winblend', _opts.float.blend, { win = win_hdr })

    return { win_hdr = win_hdr, buf_hdr = buf_hdr }
  end

  local function _create_win(win_opts)
    local buf_hdr = vim.api.nvim_create_buf(false, true)
    return _open_win(buf_hdr, win_opts)
  end

  local function _create_float_win_helper()
    local lines_val = vim.api.nvim_get_option_value('lines', {})
    local columns_val = vim.api.nvim_get_option_value('columns', {})
    local win_height = math.ceil(lines_val * _opts.float.height - 4)
    local win_width = math.ceil(columns_val * _opts.float.width)
    local col = math.ceil((columns_val - win_width) * _opts.float.x)
    local row = math.ceil((lines_val - win_height) * _opts.float.y - 1)
    local win_opts = {
      style = 'minimal',
      relative = 'editor',
      border = _opts.float.border,
      width = win_width,
      height = win_height,
      row = row,
      col = col,
    }
    local win = _create_win(win_opts)
    return win
  end

  local function _create_split_win_helper()
    local win_opts = {
      style = 'minimal',
      split = _opts.split.direction,
      width = _opts.split.width,
      height = _opts.split.height,
    }
    local win = _create_win(win_opts)
    return win
  end

  function self:create_float_win()
    local win = _create_float_win_helper()

    return win
  end

  function self:create_split_win()
    local win = _create_split_win_helper()
    return win
  end

  return self
end

return {
  Window = Window
}
