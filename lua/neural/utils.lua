-- Shared utility functions.

local Utils = {}

-- Get the current file type.
--- @return string
function Utils.get_current_filetype()
    local buffer = vim.api.nvim_get_current_buf()

    return vim.api.nvim_buf_get_option(buffer, 'filetype')
end

-- Get the visual selection range location.
-- @return start_row, start_col, end_row, end_col
function Utils.get_visual_selection()
    local buffer = vim.api.nvim_get_current_buf()

    -- Get the mark start and end position.
    local start_pos = vim.api.nvim_buf_get_mark(buffer, "<")
    local end_pos = vim.api.nvim_buf_get_mark(buffer, ">")

    local start_row = start_pos[1] - 1
    local end_row = end_pos[1] - 1

    -- Return column zero if the line is empty.
    local start_col = math.min(
        start_pos[2],
        vim.api.nvim_buf_get_lines(buffer, start_row, start_row + 1, true)[1]:len()
    )
    local end_col = math.min(
        end_pos[2] + 1,
        vim.api.nvim_buf_get_lines(buffer, end_row, end_row+1, true)[1]:len()
    )

    return start_row, start_col, end_row, end_col
end

-- Get the cursor position location.
-- @return start_row, start_col, end_row, end_col
function Utils.get_cursor_position()
    local buffer = vim.api.nvim_get_current_buf()
    local start_pos = vim.api.nvim_win_get_cursor(0)

    local start_row = start_pos[1] - 1
    local end_row = start_row

    -- Return column zero if the line is empty.
    local start_col = math.min(
        start_pos[2] + 1,
        vim.api.nvim_buf_get_lines(buffer, start_row, start_row + 1, true)[1]:len()
    )
    local end_col = math.min(
        start_col,
        vim.api.nvim_buf_get_lines(buffer, end_row, end_row+1, true)[1]:len()
    )

    return start_row, start_col, end_row, end_col
end

-- Create a Highlight with the given options.
-- @param group The highlight to create.
-- @param options Highlight options.
function Utils.highlight(group, options)
    local c = 'highlight ' .. group
    for k, v in pairs(options) do
        c = c .. " " .. k .. "=" .. v
    end
    vim.cmd(c)
end

-- Create a autocmd group with the given options.
-- @param name Autocmd group name.
-- @param autocmds Table of commands.
function Utils.augroup(name, autocmds)
    local cmd = vim.api.nvim_command
    cmd('augroup ' .. name)
    cmd('autocmd!')

    for _, autocmd in ipairs(autocmds) do
        cmd('autocmd ' .. table.concat(autocmd, ' '))
    end
    cmd('augroup END')
end

return Utils
