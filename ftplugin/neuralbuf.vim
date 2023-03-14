call neural#config#Load()

command! -buffer -nargs=0 NeuralRun :call neural#buffer#RunBuffer()

nnoremap <buffer> <Plug>(neural_run) :NeuralRun<Return>

" Keybindings of Neural Buffer
nnoremap <C-CR> <Plug>(neural_run)
inoremap <C-CR> <Esc><Plug>(neural_run)

