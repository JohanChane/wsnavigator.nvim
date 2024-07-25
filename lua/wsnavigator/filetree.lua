local log = require('wsnavigator.log').log
local is_project_node = require('wsnavigator.utils').is_project_node

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

  -- Split path `/home/user/` to {home, user}. Not {/, home, user}.
  local function _split_path(path, delimiter)
    if not path or path == '' then
      return {}
    end

    local parts = {}

    for match in (path .. delimiter):gmatch('(.-)' .. delimiter) do
      if match ~= '' then
        table.insert(parts, match)
      end
    end
    return parts
  end

  -- Find or create a directory node
  -- Assume path is {home, user}. And the file tree is {'', home}.
  -- When current is 'home', the part is 'user'. current is the part father.
  local function _find_or_create_dir(root, path)
    local current = root
    for _, part in ipairs(path) do
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

  -- node = {type = 'file|dir', filename, childs, bufnr(if type == 'file')}
  -- root node = {filename = ''}, child of root node = {filename = 'home'}
  function self:make_filetree(bufnrs)
    local root = { type = 'dir', filename = '', childs = {} }

    for _, bufnr in ipairs(bufnrs) do
      local path
      if _opts.does_test then
        path = example_paths[bufnr]
      else
        path = vim.api.nvim_buf_get_name(bufnr)
      end
      local parts = _split_path(path, '/')
      local filename = table.remove(parts)
      local dir_node = _find_or_create_dir(root, parts) -- now parts is dirname
      table.insert(dir_node.childs, { type = 'file', filename = filename, childs = {}, bufnr = bufnr })
    end

    return root
  end

  local function _findout_project_node_helper(node, parent_path)
    if not node or node.type == 'file' then
      return
    end

    local cur_path = vim.fs.joinpath(parent_path, node.filename)
    if is_project_node(cur_path) then
      node.is_proj_node = true
      return
    end

    for _, child in ipairs(node.childs) do
      _findout_project_node_helper(child, cur_path)
    end
  end

  local function _findout_project_node(root)
    _findout_project_node_helper(root, '/') -- Since root node = {filename = ''}
  end

  -- Add filetree line
  local function _add_ft_line(lines, node, indent, line_nodes, is_root)
    -- ## handle path
    local filenames = {}
    for _, n in ipairs(line_nodes) do
      table.insert(filenames, n.filename)
    end

    local root_path = is_root and '/' or ''
    local path = root_path .. vim.fn.join(filenames, '/')

    local line = {
      type = node.type,
      bufnr = node.bufnr,
      show = { indent = indent, path = path }
    }

    -- ## handle project node
    local cur_idx = 0
    local cur_path = is_root and '/' or ''
    for _, n in ipairs(line_nodes) do
      if not n.filename or #n.filename <= 0 then
        goto continue
      end

      if n.is_proj_node then
        local proj_node_pos = {}
        proj_node_pos.begin = cur_idx + 1
        proj_node_pos.length = #n.filename

        line.show.proj_node_pos = proj_node_pos
        break
      end
      cur_path = vim.fs.joinpath(cur_path, n.filename)
      cur_idx = #cur_path

      ::continue::
    end

    table.insert(lines, line)
  end

  -- line = {type = 'file|dir', bufnr(if type == 'file'), show = {indent, filenames}}
  local function _stringify_tree_helper(lines, node, is_parent_root, cur_indent, parent_indent)
    cur_indent = cur_indent or ''
    parent_indent = parent_indent or ''

    if #node.childs == 0 then
      log('', cur_indent .. (node.filename or ''), { print_msg_only = true })
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
    log('', line, { print_msg_only = true })
    _add_ft_line(lines, current, cur_indent, line_nodes, is_parent_root)
    line_nodes = {}

    for i, child in ipairs(current.childs) do
      if child.type == 'file' then
        local indent_str
        if i == #current.childs then
          indent_str = _opts.theme.last_child
        else
          indent_str = _opts.theme.mid_child
        end
        log('', parent_indent .. indent_str .. child.filename, { print_msg_only = true })
        _add_ft_line(lines, child, parent_indent .. indent_str, { child })
      else
        local cur_indent_str
        local parent_indent_str
        if i == #current.childs then
          cur_indent_str = _opts.theme.last_child
          parent_indent_str = _opts.theme.indent
        else
          cur_indent_str = _opts.theme.mid_child
          parent_indent_str = _opts.theme.branch
        end
        _stringify_tree_helper(lines, child, false, parent_indent .. cur_indent_str,
          parent_indent .. parent_indent_str)
      end
    end
  end

  function self:stringify_filetree(node)
    _findout_project_node(node)

    local lines = {}
    for _, child in ipairs(node.childs) do
      _stringify_tree_helper(lines, child, true, '', '')
    end
    log('stringify_filetree', '', { inspect = function() print(vim.inspect(lines)) end })
    return lines
  end

  -- For testing
  function self:print_filetree(node)
    local lines = self:stringify_filetree(node)
    log('print_filetree', '', { inspect = function() print(vim.inspect(lines)) end })
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
