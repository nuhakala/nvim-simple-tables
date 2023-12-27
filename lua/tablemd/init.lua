-- Setup
local Tablemd = {}
local H = {} -- for helper functions
local modeFlag = false

-- Default config
Tablemd.config = {
    defaultKeymap = true,
    separator = "-",
    separatorColumn = "+",
}

Tablemd.setup = function(cfg)
    local config = H.setup_config(cfg)
    Tablemd.config = config

    if config.defaultKeymap then
        H.setKeyMap()
    end
end


-- TABLEMODE FUNCTIONS
--[[
Formats the markdown table so cells in a column are a uniform width.
]]
function Tablemd.formatTable()
    local start_line = nil
    local end_line = nil
    local cur_line = nil
    local cursor_location = vim.fn.line('v')

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location)

    -- Get column definitions
    local col_defs = H.get_column_defs(start_line, end_line)

    -- Format each line
    for i = start_line, end_line do -- The range includes both ends.
        local line = H.trim_string(vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1])
        local formatted_line = H.get_formatted_line(line, col_defs)

        -- replace the line with the formatted line in the buffer
        vim.api.nvim_buf_set_lines(0, i - 1, i, false, { formatted_line })
    end
end

--[[--
Aligns the column. Possible values for alignment are "left", "right", and "center".
]]
function Tablemd.alignColumn(alignment)
    -- Don't do anything if the alignment value isn't one of the predefined values.
    if not (alignment == "left" or alignment == "right" or alignment == "center") then
        return
    end

    local start_line = nil
    local end_line = nil
    local cursor_location = vim.api.nvim_win_get_cursor(0)

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location[1])

    -- Get column definitions
    local col_defs = H.get_column_defs(start_line, end_line)

    -- Get the current column index
    local current_col = H.get_current_column_index()

    -- Get the second line
    local line = H.trim_string(vim.api.nvim_buf_get_lines(0, start_line, start_line + 1, false)[1])
    local t = H.split_string(line, "|")

    -- Rebuild the line
    local new_line = "|"
    local table_len = 0
    for _ in pairs(t) do table_len = table_len + 1 end

    for i = 1, table_len do
        if i ~= current_col then
            new_line = new_line .. H.trim_string(t[i]) .. " | "
        else
            if alignment == "left" then
                new_line = new_line .. "--- | "
            end

            if alignment == "right" then
                new_line = new_line .. "---: | "
            end

            if alignment == "center" then
                new_line = new_line .. ":---: | "
            end
        end
    end

    -- replace the line with the formatted line in the buffer
    vim.api.nvim_buf_set_lines(0, start_line, start_line + 1, false, { new_line })

    Tablemd.formatTable()
end

--[[--
Deletes the current column from the table.
]]
function Tablemd.deleteColumn()
    local start_line = nil
    local end_line = nil
    local cursor_location = vim.api.nvim_win_get_cursor(0)

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location[1])

    -- Get column definitions
    local col_defs = H.get_column_defs(start_line, end_line)

    -- Get the current column index
    local current_col = H.get_current_column_index()

    -- Format each line
    for i = start_line, end_line do
        local line = H.trim_string(vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1])
        local t = H.split_string(line, "|")

        local new_line = "|"
        local table_len = 0
        for _ in pairs(t) do table_len = table_len + 1 end

        for j = 1, table_len do
            if j ~= current_col then
                new_line = new_line .. H.trim_string(t[j]) .. " | "
            end
        end

        -- replave the line with the formatted line in the buffer
        vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new_line })
    end

    Tablemd.formatTable()
end

--[[--
Formats each line in the table with a new column.
@tparam bool before If true, the column will be inserted on the left side of the current column
]]
function Tablemd.insertColumn(before)
    local start_line = nil
    local end_line = nil
    local cursor_location = vim.api.nvim_win_get_cursor(0)

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location[1])

    -- Get column definitions
    local col_defs = H.get_column_defs(start_line, end_line)

    -- Get the current column index
    local current_col = H.get_current_column_index()

    -- Format each line
    for i = start_line, end_line do -- The range includes both ends.
        local line = H.trim_string(vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1])

        local t = H.split_string(line, "|")

        local new_line = "|"
        local table_len = 0
        for _ in pairs(t) do table_len = table_len + 1 end

        -- This code gets "duplicated" in the next loop, so it is encapsulated in a function here.
        local insertBlankColumn = function(new_line, start_line, i)
            if i == start_line + 1 then
                new_line = new_line .. "--- | "
            else
                new_line = new_line .. "    | "
            end

            return new_line
        end

        -- Loop through every column in the table line.
        for j = 1, table_len do
            if before == true and j == current_col then
                new_line = insertBlankColumn(new_line, start_line, i)
            end

            new_line = new_line .. H.trim_string(t[j]) .. " | "

            if before == false and j == current_col then
                new_line = insertBlankColumn(new_line, start_line, i)
            end
        end

        -- replace the line with the formatted line in the buffer
        vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new_line })
    end

    Tablemd.formatTable()
end

--[[--
Inserts a new row into the table
@tparam bool before If true, the row will be inserted above the current row
]]
function Tablemd.insertRow(before)
    -- Get the current location of the cursor
    local cursor_location = vim.api.nvim_win_get_cursor(0)
    print(vim.inspect(cursor_location))
    local line_num = cursor_location[1]

    local col_defs = H.get_column_defs(line_num, line_num)
    local new_line = "|"

    for k, v in ipairs(col_defs) do
        new_line = new_line .. "   |"
    end

    -- If 'before' is true, then insert the row above the current row.
    if before then
        line_num = line_num - 1
    end

    -- To insert a line, pass in the same line number for both start and end.
    vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { new_line })

    -- Move the cursor to the newly created line
    vim.api.nvim_win_set_cursor(0, { line_num + 1, cursor_location[2] })

    Tablemd.formatTable()
end

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



-- HELPER FUNCTIONS
--[[--
Pad string
@tparam string input The string to pad.
@tparam int len The expected length of the return value.
@treturn string String padded with spaces.
]]
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

--[[--
Split string
@tparam string input The string to split.
@tparam string sep The separator string.
@return table Table containing the split pieces
]]
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

--[[--
Trim spaces from beginning and end of string
@tparam string s The string to trim.
@treturn string The trimmed string
]]
H.trim_string = function(s)
    return s:match("^%s*(.-)%s*$")
end

--[[--
Returns a table with the max column widths and alignment information.
@tparam int s The first line of the table
@tparam int e The last line of the table
@treturn table Table with information for each column
]]
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

        -- Separator row should not affect max length
        if H.is_separator(t) then
            goto continue
        end

        -- For each column
        for k, v in ipairs(t) do
            local trimmed_str = H.trim_string(v)
            print(trimmed_str)
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
                alignment = nil
            end

            -- if the sub table doesn't already exist, then add it
            if defs[k] == nil then
                table.insert(defs, k, { length = str_len, align = alignment })
            else
                -- update the object if the length is greater
                if str_len > defs[k]["length"] then
                    defs[k]["length"] = str_len
                end
                -- if we haven't already set the alignment
                if defs[k]["align"] == nil then
                    defs[k]["align"] = alignment
                end
            end
        end
        ::continue::
    end

    return defs
end

--[[--
Determines which column the cursor is currently in.
@treturn int The column index. This is Lua, so it is 1 based.
]]
H.get_current_column_index = function()
    local cursor_location = vim.api.nvim_win_get_cursor(0)
    local line = H.trim_string(vim.api.nvim_buf_get_lines(0, cursor_location[1] - 1, cursor_location[1], false)[1])
    line = string.sub(line, 1, cursor_location[2] - 1)

    local count = 0
    for i in line:gmatch("|") do
        count = count + 1
    end

    return count
end

--[[--
Returns the formatted line
@tparam string line The line to be formatted
@tparam table col_defs Table with metadata about each column
@treturn string The formatted replacement line
]]
H.get_formatted_line = function(line, col_defs)
    local t = H.split_string(line, "|")
    local build_str = "| "
    vim.print(t)

    if H.is_separator(t) then
        build_str = "|"
        for _, v in ipairs(col_defs) do
            build_str = build_str .. H.get_separator_cell(v["length"] + 2) .. Tablemd.config.separatorColumn
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

    return build_str
end

-- t = table containing split pieces from split_string
H.is_separator = function(t)
    if next(t) == nil then
        return true
    else
        for _, v in ipairs(t) do
            for c in v:gmatch(".") do
                if c ~= Tablemd.config.separator and c ~= Tablemd.config.separatorColumn then
                    return false
                end
            end
        end
    end
    return true
end

H.get_separator_cell = function(width)
    local res = ""
    for _ = 1, width do
        res = res .. Tablemd.config.separator
    end
    return res
end

--[[--
Find the first line and last line of the table.
@tparam int current_line_number The line number that the cursor is currently on.
@treturn int, int The start line and end line for the table.
]]
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
    until current_line == "" or start_line == 0

    start_line = start_line + 2

    -- Go down
    end_line = current_line_number --+ 1
    current_line = vim.api.nvim_buf_get_lines(0, end_line - 1, end_line, false)[1]

    while current_line ~= "" and current_line ~= nil and end_line <= buf_line_count do
        end_line = end_line + 1
        current_line = vim.api.nvim_buf_get_lines(0, end_line - 1, end_line, false)[1]
    end

    end_line = end_line - 1

    -- Return start and end line numbers
    return start_line, end_line
end

H.setKeyMap = function()
    vim.api.nvim_set_keymap("n", "<Leader>ef", ':lua require("tablemd").format()<cr>', { noremap = true, desc = "Format table" })
    vim.api.nvim_set_keymap("n", "<Leader>eC", ':lua require("tablemd").insertColumn(false)<cr>', { noremap = true, desc = "Insert column before" })
    vim.api.nvim_set_keymap("n", "<Leader>ec", ':lua require("tablemd").insertColumn(true)<cr>', { noremap = true, desc = "Insert column after" })
    vim.api.nvim_set_keymap("n", "<Leader>ed", ':lua require("tablemd").deleteColumn()<cr>', { noremap = true, desc = "Delete column" })
    vim.api.nvim_set_keymap("n", "<Leader>er", ':lua require("tablemd").insertRow(false)<cr>', { noremap = true, desc = "Insert row before" })
    vim.api.nvim_set_keymap("n", "<Leader>eR", ':lua require("tablemd").insertRow(true)<cr>', { noremap = true, desc = "Insert row after" })
    vim.api.nvim_set_keymap("n", "<Leader>ek", ':lua require("tablemd").alignColumn("center")<cr>', { noremap = true, desc = "Toggle column align" })
    vim.api.nvim_set_keymap("n", "<Leader>em", ':lua require("tablemd").toggleMode()<cr>', { noremap = true, desc = "Toggle tablemode" })
end

H.default_config = vim.deepcopy(Tablemd.config)

H.setup_config = function(config)
    -- General idea: if some table elements are not present in user-supplied
    -- `config`, take them from default config
    vim.validate({ config = { config, 'table', true } })
    config = vim.tbl_deep_extend('force', vim.deepcopy(H.default_config), config or {})

    vim.validate({
        defaultKeymap = { config.defaultKeymap, 'boolean' },
    })

    return config
end

-- H.apply_config = function(config)
--   Tablemd.config = config
-- end

-- Export module
return Tablemd
