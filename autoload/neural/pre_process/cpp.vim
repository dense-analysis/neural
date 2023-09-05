" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for C++ files.

function! neural#pre_process#cpp#Process(buffer, input) abort
    let a:input.prompt = 'Write C++ syntax. '
    \   . a:input.prompt
endfunction
