" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for shell scripts

function! neural#pre_process#sh#GetScriptType(buffer) abort
    let l:current_syntax = getbufvar(a:buffer, 'current_syntax', '')

    if getbufvar(a:buffer, 'is_bash', 0)
        return 'bash'
    endif

    if l:current_syntax is# 'zsh'
        return 'zsh'
    endif

    if getbufvar(a:buffer, 'is_kornshell', 0)
        " https://www.youtube.com/watch?v=jRGrNDV2mKc
        return 'ksh'
    endif

    return 'sh'
endfunction

function! neural#pre_process#sh#GetScriptTypePrefix(script_type) abort
    if a:script_type is# 'bash'
        return 'Write Bash syntax. '
    endif

    if a:script_type is# 'zsh'
        return 'Write zsh syntax. '
    endif

    if a:script_type is# 'ksh'
        return 'Write Kornshell syntax. '
    endif

    return 'Write shell script syntax. '
endfunction

function! neural#pre_process#sh#Process(buffer, input) abort
    let l:script_type = neural#pre_process#sh#GetScriptType(a:buffer)
    let l:prefix = neural#pre_process#sh#GetScriptTypePrefix(l:script_type)

    let a:input.prompt = l:prefix . a:input.prompt
endfunction
