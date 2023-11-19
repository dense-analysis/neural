" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for Lua files.

function! neural#pre_process#lua#Process(buffer, input) abort
    let a:input.prompt = 'Write Lua code. '
    \   . a:input.prompt
endfunction
