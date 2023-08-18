" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for SQL files.

function! neural#pre_process#sql#Process(buffer, input) abort
    let a:input.prompt = 'Write SQL code. ' . a:input.prompt
endfunction
