local wsn_log = require('wsnavigator.log').Log:new({
  enable = require('wsnavigator.config').setup_opts.debug
})

-- For testing
local example_paths

local FileTree = {}
FileTree.__index = FileTree

-- ## FileTree utils
FileTree.themes = {
  classic = {
    indent = '    ',
    branch = '│   ',
    last_child = '└── ',
    mid_child = '├── ',
  },
  fine = {
    indent = '    ',
    branch = '│   ',
    last_child = '└── ',
    mid_child = '├── ',
  },
  bold = {
    indent = '    ',
    branch = '┃   ',
    last_child = '┗━━ ',
    mid_child = '┣━━ ',
  },
  dotted = {
    indent = '    ',
    branch = '│   ',
    last_child = '└··· ',
    mid_child = '├··· ',
  },
  minimal = {
    indent = '  ',
    branch = '| ',
    last_child = '\\- ',
    mid_child = '|- ',
  },
  double = {
    indent = '    ',
    branch = '║   ',
    last_child = '╚══ ',
    mid_child = '╠══ ',
  },
  arrows = {
    indent = '    ',
    branch = '→   ',
    last_child = '↳→ ',
    mid_child = '↳→ ',
  },
  simple = {
    indent = '  ',
    branch = '| ',
    last_child = '`- ',
    mid_child = '|- ',
  },
  tree = {
    indent = '    ',
    branch = '│   ',
    last_child = '└─ ',
    mid_child = '├─ ',
  },
  compact_tree = {
    indent = '  ',
    branch = '│ ',
    last_child = '└─',
    mid_child = '├─',
  },
}

-- _opts = {indent}
function FileTree:new(_opts)
  local self = setmetatable({}, FileTree)

  _opts = _opts or {}
  _opts.indent = _opts.indent or '..'
  _opts.does_test = false -- does test filetree

  _opts.theme = _opts.theme or FileTree.themes.classic

  -- Find or create a directory node
  local function _find_or_create_dir(root, parts)
    local current = root
    for _, part in ipairs(parts) do
      local found = false
      for _, child in ipairs(current.childs) do
        if child.type == 'dir' and child.filename == part then
          current = child
          found = true
          break -- next part
        end
      end

      if not found then
        local new_node = { type = 'dir', filename = part, childs = {} }
        table.insert(current.childs, new_node)
        current = new_node
      end
    end
    return current
  end

  function self:make_filetree(bufnrs)
    local root = { type = 'dir', filename = '', childs = {} }

    for _, bufnr in ipairs(bufnrs) do
      local path
      if _opts.does_test then
        path = example_paths[bufnr]
      else
        path = vim.api.nvim_buf_get_name(bufnr)
        if path == '' then    -- new buffer
          path = vim.fs.joinpath(vim.fn.getcwd(), "[No Name]")
        end
        path = path:gsub("\\", "/")
      end

      local parts = vim.split(path, "/")      -- `/home/user` => {"", "home", "user"};
                                              -- `./foo/bar` => {".", "foo", "bar"}; 
                                              -- `""` => {""}
      
      local filename = table.remove(parts)
      local dir_node = _find_or_create_dir(root, parts) -- now parts is dirname
      table.insert(dir_node.childs, { type = 'file', filename = filename, childs = {}, bufnr = bufnr })
    end

    return root
  end

  -- Add filetree line
  local function _add_ft_line(lines, node, indent, line_nodes)
    -- ## handle path
    local filenames = {}
    for _, n in ipairs(line_nodes) do
      table.insert(filenames, n.filename)
    end

    local path
    if #filenames == 1 and filenames[1] == '' then    -- root
      path = filenames[1] .. '/'
    else
      path = vim.fn.join(filenames, '/')
    end

    local line = {
      type = node.type,
      bufnr = node.bufnr,
      show = { indent = indent, path = path }
    }

    table.insert(lines, line)
  end

  -- line = {type = 'file|dir', bufnr(if type == 'file'), show = {indent, filenames}}
  local function _stringify_tree_helper(lines, node, is_parent_root, cur_indent, parent_indent)
    cur_indent = cur_indent or ''
    parent_indent = parent_indent or ''

    if #node.childs == 0 then
      wsn_log:log('', cur_indent .. (node.filename or ''), { print_msg_only = true })
      _add_ft_line(lines, node, cur_indent, { node })
      return
    end

    local line
    local line_nodes = {} -- nodes in a line
    if is_parent_root then
      line = cur_indent .. '/' .. node.filename
      table.insert(line_nodes, node)
    else
      line = cur_indent .. node.filename
      table.insert(line_nodes, node)
    end

    local current = node
    while #current.childs == 1 and current.childs[1].type == 'dir' do
      current = current.childs[1]
      line = line .. '/' .. current.filename
      table.insert(line_nodes, current)
    end
    wsn_log:log('', line, { print_msg_only = true })
    _add_ft_line(lines, current, cur_indent, line_nodes)
    line_nodes = {}

    local dir_children = {}
    local file_children = {}
    for _, child in ipairs(current.childs) do
      if child.type == 'dir' then
        table.insert(dir_children, child)
      else
        table.insert(file_children, child)
      end
    end

    for i, child in ipairs(dir_children) do
      local cur_indent_str
      local parent_indent_str
      if i == #dir_children and #file_children == 0 then    -- last child
        cur_indent_str = _opts.theme.last_child
        parent_indent_str = _opts.theme.indent
      else
        cur_indent_str = _opts.theme.mid_child
        parent_indent_str = _opts.theme.branch
      end
      _stringify_tree_helper(lines, child, false, parent_indent .. cur_indent_str,
        parent_indent .. parent_indent_str)
    end

    for i, child in ipairs(file_children) do
      local indent_str
      if i == #file_children then               -- last child
        indent_str = _opts.theme.last_child
      else
        indent_str = _opts.theme.mid_child
      end
      wsn_log:log('', parent_indent .. indent_str .. child.filename, { print_msg_only = true })
      _add_ft_line(lines, child, parent_indent .. indent_str, { child })
    end
  end

  function self:stringify_filetree(node)
    local lines = {}
    for _, child in ipairs(node.childs) do
      _stringify_tree_helper(lines, child, true, '', '')
    end
    wsn_log:log('stringify_filetree', '', { inspect = function() print(vim.inspect(lines)) end })
    return lines
  end

  -- For testing
  function self:print_filetree(node)
    local lines = self:stringify_filetree(node)
    wsn_log:log('print_filetree', '', { inspect = function() print(vim.inspect(lines)) end })
    for _, line in ipairs(lines) do
      print(line.show.indent .. line.show.path)
    end
  end

  -- For testing
  function self:set_test(paths)
    _opts.does_test = true
    example_paths = paths
  end

  return self
end

return {
  FileTree = FileTree
}
