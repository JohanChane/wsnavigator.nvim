local default_opts = {
  ui = {
    float = {
      border = "single",   -- see ':h nvim_open_win'
      float_hl = "Normal", -- see ':h winhl'
      border_hl = "Normal",
      blend = 0,           -- see ':h winblend'
      height = 0.9,        -- Num from 0 - 1 for measurements
      width = 0.9,
      x = 0.5,             -- X and Y Axis of Window
      y = 0.4,
    },
  },
  max_len_of_entries = 20,   -- max length of entries.
  max_len_of_buffers = 7,    -- If the number of buffers exceeds this threshold, automatically call `cb_for_too_many_buffers`
  cb_for_too_many_buffers = function()
  end,                       -- callback function to execute when buffer limit exceed
  display_mode = 'filetree', -- filetree | list
  jumplist = {
    buf_only = true          -- show buf_only
  },
  filetree = {
    theme = nil, -- user theme
    theme_name = 'classic',
  },
  keymaps = { -- keymaps for wsnavigator buffer. `:h :map`
    quit = { 'q', '<Esc>' },
    switch_display_mode = { 'ts' },
    callbacks = {},
  },
  theme = {
    entry_hls = nil -- user entry highlightings
  },
  debug = false,
}

local setup_opts = {}

return {
  default_opts = default_opts,
  setup_opts = setup_opts
}
