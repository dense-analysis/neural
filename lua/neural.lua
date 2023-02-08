local next = next
local Config = require('neural.config')

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

local Neural = {}

local function ensure_configured()
    -- Set up the default config if not otherwise configured.
    if next(Config.options) == nil then
        Config.setup({})
    end
end

function Neural.setup(options)
    Config.setup(options)
end

function Neural.prompt()
    ensure_configured()

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

function Neural.start_animated_sign(line)
    ensure_configured()

    if has_significant and Config.options.ui.use_animated_sign and line > 0 then
        AnimatedSign.start_animated_sign(line, 'dots', 100)
    end
end

function Neural.stop_animated_sign(line)
    ensure_configured()

    if has_significant and Config.options.ui.use_animated_sign and line > 0 then
        AnimatedSign.stop_animated_sign(line, {unplace_sign=true})
    end
end

return Neural
