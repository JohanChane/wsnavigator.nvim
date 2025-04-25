local setup_opts = require('wsnavigator.config').setup_opts
local Window = require('wsnavigator.window').Window
local wsn_window = Window:new(setup_opts.ui)
local wsn_entry = require('wsnavigator.entry')
local Flag = require('wsnavigator.utils').Flag

local wsn_win = nil

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

local function select_entry(entry)
  if Flag.has_flag(entry.buf_mode, wsn_entry.BufMode.CurBuf) then
  elseif Flag.has_flag(entry.buf_mode, wsn_entry.BufMode.InBufList) then
    vim.api.nvim_set_current_buf(entry.bufnr)
  else
    vim.cmd.edit(vim.api.nvim_buf_get_name(entry.bufnr))
    if entry.lnum then
      vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col or 0 })
    end
  end
end

local function remove_wsn_win()
  Window.remove_win(wsn_win)
  wsn_win =nil
end

local function create_wsn_win(entries, win_type)
  win_type = win_type or setup_opts.ui.default

  local win
  if win_type == "split" then
    win = wsn_window:create_split_win()
  else
    win = wsn_window:create_float_win()
  end

  local lines = wsn_entry.make_lines_for_entries(entries)

  -- ## set lines for buffer and highlight lines
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

  vim.api.nvim_buf_set_lines(win.buf_hdr, 0, -1, false, str_lines)

  for i, line in ipairs(hl_lines) do
    for _, field in ipairs(line) do
      if field[2] and field[2] ~= '' then
        vim.api.nvim_buf_add_highlight(win.buf_hdr, -1, field[2], i - 1, field[3], field[4])
      end
    end
  end

  --vim.api.nvim_win_set_cursor(win.win_hdr, {0, 0})

  -- ## set buffer keymaps
  local keymaps = {}
  for _, entry in ipairs(entries) do
    local keymap = {}
    keymap.key = entry.key
    keymap.cb = function()
      remove_wsn_win(win)
      select_entry(entry)
    end
    table.insert(keymaps, keymap)
  end
  set_keymaps(win.buf_hdr, keymaps)

  -- For quitting wsnavigator
  for _, key in ipairs(setup_opts.keymaps.quit) do
    vim.keymap.set('n', key, function()
      remove_wsn_win(win)
    end, { buffer = win.buf_hdr, noremap = true })
    vim.keymap.set('n', key, function()
      remove_wsn_win(win)
    end, { buffer = win.buf_hdr, noremap = true })
  end

  for _, key_cb in ipairs(setup_opts.keymaps.callbacks) do
    vim.keymap.set('n', key_cb.key, function()
      remove_wsn_win(win)
      key_cb.cb({buf_only = setup_opts.jumplist.buf_only})
    end, { buffer = win.buf_hdr, noremap = true })
  end

  return win
end

local function open_wsn()
  local entries = wsn_entry.make_entries()

  if #entries > setup_opts.max_len_of_buffers then
    setup_opts.cb_for_too_many_buffers()
    return
  end

  wsn_win = create_wsn_win(entries)
end

local function toggle_wsn()
  if wsn_win == nil then
    open_wsn()
  else
    remove_wsn_win()
  end
end

local function set_opts(opts)
  require('wsnavigator.utils').tbl_deep_extend_inplace(setup_opts, opts)
end

return {
  open_wsn = open_wsn,
  toggle_wsn = toggle_wsn,
  set_opts = set_opts,
}
