" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for markdown files.

function! neural#pre_process#markdown#Process(buffer, input) abort
    let a:input.prompt = 'Write text in a markdown file. '
    \   . a:input.prompt
endfunction
