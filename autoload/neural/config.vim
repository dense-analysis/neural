scriptencoding utf-8
" Author: w0rp <devw0rp@gmail.com>
" Description: Configuration of Neural with a default config.

" Track modifications to g:neural, in case we set it again.
let s:last_dictionary = get(s:, 'last_dictionary', {})

" Defaults for different providers.
let s:provider_defaults = {
\   'openai': {
\       'type': 'openai',
\       'url': 'https://api.openai.com',
\       'api_key': '',
\       'frequency_penalty': 0.1,
\       'max_tokens': 1024,
\       'model': 'gpt-3.5-turbo-instruct',
\       'use_chat_api': v:false,
\       'presence_penalty': 0.1,
\       'temperature': 0.2,
\       'top_p': 1,
\   },
\}

" Defaults for general settings.
let s:defaults = {
\   'pre_process': {
\       'enabled': v:true,
\   },
\   'set_default_keybinds': v:true,
\   'ui': {
\       'prompt_enabled': v:true,
\       'prompt_icon': '🗲',
\       'animated_sign_enabled': v:true,
\       'echo_enabled': v:true,
\   },
\   'buffer': {
\       'completion_key': '<C-CR>',
\       'create_mode': 'vertical',
\       'wrap': v:true,
\   },
\   'providers': [],
\}

function! neural#config#DeepMerge(into, from) abort
    for [l:key, l:value] in items(a:from)
        if type(l:value) is v:t_dict && type(get(a:into, l:key, 0)) is v:t_dict
            let a:into[key] = neural#config#DeepMerge(a:into[l:key], l:value)
        else
            let a:into[key] = l:value
        endif
    endfor

    return a:into
endfunction

" Set the shared configuration for Neural.
function! neural#config#Set(settings) abort
    let g:neural = a:settings
    call neural#config#Load()
endfunction

function! neural#config#ConvertLegacySettings(dictionary) abort
    " Use the old selection to know which source to copy to providers.
    let l:selected = get(a:dictionary, 'selected', 'openai')

    " Replace 'source' with newer 'providers'
    if has_key(a:dictionary, 'source') && !has_key(a:dictionary, 'providers')
        let l:source = remove(a:dictionary, 'source')
        let a:dictionary.providers = []

        if type(l:source) is v:t_dict
            " Default the configuration to the openai config for chatgpt.
            let l:settings = get(l:source, l:selected, get(l:source, 'openai'))
            " Keep old behavior to default the chatgpt key to the openai key.
            let l:default_api_key = get(get(l:source, 'openai', {}), 'api_key', '')

            if type(l:settings) is v:t_dict
                let l:settings = copy(l:settings)
                let l:settings.type = l:selected

                if l:selected is# 'chatgpt'
                    let l:settings.use_chat_api = v:true
                endif

                if empty(get(l:settings, 'api_key'))
                    let l:settings.api_key = l:default_api_key
                endif

                call add(a:dictionary.providers, l:settings)
            endif
        endif
    endif

    " Remove the 'selected' key if set.
    if has_key(a:dictionary, 'selected')
        call remove(a:dictionary, 'selected')
    endif
endfunction

" Merge defaults for different provider types in.
function! neural#config#MergeProviderDefaults(providers) abort
    let l:merged_providers = []

    if type(a:providers) is v:t_list && !empty(a:providers)
        for l:source in a:providers
            let l:type = get(l:source, 'type', v:null)

            call add(l:merged_providers, neural#config#DeepMerge(
            \   deepcopy(get(s:provider_defaults, l:type, {})),
            \   l:source,
            \))
        endfor
    else
        " Default providers to just openai with no API key.
        let l:merged_providers = [deepcopy(s:provider_defaults.openai)]
    endif

    return l:merged_providers
endfunction

function! neural#config#Load() abort
    let l:dictionary = get(g:, 'neural', {})

    " Merge the Dictionary with defaults again if g:neural changed.
    if l:dictionary isnot# s:last_dictionary
        " Create a shallow copy to modify
        let l:dictionary = copy(l:dictionary)
        call neural#config#ConvertLegacySettings(l:dictionary)
        let l:dictionary.providers = neural#config#MergeProviderDefaults(
        \   get(l:dictionary, 'providers', v:null)
        \)

        let s:last_dictionary = neural#config#DeepMerge(
        \   deepcopy(s:defaults),
        \   l:dictionary,
        \)
        let g:neural = s:last_dictionary
    endif
endfunction
