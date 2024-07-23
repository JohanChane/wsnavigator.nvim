local Window = {}
Window.__index = Window

local Flag = require('wsnavigator.utils').Flag

local function set_keymaps(buf_hdr, keymaps)
  for _, km in ipairs(keymaps) do
    if km.key and km.key ~= '' then
      vim.keymap.set('n', km.key, km.cb, {
        buffer = buf_hdr,
        noremap = true
      })
    end
  end
end

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

  local _entry_m = require('wsnavigator.entry')

  _opts = _opts or {}

  local function _open_win(buf_hdr, win_opts, lines, cursor_pos)
    local win_hdr = vim.api.nvim_open_win(buf_hdr, true, win_opts)

    local hl_lines = {}
    local str_lines = {}
    for _, line in ipairs(lines) do
      local str_line = ''
      local char_idx = 0
      local fields = {}
      for _, field in ipairs(line) do
        str_line = str_line .. field[1]

        table.insert(fields, { field[1], field[2], char_idx, char_idx + #field[1] })
        char_idx = char_idx + #field[1]
      end
      table.insert(str_lines, str_line)
      table.insert(hl_lines, fields)
    end

    vim.api.nvim_buf_set_lines(buf_hdr, 0, -1, false, str_lines)

    for i, line in ipairs(hl_lines) do
      for _, field in ipairs(line) do
        if field[2] and field[2] ~= '' then
          vim.api.nvim_buf_add_highlight(buf_hdr, -1, field[2], i - 1, field[3], field[4])
        end
      end
    end

    if cursor_pos then
      vim.api.nvim_win_set_cursor(win_hdr, cursor_pos)
    end

    vim.api.nvim_set_option_value(
      'winhl',
      'Normal:' .. _opts.float.float_hl .. ',FloatBorder:' .. _opts.float.border_hl,
      { win = win_hdr }
    )
    vim.api.nvim_set_option_value('winblend', _opts.float.blend, { win = win_hdr })

    return { win_hdr = win_hdr, buf_hdr = buf_hdr }
  end

  local function _create_win(win_opts, lines, cursor_pos)
    local buf_hdr = vim.api.nvim_create_buf(false, true)
    return _open_win(buf_hdr, win_opts, lines, cursor_pos)
  end

  local function _create_float_win_helper(lines, cursor_pos)
    local lines_val = vim.api.nvim_get_option_value('lines', {})
    local columns_val = vim.api.nvim_get_option_value('columns', {})
    local win_height = math.ceil(lines_val * _opts.float.height - 4)
    local win_width = math.ceil(columns_val * _opts.float.width)
    local col = math.ceil((columns_val - win_width) * _opts.float.x)
    local row = math.ceil((lines_val - win_height) * _opts.float.y - 1)
    local opts = {
      style = 'minimal',
      relative = 'editor',
      border = _opts.float.border,
      width = win_width,
      height = win_height,
      row = row,
      col = col,
    }
    local win = _create_win(opts, lines, cursor_pos)
    return win
  end

  local function _select_entry(entry)
    if Flag.has_flag(entry.buf_mode, _entry_m.BufMode.CurBuf) then
    elseif Flag.has_flag(entry.buf_mode, _entry_m.BufMode.InBufList) then
      vim.api.nvim_set_current_buf(entry.bufnr)
    else
      vim.cmd.edit(vim.api.nvim_buf_get_name(entry.bufnr))
      if entry.lnum then
        vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col or 0 })
      end
    end
  end

  function self:create_float_win(entries, cursor_pos)
    local lines = _entry_m.make_lines_for_entries(entries)
    local win = _create_float_win_helper(lines, cursor_pos)
    local keymaps = {}
    for _, entry in ipairs(entries[_entry_m.EntryType.JumpList]) do
      local keymap = {}
      keymap.key = entry.key
      keymap.cb = function()
        Window.remove_win(win)
        _select_entry(entry)
      end
      table.insert(keymaps, keymap)
    end
    set_keymaps(win.buf_hdr, keymaps)

    vim.keymap.set('n', 'q', function()
      Window.remove_win(win)
    end, { buffer = win.buf_hdr, noremap = true })
    vim.keymap.set('n', '<Esc>', function()
      Window.remove_win(win)
    end, { buffer = win.buf_hdr, noremap = true })
  end

  return self
end

return {
  Window = Window
}
