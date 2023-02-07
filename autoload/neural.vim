" Author: Anexon <anexon@protonmail.com>, w0rp <devw0rp@gmail.com>
" Description: The main autoload file for the Neural Vim plugin

" The location of Neural datasource scripts
let s:neural_script_dir = expand('<sfile>:p:h:h') . '/neural_datasources'

" Get the Neural scripts directory in a way that makes it hard to modify.
function! neural#GetScriptDir() abort
    return s:neural_script_dir
endfunction

function! s:OutputErrorMessage(message) abort
    let l:lines = split(a:message, '\v\r\n|\n|\r')

    if len(l:lines) > 0
        if len(l:lines) > 1
            " Add a message to say to look at a long error if there's more
            " than 1 error line.
            call add(l:lines, 'Neural hit a snag! Type :mes to see why')
        endif

        " no-custom-checks
        echohl error

        try
            for l:line in l:lines
                " no-custom-checks
                echomsg l:line
            endfor
        finally
            " no-custom-checks
            echohl None
        endtry
    endif
endfunction

function! s:AddLineToBuffer(buffer, job_data, line) abort
    if bufnr('') isnot a:buffer
        return
    endif

    let l:start_line = a:job_data.line
    let l:started = a:job_data.content_started

    " Skip introductory empty lines.
    if !l:started && len(a:line) == 0
        return
    endif

    " Check if we need to re-position the cursor to stop it appearing to move
    " down as lines are added.
    let l:pos = getpos('.')
    let l:last_line = len(getbufline(a:buffer, 1, '$'))
    let l:move_up = 0

    if l:pos[1] == l:last_line
        let l:move_up = 1
    endif

    call append(l:start_line, a:line)

    " Move the cursor back up again to make content appear below.
    if l:move_up
        call setpos('.', l:pos)
    endif

    let a:job_data.line = l:start_line + 1
    let a:job_data.content_started = 1
endfunction

function! s:AddErrorLine(buffer, job_data, line) abort
    call add(a:job_data.error_lines, a:line)
endfunction

function! s:HandleOutputEnd(buffer, job_data, exit_code) abort
    " Output an error message from the program if something goes wrong.
    if a:exit_code != 0
        call s:OutputErrorMessage(join(a:job_data.error_lines, "\n"))
    else
        " Signal Neural is done for plugin integration.
        silent doautocmd <nomodeline> User NeuralWritePost
        " no-custom-checks
        echomsg 'Neural is done!'
    endif
endfunction

" Get the path to the executable for a script language.
function! s:GetScriptExecutable(datasource) abort
    if a:datasource.script_language is# 'python'
        return 'python3'
    endif

    throw 'Unknown script language: ' . a:datasource.script_language
endfunction

" Escape a string suitably for each platform.
" shellescape does not work on Windows.
function! neural#Escape(str) abort
    if fnamemodify(&shell, ':t') is? 'cmd.exe'
        " If the string contains spaces, it will be surrounded by quotes.
        " Otherwise, special characters will be escaped with carets (^).
        return substitute(
        \   a:str =~# ' '
        \       ?  '"' .  substitute(a:str, '"', '""', 'g') . '"'
        \       : substitute(a:str, '\v([&|<>^])', '^\1', 'g'),
        \   '%',
        \   '%%',
        \   'g',
        \)
    endif

    return shellescape (a:str)
endfunction

function! neural#Prompt(prompt_text) abort
    " TODO: Print a message if the function cannot be loaded.
    let l:GetDatasource = function(
    \   'neural#datasource#'
    \   . g:neural_selected_datasource
    \   . '#Get'
    \)
    let l:datasource = l:GetDatasource()
    let l:config = get(g:neural_datasource_config, l:datasource.name, {})

    " If the config is not a Dictionary, throw it away.
    if type(l:config) isnot v:t_dict
        let l:config = {}
    endif

    let l:input = {
    \   'config': l:config,
    \   'prompt': a:prompt_text,
    \   'temperature': 0.0,
    \}

    let l:buffer = bufnr('')
    let l:neural_line = getpos('.')[1]

    if len(getline(l:neural_line)) == 0
        let l:neural_line -= 1
    endif

    let l:script_exe = s:GetScriptExecutable(l:datasource)
    let l:command = neural#Escape(l:script_exe)
    \   . ' ' . neural#Escape(l:datasource.script)
    let l:command = neural#job#PrepareCommand(l:buffer, l:command)
    let l:job_data = {
    \   'line': l:neural_line,
    \   'error_lines': [],
    \   'content_started': 0,
    \}

    let l:job_id = neural#job#Start(l:command, {
    \   'mode': 'nl',
    \   'out_cb': {job_id, line -> s:AddLineToBuffer(l:buffer, l:job_data, line)},
    \   'err_cb': {job_id, line -> s:AddErrorLine(l:buffer, l:job_data, line)},
    \   'exit_cb': {job_id, exit_code -> s:HandleOutputEnd(l:buffer, l:job_data, exit_code)},
    \})

    if l:job_id > 0
        let l:stdin_data = json_encode(l:input) . "\n"

        call neural#job#SendRaw(l:job_id, l:stdin_data)
    else
        call s:OutputErrorMessage('Failed to run ' . l:datasource.name)
    endif

    " TODO: Set a timer and check if the job is still running.
    "       if the job is still running after some time, print another
    "       friendly message explaining that we're still waiting for
    "       the first message to come through.
    "
    "       Maybe print a different message if we're buffering a response
    "       the user can't see yet, which still makes sense when we make
    "       it print the results live. Maybe users will want to disable
    "       the 'cool' printing of messages in any case.
    "
    " no-custom-checks
    echomsg 'Neural is working, please wait...'
endfunction
