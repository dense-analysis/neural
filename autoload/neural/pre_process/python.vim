" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for Python

function! neural#pre_process#python#Process(buffer, input) abort
    let a:input.prompt = 'Write Python syntax. '
    \   . a:input.prompt
endfunction
