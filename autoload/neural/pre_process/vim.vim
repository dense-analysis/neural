" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for Vim script

function! neural#pre_process#vim#Process(buffer, input) abort
    let a:input.prompt = 'Write Vim script syntax. '
    \   . a:input.prompt
endfunction
