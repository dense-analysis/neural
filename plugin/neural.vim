" Author: Anexon <anexon@protonmail.com>, w0rp <devw0rp@gmail.com>
" Description: Main entry point for the Neural Vim plugin

if exists('g:loaded_neural')
    finish
endif

let g:loaded_neural = 1

" A flag for detecting if the required features are set.
if has('nvim')
    let s:has_features = has('timers') && has('nvim-0.2.0')
else
    " Check if Job and Channel functions are available, instead of the
    " features. This works better on old MacVim versions.
    let s:has_features = has('timers') && exists('*job_start') && exists('*ch_close_in')
endif

if !s:has_features
    " Only output a warning if editing some special files.
    if index(['', 'gitcommit'], &filetype) == -1
        " no-custom-checks
        echoerr 'Neural requires NeoVim >= 0.2.0 or Vim 8 with +timers +job +channel'
        " no-custom-checks
        echoerr 'Please update your editor appropriately.'
    endif

    " Stop here, as it won't work.
    finish
endif

command! -nargs=? Neural :call neural#Prompt(<q-args>)
command! -nargs=0 NeuralBuffer call neural#buffer#CreateBuffer()
command! -nargs=0 NeuralBufferRun call neural#buffer#RunBuffer()

" <Plug> mappings for commands
nnoremap <Plug>(neural_prompt) :call neural#OpenPrompt()<Return>
