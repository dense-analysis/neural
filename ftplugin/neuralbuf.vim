" Author: Anexon <anexon@protonmail.com>
" Description: Neural Buffer for interacting with neural providers directly.

call neural#config#Load()

command! -buffer -nargs=0 NeuralCompletion :call neural#buffer#RunBuffer()

nnoremap <silent> <buffer> <Plug>(neural_completion) :NeuralCompletion<CR>

" Keybindings of Neural Buffer
execute 'nnoremap ' . g:neural.buffer.completion_key . ' <Plug>(neural_completion)'
execute 'inoremap ' . g:neural.buffer.completion_key . ' <Esc><Plug>(neural_completion)'
