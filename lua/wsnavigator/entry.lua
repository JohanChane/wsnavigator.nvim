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
  -- wsn_blue = { fg = '#2980b9' },
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
  WsnBlExJlFilename = wsn_hls.wsn_light_grey,   -- filename of buffer in listed buffers not in jumplist
  WsnExBlFilename = wsn_hls.wsn_grey,          -- filename of buffer not in listed buffers
  WsnModified = wsn_hls.wsn_pink,              -- file modified
  WsnLineNum = wsn_hls.wsn_grey,               -- line number
  WsnFtIndent = wsn_hls.wsn_grey,              -- filetree indent
  WsnFtDirPath = wsn_hls.wsn_blue,             -- filetree dir path
  WsnFtProjNode = wsn_hls.wsn_amethyst,        -- filetree project node
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

local EntryType = {
  JumpList = 'JumpList',
}

local BufMode = {
  InBufList = 1,  -- 001
  CurBuf = 2,     -- 010
  InJumpList = 4, -- 100. In jumplist
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
local function get_incl_buflist()
  local dst_buflist = {}
  local dst_bufset = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if not is_excluded(bufnr) then
      table.insert(dst_buflist, bufnr)
      dst_bufset[bufnr] = true
    end
  end

  return { list = dst_buflist, set = dst_bufset }
end

-- get buffer list from jumplist
local function get_buflist_from_jl()
  local jumplist = vim.fn.getjumplist()[1]

  local dst_buflist = {}
  local dst_bufmap = {}
  for i = #jumplist, 1, -1 do
    if #dst_buflist >= setup_opts.max_len_of_entries then
      break
    end

    local jump = jumplist[i]

    if not is_excluded(jump.bufnr, true) then
      if not dst_bufmap[jump.bufnr] then
        table.insert(dst_buflist, jump.bufnr)
        dst_bufmap[jump.bufnr] = {}
        dst_bufmap[jump.bufnr].jump = jump
      end
    end
  end

  return { list = dst_buflist, map = dst_bufmap }
end

-- make wsnavigator buflist
local function make_wsn_buflist(jl_buflist, incl_buflist)
  local buflist_in_bl = {} -- buffers in included buflist
  local buflist_ex_bl = {} -- buffers not in included buflist
  for _, bufnr in ipairs(jl_buflist.list) do
    if incl_buflist.set[bufnr] then
      table.insert(buflist_in_bl, bufnr)
    else
      table.insert(buflist_ex_bl, bufnr)
    end
  end

  local buflist_ex_jl = {} -- buffers not in jumplist
  for _, bufnr in ipairs(incl_buflist.list) do
    if not jl_buflist.map[bufnr] then
      table.insert(buflist_in_bl, bufnr)
    end
  end

  -- move cur bufnr to first
  local cur_bufnr_idx = vim.fn.index(buflist_in_bl, vim.api.nvim_get_current_buf())
  table.remove(buflist_in_bl, cur_bufnr_idx + 1)
  table.insert(buflist_in_bl, 1, vim.api.nvim_get_current_buf())

  return { buflist_in_bl, buflist_ex_jl, buflist_ex_bl }
end

-- entry = {bufnr, lnum, col, buf_mode}
local function make_jumplist_entries(jl_buflist, incl_buflist)
  local wsn_buflist = make_wsn_buflist(jl_buflist, incl_buflist)
  local dst_buflist = {}
  dst_buflist = vim.fn.extend(dst_buflist, wsn_buflist[1])
  dst_buflist = vim.fn.extend(dst_buflist, wsn_buflist[2])
  if not setup_opts.jumplist.buf_only then
    dst_buflist = vim.fn.extend(dst_buflist, wsn_buflist[3])
  end

  local entries = {}
  local entry_set = {}
  for _, bufnr in ipairs(dst_buflist) do
    if #entries >= setup_opts.max_len_of_entries then
      break
    end

    if entry_set[bufnr] then
      goto continue
    end

    local jump
    if jl_buflist.map[bufnr] then
      jump = jl_buflist.map[bufnr].jump
    else
      jump = { bufnr = bufnr }
    end

    local entry = {}
    entry.bufnr = jump.bufnr
    entry.lnum = jump.lnum
    entry.col = jump.col

    local buf_mode = 0
    if jump.bufnr == vim.api.nvim_get_current_buf() then
      buf_mode = Flag.add_flag(buf_mode, BufMode.CurBuf)
      buf_mode = Flag.add_flag(buf_mode, BufMode.InBufList)
    end
    if incl_buflist.set[jump.bufnr] then
      buf_mode = Flag.add_flag(buf_mode, BufMode.InBufList)
    end
    if jl_buflist.map[jump.bufnr] then
      buf_mode = Flag.add_flag(buf_mode, BufMode.InJumpList)
    end

    entry.buf_mode = buf_mode
    table.insert(entries, entry)
    entry_set[entry.bufnr] = true

    ::continue::
  end

  return entries
end

-- entry = {bufnr, buf_mode}
local function make_buflist_entries(incl_buflist)
  local pathlist = {}
  for _, bufnr in ipairs(incl_buflist.list) do
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

-- entry = {key (shortcut to swith buf), bufnr, lnum, col, buf_mode}
-- entries: {EntryType: entries}
local function make_entries()
  -- local jl_buflist = get_buflist_from_jl()
  local buflist = get_incl_buflist()

  local entries = {}
  -- entries[EntryType.JumpList] = make_jumplist_entries(jl_buflist, buflist)
  entries[EntryType.JumpList] = make_buflist_entries(buflist)

  -- ## set key
  local entry_num = 0
  for _, ents in pairs(entries) do
    entry_num = entry_num + #ents
  end
  local key_list = get_keylist(entry_num)
  local keylist = { list = key_list, idx = 1 }

  for _, entry in ipairs(entries[EntryType.JumpList]) do
    entry.key = get_key(keylist)
  end

  return entries
end

-- make lines for jumplist entries
local function make_lines_for_jl_entries(jl_entries)
  local lines = {}
  for _, entry in ipairs(jl_entries) do
    -- ## filename field
    local bufname = vim.fn.bufname(entry.bufnr)
    local filename
    if bufname ~= '' then
      filename = vim.fn.fnamemodify(bufname, ':~')
      filename = vim.fn.fnamemodify(filename, ':.')
    else
      filename = '[No Name]'
    end
    local filename_hl = ''
    if not Flag.has_flag(entry.buf_mode, BufMode.InBufList) then
      filename_hl = entry_hl_names.WsnExBlFilename
    elseif Flag.has_flag(entry.buf_mode, BufMode.CurBuf) then
      filename_hl = entry_hl_names.WsnCurBufFilename
    elseif Flag.has_flag(entry.buf_mode, BufMode.InBufList)
        and not Flag.has_flag(entry.buf_mode, BufMode.InJumpList) then
      filename_hl = entry_hl_names.WsnBlExJlFilename
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

    -- ## line number field
    local lnum_str = tostring(entry.lnum or 0)
    local lnum_hl = filename_hl

    -- ## concatenate fields
    local line = {}
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
    -- table.insert(line, { ' ' })

    -- ### line number
    -- table.insert(line, { lnum_str, lnum_hl })

    table.insert(lines, line)
  end

  return lines
end

-- make filenames contains project node
local function make_proj_filenames(ft_line)
  local proj_filenames = {}
  local begin = ft_line.show.proj_node_pos.begin
  local finish = ft_line.show.proj_node_pos.begin + ft_line.show.proj_node_pos.length - 1
  proj_filenames.left = ft_line.show.path:sub(1, begin - 1)
  proj_filenames.proj = ft_line.show.path:sub(begin, finish)
  proj_filenames.right = ft_line.show.path:sub(finish + 1)

  return proj_filenames
end

-- make filetree for jumplist entries
local function make_ft_for_jl_entries(jl_entries)
  -- ## filetree lines
  local bufnr_list = {}
  local jl_entry_map = {}
  for _, entry in ipairs(jl_entries) do
    table.insert(bufnr_list, entry.bufnr)
    jl_entry_map[entry.bufnr] = entry
  end

  local filetree = wsn_filetree:make_filetree(bufnr_list)
  local ft_lines = wsn_filetree:stringify_filetree(filetree) -- filetree line

  -- ## lines
  local lines = {}
  for _, ft_line in ipairs(ft_lines) do
    local line = {}
    if ft_line.type == 'dir' then
      local proj_filenames
      if ft_line.show.proj_node_pos then
        proj_filenames = make_proj_filenames(ft_line)
      end

      table.insert(line, { ft_line.show.indent, entry_hl_names.WsnFtIndent })
      if proj_filenames then
        table.insert(line, { proj_filenames.left, entry_hl_names.WsnFtDirPath })
        table.insert(line, { proj_filenames.proj, entry_hl_names.WsnFtProjNode })
        table.insert(line, { proj_filenames.right, entry_hl_names.WsnFtDirPath })
      else
        table.insert(line, { ft_line.show.path, entry_hl_names.WsnFtDirPath })
      end
    else
      local entry = jl_entry_map[ft_line.bufnr]

      -- ## filename field
      local filename
      if ft_line.show.path ~= '' then
        filename = ft_line.show.path
      else
        filename = '[No Name]'
      end

      local filename_hl = ''
      if not Flag.has_flag(entry.buf_mode, BufMode.InBufList) then
        filename_hl = entry_hl_names.WsnExBlFilename
      elseif Flag.has_flag(entry.buf_mode, BufMode.CurBuf) then
        filename_hl = entry_hl_names.WsnCurBufFilename
      elseif Flag.has_flag(entry.buf_mode, BufMode.InBufList)
          and not Flag.has_flag(entry.buf_mode, BufMode.InJumpList) then
        filename_hl = entry_hl_names.WsnBlExJlFilename
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

      -- ## line number field
      local lnum_str = tostring(entry.lnum or 0)
      local lnum_hl = filename_hl

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
      -- table.insert(line, { ' ' })

      -- ### line number
      -- table.insert(line, { lnum_str, lnum_hl })
    end

    table.insert(lines, line)
  end

  return lines
end

-- lines = {{field1, hl}, {field2, hl}, ...}
local function make_lines_for_entries(entries)
  local lines = {}
  if setup_opts.display_mode == 'list' then
    lines = vim.fn.extend(lines, make_lines_for_jl_entries(entries[EntryType.JumpList]))
  else    -- filetree
    lines = vim.fn.extend(lines, make_ft_for_jl_entries(entries[EntryType.JumpList]))
  end

  return lines
end

return {
  make_entries = make_entries,
  make_lines_for_entries = make_lines_for_entries,
  EntryType = EntryType,
  BufMode = BufMode,
}
