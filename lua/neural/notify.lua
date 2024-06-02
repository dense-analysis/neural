-- Author: Anexon <anexon@protonmail.com>
-- Description: Show messages with optional nvim-notify integration.

-- nvim-notify plugin
local has_notify, Notify = pcall(require, 'notify')

local M = {}

local opts = {
    title = 'Neural',
    icon = vim.g.neural.ui.prompt_icon
}

-- Show a message with nvim-notify or fallback.
--- @param message string
--- @param level string Level following vim.log.levels spec.
function M.show_message(message, level)
    if has_notify then
        Notify(message, level, opts)
    else
      vim.fn['neural#preview#Show'](message, {stay_here = 1})
    end
end

-- Show info message.
--- @param message string
function M.info(message)
    M.show_message(message, 'info')
end

-- Show warning message.
--- @param message string
function M.warn(message)
    M.show_message(message, 'warn')
end

-- Show error message.
--- @param message string
function M.error(message)
    if has_notify then
        Notify(message, 'error', opts)
    else
      vim.fn['neural#OutputErrorMessage'](message)
    end
end

return M
