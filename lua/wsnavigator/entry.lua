local setup_opts = require('wsnavigator.config').setup_opts
local Flag = require('wsnavigator.utils').Flag
local wsn_keylist = require('wsnavigator.keylist')

local key1_list
local key2_list

vim.api.nvim_set_hl(0, 'WsNavigatorRedText', { fg = '#e06c75' })
vim.api.nvim_set_hl(0, 'WsNavigatorGreenText', { fg = '#98c379' })
vim.api.nvim_set_hl(0, 'WsNavigatorBlueText', { fg = '#61afef' })
vim.api.nvim_set_hl(0, 'WsNavigatorGreyText', { fg = '#808080' })
vim.api.nvim_set_hl(0, 'WsNavigatorDarkCyanText', { fg = '#006666' })

local EntryType = {
  JumpList = 'JumpList',
}

local BufMode = {
  InBufList = 1,  -- 001
  CurBuf = 2,     -- 010
  InJumpList = 4, -- 100. In jumplist
}

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

local function get_key(keylist)
  local key = keylist.list[keylist.idx]
  keylist.idx = keylist.idx + 1

  return key
end

-- Check if a buffer should be excluded from the buffer line
local function is_excluded(bufnr)
  local is_ex = vim.fn.buflisted(bufnr) == 0
      or vim.fn.getbufvar(bufnr, '&filetype') == 'qf' -- quickfix
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

    if not dst_bufmap[jump.bufnr] then
      table.insert(dst_buflist, jump.bufnr)
      dst_bufmap[jump.bufnr] = {}
      dst_bufmap[jump.bufnr].jump = jump
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

  return { buflist_in_bl, buflist_ex_jl, buflist_ex_bl }
end

local function make_jumplist_entries(jl_buflist, incl_buflist)
  local wsn_buflist = make_wsn_buflist(jl_buflist, incl_buflist)
  local dst_buflist = {}
  dst_buflist = vim.fn.extend(dst_buflist, { vim.api.nvim_get_current_buf() })
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

local function make_entries()
  local jl_buflist = get_buflist_from_jl()
  local buflist = get_incl_buflist()

  local entries = {}
  entries[EntryType.JumpList] = make_jumplist_entries(jl_buflist, buflist)

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
    local key_hl = 'WsNavigatorRedText'

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
      filename_hl = 'WsNavigatorGreyText'
    elseif Flag.has_flag(entry.buf_mode, BufMode.CurBuf) then
      filename_hl = 'WsNavigatorGreenText'
    elseif Flag.has_flag(entry.buf_mode, BufMode.InBufList)
        and not Flag.has_flag(entry.buf_mode, BufMode.InJumpList) then
      filename_hl = 'WsNavigatorDarkCyanText'
    end

    local is_modified = vim.fn.getbufinfo(entry.bufnr)[1].changed == 1 and true or false
    local is_modified_str = ''
    local is_modified_hl = ''
    if is_modified then
      is_modified_str = '[+]'
      is_modified_hl = 'WsNavigatorBlueText'
    end

    local line = {}
    table.insert(line, { filename, filename_hl })
    table.insert(line, { ' ' })
    if is_modified then
      table.insert(line, { is_modified_str, is_modified_hl })
      table.insert(line, { ' ' })
    end
    table.insert(line, { entry.key or '', key_hl })
    table.insert(line, { ' ' })
    table.insert(line, { tostring(entry.lnum or 0), filename_hl })

    table.insert(lines, line)
  end

  return lines
end

local function make_lines_for_entries(entries)
  local lines = {}
  lines = vim.fn.extend(lines, make_lines_for_jl_entries(entries[EntryType.JumpList]))

  return lines
end

return {
  make_entries = make_entries,
  make_lines_for_entries = make_lines_for_entries,
  EntryType = EntryType,
  BufMode = BufMode,
}
