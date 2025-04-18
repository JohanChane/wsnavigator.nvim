# wsnavigator.nvim

## Why I Built wsnavigator.nvim

I've been using fuzzy finder plugins like `fzf-lua.nvim` and `telescope.nvim` for buffer switching. While these tools are powerful,
they feel like overkill when I only have 5-10 files open. The typical workflow of "open → filter → select" becomes unnecessarily cumbersome for a small number of buffers. 

Since working with few buffers is my common scenario and buffer switching is such a frequent operation, I wanted a solution that
simplifies this to just "open → select". After searching for quick-selection plugins like Harpoon and not finding anything that fit my needs,
I decided to build this plugin myself.

## Key Features

- Intuitive selection using just the `fdsajkl` keys
- Buffers listed in jumplist order
- `filetree` display mode

## Installation & Configuration

```lua
{
  'JohanChane/wsnavigator.nvim',
  config = function()
    require("wsnavigator").setup({
      max_len_of_buffers = 7,                 -- Do not set this value above `20`, (recommended: `7`).
      cb_for_too_many_buffers = function()    -- Callback function when buffer count exceeds `max_len_of_buffers`
        require("fzf-lua").buffers()          -- Use `fzf-lua` for buffer switching when too many buffers are open. Please config your buffer switcher.
      end
    })

    vim.keymap.set("n", "<Leader>f", function()
      require("wsnavigator").open_wsn()
    end, { noremap = true })
  end
}
```

## Advance configuration

See [ref](./docs/config.md)

## Screenshots

![](https://github.com/user-attachments/assets/c4fb53a5-5b73-4cc9-aaba-93a5436f9266)

![](https://github.com/user-attachments/assets/d03d103a-4f88-4ee1-9250-63bde2e3d4f8)
