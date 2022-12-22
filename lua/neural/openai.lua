-- OpenAI capabilities for completions and edits of text and code models.

local Request = require('neural.request')
local Config = require('neural.config')

local OpenAI = {}

OpenAI.API_KEY = ''

OpenAI.endpoints = {
    completions = 'https://api.openai.com/v1/completions',
    edits = 'https://api.openai.com/v1/edits',
}

OpenAI.models = {
    complete_text = 'text-davinci-003',
    complete_code = 'code-davinci-002',
    edit_text = 'text-davinci-edit-001',
    edit_code = 'code-davinci-edit-001',
}

-- Query for completions.
--- @param model string OpenAI completion model.
--- @param args table Query arguments.
--- @param buffer_info table Buffer info to write results.
--- @param on_complete function Callback after request is complete.
function OpenAI.completions(model, args, buffer_info, on_complete)
    assert(
        model == OpenAI.models.complete_text or model == OpenAI.models.complete_code,
        'Model must be a valid OpenAI completions model!'
    )
    -- Request JSON body
    local body = {
        model = model,
        prompt = args.prompt,
        suffix = args.suffix,
        temperature = args.temperature,
        max_tokens = Config.options.open_ai.max_tokens,
        presence_penalty = args.presence_penalty,
        frequency_penalty = args.frequency_penalty,
        stream = args.stream,
    }
    -- Make request and pass `on_complete` result callback handler.
    Request.post(OpenAI.endpoints.completions, body, OpenAI.API_KEY, buffer_info, on_complete)
end

-- Query for edits.
--- @param model string OpenAI edits model.
--- @param args table Query arguments.
--- @param buffer_info table Buffer info to write results.
--- @param on_complete function Callback after request is complete.
function OpenAI.edits(model, args, buffer_info, on_complete)
    assert(
        model == OpenAI.models.edit_text or model == OpenAI.models.edit_code,
        'Model must be a valid OpenAI edits model!'
    )
    -- Request JSON body
    local body = {
        model = model,
        input = args.input,
        instruction = args.instruction,
        temperature = args.temperature,
    }
    -- Make request and pass `on_complete` result callback handler.
    Request.post(OpenAI.endpoints.edits, body, OpenAI.API_KEY, buffer_info, on_complete)
end

return OpenAI
