" Author: Anexon <anexon@protonmail.com>
" Description: Neural Buffer for interacting with neural sources directly.

call neural#config#Load()

command! -buffer -nargs=0 NeuralRun :call neural#buffer#RunBuffer()

nnoremap <silent> <buffer> <Plug>(neural_completion) :NeuralRun<CR>

" Keybindings of Neural Buffer
execute 'nnoremap ' . g:neural.buffer.completion_key . ' <Plug>(neural_completion)'
execute 'inoremap ' . g:neural.buffer.completion_key . ' <Esc><Plug>(neural_completion)'
