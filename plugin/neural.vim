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

" Have Neural write to the buffer given a prompt.
command! -nargs=? Neural :call neural#Prompt(<q-args>)
" Stop Neural doing anything.
command! -nargs=0 NeuralStop :call neural#Stop()
" Have Neural explain the visually selected lines.
command! -range NeuralExplain :call neural#explain#SelectedLines()

" <Plug> mappings for commands
nnoremap <silent> <Plug>(neural_prompt) :call neural#OpenPrompt()<Return>
nnoremap <silent> <Plug>(neural_stop) :call neural#Stop()<Return>
vnoremap <silent> <Plug>(neural_explain) :NeuralExplain<Return>

" Set default keybinds for Neural unless we're told not to. We should almost
" never define keybinds by default in a plugin, but we can add only a few to
" make things convenient for users.
if has_key(g:, 'neural') && get(g:neural, 'set_default_keybinds')
    if empty(maparg("\<C-c>", 'n'))
        nnoremap <C-c> <Plug>(neural_stop)
    endif
endif
