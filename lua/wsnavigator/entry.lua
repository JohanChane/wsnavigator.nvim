local setup_opts = require('wsnavigator.config').setup_opts
local Flag = require('wsnavigator.utils').Flag
local wsn_keylist = require('wsnavigator.keylist')
local FileTree = require('wsnavigator.filetree').FileTree
local wsn_filetree = FileTree:new({ theme = require('wsnavigator').get_ft_theme() })

local key1_list   -- the list of single-key
local key2_list   -- the list of two-key combinations

-- Define color values
local wsn_hls = {
  wsn_light_red = { fg = '#e06c75' },
  wsn_light_green = { fg = '#98c379' },
  wsn_light_grey = { fg = '#D3D3D3' },
  wsn_blue = { fg = '#61afef' },
  wsn_grey = { fg = '#808080' },
  wsn_pink = { fg = '#d33682' },
  wsn_dark_teal = { fg = '#006666' },
  wsn_amethyst = { fg = '#9b59b6' },
}

-- Assign color values to highlighting groups
local default_entry_hls = {
  WsnKey = wsn_hls.wsn_light_red,              -- key
  WsnCurBufFilename = wsn_hls.wsn_light_green, -- filename of current buffer
  WsnInBlFilename = wsn_hls.wsn_light_grey,    -- filename of the buffer in listed buffers
  WsnExBlFilename = wsn_hls.wsn_grey,          -- filename of buffer not in listed buffers
  WsnModified = wsn_hls.wsn_pink,              -- file modified
  WsnFtIndent = wsn_hls.wsn_grey,              -- filetree indent
  WsnFtDirPath = wsn_hls.wsn_blue,             -- filetree dir path
}

local entry_hls = {}
if setup_opts.theme.entry_hls then
  entry_hls = vim.tbl_deep_extend('force', default_entry_hls, setup_opts.theme.entry_hls)
else
  entry_hls = default_entry_hls
end

local entry_hl_names = {}

for hl_group, hl_attrs in pairs(entry_hls) do
  vim.api.nvim_set_hl(0, hl_group, hl_attrs)
  entry_hl_names[hl_group] = hl_group
end

local BufMode = {
  InBufList = 1,  -- 001
  CurBuf = 2,     -- 010
}

-- If `n <= (the size of key1_list)`, then use key1_list; otherwise, use key2_list.
local function get_keylist(n)
  n = math.min(n, setup_opts.max_len_of_entries)

  if not key1_list then
    key1_list = key1_list or wsn_keylist.make_keylist(1)
  end
  if n <= #key1_list then
    return key1_list
  end

  if not key2_list then
    key2_list = key2_list or wsn_keylist.make_keylist(2)
  end
  if n <= #key2_list then
    return key2_list
  end

  return key2_list
end

-- Fetch keys one by one from the keylist
local function get_key(keylist)
  local key = keylist.list[keylist.idx]
  keylist.idx = keylist.idx + 1

  return key
end

-- Check if a buffer should be excluded from the buffer line
local function is_excluded(bufnr, for_jumplist)
  local is_ex = false

  if for_jumplist then
    is_ex = is_ex or not vim.api.nvim_buf_is_valid(bufnr)
  else
    is_ex = is_ex or vim.fn.buflisted(bufnr) == 0
  end

  is_ex = is_ex or vim.fn.getbufvar(bufnr, '&filetype') == 'qf' -- quickfix
      or vim.fn.getbufvar(bufnr, '&buftype') == 'terminal'
  return is_ex
end

-- get included buflist
local function get_included_buflist()
  local dst_buflist = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if not is_excluded(bufnr) then
      table.insert(dst_buflist, bufnr)
    end
  end

  return dst_buflist
end

-- entry = {bufnr, buf_mode}
local function make_buflist_entries(buflist)
  -- ## sort bufnr by path
  local pathlist = {}
  for _, bufnr in ipairs(buflist) do
    local path_entry = {}

    local path = vim.api.nvim_buf_get_name(bufnr)
    path = path:gsub("\\", "/")
    path_entry.path = path
    path_entry.bufnr = bufnr

    table.insert(pathlist, path_entry)
  end

  table.sort(pathlist, function (a, b)
    return a.path < b.path
  end)

  -- ## make entries
  local entries = {}
  for _, item in ipairs(pathlist) do
    local entry = {}
    entry.bufnr = item.bufnr

    local buf_mode = 0
    buf_mode = Flag.add_flag(buf_mode, BufMode.InBufList)
    if item.bufnr == vim.api.nvim_get_current_buf() then
      buf_mode = Flag.add_flag(buf_mode, BufMode.CurBuf)
    end
    entry.buf_mode = buf_mode

    table.insert(entries, entry)
  end

  return entries
end

-- entry = {key (shortcut to swith buf), bufnr, buf_mode}
local function make_entries()
  local buflist = get_included_buflist()
  local entries = make_buflist_entries(buflist)

  -- ## set key
  local entry_num = 0
  for _, ents in pairs(entries) do
    entry_num = entry_num + #ents
  end
  local key_list = get_keylist(entry_num)
  local keylist = { list = key_list, idx = 1 }

  for _, entry in ipairs(entries) do
    entry.key = get_key(keylist)
  end

  return entries
end

-- make filetree for entries
local function make_ft_for_entries(entries)
  -- ## filetree lines
  local bufnr_list = {}
  local entry_map = {}
  for _, entry in ipairs(entries) do
    table.insert(bufnr_list, entry.bufnr)
    entry_map[entry.bufnr] = entry
  end

  local filetree = wsn_filetree:make_filetree(bufnr_list)
  local ft_lines = wsn_filetree:stringify_filetree(filetree) -- filetree line

  -- ## lines
  local lines = {}
  for _, ft_line in ipairs(ft_lines) do
    local line = {}
    if ft_line.type == 'dir' then
      table.insert(line, { ft_line.show.indent, entry_hl_names.WsnFtIndent })
      table.insert(line, { ft_line.show.path, entry_hl_names.WsnFtDirPath })
    else
      local entry = entry_map[ft_line.bufnr]

      -- ## filename field
      local filename = ft_line.show.path

      local filename_hl = ''
      if not Flag.has_flag(entry.buf_mode, BufMode.InBufList) then
        filename_hl = entry_hl_names.WsnExBlFilename
      elseif Flag.has_flag(entry.buf_mode, BufMode.CurBuf) then
        filename_hl = entry_hl_names.WsnCurBufFilename
      elseif Flag.has_flag(entry.buf_mode, BufMode.InBufList) then
        filename_hl = entry_hl_names.WsnInBlFilename
      end

      -- ## modified field
      local is_modified = vim.fn.getbufinfo(entry.bufnr)[1].changed == 1 and true or false
      local is_modified_str = ''
      local is_modified_hl = ''
      if is_modified then
        is_modified_str = '[+]'
        is_modified_hl = entry_hl_names.WsnModified
      end

      -- ## key field
      local key_hl = entry_hl_names.WsnKey
      local key_str = entry.key or ''

      -- ## concatenate fields
      -- ### indent
      table.insert(line, { ft_line.show.indent, entry_hl_names.WsnFtIndent })
      -- ### filename
      table.insert(line, { filename, filename_hl })

      -- ### modified
      table.insert(line, { ' ' })
      if is_modified then
        table.insert(line, { is_modified_str, is_modified_hl })
        table.insert(line, { ' ' })
      end

      -- ### key
      table.insert(line, { key_str, key_hl })
    end

    table.insert(lines, line)
  end

  return lines
end

-- lines = {{field1, hl}, {field2, hl}, ...}
local function make_lines_for_entries(entries)
  local lines = {}
  lines = vim.fn.extend(lines, make_ft_for_entries(entries))

  return lines
end

return {
  make_entries = make_entries,
  make_lines_for_entries = make_lines_for_entries,
  BufMode = BufMode,
}
