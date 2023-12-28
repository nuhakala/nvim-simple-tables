# Neovim simple tables

Neovim plugin to help with markdown tables.
This plugin is inspired by [nvim-table-md](https://github.com/allen-mack/nvim-table-md)
and adds some functionality to be more like
[vim-table-mode](https://github.com/dhruvasagar/vim-table-mode).

## Features

- Add/delete columns/rows
- Mode for automatically formatting table
- Auto-format separator lines
- Not limited to some filetype: you can call the lua functions in any file
- Preserves indentation (linewise)
- Choose custom separators

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
    default_keymap = true,
    separator = "-",
    separator_column = "|",
    default_align = "left",

    -- If you want autoformat always when modifying text, add these: "TextChanged", "TextChangedI",
    mode_events = { "InsertLeave" }
}
```

## Usage

### Behavior

This plugin does not do anything by default, you have to initialize all the API
calls. However, it sets a set of keybindings by default, which you can disable.
For the available API-calls, check [key maps](#key-maps)

If you want to use the `alignColumn` function call to automatically align a column
then the information of the alignments is stored
in the second row of the table. If second row is not a separator row, separator
row is added. `toggleAlign` calls `alignColumn` to change the alignemnt, so it
works similarly. However, If you don't want to have a separator row as the second
row, you can add a separator row elsewhere and manually edit it to contain alignment
data. `:---:` for align center and `---:` for align right and `---` for align left.
If you add alignment data to the very first row of the table, then the formatting will
break for some reason and it adds extra padding each time you format.

Sometimes the behavior is little odd for example when deleting columns. It might
delete previous or next column instead of current one. This is because sometimes
it calculates the position of cursor inaccurately. You can prevent this by moving
cursor to more middle of the column.

### Key Maps

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

