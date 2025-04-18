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

-- n == 1: return the list of single-key. e.g {f, j, k, l, a, d, s}
-- n == 2: return the list of two-key combinations. e.g. {ff, dd, ss, aa}
local function make_keylist(n)
  local kw = key_weight

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

return {
  make_keylist = make_keylist
}
