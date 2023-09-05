" Author: w0rp <devw0rp@gmail.com>
" Description: Pre-processing rules for CMake files.

function! neural#pre_process#cmake#Process(buffer, input) abort
    let a:input.prompt = 'Write CMakeLists.txt syntax. '
    \   . a:input.prompt
endfunction
