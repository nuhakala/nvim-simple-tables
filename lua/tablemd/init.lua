-- Setup
local Tablemd = {}
local H = {} -- for helper functions
local modeFlag = false

-- Default config
Tablemd.config = {
    defaultKeymap = true,
    separator = "-", -- changing this also breaks it
    separatorColumn = "|", -- Changing this breaks it
    defaultAlign = "left",
}

Tablemd.setup = function(cfg)
    local config = H.setup_config(cfg)
    Tablemd.config = config

    if config.defaultKeymap then
        H.setKeyMap()
    end
end


-- TABLEMODE FUNCTIONS

---Formats the markdown table so cells in a column are a uniform width.
function Tablemd.formatTable()
    local start_line = nil
    local end_line = nil
    local cursor_location = vim.fn.line('v')

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location)

    -- Get column definitions
    local col_defs = H.get_column_defs(start_line, end_line)

    -- Format each line
    for i = start_line, end_line do -- The range includes both ends.
        local line, count = H.trim_string(vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1])
        local formatted_line = H.get_formatted_line(line, col_defs, count)

        -- replace the line with the formatted line in the buffer
        vim.api.nvim_buf_set_lines(0, i - 1, i, false, { formatted_line })
    end
end

---Aligns the column. Possible values for alignment are "left", "right", and "center".
function Tablemd.alignColumn(alignment)
    -- Don't do anything if the alignment value isn't one of the predefined values.
    if not (alignment == "left" or alignment == "right" or alignment == "center") then
        return
    end

    local start_line = nil
    local cursor_location = vim.api.nvim_win_get_cursor(0)

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location[1])

    -- Get the current column index
    local current_col = H.get_current_column_index()

    -- Get the second line
    local line, indent = H.trim_string(vim.api.nvim_buf_get_lines(0, start_line, start_line + 1, false)[1])
    local t = H.split_string(line, Tablemd.config.separatorColumn)
    local is_second = H.is_separator(t)
    local is_first = false
    if not is_second then
        line, indent = H.trim_string(vim.api.nvim_buf_get_lines(0, start_line - 1, start_line, false)[1])
        t = H.split_string(line, Tablemd.config.separatorColumn)
        is_first = H.is_separator(t)
    end
    local is_new = not is_first and not is_second

    -- Rebuild the line
    local new_line = "|"
    local table_len = 0
    for _ in pairs(t) do table_len = table_len + 1 end

    for i = 1, table_len do
        if i ~= current_col then
            if is_new then
                new_line = new_line .. H.get_separator_cell(3) .. Tablemd.config.separatorColumn
            else
                new_line = new_line .. H.trim_string(t[i]) .. Tablemd.config.separatorColumn
            end
        else
            local build_str = H.trim_string(t[i]):sub(2, -2)
            if is_new then
                build_str = "---"
            end

            if alignment == "left" then
                new_line = new_line .. build_str .. Tablemd.config.separatorColumn
            end

            if alignment == "right" then
                new_line = new_line .. build_str .. ":" .. Tablemd.config.separatorColumn
            end

            if alignment == "center" then
                new_line = new_line .. ":" .. build_str .. ":" .. Tablemd.config.separatorColumn
            end
        end
    end
    new_line = H.replace_last(new_line)

    -- Replace second line with the formatted line in the buffer, if the second
    -- line is a separator.
    -- If not, then add a new line to the beginning of the table
    if is_second then
        vim.api.nvim_buf_set_lines(0, start_line, start_line + 1, false, { H.add_indent(new_line, indent) })
    else
        -- If first line is separator, then replace it
        -- Otherwise add new row
        if is_first then
            vim.api.nvim_buf_set_lines(0, start_line - 1, start_line, false, { H.add_indent(new_line, indent) })
        else
            vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, { H.add_indent(new_line, indent) })
        end
    end

    Tablemd.formatTable()
end

---Deletes the current column from the table.
function Tablemd.deleteColumn()
    local start_line = nil
    local end_line = nil
    local cursor_location = vim.api.nvim_win_get_cursor(0)
    local m = Tablemd.config.separatorColumn

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location[1])

    -- Get the current column index
    local current_col = H.get_current_column_index()

    -- Format each line
    for i = start_line, end_line do
        local line, indent = H.trim_string(vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1])
        local t = H.split_string(line, m)

        local new_line = "|"
        local table_len = 0
        for _ in pairs(t) do table_len = table_len + 1 end

        for j = 1, table_len do
            if j ~= current_col then
                new_line = new_line .. H.trim_string(t[j]) .. " ".. m .. " "
            end
        end

        -- replace the line with the formatted line in the buffer
        new_line = H.replace_last(new_line)
        vim.api.nvim_buf_set_lines(0, i - 1, i, false, { H.add_indent(new_line, indent) })
    end

    Tablemd.formatTable()
end

---Formats each line in the table with a new column.
---@param bool before If true, the column will be inserted on the left side of the current column
function Tablemd.insertColumn(before)
    local start_line = nil
    local end_line = nil
    local cursor_location = vim.api.nvim_win_get_cursor(0)
    local m = Tablemd.config.separatorColumn

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location[1])

    -- Get the current column index
    local current_col = H.get_current_column_index()

    -- Format each line
    for i = start_line, end_line do -- The range includes both ends.
        local line, indent = H.trim_string(vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1])

        local t = H.split_string(line, m)
        local is_sep = H.is_separator(t)

        local new_line = "|"
        local table_len = 0
        for _ in pairs(t) do table_len = table_len + 1 end

        -- This code gets "duplicated" in the next loop, so it is encapsulated in a function here.
        local insertBlankColumn = function(l)
            if is_sep then
                l = l .. "-----".. Tablemd.config.separatorColumn .. "-"
            else
                l = l .. "    ".. Tablemd.config.separatorColumn .. " "
            end

            return l
        end

        -- Loop through every column in the table line.
        for j = 1, table_len do
            if before == true and j == current_col then
                new_line = insertBlankColumn(new_line)
            end

            if is_sep then
                new_line = new_line .. H.trim_string(t[j]) .. m
            else
                new_line = new_line .. H.trim_string(t[j]) .. " " .. m .. " "
            end

            if before == false and j == current_col then
                new_line = insertBlankColumn(new_line)
            end
        end

        -- replace the line with the formatted line in the buffer
        new_line = H.replace_last(new_line)
        vim.api.nvim_buf_set_lines(0, i - 1, i, false, { H.add_indent(new_line, indent) })
    end

    Tablemd.formatTable()
end

---Inserts a new row into the table
---@param bool before If true, the row will be inserted above the current row
function Tablemd.insertRow(before)
    -- Get the current location of the cursor
    local cursor_location = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_location[1]
    local _, indent = H.trim_string(vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1])

    local col_defs = H.get_column_defs(line_num, line_num)
    local new_line = "|"

    for _, _ in ipairs(col_defs) do
        new_line = new_line .. "   " .. Tablemd.config.separatorColumn
    end

    -- If 'before' is true, then insert the row above the current row.
    if before then
        line_num = line_num - 1
    end

    new_line = H.replace_last(new_line)
    -- To insert a line, pass in the same line number for both start and end.
    vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { H.add_indent(new_line, indent) })

    -- Move the cursor to the newly created line
    vim.api.nvim_win_set_cursor(0, { line_num + 1, cursor_location[2] })

    Tablemd.formatTable()
end

---Toggle tablemode
Tablemd.toggleMode = function()
    if not modeFlag then
        local auGroup = vim.api.nvim_create_augroup('Tablemode', { clear = false })
        vim.api.nvim_create_autocmd({ "InsertLeave" }, {
            group = auGroup,
            callback = function() Tablemd.formatTable() end,
        })
        modeFlag = true
        print("Tablemode enabled")
    else
        vim.api.nvim_clear_autocmds({ group = "Tablemode" })
        modeFlag = false
        print("Tablemode disabled")
    end
end

---Toggle alignment of the column
Tablemd.toggleAlign = function()
    local cursor_location = vim.api.nvim_win_get_cursor(0)
    -- Get the range of lines to format
    local start_line, end_line = H.get_table_range(cursor_location[1])
    -- Get the current column index
    local current_col = H.get_current_column_index()

    local col_defs = H.get_column_defs(start_line, end_line)
    local col = col_defs[current_col]
    local align = col["align"]
    if align == "left" then
        Tablemd.alignColumn("center")
    elseif align == "center" then
        Tablemd.alignColumn("right")
    elseif align == "right" then
        Tablemd.alignColumn("left")
    end
end


-- HELPER FUNCTIONS

---Pad string
---@param input string The string to pad.
---@param len number The expected length of the return value.
---@return string # String padded with spaces.
H.pad_string = function(input, len, alignment)
    -- Treat alignment as an optional paramenter with a default value
    alignment = alignment or 'left'

    local space_count = len - string.len(input);

    -- default the spacing to a left justification
    local left_spaces = 0
    local right_spaces = space_count

    -- if the alignment is 'right' then put all the space on the left side of the string.
    if alignment == 'right' then
        left_spaces = space_count
        right_spaces = 0
    end

    -- If the alignment is 'center', split the space between the left and right.
    -- For uneven splits, put the extra space on the right side of the string.
    if alignment == 'center' then
        if space_count > 0 then
            left_spaces = math.floor(space_count / 2)
            right_spaces = space_count - left_spaces
        end
    end

    input = string.rep(" ", left_spaces) .. input .. string.rep(" ", right_spaces)

    return input
end

---Split string
---@param input string The string to split.
---@param sep string The separator string.
---@return table # Table containing the split pieces
H.split_string = function(input, sep)
    if sep == nil then
        sep = "%s"
    end

    local t = {}
    for str in string.gmatch(input, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

---Trim spaces from beginning and end of string
---@param s string The string to trim.
---@return (string, number) # The trimmed string and number of whitespace in beginning
H.trim_string = function(s)
    local count = 0
    for c in s:gmatch(".") do
        if c == " " then
            count = count + 1
        else
            goto continue
        end
    end
    ::continue::
    return s:match("^%s*(.-)%s*$"), count
end

---Returns a table with the max column widths and alignment information.
---@param s number The first line of the table
---@param e number The last line of the table
---@return table # Table with information for each column
H.get_column_defs = function(s, e)
    -- look for alignment clues on the second line
    -- local second_line = s + 1
    local defs = {}

    for i = s, e do
        -- Read the line from the buffer
        -- local line = vim.api.nvim_buf_get_lines(0, i-1, i, false)[1]
        local line = H.trim_string(vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1])

        -- Split the line by the pipe symbol
        local t = H.split_string(line, "|")

        -- Pre-calculate this to save time
        local is_sep = H.is_separator(t)

        -- For each column
        for k, v in ipairs(t) do
            local trimmed_str = H.trim_string(v)
            -- Fix ä, ö not counting correctly. However, this does not provide
            -- full utf8 support.
            local _, str_len = string.gsub(trimmed_str, "[^\128-\193]", "")
            local alignment = nil

            -- look for alignment indicators
            if string.match(trimmed_str, "^-+:$") then
                alignment = 'right'
            elseif string.match(trimmed_str, "^:[-]+:$") then
                alignment = 'center'
            elseif string.match(trimmed_str, "^:-+$") or string.match(trimmed_str, "^-+$") then
                alignment = 'left'
            else
                alignment = Tablemd.config.defaultAlign
            end

            -- if the sub table doesn't already exist, then add it
            if defs[k] == nil then
                table.insert(defs, k, { length = str_len, align = alignment })
            else
                -- update the object if the length is greater
                -- Don't update if this row is separator, because separator row
                -- length should not affect it.
                if str_len > defs[k]["length"] and not is_sep then
                    defs[k]["length"] = str_len
                end
                -- if we haven't already set the alignment
                if defs[k]["align"] == nil then
                    defs[k]["align"] = alignment
                end
            end
        end
    end

    return defs
end

---Determines which column the cursor is currently in.
---@return number # The column index. This is Lua, so it is 1 based.
H.get_current_column_index = function()
    local cursor_location = vim.api.nvim_win_get_cursor(0)
    local line = H.trim_string(vim.api.nvim_buf_get_lines(0, cursor_location[1] - 1, cursor_location[1], false)[1])
    -- print(line)
    line = string.sub(line, 1, cursor_location[2] - 1)
    -- print(line)

    local count = 0
    for i in line:gmatch(Tablemd.config.separatorColumn) do
        count = count + 1
    end
    -- print(count)

    return count
end

---Returns the formatted line
---@param line string The line to be formatted
---@param col_defs table Table with metadata about each column
---@param count number Number of whitespace in beginning
---@return string # The formatted replacement line
H.get_formatted_line = function(line, col_defs, count)
    local t = H.split_string(line, "|")
    local build_str = "| "

    if H.is_separator(t) then
        build_str = "|"
        for _, v in ipairs(col_defs) do
            build_str = build_str .. H.get_separator_cell(v["length"] + 2, v["align"]) .. Tablemd.config.separatorColumn
        end
        build_str = build_str:sub(1, -2)
        build_str = build_str .. "|"
    else
        for k, v in ipairs(col_defs) do
            local col_width = v["length"]
            local col_align = v["align"]
            local str = t[k] and t[k] or ""
            local padded_str = H.pad_string(H.trim_string(str), col_width, col_align)
            build_str = build_str .. padded_str .. " | "
        end
        -- Trim off beginning or trailing spaces.
        build_str = string.gsub(build_str, '^%s*(.-)%s*$', '%1')
    end

    return H.add_indent(build_str, count)
end

H.replace_last = function(line)
    return line:sub(1, -2) .. "|"
end

---Add indentation in the beginning
---@param line string Line to be added
---@param count number Amount of indentation
---@return string # Modified string
H.add_indent = function(line, count)
    for _ = 1, count do
        line = " " .. line
    end
    return line
end

--- Check if given line is separator line
---@param t table Table containing split pieces form split_string
---@return boolean
H.is_separator = function(t)
    if next(t) == nil then
        return true
    else
        for _, v in ipairs(t) do
            for c in v:gmatch(".") do
                if c ~= Tablemd.config.separator and c ~= Tablemd.config.separatorColumn and c ~= ":" then
                    return false
                end
            end
        end
    end
    return true
end

---Returns string of separators for one cell.
---@param width number
---@alias align
---| '"left"'
---| '"right"'
---| '"center"'
---@return string
H.get_separator_cell = function(width, align)
    local res = ""
    for _ = 1, width do
        res = res .. Tablemd.config.separator
    end

    if align == "right" then
        res = res:sub(1, -2) .. ":"
    elseif align == "center" then
        res = ":" .. res:sub(1, -2):sub(2, -1) .. ":"
    end
    return res
end

---Find the first line and last line of the table.
---@param current_line_number number current_line_number The line number that the cursor is currently on.
---@return (number, number) The start line and end line for the table.
H.get_table_range = function(current_line_number)
    local start_line
    local end_line
    local current_line = nil
    local buf_line_count = vim.api.nvim_buf_line_count(0)

    -- Go Up
    start_line = current_line_number -- - 1

    repeat
        current_line = vim.api.nvim_buf_get_lines(0, start_line - 1, start_line, false)[1]
        start_line = start_line - 1
    until H.trim_string(current_line):sub(1, 1) ~= "|" or start_line == 0

    start_line = start_line + 2

    -- Go down
    end_line = current_line_number --+ 1
    current_line = vim.api.nvim_buf_get_lines(0, end_line - 1, end_line, false)[1]

    while current_line ~= nil and H.trim_string(current_line):sub(1, 1) == "|" and end_line <= buf_line_count do
        end_line = end_line + 1
        current_line = vim.api.nvim_buf_get_lines(0, end_line - 1, end_line, false)[1]
    end

    end_line = end_line - 1

    -- Return start and end line numbers
    return start_line, end_line
end

---Set default keymaps
H.setKeyMap = function()
    vim.api.nvim_set_keymap("n", "<Leader>ef", ':lua require("tablemd").formatTable()<cr>', { noremap = true, desc = "Format table" })
    vim.api.nvim_set_keymap("n", "<Leader>eC", ':lua require("tablemd").insertColumn(false)<cr>', { noremap = true, desc = "Insert column before" })
    vim.api.nvim_set_keymap("n", "<Leader>ec", ':lua require("tablemd").insertColumn(true)<cr>', { noremap = true, desc = "Insert column after" })
    vim.api.nvim_set_keymap("n", "<Leader>ed", ':lua require("tablemd").deleteColumn()<cr>', { noremap = true, desc = "Delete column" })
    vim.api.nvim_set_keymap("n", "<Leader>er", ':lua require("tablemd").insertRow(false)<cr>', { noremap = true, desc = "Insert row before" })
    vim.api.nvim_set_keymap("n", "<Leader>eR", ':lua require("tablemd").insertRow(true)<cr>', { noremap = true, desc = "Insert row after" })
    vim.api.nvim_set_keymap("n", "<Leader>ek", ':lua require("tablemd").alignColumn("center")<cr>', { noremap = true, desc = "Toggle column align" })
    vim.api.nvim_set_keymap("n", "<Leader>em", ':lua require("tablemd").toggleMode()<cr>', { noremap = true, desc = "Toggle tablemode" })
    vim.api.nvim_set_keymap("n", "<Leader>et", ':lua require("tablemd").toggleAlign()<cr>', { noremap = true, desc = "Toggle column alignment" })
end

H.default_config = vim.deepcopy(Tablemd.config)

---Combine default and user-provided configs
---@param config table user-provided config
---@return table # Combined config
H.setup_config = function(config)
    -- General idea: if some table elements are not present in user-supplied
    -- `config`, take them from default config
    vim.validate({ config = { config, 'table', true } })
    config = vim.tbl_deep_extend('force', vim.deepcopy(H.default_config), config or {})

    vim.validate({
        defaultKeymap = { config.defaultKeymap, 'boolean' },
        separator = { config.separator, "string" },
        separatorColumn = { config.separatorColumn, "string" },
        defaultAlign = { config.defaultAlign, "string" }
    })

    return config
end

-- Export module
return Tablemd
