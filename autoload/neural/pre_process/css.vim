" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for CSS files.

function! neural#pre_process#css#Process(buffer, input) abort
    let a:input.prompt = 'Write CSS code. ' . a:input.prompt
endfunction
