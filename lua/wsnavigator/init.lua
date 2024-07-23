local config = {
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
  max_len_of_entries = 20, -- max length of entries
  jumplist = {
    buf_only = false
  }
}

local function setup(user_options)
  config = vim.tbl_deep_extend('force', config, user_options)

  require('wsnavigator.window')
  require('wsnavigator.entry')
end

local function get_config()
  return config
end

local function create_win()
  local WsNavigator = require('wsnavigator.window').Window
  local wsn_window = nil
  local wsn_entry = require('wsnavigator.entry')

  local entries = wsn_entry.make_entries()
  if not wsn_window then
    wsn_window = WsNavigator:new(config.ui)
  end
  wsn_window:create_float_win(entries, nil)
end

return {
  get_config = get_config,
  setup = setup,
  create_win = create_win,
}
