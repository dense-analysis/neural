" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for Go files.

function! neural#pre_process#go#Process(buffer, input) abort
    let l:has_package = search('^package ', 'wnc') != 0

    let a:input.prompt = 'Write golang code. '
    \   . (l:has_package ? 'Do not write package main or main func. ' : '')
    \   . a:input.prompt
endfunction
