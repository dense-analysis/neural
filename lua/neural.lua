local next = next
local Config = require('neural.config')

-- External dependencies
local has_nui, _ = pcall(require, 'nui.input')
local UI = {}

if has_nui then
    UI = require('neural.ui')
end

local Neural = {}

function Neural.setup(options)
    Config.setup(options)
end

function Neural.prompt()
    -- Set up the default config if not otherwise configured.
    if next(Config.options) == nil then
        Config.setup({})
    end

    if has_nui and Config.options.ui.use_prompt then
        UI.prompt(
            ' Neural ',
            function(value)
                if value == nil or value == '' then
                    vim.fn['neural#ComplainNoPromptText']()
                else
                    vim.fn['neural#Prompt'](value)
                end
            end
        )
    else
        vim.fn.feedkeys(':NeuralPrompt ')
    end
end

return Neural
