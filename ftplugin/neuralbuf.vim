" Author: Anexon <anexon@protonmail.com>
" Description: Neural Buffer for interacting with neural sources directly.

call neural#config#Load()

command! -buffer -nargs=0 NeuralRun :call neural#buffer#RunBuffer()

nnoremap <buffer> <Plug>(neural_completion) :NeuralRun<Return>

" Keybindings of Neural Buffer
if exists('*keytrans') && exists('g:neural.buffer.completion_key')
    execute 'nnoremap ' . keytrans(g:neural.buffer.completion_key) . ' <Plug>(neural_completion)'
    execute 'inoremap ' . keytrans(g:neural.buffer.completion_key) . ' <Esc><Plug>(neural_completion)'
else
    nnoremap <C-CR> <Plug>(neural_completion)
    inoremap <C-CR> <Esc><Plug>(neural_completion)
endif

