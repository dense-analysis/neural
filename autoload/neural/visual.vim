" Author: w0rp <devw0rp@gmail.com>
" Description: Neural functions for working with Vim's visual mode.

" Get all information for a visual range command we might want.
"
" Credit to xolox for most of this.
function! neural#visual#GetRange() abort
    let [l:lnum, l:col] = getpos("'<")[1:2]
    let [l:end_lnum, l:end_col] = getpos("'>")[1:2]
    let l:end_offset = &selection is# 'inclusive' ? 1 : 2

    " Get the line range and slice the text we selected.
    let l:selection = getline(l:lnum, l:end_lnum)

    if !empty(l:selection)
        let l:selection[0] = l:selection[0][l:col - 1:]
        let l:selection[-1] = l:selection[-1][: l:end_col - l:end_offset]
        " Get the actual end column from the text length, as Vim can give us
        " the maximum int for visual line mode.
        let l:end_col = len(l:selection[-1])
    endif

    return {
    \   'lnum': l:lnum,
    \   'col': l:col,
    \   'end_lnum': l:end_lnum,
    \   'end_col': l:end_col,
    \   'selection': l:selection,
    \}
endfunction
