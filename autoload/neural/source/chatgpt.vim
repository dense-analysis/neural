" Author: w0rp <devw0rp@gmail.com>
" Description: A script describing how to use ChatGPT with Neural

function! neural#source#chatgpt#Get() abort
    return {
    \   'name': 'chatgpt',
    \   'script_language': 'python',
    \   'script': neural#GetScriptDir() . '/chatgpt.py',
    \}
endfunction
