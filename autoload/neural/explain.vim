" Author: w0rp <devw0rp@gmail.com>
" Description: Explain a visual selection with Neural.

let s:current_job = get(s:, 'current_explain_job', 0)

function! s:AddOutputLine(buffer, job_data, line) abort
    call add(a:job_data.output_lines, a:line)
endfunction

function! s:AddErrorLine(buffer, job_data, line) abort
    call add(a:job_data.error_lines, a:line)
endfunction

function! s:HandleOutputEnd(buffer, job_data, exit_code) abort
    " Output an error message from the program if something goes wrong.
    if a:exit_code != 0
        " Complain when something goes wrong.
        call neural#OutputErrorMessage(join(a:job_data.error_lines, "\n"))
    else
        let l:i = 0

        while l:i < len(a:job_data.output_lines)
            if !empty(a:job_data.output_lines[l:i])
                break
            endif

            let l:i += 1
        endwhile

        call neural#preview#Show(
        \   a:job_data.output_lines[l:i :],
        \   {'stay_here': 1},
        \)
    endif

    let s:current_job = 0
endfunction

function! neural#explain#Cleanup() abort
    if s:current_job
        call neural#job#Stop(s:current_job)
        let s:current_job = 0
    endif
endfunction

function! neural#explain#SelectedLines() abort
    " Reload the Neural config if needed.
    call neural#config#Load()
    " Stop Neural doing anything else if explaining code.
    call neural#Cleanup()

    let l:range = neural#visual#GetRange()
    let l:buffer = bufnr('')

    let [l:provider, l:command] = neural#GetCommand(l:buffer)

    let l:job_data = {
    \   'output_lines': [],
    \   'error_lines': [],
    \}
    let l:job_id = neural#job#Start(l:command, {
    \   'mode': 'nl',
    \   'out_cb': {job_id, line -> s:AddOutputLine(l:buffer, l:job_data, line)},
    \   'err_cb': {job_id, line -> s:AddErrorLine(l:buffer, l:job_data, line)},
    \   'exit_cb': {job_id, exit_code -> s:HandleOutputEnd(l:buffer, l:job_data, exit_code)},
    \})

    if l:job_id > 0
        let l:lines = neural#redact#PasswordsAndSecrets(l:range.selection)

        let l:input = {
        \   'config': l:provider.config,
        \   'prompt': "Explain these lines:\n\n" . join(l:lines, "\n"),
        \}
        call neural#job#SendRaw(l:job_id, json_encode(l:input) . "\n")
    else
        call neural#OutputErrorMessage('Failed to run ' . l:provider.name)

        return
    endif

    let s:current_job = l:job_id
endfunction
