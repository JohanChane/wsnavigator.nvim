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

return {
  Flag = Flag
}
