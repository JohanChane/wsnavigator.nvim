local Flag = {}

function Flag.has_flag(value, flag)
  return value % (flag * 2) >= flag
end

function Flag.add_flag(value, flag)
  if Flag.has_flag(value, flag) then
    return value
  else
    return value + flag
  end
end

function Flag.remove_flag(value, flag)
  if Flag.has_flag(value, flag) then
    return value - flag
  else
    return value
  end
end

local function is_array(t)
  if type(t) ~= 'table' then return false end
  local max = 0
  for k, v in pairs(t) do
    if type(k) ~= 'number' then return false end
    if k > max then max = k end
  end
  return max == #t
end

-- Modify the dst object in place, without creating a new object.
local function tbl_deep_extend_inplace(dst, src)
  for k, v in pairs(src) do
    if type(v) == 'table' and type(dst[k]) == 'table' then
      if is_array(v) then
        -- If both are arrays, extend the destination array
        for _, v2 in ipairs(v) do
          table.insert(dst[k], v2)
        end
      else
        -- Recursively merge tables
        tbl_deep_extend_inplace(dst[k], v)
      end
    else
      -- Directly set value
      dst[k] = v
    end
  end
end

local function exists(name)
  local stat = vim.loop.fs_stat(name)
  return stat ~= nil
end

local function is_project_node(path)
  local filenames_in_proj_root = { '.bzr', '.git', '.hg', '.svn', 'package.json',
    'compile_flags.txt', '.root' }

  for _, v in ipairs(filenames_in_proj_root) do
    if exists(path .. '/' .. v) then
      return true
    end
  end

  return false
end

return {
  Flag = Flag,
  tbl_deep_extend_inplace = tbl_deep_extend_inplace,
  is_project_node = is_project_node,
}
