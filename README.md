# wsnavigator.nvim

## Why I Built wsnavigator.nvim

I created it to optimize the buffer-switching experience when working with a small number of buffers.

## Features

- Only uses highly accessible keys: `f d s a j k l`
- `filetree` display mode

## Installation & Configuration

```lua
{
  'JohanChane/wsnavigator.nvim',
  config = function()
    require("wsnavigator").setup({
      split = {
        direction = 'left', -- left, right, above, below. see `:h nvim_open_win()`
        width = 48,
        height = 16,
      },
      max_len_of_buffers = 7,                 -- Do not set this value above `20`, (recommended: `7`).
      cb_for_too_many_buffers = function()    -- Callback function when buffer count exceeds `max_len_of_buffers`
        require("fzf-lua").buffers()          -- Use `fzf-lua` for buffer switching when too many buffers are open.
      end                                     -- Please config your buffer switcher.
    })

    vim.keymap.set("n", "<Leader>f", function()
      require("wsnavigator").toggle_wsn()
    end, { noremap = true })
  end
}
```

## Advance configuration

See [ref](./docs/config.md)

## Screenshots

![](https://github.com/user-attachments/assets/a09ebc78-2c6c-4ace-b03a-3ff5199e40d6)

![](https://github.com/user-attachments/assets/6471b1e3-45fa-47dc-899c-73ac39ed2fd6)
