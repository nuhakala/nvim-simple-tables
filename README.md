# Neovim simple tables

Neovim plugin to help with markdown tables.
This plugin is inspired by [nvim-table-md](https://github.com/allen-mack/nvim-table-md)
and adds some functionality to be more like
[vim-table-mode](https://github.com/dhruvasagar/vim-table-mode).

## Features

- Add/delete columns/rows
- Mode for automatically formatting table (when leaving insert mode)
- Auto-format separator lines
- Not limited to some filetype: you can call the lua functions in any file
- Preserves indentation (linewise)

## Installation

You can install this with your favourite plugin manager, here is example with
Lazy.

``` lua
{
    "nuhakala/nvim-simple-tables",
    opts = {
        -- Your configuration here
    }
},
```

## Default config

``` lua
{
    defaultKeymap = true,
    defaultAlign = "left"
}
```

## Key Maps

Default keymaps are

| Key          | Behavior                              |
| ---          | ---                                   |
| \<Leader\>ec | Add column to the right of the cursor |
| \<Leader\>ed | Delete the current column             |
| \<Leader\>ef | Format the table                      |
| \<Leader\>eR | Add row above the current line        |
| \<Leader\>er | Add row below the current line        |
| \<Leader\>ej | Align column to the left              |
| \<Leader\>ek | Center column                         |
| \<Leader\>el | Align column to the right             |
| \<Leader\>em | Toggle mode                           |
| \<Leader\>et | Toggle alignment                      |

Or if you want to set them yourself:

``` lua
vim.api.nvim_set_keymap("n", "<Leader>ef", ':lua require("tablemd").formatTable()<cr>', { noremap = true, desc = "Format table" })
vim.api.nvim_set_keymap("n", "<Leader>eC", ':lua require("tablemd").insertColumn(false)<cr>', { noremap = true, desc = "Insert column before" })
vim.api.nvim_set_keymap("n", "<Leader>ec", ':lua require("tablemd").insertColumn(true)<cr>', { noremap = true, desc = "Insert column after" })
vim.api.nvim_set_keymap("n", "<Leader>ed", ':lua require("tablemd").deleteColumn()<cr>', { noremap = true, desc = "Delete column" })
vim.api.nvim_set_keymap("n", "<Leader>er", ':lua require("tablemd").insertRow(false)<cr>', { noremap = true, desc = "Insert row before" })
vim.api.nvim_set_keymap("n", "<Leader>eR", ':lua require("tablemd").insertRow(true)<cr>', { noremap = true, desc = "Insert row after" })
vim.api.nvim_set_keymap("n", "<Leader>ek", ':lua require("tablemd").alignColumn("center")<cr>', { noremap = true, desc = "Toggle column align" })
vim.api.nvim_set_keymap("n", "<Leader>em", ':lua require("tablemd").toggleMode()<cr>', { noremap = true, desc = "Toggle tablemode" })
vim.api.nvim_set_keymap("n", "<Leader>et", ':lua require("tablemd").toggleAlign()<cr>', { noremap = true, desc = "Toggle column alignment" })
```

## Credits
Thanks to allen-mack for creating the core functionality. This repository is
forked from [here](https://github.com/allen-mack/nvim-table-md) and adds some
new features.

