# wsnavigator.nvim

## Why wsnavigator.nvim

-   When I use neovim, I usually open multiple files. Although some plugins can filter and select buffers, switching to the buffer I want is not fast enough. Buffers are not well sorted, and there is not enough relevant information about them.
-   When I want to record the position of a function, neovim's `mark` feature is not very convenient. I cannot filter out the marks that record functions. I want to implement the features I need in this plugin.

## Installation

```lua
{
  'JohanChane/wsnavigator.nvim',
  config = function()
    require('wsnavigator').setup{}

    vim.keymap.set('n', 'tt', function()
      require('wsnavigator').create_win()
    end, { noremap = true })
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
          border    = 'single',         -- see ':h nvim_open_win'
          float_hl  = 'Normal',         -- see ':h winhl'
          border_hl = 'Normal',
          blend     = 0,                -- see ':h winblend'
          height    = 0.9,              -- Num from 0 - 1 for measurements
          width     = 0.9,
          x         = 0.5,              -- X and Y Axis of Window
          y         = 0.4
        },
      },
      max_len_of_entries = 20,    -- max length of entries
    }

    vim.keymap.set('n', 'tt', function()
      require('wsnavigator').create_win()
    end, { noremap = true })
  end,
},
```

## ToDo

-   [ ] Display the current line's function in the buffer, format `filename key function:offset:lnum`
-   [ ] `SaveProject`: Record `project_name:path`
-   [ ] `SaveMark`: Record `filename key function:offset:lnum` for each project.
