" Author: w0rp <devw0rp@gmail.com>
" Description: Preview windows for showing whatever information in.

" Open a preview window and show some lines in it.
" The second argument allows options to be passed in.
"
" filetype  - The filetype to use, defaulting to 'neural-preview'
" stay_here - If 1, stay in the window you came from.
function! neural#preview#Show(lines, options) abort
    silent pedit NeuralPreviewWindow
    wincmd P

    setlocal modifiable
    setlocal noreadonly
    setlocal nobuflisted
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    :%d
    call setline(1, a:lines)
    setlocal nomodifiable
    setlocal readonly
    let &l:filetype = get(a:options, 'filetype', 'neural-preview')

    if get(a:options, 'stay_here')
        wincmd p
    endif
endfunction
