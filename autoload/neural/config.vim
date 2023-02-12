scriptencoding utf-8
" Author: w0rp <devw0rp@gmail.com>
" Description: Configuration of Neural with a default config.

" Track modifications to g:neural, in case we set it again.
if !exists('s:last_dictionary')
    let s:last_dictionary = {}
endif

let s:defaults = {
\   'selected': 'openai',
\   'ui': {
\        'prompt_enabled': v:true,
\        'prompt_icon': '🗲',
\        'animated_sign_enabled': v:true,
\   },
\   'source': {
\       'openai': {
\           'api_key': '',
\           'temperature': 0.2,
\           'max_tokens': 1024,
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

" Set the shared configuration for Neural.
function! neural#config#Set(settings) abort
    let g:neural = neural#config#DeepMerge(deepcopy(s:defaults), a:settings)
    let s:last_dictionary = g:neural
endfunction

function! neural#config#Load() abort
    let l:dictionary = get(g:, 'neural', {})

    " Merge the Dictionary with defaults again if g:neural changed.
    if l:dictionary isnot# s:last_dictionary
        let s:last_dictionary = neural#config#DeepMerge(
        \   deepcopy(s:defaults),
        \   l:dictionary,
        \)
    endif

    let g:neural = s:last_dictionary
endfunction
