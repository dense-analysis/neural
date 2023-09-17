" Author: Anexon <anexon@protonmail.com>
" Description: Neural Buffer for interacting with neural sources directly.

call neural#config#Load()

command! -buffer -nargs=0 NeuralRun :call neural#buffer#RunBuffer()

nnoremap <buffer> <Plug>(neural_run) :NeuralRun<Return>

" Keybindings of Neural Buffer
if exists('*keytrans') && exists('g:neural.buffer.run_key')
    execute 'nnoremap ' . keytrans(g:neural.buffer.run_key) . ' <Plug>(neural_run)'
    execute 'inoremap ' . keytrans(g:neural.buffer.run_key) . ' <Esc><Plug>(neural_run)'
else
    nnoremap <C-CR> <Plug>(neural_run)
    inoremap <C-CR> <Esc><Plug>(neural_run)
endif

