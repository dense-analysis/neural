local Config = {}

Config.namespace = vim.api.nvim_create_namespace('Neural')

local defaults = {
    mappings = {
        swift = '<C-n>', -- Code complete with no prompt
        prompt = '<C-space>',
    },
    -- OpenAI settings
    open_ai = {
        temperature = 0.0,
        presence_penalty = 0.3,
        frequency_penalty = 0.3,
        max_tokens = 2048,
        context_lines = 16, -- Surrounding lines for swift completion
        api_key = '...', -- Add your Open API secret key on setup (DO NOT COMMIT)
    },
    -- Visual settings
    ui = {
        use_prompt = true, -- Use visual floating Input
        use_animated_sign = true, -- Use animated sign mark
        show_hl = true,
        show_icon = true,
        icon = '🗲', -- Prompt/Static sign icon
        icon_color = '#ffe030', -- Sign icon color
        hl_color = '#4D4839', -- Line highlighting on output
        prompt_border_color = '#E5C07B',
    },
}

Config.options = {}

function Config.setup(options)
  Config.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

return Config
