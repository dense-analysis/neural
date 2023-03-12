" Author: w0rp <devw0rp@gmail.com>
" Description: A script describing how to use OpenAI with Neural

function! neural#source#openai#Get() abort
    return {
    \   'name': 'openai',
    \   'script_language': 'python',
    \   'script': neural#GetScriptDir() . '/openai.py',
    \}
endfunction
