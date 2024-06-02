" Author: Anexon <anexon@protonmail.com>
" Description: APIs for working with Asynchronous jobs, with an API normalised
" between Vim 8 and NeoVim.

function! neural#handler#AddTextToBuffer(buffer, job_data, stream_data) abort
    if bufnr('') isnot a:buffer && !exists('*appendbufline')
    \ || !a:job_data.content_started && len(a:stream_data) == 0
    \ || a:job_data.content_ended
        return
    endif

    let l:leader = ' 🔸🔶'

    " echoerr a:stream_data
    "

    " We need to handle creating new lines in the buffer separately to appending
    " content to an existing line due to Vim/Neovim API design.
    for text in a:stream_data
        " Don't write empty or null characters to the buffer.
        " Replace null characters (^@) with nothing or a space, depending on your needs
        let text = substitute(text, '\%x03', '<X>', 'g')
        let text = substitute(text, '\%x00', '', 'g')
        " let text = substitute(text, '\\n', '|||', 'g')

        " echoerr text
        " if text is? '' || match(text, '\%x10') != -1 || match(text, '\%x00') != -1
        if text is? ''
            continue
        elseif text is? '\n' || text is? '<X>'|| match(text, '\%x03') != -1 || text is? '^C'
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
                call append(a:job_data.moving_line, '')
            else
                call appendbufline(a:buffer, a:job_data.moving_line, '')
            endif

            " Cleanup leader
            let l:line_content = getbufline(a:buffer, a:job_data.moving_line)
            call setbufline(a:buffer, a:job_data.moving_line, l:line_content[0][0:-len(l:leader)-1])

            " call setpos('.', getpos('.')[1])

            " Move the cursor back up again to make content appear below.
            " if l:move_up
            "     call setpos('.', l:pos)
            " endif

            let a:job_data.moving_line += 1
        " elseif text is? '<<[EOF]>>'
        elseif match(text, '\%x04') != -1
          " Strip out leader character/s at the end of the stream.
            let l:line_content = getbufline(a:buffer, a:job_data.moving_line)

            if len(l:line_content) != 0
                let l:new_line_content = l:line_content[0][0:-len(l:leader)-1]
            endif

            call setbufline(a:buffer, a:job_data.moving_line, l:new_line_content)
            let a:job_data.content_ended = 1
        else
            let a:job_data.content_started = 1
            " Prepend any current line content with the incoming stream text.
            let l:line_content = getbufline(a:buffer, a:job_data.moving_line)

            if len(l:line_content) == 0
                let l:new_line_content = text . l:leader
            else
                let l:new_line_content = l:line_content[0][0:-len(l:leader)-1] . text . l:leader
            endif

            call setbufline(a:buffer, a:job_data.moving_line, l:new_line_content)
        endif
    endfor
endfunction

function! neural#handler#AddLineToBuffer(buffer, job_data, line) abort
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
