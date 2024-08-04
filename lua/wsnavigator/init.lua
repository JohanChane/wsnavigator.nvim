local M = {}

function M.setup(opts)
  local config = require('wsnavigator.config')
  config.setup_opts = vim.tbl_deep_extend('force', config.default_opts, opts)
end

function M.switch_display_mode()
  local setup_opts = require('wsnavigator.config').setup_opts

  local display_modes = { 'filetree', 'list' }

  local next_idx = (vim.fn.index(display_modes, setup_opts.display_mode) + 1) % #display_modes + 1
  setup_opts.display_mode = display_modes[next_idx]
  vim.api.nvim_echo({ { string.format('display_mode: %s', setup_opts.display_mode) } }, false, {})
end

-- get filetree theme
function M.get_ft_theme()
  local setup_opts = require('wsnavigator.config').setup_opts
  -- use user theme
  if setup_opts.filetree.theme then
    return setup_opts.filetree.theme
  end

  local FileTree = require('wsnavigator.filetree').FileTree
  local theme = FileTree.themes[setup_opts.filetree.theme_name]
  return theme
end

local lazyloaded_modules = {
  open_wsn = { 'wsnavigator.wsn', 'open_wsn' },
  set_opts = { 'wsnavigator.wsn', 'set_opts' },
}

for k, v in pairs(lazyloaded_modules) do
  M[k] = function(...)
    return require(v[1])[v[2]](...)
  end
end

local exported_modules = {
  'wsn'
}

for _, m in ipairs(exported_modules) do
  M[m] = function()
    return require('wsnavigator.' .. m)
  end
end

return M
