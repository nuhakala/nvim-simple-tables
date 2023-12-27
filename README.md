# Neovim simple tables

I stumbled some time ago into
[https://github.com/dhruvasagar/vim-table-mode]{table mode} and I really liked
it. However, it was overriding some of my keybindings and I was not able to
disable the keybindings or change the leader because of a bug. I have not been
able to find another as good table-mode plugin so I decided to make my own.

This plugin is inspired by [vim-table-mode](https://github.com/dhruvasagar/vim-table-mode)
but aims to be simpler.

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
    separator = "-",
    separatorColumn = "|",
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

Or if you want to set them yourself:

``` lua
vim.api.nvim_set_keymap("n", "<Leader>tf", ':lua require("tablemd").format()<cr>', { noremap = true })
vim.api.nvim_set_keymap("n", "<Leader>tc", ':lua require("tablemd").insertColumn(false)<cr>', { noremap = true })
vim.api.nvim_set_keymap("n", "<Leader>td", ':lua require("tablemd").deleteColumn()<cr>', { noremap = true })
vim.api.nvim_set_keymap("n", "<Leader>tr", ':lua require("tablemd").insertRow(false)<cr>', { noremap = true })
vim.api.nvim_set_keymap("n", "<Leader>tR", ':lua require("tablemd").insertRow(true)<cr>', { noremap = true })
vim.api.nvim_set_keymap("n", "<Leader>tj", ':lua require("tablemd").alignColumn("left")<cr>', { noremap = true })
vim.api.nvim_set_keymap("n", "<Leader>tk", ':lua require("tablemd").alignColumn("center")<cr>', { noremap = true })
vim.api.nvim_set_keymap("n", "<Leader>tl", ':lua require("tablemd").alignColumn("right")<cr>', { noremap = true })
```

## Credits
Thanks to allen-mack for creating the core functionality. This repository is
forked from [here](https://github.com/allen-mack/nvim-table-md) and adds some
new features.

