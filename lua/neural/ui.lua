-- UI module for creating the nui.nvim input popup

local Input = require('nui.input')
local Event = require('nui.utils.autocmd').event
local Config = require('neural.config')

local UI = {}

-- Prompts the user for input.
--- @param title string The title of the prompt.
--- @param on_submit function The function to call when the user submits the prompt.
function UI.prompt(title, on_submit)

    -- TODO: Make escape keys configurable.
    local exit_keys = {
        {'n', 'q',
            function(_)
                vim.api.nvim_command(':q')
            end, {noremap = true},
        },
        {'n', '<ESC>',
            function(_)
                vim.api.nvim_command(':q')
            end, {noremap = true},
        },
        {'i', '<ESC>',
            function(_)
                vim.api.nvim_command(':q')
            end, {noremap = true},
        },
        {'i', '<C-c>',
            function(_)
                vim.api.nvim_command(':q')
            end, {noremap = true},
        },
    }

    -- TODO: Make prompt more configurable.
    local input = Input({
        position = {row = '85.2%', col = '50%'},
        size = {
            width = '51.8%',
            height = '20%',
        },
        relative = 'editor',
        border = {
            highlight = 'NeuralPromptBorder',
            style = 'rounded',
            text = {
                top = title,
                top_align = 'center',
            },
        },
        win_options = {
            winblend = 10,
            winhighlight = 'Normal:Normal',
        },
    }, {
        prompt = Config.options.ui.icon .. ' ',
        default_value = '',
        on_close = function() end,
        on_submit = function(value)
            on_submit(value)
        end,
    })
    input:mount()
    input:on(Event.BufLeave, function()
        input:unmount()
    end)
    for _, v in ipairs(exit_keys) do
        input:map(unpack(v))
    end
end

return UI
