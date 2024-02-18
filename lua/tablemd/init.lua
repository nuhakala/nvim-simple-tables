-- Setup
local Tablemd = {}
local H = {} -- for helper functions
local modeFlag = false
local prefix = ""

-- Default config
Tablemd.config = {
    default_keymap = true,
    separator = "-",
    separator_column = "|",
    default_align = "left",
    mode_events = { "InsertLeave" }
}

Tablemd.setup = function(cfg)
    local config = H.setup_config(cfg)
    Tablemd.config = config

    if config.default_keymap then
        H.setKeyMap()
    end
end


-- TABLEMODE FUNCTIONS
-- Note: we need to set prefix in every function call so that the functions will
-- add correct amount indentation or correct prefix to table lines.
-- Prefix is module-wide variable, because I did not want to have it as parameter
-- in every function call.

---Formats the markdown table so cells in a column are a uniform width.
function Tablemd.formatTable()
    H.set_line_prefix()

    local start_line = nil
    local end_line = nil
    local cursor_location = vim.fn.line('v')

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location)

    -- Get column definitions
    local col_defs = H.get_column_defs(start_line, end_line)

    -- Format each line
    for i = start_line, end_line do -- The range includes both ends.
        local line = H.trim_string(H.get_table_line(i - 1, i))
        local formatted_line = H.get_formatted_line(line, col_defs)

        -- replace the line with the formatted line in the buffer
        vim.api.nvim_buf_set_lines(0, i - 1, i, false, { formatted_line })
    end
end

---Aligns the column. Possible values for alignment are "left", "right", and "center".
function Tablemd.alignColumn(alignment)
    H.set_line_prefix()

    -- Don't do anything if the alignment value isn't one of the predefined values.
    if not (alignment == "left" or alignment == "right" or alignment == "center") then
        return
    end

    local cursor_location = vim.api.nvim_win_get_cursor(0)

    -- Get the range of lines to format
    local start_line, end_line = H.get_table_range(cursor_location[1])

    -- Get the current column index
    local current_col = H.get_current_column_index()

    -- Get the second line
    local line = H.trim_string(H.get_table_line(start_line, start_line + 1))
    local t = H.split_string(line, "|")
    local is_sep = H.is_separator(line)

    -- Rebuild the line
    local new_line = "|"
    local align_cell = ""
    if alignment == "left" then
        align_cell = H.get_separator_cell(3, "left") .. "|"
    elseif alignment == "right" then
        align_cell =  H.get_separator_cell(3, "right") .. "|"
    elseif alignment == "center" then
        align_cell = H.get_separator_cell(3, "center") .. "|"
    end

    for i = 1, #t do
        -- If outside of the column we want to align
        if i ~= current_col then
            -- If second line was not a separator, then we are adding a new row to the table.
            if not is_sep then
                new_line = new_line .. H.get_separator_cell(3, Tablemd.config.default_align) .. "|"
            else
                -- If the row is not new, then add the old content
                new_line = new_line .. H.trim_string(t[i]) .. "|"
            end
        else
            -- If we are at the column we want to align, then add align-cell content
            -- We will format it later.
            new_line = new_line .. align_cell
        end
    end

    -- Check if separator line exists, if not, then add new separator line to
    -- second row.
    local sep_row = H.find_sep_line(start_line, end_line)
    if (sep_row) then
        vim.api.nvim_buf_set_lines(0, sep_row - 1, sep_row, false, { prefix .. new_line })
    else
        vim.api.nvim_buf_set_lines(0, start_line, start_line, false, { prefix .. new_line })
    end

    Tablemd.formatTable()
end

---Deletes the current column from the table.
function Tablemd.deleteColumn()
    H.set_line_prefix()
    local start_line = nil
    local end_line = nil
    local cursor_location = vim.api.nvim_win_get_cursor(0)

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location[1])

    -- Get the current column index
    local current_col = H.get_current_column_index()

    -- Format each line
    for i = start_line, end_line do
        local line = H.trim_string(H.get_table_line(i - 1, i))
        local t = H.split_string(line, "|")

        local new_line = "|"

        -- If line is separator, we can just replace the row with this, because
        -- formatTable will format it nicely.
        if H.is_separator(line) then
            new_line = "||"
        else
            local table_len = 0
            for _ in pairs(t) do table_len = table_len + 1 end

            for j = 1, table_len do
                if j ~= current_col then
                    new_line = new_line .. H.trim_string(t[j]) .. " | "
                end
            end
        end

        -- replace the line with the formatted line in the buffer
        vim.api.nvim_buf_set_lines(0, i - 1, i, false, { prefix .. new_line })
    end

    Tablemd.formatTable()
end

---Formats each line in the table with a new column.
---@param before boolean If true, the column will be inserted on the left side of the current column
function Tablemd.insertColumn(before)
    H.set_line_prefix()
    local start_line = nil
    local end_line = nil
    local cursor_location = vim.api.nvim_win_get_cursor(0)

    -- Get the range of lines to format
    start_line, end_line = H.get_table_range(cursor_location[1])

    -- Get the current column index
    local current_col = H.get_current_column_index()

    -- Format each line
    for i = start_line, end_line do -- The range includes both ends.
        local line = H.trim_string(H.get_table_line(i - 1, i))

        local t = H.split_string(line, "|")

        local new_line = "|"
        if H.is_separator(line) then
            new_line = "||"
        else
            local table_len = 0
            for _ in pairs(t) do table_len = table_len + 1 end

            -- Loop through every column in the table line.
            for j = 1, table_len do
                if before == true and j == current_col then
                    new_line = new_line .. "     | "
                end

                new_line = new_line .. H.trim_string(t[j]) .. " | "

                if before == false and j == current_col then
                    new_line = new_line .. "     | "
                end
            end
        end

        -- replace the line with the formatted line in the buffer
        vim.api.nvim_buf_set_lines(0, i - 1, i, false, { prefix .. new_line })
    end

    Tablemd.formatTable()
end

---Inserts a new row into the table
---@param before boolean If true, the row will be inserted above the current row
function Tablemd.insertRow(before)
    H.set_line_prefix()

    -- Get the current location of the cursor
    local cursor_location = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_location[1]

    local col_defs = H.get_column_defs(line_num, line_num)
    local new_line = "|"

    for _, _ in ipairs(col_defs) do
        new_line = new_line .. "   | "
    end

    -- If 'before' is true, then insert the row above the current row.
    if before then
        line_num = line_num - 1
    end

    -- To insert a line, pass in the same line number for both start and end.
    vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { prefix .. new_line })

    -- Move the cursor to the newly created line
    vim.api.nvim_win_set_cursor(0, { line_num + 1, cursor_location[2] })

    Tablemd.formatTable()
end

---Toggle tablemode
Tablemd.toggleMode = function()
    if not modeFlag then
        local auGroup = vim.api.nvim_create_augroup('Tablemode', { clear = false })
        vim.api.nvim_create_autocmd(Tablemd.config.mode_events, {
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
    H.set_line_prefix()

    local cursor_location = vim.api.nvim_win_get_cursor(0)
    -- Get the range of lines to format
    local start_line, end_line = H.get_table_range(cursor_location[1])
    -- Get the current column index
    local current_col = H.get_current_column_index()

    local col_defs = H.get_column_defs(start_line, end_line)
    local col = col_defs[current_col]
    local align = col["align"] and col["align"] or Tablemd.config.default_align
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
    alignment = alignment or Tablemd.config.default_align

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

    -- Add space to empty columns to fix formatting
    input = input:gsub(sep, sep.." ")
    input = H.trim_string(input)

    local t = {}
    for str in string.gmatch(input, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

---Trim spaces from beginning and end of string
---@param s string The string to trim.
---@return string # The trimmed string and number of whitespace in beginning
H.trim_string = function(s)
    s = s ~= nil and s or ""
    return s:match("^%s*(.-)%s*$")
end

---Returns a table with the max column widths and alignment information.
---@param s number The first line of the table
---@param e number The last line of the table
---@return table # Table with information for each column
H.get_column_defs = function(s, e)
    local defs = {}
    local sep = Tablemd.config.separator

    for i = s, e do
        -- Read the line from the buffer
        local line = H.trim_string(H.get_table_line(i - 1, i))
        local t = nil

        -- If line is separator line, then take custom separator into account
        local is_sep = H.is_separator(line)

        -- Get split-string table for the line
        if is_sep then
            t = H.split_string(line:sub(2, -2), Tablemd.config.separator_column)
        else
            t = H.split_string(line, "|")
        end

        -- For each column
        for k, v in ipairs(t) do
            local trimmed_str = H.trim_string(v)
            -- Fix ä, ö not counting correctly. However, this does not provide
            -- full utf8 support.
            local _, str_len = string.gsub(trimmed_str, "[^\128-\193]", "")
            -- Fix the length if it is separator
            if is_sep then str_len = 0 end
            local alignment = nil

            -- look for alignment indicators
            if string.match(trimmed_str, "^" .. sep .. "+:$") then
                alignment = 'right'
            elseif string.match(trimmed_str, "^:[" .. sep .. "]+:$") then
                alignment = 'center'
            elseif string.match(trimmed_str, "^:[" .. sep .. "]+$") or string.match(trimmed_str, "^[" .. sep .. "]+$") then
                alignment = 'left'
            else
                alignment = nil
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
    local line = H.trim_string(H.get_table_line(cursor_location[1] - 1, cursor_location[1]))

    -- Substitute separator columns if line is separator
    local is_sep = H.is_separator(line)
    if is_sep then
        line = string.gsub(line, Tablemd.config.separator_column, "|")
    end

    -- Remove line after cursor
    line = string.sub(line, 1, cursor_location[2])

    local count = 0
    for _ in line:gmatch("|") do
        count = count + 1
    end

    return count
end

---Returns the formatted line
---@param line string The line to be formatted
---@param col_defs table Table with metadata about each column
---@return string # The formatted replacement line
H.get_formatted_line = function(line, col_defs)
    local t = H.split_string(line, "|")
    local build_str = "| "

    -- If separator, then build separator line
    if H.is_separator(line) then
        build_str = "|"
        for _, v in ipairs(col_defs) do
            local align = v["align"] and v["align"] or Tablemd.config.default_align
            build_str = build_str .. H.get_separator_cell(v["length"] + 2, align) .. Tablemd.config.separator_column
        end
        build_str = build_str:sub(1, -2)
        build_str = build_str .. "|"
    else
        for k, v in ipairs(col_defs) do
            local col_width = v["length"]
            -- If no alignment is defined, use the default
            local col_align = v["align"] and v["align"] or Tablemd.config.default_align
            local padded_str = H.pad_string(H.trim_string(t[k]), col_width, col_align)
            build_str = build_str .. padded_str .. " | "
        end
        -- Trim off beginning or trailing spaces.
        build_str = string.gsub(build_str, '^%s*(.-)%s*$', '%1')
    end

    return prefix .. build_str
end

--- Check if given line is separator line
---@param t string The line to check
---@return boolean
H.is_separator = function(t)
    -- Check special case
    if t == "||" then
        return true
    end

    -- Check lines that are already formatted
    for c in t:sub(2, -2):gmatch(".") do
        if c ~= Tablemd.config.separator and c ~= Tablemd.config.separator_column and c ~= ":" then
            return false
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
        res = ":" .. res:sub(2, -2) .. ":"
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
    start_line = current_line_number

    current_line = H.get_table_line(start_line - 1, start_line)
    while H.trim_string(current_line):sub(1, 1) == "|" and start_line > 0 do
        start_line = start_line - 1
        current_line = H.get_table_line(start_line - 1, start_line)
    end
    start_line = start_line + 1

    -- Fix the wrong start line if we reached the start of buffer
    if (start_line < 1) then
        start_line = 1
    end

    -- Go down
    end_line = current_line_number
    current_line = H.get_table_line(end_line - 1, end_line)

    while current_line ~= nil and H.trim_string(current_line):sub(1, 1) == "|" and end_line <= buf_line_count do
        end_line = end_line + 1
        current_line = H.get_table_line(end_line - 1, end_line)
    end

    end_line = end_line - 1

    -- Return start and end line numbers
    return start_line, end_line
end

--- Finds separator row in table
---@param start_line number Start line of the table
---@param end_line number End line of the table
---@return number | nil Line number of the separator row or nil if not found
H.find_sep_line = function(start_line, end_line)
    for i = start_line, end_line do
        local current_line = H.get_table_line(i - 1, i)
        if H.is_separator(current_line) then
            return i
        end
    end
    return nil
end

--- Returns the prefix before table
H.set_line_prefix = function()
    prefix = ""
    local cl = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(0, cl - 1, cl, false)[1]
    for c in line:gmatch(".") do
        if c ~= "|" then
            prefix = prefix .. c
        else
            return
        end
    end
end

H.get_table_line = function(s, e)
    local current_line = vim.api.nvim_buf_get_lines(0, s, e, false)[1]
    if string.len(current_line) < string.len(prefix) then
        return ""
    end
    return current_line:sub(string.len(prefix), -1)
end

---Set default keymaps
H.setKeyMap = function()
    vim.api.nvim_set_keymap("n", "<Leader>ef", ':lua require("tablemd").formatTable()<cr>', { noremap = true, desc = "Format table" })
    vim.api.nvim_set_keymap("n", "<Leader>eC", ':lua require("tablemd").insertColumn(false)<cr>', { noremap = true, desc = "Insert column after" })
    vim.api.nvim_set_keymap("n", "<Leader>ec", ':lua require("tablemd").insertColumn(true)<cr>', { noremap = true, desc = "Insert column before" })
    vim.api.nvim_set_keymap("n", "<Leader>ed", ':lua require("tablemd").deleteColumn()<cr>', { noremap = true, desc = "Delete column" })
    vim.api.nvim_set_keymap("n", "<Leader>er", ':lua require("tablemd").insertRow(false)<cr>', { noremap = true, desc = "Insert row after" })
    vim.api.nvim_set_keymap("n", "<Leader>eR", ':lua require("tablemd").insertRow(true)<cr>', { noremap = true, desc = "Insert row before" })
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
        default_keymap = { config.default_keymap, 'boolean' },
        separator = { config.separator, "string" },
        separator_column = { config.separator_column, "string" },
        default_align = { config.default_align, "string" },
        mode_events = { config.mode_events, "table" },
    })

    return config
end

-- Export module
return Tablemd
