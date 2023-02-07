" Author: w0rp <devw0rp@gmail.com>
" Description: A script describing how to use OpenAI with Neural

let s:script_dir = neural#GetScriptDir()

function! neural#datasource#openai#Get() abort
    return {
    \   'name': 'openai',
    \   'script_language': 'python',
    \   'script': s:script_dir . '/openai.py',
    \}
endfunction
