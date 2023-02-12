local next = next

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

function Neural.setup(settings)
    -- Call the Vim script function to set up the shared configuration.
    vim.fn['neural#config#Set'](settings)
end

function Neural.prompt()
    local prompt_enabled = vim.g.neural.ui.prompt_enabled

    if has_nui and (prompt_enabled and prompt_enabled ~= 0) then
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
    local sign_enabled = vim.g.neural.ui.animated_sign_enabled

    if has_significant and (sign_enabled and sign_enabled ~= 0) and line > 0 then
        AnimatedSign.start_animated_sign(line, 'dots', 100)
    end
end

function Neural.stop_animated_sign(line)
    local sign_enabled = vim.g.neural.ui.animated_sign_enabled

    if has_significant and (sign_enabled and sign_enabled ~= 0) and line > 0 then
        AnimatedSign.stop_animated_sign(line, {unplace_sign=true})
    end
end

return Neural
