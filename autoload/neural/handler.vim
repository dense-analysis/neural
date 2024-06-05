scriptencoding utf8

" Author: Anexon <anexon@protonmail.com>
" Description: APIs for working with Asynchronous jobs, with an API normalised
" between Vim 8 and NeoVim.


if has('nvim') && !exists('s:ns_id')
    let s:ns_id = nvim_create_namespace('neural')
endif

function! neural#handler#AddTextToBuffer(buffer, job_data, stream_data) abort
    if (bufnr('') isnot a:buffer && !exists('*appendbufline')) || len(a:stream_data) == 0
        return
    endif

    let l:leader = ' 🔸🔶'
    let l:hl_group = 'ALEInfo'
    let l:text = a:stream_data

    " echoerr a:stream_data
    "

    " We need to handle creating new lines in the buffer separately to appending
    " content to an existing line due to Vim/Neovim API design.
    " if text is? ''
    " endif


    " Check if we need to re-position the cursor to stop it appearing to move
    " down as lines are added.
    let l:pos = getpos('.')
    let l:last_line = len(getbufline(a:buffer, 1, '$'))
    let l:move_up = 0
    let l:new_lines = split(a:stream_data, "\n")

    if l:pos[1] == l:last_line
        let l:move_up = 1
    endif

    if empty(l:new_lines)
        return
    endif

    " Cleanup leader
    let l:line_content = getbufline(a:buffer, a:job_data.moving_line)
    let l:new_lines[0] = get(l:line_content, 0, '') . l:new_lines[0]

    if has('nvim')
        call nvim_buf_set_lines(a:buffer, a:job_data.moving_line-1, a:job_data.moving_line, 0, l:new_lines)
    else
        echom string(l:new_lines)
        call setbufline(a:buffer, a:job_data.moving_line, l:new_lines)
    endif

    " Move the cursor back up again to make content appear below.
    if l:move_up
        call setpos('.', l:pos)
    endif

    let a:job_data.moving_line += len(l:new_lines)-1

    if has('nvim')
        call nvim_buf_set_virtual_text(
        \   a:buffer,
        \   s:ns_id,  a:job_data.moving_line - 1,
        \   [[l:leader, l:hl_group]],
        \   {}
        \)
    endif
    " elseif text is? '<<[EOF]>>'
    " elseif match(text, '\%x04') != -1
    "   " Strip out leader character/s at the end of the stream.
    "     let l:line_content = getbufline(a:buffer, a:job_data.moving_line)
    "
    "     if len(l:line_content) != 0
    "         let l:new_line_content = l:line_content[0][0:-len(l:leader)-1]
    "     endif
    "
    "     call setbufline(a:buffer, a:job_data.moving_line, l:new_line_content)
    "     let a:job_data.content_ended = 1
    " else
    "     let a:job_data.content_started = 1
    "     " Prepend any current line content with the incoming stream text.
    "     let l:line_content = getbufline(a:buffer, a:job_data.moving_line)
    "
    "     if len(l:line_content) == 0
    "         let l:new_line_content = text . l:leader
    "     else
    "         let l:new_line_content = l:line_content[0][0:-len(l:leader)-1] . text . l:leader
    "     endif
    "
    "     call setbufline(a:buffer, a:job_data.moving_line, l:new_line_content)
    " endif
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
