local Config = require('neural.config')
local OpenAI = require('neural.openai')
local Utils = require('neural.utils')
-- External dependencies
local UI = {}
local AnimatedSign = {}
local has_nui, _ = pcall(require, 'nui.input')
local has_significant, _ = pcall(require, 'significant')

if has_nui then
    UI = require('neural.ui')
end
if has_significant then
    AnimatedSign = require('significant')
end
----------------------------

local Neural = {}

-- TODO: Move these
local mark_id
local start_row, start_col, end_row, end_col
local context_selection = false

-- Define highlights
function NeuralSign()
    Utils.highlight('NeuralSign', {guifg = Config.options.ui.icon_color})
end
function NeuralLine()
    Utils.highlight('NeuralLine', {guibg = Config.options.ui.hl_color})
end
function NeuralPromptBorder()
    Utils.highlight('NeuralPromptBorder', {guifg = Config.options.ui.prompt_border_color})
end

function Neural.setup(options)
    if type(options) == "table" then
        Config.setup(options)
    else
        print('Neural: config options must be a table')
        return
    end

    OpenAI.API_KEY = Config.options.open_ai.api_key

    -- Highlights
    Utils.augroup('Neural', {
        {'ColorScheme', '*', 'lua NeuralSign()'},
        {'ColorScheme', '*', 'lua NeuralLine()'},
        {'ColorScheme', '*', 'lua NeuralPromptBorder()'}
    })

    -- Commands
    vim.api.nvim_create_user_command('NeuralCode', function (args)
        Neural.query(args.args, 'code', args) -- Code complete
    end, {range = true, nargs = '*'})
    vim.api.nvim_create_user_command('NeuralText', function (args)
        Neural.query(args.args, 'text', args)
    end, {range = true, nargs = '*'})
    vim.api.nvim_create_user_command('NeuralPrompt', function (args)
        Neural.prompt(args)
    end, {range = true, nargs = '*'})

    -- Keybindings
    vim.api.nvim_set_keymap('n', Config.options.mappings.prompt, ':NeuralPrompt <CR>', { noremap = true })
    vim.api.nvim_set_keymap('i', Config.options.mappings.prompt, ':NeuralPrompt <CR>', { noremap = true })
    vim.api.nvim_set_keymap('v', Config.options.mappings.prompt, ':NeuralPrompt <CR>', { noremap = true })
    vim.api.nvim_set_keymap('n', Config.options.mappings.swift, '<cmd>NeuralCode <cr>', { noremap = true })
    vim.api.nvim_set_keymap('i', Config.options.mappings.swift, '<cmd>NeuralCode <cr>', { noremap = true })
    vim.api.nvim_set_keymap('v', Config.options.mappings.swift, '<cmd>NeuralCode <cr>', { noremap = true })
end

function Neural.get_buffer_info(args)
    context_selection = args.range > 0

    if context_selection then
        start_row, start_col, end_row, end_col = Utils.get_visual_selection()
    else
        start_row, start_col, end_row, end_col = Utils.get_cursor_position()
    end
end

function Neural.prompt(args)
    Neural.get_buffer_info(args)

    if has_nui and Config.options.ui.use_prompt then
        UI.prompt(' Neural ', function(value) Neural.query(value, 'text') end)
    else
        Neural.query()
    end
end

local function set_mark(buffer)
    -- Add highlight/sign mark when running query.
    if Config.options.ui.show_icon or Config.options.ui.show_hl then
        -- Add static icon.
        local icon = ''
        if Config.options.ui.show_icon then
            icon = Config.options.ui.icon
        end

        -- Add line highlight.
        local highlight_group = ''
        if Config.options.ui.show_hl then
            highlight_group = 'NeuralLine'
        end

        mark_id = vim.api.nvim_buf_set_extmark(buffer, Config.namespace, start_row, start_col, {
            end_row = end_row,
            end_col = end_col,
            hl_group = 'NeuralLine',
            hl_eol = true,
            line_hl_group = highlight_group,
            sign_text = icon,
            sign_hl_group = 'NeuralSign',
        })

        -- Use significant to add animated sign
        if has_significant and Config.options.ui.use_animated_sign and start_row > 0 then
            -- TODO: Investigate issue with extmarks and vim.api.nvim_buf_set_text(..., {'', ''})
            AnimatedSign.start_animated_sign(start_row, 'dots', 100)
        end
    end
end

function Neural.query(prompt, type, args)
    local complete_model, edit_model

    -- Collect arguments from basic command call
    if args then
        Neural.get_buffer_info(args)
    end

    -- Select model
    if type  == 'code' then
        complete_model = OpenAI.models.complete_code
        edit_model = OpenAI.models.edit_code
    else
        complete_model = OpenAI.models.complete_text
        edit_model = OpenAI.models.edit_text
    end

    local buffer = vim.api.nvim_get_current_buf()

    set_mark(buffer)

    -- Actions after query completes.
    local function on_complete()
        if Config.options.ui.show_icon or Config.options.ui.show_hl then
            if has_significant and Config.options.ui.use_animated_sign then
                AnimatedSign.stop_animated_sign(start_row, {unplace_sign=true})
            end

            vim.api.nvim_buf_del_extmark(buffer, Config.namespace, mark_id)
        end
    end

    -- Pass into request to know where to async write when reading from pipes.
    local buffer_info = {
        start_row = start_row,
        start_col = start_col,
        end_col = end_col,
        end_row = end_row
    }

    -- Query buffer selection as prompt
    if context_selection then
        local selection = table.concat(
            vim.api.nvim_buf_get_text(buffer, start_row, start_col, end_row, end_col, {}),
            '\n'
        )
        if prompt == '' then
            -- Generate text completion from the visual selection and replace.
            OpenAI.completions(complete_model, {
                prompt = selection,
                temperature = Config.options.open_ai.temperature,
                presence_penalty = Config.options.open_ai.presence_penalty,
                frequency_penalty = Config.options.open_ai.frequency_penalty,
                stream = false,
            }, buffer_info, on_complete)
        else
            -- Generate an edit using a given prompt and replace.
            OpenAI.edits(edit_model, {
                input = selection,
                instruction = prompt,
                temperature = Config.options.open_ai.temperature,
            }, buffer_info, on_complete)
        end
    else
        if prompt == '' then
            local swift_context = Config.options.open_ai.context_lines

            -- Get prefix text from buffer.
            local prefix_text = vim.api.nvim_buf_get_text(
                buffer,
                math.max(0, start_row-swift_context), 0,
                start_row,
                start_col,
                {}
            )
            -- Get suffix text from buffer.
            local suffix_text = vim.api.nvim_buf_get_text(
                buffer,
                end_row,
                end_col,
                math.min(end_row+swift_context, vim.api.nvim_buf_line_count(buffer)-1),
                99999999,
                {}
            )
            -- Insert newline characters.
            local prefix = table.concat(prefix_text, '\n')
            local suffix = table.concat(suffix_text, '\n')

            -- Generate text completion from surrounding context.
            OpenAI.completions(complete_model, {
                prompt = prefix,
                suffix = suffix,
                temperature =  Config.options.open_ai.temperature,
                presence_penalty = Config.options.open_ai.presence_penalty,
                frequency_penalty = Config.options.open_ai.frequency_penalty,
                stream = true,
            }, buffer_info, on_complete)
        else
            -- Generate text completion from a given prompt.
            OpenAI.completions(complete_model, {
                prompt = prompt,
                temperature = Config.options.open_ai.temperature,
                presence_penalty = Config.options.open_ai.presence_penalty,
                frequency_penalty = Config.options.open_ai.frequency_penalty,
                stream = true,
            }, buffer_info, on_complete)
        end
    end
end

Neural.setup()

return Neural
