-- Make requests with curl and pipe data to buffer.

local Request = {}
local uv = vim.loop

-- Capture the text content of OpenAI JSON data response chunks.
local content_expr = ',*{"text":%s*"([^,]+[^%]"]*[^"]*)",'
-- Capture the error message of an OpenAI JSON error response.
local error_message_expr = '"message": "(.[^"]*)'
-- Wrap content from long text responses.
-- TODO: Fix this, use in syncWrite and make it configurable.
local wrap_len = 80

function Request.post(endpoint, body, api_key, buffer_info, on_complete)
    local cmd = 'curl'
    local cmd_args = {
        "-X", "POST", "--silent", "--show-error",
        "-L", endpoint,
        "-H", "Content-Type: application/json",
        "-H", "Authorization: Bearer " .. api_key,
        "-d", vim.json.encode(body)
    }

    -- Create pipes to read output from curl process.
    local stdout = uv.new_pipe()
    local stderr = uv.new_pipe()
    local handle, err
    local options = {
        args = cmd_args,
        stdio = {nil, stdout, stderr},
    }

    -- Buffer info
    local buffer = vim.api.nvim_get_current_buf()
    local start_row = buffer_info.start_row
    local end_row = buffer_info.end_row
    local start_col = buffer_info.start_col
    local end_col = buffer_info.end_col

    -- Stream info
    local current_line_len = 0
    local content_start = false
    local newline_chunk = false

    -- Write new line to the buffer.
    local function buffer_new_line()
        vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, {'', ''})
        start_col = 0
        end_col = 0
        start_row = start_row + 1
        end_row = end_row + 1
        current_line_len = 0
    end

    -- Async write stream chunks to buffer.
    --- @param data string Output stream data chunks from pipe.
    local function asyncWrite(data)
        for data_chunk in string.gmatch(data, content_expr) do
            -- Reset newline chunk.
            newline_chunk = false
            -- Parse escaped quotes.
            data_chunk = string.gsub(data_chunk, '\\"', '\"')
            data_chunk = string.gsub(data_chunk, "\\'", "'")

            -- Add new lines from the output stream chunk.
            for _ in string.gmatch(data_chunk, '\\n') do
                newline_chunk = true
                -- Ignore adding new lines before any content.
                if content_start then
                    buffer_new_line()
                end
            end

            -- Write text chunk to buffer.
            if not newline_chunk then
                content_start = true

                -- Append output chunk from stream to buffer.
                vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, {data_chunk})

                local len = #data_chunk
                current_line_len = current_line_len + len
                start_col = start_col + len
                end_col = end_col + len

                -- Wrap token chunk to new line after exceeding limit.
                if current_line_len >= wrap_len then
                    buffer_new_line()
                end
            end
        end
    end

    -- Sync write all text content from the request.
    -- Required for endpoints that don't support streaming like edits.
    --- @param data string Output data chunks.
    local function syncWrite(data)
        local response = vim.json.decode(data)

        -- Handle API errors.
        if response.error then
            vim.api.nvim_err_writeln('[Neural Error]: ' .. response.error.message)
            on_complete()
        end

        -- Add into newlines from response with newline characters.
        local lines = {}
        for line in string.gmatch(response.choices[1].text, '[^\n]+') do
            table.insert(lines, line)
        end

        vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, lines)
    end

    -- Handle standard output from pipe.
    --- @param data string Output chunk.
    local function on_stdout_read (_, data)
        if data then
            if body.stream then
                vim.schedule(function ()
                    -- Handle API errors.
                    for e in string.gmatch(data, error_message_expr) do
                        vim.api.nvim_err_writeln('[Neural Error] -> ' .. e)
                    end
                    -- Async write when we read data from the stdout pipe.
                    asyncWrite(data)
                end)
            else
                vim.schedule(function ()
                    -- Build to sync write the data to buffer.
                    syncWrite(data)
                end)
            end
        end
    end

    local stderr_chunks = {}
    -- Handle error output from pipe.
    --- @param data string Output chunk.
    local function on_stderr_read (_, data)
        if data then
            table.insert(stderr_chunks, data)
        end
    end

    -- Spawn curl process.
    handle, err = uv.spawn(cmd, options, function (code)
        stdout:close()
        stderr:close()
        handle:close()

        vim.schedule(function ()
            if code ~= 0 then
                vim.api.nvim_err_writeln('[Neural Error] -> ' .. string.gsub(table.concat(stderr_chunks, ''), '\n', ''))
            else
                on_complete()
            end
        end)
    end)

    if not handle then
        vim.api.nvim_err_writeln('[Neural Handle Error] -> ' .. cmd .. ' : ' ..  err)
        on_complete()
    else
        stdout:read_start(on_stdout_read)
        stderr:read_start(on_stderr_read)
    end
end

return Request
