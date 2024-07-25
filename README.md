# wsnavigator.nvim

## Why I Created wsnavigator.nvim

I have been using fuzzy find plugins, such as fzf-lua.nvim and telescope.nvim, to switch my buffers. They are very powerful, but in most cases, I only have 5-10 files open. For this, I have to go through the steps of "open" -> "filter" -> "select". I feel that when there are fewer buffers, it should only take "open" -> "select". Having fewer buffers is a common situation, and switching buffers is a frequent operation. Therefore, I found it necessary to write a plugin to support this situation. I then searched for some quick selection plugins, such as harpoon, but they did not meet my needs. So, I wrote this plugin based on my needs.

## Features

- Use only `fdsajkl` keys for selection.
- List buffers in the order of the jumplist.
- `filetree` display mode.
- Different categories (listed, in jumplist, etc.) of buffers are displayed in different colors, along with relevant buffer information (currently only displaying the current line number).

## Installation

```lua
{
  'JohanChane/wsnavigator.nvim',
  config = function()
    require('wsnavigator').setup{}
  end,
},
```

## Configuration

```lua
{
  'JohanChane/wsnavigator.nvim',
  config = function()
    require('wsnavigator').setup {
      ui = {
        float = {
          border    = 'single', -- see ':h nvim_open_win'
          float_hl  = 'Normal', -- see ':h winhl'
          border_hl = 'Normal',
          blend     = 0,      -- see ':h winblend'
          height    = 0.9,    -- Num from 0 - 1 for measurements
          width     = 0.9,
          x         = 0.5,    -- X and Y Axis of Window
          y         = 0.4
        },
      },
      max_len_of_entries = 20,   -- max length of entries.
      display_mode = 'filetree', -- filetree | list
      jumplist = {
        buf_only = false         -- show buf_only
      },
      filetree = {
        --theme = { -- user your theme
        --  indent = '  ',
        --  branch = '│ ',
        --  last_child = '└─',
        --  mid_child = '├─',
        --},
        theme_name = 'classic', -- 'classic' | 'fine' | 'bold' | 'dotted'
        -- | 'minimal' | 'double' | 'arrows' | 'simple' | 'tree' | 'compact_tree'
      },
    }

    -- use buf_only
    vim.keymap.set('n', 'tt', function()
      local wsn = require('wsnavigator')
      wsn.set_opts({ jumplist = { buf_only = true } })
      wsn.open_wsn()
    end, { noremap = true })

    -- use jumplist
    vim.keymap.set('n', 'tj', function()
      local wsn = require('wsnavigator')
      wsn.set_opts({ jumplist = { buf_only = false } })
      wsn.open_wsn()
    end, { noremap = true })

    -- switch_display_mode
    vim.keymap.set('n', 'ts', function()
      local wsn = require('wsnavigator')
      wsn.switch_display_mode()
    end, { noremap = true })
  end,
},
```

## TODOs

-   [x] Display buffers according to the file tree. See [ref](https://www.reddit.com/r/neovim/comments/1e9vibn/use_neotree_to_quick_switch_buffers_and_manage/). If it's not too complex, I will try to implement it.
-   [ ] Combine with fuzzy find plugin.
-   [ ] Display the current line's function in the buffer, format `filename key function:offset:lnum`
-   [ ] `SaveProject`: Record `project_name:path`
-   [ ] `SaveMark`: Record `filename key function:offset:lnum` for each project.

## Screenshots

![wsnavigator_jumplist](https://github.com/user-attachments/assets/dbdd6231-4981-415c-a631-9a13aaf16886)

![wsnavigator_jl_filetree](https://github.com/user-attachments/assets/a6639f69-d379-45ba-864d-497e1ffc8c7c)
