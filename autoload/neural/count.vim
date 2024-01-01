" Author: Anexon <anexon@protonmail.com>
" Description: Count the number of tokens in some input of text.

let s:current_job = get(s:, 'current_count_job', 0)

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
        if has('nvim')
            execute 'lua require(''neural'').notify("' . a:job_data.output_lines[0] . '", "info")'
        else
            call neural#preview#Show(
            \   a:job_data.output_lines[0],
            \   {'stay_here': 1},
            \)
        endif
    endif

    let s:current_job = 0
endfunction


function! neural#count#Cleanup() abort
    if s:current_job
        call neural#job#Stop(s:current_job)
        let s:current_job = 0
    endif
endfunction


" TODO: Refactor
" Get the path to the executable for a script language.
function! s:GetScriptExecutable(source) abort
    if a:source.script_language is# 'python'
        let l:executable = ''

        if has('win32')
            " Try to automatically find Python on Windows, even if not in PATH.
            let l:executable = expand('~/AppData/Local/Programs/Python/Python3*/python.exe')
        endif

        if empty(l:executable)
            let l:executable = 'python3'
        endif

        return l:executable
    endif

    throw 'Unknown script language: ' . a:source.script_language
endfunction

" TODO: Refactor
function! neural#count#GetCommand(buffer) abort
    let l:source = {
    \   'name': 'openai',
    \   'script_language': 'python',
    \   'script': neural#GetPythonDir() . '/utils.py',
    \}

    let l:script_exe = s:GetScriptExecutable(l:source)
    let l:command = neural#Escape(l:script_exe)
    \   . ' ' . neural#Escape(l:source.script)
    let l:command = neural#job#PrepareCommand(a:buffer, l:command)

    return [l:source, l:command]
endfunction


function! neural#count#SelectedLines() abort
    " Reload the Neural config if needed.
    " call neural#config#Load()
    " Stop Neural doing anything else if explaining code.
    " call neural#Cleanup()
    let l:range = neural#visual#GetRange()
    let l:buffer = bufnr('')

    let [l:source, l:command] = neural#count#GetCommand(l:buffer)

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
        " let l:lines = neural#redact#PasswordsAndSecrets(l:range.selection)
        let l:lines = l:range.selection

        let l:config = get(g:neural.source, l:source.name, {})

        " If the config is not a Dictionary, throw it away.
        if type(l:config) isnot v:t_dict
            let l:config = {}
        endif

        let l:input = {
        \   'model': l:config,
        \   'text': join(l:lines, "\n"),
        \}
        call neural#job#SendRaw(l:job_id, json_encode(l:input) . "\n")
    else
        call neural#OutputErrorMessage('Failed to run ' . l:source.name)

        return
    endif

    let s:current_job = l:job_id
endfunction
