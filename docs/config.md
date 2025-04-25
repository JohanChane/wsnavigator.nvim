## Advance configuration

```lua
{
  'JohanChane/wsnavigator.nvim',
  config = function()
    require('wsnavigator').setup {
      ui = {
        default = 'split',
        split = {
          direction = 'left', -- left, right, above, below. see `:h nvim_open_win()`
          width = 48,
          height = 16,
        },
        float = {
          border = "single", -- see ':h nvim_open_win'
          float_hl = "Normal", -- see ':h winhl'
          border_hl = "Normal",
          blend = 0,  -- see ':h winblend'
          height = 0.7, -- Num from 0 - 1 for measurements
          width = 0.7,
          x = 0.5,    -- X and Y Axis of Window
          y = 0.4,
        },
      },
      max_len_of_buffers = 7,                   -- If the number of buffers exceeds this threshold, automatically call `cb_for_too_many_buffers`
	    cb_for_too_many_buffers = function() end, -- callback function to execute when buffer limit exceed
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
      --keymaps = {       -- keymaps for wsnavigator buffer. `:h :map`
      --  quit = { 'q', '<Esc>' },
      --},
      theme = {
        --entry_hls = {     -- Ref `default_entry_hls`
        --  WsnKey = { fg = '#ff0000' },
        --}
      },
    }

    -- use buf_only
    vim.keymap.set('n', '<Leader>t', function()
      require('wsnavigator').open_wsn()
    end, { noremap = true })
  end,
},
```
