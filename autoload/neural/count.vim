" Author: Anexon <anexon@protonmail.com>
" Description: Count the number of tokens in a given input of text.

let s:current_job = get(s:, 'current_count_job', 0)

function! s:HandleOutputEnd(job_data, exit_code) abort
    if a:exit_code == 0
        if has('nvim')
            execute 'lua require(''neural'').notify("' . a:job_data.output_lines[0] . '", "info")'
        else
            call neural#preview#Show(
            \   a:job_data.output_lines[0],
            \   {'stay_here': 1},
            \)
        endif
    else
        call neural#OutputErrorMessage(join(a:job_data.error_lines, "\n"))
    endif

    call neural#job#Stop(s:current_job)
    let s:current_job = 0
endfunction

function! neural#count#SelectedLines() abort
    " TODO: Reload the Neural config if needed and pass.
    " call neural#config#Load()
    " TODO: Should be able to get this elsewhere from a factory-like method.
    let l:job_data = {
    \   'output_lines': [],
    \   'error_lines': [],
    \}
    let l:job_id = neural#job#Start(neural#utils#GetPythonCommand('utils.py'), {
    \   'mode': 'nl',
    \   'out_cb': {job_id, line -> add(l:job_data.output_lines, line)},
    \   'err_cb': {job_id, line -> add(l:job_data.error_lines, line)},
    \   'exit_cb': {job_id, exit_code -> s:HandleOutputEnd(l:job_data, exit_code)},
    \})

    if l:job_id > 0
        let l:lines = neural#visual#GetRange().selection

        let l:input = {
        \   'text': join(l:lines, "\n"),
        \}
        call neural#job#SendRaw(l:job_id, json_encode(l:input) . "\n")
    else
        call neural#OutputErrorMessage('Failed to cound tokens')

        return
    endif

    let s:current_job = l:job_id
endfunction
