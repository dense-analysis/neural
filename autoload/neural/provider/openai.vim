" Author: w0rp <devw0rp@gmail.com>
" Description: A script describing how to use OpenAI compatible APIs with Neural

function! neural#provider#openai#Get() abort
    return {
    \   'name': 'openai',
    \   'script_language': 'python',
    \   'script': neural#GetScriptDir() . '/openai.py',
    \}
endfunction
