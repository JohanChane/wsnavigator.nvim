local default_opts = {
  ui = {
    float = {
      border = 'none',
      float_hl = 'Normal',
      border_hl = 'FloatBorder',
      blend = 0,
      height = 0.8,
      width = 0.8,
      x = 0.5,
      y = 0.5
    },
  },
  max_len_of_entries = 20,   -- max length of entries.
  display_mode = 'filetree', -- filetree | list
  jumplist = {
    buf_only = false         -- show buf_only
  },
  filetree = {
    theme = nil, -- user theme
    theme_name = 'classic',
  },
  debug = false,
}

local setup_opts = {}

return {
  default_opts = default_opts,
  setup_opts = setup_opts
}
