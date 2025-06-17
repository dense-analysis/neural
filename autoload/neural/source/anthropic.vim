" Author: w0rp <devw0rp@gmail.com>
" Description: A script describing how to use Anthropic Claude with Neural

function! neural#source#anthropic#Get() abort
    return {
    \   'name': 'anthropic',
    \   'script_language': 'python',
    \   'script': neural#GetScriptDir() . '/anthropic.py',
    \}
endfunction
