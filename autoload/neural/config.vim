scriptencoding utf-8
" Author: w0rp <devw0rp@gmail.com>
" Description: Configuration of Neural with a default config.

" Track modifications to g:neural, in case we set it again.
let s:last_dictionary = get(s:, 'last_dictionary', {})

let s:defaults = {
\   'selected': 'openai',
\   'pre_process': {
\       'enabled': v:true,
\   },
\   'ui': {
\       'prompt_enabled': v:true,
\       'prompt_icon': '🗲',
\       'animated_sign_enabled': v:true,
\       'echo_enabled': v:true,
\   },
\   'buffer': {
\       'run_key': "\<C-CR>",
\       'create_mode': 'vertical',
\       'wrap': v:true,
\   },
\   'source': {
\       'openai': {
\           'api_key': '',
\           'temperature': 0.2,
\           'top_p': 1,
\           'max_tokens': 1024,
\           'presence_penalty': 0.1,
\           'frequency_penalty': 0.1,
\       },
\       'chatgpt': {
\           'api_key': '',
\           'temperature': 0.2,
\           'top_p': 1,
\           'max_tokens': 2048,
\           'presence_penalty': 0.1,
\           'frequency_penalty': 0.1,
\       },
\   },
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

function! s:ApplySpecialDefaults() abort
    if empty(g:neural.source.chatgpt.api_key)
        let g:neural.source.chatgpt.api_key = g:neural.source.openai.api_key
    endif
endfunction

" Set the shared configuration for Neural.
function! neural#config#Set(settings) abort
    let g:neural = a:settings
    call neural#config#Load()
endfunction

function! neural#config#Load() abort
    let l:dictionary = get(g:, 'neural', {})

    " Merge the Dictionary with defaults again if g:neural changed.
    if l:dictionary isnot# s:last_dictionary
        let s:last_dictionary = neural#config#DeepMerge(
        \   deepcopy(s:defaults),
        \   l:dictionary,
        \)
        let g:neural = s:last_dictionary
        call s:ApplySpecialDefaults()
    endif
endfunction
