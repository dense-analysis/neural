-- Author: Anexon <anexon@protonmail.com>
-- Description: UI module for creating the prompt with nui.nvim input popup.

local Input = require('nui.input')
local Event = require('nui.utils.autocmd').event

local UI = {}

-- TODO: Expose option configuration.
local opts = {
    default_value = '',
    winblend = 0,
    style = 'rounded'
}

-- Prompts the user for input.
--- @param title string The title of the prompt.
--- @param on_submit function The function to call when the user submits the prompt.
function UI.prompt(title, on_submit)
    local input = Input({
        position = {row = '85.2%', col = '50%'},
        size = { width = '51.8%', height = '20%'},
        relative = 'editor',
        border = {
            highlight = 'NeuralPromptBorder',
            style = opts.style,
            text = {
                top = title,
                top_align = 'center',
            },
        },
        win_options = {
            winblend = opts.winblend,
        },
    }, {
        prompt = vim.g.neural.ui.prompt_icon .. ' ',
        default_value = opts.default_value,
        on_close = function() end,
        on_submit = function(value)
            on_submit(value)
        end,
    })
    input:mount()

    -- Handle unmounting
    input:on(Event.BufLeave, function()
        input:unmount()
    end)

    local exit_keys = {
        {'n', 'q'},
        {'n', '<ESC>'},
        {'i', '<ESC>'},
        {'n', '<C-c>'},
        {'i', '<C-c>'},
    }
    for _, key in ipairs(exit_keys) do
        input:map(key[1], key[2], function()
            input:unmount()
        end, { noremap = true })
    end
end

return UI
