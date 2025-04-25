local M = {}

function M.setup(opts)
  local config = require('wsnavigator.config')
  config.setup_opts = vim.tbl_deep_extend('force', config.default_opts, opts)
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
  toggle_wsn = { 'wsnavigator.wsn', 'toggle_wsn' },
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
