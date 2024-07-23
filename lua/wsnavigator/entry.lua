local config = require('wsnavigator').get_config()

vim.api.nvim_set_hl(0, 'WsNavigatorRedText', { fg = '#e06c75' })
vim.api.nvim_set_hl(0, 'WsNavigatorGreenText', { fg = '#98c379' })
vim.api.nvim_set_hl(0, 'WsNavigatorBlueText', { fg = '#61afef' })
vim.api.nvim_set_hl(0, 'WsNavigatorGreyText', { fg = '#808080' })

local key1_list = nil
local key2_list = nil

local EntryType = {
  JumpList = 'JumpList',
}

local EntryBufType = {
  BufInList = {},
  BufNotInList = {},
  CurBuf = {},
}

-- Define a weight table representing the typing difficulty of each key
local key_weight = {
  f = 1,
  j = 2,
  k = 3,
  l = 4,
  a = 4,
  d = 6,
  s = 7,
}

local key_layout = {
  left = {
    f = true,
    d = true,
    s = true,
    a = true,
  },
  right = {
    j = true,
    k = true,
    l = true,
  },
}

-- Function to calculate the weight of a combination
local function comb_weight(combo)
  local k1 = string.sub(combo, 1, 1)
  local k2 = string.sub(combo, 2, 2)
  local weight = key_weight[k1] + key_weight[k2]

  if k1 == k2 then
    weight = weight - 2
    -- If the combination is typed with the same hand, increase the weight
  elseif key_layout.left[k1] and key_layout.left[k2] then
    weight = weight + 2
  elseif key_layout.right[k1] and key_layout.right[k2] then
    weight = weight + 2
  end

  return weight
end

local function make_keylist(kw, n)
  local keylist = {}
  if n == 1 then
    for k, _ in pairs(kw) do
      table.insert(keylist, k)
    end

    table.sort(keylist, function(a, b)
      return kw[a] < kw[b]
    end)
  elseif n == 2 then
    -- Generate all possible combinations of two keys
    for k1, _ in pairs(kw) do
      for k2, _ in pairs(kw) do
        table.insert(keylist, k1 .. k2)
      end
    end

    -- Sort the combinations by their weight
    table.sort(keylist, function(a, b)
      return comb_weight(a) < comb_weight(b)
    end)
  end

  return keylist
end

-- Check if a buffer should be excluded from the buffer line
local function is_excluded(bufnr)
  local is_ex = vim.fn.buflisted(bufnr) == 0
      or vim.fn.getbufvar(bufnr, '&filetype') == 'qf' -- quickfix
      or vim.fn.getbufvar(bufnr, '&buftype') == 'terminal'
  return is_ex
end

local function get_my_jumplist(buf_list, buf_set)
  local is_buf_only = config.jumplist.buf_only

  local dst_jumplist = {}
  local jumplist_set = {}

  local jumplist = vim.fn.getjumplist()[1]
  local cur_buf_pos
  for i, jump in ipairs(jumplist) do
    if is_buf_only then
      if buf_set[jump.bufnr] then
        table.insert(dst_jumplist, jump)
        jumplist_set[jump.bufnr] = true
      end
    else
      table.insert(dst_jumplist, jump)
      jumplist_set[jump.bufnr] = true
    end

    if jump.bufnr == vim.api.nvim_get_current_buf() then
      cur_buf_pos = i
    end
  end

  local buf_jumplist = {}
  for _, bufnr in ipairs(buf_list) do
    if not jumplist_set[bufnr] then
      local jump = { bufnr = bufnr }
      local bufinfo = vim.fn.getbufinfo(bufnr)[1]
      jump.filename = bufinfo.name
      table.insert(buf_jumplist, jump)
    end
  end
  dst_jumplist = vim.fn.extend(dst_jumplist, buf_jumplist)

  if cur_buf_pos then
    local jump = dst_jumplist[cur_buf_pos]
    --table.remove(dst_jumplist, cur_buf_pos)
    table.insert(dst_jumplist, jump)
  end

  return dst_jumplist
end

local function get_buf_list()
  local bufnr_list_included = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if not is_excluded(bufnr) then
      table.insert(bufnr_list_included, bufnr)
    end
  end

  return bufnr_list_included
end

local function get_keylist(n)
  n = math.min(n, config.max_len_of_entries)

  if not key1_list then
    key1_list = key1_list or make_keylist(key_weight, 1)
  end
  if n <= #key1_list then
    return key1_list
  end

  if not key2_list then
    key2_list = key2_list or make_keylist(key_weight, 2)
  end
  if n <= #key2_list then
    return key2_list
  end

  return key2_list
end

local function make_jumplist_entries(jumplist, key_list, idx, buf_set)
  local entries = {}
  local jumplist_buf_set = {}
  for i = #jumplist, 1, -1 do
    local jump = jumplist[i]

    if #entries < config.max_len_of_entries and not jumplist_buf_set[jump.bufnr] then
      jumplist_buf_set[jump.bufnr] = true

      local entry = {}
      entry.key = key_list[idx]
      entry.bufnr = jump.bufnr
      entry.lnum = jump.lnum

      local buf_type
      if jump.bufnr == vim.api.nvim_get_current_buf() then
        buf_type = EntryBufType.CurBuf
      elseif buf_set[jump.bufnr] then
        buf_type = EntryBufType.BufInList
      else
        buf_type = EntryBufType.BufNotInList
      end
      entry.buf_type = buf_type
      table.insert(entries, entry)

      idx = idx + 1
    end
  end

  return entries
end

local function make_entries()
  local entries = {}

  local buf_list = get_buf_list()
  local buf_set = {}
  for _, bufnr in ipairs(buf_list) do
    buf_set[bufnr] = true
  end

  local jumplist = get_my_jumplist(buf_list, buf_set)
  local key_list = get_keylist(#jumplist)

  local idx = 1

  entries[EntryType.JumpList] = make_jumplist_entries(jumplist, key_list, idx, buf_set)

  return entries
end

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
    if entry.buf_type == EntryBufType.BufNotInList then
      filename_hl = 'WsNavigatorGreyText'
    elseif entry.buf_type == EntryBufType.CurBuf then
      filename_hl = 'WsNavigatorGreenText'
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
    table.insert(line, { tostring(entry.lnum or 1), filename_hl })

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
  EntryBufType = EntryBufType,
}
