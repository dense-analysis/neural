function! s:AddLineToBuffer(buffer, job_data, line) abort
    if bufnr('') isnot a:buffer
        return
    endif

    if a:job_data.skip_next_line
        let a:job_data.skip_next_line = 0

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

function! s:HandleOutputEnd(buffer) abort
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
    if has('nvim')
        " FIXME
        lua Neural.prompt(prompt_text)
    else
        let l:datasource = $HOME . '/git/neural/neural_datasources/openai.py'
        let l:input = {
        \   'prompt': a:prompt_text,
        \   'temperature': 0.0,
        \}

        let l:buffer = bufnr('')
        let l:neural_line = getpos('.')[1]

        if len(getline(l:neural_line)) == 0
            let l:neural_line -= 1
        endif

        let l:command = 'python3' . ' ' . neural#Escape(l:datasource)
        let l:command = neural#job#PrepareCommand(l:buffer, l:command)
        " In Vim pty jobs echo back the input line, so we'll skip the first
        " line of output.
        let l:job_data = {
        \   'line': l:neural_line,
        \   'content_started': 0,
        \   'skip_next_line': !has('nvim'),
        \}

        let l:job_options = {
        \   'mode': 'nl',
        \   'out_cb': {job_id, line -> s:AddLineToBuffer(l:buffer, l:job_data, line)},
        \   'exit_cb': {job_id, exit_code -> s:HandleOutputEnd(l:buffer)},
        \}

        let l:job_id = neural#job#Start(l:command, l:job_options)

        if l:job_id > 0
            let l:stdin_data = json_encode(l:input) . "\n"

            call neural#job#SendRaw(l:job_id, l:stdin_data)
        endif
    endif
endfunction
