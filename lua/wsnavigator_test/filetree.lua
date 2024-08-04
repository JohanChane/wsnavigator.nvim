-- Test: `:lua require('wsnavigator_test.filetree').test()`

local wsn_log = require('wsnavigator.log').Log:new({
  enable = true
})

local M = {}

local example_paths = {
  "/home/user/project/src/main.c",
  "/home/user1/project/src/utils.c",
  "/home/user/project/include/utils.h",
  "/home/user/project/README.md",
  "/root/My"
}

local FileTree = require('wsnavigator.filetree').FileTree
local wsn_filetree = FileTree:new()

function M.test()
  wsn_filetree:set_test(example_paths)
  local bufnrs = { 1, 2, 3, 4, 5 }
  --local bufnrs = {1}
  local filetree = wsn_filetree:make_filetree(bufnrs)
  wsn_log:log('filetree debug', '', { inspect = function() wsn_filetree:print_filetree(filetree) end })
end

return M
