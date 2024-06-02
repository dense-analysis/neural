" Author: w0rp <devw0rp@gmail.com>
" Description: APIs for working with Asynchronous jobs, with an API normalised
" between Vim 8 and NeoVim.
"
" Important functions are described below. They are:
"
"   neural#job#Start(command, options) -> job_id
"   neural#job#IsRunning(job_id) -> 1 if running, 0 otherwise.
"   neural#job#Stop(job_id)

if !has_key(s:, 'job_map')
    let s:job_map = {}
endif

" A map from timer IDs to jobs, for tracking jobs that need to be killed
" with SIGKILL if they don't terminate right away.
if !has_key(s:, 'job_kill_timers')
    let s:job_kill_timers = {}
endif

function! s:GetFunction(string_or_ref) abort
    if type(a:string_or_ref) is v:t_string
        return function(a:string_or_ref)
    endif

    return a:string_or_ref
endfunction

function! s:JoinNeovimOutput(job, last_line, data, mode, callback) abort
    if a:mode is# 'raw'
        " Neovim stream event handlers receive data as it becomes available
        " from the OS, thus the first and last items in the data list may be
        " partial lines.
        " Each stream item is passed to the callback individually which can be
        " a chunk of text or a newline character.
        " echoerr a:data
        if len(a:data) > 1
            for text in a:data
                call a:callback(a:job, [text])
            endfor
        else
            call a:callback(a:job, a:data)
        endif

        return
    endif

    let l:lines = a:data[:-2]

    if len(a:data) > 1
        let l:lines[0] = a:last_line . l:lines[0]
        let l:new_last_line = a:data[-1]
    else
        let l:new_last_line = a:last_line . get(a:data, 0, '')
    endif

    for l:line in l:lines
        call a:callback(a:job, l:line)
    endfor

    return l:new_last_line
endfunction

function! s:KillHandler(timer) abort
    let l:job = remove(s:job_kill_timers, a:timer)
    call job_stop(l:job, 'kill')
endfunction

function! s:NeoVimCallback(job, data, event) abort
    let l:info = s:job_map[a:job]

    if a:event is# 'stdout'
        let l:info.out_cb_line = s:JoinNeovimOutput(
        \   a:job,
        \   l:info.out_cb_line,
        \   a:data,
        \   l:info.mode,
        \   s:GetFunction(l:info.out_cb),
        \)
    elseif a:event is# 'stderr'
        let l:info.err_cb_line = s:JoinNeovimOutput(
        \   a:job,
        \   l:info.err_cb_line,
        \   a:data,
        \   l:info.mode,
        \   s:GetFunction(l:info.err_cb),
        \)
    else
        if has_key(l:info, 'out_cb') && !empty(l:info.out_cb_line)
            call s:GetFunction(l:info.out_cb)(a:job, l:info.out_cb_line)
        endif

        if has_key(l:info, 'err_cb') && !empty(l:info.err_cb_line)
            call s:GetFunction(l:info.err_cb)(a:job, l:info.err_cb_line)
        endif

        try
            call s:GetFunction(l:info.exit_cb)(a:job, a:data)
        finally
            " Automatically forget about the job after it's done.
            if has_key(s:job_map, a:job)
                call remove(s:job_map, a:job)
            endif
        endtry
    endif
endfunction

function! s:VimOutputCallback(channel, data) abort
    let l:job = ch_getjob(a:channel)
    let l:job_id = neural#job#ParseVim8ProcessID(string(l:job))

    " Only call the callbacks for jobs which are valid.
    if l:job_id > 0 && has_key(s:job_map, l:job_id)
        call s:GetFunction(s:job_map[l:job_id].out_cb)(l:job_id, a:data)
    endif
endfunction

function! s:VimErrorCallback(channel, data) abort
    let l:job = ch_getjob(a:channel)
    let l:job_id = neural#job#ParseVim8ProcessID(string(l:job))

    " Only call the callbacks for jobs which are valid.
    if l:job_id > 0 && has_key(s:job_map, l:job_id)
        call s:GetFunction(s:job_map[l:job_id].err_cb)(l:job_id, a:data)
    endif
endfunction

function! s:VimCloseCallback(channel) abort
    let l:job = ch_getjob(a:channel)
    let l:job_id = neural#job#ParseVim8ProcessID(string(l:job))
    let l:info = get(s:job_map, l:job_id, {})

    if empty(l:info)
        return
    endif

    " job_status() can trigger the exit handler.
    " The channel can close before the job has exited.
    if job_status(l:job) is# 'dead'
        try
            if !empty(l:info) && has_key(l:info, 'exit_cb')
                " We have to remove the callback, so we don't call it twice.
                call s:GetFunction(remove(l:info, 'exit_cb'))(l:job_id, get(l:info, 'exit_code', 1))
            endif
        finally
            " Automatically forget about the job after it's done.
            if has_key(s:job_map, l:job_id)
                call remove(s:job_map, l:job_id)
            endif
        endtry
    endif
endfunction

function! s:VimExitCallback(job, exit_code) abort
    let l:job_id = neural#job#ParseVim8ProcessID(string(a:job))
    let l:info = get(s:job_map, l:job_id, {})

    if empty(l:info)
        return
    endif

    let l:info.exit_code = a:exit_code

    " The program can exit before the data has finished being read.
    if ch_status(job_getchannel(a:job)) is# 'closed'
        try
            if !empty(l:info) && has_key(l:info, 'exit_cb')
                " We have to remove the callback, so we don't call it twice.
                call s:GetFunction(remove(l:info, 'exit_cb'))(l:job_id, a:exit_code)
            endif
        finally
            " Automatically forget about the job after it's done.
            if has_key(s:job_map, l:job_id)
                call remove(s:job_map, l:job_id)
            endif
        endtry
    endif
endfunction

function! neural#job#ParseVim8ProcessID(job_string) abort
    return matchstr(a:job_string, '\d\+') + 0
endfunction

function! neural#job#ValidateArguments(command, options) abort
    if a:options.mode isnot# 'nl' && a:options.mode isnot# 'raw'
        throw 'Invalid mode: ' . a:options.mode
    endif
endfunction

function! neural#job#PrepareCommand(buffer, command) abort
    " The command will be executed in a subshell. This fixes a number of
    " issues, including reading the PATH variables correctly, %PATHEXT%
    " expansion on Windows, etc.
    "
    " NeoVim handles this issue automatically if the command is a String,
    " but we'll do this explicitly, so we use the same exact command for both
    " versions.
    if has('win32')
        return 'cmd /s/c "' . a:command . '"'
    endif

    return ['/bin/sh', '-c', a:command]
endfunction

" Start a job with options which are agnostic to Vim and NeoVim.
"
" The following options are accepted:
"
" out_cb  - A callback for receiving stdin.  Arguments: (job_id, data)
" err_cb  - A callback for receiving stderr. Arguments: (job_id, data)
" exit_cb - A callback for program exit.     Arguments: (job_id, status_code)
" mode    - A mode for I/O. Can be 'nl' for split lines or 'raw'.
function! neural#job#Start(command, options) abort
    call neural#job#ValidateArguments(a:command, a:options)

    let l:job_info = copy(a:options)
    let l:job_options = {}

    if has('nvim')
        if has_key(a:options, 'out_cb')
            let l:job_options.on_stdout = function('s:NeoVimCallback')
            let l:job_info.out_cb_line = ''
        endif

        if has_key(a:options, 'err_cb')
            let l:job_options.on_stderr = function('s:NeoVimCallback')
            let l:job_info.err_cb_line = ''
        endif

        if has_key(a:options, 'exit_cb')
            let l:job_options.on_exit = function('s:NeoVimCallback')
        endif

        let l:job_info.job = jobstart(a:command, l:job_options)
        let l:job_id = l:job_info.job
    else
        let l:job_options = {
        \   'in_mode': l:job_info.mode,
        \   'out_mode': l:job_info.mode,
        \   'err_mode': l:job_info.mode,
        \}

        if has_key(a:options, 'out_cb')
            let l:job_options.out_cb = function('s:VimOutputCallback')
        else
            " prevent buffering of output and excessive polling in case close_cb is set
            let l:job_options.out_cb = {->0}
        endif

        if has_key(a:options, 'err_cb')
            let l:job_options.err_cb = function('s:VimErrorCallback')
        else
            " prevent buffering of output and excessive polling in case close_cb is set
            let l:job_options.err_cb = {->0}
        endif

        if has_key(a:options, 'exit_cb')
            " Set a close callback to which simply calls job_status()
            " when the channel is closed, which can trigger the exit callback
            " earlier on.
            let l:job_options.close_cb = function('s:VimCloseCallback')
            let l:job_options.exit_cb = function('s:VimExitCallback')
        endif

        " Use non-blocking writes for Vim versions that support the option.
        if has('patch-8.1.350')
            let l:job_options.noblock = 1
        endif

        " Vim 8 will read the stdin from the file's buffer.
        let l:job_info.job = job_start(a:command, l:job_options)
        let l:job_id = neural#job#ParseVim8ProcessID(string(l:job_info.job))
    endif

    if l:job_id > 0
        " Store the job in the map for later only if we can get the ID.
        let s:job_map[l:job_id] = l:job_info
    endif

    return l:job_id
endfunction

" Force running commands in a Windows CMD command line.
" This means the same command syntax works everywhere.
function! neural#job#StartWithCmd(command, options) abort
    let l:shell = &l:shell
    let l:shellcmdflag = &l:shellcmdflag
    let &l:shell = 'cmd'
    let &l:shellcmdflag = '/c'

    try
        let l:job_id = neural#job#Start(a:command, a:options)
    finally
        let &l:shell = l:shell
        let &l:shellcmdflag = l:shellcmdflag
    endtry

    return l:job_id
endfunction

" Send raw data to the job.
function! neural#job#SendRaw(job_id, string) abort
    if has('nvim')
        call jobsend(a:job_id, a:string)
    else
        let l:job = s:job_map[a:job_id].job

        if ch_status(l:job) is# 'open'
            call ch_sendraw(job_getchannel(l:job), a:string)
        endif
    endif
endfunction

" Given a job ID, return 1 if the job is currently running.
" Invalid job IDs will be ignored.
function! neural#job#IsRunning(job_id) abort
    if has('nvim')
        try
            " In NeoVim, if the job isn't running, jobpid() will throw.
            call jobpid(a:job_id)

            return 1
        catch
        endtry
    elseif has_key(s:job_map, a:job_id)
        let l:job = s:job_map[a:job_id].job

        return job_status(l:job) is# 'run'
    endif

    return 0
endfunction

function! neural#job#HasOpenChannel(job_id) abort
    if neural#job#IsRunning(a:job_id)
        if has('nvim')
            " TODO: Implement a check for NeoVim.
            return 1
        endif

        " Check if the Job's channel can be written to.
        return ch_status(s:job_map[a:job_id].job) is# 'open'
    endif

    return 0
endfunction

" Given a Job ID, stop that job.
" Invalid job IDs will be ignored.
function! neural#job#Stop(job_id) abort
    if !has_key(s:job_map, a:job_id)
        return
    endif

    if has('nvim')
        " FIXME: NeoVim kills jobs on a timer, but will not kill any processes
        " which are child processes on Unix. Some work needs to be done to
        " kill child processes to stop long-running processes like pylint.
        silent! call jobstop(a:job_id)
    else
        let l:job = s:job_map[a:job_id].job

        " We must close the channel for reading the buffer if it is open
        " when stopping a job. Otherwise, we will get errors in the status line.
        if ch_status(job_getchannel(l:job)) is# 'open'
            call ch_close_in(job_getchannel(l:job))
        endif

        " Ask nicely for the job to stop.
        call job_stop(l:job)

        if neural#job#IsRunning(l:job)
            " Set a 100ms delay for killing the job with SIGKILL.
            let s:job_kill_timers[timer_start(100, function('s:KillHandler'))] = l:job
        endif
    endif
endfunction
