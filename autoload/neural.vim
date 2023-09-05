" Author: Anexon <anexon@protonmail.com>, w0rp <devw0rp@gmail.com>
" Description: The main autoload file for the Neural Vim plugin

" The location of Neural source scripts
let s:neural_script_dir = expand('<sfile>:p:h:h') . '/neural_sources'
" Keep track of the current job.
let s:current_job = get(s:, 'current_job', 0)
" Keep track of the line the last request happened on.
let s:request_line = get(s:, 'request_line', 0)

" A function purely for tests to be able to reset state
function! neural#ResetState() abort
    let s:current_job = 0
    let s:request_line = 0
endfunction

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
    " Add lines either if we can add them to the buffer which is no longer the
    " current one, or otherwise only if we're still in the same buffer.
    if bufnr('') isnot a:buffer && !exists('*appendbufline')
        return
    endif

    let l:moving_line = a:job_data.moving_line
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

    " appendbufline isn't available in old Vim versions.
    if bufnr('') is a:buffer
        call append(l:moving_line, a:line)
    else
        call appendbufline(a:buffer, l:moving_line, a:line)
    endif

    " Move the cursor back up again to make content appear below.
    if l:move_up
        call setpos('.', l:pos)
    endif

    let a:job_data.moving_line = l:moving_line + 1
    let a:job_data.content_started = 1
endfunction

function! s:AddErrorLine(buffer, job_data, line) abort
    call add(a:job_data.error_lines, a:line)
endfunction

function! s:HandleOutputEnd(buffer, job_data, exit_code) abort
    if has('nvim')
        execute 'lua require(''neural'').stop_animated_sign(' . s:request_line . ')'
    endif

    " Output an error message from the program if something goes wrong.
    if a:exit_code != 0
        call s:OutputErrorMessage(join(a:job_data.error_lines, "\n"))
    else
        " Signal Neural is done for plugin integration.
        silent doautocmd <nomodeline> User NeuralWritePost

        if g:neural.ui.echo_enabled
            " no-custom-checks
            echomsg 'Neural is done!'
        endif
    endif
endfunction

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

function! neural#ComplainNoPromptText() abort
    call s:OutputErrorMessage('No prompt text!')
endfunction

function! neural#OpenPrompt() abort
    if has('nvim')
        " Reload the Neural config on a prompt request if needed.
        call neural#config#Load()
        " In Neovim, try to use the fancy prompt UI, if we can.
        lua require('neural').prompt()
    else
        call feedkeys(':Neural ')
    endif
endfunction

function! neural#ComplainNoPromptText() abort
    call s:OutputErrorMessage('No prompt text!')
endfunction

function! s:InitiallyInformUser(job_id) abort
    if neural#job#IsRunning(a:job_id)
        " no-custom-checks
        echomsg 'Neural is working...'
    endif
endfunction

function! s:InformUserIfStillBusy(job_id) abort
    if neural#job#IsRunning(a:job_id)
        " no-custom-checks
        echomsg 'Neural is still working...'
    endif
endfunction

function! neural#Cleanup() abort
    " Stop any currently running jobs.
    call neural#job#Stop(s:current_job)

    " Remove any current signs.
    if has('nvim')
        execute 'lua require(''neural'').stop_animated_sign(' . s:request_line . ')'
    endif
endfunction

" Pre-process input for LLMs based on custom code in Neural.
function! neural#PreProcess(buffer, input) abort
    " Skip pre-processing if disabled.
    if !g:neural.pre_process.enabled
        return
    endif

    for l:split_type in split(&filetype, '\.')
        try
            let l:func_name = 'neural#pre_process#' . l:split_type . '#Process'
            call function(l:func_name)(a:buffer, a:input)
        catch /E117/
        endtry
    endfor
endfunction

function! s:LoadDataSource() abort
    let l:selected = g:neural.selected

    try
        let l:source = function('neural#source#' . selected . '#Get')()
    catch /E117/
        call s:OutputErrorMessage('Invalid source: ' . l:selected)

        return
    endtry

    return l:source
endfunction

function! s:GetSourceInput(buffer, source, prompt) abort
    let l:config = get(g:neural.source, a:source.name, {})

    " If the config is not a Dictionary, throw it away.
    if type(l:config) isnot v:t_dict
        let l:config = {}
    endif

    let l:input = {'config': l:config, 'prompt': a:prompt}

    " Pre-process input, such as modifying a prompt.
    call neural#PreProcess(a:buffer, l:input)

    return l:input
endfunction

function! neural#Prompt(prompt) abort
    " Reload the Neural config on a prompt request if needed.
    call neural#config#Load()
    call neural#Cleanup()

    if empty(a:prompt)
        if has('nvim') && g:neural.ui.prompt_enabled
            call neural#OpenPrompt()
        else
            call s:OutputErrorMessage('No prompt text!')
        endif

        return
    endif

    let l:buffer = bufnr('')
    let l:moving_line = getpos('.')[1]
    let s:request_line = l:moving_line

    if len(getline(l:moving_line)) == 0
        let l:moving_line -= 1
    endif

    let l:source = s:LoadDataSource()
    let l:script_exe = s:GetScriptExecutable(l:source)
    let l:command = neural#Escape(l:script_exe)
    \   . ' ' . neural#Escape(l:source.script)
    let l:command = neural#job#PrepareCommand(l:buffer, l:command)
    let l:job_data = {
    \   'moving_line': l:moving_line,
    \   'error_lines': [],
    \   'content_started': 0,
    \}
    let l:input = s:GetSourceInput(l:buffer, l:source, a:prompt)

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
        call s:OutputErrorMessage('Failed to run ' . l:source.name)

        return
    endif

    let s:current_job = l:job_id

    " Tell the user something is happening, if enabled.
    if g:neural.ui.echo_enabled
        " Echo with a 0 millisecond timer to avoid 'Press Enter to Continue'
        call timer_start(0, {-> s:InitiallyInformUser(l:job_id)})

        " If returning an answer takes a while, tell them again.
        call timer_start(5000, {-> s:InformUserIfStillBusy(l:job_id)})
    endif

    if has('nvim')
        execute 'lua require(''neural'').start_animated_sign(' . s:request_line . ')'
    endif
endfunction

" Stop Neural doing things when you kill buffers, quit, or suspend.
augroup NeuralCleanupGroup
    autocmd!
    autocmd BufDelete * call neural#Cleanup()
    autocmd QuitPre * call neural#Cleanup()

    if exists('##VimSuspend')
        autocmd VimSuspend call neural#Cleanup()
    endif
augroup END
