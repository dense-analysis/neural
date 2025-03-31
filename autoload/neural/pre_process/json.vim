" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for JSON files.

function! neural#pre_process#json#Process(buffer, input) abort
    let a:input.prompt = 'Write only JSON syntax, no explanation. '
    \   . a:input.prompt
endfunction
